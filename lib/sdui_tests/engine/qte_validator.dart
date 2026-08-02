/*
 * ============================================================================
 * File: qte_validator.dart
 * 
 * Description:
 * Provides semantic and structural validation for Quantum Test Engine JSON files
 * before they are parsed into DTOs or executed. It acts as an early warning system
 * to catch missing required fields, mutually exclusive properties, and invalid enum
 * values, ensuring that only correctly formatted tests are passed to the runner.
 * 
 * Key Components:
 * - QTEValidationError: Represents a specific issue found during validation, complete with JSON path.
 * - QTEValidationResult: Aggregates all errors and warnings from a validation run.
 * - QTEValidator: Static utility containing the rules and logic to traverse and validate the raw JSON map.
 * 
 * Dependencies/Relationships:
 * Depends on qte_schema.dart (for expected enum values and constants). Used directly by
 * qte_runner.dart (specifically qteRunJson) to validate input before execution.
 * 
 * Notes:
 * The validator catches edge cases that basic JSON parsing might miss, such as ensuring
 * that an assertion type like 'widget_color' explicitly includes a 'color' field, or
 * warning if an interaction is missing a target.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE VALIDATOR — qte_validator.dart
// Strongly-typed schema validation. Catches every error before the runner runs.
// ══════════════════════════════════════════════════════════════════════════════
import 'qte_schema.dart';

class QTEValidationError {
  final String path;
  final String message;
  final dynamic actual;
  final String? expected;
  const QTEValidationError({required this.path, required this.message, this.actual, this.expected});

  @override
  String toString() {
    final exp = expected != null ? ' (expected: $expected)' : '';
    final act = actual != null ? ' (got: $actual)' : '';
    return '[$path] $message$exp$act';
  }

  Map<String, dynamic> toJson() => {
    'path': path, 'message': message,
    if (actual != null) 'actual': actual?.toString(),
    if (expected != null) 'expected': expected,
  };
}

class QTEValidationResult {
  final bool isValid;
  final List<QTEValidationError> errors;
  final List<QTEValidationError> warnings;

  const QTEValidationResult({required this.isValid, required this.errors, required this.warnings});

  factory QTEValidationResult.pass() =>
      const QTEValidationResult(isValid: true, errors: [], warnings: []);

  @override
  String toString() {
    if (isValid) return 'VALID ✅ (${warnings.length} warnings)';
    final lines = ['INVALID ❌ — ${errors.length} error(s), ${warnings.length} warning(s):'];
    for (final e in errors) {
      lines.add('  ERROR: $e');
    }
    for (final w in warnings) {
      lines.add('  WARN:  $w');
    }
    return lines.join('\n');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

abstract final class QTEValidator {
  static QTEValidationResult validate(Map<String, dynamic> rawJson) {
    final errors = <QTEValidationError>[];
    final warnings = <QTEValidationError>[];

    void err(String path, String msg, {dynamic actual, String? expected}) =>
        errors.add(QTEValidationError(path: path, message: msg, actual: actual, expected: expected));
    void warn(String path, String msg, {dynamic actual, String? expected}) =>
        warnings.add(QTEValidationError(path: path, message: msg, actual: actual, expected: expected));

    // ── Top-level required fields ──────────────────────────────────────────
    _requireString(rawJson, 'id', err);
    _requireString(rawJson, 'title', err);
    _requireField(rawJson, 'sdui', err, expectedType: 'object');
    _requireField(rawJson, 'steps', err, expectedType: 'array');

    // ── Schema version ──────────────────────────────────────────────────
    final schema = rawJson[r'$schema']?.toString() ?? '';
    if (schema.isNotEmpty && schema != QTETestFile.schemaId) {
      warn(r'$schema', 'Unknown schema version', actual: schema, expected: QTETestFile.schemaId);
    }

    // ── Viewport ──────────────────────────────────────────────────────────
    final vp = rawJson['viewport'];
    if (vp != null) {
      if (vp is! Map) {
        err('viewport', '"viewport" must be an object');
      } else {
        final vpMap = Map<String, dynamic>.from(vp);
        _requireNumber(vpMap, 'viewport.width', err, min: 1, max: 4096);
        _requireNumber(vpMap, 'viewport.height', err, min: 1, max: 4096);
        if (vpMap.containsKey('pixelRatio')) {
          final pr = vpMap['pixelRatio'];
          if (pr is! num || pr <= 0) {
            err('viewport.pixelRatio', 'Must be a positive number', actual: pr);
          }
        }
        if (vpMap.containsKey('orientation')) {
          final o = vpMap['orientation']?.toString();
          if (o != 'portrait' && o != 'landscape') {
            err('viewport.orientation', 'Must be "portrait" or "landscape"', actual: o);
          }
        }
      }
    }

    // ── sdui ────────────────────────────────────────────────────────────────
    final sdui = rawJson['sdui'];
    if (sdui is Map) {
      if (!sdui.containsKey('type')) {
        err('sdui.type', 'SDUI root node must have a "type" field');
      }
    }

    // ── Steps ────────────────────────────────────────────────────────────────
    final steps = rawJson['steps'];
    if (steps is List) {
      final stepIds = <String>{};
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final p = 'steps[$i]';
        if (step is! Map) { err(p, 'Step must be an object'); continue; }
        final s = Map<String, dynamic>.from(step);
        _requireString(s, '$p.id', err);
        _requireString(s, '$p.label', err);

        final sid = s['id']?.toString() ?? '';
        if (sid.isNotEmpty) {
          if (stepIds.contains(sid)) {
            err('$p.id', 'Duplicate step id "$sid"', actual: sid);
          }
          stepIds.add(sid);
        }

        // Validate interaction
        if (s.containsKey('interaction') && s['interaction'] != null) {
          _validateInteraction(s['interaction'], '$p.interaction', err, warn);
        }

        // Validate assertions
        final assertions = s['assertions'];
        if (assertions != null) {
          if (assertions is! List) {
            err('$p.assertions', '"assertions" must be an array');
          } else {
            final assertIds = <String>{};
            for (var j2 = 0; j2 < assertions.length; j2++) {
              _validateAssertion(assertions[j2], '$p.assertions[$j2]', err, warn, assertIds);
            }
          }
        }
      }
    }

    // ── Mocks ────────────────────────────────────────────────────────────────
    final mocks = rawJson['mocks'];
    if (mocks != null && mocks is! List) {
      err('mocks', '"mocks" must be an array');
    } else if (mocks is List) {
      for (var i = 0; i < mocks.length; i++) {
        final m = mocks[i];
        if (m is! Map) { err('mocks[$i]', 'Mock must be an object'); continue; }
        _requireString(Map<String, dynamic>.from(m), 'mocks[$i].sourceId', err);
      }
    }

    // ── Performance ──────────────────────────────────────────────────────────
    final perf = rawJson['performance'];
    if (perf is Map) {
      final pmap = Map<String, dynamic>.from(perf);
      for (final numKey in ['maxFirstFrameMs', 'maxReRenderMs', 'maxMemoryMb']) {
        if (pmap.containsKey(numKey) && pmap[numKey] is! num) {
          err('performance.$numKey', 'Must be a number', actual: pmap[numKey]);
        }
      }
    }

    return QTEValidationResult(
      isValid: errors.isEmpty,
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static void _requireString(Map<String, dynamic> j, String path,
      void Function(String, String, {dynamic actual, String? expected}) err) {
    final key = path.split('.').last;
    if (!j.containsKey(key)) {
      err(path, 'Missing required field', expected: 'string');
    } else if (j[key] is! String || (j[key] as String).isEmpty) {
      err(path, 'Must be a non-empty string', actual: j[key], expected: 'string');
    }
  }

  static void _requireField(Map<String, dynamic> j, String path,
      void Function(String, String, {dynamic actual, String? expected}) err,
      {String expectedType = 'any'}) {
    final key = path.split('.').last;
    if (!j.containsKey(key)) {
      err(path, 'Missing required field', expected: expectedType);
    }
  }

  static void _requireNumber(Map<String, dynamic> j, String path,
      void Function(String, String, {dynamic actual, String? expected}) err,
      {double? min, double? max}) {
    final key = path.split('.').last;
    final val = j[key];
    if (val == null) { err(path, 'Missing required number', expected: 'number'); return; }
    if (val is! num) { err(path, 'Must be a number', actual: val); return; }
    final d = val.toDouble();
    if (min != null && d < min) err(path, 'Must be >= $min', actual: d, expected: '>= $min');
    if (max != null && d > max) err(path, 'Must be <= $max', actual: d, expected: '<= $max');
  }

  static final Set<String> _validInteractionTypes = {
    'tap', 'double_tap', 'long_press', 'hover', 'unhover', 'drag', 'scroll',
    'type', 'clear_text', 'focus', 'blur', 'resize', 'key_press', 'right_click',
    'zoom', 'pinch', 'trigger_action', 'set_state', 'merge_state', 'toggle_state',
    'dispatch_signal', 'wait', 'navigate', 'wait_for_signal',
  };

  static final Set<String> _validAssertionTypes = {
    'widget_exists', 'widget_not_exists', 'widget_width', 'widget_height',
    'widget_size', 'widget_offset', 'widget_visible', 'widget_not_visible',
    'widget_color', 'widget_background_color', 'widget_border_radius',
    'widget_opacity', 'widget_text', 'widget_text_contains', 'widget_text_style',
    'widget_count', 'widget_order', 'widget_enabled', 'widget_disabled',
    'widget_focused', 'widget_scrollable', 'widget_scroll_offset', 'widget_constrained',
    'state_equals', 'state_not_equals', 'state_contains', 'state_type',
    'state_null', 'state_not_null', 'state_list_length', 'state_greater_than',
    'state_less_than', 'state_matches_regex', 'signal_emitted', 'signal_value',
    'reactive_rebuilt', 'store_key_changed', 'action_called', 'action_result',
    'style_class_present', 'style_token_value', 'computed_style', 'theme_token',
    'first_frame_under_ms', 'rerender_under_ms', 'no_frame_drops',
    'memory_under_mb', 'memory_delta_under_mb', 'rasterize_under_ms', 'no_jank',
    'hover_triggered', 'drag_completed', 'scroll_reached_end',
    'animation_completed', 'portal_opened', 'portal_closed',
  };

  static void _validateInteraction(dynamic raw, String path,
      void Function(String, String, {dynamic actual, String? expected}) err,
      void Function(String, String, {dynamic actual, String? expected}) warn) {
    if (raw is! Map) { err(path, 'Interaction must be an object'); return; }
    final j = Map<String, dynamic>.from(raw);
    if (!j.containsKey('type')) { err('$path.type', 'Missing "type"', expected: 'interaction type string'); return; }
    final t = j['type']?.toString() ?? '';
    if (!_validInteractionTypes.contains(t)) {
      err('$path.type', 'Unknown interaction type "$t"', actual: t,
          expected: _validInteractionTypes.join(' | '));
    }
    // Type-specific required field checks
    if (t == 'drag') {
      if (!j.containsKey('from')) warn('$path.from', 'drag interaction missing "from" offset');
      if (!j.containsKey('to')) warn('$path.to', 'drag interaction missing "to" offset');
    }
    if (t == 'type' && !j.containsKey('text')) {
      err('$path.text', '"type" interaction requires a "text" field');
    }
    if (t == 'trigger_action' && !j.containsKey('action')) {
      err('$path.action', '"trigger_action" interaction requires an "action" field');
    }
    if (t == 'wait' && !j.containsKey('ms')) {
      warn('$path.ms', '"wait" interaction has no "ms" specified, will wait 0ms');
    }
    if (t == 'navigate' && !j.containsKey('route')) {
      err('$path.route', '"navigate" interaction requires a "route" field');
    }
    if (t == 'resize') {
      if (!j.containsKey('newWidth') && !j.containsKey('newHeight')) {
        err('$path.newWidth', '"resize" needs at least "newWidth" or "newHeight"');
      }
    }
    // Target required for widget-targeting interactions
    final needsTarget = {'tap', 'double_tap', 'long_press', 'hover', 'unhover',
        'drag', 'scroll', 'type', 'clear_text', 'focus', 'blur', 'resize',
        'key_press', 'right_click', 'zoom', 'pinch'};
    if (needsTarget.contains(t) && !j.containsKey('target')) {
      warn('$path.target', '"$t" interaction has no target — will use first matching widget');
    }
    if (j.containsKey('target')) {
      _validateTarget(j['target'], '$path.target', err);
    }
  }

  static void _validateTarget(dynamic raw, String path,
      void Function(String, String, {dynamic actual, String? expected}) err) {
    if (raw is! Map) { err(path, 'Target must be an object'); return; }
    final j = Map<String, dynamic>.from(raw);
    const validBy = {'key', 'text', 'type', 'semanticLabel', 'testId', 'path'};
    if (!j.containsKey('by')) { err('$path.by', 'Missing "by"', expected: validBy.join(' | ')); return; }
    final by = j['by']?.toString() ?? '';
    if (!validBy.contains(by)) { err('$path.by', 'Unknown "by": "$by"', actual: by); }
    if (!j.containsKey('value') || j['value']?.toString().isEmpty == true) {
      err('$path.value', 'Missing or empty "value"');
    }
  }

  static void _validateAssertion(dynamic raw, String path,
      void Function(String, String, {dynamic actual, String? expected}) err,
      void Function(String, String, {dynamic actual, String? expected}) warn,
      Set<String> seenIds) {
    if (raw is! Map) { err(path, 'Assertion must be an object'); return; }
    final j = Map<String, dynamic>.from(raw);
    if (!j.containsKey('id')) { err('$path.id', 'Missing "id"'); return; }
    if (!j.containsKey('type')) { err('$path.type', 'Missing "type"'); return; }

    final aid = j['id'].toString();
    if (seenIds.contains(aid)) { err('$path.id', 'Duplicate assertion id "$aid"', actual: aid); }
    seenIds.add(aid);

    final at = j['type']?.toString() ?? '';
    if (!_validAssertionTypes.contains(at)) {
      err('$path.type', 'Unknown assertion type "$at"', actual: at);
    }

    // State assertions need storeKey
    if (at.startsWith('state_') && !j.containsKey('storeKey')) {
      err('$path.storeKey', '"$at" assertion requires "storeKey"');
    }
    // action assertions need action
    if (at == 'action_called' && !j.containsKey('action')) {
      err('$path.action', '"action_called" assertion requires "action"');
    }
    // performance assertions need expected numeric value
    final perfTypes = {'first_frame_under_ms', 'rerender_under_ms', 'memory_under_mb',
        'memory_delta_under_mb', 'rasterize_under_ms'};
    if (perfTypes.contains(at) && !j.containsKey('expected')) {
      err('$path.expected', '"$at" assertion requires "expected" numeric threshold');
    }
    // Widget color assertions need color
    if ((at == 'widget_color' || at == 'widget_background_color') && !j.containsKey('color')) {
      err('$path.color', '"$at" assertion requires "color"');
    }
    // Matcher between needs min and max
    if (j['matcher']?.toString() == 'between') {
      if (!j.containsKey('min')) err('$path.min', '"between" matcher requires "min"');
      if (!j.containsKey('max')) err('$path.max', '"between" matcher requires "max"');
    }
    if (j.containsKey('target')) {
      _validateTarget(j['target'], '$path.target', err);
    }
  }
}
