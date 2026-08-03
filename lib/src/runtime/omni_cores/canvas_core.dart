/*
 * ============================================================================
 * File: canvas_core.dart
 * 
 * Description:
 * Contains canvas drawing abstractions within the Quantum Omni Registry, enabling 
 * raw vertex buffers, AOT compiled procedural bytecode rendering, and custom 
 * SPIR-V shader pipelines.
 * 
 * Key Components:
 * - _buildCanvas: Generates specific canvas node types (plot, shape, draw, shader).
 * - _QLVertexPlotPainter / _QLProceduralCanvasNode: High-performance plotting 
 *   via Float32List vertex arrays and bytecode execution.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Operates closely with dart:ui primitives.
 * 
 * Notes:
 * Includes zero-GC logic designed to minimize memory allocation per frame.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildCanvas

Widget _buildCanvas(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'scene');

// 🚀 PRIMITIVE: canvas:draw (AOT Compiled Procedural Bytecode)
  if (subType == 'draw') {
    return _QLProceduralCanvasNode(
      commands: ctx.list('commands'),
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 PRIMITIVE: canvas:plot (Raw Float32 Vertex Buffer Rendering)
  if (subType == 'plot') {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _QLVertexPlotPainter(
          dataSignal: ctx.store.signal(ctx.string('bind')),
          mode: ctx.string('mode', fallback: 'line'),
          color: ctx.color('color', fallback: Colors.blue)!,
          stepX: ctx.number('stepX', fallback: 10.0),
          gapX: ctx.number('gapX', fallback: 2.0),
          scaleY: ctx.number('scaleY', fallback: 1.0),
          baseline: ctx.string('baseline', fallback: 'bottom'),
          thickness: ctx.number('thickness', fallback: 2.0),
        ),
      ),
    );
  }
  // 🚀 GPU PRIMITIVE: canvas:shader
  // Loads SPIR-V and directly pipes QSimdArena Floats to the shader uniforms.
  if (subType == 'shader') {
    final String src = ctx.string('src');
    final QLSignal<Float32List>? uniformBind = ctx
            .string('uniformBind')
            .isNotEmpty
        ? ctx.store.signal(ctx.string('uniformBind')) as QLSignal<Float32List>?
        : null;

    return FutureBuilder<ui.FragmentProgram>(
      future: ui.FragmentProgram.fromAsset(src),
      builder: (c, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final shader = snapshot.data!.fragmentShader();

        // 🚀 FIX: Pass to QLNode with QLNodeConfig directly to bind the pipeline!
        return QLNode(
          config: QLNodeConfig(
            shader: QLSignalProxy<ui.FragmentShader>(
              uniformBind ?? QLSignal(Float32List(0)),
              (floats) {
                for (int i = 0; i < floats.length; i++) {
                  shader.setFloat(i, floats[i]);
                }
                return shader;
              },
              (s) => Float32List(0),
            ),
          ),
          child: Q('col min-w-0 min-h-0', children: ctx.children),
        );
      },
    );
  }

  // STANDARD CANVAS LOGIC
  if (subType == 'shape') {
    return QLShapeNode(
      shapeDef: QBooleanShapeDef.fromJson(ctx.map('shapeDef')),
      color: ctx.color('fillColor'),
      child: ctx.children.firstOrNull,
    );
  }

  return QLSceneLayerWidget(
    isComplex: true,
    willChange: true,
    builder: (context, layer) => ctx.children.isEmpty
        ? const SizedBox.expand()
        : Stack(children: ctx.children),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 10: SYSTEM (Headless / Logic & Omega Macro)
// ════════════════════════════════════════════════════════════════════════════

// ── 6. RAW VERTEX PLOTTER (Insanely Fast GPU Line/Scatter Rendering) ──
class _QLVertexPlotPainter extends CustomPainter {
  final QLSignal<dynamic> dataSignal;
  final String mode;
  final Color color;
  final double stepX, gapX, scaleY, thickness;
  final String baseline;

  // Pre-allocated vertex buffers
  Float32List? _vertices;

  _QLVertexPlotPainter({
    required this.dataSignal,
    required this.mode,
    required this.color,
    required this.stepX,
    required this.gapX,
    required this.scaleY,
    required this.baseline,
    required this.thickness,
  }) : super(repaint: dataSignal);

  @override
  void paint(Canvas canvas, Size size) {
    final dynamic rawData = dataSignal.value;
    if (rawData is! Float64List) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = mode == 'line' ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final double baseVY = baseline == 'bottom'
        ? size.height
        : (baseline == 'center' ? size.height / 2 : 0.0);

    // 🚀 HARDWARE ACCELERATION: Vertices via Float32List
    if (mode == 'line' || mode == 'scatter') {
      final int vCount = rawData.length;
      if (_vertices == null || _vertices!.length < vCount * 2) {
        _vertices = Float32List(vCount * 2);
      }

      double curX = 0.0;
      for (int i = 0; i < vCount; i++) {
        _vertices![i * 2] = curX;
        _vertices![i * 2 + 1] = baseVY + (rawData[i] * scaleY);
        curX += (stepX + gapX);
      }

      // Directly hits Skia/Impeller pipeline without building Paths
      canvas.drawRawPoints(
          mode == 'line' ? ui.PointMode.polygon : ui.PointMode.points,
          Float32List.sublistView(_vertices!, 0, vCount * 2),
          paint);
      return;
    }

    // Bar Rendering
    double curX = 0.0;
    for (int i = 0; i < rawData.length; i++) {
      final double valY = rawData[i] * scaleY;
      canvas.drawRect(
          Rect.fromLTWH(
              curX, math.min(baseVY, baseVY + valY), stepX, valY.abs()),
          paint);
      curX += (stepX + gapX);
    }
  }

  @override
  bool shouldRepaint(covariant _QLVertexPlotPainter old) => true;
}

// ── 5. AOT PROCEDURAL CANVAS (BYTECODE) ──
class _QLProceduralCanvasNode extends StatefulWidget {
  final List<dynamic> commands;
  final Widget child;
  const _QLProceduralCanvasNode({required this.commands, required this.child});
  @override
  State<_QLProceduralCanvasNode> createState() =>
      _QLProceduralCanvasNodeState();
}

class _QLProceduralCanvasNodeState extends State<_QLProceduralCanvasNode> {
  late Float32List _fData;
  late Int32List _iData;

  @override
  void initState() {
    super.initState();
    _compile();
  }

  @override
  void didUpdateWidget(covariant _QLProceduralCanvasNode old) {
    super.didUpdateWidget(old);
    _compile();
  }

  void _compile() {
    // Translates JSON into flat Float32 and Int32 arrays.
    // OpCodes: 1=Rect, 2=Circle.
    _fData = Float32List(widget.commands.length * 4);
    _iData = Int32List(widget.commands.length * 2);

    for (int i = 0; i < widget.commands.length; i++) {
      final cmd = widget.commands[i];
      if (cmd is! List || cmd.isEmpty) continue;
      final type = cmd[0].toString();

      try {
        _iData[i * 2 + 1] = cmd.length > 4
            ? QLParserUtils.parseColor(
                cmd.last.toString(), 0, cmd.last.toString().length)
            : 0xFF000000;
      } catch (_) {
        _iData[i * 2 + 1] = 0xFF000000;
      }

      double n(dynamic v) {
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '') ?? 0.0;
      }

      if (type == 'rect' && cmd.length >= 5) {
        _iData[i * 2] = 1;
        _fData[i * 4 + 0] = n(cmd[1]);
        _fData[i * 4 + 1] = n(cmd[2]);
        _fData[i * 4 + 2] = n(cmd[3]);
        _fData[i * 4 + 3] = n(cmd[4]);
      } else if (type == 'circle' && cmd.length >= 4) {
        _iData[i * 2] = 2;
        _fData[i * 4 + 0] = n(cmd[1]);
        _fData[i * 4 + 1] = n(cmd[2]);
        _fData[i * 4 + 2] = n(cmd[3]);
      } else {
        _iData[i * 2] = 0; // No-op for invalid/unknown commands
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _QLProceduralPainter(_fData, _iData),
      child: widget.child,
    );
  }
}

class _QLProceduralPainter extends CustomPainter {
  final Float32List fData;
  final Int32List iData;
  _QLProceduralPainter(this.fData, this.iData);

  @override
  void paint(Canvas canvas, Size size) {
    final int count = iData.length ~/ 2;
    final Paint p = Paint();
    for (int i = 0; i < count; i++) {
      final int op = iData[i * 2];
      if (op == 0) continue;
      p.color = Color(iData[i * 2 + 1]);

      if (op == 1) {
        // Rect
        canvas.drawRect(
            Rect.fromLTWH(fData[i * 4], fData[i * 4 + 1], fData[i * 4 + 2],
                fData[i * 4 + 3]),
            p);
      } else if (op == 2) {
        // Circle
        canvas.drawCircle(
            Offset(fData[i * 4], fData[i * 4 + 1]), fData[i * 4 + 2], p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QLProceduralPainter old) =>
      true; // Or equality check
}

final QuantumDomain canvasDomain = quantumDomain('canvas')
    .surface('canvas', _buildCanvas, defaultSurface: true)
    .install((vm) {
      vm.defineAlias('shader', 'canvas:shader',
          description: 'Canvas shader alias.', tags: const ['canvas', 'alias']);
    })
    .build();

class CanvasCoreExporter implements QuantumCoreExporter {
  const CanvasCoreExporter();

  @override
  void export(QuantumVM vm) {
    vm.installDomain(canvasDomain);
  }
}

