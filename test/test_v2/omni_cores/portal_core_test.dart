import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("portal");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('portal alias contract', () {
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

    test('overlay_entry exists as an alias', () {
      final alias = vm.getAlias("overlay_entry");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('overlay_entry registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "overlay_entry");
      final alias = Map<String, dynamic>.from(vm.getAlias("overlay_entry")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('overlay_entry is discoverable by name query', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "overlay_entry");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('overlay_entry is discoverable by alias description query', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "overlay_entry";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('overlay_entry describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("overlay_entry", kind: 'alias');
      final described = vm.describeRegistryItem("overlay_entry", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "overlay_entry");
    });

    test('overlay_entry default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("overlay_entry")!);
      final entry = vm.registryEntry("overlay_entry", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('overlay exists as an alias', () {
      final alias = vm.getAlias("overlay");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('overlay registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("overlay", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "overlay");
      final alias = Map<String, dynamic>.from(vm.getAlias("overlay")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('overlay is discoverable by name query', () {
      final entry = vm.registryEntry("overlay", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "overlay");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('overlay is discoverable by alias description query', () {
      final entry = vm.registryEntry("overlay", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "overlay";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('overlay describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("overlay", kind: 'alias');
      final described = vm.describeRegistryItem("overlay", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "overlay");
    });

    test('overlay default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("overlay")!);
      final entry = vm.registryEntry("overlay", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('dialog exists as an alias', () {
      final alias = vm.getAlias("dialog");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('dialog registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("dialog", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "dialog");
      final alias = Map<String, dynamic>.from(vm.getAlias("dialog")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('dialog is discoverable by name query', () {
      final entry = vm.registryEntry("dialog", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "dialog");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('dialog is discoverable by alias description query', () {
      final entry = vm.registryEntry("dialog", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "dialog";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('dialog describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("dialog", kind: 'alias');
      final described = vm.describeRegistryItem("dialog", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "dialog");
    });

    test('dialog default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("dialog")!);
      final entry = vm.registryEntry("dialog", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('drawer exists as an alias', () {
      final alias = vm.getAlias("drawer");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('drawer registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("drawer", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "drawer");
      final alias = Map<String, dynamic>.from(vm.getAlias("drawer")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('drawer is discoverable by name query', () {
      final entry = vm.registryEntry("drawer", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "drawer");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('drawer is discoverable by alias description query', () {
      final entry = vm.registryEntry("drawer", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "drawer";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('drawer describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("drawer", kind: 'alias');
      final described = vm.describeRegistryItem("drawer", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "drawer");
    });

    test('drawer default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("drawer")!);
      final entry = vm.registryEntry("drawer", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('sheet exists as an alias', () {
      final alias = vm.getAlias("sheet");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sheet registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sheet", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sheet");
      final alias = Map<String, dynamic>.from(vm.getAlias("sheet")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sheet is discoverable by name query', () {
      final entry = vm.registryEntry("sheet", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sheet");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sheet is discoverable by alias description query', () {
      final entry = vm.registryEntry("sheet", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sheet";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sheet describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sheet", kind: 'alias');
      final described = vm.describeRegistryItem("sheet", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sheet");
    });

    test('sheet default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sheet")!);
      final entry = vm.registryEntry("sheet", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('popover exists as an alias', () {
      final alias = vm.getAlias("popover");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('popover registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("popover", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "popover");
      final alias = Map<String, dynamic>.from(vm.getAlias("popover")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('popover is discoverable by name query', () {
      final entry = vm.registryEntry("popover", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "popover");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('popover is discoverable by alias description query', () {
      final entry = vm.registryEntry("popover", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "popover";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('popover describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("popover", kind: 'alias');
      final described = vm.describeRegistryItem("popover", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "popover");
    });

    test('popover default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("popover")!);
      final entry = vm.registryEntry("popover", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

