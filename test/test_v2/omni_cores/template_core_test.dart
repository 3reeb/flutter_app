import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("template");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('template alias contract', () {
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

    test('menu exists as an alias', () {
      final alias = vm.getAlias("menu");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('menu registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("menu", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "menu");
      final alias = Map<String, dynamic>.from(vm.getAlias("menu")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('menu is discoverable by name query', () {
      final entry = vm.registryEntry("menu", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "menu");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('menu is discoverable by alias description query', () {
      final entry = vm.registryEntry("menu", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "menu";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('menu describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("menu", kind: 'alias');
      final described = vm.describeRegistryItem("menu", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "menu");
    });

    test('menu default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("menu")!);
      final entry = vm.registryEntry("menu", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('menu_item exists as an alias', () {
      final alias = vm.getAlias("menu_item");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('menu_item registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "menu_item");
      final alias = Map<String, dynamic>.from(vm.getAlias("menu_item")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('menu_item is discoverable by name query', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "menu_item");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('menu_item is discoverable by alias description query', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "menu_item";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('menu_item describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("menu_item", kind: 'alias');
      final described = vm.describeRegistryItem("menu_item", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "menu_item");
    });

    test('menu_item default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("menu_item")!);
      final entry = vm.registryEntry("menu_item", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('list exists as an alias', () {
      final alias = vm.getAlias("list");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('list registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("list", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "list");
      final alias = Map<String, dynamic>.from(vm.getAlias("list")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('list is discoverable by name query', () {
      final entry = vm.registryEntry("list", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "list");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('list is discoverable by alias description query', () {
      final entry = vm.registryEntry("list", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "list";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('list describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("list", kind: 'alias');
      final described = vm.describeRegistryItem("list", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "list");
    });

    test('list default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("list")!);
      final entry = vm.registryEntry("list", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('table exists as an alias', () {
      final alias = vm.getAlias("table");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('table registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("table", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "table");
      final alias = Map<String, dynamic>.from(vm.getAlias("table")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('table is discoverable by name query', () {
      final entry = vm.registryEntry("table", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "table");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('table is discoverable by alias description query', () {
      final entry = vm.registryEntry("table", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "table";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('table describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("table", kind: 'alias');
      final described = vm.describeRegistryItem("table", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "table");
    });

    test('table default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("table")!);
      final entry = vm.registryEntry("table", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('avatars exists as an alias', () {
      final alias = vm.getAlias("avatars");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('avatars registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("avatars", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "avatars");
      final alias = Map<String, dynamic>.from(vm.getAlias("avatars")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('avatars is discoverable by name query', () {
      final entry = vm.registryEntry("avatars", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "avatars");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatars is discoverable by alias description query', () {
      final entry = vm.registryEntry("avatars", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "avatars";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatars describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("avatars", kind: 'alias');
      final described = vm.describeRegistryItem("avatars", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "avatars");
    });

    test('avatars default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("avatars")!);
      final entry = vm.registryEntry("avatars", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('avatar_group exists as an alias', () {
      final alias = vm.getAlias("avatar_group");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('avatar_group registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "avatar_group");
      final alias = Map<String, dynamic>.from(vm.getAlias("avatar_group")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('avatar_group is discoverable by name query', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "avatar_group");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatar_group is discoverable by alias description query', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "avatar_group";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatar_group describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("avatar_group", kind: 'alias');
      final described = vm.describeRegistryItem("avatar_group", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "avatar_group");
    });

    test('avatar_group default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("avatar_group")!);
      final entry = vm.registryEntry("avatar_group", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('categories exists as an alias', () {
      final alias = vm.getAlias("categories");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('categories registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("categories", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "categories");
      final alias = Map<String, dynamic>.from(vm.getAlias("categories")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('categories is discoverable by name query', () {
      final entry = vm.registryEntry("categories", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "categories");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('categories is discoverable by alias description query', () {
      final entry = vm.registryEntry("categories", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "categories";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('categories describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("categories", kind: 'alias');
      final described = vm.describeRegistryItem("categories", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "categories");
    });

    test('categories default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("categories")!);
      final entry = vm.registryEntry("categories", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('category_browser exists as an alias', () {
      final alias = vm.getAlias("category_browser");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('category_browser registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "category_browser");
      final alias = Map<String, dynamic>.from(vm.getAlias("category_browser")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('category_browser is discoverable by name query', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "category_browser");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('category_browser is discoverable by alias description query', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "category_browser";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('category_browser describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("category_browser", kind: 'alias');
      final described = vm.describeRegistryItem("category_browser", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "category_browser");
    });

    test('category_browser default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("category_browser")!);
      final entry = vm.registryEntry("category_browser", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('rich_shell exists as an alias', () {
      final alias = vm.getAlias("rich_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('rich_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "rich_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("rich_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('rich_shell is discoverable by name query', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "rich_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('rich_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "rich_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('rich_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("rich_shell", kind: 'alias');
      final described = vm.describeRegistryItem("rich_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "rich_shell");
    });

    test('rich_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("rich_shell")!);
      final entry = vm.registryEntry("rich_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('rich_list exists as an alias', () {
      final alias = vm.getAlias("rich_list");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('rich_list registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "rich_list");
      final alias = Map<String, dynamic>.from(vm.getAlias("rich_list")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('rich_list is discoverable by name query', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "rich_list");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('rich_list is discoverable by alias description query', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "rich_list";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('rich_list describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("rich_list", kind: 'alias');
      final described = vm.describeRegistryItem("rich_list", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "rich_list");
    });

    test('rich_list default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("rich_list")!);
      final entry = vm.registryEntry("rich_list", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('rich_table exists as an alias', () {
      final alias = vm.getAlias("rich_table");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('rich_table registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "rich_table");
      final alias = Map<String, dynamic>.from(vm.getAlias("rich_table")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('rich_table is discoverable by name query', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "rich_table");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('rich_table is discoverable by alias description query', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "rich_table";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('rich_table describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("rich_table", kind: 'alias');
      final described = vm.describeRegistryItem("rich_table", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "rich_table");
    });

    test('rich_table default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("rich_table")!);
      final entry = vm.registryEntry("rich_table", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('tabs exists as an alias', () {
      final alias = vm.getAlias("tabs");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('tabs registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("tabs", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "tabs");
      final alias = Map<String, dynamic>.from(vm.getAlias("tabs")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('tabs is discoverable by name query', () {
      final entry = vm.registryEntry("tabs", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "tabs");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('tabs is discoverable by alias description query', () {
      final entry = vm.registryEntry("tabs", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "tabs";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('tabs describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("tabs", kind: 'alias');
      final described = vm.describeRegistryItem("tabs", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "tabs");
    });

    test('tabs default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("tabs")!);
      final entry = vm.registryEntry("tabs", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('data_shell exists as an alias', () {
      final alias = vm.getAlias("data_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('data_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "data_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("data_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('data_shell is discoverable by name query', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "data_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('data_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "data_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('data_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("data_shell", kind: 'alias');
      final described = vm.describeRegistryItem("data_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "data_shell");
    });

    test('data_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("data_shell")!);
      final entry = vm.registryEntry("data_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('wizard exists as an alias', () {
      final alias = vm.getAlias("wizard");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('wizard registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("wizard", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "wizard");
      final alias = Map<String, dynamic>.from(vm.getAlias("wizard")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('wizard is discoverable by name query', () {
      final entry = vm.registryEntry("wizard", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "wizard");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('wizard is discoverable by alias description query', () {
      final entry = vm.registryEntry("wizard", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "wizard";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('wizard describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("wizard", kind: 'alias');
      final described = vm.describeRegistryItem("wizard", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "wizard");
    });

    test('wizard default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("wizard")!);
      final entry = vm.registryEntry("wizard", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('empty_state exists as an alias', () {
      final alias = vm.getAlias("empty_state");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('empty_state registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "empty_state");
      final alias = Map<String, dynamic>.from(vm.getAlias("empty_state")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('empty_state is discoverable by name query', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "empty_state");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('empty_state is discoverable by alias description query', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "empty_state";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('empty_state describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("empty_state", kind: 'alias');
      final described = vm.describeRegistryItem("empty_state", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "empty_state");
    });

    test('empty_state default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("empty_state")!);
      final entry = vm.registryEntry("empty_state", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('error_state exists as an alias', () {
      final alias = vm.getAlias("error_state");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('error_state registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("error_state", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "error_state");
      final alias = Map<String, dynamic>.from(vm.getAlias("error_state")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('error_state is discoverable by name query', () {
      final entry = vm.registryEntry("error_state", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "error_state");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('error_state is discoverable by alias description query', () {
      final entry = vm.registryEntry("error_state", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "error_state";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('error_state describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("error_state", kind: 'alias');
      final described = vm.describeRegistryItem("error_state", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "error_state");
    });

    test('error_state default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("error_state")!);
      final entry = vm.registryEntry("error_state", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('profile_card exists as an alias', () {
      final alias = vm.getAlias("profile_card");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('profile_card registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "profile_card");
      final alias = Map<String, dynamic>.from(vm.getAlias("profile_card")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('profile_card is discoverable by name query', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "profile_card");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('profile_card is discoverable by alias description query', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "profile_card";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('profile_card describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("profile_card", kind: 'alias');
      final described = vm.describeRegistryItem("profile_card", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "profile_card");
    });

    test('profile_card default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("profile_card")!);
      final entry = vm.registryEntry("profile_card", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('flow_shell exists as an alias', () {
      final alias = vm.getAlias("flow_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('flow_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "flow_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("flow_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('flow_shell is discoverable by name query', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "flow_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('flow_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "flow_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('flow_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("flow_shell", kind: 'alias');
      final described = vm.describeRegistryItem("flow_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "flow_shell");
    });

    test('flow_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("flow_shell")!);
      final entry = vm.registryEntry("flow_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('hero_bridge exists as an alias', () {
      final alias = vm.getAlias("hero_bridge");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('hero_bridge registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "hero_bridge");
      final alias = Map<String, dynamic>.from(vm.getAlias("hero_bridge")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('hero_bridge is discoverable by name query', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "hero_bridge");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hero_bridge is discoverable by alias description query', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "hero_bridge";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('hero_bridge describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("hero_bridge", kind: 'alias');
      final described = vm.describeRegistryItem("hero_bridge", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "hero_bridge");
    });

    test('hero_bridge default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("hero_bridge")!);
      final entry = vm.registryEntry("hero_bridge", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('search_shell exists as an alias', () {
      final alias = vm.getAlias("search_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('search_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "search_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("search_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('search_shell is discoverable by name query', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "search_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('search_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "search_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('search_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("search_shell", kind: 'alias');
      final described = vm.describeRegistryItem("search_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "search_shell");
    });

    test('search_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("search_shell")!);
      final entry = vm.registryEntry("search_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_shell exists as an alias', () {
      final alias = vm.getAlias("field_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_shell is discoverable by name query', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_shell", kind: 'alias');
      final described = vm.describeRegistryItem("field_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_shell");
    });

    test('field_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_shell")!);
      final entry = vm.registryEntry("field_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_text exists as an alias', () {
      final alias = vm.getAlias("field_text");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_text registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_text", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_text");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_text")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_text is discoverable by name query', () {
      final entry = vm.registryEntry("field_text", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_text");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_text is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_text", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_text";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_text describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_text", kind: 'alias');
      final described = vm.describeRegistryItem("field_text", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_text");
    });

    test('field_text default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_text")!);
      final entry = vm.registryEntry("field_text", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_number exists as an alias', () {
      final alias = vm.getAlias("field_number");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_number registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_number", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_number");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_number")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_number is discoverable by name query', () {
      final entry = vm.registryEntry("field_number", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_number");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_number is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_number", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_number";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_number describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_number", kind: 'alias');
      final described = vm.describeRegistryItem("field_number", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_number");
    });

    test('field_number default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_number")!);
      final entry = vm.registryEntry("field_number", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_toggle exists as an alias', () {
      final alias = vm.getAlias("field_toggle");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_toggle registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_toggle");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_toggle")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_toggle is discoverable by name query', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_toggle");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_toggle is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_toggle";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_toggle describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_toggle", kind: 'alias');
      final described = vm.describeRegistryItem("field_toggle", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_toggle");
    });

    test('field_toggle default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_toggle")!);
      final entry = vm.registryEntry("field_toggle", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_slider exists as an alias', () {
      final alias = vm.getAlias("field_slider");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_slider registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_slider");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_slider")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_slider is discoverable by name query', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_slider");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_slider is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_slider";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_slider describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_slider", kind: 'alias');
      final described = vm.describeRegistryItem("field_slider", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_slider");
    });

    test('field_slider default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_slider")!);
      final entry = vm.registryEntry("field_slider", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_select exists as an alias', () {
      final alias = vm.getAlias("field_select");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_select registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_select", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_select");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_select")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_select is discoverable by name query', () {
      final entry = vm.registryEntry("field_select", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_select");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_select is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_select", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_select";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_select describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_select", kind: 'alias');
      final described = vm.describeRegistryItem("field_select", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_select");
    });

    test('field_select default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_select")!);
      final entry = vm.registryEntry("field_select", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_array exists as an alias', () {
      final alias = vm.getAlias("field_array");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_array registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_array", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_array");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_array")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_array is discoverable by name query', () {
      final entry = vm.registryEntry("field_array", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_array");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_array is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_array", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_array";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_array describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_array", kind: 'alias');
      final described = vm.describeRegistryItem("field_array", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_array");
    });

    test('field_array default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_array")!);
      final entry = vm.registryEntry("field_array", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_blocks exists as an alias', () {
      final alias = vm.getAlias("field_blocks");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_blocks registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_blocks");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_blocks")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_blocks is discoverable by name query', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_blocks");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_blocks is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_blocks";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_blocks describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_blocks", kind: 'alias');
      final described = vm.describeRegistryItem("field_blocks", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_blocks");
    });

    test('field_blocks default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_blocks")!);
      final entry = vm.registryEntry("field_blocks", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_data exists as an alias', () {
      final alias = vm.getAlias("field_data");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_data registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_data", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_data");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_data")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_data is discoverable by name query', () {
      final entry = vm.registryEntry("field_data", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_data");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_data is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_data", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_data";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_data describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_data", kind: 'alias');
      final described = vm.describeRegistryItem("field_data", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_data");
    });

    test('field_data default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_data")!);
      final entry = vm.registryEntry("field_data", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_lookup exists as an alias', () {
      final alias = vm.getAlias("field_lookup");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_lookup registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_lookup");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_lookup")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_lookup is discoverable by name query', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_lookup");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_lookup is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_lookup";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_lookup describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_lookup", kind: 'alias');
      final described = vm.describeRegistryItem("field_lookup", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_lookup");
    });

    test('field_lookup default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_lookup")!);
      final entry = vm.registryEntry("field_lookup", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_relation exists as an alias', () {
      final alias = vm.getAlias("field_relation");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_relation registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_relation");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_relation")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_relation is discoverable by name query', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_relation");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_relation is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_relation";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_relation describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_relation", kind: 'alias');
      final described = vm.describeRegistryItem("field_relation", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_relation");
    });

    test('field_relation default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_relation")!);
      final entry = vm.registryEntry("field_relation", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('field_shell_stacked exists as an alias', () {
      final alias = vm.getAlias("field_shell_stacked");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('field_shell_stacked registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "field_shell_stacked");
      final alias = Map<String, dynamic>.from(vm.getAlias("field_shell_stacked")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('field_shell_stacked is discoverable by name query', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "field_shell_stacked");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_shell_stacked is discoverable by alias description query', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "field_shell_stacked";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('field_shell_stacked describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias');
      final described = vm.describeRegistryItem("field_shell_stacked", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "field_shell_stacked");
    });

    test('field_shell_stacked default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("field_shell_stacked")!);
      final entry = vm.registryEntry("field_shell_stacked", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('popover_shell exists as an alias', () {
      final alias = vm.getAlias("popover_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('popover_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "popover_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("popover_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('popover_shell is discoverable by name query', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "popover_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('popover_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "popover_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('popover_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("popover_shell", kind: 'alias');
      final described = vm.describeRegistryItem("popover_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "popover_shell");
    });

    test('popover_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("popover_shell")!);
      final entry = vm.registryEntry("popover_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('surface_shell exists as an alias', () {
      final alias = vm.getAlias("surface_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('surface_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "surface_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("surface_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('surface_shell is discoverable by name query', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "surface_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('surface_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "surface_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('surface_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("surface_shell", kind: 'alias');
      final described = vm.describeRegistryItem("surface_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "surface_shell");
    });

    test('surface_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("surface_shell")!);
      final entry = vm.registryEntry("surface_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('item_shell exists as an alias', () {
      final alias = vm.getAlias("item_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('item_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "item_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("item_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('item_shell is discoverable by name query', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "item_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('item_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "item_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('item_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("item_shell", kind: 'alias');
      final described = vm.describeRegistryItem("item_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "item_shell");
    });

    test('item_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("item_shell")!);
      final entry = vm.registryEntry("item_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('cluster_shell exists as an alias', () {
      final alias = vm.getAlias("cluster_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('cluster_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "cluster_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("cluster_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('cluster_shell is discoverable by name query', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "cluster_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('cluster_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "cluster_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('cluster_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("cluster_shell", kind: 'alias');
      final described = vm.describeRegistryItem("cluster_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "cluster_shell");
    });

    test('cluster_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("cluster_shell")!);
      final entry = vm.registryEntry("cluster_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('split_shell exists as an alias', () {
      final alias = vm.getAlias("split_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('split_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "split_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("split_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('split_shell is discoverable by name query', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "split_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('split_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "split_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('split_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("split_shell", kind: 'alias');
      final described = vm.describeRegistryItem("split_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "split_shell");
    });

    test('split_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("split_shell")!);
      final entry = vm.registryEntry("split_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('state_shell exists as an alias', () {
      final alias = vm.getAlias("state_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('state_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "state_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("state_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('state_shell is discoverable by name query', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "state_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('state_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "state_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('state_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("state_shell", kind: 'alias');
      final described = vm.describeRegistryItem("state_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "state_shell");
    });

    test('state_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("state_shell")!);
      final entry = vm.registryEntry("state_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('overlay_shell exists as an alias', () {
      final alias = vm.getAlias("overlay_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('overlay_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "overlay_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("overlay_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('overlay_shell is discoverable by name query', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "overlay_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('overlay_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "overlay_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('overlay_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("overlay_shell", kind: 'alias');
      final described = vm.describeRegistryItem("overlay_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "overlay_shell");
    });

    test('overlay_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("overlay_shell")!);
      final entry = vm.registryEntry("overlay_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('control_shell exists as an alias', () {
      final alias = vm.getAlias("control_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('control_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "control_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("control_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('control_shell is discoverable by name query', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "control_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('control_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "control_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('control_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("control_shell", kind: 'alias');
      final described = vm.describeRegistryItem("control_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "control_shell");
    });

    test('control_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("control_shell")!);
      final entry = vm.registryEntry("control_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('media_shell exists as an alias', () {
      final alias = vm.getAlias("media_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_shell is discoverable by name query', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_shell", kind: 'alias');
      final described = vm.describeRegistryItem("media_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_shell");
    });

    test('media_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_shell")!);
      final entry = vm.registryEntry("media_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('navigation_shell exists as an alias', () {
      final alias = vm.getAlias("navigation_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('navigation_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "navigation_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("navigation_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('navigation_shell is discoverable by name query', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "navigation_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('navigation_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "navigation_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('navigation_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("navigation_shell", kind: 'alias');
      final described = vm.describeRegistryItem("navigation_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "navigation_shell");
    });

    test('navigation_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("navigation_shell")!);
      final entry = vm.registryEntry("navigation_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('segmented_control exists as an alias', () {
      final alias = vm.getAlias("segmented_control");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('segmented_control registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "segmented_control");
      final alias = Map<String, dynamic>.from(vm.getAlias("segmented_control")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('segmented_control is discoverable by name query', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "segmented_control");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('segmented_control is discoverable by alias description query', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "segmented_control";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('segmented_control describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("segmented_control", kind: 'alias');
      final described = vm.describeRegistryItem("segmented_control", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "segmented_control");
    });

    test('segmented_control default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("segmented_control")!);
      final entry = vm.registryEntry("segmented_control", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('accordion exists as an alias', () {
      final alias = vm.getAlias("accordion");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('accordion registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("accordion", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "accordion");
      final alias = Map<String, dynamic>.from(vm.getAlias("accordion")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('accordion is discoverable by name query', () {
      final entry = vm.registryEntry("accordion", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "accordion");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('accordion is discoverable by alias description query', () {
      final entry = vm.registryEntry("accordion", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "accordion";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('accordion describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("accordion", kind: 'alias');
      final described = vm.describeRegistryItem("accordion", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "accordion");
    });

    test('accordion default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("accordion")!);
      final entry = vm.registryEntry("accordion", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('carousel exists as an alias', () {
      final alias = vm.getAlias("carousel");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('carousel registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("carousel", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "carousel");
      final alias = Map<String, dynamic>.from(vm.getAlias("carousel")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('carousel is discoverable by name query', () {
      final entry = vm.registryEntry("carousel", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "carousel");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('carousel is discoverable by alias description query', () {
      final entry = vm.registryEntry("carousel", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "carousel";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('carousel describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("carousel", kind: 'alias');
      final described = vm.describeRegistryItem("carousel", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "carousel");
    });

    test('carousel default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("carousel")!);
      final entry = vm.registryEntry("carousel", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('stepper exists as an alias', () {
      final alias = vm.getAlias("stepper");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('stepper registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("stepper", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "stepper");
      final alias = Map<String, dynamic>.from(vm.getAlias("stepper")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('stepper is discoverable by name query', () {
      final entry = vm.registryEntry("stepper", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "stepper");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('stepper is discoverable by alias description query', () {
      final entry = vm.registryEntry("stepper", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "stepper";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('stepper describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("stepper", kind: 'alias');
      final described = vm.describeRegistryItem("stepper", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "stepper");
    });

    test('stepper default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("stepper")!);
      final entry = vm.registryEntry("stepper", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('search_panel exists as an alias', () {
      final alias = vm.getAlias("search_panel");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('search_panel registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "search_panel");
      final alias = Map<String, dynamic>.from(vm.getAlias("search_panel")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('search_panel is discoverable by name query', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "search_panel");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('search_panel is discoverable by alias description query', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "search_panel";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('search_panel describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("search_panel", kind: 'alias');
      final described = vm.describeRegistryItem("search_panel", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "search_panel");
    });

    test('search_panel default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("search_panel")!);
      final entry = vm.registryEntry("search_panel", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('collection_shell exists as an alias', () {
      final alias = vm.getAlias("collection_shell");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('collection_shell registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "collection_shell");
      final alias = Map<String, dynamic>.from(vm.getAlias("collection_shell")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('collection_shell is discoverable by name query', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "collection_shell");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('collection_shell is discoverable by alias description query', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "collection_shell";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('collection_shell describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("collection_shell", kind: 'alias');
      final described = vm.describeRegistryItem("collection_shell", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "collection_shell");
    });

    test('collection_shell default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("collection_shell")!);
      final entry = vm.registryEntry("collection_shell", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('form_panel exists as an alias', () {
      final alias = vm.getAlias("form_panel");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('form_panel registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "form_panel");
      final alias = Map<String, dynamic>.from(vm.getAlias("form_panel")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('form_panel is discoverable by name query', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "form_panel");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('form_panel is discoverable by alias description query', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "form_panel";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('form_panel describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("form_panel", kind: 'alias');
      final described = vm.describeRegistryItem("form_panel", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "form_panel");
    });

    test('form_panel default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("form_panel")!);
      final entry = vm.registryEntry("form_panel", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('master_detail exists as an alias', () {
      final alias = vm.getAlias("master_detail");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('master_detail registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "master_detail");
      final alias = Map<String, dynamic>.from(vm.getAlias("master_detail")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('master_detail is discoverable by name query', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "master_detail");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('master_detail is discoverable by alias description query', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "master_detail";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('master_detail describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("master_detail", kind: 'alias');
      final described = vm.describeRegistryItem("master_detail", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "master_detail");
    });

    test('master_detail default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("master_detail")!);
      final entry = vm.registryEntry("master_detail", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('command_bar exists as an alias', () {
      final alias = vm.getAlias("command_bar");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('command_bar registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "command_bar");
      final alias = Map<String, dynamic>.from(vm.getAlias("command_bar")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('command_bar is discoverable by name query', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "command_bar");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('command_bar is discoverable by alias description query', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "command_bar";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('command_bar describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("command_bar", kind: 'alias');
      final described = vm.describeRegistryItem("command_bar", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "command_bar");
    });

    test('command_bar default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("command_bar")!);
      final entry = vm.registryEntry("command_bar", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('media_card exists as an alias', () {
      final alias = vm.getAlias("media_card");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_card registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_card", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_card");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_card")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_card is discoverable by name query', () {
      final entry = vm.registryEntry("media_card", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_card");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_card is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_card", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_card";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_card describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_card", kind: 'alias');
      final described = vm.describeRegistryItem("media_card", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_card");
    });

    test('media_card default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_card")!);
      final entry = vm.registryEntry("media_card", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('product_card exists as an alias', () {
      final alias = vm.getAlias("product_card");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('product_card registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("product_card", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "product_card");
      final alias = Map<String, dynamic>.from(vm.getAlias("product_card")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('product_card is discoverable by name query', () {
      final entry = vm.registryEntry("product_card", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "product_card");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('product_card is discoverable by alias description query', () {
      final entry = vm.registryEntry("product_card", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "product_card";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('product_card describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("product_card", kind: 'alias');
      final described = vm.describeRegistryItem("product_card", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "product_card");
    });

    test('product_card default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("product_card")!);
      final entry = vm.registryEntry("product_card", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('transaction_row exists as an alias', () {
      final alias = vm.getAlias("transaction_row");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('transaction_row registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "transaction_row");
      final alias = Map<String, dynamic>.from(vm.getAlias("transaction_row")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('transaction_row is discoverable by name query', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "transaction_row");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('transaction_row is discoverable by alias description query', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "transaction_row";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('transaction_row describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("transaction_row", kind: 'alias');
      final described = vm.describeRegistryItem("transaction_row", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "transaction_row");
    });

    test('transaction_row default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("transaction_row")!);
      final entry = vm.registryEntry("transaction_row", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('payment_method exists as an alias', () {
      final alias = vm.getAlias("payment_method");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('payment_method registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "payment_method");
      final alias = Map<String, dynamic>.from(vm.getAlias("payment_method")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('payment_method is discoverable by name query', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "payment_method");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('payment_method is discoverable by alias description query', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "payment_method";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('payment_method describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("payment_method", kind: 'alias');
      final described = vm.describeRegistryItem("payment_method", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "payment_method");
    });

    test('payment_method default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("payment_method")!);
      final entry = vm.registryEntry("payment_method", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('feed_card exists as an alias', () {
      final alias = vm.getAlias("feed_card");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('feed_card registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "feed_card");
      final alias = Map<String, dynamic>.from(vm.getAlias("feed_card")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('feed_card is discoverable by name query', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "feed_card");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('feed_card is discoverable by alias description query', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "feed_card";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('feed_card describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("feed_card", kind: 'alias');
      final described = vm.describeRegistryItem("feed_card", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "feed_card");
    });

    test('feed_card default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("feed_card")!);
      final entry = vm.registryEntry("feed_card", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('state_surface exists as an alias', () {
      final alias = vm.getAlias("state_surface");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('state_surface registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "state_surface");
      final alias = Map<String, dynamic>.from(vm.getAlias("state_surface")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('state_surface is discoverable by name query', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "state_surface");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('state_surface is discoverable by alias description query', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "state_surface";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('state_surface describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("state_surface", kind: 'alias');
      final described = vm.describeRegistryItem("state_surface", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "state_surface");
    });

    test('state_surface default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("state_surface")!);
      final entry = vm.registryEntry("state_surface", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('metric_tile exists as an alias', () {
      final alias = vm.getAlias("metric_tile");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('metric_tile registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "metric_tile");
      final alias = Map<String, dynamic>.from(vm.getAlias("metric_tile")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('metric_tile is discoverable by name query', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "metric_tile");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('metric_tile is discoverable by alias description query', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "metric_tile";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('metric_tile describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("metric_tile", kind: 'alias');
      final described = vm.describeRegistryItem("metric_tile", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "metric_tile");
    });

    test('metric_tile default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("metric_tile")!);
      final entry = vm.registryEntry("metric_tile", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('nested_menu exists as an alias', () {
      final alias = vm.getAlias("nested_menu");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('nested_menu registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "nested_menu");
      final alias = Map<String, dynamic>.from(vm.getAlias("nested_menu")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('nested_menu is discoverable by name query', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "nested_menu");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('nested_menu is discoverable by alias description query', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "nested_menu";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('nested_menu describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("nested_menu", kind: 'alias');
      final described = vm.describeRegistryItem("nested_menu", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "nested_menu");
    });

    test('nested_menu default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("nested_menu")!);
      final entry = vm.registryEntry("nested_menu", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('list_item exists as an alias', () {
      final alias = vm.getAlias("list_item");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('list_item registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("list_item", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "list_item");
      final alias = Map<String, dynamic>.from(vm.getAlias("list_item")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('list_item is discoverable by name query', () {
      final entry = vm.registryEntry("list_item", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "list_item");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('list_item is discoverable by alias description query', () {
      final entry = vm.registryEntry("list_item", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "list_item";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('list_item describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("list_item", kind: 'alias');
      final described = vm.describeRegistryItem("list_item", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "list_item");
    });

    test('list_item default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("list_item")!);
      final entry = vm.registryEntry("list_item", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('table_row exists as an alias', () {
      final alias = vm.getAlias("table_row");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('table_row registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("table_row", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "table_row");
      final alias = Map<String, dynamic>.from(vm.getAlias("table_row")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('table_row is discoverable by name query', () {
      final entry = vm.registryEntry("table_row", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "table_row");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('table_row is discoverable by alias description query', () {
      final entry = vm.registryEntry("table_row", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "table_row";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('table_row describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("table_row", kind: 'alias');
      final described = vm.describeRegistryItem("table_row", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "table_row");
    });

    test('table_row default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("table_row")!);
      final entry = vm.registryEntry("table_row", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('avatar_item exists as an alias', () {
      final alias = vm.getAlias("avatar_item");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('avatar_item registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "avatar_item");
      final alias = Map<String, dynamic>.from(vm.getAlias("avatar_item")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('avatar_item is discoverable by name query', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "avatar_item");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatar_item is discoverable by alias description query', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "avatar_item";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatar_item describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("avatar_item", kind: 'alias');
      final described = vm.describeRegistryItem("avatar_item", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "avatar_item");
    });

    test('avatar_item default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("avatar_item")!);
      final entry = vm.registryEntry("avatar_item", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

