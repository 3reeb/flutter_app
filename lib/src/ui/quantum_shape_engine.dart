/*
 * ============================================================================
 * File: quantum_shape_engine.dart
 * 
 * Description:
 * Resolves declarative string-based geometric shapes and Boolean path operations into hardware-accelerated Flutter Paths with support for percentage-based sizing and compound path generation.
 * 
 * Key Components:
 * - QShapePrimitive: Core declarative model for shapes (rect, rrect, circle, etc).
 * - QBooleanShapeDef: Model for boolean shape operations (union, intersect, etc).
 * - RenderQLShape: Proxy RenderBox that compiles declarative shapes into performant UI paths.
 * 
 * Dependencies/Relationships:
 * Part of UI foundational library.
 * 
 * Notes:
 * Handles compound paths efficiently. Immediate bounds check in hit testing provides significant performance boost.
 * ============================================================================
 */
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
enum QShapeType { rect, rrect, circle, pill, polygon }

enum QBooleanOp { union, subtract, intersect, exclude }

/// A value that can be absolute or percentage-based.
@immutable
class QShapeValue {
  final double? absolute;
  final double? percent; // 0.0 - 1.0

  const QShapeValue.absolute(this.absolute) : percent = null;
  const QShapeValue.percent(this.percent) : absolute = null;

  double resolve(double maxSpace, {double fallback = 0.0}) {
    if (absolute != null) return absolute!;
    if (percent != null) return percent!.clamp(0.0, 1.0) * maxSpace;
    return fallback;
  }

  static QShapeValue parse(dynamic value, {double fallback = 0.0}) {
    if (value == null) return QShapeValue.absolute(fallback);
    if (value is QShapeValue) return value;
    if (value is num) return QShapeValue.absolute(value.toDouble());

    if (value is String) {
      final s = value.trim();
      if (s.endsWith('%')) {
        final n = double.tryParse(s.substring(0, s.length - 1).trim());
        if (n != null) return QShapeValue.percent(n / 100.0);
      }
      final n = double.tryParse(s);
      if (n != null) return QShapeValue.absolute(n);
    }

    if (value is Map) {
      if (value.containsKey('percent')) {
        final n = value['percent'];
        if (n is num) return QShapeValue.percent(n.toDouble());
      }
      if (value.containsKey('absolute')) {
        final n = value['absolute'];
        if (n is num) return QShapeValue.absolute(n.toDouble());
      }
    }

    return QShapeValue.absolute(fallback);
  }
}

@immutable
class QShapePoint {
  final QShapeValue x;
  final QShapeValue y;

  const QShapePoint(this.x, this.y);

  Offset resolve(Size size) {
    return Offset(
      x.resolve(size.width),
      y.resolve(size.height),
    );
  }

  static QShapePoint parse(dynamic raw) {
    if (raw is QShapePoint) return raw;

    if (raw is List && raw.length >= 2) {
      return QShapePoint(
        QShapeValue.parse(raw[0]),
        QShapeValue.parse(raw[1]),
      );
    }

    if (raw is Map) {
      return QShapePoint(
        QShapeValue.parse(raw['x']),
        QShapeValue.parse(raw['y']),
      );
    }

    return const QShapePoint(
      QShapeValue.absolute(0.0),
      QShapeValue.absolute(0.0),
    );
  }
}

@immutable
class QShapePrimitive {
  final QShapeType type;
  final QShapeValue x;
  final QShapeValue y;
  final QShapeValue w;
  final QShapeValue h;
  final QShapeValue radius;
  final List<QShapePoint>? points;
  final Alignment origin;

  const QShapePrimitive({
    required this.type,
    this.x = const QShapeValue.absolute(0.0),
    this.y = const QShapeValue.absolute(0.0),
    this.w = const QShapeValue.percent(1.0),
    this.h = const QShapeValue.percent(1.0),
    this.radius = const QShapeValue.absolute(0.0),
    this.points,
    this.origin = Alignment.center,
  });

  factory QShapePrimitive.fromJson(Map<String, dynamic> json) {
    return QShapePrimitive(
      type: QShapeType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'rect'),
        orElse: () => QShapeType.rect,
      ),
      x: QShapeValue.parse(json['x'], fallback: 0.0),
      y: QShapeValue.parse(json['y'], fallback: 0.0),
      w: QShapeValue.parse(json['w'], fallback: 1.0),
      h: QShapeValue.parse(json['h'], fallback: 1.0),
      radius: QShapeValue.parse(json['radius'] ?? json['r'], fallback: 0.0),
      points: (json['points'] is List)
          ? (json['points'] as List)
              .map(QShapePoint.parse)
              .toList(growable: false)
          : null,
      origin: _parseAlignment(json['origin']?.toString() ?? 'center'),
    );
  }

  static Alignment _parseAlignment(String val) {
    switch (val) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topRight':
        return Alignment.topRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomRight':
        return Alignment.bottomRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      case 'topCenter':
        return Alignment.topCenter;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      default:
        return Alignment.center;
    }
  }
}

@immutable
class QBooleanShapeOp {
  final QBooleanOp op;
  final QShapePrimitive shape;

  const QBooleanShapeOp({
    required this.op,
    required this.shape,
  });

  // REPLACE in QBooleanShapeOp
  factory QBooleanShapeOp.fromJson(Map<String, dynamic> json) {
    final opName = (json['op'] ?? 'union').toString();
    final op = QBooleanOp.values.firstWhere(
      (e) => e.name == opName,
      orElse: () => QBooleanOp.union,
    );

    final rawShape = json['shape'];
    final shapeMap = rawShape is Map
        ? Map<String, dynamic>.from(rawShape)
        : <String, dynamic>{};

    return QBooleanShapeOp(
      op: op,
      shape: QShapePrimitive.fromJson(shapeMap),
    );
  }
}

@immutable
class QBooleanShapeDef {
  final QShapePrimitive base;
  final List<QBooleanShapeOp> operations;

  const QBooleanShapeDef({
    required this.base,
    required this.operations,
  });

  factory QBooleanShapeDef.fromJson(Map<String, dynamic> json) {
    final rawBase = json['base'];
    final baseMap = rawBase is Map
        ? Map<String, dynamic>.from(rawBase)
        : <String, dynamic>{};
    final base = QShapePrimitive.fromJson(baseMap);
    final ops = <QBooleanShapeOp>[];

    if (json['operations'] is List) {
      for (final item in json['operations']) {
        if (item is Map) {
          ops.add(QBooleanShapeOp.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return QBooleanShapeDef(base: base, operations: List.unmodifiable(ops));
    }

    void addLegacy(String key, QBooleanOp op) {
      final list = json[key];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            ops.add(QBooleanShapeOp(
                op: op,
                shape:
                    QShapePrimitive.fromJson(Map<String, dynamic>.from(item))));
          }
        }
      }
    }

    addLegacy('subtract', QBooleanOp.subtract);
    addLegacy('union', QBooleanOp.union);
    addLegacy('intersect', QBooleanOp.intersect);
    addLegacy('exclude', QBooleanOp.exclude);

    return QBooleanShapeDef(base: base, operations: List.unmodifiable(ops));
  }
}

class QLShapeNode extends SingleChildRenderObjectWidget {
  final QBooleanShapeDef shapeDef;
  final Listenable? repaint;
  final Color? color;
  final List<BoxShadow>? shadows;
  final BorderSide? border;
  final bool clipChild;
  final bool drawFillBehindChild;

  const QLShapeNode({
    super.key,
    required this.shapeDef,
    this.repaint,
    this.color,
    this.shadows,
    this.border,
    this.clipChild = true,
    this.drawFillBehindChild = true,
    super.child,
  });

  @override
  RenderQLShape createRenderObject(BuildContext context) {
    return RenderQLShape(
      shapeDef: shapeDef,
      repaint: repaint,
      color: color,
      shadows: shadows,
      border: border,
      clipChild: clipChild,
      drawFillBehindChild: drawFillBehindChild,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderQLShape renderObject) {
    renderObject
      ..shapeDef = shapeDef
      ..repaint = repaint
      ..color = color
      ..shadows = shadows
      ..border = border
      ..clipChild = clipChild
      ..drawFillBehindChild = drawFillBehindChild;
  }
}

class RenderQLShape extends RenderProxyBox {
  QBooleanShapeDef _shapeDef;
  Listenable? _repaint;
  Color? _color;
  List<BoxShadow>? _shadows;
  BorderSide? _border;
  bool _clipChild;
  bool _drawFillBehindChild;

  final Path _compiledPath = Path();
  final Path _tempPath = Path();
  final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  final Paint _strokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  bool _pathDirty = true;
  Size _lastSize = Size.zero;

  RenderQLShape({
    required QBooleanShapeDef shapeDef,
    Listenable? repaint,
    Color? color,
    List<BoxShadow>? shadows,
    BorderSide? border,
    bool clipChild = true,
    bool drawFillBehindChild = true,
  })  : _shapeDef = shapeDef,
        _repaint = repaint,
        _color = color,
        _shadows = shadows,
        _border = border,
        _clipChild = clipChild,
        _drawFillBehindChild =
            drawFillBehindChild; // REMOVED listener addition from constructor

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint?.addListener(_onRepaintTick); // Only registered when attached
  }

  @override
  void detach() {
    _repaint?.removeListener(_onRepaintTick); // Cleanly removed
    super.detach();
  }

  set repaint(Listenable? val) {
    if (identical(_repaint, val)) return;
    if (attached) {
      _repaint?.removeListener(_onRepaintTick);
    }
    _repaint = val;
    if (attached) {
      _repaint?.addListener(_onRepaintTick);
    }
  }

  set shapeDef(QBooleanShapeDef val) {
    if (identical(_shapeDef, val)) return;
    _shapeDef = val;
    _pathDirty = true;
    markNeedsPaint();
  }

  set color(Color? val) {
    if (_color == val) return;
    _color = val;
    markNeedsPaint();
  }

  set shadows(List<BoxShadow>? val) {
    _shadows = val;
    markNeedsPaint();
  }

  set border(BorderSide? val) {
    _border = val;
    markNeedsPaint();
  }

  set clipChild(bool val) {
    if (_clipChild == val) return;
    _clipChild = val;
    markNeedsPaint();
  }

  set drawFillBehindChild(bool val) {
    if (_drawFillBehindChild == val) return;
    _drawFillBehindChild = val;
    markNeedsPaint();
  }

  void _onRepaintTick() {
    _pathDirty = true;
    markNeedsPaint();
  }

  double _resolve(dynamic value, double maxSpace, {double fallback = 0.0}) {
    if (value is QShapeValue) {
      return value.resolve(maxSpace, fallback: fallback);
    }
    if (value is num) return value.toDouble();
    if (value is String && value.trim().endsWith('%')) {
      final parsed = double.tryParse(value.trim().replaceAll('%', ''));
      if (parsed != null) return (parsed / 100.0) * maxSpace;
    }
    return fallback;
  }

  Rect _buildRect(QShapePrimitive p, Size size) {
    final w = _resolve(p.w, size.width, fallback: size.width);
    final h = _resolve(p.h, size.height, fallback: size.height);

    final anchorX = _resolve(p.x, size.width, fallback: 0.0);
    final anchorY = _resolve(p.y, size.height, fallback: 0.0);

    final left = anchorX - ((p.origin.x + 1.0) * 0.5 * w);
    final top = anchorY - ((p.origin.y + 1.0) * 0.5 * h);

    return Rect.fromLTWH(left, top, w, h);
  }

  void _buildPrimitive(Path targetPath, QShapePrimitive p, Size size) {
    final rect = _buildRect(p, size);

    switch (p.type) {
      case QShapeType.rect:
        targetPath.addRect(rect);
        return;

      case QShapeType.rrect:
        final r = _resolve(p.radius, math.min(rect.width, rect.height),
            fallback: 0.0);
        if (r <= 0.0) {
          targetPath.addRect(rect);
        } else {
          targetPath
              .addRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)));
        }
        return;

      case QShapeType.pill:
        targetPath.addRRect(
          RRect.fromRectAndRadius(
            rect,
            Radius.circular(math.min(rect.width, rect.height) / 2.0),
          ),
        );
        return;

      case QShapeType.circle:
        final r = _resolve(
          p.radius,
          math.min(rect.width, rect.height),
          fallback: 0.0,
        );
        if (r > 0.0) {
          targetPath.addOval(Rect.fromCircle(center: rect.center, radius: r));
        } else {
          targetPath.addOval(rect);
        }
        return;

      case QShapeType.polygon:
        final pts = p.points;
        if (pts == null || pts.isEmpty) return;

        bool first = true;
        for (final pt in pts) {
          final o = pt.resolve(size);
          if (first) {
            targetPath.moveTo(o.dx, o.dy);
            first = false;
          } else {
            targetPath.lineTo(o.dx, o.dy);
          }
        }
        targetPath.close();
        return;
    }
  }

  void _compilePath(Size size) {
    if (!_pathDirty && _lastSize == size) return;

    _lastSize = size;
    _pathDirty = false;

    _compiledPath.reset();
    _buildPrimitive(_compiledPath, _shapeDef.base, size);

    for (final op in _shapeDef.operations) {
      _tempPath.reset();
      _buildPrimitive(_tempPath, op.shape, size);

      final ui.PathOperation pathOp;
      switch (op.op) {
        case QBooleanOp.subtract:
          pathOp = ui.PathOperation.difference;
          break;
        case QBooleanOp.union:
          pathOp = ui.PathOperation.union;
          break;
        case QBooleanOp.intersect:
          pathOp = ui.PathOperation.intersect;
          break;
        case QBooleanOp.exclude:
          pathOp = ui.PathOperation.xor;
          break;
      }

      final merged = Path.combine(pathOp, _compiledPath, _tempPath);
      _compiledPath
        ..reset()
        ..addPath(merged, Offset.zero);
    }
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    if (child != null) {
      child!.layout(constraints.loosen(), parentUsesSize: true);
    }

    final childSize = child?.size ?? Size.zero;

    final width =
        constraints.hasBoundedWidth ? constraints.maxWidth : childSize.width;
    final height =
        constraints.hasBoundedHeight ? constraints.maxHeight : childSize.height;

    size = constraints.constrain(Size(width, height));
    _pathDirty = true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!hasSize || size.isEmpty) return;

    _compilePath(size);

    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);

    // 1. SHADOWS GO FIRST (Underneath the shape)
    if (_shadows != null && _shadows!.isNotEmpty) {
      for (final shadow in _shadows!) {
        final blur = shadow.blurRadius * 0.5;
        if (blur > 0.0 || shadow.color.alpha > 0) {
          canvas.drawShadow(_compiledPath, shadow.color, blur, true);
        }
      }
    }

    // 2. FILL GOES SECOND (On top of the shadows)
    if (_drawFillBehindChild && _color != null) {
      _fillPaint.color = _color!;
      canvas.drawPath(_compiledPath, _fillPaint);
    }

    // 3. BORDER GOES THIRD (Contouring the fill)
    if (_border != null &&
        _border!.style != BorderStyle.none &&
        _border!.width > 0.0) {
      _strokePaint
        ..color = _border!.color
        ..strokeWidth = _border!.width;
      canvas.drawPath(_compiledPath, _strokePaint);
    }

    canvas.restore();

    // 4. CLIP CHILD LAST
    if (child != null) {
      if (_clipChild) {
        context.pushClipPath(
          needsCompositing,
          offset,
          offset & size,
          _compiledPath,
          (ctx, off) {
            ctx.paintChild(child!, off);
          },
        );
      } else {
        context.paintChild(child!, offset);
      }
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // 1. ADD THIS LINE: Immediate bounds check (Huge performance boost + test fix)
    if (size.isEmpty || !size.contains(position)) return false;

    // 2. Then check the complex path
    if (!_compiledPath.contains(position)) return false;

    final childHit =
        child != null && hitTestChildren(result, position: position);
    if (childHit || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }

  @override
  bool hitTestSelf(Offset position) => _compiledPath.contains(position);
}
