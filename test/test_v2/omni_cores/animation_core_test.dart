import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("animation");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('animation alias contract', () {
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

    test('animation exists as an alias', () {
      final alias = vm.getAlias("animation");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('animation registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("animation", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "animation");
      final alias = Map<String, dynamic>.from(vm.getAlias("animation")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('animation is discoverable by name query', () {
      final entry = vm.registryEntry("animation", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "animation");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('animation is discoverable by alias description query', () {
      final entry = vm.registryEntry("animation", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "animation";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('animation describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("animation", kind: 'alias');
      final described = vm.describeRegistryItem("animation", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "animation");
    });

    test('animation default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("animation")!);
      final entry = vm.registryEntry("animation", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('motion exists as an alias', () {
      final alias = vm.getAlias("motion");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('motion registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("motion", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "motion");
      final alias = Map<String, dynamic>.from(vm.getAlias("motion")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('motion is discoverable by name query', () {
      final entry = vm.registryEntry("motion", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "motion");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('motion is discoverable by alias description query', () {
      final entry = vm.registryEntry("motion", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "motion";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('motion describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("motion", kind: 'alias');
      final described = vm.describeRegistryItem("motion", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "motion");
    });

    test('motion default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("motion")!);
      final entry = vm.registryEntry("motion", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('transition exists as an alias', () {
      final alias = vm.getAlias("transition");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('transition registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("transition", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "transition");
      final alias = Map<String, dynamic>.from(vm.getAlias("transition")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('transition is discoverable by name query', () {
      final entry = vm.registryEntry("transition", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "transition");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('transition is discoverable by alias description query', () {
      final entry = vm.registryEntry("transition", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "transition";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('transition describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("transition", kind: 'alias');
      final described = vm.describeRegistryItem("transition", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "transition");
    });

    test('transition default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("transition")!);
      final entry = vm.registryEntry("transition", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('animate exists as an alias', () {
      final alias = vm.getAlias("animate");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('animate registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("animate", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "animate");
      final alias = Map<String, dynamic>.from(vm.getAlias("animate")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('animate is discoverable by name query', () {
      final entry = vm.registryEntry("animate", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "animate");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('animate is discoverable by alias description query', () {
      final entry = vm.registryEntry("animate", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "animate";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('animate describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("animate", kind: 'alias');
      final described = vm.describeRegistryItem("animate", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "animate");
    });

    test('animate default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("animate")!);
      final entry = vm.registryEntry("animate", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('glass_motion exists as an alias', () {
      final alias = vm.getAlias("glass_motion");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('glass_motion registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "glass_motion");
      final alias = Map<String, dynamic>.from(vm.getAlias("glass_motion")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('glass_motion is discoverable by name query', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "glass_motion");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('glass_motion is discoverable by alias description query', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "glass_motion";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('glass_motion describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("glass_motion", kind: 'alias');
      final described = vm.describeRegistryItem("glass_motion", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "glass_motion");
    });

    test('glass_motion default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("glass_motion")!);
      final entry = vm.registryEntry("glass_motion", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

