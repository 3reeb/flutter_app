// ════════════════════════════════════════════════════════════════════════════
// QUANTUM BOOT SCHEMA — schema-first, lazy-loaded file catalog
// quantum_boot_schema.dart
//
// Goal:
//   • one dev-facing boot config
//   • lazy file-backed loading for macros / templates / layouts / boxes
//   • no eager parse/define work during launch
//   • route discovery stays separate from page compilation
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../quantum.dart';
import '../runtime/quantum_core_schema_registry.dart';

@immutable
class QuantumBootSchema {
  final String appName;
  final String pagesDir;
  final Map<String, String> coreFolders;
  final Map<String, Map<String, String>> explicitFiles;
  final Map<String, Map<String, dynamic>> coreSchemas;
  final Map<String, Map<String, dynamic>> aliasSchemas;
  final Map<String, String> schemaFiles;
  final Map<String, String> aliasFiles;
  final List<Map<String, dynamic>> preload;
  final Map<String, dynamic> raw;

  QuantumBootSchema({
    required this.appName,
    this.pagesDir = 'pages',
    this.coreFolders = const {
      'macro': 'macros',
      'template': 'templates',
      'layout': 'layouts',
      'box': 'boxes',
      'action': 'actions',
      'field': 'fields',
      'text': 'text',
      'media': 'media',
      'data': 'data',
      'portal': 'portal',
      'control': 'control',
      'canvas': 'canvas',
      'system': 'system',
      'decoration': 'decoration',
    },
    this.explicitFiles = const {},
    this.coreSchemas = const {},
    this.aliasSchemas = const {},
    this.schemaFiles = const {},
    this.aliasFiles = const {},
    this.preload = const [],
    this.raw = const {},
  });

  factory QuantumBootSchema.fromMap(Map<String, dynamic> map,
      {String? appName}) {
    final dynamic coreSection =
        map['coreFolders'] ?? map['folders'] ?? map['roots'];
    final Map<String, String> folders = {};
    if (coreSection is Map) {
      coreSection.forEach((k, v) {
        final key = k.toString().trim();
        final value = v.toString().trim();
        if (key.isNotEmpty && value.isNotEmpty) folders[key] = value;
      });
    }

    final dynamic filesSection =
        map['files'] ?? map['catalog'] ?? map['overrides'];
    final Map<String, Map<String, String>> explicit = {};
    if (filesSection is Map) {
      filesSection.forEach((core, value) {
        if (value is Map) {
          explicit[core.toString()] = value.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          );
        }
      });
    }

    final Map<String, Map<String, dynamic>> coreSchemas = {};
    final dynamic schemasSection =
        map['schemas'] ?? map['coreSchemas'] ?? map['schemaCatalog'];
    if (schemasSection is Map) {
      schemasSection.forEach((name, value) {
        if (value is Map) {
          coreSchemas[name.toString()] =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
        }
      });
    }

    final Map<String, Map<String, dynamic>> aliasSchemas = {};
    final dynamic aliasSection = map['aliases'] ?? map['aliasSchemas'];
    if (aliasSection is Map) {
      aliasSection.forEach((name, value) {
        if (value is Map) {
          aliasSchemas[name.toString()] =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
        }
      });
    }

    final Map<String, String> schemaFiles = {};
    final dynamic schemaFilesSection = map['schemaFiles'];
    if (schemaFilesSection is Map) {
      schemaFilesSection.forEach((name, value) {
        final path = value?.toString().trim() ?? '';
        if (path.isNotEmpty) schemaFiles[name.toString()] = path;
      });
    }

    final Map<String, String> aliasFiles = {};
    final dynamic aliasFilesSection = map['aliasFiles'];
    if (aliasFilesSection is Map) {
      aliasFilesSection.forEach((name, value) {
        final path = value?.toString().trim() ?? '';
        if (path.isNotEmpty) aliasFiles[name.toString()] = path;
      });
    }

    final dynamic preloadSection = map['preload'] ?? map['warm'] ?? const [];
    final List<Map<String, dynamic>> preload = [];
    if (preloadSection is List) {
      for (final item in preloadSection) {
        if (item is Map) {
          preload.add(Map<String, dynamic>.from(item.cast<String, dynamic>()));
        }
      }
    }

    return QuantumBootSchema(
      appName: appName ?? map['appName']?.toString() ?? 'QuantumApp',
      pagesDir: map['pagesDir']?.toString() ?? 'pages',
      coreFolders: folders.isEmpty
          ? const {}
          : Map<String, String>.unmodifiable(folders),
      explicitFiles: explicit.isEmpty
          ? const {}
          : Map<String, Map<String, String>>.unmodifiable(explicit),
      coreSchemas: coreSchemas.isEmpty
          ? const {}
          : Map<String, Map<String, dynamic>>.unmodifiable(coreSchemas),
      aliasSchemas: aliasSchemas.isEmpty
          ? const {}
          : Map<String, Map<String, dynamic>>.unmodifiable(aliasSchemas),
      schemaFiles: schemaFiles.isEmpty
          ? const {}
          : Map<String, String>.unmodifiable(schemaFiles),
      aliasFiles: aliasFiles.isEmpty
          ? const {}
          : Map<String, String>.unmodifiable(aliasFiles),
      preload: List<Map<String, dynamic>>.unmodifiable(preload),
      raw: map,
    );
  }

  /// Register only the folder-to-core maps. Use this in synchronous boot
  /// paths that should avoid manifest scanning.
  void installDefaults() {
    QuantumCoreSchemaRegistry.instance.installDefaults(
      coreSchemas: coreSchemas,
      aliasSchemas: aliasSchemas,
      schemaFiles: schemaFiles,
      aliasFiles: aliasFiles,
    );

    final registry = QLCoreFileRegistry.instance;
    coreFolders.forEach(registry.registerFolder);
    explicitFiles.forEach((core, files) {
      for (final file in files.entries) {
        final assetPath = file.value.trim();
        if (assetPath.isEmpty) continue;
        registry.registerOverride(assetPath, core: core, typeName: file.key);
      }
    });
  }

  QuantumBootSchema copyWith({
    String? appName,
    String? pagesDir,
    Map<String, String>? coreFolders,
    Map<String, Map<String, String>>? explicitFiles,
    Map<String, Map<String, dynamic>>? coreSchemas,
    Map<String, Map<String, dynamic>>? aliasSchemas,
    Map<String, String>? schemaFiles,
    Map<String, String>? aliasFiles,
    List<Map<String, dynamic>>? preload,
    Map<String, dynamic>? raw,
  }) {
    return QuantumBootSchema(
      appName: appName ?? this.appName,
      pagesDir: pagesDir ?? this.pagesDir,
      coreFolders: coreFolders ?? this.coreFolders,
      explicitFiles: explicitFiles ?? this.explicitFiles,
      coreSchemas: coreSchemas ?? this.coreSchemas,
      aliasSchemas: aliasSchemas ?? this.aliasSchemas,
      schemaFiles: schemaFiles ?? this.schemaFiles,
      aliasFiles: aliasFiles ?? this.aliasFiles,
      preload: preload ?? this.preload,
      raw: raw ?? this.raw,
    );
  }

  /// Register folder-to-core mappings and the actual asset descriptors found in
  /// the Flutter asset manifest. This is cheap: it does not parse the files.
  Future<void> registerManifest(Map<String, dynamic> manifest) async {
    final registry = QLCoreFileRegistry.instance;

    // Folder mappings first so descriptor resolution works by core/name.
    coreFolders.forEach(registry.registerFolder);

    // Explicit file mappings override folder discovery.
    for (final entry in explicitFiles.entries) {
      final core = entry.key;
      for (final file in entry.value.entries) {
        final assetPath = file.value.trim();
        if (assetPath.isEmpty) continue;
        registry.registerOverride(assetPath, core: core, typeName: file.key);
      }
    }

    if (manifest.isEmpty) return;

    int seen = 0;
    for (final assetPath in manifest.keys) {
      final path = assetPath.toString();
      if (!_isSupportedFile(path)) continue;
      final core = _resolveCore(path);
      if (core == null) continue;
      final typeName = _resolveTypeName(path);
      registry.registerBuiltIn(path, core: core, typeName: typeName);
      if ((++seen & 0x7f) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  Future<Map<String, dynamic>?> load(String core, String typeName,
      {bool useCache = true}) {
    return QLCoreFileRegistry.instance
        .resolve(core, typeName, useCache: useCache);
  }

  Future<void> ensure(String core, String typeName,
      {bool useCache = true}) async {
    final key = '$core::$typeName';
    if (_loaded.contains(key)) return;
    final raw = await load(core, typeName, useCache: useCache);
    if (raw == null) return;
    QJsonDSL.define(raw);
    _loaded.add(key);
  }

  Future<void> ensureTemplate(String name) => ensure('template', name);
  Future<void> ensureMacro(String name) => ensure('macro', name);
  Future<void> ensureBox(String name) => ensure('box', name);
  Future<void> ensureLayout(String name) async {
    final raw = await load('layout', name);
    if (raw == null) return;
    QJsonDSL.define(raw);
    _loaded.add('layout::$name');
  }

  Future<void> preloadAll() async {
    for (final item in preload) {
      final core = item['core']?.toString().trim();
      final name = item['name']?.toString().trim();
      if (core == null || core.isEmpty || name == null || name.isEmpty) {
        continue;
      }
      await ensure(core, name);
    }
  }

  static bool _isSupportedFile(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.yaml') ||
        lower.endsWith('.yml') ||
        lower.endsWith('.json');
  }

  String? _resolveCore(String path) {
    final norm = path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    for (final entry in coreFolders.entries) {
      final folder =
          entry.value.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
      final prefix = folder.endsWith('/') ? folder : '$folder/';
      if (norm.startsWith(prefix)) return entry.key;
    }
    return null;
  }

  String _resolveTypeName(String path) {
    final norm = path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');
    final file = norm.split('/').last;
    final dot = file.lastIndexOf('.');
    return dot == -1 ? file : file.substring(0, dot);
  }

  final Set<String> _loaded = <String>{};
}

final class QuantumBootCatalog {
  static final QuantumBootCatalog instance = QuantumBootCatalog._();
  QuantumBootSchema? _schema;

  QuantumBootCatalog._();

  void configure(QuantumBootSchema schema) {
    _schema = schema;
    schema.installDefaults();
  }

  Future<void> registerManifest(Map<String, dynamic> manifest) async {
    final schema = _schema;
    if (schema == null) return;
    await schema.registerManifest(manifest);
  }

  Future<void> ensure(String core, String name, {bool useCache = true}) async {
    final schema = _schema ?? QuantumBootSchema(appName: 'QuantumApp');
    await schema.ensure(core, name, useCache: useCache);
  }

  Future<void> ensureTemplate(String name) => ensure('template', name);
  Future<void> ensureMacro(String name) => ensure('macro', name);
  Future<void> ensureBox(String name) => ensure('box', name);
  Future<void> ensureLayout(String name) => ensure('layout', name);
}
