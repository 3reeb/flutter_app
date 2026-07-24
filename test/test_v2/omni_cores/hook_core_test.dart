import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("hook");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('hook alias contract', () {
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

    test('hook_lifecycle exists as an alias', () {
      final alias = vm.getAlias("hook_lifecycle");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('hook_lifecycle registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "hook_lifecycle");
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_lifecycle")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('hook_lifecycle is discoverable by name query', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "hook_lifecycle");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_lifecycle is discoverable by alias description query', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "hook_lifecycle";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_lifecycle describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias');
      final described = vm.describeRegistryItem("hook_lifecycle", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "hook_lifecycle");
    });

    test('hook_lifecycle default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_lifecycle")!);
      final entry = vm.registryEntry("hook_lifecycle", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('hook_effect exists as an alias', () {
      final alias = vm.getAlias("hook_effect");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('hook_effect registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "hook_effect");
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_effect")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('hook_effect is discoverable by name query', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "hook_effect");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_effect is discoverable by alias description query', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "hook_effect";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_effect describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("hook_effect", kind: 'alias');
      final described = vm.describeRegistryItem("hook_effect", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "hook_effect");
    });

    test('hook_effect default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_effect")!);
      final entry = vm.registryEntry("hook_effect", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('hook_scope exists as an alias', () {
      final alias = vm.getAlias("hook_scope");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('hook_scope registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "hook_scope");
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_scope")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('hook_scope is discoverable by name query', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "hook_scope");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_scope is discoverable by alias description query', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "hook_scope";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_scope describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("hook_scope", kind: 'alias');
      final described = vm.describeRegistryItem("hook_scope", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "hook_scope");
    });

    test('hook_scope default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_scope")!);
      final entry = vm.registryEntry("hook_scope", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('hook_bridge exists as an alias', () {
      final alias = vm.getAlias("hook_bridge");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('hook_bridge registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "hook_bridge");
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_bridge")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('hook_bridge is discoverable by name query', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "hook_bridge");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_bridge is discoverable by alias description query', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "hook_bridge";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hook_bridge describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("hook_bridge", kind: 'alias');
      final described = vm.describeRegistryItem("hook_bridge", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "hook_bridge");
    });

    test('hook_bridge default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("hook_bridge")!);
      final entry = vm.registryEntry("hook_bridge", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

