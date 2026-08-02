/*
 * ============================================================================
 * File: quantum_app_shell.dart
 * 
 * Description:
 * The Omega Bootstrapper and God-Mode Orchestrator for the Quantum framework. 
 * This file serves as the ultimate dependency injection (DI) container and 
 * lifecycle manager. It handles synchronous low-level engine ignition, domain 
 * orchestration, and global state initialization, effectively wrapping the app 
 * in a robust shell that manages everything from routing to telemetry.
 * 
 * Key Components:
 * - QuantumAppEnvironment: Exposes all core framework engines for dynamic interception.
 * - QuantumProductionRegistry: Manages production-ready actions, pipes, and plugins.
 * - bootQuantumApp: The insane fast launch and zone matcher bootstrapper.
 * - _QuantumAppShell: The root widget compositing the VM, overlays, and router.
 * 
 * Dependencies/Relationships:
 * Sits at the top of the architectural hierarchy, coordinating QuantumVM, 
 * QLNavController, QuantumTelemetry, and modular QuantumDomain definitions.
 * 
 * Notes:
 * Designed for absolute performance and predictability. Synchronous boot steps 
 * ensure the environment is fully assembled before the first frame is rendered.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM APP SHELL v9.0 - OMEGA BOOTSTRAPPER + GOD-MODE ORCHESTRATOR & DI
// quantum_app_shell.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../quantum.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  API CLIENT STUBS (To ensure standalone compilation)
// ────────────────────────────────────────────────────────────────────────────

abstract class QuantumApiClient {
  bool get isInitialized;
  Future<void> init();
  Future<dynamic> executeRead(
      {required String slug, required Map query, String? id});
  Future<dynamic> executeWrite(
      {required String slug,
      required String op,
      required Map body,
      String? id});
  QuantumAuthClient auth();
  Future<dynamic> cacheGet(String key);
  Future<void> cacheSet(String key, dynamic value);
  Future<void> cacheRemove(String key);
}

abstract class QuantumAuthClient {
  Future<dynamic> login(Map body);
  Future<dynamic> register(Map body);
  Future<dynamic> logout();
  Future<dynamic> me();
}

typedef QuantumActionFactory = QLActionPlugin Function(
    QuantumRuntimeServices services);

class QuantumRuntimeServices {
  final QuantumApiClient? api;
  const QuantumRuntimeServices({this.api});

  Future<QuantumApiClient?> ensureApi() async {
    final client = api;
    if (client == null) return null;
    if (!client.isInitialized) {
      await client.init();
    }
    return client;
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  PRODUCTION REGISTRY (Merged into App Shell)
// ────────────────────────────────────────────────────────────────────────────

class QuantumProductionRegistry {
  final bool builtIns;
  final bool commerceWidgets;
  final bool productionActions;
  final bool productionPipes;
  final QuantumRuntimeServices services;
  final Map<String, QuantumActionFactory> actions;
  final Map<String, QLPlugin> plugins;
  final Map<String, Map<String, dynamic>> aliases;
  final Map<String, Map<String, String>> slotTypes;
  final Map<String, Map<String, dynamic>> slotNodes;

  const QuantumProductionRegistry({
    this.builtIns = true,
    this.commerceWidgets = true,
    this.productionActions = true,
    this.productionPipes = true,
    this.services = const QuantumRuntimeServices(),
    this.actions = const {},
    this.plugins = const {},
    this.aliases = const {},
    this.slotTypes = const {},
    this.slotNodes = const {},
  });

  factory QuantumProductionRegistry.commerce({
    QuantumApiClient? api,
    Map<String, QuantumActionFactory> actions = const {},
    Map<String, QLPlugin> plugins = const {},
    Map<String, Map<String, dynamic>> aliases = const {},
  }) {
    return QuantumProductionRegistry(
      services: QuantumRuntimeServices(api: api),
      actions: actions,
      plugins: plugins,
      aliases: aliases,
    );
  }

  void install([QuantumVM? target]) {
    final vm = target ?? QuantumVM.instance;
    if (builtIns) initQuantumBuiltIns(vm);
    if (productionPipes) _registerPipes();
    if (productionActions) _registerActions(vm);
    vm.installBundle(
      QuantumExtensionBundle(
        plugins: plugins,
        aliases: aliases,
        slotTypes: slotTypes,
        slotNodes: slotNodes,
      ),
    );
  }

  void _registerActions(QuantumVM vm) {
    _actionMap().forEach(vm.registerAction);
    actions.forEach((name, factory) {
      vm.registerAction(name, factory(services));
    });
  }

  Map<String, QLActionPlugin> _actionMap() => {
        'state.set': _SetStateAction(),
        'state.merge': _MergeStateAction(),
        'state.toggle': _ToggleStateAction(),
        'state.remove': _RemoveStateAction(),
        'api.read': _ApiReadAction(services),
        'api.write': _ApiWriteAction(services),
        'api.create': _ApiWriteAction(services, defaultOp: 'create'),
        'api.update': _ApiWriteAction(services, defaultOp: 'update'),
        'api.delete': _ApiWriteAction(services, defaultOp: 'delete'),
        'auth.login': _AuthAction(services, _AuthOp.login),
        'auth.register': _AuthAction(services, _AuthOp.register),
        'auth.logout': _AuthAction(services, _AuthOp.logout),
        'auth.me': _AuthAction(services, _AuthOp.me),
        'cache.get': _CacheAction(services, _CacheOp.get),
        'cache.set': _CacheAction(services, _CacheOp.set),
        'cache.remove': _CacheAction(services, _CacheOp.remove),
      };

  static void _registerPipes() {
    QLPipes.register('currency', (val, args) {
      final symbol = args.isNotEmpty ? args.first : r'$';
      final amount = num.tryParse(val?.toString() ?? '') ?? 0;
      return '$symbol${amount.toStringAsFixed(2)}';
    });
    QLPipes.register('percent', (val, args) {
      final amount = num.tryParse(val?.toString() ?? '') ?? 0;
      return '${amount.toStringAsFixed(args.isNotEmpty ? int.tryParse(args.first) ?? 1 : 1)}%';
    });
    QLPipes.register('pluck', (val, args) {
      if (val is! Iterable || args.isEmpty) return const [];
      final key = args.first;
      final out = <dynamic>[];
      for (final item in val) {
        if (item is Map) {
          final picked = item[key];
          if (picked != null) out.add(picked);
        }
      }
      return out;
    });
  }
}

// ── ACTION PLUGINS ──
class _SetStateAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final key = payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    final value =
        payload.containsKey('value') ? payload['value'] : payload['data'];
    store.set(key, value);
    return value;
  }
}

class _MergeStateAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final data = (payload['data'] ?? payload['value']) as Map?;
    if (data == null) return null;
    store.merge(data.cast<String, dynamic>(),
        clearMissing: payload['clearMissing'] == true);
    return data;
  }
}

class _ToggleStateAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final key = payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    final next = !(store.get(key) == true);
    store.set(key, next);
    return next;
  }
}

class _RemoveStateAction extends QLActionPlugin {
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final key = payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    store.sweep(key);
    return true;
  }
}

class _ApiReadAction extends QLActionPlugin {
  final QuantumRuntimeServices services;
  _ApiReadAction(this.services);
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final client = await services.ensureApi();
    if (client == null) return null;
    final slug = (payload['collection'] ?? payload['slug'])?.toString();
    if (slug == null || slug.isEmpty) return null;
    final query =
        (payload['query'] as Map?)?.cast<String, dynamic>() ?? const {};
    final id = payload['id']?.toString();
    final result = await client.executeRead(
      slug: slug,
      query: id == null ? query : {...query, 'op': 'readById'},
      id: id,
    );
    return _storeResult(payload, store, result);
  }
}

class _ApiWriteAction extends QLActionPlugin {
  final QuantumRuntimeServices services;
  final String? defaultOp;
  _ApiWriteAction(this.services, {this.defaultOp});
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final client = await services.ensureApi();
    if (client == null) return null;
    final slug = (payload['collection'] ?? payload['slug'])?.toString();
    if (slug == null || slug.isEmpty) return null;
    final data = (payload['data'] ?? payload['body']) as Map?;
    final body = data?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final op = (payload['op'] ?? defaultOp ?? 'upsert').toString();
    final id = payload['id']?.toString();
    final result =
        await client.executeWrite(slug: slug, op: op, body: body, id: id);
    return _storeResult(payload, store, result);
  }
}

enum _AuthOp { login, register, logout, me }

class _AuthAction extends QLActionPlugin {
  final QuantumRuntimeServices services;
  final _AuthOp op;
  _AuthAction(this.services, this.op);
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final client = await services.ensureApi();
    if (client == null) return null;
    final data = (payload['data'] ?? payload['credentials']) as Map?;
    final body = data?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final result = switch (op) {
      _AuthOp.login => await client.auth().login(body),
      _AuthOp.register => await client.auth().register(body),
      _AuthOp.logout => await client.auth().logout(),
      _AuthOp.me => await client.auth().me(),
    };
    return _storeResult(payload, store, result);
  }
}

enum _CacheOp { get, set, remove }

class _CacheAction extends QLActionPlugin {
  final QuantumRuntimeServices services;
  final _CacheOp op;
  _CacheAction(this.services, this.op);
  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx) async {
    final client = await services.ensureApi();
    if (client == null) return null;
    final key = payload['key']?.toString();
    if (key == null || key.isEmpty) return null;
    final result = switch (op) {
      _CacheOp.get => await client.cacheGet(key),
      _CacheOp.set => await client
          .cacheSet(key, payload['value'])
          .then((_) => payload['value']),
      _CacheOp.remove => await client.cacheRemove(key).then((_) => true),
    };
    return _storeResult(payload, store, result);
  }
}

dynamic _storeResult(
    Map<String, dynamic> payload, QLDataStore store, dynamic result) {
  final resultKey = payload['resultKey']?.toString();
  if (resultKey != null && resultKey.isNotEmpty) {
    store.set(resultKey, result);
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  THE GOD-MODE ENVIRONMENT & MODULAR DOMAINS
// ────────────────────────────────────────────────────────────────────────────

/// Exposes literally the entire Quantum Framework engine instances.
/// Allows Domain Orchestrators and Action Factories to intercept, modify,
/// and rewrite the matrix dynamically.
class QuantumAppEnvironment {
  final QLNavController router;
  final QuantumVM vm;
  final QEngine primitives;
  final QLNativeBridgeRegistry nativeBridges;
  final QLPipelineRegistry pipelines;
  final QLSchemaRegistry schemas;
  final QLStoreRegistry stores;
  final QLAsyncRegistry asyncSignals;
  final QuantumOverlay overlays;
  final QuantumTelemetry telemetry;
  final QuantumRuntimeServices services; // 🚀 INJECTED HERE
  final QuantumAppConfig config;

  QuantumAppEnvironment({
    required this.router,
    required this.vm,
    required this.primitives,
    required this.nativeBridges,
    required this.pipelines,
    required this.schemas,
    required this.stores,
    required this.asyncSignals,
    required this.overlays,
    required this.telemetry,
    required this.services,
    required this.config,
  });
}

typedef QuantumDomainOrchestrator = FutureOr<void> Function(
    QuantumAppEnvironment env);

class QuantumDomain {
  final String name;
  final List<QLRoute> routes;

  // Existing Base Registries
  final List<QLPlugin> sduiPlugins;
  final Map<String, QLActionPlugin> sduiActions;
  final Map<String, Object> nativeBridges;
  final Map<String, dynamic> initialStoreData;

  // 🚀 MISSING GAPS ADDED (Absolute Declarative Injection)
  final Map<String, Widget Function(QLContext)> sduiComponents;
  final Map<String, dynamic Function(dynamic, List<String>)> sduiPipes;
  final Map<String, Map<String, dynamic>> schemas;
  final List<ActionMiddleware> actionMiddlewares;
  final List<QLMiddleware> routeMiddlewares;

  // 🚀 DEPENDENCY INJECTION: Factories that receive the God-Mode Environment
  final Map<String, QLActionPlugin Function(QuantumAppEnvironment env)>
      actionFactories;

  // 🚀 THE GOD-MODE HOOKS
  final QuantumDomainOrchestrator? onInitialize;
  final QuantumDomainOrchestrator? orchestrator;

  const QuantumDomain({
    required this.name,
    this.routes = const [],
    this.sduiPlugins = const [],
    this.sduiActions = const {},
    this.nativeBridges = const {},
    this.initialStoreData = const {},
    this.sduiComponents = const {},
    this.sduiPipes = const {},
    this.schemas = const {},
    this.actionMiddlewares = const [],
    this.routeMiddlewares = const [],
    this.actionFactories = const {}, // 🚀 Added
    this.onInitialize,
    this.orchestrator,
  });
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  PAYLOAD-STYLE MASTER CONFIGURATION
// ────────────────────────────────────────────────────────────────────────────

class QuantumTelemetryConfig {
  final bool enabled;
  final bool enableFrameMonitorInDebug;
  final Widget Function(
          dynamic error, StackTrace stack, Map<String, dynamic> dump)?
      crashFallbackUI;

  const QuantumTelemetryConfig({
    this.enabled = true,
    this.enableFrameMonitorInDebug = true,
    this.crashFallbackUI,
  });
}

class QuantumRouterConfig {
  final String initialRoute;
  final List<QLMiddleware> globalMiddlewares;
  final Widget? notFoundWidget;

  const QuantumRouterConfig({
    this.initialRoute = '/',
    this.globalMiddlewares = const [],
    this.notFoundWidget,
  });
}

class QuantumVMConfig {
  final int workerThreads;
  final int simdArenaCapacity;
  final List<ActionMiddleware> actionMiddlewares;

  const QuantumVMConfig({
    this.workerThreads = 4,
    this.simdArenaCapacity = 4096,
    this.actionMiddlewares = const [],
  });
}

class QuantumAppConfig {
  final String appName;
  final String? title;
  final ThemeMode themeMode;
  final ThemeData? lightTheme;
  final ThemeData? darkTheme;
  final List<QuantumDomain> domains;
  final QuantumRouterConfig router;
  final QuantumTelemetryConfig telemetry;
  final QuantumVMConfig vm;
  final QuantumProductionRegistry? registry;
  final QuantumRuntimeServices services; // 🚀 INJECTED HERE
  final Future<void> Function()? onBoot;
  final Future<void> Function(BuildContext context)? onReady;

  const QuantumAppConfig({
    required this.appName,
    this.title,
    this.themeMode = ThemeMode.system,
    this.lightTheme,
    this.darkTheme,
    required this.domains,
    required this.telemetry,
    this.router = const QuantumRouterConfig(),
    this.vm = const QuantumVMConfig(),
    this.registry,
    this.services = const QuantumRuntimeServices(), // 🚀 Added
    this.onBoot,
    this.onReady,
  });
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  THE BOOTSTRAPPER (Insane Fast Launch & Zone Matcher)
// ────────────────────────────────────────────────────────────────────────────

// ════════════════════════════════════════════════════════════════════════════
// THE BOOTSTRAPPER (Insane Fast Launch & Zone Matcher)
// ════════════════════════════════════════════════════════════════════════════

void bootQuantumApp(QuantumAppConfig config) {
  QLNavController? appRouter;

  QuantumSingularity.ignite(
    appBuilder: () => _QuantumAppShell(config: config, router: appRouter!),
    fallbackUI: config.telemetry.crashFallbackUI,
    bootSequence: () {
      final binding = WidgetsFlutterBinding.ensureInitialized();
      binding.deferFirstFrame();

      try {
        // 🚀 1. Boot lowest-level hardware engines SYNCHRONOUSLY
        QEngine.instance
            .initialize(initialCapacity: config.vm.simdArenaCapacity);
        QuantumVM.instance.initialize(workerThreads: config.vm.workerThreads);

        // 🚀 2. Build the Router SYNCHRONOUSLY (so it's guaranteed before runApp)
        final List<QLRoute> allRoutes =
            config.domains.expand((domain) => domain.routes).toList();
        final List<QLMiddleware> mergedRouteMiddlewares = [
          ...config.router.globalMiddlewares,
          ...config.domains.expand((domain) => domain.routeMiddlewares),
        ];

        appRouter = QLNavController(
          routes: allRoutes,
          initialRoute: config.router.initialRoute,
          globalMiddlewares: mergedRouteMiddlewares,
          notFoundWidget: config.router.notFoundWidget,
        );

        // 🚀 3. Build the God-Mode Environment SYNCHRONOUSLY
        final QuantumAppEnvironment env = QuantumAppEnvironment(
          router: appRouter!,
          vm: QuantumVM.instance,
          primitives: QEngine.instance,
          nativeBridges: QLNativeBridgeRegistry.instance,
          pipelines: QLPipelineRegistry.instance,
          schemas: QLSchemaRegistry.instance,
          stores: QLStoreRegistry.instance,
          asyncSignals: QLAsyncRegistry.instance,
          overlays: QuantumOverlay.instance,
          telemetry: QuantumTelemetry.instance,
          services: config.services, // Passes API/Auth/Cache
          config: config,
        );

        // 🚀 4. Merge and Apply Action Middlewares globally SYNCHRONOUSLY
        final List<ActionMiddleware> mergedActionMiddlewares = [
          ...config.vm.actionMiddlewares,
          ...config.domains.expand((d) => d.actionMiddlewares),
        ];
        QuantumVM.instance.setMiddlewares(mergedActionMiddlewares);

        // 🚀 5. Register all domain capabilities SYNCHRONOUSLY
        for (final domain in config.domains) {
          domain.sduiComponents.forEach((name, builder) {
            QuantumVM.instance.define(name, builder);
          });
          domain.sduiPipes.forEach((name, transform) {
            QLPipes.register(name, transform);
          });
          domain.schemas.forEach((name, def) {
            QLSchemaRegistry.instance.registerRaw(name, def);
          });
          for (final plugin in domain.sduiPlugins) {
            QuantumVM.instance.registerPlugin(plugin);
          }
          domain.sduiActions.forEach((name, action) {
            QuantumVM.instance.registerAction(name, action);
          });
          domain.actionFactories.forEach((name, factory) {
            QuantumVM.instance.registerAction(name, factory(env));
          });
          domain.nativeBridges.forEach((channel, bridge) {
            QLNativeBridgeRegistry.instance.register(channel, bridge);
          });
          if (domain.initialStoreData.isNotEmpty) {
            QuantumVM.instance.store.merge(domain.initialStoreData);
          }
        }

        // 🚀 6. Install Production Registry or Built-ins SYNCHRONOUSLY
        if (config.registry != null) {
          config.registry!.install(QuantumVM.instance);
        } else {
          QuantumProductionRegistry(services: config.services)
              .install(QuantumVM.instance);
        }

        // 🚀 7. Execute Async Domain Orchestrators and Boot Hooks ASYNCHRONOUSLY
        // Only run things that actually require an await down here
        scheduleMicrotask(() async {
          try {
            if (config.onBoot != null) {
              await config.onBoot!();
            }

            await Future.wait(config.domains.map((domain) async {
              if (domain.onInitialize != null) await domain.onInitialize!(env);
              if (domain.orchestrator != null) await domain.orchestrator!(env);
            }));
          } catch (e, st) {
            debugPrint('🚨 CRITICAL BOOT FAILURE: $e\n$st');
            QuantumTelemetry.instance
                .record(QLType.anomaly, 'boot_sequence_failed');
          } finally {
            binding.allowFirstFrame();
          }
        });
      } catch (e, st) {
        debugPrint('🚨 CRITICAL SYNCHRONOUS BOOT FAILURE: $e\n$st');
        QuantumTelemetry.instance
            .record(QLType.anomaly, 'boot_sequence_failed');
        binding.allowFirstFrame(); // Don't brick the app on sync throw
        rethrow;
      }
    },
  );
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  THE ROOT APP SHELL (O(1) Builders & Compositors)
// ────────────────────────────────────────────────────────────────────────────

class _QuantumAppShell extends StatefulWidget {
  final QuantumAppConfig config;
  final QLNavController router;

  const _QuantumAppShell({required this.config, required this.router});

  @override
  State<_QuantumAppShell> createState() => _QuantumAppShellState();
}

class _QuantumAppShellState extends State<_QuantumAppShell> {
  late final QLRouterDelegate _routerDelegate;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void reassemble() {
    super.reassemble();
    if (kDebugMode) {
      QuantumYamlEngine.instance.clearCaches();
      QuantumVM.instance.clearRuntimeCaches();
      QJsonPresetEngine.clear();
      QLSchemaRegistry.instance.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _routerDelegate = QLRouterDelegate(widget.router);

    if (widget.config.onReady != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final BuildContext deepContext =
            _routerDelegate.navigatorKey?.currentContext ?? context;
        if (deepContext.mounted) {
          widget.config.onReady!(deepContext);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QLBridgeScope(
      registry: QLNativeBridgeRegistry.instance,
      child: MaterialApp.router(
        scaffoldMessengerKey: _scaffoldMessengerKey,
        title: widget.config.title ?? widget.config.appName,
        themeMode: widget.config.themeMode,
        theme: widget.config.lightTheme ?? ThemeData.light(),
        darkTheme: widget.config.darkTheme ?? ThemeData.dark(),
        debugShowCheckedModeBanner: false,
        routeInformationParser: const QLRouteParser(),
        routerDelegate: _routerDelegate,
        builder: (context, child) {
          Widget appLayer = child ?? const SizedBox.shrink();

          appLayer = Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            body: appLayer,
          );

          appLayer = QuantumVMRoot(
            workerThreads: widget.config.vm.workerThreads,
            child: appLayer,
          );

          appLayer = QLOverlayRoot(child: appLayer);

          if (widget.config.telemetry.enableFrameMonitorInDebug && kDebugMode) {
            appLayer = QLFrameMonitor(showOverlay: true, child: appLayer);
          }

          return appLayer;
        },
      ),
    );
  }
}

extension QuantumAppShellContextExt on BuildContext {
  QLNavController get qlRouter {
    final delegate = Router.of(this).routerDelegate as QLRouterDelegate;
    return delegate.controller;
  }
}
