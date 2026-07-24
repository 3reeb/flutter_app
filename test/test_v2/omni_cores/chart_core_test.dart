import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("chart");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('chart alias contract', () {
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

    test('chart exists as an alias', () {
      final alias = vm.getAlias("chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart is discoverable by name query', () {
      final entry = vm.registryEntry("chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart", kind: 'alias');
      final described = vm.describeRegistryItem("chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart");
    });

    test('chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart")!);
      final entry = vm.registryEntry("chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('line exists as an alias', () {
      final alias = vm.getAlias("line");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('line registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("line", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "line");
      final alias = Map<String, dynamic>.from(vm.getAlias("line")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('line is discoverable by name query', () {
      final entry = vm.registryEntry("line", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "line");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('line is discoverable by alias description query', () {
      final entry = vm.registryEntry("line", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "line";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('line describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("line", kind: 'alias');
      final described = vm.describeRegistryItem("line", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "line");
    });

    test('line default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("line")!);
      final entry = vm.registryEntry("line", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_line exists as an alias', () {
      final alias = vm.getAlias("chart_line");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_line registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_line");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_line")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_line is discoverable by name query', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_line");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_line is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_line";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_line describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_line", kind: 'alias');
      final described = vm.describeRegistryItem("chart_line", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_line");
    });

    test('chart_line default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_line")!);
      final entry = vm.registryEntry("chart_line", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('line_chart exists as an alias', () {
      final alias = vm.getAlias("line_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('line_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "line_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("line_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('line_chart is discoverable by name query', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "line_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('line_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "line_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('line_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("line_chart", kind: 'alias');
      final described = vm.describeRegistryItem("line_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "line_chart");
    });

    test('line_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("line_chart")!);
      final entry = vm.registryEntry("line_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_line_chart exists as an alias', () {
      final alias = vm.getAlias("media_line_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_line_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_line_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_line_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_line_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_line_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_line_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_line_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_line_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_line_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_line_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_line_chart");
    });

    test('media_line_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_line_chart")!);
      final entry = vm.registryEntry("media_line_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('bar exists as an alias', () {
      final alias = vm.getAlias("bar");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('bar registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("bar", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "bar");
      final alias = Map<String, dynamic>.from(vm.getAlias("bar")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('bar is discoverable by name query', () {
      final entry = vm.registryEntry("bar", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "bar");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bar is discoverable by alias description query', () {
      final entry = vm.registryEntry("bar", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "bar";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bar describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("bar", kind: 'alias');
      final described = vm.describeRegistryItem("bar", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "bar");
    });

    test('bar default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("bar")!);
      final entry = vm.registryEntry("bar", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_bar exists as an alias', () {
      final alias = vm.getAlias("chart_bar");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_bar registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_bar");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_bar")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_bar is discoverable by name query', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_bar");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_bar is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_bar";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_bar describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_bar", kind: 'alias');
      final described = vm.describeRegistryItem("chart_bar", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_bar");
    });

    test('chart_bar default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_bar")!);
      final entry = vm.registryEntry("chart_bar", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('bar_chart exists as an alias', () {
      final alias = vm.getAlias("bar_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('bar_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "bar_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("bar_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('bar_chart is discoverable by name query', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "bar_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bar_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "bar_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bar_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("bar_chart", kind: 'alias');
      final described = vm.describeRegistryItem("bar_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "bar_chart");
    });

    test('bar_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("bar_chart")!);
      final entry = vm.registryEntry("bar_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_bar_chart exists as an alias', () {
      final alias = vm.getAlias("media_bar_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_bar_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_bar_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_bar_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_bar_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_bar_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_bar_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_bar_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_bar_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_bar_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_bar_chart");
    });

    test('media_bar_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_bar_chart")!);
      final entry = vm.registryEntry("media_bar_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('area exists as an alias', () {
      final alias = vm.getAlias("area");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('area registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("area", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "area");
      final alias = Map<String, dynamic>.from(vm.getAlias("area")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('area is discoverable by name query', () {
      final entry = vm.registryEntry("area", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "area");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('area is discoverable by alias description query', () {
      final entry = vm.registryEntry("area", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "area";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('area describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("area", kind: 'alias');
      final described = vm.describeRegistryItem("area", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "area");
    });

    test('area default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("area")!);
      final entry = vm.registryEntry("area", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_area exists as an alias', () {
      final alias = vm.getAlias("chart_area");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_area registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_area");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_area")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_area is discoverable by name query', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_area");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_area is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_area";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_area describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_area", kind: 'alias');
      final described = vm.describeRegistryItem("chart_area", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_area");
    });

    test('chart_area default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_area")!);
      final entry = vm.registryEntry("chart_area", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('area_chart exists as an alias', () {
      final alias = vm.getAlias("area_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('area_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "area_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("area_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('area_chart is discoverable by name query', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "area_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('area_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "area_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('area_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("area_chart", kind: 'alias');
      final described = vm.describeRegistryItem("area_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "area_chart");
    });

    test('area_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("area_chart")!);
      final entry = vm.registryEntry("area_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_area_chart exists as an alias', () {
      final alias = vm.getAlias("media_area_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_area_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_area_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_area_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_area_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_area_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_area_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_area_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_area_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_area_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_area_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_area_chart");
    });

    test('media_area_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_area_chart")!);
      final entry = vm.registryEntry("media_area_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('pie exists as an alias', () {
      final alias = vm.getAlias("pie");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('pie registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("pie", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "pie");
      final alias = Map<String, dynamic>.from(vm.getAlias("pie")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('pie is discoverable by name query', () {
      final entry = vm.registryEntry("pie", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "pie");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('pie is discoverable by alias description query', () {
      final entry = vm.registryEntry("pie", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "pie";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('pie describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("pie", kind: 'alias');
      final described = vm.describeRegistryItem("pie", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "pie");
    });

    test('pie default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("pie")!);
      final entry = vm.registryEntry("pie", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_pie exists as an alias', () {
      final alias = vm.getAlias("chart_pie");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_pie registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_pie");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_pie")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_pie is discoverable by name query', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_pie");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_pie is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_pie";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_pie describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_pie", kind: 'alias');
      final described = vm.describeRegistryItem("chart_pie", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_pie");
    });

    test('chart_pie default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_pie")!);
      final entry = vm.registryEntry("chart_pie", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('pie_chart exists as an alias', () {
      final alias = vm.getAlias("pie_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('pie_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "pie_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("pie_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('pie_chart is discoverable by name query', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "pie_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('pie_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "pie_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('pie_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("pie_chart", kind: 'alias');
      final described = vm.describeRegistryItem("pie_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "pie_chart");
    });

    test('pie_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("pie_chart")!);
      final entry = vm.registryEntry("pie_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_pie_chart exists as an alias', () {
      final alias = vm.getAlias("media_pie_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_pie_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_pie_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_pie_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_pie_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_pie_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_pie_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_pie_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_pie_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_pie_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_pie_chart");
    });

    test('media_pie_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_pie_chart")!);
      final entry = vm.registryEntry("media_pie_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('donut exists as an alias', () {
      final alias = vm.getAlias("donut");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('donut registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("donut", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "donut");
      final alias = Map<String, dynamic>.from(vm.getAlias("donut")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('donut is discoverable by name query', () {
      final entry = vm.registryEntry("donut", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "donut");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('donut is discoverable by alias description query', () {
      final entry = vm.registryEntry("donut", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "donut";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('donut describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("donut", kind: 'alias');
      final described = vm.describeRegistryItem("donut", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "donut");
    });

    test('donut default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("donut")!);
      final entry = vm.registryEntry("donut", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_donut exists as an alias', () {
      final alias = vm.getAlias("chart_donut");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_donut registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_donut");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_donut")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_donut is discoverable by name query', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_donut");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_donut is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_donut";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_donut describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_donut", kind: 'alias');
      final described = vm.describeRegistryItem("chart_donut", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_donut");
    });

    test('chart_donut default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_donut")!);
      final entry = vm.registryEntry("chart_donut", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('donut_chart exists as an alias', () {
      final alias = vm.getAlias("donut_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('donut_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "donut_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("donut_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('donut_chart is discoverable by name query', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "donut_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('donut_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "donut_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('donut_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("donut_chart", kind: 'alias');
      final described = vm.describeRegistryItem("donut_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "donut_chart");
    });

    test('donut_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("donut_chart")!);
      final entry = vm.registryEntry("donut_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_donut_chart exists as an alias', () {
      final alias = vm.getAlias("media_donut_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_donut_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_donut_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_donut_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_donut_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_donut_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_donut_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_donut_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_donut_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_donut_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_donut_chart");
    });

    test('media_donut_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_donut_chart")!);
      final entry = vm.registryEntry("media_donut_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('radar exists as an alias', () {
      final alias = vm.getAlias("radar");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('radar registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("radar", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "radar");
      final alias = Map<String, dynamic>.from(vm.getAlias("radar")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('radar is discoverable by name query', () {
      final entry = vm.registryEntry("radar", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "radar");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('radar is discoverable by alias description query', () {
      final entry = vm.registryEntry("radar", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "radar";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('radar describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("radar", kind: 'alias');
      final described = vm.describeRegistryItem("radar", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "radar");
    });

    test('radar default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("radar")!);
      final entry = vm.registryEntry("radar", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_radar exists as an alias', () {
      final alias = vm.getAlias("chart_radar");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_radar registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_radar");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_radar")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_radar is discoverable by name query', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_radar");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_radar is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_radar";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_radar describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_radar", kind: 'alias');
      final described = vm.describeRegistryItem("chart_radar", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_radar");
    });

    test('chart_radar default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_radar")!);
      final entry = vm.registryEntry("chart_radar", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('radar_chart exists as an alias', () {
      final alias = vm.getAlias("radar_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('radar_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "radar_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("radar_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('radar_chart is discoverable by name query', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "radar_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('radar_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "radar_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('radar_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("radar_chart", kind: 'alias');
      final described = vm.describeRegistryItem("radar_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "radar_chart");
    });

    test('radar_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("radar_chart")!);
      final entry = vm.registryEntry("radar_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_radar_chart exists as an alias', () {
      final alias = vm.getAlias("media_radar_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_radar_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_radar_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_radar_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_radar_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_radar_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_radar_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_radar_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_radar_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_radar_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_radar_chart");
    });

    test('media_radar_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_radar_chart")!);
      final entry = vm.registryEntry("media_radar_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('scatter exists as an alias', () {
      final alias = vm.getAlias("scatter");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('scatter registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("scatter", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "scatter");
      final alias = Map<String, dynamic>.from(vm.getAlias("scatter")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('scatter is discoverable by name query', () {
      final entry = vm.registryEntry("scatter", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "scatter");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('scatter is discoverable by alias description query', () {
      final entry = vm.registryEntry("scatter", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "scatter";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('scatter describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("scatter", kind: 'alias');
      final described = vm.describeRegistryItem("scatter", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "scatter");
    });

    test('scatter default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("scatter")!);
      final entry = vm.registryEntry("scatter", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_scatter exists as an alias', () {
      final alias = vm.getAlias("chart_scatter");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_scatter registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_scatter");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_scatter")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_scatter is discoverable by name query', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_scatter");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_scatter is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_scatter";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_scatter describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_scatter", kind: 'alias');
      final described = vm.describeRegistryItem("chart_scatter", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_scatter");
    });

    test('chart_scatter default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_scatter")!);
      final entry = vm.registryEntry("chart_scatter", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('scatter_chart exists as an alias', () {
      final alias = vm.getAlias("scatter_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('scatter_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "scatter_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("scatter_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('scatter_chart is discoverable by name query', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "scatter_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('scatter_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "scatter_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('scatter_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("scatter_chart", kind: 'alias');
      final described = vm.describeRegistryItem("scatter_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "scatter_chart");
    });

    test('scatter_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("scatter_chart")!);
      final entry = vm.registryEntry("scatter_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_scatter_chart exists as an alias', () {
      final alias = vm.getAlias("media_scatter_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_scatter_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_scatter_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_scatter_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_scatter_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_scatter_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_scatter_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_scatter_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_scatter_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_scatter_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_scatter_chart");
    });

    test('media_scatter_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_scatter_chart")!);
      final entry = vm.registryEntry("media_scatter_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('bubble exists as an alias', () {
      final alias = vm.getAlias("bubble");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('bubble registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("bubble", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "bubble");
      final alias = Map<String, dynamic>.from(vm.getAlias("bubble")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('bubble is discoverable by name query', () {
      final entry = vm.registryEntry("bubble", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "bubble");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bubble is discoverable by alias description query', () {
      final entry = vm.registryEntry("bubble", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "bubble";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bubble describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("bubble", kind: 'alias');
      final described = vm.describeRegistryItem("bubble", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "bubble");
    });

    test('bubble default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("bubble")!);
      final entry = vm.registryEntry("bubble", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_bubble exists as an alias', () {
      final alias = vm.getAlias("chart_bubble");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_bubble registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_bubble");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_bubble")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_bubble is discoverable by name query', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_bubble");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_bubble is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_bubble";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_bubble describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_bubble", kind: 'alias');
      final described = vm.describeRegistryItem("chart_bubble", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_bubble");
    });

    test('chart_bubble default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_bubble")!);
      final entry = vm.registryEntry("chart_bubble", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('bubble_chart exists as an alias', () {
      final alias = vm.getAlias("bubble_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('bubble_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "bubble_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("bubble_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('bubble_chart is discoverable by name query', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "bubble_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bubble_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "bubble_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('bubble_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("bubble_chart", kind: 'alias');
      final described = vm.describeRegistryItem("bubble_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "bubble_chart");
    });

    test('bubble_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("bubble_chart")!);
      final entry = vm.registryEntry("bubble_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_bubble_chart exists as an alias', () {
      final alias = vm.getAlias("media_bubble_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_bubble_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_bubble_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_bubble_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_bubble_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_bubble_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_bubble_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_bubble_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_bubble_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_bubble_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_bubble_chart");
    });

    test('media_bubble_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_bubble_chart")!);
      final entry = vm.registryEntry("media_bubble_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('candlestick exists as an alias', () {
      final alias = vm.getAlias("candlestick");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('candlestick registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "candlestick");
      final alias = Map<String, dynamic>.from(vm.getAlias("candlestick")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('candlestick is discoverable by name query', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "candlestick");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('candlestick is discoverable by alias description query', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "candlestick";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('candlestick describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("candlestick", kind: 'alias');
      final described = vm.describeRegistryItem("candlestick", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "candlestick");
    });

    test('candlestick default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("candlestick")!);
      final entry = vm.registryEntry("candlestick", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_candlestick exists as an alias', () {
      final alias = vm.getAlias("chart_candlestick");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_candlestick registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_candlestick");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_candlestick")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_candlestick is discoverable by name query', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_candlestick");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_candlestick is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_candlestick";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_candlestick describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias');
      final described = vm.describeRegistryItem("chart_candlestick", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_candlestick");
    });

    test('chart_candlestick default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_candlestick")!);
      final entry = vm.registryEntry("chart_candlestick", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('candlestick_chart exists as an alias', () {
      final alias = vm.getAlias("candlestick_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('candlestick_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "candlestick_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("candlestick_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('candlestick_chart is discoverable by name query', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "candlestick_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('candlestick_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "candlestick_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('candlestick_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias');
      final described = vm.describeRegistryItem("candlestick_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "candlestick_chart");
    });

    test('candlestick_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("candlestick_chart")!);
      final entry = vm.registryEntry("candlestick_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_candlestick_chart exists as an alias', () {
      final alias = vm.getAlias("media_candlestick_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_candlestick_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_candlestick_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_candlestick_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_candlestick_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_candlestick_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_candlestick_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_candlestick_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_candlestick_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_candlestick_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_candlestick_chart");
    });

    test('media_candlestick_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_candlestick_chart")!);
      final entry = vm.registryEntry("media_candlestick_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('funnel exists as an alias', () {
      final alias = vm.getAlias("funnel");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('funnel registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("funnel", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "funnel");
      final alias = Map<String, dynamic>.from(vm.getAlias("funnel")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('funnel is discoverable by name query', () {
      final entry = vm.registryEntry("funnel", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "funnel");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('funnel is discoverable by alias description query', () {
      final entry = vm.registryEntry("funnel", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "funnel";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('funnel describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("funnel", kind: 'alias');
      final described = vm.describeRegistryItem("funnel", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "funnel");
    });

    test('funnel default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("funnel")!);
      final entry = vm.registryEntry("funnel", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_funnel exists as an alias', () {
      final alias = vm.getAlias("chart_funnel");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_funnel registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_funnel");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_funnel")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_funnel is discoverable by name query', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_funnel");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_funnel is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_funnel";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_funnel describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_funnel", kind: 'alias');
      final described = vm.describeRegistryItem("chart_funnel", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_funnel");
    });

    test('chart_funnel default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_funnel")!);
      final entry = vm.registryEntry("chart_funnel", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('funnel_chart exists as an alias', () {
      final alias = vm.getAlias("funnel_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('funnel_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "funnel_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("funnel_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('funnel_chart is discoverable by name query', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "funnel_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('funnel_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "funnel_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('funnel_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("funnel_chart", kind: 'alias');
      final described = vm.describeRegistryItem("funnel_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "funnel_chart");
    });

    test('funnel_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("funnel_chart")!);
      final entry = vm.registryEntry("funnel_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_funnel_chart exists as an alias', () {
      final alias = vm.getAlias("media_funnel_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_funnel_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_funnel_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_funnel_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_funnel_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_funnel_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_funnel_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_funnel_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_funnel_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_funnel_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_funnel_chart");
    });

    test('media_funnel_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_funnel_chart")!);
      final entry = vm.registryEntry("media_funnel_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('waterfall exists as an alias', () {
      final alias = vm.getAlias("waterfall");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('waterfall registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "waterfall");
      final alias = Map<String, dynamic>.from(vm.getAlias("waterfall")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('waterfall is discoverable by name query', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "waterfall");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('waterfall is discoverable by alias description query', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "waterfall";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('waterfall describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("waterfall", kind: 'alias');
      final described = vm.describeRegistryItem("waterfall", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "waterfall");
    });

    test('waterfall default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("waterfall")!);
      final entry = vm.registryEntry("waterfall", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_waterfall exists as an alias', () {
      final alias = vm.getAlias("chart_waterfall");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_waterfall registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_waterfall");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_waterfall")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_waterfall is discoverable by name query', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_waterfall");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_waterfall is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_waterfall";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_waterfall describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias');
      final described = vm.describeRegistryItem("chart_waterfall", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_waterfall");
    });

    test('chart_waterfall default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_waterfall")!);
      final entry = vm.registryEntry("chart_waterfall", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('waterfall_chart exists as an alias', () {
      final alias = vm.getAlias("waterfall_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('waterfall_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "waterfall_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("waterfall_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('waterfall_chart is discoverable by name query', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "waterfall_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('waterfall_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "waterfall_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('waterfall_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias');
      final described = vm.describeRegistryItem("waterfall_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "waterfall_chart");
    });

    test('waterfall_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("waterfall_chart")!);
      final entry = vm.registryEntry("waterfall_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_waterfall_chart exists as an alias', () {
      final alias = vm.getAlias("media_waterfall_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_waterfall_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_waterfall_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_waterfall_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_waterfall_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_waterfall_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_waterfall_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_waterfall_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_waterfall_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_waterfall_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_waterfall_chart");
    });

    test('media_waterfall_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_waterfall_chart")!);
      final entry = vm.registryEntry("media_waterfall_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('histogram exists as an alias', () {
      final alias = vm.getAlias("histogram");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('histogram registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("histogram", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "histogram");
      final alias = Map<String, dynamic>.from(vm.getAlias("histogram")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('histogram is discoverable by name query', () {
      final entry = vm.registryEntry("histogram", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "histogram");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('histogram is discoverable by alias description query', () {
      final entry = vm.registryEntry("histogram", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "histogram";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('histogram describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("histogram", kind: 'alias');
      final described = vm.describeRegistryItem("histogram", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "histogram");
    });

    test('histogram default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("histogram")!);
      final entry = vm.registryEntry("histogram", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_histogram exists as an alias', () {
      final alias = vm.getAlias("chart_histogram");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_histogram registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_histogram");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_histogram")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_histogram is discoverable by name query', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_histogram");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_histogram is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_histogram";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_histogram describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_histogram", kind: 'alias');
      final described = vm.describeRegistryItem("chart_histogram", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_histogram");
    });

    test('chart_histogram default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_histogram")!);
      final entry = vm.registryEntry("chart_histogram", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('histogram_chart exists as an alias', () {
      final alias = vm.getAlias("histogram_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('histogram_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "histogram_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("histogram_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('histogram_chart is discoverable by name query', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "histogram_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('histogram_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "histogram_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('histogram_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("histogram_chart", kind: 'alias');
      final described = vm.describeRegistryItem("histogram_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "histogram_chart");
    });

    test('histogram_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("histogram_chart")!);
      final entry = vm.registryEntry("histogram_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_histogram_chart exists as an alias', () {
      final alias = vm.getAlias("media_histogram_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_histogram_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_histogram_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_histogram_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_histogram_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_histogram_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_histogram_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_histogram_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_histogram_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_histogram_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_histogram_chart");
    });

    test('media_histogram_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_histogram_chart")!);
      final entry = vm.registryEntry("media_histogram_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('gauge exists as an alias', () {
      final alias = vm.getAlias("gauge");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('gauge registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("gauge", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "gauge");
      final alias = Map<String, dynamic>.from(vm.getAlias("gauge")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('gauge is discoverable by name query', () {
      final entry = vm.registryEntry("gauge", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "gauge");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('gauge is discoverable by alias description query', () {
      final entry = vm.registryEntry("gauge", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "gauge";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('gauge describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("gauge", kind: 'alias');
      final described = vm.describeRegistryItem("gauge", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "gauge");
    });

    test('gauge default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("gauge")!);
      final entry = vm.registryEntry("gauge", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_gauge exists as an alias', () {
      final alias = vm.getAlias("chart_gauge");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_gauge registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_gauge");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_gauge")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_gauge is discoverable by name query', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_gauge");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_gauge is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_gauge";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_gauge describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_gauge", kind: 'alias');
      final described = vm.describeRegistryItem("chart_gauge", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_gauge");
    });

    test('chart_gauge default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_gauge")!);
      final entry = vm.registryEntry("chart_gauge", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('gauge_chart exists as an alias', () {
      final alias = vm.getAlias("gauge_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('gauge_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "gauge_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("gauge_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('gauge_chart is discoverable by name query', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "gauge_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('gauge_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "gauge_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('gauge_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("gauge_chart", kind: 'alias');
      final described = vm.describeRegistryItem("gauge_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "gauge_chart");
    });

    test('gauge_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("gauge_chart")!);
      final entry = vm.registryEntry("gauge_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_gauge_chart exists as an alias', () {
      final alias = vm.getAlias("media_gauge_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_gauge_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_gauge_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_gauge_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_gauge_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_gauge_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_gauge_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_gauge_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_gauge_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_gauge_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_gauge_chart");
    });

    test('media_gauge_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_gauge_chart")!);
      final entry = vm.registryEntry("media_gauge_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('sparkline exists as an alias', () {
      final alias = vm.getAlias("sparkline");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sparkline registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sparkline");
      final alias = Map<String, dynamic>.from(vm.getAlias("sparkline")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sparkline is discoverable by name query', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sparkline");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sparkline is discoverable by alias description query', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sparkline";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sparkline describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sparkline", kind: 'alias');
      final described = vm.describeRegistryItem("sparkline", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sparkline");
    });

    test('sparkline default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sparkline")!);
      final entry = vm.registryEntry("sparkline", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_sparkline exists as an alias', () {
      final alias = vm.getAlias("chart_sparkline");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_sparkline registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_sparkline");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_sparkline")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_sparkline is discoverable by name query', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_sparkline");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_sparkline is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_sparkline";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_sparkline describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias');
      final described = vm.describeRegistryItem("chart_sparkline", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_sparkline");
    });

    test('chart_sparkline default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_sparkline")!);
      final entry = vm.registryEntry("chart_sparkline", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('sparkline_chart exists as an alias', () {
      final alias = vm.getAlias("sparkline_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sparkline_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sparkline_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("sparkline_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sparkline_chart is discoverable by name query', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sparkline_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sparkline_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sparkline_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sparkline_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias');
      final described = vm.describeRegistryItem("sparkline_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sparkline_chart");
    });

    test('sparkline_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sparkline_chart")!);
      final entry = vm.registryEntry("sparkline_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_sparkline_chart exists as an alias', () {
      final alias = vm.getAlias("media_sparkline_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_sparkline_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_sparkline_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_sparkline_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_sparkline_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_sparkline_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_sparkline_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_sparkline_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_sparkline_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_sparkline_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_sparkline_chart");
    });

    test('media_sparkline_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_sparkline_chart")!);
      final entry = vm.registryEntry("media_sparkline_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('treemap exists as an alias', () {
      final alias = vm.getAlias("treemap");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('treemap registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("treemap", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "treemap");
      final alias = Map<String, dynamic>.from(vm.getAlias("treemap")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('treemap is discoverable by name query', () {
      final entry = vm.registryEntry("treemap", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "treemap");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('treemap is discoverable by alias description query', () {
      final entry = vm.registryEntry("treemap", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "treemap";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('treemap describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("treemap", kind: 'alias');
      final described = vm.describeRegistryItem("treemap", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "treemap");
    });

    test('treemap default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("treemap")!);
      final entry = vm.registryEntry("treemap", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_treemap exists as an alias', () {
      final alias = vm.getAlias("chart_treemap");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_treemap registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_treemap");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_treemap")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_treemap is discoverable by name query', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_treemap");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_treemap is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_treemap";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_treemap describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_treemap", kind: 'alias');
      final described = vm.describeRegistryItem("chart_treemap", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_treemap");
    });

    test('chart_treemap default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_treemap")!);
      final entry = vm.registryEntry("chart_treemap", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('treemap_chart exists as an alias', () {
      final alias = vm.getAlias("treemap_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('treemap_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "treemap_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("treemap_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('treemap_chart is discoverable by name query', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "treemap_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('treemap_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "treemap_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('treemap_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("treemap_chart", kind: 'alias');
      final described = vm.describeRegistryItem("treemap_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "treemap_chart");
    });

    test('treemap_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("treemap_chart")!);
      final entry = vm.registryEntry("treemap_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_treemap_chart exists as an alias', () {
      final alias = vm.getAlias("media_treemap_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_treemap_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_treemap_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_treemap_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_treemap_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_treemap_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_treemap_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_treemap_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_treemap_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_treemap_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_treemap_chart");
    });

    test('media_treemap_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_treemap_chart")!);
      final entry = vm.registryEntry("media_treemap_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('sankey exists as an alias', () {
      final alias = vm.getAlias("sankey");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sankey registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sankey", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sankey");
      final alias = Map<String, dynamic>.from(vm.getAlias("sankey")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sankey is discoverable by name query', () {
      final entry = vm.registryEntry("sankey", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sankey");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sankey is discoverable by alias description query', () {
      final entry = vm.registryEntry("sankey", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sankey";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sankey describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sankey", kind: 'alias');
      final described = vm.describeRegistryItem("sankey", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sankey");
    });

    test('sankey default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sankey")!);
      final entry = vm.registryEntry("sankey", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('chart_sankey exists as an alias', () {
      final alias = vm.getAlias("chart_sankey");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('chart_sankey registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "chart_sankey");
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_sankey")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('chart_sankey is discoverable by name query', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "chart_sankey");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_sankey is discoverable by alias description query', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "chart_sankey";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('chart_sankey describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("chart_sankey", kind: 'alias');
      final described = vm.describeRegistryItem("chart_sankey", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "chart_sankey");
    });

    test('chart_sankey default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("chart_sankey")!);
      final entry = vm.registryEntry("chart_sankey", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('sankey_chart exists as an alias', () {
      final alias = vm.getAlias("sankey_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('sankey_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "sankey_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("sankey_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('sankey_chart is discoverable by name query', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "sankey_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sankey_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "sankey_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('sankey_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("sankey_chart", kind: 'alias');
      final described = vm.describeRegistryItem("sankey_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "sankey_chart");
    });

    test('sankey_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("sankey_chart")!);
      final entry = vm.registryEntry("sankey_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media_sankey_chart exists as an alias', () {
      final alias = vm.getAlias("media_sankey_chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media_sankey_chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media_sankey_chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media_sankey_chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media_sankey_chart is discoverable by name query', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media_sankey_chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_sankey_chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media_sankey_chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media_sankey_chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias');
      final described = vm.describeRegistryItem("media_sankey_chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media_sankey_chart");
    });

    test('media_sankey_chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media_sankey_chart")!);
      final entry = vm.registryEntry("media_sankey_chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media:chart exists as an alias', () {
      final alias = vm.getAlias("media:chart");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('media:chart registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "media:chart");
      final alias = Map<String, dynamic>.from(vm.getAlias("media:chart")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('media:chart is discoverable by name query', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "media:chart");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media:chart is discoverable by alias description query', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "media:chart";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('media:chart describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("media:chart", kind: 'alias');
      final described = vm.describeRegistryItem("media:chart", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "media:chart");
    });

    test('media:chart default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media:chart")!);
      final entry = vm.registryEntry("media:chart", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
      
    });

    test('media:chart default props match source expectations', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("media:chart")!);
      expect(alias['props'], equals({"chartType": "line"}));
    });

  });
}

