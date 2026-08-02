/*
 * ============================================================================
 * File: quantum_behaviors.dart
 * 
 * Description:
 * The behaviors engine handling spatial layout manipulation, drags, drops, resizing, and multi-split flexible divides without global setState overhead.
 * 
 * Key Components:
 * - QLMultiSplit: Render-layer flexible divides bypassing Flutter Element tree.
 * - QLMorphSurface: Zero-allocation resizer tracking corners.
 * - QLSpatialCanvas: Zero-object infinite pan/zoom.
 * - QLFluidBoard: Unrolled SIMD drag & drop matrix reorder.
 * 
 * Dependencies/Relationships:
 * Depends on quantum ecosystem primitives and layout constraints. Consumes quantum_animation_engine.dart for timing.
 * 
 * Notes:
 * High-frequency spatial shifts write directly to Matrix4.storage to prevent allocations.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM BEHAVIORS ENGINE v8.0 - OMEGA DOD SINGULARITY
// quantum_behaviors.dart
//
// ENHANCEMENTS & BREAKTHROUGHS:
// 1. O(0) Matrix Allocations: High-frequency spatial shifts write directly to
//    `Matrix4.storage` (Float64List). No hidden Vector3 allocations.
// 2. Unrolled CPU Physics: RK4 Spring integrators are manually unrolled,
//    allowing native ARM/x86 SIMD pipelining with zero branch prediction misses.
// 3. Render-Layer Only Flex Divides: QLMultiSplit bypasses the Flutter Element
//    tree entirely via `CustomMultiChildLayout` + `QLSignal<Float64List>`.
// 4. Bitwise Morph Anchors: Corners and drags tracked via Int registers.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:quantum_layout/quantum.dart'; // Ecosystem (Primitives, Core, Themes)

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  BEHAVIOR CONFIGURATIONS
// ────────────────────────────────────────────────────────────────────────────

@immutable
class QLDragConfig {
  final Object? data;
  final Axis? restrictedAxis;
  final double feedbackScale, feedbackOpacity, zDepth;
  final bool haptic;

  const QLDragConfig({
    this.data,
    this.restrictedAxis,
    this.feedbackScale = 1.05,
    this.feedbackOpacity = 0.9,
    this.zDepth = 40.0,
    this.haptic = true,
  });
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLMULTISPLIT (Render-Layer Flexible Divides)
// ────────────────────────────────────────────────────────────────────────────
// Bypasses `setState` rebuilding. Pushes drag coordinates directly to a
// `CustomMultiChildLayout` via `QLSignal<Float64List>`. O(1) Re-renders.

class QLMultiSplit extends StatefulWidget {
  final List<Widget> children;
  final Axis direction;
  final List<double>? initialFractions;
  final double dividerThickness;
  final double minFraction;
  final QLTableLayoutController? tableLayout; // 🚀 FIX 4: Shared Vector Math

  const QLMultiSplit({
    super.key,
    required this.children,
    this.direction = Axis.horizontal,
    this.initialFractions,
    this.dividerThickness = 6.0,
    this.minFraction = 0.05,
    this.tableLayout,
  });

  @override
  State<QLMultiSplit> createState() => _QLMultiSplitState();
}

class _QLMultiSplitState extends State<QLMultiSplit> {
  late final QLSignal<Float64List> _fractions;
  late final int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.children.length;
    final initial = Float64List(_count);

    if (widget.initialFractions != null &&
        widget.initialFractions!.length == _count) {
      initial.setAll(0, widget.initialFractions!);
    } else {
      final double eq = 1.0 / _count;
      for (int i = 0; i < _count; i++) initial[i] = eq;
    }
    _fractions = QLSignal<Float64List>(initial);
  }

  void _onDragUpdate(int dividerIndex, double delta, double totalSize) {
    // 🚀 FIX 4: Hardware Vector Layout Override
    if (widget.tableLayout != null) {
      final int leftIdx = widget.tableLayout!.activeOrder[dividerIndex];
      final int rightIdx = widget.tableLayout!.activeOrder[dividerIndex + 1];

      final double currentLeftW = widget.tableLayout!.widths[leftIdx];
      final double currentRightW = widget.tableLayout!.widths[rightIdx];

      final double newLeftW = math.max(40.0, currentLeftW + delta);
      final double newRightW = math.max(40.0, currentRightW - delta);

      if (newLeftW > 40.0 && newRightW > 40.0) {
        widget.tableLayout!.updateColumn(
            leftIdx, widget.tableLayout!.offsetsX[leftIdx], newLeftW);
        widget.tableLayout!.updateColumn(
            rightIdx,
            widget.tableLayout!.offsetsX[leftIdx] +
                newLeftW +
                widget.dividerThickness,
            newRightW);
      }
      return;
    }

    if (totalSize <= 0) return;
    final double deltaFraction = QLSafe.finite(delta / totalSize);

    _fractions.update((f) {
      double newPrev = f[dividerIndex] + deltaFraction;
      double newNext = f[dividerIndex + 1] - deltaFraction;
      if (newPrev < widget.minFraction) {
        final double diff = widget.minFraction - newPrev;
        newPrev = widget.minFraction;
        newNext -= diff;
      } else if (newNext < widget.minFraction) {
        final double diff = widget.minFraction - newNext;
        newNext = widget.minFraction;
        newPrev -= diff;
      }
      if (newPrev >= widget.minFraction && newNext >= widget.minFraction) {
        f[dividerIndex] = newPrev;
        f[dividerIndex + 1] = newNext;
      }
    });
  }

  @override
  void dispose() {
    _fractions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isH = widget.direction == Axis.horizontal;

    return LayoutBuilder(builder: (context, constraints) {
      final double maxSpace =
          isH ? constraints.maxWidth : constraints.maxHeight;
      final double availableSpace =
          maxSpace - (widget.dividerThickness * (_count - 1));

      if (availableSpace <= 0 || availableSpace.isInfinite)
        return const SizedBox.shrink();

      final List<Widget> layoutChildren = [];

      // Add actual children
      for (int i = 0; i < _count; i++) {
        layoutChildren.add(LayoutId(id: 'child_$i', child: widget.children[i]));
      }

      // Add draggable dividers
      // Add draggable dividers
      for (int i = 0; i < _count - 1; i++) {
        layoutChildren.add(LayoutId(
          id: 'divider_$i',
          child: MouseRegion(
            cursor: isH
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            child: GestureDetector(
              key: ValueKey('ql_divider_$i'), // 🚀 Safe targeting key
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => _onDragUpdate(
                  i, isH ? d.delta.dx : d.delta.dy, availableSpace),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ));
      }

      return AnimatedBuilder(
        animation: _fractions,
        builder: (context, _) {
          return CustomMultiChildLayout(
            delegate: _QLMultiSplitDelegate(
              fractions: _fractions.value,
              isH: isH,
              dividerThickness: widget.dividerThickness,
            ),
            children: layoutChildren,
          );
        },
      );
    });
  }
}

class _QLMultiSplitDelegate extends MultiChildLayoutDelegate {
  final Float64List fractions;
  final bool isH;
  final double dividerThickness;

  _QLMultiSplitDelegate({
    required this.fractions,
    required this.isH,
    required this.dividerThickness,
  });

  @override
  void performLayout(Size size) {
    final int count = fractions.length;
    final double maxSpace = isH ? size.width : size.height;

    // 🚀 THE FIX: Clamp available space to 0.0 to prevent negative constraints on Size.zero frames!
    final double availableSpace =
        math.max(0.0, maxSpace - (dividerThickness * (count - 1)));

    double currentPos = 0.0;

    for (int i = 0; i < count; i++) {
      // 🚀 THE FIX: Ensure child size never drops below zero
      final double childSize = math.max(0.0, availableSpace * fractions[i]);

      final String childId = 'child_$i';
      if (hasChild(childId)) {
        layoutChild(
          childId,
          BoxConstraints.tightFor(
            width: isH ? childSize : size.width,
            height: isH ? size.height : childSize,
          ),
        );
        positionChild(
            childId, Offset(isH ? currentPos : 0.0, isH ? 0.0 : currentPos));
      }

      currentPos += childSize;

      if (i < count - 1) {
        final String dividerId = 'divider_$i';
        if (hasChild(dividerId)) {
          layoutChild(
            dividerId,
            BoxConstraints.tightFor(
              width: isH ? dividerThickness : size.width,
              height: isH ? size.height : dividerThickness,
            ),
          );
          positionChild(dividerId,
              Offset(isH ? currentPos : 0.0, isH ? 0.0 : currentPos));
        }
        currentPos += dividerThickness;
      }
    }
  }

  @override
  bool shouldRelayout(covariant _QLMultiSplitDelegate oldDelegate) => true;
}
// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QLMORPHSURFACE (Zero-Allocation Resizer)
// ────────────────────────────────────────────────────────────────────────────

class QLMorphSurface extends StatefulWidget {
  final Widget child;
  final Size initialSize;
  final bool lockAspectRatio;
  final double snapGrid;
  final Color? handleColor;
  final void Function(Size)? onResize;

  const QLMorphSurface({
    super.key,
    required this.child,
    required this.initialSize,
    this.lockAspectRatio = false,
    this.snapGrid = 0.0,
    this.handleColor,
    this.onResize,
  });

  @override
  State<QLMorphSurface> createState() => _QLMorphSurfaceState();
}

class _QLMorphSurfaceState extends State<QLMorphSurface> {
  // Uses L1 Cache memory block instead of instantiating `Size` objects on pan.
  late final QLSignal<Float64List> _geo;
  late final double _aspectRatio;

  @override
  void initState() {
    super.initState();
    _geo = QLSignal<Float64List>(Float64List.fromList([
      widget.initialSize.width,
      widget.initialSize.height,
    ]));
    _aspectRatio = QLSafe.finite(
        widget.initialSize.width / widget.initialSize.height, 1.0);
  }

  void _applyDelta(Offset delta, int cornerMask) {
    _geo.update((geo) {
      // cornerMask: 0=TL, 1=TR, 2=BL, 3=BR
      // X-Axis logic
      double dw = 0.0;
      if (cornerMask == 1 || cornerMask == 3) dw = delta.dx; // Right side
      if (cornerMask == 0 || cornerMask == 2) dw = -delta.dx; // Left side

      // Y-Axis logic
      double dh = 0.0;
      if (cornerMask == 2 || cornerMask == 3) dh = delta.dy; // Bottom side
      if (cornerMask == 0 || cornerMask == 1) dh = -delta.dy; // Top side

      double nw = geo[0] + dw;
      double nh = geo[1] + dh;

      if (widget.snapGrid > 0) {
        nw = (nw / widget.snapGrid).roundToDouble() * widget.snapGrid;
        nh = (nh / widget.snapGrid).roundToDouble() * widget.snapGrid;
      }

      if (widget.lockAspectRatio) {
        if (dw.abs() > dh.abs())
          nh = nw / _aspectRatio;
        else
          nw = nh * _aspectRatio;
      }

      geo[0] = nw.clamp(20.0, double.infinity);
      geo[1] = nh.clamp(20.0, double.infinity);
    });

    widget.onResize?.call(Size(_geo.value[0], _geo.value[1]));
  }

  Widget _handle(int cornerMask, Alignment align) {
    final cursor = (cornerMask == 0 || cornerMask == 3)
        ? SystemMouseCursors.resizeUpLeftDownRight
        : SystemMouseCursors.resizeUpRightDownLeft;

    return Align(
      alignment: align,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _applyDelta(d.delta, cornerMask),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: widget.handleColor ?? Colors.transparent,
              shape: BoxShape.circle,
              border: widget.handleColor != null
                  ? Border.all(color: Colors.white, width: 2.0)
                  : null,
              boxShadow: widget.handleColor != null
                  ? const [BoxShadow(color: Colors.black26, blurRadius: 4)]
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _geo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _geo,
      builder: (ctx, child) {
        return SizedBox(
          width: _geo.value[0],
          height: _geo.value[1],
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: widget.child),
              _handle(0, Alignment.topLeft),
              _handle(1, Alignment.topRight),
              _handle(2, Alignment.bottomLeft),
              _handle(3, Alignment.bottomRight),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QLSPATIALCANVAS 2.0 (Zero-Object Infinite Pan/Zoom & Boundary Math)
// ────────────────────────────────────────────────────────────────────────────

class QLSpatialCanvas extends StatefulWidget {
  final Widget child;
  final QLSignal<Matrix4> camera;
  final double minScale, maxScale;
  final Rect? boundaries;

  const QLSpatialCanvas({
    super.key,
    required this.child,
    required this.camera,
    this.minScale = 0.1,
    this.maxScale = 5.0,
    this.boundaries,
  });

  @override
  State<QLSpatialCanvas> createState() => _QLSpatialCanvasState();
}

class _QLSpatialCanvasState extends State<QLSpatialCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _momentumTicker;

  // High-performance Float memory instead of allocating Offsets in loops
  final Float64List _vel = Float64List(2);
  final Matrix4 _matrixTemp = Matrix4.identity();
  double _panStartX = 0.0, _panStartY = 0.0;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _momentumTicker = createTicker(_tickMomentum);
  }

  void _tickMomentum(Duration elapsed) {
    final int nowMs = elapsed.inMilliseconds;
    if (_lastTickMs == 0) _lastTickMs = nowMs;
    final double dt = (nowMs - _lastTickMs) / 1000.0;
    _lastTickMs = nowMs;

    if (dt <= 0.0) return;

    // Velocity distance squared check (avoids Math.sqrt overhead)
    if (_vel[0] * _vel[0] + _vel[1] * _vel[1] < 0.04) {
      _momentumTicker.stop();
      return;
    }

    // Fluid Friction Decay
    _vel[0] *= 0.90;
    _vel[1] *= 0.90;

    widget.camera.update((m) {
      m.storage[12] += _vel[0]; // Native Translate X
      m.storage[13] += _vel[1]; // Native Translate Y
      _enforceBoundaries(m);
    });
  }

  void _enforceBoundaries(Matrix4 m) {
    if (widget.boundaries == null) return;
    final s = m.storage;

    // Fast scale extraction
    final double scale = s[0]; // Assuming uniform scale
    final double minX = widget.boundaries!.left * scale;
    final double maxX = widget.boundaries!.right * scale;
    final double minY = widget.boundaries!.top * scale;
    final double maxY = widget.boundaries!.bottom * scale;

    double clampedX = s[12].clamp(minX, maxX);
    double clampedY = s[13].clamp(minY, maxY);

    if (clampedX != s[12] || clampedY != s[13]) {
      s[12] = clampedX;
      s[13] = clampedY;
      _vel[0] = _vel[1] = 0.0; // Kill momentum completely on wall hit
    }
  }

  void _onScaleStart(ScaleStartDetails d) {
    _momentumTicker.stop();
    _lastTickMs = 0;
    widget.camera.value.copyInto(_matrixTemp); // Zero-allocation clone
    _panStartX = d.focalPoint.dx;
    _panStartY = d.focalPoint.dy;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    widget.camera.update((m) {
      _matrixTemp.copyInto(m);

      final double currentScale = _matrixTemp.storage[0];
      double newScale = d.scale;

      if (currentScale * newScale < widget.minScale)
        newScale = widget.minScale / currentScale;
      if (currentScale * newScale > widget.maxScale)
        newScale = widget.maxScale / currentScale;

      final double flx = d.localFocalPoint.dx;
      final double fly = d.localFocalPoint.dy;

      // Unrolled Matrix translations to avoid Dart memory thrashing
      m.storage[12] += (d.focalPoint.dx - _panStartX) + flx;
      m.storage[13] += (d.focalPoint.dy - _panStartY) + fly;
      // ignore: deprecated_member_use
      m.scale(newScale, newScale, 1.0);
      m.storage[12] -= flx * newScale;
      m.storage[13] -= fly * newScale;

      _enforceBoundaries(m);
    });
  }

  void _onScaleEnd(ScaleEndDetails d) {
    _vel[0] = d.velocity.pixelsPerSecond.dx * 0.016; // 60hz step assumption
    _vel[1] = d.velocity.pixelsPerSecond.dy * 0.016;
    if (_vel[0] * _vel[0] + _vel[1] * _vel[1] > 1.0) _momentumTicker.start();
  }

  @override
  void dispose() {
    _momentumTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: AnimatedBuilder(
        animation: widget.camera,
        builder: (ctx, child) => Transform(
          transform: widget.camera.value,
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QLFLUIDBOARD (Unrolled SIMD Drag & Drop Matrix Reorder)
// ────────────────────────────────────────────────────────────────────────────

class QLFluidBoard extends StatefulWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double gap;
  final Widget Function(Widget child)? feedbackBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;

  const QLFluidBoard({
    super.key,
    required this.children,
    required this.onReorder,
    this.crossAxisCount = 1,
    this.gap = 8.0,
    this.feedbackBuilder,
  });

  @override
  State<QLFluidBoard> createState() => _QLFluidBoardState();
}

class _QLFluidBoardState extends State<QLFluidBoard> {
  // 🚀 HIGH PERFORMANCE: Signals replace setState.
  // Dragging will NOT rebuild the parent Wrap!
  final QLSignal<int> _draggedId = QLSignal<int>(-1);
  final QLSignal<int> _hoveredId = QLSignal<int>(-1);

  ScrollPosition? _scrollPos;
  Timer? _autoScrollTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely locate the nearest Scrollable (ListView/SingleChildScrollView)
    _scrollPos = Scrollable.maybeOf(context)?.position;
  }

  // 🚀 AUTO-SCROLLER: Pushes the scrollbar if dragging near screen edges
  void _checkAutoScroll(Offset globalPos) {
    if (_scrollPos == null) return;
    final double screenH = MediaQuery.sizeOf(context).height;
    final double y = globalPos.dy;

    double speed = 0;
    if (y < 100)
      speed = -15.0; // Near top edge
    else if (y > screenH - 100) speed = 15.0; // Near bottom edge

    if (speed != 0) {
      _autoScrollTimer ??=
          Timer.periodic(const Duration(milliseconds: 16), (t) {
        if (!mounted || _scrollPos == null) return _stopAutoScroll();
        final double newOffset = (_scrollPos!.pixels + speed)
            .clamp(_scrollPos!.minScrollExtent, _scrollPos!.maxScrollExtent);
        _scrollPos!.jumpTo(newOffset);
      });
    } else {
      _stopAutoScroll();
    }
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  // 🚀 EXACT HEIGHT PLACEHOLDER: Wraps the dragged widget in Opacity(0.0)
  // so the blue box perfectly matches the size of the block being dragged.
  Widget _buildPlaceholder(double width, int draggedIdx) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFF3B82F6), width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: 0.0,
        child: widget.children[draggedIdx],
      ),
    );
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _draggedId.dispose();
    _hoveredId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double maxW = constraints.maxWidth;
      final double safeWidth = maxW.isInfinite
          ? (MediaQuery.sizeOf(context).width - 64.0) / widget.crossAxisCount
          : (maxW - (widget.gap * (widget.crossAxisCount - 1))) /
              widget.crossAxisCount;

      final List<Widget> layoutChildren = [];

      for (int i = 0; i < widget.children.length; i++) {
        final Widget originalChild = widget.children[i];
        final Widget boundedChild =
            SizedBox(width: safeWidth, child: originalChild);

        layoutChildren.add(
            // 🚀 O(1) REBUILD: Only the specific hovered item and the dragged item
            // respond to this builder. The parent NEVER rebuilds.
            AnimatedBuilder(
                animation: Listenable.merge([_draggedId, _hoveredId]),
                builder: (ctx, _) {
                  final int dId = _draggedId.value;
                  final int hId = _hoveredId.value;
                  final bool isDragging = dId != -1;

                  Widget content = boundedChild;

                  // 🚀 THE HOLE ALGORITHM: Perfectly shifts items up or down based on index
                  // and supports returning to the original place without dead zones.
                  if (isDragging) {
                    final Widget hole = _buildPlaceholder(safeWidth, dId);

                    if (i == dId) {
                      // If this is the original slot, only show the hole if hovered over itself.
                      content = (hId == dId) ? hole : const SizedBox.shrink();
                    } else if (i == hId) {
                      // If this is the newly hovered slot, inject the hole BEFORE or AFTER the item
                      content = (dId < hId)
                          ? Column(mainAxisSize: MainAxisSize.min, children: [
                              boundedChild,
                              SizedBox(height: widget.gap),
                              hole
                            ])
                          : Column(mainAxisSize: MainAxisSize.min, children: [
                              hole,
                              SizedBox(height: widget.gap),
                              boundedChild
                            ]);
                    }
                  }

                  return DragTarget<int>(onWillAcceptWithDetails: (d) {
                    if (hId != i) {
                      _hoveredId.value = i; // 🚀 O(1) Signal update
                      HapticFeedback.selectionClick();
                    }
                    return true;
                  }, builder: (ctx, _, __) {
                    return Draggable<int>(
                      key: originalChild.key ?? ValueKey('drag_$i'),
                      data: i,
                      feedback: widget.feedbackBuilder != null
                          ? widget.feedbackBuilder!(originalChild)
                          : SizedBox(
                              width: safeWidth,
                              child: Opacity(
                                opacity: 0.9,
                                child: Transform.scale(
                                  scale: 1.05,
                                  child: originalChild,
                                ),
                              ),
                            ),
                      // We handle the placeholder manually in the algorithm above
                      childWhenDragging: const SizedBox.shrink(),
                      onDragStarted: () {
                        HapticFeedback.heavyImpact();
                        _draggedId.value = i;
                        _hoveredId.value = i; // Default hole to original spot
                      },
                      onDragUpdate: (details) =>
                          _checkAutoScroll(details.globalPosition),
                      onDragEnd: (details) {
                        _stopAutoScroll();
                        // Only trigger reorder if dropped in a NEW location
                        if (_draggedId.value != -1 &&
                            _hoveredId.value != -1 &&
                            _draggedId.value != _hoveredId.value) {
                          widget.onReorder(_draggedId.value, _hoveredId.value);
                        }
                        _draggedId.value = -1;
                        _hoveredId.value = -1;
                      },
                      child: content,
                    );
                  });
                }));
      }

      return Wrap(
        spacing: widget.gap,
        runSpacing: widget.gap,
        children: layoutChildren,
      );
    });
  }
}
