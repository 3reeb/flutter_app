import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("box");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('box alias contract', () {
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

    test('row exists as an alias', () {
      final alias = vm.getAlias("row");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('row registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("row", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "row");
      final alias = Map<String, dynamic>.from(vm.getAlias("row")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('row is discoverable by name query', () {
      final entry = vm.registryEntry("row", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "row");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('row is discoverable by alias description query', () {
      final entry = vm.registryEntry("row", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "row";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('row describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("row", kind: 'alias');
      final described = vm.describeRegistryItem("row", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "row");
    });

    test('row default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("row")!);
      final entry = vm.registryEntry("row", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('col exists as an alias', () {
      final alias = vm.getAlias("col");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('col registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("col", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "col");
      final alias = Map<String, dynamic>.from(vm.getAlias("col")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('col is discoverable by name query', () {
      final entry = vm.registryEntry("col", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "col");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('col is discoverable by alias description query', () {
      final entry = vm.registryEntry("col", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "col";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('col describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("col", kind: 'alias');
      final described = vm.describeRegistryItem("col", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "col");
    });

    test('col default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("col")!);
      final entry = vm.registryEntry("col", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('stack exists as an alias', () {
      final alias = vm.getAlias("stack");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('stack registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("stack", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "stack");
      final alias = Map<String, dynamic>.from(vm.getAlias("stack")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('stack is discoverable by name query', () {
      final entry = vm.registryEntry("stack", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "stack");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('stack is discoverable by alias description query', () {
      final entry = vm.registryEntry("stack", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "stack";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('stack describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("stack", kind: 'alias');
      final described = vm.describeRegistryItem("stack", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "stack");
    });

    test('stack default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("stack")!);
      final entry = vm.registryEntry("stack", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('wrap exists as an alias', () {
      final alias = vm.getAlias("wrap");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('wrap registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("wrap", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "wrap");
      final alias = Map<String, dynamic>.from(vm.getAlias("wrap")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('wrap is discoverable by name query', () {
      final entry = vm.registryEntry("wrap", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "wrap");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('wrap is discoverable by alias description query', () {
      final entry = vm.registryEntry("wrap", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "wrap";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('wrap describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("wrap", kind: 'alias');
      final described = vm.describeRegistryItem("wrap", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "wrap");
    });

    test('wrap default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("wrap")!);
      final entry = vm.registryEntry("wrap", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('grid exists as an alias', () {
      final alias = vm.getAlias("grid");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('grid registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("grid", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "grid");
      final alias = Map<String, dynamic>.from(vm.getAlias("grid")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('grid is discoverable by name query', () {
      final entry = vm.registryEntry("grid", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "grid");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('grid is discoverable by alias description query', () {
      final entry = vm.registryEntry("grid", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "grid";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('grid describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("grid", kind: 'alias');
      final described = vm.describeRegistryItem("grid", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "grid");
    });

    test('grid default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("grid")!);
      final entry = vm.registryEntry("grid", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('masonry exists as an alias', () {
      final alias = vm.getAlias("masonry");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('masonry registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("masonry", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "masonry");
      final alias = Map<String, dynamic>.from(vm.getAlias("masonry")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('masonry is discoverable by name query', () {
      final entry = vm.registryEntry("masonry", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "masonry");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('masonry is discoverable by alias description query', () {
      final entry = vm.registryEntry("masonry", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "masonry";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('masonry describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("masonry", kind: 'alias');
      final described = vm.describeRegistryItem("masonry", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "masonry");
    });

    test('masonry default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("masonry")!);
      final entry = vm.registryEntry("masonry", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('card exists as an alias', () {
      final alias = vm.getAlias("card");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('card registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("card", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "card");
      final alias = Map<String, dynamic>.from(vm.getAlias("card")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('card is discoverable by name query', () {
      final entry = vm.registryEntry("card", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "card");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('card is discoverable by alias description query', () {
      final entry = vm.registryEntry("card", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "card";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('card describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("card", kind: 'alias');
      final described = vm.describeRegistryItem("card", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "card");
    });

    test('card default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("card")!);
      final entry = vm.registryEntry("card", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('split exists as an alias', () {
      final alias = vm.getAlias("split");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('split registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("split", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "split");
      final alias = Map<String, dynamic>.from(vm.getAlias("split")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('split is discoverable by name query', () {
      final entry = vm.registryEntry("split", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "split");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('split is discoverable by alias description query', () {
      final entry = vm.registryEntry("split", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "split";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('split describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("split", kind: 'alias');
      final described = vm.describeRegistryItem("split", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "split");
    });

    test('split default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("split")!);
      final entry = vm.registryEntry("split", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('morph exists as an alias', () {
      final alias = vm.getAlias("morph");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('morph registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("morph", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "morph");
      final alias = Map<String, dynamic>.from(vm.getAlias("morph")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('morph is discoverable by name query', () {
      final entry = vm.registryEntry("morph", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "morph");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('morph is discoverable by alias description query', () {
      final entry = vm.registryEntry("morph", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "morph";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('morph describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("morph", kind: 'alias');
      final described = vm.describeRegistryItem("morph", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "morph");
    });

    test('morph default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("morph")!);
      final entry = vm.registryEntry("morph", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('surface exists as an alias', () {
      final alias = vm.getAlias("surface");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('surface registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("surface", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "surface");
      final alias = Map<String, dynamic>.from(vm.getAlias("surface")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('surface is discoverable by name query', () {
      final entry = vm.registryEntry("surface", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "surface");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('surface is discoverable by alias description query', () {
      final entry = vm.registryEntry("surface", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "surface";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('surface describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("surface", kind: 'alias');
      final described = vm.describeRegistryItem("surface", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "surface");
    });

    test('surface default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("surface")!);
      final entry = vm.registryEntry("surface", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('shell exists as an alias', () {
      final alias = vm.getAlias("shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('shell is discoverable by name query', () {
      final entry = vm.registryEntry("shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("shell", kind: 'alias');
      final described = vm.describeRegistryItem("shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "shell");
    });

    test('shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("shell")!);
      final entry = vm.registryEntry("shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('viewport exists as an alias', () {
      final alias = vm.getAlias("viewport");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('viewport registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("viewport", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "viewport");
      final alias = Map<String, dynamic>.from(vm.getAlias("viewport")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('viewport is discoverable by name query', () {
      final entry = vm.registryEntry("viewport", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "viewport");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('viewport is discoverable by alias description query', () {
      final entry = vm.registryEntry("viewport", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "viewport";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('viewport describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("viewport", kind: 'alias');
      final described = vm.describeRegistryItem("viewport", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "viewport");
    });

    test('viewport default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("viewport")!);
      final entry = vm.registryEntry("viewport", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('responsive exists as an alias', () {
      final alias = vm.getAlias("responsive");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('responsive registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("responsive", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "responsive");
      final alias = Map<String, dynamic>.from(vm.getAlias("responsive")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('responsive is discoverable by name query', () {
      final entry = vm.registryEntry("responsive", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "responsive");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('responsive is discoverable by alias description query', () {
      final entry = vm.registryEntry("responsive", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "responsive";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('responsive describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("responsive", kind: 'alias');
      final described = vm.describeRegistryItem("responsive", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "responsive");
    });

    test('responsive default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("responsive")!);
      final entry = vm.registryEntry("responsive", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('measure exists as an alias', () {
      final alias = vm.getAlias("measure");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('measure registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("measure", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "measure");
      final alias = Map<String, dynamic>.from(vm.getAlias("measure")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('measure is discoverable by name query', () {
      final entry = vm.registryEntry("measure", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "measure");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('measure is discoverable by alias description query', () {
      final entry = vm.registryEntry("measure", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "measure";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('measure describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("measure", kind: 'alias');
      final described = vm.describeRegistryItem("measure", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "measure");
    });

    test('measure default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("measure")!);
      final entry = vm.registryEntry("measure", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('builder exists as an alias', () {
      final alias = vm.getAlias("builder");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('builder registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("builder", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "builder");
      final alias = Map<String, dynamic>.from(vm.getAlias("builder")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('builder is discoverable by name query', () {
      final entry = vm.registryEntry("builder", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "builder");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('builder is discoverable by alias description query', () {
      final entry = vm.registryEntry("builder", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "builder";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('builder describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("builder", kind: 'alias');
      final described = vm.describeRegistryItem("builder", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "builder");
    });

    test('builder default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("builder")!);
      final entry = vm.registryEntry("builder", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('layer exists as an alias', () {
      final alias = vm.getAlias("layer");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('layer registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("layer", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "layer");
      final alias = Map<String, dynamic>.from(vm.getAlias("layer")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('layer is discoverable by name query', () {
      final entry = vm.registryEntry("layer", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "layer");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('layer is discoverable by alias description query', () {
      final entry = vm.registryEntry("layer", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "layer";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('layer describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("layer", kind: 'alias');
      final described = vm.describeRegistryItem("layer", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "layer");
    });

    test('layer default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("layer")!);
      final entry = vm.registryEntry("layer", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('matrix exists as an alias', () {
      final alias = vm.getAlias("matrix");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('matrix registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("matrix", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "matrix");
      final alias = Map<String, dynamic>.from(vm.getAlias("matrix")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('matrix is discoverable by name query', () {
      final entry = vm.registryEntry("matrix", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "matrix");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('matrix is discoverable by alias description query', () {
      final entry = vm.registryEntry("matrix", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "matrix";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('matrix describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("matrix", kind: 'alias');
      final described = vm.describeRegistryItem("matrix", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "matrix");
    });

    test('matrix default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("matrix")!);
      final entry = vm.registryEntry("matrix", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

