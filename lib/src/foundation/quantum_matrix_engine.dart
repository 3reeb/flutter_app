/*
 * ============================================================================
 * File: quantum_matrix_engine.dart
 * 
 * Description:
 * Core engine for CSS-like CSS-Grid matrix layouts. Supports responsive breakpoints, 
 * variants, interactive slot overrides, and accessibility/logical ordering. Translates 
 * ASCII grid definitions into structured mathematical layouts.
 * 
 * Key Components:
 * - QMatrixInteractionController: Runtime controller managing drag, drop, and resize states.
 * - QMatrixSlotRuntimeOverride: Visual tweaks/overrides for a specific slot.
 * - QMatrixBuilder: Fluent builder for compiling ASCII grids into structured layouts.
 * - QMatrixLayoutRegistry: Global cache and registry of defined matrix layouts.
 * 
 * Dependencies/Relationships:
 * Consumes quantum_core.dart (QSize, QParser). Used directly by the JSON DSL 
 * and layout engines for rendering responsive matrices.
 * 
 * Notes:
 * Translates intuitive ASCII strings into highly optimized constraints. Supports RTL, 
 * nesting, and complex Z-indexing natively.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
// Enhanced quantum_matrix_engine.dart
//
// Added capabilities:
// - RTL support
// - Accessibility semantics with logical vs visual ordering
// - Runtime interaction controller for drag/drop/reorder/resize
// - Hero support
// - Responsive breakpoints and variants
// - Cached track compilation and override caching
// - Nested layout friendliness
//
// Notes:
// - This file assumes the surrounding project already provides:
//   QLSignal, QLPlugin, QLWidgetCapability, QLBlueprint, QLDataStore,
//   QLDataScope, QLContext, QLDataBinder, QLReactiveRenderMixin,
//   QuantumVM, QParser, QSize, QFixed, QFraction, and related quantum APIs.

import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import '../../quantum.dart';
// ──────────────────────────────────────────────────────────────────────────────
// Public configuration
// ──────────────────────────────────────────────────────────────────────────────

enum QMatrixSemanticsOrder {
  logical,
  visual,
  none,
}

enum QMatrixTextDirectionMode {
  inherit,
  ltr,
  rtl,
}

enum QMatrixInteractionMode {
  none,
  drag,
  resize,
  dragAndResize,
}

enum QMatrixResizeHandle {
  none,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  left,
  right,
  top,
  bottom,
}

class QMatrixInteractionController extends ChangeNotifier {
  final Map<String, QMatrixSlotRuntimeOverride> _overrides =
      <String, QMatrixSlotRuntimeOverride>{};
  List<String>? _visualOrder;

  UnmodifiableMapView<String, QMatrixSlotRuntimeOverride> get overrides =>
      UnmodifiableMapView<String, QMatrixSlotRuntimeOverride>(_overrides);

  UnmodifiableListView<String>? get visualOrder =>
      _visualOrder == null ? null : UnmodifiableListView<String>(_visualOrder!);

  QMatrixSlotRuntimeOverride? overrideFor(String slotName) =>
      _overrides[slotName];

  void setVisualOrder(List<String>? order) {
    _visualOrder = order == null ? null : List<String>.from(order);
    notifyListeners();
  }

  void bringToFront(String slotName) {
    final order = _visualOrder ?? <String>[];
    order.remove(slotName);
    order.add(slotName);
    _visualOrder = order;
    notifyListeners();
  }

  void sendToBack(String slotName) {
    final order = _visualOrder ?? <String>[];
    order.remove(slotName);
    order.insert(0, slotName);
    _visualOrder = order;
    notifyListeners();
  }

  void setGridPlacement(
    String slotName, {
    int? rowStart,
    int? colStart,
    int? rowSpan,
    int? colSpan,
  }) {
    final current = _overrides.putIfAbsent(
      slotName,
      () => const QMatrixSlotRuntimeOverride(),
    );
    _overrides[slotName] = current.copyWith(
      rowStart: rowStart,
      colStart: colStart,
      rowSpan: rowSpan,
      colSpan: colSpan,
    );
    notifyListeners();
  }

  void setPixelOffset(String slotName, Offset offset) {
    final current = _overrides.putIfAbsent(
      slotName,
      () => const QMatrixSlotRuntimeOverride(),
    );
    _overrides[slotName] = current.copyWith(pixelOffset: offset);
    notifyListeners();
  }

  void setPixelSize(String slotName, Size size) {
    final current = _overrides.putIfAbsent(
      slotName,
      () => const QMatrixSlotRuntimeOverride(),
    );
    _overrides[slotName] = current.copyWith(pixelSize: size);
    notifyListeners();
  }

  void setZIndex(String slotName, int zIndex) {
    final current = _overrides.putIfAbsent(
      slotName,
      () => const QMatrixSlotRuntimeOverride(),
    );
    _overrides[slotName] = current.copyWith(zIndex: zIndex);
    notifyListeners();
  }

  void setHidden(String slotName, bool hidden) {
    final current = _overrides.putIfAbsent(
      slotName,
      () => const QMatrixSlotRuntimeOverride(),
    );
    _overrides[slotName] = current.copyWith(hidden: hidden);
    notifyListeners();
  }

  void clearSlot(String slotName) {
    if (_overrides.remove(slotName) != null) {
      notifyListeners();
    }
  }

  void clearAll() {
    if (_overrides.isNotEmpty || _visualOrder != null) {
      _overrides.clear();
      _visualOrder = null;
      notifyListeners();
    }
  }
}

class QMatrixSlotRuntimeOverride {
  final int? rowStart;
  final int? colStart;
  final int? rowSpan;
  final int? colSpan;
  final Offset? pixelOffset;
  final Size? pixelSize;
  final int? zIndex;
  final bool? hidden;

  const QMatrixSlotRuntimeOverride({
    this.rowStart,
    this.colStart,
    this.rowSpan,
    this.colSpan,
    this.pixelOffset,
    this.pixelSize,
    this.zIndex,
    this.hidden,
  });

  factory QMatrixSlotRuntimeOverride.fromJson(Map<String, dynamic> json) {
    final pixelOffset = json['pixelOffset'];
    final pixelSize = json['pixelSize'];
    return QMatrixSlotRuntimeOverride(
      rowStart:
          json['rowStart'] is num ? (json['rowStart'] as num).toInt() : null,
      colStart:
          json['colStart'] is num ? (json['colStart'] as num).toInt() : null,
      rowSpan: json['rowSpan'] is num ? (json['rowSpan'] as num).toInt() : null,
      colSpan: json['colSpan'] is num ? (json['colSpan'] as num).toInt() : null,
      pixelOffset: pixelOffset is Offset
          ? pixelOffset
          : pixelOffset is Map
              ? Offset(
                  (pixelOffset['dx'] as num?)?.toDouble() ?? 0.0,
                  (pixelOffset['dy'] as num?)?.toDouble() ?? 0.0,
                )
              : null,
      pixelSize: pixelSize is Size
          ? pixelSize
          : pixelSize is Map
              ? Size(
                  (pixelSize['width'] as num?)?.toDouble() ?? 0.0,
                  (pixelSize['height'] as num?)?.toDouble() ?? 0.0,
                )
              : null,
      zIndex: json['zIndex'] is num ? (json['zIndex'] as num).toInt() : null,
      hidden: json['hidden'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (rowStart != null) 'rowStart': rowStart,
        if (colStart != null) 'colStart': colStart,
        if (rowSpan != null) 'rowSpan': rowSpan,
        if (colSpan != null) 'colSpan': colSpan,
        if (pixelOffset != null)
          'pixelOffset': <String, double>{
            'dx': pixelOffset!.dx,
            'dy': pixelOffset!.dy,
          },
        if (pixelSize != null)
          'pixelSize': <String, double>{
            'width': pixelSize!.width,
            'height': pixelSize!.height,
          },
        if (zIndex != null) 'zIndex': zIndex,
        if (hidden != null) 'hidden': hidden,
      };

  QMatrixSlotRuntimeOverride copyWith({
    int? rowStart,
    int? colStart,
    int? rowSpan,
    int? colSpan,
    Offset? pixelOffset,
    Size? pixelSize,
    int? zIndex,
    bool? hidden,
  }) {
    return QMatrixSlotRuntimeOverride(
      rowStart: rowStart ?? this.rowStart,
      colStart: colStart ?? this.colStart,
      rowSpan: rowSpan ?? this.rowSpan,
      colSpan: colSpan ?? this.colSpan,
      pixelOffset: pixelOffset ?? this.pixelOffset,
      pixelSize: pixelSize ?? this.pixelSize,
      zIndex: zIndex ?? this.zIndex,
      hidden: hidden ?? this.hidden,
    );
  }
}

class QMatrixSlotDef {
  final bool scrollable;
  final bool floating;
  final bool preserveOverlap;
  final bool draggable;
  final bool resizable;
  final bool reorderable;
  final String align; // 'start', 'center', 'end', 'stretch'
  final int zIndex;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool useHero;
  final Object? heroTag;
  final QMatrixResizeHandle resizeHandle;

  const QMatrixSlotDef({
    this.scrollable = false,
    this.floating = false,
    this.preserveOverlap = false,
    this.draggable = false,
    this.resizable = false,
    this.reorderable = false,
    this.align = 'stretch',
    this.zIndex = 0,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.useHero = false,
    this.heroTag,
    this.resizeHandle = QMatrixResizeHandle.none,
  });

  Map<String, dynamic> toJson() => {
        'scrollable': scrollable,
        'floating': floating,
        'preserveOverlap': preserveOverlap,
        'draggable': draggable,
        'resizable': resizable,
        'reorderable': reorderable,
        'align': align,
        'zIndex': zIndex,
        'padding': {
          'l': padding.left,
          't': padding.top,
          'r': padding.right,
          'b': padding.bottom,
        },
        'margin': {
          'l': margin.left,
          't': margin.top,
          'r': margin.right,
          'b': margin.bottom,
        },
        'useHero': useHero,
        if (heroTag != null) 'heroTag': heroTag.toString(),
        'resizeHandle': resizeHandle.name,
      };
}

class _CompiledSlot {
  final int hash;
  final String name;
  final int rowStart;
  final int colStart;
  final int rowSpan;
  final int colSpan;
  final int zIndex;
  final int alignX; // 0 stretch, 1 start, 2 center, 3 end
  final bool scrollable; // ADD THIS LINE
  final bool floating;
  final bool preserveOverlap;
  final bool draggable;
  final bool resizable;
  final bool reorderable;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final bool useHero;
  final Object? heroTag;
  final QMatrixResizeHandle resizeHandle;

  const _CompiledSlot({
    required this.hash,
    required this.name,
    required this.rowStart,
    required this.colStart,
    required this.rowSpan,
    required this.colSpan,
    required this.zIndex,
    required this.alignX,
    required this.scrollable,
    required this.floating,
    required this.preserveOverlap,
    required this.draggable,
    required this.resizable,
    required this.reorderable,
    required this.padding,
    required this.margin,
    required this.useHero,
    required this.heroTag,
    required this.resizeHandle,
  });
}

class _CompiledMatrixData {
  final String id;
  final String colsSource;
  final String rowsSource;
  final List<QSize> cols;
  final List<QSize> rows;
  final double gap;
  final List<_CompiledSlot> slots;
  final Map<int, _CompiledSlot> byHash;
  final Map<String, _CompiledSlot> byName;

  const _CompiledMatrixData({
    required this.id,
    required this.colsSource,
    required this.rowsSource,
    required this.cols,
    required this.rows,
    required this.gap,
    required this.slots,
    required this.byHash,
    required this.byName,
  });

  _CompiledMatrixData overrideTracks({
    required String colsSource,
    required String rowsSource,
    required double gap,
  }) {
    return _CompiledMatrixData(
      id: '$id|override|${colsSource.hashCode}|${rowsSource.hashCode}|$gap',
      colsSource: colsSource,
      rowsSource: rowsSource,
      cols: QParser.parse(colsSource),
      rows: QParser.parse(rowsSource),
      gap: gap,
      slots: slots,
      byHash: byHash,
      byName: byName,
    );
  }

  _CompiledMatrixData withGap(double newGap) {
    return _CompiledMatrixData(
      id: '$id|gap:$newGap',
      colsSource: colsSource,
      rowsSource: rowsSource,
      cols: cols,
      rows: rows,
      gap: newGap,
      slots: slots,
      byHash: byHash,
      byName: byName,
    );
  }
}

class QMatrixLayoutDef {
  final Map<String, Map<String, _CompiledMatrixData>> breakpoints;
  final Map<String, Map<String, _CompiledMatrixData>> variants;
  final Map<String, QMatrixSlotDef> slotConfigs;

  const QMatrixLayoutDef(this.breakpoints, this.variants, this.slotConfigs);

  _CompiledMatrixData resolve(String variant, String breakpoint) {
    if (variant.isNotEmpty) {
      final v = variants[variant];
      if (v != null) {
        return v[breakpoint] ??
            v['default'] ??
            breakpoints['default']![breakpoint] ??
            breakpoints['default']!['default']!;
      }
    }
    return breakpoints['default']![breakpoint] ??
        breakpoints['default']!['default']!;
  }
}

abstract final class QMatrixLayoutRegistry {
  static final Map<String, QMatrixLayoutDef> _defs =
      <String, QMatrixLayoutDef>{};
  static final Map<String, Map<String, dynamic>> _defaultProps =
      <String, Map<String, dynamic>>{};
  static final Map<String, Map<String, dynamic>> _metadata =
      <String, Map<String, dynamic>>{};
  static final Map<String, LinkedHashMap<String, _CompiledMatrixData>>
      _runtimeCaches = <String, LinkedHashMap<String, _CompiledMatrixData>>{};
  static const int _runtimeCacheLimit = 256;
  static bool _coreRegistered = false;

  static bool has(String layoutId) => _defs.containsKey(layoutId);

  static QMatrixLayoutDef? get(String layoutId) => _defs[layoutId];

  static Map<String, dynamic> defaultProps(String layoutId) =>
      _defaultProps[layoutId] ?? const <String, dynamic>{};

  static LinkedHashMap<String, _CompiledMatrixData> runtimeCache(
          String layoutId) =>
      _runtimeCaches.putIfAbsent(
          layoutId, () => LinkedHashMap<String, _CompiledMatrixData>());

  static _CompiledMatrixData? cacheGet(
    Map<String, _CompiledMatrixData> cache,
    String key,
  ) {
    final _CompiledMatrixData? value = cache.remove(key);
    if (value != null) {
      cache[key] = value;
    }
    return value;
  }

  static _CompiledMatrixData cachePut(
    Map<String, _CompiledMatrixData> cache,
    String key,
    _CompiledMatrixData Function() factory,
  ) {
    final existing = cacheGet(cache, key);
    if (existing != null) return existing;
    final created = factory();
    cache[key] = created;
    if (cache.length > _runtimeCacheLimit) {
      cache.remove(cache.keys.first);
    }
    return created;
  }

  static Map<String, dynamic> _schemaForValue(dynamic value) {
    if (value == null) {
      return const <String, dynamic>{'type': 'dynamic', 'nullable': true};
    }
    if (value is bool) return const <String, dynamic>{'type': 'bool'};
    if (value is int) return const <String, dynamic>{'type': 'int'};
    if (value is double) return const <String, dynamic>{'type': 'double'};
    if (value is String) {
      return <String, dynamic>{'type': 'String', 'example': value};
    }
    if (value is List) {
      return <String, dynamic>{
        'type': 'List<dynamic>',
        'items': value.isEmpty
            ? const <String, dynamic>{'type': 'dynamic'}
            : _schemaForValue(value.first),
      };
    }
    if (value is Map) {
      return <String, dynamic>{
        'type': 'Map<String, dynamic>',
        'properties': {
          for (final entry in value.entries)
            entry.key.toString(): _schemaForValue(entry.value),
        },
      };
    }
    return <String, dynamic>{'type': value.runtimeType.toString()};
  }

  static Map<String, dynamic> _schemaForMap(Map<String, dynamic> map) =>
      <String, dynamic>{
        'type': 'object',
        'properties': {
          for (final entry in map.entries)
            entry.key: _schemaForValue(entry.value),
        },
        'required': map.keys.toList(growable: false),
      };

  static void register(
    String layoutId,
    QMatrixLayoutDef def, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
    String engine = 'QMatrixLayoutRegistry',
  }) {
    _defs[layoutId] = def;
    _runtimeCaches.remove(layoutId)?.clear();
    if (defaultProps.isNotEmpty) {
      _defaultProps[layoutId] = Map<String, dynamic>.unmodifiable(
          Map<String, dynamic>.from(defaultProps));
    } else {
      _defaultProps.remove(layoutId);
    }
    _metadata[layoutId] = {
      'description': description ?? '',
      'params': Map<String, dynamic>.from(params),
      'metadata': Map<String, dynamic>.from(metadata),
      'tags': List<String>.from(tags),
      'engine': engine,
      'paramSchema': _schemaForMap(params.isNotEmpty
          ? Map<String, dynamic>.from(params)
          : Map<String, dynamic>.from(defaultProps)),
      'infoSchema': <String, dynamic>{
        'name': layoutId,
        'kind': 'layout',
        'description': description ?? '',
        'engine': engine,
        'tags': List<String>.from(tags),
        'slotCount': def.slotConfigs.length,
        'variantNames': def.variants.keys.toList(growable: false),
      },
    };
  }

  static List<String> get registryNames =>
      List<String>.unmodifiable(_defs.keys);

  static Map<String, dynamic>? describe(String layoutId) {
    final def = _defs[layoutId];
    if (def == null) return null;
    final meta = _metadata[layoutId] ?? const <String, dynamic>{};
    final defaultProps = QMatrixLayoutRegistry.defaultProps(layoutId);
    return {
      'id': layoutId,
      'kind': 'layout',
      'name': layoutId,
      'description': meta['description'] ?? '',
      'engine': meta['engine'] ?? 'QMatrixLayoutRegistry',
      'tags': meta['tags'] ?? const [],
      'params': {
        'defaultProps': defaultProps,
        'slotCount': def.slotConfigs.length,
        'variants': def.variants.keys.toList(growable: false),
        'paramSchema': meta['paramSchema'] ?? _schemaForMap(defaultProps),
      },
      'metadata': meta,
      'infoSchema': meta['infoSchema'] ??
          {
            'name': layoutId,
            'kind': 'layout',
            'description': meta['description'] ?? '',
            'engine': meta['engine'] ?? 'QMatrixLayoutRegistry',
            'tags': meta['tags'] ?? const [],
            'slotCount': def.slotConfigs.length,
            'variantNames': def.variants.keys.toList(growable: false),
          },
      'slotConfigs': def.slotConfigs.map((k, v) => MapEntry(k, v.toJson())),
    };
  }

  static Map<String, dynamic> snapshot() => {
        'count': _defs.length,
        'items': _defs.keys
            .map((k) => describe(k))
            .whereType<Map<String, dynamic>>()
            .toList(growable: false),
      };
}

class QMatrixBuilder {
  String _defaultGrid = '';
  final Map<String, String> _breakpointGrids = <String, String>{};
  final Map<String, Map<String, String>> _variantGrids =
      <String, Map<String, String>>{};
  final Map<String, QMatrixSlotDef> _slotConfigs = <String, QMatrixSlotDef>{};
  double defaultGap = 0.0;

  void matrix(String asciiGrid) => _defaultGrid = asciiGrid;

  void breakpoint(String name, String asciiGrid) =>
      _breakpointGrids[name] = asciiGrid;

  void variant(String name, String asciiGrid) {
    _variantGrids.putIfAbsent(name, () => <String, String>{})['default'] =
        asciiGrid;
  }

  void variantBreakpoint(String name, String breakpoint, String asciiGrid) {
    _variantGrids.putIfAbsent(name, () => <String, String>{})[breakpoint] =
        asciiGrid;
  }

  void slot(
    String name, {
    bool scrollable = false,
    bool floating = false,
    bool preserveOverlap = false,
    bool draggable = false,
    bool resizable = false,
    bool reorderable = false,
    String align = 'stretch',
    int zIndex = 0,
    double padding = 0,
    double margin = 0,
    bool useHero = false,
    Object? heroTag,
    QMatrixResizeHandle resizeHandle = QMatrixResizeHandle.none,
  }) {
    _slotConfigs[name] = QMatrixSlotDef(
      scrollable: scrollable,
      floating: floating,
      preserveOverlap: preserveOverlap,
      draggable: draggable,
      resizable: resizable,
      reorderable: reorderable,
      align: align,
      zIndex: zIndex,
      padding: EdgeInsets.all(padding),
      margin: EdgeInsets.all(margin),
      useHero: useHero,
      heroTag: heroTag,
      resizeHandle: resizeHandle,
    );
  }

  _CompiledMatrixData _compile(String id, String gridStr) {
    final lines = gridStr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('//'))
        .toList(growable: false);

    if (lines.isEmpty) {
      return _CompiledMatrixData(
        id: id,
        colsSource: '1fr',
        rowsSource: 'auto',
        cols: QParser.parse('1fr'),
        rows: QParser.parse('auto'),
        gap: defaultGap,
        slots: const <_CompiledSlot>[],
        byHash: const <int, _CompiledSlot>{},
        byName: const <String, _CompiledSlot>{},
      );
    }

    final String colsSource = lines.first.replaceAll(RegExp(r'\s+'), ' ');
    final Map<String, List<int>> bounds = <String, List<int>>{};
    final List<String> rowDefs = <String>[];

    for (int r = 1; r < lines.length; r++) {
      final parts = lines[r].split('|');
      final columns = parts[0]
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList(growable: false);
      rowDefs.add(parts.length > 1 ? parts[1].trim() : 'auto');

      for (int c = 0; c < columns.length; c++) {
        final slot = columns[c];
        if (slot == '.') continue;

        final b = bounds.putIfAbsent(slot, () => <int>[r - 1, c, r - 1, c]);
        if (r - 1 < b[0]) b[0] = r - 1;
        if (c < b[1]) b[1] = c;
        if (r - 1 > b[2]) b[2] = r - 1;
        if (c > b[3]) b[3] = c;
      }
    }

    final List<_CompiledSlot> slots = <_CompiledSlot>[];
    final Map<int, _CompiledSlot> byHash = <int, _CompiledSlot>{};
    final Map<String, _CompiledSlot> byName = <String, _CompiledSlot>{};

    bounds.forEach((name, b) {
      final int hash = name.hashCode;
      final int rStart = b[0];
      final int cStart = b[1];
      final int rSpan = b[2] - b[0] + 1;
      final int cSpan = b[3] - b[1] + 1;
      final conf = _slotConfigs[name] ?? const QMatrixSlotDef();

      int alignX = 0;
      if (conf.align == 'start') alignX = 1;
      if (conf.align == 'center') alignX = 2;
      if (conf.align == 'end') alignX = 3;

      final slot = _CompiledSlot(
        hash: hash,
        name: name,
        rowStart: rStart,
        colStart: cStart,
        rowSpan: rSpan,
        colSpan: cSpan,
        zIndex: conf.zIndex,
        alignX: alignX,
        scrollable: conf.scrollable, // ADD THIS LINE
        floating: conf.floating,
        preserveOverlap: conf.preserveOverlap,
        draggable: conf.draggable,
        resizable: conf.resizable,
        reorderable: conf.reorderable,
        padding: conf.padding,
        margin: conf.margin,
        useHero: conf.useHero,
        heroTag: conf.heroTag,
        resizeHandle: conf.resizeHandle,
      );

      slots.add(slot);
      byHash[hash] = slot;
      byName[name] = slot;
    });

    return _CompiledMatrixData(
      id: id,
      colsSource: colsSource,
      rowsSource: rowDefs.isEmpty ? 'auto' : rowDefs.join(' '),
      cols: QParser.parse(colsSource),
      rows: QParser.parse(rowDefs.isEmpty ? 'auto' : rowDefs.join(' ')),
      gap: defaultGap,
      slots: List<_CompiledSlot>.unmodifiable(slots),
      byHash: Map<int, _CompiledSlot>.unmodifiable(byHash),
      byName: Map<String, _CompiledSlot>.unmodifiable(byName),
    );
  }

  QMatrixLayoutDef buildDef() {
    final Map<String, Map<String, _CompiledMatrixData>> breakpoints =
        <String, Map<String, _CompiledMatrixData>>{
      'default': <String, _CompiledMatrixData>{
        'default': _compile('default/default', _defaultGrid),
      },
    };

    for (final entry in _breakpointGrids.entries) {
      breakpoints['default']![entry.key] =
          _compile('default/${entry.key}', entry.value);
    }

    final Map<String, Map<String, _CompiledMatrixData>> variants =
        <String, Map<String, _CompiledMatrixData>>{};
    for (final entry in _variantGrids.entries) {
      final bpMap = <String, _CompiledMatrixData>{};
      for (final bpEntry in entry.value.entries) {
        bpMap[bpEntry.key] =
            _compile('${entry.key}/${bpEntry.key}', bpEntry.value);
      }
      variants[entry.key] = bpMap;
    }

    return QMatrixLayoutDef(breakpoints, variants, _slotConfigs);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Parent data
// ──────────────────────────────────────────────────────────────────────────────

class QuantumMatrixParentData extends ContainerBoxParentData<RenderBox> {
  String id = '';
  int hash = 0;
  int zIndex = 0;
  bool floating = false;
  bool preserveOverlap = false;
  bool isHidden = false;
  bool useHero = false;
  Object? heroTag;

  int slotIndex = -1;

  double targetX = 0;
  double targetY = 0;
  double targetW = 0;
  double targetH = 0;

  double paintX = 0;
  double paintY = 0;
  double paintW = 0;
  double paintH = 0;

  bool draggable = false;
  bool resizable = false;
  bool reorderable = false;
  QMatrixResizeHandle resizeHandle = QMatrixResizeHandle.none;
}

// ──────────────────────────────────────────────────────────────────────────────
// Widget bridge
// ──────────────────────────────────────────────────────────────────────────────

class QuantumMatrixNode extends MultiChildRenderObjectWidget {
  final _CompiledMatrixData matrixData;
  final QLSignal<double>? scrollSignal;
  final QMatrixInteractionController? interactionController;
  final Map<String, QMatrixSlotRuntimeOverride> runtimeOverrides;
  final List<String>? runtimeVisualOrder;
  final TextDirection? textDirection;
  final QMatrixSemanticsOrder semanticsOrder;
  final bool enableSemantics;
  final bool enableInteractivity;
  final bool enableRTL;

  const QuantumMatrixNode({
    super.key,
    required this.matrixData,
    this.scrollSignal,
    this.interactionController,
    this.runtimeOverrides = const <String, QMatrixSlotRuntimeOverride>{},
    this.runtimeVisualOrder,
    this.textDirection,
    this.semanticsOrder = QMatrixSemanticsOrder.visual,
    this.enableSemantics = true,
    this.enableInteractivity = true,
    this.enableRTL = true,
    required super.children,
  });

  @override
  RenderQuantumMatrix createRenderObject(BuildContext context) {
    return RenderQuantumMatrix(
      matrixData: matrixData,
      scrollSignal: scrollSignal,
      interactionController: interactionController,
      runtimeOverrides: runtimeOverrides,
      runtimeVisualOrder: runtimeVisualOrder,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      semanticsOrder: semanticsOrder,
      enableSemantics: enableSemantics,
      enableRTL: enableRTL,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderQuantumMatrix renderObject) {
    renderObject
      ..matrixData = matrixData
      ..scrollSignal = scrollSignal
      ..interactionController = interactionController
      ..runtimeOverrides = runtimeOverrides
      ..runtimeVisualOrder = runtimeVisualOrder
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..semanticsOrder = semanticsOrder
      ..enableSemantics = enableSemantics
      ..enableRTL = enableRTL;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Fast render object
// ──────────────────────────────────────────────────────────────────────────────

class RenderQuantumMatrix extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, QuantumMatrixParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, QuantumMatrixParentData>,
        QLReactiveRenderMixin {
  _CompiledMatrixData _matrixData;
  QLSignal<double>? _scrollSignal;
  QMatrixInteractionController? _interactionController;
  Map<String, QMatrixSlotRuntimeOverride> _runtimeOverrides;
  List<String>? _runtimeVisualOrder;
  TextDirection? _textDirection;
  QMatrixSemanticsOrder _semanticsOrder;
  bool _enableSemantics;
  bool _enableRTL;

  late final Ticker _ticker;
  bool _tickerStarted = false;
  bool _isMorphing = false;
  Duration? _lastElapsed;

  Float64List _currentBounds = Float64List(0);
  Float64List _velocities = Float64List(0);

  Float64List _colWidths = Float64List(0);
  Float64List _colOffsets = Float64List(0);
  Float64List _rowHeights = Float64List(0);
  Float64List _rowOffsets = Float64List(0);

  int _childCount = 0;
  final List<RenderBox> _paintOrder = <RenderBox>[];
  final List<QuantumMatrixParentData> _paintData = <QuantumMatrixParentData>[];

  RenderQuantumMatrix({
    required _CompiledMatrixData matrixData,
    QLSignal<double>? scrollSignal,
    QMatrixInteractionController? interactionController,
    Map<String, QMatrixSlotRuntimeOverride> runtimeOverrides =
        const <String, QMatrixSlotRuntimeOverride>{},
    List<String>? runtimeVisualOrder,
    TextDirection? textDirection,
    QMatrixSemanticsOrder semanticsOrder = QMatrixSemanticsOrder.visual,
    bool enableSemantics = true,
    bool enableRTL = true,
  })  : _matrixData = matrixData,
        _scrollSignal = scrollSignal,
        _interactionController = interactionController,
        _runtimeOverrides =
            Map<String, QMatrixSlotRuntimeOverride>.from(runtimeOverrides),
        _runtimeVisualOrder = runtimeVisualOrder == null
            ? null
            : List<String>.from(runtimeVisualOrder, growable: false),
        _textDirection = textDirection,
        _semanticsOrder = semanticsOrder,
        _enableSemantics = enableSemantics,
        _enableRTL = enableRTL {
    _ticker = Ticker(_onTick);
    if (_scrollSignal != null) {
      watchPaint(_scrollSignal);
    }
    _interactionController?.addListener(_onInteractionChanged);
  }

  set matrixData(_CompiledMatrixData val) {
    if (identical(_matrixData, val)) return;
    _matrixData = val;
    markNeedsLayout();
  }

  set scrollSignal(QLSignal<double>? val) {
    if (_scrollSignal == val) return;
    _scrollSignal = val;
    watchPaint(_scrollSignal);
    markNeedsPaint();
  }

  set interactionController(QMatrixInteractionController? val) {
    if (_interactionController == val) return;
    _interactionController?.removeListener(_onInteractionChanged);
    _interactionController = val;
    _interactionController?.addListener(_onInteractionChanged);
    markNeedsLayout();
  }

  set runtimeOverrides(Map<String, QMatrixSlotRuntimeOverride> val) {
    if (mapEquals(_runtimeOverrides, val)) return;
    _runtimeOverrides = Map<String, QMatrixSlotRuntimeOverride>.from(val);
    markNeedsLayout();
  }

  set runtimeVisualOrder(List<String>? val) {
    if (listEquals(_runtimeVisualOrder, val)) return;
    _runtimeVisualOrder =
        val == null ? null : List<String>.from(val, growable: false);
    markNeedsLayout();
  }

  set textDirection(TextDirection? val) {
    if (_textDirection == val) return;
    _textDirection = val;
    markNeedsLayout();
  }

  set semanticsOrder(QMatrixSemanticsOrder val) {
    if (_semanticsOrder == val) return;
    _semanticsOrder = val;
    markNeedsSemanticsUpdate();
  }

  set enableSemantics(bool val) {
    if (_enableSemantics == val) return;
    _enableSemantics = val;
    markNeedsSemanticsUpdate();
  }

  set enableRTL(bool val) {
    if (_enableRTL == val) return;
    _enableRTL = val;
    markNeedsLayout();
  }

  void _onInteractionChanged() {
    markNeedsLayout();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (!_tickerStarted) {
      _tickerStarted = true;
    }
  }

  @override
  void detach() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _lastElapsed = null;
    super.detach();
  }

  @override
  void dispose() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _interactionController?.removeListener(_onInteractionChanged);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! QuantumMatrixParentData) {
      child.parentData = QuantumMatrixParentData();
    }
  }

  bool get _isRtl =>
      _enableRTL && (_textDirection ?? TextDirection.ltr) == TextDirection.rtl;

  void _ensureTrackBuffers(int cols, int rows) {
    if (_colWidths.length < cols) {
      _colWidths = Float64List(cols);
      _colOffsets = Float64List(cols + 1);
    }
    if (_rowHeights.length < rows) {
      _rowHeights = Float64List(rows);
      _rowOffsets = Float64List(rows + 1);
    }
  }

  void _ensureChildBuffers(int childCount) {
    if (_currentBounds.length < childCount * 4) {
      _currentBounds = Float64List(childCount * 4);
      _velocities = Float64List(childCount * 4);
    }
  }

  void _solve1D(
    List<QSize> tracks,
    double avail,
    double gap,
    Float64List sizes,
    Float64List offsets,
  ) {
    final int n = tracks.length;
    if (n == 0) {
      if (offsets.isNotEmpty) offsets[0] = 0.0;
      return;
    }

    double usedFixed = 0.0;
    double totalFr = 0.0;

    for (int i = 0; i < n; i++) {
      final t = tracks[i];
      if (t is QFixed) {
        sizes[i] = t.px;
        usedFixed += t.px;
      } else if (t is QFraction) {
        totalFr += t.fr;
      } else {
        sizes[i] = 40.0;
        usedFixed += 40.0;
      }
    }

    final remaining =
        math.max(0.0, avail - usedFixed - (math.max(0, n - 1) * gap));
    if (totalFr > 0.0 && remaining > 0.0) {
      final unit = remaining / totalFr;
      for (int i = 0; i < n; i++) {
        final t = tracks[i];
        if (t is QFraction) {
          sizes[i] = t.fr * unit;
        }
      }
    }

    double acc = 0.0;
    for (int i = 0; i < n; i++) {
      offsets[i] = acc;
      acc += sizes[i] + gap;
    }
    offsets[n] = acc;
  }

  void _resolveTracks(double availW, double availH) {
    _ensureTrackBuffers(_matrixData.cols.length, _matrixData.rows.length);
    _solve1D(
        _matrixData.cols, availW, _matrixData.gap, _colWidths, _colOffsets);
    _solve1D(
        _matrixData.rows, availH, _matrixData.gap, _rowHeights, _rowOffsets);
  }

  int _countChildren() {
    int count = 0;
    RenderBox? child = firstChild;
    while (child != null) {
      count++;
      child = childAfter(child);
    }
    return count;
  }

  _CompiledSlot? _resolveSlot(QuantumMatrixParentData pd) {
    final ctrl = _interactionController;
    if (pd.id.isNotEmpty) {
      final byName = _matrixData.byName[pd.id];
      if (byName != null) return byName;
    }
    if (pd.hash != 0) {
      final byHash = _matrixData.byHash[pd.hash];
      if (byHash != null) return byHash;
    }
    if (pd.id.isNotEmpty) {
      final override = _runtimeOverrides[pd.id] ?? ctrl?.overrideFor(pd.id);
      if (override != null) {
        final base = _matrixData.byName[pd.id];
        if (base != null) {
          final rowStart = override.rowStart ?? base.rowStart;
          final colStart = override.colStart ?? base.colStart;
          final rowSpan = override.rowSpan ?? base.rowSpan;
          final colSpan = override.colSpan ?? base.colSpan;
          return _CompiledSlot(
            hash: base.hash,
            name: base.name,
            rowStart: rowStart,
            colStart: colStart,
            rowSpan: rowSpan,
            colSpan: colSpan,
            zIndex: override.zIndex ?? base.zIndex,
            alignX: base.alignX,
            scrollable: base.scrollable,
            floating: base.floating,
            preserveOverlap: base.preserveOverlap,
            draggable: base.draggable,
            resizable: base.resizable,
            reorderable: base.reorderable,
            padding: base.padding,
            margin: base.margin,
            useHero: base.useHero,
            heroTag: base.heroTag,
            resizeHandle: base.resizeHandle,
          );
        }
      }
    }
    return null;
  }

  static BoxConstraints _childConstraintsForSlot({
    required double w,
    required double h,
    required _CompiledSlot slot,
    required Size? resizedSize,
  }) {
    final double baseW = resizedSize?.width ??
        math.max(0.0, w - slot.padding.horizontal - slot.margin.horizontal);
    final double baseH = resizedSize?.height ??
        math.max(0.0, h - slot.padding.vertical - slot.margin.vertical);

    if (slot.alignX == 0) {
      return BoxConstraints.tightFor(
        width: math.max(0.0, baseW),
        height: math.max(0.0, baseH),
      );
    }

    return BoxConstraints(
      minWidth: 0,
      maxWidth: math.max(0.0, baseW),
      minHeight: 0,
      maxHeight: math.max(0.0, baseH),
    );
  }

  static Offset _alignedOffset({
    required _CompiledSlot slot,
    required double slotX,
    required double slotY,
    required double slotW,
    required double slotH,
    required Size childSize,
  }) {
    final innerX = slotX + slot.margin.left + slot.padding.left;
    final innerY = slotY + slot.margin.top + slot.padding.top;
    final innerW =
        math.max(0.0, slotW - slot.padding.horizontal - slot.margin.horizontal);
    final innerH =
        math.max(0.0, slotH - slot.padding.vertical - slot.margin.vertical);

    double dx = innerX;
    double dy = innerY;

    if (slot.alignX == 2) {
      dx = innerX + math.max(0.0, (innerW - childSize.width) * 0.5);
    } else if (slot.alignX == 3) {
      dx = innerX + math.max(0.0, innerW - childSize.width);
    }

    if (slot.alignX == 2) {
      dy = innerY + math.max(0.0, (innerH - childSize.height) * 0.5);
    } else if (slot.alignX == 3) {
      dy = innerY + math.max(0.0, innerH - childSize.height);
    }

    return Offset(dx, dy);
  }

  static List<_PaintEntry> _sortedPaintEntries(
    List<RenderBox> children,
    List<QuantumMatrixParentData> data,
  ) {
    final combined = List<_PaintEntry>.generate(
      children.length,
      (i) => _PaintEntry(children[i], data[i]),
      growable: false,
    )..sort((a, b) {
        final za = a.data.zIndex;
        final zb = b.data.zIndex;
        if (za != zb) return za.compareTo(zb);
        return a.data.hash.compareTo(b.data.hash);
      });
    return combined;
  }

  List<RenderBox> _applyVisualOrder(
    List<RenderBox> children,
    List<QuantumMatrixParentData> data,
  ) {
    final ctrl = _interactionController;
    final order = _runtimeVisualOrder ?? ctrl?.visualOrder;
    if (order == null || order.isEmpty) return children;

    final Map<String, _PaintEntry> byName = <String, _PaintEntry>{};
    for (int i = 0; i < children.length; i++) {
      byName[data[i].id] = _PaintEntry(children[i], data[i]);
    }

    final List<RenderBox> ordered = <RenderBox>[];
    final List<QuantumMatrixParentData> orderedData =
        <QuantumMatrixParentData>[];

    for (final name in order) {
      final entry = byName.remove(name);
      if (entry != null) {
        ordered.add(entry.child);
        orderedData.add(entry.data);
      }
    }

    for (final entry in byName.values) {
      ordered.add(entry.child);
      orderedData.add(entry.data);
    }

    _paintOrder
      ..clear()
      ..addAll(ordered);
    _paintData
      ..clear()
      ..addAll(orderedData);

    return ordered;
  }

  @override
  void performLayout() {
    final double availW =
        constraints.maxWidth.isFinite ? constraints.maxWidth : 1200.0;
    final double availH =
        constraints.maxHeight.isFinite ? constraints.maxHeight : 1000.0;

    _resolveTracks(availW, availH);

    _childCount = _countChildren();
    _ensureChildBuffers(_childCount);

    _paintOrder
      ..clear()
      ..length = 0;
    _paintData
      ..clear()
      ..length = 0;

    double maxTotalW = 0.0;
    double maxTotalH = 0.0;
    bool needsMorph = false;

    RenderBox? child = firstChild;
    int childIdx = 0;
    while (child != null) {
      final pd = child.parentData as QuantumMatrixParentData;
      final slot = _resolveSlot(pd);

      if (slot == null) {
        pd.isHidden = true;
        pd.slotIndex = -1;
        pd.paintX = 0.0;
        pd.paintY = 0.0;
        pd.paintW = 0.0;
        pd.paintH = 0.0;
        child.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        child = childAfter(child);
        childIdx++;
        continue;
      }

      final ctrl = _interactionController;
      final override = _runtimeOverrides[pd.id] ?? ctrl?.overrideFor(slot.name);

      pd.isHidden = override?.hidden == true;
      pd.id = slot.name;
      pd.hash = slot.hash;
      pd.zIndex = override?.zIndex ?? slot.zIndex;
      pd.floating = slot.floating;
      pd.preserveOverlap = slot.preserveOverlap;
      pd.useHero = slot.useHero;
      pd.heroTag = slot.heroTag;
      pd.slotIndex = childIdx;
      pd.draggable = slot.draggable;
      pd.resizable = slot.resizable;
      pd.reorderable = slot.reorderable;
      pd.resizeHandle = slot.resizeHandle;

      if (pd.isHidden) {
        child.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        child = childAfter(child);
        childIdx++;
        continue;
      }

      final int rowStart = override?.rowStart ?? slot.rowStart;
      final int colStart = override?.colStart ?? slot.colStart;
      final int rowSpan = override?.rowSpan ?? slot.rowSpan;
      final int colSpan = override?.colSpan ?? slot.colSpan;

      final double slotX = _colOffsets[colStart];
      final double slotY = _rowOffsets[rowStart];
      final double slotW = math.max(
          0.0, _colOffsets[colStart + colSpan] - _matrixData.gap - slotX);
      final double slotH = math.max(
          0.0, _rowOffsets[rowStart + rowSpan] - _matrixData.gap - slotY);

      pd.targetX = slotX;
      pd.targetY = slotY;
      pd.targetW = slotW;
      pd.targetH = slotH;

      final Size? resizedSize = override?.pixelSize;
      final childConstraints = _childConstraintsForSlot(
        w: slotW,
        h: slotH,
        slot: slot,
        resizedSize: resizedSize,
      );
      child.layout(childConstraints, parentUsesSize: true);

      final childSize = resizedSize ?? child.size;
      final Offset paintOffset = _alignedOffset(
        slot: slot,
        slotX: slotX,
        slotY: slotY,
        slotW: slotW,
        slotH: slotH,
        childSize: childSize,
      );

      pd.paintX = paintOffset.dx;
      pd.paintY = paintOffset.dy;
      pd.paintW = childSize.width;
      pd.paintH = childSize.height;

      final int base = childIdx * 4;
      final bool initialized =
          _currentBounds[base + 2] != 0.0 || _currentBounds[base + 3] != 0.0;
      if (!initialized) {
        _currentBounds[base + 0] = pd.paintX;
        _currentBounds[base + 1] = pd.paintY;
        _currentBounds[base + 2] = pd.paintW;
        _currentBounds[base + 3] = pd.paintH;
      } else if ((_currentBounds[base + 0] - pd.paintX).abs() > 0.5 ||
          (_currentBounds[base + 1] - pd.paintY).abs() > 0.5 ||
          (_currentBounds[base + 2] - pd.paintW).abs() > 0.5 ||
          (_currentBounds[base + 3] - pd.paintH).abs() > 0.5) {
        needsMorph = true;
      }

      if (pd.paintX + pd.paintW > maxTotalW) maxTotalW = pd.paintX + pd.paintW;
      if (pd.paintY + pd.paintH > maxTotalH) maxTotalH = pd.paintY + pd.paintH;

      _paintOrder.add(child);
      _paintData.add(pd);

      child = childAfter(child);
      childIdx++;
    }

    if (_paintOrder.length > 1) {
      final combined = _sortedPaintEntries(_paintOrder, _paintData);
      _paintOrder
        ..clear()
        ..addAll(combined.map((e) => e.child));
      _paintData
        ..clear()
        ..addAll(combined.map((e) => e.data));
    }

    _applyVisualOrder(_paintOrder, _paintData);

    size = constraints.constrain(Size(maxTotalW, maxTotalH));

    if (needsMorph && !_isMorphing) {
      _isMorphing = true;
      _lastElapsed = Duration.zero;
      if (!_ticker.isActive) {
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (_childCount == 0) {
      if (_ticker.isActive) _ticker.stop();
      _isMorphing = false;
      _lastElapsed = elapsed;
      return;
    }

    final Duration prev = _lastElapsed ?? elapsed;
    final double dt =
        math.min((elapsed - prev).inMicroseconds / 1000000.0, 0.032);
    _lastElapsed = elapsed;

    const double stiffness = 450.0;
    const double damping = 32.0;
    bool stillMoving = false;

    RenderBox? child = firstChild;
    int childIdx = 0;

    while (child != null) {
      final pd = child.parentData as QuantumMatrixParentData;
      if (!pd.isHidden) {
        final int base = childIdx * 4;

        final double tx = pd.paintX;
        final double ty = pd.paintY;
        final double tw = pd.paintW;
        final double th = pd.paintH;

        final double currentX = _currentBounds[base + 0];
        final double currentY = _currentBounds[base + 1];
        final double currentW = _currentBounds[base + 2];
        final double currentH = _currentBounds[base + 3];

        final double dx = tx - currentX;
        final double dy = ty - currentY;
        final double dw = tw - currentW;
        final double dh = th - currentH;

        double vx = _velocities[base + 0];
        double vy = _velocities[base + 1];
        double vw = _velocities[base + 2];
        double vh = _velocities[base + 3];

        if (dx.abs() > 0.5 ||
            dy.abs() > 0.5 ||
            dw.abs() > 0.5 ||
            dh.abs() > 0.5 ||
            vx.abs() > 0.5 ||
            vy.abs() > 0.5 ||
            vw.abs() > 0.5 ||
            vh.abs() > 0.5) {
          stillMoving = true;

          vx += (stiffness * dx - damping * vx) * dt;
          vy += (stiffness * dy - damping * vy) * dt;
          vw += (stiffness * dw - damping * vw) * dt;
          vh += (stiffness * dh - damping * vh) * dt;

          _currentBounds[base + 0] = currentX + vx * dt;
          _currentBounds[base + 1] = currentY + vy * dt;
          _currentBounds[base + 2] = currentW + vw * dt;
          _currentBounds[base + 3] = currentH + vh * dt;

          _velocities[base + 0] = vx;
          _velocities[base + 1] = vy;
          _velocities[base + 2] = vw;
          _velocities[base + 3] = vh;
        } else {
          _currentBounds[base + 0] = tx;
          _currentBounds[base + 1] = ty;
          _currentBounds[base + 2] = tw;
          _currentBounds[base + 3] = th;
          _velocities[base + 0] = 0.0;
          _velocities[base + 1] = 0.0;
          _velocities[base + 2] = 0.0;
          _velocities[base + 3] = 0.0;
        }
      }

      child = childAfter(child);
      childIdx++;
    }

    if (!stillMoving) {
      _isMorphing = false;
      if (_ticker.isActive) _ticker.stop();
    }

    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_childCount == 0) return;

    final double scrollY = _scrollSignal?.value ?? 0.0;
    final double viewportH = constraints.maxHeight;
    final bool hasViewportClip = viewportH.isFinite && viewportH > 0.0;
    final double containerWidth = size.width;

    for (int i = 0; i < _paintOrder.length; i++) {
      final child = _paintOrder[i];
      final pd = _paintData[i];
      if (pd.isHidden) continue;

      final int base = pd.slotIndex * 4;
      final double x = _currentBounds[base + 0];
      final double y = _currentBounds[base + 1];
      final double w = _currentBounds[base + 2];
      final double h = _currentBounds[base + 3];

      if (hasViewportClip && !pd.preserveOverlap) {
        if (y > scrollY + viewportH || (y + h) < scrollY) {
          continue;
        }
      }

      final double drawX = _isRtl ? containerWidth - (x + w) : x;
      context.paintChild(child, offset + Offset(drawX, y - scrollY));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final double scrollY = _scrollSignal?.value ?? 0.0;
    final double containerWidth = size.width;

    for (int i = _paintOrder.length - 1; i >= 0; i--) {
      final child = _paintOrder[i];
      final pd = _paintData[i];
      if (pd.isHidden) continue;

      final int base = pd.slotIndex * 4;
      final double x = _currentBounds[base + 0];
      final double y = _currentBounds[base + 1];
      final double w = _currentBounds[base + 2];
      final double h = _currentBounds[base + 3];

      if (!pd.preserveOverlap) {
        final double viewportH = constraints.maxHeight;
        if (viewportH.isFinite && viewportH > 0.0) {
          if (y > scrollY + viewportH || (y + h) < scrollY) {
            continue;
          }
        }
      }

      final double drawX = _isRtl ? containerWidth - (x + w) : x;

      final bool isHit = result.addWithPaintOffset(
        offset: Offset(drawX, y - scrollY),
        position: position,
        hitTest: (r, p) => child.hitTest(r, position: p),
      );
      if (isHit) return true;
    }
    return false;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    config.isMergingSemanticsOfDescendants = false;
  }

  @override
  void visitChildrenForSemantics(RenderObjectVisitor visitor) {
    if (!_enableSemantics || _semanticsOrder == QMatrixSemanticsOrder.none) {
      super.visitChildrenForSemantics(visitor);
      return;
    }

    final List<_PaintEntry> entries = <_PaintEntry>[];
    for (int i = 0; i < _paintOrder.length; i++) {
      final child = _paintOrder[i];
      final pd = _paintData[i];
      if (pd.isHidden) continue;
      entries.add(_PaintEntry(child, pd));
    }

    if (_semanticsOrder == QMatrixSemanticsOrder.logical) {
      entries.sort((a, b) => a.data.slotIndex.compareTo(b.data.slotIndex));
    }

    for (final entry in entries) {
      visitor(entry.child);
    }
  }
}

class _PaintEntry {
  final RenderBox child;
  final QuantumMatrixParentData data;
  _PaintEntry(this.child, this.data);
}

// ──────────────────────────────────────────────────────────────────────────────
// SDUI integration
// ──────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

Map<String, QMatrixSlotRuntimeOverride> _parseMatrixSlotOverrides(dynamic raw) {
  final Map<String, QMatrixSlotRuntimeOverride> out =
      <String, QMatrixSlotRuntimeOverride>{};

  if (raw is List) {
    for (final entry in raw) {
      if (entry is String && entry.trim().isNotEmpty) {
        out[entry.trim()] = const QMatrixSlotRuntimeOverride(hidden: true);
      } else if (entry is Map) {
        final map = _asStringKeyedMap(entry);
        final name =
            (map['slot'] ?? map['name'] ?? map['id'] ?? '').toString().trim();
        if (name.isNotEmpty) {
          out[name] = QMatrixSlotRuntimeOverride.fromJson(map);
        }
      }
    }
    return out;
  }

  if (raw is Map) {
    raw.forEach((key, value) {
      final String name = key.toString().trim();
      if (name.isEmpty) return;
      if (value is QMatrixSlotRuntimeOverride) {
        out[name] = value;
      } else if (value is Map) {
        out[name] =
            QMatrixSlotRuntimeOverride.fromJson(_asStringKeyedMap(value));
      } else if (value is bool) {
        out[name] = QMatrixSlotRuntimeOverride(hidden: value);
      } else if (value == null) {
        return;
      } else {
        out[name] = QMatrixSlotRuntimeOverride.fromJson(<String, dynamic>{
          'hidden': value == 'hidden',
        });
      }
    });
  }

  return out;
}

List<String>? _parseMatrixVisualOrder(dynamic raw) {
  if (raw == null) return null;
  if (raw is List) {
    final values = raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return values.isEmpty ? null : values;
  }
  if (raw is String) {
    final values = raw
        .split(RegExp(r'[,:|\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return values.isEmpty ? null : values;
  }
  return null;
}

QMatrixInteractionController _resolveMatrixController(
  QLDataStore store, {
  String key = '',
  QMatrixInteractionController? fallback,
}) {
  final String signalKey =
      key.isEmpty ? 'system.matrixController' : 'system.matrixController.$key';
  final signal = store.signal(signalKey);
  final current = signal.value;
  if (current is QMatrixInteractionController) return current;
  final controller = fallback ?? QMatrixInteractionController();
  signal.value = controller;
  return controller;
}

Widget buildQuantumMatrixWidget({
  required BuildContext ctx,
  required QLBlueprint node,
  required QLDataStore store,
  required QMatrixLayoutDef layoutDef,
  required Map<String, _CompiledMatrixData> runtimeCache,
}) {
  String breakpointForWidth(double w) {
    final defaultBreakpoints = layoutDef.breakpoints['default'];
    if (defaultBreakpoints == null) return 'default';
    if (w >= 1280 && defaultBreakpoints.containsKey('xl')) {
      return 'xl';
    }
    if (w >= 1024 && defaultBreakpoints.containsKey('lg')) {
      return 'lg';
    }
    if (w >= 768 && defaultBreakpoints.containsKey('md')) {
      return 'md';
    }
    if (w >= 640 && defaultBreakpoints.containsKey('sm')) {
      return 'sm';
    }
    return 'default';
  }

  _CompiledMatrixData runtimeOverride({
    required _CompiledMatrixData base,
    required String cols,
    required String rows,
  }) {
    final String key =
        '${base.id}|${cols.hashCode}|${rows.hashCode}|${base.gap}';
    final cached = QMatrixLayoutRegistry.cacheGet(runtimeCache, key);
    if (cached != null) return cached;
    return QMatrixLayoutRegistry.cachePut(runtimeCache, key, () {
      return base.overrideTracks(
        colsSource: cols,
        rowsSource: rows,
        gap: base.gap,
      );
    });
  }

  Widget wrapAccessibilityAndInteraction({
    required BuildContext ctx,
    required String slotName,
    required Widget child,
    required _CompiledSlot slot,
    required QMatrixSemanticsOrder semanticsOrder,
    required int semanticIndex,
    required QMatrixInteractionController? controller,
  }) {
    Widget current = child;

    if (controller != null &&
        (slot.draggable || slot.resizable || slot.reorderable)) {
      current = _MatrixInteractiveShell(
        slotName: slotName,
        controller: controller,
        draggable: slot.draggable,
        resizable: slot.resizable,
        reorderable: slot.reorderable,
        resizeHandle: slot.resizeHandle,
        child: current,
      );
    }

    if (semanticsOrder != QMatrixSemanticsOrder.none) {
      current = Semantics(
        container: true,
        sortKey: OrdinalSortKey(semanticIndex.toDouble()),
        child: current,
      );
    }

    if (slot.useHero && slot.heroTag != null) {
      current = Hero(tag: slot.heroTag!, child: current);
    }

    return current;
  }

  TextDirection resolveTextDirection(BuildContext ctx, bool enableRTL) {
    if (!enableRTL) {
      return TextDirection.ltr;
    }
    return Directionality.maybeOf(ctx) ?? TextDirection.ltr;
  }

  return LayoutBuilder(
    builder: (layoutContext, constraints) {
      final Map<String, dynamic> rawEnv =
          _asStringKeyedMap(QLDataScope.ofNode(layoutContext)?.localData);
      final String layoutId = (node.props['layoutId'] ??
              node.props['layout'] ??
              node.props['id'] ??
              node.props['__subType'] ??
              '')
          .toString();
      final String variant = QLDataBinder.resolveAOT(
                  node.props['variant'], layoutContext, rawEnv, store)
              ?.toString() ??
          '';

      final Map<String, dynamic> nodeProps = _asStringKeyedMap(node.props);
      final Map<String, dynamic> resolvedOverrides = _asStringKeyedMap(
        QLDataBinder.resolveAOT(
          nodeProps['overrides'],
          layoutContext,
          rawEnv,
          store,
        ),
      );

      final Map<String, dynamic> sharedData = <String, dynamic>{}
        ..addAll(_asStringKeyedMap(resolvedOverrides['sharedData'] ??
            resolvedOverrides['layoutData'] ??
            nodeProps['sharedData'] ??
            nodeProps['layoutData']))
        ..addAll(_asStringKeyedMap(nodeProps['shared']))
        ..addAll(_asStringKeyedMap(nodeProps['scopeData']));

      final String controllerKey = (resolvedOverrides['controllerKey'] ??
              nodeProps['controllerKey'] ??
              nodeProps['layoutControllerKey'] ??
              '')
          .toString()
          .trim();
      final String layoutStateKey = (resolvedOverrides['stateKey'] ??
              resolvedOverrides['layoutStateKey'] ??
              nodeProps['stateKey'] ??
              nodeProps['layoutStateKey'] ??
              '')
          .toString()
          .trim();
      final String sharedKey = (resolvedOverrides['sharedKey'] ??
              resolvedOverrides['layoutScopeKey'] ??
              nodeProps['sharedKey'] ??
              nodeProps['layoutScopeKey'] ??
              layoutId)
          .toString()
          .trim();

      final QMatrixInteractionController? suppliedController =
          resolvedOverrides['controller'] is QMatrixInteractionController
              ? resolvedOverrides['controller'] as QMatrixInteractionController
              : nodeProps['controller'] is QMatrixInteractionController
                  ? nodeProps['controller'] as QMatrixInteractionController
                  : null;
      final QMatrixInteractionController interactionController =
          _resolveMatrixController(
        store,
        key: controllerKey.isNotEmpty ? controllerKey : sharedKey,
        fallback: suppliedController,
      );

      final QLSignal<dynamic>? layoutStateSignal = layoutStateKey.isNotEmpty
          ? store.signal('layout.state.$layoutStateKey')
          : null;
      final dynamic initialState = resolvedOverrides['state'] ??
          resolvedOverrides['layoutState'] ??
          nodeProps['state'] ??
          nodeProps['layoutState'];
      if (layoutStateSignal != null &&
          layoutStateSignal.value == null &&
          initialState != null) {
        layoutStateSignal.value = initialState;
      }

      final Map<String, dynamic> layoutEnv = <String, dynamic>{
        ...rawEnv,
        ...sharedData,
        '__layoutId': layoutId,
        '__layoutVariant': variant,
        '__layoutScopeKey': sharedKey,
        '__layoutStateKey': layoutStateKey,
        '__layoutState': layoutStateSignal?.value,
        '__layoutStateSignal': layoutStateSignal,
        '__layoutController': interactionController,
        '__layoutSharedData': sharedData,
      };

      final QLContext qlCtx = QLContext(layoutContext, node, layoutEnv, store);

      final double width =
          constraints.hasBoundedWidth && constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(layoutContext).width;
      final String bp = breakpointForWidth(width);
      final _CompiledMatrixData compiled = layoutDef.resolve(variant, bp);

      final Map<String, QMatrixSlotRuntimeOverride> runtimeOverrides = <String,
          QMatrixSlotRuntimeOverride>{}
        ..addAll(_parseMatrixSlotOverrides(
            resolvedOverrides['slotOverrides'] ?? resolvedOverrides['slots']))
        ..addAll(_parseMatrixSlotOverrides(
            nodeProps['slotOverrides'] ?? nodeProps['slotStates']));

      final List<String>? runtimeVisualOrder = _parseMatrixVisualOrder(
        resolvedOverrides['slotOrder'] ??
            resolvedOverrides['visualOrder'] ??
            nodeProps['slotOrder'] ??
            nodeProps['visualOrder'],
      );

      final Map<String, dynamic> layoutOverrides = _asStringKeyedMap(
        resolvedOverrides['layoutOverrides'] ?? nodeProps['layoutOverrides'],
      );

      final bool enableSemantics = (layoutOverrides['enableSemantics'] ??
              node.props['enableSemantics']) !=
          false;
      final bool enableInteractivity =
          (layoutOverrides['enableInteractivity'] ??
                  node.props['enableInteractivity']) !=
              false;
      final bool enableRTL =
          (layoutOverrides['enableRTL'] ?? node.props['enableRTL']) != false;

      final dynamic semanticsModeProp =
          layoutOverrides['semanticsOrder'] ?? node.props['semanticsOrder'];
      final QMatrixSemanticsOrder semanticsOrder =
          semanticsModeProp == 'logical'
              ? QMatrixSemanticsOrder.logical
              : semanticsModeProp == 'none'
                  ? QMatrixSemanticsOrder.none
                  : QMatrixSemanticsOrder.visual;

      final List<Widget> children = <Widget>[];
      final List<MapEntry<String, QMatrixSlotDef>> orderedSlots =
          layoutDef.slotConfigs.entries.toList(growable: false);

      for (int i = 0; i < orderedSlots.length; i++) {
        final String slotName = orderedSlots[i].key;
        final QMatrixSlotDef config = orderedSlots[i].value;
        final _CompiledSlot slot = compiled.byName[slotName] ??
            _CompiledSlot(
              hash: slotName.hashCode,
              name: slotName,
              rowStart: 0,
              colStart: 0,
              rowSpan: 1,
              colSpan: 1,
              zIndex: config.zIndex,
              alignX: 0,
              scrollable: config.scrollable,
              floating: config.floating,
              preserveOverlap: config.preserveOverlap,
              draggable: config.draggable,
              resizable: config.resizable,
              reorderable: config.reorderable,
              padding: config.padding,
              margin: config.margin,
              useHero: config.useHero,
              heroTag: config.heroTag,
              resizeHandle: config.resizeHandle,
            );

        final Widget? rawChild = qlCtx.slot(slotName);
        if (rawChild == null) continue;

        Widget childWidget = rawChild;
        if (slot.margin != EdgeInsets.zero || slot.padding != EdgeInsets.zero) {
          childWidget = Padding(
            padding: slot.margin,
            child: Padding(
              padding: slot.padding,
              child: childWidget,
            ),
          );
        }
        if (slot.scrollable) {
          childWidget = QuantumFlexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              primary: false,
              child: childWidget,
            ),
          );
        }

        if (enableInteractivity) {
          childWidget = wrapAccessibilityAndInteraction(
            ctx: layoutContext,
            slotName: slotName,
            child: childWidget,
            slot: slot,
            semanticsOrder: semanticsOrder,
            semanticIndex: i,
            controller: interactionController,
          );
        } else if (enableSemantics) {
          childWidget = Semantics(
            container: true,
            sortKey: OrdinalSortKey(i.toDouble()),
            child: childWidget,
          );
        }

        children.add(
          _MatrixSlotIdentifier(
            hash: slotName.hashCode,
            slotName: slotName,
            child: RepaintBoundary(
              child: KeyedSubtree(
                key: ValueKey<String>(slotName),
                child: childWidget,
              ),
            ),
          ),
        );
      }

      _CompiledMatrixData matData = compiled;
      final String colsProp = (resolvedOverrides['gridCols'] ??
              nodeProps['gridCols'] ??
              layoutOverrides['gridCols'] ??
              '')
          .toString();
      final String rowsProp = (resolvedOverrides['gridRows'] ??
              nodeProps['gridRows'] ??
              layoutOverrides['gridRows'] ??
              '')
          .toString();
      if (colsProp.trim().isNotEmpty || rowsProp.trim().isNotEmpty) {
        matData = runtimeOverride(
          base: matData,
          cols: colsProp.trim().isNotEmpty ? colsProp : matData.colsSource,
          rows: rowsProp.trim().isNotEmpty ? rowsProp : matData.rowsSource,
        );
      }

      final dynamic maybeGap = resolvedOverrides['gap'] ??
          nodeProps['gap'] ??
          layoutOverrides['gap'];
      if (maybeGap is num) {
        final double gap = maybeGap.toDouble();
        if (gap != matData.gap) {
          matData = matData.withGap(gap);
        }
      }

      final dynamic scrollSignalValue = store.signal('system.scrollY');
      final QLSignal<double>? scrollSignal =
          scrollSignalValue is QLSignal<double> ? scrollSignalValue : null;

      return Directionality(
        textDirection: resolveTextDirection(layoutContext, enableRTL),
        child: QuantumMatrixNode(
          matrixData: matData,
          scrollSignal: scrollSignal,
          interactionController: interactionController,
          runtimeOverrides: runtimeOverrides,
          runtimeVisualOrder: runtimeVisualOrder,
          textDirection: resolveTextDirection(layoutContext, enableRTL),
          semanticsOrder: semanticsOrder,
          enableSemantics: enableSemantics,
          enableInteractivity: enableInteractivity,
          enableRTL: enableRTL,
          children: children,
        ),
      );
    },
  );
}

class _QuantumMatrixCorePlugin extends QLPlugin implements QLWidgetCapability {
  final Map<String, Map<String, _CompiledMatrixData>> _runtimeCaches =
      <String, Map<String, _CompiledMatrixData>>{};

  @override
  String get type => 'layout';

  @override
  Map<String, dynamic> get defaultProps => const {};

  @override
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    final String subType = node.props['__subType']?.toString() ?? '';
    final String layoutId = subType.isNotEmpty
        ? subType
        : (node.props['layoutId'] ??
                node.props['layout'] ??
                node.props['id'] ??
                '')
            .toString();

    final QMatrixLayoutDef? layoutDef = QMatrixLayoutRegistry.get(layoutId);
    if (layoutDef == null) {
      debugPrint(
          '🚨 [QuantumVM] Unknown layout id: $layoutId at ${node.debugPath}');
      return kDebugMode
          ? ErrorWidget('Unknown Layout: $layoutId\nPath: ${node.debugPath}')
          : const SizedBox.shrink();
    }

    final runtimeCache = _runtimeCaches.putIfAbsent(
      layoutId,
      () => <String, _CompiledMatrixData>{},
    );

    return buildQuantumMatrixWidget(
      ctx: ctx,
      node: node,
      store: store,
      layoutDef: layoutDef,
      runtimeCache: runtimeCache,
    );
  }
}

class _QuantumMatrixPlugin extends QLPlugin implements QLWidgetCapability {
  @override
  final String type;
  final QMatrixLayoutDef layoutDef;
  @override
  final Map<String, dynamic> defaultProps = const {};
  final Map<String, _CompiledMatrixData> _runtimeCache =
      <String, _CompiledMatrixData>{};

  _QuantumMatrixPlugin(this.type, this.layoutDef);

  @override
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    return buildQuantumMatrixWidget(
      ctx: ctx,
      node: node,
      store: store,
      layoutDef: layoutDef,
      runtimeCache: _runtimeCache,
    );
  }
}

class _MatrixSlotIdentifier extends ParentDataWidget<QuantumMatrixParentData> {
  final int hash;
  final String slotName;

  const _MatrixSlotIdentifier({
    required this.hash,
    required this.slotName,
    required super.child,
  });

  @override
  void applyParentData(RenderObject renderObject) {
    if (renderObject.parentData is! QuantumMatrixParentData) {
      renderObject.parentData = QuantumMatrixParentData();
    }
    final pd = renderObject.parentData as QuantumMatrixParentData;
    bool needsLayout = false;
    if (pd.hash != hash) {
      pd.hash = hash;
      needsLayout = true;
    }
    if (pd.id != slotName) {
      pd.id = slotName;
      needsLayout = true;
    }

    if (needsLayout) {
      final parent = renderObject.parent;
      if (parent is RenderObject) {
        parent.markNeedsLayout();
      }
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => QuantumMatrixNode;
}

// ──────────────────────────────────────────────────────────────────────────────
// Interaction shell for drag / resize / reorder
// ──────────────────────────────────────────────────────────────────────────────

class _MatrixInteractiveShell extends StatefulWidget {
  final String slotName;
  final QMatrixInteractionController controller;
  final Widget child;
  final bool draggable;
  final bool resizable;
  final bool reorderable;
  final QMatrixResizeHandle resizeHandle;

  const _MatrixInteractiveShell({
    required this.slotName,
    required this.controller,
    required this.child,
    required this.draggable,
    required this.resizable,
    required this.reorderable,
    required this.resizeHandle,
  });

  @override
  State<_MatrixInteractiveShell> createState() =>
      _MatrixInteractiveShellState();
}

class _MatrixInteractiveShellState extends State<_MatrixInteractiveShell> {
  Offset _dragStart = Offset.zero;
  Offset _resizeStart = Offset.zero;
  Size _resizeSizeStart = Size.zero;
  bool _dragging = false;
  bool _resizing = false;

  void _onDragStart(DragStartDetails d) {
    _dragStart = d.localPosition;
    _dragging = true;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    if (!widget.draggable && !widget.reorderable) return;
    final current = widget.controller.overrideFor(widget.slotName);
    final baseOffset = current?.pixelOffset ?? Offset.zero;
    widget.controller.setPixelOffset(
      widget.slotName,
      baseOffset + d.delta,
    );
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;
    if (widget.reorderable) {
      widget.controller.bringToFront(widget.slotName);
    }
  }

  void _onResizeStart(DragStartDetails d) {
    _resizeStart = d.localPosition;
    final current = widget.controller.overrideFor(widget.slotName);
    _resizeSizeStart = current?.pixelSize ?? Size.zero;
    _resizing = true;
  }

  void _onResizeUpdate(DragUpdateDetails d) {
    if (!widget.resizable) return;
    final current = widget.controller.overrideFor(widget.slotName);
    final baseSize = current?.pixelSize ?? _resizeSizeStart;
    final newSize = Size(
      math.max(0.0, baseSize.width + d.delta.dx),
      math.max(0.0, baseSize.height + d.delta.dy),
    );
    widget.controller.setPixelSize(widget.slotName, newSize);
  }

  void _onResizeEnd(DragEndDetails d) {
    _resizing = false;
  }

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    if (widget.draggable || widget.reorderable || widget.resizable) {
      child = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: widget.draggable || widget.reorderable
                    ? _onDragStart
                    : null,
                onPanUpdate: widget.draggable || widget.reorderable
                    ? _onDragUpdate
                    : null,
                onPanEnd:
                    widget.draggable || widget.reorderable ? _onDragEnd : null,
                child: const SizedBox.expand(),
              ),
            ), child, if (widget.resizable && widget.resizeHandle != QMatrixResizeHandle.none) ...<Widget>[
                    _ResizeHandles(
                      onStart: _onResizeStart,
                      onUpdate: _onResizeUpdate,
                      onEnd: _onResizeEnd,
                      handle: widget.resizeHandle,
                    ),
                  ]]
          
          
          ,
      );
    }

    return child;
  }
}

class _ResizeHandles extends StatelessWidget {
  final GestureDragStartCallback onStart;
  final GestureDragUpdateCallback onUpdate;
  final GestureDragEndCallback onEnd;
  final QMatrixResizeHandle handle;

  const _ResizeHandles({
    required this.onStart,
    required this.onUpdate,
    required this.onEnd,
    required this.handle,
  });

  Widget _handle(Alignment alignment, Size size) {
    return Align(
      alignment: alignment,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: onStart,
        onPanUpdate: onUpdate,
        onPanEnd: onEnd,
        child: SizedBox(width: size.width, height: size.height),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const handleSize = Size(18, 18);
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: <Widget>[
            if (handle == QMatrixResizeHandle.topLeft ||
                handle == QMatrixResizeHandle.left ||
                handle == QMatrixResizeHandle.top)
              _handle(Alignment.topLeft, handleSize),
            if (handle == QMatrixResizeHandle.topRight ||
                handle == QMatrixResizeHandle.right ||
                handle == QMatrixResizeHandle.top)
              _handle(Alignment.topRight, handleSize),
            if (handle == QMatrixResizeHandle.bottomLeft ||
                handle == QMatrixResizeHandle.left ||
                handle == QMatrixResizeHandle.bottom)
              _handle(Alignment.bottomLeft, handleSize),
            if (handle == QMatrixResizeHandle.bottomRight ||
                handle == QMatrixResizeHandle.right ||
                handle == QMatrixResizeHandle.bottom)
              _handle(Alignment.bottomRight, handleSize),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Registration
// ──────────────────────────────────────────────────────────────────────────────

extension QuantumMatrixLayoutPlugin on QuantumVM {
  void defineMatrixLayout(
    String layoutId,
    void Function(QMatrixBuilder) build, {
    Map<String, dynamic> defaultProps = const {},
    String? defaultVariant,
    String? description,
    Map<String, dynamic> params = const {},
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    final builder = QMatrixBuilder();
    build(builder);
    final layoutDef = builder.buildDef();
    final Map<String, dynamic> resolvedParams = params.isNotEmpty
        ? Map<String, dynamic>.from(params)
        : Map<String, dynamic>.from(defaultProps);
    final List<String> resolvedTags = tags.isNotEmpty
        ? List<String>.from(tags)
        : <String>['layout', 'matrix'];
    final Map<String, dynamic> resolvedMetadata = {
      ...metadata,
      'defaultVariant': defaultVariant,
      'slotCount': layoutDef.slotConfigs.length,
      'variantNames': layoutDef.variants.keys.toList(growable: false),
    };
    QMatrixLayoutRegistry.register(
      layoutId,
      layoutDef,
      defaultProps: defaultProps,
      description: description ?? 'Matrix layout $layoutId',
      params: resolvedParams,
      metadata: resolvedMetadata,
      tags: resolvedTags,
    );

    if (!QMatrixLayoutRegistry._coreRegistered) {
      QMatrixLayoutRegistry._coreRegistered = true;
      QuantumVM.instance.registerPlugin(_QuantumMatrixCorePlugin());
    }

    QuantumVM.instance.defineAlias(
      layoutId,
      'layout:$layoutId',
      defaultProps: Map<String, dynamic>.from(defaultProps),
      description: description ?? 'Layout alias for $layoutId',
      metadata: {
        ...resolvedMetadata,
        'paramSchema': QMatrixLayoutRegistry._schemaForMap(resolvedParams),
        'infoSchema': {
          'name': layoutId,
          'kind': 'layout',
          'description': description ?? 'Matrix layout $layoutId',
          'engine': 'QMatrixLayoutRegistry',
          'tags': resolvedTags,
          'defaultVariant': defaultVariant,
          'slotCount': layoutDef.slotConfigs.length,
        },
      },
      tags: resolvedTags,
    );

    registerPlugin(_QuantumMatrixPlugin(layoutId, layoutDef));
  }
}
