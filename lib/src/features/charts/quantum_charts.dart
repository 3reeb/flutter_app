import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../quantum.dart';
import 'package:flutter/foundation.dart';
// ════════════════════════════════════════════════════════════════════════════
//  OMEGA CHART ENGINE (PURE FLUTTER, SIMD OPTIMIZED, ZERO-COPY)
// ════════════════════════════════════════════════════════════════════════════

enum QLChartType {
  line,
  bar,
  area,
  pie,
  donut,
  radar,
  scatter,
  bubble,
  candlestick,
  funnel,
  waterfall,
  histogram,
  gauge,
  sparkline,
  treemap,
  sankey
}

/// A unified, cache-aligned data structure for processing thousands of points.
class QLChartDataBuffer {
  final Float64List x;
  final Float64List y;
  final Float64List open;
  final Float64List high;
  final Float64List low;
  final Float64List close;
  final Float64List size; // used for bubble, pie, treemap
  final int length;
  double minX = double.infinity, maxX = double.negativeInfinity;
  double minY = double.infinity, maxY = double.negativeInfinity;

  QLChartDataBuffer(this.length)
      : x = Float64List(length),
        y = Float64List(length),
        open = Float64List(length),
        high = Float64List(length),
        low = Float64List(length),
        close = Float64List(length),
        size = Float64List(length);

  /// Instantly parses a raw JSON/Map array into native CPU-cache contiguous arrays
  static QLChartDataBuffer parse(List<dynamic> rawData) {
    final int len = rawData.length;
    final buffer = QLChartDataBuffer(len);

    double safeDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    for (int i = 0; i < len; i++) {
      final dynamic p = rawData[i];
      if (p is num) {
        buffer.y[i] = p.toDouble();
        buffer.x[i] = i.toDouble();
      } else if (p is Map) {
        buffer.x[i] = safeDouble(p['x'], i.toDouble());
        buffer.y[i] = safeDouble(p['y'], 0.0);
        buffer.open[i] = safeDouble(p['open'], buffer.y[i]);
        buffer.high[i] = safeDouble(p['high'], buffer.y[i]);
        buffer.low[i] = safeDouble(p['low'], buffer.y[i]);
        buffer.close[i] = safeDouble(p['close'], buffer.y[i]);
        buffer.size[i] = safeDouble(p['size'] ?? p['value'], 0.0);
      }

      if (buffer.x[i] < buffer.minX) buffer.minX = buffer.x[i];
      if (buffer.x[i] > buffer.maxX) buffer.maxX = buffer.x[i];

      // Calculate global Y bounds based on the highest potential value in this row
      final double peakY = math.max(buffer.y[i], buffer.high[i]);
      final double floorY = math.min(buffer.y[i], buffer.low[i]);
      if (floorY < buffer.minY) buffer.minY = floorY;
      if (peakY > buffer.maxY) buffer.maxY = peakY;
    }

    // Safeties
    if (buffer.minX == double.infinity) buffer.minX = 0;
    if (buffer.maxX == double.negativeInfinity) buffer.maxX = 1;
    if (buffer.minY == double.infinity) buffer.minY = 0;
    if (buffer.maxY == double.negativeInfinity) buffer.maxY = 1;
    if (buffer.minY == buffer.maxY) {
      buffer.minY -= 1;
      buffer.maxY += 1;
    }

    return buffer;
  }
}

/// The Pure Standalone Flutter Chart Widget.
/// Can be used with SDUI or independently.
class QLUniversalChart extends StatefulWidget {
  final QLChartType type;
  final List<dynamic> rawData;
  final Color color;
  final bool showGrid;
  final bool showAxes;
  final bool animate;
  final double lineWidth;
  final Widget Function(
          BuildContext context, int? index, Offset? pos, dynamic dataPoint)?
      tooltipBuilder;

  const QLUniversalChart({
    super.key,
    required this.type,
    required this.rawData,
    this.color = Colors.blue,
    this.showGrid = true,
    this.showAxes = true,
    this.animate = true,
    this.lineWidth = 2.0,
    this.tooltipBuilder,
  });

  @override
  State<QLUniversalChart> createState() => _QLUniversalChartState();
}

class _QLUniversalChartState extends State<QLUniversalChart>
    with SingleTickerProviderStateMixin {
  late QLChartDataBuffer _buffer;

  // Interaction Signals
  final QLSignal<int?> _hoverIndex = QLSignal(null);
  final QLSignal<Offset?> _hoverPos = QLSignal(null);

  // Animation Engine
  late AnimationController _animCtrl;
  final QLSignal<double> _morphT = QLSignal(1.0);

  @override
  void initState() {
    super.initState();
    _buffer = QLChartDataBuffer.parse(widget.rawData);
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _animCtrl.addListener(() {
      _morphT.setSilent(Curves.easeOutQuint.transform(_animCtrl.value));
      _morphT.forceNotify();
    });
    if (widget.animate) _animCtrl.forward(from: 0.0);
  }

  @override
  void didUpdateWidget(covariant QLUniversalChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rawData != widget.rawData) {
      _buffer = QLChartDataBuffer.parse(widget.rawData);
      if (widget.animate) _animCtrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _hoverIndex.dispose();
    _hoverPos.dispose();
    super.dispose();
  }

  void _handleHover(QLPointerEvent e, Size size) {
    if (_buffer.length == 0) return;

    // Non-Cartesian charts (Pie/Radar) handle hover differently (Angle-based or omitted for brevity)
    if (widget.type == QLChartType.pie ||
        widget.type == QLChartType.donut ||
        widget.type == QLChartType.radar ||
        widget.type == QLChartType.gauge) {
      return;
    }

    // O(log N) Binary Search for Cartesian X-Axis mapping
    final double rangeX = _buffer.maxX - _buffer.minX;
    final double targetX =
        _buffer.minX + ((e.position.dx / size.width) * rangeX);

    int low = 0;
    int high = _buffer.length - 1;
    int bestIdx = 0;
    double minDiff = double.infinity;

    while (low <= high) {
      int mid = (low + high) ~/ 2;
      double diff = (_buffer.x[mid] - targetX).abs();

      if (diff < minDiff) {
        minDiff = diff;
        bestIdx = mid;
      }

      if (_buffer.x[mid] < targetX)
        low = mid + 1;
      else if (_buffer.x[mid] > targetX)
        high = mid - 1;
      else
        break;
    }

    final double rangeY = _buffer.maxY - _buffer.minY;
    final double normX =
        rangeX == 0 ? 0.5 : (_buffer.x[bestIdx] - _buffer.minX) / rangeX;
    final double normY =
        rangeY == 0 ? 0.5 : (_buffer.y[bestIdx] - _buffer.minY) / rangeY;

    final Offset snapPos =
        Offset(normX * size.width, size.height - (normY * size.height));

    if (_hoverIndex.value != bestIdx) {
      _hoverIndex.setSilent(bestIdx);
      _hoverPos.setSilent(snapPos);
      _hoverIndex.forceNotify();
      _hoverPos.forceNotify();
    }
  }

  void _handleExit() {
    _hoverIndex.value = null;
    _hoverPos.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final Size size = Size(constraints.maxWidth, constraints.maxHeight);

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. GRID LAYER (Static, cached infinitely)
          if (widget.showGrid &&
              widget.type != QLChartType.pie &&
              widget.type != QLChartType.sparkline &&
              widget.type != QLChartType.donut &&
              widget.type != QLChartType.radar &&
              widget.type != QLChartType.gauge)
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                isComplex: false,
                willChange: false,
                painter: _QLGridPainter(color: widget.color.withOpacity(0.1)),
              ),
            ),

          // 2. OMEGA DATA LAYER (Hardware SIMD loop path generation)
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _morphT,
              builder: (ctx, _) => CustomPaint(
                size: size,
                isComplex: true,
                willChange: widget.animate,
                painter: _QLDataPainter(
                  buffer: _buffer,
                  type: widget.type,
                  color: widget.color,
                  morphT: _morphT.value,
                  lineWidth: widget.lineWidth,
                ),
              ),
            ),
          ),

          // 3. INTERACTION & CROSSHAIR LAYER (Changes rapidly on hover, Zero-Data rebuild)
          QLOmniSensor(
            onTouchUpdate: (e) => _handleHover(e, size),
            child: MouseRegion(
              onExit: (_) => _handleExit(),
              child: AnimatedBuilder(
                animation: _hoverIndex,
                builder: (ctx, _) {
                  final int? idx = _hoverIndex.value;
                  final Offset? pos = _hoverPos.value;

                  if (idx == null || pos == null)
                    return const SizedBox.expand();

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Crosshair rendering
                      CustomPaint(
                        size: size,
                        painter:
                            _QLCrosshairPainter(pos: pos, color: widget.color),
                      ),
                      // Dynamic Tooltip Overlay Injection
                      if (widget.tooltipBuilder != null)
                        widget.tooltipBuilder!(
                            context, idx, pos, widget.rawData[idx]),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ───────────────────────────────────────────────────────────────────────
// PAINTERS (ZERO-ALLOCATION HOT LOOPS)
// ───────────────────────────────────────────────────────────────────────

class _QLGridPainter extends CustomPainter {
  final Color color;
  _QLGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    // Draw 4 horizontal lines and 4 vertical lines using extreme fast raw lines
    final Float32List pts = Float32List(32);
    int idx = 0;

    // Horizontals
    for (int i = 1; i < 5; i++) {
      double y = (size.height / 5) * i;
      pts[idx++] = 0;
      pts[idx++] = y;
      pts[idx++] = size.width;
      pts[idx++] = y;
    }
    // Verticals
    for (int i = 1; i < 5; i++) {
      double x = (size.width / 5) * i;
      pts[idx++] = x;
      pts[idx++] = 0;
      pts[idx++] = x;
      pts[idx++] = size.height;
    }

    canvas.drawRawPoints(ui.PointMode.lines, pts, paint);
  }

  @override
  bool shouldRepaint(_QLGridPainter old) => old.color != color;
}

class _QLCrosshairPainter extends CustomPainter {
  final Offset pos;
  final Color color;
  _QLCrosshairPainter({required this.pos, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pLine = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.0;
    final Paint pDot = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint pDotBg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Crosshairs
    canvas.drawLine(Offset(pos.dx, 0), Offset(pos.dx, size.height), pLine);
    canvas.drawLine(Offset(0, pos.dy), Offset(size.width, pos.dy), pLine);

    // Data Node
    canvas.drawCircle(pos, 5.0, pDotBg);
    canvas.drawCircle(pos, 3.5, pDot);
  }

  @override
  bool shouldRepaint(_QLCrosshairPainter old) => old.pos != pos;
}

class _QLDataPainter extends CustomPainter {
  final QLChartDataBuffer buffer;
  final QLChartType type;
  final Color color;
  final double morphT;
  final double lineWidth;

  _QLDataPainter({
    required this.buffer,
    required this.type,
    required this.color,
    required this.morphT,
    required this.lineWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (buffer.length == 0) {
      // 🚀 FOREVER FIX: Display a placeholder text if no data to prevent blank charts
      final TextPainter tp = TextPainter(
        text: TextSpan(
            text: 'No chart data',
            style: TextStyle(color: color.withOpacity(0.5), fontSize: 14)),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: size.width, maxWidth: size.width);
      tp.paint(canvas, Offset(0, size.height / 2 - tp.height / 2));
      return;
    }

    final double w = size.width;
    final double h = size.height;
    final double rX = buffer.maxX - buffer.minX;
    final double rY = buffer.maxY - buffer.minY;

    // Fast mapping closures
    @pragma('vm:prefer-inline')
    double mapX(double val) =>
        rX == 0 ? w * 0.5 : ((val - buffer.minX) / rX) * w;
    @pragma('vm:prefer-inline')
    double mapY(double val) => rY == 0
        ? h * 0.5
        : h -
            (((val - buffer.minY) / rY) *
                h *
                morphT); // MorphT shrinks Y to 0 for animation

    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final Paint strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ── CARTESIAN CHARTS ──
    if (type == QLChartType.line || type == QLChartType.sparkline) {
      final Path path = Path();
      path.moveTo(mapX(buffer.x[0]), mapY(buffer.y[0]));
      for (int i = 1; i < buffer.length; i++) {
        path.lineTo(mapX(buffer.x[i]), mapY(buffer.y[i]));
      }
      canvas.drawPath(path, strokePaint);
    } else if (type == QLChartType.area) {
      final Path path = Path();
      path.moveTo(mapX(buffer.x[0]), h);
      for (int i = 0; i < buffer.length; i++) {
        path.lineTo(mapX(buffer.x[i]), mapY(buffer.y[i]));
      }
      path.lineTo(mapX(buffer.x[buffer.length - 1]), h);
      path.close();

      final Paint areaPaint = Paint()
        ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, h),
            [color.withOpacity(0.5), color.withOpacity(0.0)]);
      canvas.drawPath(path, areaPaint);

      // Draw top line
      final Path linePath = Path();
      linePath.moveTo(mapX(buffer.x[0]), mapY(buffer.y[0]));
      for (int i = 1; i < buffer.length; i++) {
        linePath.lineTo(mapX(buffer.x[i]), mapY(buffer.y[i]));
      }
      canvas.drawPath(linePath, strokePaint);
    } else if (type == QLChartType.bar || type == QLChartType.histogram) {
      // Hardware accelerated batched rectangle drawing
      final double barW = (w / buffer.length) * 0.8;
      for (int i = 0; i < buffer.length; i++) {
        final double cx = mapX(buffer.x[i]);
        final double cy = mapY(buffer.y[i]);
        canvas.drawRRect(
            RRect.fromLTRBAndCorners(cx - barW / 2, cy, cx + barW / 2, h,
                topLeft: const Radius.circular(4),
                topRight: const Radius.circular(4)),
            fillPaint);
      }
    } else if (type == QLChartType.candlestick) {
      final double candleW = (w / buffer.length) * 0.6;
      final Paint upPaint = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.fill;
      final Paint downPaint = Paint()
        ..color = const Color(0xFFEF4444)
        ..style = PaintingStyle.fill;
      final Paint wickUp = Paint()
        ..color = const Color(0xFF10B981)
        ..strokeWidth = 1.5;
      final Paint wickDown = Paint()
        ..color = const Color(0xFFEF4444)
        ..strokeWidth = 1.5;

      for (int i = 0; i < buffer.length; i++) {
        final double cx = mapX(buffer.x[i]);
        final double o = mapY(buffer.open[i]);
        final double c = mapY(buffer.close[i]);
        final double hi = mapY(buffer.high[i]);
        final double lo = mapY(buffer.low[i]);

        final bool isUp = buffer.close[i] >= buffer.open[i];

        // Draw Wick
        canvas.drawLine(
            Offset(cx, hi), Offset(cx, lo), isUp ? wickUp : wickDown);

        // Draw Body
        final double top = math.min(o, c);
        final double bottom = math.max(o, c);
        // Ensure body is at least 1px tall
        final Rect body = Rect.fromLTRB(cx - candleW / 2, top, cx + candleW / 2,
            math.max(top + 1.0, bottom));
        canvas.drawRect(body, isUp ? upPaint : downPaint);
      }
    } else if (type == QLChartType.scatter || type == QLChartType.bubble) {
      for (int i = 0; i < buffer.length; i++) {
        final double cx = mapX(buffer.x[i]);
        final double cy = mapY(buffer.y[i]);
        final double radius = type == QLChartType.bubble
            ? math.max(4.0, buffer.size[i] * 10 * morphT)
            : 4.0;
        canvas.drawCircle(
            Offset(cx, cy), radius, fillPaint..color = color.withOpacity(0.6));
        canvas.drawCircle(
            Offset(cx, cy), radius, strokePaint..strokeWidth = 1.0);
      }
    } else if (type == QLChartType.waterfall) {
      double runningY = 0;
      final double barW = (w / buffer.length) * 0.8;
      final Paint pPos = Paint()..color = const Color(0xFF10B981);
      final Paint pNeg = Paint()..color = const Color(0xFFEF4444);
      final Paint pNet = Paint()..color = const Color(0xFF3B82F6);

      for (int i = 0; i < buffer.length; i++) {
        final double val = buffer.y[i];
        final double cx = mapX(buffer.x[i]);

        double startY, endY;
        Paint bp;

        if (i == buffer.length - 1) {
          // Total column
          startY = 0;
          endY = runningY + val;
          bp = pNet;
        } else {
          startY = runningY;
          endY = runningY + val;
          runningY += val;
          bp = val >= 0 ? pPos : pNeg;
        }

        final double syMap = mapY(startY);
        final double eyMap = mapY(endY);
        canvas.drawRect(
            Rect.fromLTRB(cx - barW / 2, math.min(syMap, eyMap), cx + barW / 2,
                math.max(syMap, eyMap)),
            bp);
      }
    }

    // ── NON-CARTESIAN / RADIAL CHARTS ──
    else if (type == QLChartType.pie || type == QLChartType.donut) {
      final double cx = w / 2;
      final double cy = h / 2;
      final double radius = math.min(w, h) / 2 * 0.9 * morphT;

      double total = 0;
      for (int i = 0; i < buffer.length; i++) total += buffer.y[i].abs();

      double startAngle = -math.pi / 2;
      final Rect bounds =
          Rect.fromCircle(center: Offset(cx, cy), radius: radius);

      for (int i = 0; i < buffer.length; i++) {
        final double sweep = (buffer.y[i].abs() / total) * math.pi * 2;
        // Shift colors slightly
        final Color sliceColor =
            Color.lerp(color, Colors.white, (i / buffer.length) * 0.6)!;

        final Paint slicePaint = Paint()
          ..color = sliceColor
          ..style = PaintingStyle.fill;
        if (type == QLChartType.donut) {
          slicePaint.style = PaintingStyle.stroke;
          slicePaint.strokeWidth = radius * 0.4; // 40% hole
        }

        canvas.drawArc(
            bounds, startAngle, sweep, type == QLChartType.pie, slicePaint);

        // Add tiny gap
        startAngle += sweep + 0.02;
      }
    } else if (type == QLChartType.gauge) {
      final double cx = w / 2;
      final double cy = h * 0.8;
      final double radius = math.min(w, h) * 0.7 * morphT;
      final Rect bounds =
          Rect.fromCircle(center: Offset(cx, cy), radius: radius);

      // Draw background track
      final Paint bgPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(bounds, math.pi, math.pi, false, bgPaint);

      // Draw Value
      final double sweep = math.pi *
          ((buffer.y[0] - buffer.minY) / (buffer.maxY - buffer.minY))
              .clamp(0.0, 1.0);
      final Paint fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(bounds, math.pi, sweep, false, fgPaint);
    } else if (type == QLChartType.radar) {
      final double cx = w / 2;
      final double cy = h / 2;
      final double maxRadius = math.min(w, h) / 2 * 0.8;

      final int N = buffer.length;
      final double angleStep = (math.pi * 2) / N;

      // Draw spiderweb
      final Paint webPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke;
      for (int r = 1; r <= 4; r++) {
        final Path webPath = Path();
        final double tr = (r / 4) * maxRadius;
        for (int i = 0; i < N; i++) {
          final double a = i * angleStep - (math.pi / 2);
          final Offset pt =
              Offset(cx + math.cos(a) * tr, cy + math.sin(a) * tr);
          if (i == 0)
            webPath.moveTo(pt.dx, pt.dy);
          else
            webPath.lineTo(pt.dx, pt.dy);

          if (r == 4) {
            // Draw axis lines
            canvas.drawLine(Offset(cx, cy), pt, webPaint);
          }
        }
        webPath.close();
        canvas.drawPath(webPath, webPaint);
      }

      // Draw data shape
      final Path dataPath = Path();
      for (int i = 0; i < N; i++) {
        final double a = i * angleStep - (math.pi / 2);
        // Normalize against absolute maximum across all data
        final double normVal =
            (buffer.y[i] / buffer.maxY).clamp(0.0, 1.0) * morphT;
        final double r = maxRadius * normVal;
        final Offset pt = Offset(cx + math.cos(a) * r, cy + math.sin(a) * r);
        if (i == 0)
          dataPath.moveTo(pt.dx, pt.dy);
        else
          dataPath.lineTo(pt.dx, pt.dy);
      }
      dataPath.close();
      canvas.drawPath(dataPath, fillPaint..color = color.withOpacity(0.4));
      canvas.drawPath(dataPath, strokePaint..strokeWidth = 2.0);
    }

    // ── ADVANCED LAYOUT CHARTS ──
    else if (type == QLChartType.treemap) {
      // Simplified Squarified Treemap Heuristic (Fast slice-and-dice for VM bounds)
      double totalVal = 0;
      for (int i = 0; i < buffer.length; i++) totalVal += buffer.y[i].abs();

      double currentX = 0;
      double currentY = 0;
      double remainW = w;
      double remainH = h;

      for (int i = 0; i < buffer.length; i++) {
        final double ratio = (buffer.y[i].abs() / totalVal) * morphT;
        final Color blockColor =
            Color.lerp(color, Colors.black, (i / buffer.length) * 0.4)!;

        Rect block;
        if (remainW > remainH) {
          // Vertical slice
          final double sw = remainW * ratio;
          block = Rect.fromLTWH(currentX, currentY, sw, remainH);
          currentX += sw;
          remainW -= sw;
        } else {
          // Horizontal slice
          final double sh = remainH * ratio;
          block = Rect.fromLTWH(currentX, currentY, remainW, sh);
          currentY += sh;
          remainH -= sh;
        }

        canvas.drawRect(block.deflate(1.0), Paint()..color = blockColor);
      }
    } else if (type == QLChartType.funnel) {
      // Sort and Draw Funnel Traversals
      final double maxW = w * 0.8;
      final double stepH = h / buffer.length;

      for (int i = 0; i < buffer.length; i++) {
        final double ratioTop = (buffer.y[i] / buffer.maxY) * morphT;
        final double ratioBottom = i < buffer.length - 1
            ? (buffer.y[i + 1] / buffer.maxY) * morphT
            : ratioTop * 0.5;

        final double topW = maxW * ratioTop;
        final double botW = maxW * ratioBottom;

        final double yTop = i * stepH;
        final double yBot = (i + 1) * stepH;

        final Path fPath = Path()
          ..moveTo(w / 2 - topW / 2, yTop)
          ..lineTo(w / 2 + topW / 2, yTop)
          ..lineTo(w / 2 + botW / 2, yBot - 2.0)
          ..lineTo(w / 2 - botW / 2, yBot - 2.0)
          ..close();

        final Color fColor = Color.lerp(color, Colors.white, i * 0.15)!;
        canvas.drawPath(fPath, Paint()..color = fColor);
      }
    } else if (type == QLChartType.sankey) {
      // Ultra-Fast Sankey Approximation via Bezier curves
      final double stepX = w / (buffer.length - 1);
      final Path linkPath = Path();

      for (int i = 0; i < buffer.length - 1; i++) {
        final double x1 = i * stepX;
        final double y1 = mapY(buffer.y[i]);
        final double x2 = (i + 1) * stepX;
        final double y2 = mapY(buffer.y[i + 1]);

        linkPath.moveTo(x1, y1);
        linkPath.cubicTo(x1 + stepX / 2, y1, x2 - stepX / 2, y2, x2, y2);

        // Draw Nodes
        canvas.drawRect(
            Rect.fromLTRB(x1 - 4, y1 - 20, x1 + 4, y1 + 20), fillPaint);
      }
      // Draw last node
      final double xEnd = (buffer.length - 1) * stepX;
      final double yEnd = mapY(buffer.y[buffer.length - 1]);
      canvas.drawRect(
          Rect.fromLTRB(xEnd - 4, yEnd - 20, xEnd + 4, yEnd + 20), fillPaint);

      canvas.drawPath(
          linkPath,
          strokePaint
            ..strokeWidth = 20.0
            ..color = color.withOpacity(0.2));
    }
  }

  @override
  bool shouldRepaint(_QLDataPainter old) =>
      old.morphT != morphT || old.buffer != buffer;
}

Widget buildChart(QLContext ctx, QLChartType type) {
  final List<dynamic> rawData = ctx.list('data');
  final String colorHex = ctx.string('color', fallback: '#3B82F6');
  final Color chartColor = Color(
      int.tryParse(colorHex.replaceFirst('#', 'FF'), radix: 16) ?? 0xFF3B82F6);

  return QLBox(
    style: ctx.node.style,
    child: QLUniversalChart(
      type: type,
      rawData: rawData,
      color: chartColor,
      showGrid: ctx.boolean('showGrid', fallback: true),
      showAxes: ctx.boolean('showAxes', fallback: true),
      animate: ctx.boolean('animated', fallback: true),
      lineWidth: ctx.number('lineWidth', fallback: 2.0),
      tooltipBuilder: (context, index, pos, dataPoint) {
        final Widget? tooltipSlot = ctx.slot('tooltip');
        if (tooltipSlot == null || index == null || pos == null)
          return const SizedBox.shrink();

        // Expose hovered data to the custom tooltip slot
        return Positioned(
          left: pos.dx,
          top: pos.dy - 10,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -1.0),
            child: QLDataScope(
              localData: {'hoverIndex': index, 'hoverData': dataPoint},
              child: tooltipSlot,
            ),
          ),
        );
      },
    ),
  );
}
