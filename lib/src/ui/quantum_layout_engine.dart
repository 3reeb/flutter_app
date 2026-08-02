/*
 * ============================================================================
 * File: quantum_layout_engine.dart
 * 
 * Description:
 * A high-performance virtualized DOM layout engine featuring cached render lists, bitmask-based O(1) grid occupancy tracking, and custom grid, split, morph, and sliver helpers.
 * 
 * Key Components:
 * - QuantumLayout: The unified polymorphic abstraction for all layouts.
 * - QuantumGrid / RenderQuantumGrid: The core CSS-like grid and masonry engine.
 * - QuantumParentData: The metadata node for spanning and alignment tracking.
 * 
 * Dependencies/Relationships:
 * The foundational layout layer, consumed by quantum_components.dart and QLSpace.
 * 
 * Notes:
 * Rendering avoids continuous memory allocations by reusing Float64List and Int32List.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM LAYOUT ENGINE (QLE) v14.0 — HIGH-PERFORMANCE VIRTUALIZED DOM
// quantum_layout_engine.dart
// ════════════════════════════════════════════════════════════════════════════
//
// A performance-oriented Flutter layout engine with:
// - cached render lists
// - zero re-collection in paint/hit test
// - bitmask-based O(1) grid occupancy tracking
// - custom grid, split, morph, and sliver helpers
// - builder-backed virtualized grid for large datasets
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// Foundation dependencies (Assumed to exist in your ecosystem)
import '../foundation/quantum_core.dart';
import '../foundation/quantum_primitives.dart';
// ────────────────────────────────────────────────────────────────────────────
// §1 — ENUMS & PRIMITIVES
// ────────────────────────────────────────────────────────────────────────────

enum QLayoutType { grid, masonry, row, col, wrap, stack, split, morph, none }

enum QFlowDirection { row, column, rowDense, columnDense, masonry }

enum QAlign { start, center, end, stretch, baseline }

enum QJustify { start, center, end, stretch, spaceBetween, spaceAround }

// ────────────────────────────────────────────────────────────────────────────
// §2 — INHERITED SCOPES (Contextual Layout Awareness)
// ────────────────────────────────────────────────────────────────────────────

/// Injects the current layout type into the tree so children (like Flexible)
/// can adapt their behavior dynamically.
class QuantumLayoutScope extends InheritedWidget {
  final String layoutType;

  const QuantumLayoutScope({
    super.key,
    required this.layoutType,
    required super.child,
  });

  static QuantumLayoutScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<QuantumLayoutScope>();
  }

  @override
  bool updateShouldNotify(QuantumLayoutScope oldWidget) {
    return layoutType != oldWidget.layoutType;
  }
}

/// Marks a subtree as being inside a scroll viewport so layout code can avoid
/// force-bounding its main axis and causing flex overflows inside nested scrolls.
class QuantumScrollScope extends InheritedWidget {
  final Axis axis;

  const QuantumScrollScope({
    super.key,
    required this.axis,
    required super.child,
  });

  static QuantumScrollScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<QuantumScrollScope>();
  }

  @override
  bool updateShouldNotify(QuantumScrollScope oldWidget) =>
      axis != oldWidget.axis;
}

// ────────────────────────────────────────────────────────────────────────────
// §3 — HIGH-LEVEL ABSTRACTION (QuantumLayout)
// ────────────────────────────────────────────────────────────────────────────

class QuantumLayout extends StatelessWidget {
  final QLayoutType layoutType;
  final String? columns;
  final String? rows;
  final double columnGap;
  final double rowGap;
  final Axis? direction;
  final List<double>? fractions;
  final bool dense;
  final Size? initialMorphSize;
  final bool lockAspect;
  final double snapGrid;
  final List<Widget> children;

  const QuantumLayout({
    super.key,
    required this.layoutType,
    this.columns,
    this.rows,
    this.columnGap = 0.0,
    this.rowGap = 0.0,
    this.direction,
    this.fractions,
    this.dense = true,
    this.initialMorphSize,
    this.lockAspect = false,
    this.snapGrid = 0.0,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return QuantumLayoutScope(
      layoutType: layoutType.name,
      child: _buildEngine(),
    );
  }

  Widget _buildEngine() {
    switch (layoutType) {
      case QLayoutType.grid:
      case QLayoutType.masonry:
        return QuantumGrid(
          columns: columns ?? '1fr',
          rows: rows ?? 'auto',
          columnGap: columnGap,
          rowGap: rowGap,
          flow: layoutType == QLayoutType.masonry
              ? QFlowDirection.masonry
              : (dense ? QFlowDirection.rowDense : QFlowDirection.row),
          alignItems: QAlign.stretch,
          children: children,
        );
      case QLayoutType.row:
      case QLayoutType.col:
        return QuantumFlex(
          direction:
              layoutType == QLayoutType.row ? Axis.horizontal : Axis.vertical,
          gap: columnGap > 0 ? columnGap : rowGap,
          mainAxisSize: MainAxisSize.min,
          children: children,
        );
      case QLayoutType.wrap:
        return Wrap(spacing: columnGap, runSpacing: rowGap, children: children);
      case QLayoutType.stack:
        return Stack(children: children);
      case QLayoutType.split:
        return QuantumSplitPane(
          direction: direction ?? Axis.horizontal,
          initialFractions: fractions,
          dividerThickness: 6.0,
          children: children,
        );
      case QLayoutType.morph:
        return QuantumMorphSurface(
          initialSize: initialMorphSize ?? const Size(200, 200),
          lockAspectRatio: lockAspect,
          snapGrid: snapGrid,
          child: Wrap(children: children),
        );
      case QLayoutType.none:
      default:
        return children.isNotEmpty ? children.first : const SizedBox.shrink();
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §4 — CSS-LIKE GRID & MASONRY (The Crown Jewel)
// ────────────────────────────────────────────────────────────────────────────

class QuantumGrid extends MultiChildRenderObjectWidget {
  final String columns;
  final String rows;
  final String autoColumns;
  final String autoRows;
  final double columnGap;
  final double rowGap;
  final QFlowDirection flow;
  final QAlign alignItems;
  final QAlign justifyItems;

  const QuantumGrid({
    super.key,
    this.columns = '1fr',
    this.rows = 'auto',
    this.autoColumns = 'auto',
    this.autoRows = 'auto',
    this.columnGap = 0.0,
    this.rowGap = 0.0,
    this.flow = QFlowDirection.row,
    this.alignItems = QAlign.stretch,
    this.justifyItems = QAlign.stretch,
    required super.children,
  });

  @override
  RenderQuantumGrid createRenderObject(BuildContext context) {
    return RenderQuantumGrid(
      columns: QParser.parse(columns),
      rows: QParser.parse(rows),
      autoColumns: QParser.parse(autoColumns),
      autoRows: QParser.parse(autoRows),
      colGap: columnGap,
      rowGap: rowGap,
      flow: flow,
      alignItems: alignItems,
      justifyItems: justifyItems,
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderQuantumGrid renderObject) {
    renderObject
      ..columns = QParser.parse(columns)
      ..rows = QParser.parse(rows)
      ..autoColumns = QParser.parse(autoColumns)
      ..autoRows = QParser.parse(autoRows)
      ..colGap = columnGap
      ..rowGap = rowGap
      ..flow = flow
      ..alignItems = alignItems
      ..justifyItems = justifyItems
      ..textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }
}

class QuantumParentData extends ContainerBoxParentData<RenderBox> {
  int cStart = 0, cEnd = 0, cSpan = 1;
  int rStart = 0, rEnd = 0, rSpan = 1;
  QAlign? align;
  QAlign? justify;
  int zIndex = 0;
  bool ignoreOccupancy = false;

  // Internal resolved coordinates (1-based index)
  int rcStart = 1, rcEnd = 2;
  int rrStart = 1, rrEnd = 2;
  int index = 0;
}

class QuantumItem extends ParentDataWidget<QuantumParentData> {
  final int colStart, colEnd, colSpan;
  final int rowStart, rowEnd, rowSpan;
  final QAlign? alignSelf;
  final QAlign? justifySelf;
  final int zIndex;
  final bool ignoreOccupancy;

  const QuantumItem({
    super.key,
    this.colStart = 0,
    this.colEnd = 0,
    this.colSpan = 1,
    this.rowStart = 0,
    this.rowEnd = 0,
    this.rowSpan = 1,
    this.alignSelf,
    this.justifySelf,
    this.zIndex = 0,
    this.ignoreOccupancy = false,
    required super.child,
  });

  @override
  Type get debugTypicalAncestorWidgetClass => QuantumGrid;

  @override
  void applyParentData(RenderObject renderObject) {
    final pd = renderObject.parentData as QuantumParentData;
    var needsLayout = false;
    var needsPaint = false;

    void setIfChanged<T>(T current, T next, void Function(T) setter) {
      if (current != next) {
        setter(next);
        needsLayout = true;
      }
    }

    setIfChanged(pd.cStart, colStart, (v) => pd.cStart = v);
    setIfChanged(pd.cEnd, colEnd, (v) => pd.cEnd = v);
    setIfChanged(pd.cSpan, colSpan, (v) => pd.cSpan = v);
    setIfChanged(pd.rStart, rowStart, (v) => pd.rStart = v);
    setIfChanged(pd.rEnd, rowEnd, (v) => pd.rEnd = v);
    setIfChanged(pd.rSpan, rowSpan, (v) => pd.rSpan = v);
    setIfChanged(pd.align, alignSelf, (v) => pd.align = v);
    setIfChanged(pd.justify, justifySelf, (v) => pd.justify = v);
    setIfChanged(
        pd.ignoreOccupancy, ignoreOccupancy, (v) => pd.ignoreOccupancy = v);

    if (pd.zIndex != zIndex) {
      pd.zIndex = zIndex;
      needsPaint = true;
      final parent = renderObject.parent;
      if (parent is RenderQuantumGrid) parent.markZOrderDirty();
    }

    if (needsLayout) {
      renderObject.parent?.markNeedsLayout();
    } else if (needsPaint) {
      renderObject.parent?.markNeedsPaint();
    }
  }
}

class RenderQuantumGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, QuantumParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, QuantumParentData> {
  List<QSize> _columns;
  List<QSize> _rows;
  List<QSize> _autoColumns;
  List<QSize> _autoRows;
  double _colGap;
  double _rowGap;
  QFlowDirection _flow;
  QAlign _alignItems;
  QAlign _justifyItems;
  TextDirection _textDirection;

  Uint32List _bitmask = Uint32List(0);
  int _bCols = 0;
  int _stride = 0;

  Float64List _cWidths = Float64List(0);
  Float64List _rHeights = Float64List(0);
  Float64List _cOffsets = Float64List(0);
  Float64List _rOffsets = Float64List(0);

  Int32List _paintOrder = Int32List(0);
  List<RenderBox> _children = const <RenderBox>[];
  int _childCount = 0;
  bool _isZOrderDirty = true;
  int _maxCols = 0, _maxRows = 0;

  RenderQuantumGrid({
    required List<QSize> columns,
    required List<QSize> rows,
    required List<QSize> autoColumns,
    required List<QSize> autoRows,
    required double colGap,
    required double rowGap,
    required QFlowDirection flow,
    required QAlign alignItems,
    required QAlign justifyItems,
    required TextDirection textDirection,
  })  : _columns = columns,
        _rows = rows,
        _autoColumns = autoColumns,
        _autoRows = autoRows,
        _colGap = colGap,
        _rowGap = rowGap,
        _flow = flow,
        _alignItems = alignItems,
        _justifyItems = justifyItems,
        _textDirection = textDirection;

  set columns(List<QSize> v) {
    if (!identical(_columns, v)) {
      _columns = v;
      markNeedsLayout();
    }
  }

  set rows(List<QSize> v) {
    if (!identical(_rows, v)) {
      _rows = v;
      markNeedsLayout();
    }
  }

  set autoColumns(List<QSize> v) {
    if (!identical(_autoColumns, v)) {
      _autoColumns = v;
      markNeedsLayout();
    }
  }

  set autoRows(List<QSize> v) {
    if (!identical(_autoRows, v)) {
      _autoRows = v;
      markNeedsLayout();
    }
  }

  set colGap(double v) {
    if (_colGap != v) {
      _colGap = v;
      markNeedsLayout();
    }
  }

  set rowGap(double v) {
    if (_rowGap != v) {
      _rowGap = v;
      markNeedsLayout();
    }
  }

  set flow(QFlowDirection v) {
    if (_flow != v) {
      _flow = v;
      markNeedsLayout();
    }
  }

  set alignItems(QAlign v) {
    if (_alignItems != v) {
      _alignItems = v;
      markNeedsLayout();
    }
  }

  set justifyItems(QAlign v) {
    if (_justifyItems != v) {
      _justifyItems = v;
      markNeedsLayout();
    }
  }

  set textDirection(TextDirection v) {
    if (_textDirection != v) {
      _textDirection = v;
      markNeedsLayout();
    }
  }

  void markZOrderDirty() {
    _isZOrderDirty = true;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! QuantumParentData) {
      child.parentData = QuantumParentData();
    }
  }

  @pragma('vm:prefer-inline')
  int _clampInt(int value, int minValue, int maxValue) {
    if (value < minValue) return minValue;
    if (value > maxValue) return maxValue;
    return value;
  }

  @pragma('vm:prefer-inline')
  double _finiteOrZero(double v) => QLSafe.finite(v, 0.0);

  void _ensureBitmask(int rows, int cols) {
    _bCols = cols;
    _stride = (cols + 31) >> 5;
    final reqSize = rows * _stride;
    if (reqSize <= 0) {
      _bitmask = Uint32List(0);
      return;
    }
    if (_bitmask.length < reqSize) {
      var nextSize = _bitmask.isEmpty ? 64 : _bitmask.length * 2;
      while (nextSize < reqSize) {
        nextSize *= 2;
      }
      _bitmask = Uint32List(nextSize);
    } else {
      _bitmask.fillRange(0, reqSize, 0);
    }
  }

  @pragma('vm:prefer-inline')
  void _occupy(int r, int c, int rSpan, int cSpan) {
    if (rSpan <= 0 || cSpan <= 0) return;
    for (int ri = r; ri < r + rSpan; ri++) {
      final rowOffset = ri * _stride;
      for (int ci = c; ci < c + cSpan; ci++) {
        final idx = rowOffset + (ci >> 5);
        if (idx >= 0) {
          if (idx >= _bitmask.length) {
            final oldLen = _bitmask.length;
            var nextSize = oldLen == 0 ? 64 : oldLen * 2;
            while (nextSize <= idx) {
              nextSize *= 2;
            }
            final newMask = Uint32List(nextSize);
            for (int i = 0; i < oldLen; i++) {
              newMask[i] = _bitmask[i];
            }
            _bitmask = newMask;
          }
          _bitmask[idx] |= (1 << (ci & 31));
        }
      }
    }
    _maxCols = math.max(_maxCols, c + cSpan);
    _maxRows = math.max(_maxRows, r + rSpan);
  }

  void _ensureRegisters(int reqCols, int reqRows) {
    if (reqCols < 0) reqCols = 0;
    if (reqRows < 0) reqRows = 0;

    if (_cWidths.length < reqCols) {
      var s = _cWidths.isEmpty ? 16 : _cWidths.length * 2;
      while (s < reqCols) {
        s *= 2;
      }
      _cWidths = Float64List(s);
      _cOffsets = Float64List(s + 1);
    }
    if (_rHeights.length < reqRows) {
      var s = _rHeights.isEmpty ? 16 : _rHeights.length * 2;
      while (s < reqRows) {
        s *= 2;
      }
      _rHeights = Float64List(s);
      _rOffsets = Float64List(s + 1);
    }
  }

  void _cacheChildren() {
    final cached = <RenderBox>[];
    RenderBox? child = firstChild;
    while (child != null) {
      final pd = child.parentData as QuantumParentData;
      pd.index = cached.length;
      cached.add(child);
      child = childAfter(child);
    }
    _children = cached;
    _childCount = cached.length;
  }

  @override
  void performLayout() {
    _cacheChildren();

    if (_childCount == 0) {
      _maxCols = 0;
      _maxRows = 0;
      _paintOrder = Int32List(0);
      size = constraints.constrain(Size.zero);
      return;
    }

    try {
      final availW = _finiteOrZero(constraints.maxWidth);
      final availH = _finiteOrZero(constraints.maxHeight);

      _resolveDynamicTracks(availW, availH);

      if (_flow == QFlowDirection.masonry) {
        _executeMasonryPlacement(_children, availW);
      } else {
        _executeAutoPlacement(_children);
      }

      _ensureRegisters(_maxCols, _maxRows);
      _calculateDimensions(availW, availH, _children);
      _positionAndAlignChildren(_children);

      if (_isZOrderDirty || _paintOrder.length < _childCount) {
        _buildZIndexOrder(_children);
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('RenderQuantumGrid.performLayout failed: $e\n$st');
      }
      _childCount = _children.length;
      _maxCols = math.max(1, _maxCols);
      _maxRows = math.max(1, _maxRows);
      size = constraints.constrain(Size.zero);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!hasSize || _childCount == 0 || size.isEmpty || _paintOrder.isEmpty) {
      return;
    }
    final children = _children;
    for (int i = 0; i < _childCount && i < _paintOrder.length; i++) {
      final childIndex = _paintOrder[i];
      if (childIndex < 0 || childIndex >= children.length) continue;
      final c = children[childIndex];
      final pd = c.parentData as QuantumParentData;
      context.paintChild(c, pd.offset + offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!hasSize || _childCount == 0 || size.isEmpty || _paintOrder.isEmpty) {
      return false;
    }
    final children = _children;
    for (int i = _childCount - 1; i >= 0; i--) {
      if (i >= _paintOrder.length) continue;
      final childIndex = _paintOrder[i];
      if (childIndex < 0 || childIndex >= children.length) continue;
      final c = children[childIndex];
      final pd = c.parentData as QuantumParentData;
      final isHit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return c.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
    }
    return false;
  }

  void _resolveDynamicTracks(double availW, double availH) {
    _columns = _expandDynamic(_columns, availW, _colGap);
    _rows = _expandDynamic(_rows, availH, _rowGap);
  }

  List<QSize> _expandDynamic(
      List<QSize> original, double availableSpace, double gap) {
    final resolved = <QSize>[];
    for (final track in original) {
      if (track is QAutoFill || track is QAutoFit) {
        final subTracks =
            track is QAutoFill ? track.tracks : (track as QAutoFit).tracks;
        if (availableSpace <= 0.0) {
          resolved.addAll(subTracks);
          continue;
        }

        var minSize = 0.0;
        for (final st in subTracks) {
          if (st is QFixed) {
            minSize += st.px;
          } else if (st is QMinMax && st.min is QFixed) {
            minSize += (st.min as QFixed).px;
          } else {
            minSize += 40.0;
          }
        }
        if (minSize <= 0.0) minSize = 40.0;

        var repetitions =
            math.max(1, ((availableSpace + gap) / (minSize + gap)).floor());
        if (repetitions > 1024) repetitions = 1024;
        for (int i = 0; i < repetitions; i++) {
          resolved.addAll(subTracks);
        }
      } else if (track is QRepeat) {
        final count = track.count.clamp(1, 10000);
        for (int i = 0; i < count; i++) {
          resolved.addAll(track.tracks);
        }
      } else {
        resolved.add(track);
      }
    }
    return resolved;
  }

  void _executeMasonryPlacement(List<RenderBox> children, double availW) {
    _maxCols = math.max(1, _columns.length);
    _maxRows = 0;
    final colHeights = Float64List(_maxCols);

    for (final child in children) {
      final pd = child.parentData as QuantumParentData;
      if (pd.ignoreOccupancy) continue;

      var shortestCol = 0;
      var minH = colHeights[0];
      for (int i = 1; i < _maxCols; i++) {
        if (colHeights[i] < minH) {
          minH = colHeights[i];
          shortestCol = i;
        }
      }

      final span = math.max(1, math.min(pd.cSpan, _maxCols - shortestCol));
      pd.rrStart = 1;
      pd.rcStart = shortestCol + 1;
      pd.rrEnd = 2;
      pd.rcEnd = pd.rcStart + span;

      final cw =
          math.max(0.0, (availW - (_maxCols - 1) * _colGap) / _maxCols * span);
      final ch = _safeIntrinsicHeight(child, cw);

      for (int c = shortestCol; c < shortestCol + span && c < _maxCols; c++) {
        colHeights[c] = minH + ch + _rowGap;
      }
    }
    _maxRows = 1;
  }

  void _executeAutoPlacement(List<RenderBox> children) {
    _maxCols = math.max(1, _columns.length);
    _maxRows = math.max(1, _rows.length);

    var estMaxCol = _maxCols;
    var estMaxRow = _maxRows;
    final isRow =
        _flow == QFlowDirection.row || _flow == QFlowDirection.rowDense;
    final isDense =
        _flow == QFlowDirection.rowDense || _flow == QFlowDirection.columnDense;

    for (final child in children) {
      final pd = child.parentData as QuantumParentData;
      final cSpan = isRow ? math.min(pd.cSpan, _maxCols) : pd.cSpan;
      if (pd.cStart > 0) estMaxCol = math.max(estMaxCol, pd.cStart + cSpan - 1);
      if (pd.rStart > 0) {
        estMaxRow = math.max(estMaxRow, pd.rStart + pd.rSpan - 1);
      }
    }

    _maxCols = math.max(1, estMaxCol);
    _maxRows = math.max(1, estMaxRow);
    _ensureBitmask(_maxRows + 8, _maxCols + 8);

    for (final child in children) {
      final pd = child.parentData as QuantumParentData;
      final cSpan = isRow ? math.min(pd.cSpan, _maxCols) : pd.cSpan;
      if (pd.rStart > 0 && pd.cStart > 0) {
        pd.rrStart = pd.rStart;
        pd.rcStart = pd.cStart;
        pd.rrEnd = pd.rEnd > 0 ? pd.rEnd : pd.rStart + pd.rSpan;
        pd.rcEnd = pd.cEnd > 0 ? pd.cEnd : pd.cStart + cSpan;
        if (!pd.ignoreOccupancy) {
          _occupy(pd.rrStart - 1, pd.rcStart - 1, pd.rrEnd - pd.rrStart,
              pd.rcEnd - pd.rcStart);
        }
      }
    }

    var cursorR = 0;
    var cursorC = 0;

    for (final child in children) {
      final pd = child.parentData as QuantumParentData;
      if (pd.rStart > 0 && pd.cStart > 0) continue;

      final spanR = !isRow
          ? math.max(1, math.min(pd.rSpan, _maxRows))
          : math.max(1, pd.rSpan);
      final spanC = isRow
          ? math.max(1, math.min(pd.cSpan, _maxCols))
          : math.max(1, pd.cSpan);

      var sR = isDense ? 0 : cursorR;
      var sC = isDense ? 0 : cursorC;

      if (pd.cStart > 0) sC = pd.cStart - 1;
      if (pd.rStart > 0) sR = pd.rStart - 1;

      if (!pd.ignoreOccupancy) {
        var attempts = 0;
        const maxAttempts = 100000;
        while (attempts++ < maxAttempts) {
          if (isRow && pd.cStart == 0 && sC + spanC > _maxCols) {
            sC = 0;
            sR++;
            continue;
          }
          if (!isRow && pd.rStart == 0 && sR + spanR > _maxRows) {
            sR = 0;
            sC++;
            continue;
          }

          var fits = true;
          for (int r = sR; r < sR + spanR; r++) {
            final rowOffset = r * _stride;
            for (int c = sC; c < sC + spanC; c++) {
              final idx = rowOffset + (c >> 5);
              if (idx < 0 ||
                  (idx < _bitmask.length &&
                      (_bitmask[idx] & (1 << (c & 31))) != 0)) {
                fits = false;
                break;
              }
            }
            if (!fits) break;
          }
          if (fits) break;

          if (isRow) {
            if (pd.cStart > 0) {
              sR++;
            } else {
              sC++;
            }
          } else {
            if (pd.rStart > 0) {
              sC++;
            } else {
              sR++;
            }
          }
        }
        _occupy(sR, sC, spanR, spanC);
      }

      pd.rrStart = sR + 1;
      pd.rcStart = sC + 1;
      pd.rrEnd = sR + 1 + spanR;
      pd.rcEnd = sC + 1 + spanC;

      if (!pd.ignoreOccupancy) {
        if (isRow) {
          cursorR = sR;
          cursorC = sC + spanC;
        } else {
          cursorR = sR + spanR;
          cursorC = sC;
        }
      }
    }
  }

  void _calculateDimensions(double aW, double aH, List<RenderBox> children) {
    _resolve1D(_maxCols, aW, children, true, _cWidths);
    if (_flow != QFlowDirection.masonry) {
      _resolve1D(_maxRows, aH, children, false, _rHeights);
    } else {
      _rHeights.fillRange(0, _rHeights.length, 0.0);
      for (final c in children) {
        final pd = c.parentData as QuantumParentData;
        final colIndex =
            _clampInt(pd.rcStart - 1, 0, math.max(0, _maxCols - 1));
        final rowIndex =
            _clampInt(pd.rrStart - 1, 0, math.max(0, _maxRows - 1));
        final cw = _cWidths.isNotEmpty ? _cWidths[colIndex] : 0.0;
        _rHeights[rowIndex] =
            math.max(_rHeights[rowIndex], _safeIntrinsicHeight(c, cw));
      }
    }

    var accW = 0.0;
    for (int i = 0; i < _maxCols; i++) {
      _cOffsets[i] = accW;
      accW += _cWidths[i] + _colGap;
    }
    _cOffsets[_maxCols] = accW;

    var accH = 0.0;
    for (int i = 0; i < _maxRows; i++) {
      _rOffsets[i] = accH;
      accH += _rHeights[i] + _rowGap;
    }
    _rOffsets[_maxRows] = accH;
  }

  QSize _getTrack(int idx, bool isCol) {
    final explicit = isCol ? _columns : _rows;
    if (idx < explicit.length) return explicit[idx];
    final auto = isCol ? _autoColumns : _autoRows;
    if (auto.isEmpty) return const QAuto();
    return auto[(idx - explicit.length) % auto.length];
  }

  void _resolve1D(int count, double avail, List<RenderBox> children, bool isCol,
      Float64List out) {
    if (count <= 0) return;
    var usedFixed = 0.0;
    var totalFr = 0.0;
    final gap = isCol ? _colGap : _rowGap;

    for (int i = 0; i < count; i++) {
      out[i] = 0.0;
      final t = _getTrack(i, isCol);
      if (t is QFixed) {
        out[i] = math.max(0.0, t.px);
        usedFixed += out[i];
      } else if (t is QMinMax && t.min is QFixed) {
        out[i] = math.max(0.0, (t.min as QFixed).px);
        usedFixed += out[i];
      } else if (t is QFraction) {
        totalFr += math.max(0.0, t.fr);
      } else if (t is QMinMax && t.max is QFraction) {
        totalFr += math.max(0.0, (t.max as QFraction).fr);
      }
    }

    for (int i = 0; i < count; i++) {
      final t = _getTrack(i, isCol);
      if (t is QFixed || (t is QFraction && avail.isFinite)) continue;

      var maxIn = 0.0;
      for (final child in children) {
        final pd = child.parentData as QuantumParentData;
        final start = isCol ? pd.rcStart - 1 : pd.rrStart - 1;
        final end = isCol ? pd.rcEnd - 1 : pd.rrEnd - 1;
        if (i < start || i >= end) continue;

        final span = math.max(1, end - start);
        final childIn = isCol
            ? _safeIntrinsicWidth(child)
            : _safeIntrinsicHeight(
                child,
                _cWidths.isNotEmpty
                    ? _cWidths[
                        _clampInt(pd.rcStart - 1, 0, _cWidths.length - 1)]
                    : double.infinity);
        maxIn = math.max(maxIn, childIn / span);
      }

      final initialOut = out[i];
      if (t is QAuto) {
        out[i] = math.max(initialOut, maxIn);
      } else if (t is QFitContent) {
        out[i] = math.max(initialOut, math.min(maxIn, t.maxPx));
      } else if (t is QMinMax) {
        final minLimit = t.min is QFixed ? (t.min as QFixed).px : 0.0;
        if (t.max is! QFraction) {
          final maxLimit = t.max is QFixed ? (t.max as QFixed).px : maxIn;
          out[i] =
              maxIn.clamp(minLimit, math.max(minLimit, maxLimit)).toDouble();
        } else {
          out[i] = math.max(minLimit, maxIn);
        }
      } else if (t is QFraction || (t is QMinMax && t.max is QFraction)) {
        out[i] = math.max(initialOut, maxIn);
      }
      usedFixed += (out[i] - initialOut);
    }

    final remaining = avail - usedFixed - (math.max(0, count - 1) * gap);
    if (totalFr > 0.0 && remaining > 0.0) {
      final unit = remaining / totalFr;
      for (int i = 0; i < count; i++) {
        final t = _getTrack(i, isCol);
        if (t is QFraction) {
          out[i] += unit * t.fr;
        } else if (t is QMinMax && t.max is QFraction) {
          out[i] += unit * (t.max as QFraction).fr;
        }
      }
    }
  }

  void _positionAndAlignChildren(List<RenderBox> children) {
    final isRtl = _textDirection == TextDirection.rtl;
    final totalW = (_maxCols > 0 && _cOffsets.isNotEmpty)
        ? math.max(0.0, _cOffsets[_maxCols] - _colGap)
        : 0.0;
    final masonryColY = Float64List(math.max(1, _maxCols));

    for (final child in children) {
      final pd = child.parentData as QuantumParentData;
      final cs = _clampInt(pd.rcStart - 1, 0, math.max(0, _maxCols));
      final ce = _clampInt(pd.rcEnd - 1, cs, math.max(0, _maxCols));
      final rs = _clampInt(pd.rrStart - 1, 0, math.max(0, _maxRows));
      final re = _clampInt(pd.rrEnd - 1, rs, math.max(0, _maxRows));

      final cw = math.max(0.0, _cOffsets[ce] - _cOffsets[cs] - _colGap);
      final ch = math.max(0.0, _rOffsets[re] - _rOffsets[rs] - _rowGap);

      final align = pd.align ?? _alignItems;
      final justify = pd.justify ?? _justifyItems;

      child.layout(
        BoxConstraints(
          minWidth: justify == QAlign.stretch ? cw : 0.0,
          maxWidth: cw,
          minHeight: _flow == QFlowDirection.masonry
              ? 0.0
              : (align == QAlign.stretch ? ch : 0.0),
          maxHeight: _flow == QFlowDirection.masonry ? double.infinity : ch,
        ),
        parentUsesSize: true,
      );

      var dx = _cOffsets[cs];
      var dy =
          _flow == QFlowDirection.masonry ? masonryColY[cs] : _rOffsets[rs];

      if (justify == QAlign.center) {
        dx += (cw - child.size.width) * 0.5;
      } else if (justify == QAlign.end) {
        dx += (cw - child.size.width);
      }

      if (_flow != QFlowDirection.masonry) {
        if (align == QAlign.center) {
          dy += (ch - child.size.height) * 0.5;
        } else if (align == QAlign.end) {
          dy += (ch - child.size.height);
        }
      }

      if (isRtl) dx = totalW - dx - child.size.width;
      pd.offset = Offset(dx, dy);

      if (_flow == QFlowDirection.masonry && !pd.ignoreOccupancy) {
        for (int i = cs; i < ce && i < masonryColY.length; i++) {
          masonryColY[i] = dy + child.size.height + _rowGap;
        }
      }
    }

    final finalHeight = _flow == QFlowDirection.masonry
        ? masonryColY.fold<double>(0.0, math.max) - _rowGap
        : (_maxRows > 0 ? math.max(0.0, _rOffsets[_maxRows] - _rowGap) : 0.0);
    size = constraints.constrain(Size(totalW, math.max(0.0, finalHeight)));
  }

  void _buildZIndexOrder(List<RenderBox> children) {
    if (_paintOrder.length < _childCount) {
      var s = _paintOrder.isEmpty ? 16 : _paintOrder.length * 2;
      while (s < _childCount) {
        s *= 2;
      }
      _paintOrder = Int32List(s);
    }
    for (int i = 0; i < _childCount; i++) {
      _paintOrder[i] = i;
    }

    for (int i = 1; i < _childCount; i++) {
      final keyIdx = _paintOrder[i];
      final keyZ = (children[keyIdx].parentData as QuantumParentData).zIndex;
      var j = i - 1;
      while (j >= 0 &&
          (children[_paintOrder[j]].parentData as QuantumParentData).zIndex >
              keyZ) {
        _paintOrder[j + 1] = _paintOrder[j];
        j--;
      }
      _paintOrder[j + 1] = keyIdx;
    }
    _isZOrderDirty = false;
  }

  double _safeIntrinsicWidth(RenderBox child) {
    try {
      final v = child.computeMaxIntrinsicWidth(double.infinity);
      return v.isFinite && v > 0.0 ? v : 0.0;
    } catch (_) {
      try {
        child.layout(
          const BoxConstraints(
            minWidth: 0,
            maxWidth: 99999.0,
            minHeight: 0,
            maxHeight: 99999.0,
          ),
          parentUsesSize: true,
        );
        return child.size.width;
      } catch (_) {
        return 0.0;
      }
    }
  }

  double _safeIntrinsicHeight(RenderBox child, double width) {
    final safeWidth = width.isFinite && width > 0.0 ? width : 99999.0;
    try {
      final v = child.computeMaxIntrinsicHeight(safeWidth);
      return v.isFinite && v > 0.0 ? v : 0.0;
    } catch (_) {
      try {
        child.layout(
          BoxConstraints(
            minWidth: 0,
            maxWidth: safeWidth,
            minHeight: 0,
            maxHeight: 99999.0,
          ),
          parentUsesSize: true,
        );
        return child.size.height;
      } catch (_) {
        return 0.0;
      }
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0.0;
  @override
  double computeMinIntrinsicHeight(double width) => 0.0;
  @override
  double computeMaxIntrinsicHeight(double width) => 0.0;
}

// ────────────────────────────────────────────────────────────────────────────
// §5 — FLEX WITH SCROLL SHELL & GAP INJECTION
// ────────────────────────────────────────────────────────────────────────────

class QuantumFlex extends StatelessWidget {
  final Axis direction;
  final double gap;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final Clip clipBehavior;

  const QuantumFlex({
    super.key,
    required this.direction,
    required this.gap,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.clipBehavior = Clip.none, // Removed ClipRect
  });

  List<Widget> _withGap() {
    if (gap <= 0 || children.length < 2) return children;
    final spacedChildren = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1) {
        spacedChildren.add(SizedBox(
            width: direction == Axis.horizontal ? gap : 0.0,
            height: direction == Axis.vertical ? gap : 0.0));
      }
    }
    return spacedChildren;
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 FOREVER FIX: Pure Flex. No LayoutBuilders. No SingleChildScrollViews.
    return Flex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: TextDirection.ltr,
      verticalDirection: VerticalDirection.down,
      mainAxisSize: mainAxisSize,
      clipBehavior: clipBehavior,
      children: _withGap(),
    );
  }
}
// ────────────────────────────────────────────────────────────────────────────
// §6 — ADVANCED UI SURFACES (Split Pane, Morph)
// ────────────────────────────────────────────────────────────────────────────

class QuantumSplitPane extends StatefulWidget {
  final Axis direction;
  final List<Widget> children;
  final List<double>? initialFractions;
  final double dividerThickness;
  final Color dividerColor;

  const QuantumSplitPane({
    super.key,
    required this.direction,
    required this.children,
    this.initialFractions,
    this.dividerThickness = 6.0,
    this.dividerColor = const Color(0xFFE2E8F0),
  });

  @override
  State<QuantumSplitPane> createState() => _QuantumSplitPaneState();
}

class _QuantumSplitPaneState extends State<QuantumSplitPane> {
  late List<double> _fractions;

  @override
  void initState() {
    super.initState();
    _initFractions();
  }

  @override
  void didUpdateWidget(covariant QuantumSplitPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.children.length != widget.children.length ||
        oldWidget.initialFractions != widget.initialFractions) {
      _initFractions();
    }
  }

  void _initFractions() {
    final count = widget.children.length;
    if (count == 0) {
      _fractions = const [];
      return;
    }

    if (widget.initialFractions != null &&
        widget.initialFractions!.length == count) {
      _fractions = List<double>.from(widget.initialFractions!);
      _normalize();
    } else {
      _fractions = List<double>.filled(count, 1.0 / count);
    }
  }

  void _normalize() {
    final total = _fractions.fold<double>(0.0, (a, b) => a + b);
    if (total <= 0) return;
    for (int i = 0; i < _fractions.length; i++) {
      _fractions[i] /= total;
    }
  }

  void _updateFractions(int dividerIndex, double delta, double totalSize) {
    if (totalSize <= 0 ||
        dividerIndex < 0 ||
        dividerIndex + 1 >= _fractions.length) {
      return;
    }

    final fractionDelta = delta / totalSize;
    const minFraction = 0.05;

    setState(() {
      var f1 = _fractions[dividerIndex] + fractionDelta;
      var f2 = _fractions[dividerIndex + 1] - fractionDelta;

      if (f1 < minFraction) {
        final diff = minFraction - f1;
        f1 = minFraction;
        f2 -= diff;
      } else if (f2 < minFraction) {
        final diff = minFraction - f2;
        f2 = minFraction;
        f1 -= diff;
      }

      if (f1 >= minFraction && f2 >= minFraction) {
        _fractions[dividerIndex] = f1;
        _fractions[dividerIndex + 1] = f2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    if (widget.children.length == 1) return widget.children.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isHoriz = widget.direction == Axis.horizontal;
        final totalSize =
            isHoriz ? constraints.maxWidth : constraints.maxHeight;

        final layoutChildren = <Widget>[];
        for (int i = 0; i < widget.children.length; i++) {
          layoutChildren.add(
            Flexible(
              flex: (_fractions[i] * 10000).round().clamp(1, 10000),
              fit: FlexFit.tight,
              child: widget.children[i],
            ),
          );

          if (i < widget.children.length - 1) {
            layoutChildren.add(
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: isHoriz
                    ? (d) => _updateFractions(i, d.delta.dx, totalSize)
                    : null,
                onVerticalDragUpdate: !isHoriz
                    ? (d) => _updateFractions(i, d.delta.dy, totalSize)
                    : null,
                child: MouseRegion(
                  cursor: isHoriz
                      ? SystemMouseCursors.resizeLeftRight
                      : SystemMouseCursors.resizeUpDown,
                  child: SizedBox(
                    width: isHoriz ? widget.dividerThickness : double.infinity,
                    height:
                        !isHoriz ? widget.dividerThickness : double.infinity,
                    child: ColoredBox(color: widget.dividerColor),
                  ),
                ),
              ),
            );
          }
        }

        return Flex(direction: widget.direction, children: layoutChildren);
      },
    );
  }
}

class QuantumMorphSurface extends StatefulWidget {
  final Size initialSize;
  final bool lockAspectRatio;
  final double snapGrid;
  final Widget child;

  const QuantumMorphSurface({
    super.key,
    required this.initialSize,
    required this.lockAspectRatio,
    required this.snapGrid,
    required this.child,
  });

  @override
  State<QuantumMorphSurface> createState() => _QuantumMorphSurfaceState();
}

class _QuantumMorphSurfaceState extends State<QuantumMorphSurface> {
  late double _w;
  late double _h;
  late double _aspect;

  @override
  void initState() {
    super.initState();
    _w = widget.initialSize.width;
    _h = widget.initialSize.height;
    _aspect = _w / (_h > 0 ? _h : 1);
  }

  double _snap(double value) {
    if (widget.snapGrid <= 0) return value;
    return (value / widget.snapGrid).round() * widget.snapGrid;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _w,
      height: _h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (d) {
                setState(() {
                  var newW = math.max(20.0, _w + d.delta.dx);
                  var newH = math.max(20.0, _h + d.delta.dy);

                  if (widget.lockAspectRatio && _aspect > 0) {
                    if (d.delta.dx.abs() > d.delta.dy.abs()) {
                      newH = newW / _aspect;
                    } else {
                      newW = newH * _aspect;
                    }
                  }

                  _w = _snap(newW);
                  _h = _snap(newH);
                });
              },
              child: const MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child:
                      Icon(Icons.drag_indicator, size: 16, color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §7 — FLEXIBLE & ASPECT HELPERS (Context-Aware)
// ────────────────────────────────────────────────────────────────────────────

class _QuantumFlexibleResolution {
  final Widget child;
  final int flex;
  final FlexFit fit;

  const _QuantumFlexibleResolution({
    required this.child,
    required this.flex,
    required this.fit,
  });
}

class QuantumFlexible extends StatelessWidget {
  final int flex;
  final FlexFit fit;
  final Widget child;

  const QuantumFlexible({
    super.key,
    this.flex = 1,
    this.fit = FlexFit.tight,
    required this.child,
  });

  _QuantumFlexibleResolution _resolve(
    Widget node,
    int depth, {
    required int flexSeed,
    required FlexFit fitSeed,
  }) {
    if (depth > 16) {
      return _QuantumFlexibleResolution(
          child: node, flex: flexSeed, fit: fitSeed);
    }
    if (node is QuantumFlexible) {
      final int nextFlex = math.max(1, flexSeed * node.flex);
      final FlexFit nextFit =
          fitSeed == FlexFit.loose || node.fit == FlexFit.loose
              ? FlexFit.loose
              : FlexFit.tight;
      return _resolve(
        node.child,
        depth + 1,
        flexSeed: nextFlex,
        fitSeed: nextFit,
      );
    }
    return _QuantumFlexibleResolution(
        child: node, flex: flexSeed, fit: fitSeed);
  }

  @override
  Widget build(BuildContext context) {
    final parentScope = QuantumLayoutScope.of(context);
    final scrollScope = QuantumScrollScope.of(context);
    final resolved = _resolve(child, 0, flexSeed: flex, fitSeed: fit);

    if (parentScope == null ||
        (parentScope.layoutType != 'row' && parentScope.layoutType != 'col')) {
      // Degrade gracefully when the widget is placed outside a flex layout.
      return resolved.child;
    }

    final bool parentIsVertical = parentScope.layoutType == 'col';
    final bool inSameAxisScroll = scrollScope?.axis ==
        (parentIsVertical ? Axis.vertical : Axis.horizontal);

    if (inSameAxisScroll) {
      // Tight flex inside a same-axis scroll viewport is the source of most
      // parent-data and "unbounded" layout failures. In that case the child
      // must participate as a normal widget so the surrounding scrollable can
      // measure and scroll it safely.
      return resolved.child;
    }

    if (resolved.child is Flexible) {
      return resolved.child;
    }

    return Flexible(
      flex: resolved.flex,
      fit: resolved.fit,
      child: resolved.child,
    );
  }
}

class QuantumAspectRatio extends StatelessWidget {
  final double ratio;
  final Widget child;

  const QuantumAspectRatio({
    super.key,
    required this.ratio,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth && !constraints.hasBoundedHeight) {
          // Prefer the framework's own scroll-axis signal over guessing:
          // if we're inside a horizontally-scrolling ancestor, the *height*
          // is the axis that's actually unbounded and width is what we
          // should size from (and vice versa). QuantumScrollScope is set by
          // every scrollable QuantumVM renders, so this is available whenever
          // the unbounded constraint came from one of our own scroll wrappers.
          final QuantumScrollScope? scrollScope =
              QuantumScrollScope.of(context);
          if (scrollScope != null) {
            if (scrollScope.axis == Axis.vertical) {
              // Width should already be bounded by the scroll viewport's
              // cross axis; only fall back to the screen-width guess if it
              // genuinely isn't.
              if (constraints.hasBoundedWidth) {
                return AspectRatio(aspectRatio: ratio, child: child);
              }
            }
          }
          final safeWidth = MediaQuery.sizeOf(context).width - 40.0;
          return SizedBox(
            width: safeWidth,
            child: AspectRatio(aspectRatio: ratio, child: child),
          );
        }
        return AspectRatio(aspectRatio: ratio, child: child);
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// §8 — SLIVER DELEGATES & VIRTUALIZATION
// ────────────────────────────────────────────────────────────────────────────

class QuantumStickyDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  QuantumStickyDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => math.max(maxHeight, minHeight);

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(covariant QuantumStickyDelegate old) {
    return minHeight != old.minHeight ||
        maxHeight != old.maxHeight ||
        child != old.child;
  }
}

class QuantumSliverDelegate extends SliverGridDelegate {
  final List<QSize> cols;
  final List<QSize> rows;
  final double colGap;
  final double rowGap;
  final double fallbackExtent;
  final bool isMasonry;

  const QuantumSliverDelegate({
    required this.cols,
    required this.rows,
    required this.colGap,
    required this.rowGap,
    this.fallbackExtent = 100.0,
    this.isMasonry = false,
  });

  List<QSize> _expandDynamic(
      List<QSize> original, double availableSpace, double gap) {
    final resolved = <QSize>[];
    for (final track in original) {
      if (track is QAutoFill || track is QAutoFit) {
        final subTracks =
            track is QAutoFill ? track.tracks : (track as QAutoFit).tracks;
        if (availableSpace <= 0.0) {
          resolved.addAll(subTracks);
          continue;
        }

        var minSize = 0.0;
        for (final st in subTracks) {
          if (st is QFixed) {
            minSize += st.px;
          } else if (st is QMinMax && st.min is QFixed) {
            minSize += (st.min as QFixed).px;
          } else {
            minSize += 40.0;
          }
        }
        if (minSize <= 0.0) minSize = 40.0;

        var repetitions =
            math.max(1, ((availableSpace + gap) / (minSize + gap)).floor());
        if (repetitions > 1024) repetitions = 1024;
        for (int i = 0; i < repetitions; i++) {
          resolved.addAll(subTracks);
        }
      } else if (track is QRepeat) {
        for (int i = 0; i < track.count.clamp(1, 10000); i++) {
          resolved.addAll(track.tracks);
        }
      } else {
        resolved.add(track);
      }
    }
    return resolved;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    var resolvedCols =
        _expandDynamic(cols, constraints.crossAxisExtent, colGap);
    var resolvedRows = _expandDynamic(rows, double.infinity, rowGap);

    if (resolvedCols.isEmpty) resolvedCols = const [QFraction(1.0)];
    if (resolvedRows.isEmpty) resolvedRows = const [QAuto()];

    final maxCols = resolvedCols.length;
    final cWidths = Float64List(maxCols);
    final cOffsets = Float64List(maxCols);

    var usedW = 0.0;
    var totalFr = 0.0;
    for (int i = 0; i < maxCols; i++) {
      final t = resolvedCols[i];
      if (t is QFixed) {
        cWidths[i] = math.max(0.0, t.px);
        usedW += cWidths[i];
      } else if (t is QMinMax && t.min is QFixed) {
        cWidths[i] = math.max(0.0, (t.min as QFixed).px);
        usedW += cWidths[i];
      } else if (t is QFraction) {
        totalFr += math.max(0.0, t.fr);
      } else if (t is QMinMax && t.max is QFraction) {
        totalFr += math.max(0.0, (t.max as QFraction).fr);
      }
    }

    final remaining = math.max(
      0.0,
      constraints.crossAxisExtent - usedW - (math.max(0, maxCols - 1) * colGap),
    );
    if (totalFr > 0.0) {
      final unit = remaining / totalFr;
      for (int i = 0; i < maxCols; i++) {
        final t = resolvedCols[i];
        if (t is QFraction) {
          cWidths[i] += unit * t.fr;
        } else if (t is QMinMax && t.max is QFraction) {
          cWidths[i] += unit * (t.max as QFraction).fr;
        } else if (t is QAuto) {
          cWidths[i] += unit;
        }
      }
    }

    var accW = 0.0;
    for (int i = 0; i < maxCols; i++) {
      cOffsets[i] = accW;
      accW += cWidths[i] + colGap;
    }

    final maxRows = resolvedRows.length;
    final rHeights = Float64List(maxRows);
    final rOffsets = Float64List(maxRows);

    var accH = 0.0;
    for (int i = 0; i < maxRows; i++) {
      final t = resolvedRows[i];
      if (t is QFixed) {
        rHeights[i] = math.max(0.0, t.px);
      } else if (t is QMinMax && t.min is QFixed) {
        rHeights[i] = math.max(0.0, (t.min as QFixed).px);
      } else {
        rHeights[i] = math.max(0.0, fallbackExtent);
      }
      rOffsets[i] = accH;
      accH += rHeights[i] + rowGap;
    }

    return _QSliverLayout(
      cWidths,
      cOffsets,
      rHeights,
      rOffsets,
      colGap,
      rowGap,
      isMasonry,
    );
  }

  @override
  bool shouldRelayout(QuantumSliverDelegate old) {
    return old.cols != cols ||
        old.rows != rows ||
        old.colGap != colGap ||
        old.rowGap != rowGap ||
        old.fallbackExtent != fallbackExtent ||
        old.isMasonry != isMasonry;
  }
}

class _QSliverLayout extends SliverGridLayout {
  final Float64List cW;
  final Float64List cO;
  final Float64List rH;
  final Float64List rO;
  final double cGap;
  final double rGap;
  final bool masonry;

  const _QSliverLayout(
    this.cW,
    this.cO,
    this.rH,
    this.rO,
    this.cGap,
    this.rGap,
    this.masonry,
  );

  int get _c => cW.length;
  int get _r => rH.length;

  double _patternHeight() {
    if (_r == 0) return 0.0;
    return rO[_r - 1] + rH[_r - 1] + rGap;
  }

  @override
  int getMinChildIndexForScrollOffset(double scrollOffset) {
    if (_c == 0 || _r == 0) return 0;
    final ph = _patternHeight();
    if (ph <= 0.0) return 0;
    final complete = (scrollOffset / ph).floor();
    var row = complete * _r;
    var rem = scrollOffset - (complete * ph);
    for (int i = 0; i < _r; i++) {
      if (rem <= rH[i] + rGap) break;
      rem -= rH[i] + rGap;
      row++;
    }
    return row * _c;
  }

  @override
  int getMaxChildIndexForScrollOffset(double scrollOffset) {
    return getMinChildIndexForScrollOffset(scrollOffset) + (_c * _r * 3);
  }

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    if (_c == 0 || _r == 0) {
      return const SliverGridGeometry(
        scrollOffset: 0.0,
        crossAxisOffset: 0.0,
        mainAxisExtent: 0.0,
        crossAxisExtent: 0.0,
      );
    }
    final col = index % _c;
    final row = index ~/ _c;
    final pr = row % _r;
    final block = row ~/ _r;
    final dy = block * _patternHeight() + rO[pr];

    return SliverGridGeometry(
      scrollOffset: dy,
      crossAxisOffset: cO[col],
      mainAxisExtent: rH[pr],
      crossAxisExtent: cW[col],
    );
  }

  @override
  double computeMaxScrollOffset(int count) {
    if (count <= 0 || _c == 0 || _r == 0) return 0.0;
    final totalRows = (count / _c).ceil();
    final completeBlocks = totalRows ~/ _r;
    final remainderRows = totalRows % _r;
    var total = completeBlocks * _patternHeight();
    if (remainderRows > 0) {
      total += rO[remainderRows - 1] + rH[remainderRows - 1] + rGap;
    }
    return math.max(0.0, total - rGap);
  }
}

/// Builder-backed sliver grid for very large data sets.
class QuantumVirtualGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final List<QSize> columns;
  final List<QSize> rows;
  final double columnGap;
  final double rowGap;
  final EdgeInsetsGeometry padding;

  const QuantumVirtualGridView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.columns = const [QFraction(1)],
    this.rows = const [QAuto()],
    this.columnGap = 0.0,
    this.rowGap = 0.0,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverGrid(
            gridDelegate: QuantumSliverDelegate(
              cols: columns,
              rows: rows,
              colGap: columnGap,
              rowGap: rowGap,
              fallbackExtent: 120.0,
            ),
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
              addSemanticIndexes: false,
            ),
          ),
        ),
      ],
    );
  }
}
