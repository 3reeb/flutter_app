/*
 * ============================================================================
 * File: quantum_widget_image_exporter.dart
 * 
 * Description:
 * Provides an asynchronous utility to compile an SDUI JSON schema and export 
 * the fully rendered widget tree as PNG bytes, entirely offscreen. It achieves 
 * this by mounting the UI in an ephemeral OverlayEntry and capturing its 
 * RenderRepaintBoundary.
 * 
 * Key Components:
 * - QuantumWidgetImageExporter: The public API for single or batch exports.
 * - _OffscreenCaptureHost: An invisible stateful widget that inflates the blueprint.
 * - QuantumExportConfig: Configuration for dimensions, pixel ratio, and timeout.
 * 
 * Dependencies/Relationships:
 * Relies on dart:ui and Flutter's rendering pipeline. Often paired with 
 * quantum_export_web_bridge.dart for server-side rendering scraping.
 * 
 * Notes:
 * This is an intensive operation. Use exportBatch sequentially rather than 
 * spawning many concurrent exports to avoid overwhelming the raster thread.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM WIDGET IMAGE EXPORTER v1.0
// quantum_widget_image_exporter.dart
//
// API OVERVIEW:
//   QuantumWidgetImageExporter.export(json, ...)
//     → Uint8List  (PNG bytes, fully async)
//
// HOW IT WORKS:
//   1. Compile the SDUI JSON → QLBlueprint   (QLCompiler.compile)
//   2. Inflate the blueprint inside an offscreen, Offstage widget tree that is
//      mounted into an Overlay entry so it gets a real BuildContext and goes
//      through a full layout/paint cycle.
//   3. Capture the RenderRepaintBoundary → dart:ui Image → PNG bytes.
//   4. Remove the Overlay entry and return the bytes.
//
// USAGE (inside a widget that has an Overlay ancestor, e.g. MaterialApp):
//   final Uint8List png = await QuantumWidgetImageExporter.export(
//     json: mySchemaMap,
//     context: context,
//     width: 390,
//     height: 844,
//   );
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quantum_layout/quantum.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  RESULT — returned from every export call
// ─────────────────────────────────────────────────────────────────────────────

/// The result of a single SDUI-to-image export operation.
class QuantumExportResult {
  /// Raw PNG bytes of the rendered widget.
  final Uint8List pngBytes;

  /// Pixel width of the captured image.
  final int pixelWidth;

  /// Pixel height of the captured image.
  final int pixelHeight;

  /// How long the full export took (compile + layout + capture).
  final Duration elapsed;

  const QuantumExportResult({
    required this.pngBytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.elapsed,
  });

  @override
  String toString() =>
      'QuantumExportResult($pixelWidth×$pixelHeight, '
      '${pngBytes.length} bytes, ${elapsed.inMilliseconds}ms)';
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIG — controls render size, DPR, timeout, etc.
// ─────────────────────────────────────────────────────────────────────────────

/// Configuration for a single image-export operation.
class QuantumExportConfig {
  /// Logical width of the offscreen viewport in dp.
  final double width;

  /// Logical height of the offscreen viewport in dp.
  /// If null the widget is laid out with unbounded height and the captured
  /// image height equals the widget's natural height.
  final double? height;

  /// Device pixel ratio used for the captured image (default: 3.0 → crisp).
  final double pixelRatio;

  /// Background colour behind the rendered widget (default: transparent).
  final Color background;

  /// Store data to inject into the QLDataScope (e.g. mock API results).
  final Map<String, dynamic> storeData;

  /// Env / compile-time tokens injected as QLCompiler env.
  final Map<String, dynamic> env;

  /// Macros forwarded to QLCompiler (default: empty).
  final Map<String, dynamic> macros;

  /// Maximum time to wait for the widget to finish painting.
  final Duration timeout;

  const QuantumExportConfig({
    this.width = 390,
    this.height,
    this.pixelRatio = 3.0,
    this.background = Colors.transparent,
    this.storeData = const {},
    this.env = const {},
    this.macros = const {},
    this.timeout = const Duration(seconds: 15),
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

/// Compiles any Quantum SDUI JSON schema and exports the fully-rendered widget
/// tree as PNG bytes — completely offscreen, without touching any visible UI.
///
/// ### Minimal example
/// ```dart
/// final result = await QuantumWidgetImageExporter.export(
///   json: {'type': 'text', 'props': {'text': 'Hello Quantum!'}},
///   context: context,
/// );
/// final image = Image.memory(result.pngBytes);
/// ```
///
/// ### With config
/// ```dart
/// final result = await QuantumWidgetImageExporter.export(
///   json: mySchema,
///   context: context,
///   config: QuantumExportConfig(
///     width: 1280,
///     height: 720,
///     pixelRatio: 2.0,
///     background: Colors.white,
///     storeData: {'user': {'name': 'Alice'}},
///   ),
/// );
/// ```
abstract final class QuantumWidgetImageExporter {
  // ── Primary entry-point ────────────────────────────────────────────────────

  /// Export [json] SDUI schema as a PNG image.
  ///
  /// [context] must be a valid [BuildContext] with an [Overlay] ancestor
  /// (any context inside a [MaterialApp] / [WidgetsApp] qualifies).
  static Future<QuantumExportResult> export({
    required Map<String, dynamic> json,
    required BuildContext context,
    QuantumExportConfig config = const QuantumExportConfig(),
  }) async {
    final sw = Stopwatch()..start();

    // 1. Compile JSON → QLBlueprint (happens on the current isolate; for very
    //    large schemas QLCompiler.compileAsync offloads to a worker isolate).
    final QLBlueprint blueprint = await _compile(json, config);

    // 2. Build an isolated ephemeral store so storeData doesn't pollute the
    //    global default store.
    final QLDataStore ephemeralStore = QLDataStore(namespace: '_qx_export_${DateTime.now().microsecondsSinceEpoch}');
    config.storeData.forEach((k, v) => ephemeralStore.set(k, v));

    // 3. Inflate the widget offscreen and capture it.
    final Uint8List bytes = await _captureViaOverlay(
      context: context,
      blueprint: blueprint,
      store: ephemeralStore,
      config: config,
    );

    // 4. Decode dimensions from the PNG header (bytes 16-24).
    final int w = _readPngDimension(bytes, 16);
    final int h = _readPngDimension(bytes, 20);

    sw.stop();
    ephemeralStore.dispose();

    return QuantumExportResult(
      pngBytes: bytes,
      pixelWidth: w,
      pixelHeight: h,
      elapsed: sw.elapsed,
    );
  }

  // ── Batch export ───────────────────────────────────────────────────────────

  /// Export multiple SDUI schemas sequentially, returning one result per item.
  ///
  /// Runs sequentially rather than concurrently to avoid overwhelming the
  /// raster thread during capture.
  static Future<List<QuantumExportResult>> exportBatch({
    required List<Map<String, dynamic>> schemas,
    required BuildContext context,
    QuantumExportConfig config = const QuantumExportConfig(),
  }) async {
    final results = <QuantumExportResult>[];
    for (final schema in schemas) {
      results.add(await export(json: schema, context: context, config: config));
    }
    return results;
  }

  // ── Convenience: export and get a Flutter Image widget ────────────────────

  /// Export [json] and return it immediately as a Flutter [Image] widget.
  static Future<Image> exportAsWidget({
    required Map<String, dynamic> json,
    required BuildContext context,
    QuantumExportConfig config = const QuantumExportConfig(),
    BoxFit fit = BoxFit.contain,
  }) async {
    final result = await export(json: json, context: context, config: config);
    return Image.memory(result.pngBytes, fit: fit);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  static Future<QLBlueprint> _compile(
    Map<String, dynamic> json,
    QuantumExportConfig config,
  ) async {
    // Extract the UI node the same way QLSmartView does.
    final dynamic uiNode = json['ui'] ?? json;
    return QLCompiler.compileAsync(uiNode, config.macros, config.env);
  }

  /// Mounts an Offstage widget into the Overlay, waits for a real paint cycle,
  /// then captures the RepaintBoundary and removes the Overlay entry.
  static Future<Uint8List> _captureViaOverlay({
    required BuildContext context,
    required QLBlueprint blueprint,
    required QLDataStore store,
    required QuantumExportConfig config,
  }) async {
    final completer = Completer<Uint8List>();
    final repaintKey = GlobalKey();
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (overlayContext) => _OffscreenCaptureHost(
        repaintKey: repaintKey,
        blueprint: blueprint,
        store: store,
        config: config,
        onReady: (renderBoundary) async {
          try {
            final ui.Image img = await renderBoundary.toImage(
              pixelRatio: config.pixelRatio,
            );
            final ByteData? byteData =
                await img.toByteData(format: ui.ImageByteFormat.png);
            img.dispose();
            if (byteData == null) {
              completer.completeError(
                  StateError('QuantumWidgetImageExporter: toByteData returned null'));
            } else {
              completer.complete(byteData.buffer.asUint8List());
            }
          } catch (e, st) {
            completer.completeError(e, st);
          } finally {
            entry?.remove();
            entry?.dispose();
          }
        },
        onError: (e, st) {
          entry?.remove();
          entry?.dispose();
          completer.completeError(e, st);
        },
      ),
    );

    // Insert the hidden entry into the nearest Overlay.
    Overlay.of(context).insert(entry);

    return completer.future.timeout(
      config.timeout,
      onTimeout: () {
        entry?.remove();
        entry?.dispose();
        throw TimeoutException(
          'QuantumWidgetImageExporter: export timed out after '
          '${config.timeout.inSeconds}s. Is the QuantumVM fully initialized?',
          config.timeout,
        );
      },
    );
  }

  /// Read a 4-byte big-endian int from [bytes] at [offset] (for PNG parsing).
  static int _readPngDimension(Uint8List bytes, int offset) {
    if (bytes.length < offset + 4) return 0;
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  OFFSCREEN HOST WIDGET (internal)
// ─────────────────────────────────────────────────────────────────────────────

/// A fully invisible widget that inflates the SDUI blueprint inside a proper
/// [QLDataScope] + [RepaintBoundary] and fires [onReady] after the first paint.
class _OffscreenCaptureHost extends StatefulWidget {
  final GlobalKey repaintKey;
  final QLBlueprint blueprint;
  final QLDataStore store;
  final QuantumExportConfig config;
  final void Function(RenderRepaintBoundary) onReady;
  final void Function(Object, StackTrace) onError;

  const _OffscreenCaptureHost({
    required this.repaintKey,
    required this.blueprint,
    required this.store,
    required this.config,
    required this.onReady,
    required this.onError,
  });

  @override
  State<_OffscreenCaptureHost> createState() => _OffscreenCaptureHostState();
}

class _OffscreenCaptureHostState extends State<_OffscreenCaptureHost> {
  bool _captured = false;

  @override
  void initState() {
    super.initState();
    // Schedule capture after the first frame completes painting.
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    if (_captured || !mounted) return;
    _captured = true;

    await Future<void>.delayed(
      // Give reactive widgets (signals, animations) one extra frame to settle.
      const Duration(milliseconds: 80),
    );

    if (!mounted) return;

    final RenderObject? ro =
        widget.repaintKey.currentContext?.findRenderObject();
    if (ro is RenderRepaintBoundary) {
      widget.onReady(ro);
    } else {
      widget.onError(
        StateError(
          'QuantumWidgetImageExporter: RenderRepaintBoundary not found. '
          'Make sure the QuantumVM is initialized before exporting.',
        ),
        StackTrace.current,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double logicalWidth = widget.config.width;
    final double? logicalHeight = widget.config.height;

    // Build the rendered widget from the compiled blueprint.
    final Widget sduiWidget = QLDataScope(
      moduleStore: widget.store,
      child: Builder(
        builder: (ctx) => QuantumVM.instance.renderWidget(ctx, widget.blueprint),
      ),
    );

    // Wrap in a SizedBox to enforce the desired viewport.
    final Widget sized = SizedBox(
      width: logicalWidth,
      height: logicalHeight,
      child: logicalHeight != null
          ? sduiWidget
          : SingleChildScrollView(
              // Unbounded height: let the widget decide its own height.
              physics: const NeverScrollableScrollPhysics(),
              child: sduiWidget,
            ),
    );

    // Positioned far off-screen so it never shows on screen, but still paints.
    return Positioned(
      left: -10000,
      top: -10000,
      child: RepaintBoundary(
        key: widget.repaintKey,
        child: MediaQuery(
          // Override device pixel ratio so captures are always crisp at the
          // requested pixelRatio regardless of the host device's DPR.
          data: MediaQuery.of(context).copyWith(
            size: Size(logicalWidth, logicalHeight ?? 10000),
            devicePixelRatio: widget.config.pixelRatio,
          ),
          child: ColoredBox(
            color: widget.config.background,
            child: sized,
          ),
        ),
      ),
    );
  }
}
