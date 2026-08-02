/*
 * ============================================================================
 * File: qte_runner.dart
 * 
 * Description:
 * The central orchestrator of the Quantum Test Engine. It coordinates the entire lifecycle
 * of a test execution: initializing the test environment (host widget), iterating through
 * defined steps, dispatching interactions, evaluating assertions, monitoring performance,
 * and finally tearing down and generating the report.
 * 
 * Key Components:
 * - QTERunnerConfig: Configuration options (fail fast, verbose logging) for test execution.
 * - QTERunner: The main execution loop that processes a QTETestFile.
 * - qteRunJson / qteRunJsonString: Public entry points for executing tests from raw JSON data.
 * 
 * Dependencies/Relationships:
 * Integrates virtually all other QTE components: qte_host_widget, qte_interaction, 
 * qte_assertion, qte_performance, qte_reactive, and qte_report.
 * 
 * Notes:
 * Tests execute asynchronously, utilizing the WidgetTester to pump frames and allow
 * the UI and state to settle between steps. Fail-fast mode will immediately abort
 * the suite upon the first error, skipping remaining steps.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE RUNNER — qte_runner.dart
// Orchestrates: setup → steps (interact → assert → snapshot) → teardown → report
// ══════════════════════════════════════════════════════════════════════════════
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';
import 'qte_schema.dart';
import 'qte_validator.dart';
import 'qte_render_probe.dart';
import 'qte_reactive.dart';
import 'qte_performance.dart';
import 'qte_interaction.dart';
import 'qte_assertion.dart';
import 'qte_report.dart';
import 'qte_host_widget.dart';

class QTERunnerConfig {
  /// Stop after first failed step
  final bool failFast;
  /// Also run disabled steps
  final bool runDisabled;
  /// Print step-by-step progress to debugPrint
  final bool verbose;
  /// Output a JUnit XML report alongside the text report
  final bool junitOutput;

  const QTERunnerConfig({
    this.failFast = false,
    this.runDisabled = false,
    this.verbose = true,
    this.junitOutput = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class QTERunner {
  final QTETestFile testFile;
  final QTERunnerConfig config;

  QTERunner(this.testFile, {this.config = const QTERunnerConfig()});

  // ── Entry point from flutter_test ─────────────────────────────────────────
  Future<QTERunResult> run(WidgetTester tester) async {
    print('QTERunner.run STARTING...');
    if (config.verbose) {
      debugPrint('\n[QTE] ▶ Starting test: ${testFile.title} [${testFile.id}]');
    }

    final totalSw = Stopwatch()..start();

    // ── 1. Build host ────────────────────────────────────────────────────────
    print('QTERunner: building host...');
    final host = QTEHostBuilder.build(testFile);
    final store = host.store;

    print('QTERunner: pumping widget...');
    await tester.pumpWidget(host.widget);
    print('QTERunner: pumping widget done, trying pumpAndSettle...');
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    } catch (_) {
      print('QTERunner: pumpAndSettle timed out, doing pump() instead...');
      await tester.pump();
    }
    print('QTERunner: pumpAndSettle done!');

    // ── 2. Build engines ─────────────────────────────────────────────────────
    final probe = QTERenderProbe(tester);
    final watcher = QTEReactiveWatcher(store);
    final profiler = QTEPerformanceProfiler(tester, testFile.performance);

    final interactionEngine = QTEInteractionEngine(
      tester: tester, store: store, probe: probe, watcher: watcher,
    );
    final assertionEngine = QTEAssertionEngine(
      tester: tester, store: store, probe: probe, watcher: watcher, profiler: profiler,
    );

    // Watch all store keys referenced in assertions
    for (final step in testFile.steps) {
      for (final a in step.assertions) {
        if (a.storeKey != null) watcher.watchKey(a.storeKey!);
      }
    }

    watcher.start();

    // ── 3. Run steps ─────────────────────────────────────────────────────────
    final stepResults = <QTEStepResult>[];

    for (final step in testFile.steps) {
      if (step.disabled && !config.runDisabled) {
        if (config.verbose) debugPrint('[QTE]   ⏭ Skipped: ${step.id}');
        stepResults.add(QTEStepResult(
          stepId: step.id, label: step.label,
          status: QTEStepStatus.skipped, assertions: [],
          elapsed: Duration.zero,
        ));
        continue;
      }

      final result = await _runStep(
        step, store, tester, probe, watcher, profiler,
        interactionEngine, assertionEngine,
      );
      stepResults.add(result);

      if (config.failFast && result.status == QTEStepStatus.failed) {
        if (config.verbose) debugPrint('[QTE]   ⛔ Fail-fast: stopping after step ${step.id}');
        break;
      }
    }

    watcher.stop();
    totalSw.stop();

    // ── 4. Teardown ──────────────────────────────────────────────────────────
    if (testFile.teardownClearState) {
      store.sweep('');
      store.clearCache();
    }
    if (testFile.teardownClearCache) {
      QLCompiler.clearCaches();
    }

    // ── 5. Build report ───────────────────────────────────────────────────────
    final report = QTEReportGenerator.build(
      testId: testFile.id,
      title: testFile.title,
      steps: stepResults,
      totalElapsed: totalSw.elapsed,
      performanceSummary: testFile.performance.trackFrames || testFile.performance.trackMemory
          ? profiler.summary() : null,
    );

    if (config.verbose) {
      debugPrint(QTEReportGenerator.textReport(report));
    }

    return report;
  }

  // ── Run a single step ─────────────────────────────────────────────────────
  Future<QTEStepResult> _runStep(
    QTEStepDef step,
    QLDataStore store,
    WidgetTester tester,
    QTERenderProbe probe,
    QTEReactiveWatcher watcher,
    QTEPerformanceProfiler profiler,
    QTEInteractionEngine interactionEngine,
    QTEAssertionEngine assertionEngine,
  ) async {
    if (config.verbose) debugPrint('[QTE]   ▷ Step [${step.id}]: ${step.label}');

    watcher.setCurrentStep(step.id);
    final stepSw = Stopwatch()..start();

    String? interactionError;
    QTEStepPerformance? stepPerf;

    // ── Capture memory before ─────────────────────────────────────────────
    QTEMemorySnapshot? memBefore;
    if (step.snapshot?.captureMemory == true || testFile.performance.trackMemory) {
      memBefore = profiler.captureMemory(step.id);
    }

    // ── Execute interaction ───────────────────────────────────────────────
    double firstFrameMs = 0;
    double reRenderMs = 0;
    List<QTEFrameTimingRecord> frames = [];

    if (step.interaction != null) {
      final ix = step.interaction!;
      final bool shouldProfileFrames = testFile.performance.trackFrames;

      if (shouldProfileFrames) {
        // Measure frames during the interaction
        frames = await profiler.collectFramesDuring(step.id, () async {
          final result = await interactionEngine.execute(ix, step.id);
          if (!result.succeeded) interactionError = result.error;
          reRenderMs = result.elapsed.inMicroseconds / 1000.0;
        });
      } else {
        final sw2 = Stopwatch()..start();
        final result = await interactionEngine.execute(ix, step.id);
        sw2.stop();
        if (!result.succeeded) interactionError = result.error;
        reRenderMs = sw2.elapsedMicroseconds / 1000.0;
      }
    }

    // ── Pump for reactive updates ─────────────────────────────────────────
    await tester.pump();

    // ── Capture state snapshot ────────────────────────────────────────────
    Map<String, dynamic>? stateSnapshot;
    if (step.snapshot?.captureState == true) {
      stateSnapshot = store.snapshot;
    }

    // ── Run assertions ────────────────────────────────────────────────────
    final assertionOutcomes = <QTEAssertionOutcome>[];
    for (final assertion in step.assertions) {
      final outcome = await assertionEngine.evaluate(assertion, step.id);
      assertionOutcomes.add(outcome);
      if (config.verbose) {
        debugPrint('[QTE]     ${outcome.toString()}');
      }
    }

    // ── Capture memory after ──────────────────────────────────────────────
    QTEMemorySnapshot? memAfter;
    if (memBefore != null) {
      memAfter = profiler.captureMemory('${step.id}_after');
    }

    // ── Build step performance record ─────────────────────────────────────
    if (testFile.performance.trackFrames || testFile.performance.trackMemory) {
      stepPerf = QTEStepPerformance(
        stepId: step.id,
        firstFrameMs: firstFrameMs,
        reRenderMs: reRenderMs,
        frames: frames,
        memoryBefore: memBefore,
        memoryAfter: memAfter,
        frameDropCount: frames.where((f) => f.isJank).length,
      );
      profiler.recordStep(stepPerf);
    }

    stepSw.stop();

    // ── Determine step status ─────────────────────────────────────────────
    final hasError = interactionError != null ||
        assertionOutcomes.any((a) => !a.passed && a.severity == QTESeverity.error);
    final hasWarn = assertionOutcomes.any((a) => !a.passed && a.severity == QTESeverity.warning);

    final status = hasError ? QTEStepStatus.failed
        : hasWarn ? QTEStepStatus.warning
        : QTEStepStatus.passed;

    return QTEStepResult(
      stepId: step.id, label: step.label, status: status,
      assertions: assertionOutcomes,
      interactionError: interactionError,
      elapsed: stepSw.elapsed,
      stateSnapshot: stateSnapshot,
      performance: stepPerf,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience: run from raw JSON map
// ─────────────────────────────────────────────────────────────────────────────

Future<QTERunResult> qteRunJson(
  Map<String, dynamic> rawJson,
  WidgetTester tester, {
  QTERunnerConfig config = const QTERunnerConfig(),
}) async {
  print('qteRunJson: started');
  // Validate first
  print('qteRunJson: validating...');
  final validation = QTEValidator.validate(rawJson);
  if (!validation.isValid) {
    throw Exception(
      'QTE validation failed:\n${validation.errors.map((e) => "  $e").join("\n")}',
    );
  }
  print('qteRunJson: converting to QTETestFile...');
  final testFile = QTETestFile.fromJson(rawJson);
  print('qteRunJson: creating runner...');
  final runner = QTERunner(testFile, config: config);
  print('qteRunJson: calling runner.run()...');
  return runner.run(tester);
}

/// Run a JSON string
Future<QTERunResult> qteRunJsonString(
  String jsonStr,
  WidgetTester tester, {
  QTERunnerConfig config = const QTERunnerConfig(),
}) async {
  final raw = jsonDecode(jsonStr) as Map<String, dynamic>;
  return qteRunJson(raw, tester, config: config);
}
