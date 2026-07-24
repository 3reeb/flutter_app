import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("control");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('control alias contract', () {
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

    test('flow exists as an alias', () {
      final alias = vm.getAlias("flow");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('flow registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("flow", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "flow");
      final alias = Map<String, dynamic>.from(vm.getAlias("flow")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('flow is discoverable by name query', () {
      final entry = vm.registryEntry("flow", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "flow");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('flow is discoverable by alias description query', () {
      final entry = vm.registryEntry("flow", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "flow";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('flow describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("flow", kind: 'alias');
      final described = vm.describeRegistryItem("flow", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "flow");
    });

    test('flow default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("flow")!);
      final entry = vm.registryEntry("flow", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('workflow exists as an alias', () {
      final alias = vm.getAlias("workflow");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('workflow registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("workflow", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "workflow");
      final alias = Map<String, dynamic>.from(vm.getAlias("workflow")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('workflow is discoverable by name query', () {
      final entry = vm.registryEntry("workflow", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "workflow");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('workflow is discoverable by alias description query', () {
      final entry = vm.registryEntry("workflow", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "workflow";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('workflow describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("workflow", kind: 'alias');
      final described = vm.describeRegistryItem("workflow", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "workflow");
    });

    test('workflow default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("workflow")!);
      final entry = vm.registryEntry("workflow", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('form_scope exists as an alias', () {
      final alias = vm.getAlias("form_scope");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('form_scope registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "form_scope");
      final alias = Map<String, dynamic>.from(vm.getAlias("form_scope")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('form_scope is discoverable by name query', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "form_scope");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('form_scope is discoverable by alias description query', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "form_scope";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('form_scope describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("form_scope", kind: 'alias');
      final described = vm.describeRegistryItem("form_scope", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "form_scope");
    });

    test('form_scope default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("form_scope")!);
      final entry = vm.registryEntry("form_scope", kind: 'alias')!;
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

    test('segment exists as an alias', () {
      final alias = vm.getAlias("segment");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('segment registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("segment", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "segment");
      final alias = Map<String, dynamic>.from(vm.getAlias("segment")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('segment is discoverable by name query', () {
      final entry = vm.registryEntry("segment", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "segment");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('segment is discoverable by alias description query', () {
      final entry = vm.registryEntry("segment", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "segment";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('segment describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("segment", kind: 'alias');
      final described = vm.describeRegistryItem("segment", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "segment");
    });

    test('segment default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("segment")!);
      final entry = vm.registryEntry("segment", kind: 'alias')!;
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

  });
}

