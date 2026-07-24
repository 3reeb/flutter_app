import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("decoration");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('decoration alias contract', () {
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

    test('decorate exists as an alias', () {
      final alias = vm.getAlias("decorate");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('decorate registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("decorate", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "decorate");
      final alias = Map<String, dynamic>.from(vm.getAlias("decorate")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('decorate is discoverable by name query', () {
      final entry = vm.registryEntry("decorate", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "decorate");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('decorate is discoverable by alias description query', () {
      final entry = vm.registryEntry("decorate", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "decorate";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('decorate describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("decorate", kind: 'alias');
      final described = vm.describeRegistryItem("decorate", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "decorate");
    });

    test('decorate default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("decorate")!);
      final entry = vm.registryEntry("decorate", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('highlight exists as an alias', () {
      final alias = vm.getAlias("highlight");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('highlight registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("highlight", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "highlight");
      final alias = Map<String, dynamic>.from(vm.getAlias("highlight")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('highlight is discoverable by name query', () {
      final entry = vm.registryEntry("highlight", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "highlight");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('highlight is discoverable by alias description query', () {
      final entry = vm.registryEntry("highlight", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "highlight";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('highlight describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("highlight", kind: 'alias');
      final described = vm.describeRegistryItem("highlight", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "highlight");
    });

    test('highlight default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("highlight")!);
      final entry = vm.registryEntry("highlight", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('markup exists as an alias', () {
      final alias = vm.getAlias("markup");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('markup registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("markup", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "markup");
      final alias = Map<String, dynamic>.from(vm.getAlias("markup")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('markup is discoverable by name query', () {
      final entry = vm.registryEntry("markup", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "markup");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('markup is discoverable by alias description query', () {
      final entry = vm.registryEntry("markup", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "markup";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('markup describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("markup", kind: 'alias');
      final described = vm.describeRegistryItem("markup", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "markup");
    });

    test('markup default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("markup")!);
      final entry = vm.registryEntry("markup", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

