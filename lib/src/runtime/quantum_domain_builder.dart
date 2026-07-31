// ════════════════════════════════════════════════════════════════════════════
// quantum_domain_builder.dart
//
// Fluent helpers for building QuantumDomain objects with minimal boilerplate.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';
import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/src/runtime/api/network_shell.dart';

/// Convenience factory for fluent domain construction.
QuantumDomainBuilder quantumDomain(String name) => QuantumDomainBuilder(name);

/// A lightweight fluent builder for domain plugins and registry surfaces.
///
/// This is designed to reduce the amount of handwritten boilerplate needed to
/// assemble a [QuantumDomain] while still keeping the final object fully
/// explicit and inspectable.
class QuantumDomainBuilder {
  final String name;

  final List<QLRoute> _routes = <QLRoute>[];
  final List<QLPlugin> _plugins = <QLPlugin>[];
  final Map<String, QLActionPlugin> _actions = <String, QLActionPlugin>{};
  final Map<String, Object> _nativeBridges = <String, Object>{};
  final Map<String, dynamic> _initialStoreData = <String, dynamic>{};
  final Map<String, Widget Function(QLContext)> _components =
      <String, Widget Function(QLContext)>{};
  final Map<String, dynamic Function(dynamic, List<String>)> _pipes =
      <String, dynamic Function(dynamic, List<String>)>{};
  final Map<String, Map<String, dynamic>> _schemas =
      <String, Map<String, dynamic>>{};
  final List<ActionMiddleware> _actionMiddlewares = <ActionMiddleware>[];
  final List<QLMiddleware> _routeMiddlewares = <QLMiddleware>[];
  final Map<String, QLActionPlugin Function(QuantumAppEnvironment env)>
      _actionFactories =
      <String, QLActionPlugin Function(QuantumAppEnvironment env)>{};

  QuantumDomainOrchestrator? _onInitialize;
  QuantumDomainOrchestrator? _orchestrator;

  QuantumDomainBuilder(this.name);

  QuantumDomainBuilder route(QLRoute route) {
    _routes.add(route);
    return this;
  }

  QuantumDomainBuilder plugin(QLPlugin plugin) {
    _plugins.add(plugin);
    return this;
  }

  QuantumDomainBuilder action(String key, QLActionPlugin plugin) {
    _actions[key] = plugin;
    return this;
  }

  /// Declares a proxy action that forwards to another Quantum action request.
  QuantumDomainBuilder proxyAction(
    String key, {
    String? domain,
    String? action,
    String? resource,
    Map<String, dynamic> args = const {},
    bool mergePayload = true,
    bool throwOnError = false,
  }) {
    _actions[key] = _QuantumProxyActionPlugin(
      defaultDomain: domain,
      defaultAction: action,
      defaultResource: resource,
      defaultArgs: args,
      mergePayload: mergePayload,
      throwOnError: throwOnError,
    );
    return this;
  }

  QuantumDomainBuilder component(
    String key,
    Widget Function(QLContext) builder,
  ) {
    _components[key] = builder;
    return this;
  }

  QuantumDomainBuilder pipe(
    String key,
    dynamic Function(dynamic, List<String>) transform,
  ) {
    _pipes[key] = transform;
    return this;
  }

  QuantumDomainBuilder schema(String key, Map<String, dynamic> schema) {
    _schemas[key] = Map<String, dynamic>.from(schema);
    return this;
  }

  QuantumDomainBuilder bridge(String key, Object bridge) {
    _nativeBridges[key] = bridge;
    return this;
  }

  QuantumDomainBuilder initialStore(Map<String, dynamic> data) {
    _initialStoreData.addAll(data);
    return this;
  }

  QuantumDomainBuilder actionMiddleware(ActionMiddleware middleware) {
    _actionMiddlewares.add(middleware);
    return this;
  }

  QuantumDomainBuilder routeMiddleware(QLMiddleware middleware) {
    _routeMiddlewares.add(middleware);
    return this;
  }

  QuantumDomainBuilder onInitialize(QuantumDomainOrchestrator hook) {
    _onInitialize = hook;
    return this;
  }

  QuantumDomainBuilder orchestrator(QuantumDomainOrchestrator hook) {
    _orchestrator = hook;
    return this;
  }

  QuantumDomainBuilder actionFactory(
    String key,
    QLActionPlugin Function(QuantumAppEnvironment env) factory,
  ) {
    _actionFactories[key] = factory;
    return this;
  }

  QuantumDomain build() {
    return QuantumDomain(
      name: name,
      routes: List<QLRoute>.unmodifiable(_routes),
      sduiPlugins: List<QLPlugin>.unmodifiable(_plugins),
      sduiActions: Map<String, QLActionPlugin>.unmodifiable(_actions),
      nativeBridges: Map<String, Object>.unmodifiable(_nativeBridges),
      initialStoreData: Map<String, dynamic>.unmodifiable(_initialStoreData),
      sduiComponents:
          Map<String, Widget Function(QLContext)>.unmodifiable(_components),
      sduiPipes:
          Map<String, dynamic Function(dynamic, List<String>)>.unmodifiable(
              _pipes),
      schemas: Map<String, Map<String, dynamic>>.unmodifiable(_schemas),
      actionMiddlewares:
          List<ActionMiddleware>.unmodifiable(_actionMiddlewares),
      routeMiddlewares: List<QLMiddleware>.unmodifiable(_routeMiddlewares),
      actionFactories: Map<
          String,
          QLActionPlugin Function(
              QuantumAppEnvironment env)>.unmodifiable(_actionFactories),
      onInitialize: _onInitialize,
      orchestrator: _orchestrator,
    );
  }

  /// Builds a domain from a plain JSON map.
  ///
  /// Supported JSON keys:
  /// - `name`: required domain name.
  /// - `initialStoreData` / `store`: map merged into the domain store.
  /// - `actions`: map of action name → proxy descriptor or string target.
  /// - `schemas`: map of schema name → schema JSON.
  /// - `nativeBridges`: map of bridge name → bridge object reference.
  /// - `components`: map of component name → widget builder is not expressible
  ///   in JSON and is therefore ignored by this helper.
  /// - `pipes`: map of pipe name → transform descriptor is ignored here.
  static QuantumDomain fromJson(Map<String, dynamic> json) {
    final String name = (json['name'] ?? json['id'] ?? '').toString().trim();
    if (name.isEmpty) {
      throw ArgumentError(
        '[QuantumDomainBuilder.fromJson] JSON must contain a non-empty "name" field.',
      );
    }

    final builder = QuantumDomainBuilder(name);

    final dynamic initialStore = json['initialStoreData'] ?? json['store'];
    if (initialStore is Map) {
      builder.initialStore(initialStore.cast<String, dynamic>());
    }

    final dynamic schemas = json['schemas'];
    if (schemas is Map) {
      for (final entry in schemas.entries) {
        if (entry.value is Map) {
          builder.schema(
            entry.key.toString(),
            Map<String, dynamic>.from(entry.value.cast<String, dynamic>()),
          );
        }
      }
    }

    final dynamic bridges = json['nativeBridges'] ?? json['bridges'];
    if (bridges is Map) {
      for (final entry in bridges.entries) {
        builder.bridge(entry.key.toString(), entry.value as Object);
      }
    }

    final dynamic actions = json['actions'];
    if (actions is Map) {
      for (final entry in actions.entries) {
        final String key = entry.key.toString();
        final dynamic value = entry.value;
        if (value is String) {
          final parts = value.split('.');
          final String? domain = parts.length > 1 ? parts.first : null;
          final String action =
              parts.length > 1 ? parts.sublist(1).join('.') : value;
          builder.proxyAction(key, domain: domain, action: action);
        } else if (value is Map) {
          final Map<String, dynamic> v =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          builder.proxyAction(
            key,
            domain: v['domain']?.toString(),
            action: v['action']?.toString(),
            resource: v['resource']?.toString(),
            args:
                v['args'] is Map ? v['args'].cast<String, dynamic>() : const {},
            mergePayload: v['mergePayload'] != false,
            throwOnError: v['throwOnError'] == true,
          );
        }
      }
    }

    return builder.build();
  }
}

class _QuantumProxyActionPlugin extends QLActionPlugin {
  final String? defaultDomain;
  final String? defaultAction;
  final String? defaultResource;
  final Map<String, dynamic> defaultArgs;
  final bool mergePayload;
  final bool throwOnError;

  _QuantumProxyActionPlugin({
    required this.defaultDomain,
    required this.defaultAction,
    required this.defaultResource,
    required this.defaultArgs,
    required this.mergePayload,
    required this.throwOnError,
  });

  @override
  Future<dynamic> execute(
    Map<String, dynamic> payload,
    QLDataStore store,
    BuildContext ctx,
  ) async {
    final Map<String, dynamic> request = <String, dynamic>{
      if (defaultDomain != null && defaultDomain!.isNotEmpty)
        'domain': defaultDomain,
      if (defaultAction != null && defaultAction!.isNotEmpty)
        'action': defaultAction,
      if (defaultResource != null && defaultResource!.isNotEmpty)
        'resource': defaultResource,
      if (defaultArgs.isNotEmpty)
        'args': Map<String, dynamic>.from(defaultArgs),
    };

    if (mergePayload) {
      request.addAll(payload);
    }

    final dynamic args = request['args'];
    if (args is Map) {
      final mergedArgs =
          Map<String, dynamic>.from(args.cast<String, dynamic>());
      if (payload['args'] is Map) {
        mergedArgs.addAll(
            Map<String, dynamic>.from(payload['args'].cast<String, dynamic>()));
      }
      request['args'] = mergedArgs;
    } else if (payload['args'] is Map) {
      request['args'] =
          Map<String, dynamic>.from(payload['args'].cast<String, dynamic>());
    }

    final dynamic result = await Quantum.runAction(request);
    if (throwOnError == true && result is Map && result['success'] != true) {
      throw StateError(
          result['error']?.toString() ?? 'Quantum proxy action failed.');
    }
    return result;
  }
}
