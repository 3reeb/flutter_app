// ════════════════════════════════════════════════════════════════════════════
// QUANTUM WORKSPACE ENGINE v3.0 - UNCOMPROMISED GPU RENDERER
// quantum_workspace_engine.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../foundation/quantum_primitives.dart';
import 'package:quantum_layout/quantum.dart';
abstract final class QLSpaceFlags {
  static const int none = 0;
  static const int isHidden = 1 << 0;
  static const int isPinned = 1 << 1;
  static const int resizableLeft = 1 << 2;
  static const int resizableRight = 1 << 3;
  static const int resizableTop = 1 << 4;
  static const int resizableBottom = 1 << 5;
}

class QLWorkspaceController {
  final QLSignal<int> version = QLSignal(0);
  final QLSignal<Float64List> camera =
      QLSignal(Float64List(3)..setAll(0, [0.0, 0.0, 1.0]));

  Float64List bounds = Float64List(0); // [X, Y, W, H]
  Float64List constraints = Float64List(0); // [MinW, MaxW, MinH, MaxH]
  Int32List meta = Int32List(0); // [Flags, Z-Index]

  void loadMemory(
      Float64List newBounds, Float64List newConstraints, Int32List newMeta) {
    bounds = newBounds;
    constraints = newConstraints;
    meta = newMeta;
    version.value++;
  }

  void pan(double dx, double dy) {
    camera.value[0] -= dx;
    camera.value[1] -= dy;
    camera.forceNotify(); // GPU Only
  }

  void zoom(double delta) {
    final double z = camera.value[2];
    camera.value[2] = (z * delta).clamp(0.05, 10.0);
    camera.forceNotify(); // GPU Only
  }

  void hideNode(int index, bool hidden) {
    if (index * 2 >= meta.length) return;
    if (hidden) {
      meta[index * 2] |= QLSpaceFlags.isHidden;
    } else {
      meta[index * 2] &= ~QLSpaceFlags.isHidden;
    }
    version.value++;
  }
}

class QLWorkspace extends MultiChildRenderObjectWidget {
  final QLWorkspaceController controller;
  final bool isCanvas;

  QLWorkspace({
    super.key,
    required this.controller,
    required this.isCanvas,
    required List<Widget> children,
  }) : super(children: _wrap(children));

  static List<Widget> _wrap(List<Widget> kids) {
    return List.generate(
        kids.length,
        (i) => QLSpaceParentDataWidget(
            index: i, child: RepaintBoundary(child: kids[i])));
  }

  @override
  RenderQuantumWorkspace createRenderObject(BuildContext context) {
    return RenderQuantumWorkspace(controller: controller, isCanvas: isCanvas);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderQuantumWorkspace renderObject) {
    renderObject
      ..controller = controller
      ..isCanvas = isCanvas;
  }
}

class QLSpaceParentData extends ContainerBoxParentData<RenderBox> {
  int index = 0;
}

class QLSpaceParentDataWidget extends ParentDataWidget<QLSpaceParentData> {
  final int index;
  const QLSpaceParentDataWidget(
      {super.key, required this.index, required super.child});

  @override
  void applyParentData(RenderObject renderObject) {
    if (renderObject.parentData is! QLSpaceParentData)
      renderObject.parentData = QLSpaceParentData();
    final pd = renderObject.parentData as QLSpaceParentData;
    if (pd.index != index) {
      pd.index = index;
      if (renderObject.parent is RenderObject)
        renderObject.parent!.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => QLWorkspace;
}

class RenderQuantumWorkspace extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, QLSpaceParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, QLSpaceParentData>,
        QLReactiveRenderMixin {
  QLWorkspaceController _controller;
  bool _isCanvas;

  int _resizingIndex = -1;
  int _resizeEdge = 0; // 1=L, 2=R, 3=T, 4=B
  static const double _hitZone = 8.0;

  RenderQuantumWorkspace(
      {required QLWorkspaceController controller, required bool isCanvas})
      : _controller = controller,
        _isCanvas = isCanvas {
    watchLayout(_controller.version);
    watchPaint(_controller.camera);
  }

  set controller(QLWorkspaceController c) {
    if (_controller == c) return;
    _controller.version.removeListener(markNeedsLayout);
    _controller.camera.removeListener(markNeedsPaint);
    _controller = c;
    watchLayout(_controller.version);
    watchPaint(_controller.camera);
    markNeedsLayout();
  }

  set isCanvas(bool v) {
    if (_isCanvas == v) return;
    _isCanvas = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! QLSpaceParentData)
      child.parentData = QLSpaceParentData();
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    double maxW = 0.0, maxH = 0.0;

    final double sX = _controller.camera.value[0];
    final double sY = _controller.camera.value[1];
    final double z = _controller.camera.value[2];
    final double vW = constraints.maxWidth;
    final double vH = constraints.maxHeight;

    while (child != null) {
      final int idx = (child.parentData as QLSpaceParentData).index;
      if (idx * 4 >= _controller.bounds.length) {
        child.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        child = childAfter(child);
        continue;
      }

      final int flags = _controller.meta[idx * 2];
      if ((flags & QLSpaceFlags.isHidden) != 0) {
        child.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        child = childAfter(child);
        continue;
      }

      final double px = _controller.bounds[idx * 4 + 0];
      final double py = _controller.bounds[idx * 4 + 1];
      double pw = _controller.bounds[idx * 4 + 2];
      double ph = _controller.bounds[idx * 4 + 3];

      if (_isCanvas && (flags & QLSpaceFlags.isPinned) == 0) {
        if (QLSafe.isOffscreen2D(
            (px - sX) * z, (py - sY) * z, pw * z, ph * z, 0, 0, vW, vH)) {
          child.layout(const BoxConstraints.tightFor(width: 0, height: 0));
          child = childAfter(child);
          continue;
        }
      }

      if (pw < 0 || pw == double.infinity) pw = vW;
      if (ph < 0 || ph == double.infinity) ph = vH;

      if (_controller.constraints.length > idx * 4) {
        pw = pw.clamp(_controller.constraints[idx * 4 + 0],
            _controller.constraints[idx * 4 + 1]);
        ph = ph.clamp(_controller.constraints[idx * 4 + 2],
            _controller.constraints[idx * 4 + 3]);
      }

      _controller.bounds[idx * 4 + 2] = pw;
      _controller.bounds[idx * 4 + 3] = ph;

      child.layout(BoxConstraints.tightFor(width: pw, height: ph),
          parentUsesSize: false);
      if (px + pw > maxW) maxW = px + pw;
      if (py + ph > maxH) maxH = py + ph;

      child = childAfter(child);
    }
    size = constraints.constrain(Size(maxW, maxH));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    RenderBox? child = firstChild;
    final List<RenderBox> drawOrder = [];
    while (child != null) {
      if (child.size.width > 0) drawOrder.add(child);
      child = childAfter(child);
    }

    drawOrder.sort((a, b) => _controller
        .meta[(a.parentData as QLSpaceParentData).index * 2 + 1]
        .compareTo(_controller
            .meta[(b.parentData as QLSpaceParentData).index * 2 + 1]));

    final double sX = _controller.camera.value[0],
        sY = _controller.camera.value[1],
        z = _controller.camera.value[2];

    for (final c in drawOrder) {
      final int idx = (c.parentData as QLSpaceParentData).index;
      final bool isPinned =
          (_controller.meta[idx * 2] & QLSpaceFlags.isPinned) != 0;
      final double px = _controller.bounds[idx * 4 + 0],
          py = _controller.bounds[idx * 4 + 1];
      final double pw = _controller.bounds[idx * 4 + 2],
          ph = _controller.bounds[idx * 4 + 3];

      if (_isCanvas && !isPinned) {
        final Matrix4 m = Matrix4.identity()
          ..translate(offset.dx + px - sX, offset.dy + py - sY)
          ..scale(z, z, 1.0);
        context.pushTransform(needsCompositing, offset, m,
            (c2, o2) => c2.paintChild(c, Offset.zero));
      } else {
        context.pushClipRect(needsCompositing, offset + Offset(px, py),
            Offset.zero & Size(pw, ph), (ctx, off) => ctx.paintChild(c, off));
      }
    }
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      RenderBox? child = lastChild;
      while (child != null) {
        final int idx = (child.parentData as QLSpaceParentData).index;
        final int flags = _controller.meta[idx * 2];

        if ((flags & QLSpaceFlags.isHidden) == 0) {
          final double px = _controller.bounds[idx * 4 + 0],
              py = _controller.bounds[idx * 4 + 1];
          final double pw = _controller.bounds[idx * 4 + 2],
              ph = _controller.bounds[idx * 4 + 3];
          final Offset p = event.localPosition;

          if ((flags & QLSpaceFlags.resizableRight) != 0 &&
              (p.dx - (px + pw)).abs() < _hitZone &&
              p.dy >= py &&
              p.dy <= py + ph) {
            _resizingIndex = idx;
            _resizeEdge = 2;
            return;
          }
          if ((flags & QLSpaceFlags.resizableBottom) != 0 &&
              (p.dy - (py + ph)).abs() < _hitZone &&
              p.dx >= px &&
              p.dx <= px + pw) {
            _resizingIndex = idx;
            _resizeEdge = 4;
            return;
          }
        }
        child = childBefore(child);
      }
    } else if (event is PointerMoveEvent) {
      if (_resizingIndex != -1) {
        if (_resizeEdge == 2)
          _controller.bounds[_resizingIndex * 4 + 2] += event.delta.dx;
        if (_resizeEdge == 4)
          _controller.bounds[_resizingIndex * 4 + 3] += event.delta.dy;
        _controller.version.value++; // Flush layout
        return;
      }
      if (_isCanvas) _controller.pan(event.delta.dx, event.delta.dy);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _resizingIndex = -1;
      _resizeEdge = 0;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      hitTestChildren(result, position: position);
      result.add(BoxHitTestEntry(this, position)); // Absorb events for drag/pan
      return true;
    }
    return false;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;
    while (child != null) {
      if (child.size.width > 0) {
        final int idx = (child.parentData as QLSpaceParentData).index;
        final bool isPinned =
            (_controller.meta[idx * 2] & QLSpaceFlags.isPinned) != 0;
        final double px = _controller.bounds[idx * 4 + 0],
            py = _controller.bounds[idx * 4 + 1];

        Offset localPos = position;
        if (_isCanvas && !isPinned) {
          final double sX = _controller.camera.value[0],
              sY = _controller.camera.value[1],
              z = _controller.camera.value[2];
          localPos =
              Offset((position.dx + sX - px) / z, (position.dy + sY - py) / z);
        } else {
          localPos = position - Offset(px, py);
        }

        if (result.addWithPaintOffset(
            offset: Offset(px, py),
            position: position,
            hitTest: (r, t) => child!.hitTest(r, position: localPos)))
          return true;
      }
      child = childBefore(child);
    }
    return false;
  }
}
