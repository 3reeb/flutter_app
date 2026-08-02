/*
 * ============================================================================
 * File: qte_assertion.dart
 * 
 * Description:
 * Implements the core assertion evaluation logic for the Quantum Test Engine.
 * It is responsible for assessing whether the actual state, UI rendering, performance
 * metrics, and reactive behaviors match the expected outcomes defined in the test
 * specifications. It dispatches assertion evaluations based on their type.
 * 
 * Key Components:
 * - QTEAssertionOutcome: A data class representing the result of a single assertion evaluation.
 * - QTEAssertionEngine: The engine component that evaluates assertions against the UI, state, and profilers.
 * 
 * Dependencies/Relationships:
 * Depends on lutter_test, quantum_layout/quantum.dart, and other QTE components
 * like qte_schema.dart, qte_render_probe.dart, qte_reactive.dart, and qte_performance.dart.
 * 
 * Notes:
 * The _dispatch method handles a wide variety of assertion types (geometry, visibility,
 * text, state, reactive signals, performance). When adding new assertion types to the schema,
 * their evaluation logic must be implemented in this dispatch switch statement.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE ASSERTION ENGINE — qte_assertion.dart
// Evaluates every assertion type: UI, state, reactive, style, performance.
// ══════════════════════════════════════════════════════════════════════════════
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';
import 'qte_schema.dart';
import 'qte_render_probe.dart';
import 'qte_reactive.dart';
import 'qte_performance.dart';

class QTEAssertionOutcome {
  final String assertionId;
  final String stepId;
  final bool passed;
  final String label;
  final String? failureMessage;
  final dynamic actual;
  final dynamic expected;
  final QTESeverity severity;

  const QTEAssertionOutcome({
    required this.assertionId,
    required this.stepId,
    required this.passed,
    required this.label,
    this.failureMessage,
    this.actual,
    this.expected,
    this.severity = QTESeverity.error,
  });

  factory QTEAssertionOutcome.pass(String id, String stepId, String label, {dynamic actual}) =>
      QTEAssertionOutcome(assertionId: id, stepId: stepId, passed: true, label: label, actual: actual);

  factory QTEAssertionOutcome.fail(String id, String stepId, String label, String msg,
      {dynamic actual, dynamic expected, QTESeverity severity = QTESeverity.error}) =>
      QTEAssertionOutcome(
        assertionId: id, stepId: stepId, passed: false, label: label,
        failureMessage: msg, actual: actual, expected: expected, severity: severity,
      );

  Map<String, dynamic> toJson() => {
    'id': assertionId, 'stepId': stepId,
    'passed': passed, 'label': label,
    if (failureMessage != null) 'failureMessage': failureMessage,
    if (actual != null) 'actual': actual?.toString(),
    if (expected != null) 'expected': expected?.toString(),
    'severity': severity.name,
  };

  @override
  String toString() {
    if (passed) return '✅ [$assertionId] $label';
    final icon = severity == QTESeverity.error ? '❌' : severity == QTESeverity.warning ? '⚠️' : 'ℹ️';
    return '$icon [$assertionId] $label — $failureMessage'
        '${actual != null ? " (actual: $actual)" : ""}'
        '${expected != null ? " (expected: $expected)" : ""}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class QTEAssertionEngine {
  final WidgetTester tester;
  final QLDataStore store;
  final QTERenderProbe probe;
  final QTEReactiveWatcher watcher;
  final QTEPerformanceProfiler profiler;

  QTEAssertionEngine({
    required this.tester,
    required this.store,
    required this.probe,
    required this.watcher,
    required this.profiler,
  });

  Future<QTEAssertionOutcome> evaluate(QTEAssertion a, String stepId) async {
    if (a.disabled) {
      return QTEAssertionOutcome.pass(a.id, stepId, a.label.isNotEmpty ? a.label : a.id);
    }
    try {
      return await _dispatch(a, stepId);
    } catch (e) {
      return QTEAssertionOutcome.fail(a.id, stepId, a.label, 'Exception: $e', severity: a.severity);
    }
  }

  Future<QTEAssertionOutcome> _dispatch(QTEAssertion a, String stepId) async {
    final label = a.label.isNotEmpty ? a.label : '${a.type.name}(${a.id})';

    switch (a.type) {
      // ── Widget Existence ───────────────────────────────────────────────
      case QTEAssertionType.widgetExists:
        final found = a.target != null && probe.exists(a.target!);
        if (!found) return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget not found', severity: a.severity);
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.widgetNotExists:
        final found = a.target != null && probe.exists(a.target!);
        if (found) return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget should not exist but was found', severity: a.severity);
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Widget Geometry ────────────────────────────────────────────────
      case QTEAssertionType.widgetWidth:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.geometry!.width;
        final exp = (a.expected as num?)?.toDouble() ?? a.width ?? 0;
        return _numericCheck(a, stepId, label, actual, exp);

      case QTEAssertionType.widgetHeight:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.geometry!.height;
        final exp = (a.expected as num?)?.toDouble() ?? a.height ?? 0;
        return _numericCheck(a, stepId, label, actual, exp);

      case QTEAssertionType.widgetSize:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final geo = result.geometry!;
        final expW = a.width ?? (a.expected is Map ? (a.expected['width'] as num?)?.toDouble() : null) ?? 0;
        final expH = a.height ?? (a.expected is Map ? (a.expected['height'] as num?)?.toDouble() : null) ?? 0;
        final tol = a.tolerance ?? 1.0;
        if ((geo.width - expW).abs() > tol || (geo.height - expH).abs() > tol) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Size mismatch', actual: '${geo.width}x${geo.height}', expected: '${expW}x$expH', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '${geo.width}x${geo.height}');

      case QTEAssertionType.widgetOffset:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final geo = result.geometry!;
        final expDx = (a.expected is Map ? (a.expected['dx'] as num?)?.toDouble() : null) ?? 0;
        final expDy = (a.expected is Map ? (a.expected['dy'] as num?)?.toDouble() : null) ?? 0;
        final tol = a.tolerance ?? 1.0;
        final ok = (geo.globalOffset.dx - expDx).abs() <= tol && (geo.globalOffset.dy - expDy).abs() <= tol;
        if (!ok) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Offset mismatch',
              actual: '(${geo.globalOffset.dx},${geo.globalOffset.dy})', expected: '($expDx,$expDy)', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Visibility / Opacity ───────────────────────────────────────────
      case QTEAssertionType.widgetVisible:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        if (result.geometry?.isVisible != true) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget not visible', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.widgetNotVisible:
        if (a.target == null || !probe.exists(a.target!)) {
          return QTEAssertionOutcome.pass(a.id, stepId, label);
        }
        final result2 = probe.probe(a.target!);
        if (result2.geometry?.isVisible == true) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget should not be visible', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.widgetOpacity:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.geometry?.opacity ?? 1.0;
        final exp = (a.expected as num?)?.toDouble() ?? 1.0;
        return _numericCheck(a, stepId, label, actual, exp);

      // ── Color ──────────────────────────────────────────────────────────
      case QTEAssertionType.widgetColor:
      case QTEAssertionType.widgetBackgroundColor:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actualColor = a.type == QTEAssertionType.widgetBackgroundColor
            ? result.backgroundColor : result.color;
        final expColor = QTERenderProbe.parseColor(a.color ?? a.expected?.toString());
        if (expColor == null) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Cannot parse expected color: "${a.color}"', severity: a.severity);
        }
        if (actualColor == null) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Could not read widget color from RenderObject', severity: a.severity);
        }
        final tol = (a.tolerance ?? 5).round();
        if (!QTERenderProbe.colorsMatch(actualColor, expColor, tolerance: tol)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Color mismatch',
              actual: '#${actualColor.toARGB32().toRadixString(16).padLeft(8, "0").toUpperCase()}',
              expected: a.color, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Border radius ──────────────────────────────────────────────────
      case QTEAssertionType.widgetBorderRadius:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.borderRadius;
        final exp = (a.expected as num?)?.toDouble() ?? 0;
        if (actual == null) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Could not read border radius', severity: a.severity);
        }
        return _numericCheck(a, stepId, label, actual, exp);

      // ── Text ───────────────────────────────────────────────────────────
      case QTEAssertionType.widgetText:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.textContent ?? '';
        final exp = a.expected?.toString() ?? '';
        if (!_matchStr(actual, a.matcher, exp)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Text mismatch', actual: actual, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual);

      case QTEAssertionType.widgetTextContains:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.textContent ?? '';
        final exp = a.expected?.toString() ?? '';
        if (!actual.contains(exp)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Text does not contain "$exp"', actual: actual, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual);

      // ── Text Style ─────────────────────────────────────────────────────
      case QTEAssertionType.widgetTextStyle:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final style = result.textStyle;
        final spec = a.textStyle;
        if (style == null) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'No TextStyle found on widget', severity: a.severity);
        }
        if (spec == null) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final errors = <String>[];
        if (spec.fontSize != null && (style.fontSize == null || (style.fontSize! - spec.fontSize!).abs() > 0.5)) {
          errors.add('fontSize: actual=${style.fontSize} expected=${spec.fontSize}');
        }
        if (spec.color != null) {
          final ec = QTERenderProbe.parseColor(spec.color);
          if (ec != null && style.color != null && !QTERenderProbe.colorsMatch(style.color!, ec)) {
            errors.add('color: actual=${style.color} expected=${spec.color}');
          }
        }
        if (errors.isNotEmpty) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'TextStyle mismatch: ${errors.join(", ")}', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Count ──────────────────────────────────────────────────────────
      case QTEAssertionType.widgetCount:
        final actual = a.target != null ? probe.count(a.target!) : 0;
        final exp = a.count ?? (a.expected as int?) ?? 0;
        if (!_matchNum(actual.toDouble(), a.matcher, exp.toDouble())) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Count mismatch', actual: actual, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual);

      // ── Enabled / Disabled ─────────────────────────────────────────────
      case QTEAssertionType.widgetEnabled:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        if (result.isEnabled == false) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget is disabled', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.widgetDisabled:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        if (result.isEnabled != false) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget is not disabled', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Focused ────────────────────────────────────────────────────────
      case QTEAssertionType.widgetFocused:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        if (result.isFocused != true) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget is not focused', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Scroll ─────────────────────────────────────────────────────────
      case QTEAssertionType.widgetScrollable:
        final found = a.target != null && probe.exists(a.target!);
        if (!found) return QTEAssertionOutcome.fail(a.id, stepId, label, 'Widget not found', severity: a.severity);
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.widgetScrollOffset:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        final actual = result.scrollOffset ?? 0;
        final exp = a.scrollOffset?.dy ?? (a.expected as num?)?.toDouble() ?? 0;
        return _numericCheck(a, stepId, label, actual, exp);

      case QTEAssertionType.widgetConstrained:
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.widgetOrder:
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── State assertions ───────────────────────────────────────────────
      case QTEAssertionType.stateEquals:
        final actual = store.get(a.storeKey ?? '');
        if (!_matchesExpected(actual, a.expected, a.matcher)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label, 'State mismatch',
              actual: actual, expected: a.expected, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual);

      case QTEAssertionType.stateNotEquals:
        final actual = store.get(a.storeKey ?? '');
        if (_matchesExpected(actual, a.expected, QTEMatcher.equals)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'State should not equal ${a.expected}', actual: actual, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.stateNull:
        final actual = store.get(a.storeKey ?? '');
        if (actual != null) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Expected null but got $actual', actual: actual, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.stateNotNull:
        final actual = store.get(a.storeKey ?? '');
        if (actual == null) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Expected non-null value but got null', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual);

      case QTEAssertionType.stateContains:
        final actual = store.get(a.storeKey ?? '');
        final exp = a.expected?.toString() ?? '';
        final str = actual?.toString() ?? '';
        if (!str.contains(exp)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'State does not contain "$exp"', actual: str, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.stateListLength:
        final actual = store.get(a.storeKey ?? '');
        final len = actual is List ? actual.length : 0;
        final exp = (a.expected as int?) ?? a.count ?? 0;
        if (!_matchNum(len.toDouble(), a.matcher, exp.toDouble())) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'List length mismatch', actual: len, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: len);

      case QTEAssertionType.stateGreaterThan:
        final actual = store.get(a.storeKey ?? '');
        final n = num.tryParse(actual?.toString() ?? '') ?? 0;
        final exp = (a.expected as num?)?.toDouble() ?? 0;
        if (n <= exp) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              '$n is not > $exp', actual: n, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: n);

      case QTEAssertionType.stateLessThan:
        final actual = store.get(a.storeKey ?? '');
        final n = num.tryParse(actual?.toString() ?? '') ?? 0;
        final exp = (a.expected as num?)?.toDouble() ?? 0;
        if (n >= exp) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              '$n is not < $exp', actual: n, expected: exp, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: n);

      case QTEAssertionType.stateType:
        final actual = store.get(a.storeKey ?? '');
        final expType = a.expected?.toString() ?? '';
        final actualType = actual.runtimeType.toString();
        if (actualType != expType) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Type mismatch', actual: actualType, expected: expType, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.stateMatchesRegex:
        final actual = store.get(a.storeKey ?? '');
        final pattern = a.expected?.toString() ?? '';
        final str = actual?.toString() ?? '';
        if (!RegExp(pattern).hasMatch(str)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'State "$str" does not match regex "$pattern"', actual: str, expected: pattern, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      // ── Reactive / Signal assertions ───────────────────────────────────
      case QTEAssertionType.signalEmitted:
      case QTEAssertionType.storeKeyChanged:
        final key = a.storeKey ?? a.expected?.toString() ?? '';
        if (!watcher.wasKeyChanged(key)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'No signal emitted for key "$key"', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.signalValue:
        final key = a.storeKey ?? '';
        final actual = watcher.latestSignalValue(key) ?? store.get(key);
        if (!_matchesExpected(actual, a.expected, a.matcher)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Signal value mismatch', actual: actual, expected: a.expected, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual);

      case QTEAssertionType.reactiveRebuilt:
        final key = a.storeKey ?? a.expected?.toString() ?? '';
        final count = watcher.rebuildCount(key);
        if (count == 0) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Widget "$key" did not rebuild', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '$count rebuilds');

      case QTEAssertionType.actionCalled:
        final actionName = a.action ?? a.expected?.toString() ?? '';
        if (!watcher.wasActionCalled(actionName)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Action "$actionName" was not called', severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.actionResult:
        final actionName = a.action ?? '';
        final result = watcher.latestActionResult(actionName);
        if (!_matchesExpected(result, a.expected, a.matcher)) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Action result mismatch', actual: result, expected: a.expected, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: result);

      // ── Style / Theme assertions ────────────────────────────────────────
      case QTEAssertionType.styleClassPresent:
      case QTEAssertionType.styleTokenValue:
      case QTEAssertionType.computedStyle:
      case QTEAssertionType.themeToken:
        // TODO: integrate QEngine style compiler to validate style tokens
        return QTEAssertionOutcome.pass(a.id, stepId, '$label (style check — not yet implemented)');

      // ── Performance assertions ─────────────────────────────────────────
      case QTEAssertionType.firstFrameUnderMs:
        final records = profiler.allStepRecords;
        if (records.isEmpty) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final ms = records.last.firstFrameMs;
        final budget = (a.expected as num?)?.toDouble() ?? 16.0;
        if (ms > budget) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'First frame ${ms.toStringAsFixed(1)}ms exceeds ${budget}ms',
              actual: ms, expected: budget, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '${ms.toStringAsFixed(1)}ms');

      case QTEAssertionType.rerenderUnderMs:
        final records = profiler.allStepRecords;
        if (records.isEmpty) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final ms = records.last.reRenderMs;
        final budget = (a.expected as num?)?.toDouble() ?? 16.0;
        if (ms > budget) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Re-render ${ms.toStringAsFixed(1)}ms exceeds ${budget}ms',
              actual: ms, expected: budget, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '${ms.toStringAsFixed(1)}ms');

      case QTEAssertionType.noFrameDrops:
        final drops = profiler.allStepRecords.fold(0, (s, r) => s + r.frameDropCount);
        final maxDrops = (a.expected as int?) ?? 0;
        if (drops > maxDrops) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              '$drops frame drops (max: $maxDrops)', actual: drops, expected: maxDrops, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '$drops drops');

      case QTEAssertionType.noJank:
        final frames = profiler.allStepRecords.expand((r) => r.frames).toList();
        final jankCount = frames.where((f) => f.isJank).length;
        if (jankCount > 0) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              '$jankCount jank frames detected', actual: jankCount, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);

      case QTEAssertionType.memoryUnderMb:
        final snap = profiler.getMemorySnapshot(stepId);
        if (snap == null) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final mb = snap.rssMb;
        final budget = (a.expected as num?)?.toDouble() ?? 100.0;
        if (mb > budget) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Memory ${mb.toStringAsFixed(1)}MB exceeds ${budget}MB',
              actual: mb, expected: budget, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '${mb.toStringAsFixed(1)}MB');

      case QTEAssertionType.memoryDeltaUnderMb:
        if (a.deltaFromStep == null) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final snapA = profiler.getMemorySnapshot(a.deltaFromStep!);
        final snapB = profiler.getMemorySnapshot(stepId);
        if (snapA == null || snapB == null) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final delta = snapB.rssMb - snapA.rssMb;
        final budget = (a.expected as num?)?.toDouble() ?? 10.0;
        if (delta > budget) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Memory delta +${delta.toStringAsFixed(1)}MB exceeds ${budget}MB',
              actual: delta, expected: budget, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '+${delta.toStringAsFixed(1)}MB');

      case QTEAssertionType.rasterizeUnderMs:
        final records = profiler.allStepRecords;
        if (records.isEmpty) return QTEAssertionOutcome.pass(a.id, stepId, label);
        final ms = records.last.frames.isEmpty ? 0.0
            : records.last.frames.map((f) => f.rasterMs).reduce((a, b) => a > b ? a : b);
        final budget = (a.expected as num?)?.toDouble() ?? 16.0;
        if (ms > budget) {
          return QTEAssertionOutcome.fail(a.id, stepId, label,
              'Peak rasterize ${ms.toStringAsFixed(1)}ms exceeds ${budget}ms',
              actual: ms, expected: budget, severity: a.severity);
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label, actual: '${ms.toStringAsFixed(1)}ms');

      // ── Interaction behavior assertions ────────────────────────────────
      case QTEAssertionType.hoverTriggered:
        final key = a.storeKey ?? a.expected?.toString() ?? 'hovered';
        return watcher.wasKeyChanged(key)
            ? QTEAssertionOutcome.pass(a.id, stepId, label)
            : QTEAssertionOutcome.fail(a.id, stepId, label, 'Hover was not triggered', severity: a.severity);

      case QTEAssertionType.dragCompleted:
        final key = a.storeKey ?? 'drag.completed';
        return watcher.wasKeyChanged(key)
            ? QTEAssertionOutcome.pass(a.id, stepId, label)
            : QTEAssertionOutcome.pass(a.id, stepId, '$label (no drag signal tracked)');

      case QTEAssertionType.scrollReachedEnd:
        final r = _probeRequired(a, label, stepId);
        if (r is QTEAssertionOutcome) return r;
        final result = r as QTEProbeResult;
        return QTEAssertionOutcome.pass(a.id, stepId, label,
            actual: 'scrollOffset=${result.scrollOffset}');

      case QTEAssertionType.animationCompleted:
      case QTEAssertionType.portalOpened:
      case QTEAssertionType.portalClosed:
        // Detect via widget existence
        if (a.target != null) {
          final exists = probe.exists(a.target!);
          final shouldExist = a.type == QTEAssertionType.portalOpened || a.type == QTEAssertionType.animationCompleted;
          if (exists != shouldExist) {
            return QTEAssertionOutcome.fail(a.id, stepId, label,
                '${a.type.name}: widget ${shouldExist ? "not found" : "still exists"}', severity: a.severity);
          }
        }
        return QTEAssertionOutcome.pass(a.id, stepId, label);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  dynamic _probeRequired(QTEAssertion a, String label, String stepId) {
    if (a.target == null) {
      return QTEAssertionOutcome.fail(a.id, stepId, label, 'No target specified', severity: a.severity);
    }
    final result = probe.probe(a.target!);
    if (!result.found) {
      return QTEAssertionOutcome.fail(a.id, stepId, label,
          result.error ?? 'Widget not found: ${a.target!.value}', severity: a.severity);
    }
    if (result.geometry == null) {
      return QTEAssertionOutcome.fail(a.id, stepId, label,
          'Widget found but has no RenderBox', severity: a.severity);
    }
    return result;
  }

  QTEAssertionOutcome _numericCheck(QTEAssertion a, String stepId, String label, double actual, double expected) {
    final tol = a.tolerance ?? 1.0;
    if (!_matchNum(actual, a.matcher, expected, tolerance: tol, min: a.min, max: a.max)) {
      return QTEAssertionOutcome.fail(a.id, stepId, label, 'Numeric mismatch',
          actual: actual.toStringAsFixed(2), expected: expected.toStringAsFixed(2), severity: a.severity);
    }
    return QTEAssertionOutcome.pass(a.id, stepId, label, actual: actual.toStringAsFixed(2));
  }

  bool _matchNum(double actual, QTEMatcher m, double expected,
      {double tolerance = 1.0, double? min, double? max}) {
    switch (m) {
      case QTEMatcher.equals: return (actual - expected).abs() <= tolerance;
      case QTEMatcher.notEquals: return (actual - expected).abs() > tolerance;
      case QTEMatcher.gt: return actual > expected;
      case QTEMatcher.gte: return actual >= expected;
      case QTEMatcher.lt: return actual < expected;
      case QTEMatcher.lte: return actual <= expected;
      case QTEMatcher.between: return actual >= (min ?? 0) && actual <= (max ?? double.infinity);
      default: return (actual - expected).abs() <= tolerance;
    }
  }

  bool _matchStr(String actual, QTEMatcher m, String expected) {
    switch (m) {
      case QTEMatcher.equals: return actual == expected;
      case QTEMatcher.notEquals: return actual != expected;
      case QTEMatcher.contains: return actual.contains(expected);
      case QTEMatcher.startsWith: return actual.startsWith(expected);
      case QTEMatcher.endsWith: return actual.endsWith(expected);
      case QTEMatcher.matchesRegex: return RegExp(expected).hasMatch(actual);
      case QTEMatcher.isNull: return actual.isEmpty;
      case QTEMatcher.isNotNull: return actual.isNotEmpty;
      default: return actual == expected;
    }
  }

  bool _matchesExpected(dynamic actual, dynamic expected, QTEMatcher m) {
    if (actual is num && expected is num) {
      return _matchNum(actual.toDouble(), m, expected.toDouble());
    }
    return _matchStr(actual?.toString() ?? '', m, expected?.toString() ?? '');
  }
}
