import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("field");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('field alias contract', () {
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

    test('text_field exists as an alias', () {
      final alias = vm.getAlias("text_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('text_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("text_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "text_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("text_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('text_field is discoverable by name query', () {
      final entry = vm.registryEntry("text_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "text_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('text_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("text_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "text_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('text_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("text_field", kind: 'alias');
      final described = vm.describeRegistryItem("text_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "text_field");
    });

    test('text_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("text_field")!);
      final entry = vm.registryEntry("text_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('textarea exists as an alias', () {
      final alias = vm.getAlias("textarea");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('textarea registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("textarea", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "textarea");
      final alias = Map<String, dynamic>.from(vm.getAlias("textarea")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('textarea is discoverable by name query', () {
      final entry = vm.registryEntry("textarea", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "textarea");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('textarea is discoverable by alias description query', () {
      final entry = vm.registryEntry("textarea", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "textarea";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('textarea describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("textarea", kind: 'alias');
      final described = vm.describeRegistryItem("textarea", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "textarea");
    });

    test('textarea default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("textarea")!);
      final entry = vm.registryEntry("textarea", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('email_field exists as an alias', () {
      final alias = vm.getAlias("email_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('email_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("email_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "email_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("email_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('email_field is discoverable by name query', () {
      final entry = vm.registryEntry("email_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "email_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('email_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("email_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "email_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('email_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("email_field", kind: 'alias');
      final described = vm.describeRegistryItem("email_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "email_field");
    });

    test('email_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("email_field")!);
      final entry = vm.registryEntry("email_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('password_field exists as an alias', () {
      final alias = vm.getAlias("password_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('password_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("password_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "password_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("password_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('password_field is discoverable by name query', () {
      final entry = vm.registryEntry("password_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "password_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('password_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("password_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "password_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('password_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("password_field", kind: 'alias');
      final described = vm.describeRegistryItem("password_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "password_field");
    });

    test('password_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("password_field")!);
      final entry = vm.registryEntry("password_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('number_field exists as an alias', () {
      final alias = vm.getAlias("number_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('number_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("number_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "number_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("number_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('number_field is discoverable by name query', () {
      final entry = vm.registryEntry("number_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "number_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('number_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("number_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "number_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('number_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("number_field", kind: 'alias');
      final described = vm.describeRegistryItem("number_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "number_field");
    });

    test('number_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("number_field")!);
      final entry = vm.registryEntry("number_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('search_field exists as an alias', () {
      final alias = vm.getAlias("search_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('search_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("search_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "search_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("search_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('search_field is discoverable by name query', () {
      final entry = vm.registryEntry("search_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "search_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('search_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("search_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "search_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('search_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("search_field", kind: 'alias');
      final described = vm.describeRegistryItem("search_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "search_field");
    });

    test('search_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("search_field")!);
      final entry = vm.registryEntry("search_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('date_field exists as an alias', () {
      final alias = vm.getAlias("date_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('date_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("date_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "date_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("date_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('date_field is discoverable by name query', () {
      final entry = vm.registryEntry("date_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "date_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('date_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("date_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "date_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('date_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("date_field", kind: 'alias');
      final described = vm.describeRegistryItem("date_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "date_field");
    });

    test('date_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("date_field")!);
      final entry = vm.registryEntry("date_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('select_field exists as an alias', () {
      final alias = vm.getAlias("select_field");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('select_field registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("select_field", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "select_field");
      final alias = Map<String, dynamic>.from(vm.getAlias("select_field")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('select_field is discoverable by name query', () {
      final entry = vm.registryEntry("select_field", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "select_field");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('select_field is discoverable by alias description query', () {
      final entry = vm.registryEntry("select_field", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "select_field";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('select_field describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("select_field", kind: 'alias');
      final described = vm.describeRegistryItem("select_field", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "select_field");
    });

    test('select_field default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("select_field")!);
      final entry = vm.registryEntry("select_field", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('toggle exists as an alias', () {
      final alias = vm.getAlias("toggle");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('toggle registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("toggle", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "toggle");
      final alias = Map<String, dynamic>.from(vm.getAlias("toggle")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('toggle is discoverable by name query', () {
      final entry = vm.registryEntry("toggle", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "toggle");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('toggle is discoverable by alias description query', () {
      final entry = vm.registryEntry("toggle", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "toggle";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('toggle describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("toggle", kind: 'alias');
      final described = vm.describeRegistryItem("toggle", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "toggle");
    });

    test('toggle default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("toggle")!);
      final entry = vm.registryEntry("toggle", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('slider exists as an alias', () {
      final alias = vm.getAlias("slider");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('slider registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("slider", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "slider");
      final alias = Map<String, dynamic>.from(vm.getAlias("slider")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('slider is discoverable by name query', () {
      final entry = vm.registryEntry("slider", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "slider");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('slider is discoverable by alias description query', () {
      final entry = vm.registryEntry("slider", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "slider";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('slider describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("slider", kind: 'alias');
      final described = vm.describeRegistryItem("slider", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "slider");
    });

    test('slider default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("slider")!);
      final entry = vm.registryEntry("slider", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

  });
}

