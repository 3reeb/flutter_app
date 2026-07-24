import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("action");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('action alias contract', () {
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

    test('raw_pointer exists as an alias', () {
      final alias = vm.getAlias("raw_pointer");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('raw_pointer registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "raw_pointer");
      final alias = Map<String, dynamic>.from(vm.getAlias("raw_pointer")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('raw_pointer is discoverable by name query', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "raw_pointer");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('raw_pointer is discoverable by alias description query', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "raw_pointer";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('raw_pointer describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("raw_pointer", kind: 'alias');
      final described = vm.describeRegistryItem("raw_pointer", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "raw_pointer");
    });

    test('raw_pointer default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("raw_pointer")!);
      final entry = vm.registryEntry("raw_pointer", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('pointer exists as an alias', () {
      final alias = vm.getAlias("pointer");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('pointer registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("pointer", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "pointer");
      final alias = Map<String, dynamic>.from(vm.getAlias("pointer")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('pointer is discoverable by name query', () {
      final entry = vm.registryEntry("pointer", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "pointer");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('pointer is discoverable by alias description query', () {
      final entry = vm.registryEntry("pointer", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "pointer";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('pointer describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("pointer", kind: 'alias');
      final described = vm.describeRegistryItem("pointer", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "pointer");
    });

    test('pointer default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("pointer")!);
      final entry = vm.registryEntry("pointer", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('focus exists as an alias', () {
      final alias = vm.getAlias("focus");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('focus registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("focus", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "focus");
      final alias = Map<String, dynamic>.from(vm.getAlias("focus")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('focus is discoverable by name query', () {
      final entry = vm.registryEntry("focus", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "focus");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('focus is discoverable by alias description query', () {
      final entry = vm.registryEntry("focus", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "focus";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('focus describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("focus", kind: 'alias');
      final described = vm.describeRegistryItem("focus", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "focus");
    });

    test('focus default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("focus")!);
      final entry = vm.registryEntry("focus", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('button exists as an alias', () {
      final alias = vm.getAlias("button");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('button registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("button", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "button");
      final alias = Map<String, dynamic>.from(vm.getAlias("button")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('button is discoverable by name query', () {
      final entry = vm.registryEntry("button", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "button");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('button is discoverable by alias description query', () {
      final entry = vm.registryEntry("button", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "button";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('button describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("button", kind: 'alias');
      final described = vm.describeRegistryItem("button", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "button");
    });

    test('button default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("button")!);
      final entry = vm.registryEntry("button", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('tap exists as an alias', () {
      final alias = vm.getAlias("tap");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('tap registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("tap", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "tap");
      final alias = Map<String, dynamic>.from(vm.getAlias("tap")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('tap is discoverable by name query', () {
      final entry = vm.registryEntry("tap", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "tap");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('tap is discoverable by alias description query', () {
      final entry = vm.registryEntry("tap", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "tap";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('tap describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("tap", kind: 'alias');
      final described = vm.describeRegistryItem("tap", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "tap");
    });

    test('tap default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("tap")!);
      final entry = vm.registryEntry("tap", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('press exists as an alias', () {
      final alias = vm.getAlias("press");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('press registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("press", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "press");
      final alias = Map<String, dynamic>.from(vm.getAlias("press")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('press is discoverable by name query', () {
      final entry = vm.registryEntry("press", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "press");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('press is discoverable by alias description query', () {
      final entry = vm.registryEntry("press", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "press";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('press describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("press", kind: 'alias');
      final described = vm.describeRegistryItem("press", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "press");
    });

    test('press default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("press")!);
      final entry = vm.registryEntry("press", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('hover_action exists as an alias', () {
      final alias = vm.getAlias("hover_action");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('hover_action registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "hover_action");
      final alias = Map<String, dynamic>.from(vm.getAlias("hover_action")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('hover_action is discoverable by name query', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "hover_action");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hover_action is discoverable by alias description query', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "hover_action";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hover_action describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("hover_action", kind: 'alias');
      final described = vm.describeRegistryItem("hover_action", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "hover_action");
    });

    test('hover_action default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("hover_action")!);
      final entry = vm.registryEntry("hover_action", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('icon_button exists as an alias', () {
      final alias = vm.getAlias("icon_button");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('icon_button registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "icon_button");
      final alias = Map<String, dynamic>.from(vm.getAlias("icon_button")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('icon_button is discoverable by name query', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "icon_button");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('icon_button is discoverable by alias description query', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "icon_button";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('icon_button describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("icon_button", kind: 'alias');
      final described = vm.describeRegistryItem("icon_button", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "icon_button");
    });

    test('icon_button default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("icon_button")!);
      final entry = vm.registryEntry("icon_button", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chip exists as an alias', () {
      final alias = vm.getAlias("chip");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chip registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chip", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chip");
      final alias = Map<String, dynamic>.from(vm.getAlias("chip")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chip is discoverable by name query', () {
      final entry = vm.registryEntry("chip", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chip");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chip is discoverable by alias description query', () {
      final entry = vm.registryEntry("chip", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chip";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chip describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chip", kind: 'alias');
      final described = vm.describeRegistryItem("chip", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chip");
    });

    test('chip default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chip")!);
      final entry = vm.registryEntry("chip", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('badge exists as an alias', () {
      final alias = vm.getAlias("badge");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('badge registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("badge", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "badge");
      final alias = Map<String, dynamic>.from(vm.getAlias("badge")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('badge is discoverable by name query', () {
      final entry = vm.registryEntry("badge", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "badge");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('badge is discoverable by alias description query', () {
      final entry = vm.registryEntry("badge", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "badge";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('badge describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("badge", kind: 'alias');
      final described = vm.describeRegistryItem("badge", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "badge");
    });

    test('badge default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("badge")!);
      final entry = vm.registryEntry("badge", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('badge default props match source expectations', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("badge")!);
      expect(alias['props'], equals({"shape": "pill", "scale": "xs", "disabled": true}));
    });

  });
}

