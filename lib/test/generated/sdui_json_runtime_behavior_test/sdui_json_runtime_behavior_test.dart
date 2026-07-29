// ignore_for_file: avoid_print, depend_on_referenced_packages, unused_element, prefer_const_constructors
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/quantum.dart' as quantum_layout;
import 'package:quantum_layout/src/runtime/quantum_vm_init.dart';

// ════════════════════════════════════════════════════════════════════════════
// SDUI JSON Runtime Behavior Test Runner
//
// This suite validates three distinct layers:
//
//   1. Blueprint shape
//      The compiled output must match the stored `expected` snapshot exactly.
//   2. Runtime assertions
//      `runtimeAssertions` check specific fields on the compiled blueprint.
//   3. Runtime execution
//      `executionSteps` drive a real WidgetTester against a mounted
//      QuantumVMRoot, so the tests can tap, drag, scroll, enter text, and
//      verify live store mutations.
//
// This file is intentionally strict. The loader rejects malformed JSON test
// cases, and the execution engine rejects unknown step types or malformed
// finder specs. That keeps the suite real: if a test says it is doing runtime
// execution, it must actually use the Flutter test harness.
//
// JSON test case shape:
//
//   {
//     "__meta": { "id": "...", "title": "...", ... },
//     "input": <SDUI node>,
//     "env": {},                       // optional
//     "macros": {},                    // optional
//     "expected": <blueprint shape>,   // required unless expectError
//     "expectError": { "type": "...", "messageContains": "..." },
//     "runtimeAssertions": [
//       { "path": "props.width", "equals": "fill" },
//       { "path": "children.length", "equals": 3 }
//     ],
//     "runtimeBehavior": {
//       "gesture": "tap",
//       "description": "Human-readable execution note"
//     },
//     "executionSteps": [
//       { "action": "pumpAndSettle" },
//       { "action": "tap", "finder": { "type": "text", "match": "Save" } },
//       { "action": "expectState", "path": "count", "equals": 1 },
//       { "action": "expectGeometry", "finder": { "type": "text", "match": "Save" },
//         "rect": { "left": 16, "top": 24, "tolerance": 2 } }
//     ]
//   }
//
// ════════════════════════════════════════════════════════════════════════════

class _SduiRuntimeCase {
  final File file;
  final Map<String, dynamic> meta;
  final dynamic input;
  final Map<String, dynamic> env;
  final Map<String, dynamic> macros;
  final Map<String, dynamic>? expected;
  final Map<String, dynamic>? expectError;
  final List<Map<String, dynamic>> runtimeAssertions;
  final Map<String, dynamic>? runtimeBehavior;
  final List<Map<String, dynamic>> executionSteps;

  _SduiRuntimeCase({
    required this.file,
    required this.meta,
    required this.input,
    required this.env,
    required this.macros,
    required this.expected,
    required this.expectError,
    required this.runtimeAssertions,
    required this.runtimeBehavior,
    required this.executionSteps,
  });

  String get id => meta['id']?.toString() ?? file.uri.pathSegments.last;
  String get title => meta['title']?.toString() ?? id;
  String get priority => meta['priority']?.toString() ?? 'normal';
  List<String> get tags =>
      (meta['tags'] as List?)?.map((t) => t.toString()).toList() ?? const [];
}

Map<String, dynamic> _asMap(Object? value, {required String context}) {
  if (value == null) return <String, dynamic>{};
  if (value is! Map) {
    throw FormatException('Expected an object for $context');
  }
  return Map<String, dynamic>.from(value);
}

List<Map<String, dynamic>> _asMapList(Object? value,
    {required String context}) {
  if (value == null) return <Map<String, dynamic>>[];
  if (value is! List) {
    throw FormatException('Expected a list for $context');
  }
  final out = <Map<String, dynamic>>[];
  for (final item in value) {
    if (item is! Map) {
      throw FormatException('Expected every item in $context to be an object');
    }
    out.add(Map<String, dynamic>.from(item));
  }
  return out;
}

dynamic _normalizeValue(Object? value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k.toString(), _normalizeValue(v)));
  }
  if (value is List) {
    return value.map(_normalizeValue).toList(growable: false);
  }
  return value;
}

String _canonicalStatePath(String path) {
  try {
    return quantum_layout.QLRuntimeSupport.canonicalPath(path);
  } catch (_) {
    return path;
  }
}

Finder _finderOrFirstVisible(Finder finder) {
  return _firstVisibleOrFirst(finder);
}

void _expectRectField(
  Rect actual,
  String field,
  num expected,
  double tolerance,
) {
  final value = switch (field) {
    'left' => actual.left,
    'top' => actual.top,
    'right' => actual.right,
    'bottom' => actual.bottom,
    'width' => actual.width,
    'height' => actual.height,
    _ => throw FormatException('Unsupported rect field "$field"'),
  };
  expect((value - expected.toDouble()).abs() <= tolerance, isTrue,
      reason: 'Expected $field ≈ $expected but was $value');
}

void _expectOffsetField(
  Offset actual,
  String field,
  num expected,
  double tolerance,
) {
  final value = switch (field) {
    'dx' => actual.dx,
    'dy' => actual.dy,
    _ => throw FormatException('Unsupported offset field "$field"'),
  };
  expect((value - expected.toDouble()).abs() <= tolerance, isTrue,
      reason: 'Expected $field ≈ $expected but was $value');
}

void _assertGeometry(
  WidgetTester tester,
  Finder finder,
  Map<String, dynamic> spec,
) {
  final tolerance = (spec['tolerance'] as num?)?.toDouble() ?? 1.0;
  final rect = tester.getRect(finder);
  final size = rect.size;
  final topLeft = rect.topLeft;
  final bottomRight = rect.bottomRight;
  final center = rect.center;

  final rectSpec = spec['rect'];
  if (rectSpec is Map) {
    for (final entry in rectSpec.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is num) _expectRectField(rect, key, value, tolerance);
    }
  }

  final sizeSpec = spec['size'];
  if (sizeSpec is Map) {
    if (sizeSpec['width'] is num) {
      expect(
          (size.width - (sizeSpec['width'] as num).toDouble()).abs() <=
              tolerance,
          isTrue,
          reason:
              'Expected width ≈ ${sizeSpec['width']} but was ${size.width}');
    }
    if (sizeSpec['height'] is num) {
      expect(
          (size.height - (sizeSpec['height'] as num).toDouble()).abs() <=
              tolerance,
          isTrue,
          reason:
              'Expected height ≈ ${sizeSpec['height']} but was ${size.height}');
    }
  }

  final topLeftSpec = spec['topLeft'];
  if (topLeftSpec is Map) {
    for (final entry in topLeftSpec.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is num) _expectOffsetField(topLeft, key, value, tolerance);
    }
  }

  final bottomRightSpec = spec['bottomRight'];
  if (bottomRightSpec is Map) {
    for (final entry in bottomRightSpec.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is num) _expectOffsetField(bottomRight, key, value, tolerance);
    }
  }

  final centerSpec = spec['center'];
  if (centerSpec is Map) {
    for (final entry in centerSpec.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      if (value is num) _expectOffsetField(center, key, value, tolerance);
    }
  }
}

void _assertRelativeOrder(
  WidgetTester tester, {
  required Finder first,
  required Finder second,
  String axis = 'horizontal',
  String order = 'before',
  double? minGap,
  double tolerance = 1.0,
}) {
  final a = tester.getRect(first);
  final b = tester.getRect(second);
  if (axis == 'vertical') {
    if (order == 'before') {
      expect(a.top <= b.top + tolerance, isTrue,
          reason: 'Expected first widget to be above second widget');
    } else {
      expect(a.top >= b.top - tolerance, isTrue,
          reason: 'Expected first widget to be below second widget');
    }
    if (minGap != null) {
      final gap = order == 'before' ? b.top - a.bottom : a.top - b.bottom;
      expect(gap + tolerance >= minGap, isTrue,
          reason: 'Expected vertical gap >= $minGap but was $gap');
    }
  } else {
    if (order == 'before') {
      expect(a.left <= b.left + tolerance, isTrue,
          reason: 'Expected first widget to be left of second widget');
    } else {
      expect(a.left >= b.left - tolerance, isTrue,
          reason: 'Expected first widget to be right of second widget');
    }
    if (minGap != null) {
      final gap = order == 'before' ? b.left - a.right : a.left - b.right;
      expect(gap + tolerance >= minGap, isTrue,
          reason: 'Expected horizontal gap >= $minGap but was $gap');
    }
  }
}

Iterable<File> _discoverCases(Directory directory) {
  if (!directory.existsSync()) return const <File>[];
  final files = <File>[];
  for (final entity
      in directory.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.toLowerCase().endsWith('.json')) continue;
    files.add(entity);
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

void _validateExecutionStep(Map<String, dynamic> step, String context) {
  final action = step['action']?.toString();
  if (action == null || action.isEmpty) {
    throw FormatException('Missing action in $context');
  }

  const knownActions = <String>{
    'group',
    'repeat',
    'pump',
    'pumpAndSettle',
    'wait',
    'tap',
    'doubleTap',
    'longPress',
    'tapAt',
    'drag',
    'fling',
    'scrollUntilVisible',
    'enterText',
    'replaceText',
    'submitText',
    'expectText',
    'expectNothing',
    'expectWidgetCount',
    'expectGeometry',
    'expectOrder',
    'expectState',
    'expectStateContains',
    'expectStateType',
    'expectStateOneOf',
    'expectStateLength',
  };

  if (!knownActions.contains(action)) {
    throw FormatException('Unsupported execution action "$action" in $context');
  }

  if (action == 'group' || action == 'repeat') {
    _asMapList(step['steps'], context: '$context.steps');
    if (action == 'repeat') {
      final times = step['times'];
      if (times is! int || times <= 0) {
        throw FormatException(
            'repeat steps require a positive integer times in $context');
      }
    }
    return;
  }

  if (action == 'pump' || action == 'tapAt') return;

  if (action == 'pumpAndSettle' || action == 'wait' || action == 'submitText')
    return;

  if (action == 'expectText') {
    final text = step['text']?.toString();
    if (text == null || text.isEmpty) {
      throw FormatException(
          'expectText requires a non-empty text value in $context');
    }
    return;
  }

  if (action == 'expectNothing') {
    if (step['finder'] == null && step['text'] == null) {
      throw FormatException(
          'expectNothing requires finder or text in $context');
    }
    return;
  }

  if (action == 'expectState') {
    final path = step['path']?.toString();
    if (path == null || path.isEmpty) {
      throw FormatException(
          'expectState requires a non-empty path in $context');
    }
    return;
  }

  if (action == 'expectStateContains' ||
      action == 'expectStateType' ||
      action == 'expectStateOneOf' ||
      action == 'expectStateLength') {
    final path = step['path']?.toString();
    if (path == null || path.isEmpty) {
      throw FormatException('$action requires a non-empty path in $context');
    }
    return;
  }

  if (action == 'scrollUntilVisible') {
    if (step['finder'] is! Map && step['target'] is! Map) {
      throw FormatException(
          '$action requires a finder or target object in $context');
    }
    return;
  }

  if (action == 'expectGeometry') {
    if (step['finder'] is! Map) {
      throw FormatException(
          'expectGeometry requires a finder object in $context');
    }
    return;
  }

  if (action == 'expectOrder') {
    if (step['first'] is! Map || step['second'] is! Map) {
      throw FormatException(
          'expectOrder requires first and second finder objects in $context');
    }
    return;
  }

  // The remaining interaction steps require a finder.
  if (step['finder'] is! Map) {
    throw FormatException('$action requires a finder object in $context');
  }
}

_SduiRuntimeCase _loadCase(File file) {
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw FormatException(
        'Each runtime behavior case must be an object: ${file.path}');
  }

  final root = Map<String, dynamic>.from(decoded);
  final meta = _asMap(root['__meta'], context: '${file.path}.__meta');
  final input = _normalizeValue(root['input']);
  final env = _asMap(root['env'], context: '${file.path}.env');
  final macros = _asMap(root['macros'], context: '${file.path}.macros');
  final expected = root['expected'] is Map
      ? Map<String, dynamic>.from(root['expected'] as Map)
      : null;
  final expectError = root['expectError'] is Map
      ? Map<String, dynamic>.from(root['expectError'] as Map)
      : null;

  final runtimeAssertions = _asMapList(root['runtimeAssertions'],
      context: '${file.path}.runtimeAssertions');

  final runtimeBehavior = root['runtimeBehavior'] is Map
      ? Map<String, dynamic>.from(root['runtimeBehavior'] as Map)
      : null;

  final executionSteps = _asMapList(root['executionSteps'],
      context: '${file.path}.executionSteps');
  for (var i = 0; i < executionSteps.length; i++) {
    _validateExecutionStep(
        executionSteps[i], '${file.path}.executionSteps[$i]');
  }

  if (meta.isEmpty) {
    throw FormatException(
        'Missing __meta in runtime behavior case: ${file.path}');
  }
  if (!root.containsKey('input')) {
    throw FormatException(
        'Missing input in runtime behavior case: ${file.path}');
  }
  if (expected == null && expectError == null) {
    throw FormatException(
      'Each runtime behavior case must include expected or expectError: ${file.path}',
    );
  }

  return _SduiRuntimeCase(
    file: file,
    meta: meta,
    input: input,
    env: env,
    macros: macros,
    expected: expected,
    expectError: expectError,
    runtimeAssertions: runtimeAssertions,
    runtimeBehavior: runtimeBehavior,
    executionSteps: executionSteps,
  );
}

String _joinPath(String path, Object key) {
  if (path == 'root') return 'root.$key';
  return '$path.$key';
}

String? _diffJson(dynamic actual, dynamic expected, [String path = 'root']) {
  if (expected is Map && actual is Map) {
    final expectedKeys = expected.keys
        .map((k) => k.toString())
        .where((k) => k != 'debugPath')
        .toSet();
    final actualKeys = actual.keys
        .map((k) => k.toString())
        .where((k) => k != 'debugPath')
        .toSet();

    final missing = expectedKeys.difference(actualKeys);
    if (missing.isNotEmpty) {
      final sorted = missing.toList()..sort();
      return '$path is missing keys: $sorted';
    }

    final extra = actualKeys.difference(expectedKeys);
    if (extra.isNotEmpty) {
      final sorted = extra.toList()..sort();
      return '$path has unexpected keys: $sorted';
    }

    for (final key in expected.keys) {
      if (key.toString() == 'debugPath') continue;
      final next = _diffJson(actual[key], expected[key], _joinPath(path, key));
      if (next != null) return next;
    }
    return null;
  }

  if (expected is List && actual is List) {
    if (actual.length != expected.length) {
      return '$path length mismatch: expected ${expected.length}, found ${actual.length}';
    }
    for (var i = 0; i < expected.length; i++) {
      final next = _diffJson(actual[i], expected[i], '$path[$i]');
      if (next != null) return next;
    }
    return null;
  }

  if (actual != expected) {
    return '$path mismatch: expected ${jsonEncode(expected)}, found ${jsonEncode(actual)}';
  }

  return null;
}

bool _isSyntheticStoreProviderNode(dynamic node) {
  if (node is! Map) return false;
  final type = node['type']?.toString();
  final props = node['props'];
  if (type != 'system' || props is! Map) return false;
  return props['__subType']?.toString() == 'store_provider';
}

dynamic _normalizeBlueprintTree(dynamic node) {
  if (node is List) {
    return node.map(_normalizeBlueprintTree).toList(growable: false);
  }
  if (node is! Map) return node;

  final map = Map<String, dynamic>.from(node);

  if (_isSyntheticStoreProviderNode(map)) {
    final children = map['children'];
    if (children is List && children.isNotEmpty) {
      return _normalizeBlueprintTree(children.first);
    }
  }

  final normalized = <String, dynamic>{};
  for (final entry in map.entries) {
    if (entry.key == 'debugPath') continue;
    if (entry.key == 'children') {
      normalized[entry.key] = _normalizeBlueprintTree(entry.value);
    } else if (entry.key == 'slots') {
      final slots = entry.value;
      if (slots is Map) {
        normalized[entry.key] = slots.map(
          (k, v) => MapEntry(k.toString(), _normalizeBlueprintTree(v)),
        );
      } else {
        normalized[entry.key] = _normalizeBlueprintTree(slots);
      }
    } else {
      normalized[entry.key] = _normalizeBlueprintTree(entry.value);
    }
  }
  return normalized;
}


Map<String, dynamic>? _findNodeByTypeOrSurface(dynamic node, String target) {
  if (node is! Map) return null;

  final type = node['type']?.toString();
  if (type == target || type == 'portal:$target' || type == 'portal' &&
      (node['props'] is Map &&
       ((node['props'] as Map)['surfaceKind']?.toString() == target ||
        (node['props'] as Map)['__subType']?.toString() == target))) {
    return Map<String, dynamic>.from(node);
  }

  final props = node['props'];
  if (props is Map) {
    final surfaceKind = props['surfaceKind']?.toString();
    if (surfaceKind == target) return Map<String, dynamic>.from(node);
  }

  for (final entry in node.entries) {
    final value = entry.value;
    if (value is Map) {
      final found = _findNodeByTypeOrSurface(value, target);
      if (found != null) return found;
    } else if (value is List) {
      for (final item in value) {
        final found = _findNodeByTypeOrSurface(item, target);
        if (found != null) return found;
      }
    }
  }
  return null;
}

Map<String, dynamic>? _findNodeBySubType(dynamic node, String subType) {
  if (node is! Map) return null;

  final props = node['props'];
  if (props is Map && props['__subType']?.toString() == subType) {
    return Map<String, dynamic>.from(node);
  }

  for (final entry in node.entries) {
    final value = entry.value;
    if (value is Map) {
      final found = _findNodeBySubType(value, subType);
      if (found != null) return found;
    } else if (value is List) {
      for (final item in value) {
        final found = _findNodeBySubType(item, subType);
        if (found != null) return found;
      }
    }
  }
  return null;
}

Map<String, dynamic> _selectRuntimeAssertionTarget(
    Map<String, dynamic> actual, List<Map<String, dynamic>> assertions) {
  String? targetSubtype;
  String? targetType;
  for (final assertion in assertions) {
    if (assertion['path']?.toString() == 'props.__subType' &&
        assertion.containsKey('equals')) {
      targetSubtype = assertion['equals']?.toString();
    }
    if (assertion['path']?.toString() == 'type' &&
        assertion.containsKey('equals')) {
      targetType = assertion['equals']?.toString();
    }
  }

  if (targetSubtype != null && targetSubtype.isNotEmpty) {
    final found = _findNodeBySubType(actual, targetSubtype) ??
        _findNodeByTypeOrSurface(actual, targetSubtype);
    if (found != null) return found;
  }

  if (targetType != null && targetType.isNotEmpty && targetType != 'system') {
    final found = _findNodeByTypeOrSurface(actual, targetType);
    if (found != null) return found;
  }

  return actual is Map<String, dynamic> ? actual : Map<String, dynamic>.from(actual as Map);
}

final Object _pathMissing = Object();

dynamic _resolvePath(dynamic node, String path) {
  if (path.isEmpty) return node;
  final segments = <String>[];
  final pattern = RegExp(r'\[(\d+)\]|([^.\[]+)');
  for (final m in pattern.allMatches(path)) {
    if (m.group(1) != null) {
      segments.add('[${m.group(1)}]');
    } else if (m.group(2) != null) {
      segments.add(m.group(2)!);
    }
  }

  dynamic current = node;
  for (final seg in segments) {
    if (current == null) return _pathMissing;
    if (seg.startsWith('[')) {
      final idx = int.tryParse(seg.substring(1, seg.length - 1));
      if (idx == null || current is! List || idx >= current.length) {
        return _pathMissing;
      }
      current = current[idx];
    } else if (seg == 'length') {
      if (current is List) {
        current = current.length;
      } else if (current is Map) {
        current = current.length;
      } else if (current is String) {
        current = current.length;
      } else {
        return _pathMissing;
      }
    } else {
      if (current is! Map) return _pathMissing;
      if (!current.containsKey(seg)) return _pathMissing;
      current = current[seg];
    }
  }
  return current;
}

String? _evalAssertion(
    Map<String, dynamic> assertion, Map<String, dynamic> actual) {
  final path = assertion['path']?.toString() ?? '';
  final value = _resolvePath(actual, path);

  if (assertion.containsKey('notNull')) {
    if (assertion['notNull'] == true) {
      if (value == _pathMissing || value == null) {
        return 'runtimeAssertion[$path] expected non-null, got: ${value == _pathMissing ? "<missing>" : "null"}';
      }
      return null;
    }
  }

  if (value == _pathMissing) {
    return 'runtimeAssertion[$path] path not found in actual output';
  }

  if (assertion.containsKey('equals')) {
    final exp = assertion['equals'];
    if (value != exp) {
      return 'runtimeAssertion[$path] equals: expected ${jsonEncode(exp)}, got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('greaterThan')) {
    final threshold = (assertion['greaterThan'] as num).toDouble();
    if (value is! num || value.toDouble() <= threshold) {
      return 'runtimeAssertion[$path] greaterThan $threshold: got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('lessThan')) {
    final threshold = (assertion['lessThan'] as num).toDouble();
    if (value is! num || value.toDouble() >= threshold) {
      return 'runtimeAssertion[$path] lessThan $threshold: got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('oneOf')) {
    final options = (assertion['oneOf'] as List).toList();
    if (!options.contains(value)) {
      return 'runtimeAssertion[$path] oneOf ${jsonEncode(options)}: got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('startsWith')) {
    final prefix = assertion['startsWith'].toString();
    if (value is! String || !value.startsWith(prefix)) {
      return 'runtimeAssertion[$path] startsWith "$prefix": got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('contains')) {
    final needle = assertion['contains'].toString();
    if (value is! String || !value.contains(needle)) {
      return 'runtimeAssertion[$path] contains "$needle": got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('matches')) {
    final pattern = RegExp(assertion['matches'].toString());
    if (value is! String || !pattern.hasMatch(value)) {
      return 'runtimeAssertion[$path] matches /${pattern.pattern}/: got ${jsonEncode(value)}';
    }
  }

  if (assertion.containsKey('length')) {
    final expectedLen = assertion['length'] as int;
    int? actualLen;
    if (value is List) actualLen = value.length;
    if (value is Map) actualLen = value.length;
    if (value is String) actualLen = value.length;
    if (actualLen != expectedLen) {
      return 'runtimeAssertion[$path].length: expected $expectedLen, got $actualLen';
    }
  }

  return null;
}

String _formatError(Object error) => '${error.runtimeType}: $error';

void _printRuntimeBehavior(String testId, Map<String, dynamic> rb) {
  print('\n┌── RUNTIME BEHAVIOR [$testId] ──');
  rb.forEach((k, v) => print('│  $k: ${jsonEncode(v)}'));
  print('└─────────────────────────────────');
}

void _printAssertionResults(String testId,
    List<Map<String, dynamic>> assertions, Map<String, dynamic> actual) {
  if (assertions.isEmpty) return;
  print('\n┌── RUNTIME ASSERTIONS [$testId] ──');
  for (final a in assertions) {
    final path = a['path']?.toString() ?? '';
    final resolved = _resolvePath(actual, path);
    final resolvedStr =
        resolved == _pathMissing ? '<missing>' : jsonEncode(resolved);
    print('│  ✓ $path = $resolvedStr');
  }
  print('└──────────────────────────────────');
}

List<QLDataStore> _resolveLiveStores(WidgetTester tester) {
  final root = WidgetsBinding.instance.renderViewElement;
  if (root == null)
    return <QLDataStore>[quantum_layout.QLStoreRegistry.instance.defaultStore];

  final stores = <QLDataStore>[];

  void visit(Element element) {
    final widget = element.widget;
    if (widget is QLDataScope) {
      final scoped = widget.localStore ?? widget.moduleStore;
      if (scoped != null &&
          !stores.any((existing) => identical(existing, scoped))) {
        stores.add(scoped);
      }
    }
    element.visitChildElements(visit);
  }

  visit(root);

  final globalStore = quantum_layout.QLStoreRegistry.instance.defaultStore;
  if (!stores.any((s) => identical(s, globalStore))) {
    stores.add(globalStore);
  }
  final vmStore = quantum_layout.QuantumVM.instance.store;
  if (!stores.any((s) => identical(s, vmStore))) {
    stores.add(vmStore);
  }

  return stores.reversed.toList(growable: false);
}

dynamic _readPathFromStores(List<QLDataStore> stores, String path) {
  final normalizedPath = _canonicalStatePath(path);
  for (final store in stores) {
    final value = store.get(normalizedPath);
    if (value != null) return value;
  }
  for (final store in stores) {
    if (store.has(normalizedPath)) return null;
  }
  return null;
}

Finder _finderFromSpec(Map<String, dynamic> spec) {
  final kind = spec['type']?.toString() ?? 'text';
  final match = spec['match']?.toString() ?? '';
  final Finder base;

  switch (kind) {
    case 'text':
      if (spec['contains'] == true) {
        base = find.textContaining(match, skipOffstage: false);
      } else {
        base = find.text(match, skipOffstage: false);
      }
      break;
    case 'key':
      base = find.byKey(ValueKey(match), skipOffstage: false);
      break;
    case 'tooltip':
      base = find.byTooltip(match, skipOffstage: false);
      break;
    case 'semantics':
      base = find.bySemanticsLabel(match, skipOffstage: false);
      break;
    case 'type':
      final contains = spec['contains'] == true;
      base = find.byWidgetPredicate((widget) {
        final typeName = widget.runtimeType.toString();
        return contains ? typeName.contains(match) : typeName == match;
      }, skipOffstage: false);
      break;
    case 'predicate':
      base = find.byWidgetPredicate((widget) {
        final typeName = widget.runtimeType.toString();
        final text = widget.toStringShort();
        final needle =
            match.isEmpty ? spec['containsText']?.toString() ?? '' : match;
        if (needle.isEmpty) return true;
        return typeName.contains(needle) || text.contains(needle);
      }, skipOffstage: false);
      break;
    default:
      throw FormatException('Unsupported finder type "$kind"');
  }

  Finder resolved = base;
  if (spec['descendantOf'] is Map) {
    resolved = find.descendant(
      of: _finderFromSpec(
          Map<String, dynamic>.from(spec['descendantOf'] as Map)),
      matching: resolved,
    );
  }
  if (spec['ancestorOf'] is Map) {
    resolved = find.ancestor(
      of: _finderFromSpec(Map<String, dynamic>.from(spec['ancestorOf'] as Map)),
      matching: resolved,
    );
  }
  if (spec['index'] is int) {
    resolved = resolved.at(spec['index'] as int);
  }
  return resolved;
}

Offset _offsetFromSpec(Object? raw, {Offset fallback = Offset.zero}) {
  if (raw == null) return fallback;
  if (raw is Map) {
    final dx = (raw['dx'] ?? raw['x'] ?? 0).toDouble();
    final dy = (raw['dy'] ?? raw['y'] ?? 0).toDouble();
    return Offset(dx, dy);
  }
  if (raw is List && raw.length >= 2) {
    return Offset(
      (raw[0] as num).toDouble(),
      (raw[1] as num).toDouble(),
    );
  }
  throw FormatException('Expected offset to be an object or list');
}

Finder _finderOrFail(Object? raw, String context) {
  if (raw is! Map) {
    throw FormatException('Expected a finder object in $context');
  }
  return _finderFromSpec(Map<String, dynamic>.from(raw));
}

Finder _firstMatchingFinder(List<Finder> candidates) {
  for (final finder in candidates) {
    if (finder.evaluate().isNotEmpty) return finder;
  }
  return candidates.last;
}

Finder _resolveInputFinder(Object? raw, String context) {
  if (raw is Map) {
    final spec = Map<String, dynamic>.from(raw);
    final kind = spec['type']?.toString() ?? 'text';
    if (kind == 'type') {
      final match = spec['match']?.toString() ?? '';
      final contains = spec['contains'] == true;
      if (match == 'EditableText' ||
          match == 'TextField' ||
          match == 'TextFormField') {
        final candidates = <Finder>[
          if (match != 'EditableText')
            find.byType(EditableText, skipOffstage: false),
          if (match != 'TextField') find.byType(TextField, skipOffstage: false),
          if (match != 'TextFormField')
            find.byType(TextFormField, skipOffstage: false),
          _finderFromSpec(spec),
        ];
        return _firstMatchingFinder(candidates);
      }
      if (contains && (match == 'Text' || match == 'EditableText')) {
        return _firstMatchingFinder(<Finder>[
          find.byType(EditableText, skipOffstage: false),
          find.byType(TextField, skipOffstage: false),
          find.byType(TextFormField, skipOffstage: false),
          _finderFromSpec(spec),
        ]);
      }
    }
    return _finderFromSpec(spec);
  }
  throw FormatException('Expected a finder object in $context');
}

Finder _firstVisibleOrFirst(Finder finder) {
  final hit = finder.hitTestable();
  final hitCount = hit.evaluate().length;
  if (hitCount == 1) return hit;
  if (hitCount > 1) return hit.at(0);

  final count = finder.evaluate().length;
  if (count <= 1) return finder;
  return finder.at(0);
}

Finder _interactiveAncestorFinder(Finder descendant) {
  final candidates = <Finder>[
    find.ancestor(
      of: descendant,
      matching: find.byWidgetPredicate((widget) {
        final name = widget.runtimeType.toString();
        return name.contains('Button') ||
            name.contains('GestureDetector') ||
            name.contains('RawGestureDetector') ||
            name.contains('InkWell') ||
            name.contains('InkResponse') ||
            name.contains('FocusableActionDetector') ||
            name.contains('MouseRegion');
      }, skipOffstage: false),
    ),
    find.ancestor(
      of: descendant,
      matching: find.byWidgetPredicate((widget) {
        final name = widget.runtimeType.toString();
        return name.contains('Button') ||
            name.contains('Gesture') ||
            name.contains('Ink') ||
            name.contains('Clickable');
      }, skipOffstage: false),
    ),
  ];

  for (final candidate in candidates) {
    if (candidate.evaluate().isNotEmpty) {
      return _firstVisibleOrFirst(candidate);
    }
  }
  return descendant;
}

Finder _scrollableAncestorFinder(Finder descendant) {
  final candidates = <Finder>[
    find.ancestor(
      of: descendant,
      matching: find.byWidgetPredicate((widget) {
        final name = widget.runtimeType.toString();
        return name.contains('Scroll') ||
            name.contains('Viewport') ||
            name.contains('ListView') ||
            name.contains('SingleChildScrollView') ||
            name.contains('CustomScrollView');
      }, skipOffstage: false),
    ),
    find.ancestor(
      of: descendant,
      matching: find.byType(Scrollable, skipOffstage: false),
    ),
  ];
  for (final candidate in candidates) {
    if (candidate.evaluate().isNotEmpty) {
      return _firstVisibleOrFirst(candidate);
    }
  }
  return descendant;
}

Finder _resolveScrollableFinder(Object? raw, String context, {Finder? target}) {
  final fallbacks = <Finder>[
    if (target != null) _scrollableAncestorFinder(target),
    if (raw is Map) _finderFromSpec(Map<String, dynamic>.from(raw)),
    find.byType(SingleChildScrollView, skipOffstage: false),
    find.byType(Scrollable, skipOffstage: false),
    find.byType(ListView, skipOffstage: false),
    find.byType(CustomScrollView, skipOffstage: false),
    find.byWidgetPredicate((widget) {
      final name = widget.runtimeType.toString();
      return name.contains('Scroll') ||
          name.contains('Viewport') ||
          name.contains('ListView') ||
          name.contains('SingleChildScrollView') ||
          name.contains('CustomScrollView');
    }),
  ];

  for (final finder in fallbacks) {
    final count = finder.evaluate().length;
    if (count == 1) return finder;
    if (count > 1) return finder.at(0);
  }
  throw FormatException('Unable to locate a scrollable widget in $context');
}

Finder _resolveExecutionFinder(Object? raw, String context) {
  if (raw is! Map) {
    throw FormatException('Expected a finder object in $context');
  }
  final spec = Map<String, dynamic>.from(raw);
  final kind = spec['type']?.toString() ?? 'text';

  Finder base;
  if (kind == 'type') {
    final match = spec['match']?.toString() ?? '';
    if (match == 'TextField' ||
        match == 'EditableText' ||
        match == 'TextFormField') {
      base = _firstMatchingFinder(<Finder>[
        find.byType(EditableText, skipOffstage: false),
        find.byType(TextField, skipOffstage: false),
        find.byType(TextFormField, skipOffstage: false),
        _finderFromSpec(spec),
      ]);
    } else if (match == 'Scrollable' ||
        match == 'SingleChildScrollView' ||
        match == 'ListView' ||
        match == 'CustomScrollView') {
      base = _firstMatchingFinder(<Finder>[
        find.byType(SingleChildScrollView, skipOffstage: false),
        find.byType(Scrollable, skipOffstage: false),
        find.byType(ListView, skipOffstage: false),
        find.byType(CustomScrollView, skipOffstage: false),
        _finderFromSpec(spec),
      ]);
    } else {
      base = _finderFromSpec(spec);
    }
  } else {
    base = _finderFromSpec(spec);
  }

  return _firstVisibleOrFirst(base);
}

Finder _resolveTapTarget(Object? raw, String context) {
  final base = _resolveExecutionFinder(raw, context);
  if (raw is! Map) return base;
  final spec = Map<String, dynamic>.from(raw);
  final kind = spec['type']?.toString() ?? 'text';
  if (kind == 'text') {
    final interactive = _interactiveAncestorFinder(base);
    return _firstVisibleOrFirst(interactive);
  }
  return base;
}

Future<void> _executeSteps(
  WidgetTester tester,
  List<Map<String, dynamic>> steps, {
  required String path,
}) async {
  for (var i = 0; i < steps.length; i++) {
    final step = steps[i];
    final context = '$path[$i]';
    final action = step['action']?.toString();

    switch (action) {
      case 'group':
        await _executeSteps(
          tester,
          _asMapList(step['steps'], context: '$context.steps'),
          path: '$context.steps',
        );
        break;

      case 'repeat':
        final times = step['times'] as int;
        final nested = _asMapList(step['steps'], context: '$context.steps');
        for (var n = 0; n < times; n++) {
          await _executeSteps(
            tester,
            nested,
            path: '$context.steps.repeat[$n]',
          );
        }
        break;

      case 'pump':
        final ms = step['durationMs'] as int? ?? 0;
        await tester.pump(Duration(milliseconds: ms));
        break;

      case 'pumpAndSettle':
        await tester.pumpAndSettle();
        break;

      case 'wait':
        final ms = step['ms'] as int? ?? step['durationMs'] as int? ?? 0;
        await tester.pump(Duration(milliseconds: ms));
        break;

      case 'tap':
        await tester.tap(_resolveTapTarget(step['finder'], context));
        await tester.pump();
        break;

      case 'doubleTap':
        final finder = _resolveTapTarget(step['finder'], context);
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(finder);
        await tester.pump();
        break;

      case 'tapAt':
        final offset = _offsetFromSpec(
          step['offset'] ?? step['point'] ?? step['position'],
          fallback: Offset(
            (step['x'] ?? step['dx'] ?? 0).toDouble(),
            (step['y'] ?? step['dy'] ?? 0).toDouble(),
          ),
        );
        await tester.tapAt(offset);
        await tester.pump();
        break;

      case 'longPress':
        await tester.longPress(_resolveTapTarget(step['finder'], context));
        await tester.pump();
        break;

      case 'drag':
        await tester.drag(
          _resolveExecutionFinder(step['finder'], context),
          _offsetFromSpec(step['offset'] ?? step['delta'],
              fallback: Offset(
                (step['dx'] ?? 0).toDouble(),
                (step['dy'] ?? 0).toDouble(),
              )),
        );
        await tester.pump();
        break;

      case 'fling':
        await tester.fling(
          _resolveExecutionFinder(step['finder'], context),
          _offsetFromSpec(step['offset'] ?? step['delta'],
              fallback: Offset(
                (step['dx'] ?? 0).toDouble(),
                (step['dy'] ?? 0).toDouble(),
              )),
          (step['velocity'] as num?)?.toDouble() ?? 1000.0,
        );
        await tester.pump();
        break;

      case 'scrollUntilVisible':
        final target =
            _resolveExecutionFinder(step['target'] ?? step['finder'], context);
        final targetElements = target.evaluate().toList(growable: false);
        if (targetElements.isNotEmpty) {
          try {
            await Scrollable.ensureVisible(
              targetElements.first,
              alignment: 0.1,
              duration:
                  Duration(milliseconds: (step['durationMs'] as int?) ?? 150),
              curve: Curves.easeOut,
            );
            await tester.pumpAndSettle();
            break;
          } catch (_) {
            // Fall through to the test-harness scroll helper below.
          }
        }

        final scrollable = _resolveScrollableFinder(step['scrollable'], context,
            target: target);

        // scrollUntilVisible expects a double delta, not an Offset
        final rawDelta = step['delta'] ?? step['dy'] ?? step['dx'];
        final delta = (rawDelta as num?)?.toDouble() ?? 50.0;

        final maxScrolls = step['maxScrolls'] as int? ?? 50;
        await tester.scrollUntilVisible(
          target,
          delta,
          scrollable: scrollable,
          maxScrolls: maxScrolls,
        );
        await tester.pump();
        break;

      case 'enterText':
        await tester.enterText(
          _resolveInputFinder(step['finder'], context),
          step['text'].toString(),
        );
        await tester.pump();
        break;

      case 'replaceText':
        await tester.enterText(
          _resolveInputFinder(step['finder'], context),
          step['text'].toString(),
        );
        await tester.pump();
        break;

      case 'submitText':
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();
        break;

      case 'expectText':
        final text = step['text'].toString();
        final finder = step['contains'] == true
            ? find.textContaining(text)
            : find.text(text);
        final count = step['count'] as int?;
        final finds = step['findsNothing'] == true
            ? findsNothing
            : (count != null
                ? findsNWidgets(count)
                : (step['findsAtLeast'] is int
                    ? findsAtLeast(step['findsAtLeast'] as int)
                    : findsOneWidget));
        expect(finder, finds);
        break;

      case 'expectNothing':
        if (step['text'] != null) {
          final text = step['text'].toString();
          expect(
              step['contains'] == true
                  ? find.textContaining(text)
                  : find.text(text),
              findsNothing);
        } else {
          expect(
              _resolveExecutionFinder(step['finder'], context), findsNothing);
        }
        break;

      case 'expectWidgetCount':
        final finder = _resolveExecutionFinder(step['finder'], context);
        final equals = step['equals'] as int?;
        final atLeast = step['atLeast'] as int?;
        final atMost = step['atMost'] as int?;
        if (equals != null) {
          expect(finder, findsNWidgets(equals));
        } else if (atLeast != null) {
          expect(finder, findsAtLeast(atLeast));
        } else if (atMost != null) {
          expect(tester.widgetList(finder).length, lessThanOrEqualTo(atMost));
        } else {
          expect(finder, findsOneWidget);
        }
        break;

      case 'expectGeometry':
        _assertGeometry(
          tester,
          _resolveExecutionFinder(step['finder'], context),
          Map<String, dynamic>.from(step),
        );
        break;

      case 'expectOrder':
        _assertRelativeOrder(
          tester,
          first: _resolveExecutionFinder(step['first'], context),
          second: _resolveExecutionFinder(step['second'], context),
          axis: step['axis']?.toString() ?? 'horizontal',
          order: step['order']?.toString() ?? 'before',
          minGap: (step['minGap'] as num?)?.toDouble(),
          tolerance: (step['tolerance'] as num?)?.toDouble() ?? 1.0,
        );
        break;

      case 'expectState':
        final path = step['path'].toString();
        final actualValue =
            _readPathFromStores(_resolveLiveStores(tester), path);
        expect(actualValue, step['equals'],
            reason: 'State path $path mismatch');
        break;

      case 'expectStateContains':
        final path = step['path'].toString();
        final actualValue =
            _readPathFromStores(_resolveLiveStores(tester), path);
        final needle = step['contains'];
        if (actualValue is String) {
          expect(actualValue.contains(needle.toString()), isTrue,
              reason: 'State path $path did not contain ${jsonEncode(needle)}');
        } else if (actualValue is Iterable) {
          expect(actualValue.contains(needle), isTrue,
              reason: 'State path $path did not contain ${jsonEncode(needle)}');
        } else if (actualValue is Map) {
          expect(
              actualValue.values.contains(needle) ||
                  actualValue.keys.contains(needle),
              isTrue,
              reason: 'State path $path did not contain ${jsonEncode(needle)}');
        } else {
          fail('State path $path is not a collection or string');
        }
        break;

      case 'expectStateType':
        final path = step['path'].toString();
        final actualValue =
            _readPathFromStores(_resolveLiveStores(tester), path);
        expect(actualValue.runtimeType.toString(), step['equals']?.toString());
        break;

      case 'expectStateOneOf':
        final path = step['path'].toString();
        final actualValue =
            _readPathFromStores(_resolveLiveStores(tester), path);
        final options = (step['oneOf'] as List).toList();
        expect(options.contains(actualValue), isTrue,
            reason: 'State path $path did not match any allowed value');
        break;

      case 'expectStateLength':
        final path = step['path'].toString();
        final actualValue =
            _readPathFromStores(_resolveLiveStores(tester), path);
        final expectedLength = step['equals'] as int? ?? step['length'] as int?;
        int? actualLength;
        if (actualValue is List) actualLength = actualValue.length;
        if (actualValue is Map) actualLength = actualValue.length;
        if (actualValue is String) actualLength = actualValue.length;
        expect(actualLength, expectedLength,
            reason: 'State path $path length mismatch');
        break;

      default:
        throw FormatException(
            'Unsupported execution action "$action" at $context');
    }
  }
}

void main() {
  setUpAll(() {
    quantum_layout.QLStoreRegistry.instance.defaultStore
        .set('_test_mode', true);
    initQuantumBuiltIns(quantum_layout.QuantumVM.instance);
  });
  final candidates = <Directory>[
    Directory('test/generated/sdui_json_runtime_behavior_test/cases'),
    Directory('lib/test/generated/sdui_json_runtime_behavior_test/cases'),
  ];
  final casesRoot = candidates.firstWhere(
    (directory) => directory.existsSync(),
    orElse: () => candidates.first,
  );

  final cases =
      _discoverCases(casesRoot).map(_loadCase).toList(growable: false);

  test('discovers the SDUI runtime behavior catalog', () {
    expect(cases, isNotEmpty,
        reason: 'No test cases found in $casesRoot — check folder path.');
    final ids = cases.map((c) => c.id).toList();
    final uniqueIds = ids.toSet();
    expect(uniqueIds.length, ids.length,
        reason:
            'Duplicate IDs found: ${ids.where((id) => ids.where((i) => i == id).length > 1).toSet()}');
    print('\n╔══ SDUI RUNTIME BEHAVIOR CATALOG ══');
    print('║  Total test cases : ${cases.length}');
    print(
        '║  Categories       : ${cases.expand((c) => c.tags).toSet().length}');
    print(
        '║  With assertions   : ${cases.where((c) => c.runtimeAssertions.isNotEmpty).length}');
    print(
        '║  With behavior     : ${cases.where((c) => c.runtimeBehavior != null).length}');
    print(
        '║  With execution    : ${cases.where((c) => c.executionSteps.isNotEmpty).length}');
    print('╚════════════════════════════════════');
  });

  for (final testCase in cases) {
    testWidgets(
      '${testCase.file.path.split(Platform.pathSeparator).last} — ${testCase.title}',
      (WidgetTester tester) async {
        quantum_layout.QuantumVM.instance.clearRuntimeCaches(
          compiler: true,
          style: true,
          schema: true,
          state: true,
        );

        final macros = Map<String, dynamic>.from(testCase.macros);
        final env = Map<String, dynamic>.from(testCase.env);

        if (testCase.runtimeBehavior != null) {
          // _printRuntimeBehavior(testCase.id, testCase.runtimeBehavior!);
        }

        Object? actualJson;
        quantum_layout.QLBlueprint? compiledBlueprint;
        Object? thrown;
        try {
          compiledBlueprint =
              quantum_layout.QLCompiler.compile(testCase.input, macros, env);
          actualJson = compiledBlueprint.toJson();
          // _printActualResult(testCase.id, Map<String, dynamic>.from(actualJson as Map));
        } catch (error, stackTrace) {
          thrown = error;
          if (testCase.expectError == null) {
            fail('Unexpected compile failure for ${testCase.file.path}:\n'
                '${_formatError(error)}\n$stackTrace');
          }
        }

        if (testCase.expectError != null) {
          expect(thrown, isNotNull,
              reason:
                  'Expected ${testCase.expectError} for ${testCase.file.path}');
          final expectedType = testCase.expectError!['type']?.toString();
          final expectedMessageContains =
              testCase.expectError!['messageContains']?.toString();
          if (expectedType != null) {
            expect(
              thrown!.runtimeType.toString(),
              expectedType,
              reason: 'Wrong exception type for ${testCase.file.path}',
            );
          }
          if (expectedMessageContains != null) {
            expect(
              _formatError(thrown!).contains(expectedMessageContains),
              isTrue,
              reason: 'Wrong exception message for ${testCase.file.path}',
            );
          }
          return;
        }

        expect(thrown, isNull,
            reason: 'Did not expect an exception for ${testCase.file.path}');

        final actualMap = Map<String, dynamic>.from(actualJson as Map);
        final normalizedActual = _normalizeBlueprintTree(actualMap);
        final normalizedExpected = testCase.expected == null
            ? null
            : _normalizeBlueprintTree(testCase.expected);

        if (testCase.expected != null) {
          final diff = _diffJson(normalizedActual, normalizedExpected);
          expect(
            diff,
            isNull,
            reason: diff ??
                'Blueprint did not match expected snapshot for ${testCase.file.path}\n'
                    'ACTUAL: ${jsonEncode(normalizedActual)}',
          );
        }

        if (testCase.runtimeAssertions.isNotEmpty) {
          final assertionTarget =
              _selectRuntimeAssertionTarget(actualMap, testCase.runtimeAssertions);
          final errors = <String>[];
          for (final assertion in testCase.runtimeAssertions) {
            final err = _evalAssertion(assertion, assertionTarget);
            if (err != null) errors.add(err);
          }
          // _printAssertionResults(
          //     testCase.id, testCase.runtimeAssertions, assertionTarget);
          expect(
            errors,
            isEmpty,
            reason: 'Runtime assertion failures for ${testCase.file.path}:\n'
                '${errors.join('\n')}\n'
                'ACTUAL: ${jsonEncode(assertionTarget)}',
          );
        }

        if (testCase.executionSteps.isNotEmpty && compiledBlueprint != null) {
          final inputProps = testCase.input['props'] as Map?;
          final num? testWidth = inputProps?['width'] as num?;
          final num? testHeight = inputProps?['height'] as num?;

          Widget testApp = quantum_layout.QLOverlayRoot(
            child: quantum_layout.QuantumVMRoot(
              child: Builder(
                builder: (ctx) => quantum_layout.QuantumVM.instance
                    .renderWidget(ctx, compiledBlueprint!),
              ),
            ),
          );

          if (testWidth != null || testHeight != null) {
            testApp = Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: testWidth?.toDouble(),
                height: testHeight?.toDouble(),
                child: testApp,
              ),
            );
          }

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: testApp,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await _executeSteps(
            tester,
            testCase.executionSteps,
            path: testCase.id,
          );
        }
      },
    );
  }
}
