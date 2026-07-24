import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

const String _fixtureRoot = 'test/test_v2/fixtures';

Map<String, dynamic> loadJsonFixture(String fileName) {
  final file = File('$_fixtureRoot/$fileName');
  if (!file.existsSync()) {
    throw StateError('Missing fixture file: ${file.path}');
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! Map) {
    throw StateError('Expected decoded JSON to be a Map');
  }
  return Map<String, dynamic>.from(decoded);
}

List<Map<String, dynamic>> loadJsonList(
  String fileName,
  String key,
) {
  final fixture = loadJsonFixture(fileName);
  final value = fixture[key];
  if (value is! List) {
    throw StateError('Expected `$key` to be a JSON array in $fileName');
  }
  return value
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);
}

List<Map<String, dynamic>> loadAliasGroup(String group) {
  final fixture = loadJsonFixture('omni_registry_cases.json');
  final groups = Map<String, dynamic>.from(fixture['groups'] as Map);
  final value = groups[group];
  if (value is! List) {
    throw StateError('Missing alias group `$group` in omni_registry_cases.json');
  }
  return value
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList(growable: false);
}

QuantumVM bootstrapQuantum({bool includeConnect = false}) {
  final vm = QuantumVM.instance;
  registerOmniComponents(vm);
  if (includeConnect) {
    registerConnectOmniNodes(vm);
  }
  return vm;
}

Map<String, dynamic>? registryItem(String key, {String? kind}) {
  return QuantumVM.instance.describeRegistryItem(key, kind: kind);
}
