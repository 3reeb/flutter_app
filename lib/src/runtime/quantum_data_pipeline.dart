import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'quantum_data_state.dart';
import '../foundation/quantum_primitives.dart';
import '../foundation/quantum_core.dart';
import 'package:quantum_layout/quantum.dart';
enum QLPipelineMode { collection, single }

enum QLExecutionMode { client, server, isolate, auto }

class QLPrefetchConfig {
  final int triggerDistance;
  final int maxPagesToCache;

  const QLPrefetchConfig({
    this.triggerDistance = 10,
    this.maxPagesToCache = 5,
  });
}

class QLAggregateOp {
  final String alias;
  final String field;
  final String type; // sum, avg, min, max, count

  const QLAggregateOp({
    required this.alias,
    required this.field,
    required this.type,
  });
}

abstract class QLPipelineDelegate {
  Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state);
  Future<List<Map<String, dynamic>>> fetchPartial(
      List<String> ids, QLProjection projection);
}

/// Flat-cache pipeline optimized for large record sets, partial hydration,
/// indexed lookups, and aggregate computation.
class QLDataPipeline {
  final String id;
  final QLSchemaBlueprint schema;
  final QLPipelineMode mode;
  final QLExecutionMode executionMode;
  final QLPipelineDelegate? delegate;
  final QLPrefetchConfig prefetchConfig;
  final int pageSize;

  final int _primaryKeyIdx;
  final List<dynamic> _fields;
  final List<List<dynamic>> _resolvedPaths;

  final Map<int, String> _indexToPath = <int, String>{};

  final List<List<dynamic>> _records = <List<dynamic>>[];
  List<List<dynamic>> get rawRecords => _records;

  final Map<String, int> _idToIndex = <String, int>{};
  final List<String> _searchCache = <String>[];

  final Map<int, Map<dynamic, List<int>>> _indices =
      <int, Map<dynamic, List<int>>>{};
  final Map<int, Map<dynamic, int>> _uniqueIndices = <int, Map<dynamic, int>>{};

  late final int _maskWordsPerRecord;
  Uint32List _loadedMasks = Uint32List(0);
  int _recordCount = 0;

  final QLSignal<Int32List> visibleIndices = QLSignal(Int32List(0));
  int visibleCount = 0;

  final QLSignal<Map<int, String>> filters = QLSignal(<int, String>{});
  final QLSignal<String> searchQuery = QLSignal('');
  final QLSignal<int> sortFieldIndex = QLSignal(-1);
  final QLSignal<bool> sortAsc = QLSignal(true);
  final QLSignal<int> page = QLSignal(0);

  final QLSignal<Map<String, double>> aggregates = QLSignal(<String, double>{});
  final List<QLAggregateOp> _aggregateOps = <QLAggregateOp>[];

  final Set<int> _requestedPages = <int>{};
  final Set<int> _inFlightPages = <int>{};
  final ListQueue<int> _requestedPageOrder = ListQueue<int>();

  bool _isComputing = false;
  bool _computeScheduled = false;
  bool _fetching = false;
  bool _disposed = false;

  late final VoidCallback _recomputeListener = _scheduleCompute;

  QLDataPipeline({
    required this.id,
    required this.schema,
    this.mode = QLPipelineMode.collection,
    this.executionMode = QLExecutionMode.auto,
    this.delegate,
    this.prefetchConfig = const QLPrefetchConfig(),
    this.pageSize = 0,
    String primaryKey = 'id',
  })  : _fields = schema.fields.toList(growable: false),
        _resolvedPaths = schema.fields
            .map((field) => QLPathUtils.resolve(field.path))
            .toList(growable: false),
        _primaryKeyIdx = schema.getIndex(primaryKey) {
    if (_primaryKeyIdx == -1 && mode == QLPipelineMode.collection) {
      throw StateError(
        'Primary key "$primaryKey" not found in schema "${schema.name}".',
      );
    }

    _maskWordsPerRecord = (schema.fieldCount + 31) ~/ 32;
    _expandMasks(1024);
    _buildIndices();

    filters.addListener(_recomputeListener);
    searchQuery.addListener(_recomputeListener);
    sortFieldIndex.addListener(_recomputeListener);
    sortAsc.addListener(_recomputeListener);
    page.addListener(_recomputeListener);

    for (final field in _fields) {
      _indexToPath[field.index] = field.path.toString();
    }
  }

  bool get isDisposed => _disposed;
  bool get isComputing => _isComputing;

  Map<String, dynamic> snapshot() {
    if (_computeScheduled && !_isComputing && !_disposed) {
      _compute();
    }

    return <String, dynamic>{
      'id': id,
      'schema': schema.name,
      'mode': mode.name,
      'executionMode': executionMode.name,
      'pageSize': pageSize,
      'fieldCount': schema.fieldCount,
      'recordCount': _recordCount,
      'visibleCount': visibleCount,
      'aggregates': aggregates.value,
      'filters': filters.value,
      'searchQuery': searchQuery.value,
      'sortFieldIndex': sortFieldIndex.value,
      'sortAsc': sortAsc.value,
      'page': page.value,
      'requestedPages': _requestedPages.toList(growable: false),
      'inFlightPages': _inFlightPages.toList(growable: false),
    };
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    filters.removeListener(_recomputeListener);
    searchQuery.removeListener(_recomputeListener);
    sortFieldIndex.removeListener(_recomputeListener);
    sortAsc.removeListener(_recomputeListener);
    page.removeListener(_recomputeListener);

    _records.clear();
    _idToIndex.clear();
    _searchCache.clear();
    _indices.clear();
    _uniqueIndices.clear();
    _requestedPages.clear();
    _inFlightPages.clear();
    _requestedPageOrder.clear();
    _aggregateOps.clear();
    _loadedMasks = Uint32List(0);
    _recordCount = 0;
    visibleIndices.setSilent(Int32List(0));
    visibleCount = 0;
    aggregates.setSilent(<String, double>{});
  }

  // ───────────────────────────────────────────────────────────── Public API ──

  void setFilters(Map<int, String> next) {
    filters.setSilent(Map<int, String>.from(next));
    filters.forceNotify();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setSort(int fieldIndex, {bool ascending = true}) {
    sortFieldIndex.value = fieldIndex;
    sortAsc.value = ascending;
  }

  void setPage(int pageIndex) {
    page.value = pageIndex < 0 ? 0 : pageIndex;
  }

  void clearFilters() {
    filters.setSilent(<int, String>{});
    filters.forceNotify();
  }

  void replaceAll(dynamic rawData, {List<String>? selectedFields}) {
    _records.clear();
    _idToIndex.clear();
    _searchCache.clear();
    _loadedMasks = Uint32List(0);
    _recordCount = 0;
    _requestedPages.clear();
    _inFlightPages.clear();
    ingest(rawData, selectedFields: selectedFields);
  }

  Map<String, dynamic> recordAsMap(int realIdx) => getAsMap(realIdx);

  // ───────────────────────────────────────────────────────────── Indices ──

  void _buildIndices() {
    for (final spec in _fields) {
      if ((spec.flags & QLFieldFlags.isUnique) != 0) {
        _uniqueIndices[spec.index] = <dynamic, int>{};
      } else if ((spec.flags & QLFieldFlags.isIndexed) != 0) {
        _indices[spec.index] = <dynamic, List<int>>{};
      }
    }
  }

  void _updateIndexEntries(
      int recordIdx, List<dynamic> oldRow, List<dynamic> newRow, bool fullRow) {
    for (final spec in _fields) {
      final fieldIdx = spec.index;
      final shouldTouch = fullRow ||
          oldRow[fieldIdx] != newRow[fieldIdx] ||
          (oldRow[fieldIdx] == null && newRow[fieldIdx] != null);

      if (!shouldTouch) continue;

      final oldVal = oldRow[fieldIdx];
      final newVal = newRow[fieldIdx];

      final unique = _uniqueIndices[fieldIdx];
      if (unique != null) {
        if (oldVal != null && unique[oldVal] == recordIdx) {
          unique.remove(oldVal);
        }
        if (newVal != null) {
          unique[newVal] = recordIdx;
        }
      }

      final indexMap = _indices[fieldIdx];
      if (indexMap != null) {
        if (oldVal != null) {
          final bucket = indexMap[oldVal];
          if (bucket != null) {
            bucket.remove(recordIdx);
            if (bucket.isEmpty) indexMap.remove(oldVal);
          }
        }
        if (newVal != null) {
          (indexMap[newVal] ??= <int>[]).add(recordIdx);
        }
      }
    }
  }

  void _updateSearchCache(int recordIdx, List<dynamic> flat) {
    final sb = StringBuffer();
    for (final v in flat) {
      if (v != null) {
        sb.write(v);
        sb.write(' ');
      }
    }
    final searchStr = sb.toString().toLowerCase();
    if (recordIdx >= _searchCache.length) {
      _searchCache.add(searchStr);
    } else {
      _searchCache[recordIdx] = searchStr;
    }
  }

  // ───────────────────────────────────────────────────────────── Masking ──

  void _expandMasks(int minCapacity) {
    final requiredLength = minCapacity * _maskWordsPerRecord;
    if (_loadedMasks.length >= requiredLength) return;

    var newCap = _loadedMasks.isEmpty ? 1024 : _loadedMasks.length * 2;
    while (newCap < requiredLength) {
      newCap *= 2;
    }

    final next = Uint32List(newCap);
    if (_loadedMasks.isNotEmpty) {
      next.setAll(0, _loadedMasks);
    }
    _loadedMasks = next;
  }

  void _markLoadedBits(int recordIdx, QLProjection? proj, bool full) {
    final maskStart = recordIdx * _maskWordsPerRecord;
    if (full || proj == null) {
      for (int w = 0; w < _maskWordsPerRecord; w++) {
        _loadedMasks[maskStart + w] = 0xFFFFFFFF;
      }
      return;
    }

    for (int i = 0; i < schema.fieldCount; i++) {
      if (proj.isSelected(i)) {
        final word = i >> 5;
        _loadedMasks[maskStart + word] |= (1 << (i & 31));
      }
    }
  }

  // ───────────────────────────────────────────────────────────── Flattening ──

  List<dynamic> _flattenMap(Map<String, dynamic> parsed, QLProjection? proj) {
    final flat = List<dynamic>.filled(schema.fieldCount, null, growable: false);
    for (final spec in _fields) {
      if (proj != null && !proj.isSelected(spec.index)) continue;
      flat[spec.index] = _readAt(parsed, _resolvedPaths[spec.index]);
    }
    return flat;
  }

  dynamic _readAt(Map<String, dynamic> root, List<dynamic> path) {
    dynamic current = root;
    for (final seg in path) {
      if (current is Map && current.containsKey(seg.toString())) {
        current = current[seg.toString()];
      } else if (current is List &&
          seg is int &&
          seg >= 0 &&
          seg < current.length) {
        current = current[seg];
      } else {
        return null;
      }
    }
    return current;
  }

  void _writeToMap(
      Map<String, dynamic> root, List<dynamic> path, dynamic value) {
    if (path.isEmpty) return;
    dynamic current = root;

    for (int i = 0; i < path.length - 1; i++) {
      final seg = path[i];
      final next = path[i + 1];

      if (current is Map) {
        final key = seg.toString();
        current.putIfAbsent(
          key,
          () => next is int ? <dynamic>[] : <String, dynamic>{},
        );
        current = current[key];
      } else if (current is List) {
        final idx = seg is int ? seg : int.tryParse(seg.toString()) ?? 0;
        while (current.length <= idx) {
          current.add(next is int ? <dynamic>[] : <String, dynamic>{});
        }
        current = current[idx];
      } else {
        return;
      }
    }

    final last = path.last;
    if (current is Map) {
      current[last.toString()] = value;
    } else if (current is List) {
      final idx = last is int ? last : int.tryParse(last.toString()) ?? 0;
      while (current.length <= idx) {
        current.add(null);
      }
      current[idx] = value;
    }
  }

  // ───────────────────────────────────────────────────────────── Ingestion ──

  void ingest(dynamic rawData, {List<String>? selectedFields}) {
    if (_disposed) return;

    final proj =
        selectedFields != null ? schema.createProjection(selectedFields) : null;
    final records = QLRuntimeSupport.recordsOf(rawData);
    if (records.isEmpty) return;

    var requiresCompute = false;

    if (mode == QLPipelineMode.single) {
      final json = records.first;
      final parsedMap = schema.parse(json, projection: proj);
      final incoming = _flattenMap(parsedMap, proj);

      if (_records.isEmpty) {
        final row =
            List<dynamic>.filled(schema.fieldCount, null, growable: false);
        for (int i = 0; i < schema.fieldCount; i++) {
          if (proj == null || proj.isSelected(i)) {
            row[i] = incoming[i];
          }
        }
        _records.add(row);
        _recordCount = 1;
        _expandMasks(1);
        _updateSearchCache(0, row);
        _markLoadedBits(0, proj, proj == null);
        requiresCompute = true;
      } else {
        final row = _records[0];
        final old = List<dynamic>.from(row, growable: false);
        var changed = false;

        for (int i = 0; i < schema.fieldCount; i++) {
          if (proj == null || proj.isSelected(i)) {
            final nextValue = incoming[i];
            if (row[i] != nextValue) {
              row[i] = nextValue;
              changed = true;
            }
          }
        }

        if (changed) {
          _updateIndexEntries(0, old, row, proj == null);
          _updateSearchCache(0, row);
          _markLoadedBits(0, proj, proj == null);
          requiresCompute = true;
        }
      }

      if (requiresCompute) _scheduleCompute();
      return;
    }

    for (final json in records) {
      final parsedMap = schema.parse(json, projection: proj);
      final incoming = _flattenMap(parsedMap, proj);

      final dynamic idRaw = incoming[_primaryKeyIdx];
      if (idRaw == null) continue;
      final recordId = idRaw.toString();

      final existingIdx = _idToIndex[recordId];
      if (existingIdx == null) {
        final idx = _recordCount++;
        _idToIndex[recordId] = idx;

        final row =
            List<dynamic>.filled(schema.fieldCount, null, growable: false);
        for (int i = 0; i < schema.fieldCount; i++) {
          if (proj == null || proj.isSelected(i)) {
            row[i] = incoming[i];
          }
        }

        _records.add(row);
        _expandMasks(_recordCount);
        _updateSearchCache(idx, row);
        _markLoadedBits(idx, proj, proj == null);
        _updateIndexEntries(
          idx,
          List<dynamic>.filled(schema.fieldCount, null, growable: false),
          row,
          proj == null,
        );
        requiresCompute = true;
      } else {
        final row = _records[existingIdx];
        final old = List<dynamic>.from(row, growable: false);
        var changed = false;

        for (int i = 0; i < schema.fieldCount; i++) {
          if (proj == null || proj.isSelected(i)) {
            final nextValue = incoming[i];
            if (row[i] != nextValue) {
              row[i] = nextValue;
              changed = true;
            }
          }
        }

        if (changed) {
          _updateIndexEntries(existingIdx, old, row, proj == null);
          _updateSearchCache(existingIdx, row);
          _markLoadedBits(existingIdx, proj, proj == null);
          requiresCompute = true;
        }
      }
    }

    if (requiresCompute) _scheduleCompute();
  }

  void patch(String recordId, Map<String, dynamic> delta) {
    if (_disposed) return;

    final idx = _idToIndex[recordId];
    if (idx == null) {
      if (mode == QLPipelineMode.collection) {
        final pkPath = _getPathForIndex(_primaryKeyIdx);
        if (pkPath.isNotEmpty) {
          delta[pkPath] = recordId;
          ingest(<Map<String, dynamic>>[delta]);
        }
      }
      return;
    }

    final row = _records[idx];
    final old = List<dynamic>.from(row, growable: false);
    var modified = false;

    for (final entry in delta.entries) {
      final fieldIdx = schema.getIndex(entry.key);
      if (fieldIdx == -1) continue;

      final value = entry.value;
      if (row[fieldIdx] != value) {
        row[fieldIdx] = value;
        modified = true;
      }

      final maskStart = idx * _maskWordsPerRecord;
      final word = fieldIdx >> 5;
      _loadedMasks[maskStart + word] |= (1 << (fieldIdx & 31));

      if (fieldIdx == _primaryKeyIdx) {
        final oldPk = recordId;
        final newPk = value?.toString();
        if (newPk != null && newPk.isNotEmpty && newPk != oldPk) {
          _idToIndex.remove(oldPk);
          _idToIndex[newPk] = idx;
        }
      }
    }

    if (modified) {
      _updateIndexEntries(idx, old, row, false);
      _updateSearchCache(idx, row);
      _scheduleCompute();
    }
  }

  Future<void> ensureFields(
      String recordId, List<String> requiredFields) async {
    if (mode == QLPipelineMode.single ||
        delegate == null ||
        requiredFields.isEmpty ||
        _disposed) {
      return;
    }

    final idx = _idToIndex[recordId];
    if (idx == null) return;

    final requiredProj = schema.createProjection(requiredFields);
    final maskStart = idx * _maskWordsPerRecord;

    var hasAll = true;
    final missingPaths = <String>[];

    for (int i = 0; i < schema.fieldCount; i++) {
      if (!requiredProj.isSelected(i)) continue;
      final word = i >> 5;
      final bit = 1 << (i & 31);
      if ((_loadedMasks[maskStart + word] & bit) == 0) {
        hasAll = false;
        missingPaths.add(_indexToPath[i] ?? '');
      }
    }

    if (!hasAll && missingPaths.isNotEmpty) {
      final pkPath = _getPathForIndex(_primaryKeyIdx);
      final requestFields = <String>{
        if (pkPath.isNotEmpty) pkPath,
        ...requiredFields.where((p) => p.isNotEmpty),
        ...missingPaths.where((p) => p.isNotEmpty),
      }.toList(growable: false);
      final fetchProj = schema.createProjection(requestFields);
      await _delegatePartialFetch(recordId, fetchProj, requestFields);
    }
  }

  Future<void> _delegatePartialFetch(
      String id, QLProjection projection, List<String> selectedFields) async {
    if (delegate == null || _disposed) return;
    final result = await delegate!.fetchPartial(<String>[id], projection);
    ingest(result, selectedFields: selectedFields);

    // Fallback: if the delegate returned a richer payload than the selected
    // projection path covers, patch the first record directly so partial
    // hydration cannot strand a field in a null state.
    if (result.isNotEmpty && result.first is Map) {
      final first = Map<String, dynamic>.from(result.first as Map);
      final pkPath = _getPathForIndex(_primaryKeyIdx);
      final pkValue = first[pkPath] ?? first['id'];
      if (pkValue != null) {
        patch(pkValue.toString(), first);
      }
    }
  }

  // ───────────────────────────────────────────────────────────── Prefetch ──

  void notifyScrollIndex(int currentIndex) {
    if (delegate == null || mode == QLPipelineMode.single || _fetching) return;
    if (visibleCount == 0) return;

    final triggerPoint =
        math.max(0, visibleCount - prefetchConfig.triggerDistance);
    if (currentIndex < triggerPoint) return;

    final nextPage = page.value + 1;
    if (_requestedPages.contains(nextPage) ||
        _inFlightPages.contains(nextPage)) {
      return;
    }

    if (prefetchConfig.maxPagesToCache > 0 &&
        _requestedPages.length >= prefetchConfig.maxPagesToCache) {
      return;
    }

    _fetching = true;
    unawaited(_requestServerPage(nextPage));
  }

  Future<void> _requestServerPage(int pageNum) async {
    if (delegate == null || _disposed) return;
    _inFlightPages.add(pageNum);

    try {
      final res = await delegate!.fetch(<String, dynamic>{
        'filters': filters.value,
        'search': searchQuery.value,
        'sortField': sortFieldIndex.value,
        'sortAsc': sortAsc.value,
        'page': pageNum,
        'pageSize': pageSize,
      });

      _rememberRequestedPage(pageNum);
      ingest(res);
    } finally {
      _inFlightPages.remove(pageNum);
      _fetching = false;
    }
  }

  void _rememberRequestedPage(int pageNum) {
    if (_requestedPages.add(pageNum)) {
      _requestedPageOrder.addLast(pageNum);
      while (prefetchConfig.maxPagesToCache > 0 &&
          _requestedPageOrder.length > prefetchConfig.maxPagesToCache) {
        final removed = _requestedPageOrder.removeFirst();
        _requestedPages.remove(removed);
      }
    }
  }

  // ───────────────────────────────────────────────────────────── Aggregates ──

  void registerAggregates(List<QLAggregateOp> ops) {
    _aggregateOps
      ..clear()
      ..addAll(ops);
    _scheduleCompute();
  }

  // ───────────────────────────────────────────────────────────── Computation ──

  void _scheduleCompute() {
    if (_disposed || _computeScheduled) return;
    _computeScheduled = true;
    scheduleMicrotask(() {
      if (_disposed || !_computeScheduled) return;
      _compute();
    });
  }

  void _compute() {
    if (_disposed) return;

    _computeScheduled = false;
    _isComputing = true;

    try {
      if (_records.isEmpty) {
        visibleCount = 0;
        visibleIndices.forceNotify();
        return;
      }

      if (mode == QLPipelineMode.single) {
        if (visibleIndices.value.isEmpty) {
          visibleIndices.setSilent(Int32List(1));
        }
        visibleIndices.value[0] = 0;
        visibleCount = 1;
        _processAggregatesAndNotify(visibleIndices.value);
        return;
      }

      if (visibleIndices.value.length < _recordCount) {
        visibleIndices.setSilent(Int32List(math.max(16, _recordCount * 2)));
      }

      final out = visibleIndices.value;
      visibleCount = 0;

      final activeFilters = filters.value;
      final q = searchQuery.value.toLowerCase();

      if (activeFilters.length == 1 && q.isEmpty) {
        final entry = activeFilters.entries.first;
        final fIdx = entry.key;
        final fVal = entry.value;

        final unique = _uniqueIndices[fIdx];
        if (unique != null) {
          final exact = unique[fVal];
          if (exact != null) {
            out[0] = exact;
            visibleCount = 1;
            _processAggregatesAndNotify(out);
            return;
          }
        }

        final bucketMap = _indices[fIdx];
        if (bucketMap != null) {
          final matches = bucketMap[fVal];
          if (matches != null) {
            for (int i = 0; i < matches.length; i++) {
              out[i] = matches[i];
            }
            visibleCount = matches.length;
            _processAggregatesAndNotify(out);
            return;
          }
        }
      }

      for (int i = 0; i < _recordCount; i++) {
        var matches = true;
        final row = _records[i];

        if (activeFilters.isNotEmpty) {
          for (final entry in activeFilters.entries) {
            final cell = row[entry.key];
            if (cell == null ||
                !cell
                    .toString()
                    .toLowerCase()
                    .contains(entry.value.toLowerCase())) {
              matches = false;
              break;
            }
          }
        }

        if (matches && q.isNotEmpty) {
          if (i >= _searchCache.length || !_searchCache[i].contains(q)) {
            matches = false;
          }
        }

        if (matches) {
          out[visibleCount++] = i;
        }
      }

      _processAggregatesAndNotify(out);
    } finally {
      _isComputing = false;
    }
  }

  void _processAggregatesAndNotify(Int32List out) {
    if (_aggregateOps.isNotEmpty) {
      final Map<String, double> sum = <String, double>{};
      final Map<String, double> min = <String, double>{};
      final Map<String, double> max = <String, double>{};
      final Map<String, int> count = <String, int>{};

      for (int i = 0; i < visibleCount; i++) {
        final row = _records[out[i]];
        for (final op in _aggregateOps) {
          final fIdx = schema.getIndex(op.field);
          if (fIdx == -1) continue;

          var val = 0.0;
          final rawVal = row[fIdx];
          if (rawVal is num) {
            val = rawVal.toDouble();
          } else if (rawVal != null) {
            val = double.tryParse(rawVal.toString()) ?? 0.0;
          }

          switch (op.type) {
            case 'sum':
            case 'avg':
              sum[op.alias] = (sum[op.alias] ?? 0.0) + val;
              count[op.alias] = (count[op.alias] ?? 0) + 1;
              break;
            case 'min':
              min[op.alias] = math.min(min[op.alias] ?? val, val);
              break;
            case 'max':
              max[op.alias] = math.max(max[op.alias] ?? val, val);
              break;
            case 'count':
              count[op.alias] = (count[op.alias] ?? 0) + 1;
              break;
          }
        }
      }

      final results = <String, double>{};
      for (final op in _aggregateOps) {
        switch (op.type) {
          case 'sum':
            results[op.alias] = sum[op.alias] ?? 0.0;
            break;
          case 'avg':
            results[op.alias] = (count[op.alias] ?? 0) > 0
                ? (sum[op.alias] ?? 0.0) / count[op.alias]!
                : 0.0;
            break;
          case 'min':
            results[op.alias] = min[op.alias] ?? 0.0;
            break;
          case 'max':
            results[op.alias] = max[op.alias] ?? 0.0;
            break;
          case 'count':
            results[op.alias] = (count[op.alias] ?? 0).toDouble();
            break;
        }
      }
      aggregates.setSilent(results);
      aggregates.forceNotify();
    }

    final sField = sortFieldIndex.value;
    if (sField >= 0 && visibleCount > 1) {
      _quickSortIndices(out, 0, visibleCount - 1, sField, sortAsc.value);
    }

    if (pageSize > 0) {
      final p = page.value;
      final start = p * pageSize;
      if (start < visibleCount) {
        final int end = (start + pageSize).clamp(0, visibleCount).toInt();
        for (int i = 0; i < (end - start); i++) {
          out[i] = out[start + i];
        }
        visibleCount = end - start;
      } else {
        visibleCount = 0;
      }
    }

    visibleIndices.forceNotify();
  }

  void _quickSortIndices(
      Int32List arr, int left, int right, int field, bool asc) {
    if (left >= right) return;

    final pivotIdx = arr[(left + right) >> 1];
    final pivotVal = _records[pivotIdx][field];

    var i = left;
    var j = right;
    while (i <= j) {
      while (_compare(_records[arr[i]][field], pivotVal, asc,
              leftIndex: arr[i], rightIndex: pivotIdx) <
          0) {
        i++;
      }
      while (_compare(_records[arr[j]][field], pivotVal, asc,
              leftIndex: arr[j], rightIndex: pivotIdx) >
          0) {
        j--;
      }
      if (i <= j) {
        final temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
        i++;
        j--;
      }
    }

    if (left < j) _quickSortIndices(arr, left, j, field, asc);
    if (i < right) _quickSortIndices(arr, i, right, field, asc);
  }

  @pragma('vm:prefer-inline')
  int _compare(dynamic a, dynamic b, bool asc,
      {required int leftIndex, required int rightIndex}) {
    if (identical(a, b)) return 0;
    if (a == null) return asc ? 1 : -1;
    if (b == null) return asc ? -1 : 1;

    final cmp = (a is num && b is num)
        ? a.compareTo(b)
        : a.toString().compareTo(b.toString());

    if (cmp != 0) return asc ? cmp : -cmp;
    return leftIndex.compareTo(rightIndex);
  }

  // ───────────────────────────────────────────────────────────── Extraction ──

  Map<String, dynamic> getAsMap(int realIdx) {
    if (realIdx < 0 || realIdx >= _records.length) {
      return <String, dynamic>{};
    }

    final flat = _records[realIdx];
    final out = <String, dynamic>{};

    for (final spec in _fields) {
      final val = flat[spec.index];
      if (val != null) {
        _writeToMap(out, _resolvedPaths[spec.index], val);
      }
    }
    return out;
  }

  String _getPathForIndex(int index) => _indexToPath[index] ?? '';
}

class QLPipelineRegistry {
  static final QLPipelineRegistry instance = QLPipelineRegistry._();
  QLPipelineRegistry._();

  final Map<String, QLDataPipeline> _pipelines = <String, QLDataPipeline>{};

  void register(QLDataPipeline pipeline) {
    final previous = _pipelines[pipeline.id];
    if (previous != null) previous.dispose();
    _pipelines[pipeline.id] = pipeline;
  }

  QLDataPipeline get(String id) => _pipelines[id]!;

  bool exists(String id) => _pipelines.containsKey(id);

  Iterable<String> ids() => _pipelines.keys;

  void destroy(String id) => _pipelines.remove(id)?.dispose();

  void clear() {
    final ids = _pipelines.keys.toList(growable: false);
    for (final id in ids) {
      destroy(id);
    }
  }

  /// Export a registry snapshot with live pipeline metadata.
  Map<String, dynamic> snapshot() => <String, dynamic>{
        'count': _pipelines.length,
        'pipelines':
            _pipelines.values.map((p) => p.snapshot()).toList(growable: false),
      };
}


class QLDataPipelineReadPlan {
  final List<String> requested;
  final List<String> satisfied;
  final List<String> missing;

  const QLDataPipelineReadPlan({
    required this.requested,
    required this.satisfied,
    required this.missing,
  });

  bool get needsHydration => missing.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'requested': requested,
        'satisfied': satisfied,
        'missing': missing,
        'needsHydration': needsHydration,
      };
}

extension QLDataPipelineSmartAccess on QLDataPipeline {
  List<String> normalizeSelection(Iterable<String>? select) {
    final raw = select?.map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false) ??
        const <String>[];
    if (raw.isEmpty) {
      return schema.fieldPaths()
          .where((path) {
            final spec = schema.field(path);
            return spec != null && !spec.isVirtual && !spec.isComputed;
          })
          .toList(growable: false);
    }
    return schema.expandSelection(raw);
  }

  QLDataPipelineReadPlan buildReadPlan(int realIdx, {Iterable<String>? select}) {
    final requested = normalizeSelection(select);
    final row = realIdx >= 0 && realIdx < _records.length ? _records[realIdx] : null;
    final satisfied = <String>[];
    final missing = <String>[];

    if (row == null) {
      return QLDataPipelineReadPlan(
        requested: requested,
        satisfied: satisfied,
        missing: requested,
      );
    }

    for (final path in requested) {
      final idx = schema.getIndex(path);
      if (idx >= 0 && row[idx] != null) {
        satisfied.add(path);
      } else {
        missing.add(path);
      }
    }

    return QLDataPipelineReadPlan(
      requested: requested,
      satisfied: satisfied,
      missing: missing,
    );
  }

  Map<String, dynamic> getProjectedMap(int realIdx, {Iterable<String>? select}) {
    final map = getAsMap(realIdx);
    final requested = normalizeSelection(select);
    if (requested.isEmpty) return map;

    final out = <String, dynamic>{};
    for (final path in requested) {
      final value = _readValueAt(map, path);
      if (value != null) {
        _writeProjectedValue(out, path, value);
      }
    }
    return out;
  }

  bool hasProjectedFields(int realIdx, Iterable<String> select) {
    final plan = buildReadPlan(realIdx, select: select);
    return !plan.needsHydration;
  }

  Future<void> ensureSelection(String recordId, Iterable<String> select) async {
    if (select.isEmpty || delegate == null) return;
    await ensureFields(recordId, normalizeSelection(select));
  }

  dynamic _readValueAt(dynamic root, String path) {
    final pathParts = QLPathUtils.resolve(path);
    dynamic current = root;
    for (final part in pathParts) {
      if (current is Map) {
        current = current[part.toString()];
      } else if (current is List && part is int && part >= 0 && part < current.length) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  void _writeProjectedValue(Map<String, dynamic> root, String path, dynamic value) {
    final parts = QLPathUtils.resolve(path);
    if (parts.isEmpty) return;
    dynamic current = root;

    for (int i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      final next = parts[i + 1];
      if (current is Map) {
        final key = part.toString();
        current.putIfAbsent(key, () => next is int ? <dynamic>[] : <String, dynamic>{});
        current = current[key];
      } else if (current is List) {
        final idx = part is int ? part : int.tryParse(part.toString()) ?? 0;
        while (current.length <= idx) {
          current.add(next is int ? <dynamic>[] : <String, dynamic>{});
        }
        current = current[idx];
      } else {
        return;
      }
    }

    final last = parts.last;
    if (current is Map) {
      current[last.toString()] = value;
    } else if (current is List) {
      final idx = last is int ? last : int.tryParse(last.toString()) ?? 0;
      while (current.length <= idx) {
        current.add(null);
      }
      current[idx] = value;
    }
  }
}
