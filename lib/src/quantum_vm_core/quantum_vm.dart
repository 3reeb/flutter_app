/*
 * ============================================================================
 * File: quantum_vm.dart
 * 
 * Description:
 * The main orchestrator and entry point for the Quantum Virtual Machine (QVM). 
 * It manages the initialization, global state, plugins, design system bundles, 
 * and alias definitions, binding them together into an executable architecture 
 * for rendering dynamic UI blueprints.
 * 
 * Key Components:
 * - QuantumVM: The singleton class acting as the hub for the virtual machine.
 * - QLSignalBatch: A utility to defer and batch reactive state notifications.
 * - QLPluginStreamRegistry: A registry connecting Dart streams to observable nodes.
 * 
 * Dependencies/Relationships:
 * Integrates closely with quantum_vm_compiler.dart, quantum_vm_registry.dart, 
 * and quantum_vm_components.dart as part files. It acts as the backbone for 
 * the Quantum Execution Engine (QEE).
 * 
 * Notes:
 * This file serves as a God-object in the architecture, coordinating everything 
 * from UI routing to macro actions and zero-GC signaling.
 * ============================================================================
 */
// QUANTUM VIRTUAL MACHINE (QVM) v11.0 - GOD-MODE OMEGA CORE
// quantum_vm.dart
//
// BREAKTHROUGHS & REFACTORING:
// 1. Data Store / Runtime Caches fully decoupled to quantum_state.dart.
// 2. O(1) AST "Colon Syntax" (Base:Sub) & Alias Registry natively integrated.
// 3. Implicit Behaviors: Eliminates AST nesting overhead by pushing logic into cores.
// 4. Array-based Box Model integration ready via QSimdArena bypasses.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:quantum_layout/quantum.dart';
import 'quantum_vm_catalog.dart';
import './qee/qee_registry.dart';

part 'quantum_vm_compiler.dart';
part 'quantum_vm_registry.dart';
part 'quantum_vm_components.dart';
part 'quantum_vm_layout.dart';

class QuantumSecurityException implements Exception {
  final String message;
  const QuantumSecurityException(this.message);
  @override
  String toString() => 'QuantumSecurityException: $message';
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// ZERO-GC SIGNAL BATCHING
// Defers all signal notifications until the batch ends, preventing N rebuilds
// from N consecutive signal.value = ... assignments.
// Usage: QLSignalBatch.run(() { store.set('a', 1); store.set('b', 2); });
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
abstract final class QLSignalBatch {
  static bool _inBatch = false;
  static final List<ChangeNotifier> _pending = [];

  /// Run [fn] inside a batch. All QLSignal/ChangeNotifier notifications queued
  /// inside [fn] are deferred and fired once, in order, when [fn] returns.
  static void run(void Function() fn) {
    _inBatch = true;
    try {
      fn();
    } finally {
      _inBatch = false;
      for (final s in _pending) {
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        s.notifyListeners();
      }
      _pending.clear();
    }
  }

  static void enqueue(ChangeNotifier s) {
    if (_inBatch && !_pending.contains(s)) _pending.add(s);
  }

  static bool get isActive => _inBatch;
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// PLUGIN STREAM REGISTRY
// Platform plugins register named Dart Streams here for hook:observable nodes.
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
abstract final class QLPluginStreamRegistry {
  static final Map<String, Stream<dynamic>> _streams = {};
  static void register(String key, Stream<dynamic> s) => _streams[key] = s;
  static Stream<dynamic>? get(String key) => _streams[key];
  static bool has(String key) => _streams.containsKey(key);
  static void unregister(String key) => _streams.remove(key);
  static Iterable<String> get keys => _streams.keys;
}

// Note: Apply the exact same QLAstInspector.isReactive check to _MicroSliverPlugin and _MicroLayoutPlugin.
abstract class QLPlugin {
  String get type;
  Map<String, dynamic> get defaultProps => const {};
}

abstract class QLWidgetCapability {
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store);
}

abstract class QLSliverCapability {
  Widget buildSliver(BuildContext ctx, QLBlueprint node, QLDataStore store);
}

abstract class QLLayoutCapability {
  Widget buildLayout(BuildContext ctx, QLBlueprint node, List<Widget> children,
      QLDataStore store);
}

abstract class QLGraphicsCapability {
  QLFragmentDraw buildFragment(
      QLContext ctx, QLBlueprint node, QLDataStore store);
}

abstract class QLKineticCapability {
  Widget buildKinetic(QLContext ctx, QLBlueprint node,
      QLAnimCompositor compositor, QLDataStore store);
}

abstract class QLComputeCapability {
  QLWorkerTask<dynamic, dynamic> buildTask(QLContext ctx, QLBlueprint node);
  dynamic buildInput(QLContext ctx, QLBlueprint node);
  void onTaskCompleted(QLContext ctx, dynamic result, QLDataStore store);
}

abstract class QLSandboxCapability {
  Future<dynamic> executeSandboxed(
      String script, Map<String, dynamic> memoryEnv);
}

abstract class QLSensorCapability {
  Widget buildSensor(
      QLContext ctx, QLBlueprint node, Widget child, QLDataStore store);
}

typedef ActionMiddleware = Future<void> Function(
    String action, Map<String, dynamic> payload, Future<void> Function() next);

class QuantumVM {
  static final QuantumVM instance = QuantumVM._();
  QuantumVM._();

  static SessionContext _sessionFromEnv(Map<String, dynamic> env) {
    final dynamic raw = env['session'] ?? env['auth'] ?? env['context'];
    if (raw is SessionContext) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return SessionContext(
        userId: map['userId']?.toString(),
        sessionId: map['sessionId']?.toString(),
        accessToken: map['accessToken']?.toString(),
        refreshToken: map['refreshToken']?.toString(),
        expiresAt: map['expiresAt'] is DateTime
            ? map['expiresAt'] as DateTime
            : DateTime.tryParse(map['expiresAt']?.toString() ?? ''),
        claims: map['claims'] is Map
            ? Map<String, dynamic>.from(map['claims'] as Map)
            : <String, dynamic>{},
        authProviderUsed: map['authProviderUsed']?.toString() ?? 'none',
        deviceId: map['deviceId']?.toString(),
      );
    }
    return const SessionContext(claims: <String, dynamic>{
      'roles': <String>['guest']
    });
  }

  QuantumPermissionDecision _nodePermissionDecision(
    BuildContext ctx,
    QLBlueprint node,
  ) {
    final Map<String, dynamic> env = QLDataScope.of(ctx);
    final dynamic rule = node.props['permission'] ??
        node.props['permissions'] ??
        node.props['guard'] ??
        node.props['visibleIf'] ??
        node.props['policy'];
    if (rule == null) {
      return const QuantumPermissionDecision.allow('no node rule');
    }
    return QuantumPermissionEngine.instance.evaluate(
      rule,
      QuantumPermissionContext.fromSession(
        _sessionFromEnv(env),
        env: <String, dynamic>{...env, 'node': node.toJson()},
        data: node.props,
        scope: 'sdui',
        resource: node.type,
        operation: 'render',
        feature: node.props['feature']?.toString(),
        schema: node.props['schema']?.toString(),
      ),
      meta: <String, dynamic>{'path': node.debugPath},
    );
  }

  final Map<String, int> _actionGenerations = {};
  int _globalActionDepth = 0;
  final Map<String, Map<String, dynamic>> _defaultSlotNodes = {};
  void registerDefaultSlotNodes(String alias, Map<String, dynamic> slots) {
    _defaultSlotNodes[alias] = slots;
    _registryEntries['slotnodes:$alias'] = QLRegistryEntry(
      id: 'slotnodes:$alias',
      kind: 'slotnodes',
      name: alias,
      description: 'Default slot nodes for $alias',
      engine: 'QuantumVM',
      tags: const ['slots', 'layout'],
      params: const {},
      metadata: {'slots': slots},
      registeredAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? getDefaultSlotNodes(String alias) =>
      _defaultSlotNodes[alias];

  QuantumDesignSystemBundle installDesignSystemManifest(
    Map<String, dynamic> manifest, {
    String? manifestId,
    bool overwrite = true,
  }) {
    final bundle = QuantumDesignSystemCompiler.compile(
      manifest,
      manifestId: manifestId,
    );
    if (!overwrite && _designSystems.containsKey(bundle.id)) {
      return _designSystems[bundle.id]!;
    }

    _designSystems[bundle.id] = bundle;
    _localManifests.put(bundle.id, Map<String, dynamic>.from(bundle.manifest),
        weight: QLRuntimeCacheSizer.estimate(bundle.manifest));

    bundle.aliases.forEach((alias, payload) {
      if (!overwrite && hasAlias(alias)) return;
      final targetType =
          payload['target']?.toString() ?? payload['type']?.toString() ?? '';
      if (targetType.isEmpty) return;
      defineAlias(
        alias,
        targetType,
        defaultProps: payload['props'] is Map
            ? Map<String, dynamic>.from(payload['props'] as Map)
            : const <String, dynamic>{},
        description: payload['description']?.toString(),
        metadata: payload['metadata'] is Map
            ? Map<String, dynamic>.from(payload['metadata'] as Map)
            : const <String, dynamic>{},
        tags: _asStringList(payload['tags']),
      );
    });

    bundle.slotTypes.forEach((name, payload) {
      if (!overwrite && getSlotTypes(name) != null) return;
      registerSlotTypes(
        name,
        Map<String, String>.fromEntries(
          payload.entries.map(
            (entry) => MapEntry(entry.key.toString(), entry.value.toString()),
          ),
        ),
      );
    });

    bundle.slotNodes.forEach((name, payload) {
      if (!overwrite && getDefaultSlotNodes(name) != null) return;
      registerDefaultSlotNodes(name, Map<String, dynamic>.from(payload));
    });

    bundle.templates.forEach((name, payload) {
      if (!overwrite && QJsonPresetEngine.lookup(name) != null) return;
      final Map<String, dynamic> def = Map<String, dynamic>.from(payload);
      def.putIfAbsent('name', () => name);
      QJsonPresetEngine.define(def);
    });

    bundle.layouts.forEach((name, payload) {
      if (!overwrite && QMatrixLayoutRegistry.has(name)) return;
      final Map<String, dynamic> def = Map<String, dynamic>.from(payload);
      def.putIfAbsent('name', () => name);
      defineMatrixLayoutJson(def);
    });

    void registerSectionEntries(
      String kind,
      Map<String, Map<String, dynamic>> section,
    ) {
      for (final entry in section.entries) {
        final sectionName = entry.key;
        _registryEntries['design_system:${bundle.id}:$kind:$sectionName'] =
            QLRegistryEntry(
          id: 'design_system:${bundle.id}:$kind:$sectionName',
          kind: kind,
          name: sectionName,
          description: entry.value['description']?.toString() ??
              '$kind $sectionName from ${bundle.id}',
          engine: 'QuantumDesignSystemCompiler',
          tags: ['design_system', 'manifest', kind],
          params: Map<String, dynamic>.from(entry.value),
          metadata: {
            'designSystem': bundle.id,
            'section': kind,
            'name': sectionName,
          },
          registeredAt: DateTime.now(),
        );
      }
    }

    for (final entry in bundle.components.entries) {
      final name = entry.key;
      final raw = Map<String, dynamic>.from(entry.value);
      raw.putIfAbsent('name', () => name);
      final compiled = _compileDefinitionFromRaw(
        raw,
        debugPath: 'design_system:${bundle.id}:component:$name',
        fallbackName: name,
        sourceNode: QLBlueprint(
          type: 'component',
          props: const <String, dynamic>{},
          children: const <QLBlueprint>[],
          debugPath: 'design_system:${bundle.id}:component:$name',
        ),
      );
      _registerComponentDefinition(compiled);
    }
    registerSectionEntries('native_component', bundle.components);
    registerSectionEntries('preset', bundle.templates);
    registerSectionEntries('layout', bundle.layouts);
    registerSectionEntries('action', bundle.actions);
    registerSectionEntries('behavior', bundle.behaviors);
    registerSectionEntries('workflow', bundle.workflows);
    registerSectionEntries('state_machine', bundle.stateMachines);
    registerSectionEntries('route', bundle.routes);
    registerSectionEntries('pack', bundle.packs);

    // Re-install structured schemas using the registry's own compiler when the
    // manifest provides raw schema maps. This keeps schema metadata visible in
    // the catalog without hard-coding any special-case widgets.
    if (bundle.coreSchemas.isNotEmpty || bundle.aliasSchemas.isNotEmpty) {
      QuantumCoreSchemaRegistry.instance.installDefaults(
        coreSchemas: bundle.coreSchemas,
        aliasSchemas: bundle.aliasSchemas,
      );
    }

    _registryEntries['design_system:${bundle.id}'] = QLRegistryEntry(
      id: 'design_system:${bundle.id}',
      kind: 'design_system',
      name: bundle.id,
      description:
          bundle.metadata['description']?.toString() ?? 'Design system bundle',
      engine: 'QuantumDesignSystemCompiler',
      tags: const ['design_system', 'manifest'],
      params: {
        'fingerprint': bundle.fingerprint,
        'sections': bundle.sectionCount,
        'tokens': bundle.tokens.keys.toList(growable: false),
      },
      metadata: bundle.toMap(),
      registeredAt: DateTime.now(),
    );

    return bundle;
  }

  QuantumDesignSystemBundle? getDesignSystemManifest(String id) =>
      _designSystems[id];

  Map<String, QuantumDesignSystemBundle> designSystemSnapshot() =>
      Map<String, QuantumDesignSystemBundle>.unmodifiable(_designSystems);

  List<String> designSystemIds() =>
      List<String>.unmodifiable(_designSystems.keys);

  Map<String, dynamic>? describeDesignSystem(String id) {
    final bundle = _designSystems[id];
    return bundle?.toMap();
  }

  // ًںڑ€ ALIAS REGISTRY
  final Map<String, Map<String, dynamic>> _aliases = {};
  final Map<String, Map<String, dynamic>> _variants = {};

  static Map<String, dynamic> _cloneMap(dynamic raw) {
    if (raw is Map) {
      return Map<String, dynamic>.fromEntries(
        raw.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
      );
    }
    return <String, dynamic>{};
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    if (raw is String && raw.isNotEmpty) return <String>[raw];
    return const <String>[];
  }

  static Map<String, dynamic> _schemaForValue(dynamic value) {
    if (value == null) {
      return const <String, dynamic>{'type': 'dynamic', 'nullable': true};
    }
    if (value is bool) {
      return const <String, dynamic>{'type': 'bool'};
    }
    if (value is int) {
      return const <String, dynamic>{'type': 'int'};
    }
    if (value is double) {
      return const <String, dynamic>{'type': 'double'};
    }
    if (value is String) {
      return <String, dynamic>{'type': 'String', 'example': value};
    }
    if (value is List) {
      return <String, dynamic>{
        'type': 'List<dynamic>',
        'items': value.isEmpty
            ? const <String, dynamic>{'type': 'dynamic'}
            : _schemaForValue(value.first),
      };
    }
    if (value is Map) {
      return <String, dynamic>{
        'type': 'Map<String, dynamic>',
        'properties': _schemaForMap(_cloneMap(value)),
      };
    }
    return <String, dynamic>{'type': value.runtimeType.toString()};
  }

  static Map<String, dynamic> _schemaForMap(Map<String, dynamic> map) {
    return <String, dynamic>{
      'type': 'object',
      'properties': {
        for (final entry in map.entries)
          entry.key: _schemaForValue(entry.value),
      },
      'required': map.keys.toList(growable: false),
    };
  }

  static String _humanizeTarget(String targetType) {
    final parts = targetType.split(':');
    return parts.isEmpty ? targetType : parts.last;
  }

  static Map<String, dynamic> _coreParamSchema(String type) {
    final subtypes =
        QuantumVMCatalog.omniCoreSubtypes[type] ?? const <String>[];
    return <String, dynamic>{
      'type': 'object',
      'properties': {
        '__subType': {'type': 'String', 'enum': subtypes},
        'style': {'type': 'String'},
        'props': {'type': 'Map<String, dynamic>'},
        'slots': {'type': 'Map<String, dynamic>'},
        'children': {'type': 'List<dynamic>'},
        'metadata': {'type': 'Map<String, dynamic>'},
        'actions': {'type': 'List<dynamic>'},
        'tags': {'type': 'List<dynamic>'},
      },
      'required': const <String>[],
      'subtypes': subtypes,
    };
  }

  static Map<String, dynamic> _coreInfoSchema({
    required String type,
    required String description,
    required List<String> tags,
    required String engine,
  }) {
    final subtypes =
        QuantumVMCatalog.omniCoreSubtypes[type] ?? const <String>[];
    return <String, dynamic>{
      'name': type,
      'kind': 'core',
      'description': description,
      'engine': engine,
      'tags': List<String>.unmodifiable(tags),
      'subtypes': subtypes,
      'subtypeCount': subtypes.length,
    };
  }

  static Map<String, dynamic> _coreFeatureSchema(
    String type, {
    required String description,
    required List<String> tags,
    required String engine,
  }) {
    final String core = type.contains(':') ? type.split(':').first : type;
    final Map<String, String> propTypes =
        QuantumVMCatalog.omniCoreFeaturePropTypes[core] ??
            const <String, String>{};
    final List<String> subtypes =
        QuantumVMCatalog.omniCoreSubtypes[core] ?? const <String>[];
    final Map<String, dynamic> properties = <String, dynamic>{
      '__subType': {'type': 'string', 'enum': subtypes},
      'style': {'type': 'string'},
      'props': {'type': 'object'},
      'slots': {'type': 'object'},
      'children': {'type': 'array'},
      'metadata': {'type': 'object'},
      'actions': {'type': 'array'},
      'tags': {'type': 'array'},
      for (final entry in propTypes.entries)
        entry.key: (() {
          final t = entry.value;
          if (t.startsWith('List')) return {'type': 'array', 'originalType': t};
          if (t.startsWith('Map')) return {'type': 'object', 'originalType': t};
          switch (t) {
            case 'String':
            case 'Color':
              return {'type': 'string', 'originalType': t};
            case 'int':
            case 'double':
            case 'num':
              return {'type': 'number', 'originalType': t};
            case 'bool':
              return {'type': 'boolean', 'originalType': t};
            default:
              return {'type': 'object', 'originalType': t};
          }
        })(),
    };
    return <String, dynamic>{
      'paramSchema': <String, dynamic>{
        'type': 'object',
        'properties': properties,
        'required': const <String>[],
        'additionalProperties': true,
        'subtypes': subtypes,
        'featureProps': propTypes.keys.toList(growable: false),
      },
      'infoSchema': _buildInfoSchema(
        name: core,
        kind: 'core',
        description: description,
        tags: tags,
        engine: engine,
        extra: <String, dynamic>{
          'sourceFile': QuantumVMCatalog.omniCoreFeatureCatalog[core]
              ?['sourceFile'],
          'aliasCount': QuantumVMCatalog.omniCoreFeatureCatalog[core]
              ?['aliasCount'],
          'defineCount': QuantumVMCatalog.omniCoreFeatureCatalog[core]
              ?['defineCount'],
          'propCount': QuantumVMCatalog.omniCoreFeatureCatalog[core]
              ?['propCount'],
          'featureProps': QuantumVMCatalog.omniCoreFeatureCatalog[core]
              ?['featureProps'],
          'propTypes': propTypes,
          'subtypes': subtypes,
        },
      ),
      'featureProps': QuantumVMCatalog.omniCoreFeatureCatalog[core]
              ?['featureProps'] ??
          const <String>[],
      'propTypes': propTypes,
      'sourceFile': QuantumVMCatalog.omniCoreFeatureCatalog[core]
          ?['sourceFile'],
      'aliasCount': QuantumVMCatalog.omniCoreFeatureCatalog[core]
          ?['aliasCount'],
      'defineCount': QuantumVMCatalog.omniCoreFeatureCatalog[core]
          ?['defineCount'],
    };
  }

  static Map<String, dynamic> _buildInfoSchema({
    required String name,
    required String kind,
    required String description,
    required List<String> tags,
    required String engine,
    Map<String, dynamic>? extra,
  }) {
    return <String, dynamic>{
      'name': name,
      'kind': kind,
      'description': description,
      'engine': engine,
      'tags': List<String>.unmodifiable(tags),
      if (extra != null && extra.isNotEmpty) 'details': extra,
    };
  }

  void defineAlias(String alias, String targetType,
      {Map<String, dynamic> defaultProps = const {},
      String? description,
      Map<String, dynamic> metadata = const {},
      List<String> tags = const []}) {
    final Map<String, dynamic> clonedProps =
        Map<String, dynamic>.from(defaultProps);
    final String resolvedDescription = description ?? 'Alias for $targetType';
    final List<String> resolvedTags = tags.isNotEmpty
        ? List<String>.unmodifiable(tags)
        : List<String>.unmodifiable(<String>[
            'alias',
            targetType.split(':').first,
            _humanizeTarget(targetType),
          ]);
    final Map<String, dynamic> defaultPropsSchema = _schemaForMap(clonedProps);
    final Map<String, dynamic> featureSchema = _coreFeatureSchema(
      targetType,
      description: resolvedDescription,
      tags: resolvedTags,
      engine: 'QuantumVM',
    );
    final String targetKind =
        targetType.contains(':') ? targetType.split(':').first : targetType;
    final Map<String, dynamic> paramSchema = Map<String, dynamic>.from(
      featureSchema['paramSchema'] as Map? ?? defaultPropsSchema,
    );
    final Map<String, dynamic> infoSchema = Map<String, dynamic>.from(
      featureSchema['infoSchema'] as Map? ??
          _buildInfoSchema(
            name: alias,
            kind: 'alias',
            description: resolvedDescription,
            tags: resolvedTags,
            engine: 'QuantumVM',
            extra: <String, dynamic>{
              'targetType': targetType,
              'targetKind': targetKind,
              'targetName': _humanizeTarget(targetType),
              'defaultProps': clonedProps,
              'defaultPropsSchema': defaultPropsSchema,
            },
          ),
    )
      ..['alias'] = alias
      ..['targetType'] = targetType
      ..['targetKind'] = targetKind
      ..['targetName'] = _humanizeTarget(targetType)
      ..['defaultPropsSchema'] = defaultPropsSchema;

    _aliases[alias] = {'type': targetType, 'props': clonedProps};
    if (targetType.isNotEmpty && targetType != alias) {
      _aliases.putIfAbsent(
        targetType,
        () => {'type': targetType, 'props': clonedProps},
      );
    }
    _registryEntries['alias:$alias'] = QLRegistryEntry(
      id: 'alias:$alias',
      kind: 'alias',
      name: alias,
      description: resolvedDescription,
      engine: 'QuantumVM',
      tags: resolvedTags,
      params: {
        'targetType': targetType,
        'defaultProps': clonedProps,
        'paramSchema': paramSchema,
      },
      metadata: {
        ...metadata,
        'targetType': targetType,
        'targetKind': targetKind,
        'targetName': _humanizeTarget(targetType),
        'paramSchema': paramSchema,
        'infoSchema': infoSchema,
        'featureProps': featureSchema['featureProps'],
        'propTypes': featureSchema['propTypes'],
        'sourceFile': featureSchema['sourceFile'],
        'aliasCount': featureSchema['aliasCount'],
        'defineCount': featureSchema['defineCount'],
        'defaultPropsSchema': defaultPropsSchema,
        'description': resolvedDescription,
      },
      registeredAt: DateTime.now(),
    );
  }

  void defineVariant(
    String variant,
    String targetType, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    final Map<String, dynamic> clonedProps =
        Map<String, dynamic>.from(defaultProps);
    final String resolvedDescription =
        description ?? 'Variant for $targetType';
    final List<String> resolvedTags = tags.isNotEmpty
        ? List<String>.unmodifiable(tags)
        : List<String>.unmodifiable(<String>[
            'variant',
            targetType.split(':').first,
            _humanizeTarget(targetType),
          ]);
    _variants[variant] = <String, dynamic>{
      'type': targetType,
      'props': clonedProps,
      'variant': variant,
      'description': resolvedDescription,
      'metadata': Map<String, dynamic>.from(metadata),
      'tags': resolvedTags,
    };
    defineAlias(
      variant,
      targetType,
      defaultProps: clonedProps,
      description: resolvedDescription,
      metadata: <String, dynamic>{
        ...metadata,
        'kind': 'variant',
        'variant': variant,
      },
      tags: resolvedTags,
    );
    _registryEntries['variant:$variant'] = QLRegistryEntry(
      id: 'variant:$variant',
      kind: 'variant',
      name: variant,
      description: resolvedDescription,
      engine: 'QuantumVM',
      tags: resolvedTags,
      params: <String, dynamic>{
        'targetType': targetType,
        'defaultProps': clonedProps,
      },
      metadata: <String, dynamic>{
        ...metadata,
        'kind': 'variant',
        'variant': variant,
        'targetType': targetType,
      },
      registeredAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? getVariant(String variant) => _variants[variant];

  bool hasVariant(String variant) => _variants.containsKey(variant);

  void defineSurface(
    String name,
    Widget Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    Map<String, String> aliases = const {},
    Map<String, Map<String, dynamic>> variants = const {},
    String? description,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    define(
      name,
      builder,
      defaultProps: defaultProps,
      description: description,
      metadata: metadata,
      tags: tags,
    );
    for (final entry in aliases.entries) {
      defineAlias(
        entry.key,
        name,
        defaultProps: defaultProps,
        description: description == null ? null : '$description (alias: ${entry.key})',
        metadata: <String, dynamic>{
          ...metadata,
          'surface': name,
          'alias': entry.key,
          if (entry.value.isNotEmpty) 'aliasValue': entry.value,
        },
        tags: tags,
      );
    }
    for (final entry in variants.entries) {
      defineVariant(
        '$name:${entry.key}',
        name,
        defaultProps: entry.value,
        description: description == null ? null : '$description (variant: ${entry.key})',
        metadata: <String, dynamic>{
          ...metadata,
          'surface': name,
          'variant': entry.key,
        },
        tags: tags,
      );
    }
  }

  Map<String, dynamic>? getAlias(String alias) {
    final direct = _aliases[alias];
    if (direct != null) return direct;
    if (alias.contains(':')) {
      for (final entry in _aliases.values) {
        if (entry['type'] == alias) return entry;
      }
      return <String, dynamic>{'type': alias, 'props': const <String, dynamic>{}};
    }
    return null;
  }

  final Map<String, QLPlugin> _plugins = {};
  final Map<String, QLActionPlugin> _actions = {};
  final Map<String, QLRegistryEntry> _registryEntries = {};
  final Map<String, Map<String, String>> _slotDefaults = {};
  final Map<String, QuantumDesignSystemBundle> _designSystems = {};

  final QLDataStore store = QLStoreRegistry.instance.defaultStore;
  final QLRuntimeCache<QLSchemaSlice> schemaSlices =
      QLRuntimeCache<QLSchemaSlice>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 4096, maxWeight: 2 * 1024 * 1024));
  final QLRuntimeCache<QToken> _styleTokens = QLRuntimeCache<QToken>(
      config:
          const QLRuntimeCacheConfig(maxEntries: 4096, maxWeight: 1024 * 1024));
  final QLRuntimeCache<Map<String, dynamic>> _localManifests =
      QLRuntimeCache<Map<String, dynamic>>(
          config: const QLRuntimeCacheConfig(
              maxEntries: 128, maxWeight: 12 * 1024 * 1024));

  final Expando<_QLRenderHints> _renderHints = Expando<_QLRenderHints>();

  final Map<int, Timer> _debouncers = {};
  List<ActionMiddleware> _middlewares = [];

  QLWorkerPool? _workerPool;
  QLWorkerPool get workerPool =>
      _workerPool ??
      (throw StateError(
          'QuantumVM WorkerPool not initialized. Call initialize() first.'));

  QLAnimCompositor? _compositor;
  QLAnimCompositor get compositor =>
      _compositor ??
      (throw StateError(
          'QuantumVM Compositor not initialized. Wrap app in QuantumVMRoot.'));

  bool _isInitialized = false;

  void initialize({int workerThreads = 4}) {
    if (_isInitialized) return;
    _workerPool = QLWorkerPool(size: workerThreads);

    // 🚀 HOOK: Wire state slice registry directly to VM action dispatcher!
    QLSliceRegistry.actionRegistrar = registerAction;
    _registerCoreStateActions();

    // 🏗️ NATIVE LAYOUT: Register all built-in layout types, matrix shells,
    // and aliases. This runs BEFORE any external omni_core plugin, ensuring
    // layout is always available as a first-class built-in.
    _registerNativeLayoutCore(this);

    _isInitialized = true;
  }

  void _registerCoreStateActions() {
    registerAction(
      'state.set',
      LambdaActionPlugin((p, s, c) async {
        final key = p['key']?.toString();
        if (key == null || key.isEmpty) return null;
        final val = p.containsKey('value') ? p['value'] : p['data'];
        s.set(key, val);
        return val;
      }),
      description: 'Set a value in the global store',
      params: const {'key': 'String', 'value': 'dynamic'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    registerAction(
      'state.merge',
      LambdaActionPlugin((p, s, c) async {
        final raw = p['data'];
        if (raw is Map<String, dynamic>) {
          s.merge(raw);
        } else if (raw is Map) {
          s.merge(Map<String, dynamic>.from(raw));
        }
        return raw;
      }),
      description: 'Merge a map into the global store',
      params: const {'data': 'Map<String, dynamic>'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    registerAction(
      'state.toggle',
      LambdaActionPlugin((p, s, c) async {
        final key = p['key']?.toString();
        if (key == null || key.isEmpty) return null;
        final next = !(s.get(key) == true);
        s.set(key, next);
        return next;
      }),
      description: 'Toggle a boolean flag',
      params: const {'key': 'String'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    registerAction(
      'state.remove',
      LambdaActionPlugin((p, s, c) async {
        final key = p['key']?.toString();
        if (key == null || key.isEmpty) return null;
        s.sweep(key);
        return key;
      }),
      description: 'Remove a path from the global store',
      params: const {'key': 'String'},
      engine: 'QuantumVM',
      tags: const ['state', 'core'],
    );

    // ًںڑ€ FORM ACTIONS
    registerAction(
      'form.set',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        final value = p['value'];
        if (path == null) return null;
        final node = QLDataNode.globalNodes[path];
        if (node != null) node.mutate(value);
        return value;
      }),
      description: 'Safely mutates a form field.',
      params: const {'path': 'String', 'value': 'dynamic'},
      engine: 'QuantumVM',
    );

    registerAction(
      'form.reset',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        if (path == null) return null;
        final node = QLDataNode.globalNodes[path];
        if (node != null) node.reset();
        return null;
      }),
      description: 'Resets a field or form.',
      params: const {'path': 'String'},
      engine: 'QuantumVM',
    );

    registerAction(
      'form.array.add',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        if (path == null) return null;
        final node = QLDataNode.globalNodes[path];
        if (node is QLBlockArrayController) {
          node.addBlock(p['blockType']?.toString() ?? 'default');
        } else if (node is QLScalarArrayController) {
          node.push(p['value']);
        }
        return null;
      }),
      description: 'Adds an item to a form array/block list.',
      params: const {
        'path': 'String',
        'blockType': 'String',
        'value': 'dynamic'
      },
      engine: 'QuantumVM',
    );

    registerAction(
      'form.array.remove',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        final index = int.tryParse(p['index']?.toString() ?? '');
        if (path == null || index == null) return null;
        final node = QLDataNode.globalNodes[path];
        if (node is QLBlockArrayController) node.removeAt(index);
        if (node is QLScalarArrayController) node.removeAt(index);
        return null;
      }),
      description: 'Removes an item from a form array by index.',
      params: const {'path': 'String', 'index': 'int'},
      engine: 'QuantumVM',
    );

    registerAction(
      'form.media.clear',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        if (path == null) return null;
        final node = QLDataNode.globalNodes[path];
        if (node is QLMediaController) node.setMedia(null);
        return null;
      }),
      description: 'Clears a media field.',
      params: const {'path': 'String'},
      engine: 'QuantumVM',
    );

    registerAction(
      'form.load',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        final source = p['source']?.toString() ?? p['dataSource']?.toString();
        if (path == null) return null;

        final formNode = QLDataNode.globalNodes[path];
        if (formNode is! QLGroupController) return null;

        Map<String, dynamic>? data;
        if (source != null && QLDataSourceRegistry.instance.exists(source)) {
          final res =
              await QLDataSourceRegistry.instance.execute(source, 'read', p);
          if (res is Map) data = Map<String, dynamic>.from(res);
        } else {
          final storePath = p['storePath']?.toString() ?? path;
          final res = s.get(storePath);
          if (res is Map) data = Map<String, dynamic>.from(res);
        }

        if (data != null) {
          void hydrate(String prefix, Map<String, dynamic> map) {
            map.forEach((key, val) {
              final fullPath = prefix.isEmpty ? key : '$prefix.$key';
              if (val is Map) {
                hydrate(fullPath, Map<String, dynamic>.from(val));
              } else {
                final field = QLDataNode.globalNodes[fullPath];
                if (field != null) field.mutate(val, shouldValidate: false);
              }
            });
          }

          hydrate(path, data);
        }
        return data;
      }),
      description: 'Hydrates a form from an API DataSource or Global Store.',
      params: const {
        'path': 'String',
        'source': 'String',
        'storePath': 'String'
      },
      engine: 'QuantumVM',
    );

    // ًںڑ€ UPGRADED FORM SUBMIT ACTION (Form -> API SEND)
    registerAction(
      'form.submit',
      LambdaActionPlugin((p, s, c) async {
        final path = p['path']?.toString();
        if (path == null) return null;

        // 1. Gather all nodes that match the exact path OR start with the path prefix
        final nodesToValidate = QLDataNode.globalNodes.values.where((node) {
          return node.path == path ||
              node.path.startsWith('$path.') ||
              node.path.startsWith('$path[');
        }).toList();

        if (nodesToValidate.isEmpty) return null;

        // 2. Force validation concurrently on all fields
        await Future.wait(nodesToValidate.map((n) => n.validate()));

        // 3. Check if ANY field has an error
        final hasErrors = nodesToValidate.any((n) => !n.isValid);

        if (hasErrors) {
          throw QuantumSecurityException('Form validation failed at $path');
        }

        // 4. Extract the perfect JSON payload directly from the Form Graph!
        // This leverages your battle-tested extractSubgraph method.
        final graph = nodesToValidate.first.graph;
        Map<String, dynamic> payload;

        if (graph is QLFormController) {
          payload = graph.extractSubgraph(path);
          // If the prefix wasn't a group, extractSubgraph might return an empty map.
          if (payload.isEmpty &&
              nodesToValidate.length == 1 &&
              nodesToValidate.first.path == path) {
            payload = {'value': nodesToValidate.first.data.value};
          }
        } else {
          final raw = s.get(path);
          payload = raw is Map
              ? Map<String, dynamic>.from(raw)
              : (raw != null ? {'value': raw} : {});
        }

        // 5. Automatic API Dispatch
        final source = p['source']?.toString() ?? p['dataSource']?.toString();
        final operation =
            p['operation']?.toString() ?? p['op']?.toString() ?? 'create';

        if (source != null && QLDataSourceRegistry.instance.exists(source)) {
          return await QLDataSourceRegistry.instance.execute(
            source,
            operation,
            {'payload': payload, ...p},
          );
        }

        return payload;
      }),
      description:
          'Validates a form prefix and optionally submits it to an API.',
      params: const {
        'path': 'String',
        'dataSource': 'String',
        'operation': 'String'
      },
      engine: 'QuantumVM',
    );
  }

  void installBundle(QuantumExtensionBundle bundle, {bool overwrite = true}) {
    bundle.plugins.forEach((name, plugin) {
      if (!overwrite && hasPlugin(name)) return;
      registerPlugin(
        plugin,
        metadata: bundle.metadata[name] ?? const {},
      );
    });

    bundle.actions.forEach((name, action) {
      if (!overwrite && hasAction(name)) return;
      registerAction(
        name,
        action,
        metadata: bundle.metadata[name] ?? const {},
      );
    });

    bundle.aliases.forEach((alias, payload) {
      if (!overwrite && hasAlias(alias)) return;
      final targetType = payload['type']?.toString() ?? '';
      if (targetType.isEmpty) return;
      final defaultProps = Map<String, dynamic>.from(
        payload['props'] as Map? ?? const {},
      );
      defineAlias(
        alias,
        targetType,
        defaultProps: defaultProps,
        description: payload['description']?.toString(),
        metadata: Map<String, dynamic>.from(
          payload['metadata'] as Map? ?? const {},
        ),
        tags: _asStringList(payload['tags']),
      );
    });

    bundle.variants.forEach((variant, payload) {
      if (!overwrite && hasVariant(variant)) return;
      final targetType = payload['type']?.toString() ?? '';
      if (targetType.isEmpty) return;
      final defaultProps = Map<String, dynamic>.from(
        payload['props'] as Map? ?? const {},
      );
      defineVariant(
        variant,
        targetType,
        defaultProps: defaultProps,
        description: payload['description']?.toString(),
        metadata: Map<String, dynamic>.from(
          payload['metadata'] as Map? ?? const {},
        ),
        tags: _asStringList(payload['tags']),
      );
    });

    bundle.slotTypes.forEach((alias, types) {
      if (!overwrite && getSlotTypes(alias) != null) return;
      registerSlotTypes(alias, Map<String, String>.from(types));
    });

    bundle.slotNodes.forEach((alias, slots) {
      if (!overwrite && getDefaultSlotNodes(alias) != null) return;
      registerDefaultSlotNodes(alias, Map<String, dynamic>.from(slots));
    });
  }

  void attachCompositor(TickerProvider vsync) {
    if (_compositor != null) {
      try {
        _compositor!.dispose();
      } catch (_) {}
    }
    _compositor = QLAnimCompositor(vsync: vsync);
    _compositor!.activate();
  }

  void registerPlugin(
    QLPlugin p, {
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    final Map<String, dynamic> resolvedParams = params.isNotEmpty
        ? Map<String, dynamic>.from(params)
        : Map<String, dynamic>.from(p.defaultProps);
    final Map<String, dynamic> paramSchema = _schemaForMap(resolvedParams);
    final String resolvedDescription =
        description ?? _inferPluginDescription(p);
    final List<String> resolvedTags =
        tags.isNotEmpty ? List<String>.unmodifiable(tags) : _inferPluginTags(p);
    final String engineName = engine ?? p.runtimeType.toString();
    final String pluginKind = _inferPluginKind(p);
    final Map<String, dynamic> coreSchema =
        QuantumVMCatalog.omniCoreFeatureCatalog.containsKey(p.type)
            ? _coreFeatureSchema(
                p.type,
                description: resolvedDescription,
                tags: resolvedTags,
                engine: engineName,
              )
            : QuantumVMCatalog.omniCoreSubtypes.containsKey(p.type)
                ? <String, dynamic>{
                    'paramSchema': _coreParamSchema(p.type),
                    'infoSchema': _coreInfoSchema(
                      type: p.type,
                      description: resolvedDescription,
                      tags: resolvedTags,
                      engine: engineName,
                    ),
                    'subtypes': QuantumVMCatalog.omniCoreSubtypes[p.type],
                  }
                : const <String, dynamic>{};
    _plugins[p.type] = p;
    _registryEntries['plugin:${p.type}'] = QLRegistryEntry(
      id: 'plugin:${p.type}',
      kind: pluginKind,
      name: p.type,
      description: resolvedDescription,
      engine: engineName,
      tags: resolvedTags,
      params: resolvedParams,
      metadata: {
        ..._inferPluginMetadata(p),
        ...metadata,
        ...coreSchema,
        'paramSchema': coreSchema['paramSchema'] ?? paramSchema,
        'infoSchema': coreSchema['infoSchema'] ??
            _buildInfoSchema(
              name: p.type,
              kind: pluginKind,
              description: resolvedDescription,
              tags: resolvedTags,
              engine: engineName,
              extra: <String, dynamic>{
                'params': resolvedParams,
                'defaultProps': Map<String, dynamic>.from(p.defaultProps),
              },
            ),
      },
      registeredAt: DateTime.now(),
    );
  }

  void registerAction(
    String name,
    QLActionPlugin p, {
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) {
    final Map<String, dynamic> resolvedParams =
        Map<String, dynamic>.from(params);
    final Map<String, dynamic> paramSchema = _schemaForMap(resolvedParams);
    final String resolvedDescription = description ?? 'Action $name';
    final List<String> resolvedTags =
        tags.isNotEmpty ? List<String>.unmodifiable(tags) : const ['action'];
    _actions[name] = p;
    _registryEntries['action:$name'] = QLRegistryEntry(
      id: 'action:$name',
      kind: 'action',
      name: name,
      description: resolvedDescription,
      engine: engine ?? p.runtimeType.toString(),
      tags: resolvedTags,
      params: resolvedParams,
      metadata: {
        ...metadata,
        'paramSchema': paramSchema,
        'infoSchema': _buildInfoSchema(
          name: name,
          kind: 'action',
          description: resolvedDescription,
          tags: resolvedTags,
          engine: engine ?? p.runtimeType.toString(),
          extra: <String, dynamic>{'params': resolvedParams},
        ),
      },
      registeredAt: DateTime.now(),
    );
  }

  void registerSlotTypes(String alias, Map<String, String> types) {
    final Map<String, String> resolvedTypes = Map<String, String>.from(types);
    final Map<String, dynamic> resolvedTypesDynamic =
        Map<String, dynamic>.from(resolvedTypes);
    _slotDefaults[alias] = resolvedTypes;
    _registryEntries['slottype:$alias'] = QLRegistryEntry(
      id: 'slottype:$alias',
      kind: 'slottype',
      name: alias,
      description: 'Slot types for $alias',
      engine: 'QuantumVM',
      tags: const ['slots'],
      params: {
        'types': resolvedTypes,
        'paramSchema': _schemaForMap(resolvedTypesDynamic),
      },
      metadata: {
        'types': resolvedTypes,
        'paramSchema': _schemaForMap(resolvedTypesDynamic),
        'infoSchema': _buildInfoSchema(
          name: alias,
          kind: 'slottype',
          description: 'Slot types for $alias',
          tags: const ['slots'],
          engine: 'QuantumVM',
          extra: <String, dynamic>{'types': resolvedTypes},
        ),
      },
      registeredAt: DateTime.now(),
    );
  }

  Map<String, String>? getSlotTypes(String alias) => _slotDefaults[alias];
  void setMiddlewares(List<ActionMiddleware> m) {
    _middlewares = [
      TelemetryVMBridge.buildActionMiddleware(),
      ...m,
    ];
  }

  QLRegistryEntry? registryEntry(String key, {String? kind}) {
    final normalized = key.trim();

    // exact id
    if (_registryEntries.containsKey(normalized))
      return _registryEntries[normalized];

    // exact kind:key
    if (kind != null) {
      final direct = _registryEntries['$kind:$normalized'];
      if (direct != null) return direct;
    }

    // match by name or explicit id field
    for (final entry in _aggregateRegistryEntries()) {
      if ((entry.id == normalized || entry.name == normalized) &&
          (kind == null || entry.kind == kind)) {
        return entry;
      }
    }
    return null;
  }

  List<QLRegistryEntry> registryEntries({String? kind, String? query}) {
    final q = query?.trim().toLowerCase() ?? '';

    bool matches(QLRegistryEntry e) {
      if (kind != null && e.kind != kind) return false;
      if (q.isEmpty) return true;
      if (e.id.toLowerCase().contains(q)) return true;
      if (e.kind.toLowerCase().contains(q)) return true;
      if (e.name.toLowerCase().contains(q)) return true;
      if (e.description.toLowerCase().contains(q)) return true;
      if (e.engine.toLowerCase().contains(q)) return true;
      if (e.params.toString().toLowerCase().contains(q)) return true;
      if (e.metadata.toString().toLowerCase().contains(q)) return true;
      for (final tag in e.tags) {
        if (tag.toLowerCase().contains(q)) return true;
      }
      return false;
    }

    final items =
        _aggregateRegistryEntries().where(matches).toList(growable: false);
    items.sort((a, b) => a.name.compareTo(b.name));
    return List<QLRegistryEntry>.unmodifiable(items);
  }

  List<QLRegistryEntry> _aggregateRegistryEntries() {
    final items = <QLRegistryEntry>[];
    items.addAll(_registryEntries.values);

    for (final componentName in _componentDefinitionsByName.keys) {
      final item = _nativeComponentDescribe(componentName);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: item['id']?.toString() ?? 'native_component:$componentName',
          kind: item['kind']?.toString() ?? 'native_component',
          name: item['name']?.toString() ?? componentName,
          description: item['description']?.toString() ??
              'Native component $componentName',
          engine: item['engine']?.toString() ?? 'QuantumVM',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt:
              DateTime.tryParse(item['registeredAt']?.toString() ?? '') ??
                  DateTime.now(),
        ));
      }
    }

    for (final module in QLModuleRegistry.instance.allModules) {
      items.add(QLRegistryEntry(
        id: 'module:${module.id}',
        kind: 'module',
        name: module.id,
        description: module.manifest['description']?.toString() ?? '',
        engine: 'QLModuleRegistry',
        tags: _asStringList(
            module.manifest['tags'] ?? module.manifest['keywords']),
        params: {
          'imports': QLModuleRegistry.instance.importsFor(module.id),
          'access': module.access.visibility.name,
        },
        metadata: module.manifest,
        registeredAt: module.registeredAt,
      ));

      final macros = module.manifest['macros'];
      if (macros is Map) {
        for (final entry in macros.entries) {
          items.add(QLRegistryEntry(
            id: 'macro:${module.id}:${entry.key}',
            kind: 'macro',
            name: entry.key.toString(),
            description: 'Macro ${entry.key} from module ${module.id}',
            engine: 'QLModuleRegistry',
            tags: const ['macro'],
            params: entry.value is Map
                ? Map<String, dynamic>.from(entry.value as Map)
                : {'value': entry.value},
            metadata: {
              'module': module.id,
              'macro': entry.key,
            },
            registeredAt: module.registeredAt,
          ));
        }
      }
    }

    for (final name in QJsonPresetEngine.registryNames) {
      final item = QJsonPresetEngine.describe(name);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: 'preset:$name',
          kind: 'preset',
          name: name,
          description: item['description']?.toString() ?? '',
          engine: item['engine']?.toString() ?? 'QJsonPresetEngine',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt: DateTime.now(),
        ));
      }
    }

    for (final name in QMatrixLayoutRegistry.registryNames) {
      final item = QMatrixLayoutRegistry.describe(name);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: 'layout:$name',
          kind: 'layout',
          name: name,
          description: item['description']?.toString() ?? '',
          engine: item['engine']?.toString() ?? 'QMatrixLayoutRegistry',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt: DateTime.now(),
        ));
      }
    }

    for (final name in QLSchemaRegistry.instance.allSchemaNames) {
      final item = QLSchemaRegistry.instance.describe(name);
      if (item != null) {
        items.add(QLRegistryEntry(
          id: 'schema:$name',
          kind: 'schema',
          name: name,
          description: item['description']?.toString() ?? '',
          engine: item['engine']?.toString() ?? 'QLSchemaRegistry',
          tags: _asStringList(item['tags']),
          params: Map<String, dynamic>.from(item['params'] as Map? ?? const {}),
          metadata:
              Map<String, dynamic>.from(item['metadata'] as Map? ?? const {}),
          registeredAt: DateTime.now(),
        ));
      }
    }

    for (final pipeName in QLPipes.registry.keys) {
      items.add(QLRegistryEntry(
        id: 'pipe:$pipeName',
        kind: 'pipe',
        name: pipeName,
        description: 'Pipe transform $pipeName',
        engine: 'QLPipes',
        tags: const ['pipe'],
        params: const {},
        metadata: const {},
        registeredAt: DateTime.now(),
      ));
    }

    return items;
  }

  Map<String, dynamic> registrySnapshot({String? kind, String? query}) {
    final items = registryEntries(kind: kind, query: query)
        .map((e) => e.toMap())
        .toList(growable: false);
    return {
      'counts': {
        'actions': _actions.length,
        'plugins': _plugins.length,
        'aliases': _aliases.length,
        'slotTypes': _slotDefaults.length,
        'slotNodes': _defaultSlotNodes.length,
        'internalRegistryItems': _registryEntries.length,
        'registryItems': items.length,
        'components': _componentDefinitionsByName.length,
        'modules': QLModuleRegistry.instance.registeredModuleIds.length,
        'macros': items.where((e) => e['kind'] == 'macro').length,
        'schemas': QLSchemaRegistry.instance.allSchemaNames.length,
        'presets': QJsonPresetEngine.registryNames.length,
        'designSystems': _designSystems.length,
        'layouts': QMatrixLayoutRegistry.registryNames.length,
        'coreFiles': QLCoreFileRegistry.instance.count,
        'pipes': QLPipes.registry.length,
      },
      'items': items,
    };
  }

  Map<String, dynamic>? describeRegistryItem(String key, {String? kind}) {
    final entry = registryEntry(key, kind: kind);
    if (entry != null) return entry.toMap();

    final module = QLModuleRegistry.instance.get(key);
    if (module != null) {
      return {
        'id': module.id,
        'kind': 'module',
        'name': module.id,
        'description': module.manifest['description']?.toString() ?? '',
        'engine': 'QLModuleRegistry',
        'tags': _asStringList(
            module.manifest['tags'] ?? module.manifest['keywords']),
        'params': {
          'imports': QLModuleRegistry.instance.importsFor(module.id),
          'access': module.access.visibility.name,
        },
        'metadata': module.manifest,
        'registeredAt': module.registeredAt.toIso8601String(),
      };
    }

    final template = QJsonPresetEngine.describe(key);
    if (template != null) return template;
    final layout = QMatrixLayoutRegistry.describe(key);
    if (layout != null) return layout;
    final schema = QLSchemaRegistry.instance.describe(key);
    if (schema != null) return schema;
    final coreFile = QLCoreFileRegistry.instance.descriptorByKey(key);
    if (coreFile != null) {
      return coreFile.toMap();
    }
    final component = _nativeComponentDescribe(key);
    if (component != null) {
      return component;
    }
    if (QLPipes.registry.containsKey(key)) {
      return {
        'id': 'pipe:$key',
        'kind': 'pipe',
        'name': key,
        'description': 'Pipe transform $key',
        'engine': 'QLPipes',
        'tags': ['pipe'],
        'params': const {},
        'metadata': const {},
      };
    }
    return null;
  }

  List<String> registeredRegistryKinds() => const [
        'action',
        'plugin',
        'alias',
        'slottype',
        'slotnodes',
        'module',
        'macro',
        'preset',
        'layout',
        'schema',
        'pipe',
      ];

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  //  DYNAMIC DSL OPERATOR CATALOGUE
  //  All $-prefixed compile-time operators supported by the QVM compiler.
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  /// Returns the static list of all DSL \$-operators the VM compiler supports.
  List<Map<String, String>> dslOperatorsSnapshot() =>
      List<Map<String, String>>.unmodifiable(QuantumVMCatalog.dslOperators);

  /// Returns a dynamic snapshot of every registered OmniCore and any
  /// additional plugin whose name matches an omni-core name (e.g., q_omni_manifold).
  /// Keys are the core type names; values contain subtypes + fullTypes + all prop schemas.
  Map<String, dynamic> omniCoresSnapshot() {
    final result = <String, dynamic>{};

    // 1. Start with the canonical static subtypes table
    for (final entry in QuantumVMCatalog.omniCoreSubtypes.entries) {
      final name = entry.key;
      final subtypes = entry.value;
      final registryEntry = _registryEntries['plugin:$name'];

      final computedMetadata = _coreFeatureSchema(
        name,
        description: registryEntry?.description ?? 'Omni core: $name',
        tags: registryEntry?.tags.toList() ?? [name, 'core'],
        engine: registryEntry?.engine ?? 'QuantumVM',
      );

      result[name] = <String, dynamic>{
        'subtypes': List<String>.unmodifiable(subtypes),
        'subtypeCount': subtypes.length,
        'fullTypes': <String>[
          name,
          for (final s in subtypes) '$name:$s',
        ],
        ...computedMetadata,
        if (registryEntry != null) ...registryEntry.metadata,
      };
    }

    // 2. Overlay any EXTRA plugins that are not in QuantumVMCatalog.omniCoreSubtypes,
    //    so q_omni_manifold and any future define() calls are included.
    for (final pluginEntry in _plugins.entries) {
      final name = pluginEntry.key;
      // Skip sub-type keys (e.g. 'box:row') â€” they belong to their parent core
      if (name.contains(':')) continue;
      if (result.containsKey(name)) continue;

      final subtypes =
          QuantumVMCatalog.omniCoreSubtypes[name] ?? const <String>[];
      final registryEntry = _registryEntries['plugin:$name'];

      final computedMetadata = _coreFeatureSchema(
        name,
        description: registryEntry?.description ?? 'Omni core: $name',
        tags: registryEntry?.tags.toList() ?? [name, 'core'],
        engine: registryEntry?.engine ?? 'QuantumVM',
      );

      result[name] = <String, dynamic>{
        'subtypes': List<String>.unmodifiable(subtypes),
        'subtypeCount': subtypes.length,
        'fullTypes': <String>[
          name,
          for (final s in subtypes) '$name:$s',
        ],
        ...computedMetadata,
        if (registryEntry != null) ...registryEntry.metadata,
      };
    }

    return Map<String, dynamic>.unmodifiable(result);
  }

  /// Returns a snapshot of all registered aliases with their target type and default props.
  Map<String, dynamic> aliasRegistrySnapshot() {
    final result = <String, dynamic>{};
    for (final entry in _aliases.entries) {
      result[entry.key] = Map<String, dynamic>.unmodifiable(entry.value);
    }
    return Map<String, dynamic>.unmodifiable(result);
  }

  /// Returns a snapshot of all installed design systems with their tokens.
  Map<String, dynamic> designSystemsExportSnapshot() {
    final result = <String, dynamic>{};
    for (final entry in _designSystems.entries) {
      final bundle = entry.value;
      result[entry.key] = bundle.toMap();
    }
    return Map<String, dynamic>.unmodifiable(result);
  }

  /// Returns a merged snapshot of all design-system tokens, keyed by token name.
  /// Later-installed design systems overwrite earlier ones for duplicate token names.
  Map<String, dynamic> themeConfigSnapshot() {
    final tokens = <String, dynamic>{};
    for (final bundle in _designSystems.values) {
      tokens.addAll(bundle.tokens);
    }
    return <String, dynamic>{
      'tokens': Map<String, dynamic>.unmodifiable(tokens),
      'designSystemIds': List<String>.unmodifiable(_designSystems.keys),
    };
  }

  static List<String> _asStringList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    if (raw is Set) return raw.map((e) => e.toString()).toList(growable: false);
    if (raw is String && raw.isNotEmpty) return [raw];
    return const [];
  }

  static String _inferPluginKind(QLPlugin p) {
    if (p is QLLayoutCapability) return 'layout';
    if (p is QLWidgetCapability) return 'widget';
    if (p is QLSliverCapability) return 'sliver';
    if (p is QLGraphicsCapability) return 'graphics';
    if (p is QLKineticCapability) return 'kinetic';
    if (p is QLSensorCapability) return 'sensor';
    return 'plugin';
  }

  static String _inferPluginDescription(QLPlugin p) =>
      '${p.runtimeType} (${_inferPluginKind(p)})';

  static List<String> _inferPluginTags(QLPlugin p) {
    final tags = <String>[_inferPluginKind(p)];
    if (p is QLWidgetCapability) tags.add('widget');
    if (p is QLLayoutCapability) tags.add('layout');
    if (p is QLSliverCapability) tags.add('sliver');
    if (p is QLGraphicsCapability) tags.add('graphics');
    if (p is QLKineticCapability) tags.add('kinetic');
    if (p is QLSensorCapability) tags.add('sensor');
    return List<String>.unmodifiable(tags.toSet());
  }

  static Map<String, dynamic> _inferPluginMetadata(QLPlugin p) {
    return {
      'defaultProps': p.defaultProps,
      'capabilities': _inferPluginTags(p),
      'runtimeType': p.runtimeType.toString(),
    };
  }

  QLPlugin? getPlugin(String type) => _plugins[type];

  QToken compileStyle(String style) {
    final normalized = mergeStyleTokens([style]);
    return _styleTokens.getOrPut(
      normalized,
      () {
        try {
          return QEngine.instance.compiler.compile(normalized);
        } on StateError {
          QEngine.instance.initialize();
          return QEngine.instance.compiler.compile(normalized);
        }
      },
      weight: normalized.length + 64,
    );
  }

  void dispose() {
    try {
      _workerPool?.dispose();
    } catch (_) {}
    try {
      _compositor?.dispose();
    } catch (_) {}
    _workerPool = null;
    _compositor = null;
    _isInitialized = false;
    _actionGenerations.clear();
    _globalActionDepth = 0;
    _defaultSlotNodes.clear();
    _aliases.clear();
    _plugins.clear();
    _actions.clear();
    _registryEntries.clear();
    _slotDefaults.clear();
    for (var t in _debouncers.values) {
      t.cancel();
    }
    _debouncers.clear();
    _middlewares = [];
    QLSliceRegistry.actionRegistrar = null;
    clearRuntimeCaches();
  }

  QLLazySchemaView lazySchema(String id, Map<String, dynamic> schema) =>
      QLLazySchemaView(id, schema, cache: schemaSlices);

  QLModuleRecord registerModule(Map<String, dynamic> manifest, {String? id}) =>
      QLModuleRegistry.instance.register(manifest, id: id);

  Future<void> bootstrapModule(Map<String, dynamic> manifest,
      {BuildContext? context, String? id}) {
    registerModule(manifest, id: id);
    return QuantumDataOrchestrator.bootstrap(manifest, context);
  }

  dynamic modulePart(String moduleId, Object path,
          {String requester = 'default', String? ownerId}) =>
      QLModuleRegistry.instance
          .section(moduleId, path, requester: requester, ownerId: ownerId);

  Map<String, dynamic> moduleMacros(String moduleId, {String? ownerId}) =>
      QLModuleRegistry.instance.macrosFor(moduleId, ownerId: ownerId);

  Future<Map<String, dynamic>> loadLocalManifest(String assetPath,
      {bool useCache = true}) async {
    if (useCache) {
      final cached = _localManifests.get(assetPath);
      if (cached != null) return cached;
    }

    final rawString = await rootBundle.loadString(assetPath, cache: useCache);

    final Map<String, dynamic> manifest = await QLIsolateBridge.safeRun(() {
      final parsed = QLFormatParser.parse(rawString);
      if (parsed.isEmpty) {
        throw QuantumSecurityException(
            'Manifest at $assetPath parsed to an empty or invalid structure.');
      }
      return parsed;
    });

    if (useCache) {
      _localManifests.put(assetPath, manifest,
          weight: rawString.length + QLRuntimeCacheSizer.estimate(manifest));
    }
    return manifest;
  }

  Future<QLBlueprint> compileStringAsync(
    String rawData, {
    Map<String, dynamic> macros = const {},
    Map<String, dynamic> env = const {},
  }) async {
    final int cacheKey = rawData.hashCode;
    final cached = QLCompiler._blueprintCache.get(cacheKey);
    if (cached != null) return cached;

    final Map<String, dynamic> safeMap = await QLIsolateBridge.safeRun(() {
      return QLFormatParser.parse(rawData);
    });

    final uiNode =
        safeMap['ui'] ?? safeMap['view'] ?? safeMap['template'] ?? safeMap;

    final blueprint = await QLCompiler.compileAsync(uiNode, macros, env);

    QLCompiler._blueprintCache.put(cacheKey, blueprint);
    return blueprint;
  }

  Future<QLBlueprint> warmManifestCache(
    Map<String, dynamic> manifest, {
    Map<String, dynamic> macros = const {},
    Map<String, dynamic> env = const {},
  }) {
    final uiNode = manifest['ui'] ?? manifest;
    final compileEnv = manifest['env'] is Map
        ? <String, dynamic>{
            ...Map<String, dynamic>.from(manifest['env'] as Map),
            ...env,
          }
        : env;
    return QLCompiler.compileAsync(uiNode, macros, compileEnv);
  }

  void clearRuntimeCaches({
    bool compiler = true,
    bool style = true,
    bool schema = true,
    bool state = true,
  }) {
    if (compiler) QLCompiler.clearCaches();
    if (style) _styleTokens.clear();
    if (schema) schemaSlices.clear();
    if (compiler) _localManifests.clear();
    if (compiler) QLModuleRegistry.instance.clear();
    if (state) {
      store.clearCache();
      // Since stores are managed in QLStoreRegistry, we might need a method there to clear caches.
      // Assuming QLStoreRegistry exposes its internal stores or has a clearCaches method.
    }
  }

  Map<String, Map<String, int>> runtimeCacheStats() {
    final compilerStats =
        QLCompiler.cacheStats().map((k, v) => MapEntry(k, v.toMap()));
    return {
      ...compilerStats,
      'style': _styleTokens.stats.toMap(),
      'localManifests': _localManifests.stats.toMap(),
      'modules': QLModuleRegistry.instance.cacheStats.toMap(),
      'schemaSlices': schemaSlices.stats.toMap(),
      'state': store.cacheStats.toMap(),
    };
  }

  Future<void> triggerActions(List<dynamic>? actionList, BuildContext? ctx,
      {Map<String, dynamic>? env}) async {
    if (actionList == null) return;

    _globalActionDepth++;
    if (_globalActionDepth > 50) {
      _globalActionDepth = 0;
      throw const QuantumSecurityException(
          'Action Guard: Maximum execution limits exceeded (50 levels).');
    }

    try {
      final Map<String, dynamic> pipelineEnv = env ??
          Map<String, dynamic>.from(
              (ctx != null && ctx.mounted) ? QLDataScope.of(ctx) : const {});

      final QLDataStore contextStore =
          ctx != null ? QLDataScope.resolveStore(ctx) : store;
      final Stopwatch watchdog = Stopwatch()..start();
      int executionCount = 0;

      final String chainId = actionList.toString().hashCode.toString();
      final int currentGen = (_actionGenerations[chainId] ?? 0) + 1;
      _actionGenerations[chainId] = currentGen;

      for (final def in actionList) {
        if (++executionCount > 100 || watchdog.elapsedMilliseconds > 250) {
          throw QuantumSecurityException(
              'Action Guard: Maximum execution limits exceeded (${watchdog.elapsedMilliseconds}ms / $executionCount calls).');
        }

        if (_actionGenerations[chainId] != currentGen) {
          if (kDebugMode) {
            debugPrint('QuantumVM: Aborted stale async action chain.');
          }
          return;
        }

        String? actionName;
        Map<String, dynamic> actionMap = {};

        if (def is List && def.isNotEmpty) {
          actionName = def[0].toString();
          if (def.length > 1 && def[1] is Map) {
            actionMap = Map<String, dynamic>.from(def[1]);
          }
        } else if (def is Map) {
          actionMap = Map<String, dynamic>.from(def);
          actionName = actionMap.remove('action')?.toString();
        }

        if (actionName == null || !_actions.containsKey(actionName)) {
          print(
              'ACTION SKIP: actionName=$actionName, hasKey=${_actions.containsKey(actionName)}');
          continue;
        }

        print('ACTION EXECUTING: $actionName');

        final Map<String, dynamic> payload = actionMap.map((k, v) => MapEntry(
            k, QLDataBinder.resolveAOT(v, ctx, pipelineEnv, contextStore)));

        dynamic actionResult;
        Future<void> executeChain(int index) async {
          if (index < _middlewares.length) {
            await _middlewares[index](
                actionName!, payload, () => executeChain(index + 1));
          } else {
            actionResult = await _actions[actionName!]!.execute(
                payload, contextStore, ctx ?? const _QEEDummyContext());
          }
        }

        try {
          final int debounceMs = actionMap['debounce'] as int? ?? 0;
          if (debounceMs > 0) {
            final int hash = def.toString().hashCode;
            _debouncers[hash]?.cancel();
            final Completer<void> completer = Completer<void>();
            _debouncers[hash] =
                Timer(Duration(milliseconds: debounceMs), () async {
              try {
                if (_actionGenerations[chainId] == currentGen) {
                  await executeChain(0);
                }
                completer.complete();
              } catch (e, st) {
                completer.completeError(e, st);
              }
            });
            await completer.future;
          } else {
            await executeChain(0);
          }

          if (_actionGenerations[chainId] != currentGen) return;

          pipelineEnv['\$lastResult'] = actionResult;
        } catch (e, st) {
          if (actionMap['onError'] != null) {
            pipelineEnv['\$error'] = e.toString();
            await triggerActions(actionMap['onError'] as List<dynamic>, ctx,
                env: pipelineEnv);
            break;
          }
          Error.throwWithStackTrace(e, st);
        }
      }
      watchdog.stop();
    } finally {
      _globalActionDepth--;
    }
  }

  Widget renderWidget(BuildContext ctx, QLBlueprint node, {String? keySuffix}) {
    var hints = _renderHints[node];
    if (hints == null) {
      hints = _QLRenderHints(
        hasDeps: node.style?.contains('{{') == true || _hasTokens(node.props),
      );
      _renderHints[node] = hints;
    }

    final decision = _nodePermissionDecision(ctx, node);
    if (!decision.allowed) {
      return const SizedBox.shrink();
    }

    if (hints.hasDeps) {
      return _QLReactiveNodeBoundary(node: node, keySuffix: keySuffix);
    }
    return _assembleNode(ctx, node, QLDataScope.of(ctx),
        QLDataScope.resolveStore(ctx), keySuffix);
  }

  bool _hasTokens(dynamic target) {
    if (target is String) return target.contains('{{');
    if (target is Map) {
      if (target['_isTokenized'] == true) return true;
      for (final v in target.values) {
        if (_hasTokens(v)) return true;
      }
    }
    if (target is List) {
      for (final v in target) {
        if (_hasTokens(v)) return true;
      }
    }
    return false;
  }

  Widget _assembleNode(BuildContext ctx, QLBlueprint node,
      Map<String, dynamic> env, QLDataStore store, String? keySuffix) {
    if (node.props.containsKey(r'$if')) {
      final dynamic condition =
          QLDataBinder.resolveAOT(node.props[r'$if'], ctx, env, store);
      if (condition == false ||
          condition == 'false' ||
          condition == 0 ||
          condition == '0' ||
          condition == null ||
          condition == '') {
        return const SizedBox.shrink();
      }
    }

    String nodeType = node.type.toString();
    final aliasDef = getAlias(nodeType);
    if (aliasDef != null) nodeType = aliasDef['type'].toString();

    final String nodeBaseType =
        nodeType.contains(':') ? nodeType.split(':').first : nodeType;
    final String renderType = nodeBaseType;

    final QLPlugin? plugin = _plugins[renderType];
    final _QLComponentDefinition? nativeComponent =
        _componentDefinitionsByName[renderType];
    const QuantumComponentBuilder? componentBuilder = null;

    const Set<String> nativeTypes = {
      'row',
      'col',
      'column',
      '->',
      'v',
      'wrap',
      'center',
      'stack',
      'grid',
      'grid_item',
      'wrapper',
      'empty'
    };

    if (nativeComponent != null && plugin == null) {
      return _QLComponentRuntimeHost(
        definition: nativeComponent,
        sourceNode: node,
        sourceCtx: _AliasContext(QLContext(ctx, node, env, store)),
      );
    }

    Widget content = const SizedBox.shrink();

    final String reactiveStyle =
        QLDataBinder.resolveAOT(node.props['style'], ctx, env, store)
                ?.toString() ??
            '';
    final String baseStyle = node.style ?? '';
    final String resolvedStyle = '$baseStyle $reactiveStyle'.trim();

    List<Widget> buildChildren() {
      return node.children
          .map((c) => renderWidget(ctx, c))
          .toList(growable: false);
    }

    if (plugin != null) {
      if (plugin is QLComputeCapability) {
        return _QLHeadlessComputeNode(
            node: node,
            capability: plugin as QLComputeCapability,
            store: store,
            workerPool: workerPool);
      }
      if (plugin is QLGraphicsCapability) {
        final drawFn = (plugin as QLGraphicsCapability)
            .buildFragment(QLContext(ctx, node, env, store), node, store);
        content = QLSceneLayerWidget(
            isComplex: true,
            willChange: true,
            builder: (context, layer) {
              layer.update(node.hashCode, drawFn);
              return const SizedBox.shrink();
            });
      } else if (plugin is QLKineticCapability) {
        content = (plugin as QLKineticCapability).buildKinetic(
            QLContext(ctx, node, env, store), node, compositor, store);
      } else if (plugin is QLWidgetCapability) {
        content = (plugin as QLWidgetCapability).buildWidget(ctx, node, store);
      } else if (plugin is QLSliverCapability) {
        content = CustomScrollView(slivers: [
          (plugin as QLSliverCapability).buildSliver(ctx, node, store)
        ]);
      } else if (plugin is QLLayoutCapability) {
        content = (plugin as QLLayoutCapability)
            .buildLayout(ctx, node, buildChildren(), store);
      }
      if (plugin is QLSensorCapability) {
        content = (plugin as QLSensorCapability).buildSensor(
            QLContext(ctx, node, env, store), node, content, store);
      }
    } else if (componentBuilder != null) {
      content = componentBuilder(ctx, node, store);
    } else {
      final children = buildChildren();

      // ًںڑ€ EXTRACT TAP & TEXT NATIVELY
      final QLContext nodeCtx = QLContext(ctx, node, env, store);
      final VoidCallback? tapHandler = nodeCtx.action('onClick') ??
          nodeCtx.action('onTap') ??
          nodeCtx.action('action');
      final String? nodeText =
          QLDataBinder.resolveAOT(node.props['text'], ctx, env, store)
              ?.toString();

      if (renderType == 'grid' || renderType == 'masonry') {
        final layout = node.props['layout'] as Map? ?? {};
        final cols = node.props['gridCols'] ?? layout['cols'] ?? '1fr 1fr';
        final rows = node.props['gridRows'] ?? layout['rows'] ?? 'auto';
        final dynamic gapProp =
            QLDataBinder.resolveAOT(node.props['gap'], ctx, env, store) ??
                layout['gap'];
        final num gap = gapProp is num
            ? gapProp
            : (num.tryParse(gapProp?.toString() ?? '') ?? 0);

        content = Q(
          '$renderType grid-cols-$cols grid-rows-$rows $resolvedStyle',
          gap: gap > 0 ? gap : null,
          text: nodeText,
          onTap: tapHandler,
          suppressParentData: true,
          children: children.isEmpty ? null : children,
        );
      } else if (renderType == 'grid_item') {
        Widget inner = children.firstOrNull ?? const SizedBox.shrink();
        if (tapHandler != null) {
          inner = GestureDetector(
              onTap: tapHandler,
              behavior: HitTestBehavior.opaque,
              child: inner);
        }
        content = QuantumItem(
          rowStart: (node.props['rowStart'] as num?)?.toInt() ?? 0,
          rowEnd: (node.props['rowEnd'] as num?)?.toInt() ?? 0,
          colStart: (node.props['colStart'] as num?)?.toInt() ?? 0,
          colEnd: (node.props['colEnd'] as num?)?.toInt() ?? 0,
          rowSpan: (node.props['rowSpan'] as num?)?.toInt() ?? 1,
          colSpan: (node.props['colSpan'] as num?)?.toInt() ?? 1,
          zIndex: (node.props['zIndex'] as num?)?.toInt() ?? 0,
          alignSelf: QAlign.stretch,
          justifySelf: QAlign.stretch,
          child: inner,
        );
      } else if (renderType == 'empty') {
        content = const SizedBox.shrink();
      } else {
        String combinedStyle = resolvedStyle;
        if (renderType == 'row' || renderType == '->') {
          combinedStyle = 'row $combinedStyle';
        }
        if (renderType == 'col' ||
            renderType == 'column' ||
            renderType == 'v') {
          combinedStyle = 'col $combinedStyle';
        }
        if (renderType == 'wrap') combinedStyle = 'wrap $combinedStyle';
        if (renderType == 'center') {
          combinedStyle = 'flex-center $combinedStyle';
        }

        final String justify =
            QLDataBinder.resolveAOT(node.props['justify'], ctx, env, store)
                    ?.toString() ??
                '';
        final String items =
            QLDataBinder.resolveAOT(node.props['items'], ctx, env, store)
                    ?.toString() ??
                '';
        final bool clip =
            QLDataBinder.resolveAOT(node.props['clip'], ctx, env, store) ==
                true;
        final dynamic gapProp =
            QLDataBinder.resolveAOT(node.props['gap'], ctx, env, store);
        final num gap = gapProp is num
            ? gapProp
            : (num.tryParse(gapProp?.toString() ?? '') ?? 0);

        if (justify.isNotEmpty) {
          combinedStyle = '$combinedStyle justify-$justify';
        }
        if (items.isNotEmpty) combinedStyle = '$combinedStyle items-$items';
        if (clip) combinedStyle = '$combinedStyle overflow-hidden';

        content = Q(combinedStyle,
            text: nodeText,
            gap: gap > 0 ? gap : null,
            onTap: tapHandler,
            suppressParentData: true,
            children: children.isEmpty ? null : children);
      }
    }

    // ًںڑ€ UNIVERSAL PLUGIN TAP FALLBACK
    if (plugin != null && renderType != 'action') {
      final QLContext nodeCtx = QLContext(ctx, node, env, store);
      final VoidCallback? tapHandler = nodeCtx.action('onClick') ??
          nodeCtx.action('onTap') ??
          nodeCtx.action('action');
      if (tapHandler != null) {
        content = GestureDetector(
          onTap: tapHandler,
          behavior: HitTestBehavior.opaque,
          child: content,
        );
      }
    }

    final String? testIdProp = node.props['testId']?.toString();
    final String? nodeId = node.props['id']?.toString() ?? node.props['key']?.toString() ?? testIdProp;
    if (nodeId != null || keySuffix != null) {
      final keyString = testIdProp != null
          ? '__qte_testId_$testIdProp'
          : (keySuffix != null ? '${nodeId ?? ''}_$keySuffix' : nodeId!);
      content = KeyedSubtree(
          key: ValueKey(keyString), child: content);
    }

    return content;
  }
}

class QuantumVMRoot extends StatefulWidget {
  final Widget child;
  final int workerThreads;

  const QuantumVMRoot({super.key, required this.child, this.workerThreads = 4});

  @override
  State<QuantumVMRoot> createState() => _QuantumVMRootState();
}

class _QuantumVMRootState extends State<QuantumVMRoot>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    QuantumVM.instance.initialize(workerThreads: widget.workerThreads);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) QuantumVM.instance.attachCompositor(this);
    });
  }

  @override
  void dispose() {
    try {
      QuantumVM.instance.compositor.dispose();
    } catch (_) {}
    try {
      QuantumVM.instance.workerPool.dispose();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ًںڑ€ FOREVER FIX: One AnimatedBuilder for the entire app!
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: QEngine.instance.tick,
        builder: (context, child) => widget.child,
      ),
    );
  }
}

class _QLHeadlessComputeNode extends StatefulWidget {
  final QLBlueprint node;
  final QLComputeCapability capability;
  final QLDataStore store;
  final QLWorkerPool workerPool;

  const _QLHeadlessComputeNode({
    required this.node,
    required this.capability,
    required this.store,
    required this.workerPool,
  });

  @override
  State<_QLHeadlessComputeNode> createState() => _QLHeadlessComputeNodeState();
}

class _QLHeadlessComputeNodeState extends State<_QLHeadlessComputeNode> {
  QLAsyncSignal<dynamic>? _signal;

  @override
  void initState() {
    super.initState();
    _executeTask();
  }

  void _executeTask() {
    final ctx = QLContext(context, widget.node,
        QLDataScope.ofNode(context)?.localData ?? const {}, widget.store);
    final task = widget.capability.buildTask(ctx, widget.node);
    final input = widget.capability.buildInput(ctx, widget.node);

    _signal = widget.workerPool.submit(task, input);

    _signal!.data.addListener(() {
      if (_signal!.data.value != null && mounted) {
        widget.capability
            .onTaskCompleted(ctx, _signal!.data.value, widget.store);
      }
    });
  }

  @override
  void dispose() {
    _signal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class QLContext {
  final BuildContext flutterContext;
  final QLBlueprint node;
  final Map<String, dynamic> env;
  final QLDataStore store;

  final Map<String, dynamic> _propCache = {};

  QLContext(this.flutterContext, this.node, this.env, this.store);

  T prop<T>(String key, {T? fallback}) {
    if (_propCache.containsKey(key)) {
      final cached = _propCache[key];
      if (cached is T) return cached;
    }

    final dynamic raw = node.props[key];
    if (raw == null) return _returnFallback<T>(fallback);

    final dynamic resolved =
        QLDataBinder.resolveAOT(raw, flutterContext, env, store);
    if (resolved == null) return _returnFallback<T>(fallback);

    if (resolved is T) {
      _propCache[key] = resolved;
      return resolved;
    }

    final T? coerced = _coerceType<T>(resolved);
    if (coerced != null) {
      _propCache[key] = coerced;
      return coerced;
    }

    return _returnFallback<T>(fallback);
  }

  String string(String key, {String fallback = ''}) =>
      prop<String>(key, fallback: fallback);
  double number(String key, {double fallback = 0.0}) =>
      prop<double>(key, fallback: fallback);
  Color? color(String key, {Color? fallback}) {
    final raw = prop<dynamic>(key);
    if (raw == null) return fallback;
    if (raw is Color) return raw;
    if (raw is int) return Color(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        int c = QLParserUtils.parseColor(raw, 0, raw.length);
        if (c == 0) return fallback;
        return Color(c);
      } catch (_) {
        return fallback;
      }
    }
    return fallback;
  }

  bool boolean(String key, {bool fallback = false}) =>
      prop<bool>(key, fallback: fallback);
  int integer(String key, {int fallback = 0}) =>
      prop<int>(key, fallback: fallback);
  List<dynamic> list(String key, {List<dynamic> fallback = const []}) =>
      List<dynamic>.from(prop<List>(key, fallback: fallback));

  VoidCallback? action(String eventKey, {Map<String, dynamic>? localPayload}) {
    dynamic rawActions = node.props[eventKey];

    // Allow both the legacy list form and the newer single-action map form.
    List<dynamic>? actions;
    if (rawActions is List) {
      actions = rawActions;
    } else if (rawActions is Map) {
      actions = <dynamic>[Map<String, dynamic>.from(rawActions)];
    }

    // ًںڑ€ FALLBACK LOGIC: If looking for onClick, also check onTap and action.
    if (actions == null) {
      final eventsMap = node.props['events'];
      if (eventsMap is Map) {
        final rawEventActions = eventsMap[eventKey];
        if (rawEventActions is List) {
          actions = rawEventActions;
        } else if (rawEventActions is Map) {
          actions = <dynamic>[Map<String, dynamic>.from(rawEventActions)];
        }
      }
    }

    if (actions == null && eventKey == 'onClick') {
      final onTap = node.props['onTap'];
      final action = node.props['action'];
      if (onTap is List) {
        actions = onTap;
      } else if (onTap is Map) {
        actions = <dynamic>[Map<String, dynamic>.from(onTap)];
      } else if (action is List) {
        actions = action;
      } else if (action is Map) {
        actions = <dynamic>[Map<String, dynamic>.from(action)];
      }
    }

    if (actions == null) return null;

    return () => QuantumVM.instance.triggerActions(actions!, flutterContext,
        env: {...env, ...?localPayload});
  }

  Map<K, V> map<K, V>(String key, {Map<K, V> fallback = const {}}) =>
      prop<Map<K, V>>(key, fallback: fallback);

  QLLazySchemaView schema(String key, {String? id}) {
    final raw = prop<Map<String, dynamic>>(key, fallback: const {});
    final schemaId = id ??
        '${node.debugPath}:$key:${node.props[key] == null ? 0 : QLStableHasher.of(node.props[key])}';
    return QuantumVM.instance.lazySchema(schemaId, raw);
  }

  Map<String, dynamic> schemaFields(String key, Iterable<String> fields,
          {String? id}) =>
      schema(key, id: id).pick(fields);

  Map<String, dynamic> schemaField(String key, String field, {String? id}) =>
      schema(key, id: id).field(field)?.definition ?? const {};

  E enumValue<E extends Enum>(String key, List<E> values,
      {required E fallback}) {
    final raw = string(key);
    if (raw.isEmpty) return fallback;
    return values.firstWhere((e) => e.name.toLowerCase() == raw.toLowerCase(),
        orElse: () => fallback);
  }

  List<Widget> get children => node.children
      .where((c) => c.props['slot'] == null)
      .map((c) => QuantumVM.instance.renderWidget(flutterContext, c))
      .toList();

  Widget? slot(String slotName) {
    final QLBlueprint? childNode = node.slots[slotName] ??
        node.children.where((c) => c.props['slot'] == slotName).firstOrNull;
    if (childNode != null) {
      final Map<String, dynamic> resolvedProps = {};
      node.props.forEach((k, v) {
        resolvedProps[k] =
            QLDataBinder.resolveAOT(v, flutterContext, env, store);
      });
      return QLDataScope(
        localData: {...env, ...resolvedProps},
        moduleStore: store,
        child: QuantumVM.instance.renderWidget(flutterContext, childNode),
      );
    }
    return null;
  }

  T _returnFallback<T>(T? fallback) {
    if (fallback != null) return fallback;
    if (null is T) return null as T;
    if (T == String) return '' as T;
    if (T == double) return 0.0 as T;
    if (T == int) return 0 as T;
    if (T == bool) return false as T;
    throw ArgumentError(
        'Required SDUI property of type $T was null and no fallback was provided.');
  }

  T? _coerceType<T>(dynamic resolved) {
    final String str = resolved.toString().trim();
    if (T == String) return str as T;
    if (T == double) {
      if (resolved is num) return resolved.toDouble() as T;
      return (double.tryParse(str) ?? int.tryParse(str)?.toDouble()) as T?;
    }
    if (T == int) {
      if (resolved is num) return resolved.toInt() as T;
      return (int.tryParse(str) ?? double.tryParse(str)?.toInt()) as T?;
    }
    if (T == bool) {
      if (resolved is bool) return resolved as T;
      final lower = str.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') {
        return true as T;
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off') {
        return false as T;
      }
      return null;
    }
    if (T == Color) {
      if (resolved is Color) return resolved as T;
      if (resolved is int) return Color(resolved) as T;
      if (resolved is String && str.isNotEmpty) {
        return Color(QLParserUtils.parseColor(str, 0, str.length)) as T;
      }
      return null;
    }
    if (T == List || T == List<dynamic>) {
      if (resolved is List) return resolved as T;
      return [resolved] as T;
    }
    if (T == Map || T == Map<String, dynamic>) {
      if (resolved is Map) return Map<String, dynamic>.from(resolved) as T;
      return null;
    }
    return null;
  }
}

class _QLAutoReactiveNode extends StatefulWidget {
  final QLBlueprint node;
  final Widget Function(QLContext ctx) builder;
  final bool isSliver;

  const _QLAutoReactiveNode(this.node, this.builder, {this.isSliver = false});

  @override
  State<_QLAutoReactiveNode> createState() => _QLAutoReactiveNodeState();
}

class _QLAutoReactiveNodeState extends State<_QLAutoReactiveNode> {
  final Set<String> deps = {};
  Listenable _mergedListenable = _NoopListenable.instance;
  QLDataStore? _resolvedStore;

  @override
  void initState() {
    super.initState();
    _extractDeps(widget.node.props, deps);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = QLDataScope.resolveStore(context);
    if (_resolvedStore != store) {
      _resolvedStore = store;
      _buildSignals();
    }
  }

  void _buildSignals() {
    if (deps.isEmpty || _resolvedStore == null) {
      _mergedListenable = _NoopListenable.instance;
      return;
    }
    final List<Listenable> signals = [];
    for (final d in deps) {
      if (!d.startsWith('item.') && !d.startsWith(r'$env.')) {
        signals.add(_resolvedStore!.signal(d));
      }
    }
    _mergedListenable = Listenable.merge(signals);
  }

  void _extractDeps(dynamic value, Set<String> deps) {
    if (value is Map) {
      if (value['_isTokenized'] == true) {
        deps.addAll((value['deps'] as List).cast<String>());
      }
      for (final v in value.values) {
        _extractDeps(v, deps);
      }
    } else if (value is List) {
      for (final v in value) {
        _extractDeps(v, deps);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> env =
        QLDataScope.ofNode(context)?.localData ?? const {};
    final QLDataStore store =
        _resolvedStore ?? QLStoreRegistry.instance.defaultStore;

    if (deps.isEmpty) return _buildSafeContent(env, store);

    return AnimatedBuilder(
      animation: _mergedListenable,
      builder: (context, child) => _buildSafeContent(env, store),
    );
  }

  Widget _buildSafeContent(Map<String, dynamic> env, QLDataStore store) {
    try {
      return widget.builder(QLContext(context, widget.node, env, store));
    } catch (e, st) {
      debugPrint('ًںڑ¨ [QuantumVM] Crash in ${widget.node.type}: $e\n$st');
      return const SizedBox.shrink();
    }
  }
}

class _QLReactiveNodeBoundary extends StatefulWidget {
  final QLBlueprint node;
  final String? keySuffix;
  const _QLReactiveNodeBoundary({required this.node, this.keySuffix});
  @override
  State<_QLReactiveNodeBoundary> createState() =>
      _QLReactiveNodeBoundaryState();
}

class _QLReactiveNodeBoundaryState extends State<_QLReactiveNodeBoundary> {
  final Set<String> deps = {};
  Listenable _mergedListenable = _NoopListenable.instance;

  QLDataStore? _moduleStore;
  QLDataStore? _localStore;

  @override
  void initState() {
    super.initState();
    _extractDeps(widget.node.props, deps);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = QLDataScope.ofNode(context);
    final moduleStore =
        scope?.moduleStore ?? QLStoreRegistry.instance.defaultStore;
    final localStore = scope?.localStore;

    if (_moduleStore != moduleStore || _localStore != localStore) {
      _moduleStore = moduleStore;
      _localStore = localStore;
      _buildSignals();
    }
  }

  void _buildSignals() {
    if (deps.isEmpty) {
      _mergedListenable = _NoopListenable.instance;
      return;
    }

    final List<Listenable> signals = [];
    for (final d in deps) {
      if (d.startsWith('item.') || d.startsWith(r'$env.')) continue;

      if (d.startsWith(r'$local')) {
        if (_localStore != null) {
          signals.add(_localStore!.signal(d.replaceFirst(r'$local.', '')));
        }
        continue;
      }

      if (d.startsWith('@')) {
        final ns = d.substring(1).split('.').first;
        signals.add(QLStoreRegistry.instance
            .get(ns)
            .signal(d.substring(ns.length + 2)));
        continue;
      }

      if (_moduleStore != null) {
        signals.add(_moduleStore!.signal(d));
      }
    }

    _mergedListenable =
        signals.isEmpty ? _NoopListenable.instance : Listenable.merge(signals);
  }

  void _extractDeps(dynamic value, Set<String> deps) {
    if (value is String) {
      final matches = RegExp(r'\{\{(.*?)\}\}').allMatches(value);
      for (final m in matches) {
        final expr = m.group(1) ?? '';
        final tokens = RegExp(r'[a-zA-Z_][a-zA-Z0-9_\.]*').allMatches(expr);
        for (final t in tokens) {
          final name = t.group(0);
          if (name != null && name != 'true' && name != 'false' && name != 'null') {
            deps.add(name);
          }
        }
      }
    } else if (value is Map) {
      if (value['_isTokenized'] == true && value['deps'] is List) {
        deps.addAll((value['deps'] as List).cast<String>());
      }
      for (final v in value.values) {
        _extractDeps(v, deps);
      }
    } else if (value is List) {
      for (final v in value) {
        _extractDeps(v, deps);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> env =
        QLDataScope.ofNode(context)?.localData ?? const {};
    final QLDataStore store =
        _localStore ?? _moduleStore ?? QuantumVM.instance.store;

    Widget content;
    if (deps.isEmpty) {
      content = _buildSafeContent(context, env, store);
    } else {
      content = AnimatedBuilder(
          animation: _mergedListenable,
          builder: (context, child) => _buildSafeContent(context, env, store));
    }
    return content;
  }

  Widget _buildSafeContent(
      BuildContext ctx, Map<String, dynamic> env, QLDataStore store) {
    try {
      TelemetryVMBridge.onReactiveBuild(widget.node.debugPath);
      return QuantumVM.instance
          ._assembleNode(ctx, widget.node, env, store, widget.keySuffix);
    } catch (e, st) {
      debugPrint(
          'ًںڑ¨ [QuantumVM] Crash in node <${widget.node.type}> at [${widget.node.debugPath}]\nError: $e\n$st');
      return kDebugMode
          ? ErrorWidget('Crash at ${widget.node.debugPath}\n$e')
          : const SizedBox.shrink();
    }
  }
}

extension QuantumVMMicroPlugin on QuantumVM {
  void define(
    String type,
    Widget Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroWidgetPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineSliver(
    String type,
    Widget Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroSliverPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineLayout(
    String type,
    Widget Function(QLContext ctx, List<Widget> children) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroLayoutPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineGraphics(
    String type,
    QLFragmentDraw Function(QLContext ctx) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroGraphicsPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineKinetic(
    String type,
    Widget Function(QLContext ctx, QLAnimCompositor compositor) builder, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroKineticPlugin(type, builder, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void defineSensor(
    String type,
    void Function(QLContext ctx, QLPointerEvent event) onSensorData, {
    Map<String, dynamic> defaultProps = const {},
    String? description,
    Map<String, dynamic> params = const {},
    String? engine,
    Map<String, dynamic> metadata = const {},
    List<String> tags = const [],
  }) =>
      registerPlugin(
        _MicroSensorPlugin(type, onSensorData, defaultProps),
        description: description,
        params: params.isNotEmpty ? params : defaultProps,
        engine: engine,
        metadata: metadata,
        tags: tags,
      );

  void installDomain(QuantumDomain domain) {
    domain.sduiComponents.forEach((name, builder) => define(name, builder));
    domain.sduiVariants.forEach((variantName, builder) {
      final targetType = '${domain.name}:$variantName';
      defineVariant(variantName, targetType);
      define(variantName, builder);
      define(targetType, builder);
    });
    if (domain.widgetBuilder != null) {
      define(domain.name, domain.widgetBuilder!);
    }
    for (final plugin in domain.sduiPlugins) {
      registerPlugin(plugin);
    }
    domain.sduiActions.forEach((key, plugin) {
      registerAction(key, plugin);
    });
    domain.sduiPipes.forEach((name, transform) {
      QLPipes.register(name, transform);
    });
    domain.schemas.forEach((name, def) {
      QLSchemaRegistry.instance.registerRaw(name, def);
    });
    domain.aliases.forEach((alias, info) {
      final targetType = info['type']?.toString() ?? '';
      final props = info['props'] is Map
          ? Map<String, dynamic>.from(info['props'] as Map)
          : const <String, dynamic>{};
      final description = info['description']?.toString();
      final metadata = info['metadata'] is Map
          ? Map<String, dynamic>.from(info['metadata'] as Map)
          : const <String, dynamic>{};
      final tags = info['tags'] is List
          ? (info['tags'] as List).map((e) => e.toString()).toList()
          : const <String>[];
      defineAlias(
        alias,
        targetType,
        defaultProps: props,
        description: description,
        metadata: metadata,
        tags: tags,
      );
    });
    if (domain.initialStoreData.isNotEmpty) {
      store.merge(domain.initialStoreData);
    }
    for (final hook in domain.installHooks) {
      hook(this);
    }
  }
}

// ADD THIS HELPER JUST ABOVE THE PLUGINS IF NOT ALREADY THERE
// ًںڑ€ BULLETPROOF STATIC CHECKER
bool _nodeHasTokens(dynamic target) {
  if (target == null) return false;
  if (target is String) return target.contains('{{');
  if (target is Map) {
    if (target['_isTokenized'] == true) return true;
    if (target.containsKey(r'$bind') || target.containsKey('bind')) return true;
    for (final v in target.values) {
      if (_nodeHasTokens(v)) return true;
    }
  }
  if (target is List) {
    for (final v in target) {
      if (_nodeHasTokens(v)) return true;
    }
  }
  return false;
}

// ًںڑ€ THE ULTIMATE STATIC CHECKER
bool _nodeIsReactive(dynamic target) {
  if (target == null) return false;
  if (target is String) return target.contains('{{');
  if (target is Map) {
    if (target['_isTokenized'] == true) return true;
    if (target.containsKey(r'$bind') ||
        target.containsKey('bind') ||
        target.containsKey(r'$if') ||
        target.containsKey(r'$repeat')) {
      return true;
    }
    for (final v in target.values) {
      if (_nodeIsReactive(v)) return true;
    }
  }
  if (target is List) {
    for (final v in target) {
      if (_nodeIsReactive(v)) return true;
    }
  }
  return false;
}

// Inside your MicroPlugins (quantum_vm.dart):
class _MicroWidgetPlugin extends QLPlugin implements QLWidgetCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx) builder;
  _MicroWidgetPlugin(this.type, this.builder, this.defaultProps);

  @override
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    // ًںڑ€ O(1) MEMOIZED CHECK: Kills recursive AST crawling
    if (!QLAstInspector.isReactive(node.props) &&
        !QLAstInspector.isReactive(node.style) &&
        !QLAstInspector.isReactive(node.type)) {
      return builder(QLContext(
          ctx, node, QLDataScope.ofNode(ctx)?.localData ?? const {}, store));
    }
    return _QLAutoReactiveNode(node, builder, isSliver: false);
  }
}

// Apply the exact same _nodeIsReactive check to _MicroSliverPlugin and _MicroLayoutPlugin!
class _MicroSliverPlugin extends QLPlugin implements QLSliverCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx) builder;
  _MicroSliverPlugin(this.type, this.builder, this.defaultProps);

  @override
  Widget buildSliver(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    if (!_nodeHasTokens(node.props) && !_nodeHasTokens(node.style)) {
      return builder(QLContext(
          ctx, node, QLDataScope.ofNode(ctx)?.localData ?? const {}, store));
    }
    return _QLAutoReactiveNode(node, builder, isSliver: true);
  }
}

class _MicroLayoutPlugin extends QLPlugin implements QLLayoutCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx, List<Widget> children) builder;
  _MicroLayoutPlugin(this.type, this.builder, this.defaultProps);

  @override
  Widget buildLayout(BuildContext ctx, QLBlueprint node, List<Widget> children,
      QLDataStore store) {
    return builder(
        QLContext(
            ctx, node, QLDataScope.ofNode(ctx)?.localData ?? const {}, store),
        children);
  }
}

class _MicroGraphicsPlugin extends QLPlugin implements QLGraphicsCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final QLFragmentDraw Function(QLContext ctx) builder;
  _MicroGraphicsPlugin(this.type, this.builder, this.defaultProps);
  @override
  QLFragmentDraw buildFragment(
          QLContext ctx, QLBlueprint node, QLDataStore store) =>
      builder(ctx);
}

class _MicroKineticPlugin extends QLPlugin implements QLKineticCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final Widget Function(QLContext ctx, QLAnimCompositor compositor) builder;
  _MicroKineticPlugin(this.type, this.builder, this.defaultProps);
  @override
  Widget buildKinetic(QLContext ctx, QLBlueprint node,
          QLAnimCompositor compositor, QLDataStore store) =>
      builder(ctx, compositor);
}

class _MicroSensorPlugin extends QLPlugin implements QLSensorCapability {
  @override
  final String type;
  @override
  final Map<String, dynamic> defaultProps;
  final void Function(QLContext ctx, QLPointerEvent event) onSensorData;
  _MicroSensorPlugin(this.type, this.onSensorData, this.defaultProps);
  @override
  Widget buildSensor(
      QLContext ctx, QLBlueprint node, Widget child, QLDataStore store) {
    return QLOmniSensor(
        onTouchUpdate: (event) => onSensorData(ctx, event), child: child);
  }
}

abstract final class QLRouteBuilder {
  static QLRoute localJson({
    required String path,
    required Map<String, dynamic> Function(QLRouteInfo) schemaBuilder,
    Map<String, dynamic> macros = const {},
    QLTransitionType transition = QLTransitionType.slideRight,
  }) {
    return QLRoute(
      path: path,
      transition: transition,
      builder: (context, info) => QLSmartView(
        manifest: schemaBuilder(info),
        macros: macros,
        routeInfo: info,
      ),
    );
  }

  static QLRoute localJsonAsset({
    required String path,
    required String assetPath,
    Map<String, dynamic> macros = const {},
    Widget? loadingWidget,
    QLTransitionType transition = QLTransitionType.slideRight,
  }) {
    return QLRoute(
      path: path,
      transition: transition,
      builder: (context, info) => FutureBuilder<Map<String, dynamic>>(
        future: QuantumVM.instance.loadLocalManifest(assetPath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return loadingWidget ?? const SizedBox.shrink();
          }
          return QLSmartView(
            manifest: snapshot.data!,
            macros: macros,
            routeInfo: info,
            loadingWidget: loadingWidget,
          );
        },
      ),
    );
  }

  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
  // NEW INJECTION: UNIVERSAL ROUTE BUILDER (quantum_navigation_engine.dart)
  // â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ

  static QLRoute localAsset({
    required String path,
    required String assetPath,
    Map<String, dynamic> macros = const {},
    Widget? loadingWidget,
    QLTransitionType transition = QLTransitionType.slideRight,
  }) {
    return QLRoute(
      path: path,
      transition: transition,
      builder: (context, info) => FutureBuilder<Map<String, dynamic>>(
        future: QuantumVM.instance.loadLocalManifest(assetPath),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text("Load Error: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return loadingWidget ?? const SizedBox.shrink();
          }
          return QLSmartView(
            manifest: snapshot.data!,
            macros: macros,
            routeInfo: info,
            loadingWidget: loadingWidget,
          );
        },
      ),
    );
  }
}

class QLSmartView extends StatefulWidget {
  final Map<String, dynamic> manifest;
  final Map<String, dynamic> macros;
  final Widget? loadingWidget;
  final QLRouteInfo? routeInfo;

  /// Called when manifest bootstrap/compilation throws. If omitted, a
  /// minimal built-in error widget is shown in debug mode (so failures are
  /// impossible to miss during development) and, in release mode, the
  /// previous [loadingWidget] state is kept -- matching this widget's old
  /// (silent) behavior for release builds by default, but now the error is
  /// always still reported via [QLErrorBoundaryScope] and [onCompileError]
  /// regardless of which UI path is shown.
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;

  /// Called whenever manifest bootstrap/compilation throws, in addition to
  /// (not instead of) reporting to the nearest [QLErrorBoundaryScope] if one
  /// is present. Use this to log/report even when you don't need custom
  /// error UI.
  final void Function(Object error, StackTrace stackTrace)? onCompileError;

  QLSmartView({
    super.key,
    Map<String, dynamic>? manifest,
    Map<String, dynamic>? schema,
    this.macros = const {},
    this.loadingWidget,
    this.routeInfo,
    this.errorBuilder,
    this.onCompileError,
  })  : assert(manifest != null || schema != null,
            'QLSmartView requires either manifest or schema.'),
        manifest = manifest ?? schema!;

  @override
  State<QLSmartView> createState() => _QLSmartViewState();
}

class _QLSmartViewState extends State<QLSmartView> {
  QLBlueprint? _compiledAST;
  Object? _compileError;
  StackTrace? _compileStackTrace;

  @override
  void reassemble() {
    super.reassemble();
    _processManifest();
  }

  @override
  void initState() {
    super.initState();
    _processManifest();
  }

  @override
  void didUpdateWidget(covariant QLSmartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final manifestChanged = !identical(widget.manifest, oldWidget.manifest);
    final macrosChanged = !mapEquals(widget.macros, oldWidget.macros);
    final routeChanged = widget.routeInfo != oldWidget.routeInfo;
    if (manifestChanged || macrosChanged || routeChanged) {
      _processManifest();
    }
  }

  Future<void> _processManifest() async {
    try {
      await QuantumDataOrchestrator.bootstrap(widget.manifest, context);

      final uiNode = widget.manifest['ui'] ?? widget.manifest;
      final Map<String, dynamic> compileEnv = widget.manifest['env'] is Map
          ? Map<String, dynamic>.from(widget.manifest['env'])
          : {};

      if (widget.routeInfo != null) {
        compileEnv[r'$route'] = {
          'path': widget.routeInfo!.path,
          'param': widget.routeInfo!.params,
          'query': widget.routeInfo!.queryParams,
        };
      }

      final int ticket = TelemetryVMBridge.beginSmartViewCompile(
          widget.manifest['id']?.toString() ?? 'view');
      final QLBlueprint ast =
          await QLCompiler.compileAsync(uiNode, widget.macros, compileEnv);
      TelemetryVMBridge.endSmartViewCompile(ticket);
      if (mounted) {
        setState(() {
          _compiledAST = ast;
          _compileError = null;
          _compileStackTrace = null;
        });
      }
    } catch (e, st) {
      // Previously: print(e); print(st); -- with nothing else. That left
      // this widget stuck on `loadingWidget` forever with zero way for the
      // app (or a human debugging it) to discover a manifest failed to
      // compile short of reading raw console output.
      if (kDebugMode) {
        debugPrint('ًںڑ¨ QuantumVM Compilation Error: $e');
        debugPrintStack(stackTrace: st);
      }
      widget.onCompileError?.call(e, st);
      // Route into the framework's existing error-boundary mechanism if
      // this QLSmartView happens to be inside one, so ancestor retry/UI
      // logic (QLErrorBoundary) can react the same way it would to any
      // other subtree error.
      QLErrorBoundaryScope.maybeOf(context)?.report(
        e,
        stackTrace: st,
        context: 'QLSmartView(${widget.manifest['id'] ?? 'unknown'})',
      );
      if (mounted) {
        setState(() {
          _compileError = e;
          _compileStackTrace = st;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_compileError != null) {
      final err = _compileError!;
      final st = _compileStackTrace ?? StackTrace.empty;
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(err, st);
      }
      if (kDebugMode) {
        // No custom errorBuilder was given: fail loudly in debug so this
        // is never mistaken for "still loading" during development.
        return Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFF3A0000),
          child: Text(
            'QLSmartView failed to compile manifest '
            '"${widget.manifest['id'] ?? ''}":\n$err',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      }
      // Release build, no errorBuilder provided: preserve the previous
      // (silent-to-the-UI) behavior rather than surprising an app that
      // hasn't opted into custom error UI -- the error is still reported
      // above via onCompileError / QLErrorBoundaryScope either way.
      return widget.loadingWidget ?? const SizedBox.shrink();
    }
    if (_compiledAST == null) {
      return widget.loadingWidget ?? const SizedBox.shrink();
    }

    final Map<String, dynamic> rootData = {};
    if (widget.routeInfo != null) {
      rootData['\$route'] = {
        'path': widget.routeInfo!.path,
        'param': widget.routeInfo!.params,
        'query': widget.routeInfo!.queryParams,
      };
    }

    return QLDataScope(
      moduleStore:
          QLStoreRegistry.instance.get(widget.manifest['module'] ?? 'default'),
      localData: rootData,
      child: QuantumVM.instance.renderWidget(context, _compiledAST!),
    );
  }
}

class _QLRenderHints {
  final bool hasDeps;
  const _QLRenderHints({required this.hasDeps});
}

class _GridRect {
  int minR, minC, maxR, maxC;
  _GridRect(this.minR, this.minC, this.maxR, this.maxC);
}

class _NoopListenable implements Listenable {
  const _NoopListenable._();
  static const _NoopListenable instance = _NoopListenable._();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ
// These are thin read-only views â€” they never mutate VM state.
// â•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گâ•گ

/// Extension exposing read-only inspector APIs on [QuantumVM] for the QEE.
extension QuantumVMInspector on QuantumVM {
  /// All registered action names.
  List<String> get registeredActionNames =>
      List<String>.unmodifiable(_actions.keys);

  /// All registered plugin type names.
  List<String> get registeredPluginNames =>
      List<String>.unmodifiable(_plugins.keys);

  /// All registered alias names.
  List<String> get registeredAliasNames =>
      List<String>.unmodifiable(_aliases.keys);

  /// True if an action with [name] is registered.
  bool hasAction(String name) => _actions.containsKey(name);

  /// True if a plugin with [type] is registered.
  bool hasPlugin(String type) => _plugins.containsKey(type);

  /// True if an alias with [name] is registered.
  bool hasAlias(String name) => _aliases.containsKey(name);
}

/// A dummy context used for headless engine tests when [triggerActions] is called without a UI.
class _QEEDummyContext implements BuildContext {
  const _QEEDummyContext();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Cannot call BuildContext methods in headless engine tests.');
}
