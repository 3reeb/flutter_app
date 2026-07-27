// ════════════════════════════════════════════════════════════════════════════
// QUANTUM APP ENTRY v1.0 — SINGLE-FILE APP BOOTSTRAPPER
// quantum_app_entry.dart
//
// USAGE — Run an entire app from a single Dart file:
//
//   void main() => bootQuantumManifestApp(
//     quantumApp(
//       appName: 'MyApp',
//       title: 'My App',
//       domains: [quantumApiShellDomain()],
//     ),
//   );
//
// Or keep the YAML-first path:
//
//   void main() => bootQuantumYamlApp('APP.yaml');
//
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../quantum.dart';
import 'quantum_boot_schema.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  QL YAML APP ENV — passed to the extend() callback
// ────────────────────────────────────────────────────────────────────────────

/// Injected into the [extend] callback of [bootQuantumYamlApp].
/// Gives full access to all subsystems for native-Dart customization.
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

// ─────────────────────────────────────────────────────────────────────── §1b ─
//  QL APP MANIFEST — schema-first, payload-style launch contract
// ────────────────────────────────────────────────────────────────────────────

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

/// One-file, schema-first launch helper for the shortest possible dev path.
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

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  BOOT FUNCTION
// ────────────────────────────────────────────────────────────────────────────

/// Bootstrap an entire Quantum application from a YAML config file.
///
/// ```dart
/// void main() => bootQuantumYamlApp('APP.yaml');
/// ```
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

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  BOOT LOADER WIDGET
// ────────────────────────────────────────────────────────────────────────────

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
  Key _appKey = UniqueKey();
  StreamSubscription? _yamlWatcher;
  Timer? _debounce;

  // 🚀 ADD THIS ENTIRE METHOD:
  // This hooks into Flutter's Hot Reload (Lightning Bolt)
  @override
  void reassemble() {
    super.reassemble();

    // Nuke all global Singletons
    QuantumYamlEngine.instance.clearCaches();
    QuantumVM.instance.clearRuntimeCaches();
    QuantumFileRouter.instance.invalidateCache();
    QLCoreFileRegistry.instance.clear();
    QJsonTemplateEngine_D.clear();
    QLSchemaRegistry.instance.clear();
    QuantumCoreSchemaRegistry.instance.clear();

    // Force the app to reboot and re-read APP.yaml
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
      if (mounted)
        setState(() {
          _appConfig = cfg;
          _ready = true;
        });
    } catch (e, st) {
      debugPrint('[QuantumAppEntry] Boot error: $e\n$st');
      if (mounted)
        setState(() {
          _error = e;
          _ready = true;
        });
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

// ─────────────────────────────────────────────────────────────────────── §3b ─
//  ROOT WIDGET — replaces runApp after boot
// ────────────────────────────────────────────────────────────────────────────

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

    // Register domain capabilities
    for (final domain in widget.appConfig.domains) {
      domain.sduiComponents
          .forEach((name, builder) => QuantumVM.instance.define(name, builder));
      domain.sduiPipes
          .forEach((name, transform) => QLPipes.register(name, transform));
      domain.schemas.forEach(
          (name, def) => QLSchemaRegistry.instance.registerRaw(name, def));
      for (final plugin in domain.sduiPlugins) {
        QuantumVM.instance.registerPlugin(plugin);
      }
      domain.sduiActions.forEach(
          (name, action) => QuantumVM.instance.registerAction(name, action));
      if (domain.initialStoreData.isNotEmpty) {
        QuantumVM.instance.store.merge(domain.initialStoreData);
      }
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

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  MAIN BOOTSTRAP PIPELINE
// ────────────────────────────────────────────────────────────────────────────

Future<QuantumAppConfig> _buildAppConfig({
  required String configPath,
  void Function(QLYamlAppEnv env)? extend,
}) async {
  // 1. Parse APP.yaml (with all $import: resolved)
  final QLAppYamlConfig config =
      await QLAppYamlConfig.loadFromAsset(configPath);

  // 2. Install boot schema first so schemas / aliases / file catalogs are ready
  final QuantumBootSchema bootSchema = config.raw['boot'] is Map
      ? QuantumBootSchema.fromMap(
          Map<String, dynamic>.from(config.raw['boot'] as Map),
          appName: config.appName,
        )
      : QuantumBootSchema(appName: config.appName, pagesDir: config.pagesDir);
  bootSchema.installDefaults();

  // 3. Apply global state / macros / schemas / pipes into QuantumVM
  if (config.state.isNotEmpty) applyYamlState(config.state);
  if (config.macros.isNotEmpty) applyYamlMacros(config.macros);
  if (config.schemas.isNotEmpty) applyYamlSchemas(config.schemas);
  if (config.pipes.isNotEmpty) applyYamlPipes(config.pipes);

  // 4. Install API engine built-in actions
  QuantumApiEngine.instance.installActions(QuantumVM.instance);

  // 5. Configure SDUI encryption from APP.yaml → sdui: section
  _applySduiConfig(config.sdui);

  // 6. Build file-based routes from pagesDir + explicit ROUTES.yaml entries
  final List<QLRoute> explicitRoutes =
      _buildExplicitRoutes(config.raw['routes']);
  final List<QLRoute> fileRoutes = await QuantumFileRouter.instance.buildRoutes(
    config.pagesDir,
    explicitRoutes: explicitRoutes,
  );

  // 7. Build 404 widget
  Widget? notFoundWidget;
  if (config.notFoundPage != null) {
    notFoundWidget = _QLFileRouteViewStatic(assetPath: config.notFoundPage!);
  }

  // 7. Call extend() for native Dart additions BEFORE route assembly
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

  // 8. Collect any runtime routes added in extend()
  final List<QLRoute> runtimeRoutes =
      QuantumFileRouter.instance.runtimeRoutes.toList();

  // 9. Assemble the final schema-first manifest and bridge into the shell.
  final QuantumAppManifest manifest = QuantumAppManifest.fromYamlConfig(
    config,
    routes: [...runtimeRoutes, ...fileRoutes],
    notFoundWidget: notFoundWidget,
    boot: bootSchema,
  );

  return manifest.toAppConfig();
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
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
          debugPrint('[QuantumAppEntry] SDUI key error for $kid: $e');
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
  // Light theme only if mode != 'dark'
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

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  STATIC FILE ROUTE VIEW
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
  dynamic _error; // 🚀 ADD THIS

  // 🚀 ADD THIS: Forces the route to re-read the YAML on hot reload
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

      // 🚀 UPDATE THIS LINE
      if (mounted)
        setState(() {
          _ast = ast;
          _raw = raw;
          _error = null;
        });
    } catch (e, st) {
      debugPrint('[QuantumAppEntry] Compile error: $e\n$st');
      // 🚀 ADD THIS LINE
      if (mounted)
        setState(() {
          _error = e;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 ADD THIS BLOCK: Display the error visually to prevent a black screen
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
// ─────────────────────────────────────────────────────────────────────── §7 ─
//  DEFAULT LOADING / ERROR WIDGETS
// ────────────────────────────────────────────────────────────────────────────

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
