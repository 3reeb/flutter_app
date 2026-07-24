import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("data");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('data alias contract', () {
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

    test('sliver_plane exists as an alias', () {
      final alias = vm.getAlias("sliver_plane");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sliver_plane registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sliver_plane");
      final alias = Map<String, dynamic>.from(vm.getAlias("sliver_plane")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sliver_plane is discoverable by name query', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sliver_plane");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sliver_plane is discoverable by alias description query', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sliver_plane";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sliver_plane describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sliver_plane", kind: 'alias');
      final described = vm.describeRegistryItem("sliver_plane", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sliver_plane");
    });

    test('sliver_plane default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sliver_plane")!);
      final entry = vm.registryEntry("sliver_plane", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('sliver exists as an alias', () {
      final alias = vm.getAlias("sliver");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sliver registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sliver", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sliver");
      final alias = Map<String, dynamic>.from(vm.getAlias("sliver")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sliver is discoverable by name query', () {
      final entry = vm.registryEntry("sliver", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sliver");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sliver is discoverable by alias description query', () {
      final entry = vm.registryEntry("sliver", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sliver";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sliver describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sliver", kind: 'alias');
      final described = vm.describeRegistryItem("sliver", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sliver");
    });

    test('sliver default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sliver")!);
      final entry = vm.registryEntry("sliver", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

