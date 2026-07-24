import 'package:flutter_test/flutter_test.dart';

import '../support/quantum_test_support.dart';
import 'package:quantum_layout/quantum.dart';

String _normalize(String path) {
  return path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
}

void main() {
  final registry = QLCoreFileRegistry.instance;
  final cases = loadJsonList('core_file_cases.json', 'cases');

  setUpAll(() {
    bootstrapQuantum(includeConnect: true);
  });

  group('core file registry', () {
    test('folder mappings are bootstrapped', () {
      final snapshot = registry.snapshot();
      expect(snapshot['counts']['items'], isA<int>());
    });

    test('macros_built_in registers built-in and override descriptors', () {
      final expectedCore = "custom_macro";
      registry.registerBuiltIn(
        "/macros/case_01.yaml",
        core: "custom_macro",
        typeName: "case_01",
        metadata: {"case": 1, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_01");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_01");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/macros/case_01.yaml"));

      registry.registerOverride(
        "\\macros\\case_01.override.json",
        core: "custom_macro",
        typeName: "case_01",
        metadata: {"case": 1, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_01");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_01");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\macros\\case_01.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('macros_built_in resolves descriptors by key and path', () {
      final expectedCore = "custom_macro";
      final key = '$expectedCore::case_01';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_01");

      final fromPath = registry.descriptorForPath(
          "\\macros\\case_01.override.json",
          core: "custom_macro");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_01");
    });

    test('macros_built_in appears in snapshot output', () {
      final expectedCore = "custom_macro";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_01"), isTrue);
    });

    test('macros_override registers built-in and override descriptors', () {
      final expectedCore = "macro";
      registry.registerBuiltIn(
        "macros\\case_01_override.yaml",
        core: null,
        typeName: "case_01_override",
        metadata: {"case": 1, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_01_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_01_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("macros\\case_01_override.yaml"));

      registry.registerOverride(
        "macros/case_01_override.override.json",
        core: null,
        typeName: "case_01_override",
        metadata: {"case": 1, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_01_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_01_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("macros/case_01_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('macros_override resolves descriptors by key and path', () {
      final expectedCore = "macro";
      final key = '$expectedCore::case_01_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_01_override");

      final fromPath = registry.descriptorForPath(
          "macros/case_01_override.override.json",
          core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_01_override");
    });

    test('macros_override appears in snapshot output', () {
      final expectedCore = "macro";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_01_override"), isTrue);
    });

    test('templates_built_in registers built-in and override descriptors', () {
      final expectedCore = "alt_template";
      registry.registerBuiltIn(
        "/templates/case_02.yaml",
        core: "alt_template",
        typeName: "case_02",
        metadata: {"case": 2, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_02");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_02");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/templates/case_02.yaml"));

      registry.registerOverride(
        "\\templates\\case_02.override.json",
        core: "alt_template",
        typeName: "case_02",
        metadata: {"case": 2, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_02");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_02");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\templates\\case_02.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('templates_built_in resolves descriptors by key and path', () {
      final expectedCore = "alt_template";
      final key = '$expectedCore::case_02';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_02");

      final fromPath = registry.descriptorForPath(
          "\\templates\\case_02.override.json",
          core: "alt_template");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_02");
    });

    test('templates_built_in appears in snapshot output', () {
      final expectedCore = "alt_template";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_02"), isTrue);
    });

    test('templates_override registers built-in and override descriptors', () {
      final expectedCore = "custom_template";
      registry.registerBuiltIn(
        "templates\\case_02_override.yaml",
        core: "custom_template",
        typeName: "case_02_override",
        metadata: {"case": 2, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_02_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_02_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("templates\\case_02_override.yaml"));

      registry.registerOverride(
        "templates/case_02_override.override.json",
        core: "custom_template",
        typeName: "case_02_override",
        metadata: {"case": 2, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_02_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_02_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("templates/case_02_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('templates_override resolves descriptors by key and path', () {
      final expectedCore = "custom_template";
      final key = '$expectedCore::case_02_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_02_override");

      final fromPath = registry.descriptorForPath(
          "templates/case_02_override.override.json",
          core: "custom_template");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_02_override");
    });

    test('templates_override appears in snapshot output', () {
      final expectedCore = "custom_template";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_02_override"), isTrue);
    });

    test('layouts_built_in registers built-in and override descriptors', () {
      final expectedCore = "layout";
      registry.registerBuiltIn(
        "/layouts/case_03.yaml",
        core: null,
        typeName: "case_03",
        metadata: {"case": 3, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_03");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_03");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/layouts/case_03.yaml"));

      registry.registerOverride(
        "\\layouts\\case_03.override.json",
        core: null,
        typeName: "case_03",
        metadata: {"case": 3, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_03");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_03");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\layouts\\case_03.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('layouts_built_in resolves descriptors by key and path', () {
      final expectedCore = "layout";
      final key = '$expectedCore::case_03';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_03");

      final fromPath = registry
          .descriptorForPath("\\layouts\\case_03.override.json", core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_03");
    });

    test('layouts_built_in appears in snapshot output', () {
      final expectedCore = "layout";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_03"), isTrue);
    });

    test('layouts_override registers built-in and override descriptors', () {
      final expectedCore = "alt_layout";
      registry.registerBuiltIn(
        "layouts\\case_03_override.yaml",
        core: "alt_layout",
        typeName: "case_03_override",
        metadata: {"case": 3, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_03_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_03_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("layouts\\case_03_override.yaml"));

      registry.registerOverride(
        "layouts/case_03_override.override.json",
        core: "alt_layout",
        typeName: "case_03_override",
        metadata: {"case": 3, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_03_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_03_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("layouts/case_03_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('layouts_override resolves descriptors by key and path', () {
      final expectedCore = "alt_layout";
      final key = '$expectedCore::case_03_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_03_override");

      final fromPath = registry.descriptorForPath(
          "layouts/case_03_override.override.json",
          core: "alt_layout");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_03_override");
    });

    test('layouts_override appears in snapshot output', () {
      final expectedCore = "alt_layout";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_03_override"), isTrue);
    });

    test('actions_built_in registers built-in and override descriptors', () {
      final expectedCore = "custom_action";
      registry.registerBuiltIn(
        "/actions/case_04.yaml",
        core: "custom_action",
        typeName: "case_04",
        metadata: {"case": 4, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_04");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_04");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/actions/case_04.yaml"));

      registry.registerOverride(
        "\\actions\\case_04.override.json",
        core: "custom_action",
        typeName: "case_04",
        metadata: {"case": 4, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_04");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_04");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\actions\\case_04.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('actions_built_in resolves descriptors by key and path', () {
      final expectedCore = "custom_action";
      final key = '$expectedCore::case_04';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_04");

      final fromPath = registry.descriptorForPath(
          "\\actions\\case_04.override.json",
          core: "custom_action");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_04");
    });

    test('actions_built_in appears in snapshot output', () {
      final expectedCore = "custom_action";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_04"), isTrue);
    });

    test('actions_override registers built-in and override descriptors', () {
      final expectedCore = "action";
      registry.registerBuiltIn(
        "actions\\case_04_override.yaml",
        core: null,
        typeName: "case_04_override",
        metadata: {"case": 4, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_04_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_04_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("actions\\case_04_override.yaml"));

      registry.registerOverride(
        "actions/case_04_override.override.json",
        core: null,
        typeName: "case_04_override",
        metadata: {"case": 4, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_04_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_04_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("actions/case_04_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('actions_override resolves descriptors by key and path', () {
      final expectedCore = "action";
      final key = '$expectedCore::case_04_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_04_override");

      final fromPath = registry.descriptorForPath(
          "actions/case_04_override.override.json",
          core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_04_override");
    });

    test('actions_override appears in snapshot output', () {
      final expectedCore = "action";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_04_override"), isTrue);
    });

    test('fields_built_in registers built-in and override descriptors', () {
      final expectedCore = "alt_field";
      registry.registerBuiltIn(
        "/fields/case_05.yaml",
        core: "alt_field",
        typeName: "case_05",
        metadata: {"case": 5, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_05");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_05");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/fields/case_05.yaml"));

      registry.registerOverride(
        "\\fields\\case_05.override.json",
        core: "alt_field",
        typeName: "case_05",
        metadata: {"case": 5, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_05");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_05");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\fields\\case_05.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('fields_built_in resolves descriptors by key and path', () {
      final expectedCore = "alt_field";
      final key = '$expectedCore::case_05';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_05");

      final fromPath = registry.descriptorForPath(
          "\\fields\\case_05.override.json",
          core: "alt_field");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_05");
    });

    test('fields_built_in appears in snapshot output', () {
      final expectedCore = "alt_field";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_05"), isTrue);
    });

    test('fields_override registers built-in and override descriptors', () {
      final expectedCore = "custom_field";
      registry.registerBuiltIn(
        "fields\\case_05_override.yaml",
        core: "custom_field",
        typeName: "case_05_override",
        metadata: {"case": 5, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_05_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_05_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("fields\\case_05_override.yaml"));

      registry.registerOverride(
        "fields/case_05_override.override.json",
        core: "custom_field",
        typeName: "case_05_override",
        metadata: {"case": 5, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_05_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_05_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("fields/case_05_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('fields_override resolves descriptors by key and path', () {
      final expectedCore = "custom_field";
      final key = '$expectedCore::case_05_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_05_override");

      final fromPath = registry.descriptorForPath(
          "fields/case_05_override.override.json",
          core: "custom_field");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_05_override");
    });

    test('fields_override appears in snapshot output', () {
      final expectedCore = "custom_field";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_05_override"), isTrue);
    });

    test('media_built_in registers built-in and override descriptors', () {
      final expectedCore = "media";
      registry.registerBuiltIn(
        "/media/case_06.yaml",
        core: null,
        typeName: "case_06",
        metadata: {"case": 6, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_06");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_06");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/media/case_06.yaml"));

      registry.registerOverride(
        "\\media\\case_06.override.json",
        core: null,
        typeName: "case_06",
        metadata: {"case": 6, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_06");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_06");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(
          overrideDesc.assetPath, _normalize("\\media\\case_06.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('media_built_in resolves descriptors by key and path', () {
      final expectedCore = "media";
      final key = '$expectedCore::case_06';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_06");

      final fromPath = registry
          .descriptorForPath("\\media\\case_06.override.json", core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_06");
    });

    test('media_built_in appears in snapshot output', () {
      final expectedCore = "media";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_06"), isTrue);
    });

    test('media_override registers built-in and override descriptors', () {
      final expectedCore = "alt_media";
      registry.registerBuiltIn(
        "media\\case_06_override.yaml",
        core: "alt_media",
        typeName: "case_06_override",
        metadata: {"case": 6, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_06_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_06_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("media\\case_06_override.yaml"));

      registry.registerOverride(
        "media/case_06_override.override.json",
        core: "alt_media",
        typeName: "case_06_override",
        metadata: {"case": 6, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_06_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_06_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("media/case_06_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('media_override resolves descriptors by key and path', () {
      final expectedCore = "alt_media";
      final key = '$expectedCore::case_06_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_06_override");

      final fromPath = registry.descriptorForPath(
          "media/case_06_override.override.json",
          core: "alt_media");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_06_override");
    });

    test('media_override appears in snapshot output', () {
      final expectedCore = "alt_media";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_06_override"), isTrue);
    });

    test('portal_built_in registers built-in and override descriptors', () {
      final expectedCore = "custom_portal";
      registry.registerBuiltIn(
        "/portal/case_07.yaml",
        core: "custom_portal",
        typeName: "case_07",
        metadata: {"case": 7, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_07");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_07");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/portal/case_07.yaml"));

      registry.registerOverride(
        "\\portal\\case_07.override.json",
        core: "custom_portal",
        typeName: "case_07",
        metadata: {"case": 7, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_07");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_07");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\portal\\case_07.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('portal_built_in resolves descriptors by key and path', () {
      final expectedCore = "custom_portal";
      final key = '$expectedCore::case_07';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_07");

      final fromPath = registry.descriptorForPath(
          "\\portal\\case_07.override.json",
          core: "custom_portal");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_07");
    });

    test('portal_built_in appears in snapshot output', () {
      final expectedCore = "custom_portal";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_07"), isTrue);
    });

    test('portal_override registers built-in and override descriptors', () {
      final expectedCore = "portal";
      registry.registerBuiltIn(
        "portal\\case_07_override.yaml",
        core: null,
        typeName: "case_07_override",
        metadata: {"case": 7, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_07_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_07_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("portal\\case_07_override.yaml"));

      registry.registerOverride(
        "portal/case_07_override.override.json",
        core: null,
        typeName: "case_07_override",
        metadata: {"case": 7, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_07_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_07_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("portal/case_07_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('portal_override resolves descriptors by key and path', () {
      final expectedCore = "portal";
      final key = '$expectedCore::case_07_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_07_override");

      final fromPath = registry.descriptorForPath(
          "portal/case_07_override.override.json",
          core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_07_override");
    });

    test('portal_override appears in snapshot output', () {
      final expectedCore = "portal";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_07_override"), isTrue);
    });

    test('control_built_in registers built-in and override descriptors', () {
      final expectedCore = "alt_control";
      registry.registerBuiltIn(
        "/control/case_08.yaml",
        core: "alt_control",
        typeName: "case_08",
        metadata: {"case": 8, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_08");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_08");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/control/case_08.yaml"));

      registry.registerOverride(
        "\\control\\case_08.override.json",
        core: "alt_control",
        typeName: "case_08",
        metadata: {"case": 8, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_08");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_08");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\control\\case_08.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('control_built_in resolves descriptors by key and path', () {
      final expectedCore = "alt_control";
      final key = '$expectedCore::case_08';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_08");

      final fromPath = registry.descriptorForPath(
          "\\control\\case_08.override.json",
          core: "alt_control");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_08");
    });

    test('control_built_in appears in snapshot output', () {
      final expectedCore = "alt_control";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_08"), isTrue);
    });

    test('control_override registers built-in and override descriptors', () {
      final expectedCore = "custom_control";
      registry.registerBuiltIn(
        "control\\case_08_override.yaml",
        core: "custom_control",
        typeName: "case_08_override",
        metadata: {"case": 8, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_08_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_08_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("control\\case_08_override.yaml"));

      registry.registerOverride(
        "control/case_08_override.override.json",
        core: "custom_control",
        typeName: "case_08_override",
        metadata: {"case": 8, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_08_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_08_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("control/case_08_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('control_override resolves descriptors by key and path', () {
      final expectedCore = "custom_control";
      final key = '$expectedCore::case_08_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_08_override");

      final fromPath = registry.descriptorForPath(
          "control/case_08_override.override.json",
          core: "custom_control");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_08_override");
    });

    test('control_override appears in snapshot output', () {
      final expectedCore = "custom_control";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_08_override"), isTrue);
    });

    test('chart_built_in registers built-in and override descriptors', () {
      final expectedCore = "chart";
      registry.registerBuiltIn(
        "/chart/case_09.yaml",
        core: null,
        typeName: "case_09",
        metadata: {"case": 9, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_09");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_09");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/chart/case_09.yaml"));

      registry.registerOverride(
        "\\chart\\case_09.override.json",
        core: null,
        typeName: "case_09",
        metadata: {"case": 9, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_09");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_09");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(
          overrideDesc.assetPath, _normalize("\\chart\\case_09.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('chart_built_in resolves descriptors by key and path', () {
      final expectedCore = "chart";
      final key = '$expectedCore::case_09';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_09");

      final fromPath = registry
          .descriptorForPath("\\chart\\case_09.override.json", core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_09");
    });

    test('chart_built_in appears in snapshot output', () {
      final expectedCore = "chart";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_09"), isTrue);
    });

    test('chart_override registers built-in and override descriptors', () {
      final expectedCore = "alt_chart";
      registry.registerBuiltIn(
        "chart\\case_09_override.yaml",
        core: "alt_chart",
        typeName: "case_09_override",
        metadata: {"case": 9, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_09_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_09_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("chart\\case_09_override.yaml"));

      registry.registerOverride(
        "chart/case_09_override.override.json",
        core: "alt_chart",
        typeName: "case_09_override",
        metadata: {"case": 9, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_09_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_09_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("chart/case_09_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('chart_override resolves descriptors by key and path', () {
      final expectedCore = "alt_chart";
      final key = '$expectedCore::case_09_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_09_override");

      final fromPath = registry.descriptorForPath(
          "chart/case_09_override.override.json",
          core: "alt_chart");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_09_override");
    });

    test('chart_override appears in snapshot output', () {
      final expectedCore = "alt_chart";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_09_override"), isTrue);
    });

    test('animation_built_in registers built-in and override descriptors', () {
      final expectedCore = "custom_animation";
      registry.registerBuiltIn(
        "/animation/case_10.yaml",
        core: "custom_animation",
        typeName: "case_10",
        metadata: {"case": 10, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_10");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_10");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/animation/case_10.yaml"));

      registry.registerOverride(
        "\\animation\\case_10.override.json",
        core: "custom_animation",
        typeName: "case_10",
        metadata: {"case": 10, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_10");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_10");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\animation\\case_10.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('animation_built_in resolves descriptors by key and path', () {
      final expectedCore = "custom_animation";
      final key = '$expectedCore::case_10';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_10");

      final fromPath = registry.descriptorForPath(
          "\\animation\\case_10.override.json",
          core: "custom_animation");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_10");
    });

    test('animation_built_in appears in snapshot output', () {
      final expectedCore = "custom_animation";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_10"), isTrue);
    });

    test('animation_override registers built-in and override descriptors', () {
      final expectedCore = "animation";
      registry.registerBuiltIn(
        "animation\\case_10_override.yaml",
        core: null,
        typeName: "case_10_override",
        metadata: {"case": 10, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_10_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_10_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("animation\\case_10_override.yaml"));

      registry.registerOverride(
        "animation/case_10_override.override.json",
        core: null,
        typeName: "case_10_override",
        metadata: {"case": 10, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_10_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_10_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("animation/case_10_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('animation_override resolves descriptors by key and path', () {
      final expectedCore = "animation";
      final key = '$expectedCore::case_10_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_10_override");

      final fromPath = registry.descriptorForPath(
          "animation/case_10_override.override.json",
          core: null);
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_10_override");
    });

    test('animation_override appears in snapshot output', () {
      final expectedCore = "animation";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_10_override"), isTrue);
    });

    test('connect_built_in registers built-in and override descriptors', () {
      final expectedCore = "alt_connect";
      registry.registerBuiltIn(
        "/connect/case_11.yaml",
        core: "alt_connect",
        typeName: "case_11",
        metadata: {"case": 11, "phase": "built_in"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_11");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_11");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("/connect/case_11.yaml"));

      registry.registerOverride(
        "\\connect\\case_11.override.json",
        core: "alt_connect",
        typeName: "case_11",
        metadata: {"case": 11, "phase": "built_in"},
      );

      final overrideDesc = registry.descriptor(expectedCore, "case_11");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_11");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("\\connect\\case_11.override.json"));
      expect(overrideDesc.metadata['phase'], "built_in");
    });

    test('connect_built_in resolves descriptors by key and path', () {
      final expectedCore = "alt_connect";
      final key = '$expectedCore::case_11';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_11");

      final fromPath = registry.descriptorForPath(
          "\\connect\\case_11.override.json",
          core: "alt_connect");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_11");
    });

    test('connect_built_in appears in snapshot output', () {
      final expectedCore = "alt_connect";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_11"), isTrue);
    });

    test('connect_override registers built-in and override descriptors', () {
      final expectedCore = "custom_connect";
      registry.registerBuiltIn(
        "connect\\case_11_override.yaml",
        core: "custom_connect",
        typeName: "case_11_override",
        metadata: {"case": 11, "phase": "override"},
      );

      final builtIn = registry.descriptor(expectedCore, "case_11_override");
      expect(builtIn, isNotNull);
      expect(builtIn!.core, expectedCore);
      expect(builtIn.typeName, "case_11_override");
      expect(builtIn.builtIn, isTrue);
      expect(builtIn.source, 'built-in');
      expect(builtIn.assetPath, _normalize("connect\\case_11_override.yaml"));

      registry.registerOverride(
        "connect/case_11_override.override.json",
        core: "custom_connect",
        typeName: "case_11_override",
        metadata: {"case": 11, "phase": "override"},
      );

      final overrideDesc =
          registry.descriptor(expectedCore, "case_11_override");
      expect(overrideDesc, isNotNull);
      expect(overrideDesc!.core, expectedCore);
      expect(overrideDesc.typeName, "case_11_override");
      expect(overrideDesc.builtIn, isFalse);
      expect(overrideDesc.source, 'override');
      expect(overrideDesc.assetPath,
          _normalize("connect/case_11_override.override.json"));
      expect(overrideDesc.metadata['phase'], "override");
    });

    test('connect_override resolves descriptors by key and path', () {
      final expectedCore = "custom_connect";
      final key = '$expectedCore::case_11_override';
      final byKey = registry.descriptorByKey(key);
      expect(byKey, isNotNull);
      expect(byKey!.core, expectedCore);
      expect(byKey.typeName, "case_11_override");

      final fromPath = registry.descriptorForPath(
          "connect/case_11_override.override.json",
          core: "custom_connect");
      expect(fromPath, isNotNull);
      expect(fromPath!.core, expectedCore);
      expect(fromPath.typeName, "case_11_override");
    });

    test('connect_override appears in snapshot output', () {
      final expectedCore = "custom_connect";
      final snap = registry.snapshot(core: expectedCore);
      expect(snap['items'], isA<List>());
      final items = (snap['items'] as List).cast<Map>();
      expect(items.any((e) => e['name'] == "case_11_override"), isTrue);
    });
  });
}

