/*
 * ============================================================================
 * File: quantum_app_boot.dart
 * 
 * Description:
 * The single unified application bootstrapper and schema surface for the 
 * Quantum framework. It handles schema-first asset catalogs (QuantumBootSchema),
 * app manifests (QuantumAppManifest), YAML-first and code-first app booting,
 * initialization of the Quantum Virtual Machine (VM), file-based routing, and
 * optional QEE bridges.
 * 
 * Key Components:
 * - QuantumBootSchema: Schema-first lazy catalog mapping.
 * - QuantumBootCatalog: Singleton lazy asset resolution manager.
 * - QuantumAppManifest: Launch contract defining application requirements.
 * - QuantumAppBootstrap & quantumAppBoot: Unified dev-facing startup surface.
 * - bootQuantumYamlApp & bootQuantumManifestApp: Execution pipeline entries.
 * 
 * Dependencies/Relationships:
 * Integrates deeply with QuantumVM, QuantumFileRouter, QuantumSduiEngine,
 * and optional QEE subsystem bridges.
 * ============================================================================
 */
library quantum_app_boot;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../quantum.dart';
import '../quantum_vm_core/qee/qee.dart'
    show QNodeRegistry, QFileRouterBridge, QAppNodeBuilder;
import '../quantum_vm_core/qee/qee_file_router_bridge.dart'
    show QLFileRouteEntryLite;

export 'quantum_app_shell.dart'
    show
        QuantumAppConfig,
        QuantumProductionRegistry,
        QuantumRouterConfig,
        QuantumRuntimeServices,
        QuantumTelemetryConfig,
        QuantumVMConfig;

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  QUANTUM BOOT SCHEMA — schema-first, lazy-loaded file catalog
// ────────────────────────────────────────────────────────────────────────────

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
      'preset': 'presets',
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

  Future<void> registerManifest(Map<String, dynamic> manifest) async {
    final registry = QLCoreFileRegistry.instance;

    coreFolders.forEach(registry.registerFolder);

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

  Future<void> ensurePreset(String name) => ensure('template', name);
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

  Future<void> ensurePreset(String name) => ensure('template', name);
  Future<void> ensureMacro(String name) => ensure('macro', name);
  Future<void> ensureBox(String name) => ensure('box', name);
  Future<void> ensureLayout(String name) => ensure('layout', name);
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QL YAML APP ENV & MANIFEST
// ────────────────────────────────────────────────────────────────────────────

/// Injected into the [extend] callback of [bootQuantumYamlApp].
class QLYamlAppEnv {
  final QuantumVM vm;
  final QuantumFileRouter router;
  final QuantumSduiEngine sdui;
  final QuantumApiEngine api;
  final QuantumYamlEngine yaml;
  final QLAppYamlConfig config;

  const QLYamlAppEnv({
    required this.vm,
    required this.router,
    required this.sdui,
    required this.api,
    required this.yaml,
    required this.config,
  });
}

@immutable
class QuantumAppManifest {
  final String appName;
  final String? title;
  final ThemeMode themeMode;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final List<QuantumDomain> domains;
  final QuantumRouterConfig router;
  final QuantumTelemetryConfig telemetry;
  final QuantumVMConfig vm;
  final QuantumBootSchema? boot;
  final QuantumProductionRegistry? registry;
  final QuantumRuntimeServices services;
  final Future<void> Function()? onBoot;
  final Future<void> Function(BuildContext context)? onReady;
  final Map<String, dynamic> raw;

  final bool qeeEnabled;
  final String? qeeKeyHex;

  const QuantumAppManifest({
    required this.appName,
    this.title,
    this.themeMode = ThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    this.domains = const [],
    this.router = const QuantumRouterConfig(),
    this.telemetry = const QuantumTelemetryConfig(),
    this.vm = const QuantumVMConfig(),
    this.boot,
    this.registry,
    this.services = const QuantumRuntimeServices(),
    this.onBoot,
    this.onReady,
    this.raw = const {},
    this.qeeEnabled = true,
    this.qeeKeyHex,
  });

  factory QuantumAppManifest.quick({
    required String appName,
    String? title,
    ThemeMode themeMode = ThemeMode.system,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    List<QuantumDomain> domains = const [],
    QuantumRouterConfig router = const QuantumRouterConfig(),
    QuantumTelemetryConfig telemetry = const QuantumTelemetryConfig(),
    QuantumVMConfig vm = const QuantumVMConfig(),
    QuantumBootSchema? boot,
    QuantumProductionRegistry? registry,
    QuantumRuntimeServices services = const QuantumRuntimeServices(),
    Future<void> Function()? onBoot,
    Future<void> Function(BuildContext context)? onReady,
    Map<String, dynamic> raw = const {},
  }) {
    return QuantumAppManifest(
      appName: appName,
      title: title,
      themeMode: themeMode,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      domains: List<QuantumDomain>.unmodifiable(domains),
      router: router,
      telemetry: telemetry,
      vm: vm,
      boot: boot,
      registry: registry,
      services: services,
      onBoot: onBoot,
      onReady: onReady,
      raw: raw,
    );
  }

  factory QuantumAppManifest.fromYamlConfig(
    QLAppYamlConfig config, {
    List<QLRoute> routes = const [],
    QuantumProductionRegistry? registry,
    QuantumRuntimeServices services = const QuantumRuntimeServices(),
    Widget? notFoundWidget,
    Future<void> Function()? onBoot,
    Future<void> Function(BuildContext context)? onReady,
    QuantumBootSchema? boot,
  }) {
    final String mode =
        QLYamlConfig.string(config.theme, 'mode', fallback: 'system');
    final ThemeMode themeMode = switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return QuantumAppManifest.quick(
      appName: config.appName,
      title: config.title.isEmpty ? config.appName : config.title,
      themeMode: themeMode,
      lightTheme: _buildThemeFromYaml(config.theme, dark: false),
      darkTheme: _buildThemeFromYaml(config.theme, dark: true),
      domains: <QuantumDomain>[
        if (routes.isNotEmpty)
          QuantumDomain(
            name: '_yaml_router',
            routes: List<QLRoute>.unmodifiable(routes),
          ),
        ..._buildDomainsFromYaml(config.domains),
      ],
      router: QuantumRouterConfig(
        initialRoute: config.initialRoute,
        notFoundWidget: notFoundWidget,
      ),
      telemetry: QuantumTelemetryConfig(
        enabled: config.telemetryEnabled,
        enableFrameMonitorInDebug: config.frameMonitor,
      ),
      vm: QuantumVMConfig(
        workerThreads: config.workerThreads,
        simdArenaCapacity: config.simdArenaCapacity,
      ),
      registry: registry,
      services: services,
      onBoot: onBoot,
      onReady: onReady,
      boot: boot ??
          (config.raw['boot'] is Map
              ? QuantumBootSchema.fromMap(
                  Map<String, dynamic>.from(config.raw['boot'] as Map),
                  appName: config.appName,
                )
              : QuantumBootSchema(
                  appName: config.appName, pagesDir: config.pagesDir)),
      raw: config.raw,
    );
  }

  factory QuantumAppManifest.fromMap(Map<String, dynamic> map) =>
      QuantumAppManifest.fromYamlConfig(
        QLAppYamlConfig.fromMap(map),
        boot: map['boot'] is Map
            ? QuantumBootSchema.fromMap(
                Map<String, dynamic>.from(map['boot'] as Map),
                appName: map['appName']?.toString(),
              )
            : null,
      );

  QuantumAppManifest copyWith({
    String? appName,
    String? title,
    ThemeMode? themeMode,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    List<QuantumDomain>? domains,
    QuantumRouterConfig? router,
    QuantumTelemetryConfig? telemetry,
    QuantumVMConfig? vm,
    QuantumBootSchema? boot,
    QuantumProductionRegistry? registry,
    QuantumRuntimeServices? services,
    Future<void> Function()? onBoot,
    Future<void> Function(BuildContext context)? onReady,
    Map<String, dynamic>? raw,
  }) {
    return QuantumAppManifest.quick(
      appName: appName ?? this.appName,
      title: title ?? this.title,
      themeMode: themeMode ?? this.themeMode,
      lightTheme: lightTheme ?? this.lightTheme,
      darkTheme: darkTheme ?? this.darkTheme,
      domains: domains ?? this.domains,
      router: router ?? this.router,
      telemetry: telemetry ?? this.telemetry,
      vm: vm ?? this.vm,
      boot: boot ?? this.boot,
      registry: registry ?? this.registry,
      services: services ?? this.services,
      onBoot: onBoot ?? this.onBoot,
      onReady: onReady ?? this.onReady,
      raw: raw ?? this.raw,
    );
  }

  QuantumAppManifest withDomain(QuantumDomain domain) => copyWith(
        domains: <QuantumDomain>[...domains, domain],
      );

  QuantumAppConfig toAppConfig() {
    return QuantumAppConfig(
      appName: appName,
      title: title?.isEmpty == true ? appName : title,
      themeMode: themeMode,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      domains: List<QuantumDomain>.unmodifiable(domains),
      telemetry: telemetry,
      router: router,
      vm: vm,
      registry: registry,
      services: services,
      onBoot: onBoot,
      onReady: onReady,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  BOOTSTRAP FACADE & WRAPPER
// ────────────────────────────────────────────────────────────────────────────

/// Main launch helper for the shortest possible dev path.
QuantumAppManifest quantumApp({
  required String appName,
  String? title,
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? lightTheme,
  ThemeData? darkTheme,
  List<QuantumDomain> domains = const [],
  QuantumRouterConfig router = const QuantumRouterConfig(),
  QuantumTelemetryConfig telemetry = const QuantumTelemetryConfig(),
  QuantumVMConfig vm = const QuantumVMConfig(),
  QuantumBootSchema? boot,
  QuantumProductionRegistry? registry,
  QuantumRuntimeServices services = const QuantumRuntimeServices(),
  Future<void> Function()? onBoot,
  Future<void> Function(BuildContext context)? onReady,
  Map<String, dynamic> raw = const {},
}) {
  return QuantumAppManifest.quick(
    appName: appName,
    title: title,
    themeMode: themeMode,
    lightTheme: lightTheme,
    darkTheme: darkTheme,
    domains: domains,
    router: router,
    telemetry: telemetry,
    vm: vm,
    boot: boot,
    registry: registry,
    services: services,
    onBoot: onBoot,
    onReady: onReady,
    raw: raw,
  );
}

void bootQuantumManifestApp(QuantumAppManifest manifest) {
  final boot = manifest.boot ?? QuantumBootSchema(appName: manifest.appName);
  boot.installDefaults();
  QuantumBootCatalog.instance.configure(boot);
  bootQuantumApp(manifest.toAppConfig());
}

/// A streamlined wrapper class for the manifest-based boot flow.
@immutable
class QuantumAppBootstrap {
  final QuantumAppManifest manifest;

  const QuantumAppBootstrap(this.manifest);

  QuantumAppBootstrap.quick({
    required String appName,
    String? title,
    ThemeMode themeMode = ThemeMode.system,
    ThemeData? lightTheme,
    ThemeData? darkTheme,
    List<QuantumDomain> domains = const [],
    QuantumRouterConfig router = const QuantumRouterConfig(),
    QuantumTelemetryConfig telemetry = const QuantumTelemetryConfig(),
    QuantumVMConfig vm = const QuantumVMConfig(),
    QuantumBootSchema? boot,
    QuantumProductionRegistry? registry,
    QuantumRuntimeServices services = const QuantumRuntimeServices(),
    Future<void> Function()? onBoot,
    Future<void> Function(BuildContext context)? onReady,
    Map<String, dynamic> raw = const {},
  }) : manifest = quantumApp(
          appName: appName,
          title: title,
          themeMode: themeMode,
          lightTheme: lightTheme,
          darkTheme: darkTheme,
          domains: domains,
          router: router,
          telemetry: telemetry,
          vm: vm,
          boot: boot,
          registry: registry,
          services: services,
          onBoot: onBoot,
          onReady: onReady,
          raw: raw,
        );

  QuantumAppConfig toConfig() => manifest.toAppConfig();

  void run() => bootQuantumManifestApp(manifest);
}

/// Convenience helper for the shortest possible app startup.
QuantumAppBootstrap quantumAppBoot({
  required String appName,
  String? title,
  ThemeMode themeMode = ThemeMode.system,
  ThemeData? lightTheme,
  ThemeData? darkTheme,
  List<QuantumDomain> domains = const [],
  QuantumRouterConfig router = const QuantumRouterConfig(),
  QuantumTelemetryConfig telemetry = const QuantumTelemetryConfig(),
  QuantumVMConfig vm = const QuantumVMConfig(),
  QuantumBootSchema? boot,
  QuantumProductionRegistry? registry,
  QuantumRuntimeServices services = const QuantumRuntimeServices(),
  Future<void> Function()? onBoot,
  Future<void> Function(BuildContext context)? onReady,
  Map<String, dynamic> raw = const {},
}) {
  return QuantumAppBootstrap.quick(
    appName: appName,
    title: title,
    themeMode: themeMode,
    lightTheme: lightTheme,
    darkTheme: darkTheme,
    domains: domains,
    router: router,
    telemetry: telemetry,
    vm: vm,
    boot: boot,
    registry: registry,
    services: services,
    onBoot: onBoot,
    onReady: onReady,
    raw: raw,
  );
}

typedef QuantumAppYamlEnv = QLYamlAppEnv;

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  YAML BOOTSTRAPPER PIPELINE
// ────────────────────────────────────────────────────────────────────────────

void bootQuantumYamlApp(
  String appConfigPath, {
  void Function(QLYamlAppEnv env)? extend,
  Widget Function()? loadingApp,
  Widget Function(dynamic error)? errorApp,
}) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(_QuantumBootLoader(
    configPath: appConfigPath,
    extend: extend,
    loadingApp: loadingApp,
    errorApp: errorApp,
  ));
}

class _QuantumBootLoader extends StatefulWidget {
  final String configPath;
  final void Function(QLYamlAppEnv env)? extend;
  final Widget Function()? loadingApp;
  final Widget Function(dynamic error)? errorApp;

  const _QuantumBootLoader({
    required this.configPath,
    this.extend,
    this.loadingApp,
    this.errorApp,
  });

  @override
  State<_QuantumBootLoader> createState() => _QuantumBootLoaderState();
}

class _QuantumBootLoaderState extends State<_QuantumBootLoader> {
  bool _ready = false;
  dynamic _error;
  QuantumAppConfig? _appConfig;
  final Key _appKey = UniqueKey();
  StreamSubscription? _yamlWatcher;
  Timer? _debounce;

  @override
  void reassemble() {
    super.reassemble();

    QuantumYamlEngine.instance.clearCaches();
    QuantumVM.instance.clearRuntimeCaches();
    QuantumFileRouter.instance.invalidateCache();
    QLCoreFileRegistry.instance.clear();
    QJsonPresetEngine.clear();
    QLSchemaRegistry.instance.clear();
    QuantumCoreSchemaRegistry.instance.clear();
    try {
      QFileRouterBridge.instance.invalidateAll();
    } catch (_) {}

    setState(() {
      _ready = false;
      _appConfig = null;
      _error = null;
    });
    _boot();
  }

  @override
  void initState() {
    super.initState();
    _boot();
    if (kDebugMode && !kIsWeb) {
      _startDevWatcher();
    }
  }

  void _startDevWatcher() {
    try {
      final root = QuantumYamlEngine.getProjectRoot();
      final dirPath =
          root != null ? '$root/assets' : '${Directory.current.path}/assets';
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        _yamlWatcher = dir.watch(recursive: true).listen((event) {
          if (event.path.endsWith('.yaml') ||
              event.path.endsWith('.yml') ||
              event.path.endsWith('.json')) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 150), () {
              if (mounted) reassemble();
            });
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _yamlWatcher?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    try {
      final cfg = await _buildAppConfig(
        configPath: widget.configPath,
        extend: widget.extend,
      );
      if (mounted) {
        setState(() {
          _appConfig = cfg;
          _ready = true;
        });
      }
    } catch (e, st) {
      debugPrint('[QuantumAppBoot] Boot error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e;
          _ready = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return widget.loadingApp?.call() ?? const _DefaultBootLoader();
    }
    if (_error != null) {
      if (widget.errorApp != null) return widget.errorApp!(_error);
      return _DefaultErrorApp(error: _error.toString());
    }
    if (_appConfig != null) {
      return _QuantumYamlAppRoot(key: _appKey, appConfig: _appConfig!);
    }
    return const _DefaultBootLoader();
  }
}

class _QuantumYamlAppRoot extends StatefulWidget {
  final QuantumAppConfig appConfig;
  const _QuantumYamlAppRoot({super.key, required this.appConfig});

  @override
  State<_QuantumYamlAppRoot> createState() => _QuantumYamlAppRootState();
}

class _QuantumYamlAppRootState extends State<_QuantumYamlAppRoot> {
  late QLNavController _router;

  @override
  void initState() {
    super.initState();

    QEngine.instance
        .initialize(initialCapacity: widget.appConfig.vm.simdArenaCapacity);

    final List<QLRoute> allRoutes = [
      ...widget.appConfig.domains.expand((d) => d.routes),
    ];
    final List<QLMiddleware> mergedMiddlewares = [
      ...widget.appConfig.router.globalMiddlewares,
      ...widget.appConfig.domains.expand((d) => d.routeMiddlewares),
    ];

    _router = QLNavController(
      routes: allRoutes,
      initialRoute: widget.appConfig.router.initialRoute,
      globalMiddlewares: mergedMiddlewares,
      notFoundWidget: widget.appConfig.router.notFoundWidget,
    );

    for (final domain in widget.appConfig.domains) {
      QuantumVM.instance.installDomain(domain);
    }

    final List<ActionMiddleware> middlewares = [
      ...widget.appConfig.vm.actionMiddlewares,
      ...widget.appConfig.domains.expand((d) => d.actionMiddlewares),
    ];
    QuantumVM.instance.setMiddlewares(middlewares);

    if (widget.appConfig.registry != null) {
      widget.appConfig.registry!.install(QuantumVM.instance);
    } else {
      QuantumProductionRegistry(services: widget.appConfig.services)
          .install(QuantumVM.instance);
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QLBridgeScope(
      registry: QLNativeBridgeRegistry.instance,
      child: MaterialApp.router(
        title: widget.appConfig.title ?? widget.appConfig.appName,
        themeMode: widget.appConfig.themeMode,
        theme:
            widget.appConfig.lightTheme ?? ThemeData.light(useMaterial3: true),
        darkTheme:
            widget.appConfig.darkTheme ?? ThemeData.dark(useMaterial3: true),
        debugShowCheckedModeBanner: false,
        routeInformationParser: const QLRouteParser(),
        routerDelegate: QLRouterDelegate(_router),
        builder: (context, child) {
          Widget appLayer = child ?? const SizedBox.shrink();
          appLayer = Scaffold(
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
              body: appLayer);
          appLayer = QuantumVMRoot(
              workerThreads: widget.appConfig.vm.workerThreads,
              child: appLayer);
          appLayer = QLOverlayRoot(child: appLayer);
          if (widget.appConfig.telemetry.enableFrameMonitorInDebug &&
              kDebugMode) {
            appLayer = QLFrameMonitor(showOverlay: true, child: appLayer);
          }
          return appLayer;
        },
      ),
    );
  }
}

Future<QuantumAppConfig> _buildAppConfig({
  required String configPath,
  void Function(QLYamlAppEnv env)? extend,
}) async {
  final QLAppYamlConfig config =
      await QLAppYamlConfig.loadFromAsset(configPath);

  final QuantumBootSchema bootSchema = config.raw['boot'] is Map
      ? QuantumBootSchema.fromMap(
          Map<String, dynamic>.from(config.raw['boot'] as Map),
          appName: config.appName,
        )
      : QuantumBootSchema(appName: config.appName, pagesDir: config.pagesDir);
  bootSchema.installDefaults();

  if (config.state.isNotEmpty) applyYamlState(config.state);
  if (config.macros.isNotEmpty) applyYamlMacros(config.macros);
  if (config.schemas.isNotEmpty) applyYamlSchemas(config.schemas);
  if (config.pipes.isNotEmpty) applyYamlPipes(config.pipes);

  QuantumApiEngine.instance.installActions(QuantumVM.instance);
  _applySduiConfig(config.sdui);

  final List<QLRoute> explicitRoutes =
      _buildExplicitRoutes(config.raw['routes']);
  final List<QLRoute> fileRoutes = await QuantumFileRouter.instance.buildRoutes(
    config.pagesDir,
    explicitRoutes: explicitRoutes,
  );

  final qeeSyncFuture = _bootQEE(
    config: config,
    bootSchema: bootSchema,
    fileRoutes: fileRoutes,
    manifest: await _loadAssetManifestMap(),
  );

  Widget? notFoundWidget;
  if (config.notFoundPage != null) {
    notFoundWidget = _QLFileRouteViewStatic(assetPath: config.notFoundPage!);
  }

  if (extend != null) {
    extend(QLYamlAppEnv(
      vm: QuantumVM.instance,
      router: QuantumFileRouter.instance,
      sdui: QuantumSduiEngine.instance,
      api: QuantumApiEngine.instance,
      yaml: QuantumYamlEngine.instance,
      config: config,
    ));
  }

  final List<QLRoute> runtimeRoutes =
      QuantumFileRouter.instance.runtimeRoutes.toList();

  await qeeSyncFuture;

  final QuantumAppManifest manifest = QuantumAppManifest.fromYamlConfig(
    config,
    routes: [...runtimeRoutes, ...fileRoutes],
    notFoundWidget: notFoundWidget,
    boot: bootSchema,
  );

  return manifest.toAppConfig();
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  OPTIONAL QEE BOOT HELPERS (SAFE GUARDS)
// ────────────────────────────────────────────────────────────────────────────

Future<void> _bootQEE({
  required QLAppYamlConfig config,
  required QuantumBootSchema bootSchema,
  required List<QLRoute> fileRoutes,
  required Map<String, dynamic> manifest,
}) async {
  try {
    await QNodeRegistry.instance.initialize(
      namespace: config.appName.toLowerCase().replaceAll(RegExp(r'\W+'), '_'),
    );

    await QAppNodeBuilder.buildAndRegister(
      appId: config.appName,
      pagesDir: config.pagesDir,
      initialRoute: config.initialRoute,
    );

    final entries = manifest.keys
        .where((k) =>
            k.startsWith(bootSchema.pagesDir.endsWith('/')
                ? bootSchema.pagesDir
                : '${bootSchema.pagesDir}/') &&
            (k.endsWith('.yaml') || k.endsWith('.yml') || k.endsWith('.json')))
        .map((assetPath) {
          final entry = QLFileRouteParser.parse(assetPath, config.pagesDir);
          if (entry == null) return null;
          return QLFileRouteEntryLite(
            assetPath: entry.assetPath,
            routePath: entry.routePath,
            paramNames: entry.paramNames,
            isCatchAll: entry.isCatchAll,
          );
        })
        .whereType<QLFileRouteEntryLite>()
        .toList(growable: false);

    await QFileRouterBridge.instance.sync(
      entries: entries,
      allAssetPaths: manifest.keys.toList(),
      pagesDir: config.pagesDir,
      appId: config.appName,
    );

    await QLModuleRegistry.instance.syncToQEE(appId: config.appName);

    if (kDebugMode) {
      final snap = QNodeRegistry.instance.snapshot();
      debugPrint('[QEE] Boot complete: '
          'pages=${snap.pageCount}, '
          'layouts=${snap.layoutCount}, '
          'middlewares=${snap.middlewareCount}, '
          'modules=${snap.moduleCount}');
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[QEE] Boot error (non-fatal): $e\n$st');
    }
  }
}

Future<Map<String, dynamic>> _loadAssetManifestMap() async {
  try {
    return await QuantumFileRouter.instance.loadAssetManifest();
  } catch (_) {
    return const {};
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  HELPERS
// ────────────────────────────────────────────────────────────────────────────

void _applySduiConfig(Map<String, dynamic> sduiConfig) {
  if (sduiConfig.isEmpty) return;

  final keys = sduiConfig['keys'];
  if (keys is List) {
    for (final keyDef in keys) {
      if (keyDef is! Map) continue;
      final kid = keyDef['kid']?.toString();
      final aes = keyDef['aesKey']?.toString();
      final sig = keyDef['sigKey']?.toString();
      final active = keyDef['active'] as bool? ?? false;
      if (kid != null && aes != null && sig != null) {
        try {
          QuantumSduiEngine.instance.keyStore.registerBase64(
            kid: kid,
            aesKeyB64: aes,
            sigKeyB64: sig,
            setActive: active,
          );
        } catch (e) {
          debugPrint('[QuantumAppBoot] SDUI key error for $kid: $e');
        }
      }
    }
  }

  final maxAge = sduiConfig['replayGuardMaxAgeSeconds'];
  if (maxAge is num) {
    QuantumSduiEngine.instance.replayGuard.maxAge =
        Duration(seconds: maxAge.toInt());
  }
}

List<QLRoute> _buildExplicitRoutes(dynamic routesConfig) {
  if (routesConfig is! List) return const [];
  return routesConfig
      .whereType<Map>()
      .map((r) {
        final path = r['path']?.toString();
        final assetPath = r['page']?.toString() ?? r['asset']?.toString();
        if (path == null || assetPath == null) return null;
        return QLRoute(
          path: path,
          builder: (context, info) =>
              _QLFileRouteViewStatic(assetPath: assetPath, routeInfo: info),
          transition: _parseTransition(r['transition']?.toString()),
        );
      })
      .whereType<QLRoute>()
      .toList(growable: false);
}

QLTransitionType _parseTransition(String? name) =>
    switch (name?.toLowerCase() ?? '') {
      'fade' => QLTransitionType.fade,
      'scale' => QLTransitionType.scale,
      'slideleft' || 'slide_left' => QLTransitionType.slideLeft,
      'slideup' || 'slide_up' => QLTransitionType.slideUp,
      'slidedown' || 'slide_down' => QLTransitionType.slideDown,
      'none' => QLTransitionType.none,
      _ => QLTransitionType.slideRight,
    };

ThemeData? _buildThemeFromYaml(Map<String, dynamic> themeMap,
    {required bool dark}) {
  if (themeMap.isEmpty) return null;

  final String mode = QLYamlConfig.string(themeMap, 'mode', fallback: 'system');
  if (!dark && mode == 'dark') return null;

  final colorsKey = dark && themeMap.containsKey('dark') ? 'dark' : 'colors';
  final colors = QLYamlConfig.map(themeMap, colorsKey);
  final String primaryStr =
      QLYamlConfig.string(colors, 'primary', fallback: '');
  final String bgStr = QLYamlConfig.string(colors, 'background',
      fallback: dark ? '#0F0F14' : '#FFFFFF');
  final String fontFamily = QLYamlConfig.string(
      QLYamlConfig.map(themeMap, 'typography'), 'fontFamily',
      fallback: 'Inter');

  Color primary = dark ? const Color(0xFF6366F1) : const Color(0xFF4F46E5);
  Color bg = dark ? const Color(0xFF0F0F14) : Colors.white;

  if (primaryStr.isNotEmpty) {
    try {
      primary =
          Color(QLParserUtils.parseColor(primaryStr, 0, primaryStr.length));
    } catch (_) {}
  }
  if (bgStr.isNotEmpty) {
    try {
      bg = Color(QLParserUtils.parseColor(bgStr, 0, bgStr.length));
    } catch (_) {}
  }

  final brightness = dark ? Brightness.dark : Brightness.light;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme:
        ColorScheme.fromSeed(seedColor: primary, brightness: brightness),
    fontFamily: fontFamily,
    scaffoldBackgroundColor: bg,
  );
}

List<QuantumDomain> _buildDomainsFromYaml(
    List<Map<String, dynamic>> domainsConfig) {
  return domainsConfig.map((m) {
    final name = m['name']?.toString() ?? 'domain_${m.hashCode}';
    final storeData = m['state'] is Map
        ? Map<String, dynamic>.from(m['state'] as Map)
        : const <String, dynamic>{};
    return QuantumDomain(name: name, initialStoreData: storeData);
  }).toList(growable: false);
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  STATIC FILE ROUTE VIEW & DEFAULT WIDGETS
// ────────────────────────────────────────────────────────────────────────────

class _QLFileRouteViewStatic extends StatefulWidget {
  final String assetPath;
  final QLRouteInfo? routeInfo;
  const _QLFileRouteViewStatic({required this.assetPath, this.routeInfo});

  @override
  State<_QLFileRouteViewStatic> createState() => _QLFileRouteViewStaticState();
}

class _QLFileRouteViewStaticState extends State<_QLFileRouteViewStatic> {
  QLBlueprint? _ast;
  Map<String, dynamic>? _raw;
  dynamic _error;

  @override
  void reassemble() {
    super.reassemble();
    _compile();
  }

  @override
  void initState() {
    super.initState();
    _compile();
  }

  @override
  void didUpdateWidget(covariant _QLFileRouteViewStatic old) {
    super.didUpdateWidget(old);
    if (old.assetPath != widget.assetPath ||
        old.routeInfo != widget.routeInfo) {
      _compile();
    }
  }

  Future<void> _compile() async {
    try {
      final Map<String, dynamic> raw =
          await QuantumYamlEngine.instance.load(widget.assetPath);
      final QLPageYamlConfig cfg = QLPageYamlConfig.fromMap(raw);
      if (cfg.macros.isNotEmpty) applyYamlMacros(cfg.macros);
      if (cfg.state.isNotEmpty) {
        QLStoreRegistry.instance
            .get(raw['module']?.toString() ?? 'default')
            .merge(cfg.state);
      }

      final Map<String, dynamic> env = {
        ...raw['env'] is Map
            ? Map<String, dynamic>.from(raw['env'] as Map)
            : <String, dynamic>{},
        if (widget.routeInfo != null)
          r'$route': {
            'path': widget.routeInfo!.path,
            'param': widget.routeInfo!.params,
            'query': widget.routeInfo!.queryParams,
          },
      };

      final dynamic uiNode = cfg.ui ?? raw['ui'] ?? raw;
      final ast = await QLCompiler.compileAsync(
          uiNode,
          {...QLModuleRegistry.instance.macrosFor('default'), ...cfg.macros},
          env);

      if (mounted) {
        setState(() {
          _ast = ast;
          _raw = raw;
          _error = null;
        });
      }
    } catch (e, st) {
      debugPrint('[QuantumAppBoot] Compile error: $e\n$st');
      if (mounted) {
        setState(() {
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F14),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Static Route Error:\n$_error',
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontFamily: 'monospace',
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_ast == null) return const SizedBox.shrink();
    return QLDataScope(
      moduleStore: QLStoreRegistry.instance
          .get(_raw?['module']?.toString() ?? 'default'),
      localData: {
        if (widget.routeInfo != null)
          r'$route': {
            'path': widget.routeInfo!.path,
            'param': widget.routeInfo!.params,
            'query': widget.routeInfo!.queryParams,
          },
      },
      child: QuantumVM.instance.renderWidget(context, _ast!),
    );
  }
}

class _DefaultBootLoader extends StatelessWidget {
  const _DefaultBootLoader();
  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF0F0F14),
          body: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ),
        ),
      );
}

class _DefaultErrorApp extends StatelessWidget {
  final String error;
  const _DefaultErrorApp({required this.error});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0F0F14),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  const Text('Quantum Boot Error',
                      style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none)),
                  const SizedBox(height: 12),
                  Text(error,
                      style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontFamily: 'monospace',
                          decoration: TextDecoration.none),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      );
}
