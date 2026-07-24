import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import '../support/quantum_test_support.dart';

String _finalizeType(String type) {
  final alias = QuantumVM.instance.getAlias(type);
  if (alias != null) {
    type = alias['type']?.toString() ?? type;
  }
  final parts = type.split(':');
  final base = parts.first;
  final sub = parts.length > 1 ? parts.sublist(1).join(':') : '';
  if (base == 'box' && sub.isNotEmpty) return type;
  return base;
}

String _expectedType(Map<String, dynamic> raw) {
  final type = raw['type']?.toString() ?? 'box';
  return _finalizeType(type);
}

void _expectPayload(QLBlueprint blueprint, Map<String, dynamic> raw) {
  final props = raw['props'];
  if (props is Map) {
    for (final entry in props.entries) {
      expect(blueprint.props[entry.key], entry.value);
    }
  }

  final type = raw['type']?.toString();
  if (type != null) {
    final alias = QuantumVM.instance.getAlias(type);
    if (alias != null) {
      final defaults =
          Map<String, dynamic>.from(alias['props'] as Map? ?? const {});
      for (final entry in defaults.entries) {
        final rawProps = raw['props'] as Map? ?? {};
        bool hasOverride = rawProps.containsKey(entry.key);
        if (entry.key == 'className' && rawProps.containsKey('style')) {
          hasOverride = true;
        }
        if (!hasOverride) {
          expect(blueprint.props[entry.key], entry.value);
        }
      }
    }
  }

  final children = raw['children'];
  if (children is List) {
    expect(blueprint.children.length, children.length);
  }

  final slots = raw['slots'];
  if (slots is Map) {
    expect(blueprint.slots.length, slots.length);
  }
}

void main() {
  final cases = loadJsonList('blueprint_cases.json', 'cases');

  setUpAll(() {
    bootstrapQuantum(includeConnect: true);
  });

  group('QLBlueprint JSON behavior', () {
    test('fixture count is stable', () {
      expect(cases.length, 76);
    });

    for (final caseData in cases) {
      final label = caseData['label'] as String;
      final raw = Map<String, dynamic>.from(caseData['raw'] as Map);

      test('$label normalizes to the expected type', () {
        final blueprint = QLBlueprint.fromJson(raw, path: label);
        expect(blueprint.debugPath, label);
        expect(blueprint.type, _expectedType(raw));
      });

      test('$label roundtrips through toJson', () {
        final blueprint = QLBlueprint.fromJson(raw, path: label);
        final clone =
            QLBlueprint.fromJson(blueprint.toJson(), path: '$label.clone');
        expect(clone.type, blueprint.type);
        expect(clone.debugPath, '$label.clone');
      });

      test('$label exposes raw payload details', () {
        final blueprint = QLBlueprint.fromJson(raw, path: label);
        _expectPayload(blueprint, raw);
      });

      test('$label serializes to valid JSON', () {
        final blueprint = QLBlueprint.fromJson(raw, path: label);
        expect(() => jsonEncode(blueprint.toJson()), returnsNormally);
      });

      test('$label has a stable debug path', () {
        final blueprint = QLBlueprint.fromJson(raw, path: label);
        expect(blueprint.toJson()['debugPath'], label);
      });
    }
  });
}

