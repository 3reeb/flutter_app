// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SDUI TEST ENGINE — IO implementation
// quantum_sdui_test_engine_io.dart
//
// Real runtime behavior:
// 1. Scans a folder for .json SDUI cases
// 2. Parses each JSON file independently
// 3. Compiles with QLCompiler
// 4. Renders in a hidden probe surface
// 5. Captures pixels from a RepaintBoundary
// 6. Flags thrown errors AND blank / white renders
// 7. Continues after failures so one broken case never blocks the others
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:quantum_layout/quantum.dart';
import 'quantum_sdui_test_engine_shared.dart';
final class QuantumSduiTestEngine {
  static final QuantumSduiTestEngine instance = QuantumSduiTestEngine._();
  QuantumSduiTestEngine._();

  QuantumSduiTestReport? _lastReport;
  QuantumSduiTestReport? get lastReport => _lastReport;

  Future<List<QuantumSduiTestCase>> discoverFolder(
    String folderPath, {
    bool recursive = true,
  }) async {
    final dir = Directory(folderPath);
    if (!await dir.exists()) {
      throw QuantumSduiTestException(
        'Folder does not exist: $folderPath',
        code: 'FOLDER_NOT_FOUND',
      );
    }

    final cases = <QuantumSduiTestCase>[];
    await for (final entity
        in dir.list(recursive: recursive, followLinks: false)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.json')) continue;
      try {
        cases.add(await loadCase(entity));
      } catch (e) {
        debugPrint('[QuantumSduiTestEngine] skipping ${entity.path}: $e');
      }
    }

    cases.sort((a, b) => a.filePath.compareTo(b.filePath));
    return cases;
  }

  Future<QuantumSduiTestCase> loadCase(File file) async {
    final source = await file.readAsString();
    final cleaned = _stripJsonWrapper(source);
    final dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } catch (e) {
      throw QuantumSduiTestException(
        'Invalid JSON in ${file.path}: $e',
        code: 'JSON_PARSE_ERROR',
        cause: e,
      );
    }

    if (decoded is! Map) {
      throw QuantumSduiTestException(
        'Top-level JSON must be an object in ${file.path}.',
        code: 'INVALID_ROOT',
      );
    }

    return QuantumSduiTestCase.fromFilePath(
      file.path,
      source,
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<QuantumSduiTestReport> runFolder(
    BuildContext context, {
    required String folderPath,
    bool recursive = true,
    bool stopOnFirstFailure = false,
    Size defaultViewport = const Size(390, 844),
    double defaultPixelRatio = 1.0,
    Duration timeout = const Duration(seconds: 8),
    String? outputJsonPath,
    String? outputImageDirectory,
  }) async {
    final started = DateTime.now();
    final cases = await discoverFolder(folderPath, recursive: recursive);
    final results = <QuantumSduiTestResult>[];

    for (final testCase in cases) {
      final viewport = testCase.viewport.logicalSize == Size.zero
          ? defaultViewport
          : testCase.viewport.logicalSize;
      final pixelRatio = testCase.viewport.pixelRatio > 0
          ? testCase.viewport.pixelRatio
          : defaultPixelRatio;

      final result = await runCase(
        context,
        testCase,
        viewport: viewport,
        pixelRatio: pixelRatio,
        timeout: timeout,
        outputImageDirectory: outputImageDirectory,
      );
      results.add(result);
      if (stopOnFirstFailure && !result.ok) break;
    }

    final report = QuantumSduiTestReport(
      results: results,
      startedAt: started,
      finishedAt: DateTime.now(),
      folderPath: folderPath,
      recursive: recursive,
    );
    _lastReport = report;

    if (outputJsonPath != null && outputJsonPath.trim().isNotEmpty) {
      final outFile = File(outputJsonPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsString(report.toPrettyJson(), flush: true);
    }

    return report;
  }

  Future<QuantumSduiTestResult> runCase(
    BuildContext context,
    QuantumSduiTestCase testCase, {
    Size? viewport,
    double? pixelRatio,
    Duration? timeout,
    String? outputImageDirectory,
  }) async {
    final sw = Stopwatch()..start();
    final Size resolvedViewport = viewport ?? testCase.viewport.logicalSize;
    final double resolvedPixelRatio =
        pixelRatio ?? testCase.viewport.pixelRatio;
    final Duration resolvedTimeout =
        timeout ?? Duration(milliseconds: testCase.timeoutMs);

    try {
      final Map<String, dynamic> root = testCase.compileRoot();
      final QLBlueprint blueprint = await QLCompiler.compileAsync(
        root,
        const <String, dynamic>{},
        testCase.env,
      );

      final String? screenshotPath = (outputImageDirectory != null &&
              outputImageDirectory.trim().isNotEmpty)
          ? _defaultScreenshotPath(outputImageDirectory, testCase, '.png')
          : null;

      final _ProbeOutcome outcome = await _runRenderProbe(
        context,
        blueprint: blueprint,
        caseId: testCase.id,
        title: testCase.title,
        viewport: resolvedViewport,
        pixelRatio: resolvedPixelRatio,
        background: testCase.background,
        allowSolidFill: testCase.allowSolidFill,
        allowBlank: testCase.allowBlank,
        timeout: resolvedTimeout,
        outputImagePath: screenshotPath,
      );

      sw.stop();

      if (outcome.error != null) {
        return QuantumSduiTestResult.fail(
          caseId: testCase.id,
          title: testCase.title,
          filePath: testCase.filePath,
          duration: sw.elapsed,
          phase: QuantumSduiTestPhase.rendered,
          message: outcome.message ?? 'Render failed.',
          error: outcome.error.toString(),
          stackTrace: outcome.stackTrace,
          analysis: outcome.analysis,
          details: <String, dynamic>{
            'viewport': outcome.viewport.toString(),
            if (outcome.screenshotPath != null)
              'screenshotPath': outcome.screenshotPath,
          },
        );
      }

      if (outcome.analysis.blank && !testCase.allowBlank) {
        return QuantumSduiTestResult.fail(
          caseId: testCase.id,
          title: testCase.title,
          filePath: testCase.filePath,
          duration: sw.elapsed,
          phase: QuantumSduiTestPhase.rendered,
          message: 'Render produced a blank / uniform frame.',
          analysis: outcome.analysis,
          details: <String, dynamic>{
            'viewport': outcome.viewport.toString(),
            if (outcome.screenshotPath != null)
              'screenshotPath': outcome.screenshotPath,
          },
        );
      }

      return QuantumSduiTestResult.pass(
        caseId: testCase.id,
        title: testCase.title,
        filePath: testCase.filePath,
        duration: sw.elapsed,
        analysis: outcome.analysis,
        message: 'Compiled and rendered successfully.',
        details: <String, dynamic>{
          'viewport': outcome.viewport.toString(),
          if (outcome.screenshotPath != null)
            'screenshotPath': outcome.screenshotPath,
        },
      );
    } on QuantumSduiTestException catch (e, st) {
      sw.stop();
      return QuantumSduiTestResult.fail(
        caseId: testCase.id,
        title: testCase.title,
        filePath: testCase.filePath,
        duration: sw.elapsed,
        phase: QuantumSduiTestPhase.failed,
        message: e.message,
        error: e.toString(),
        stackTrace: st.toString(),
        details: <String, dynamic>{'code': e.code},
      );
    } catch (e, st) {
      sw.stop();
      return QuantumSduiTestResult.fail(
        caseId: testCase.id,
        title: testCase.title,
        filePath: testCase.filePath,
        duration: sw.elapsed,
        phase: QuantumSduiTestPhase.failed,
        message: 'Unexpected test failure.',
        error: e.toString(),
        stackTrace: st.toString(),
      );
    }
  }

  Future<QuantumSduiTestReport> runAllRegistered({
    required BuildContext context,
    required List<QuantumSduiTestCase> cases,
    Size defaultViewport = const Size(390, 844),
    double defaultPixelRatio = 1.0,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final started = DateTime.now();
    final results = <QuantumSduiTestResult>[];
    for (final testCase in cases) {
      results.add(
        await runCase(
          context,
          testCase,
          viewport: testCase.viewport.logicalSize == Size.zero
              ? defaultViewport
              : testCase.viewport.logicalSize,
          pixelRatio: testCase.viewport.pixelRatio > 0
              ? testCase.viewport.pixelRatio
              : defaultPixelRatio,
          timeout: timeout,
        ),
      );
    }
    final report = QuantumSduiTestReport(
      results: results,
      startedAt: started,
      finishedAt: DateTime.now(),
      folderPath: '(in-memory)',
      recursive: true,
    );
    _lastReport = report;
    return report;
  }

  Future<QuantumSduiTestReport> saveLastReport(
    String outputJsonPath,
  ) async {
    final report = _lastReport;
    if (report == null) {
      throw const QuantumSduiTestException(
        'No report available to save.',
        code: 'NO_REPORT',
      );
    }
    final outFile = File(outputJsonPath);
    await outFile.parent.create(recursive: true);
    await outFile.writeAsString(report.toPrettyJson(), flush: true);
    return report;
  }

  Future<_ProbeOutcome> _runRenderProbe(
    BuildContext context, {
    required QLBlueprint blueprint,
    required String caseId,
    required String title,
    required Size viewport,
    required double pixelRatio,
    required Color background,
    required bool allowSolidFill,
    required bool allowBlank,
    required Duration timeout,
    String? outputImagePath,
  }) async {
    final OverlayState? overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      throw const QuantumSduiTestException(
        'No overlay found. Call runFolder() from a widget context.',
        code: 'NO_OVERLAY',
      );
    }

    final completer = Completer<_ProbeOutcome>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      maintainState: true,
      builder: (overlayContext) {
        return Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: _QuantumSduiRenderProbe(
              caseId: caseId,
              title: title,
              blueprint: blueprint,
              viewport: viewport,
              pixelRatio: pixelRatio,
              background: background,
              allowSolidFill: allowSolidFill,
              allowBlank: allowBlank,
              outputImagePath: outputImagePath,
              onComplete: (outcome) {
                if (!completer.isCompleted) completer.complete(outcome);
              },
            ),
          ),
        );
      },
    );

    overlay.insert(entry);
    try {
      final outcome = await completer.future.timeout(timeout, onTimeout: () {
        return _ProbeOutcome.error(
          viewport: viewport,
          message: 'Timed out after ${timeout.inMilliseconds}ms.',
          error: QuantumSduiTestException(
            'Render probe timed out after ${timeout.inMilliseconds}ms.',
            code: 'TIMEOUT',
          ),
        );
      });
      return outcome;
    } finally {
      entry.remove();
    }
  }

  String _defaultScreenshotPath(
    String directory,
    QuantumSduiTestCase testCase,
    String suffix,
  ) {
    final safeName = testCase.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    return '$directory/$safeName$suffix';
  }
}

@immutable
class _ProbeOutcome {
  final QuantumSduiRenderAnalysis analysis;
  final Size viewport;
  final Object? error;
  final String? stackTrace;
  final String? message;
  final String? screenshotPath;

  const _ProbeOutcome({
    required this.analysis,
    required this.viewport,
    this.error,
    this.stackTrace,
    this.message,
    this.screenshotPath,
  });

  factory _ProbeOutcome.error({
    required Size viewport,
    required String message,
    required Object error,
    String? stackTrace,
  }) {
    return _ProbeOutcome(
      analysis: QuantumSduiRenderAnalysis(
        blank: true,
        uniform: true,
        distinctBuckets: 0,
        luminanceStdDev: 0,
        backgroundMatchRatio: 1,
        totalPixels: 0,
        visiblePixels: 0,
        width: viewport.width.round(),
        height: viewport.height.round(),
        note: message,
      ),
      viewport: viewport,
      error: error,
      stackTrace: stackTrace,
      message: message,
    );
  }
}

class _QuantumSduiRenderProbe extends StatefulWidget {
  final String caseId;
  final String title;
  final QLBlueprint blueprint;
  final Size viewport;
  final double pixelRatio;
  final Color background;
  final bool allowSolidFill;
  final bool allowBlank;
  final String? outputImagePath;
  final void Function(_ProbeOutcome outcome) onComplete;

  const _QuantumSduiRenderProbe({
    required this.caseId,
    required this.title,
    required this.blueprint,
    required this.viewport,
    required this.pixelRatio,
    required this.background,
    required this.allowSolidFill,
    required this.allowBlank,
    required this.outputImagePath,
    required this.onComplete,
  });

  @override
  State<_QuantumSduiRenderProbe> createState() =>
      _QuantumSduiRenderProbeState();
}

class _QuantumSduiRenderProbeState extends State<_QuantumSduiRenderProbe> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _captured = false;
  Object? _boundaryError;
  String? _boundaryStack;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLater());
  }

  void _captureLater() {
    if (!mounted || _captured) return;
    _captured = true;
    Future<void>.delayed(const Duration(milliseconds: 40), _capture);
  }

  Future<void> _capture() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary) {
        widget.onComplete(
          _ProbeOutcome.error(
            viewport: widget.viewport,
            message: 'Render boundary is not ready.',
            error: QuantumSduiTestException(
              'Render boundary is not ready.',
              code: 'BOUNDARY_NOT_READY',
            ),
          ),
        );
        return;
      }

      final ui.Image image = await boundary.toImage(
        pixelRatio: widget.pixelRatio <= 0 ? 1.0 : widget.pixelRatio,
      );
      final ByteData? raw = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (raw == null) {
        widget.onComplete(
          _ProbeOutcome.error(
            viewport: widget.viewport,
            message: 'Unable to read pixel buffer.',
            error: QuantumSduiTestException(
              'Unable to read pixel buffer.',
              code: 'PIXEL_BUFFER_NULL',
            ),
          ),
        );
        return;
      }

      final Uint8List rgba = raw.buffer.asUint8List();
      final analysis = _analyzeFrame(
        rgba,
        width: (widget.viewport.width * widget.pixelRatio).round(),
        height: (widget.viewport.height * widget.pixelRatio).round(),
        background: widget.background,
        allowBlank: widget.allowBlank,
        allowSolidFill: widget.allowSolidFill,
      );

      String? screenshotPath;
      if (widget.outputImagePath != null) {
        final ByteData? png = await image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png != null) {
          final file = File(widget.outputImagePath!);
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
          screenshotPath = file.path;
        }
      }

      widget.onComplete(
        _ProbeOutcome(
          analysis: analysis.copyWith(
            note: analysis.note ??
                (_boundaryError != null ? 'Boundary error captured.' : null),
          ),
          viewport: widget.viewport,
          error: _boundaryError,
          stackTrace: _boundaryStack,
          message: _boundaryError != null
              ? 'Boundary error captured.'
              : 'Rendered successfully.',
          screenshotPath: screenshotPath,
        ),
      );
    } catch (e, st) {
      widget.onComplete(
        _ProbeOutcome.error(
          viewport: widget.viewport,
          message: e.toString(),
          error: e,
          stackTrace: st.toString(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(brightness: Brightness.light, useMaterial3: true);

    return Material(
      color: widget.background,
      child: Theme(
        data: theme,
        child: MediaQuery(
          data: MediaQueryData(
            size: widget.viewport,
            devicePixelRatio: widget.pixelRatio,
            textScaler: TextScaler.noScaling,
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: widget.viewport.width,
                height: widget.viewport.height,
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: QLErrorBoundary(
                    label: 'sdui-test:${widget.caseId}',
                    maxRetries: 0,
                    onError: (state) {
                      _boundaryError = state.error;
                      _boundaryStack = state.stackTrace?.toString();
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _captureLater();
                      });
                    },
                    fallback: (ctx, error, retry) {
                      return Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Render error in ${widget.title}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SelectableText(error.error.toString()),
                              if ((error.stackTrace?.toString() ?? '')
                                  .trim()
                                  .isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SelectableText(error.stackTrace!.toString()),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    builder: (_) {
                      return QuantumVM.instance.renderWidget(
                        context,
                        widget.blueprint,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

QuantumSduiRenderAnalysis _analyzeFrame(
  Uint8List rgba, {
  required int width,
  required int height,
  required Color background,
  required bool allowBlank,
  required bool allowSolidFill,
}) {
  final int totalPixels = math.max(0, width * height);
  if (totalPixels == 0 || rgba.length < totalPixels * 4) {
    return QuantumSduiRenderAnalysis(
      blank: !allowBlank,
      uniform: true,
      distinctBuckets: 0,
      luminanceStdDev: 0,
      backgroundMatchRatio: 1,
      totalPixels: totalPixels,
      visiblePixels: 0,
      width: width,
      height: height,
      note: 'Empty frame buffer.',
    );
  }

  final Map<int, int> buckets = <int, int>{};
  int visiblePixels = 0;
  int backgroundMatches = 0;
  double mean = 0;
  double m2 = 0;
  int n = 0;

  final int bgR = background.red;
  final int bgG = background.green;
  final int bgB = background.blue;
  final int bgA = background.alpha;

  for (int i = 0; i < rgba.length; i += 4) {
    final int r = rgba[i];
    final int g = rgba[i + 1];
    final int b = rgba[i + 2];
    final int a = rgba[i + 3];

    if (a > 12) visiblePixels++;

    final double lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    n++;
    final double delta = lum - mean;
    mean += delta / n;
    m2 += delta * (lum - mean);

    final int bucket =
        ((r >> 4) << 12) | ((g >> 4) << 8) | ((b >> 4) << 4) | (a >> 4);
    buckets[bucket] = (buckets[bucket] ?? 0) + 1;

    if ((r - bgR).abs() <= 8 &&
        (g - bgG).abs() <= 8 &&
        (b - bgB).abs() <= 8 &&
        (a - bgA).abs() <= 8) {
      backgroundMatches++;
    }
  }

  final double variance = n > 1 ? m2 / (n - 1) : 0;
  final double stdDev = math.sqrt(math.max(0, variance));
  final double backgroundRatio =
      totalPixels == 0 ? 1 : backgroundMatches / totalPixels.toDouble();
  final int distinctBuckets = buckets.length;
  final bool uniform = stdDev < 2.4 || distinctBuckets <= 6;
  final bool blank = !allowBlank && !allowSolidFill && uniform;

  return QuantumSduiRenderAnalysis(
    blank: blank,
    uniform: uniform,
    distinctBuckets: distinctBuckets,
    luminanceStdDev: stdDev,
    backgroundMatchRatio: backgroundRatio,
    totalPixels: totalPixels,
    visiblePixels: visiblePixels,
    width: width,
    height: height,
    note: blank
        ? 'Blank / uniform render detected.'
        : (uniform ? 'Uniform but allowed.' : 'Non-uniform render captured.'),
  );
}

String _stripJsonWrapper(String input) {
  var text = input.trim();
  if (text.startsWith('```')) {
    final lines = text.split('\n');
    if (lines.isNotEmpty) lines.removeAt(0);
    if (lines.isNotEmpty && lines.last.trim() == '```') {
      lines.removeLast();
    }
    text = lines.join('\n').trim();
  }
  if (text.startsWith('json\n')) {
    text = text.substring(5).trimLeft();
  }
  if (text.startsWith('JSON\n')) {
    text = text.substring(5).trimLeft();
  }
  return text;
}

extension on QuantumSduiRenderAnalysis {
  QuantumSduiRenderAnalysis copyWith({
    bool? blank,
    bool? uniform,
    int? distinctBuckets,
    double? luminanceStdDev,
    double? backgroundMatchRatio,
    int? totalPixels,
    int? visiblePixels,
    int? width,
    int? height,
    String? note,
  }) {
    return QuantumSduiRenderAnalysis(
      blank: blank ?? this.blank,
      uniform: uniform ?? this.uniform,
      distinctBuckets: distinctBuckets ?? this.distinctBuckets,
      luminanceStdDev: luminanceStdDev ?? this.luminanceStdDev,
      backgroundMatchRatio: backgroundMatchRatio ?? this.backgroundMatchRatio,
      totalPixels: totalPixels ?? this.totalPixels,
      visiblePixels: visiblePixels ?? this.visiblePixels,
      width: width ?? this.width,
      height: height ?? this.height,
      note: note ?? this.note,
    );
  }
}
