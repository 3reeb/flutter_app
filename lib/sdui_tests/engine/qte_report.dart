/*
 * ============================================================================
 * File: qte_report.dart
 * 
 * Description:
 * Handles the generation, formatting, and serialization of Quantum Test Engine test results.
 * It aggregates the outcomes of individual steps and assertions into comprehensive reports,
 * supporting multiple output formats including plain text (for console), JSON (for
 * programmatic ingestion), and JUnit XML (for CI/CD pipelines).
 * 
 * Key Components:
 * - QTEStepResult: Encapsulates the results, timing, and errors of a single test step.
 * - QTERunResult: The overarching summary of an entire test suite execution.
 * - QTEReportGenerator: Utility class that builds the result objects and formats them for output.
 * 
 * Dependencies/Relationships:
 * Consumes DTOs from qte_schema.dart and outcome data from qte_assertion.dart and 
 * qte_performance.dart. Used by qte_runner.dart as the final stage of execution.
 * 
 * Notes:
 * The JUnit XML generation ensures seamless integration with standard continuous integration
 * platforms like Jenkins or GitHub Actions. Diff formatting is intentionally kept simple
 * but can be expanded for more complex object comparisons in the future.
 * ============================================================================
 */
// ??????????????????????????????????????????????????????????????????????????????
// QTE REPORT � qte_report.dart
// Structured pass/fail result with diffs, JSON export, human-readable output.
// ??????????????????????????????????????????????????????????????????????????????
import 'dart:convert';
import 'qte_schema.dart';
import 'qte_assertion.dart';
import 'qte_performance.dart';

// ?????????????????????????????????????????????????????????????????????????????
// Result DTOs
// ?????????????????????????????????????????????????????????????????????????????

enum QTEStepStatus { passed, failed, warning, skipped }

class QTEStepResult {
  final String stepId;
  final String label;
  final QTEStepStatus status;
  final List<QTEAssertionOutcome> assertions;
  final String? interactionError;
  final Duration elapsed;
  final Map<String, dynamic>? stateSnapshot;
  final QTEStepPerformance? performance;

  int get passCount => assertions.where((a) => a.passed).length;
  int get failCount => assertions
      .where((a) => !a.passed && a.severity == QTESeverity.error)
      .length;
  int get warnCount => assertions
      .where((a) => !a.passed && a.severity == QTESeverity.warning)
      .length;

  const QTEStepResult({
    required this.stepId,
    required this.label,
    required this.status,
    required this.assertions,
    this.interactionError,
    required this.elapsed,
    this.stateSnapshot,
    this.performance,
  });

  Map<String, dynamic> toJson() => {
        'stepId': stepId,
        'label': label,
        'status': status.name,
        'elapsed_ms': elapsed.inMilliseconds,
        'pass': passCount,
        'fail': failCount,
        'warn': warnCount,
        if (interactionError != null) 'interactionError': interactionError,
        'assertions': assertions.map((a) => a.toJson()).toList(),
        if (stateSnapshot != null) 'stateSnapshot': stateSnapshot,
        if (performance != null) 'performance': performance!.toJson(),
      };
}

class QTERunResult {
  final String testId;
  final String title;
  final bool passed;
  final int totalSteps;
  final int passedSteps;
  final int failedSteps;
  final int skippedSteps;
  final int totalAssertions;
  final int passedAssertions;
  final int failedAssertions;
  final int warnedAssertions;
  final List<QTEStepResult> steps;
  final Duration totalElapsed;
  final Map<String, dynamic>? performanceSummary;
  final DateTime runAt;

  bool get hasWarnings => warnedAssertions > 0;

  const QTERunResult({
    required this.testId,
    required this.title,
    required this.passed,
    required this.totalSteps,
    required this.passedSteps,
    required this.failedSteps,
    required this.skippedSteps,
    required this.totalAssertions,
    required this.passedAssertions,
    required this.failedAssertions,
    required this.warnedAssertions,
    required this.steps,
    required this.totalElapsed,
    this.performanceSummary,
    required this.runAt,
  });

  Map<String, dynamic> toJson() => {
        'testId': testId,
        'title': title,
        'passed': passed,
        'runAt': runAt.toIso8601String(),
        'elapsed_ms': totalElapsed.inMilliseconds,
        'summary': {
          'steps': {
            'total': totalSteps,
            'passed': passedSteps,
            'failed': failedSteps,
            'skipped': skippedSteps
          },
          'assertions': {
            'total': totalAssertions,
            'passed': passedAssertions,
            'failed': failedAssertions,
            'warned': warnedAssertions
          },
        },
        if (performanceSummary != null) 'performance': performanceSummary,
        'steps': steps.map((s) => s.toJson()).toList(),
      };
}

// ?????????????????????????????????????????????????????????????????????????????
// Report Generator
// ?????????????????????????????????????????????????????????????????????????????

abstract final class QTEReportGenerator {
  static QTERunResult build({
    required String testId,
    required String title,
    required List<QTEStepResult> steps,
    required Duration totalElapsed,
    Map<String, dynamic>? performanceSummary,
  }) {
    var passedSteps = 0, failedSteps = 0, skippedSteps = 0;
    var passedAssertions = 0, failedAssertions = 0, warnedAssertions = 0;

    for (final step in steps) {
      switch (step.status) {
        case QTEStepStatus.passed:
          passedSteps++;
          break;
        case QTEStepStatus.failed:
          failedSteps++;
          break;
        case QTEStepStatus.skipped:
          skippedSteps++;
          break;
        case QTEStepStatus.warning:
          passedSteps++;
          break;
      }
      passedAssertions += step.passCount;
      failedAssertions += step.failCount;
      warnedAssertions += step.warnCount;
    }

    final passed = failedSteps == 0 && failedAssertions == 0;

    return QTERunResult(
      testId: testId,
      title: title,
      passed: passed,
      totalSteps: steps.length,
      passedSteps: passedSteps,
      failedSteps: failedSteps,
      skippedSteps: skippedSteps,
      totalAssertions: passedAssertions + failedAssertions + warnedAssertions,
      passedAssertions: passedAssertions,
      failedAssertions: failedAssertions,
      warnedAssertions: warnedAssertions,
      steps: steps,
      totalElapsed: totalElapsed,
      performanceSummary: performanceSummary,
      runAt: DateTime.now(),
    );
  }

  // ?? Human-readable text report ?????????????????????????????????????????????
  static String textReport(QTERunResult result) {
    final lines = <String>[];
    final bar = '?' * 70;
    final thin = '?' * 70;

    lines.add(bar);
    lines.add('  QTE TEST REPORT');
    lines.add('  Test: ${result.title} [${result.testId}]');
    lines.add('  Run at: ${result.runAt.toIso8601String()}');
    lines.add('  Duration: ${result.totalElapsed.inMilliseconds}ms');
    lines.add('  Result: ${result.passed ? "? PASSED" : "? FAILED"}');
    lines.add(thin);
    lines.add('  Steps:      ${result.passedSteps}/${result.totalSteps} passed'
        '${result.skippedSteps > 0 ? " (${result.skippedSteps} skipped)" : ""}');
    lines.add(
        '  Assertions: ${result.passedAssertions}/${result.totalAssertions} passed'
        '${result.warnedAssertions > 0 ? " (${result.warnedAssertions} warnings)" : ""}');
    lines.add(bar);

    for (final step in result.steps) {
      final icon = step.status == QTEStepStatus.passed
          ? '?'
          : step.status == QTEStepStatus.failed
              ? '?'
              : step.status == QTEStepStatus.warning
                  ? '??'
                  : '??';
      lines.add('');
      lines.add(
          '  $icon STEP [${step.stepId}]: ${step.label} (${step.elapsed.inMilliseconds}ms)');

      if (step.interactionError != null) {
        lines.add('     ? Interaction error: ${step.interactionError}');
      }

      for (final a in step.assertions) {
        final aIcon = a.passed
            ? '  ?'
            : a.severity == QTESeverity.error
                ? '  ?'
                : '  ??';
        lines.add('$aIcon [${a.assertionId}] ${a.label}');
        if (!a.passed && a.failureMessage != null) {
          lines.add('       ? ${a.failureMessage}');
          if (a.actual != null) lines.add('         actual:   ${a.actual}');
          if (a.expected != null) lines.add('         expected: ${a.expected}');
        }
      }

      if (step.performance != null) {
        final p = step.performance!;
        lines.add('     ? firstFrame=${p.firstFrameMs.toStringAsFixed(1)}ms '
            'reRender=${p.reRenderMs.toStringAsFixed(1)}ms '
            'drops=${p.frameDropCount}');
        if (p.memoryDeltaMb != null) {
          lines
              .add('     ?? memDelta=${p.memoryDeltaMb!.toStringAsFixed(1)}MB');
        }
      }
    }

    lines.add('');
    lines.add(bar);
    if (!result.passed) {
      lines.add('  FAILURES:');
      for (final step in result.steps) {
        for (final a in step.assertions) {
          if (!a.passed && a.severity == QTESeverity.error) {
            lines.add(
                '  ? [${step.stepId}] ? [${a.assertionId}] ${a.failureMessage}');
          }
        }
        if (step.interactionError != null) {
          lines.add(
              '  ? [${step.stepId}] Interaction: ${step.interactionError}');
        }
      }
      lines.add(bar);
    }

    return lines.join('\n');
  }

  // ?? Machine-readable JSON ??????????????????????????????????????????????????
  static String jsonReport(QTERunResult result, {bool pretty = true}) {
    final encoder =
        pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(result.toJson());
  }

  // ?? JUnit XML (for CI systems) ?????????????????????????????????????????????
  static String junitXml(QTERunResult result) {
    final sb = StringBuffer();
    sb.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    sb.writeln('<testsuite name="${_escape(result.title)}" '
        'tests="${result.totalAssertions}" failures="${result.failedAssertions}" '
        'time="${(result.totalElapsed.inMilliseconds / 1000).toStringAsFixed(3)}">');
    for (final step in result.steps) {
      for (final a in step.assertions) {
        final time =
            (step.elapsed.inMilliseconds / step.assertions.length / 1000)
                .toStringAsFixed(3);
        sb.writeln(
            '  <testcase classname="${_escape(result.testId)}.${_escape(step.stepId)}" '
            'name="${_escape(a.label.isNotEmpty ? a.label : a.assertionId)}" time="$time">');
        if (!a.passed) {
          final type = a.severity == QTESeverity.error ? 'failure' : 'warning';
          sb.writeln(
              '    <$type message="${_escape(a.failureMessage ?? "Failed")}">'
              '${_escape("actual: ${a.actual}\nexpected: ${a.expected}")}</$type>');
        }
        sb.writeln('  </testcase>');
      }
    }
    sb.writeln('</testsuite>');
    return sb.toString();
  }

  static String _escape(String? s) {
    return (s ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  // ?? Diff helper ????????????????????????????????????????????????????????????
  static String diff(dynamic actual, dynamic expected) {
    final a = actual?.toString() ?? 'null';
    final e = expected?.toString() ?? 'null';
    if (a == e) return '(no diff)';
    return '- actual:   $a\n+ expected: $e';
  }
}
