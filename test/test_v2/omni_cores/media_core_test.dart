import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';

void main() {
  final vm = bootstrapQuantum(includeConnect: false);

  final aliases = loadAliasGroup("media");
  final aliasNames = aliases.map((a) => a['name'] as String).toList(growable: false);

  setUpAll(() {
    // Idempotent bootstrap for this suite.
    bootstrapQuantum(includeConnect: false);
  });

  group('media alias contract', () {
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

    test('image exists as an alias', () {
      final alias = vm.getAlias("image");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('image registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("image", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "image");
      final alias = Map<String, dynamic>.from(vm.getAlias("image")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('image is discoverable by name query', () {
      final entry = vm.registryEntry("image", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "image");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('image is discoverable by alias description query', () {
      final entry = vm.registryEntry("image", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "image";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('image describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("image", kind: 'alias');
      final described = vm.describeRegistryItem("image", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "image");
    });

    test('image default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("image")!);
      final entry = vm.registryEntry("image", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('avatar exists as an alias', () {
      final alias = vm.getAlias("avatar");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('avatar registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("avatar", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "avatar");
      final alias = Map<String, dynamic>.from(vm.getAlias("avatar")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('avatar is discoverable by name query', () {
      final entry = vm.registryEntry("avatar", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "avatar");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatar is discoverable by alias description query', () {
      final entry = vm.registryEntry("avatar", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "avatar";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('avatar describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("avatar", kind: 'alias');
      final described = vm.describeRegistryItem("avatar", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "avatar");
    });

    test('avatar default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("avatar")!);
      final entry = vm.registryEntry("avatar", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
});

    test('video exists as an alias', () {
      final alias = vm.getAlias("video");
      expect(alias, isNotNull);
      expect(alias!['type'], isNotEmpty);
    });

    test('video registry entry mirrors alias bookkeeping', () {
      final entry = vm.registryEntry("video", kind: 'alias');
      expect(entry, isNotNull);
      expect(entry!.kind, 'alias');
      expect(entry.name, "video");
      final alias = Map<String, dynamic>.from(vm.getAlias("video")!);
      expect(entry.params['targetType'], alias['type']);
      expect(entry.params['defaultProps'], alias['props']);
    });

    test('video is discoverable by name query', () {
      final entry = vm.registryEntry("video", kind: 'alias');
      final results = vm.registryEntries(kind: 'alias', query: "video");
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('video is discoverable by alias description query', () {
      final entry = vm.registryEntry("video", kind: 'alias');
      final query = entry?.description.isNotEmpty == true ? entry!.description : "video";
      final results = vm.registryEntries(kind: 'alias', query: query);
      expect(results.any((e) => e.id == entry!.id), isTrue);
    });

    test('video describeRegistryItem stays aligned', () {
      final entry = vm.registryEntry("video", kind: 'alias');
      final described = vm.describeRegistryItem("video", kind: 'alias');
      expect(described, isNotNull);
      expect(described!['id'], entry!.id);
      expect(described['kind'], 'alias');
      expect(described['name'], "video");
    });

    test('video default props survive roundtrip', () {
      final alias = Map<String, dynamic>.from(vm.getAlias("video")!);
      final entry = vm.registryEntry("video", kind: 'alias')!;
      expect(alias['props'], equals(entry.params['defaultProps']));
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

  });
}

