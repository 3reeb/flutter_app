import 'dart:async';
import 'dart:typed_data';
import '../reactivity/ql_signal.dart';
import 'ql_aggregate.dart';

abstract class QLPipelineDelegate {
  Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state);
}

class QLDataPipeline {
  final String id;
  final QLPipelineDelegate? delegate;

  final List<Map<String, dynamic>> _records = <Map<String, dynamic>>[];
  final QLSignal<Int32List> visibleIndices = QLSignal(Int32List(0));
  int visibleCount = 0;

  final QLSignal<Map<String, double>> aggregates =
      QLSignal(<String, double>{});
  final List<QLAggregateOp> _aggregateOps = <QLAggregateOp>[];

  final QLSignal<String> searchQuery = QLSignal('');
  final QLSignal<String> sortField = QLSignal('');
  final QLSignal<bool> sortAscending = QLSignal(true);

  QLDataPipeline({required this.id, this.delegate}) {
    searchQuery.addListener(recompute);
    sortField.addListener(recompute);
    sortAscending.addListener(recompute);
  }

  void ingest(List<Map<String, dynamic>> incoming) {
    _records.addAll(incoming);
    recompute();
  }

  void replaceAll(List<Map<String, dynamic>> incoming) {
    _records.clear();
    _records.addAll(incoming);
    recompute();
  }

  void registerAggregates(List<QLAggregateOp> ops) {
    _aggregateOps.addAll(ops);
    recompute();
  }

  void recompute() {
    final query = searchQuery.value.toLowerCase();
    final List<int> matches = <int>[];

    for (int i = 0; i < _records.length; i++) {
      if (query.isNotEmpty) {
        final recordStr = _records[i].values.join(' ').toLowerCase();
        if (!recordStr.contains(query)) continue;
      }
      matches.add(i);
    }

    final Int32List indices = Int32List.fromList(matches);
    visibleCount = indices.length;

    if (sortField.value.isNotEmpty && visibleCount > 1) {
      _quickSortIndices(
          indices, 0, visibleCount - 1, sortField.value, sortAscending.value);
    }

    visibleIndices.value = indices;
    _computeAggregates();
  }

  void _quickSortIndices(
      Int32List arr, int left, int right, String field, bool asc) {
    if (left >= right) return;
    final pivotVal = _records[arr[(left + right) >> 1]][field];
    var i = left, j = right;

    while (i <= j) {
      while (_compare(_records[arr[i]][field], pivotVal, asc) < 0) {
        i++;
      }
      while (_compare(_records[arr[j]][field], pivotVal, asc) > 0) {
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

  int _compare(dynamic a, dynamic b, bool asc) {
    if (a == b) return 0;
    if (a == null) return asc ? 1 : -1;
    if (b == null) return asc ? -1 : 1;
    final cmp = (a is num && b is num)
        ? a.compareTo(b)
        : a.toString().compareTo(b.toString());
    return asc ? cmp : -cmp;
  }

  void _computeAggregates() {
    if (_aggregateOps.isEmpty) return;
    final Map<String, double> results = <String, double>{};

    for (final op in _aggregateOps) {
      double sum = 0;
      double minVal = double.infinity;
      double maxVal = -double.infinity;
      int count = 0;

      for (int i = 0; i < visibleCount; i++) {
        final raw = _records[visibleIndices.value[i]][op.field];
        final val = (raw is num)
            ? raw.toDouble()
            : (double.tryParse(raw?.toString() ?? '') ?? 0.0);
        sum += val;
        count++;
        if (val < minVal) minVal = val;
        if (val > maxVal) maxVal = val;
      }

      switch (op.type) {
        case 'sum':
          results[op.alias] = sum;
          break;
        case 'avg':
          results[op.alias] = count > 0 ? sum / count : 0.0;
          break;
        case 'min':
          results[op.alias] = minVal.isInfinite ? 0.0 : minVal;
          break;
        case 'max':
          results[op.alias] = maxVal.isInfinite ? 0.0 : maxVal;
          break;
        case 'count':
          results[op.alias] = count.toDouble();
          break;
      }
    }
    aggregates.value = results;
  }

  Map<String, dynamic> getAsMap(int index) => _records[index];
}
