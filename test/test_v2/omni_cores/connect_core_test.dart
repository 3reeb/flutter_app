import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: true);
  final aliases = loadAliasGroup('connect');

  setUpAll(() {
    bootstrapQuantum(includeConnect: true);
  });

  group('connect core contract', () {
    test('connect plugin is registered', () {
      final entry = vm.registryEntry('connect', kind: 'widget');
      expect(entry, isNotNull);
      expect(entry!.kind, 'widget');
      expect(entry.name, 'connect');
    });

    test('connect behaviors are installed', () {
      expect(QLBehaviorRegistry.has('smart_back_button'), isTrue);
      expect(QLBehaviorRegistry.has('press_hold_morph'), isTrue);
      expect(QLBehaviorRegistry.has('focus_reveal_close'), isTrue);
      expect(QLBehaviorRegistry.resolve('smart_back_button'), isNotNull);
      expect(QLBehaviorRegistry.resolve('press_hold_morph'), isNotNull);
      expect(QLBehaviorRegistry.resolve('focus_reveal_close'), isNotNull);
    });

    for (final alias in aliases) {
      final String name = alias['name'] as String;
      final String safe = name.replaceAll("'", "\'");
      final Map<String, dynamic> defaults =
          Map<String, dynamic>.from(alias['defaultProps'] as Map? ?? const {});

      test('$safe exists in connect alias registry', () {
        expect(vm.getAlias(name), isNotNull);
      });

      test('$safe registry entry is an alias', () {
        final entry = vm.registryEntry(name, kind: 'alias');
        expect(entry, isNotNull);
        expect(entry!.kind, 'alias');
        expect(entry.name, name);
      });

      test('$safe targetType stays aligned', () {
        final aliasMap = Map<String, dynamic>.from(vm.getAlias(name)!);
        final entry = vm.registryEntry(name, kind: 'alias')!;
        expect(entry.params['targetType'], aliasMap['type']);
      });

      test('$safe default props are preserved', () {
        final aliasMap = Map<String, dynamic>.from(vm.getAlias(name)!);
        final entry = vm.registryEntry(name, kind: 'alias')!;
        expect(aliasMap['props'], equals(entry.params['defaultProps']));
        if (defaults.isNotEmpty) {
          expect(aliasMap['props'], equals(defaults));
        }
      });

      test('$safe is found by query', () {
        final entry = vm.registryEntry(name, kind: 'alias')!;
        final results = vm.registryEntries(kind: 'alias', query: name);
        expect(results.any((e) => e.id == entry.id), isTrue);
      });
    }
  });
}

