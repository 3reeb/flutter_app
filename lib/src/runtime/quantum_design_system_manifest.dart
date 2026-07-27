// ════════════════════════════════════════════════════════════════════════════
// QUANTUM DESIGN SYSTEM MANIFEST
// quantum_design_system_manifest.dart
//
// JSON-first compiler for design systems, components, templates, layouts,
// aliases, schemas, workflows, and app-logic primitives.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
@immutable
class QuantumDesignSystemBundle {
  final String id;
  final int fingerprint;
  final Map<String, dynamic> manifest;
  final Map<String, Map<String, dynamic>> aliases;
  final Map<String, Map<String, dynamic>> slotTypes;
  final Map<String, Map<String, dynamic>> slotNodes;
  final Map<String, Map<String, dynamic>> templates;
  final Map<String, Map<String, dynamic>> layouts;
  final Map<String, Map<String, dynamic>> decorations;
  final Map<String, Map<String, dynamic>> coreSchemas;
  final Map<String, Map<String, dynamic>> aliasSchemas;
  final Map<String, Map<String, dynamic>> components;
  final Map<String, Map<String, dynamic>> actions;
  final Map<String, Map<String, dynamic>> behaviors;
  final Map<String, Map<String, dynamic>> workflows;
  final Map<String, Map<String, dynamic>> stateMachines;
  final Map<String, Map<String, dynamic>> routes;
  final Map<String, Map<String, dynamic>> packs;
  final Map<String, dynamic> tokens;
  final Map<String, dynamic> metadata;

  const QuantumDesignSystemBundle({
    required this.id,
    required this.fingerprint,
    required this.manifest,
    this.aliases = const <String, Map<String, dynamic>>{},
    this.slotTypes = const <String, Map<String, dynamic>>{},
    this.slotNodes = const <String, Map<String, dynamic>>{},
    this.templates = const <String, Map<String, dynamic>>{},
    this.layouts = const <String, Map<String, dynamic>>{},
    this.decorations = const <String, Map<String, dynamic>>{},
    this.coreSchemas = const <String, Map<String, dynamic>>{},
    this.aliasSchemas = const <String, Map<String, dynamic>>{},
    this.components = const <String, Map<String, dynamic>>{},
    this.actions = const <String, Map<String, dynamic>>{},
    this.behaviors = const <String, Map<String, dynamic>>{},
    this.workflows = const <String, Map<String, dynamic>>{},
    this.stateMachines = const <String, Map<String, dynamic>>{},
    this.routes = const <String, Map<String, dynamic>>{},
    this.packs = const <String, Map<String, dynamic>>{},
    this.tokens = const <String, dynamic>{},
    this.metadata = const <String, dynamic>{},
  });

  int get sectionCount =>
      aliases.length +
      slotTypes.length +
      slotNodes.length +
      templates.length +
      layouts.length +
      decorations.length +
      coreSchemas.length +
      aliasSchemas.length +
      components.length +
      actions.length +
      behaviors.length +
      workflows.length +
      stateMachines.length +
      routes.length +
      packs.length;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'fingerprint': fingerprint,
        'manifest': manifest,
        'aliases': aliases,
        'slotTypes': slotTypes,
        'slotNodes': slotNodes,
        'templates': templates,
        'layouts': layouts,
        'decorations': decorations,
        'coreSchemas': coreSchemas,
        'aliasSchemas': aliasSchemas,
        'components': components,
        'actions': actions,
        'behaviors': behaviors,
        'workflows': workflows,
        'stateMachines': stateMachines,
        'routes': routes,
        'packs': packs,
        'tokens': tokens,
        'metadata': metadata,
      };
}

abstract final class QuantumDesignSystemCompiler {
  static QuantumDesignSystemBundle compile(
    Map<String, dynamic> raw, {
    String? manifestId,
  }) {
    final Map<String, dynamic> normalized =
        Map<String, dynamic>.from(_normalizeRoot(raw));
    final Map<String, dynamic> root = _resolveRoot(normalized);
    final String id = (manifestId ??
            _string(root['id']) ??
            _string(root['name']) ??
            'design_system')
        .trim();

    final Map<String, dynamic> metadata = _sectionMap(root, const [
      'metadata',
      'meta',
      'info',
    ]);

    final Map<String, dynamic> tokens = _sectionMap(root, const [
      'tokens',
      'token',
      'theme',
      'semanticTokens',
      'semantic_tokens',
    ]);

    final _SectionCollector collector = _SectionCollector();
    collector.ingest(root);

    final int fingerprint = _stableHash(<String, dynamic>{
      'id': id,
      'root': root,
      'tokens': tokens,
      'collector': collector.toMap(),
      'metadata': metadata,
    });

    return QuantumDesignSystemBundle(
      id: id,
      fingerprint: fingerprint,
      manifest: Map<String, dynamic>.unmodifiable(root),
      aliases: collector.aliases,
      slotTypes: collector.slotTypes,
      slotNodes: collector.slotNodes,
      templates: collector.templates,
      layouts: collector.layouts,
      decorations: collector.decorations,
      coreSchemas: collector.coreSchemas,
      aliasSchemas: collector.aliasSchemas,
      components: collector.components,
      actions: collector.actions,
      behaviors: collector.behaviors,
      workflows: collector.workflows,
      stateMachines: collector.stateMachines,
      routes: collector.routes,
      packs: collector.packs,
      tokens: Map<String, dynamic>.unmodifiable(tokens),
      metadata: Map<String, dynamic>.unmodifiable(metadata),
    );
  }

  static Map<String, dynamic> _resolveRoot(Map<String, dynamic> raw) {
    final candidates = [
      raw['design_system'],
      raw['designSystem'],
      raw['manifest'],
      raw['package'],
      raw['pack'],
    ];
    for (final candidate in candidates) {
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate.cast<String, dynamic>());
      }
    }
    return raw;
  }

  static Map<String, dynamic> _normalizeRoot(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};
    raw.forEach((dynamic key, dynamic value) {
      out[key.toString()] = _normalizeValue(value);
    });
    return out;
  }

  static dynamic _normalizeValue(dynamic value) {
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((dynamic key, dynamic child) {
        out[key.toString()] = _normalizeValue(child);
      });
      return out;
    }
    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }
    return value;
  }

  static Map<String, dynamic> _sectionMap(
    Map<String, dynamic> root,
    List<String> keys, {
    bool preserveRaw = false,
  }) {
    for (final key in keys) {
      final value = root[key];
      if (value is Map) {
        return preserveRaw
            ? Map<String, dynamic>.from(value.cast<String, dynamic>())
            : Map<String, dynamic>.from(value.cast<String, dynamic>());
      }
    }
    return <String, dynamic>{};
  }

  static String? _string(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _stableHash(dynamic value, [int depth = 0]) {
    if (depth > 16 || value == null) return 0;
    if (value is String || value is num || value is bool) return value.hashCode;
    if (value is Map) {
      final entries = value.entries.toList(growable: false)
        ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
      var hash = entries.length;
      for (final entry in entries) {
        hash = Object.hash(
          hash,
          entry.key.toString(),
          _stableHash(entry.value, depth + 1),
        );
      }
      return hash;
    }
    if (value is Iterable) {
      var hash = 0;
      for (final item in value) {
        hash = Object.hash(hash, _stableHash(item, depth + 1));
      }
      return hash;
    }
    return value.hashCode;
  }
}

final class _SectionCollector {
  final Map<String, Map<String, dynamic>> aliases = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> slotTypes = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> slotNodes = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> templates = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> layouts = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> decorations = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> coreSchemas = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> aliasSchemas = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> components = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> actions = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> behaviors = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> workflows = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> stateMachines = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> routes = <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> packs = <String, Map<String, dynamic>>{};

  void ingest(Map<String, dynamic> root) {
    _ingestAliases(_sectionMap(root, const ['aliases', 'alias']));
    _ingestCoreSection(root, 'box');
    _ingestCoreSection(root, 'action');
    _ingestCoreSection(root, 'field');
    _ingestCoreSection(root, 'text');
    _ingestCoreSection(root, 'media');
    _ingestCoreSection(root, 'data');
    _ingestCoreSection(root, 'portal');
    _ingestCoreSection(root, 'control');
    _ingestCoreSection(root, 'canvas');
    _ingestCoreSection(root, 'system');
    _ingestCoreSection(root, 'decoration');
    _ingestCoreSection(root, 'chart');
    _ingestCoreSection(root, 'animation');

    _ingestStructuredSection(root, const ['components', 'component'], components);
    _ingestStructuredSection(root, const ['templates', 'template'], templates);
    _ingestStructuredSection(root, const ['layouts', 'layout'], layouts);
    _ingestStructuredSection(root, const ['decorations', 'decoration'], decorations);
    _ingestStructuredSection(root, const ['schemas', 'schema'], coreSchemas);
    _ingestStructuredSection(root, const ['aliasSchemas'], aliasSchemas);
    _ingestStructuredSection(root, const ['actions', 'actionDefs'], actions);
    _ingestStructuredSection(root, const ['behaviors', 'behavior'], behaviors);
    _ingestStructuredSection(root, const ['workflows', 'workflow'], workflows);
    _ingestStructuredSection(root, const ['stateMachines', 'state_machine', 'stateMachine'], stateMachines);
    _ingestStructuredSection(root, const ['routes', 'route'], routes);
    _ingestStructuredSection(root, const ['packs', 'pack', 'modules'], packs);

    slotTypes.addAll(_stringMapOfMap(_sectionMap(root, const ['slotTypes', 'slot_types'])));
    slotNodes.addAll(_stringMapOfMap(_sectionMap(root, const ['slotNodes', 'slot_nodes'])));

    // Components often double as alias/template declarations; capture those
    // semantics so a single JSON component block can author the whole stack.
    for (final entry in components.entries) {
      final String name = entry.key;
      final Map<String, dynamic> def = entry.value;
      final dynamic alias = def['alias'] ?? def['name'];
      final dynamic target = def['target'] ?? def['type'];
      if (alias != null && target != null) {
        aliases.putIfAbsent(name, () => _aliasMap(
              alias: name,
              target: target.toString(),
              props: _mapOf(def['defaultProps'] ?? def['props']),
              metadata: _mapOf(def['metadata']),
            ));
      }
      final dynamic template = def['template'] ?? def['ui'] ?? def['view'];
      if (template is Map) {
        templates.putIfAbsent(name,
            () => Map<String, dynamic>.from(template.cast<String, dynamic>()));
      }
      final dynamic slotTypesMap = def['slotTypes'];
      if (slotTypesMap is Map) {
        slotTypes.putIfAbsent(name,
            () => Map<String, dynamic>.from(slotTypesMap.cast<String, dynamic>()));
      }
      final dynamic defaultSlots = def['defaultSlots'] ?? def['slots'];
      if (defaultSlots is Map) {
        slotNodes.putIfAbsent(name,
            () => Map<String, dynamic>.from(defaultSlots.cast<String, dynamic>()));
      }
      final dynamic schema = def['schema'];
      if (schema is Map) {
        coreSchemas.putIfAbsent(name,
            () => Map<String, dynamic>.from(schema.cast<String, dynamic>()));
      }
    }
  }

  void _ingestAliases(Map<String, dynamic> raw) {
    raw.forEach((dynamic key, dynamic value) {
      final alias = key.toString();
      if (value is String) {
        aliases[alias] = _aliasMap(alias: alias, target: value);
        return;
      }
      if (value is Map) {
        final map = Map<String, dynamic>.from(value.cast<String, dynamic>());
        final String target = (map['target'] ?? map['type'] ?? '').toString().trim();
        if (target.isEmpty) return;
        aliases[alias] = _aliasMap(
          alias: alias,
          target: target,
          props: _mapOf(map['defaultProps'] ?? map['props']),
          metadata: _mapOf(map['metadata']),
        );
      }
    });
  }

  void _ingestCoreSection(Map<String, dynamic> root, String key) {
    final raw = root[key];
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    map.forEach((dynamic entryKey, dynamic value) {
      final name = entryKey.toString();
      if (value is String) {
        aliases.putIfAbsent(name, () => _aliasMap(alias: name, target: value));
      } else if (value is Map) {
        final data = Map<String, dynamic>.from(value.cast<String, dynamic>());
        final String target = (data['target'] ?? data['type'] ?? '$key:$name').toString();
        final alias = data['alias']?.toString() ?? name;
        aliases.putIfAbsent(alias, () => _aliasMap(
              alias: alias,
              target: target,
              props: _mapOf(data['defaultProps'] ?? data['props']),
              metadata: _mapOf(data['metadata']),
            ));
        if (key == 'decoration') {
          decorations.putIfAbsent(alias, () => data);
        }
      }
    });
  }

  void _ingestStructuredSection(
    Map<String, dynamic> root,
    List<String> keys,
    Map<String, Map<String, dynamic>> target,
  ) {
    final raw = _sectionMap(root, keys);
    raw.forEach((dynamic key, dynamic value) {
      final name = key.toString();
      if (value is String) {
        target[name] = <String, dynamic>{
          'target': value,
          'type': value,
          'alias': name,
        };
        return;
      }
      if (value is Map) {
        final map = Map<String, dynamic>.from(value.cast<String, dynamic>());
        map.putIfAbsent('name', () => name);
        target[name] = map;
      }
    });
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'aliases': aliases,
        'slotTypes': slotTypes,
        'slotNodes': slotNodes,
        'templates': templates,
        'layouts': layouts,
        'decorations': decorations,
        'coreSchemas': coreSchemas,
        'aliasSchemas': aliasSchemas,
        'components': components,
        'actions': actions,
        'behaviors': behaviors,
        'workflows': workflows,
        'stateMachines': stateMachines,
        'routes': routes,
        'packs': packs,
      };

  static Map<String, dynamic> _aliasMap({
    required String alias,
    required String target,
    Map<String, dynamic> props = const <String, dynamic>{},
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return <String, dynamic>{
      'alias': alias,
      'name': alias,
      'target': target,
      'type': target,
      if (props.isNotEmpty) 'props': Map<String, dynamic>.unmodifiable(props),
      if (metadata.isNotEmpty)
        'metadata': Map<String, dynamic>.unmodifiable(metadata),
    };
  }

  static Map<String, dynamic> _mapOf(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<String, dynamic>());
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic> _sectionMap(Map<String, dynamic> root, List<String> keys) {
    for (final key in keys) {
      final value = root[key];
      if (value is Map) {
        return Map<String, dynamic>.from(value.cast<String, dynamic>());
      }
    }
    return <String, dynamic>{};
  }

  static Map<String, Map<String, dynamic>> _stringMapOfMap(Map<String, dynamic> raw) {
    final out = <String, Map<String, dynamic>>{};
    raw.forEach((dynamic key, dynamic value) {
      if (value is Map) {
        out[key.toString()] = Map<String, dynamic>.from(value.cast<String, dynamic>());
      }
    });
    return out;
  }
}
