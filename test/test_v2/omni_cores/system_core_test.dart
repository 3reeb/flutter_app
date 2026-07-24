import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("system");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('system alias contract', () {
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

    test('sync_scroll exists as an alias', () {
      final alias = vm.getAlias("sync_scroll");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sync_scroll registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sync_scroll");
      final alias = Map<String, dynamic>.from(vm.getAlias("sync_scroll")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sync_scroll is discoverable by name query', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sync_scroll");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sync_scroll is discoverable by alias description query', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sync_scroll";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sync_scroll describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sync_scroll", kind: 'alias');
      final described = vm.describeRegistryItem("sync_scroll", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sync_scroll");
    });

    test('sync_scroll default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sync_scroll")!);
      final entry = vm.registryEntry("sync_scroll", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('worker exists as an alias', () {
      final alias = vm.getAlias("worker");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('worker registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("worker", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "worker");
      final alias = Map<String, dynamic>.from(vm.getAlias("worker")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('worker is discoverable by name query', () {
      final entry = vm.registryEntry("worker", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "worker");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('worker is discoverable by alias description query', () {
      final entry = vm.registryEntry("worker", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "worker";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('worker describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("worker", kind: 'alias');
      final described = vm.describeRegistryItem("worker", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "worker");
    });

    test('worker default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("worker")!);
      final entry = vm.registryEntry("worker", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('ticker exists as an alias', () {
      final alias = vm.getAlias("ticker");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('ticker registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("ticker", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "ticker");
      final alias = Map<String, dynamic>.from(vm.getAlias("ticker")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('ticker is discoverable by name query', () {
      final entry = vm.registryEntry("ticker", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "ticker");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('ticker is discoverable by alias description query', () {
      final entry = vm.registryEntry("ticker", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "ticker";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('ticker describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("ticker", kind: 'alias');
      final described = vm.describeRegistryItem("ticker", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "ticker");
    });

    test('ticker default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("ticker")!);
      final entry = vm.registryEntry("ticker", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('omega_macro exists as an alias', () {
      final alias = vm.getAlias("omega_macro");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('omega_macro registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "omega_macro");
      final alias = Map<String, dynamic>.from(vm.getAlias("omega_macro")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('omega_macro is discoverable by name query', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "omega_macro");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('omega_macro is discoverable by alias description query', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "omega_macro";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('omega_macro describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("omega_macro", kind: 'alias');
      final described = vm.describeRegistryItem("omega_macro", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "omega_macro");
    });

    test('omega_macro default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("omega_macro")!);
      final entry = vm.registryEntry("omega_macro", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

