import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("canvas");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('canvas alias contract', () {
    test('group has entries', () {
      expect(aliasNames, isNotEmpty);
    });

    test('all names are registered in the alias registry', () {
      for (final name in aliasNames) {
        expect(vm.getAlias(name), isNotNull, reason: 'Missing alias: $name');
        final entry = vm.registryEntry(name, kind: 'alias');
        expect(entry, isNotNull, reason: 'Missing registry entry: alias:$name');
      }
    });

    test('shader exists as an alias', () {
      final alias = vm.getAlias("shader");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('shader registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("shader", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "shader");
      final alias = Map<String, dynamic>.from(vm.getAlias("shader")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('shader is discoverable by name query', () {
      final entry = vm.registryEntry("shader", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "shader");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('shader is discoverable by alias description query', () {
      final entry = vm.registryEntry("shader", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "shader";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('shader describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("shader", kind: 'alias');
      final described = vm.describeRegistryItem("shader", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "shader");
    });

    test('shader default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("shader")!);
      final entry = vm.registryEntry("shader", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

