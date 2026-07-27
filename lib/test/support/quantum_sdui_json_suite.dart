// Quantum SDUI JSON contract suite helper.
// This file turns JSON specs into concrete flutter_test cases.
//
// Supported assertion kinds:
// - source_contains_all
// - source_contains_any
// - source_not_contains
// - subtypes_exact
// - subtypes_contains
// - builder_contains
// - line_count_at_least
// - source_sha256_matches
// - snapshot_path_not_empty
// - json_round_trip
// - json_round_trip_strict
// - json_root_keys_contains
// - json_root_keys_exact
// - json_meta_keys_contains
// - json_meta_keys_exact
// - json_case_count_at_least
// - json_case_count_exact
// - json_case_keys_contains
// - json_case_keys_exact
// - json_case_ids_unique
// - json_case_assertions_nonempty
// - json_assertion_kinds_allowed
// - json_path_exists
// - json_path_not_empty
// - json_path_equals
// - json_path_contains_all
// - json_path_contains_any
// - json_path_keys_contains
// - json_path_keys_exact
// - json_path_length_at_least
// - json_path_length_exact
// - json_path_type_is
// - all
// - any
// - not

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart' as quantum_layout;

class QuantumSduiJsonSuite {
  final String filePath;
  final Map<String, dynamic> root;
  final List<QuantumSduiJsonGroup> groups;
  final List<QuantumSduiJsonCase> cases;
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final bool allowBlank;

  QuantumSduiJsonSuite({
    required this.filePath,
    required this.root,
    required this.groups,
    required this.cases,
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.allowBlank,
  });

  factory QuantumSduiJsonSuite.fromFile(File file) {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw FormatException('Top-level JSON must be an object: ${file.path}');
    }

    final root = Map<String, dynamic>.from(decoded);
    final meta = _jsonMap(root['__meta']) ?? _jsonMap(root['meta']) ?? const <String, dynamic>{};
    final rawGroups = root['groups'] ?? root['sections'];
    final rawCases = root['cases'] ?? root['tests'] ?? root['rows'];

    final groups = <QuantumSduiJsonGroup>[];
    if (rawGroups is List) {
      for (var index = 0; index < rawGroups.length; index++) {
        final item = rawGroups[index];
        if (item is Map) {
          groups.add(
            QuantumSduiJsonGroup.fromJson(
              Map<String, dynamic>.from(item),
              fallbackId: '${_slugFromPath(file.path)}-group-$index',
            ),
          );
        }
      }
    }

    final cases = <QuantumSduiJsonCase>[];
    if (rawCases is List) {
      for (var index = 0; index < rawCases.length; index++) {
        final item = rawCases[index];
        if (item is Map) {
          cases.add(
            QuantumSduiJsonCase.fromJson(
              Map<String, dynamic>.from(item),
              fallbackId: '${_slugFromPath(file.path)}-case-$index',
            ),
          );
        }
      }
    }

    return QuantumSduiJsonSuite(
      filePath: file.path,
      root: root,
      groups: groups,
      cases: cases,
      id: _string(meta['id'], fallback: _slugFromPath(file.path)),
      title: _string(meta['title'], fallback: _slugFromPath(file.path)),
      description: meta['description']?.toString(),
      tags: _stringList(meta['tags']),
      allowBlank: meta['allowBlank'] == true,
    );
  }
}

class QuantumSduiJsonGroup {
  final String id;
  final String title;
  final String? description;
  final List<String> tags;
  final List<QuantumSduiJsonGroup> groups;
  final List<QuantumSduiJsonCase> cases;

  QuantumSduiJsonGroup({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.groups,
    required this.cases,
  });

  factory QuantumSduiJsonGroup.fromJson(Map<String, dynamic> json, {required String fallbackId}) {
    final rawGroups = json['groups'] ?? json['sections'];
    final rawCases = json['cases'] ?? json['tests'] ?? json['rows'];

    final groups = <QuantumSduiJsonGroup>[];
    if (rawGroups is List) {
      for (var index = 0; index < rawGroups.length; index++) {
        final item = rawGroups[index];
        if (item is Map) {
          groups.add(
            QuantumSduiJsonGroup.fromJson(
              Map<String, dynamic>.from(item),
              fallbackId: '$fallbackId-group-$index',
            ),
          );
        }
      }
    }

    final cases = <QuantumSduiJsonCase>[];
    if (rawCases is List) {
      for (var index = 0; index < rawCases.length; index++) {
        final item = rawCases[index];
        if (item is Map) {
          cases.add(
            QuantumSduiJsonCase.fromJson(
              Map<String, dynamic>.from(item),
              fallbackId: '$fallbackId-case-$index',
            ),
          );
        }
      }
    }

    return QuantumSduiJsonGroup(
      id: _string(json['id'] ?? json['name'], fallback: fallbackId),
      title: _string(json['title'] ?? json['name'] ?? json['id'], fallback: fallbackId),
      description: json['description']?.toString(),
      tags: _stringList(json['tags']),
      groups: groups,
      cases: cases,
    );
  }
}

class QuantumSduiJsonCase {
  final String id;
  final String title;
  final String? description;
  final String? sourcePath;
  final String? snapshotPath;
  final String? sourceSha256;
  final int? lineCountAtLeast;
  final List<QuantumSduiJsonAssertion> assertions;

  QuantumSduiJsonCase({
    required this.id,
    required this.title,
    required this.description,
    required this.sourcePath,
    required this.snapshotPath,
    required this.sourceSha256,
    required this.lineCountAtLeast,
    required this.assertions,
  });

  factory QuantumSduiJsonCase.fromJson(Map<String, dynamic> json, {required String fallbackId}) {
    final assertionsRaw = json['assertions'];
    final assertions = <QuantumSduiJsonAssertion>[];
    if (assertionsRaw is List) {
      for (var index = 0; index < assertionsRaw.length; index++) {
        final item = assertionsRaw[index];
        if (item is Map) {
          assertions.add(
            QuantumSduiJsonAssertion.fromJson(
              Map<String, dynamic>.from(item),
              fallbackId: '$fallbackId-assertion-$index',
            ),
          );
        }
      }
    }

    return QuantumSduiJsonCase(
      id: _string(json['id'], fallback: fallbackId),
      title: _string(json['title'], fallback: _string(json['id'], fallback: fallbackId)),
      description: json['description']?.toString(),
      sourcePath: json['sourcePath']?.toString(),
      snapshotPath: json['snapshotPath']?.toString(),
      sourceSha256: json['sourceSha256']?.toString(),
      lineCountAtLeast: _int(json['lineCountAtLeast']),
      assertions: assertions,
    );
  }
}

class QuantumSduiJsonAssertion {
  final String kind;
  final List<String> values;
  final List<String> expected;
  final int? value;
  final String? path;
  final List<QuantumSduiJsonAssertion> assertions;

  QuantumSduiJsonAssertion({
    required this.kind,
    required this.values,
    required this.expected,
    required this.value,
    required this.path,
    required this.assertions,
  });

  factory QuantumSduiJsonAssertion.fromJson(Map<String, dynamic> json, {required String fallbackId}) {
    final nestedRaw = json['assertions'] ?? json['children'] ?? json['items'];
    final nested = <QuantumSduiJsonAssertion>[];
    if (nestedRaw is List) {
      for (var index = 0; index < nestedRaw.length; index++) {
        final item = nestedRaw[index];
        if (item is Map) {
          nested.add(
            QuantumSduiJsonAssertion.fromJson(
              Map<String, dynamic>.from(item),
              fallbackId: '$fallbackId-child-$index',
            ),
          );
        }
      }
    }

    return QuantumSduiJsonAssertion(
      kind: _string(json['kind'], fallback: ''),
      values: _stringList(json['values'] ?? json['value']),
      expected: _stringList(json['expected']),
      value: _int(json['value']),
      path: json['path']?.toString(),
      assertions: nested,
    );
  }
}

void defineQuantumSduiJsonSuite({
  required String folderPath,
}) {
  final dir = Directory(folderPath);
  test('SDUI JSON folder exists', () {
    expect(dir.existsSync(), isTrue, reason: 'Missing JSON folder: $folderPath');
  });

  if (!dir.existsSync()) return;

  final files = dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final suite = QuantumSduiJsonSuite.fromFile(file);
    group(suite.title, () {
      test('suite metadata is readable', () {
        expect(suite.id, isNotEmpty);
        expect(suite.title, isNotEmpty);
        if (!suite.allowBlank) {
          expect(suite.description, isNotNull);
        }
      });

      if (suite.groups.isNotEmpty) {
        test('suite exposes nested groups', () {
          expect(suite.groups, isNotEmpty);
        });
        for (final groupNode in suite.groups) {
          _runGroupNode(file: file, groupNode: groupNode);
        }
      }

      if (suite.cases.isNotEmpty) {
        test('suite exposes root cases', () {
          expect(suite.cases, isNotEmpty);
        });
        for (final testCase in suite.cases) {
          test(testCase.title, () {
            _runJsonCase(file: file, testCase: testCase);
          });
        }
      }
    });
  }
}

void _runGroupNode({
  required File file,
  required QuantumSduiJsonGroup groupNode,
}) {
  group(groupNode.title, () {
    test('group metadata is readable', () {
      expect(groupNode.id, isNotEmpty);
      expect(groupNode.title, isNotEmpty);
      if (groupNode.description != null) {
        expect(groupNode.description!.trim(), isNotEmpty);
      }
      if (groupNode.tags.isNotEmpty) {
        expect(groupNode.tags, isNotEmpty);
      }
    });

    if (groupNode.groups.isNotEmpty) {
      test('group exposes nested groups', () {
        expect(groupNode.groups, isNotEmpty);
      });
      for (final childGroup in groupNode.groups) {
        _runGroupNode(file: file, groupNode: childGroup);
      }
    }

    if (groupNode.cases.isNotEmpty) {
      test('group exposes cases', () {
        expect(groupNode.cases, isNotEmpty);
      });
      for (final testCase in groupNode.cases) {
        test(testCase.title, () {
          _runJsonCase(file: file, testCase: testCase);
        });
      }
    }
  });
}

void _runJsonCase({
  required File file,
  required QuantumSduiJsonCase testCase,
}) {
  final sourcePath = testCase.sourcePath;
  final sourceFile = sourcePath == null ? null : File(sourcePath);
  final sourceText = sourceFile != null && sourceFile.existsSync() ? sourceFile.readAsStringSync() : '';
  final sourceJson = _tryDecodeJson(sourceText);

  if (sourcePath != null) {
    expect(sourceFile!.existsSync(), isTrue, reason: 'Missing source file: $sourcePath');
  }

  if (testCase.sourceSha256 != null && sourceText.isNotEmpty) {
    expect(sha256.convert(utf8.encode(sourceText)).toString(), testCase.sourceSha256);
  }

  if (testCase.lineCountAtLeast != null && sourceText.isNotEmpty) {
    final lineCount = sourceText.split('\n').length;
    expect(lineCount, greaterThanOrEqualTo(testCase.lineCountAtLeast!));
  }

  _runAssertions(
    file: file,
    sourceText: sourceText,
    sourceJson: sourceJson,
    sourcePath: sourcePath,
    assertions: testCase.assertions,
  );
}

void _runAssertions({
  required File file,
  required String sourceText,
  required dynamic sourceJson,
  required String? sourcePath,
  required List<QuantumSduiJsonAssertion> assertions,
}) {
  for (final assertion in assertions) {
    _runSingleAssertion(
      file: file,
      sourceText: sourceText,
      sourceJson: sourceJson,
      sourcePath: sourcePath,
      assertion: assertion,
    );
  }
}

void _runSingleAssertion({
  required File file,
  required String sourceText,
  required dynamic sourceJson,
  required String? sourcePath,
  required QuantumSduiJsonAssertion assertion,
}) {
  switch (assertion.kind) {
    case 'all':
      expect(assertion.assertions, isNotEmpty, reason: 'all requires nested assertions');
      _runAssertions(
        file: file,
        sourceText: sourceText,
        sourceJson: sourceJson,
        sourcePath: sourcePath,
        assertions: assertion.assertions,
      );
      break;
    case 'any':
      expect(assertion.assertions, isNotEmpty, reason: 'any requires nested assertions');
      final failures = <String>[];
      var passed = false;
      for (final child in assertion.assertions) {
        try {
          _runAssertions(
            file: file,
            sourceText: sourceText,
            sourceJson: sourceJson,
            sourcePath: sourcePath,
            assertions: [child],
          );
          passed = true;
          break;
        } catch (error) {
          failures.add('$error');
        }
      }
      expect(
        passed,
        isTrue,
        reason: 'None of the nested any(...) assertions passed for ${sourcePath ?? file.path}.\n${failures.join('\n---\n')}',
      );
      break;
    case 'not':
      expect(assertion.assertions, isNotEmpty, reason: 'not requires nested assertions');
      var nestedPassed = false;
      try {
        _runAssertions(
          file: file,
          sourceText: sourceText,
          sourceJson: sourceJson,
          sourcePath: sourcePath,
          assertions: assertion.assertions,
        );
        nestedPassed = true;
      } catch (_) {
        nestedPassed = false;
      }
      expect(
        nestedPassed,
        isFalse,
        reason: 'Expected nested assertion block to fail for ${sourcePath ?? file.path}',
      );
      break;
    case 'source_contains_all':
      for (final value in assertion.values) {
        expect(sourceText.contains(value), isTrue,
            reason: 'Missing `$value` in ${sourcePath ?? file.path}');
      }
      break;
    case 'source_contains_any':
      expect(assertion.values.any(sourceText.contains), isTrue,
          reason: 'None of the expected strings were found in ${sourcePath ?? file.path}');
      break;
    case 'source_not_contains':
      for (final value in assertion.values) {
        expect(sourceText.contains(value), isFalse,
            reason: 'Unexpected `$value` in ${sourcePath ?? file.path}');
      }
      break;
    case 'subtypes_exact':
      final actual = _extractSubtypes(sourceText);
      expect(actual, unorderedEquals(assertion.expected),
          reason: 'Subtype catalog mismatch in ${sourcePath ?? file.path}');
      break;
    case 'subtypes_contains':
      final actual = _extractSubtypes(sourceText).toSet();
      for (final expected in assertion.expected) {
        expect(actual.contains(expected), isTrue,
            reason: 'Missing subtype `$expected` in ${sourcePath ?? file.path}');
      }
      break;
    case 'builder_contains':
      for (final value in assertion.values) {
        expect(sourceText.contains(value), isTrue,
            reason: 'Missing builder symbol `$value` in ${sourcePath ?? file.path}');
      }
      break;
    case 'line_count_at_least':
      final min = assertion.value ?? 0;
      expect(sourceText.split('\n').length, greaterThanOrEqualTo(min));
      break;
    case 'source_sha256_matches':
      expect(
        sha256.convert(utf8.encode(sourceText)).toString(),
        assertion.values.isNotEmpty ? assertion.values.first : '',
      );
      break;
    case 'snapshot_path_not_empty':
      final snapshot = quantum_layout.QuantumSduiTypeEngine.exportSnapshot();
      final value = _resolveSnapshotPath(snapshot, assertion.path ?? '');
      expect(value, isNotNull);
      expect(value.toString().trim(), isNotEmpty);
      break;
    case 'json_round_trip':
      final normalized = _jsonRoundTrip(sourceText);
      expect(normalized, isNotEmpty);
      break;
    case 'json_round_trip_strict':
      final normalized = _jsonRoundTrip(sourceText);
      expect(normalized, _jsonRoundTrip(normalized));
      break;
    case 'json_root_keys_contains':
      final root = _requireJsonRoot(sourceJson, sourcePath ?? file.path, assertion.kind);
      final keys = root.keys.map((e) => e.toString()).toSet();
      for (final expected in assertion.expected) {
        expect(keys.contains(expected), isTrue,
            reason: 'Missing root key `$expected` in ${sourcePath ?? file.path}');
      }
      break;
    case 'json_root_keys_exact':
      final root = _requireJsonRoot(sourceJson, sourcePath ?? file.path, assertion.kind);
      expect(root.keys.map((e) => e.toString()).toSet(), unorderedEquals(assertion.expected.toSet()));
      break;
    case 'json_meta_keys_contains':
      final meta = _requireJsonMeta(sourceJson, sourcePath ?? file.path);
      final keys = meta.keys.map((e) => e.toString()).toSet();
      for (final expected in assertion.expected) {
        expect(keys.contains(expected), isTrue,
            reason: 'Missing meta key `$expected` in ${sourcePath ?? file.path}');
      }
      break;
    case 'json_meta_keys_exact':
      final meta = _requireJsonMeta(sourceJson, sourcePath ?? file.path);
      expect(meta.keys.map((e) => e.toString()).toSet(), unorderedEquals(assertion.expected.toSet()));
      break;
    case 'json_case_count_at_least':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      expect(cases.length, greaterThanOrEqualTo(assertion.value ?? 0));
      break;
    case 'json_case_count_exact':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      expect(cases.length, assertion.value ?? 0);
      break;
    case 'json_case_keys_contains':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      for (final caseJson in cases) {
        final keys = caseJson.keys.map((e) => e.toString()).toSet();
        for (final expected in assertion.expected) {
          expect(keys.contains(expected), isTrue,
              reason: 'Missing case key `$expected` in ${sourcePath ?? file.path}');
        }
      }
      break;
    case 'json_case_keys_exact':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      final expected = assertion.expected.toSet();
      for (final caseJson in cases) {
        expect(caseJson.keys.map((e) => e.toString()).toSet(), unorderedEquals(expected));
      }
      break;
    case 'json_case_ids_unique':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      final ids = <String>{};
      for (final caseJson in cases) {
        final id = caseJson['id']?.toString().trim() ?? '';
        expect(id, isNotEmpty, reason: 'Blank case id in ${sourcePath ?? file.path}');
        expect(ids.add(id), isTrue, reason: 'Duplicate case id `$id` in ${sourcePath ?? file.path}');
      }
      break;
    case 'json_case_assertions_nonempty':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      for (final caseJson in cases) {
        final assertions = caseJson['assertions'];
        expect(assertions, isA<List>(), reason: 'Case assertions must be a list in ${sourcePath ?? file.path}');
        expect((assertions as List).isNotEmpty, isTrue,
            reason: 'Empty assertions list in ${sourcePath ?? file.path}');
      }
      break;
    case 'json_assertion_kinds_allowed':
      final cases = _requireJsonCases(sourceJson, sourcePath ?? file.path);
      final allowed = assertion.values.isEmpty ? _supportedAssertionKinds : assertion.values.toSet();
      for (final caseJson in cases) {
        final assertions = caseJson['assertions'];
        if (assertions is! List) continue;
        for (final raw in assertions) {
          if (raw is! Map) continue;
          final kind = raw['kind']?.toString() ?? '';
          expect(kind, isNotEmpty, reason: 'Blank assertion kind in ${sourcePath ?? file.path}');
          expect(allowed.contains(kind), isTrue,
              reason: 'Unsupported assertion kind `$kind` in ${sourcePath ?? file.path}');
        }
      }
      break;
    case 'json_path_exists':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      expect(value, isNotNull, reason: 'Missing JSON path `${assertion.path}` in ${sourcePath ?? file.path}');
      break;
    case 'json_path_not_empty':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      expect(value, isNotNull, reason: 'Missing JSON path `${assertion.path}` in ${sourcePath ?? file.path}');
      expect(_valueIsEmpty(value), isFalse, reason: 'Blank JSON path `${assertion.path}` in ${sourcePath ?? file.path}');
      break;
    case 'json_path_equals':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      final expected = assertion.expected.isNotEmpty ? assertion.expected.first : '';
      expect(_jsonScalar(value), expected,
          reason: 'JSON path `${assertion.path}` mismatch in ${sourcePath ?? file.path}');
      break;
    case 'json_path_contains_all':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      final values = _pathValues(value);
      for (final expected in assertion.expected) {
        expect(values.contains(expected), isTrue,
            reason: 'Missing `$expected` at JSON path `${assertion.path}` in ${sourcePath ?? file.path}');
      }
      break;
    case 'json_path_contains_any':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      final values = _pathValues(value);
      expect(
        assertion.expected.any(values.contains),
        isTrue,
        reason: 'None of the expected values were found at JSON path `${assertion.path}` in ${sourcePath ?? file.path}',
      );
      break;
    case 'json_path_keys_contains':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      final mapValue = _jsonMap(value);
      expect(mapValue, isNotNull, reason: 'JSON path `${assertion.path}` must resolve to an object in ${sourcePath ?? file.path}');
      final keys = mapValue!.keys.map((e) => e.toString()).toSet();
      for (final expected in assertion.expected) {
        expect(keys.contains(expected), isTrue,
            reason: 'Missing key `$expected` at JSON path `${assertion.path}` in ${sourcePath ?? file.path}');
      }
      break;
    case 'json_path_keys_exact':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      final mapValue = _jsonMap(value);
      expect(mapValue, isNotNull, reason: 'JSON path `${assertion.path}` must resolve to an object in ${sourcePath ?? file.path}');
      expect(mapValue!.keys.map((e) => e.toString()).toSet(), unorderedEquals(assertion.expected.toSet()));
      break;
    case 'json_path_length_at_least':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      expect(_pathLength(value), greaterThanOrEqualTo(assertion.value ?? 0),
          reason: 'JSON path `${assertion.path}` must have length >= ${assertion.value ?? 0}');
      break;
    case 'json_path_length_exact':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      expect(_pathLength(value), assertion.value ?? 0,
          reason: 'JSON path `${assertion.path}` must have length ${assertion.value ?? 0}');
      break;
    case 'json_path_type_is':
      final value = _resolveJsonPath(sourceJson, assertion.path ?? '');
      final expectedType = _pathTypeName(assertion.expected, assertion.values);
      expect(_jsonTypeName(value), expectedType,
          reason: 'JSON path `${assertion.path}` type mismatch in ${sourcePath ?? file.path}');
      break;
    default:
      fail('Unsupported JSON assertion kind: ${assertion.kind}');
  }
}

String _pathTypeName(List<String> expected, List<String> values) {
  if (expected.isNotEmpty) return expected.first.toLowerCase();
  if (values.isNotEmpty) return values.first.toLowerCase();
  return '';
}

const Set<String> _supportedAssertionKinds = {
  'source_contains_all',
  'source_contains_any',
  'source_not_contains',
  'subtypes_exact',
  'subtypes_contains',
  'builder_contains',
  'line_count_at_least',
  'source_sha256_matches',
  'snapshot_path_not_empty',
  'json_round_trip',
  'json_round_trip_strict',
  'json_root_keys_contains',
  'json_root_keys_exact',
  'json_meta_keys_contains',
  'json_meta_keys_exact',
  'json_case_count_at_least',
  'json_case_count_exact',
  'json_case_keys_contains',
  'json_case_keys_exact',
  'json_case_ids_unique',
  'json_case_assertions_nonempty',
  'json_assertion_kinds_allowed',
  'json_path_exists',
  'json_path_not_empty',
  'json_path_equals',
  'json_path_contains_all',
  'json_path_contains_any',
  'json_path_keys_contains',
  'json_path_keys_exact',
  'json_path_length_at_least',
  'json_path_length_exact',
  'json_path_type_is',
  'all',
  'any',
  'not',
};

List<String> _extractSubtypes(String sourceText) {
  final matches = RegExp(r"subType == '([^']+)'").allMatches(sourceText);
  final values = <String>{};
  for (final match in matches) {
    values.add(match.group(1)!);
  }
  return values.toList()..sort();
}

dynamic _resolveSnapshotPath(Map<String, dynamic> snapshot, String path) {
  if (path.trim().isEmpty) return snapshot;
  dynamic current = snapshot;
  for (final segment in _pathSegments(path)) {
    if (segment is String) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    } else if (segment is int) {
      if (current is List && segment >= 0 && segment < current.length) {
        current = current[segment];
      } else {
        return null;
      }
    }
  }
  return current;
}

dynamic _resolveJsonPath(dynamic root, String path) {
  if (path.trim().isEmpty) return root;
  dynamic current = root;
  for (final segment in _pathSegments(path)) {
    if (segment is String) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    } else if (segment is int) {
      if (current is List && segment >= 0 && segment < current.length) {
        current = current[segment];
      } else {
        return null;
      }
    }
  }
  return current;
}

Iterable<Object> _pathSegments(String path) sync* {
  var buffer = StringBuffer();
  for (var i = 0; i < path.length; i++) {
    final ch = path[i];
    if (ch == '.') {
      if (buffer.isNotEmpty) {
        yield buffer.toString();
        buffer = StringBuffer();
      }
      continue;
    }
    if (ch == '[') {
      if (buffer.isNotEmpty) {
        yield buffer.toString();
        buffer = StringBuffer();
      }
      final close = path.indexOf(']', i + 1);
      if (close == -1) {
        yield path.substring(i);
        return;
      }
      final indexText = path.substring(i + 1, close).trim();
      if (indexText.isNotEmpty) {
        final index = int.tryParse(indexText);
        yield index ?? indexText;
      }
      i = close;
      continue;
    }
    buffer.write(ch);
  }
  if (buffer.isNotEmpty) {
    yield buffer.toString();
  }
}

Map<String, dynamic>? _jsonMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

Map<String, dynamic> _requireJsonRoot(dynamic sourceJson, String sourcePath, String kind) {
  if (sourceJson is! Map<String, dynamic>) {
    fail('`$kind` requires a JSON source file: $sourcePath');
  }
  return sourceJson;
}

Map<String, dynamic> _requireJsonMeta(dynamic sourceJson, String sourcePath) {
  final root = _requireJsonRoot(sourceJson, sourcePath, 'json_meta_keys_*');
  final meta = _jsonMap(root['__meta']) ?? _jsonMap(root['meta']);
  if (meta == null) {
    fail('Missing __meta/meta block in $sourcePath');
  }
  return meta;
}

List<Map<String, dynamic>> _requireJsonCases(dynamic sourceJson, String sourcePath) {
  final root = _requireJsonRoot(sourceJson, sourcePath, 'json_case_*');
  final rawCases = root['cases'] ?? root['tests'] ?? root['rows'];
  if (rawCases is! List) {
    fail('Missing cases/tests/rows list in $sourcePath');
  }
  return rawCases.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
}

dynamic _tryDecodeJson(String sourceText) {
  if (sourceText.trim().isEmpty) return null;
  try {
    return jsonDecode(sourceText);
  } catch (_) {
    return null;
  }
}

String _jsonRoundTrip(String sourceText) {
  final decoded = jsonDecode(sourceText);
  return jsonEncode(decoded);
}

String _string(dynamic value, {required String fallback}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(growable: false);
  }
  return const <String>[];
}

bool _valueIsEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  if (value is Iterable) return value.isEmpty;
  if (value is Map) return value.isEmpty;
  return false;
}

int _pathLength(dynamic value) {
  if (value is String) return value.length;
  if (value is List) return value.length;
  if (value is Map) return value.length;
  return 0;
}

String _jsonScalar(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return jsonEncode(value);
}

String _jsonTypeName(dynamic value) {
  if (value == null) return 'null';
  if (value is String) return 'string';
  if (value is int || value is double) return 'number';
  if (value is bool) return 'bool';
  if (value is List) return 'list';
  if (value is Map) return 'map';
  return 'other';
}

Set<String> _pathValues(dynamic value) {
  if (value is String) {
    return {value};
  }
  if (value is Iterable) {
    return value.map((e) => e.toString()).toSet();
  }
  if (value is Map) {
    return value.keys.map((e) => e.toString()).toSet();
  }
  if (value == null) {
    return const <String>{};
  }
  return {value.toString()};
}

String _slugFromPath(String filePath) {
  final normalized = filePath.replaceAll('\\', '/');
  final fileName = normalized.split('/').last.replaceAll(RegExp(r'\.json$'), '');
  final slug = fileName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return slug.isEmpty ? 'case-unknown' : slug;
}
