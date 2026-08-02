/*
 * ============================================================================
 * File: qte_performance.dart
 * 
 * Description:
 * Manages the profiling and performance monitoring aspects of the Quantum Test Engine.
 * It is responsible for capturing memory snapshots, measuring frame render times (build,
 * raster, total), detecting jank, and tracking overall step execution costs against
 * predefined budgets.
 * 
 * Key Components:
 * - QTEMemorySnapshot: Records RSS and heap usage at a specific point in time.
 * - QTEFrameTimingRecord: Captures microsecond-level timing for a single frame.
 * - QTEStepPerformance: Aggregates performance data for an entire test step.
 * - QTEPerformanceProfiler: The engine component that instruments the tester and collects metrics.
 * 
 * Dependencies/Relationships:
 * Uses dart:io for process memory info and dart:ui for FrameTiming API.
 * Interacts with lutter_test and provides data consumed by qte_assertion.dart.
 * 
 * Notes:
 * Frame timing capture relies on 	ester.binding.addTimingsCallback, which may
 * behave differently or be unavailable in web test environments. Memory profiling
 * uses ProcessInfo.currentRss which is native-only.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE PERFORMANCE PROFILER — qte_performance.dart
// Records frame timing, memory snapshots, rasterize cost, jank detection.
// ══════════════════════════════════════════════════════════════════════════════
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'qte_schema.dart';

class QTEMemorySnapshot {
  final int rssBytes;
  final int heapUsedBytes;
  final int heapCapacityBytes;
  final String stepId;
  final DateTime timestamp;

  const QTEMemorySnapshot({
    required this.rssBytes,
    required this.heapUsedBytes,
    required this.heapCapacityBytes,
    required this.stepId,
    required this.timestamp,
  });

  double get rssMb => rssBytes / (1024 * 1024);
  double get heapUsedMb => heapUsedBytes / (1024 * 1024);
  double get heapCapacityMb => heapCapacityBytes / (1024 * 1024);

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'timestamp': timestamp.toIso8601String(),
    'rssBytes': rssBytes,
    'rssMb': rssMb,
    'heapUsedBytes': heapUsedBytes,
    'heapUsedMb': heapUsedMb,
    'heapCapacityBytes': heapCapacityBytes,
    'heapCapacityMb': heapCapacityMb,
  };

  @override
  String toString() =>
      '[Memory] RSS=${rssMb.toStringAsFixed(1)}MB heap=${heapUsedMb.toStringAsFixed(1)}MB/${heapCapacityMb.toStringAsFixed(1)}MB (step=$stepId)';
}

class QTEFrameTimingRecord {
  final int buildMicros;
  final int rasterMicros;
  final int totalMicros;
  final String stepId;
  final DateTime timestamp;

  const QTEFrameTimingRecord({
    required this.buildMicros,
    required this.rasterMicros,
    required this.totalMicros,
    required this.stepId,
    required this.timestamp,
  });

  double get buildMs => buildMicros / 1000.0;
  double get rasterMs => rasterMicros / 1000.0;
  double get totalMs => totalMicros / 1000.0;
  bool get isJank => totalMs > 16.0;

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'timestamp': timestamp.toIso8601String(),
    'buildMs': buildMs,
    'rasterMs': rasterMs,
    'totalMs': totalMs,
    'isJank': isJank,
  };

  @override
  String toString() =>
      '[Frame] build=${buildMs.toStringAsFixed(1)}ms raster=${rasterMs.toStringAsFixed(1)}ms '
      'total=${totalMs.toStringAsFixed(1)}ms${isJank ? " ⚠️JANK" : ""}';
}

class QTEStepPerformance {
  final String stepId;
  final double firstFrameMs;
  final double reRenderMs;
  final List<QTEFrameTimingRecord> frames;
  final QTEMemorySnapshot? memoryBefore;
  final QTEMemorySnapshot? memoryAfter;
  final int frameDropCount;

  const QTEStepPerformance({
    required this.stepId,
    required this.firstFrameMs,
    required this.reRenderMs,
    required this.frames,
    this.memoryBefore,
    this.memoryAfter,
    required this.frameDropCount,
  });

  double? get memoryDeltaMb {
    if (memoryBefore == null || memoryAfter == null) return null;
    return memoryAfter!.rssMb - memoryBefore!.rssMb;
  }

  double get peakFrameMs =>
      frames.isEmpty ? 0 : frames.map((f) => f.totalMs).reduce((a, b) => a > b ? a : b);

  double get avgFrameMs =>
      frames.isEmpty ? 0 : frames.map((f) => f.totalMs).reduce((a, b) => a + b) / frames.length;

  Map<String, dynamic> toJson() => {
    'stepId': stepId,
    'firstFrameMs': firstFrameMs,
    'reRenderMs': reRenderMs,
    'frameDropCount': frameDropCount,
    'peakFrameMs': peakFrameMs,
    'avgFrameMs': avgFrameMs,
    if (memoryBefore != null) 'memoryBefore': memoryBefore!.toJson(),
    if (memoryAfter != null) 'memoryAfter': memoryAfter!.toJson(),
    if (memoryDeltaMb != null) 'memoryDeltaMb': memoryDeltaMb,
    'frames': frames.map((f) => f.toJson()).toList(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class QTEPerformanceProfiler {
  final WidgetTester tester;
  final QTEPerformanceBudget budget;

  final List<QTEStepPerformance> _stepRecords = [];
  final Map<String, QTEMemorySnapshot> _stepMemorySnapshots = {};

  QTEPerformanceProfiler(this.tester, this.budget);

  List<QTEStepPerformance> get allStepRecords => List.unmodifiable(_stepRecords);

  // ── Capture memory snapshot ────────────────────────────────────────────────
  QTEMemorySnapshot captureMemory(String stepId) {
    int rss = 0, heapUsed = 0, heapCap = 0;
    try {
      final info = ProcessInfo.currentRss;
      rss = info;
    } catch (_) {}
    // Use ProcessInfo for RSS in native environments
    try { rss = ProcessInfo.currentRss; } catch (_) {}

    final snap = QTEMemorySnapshot(
      rssBytes: rss,
      heapUsedBytes: heapUsed,
      heapCapacityBytes: heapCap,
      stepId: stepId,
      timestamp: DateTime.now(),
    );
    _stepMemorySnapshots[stepId] = snap;
    return snap;
  }

  QTEMemorySnapshot? getMemorySnapshot(String stepId) => _stepMemorySnapshots[stepId];

  // ── Measure first frame ────────────────────────────────────────────────────
  Future<double> measureFirstFrame(Future<void> Function() renderFn) async {
    final sw = Stopwatch()..start();
    await renderFn();
    await tester.pump();
    sw.stop();
    return sw.elapsedMicroseconds / 1000.0;
  }

  // ── Measure re-render after state change ──────────────────────────────────
  Future<double> measureReRender(Future<void> Function() mutateFn) async {
    final sw = Stopwatch()..start();
    await mutateFn();
    await tester.pump();
    sw.stop();
    return sw.elapsedMicroseconds / 1000.0;
  }

  // ── Collect frame timings during an action ─────────────────────────────────
  Future<List<QTEFrameTimingRecord>> collectFramesDuring(
    String stepId,
    Future<void> Function() action,
  ) async {
    final records = <QTEFrameTimingRecord>[];

    if (kIsWeb) {
      // Frame timing API not available on web test
      await action();
      return records;
    }

    final timings = <FrameTiming>[];
    void cb(List<FrameTiming> ts) => timings.addAll(ts);
    tester.binding.addTimingsCallback(cb);

    try {
      await action();
      try {
        await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
      } catch (_) {}
    } finally {
      tester.binding.removeTimingsCallback(cb);
    }

    for (final t in timings) {
      records.add(QTEFrameTimingRecord(
        buildMicros: t.buildDuration.inMicroseconds,
        rasterMicros: t.rasterDuration.inMicroseconds,
        totalMicros: t.totalSpan.inMicroseconds,
        stepId: stepId,
        timestamp: DateTime.now(),
      ));
    }
    return records;
  }

  // ── Record a full step performance ────────────────────────────────────────
  void recordStep(QTEStepPerformance perf) {
    _stepRecords.add(perf);
    if (kDebugMode) {
      debugPrint('[QTEPerf] Step "${perf.stepId}": '
          'firstFrame=${perf.firstFrameMs.toStringAsFixed(1)}ms '
          'reRender=${perf.reRenderMs.toStringAsFixed(1)}ms '
          'drops=${perf.frameDropCount}'
          '${perf.memoryDeltaMb != null ? " memDelta=${perf.memoryDeltaMb!.toStringAsFixed(1)}MB" : ""}');
    }
  }

  // ── Budget checks ─────────────────────────────────────────────────────────
  String? checkFirstFrame(double ms) {
    if (budget.maxFirstFrameMs != null && ms > budget.maxFirstFrameMs!) {
      return 'First frame ${ms.toStringAsFixed(1)}ms exceeds budget ${budget.maxFirstFrameMs}ms';
    }
    return null;
  }

  String? checkReRender(double ms) {
    if (budget.maxReRenderMs != null && ms > budget.maxReRenderMs!) {
      return 'Re-render ${ms.toStringAsFixed(1)}ms exceeds budget ${budget.maxReRenderMs}ms';
    }
    return null;
  }

  String? checkMemory(double mb) {
    if (budget.maxMemoryMb != null && mb > budget.maxMemoryMb!) {
      return 'Memory ${mb.toStringAsFixed(1)}MB exceeds budget ${budget.maxMemoryMb}MB';
    }
    return null;
  }

  String? checkFrameDrops(int drops) {
    if (drops > budget.maxFrameDrops) {
      return '$drops frame drops exceed budget ${budget.maxFrameDrops}';
    }
    return null;
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  Map<String, dynamic> summary() {
    final allFrames = _stepRecords.expand((s) => s.frames).toList();
    final totalDrops = _stepRecords.fold(0, (a, s) => a + s.frameDropCount);
    final avgFirst = _stepRecords.isEmpty ? 0.0
        : _stepRecords.map((s) => s.firstFrameMs).reduce((a, b) => a + b) / _stepRecords.length;

    return {
      'stepCount': _stepRecords.length,
      'totalFrameDrops': totalDrops,
      'avgFirstFrameMs': avgFirst,
      'totalFramesCaptured': allFrames.length,
      'jankFrames': allFrames.where((f) => f.isJank).length,
      'steps': _stepRecords.map((s) => s.toJson()).toList(),
    };
  }
}
