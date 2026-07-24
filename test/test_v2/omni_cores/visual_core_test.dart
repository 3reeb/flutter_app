import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("visual");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('visual alias contract', () {
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

    test('visual_surface exists as an alias', () {
      final alias = vm.getAlias("visual_surface");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('visual_surface registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "visual_surface");
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_surface")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('visual_surface is discoverable by name query', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "visual_surface");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_surface is discoverable by alias description query', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "visual_surface";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_surface describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("visual_surface", kind: 'alias');
      final described = vm.describeRegistryItem("visual_surface", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "visual_surface");
    });

    test('visual_surface default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_surface")!);
      final entry = vm.registryEntry("visual_surface", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('visual_shell exists as an alias', () {
      final alias = vm.getAlias("visual_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('visual_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "visual_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('visual_shell is discoverable by name query', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "visual_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "visual_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("visual_shell", kind: 'alias');
      final described = vm.describeRegistryItem("visual_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "visual_shell");
    });

    test('visual_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_shell")!);
      final entry = vm.registryEntry("visual_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('visual_scene exists as an alias', () {
      final alias = vm.getAlias("visual_scene");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('visual_scene registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "visual_scene");
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_scene")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('visual_scene is discoverable by name query', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "visual_scene");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_scene is discoverable by alias description query', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "visual_scene";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_scene describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("visual_scene", kind: 'alias');
      final described = vm.describeRegistryItem("visual_scene", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "visual_scene");
    });

    test('visual_scene default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_scene")!);
      final entry = vm.registryEntry("visual_scene", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('visual_overlay exists as an alias', () {
      final alias = vm.getAlias("visual_overlay");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('visual_overlay registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "visual_overlay");
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_overlay")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('visual_overlay is discoverable by name query', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "visual_overlay");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_overlay is discoverable by alias description query', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "visual_overlay";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_overlay describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("visual_overlay", kind: 'alias');
      final described = vm.describeRegistryItem("visual_overlay", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "visual_overlay");
    });

    test('visual_overlay default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_overlay")!);
      final entry = vm.registryEntry("visual_overlay", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('visual_delegate exists as an alias', () {
      final alias = vm.getAlias("visual_delegate");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('visual_delegate registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "visual_delegate");
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_delegate")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('visual_delegate is discoverable by name query', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "visual_delegate");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_delegate is discoverable by alias description query', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "visual_delegate";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('visual_delegate describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("visual_delegate", kind: 'alias');
      final described = vm.describeRegistryItem("visual_delegate", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "visual_delegate");
    });

    test('visual_delegate default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("visual_delegate")!);
      final entry = vm.registryEntry("visual_delegate", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

