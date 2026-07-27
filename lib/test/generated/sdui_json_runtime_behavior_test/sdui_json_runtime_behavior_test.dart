// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart' as quantum_layout;

// ════════════════════════════════════════════════════════════════════════════
// SDUI JSON Runtime Behavior Test Runner
//
// What this runner validates:
//   1. Blueprint shape — compiled output exactly matches the `expected` snapshot.
//   2. Runtime assertions — per-prop value checks via `runtimeAssertions`.
//   3. Runtime behavior docs — `runtimeBehavior` annotations printed for human review.
//
// Every test prints its ACTUAL c
//ompiled result so you can see the live runtime
// output, not just a pass/fail signal.
//
// JSON test case shape:
//   {
//     "__meta": { "id": "...", "title": "...", ... },
//     "input": <SDUI node>,
//     "env": {},                       // optional
//     "macros": {},                    // optional
//     "expected": <blueprint shape>,   // required unless expectError
//     "expectError": { "type": "...", "messageContains": "..." }, // required unless expected
//     "runtimeAssertions": [           // optional — value checks on compiled output
//       { "path": "props.draggable",   "equals": true },
//       { "path": "props.handles[0]",  "equals": "n" },
//       { "path": "props.width",       "greaterThan": 0 },
//       { "path": "children.length",   "equals": 3 },
//       { "path": "props.dragAxis",    "oneOf": ["x", "y", "both"] },
//       { "path": "type",              "startsWith": "box" },
//       { "path": "props.minWidth",    "lessThan": 999 },
//       { "path": "props.angle",       "notNull": true }
//     ],
//     "runtimeBehavior": {             // optional — widget-level gesture documentation
//       "gesture":        "drag",
//       "description":    "Horizontal drag 100px returns offset dx:100 dy:0",
//       "axis":           "x",
//       "deltaX":         100,
//       "expectedOffsetX": 100,
//       "expectedOffsetY": 0,
//       "snapGrid":       16,
//       "expectedSnappedX": 96
//     }
//   }
//
// ════════════════════════════════════════════════════════════════════════════

// ─── Data classes ───────────────────────────────────────────────────────────

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

// ─── Helpers ────────────────────────────────────────────────────────────────

Map<String, dynamic> _asMap(Object? value, {required String context}) {
  if (value == null) return <String, dynamic>{};
  if (value is! Map) {
    throw FormatException('Expected an object for $context');
  }
  return Map<String, dynamic>.from(value);
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

  // runtimeAssertions — list of { path, equals|greaterThan|lessThan|oneOf|startsWith|notNull }
  final rawAssertions = root['runtimeAssertions'];
  final runtimeAssertions = rawAssertions is List
      ? rawAssertions
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList()
      : <Map<String, dynamic>>[];

  // runtimeBehavior — free-form object documenting widget-level gesture behavior
  final runtimeBehavior = root['runtimeBehavior'] is Map
      ? Map<String, dynamic>.from(root['runtimeBehavior'] as Map)
      : null;

  // executionSteps — widget execution commands
  final rawSteps = root['executionSteps'];
  final executionSteps = rawSteps is List
      ? rawSteps.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
      : <Map<String, dynamic>>[];

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

// ─── Snapshot diff ──────────────────────────────────────────────────────────

String _joinPath(String path, Object key) {
  if (path == 'root') return 'root.$key';
  return '$path.$key';
}

String? _diffJson(dynamic actual, dynamic expected, [String path = 'root']) {
  if (expected is Map && actual is Map) {
    final expectedKeys = expected.keys.map((k) => k.toString()).toSet();
    final actualKeys = actual.keys.map((k) => k.toString()).toSet();

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

// ─── Runtime assertion evaluator ────────────────────────────────────────────

/// Resolves a dot-and-bracket path like "props.handles[0]" against [actual].
/// Returns [_PathMissing] sentinel when a segment is absent.
const _pathMissing = Object();

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
      // array index
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

/// Evaluates one runtimeAssertion against the compiled [actual] JSON map.
/// Returns null on pass, or an error string on failure.
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

// ─── Formatting ─────────────────────────────────────────────────────────────

String _formatError(Object error) => '${error.runtimeType}: $error';

/// Pretty prints the actual compiled result with a visible header.
/// This is the "real runtime output" the user wants to see.
void _printActualResult(String testId, Map<String, dynamic> actual) {
  final pretty = const JsonEncoder.withIndent('  ').convert(actual);
  print('\n╔══ ACTUAL RUNTIME OUTPUT [$testId] ══');
  for (final line in pretty.split('\n')) {
    print('║ $line');
  }
  print('╚══════════════════════════════════════');
}

/// Prints runtimeBehavior annotations as documentation.
void _printRuntimeBehavior(String testId, Map<String, dynamic> rb) {
  print('\n┌── RUNTIME BEHAVIOR [$testId] ──');
  rb.forEach((k, v) => print('│  $k: ${jsonEncode(v)}'));
  print('└─────────────────────────────────');
}

/// Prints passed runtimeAssertions with their resolved values.
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

Future<void> _executeSteps(WidgetTester tester, List<Map<String, dynamic>> steps) async {
  for (final step in steps) {
    final action = step['action'];
    if (action == 'pumpAndSettle') {
      await tester.pumpAndSettle();
    } else if (action == 'pump') {
      final ms = step['durationMs'] as int? ?? 0;
      await tester.pump(Duration(milliseconds: ms));
    } else if (action == 'tap') {
      final finderDef = step['finder'] as Map?;
      if (finderDef != null && finderDef['type'] == 'text') {
        await tester.tap(find.text(finderDef['match'].toString()));
      }
    } else if (action == 'enterText') {
      final finderDef = step['finder'] as Map?;
      if (finderDef != null && finderDef['type'] == 'key') {
        await tester.enterText(find.byKey(Key(finderDef['match'].toString())), step['text'].toString());
      }
    } else if (action == 'expectText') {
      final text = step['text'].toString();
      if (step['findsOne'] == true) {
        expect(find.text(text), findsOneWidget);
      }
    } else if (action == 'expectState') {
      final path = step['path'].toString();
      final expectedValue = step['equals'];
      final actualValue = quantum_layout.QuantumVM.instance.store.get(path);
      expect(actualValue, expectedValue, reason: 'State path $path mismatch');
    }
  }
}

// ─── Test main ──────────────────────────────────────────────────────────────

void main() {
  var casesRoot =
      Directory('lib/test/generated/sdui_json_runtime_behavior_test/cases');
  if (!casesRoot.existsSync()) {
    final suiteRoot = File.fromUri(Platform.script).parent;
    casesRoot = Directory('${suiteRoot.path}${Platform.pathSeparator}cases');
  }

  final cases =
      _discoverCases(casesRoot).map(_loadCase).toList(growable: false);

  // ── Catalog discovery sanity check ──────────────────────────────────────
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
        '║  With assertions  : ${cases.where((c) => c.runtimeAssertions.isNotEmpty).length}');
    print(
        '║  With behavior    : ${cases.where((c) => c.runtimeBehavior != null).length}');
    print('╚════════════════════════════════════');
  });

  // ── Per-case tests ───────────────────────────────────────────────────────
  for (final testCase in cases) {
    testWidgets(
      '${testCase.file.path.split(Platform.pathSeparator).last} — ${testCase.title}',
      (WidgetTester tester) async {
        final macros = Map<String, dynamic>.from(testCase.macros);
        final env = Map<String, dynamic>.from(testCase.env);

        // ── Print runtime behavior annotation (documentation) ──────────────
        // if (testCase.runtimeBehavior != null) {
        //   _printRuntimeBehavior(testCase.id, testCase.runtimeBehavior!);
        // }

        // ── Compile ────────────────────────────────────────────────────────
        Object? actualJson;
        quantum_layout.QLBlueprint? compiledBlueprint;
        Object? thrown;
        try {
          compiledBlueprint =
              quantum_layout.QLCompiler.compile(testCase.input, macros, env);
          actualJson = compiledBlueprint.toJson();

          // ── Print actual runtime result — the real compiled output ────────
          // _printActualResult(
          //     testCase.id, Map<String, dynamic>.from(actualJson as Map));
        } catch (error, stackTrace) {
          thrown = error;
          if (testCase.expectError == null) {
            fail('Unexpected compile failure for ${testCase.file.path}:\n'
                '${_formatError(error)}\n$stackTrace');
          }
        }

        // ── expectError path ───────────────────────────────────────────────
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
          // print('\n║ ✓ EXPECTED ERROR: ${_formatError(thrown!)}');
          return;
        }

        // ── Success path ───────────────────────────────────────────────────
        expect(thrown, isNull,
            reason: 'Did not expect an exception for ${testCase.file.path}');

        final actualMap = Map<String, dynamic>.from(actualJson as Map);

        // ── 1. Snapshot check ───────────────────────────────────────────────
        if (testCase.expected != null) {
          final diff = _diffJson(actualMap, testCase.expected);
          expect(
            diff,
            isNull,
            reason: diff ??
                'Blueprint did not match expected snapshot for ${testCase.file.path}\n'
                    'ACTUAL: ${jsonEncode(actualMap)}',
          );
          // print('\n║ ✓ SNAPSHOT MATCH: ${testCase.id}');
        }

        // ── 2. Runtime assertions — per-prop value checks ───────────────────
        if (testCase.runtimeAssertions.isNotEmpty) {
          final errors = <String>[];
          for (final assertion in testCase.runtimeAssertions) {
            final err = _evalAssertion(assertion, actualMap);
            if (err != null) errors.add(err);
          }
          _printAssertionResults(
              testCase.id, testCase.runtimeAssertions, actualMap);
          expect(
            errors,
            isEmpty,
            reason: 'Runtime assertion failures for ${testCase.file.path}:\n'
                '${errors.join('\n')}\n'
                'ACTUAL: ${jsonEncode(actualMap)}',
          );
          // print(
          //     '║ ✓ ALL ${testCase.runtimeAssertions.length} RUNTIME ASSERTIONS PASSED');
        }

        // ── 3. Runtime execution tests (Final Render) ──────────────────────
        if (testCase.executionSteps.isNotEmpty && compiledBlueprint != null) {
          await tester.pumpWidget(
            MaterialApp(
              home: quantum_layout.QuantumVMRoot(
                child: Builder(
                  builder: (ctx) => quantum_layout.QuantumVM.instance.renderWidget(ctx, compiledBlueprint!)
                )
              )
            )
          );
          
          await _executeSteps(tester, testCase.executionSteps);
        }
      },
    );
  }
}
