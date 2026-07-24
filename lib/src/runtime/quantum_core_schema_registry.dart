// ════════════════════════════════════════════════════════════════════════════
// QUANTUM CORE SCHEMA REGISTRY — lazy file-backed schema catalog
// quantum_core_schema_registry.dart
//
// Goal:
//   • describe the 14 core runtime types + macro in one lazy registry
//   • allow alias schemas to overlay/extend core schemas
//   • support file-backed schema descriptors at build time
//   • keep metadata out of render objects and out of eager boot
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../foundation/quantum_yaml_engine.dart';
import 'quantum_core_file_registry.dart';

@immutable
class QLCorePropSpec {
  final String name;
  final String type;
  final String? description;
  final bool required;
  final bool nullable;
  final dynamic defaultValue;
  final List<String> enumValues;
  final Map<String, dynamic> extras;

  const QLCorePropSpec({
    required this.name,
    required this.type,
    this.description,
    this.required = false,
    this.nullable = true,
    this.defaultValue,
    this.enumValues = const <String>[],
    this.extras = const <String, dynamic>{},
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'type': type,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'required': required,
        'nullable': nullable,
        if (defaultValue != null) 'default': defaultValue,
        if (enumValues.isNotEmpty)
          'enum': List<String>.unmodifiable(enumValues),
        if (extras.isNotEmpty) 'extras': extras,
      };
}

@immutable
class QLCoreSlotSpec {
  final String name;
  final String? description;
  final bool required;
  final Map<String, dynamic> extras;

  const QLCoreSlotSpec({
    required this.name,
    this.description,
    this.required = false,
    this.extras = const <String, dynamic>{},
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        if (description != null && description!.isNotEmpty)
          'description': description,
        'required': required,
        if (extras.isNotEmpty) 'extras': extras,
      };
}

@immutable
class QLCoreSchemaDescriptor {
  final String name;
  final String? extendsName;
  final String summary;
  final String category;
  final List<QLCorePropSpec> props;
  final List<QLCoreSlotSpec> slots;
  final Map<String, dynamic> metadata;
  final bool lazy;

  const QLCoreSchemaDescriptor({
    required this.name,
    this.extendsName,
    this.summary = '',
    this.category = 'core',
    this.props = const <QLCorePropSpec>[],
    this.slots = const <QLCoreSlotSpec>[],
    this.metadata = const <String, dynamic>{},
    this.lazy = true,
  });

  Map<String, dynamic> _mergeMaps(
      Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.isEmpty)
      return b.isEmpty
          ? const <String, dynamic>{}
          : Map<String, dynamic>.from(b);
    if (b.isEmpty) return Map<String, dynamic>.from(a);
    final out = Map<String, dynamic>.from(a);
    out.addAll(b);
    return out;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        if (extendsName != null && extendsName!.isNotEmpty)
          'extends': extendsName,
        if (summary.isNotEmpty) 'summary': summary,
        'category': category,
        'lazy': lazy,
        'props': props.map((p) => p.toMap()).toList(growable: false),
        'slots': slots.map((s) => s.toMap()).toList(growable: false),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };

  QLCoreSchemaDescriptor merge(QLCoreSchemaDescriptor parent) {
    final propsByName = <String, QLCorePropSpec>{
      for (final prop in parent.props) prop.name: prop,
      for (final prop in props) prop.name: prop,
    };
    final slotsByName = <String, QLCoreSlotSpec>{
      for (final slot in parent.slots) slot.name: slot,
      for (final slot in slots) slot.name: slot,
    };
    return QLCoreSchemaDescriptor(
      name: name,
      extendsName: null,
      summary: summary.isEmpty ? parent.summary : summary,
      category: category.isEmpty ? parent.category : category,
      props: List<QLCorePropSpec>.unmodifiable(propsByName.values),
      slots: List<QLCoreSlotSpec>.unmodifiable(slotsByName.values),
      metadata: _mergeMaps(parent.metadata, metadata),
      lazy: lazy || parent.lazy,
    );
  }
}

final class QuantumCoreSchemaRegistry {
  static final QuantumCoreSchemaRegistry instance =
      QuantumCoreSchemaRegistry._();
  QuantumCoreSchemaRegistry._();

  final Map<String, QLCoreSchemaDescriptor> _schemas =
      <String, QLCoreSchemaDescriptor>{};
  final Map<String, String> _schemaFiles = <String, String>{};
  final Map<String, String> _aliasFiles = <String, String>{};
  final Map<String, String> _aliasToTarget = <String, String>{};
  final Map<String, Future<QLCoreSchemaDescriptor?>> _inFlight =
      <String, Future<QLCoreSchemaDescriptor?>>{};
  Map<String, QLCoreSchemaDescriptor>? _builtInCatalogCache;
  bool _seededBuiltIns = false;

  void clear() {
    _schemas.clear();
    _schemaFiles.clear();
    _aliasFiles.clear();
    _aliasToTarget.clear();
    _inFlight.clear();
    _seededBuiltIns = false;
  }

  void installDefaults({
    Map<String, Map<String, dynamic>> coreSchemas =
        const <String, Map<String, dynamic>>{},
    Map<String, Map<String, dynamic>> aliasSchemas =
        const <String, Map<String, dynamic>>{},
    Map<String, String> schemaFiles = const <String, String>{},
    Map<String, String> aliasFiles = const <String, String>{},
  }) {
    if (!_seededBuiltIns) {
      _seedBuiltIns();
    }

    for (final entry in coreSchemas.entries) {
      registerCore(entry.key,
          _descriptorFromMap(entry.key, entry.value, category: 'core'));
    }
    for (final entry in aliasSchemas.entries) {
      registerAlias(entry.key,
          _descriptorFromMap(entry.key, entry.value, category: 'alias'));
    }
    for (final entry in schemaFiles.entries) {
      registerFileSource(entry.key, entry.value, alias: false);
    }
    for (final entry in aliasFiles.entries) {
      registerFileSource(entry.key, entry.value, alias: true);
    }
  }

  void registerCore(String name, QLCoreSchemaDescriptor schema) {
    final key = _norm(name);
    _schemas[key] = schema;
  }

  void registerAlias(String name, QLCoreSchemaDescriptor schema,
      {String? target}) {
    final key = _norm(name);
    _schemas[key] = schema;
    if (target != null && target.trim().isNotEmpty) {
      _aliasToTarget[key] = _norm(target);
    }
  }

  void registerFileSource(String name, String assetPath,
      {required bool alias}) {
    final key = _norm(name);
    final value = assetPath.trim();
    if (value.isEmpty) return;
    if (alias) {
      _aliasFiles[key] = value;
    } else {
      _schemaFiles[key] = value;
    }
  }

  bool hasName(String name) =>
      _schemas.containsKey(_norm(name)) ||
      _schemaFiles.containsKey(_norm(name)) ||
      _aliasFiles.containsKey(_norm(name));

  QLCoreSchemaDescriptor? peek(String name) {
    final key = _norm(name);
    final cached = _schemas[key];
    if (cached == null) return null;
    if (cached.extendsName != null && cached.extendsName!.isNotEmpty) {
      final parent = _schemas[cached.extendsName!] ??
          _builtInCatalog()[cached.extendsName!];
      if (parent != null) {
        final merged = cached.merge(parent);
        _schemas[key] = merged;
        return merged;
      }
    }
    return cached;
  }

  Future<QLCoreSchemaDescriptor?> resolve(String name) async {
    final key = _norm(name);
    final cached = peek(key);
    if (cached != null) {
      if (cached.extendsName != null && cached.extendsName!.isNotEmpty) {
        final parent =
            peek(cached.extendsName!) ?? await resolve(cached.extendsName!);
        if (parent != null && parent.name != cached.name) {
          final merged = cached.merge(parent);
          _schemas[key] = merged;
          return merged;
        }
      }
      return cached;
    }
    final inflight = _inFlight[key];
    if (inflight != null) return inflight;
    final future = _resolveAsync(key);
    _inFlight[key] = future;
    return future.whenComplete(() => _inFlight.remove(key));
  }

  Future<Map<String, dynamic>?> describe(String name) async {
    final schema = await resolve(name);
    return schema?.toMap();
  }

  Map<String, dynamic>? describeCached(String name) => peek(name)?.toMap();

  Future<Map<String, dynamic>?> describeAny(String name) async =>
      describe(name);

  QLCoreSchemaDescriptor? schemaOrNull(String name) => peek(name);

  Map<String, dynamic> snapshot() => <String, dynamic>{
        'schemas': _schemas.map((k, v) => MapEntry(k, v.toMap())),
        'aliases': Map<String, String>.unmodifiable(_aliasToTarget),
        'schemaFiles': Map<String, String>.unmodifiable(_schemaFiles),
        'aliasFiles': Map<String, String>.unmodifiable(_aliasFiles),
      };

  String exportMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Quantum Core Schema Catalog');
    for (final entry in _schemas.entries) {
      final schema = entry.value;
      buffer.writeln('');
      buffer.writeln('## ${schema.name}');
      if (schema.summary.isNotEmpty) buffer.writeln(schema.summary);
      if (schema.extendsName != null) {
        buffer.writeln('Extends: ${schema.extendsName}');
      }
      if (schema.props.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('### Props');
        for (final prop in schema.props) {
          buffer.writeln(
              '- `${prop.name}` — ${prop.type}${prop.description == null ? '' : ' — ${prop.description}'}');
        }
      }
      if (schema.slots.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('### Slots');
        for (final slot in schema.slots) {
          buffer.writeln(
              '- `${slot.name}`${slot.description == null ? '' : ' — ${slot.description}'}');
        }
      }
    }
    return buffer.toString();
  }

  Future<void> _seedBuiltIns() async {
    final catalog = _builtInCatalog();
    for (final entry in catalog.entries) {
      _schemas.putIfAbsent(entry.key, () => entry.value);
    }
    _seededBuiltIns = true;
  }

  Future<QLCoreSchemaDescriptor?> _resolveAsync(String key) async {
    final file = _schemaFiles[key] ?? _aliasFiles[key];
    if (file == null) {
      final aliasTarget = _aliasToTarget[key];
      if (aliasTarget != null) {
        final base = await resolve(aliasTarget);
        if (base != null) {
          final alias = _schemas[key];
          if (alias != null) {
            final merged = alias.merge(base);
            _schemas[key] = merged;
            return merged;
          }
          return base;
        }
      }
      return peek(key);
    }

    final raw = await QuantumYamlEngine.instance.load(file);
    final desc = _compileFromFile(key, raw, sourcePath: file);
    if (desc.extendsName != null && desc.extendsName!.isNotEmpty) {
      final parent =
          peek(desc.extendsName!) ?? await resolve(desc.extendsName!);
      if (parent != null && parent.name != desc.name) {
        final merged = desc.merge(parent);
        _schemas[key] = merged;
        return merged;
      }
    }
    _schemas[key] = desc;
    return desc;
  }

  QLCoreSchemaDescriptor _compileFromFile(String key, Map<String, dynamic> raw,
      {required String sourcePath}) {
    final map = Map<String, dynamic>.from(raw);
    final extendsName = _norm(map['extends']?.toString() ??
        map['base']?.toString() ??
        map['aliasOf']?.toString() ??
        '');
    final desc = _descriptorFromMap(
      key,
      map,
      category: map['category']?.toString() ??
          (_aliasFiles.containsKey(key) ? 'alias' : 'core'),
      defaultSummary: 'Loaded from $sourcePath',
    );
    if (extendsName.isNotEmpty && extendsName != key) {
      final parent = peek(extendsName) ?? _builtInCatalog()[extendsName];
      if (parent != null) {
        return desc.merge(parent);
      }
      _aliasToTarget[key] = extendsName;
    }
    return desc;
  }

  QLCoreSchemaDescriptor _descriptorFromMap(
    String key,
    Map<String, dynamic> raw, {
    required String category,
    String defaultSummary = '',
  }) {
    final extendsName = _norm(raw['extends']?.toString() ??
        raw['base']?.toString() ??
        raw['aliasOf']?.toString() ??
        '');
    final props = _parseProps(raw['props'] ?? raw['properties']);
    final slots = _parseSlots(raw['slots']);
    final metadata = Map<String, dynamic>.from(raw['metadata'] is Map
        ? raw['metadata'] as Map
        : const <String, dynamic>{});
    return QLCoreSchemaDescriptor(
      name: key,
      extendsName: extendsName.isEmpty ? null : extendsName,
      summary: raw['summary']?.toString() ?? defaultSummary,
      category: raw['category']?.toString() ?? category,
      props: List<QLCorePropSpec>.unmodifiable(props),
      slots: List<QLCoreSlotSpec>.unmodifiable(slots),
      metadata: metadata,
      lazy: raw['lazy'] as bool? ?? true,
    );
  }

  List<QLCorePropSpec> _parseProps(dynamic input) {
    if (input is! List) return const <QLCorePropSpec>[];
    final out = <QLCorePropSpec>[];
    for (final item in input) {
      if (item is String) {
        out.add(_prop(item,
            type: _guessType(item), description: _propDescription(item)));
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item.cast<String, dynamic>());
        final name = map['name']?.toString();
        if (name == null || name.isEmpty) continue;
        out.add(QLCorePropSpec(
          name: name,
          type: map['type']?.toString() ?? _guessType(name),
          description: map['description']?.toString() ??
              map['desc']?.toString() ??
              _propDescription(name),
          required: map['required'] as bool? ?? false,
          nullable: map['nullable'] as bool? ?? true,
          defaultValue: map.containsKey('default') ? map['default'] : null,
          enumValues: _stringList(map['enum'] ?? map['values']),
          extras: _extraMap(map),
        ));
      }
    }
    return out;
  }

  List<QLCoreSlotSpec> _parseSlots(dynamic input) {
    if (input is! List) return const <QLCoreSlotSpec>[];
    final out = <QLCoreSlotSpec>[];
    for (final item in input) {
      if (item is String) {
        out.add(_slot(item, description: '$item slot.'));
      } else if (item is Map) {
        final map = Map<String, dynamic>.from(item.cast<String, dynamic>());
        final name = map['name']?.toString();
        if (name == null || name.isEmpty) continue;
        out.add(QLCoreSlotSpec(
          name: name,
          description:
              map['description']?.toString() ?? map['desc']?.toString(),
          required: map['required'] as bool? ?? false,
          extras: _extraMap(map),
        ));
      }
    }
    return out;
  }

  List<String> _stringList(dynamic input) {
    if (input is! List) return const <String>[];
    return List<String>.unmodifiable(
      input.map((e) => e.toString()).where((e) => e.isNotEmpty),
    );
  }

  Map<String, dynamic> _extraMap(Map<String, dynamic> map) {
    final extras = <String, dynamic>{};
    const skipped = <String>{
      'name',
      'type',
      'description',
      'desc',
      'required',
      'nullable',
      'default',
      'enum',
      'values',
      'kind'
    };
    for (final entry in map.entries) {
      if (skipped.contains(entry.key)) continue;
      extras[entry.key] = entry.value;
    }
    return extras.isEmpty ? const <String, dynamic>{} : extras;
  }

  String _norm(String name) => name.trim().toLowerCase();

  String _guessType(String name) {
    final n = name.toLowerCase();
    if (n == '__subtype') return 'String';
    if (n.startsWith('on')) return 'Callback';
    if (n.contains('bind')) return 'Binding';
    if (n == 'id' ||
        n == 'key' ||
        n == 'name' ||
        n == 'label' ||
        n == 'title' ||
        n == 'text' ||
        n == 'href' ||
        n == 'path' ||
        n == 'src' ||
        n == 'url' ||
        n == 'icon' ||
        n == 'route' ||
        n == 'channel' ||
        n == 'mode' ||
        n == 'variant' ||
        n == 'align' ||
        n == 'style' ||
        n == 'fit' ||
        n == 'theme' ||
        n == 'shape' ||
        n == 'intent' ||
        n == 'placeholder' ||
        n == 'routekey' ||
        n == 'selectionkey' ||
        n == 'statekey' ||
        n == 'namespace' ||
        n == 'contract' ||
        n == 'fallback') return 'String';
    if (n == 'props' ||
        n == 'state' ||
        n == 'metadata' ||
        n == 'raw' ||
        n == 'config') return 'Map<String, dynamic>';
    if (n == 'children' ||
        n == 'items' ||
        n == 'entries' ||
        n == 'cells' ||
        n == 'rows' ||
        n == 'cols' ||
        n == 'columns' ||
        n == 'parts' ||
        n == 'segments' ||
        n == 'spans' ||
        n == 'steps' ||
        n == 'categories' ||
        n == 'avatars' ||
        n == 'rolenames' ||
        n == 'slots' ||
        n == 'commands') return 'List';
    if (n == 'padding' ||
        n == 'margin' ||
        n == 'gap' ||
        n == 'radius' ||
        n == 'opacity' ||
        n == 'scale' ||
        n == 'height' ||
        n == 'width' ||
        n == 'min' ||
        n == 'max' ||
        n == 'x' ||
        n == 'y' ||
        n == 'left' ||
        n == 'right' ||
        n == 'top' ||
        n == 'bottom' ||
        n == 'thickness' ||
        n == 'strength' ||
        n == 'stiffness' ||
        n == 'damping' ||
        n == 'progress' ||
        n == 'speed' ||
        n == 'blurintensity' ||
        n == 'cornerradius') return 'double';
    if (n.endsWith('ms') || n == 'interval') return 'int';
    if (n == 'disabled' ||
        n == 'readonly' ||
        n == 'selectable' ||
        n == 'multiple' ||
        n == 'draggable' ||
        n == 'autoplay' ||
        n == 'loop' ||
        n == 'progressive' ||
        n == 'dense' ||
        n == 'floating' ||
        n == 'expand' ||
        n == 'ignorepointer' ||
        n == 'absorbpointer' ||
        n == 'showdraghandle' ||
        n == 'barrierdismissible' ||
        n == 'allowresize' ||
        n == 'enabledrag' ||
        n == 'ismodal' ||
        n == 'heroflight' ||
        n == 'lockaspect' ||
        n == 'longpressdraggable' ||
        n == 'suppressparentdata' ||
        n == 'mergestyle' ||
        n == 'selected' ||
        n == 'active' ||
        n == 'hidden') return 'bool';
    if (n.contains('color') ||
        n.contains('fill') ||
        n.contains('stroke') ||
        n.contains('bg')) return 'Color';
    return 'dynamic';
  }

  String _propDescription(String name) {
    if (name == '__subType') return 'Internal subtype discriminator.';
    if (name.startsWith('on'))
      return 'Event callback for ${name.substring(2)}.';
    if (name.contains('bind'))
      return 'Runtime binding key for lazy state lookup.';
    return '$name value.';
  }

  Map<String, QLCoreSchemaDescriptor> _builtInCatalog() =>
      _builtInCatalogCache ??= <String, QLCoreSchemaDescriptor>{
        'macro': _schema(
          name: 'macro',
          summary: 'Lazy macro definition core.',
          category: 'macro',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Macro name.'),
            _prop('pattern', type: 'dynamic', description: 'Matching pattern.'),
            _prop('when', type: 'dynamic', description: 'Activation rule.'),
            _prop('replace',
                type: 'dynamic', description: 'Expansion payload.'),
            _prop('args', type: 'List', description: 'Macro arguments.'),
            _prop('slots',
                type: 'List', description: 'Macro slot definitions.'),
            _prop('description',
                type: 'String', description: 'Optional description.'),
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'design_system': _schema(
          name: 'design_system',
          summary: 'Top-level manifest for a full Quantum design system.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('id', type: 'String', description: 'Design system id.'),
            _prop('name', type: 'String', description: 'Design system name.'),
            _prop('version', type: 'String', description: 'Version string.'),
            _prop('tokens',
                type: 'Map<String, dynamic>', description: 'Token graph.'),
            _prop('components',
                type: 'Map', description: 'Component definitions.'),
            _prop('templates',
                type: 'Map', description: 'Template definitions.'),
            _prop('layouts', type: 'Map', description: 'Layout definitions.'),
            _prop('schemas', type: 'Map', description: 'Schema definitions.'),
            _prop('actions', type: 'Map', description: 'Action definitions.'),
            _prop('workflows',
                type: 'Map', description: 'Workflow definitions.'),
            _prop('routes', type: 'Map', description: 'Route definitions.'),
            _prop('packs', type: 'Map', description: 'Pack definitions.'),
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'component': _schema(
          name: 'component',
          summary: 'Schema for a semantic public component.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Component name.'),
            _prop('target', type: 'String', description: 'Canonical target.'),
            _prop('template', type: 'dynamic', description: 'Template shell.'),
            _prop('slots', type: 'Map', description: 'Slot declarations.'),
            _prop('defaultProps', type: 'Map', description: 'Default props.'),
            _prop('schema', type: 'Map', description: 'Inline schema.'),
          ],
          slots: <QLCoreSlotSpec>[
            _slot('header', description: 'Header slot.'),
            _slot('body', description: 'Body slot.'),
            _slot('footer', description: 'Footer slot.'),
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'template': _schema(
          name: 'template',
          summary: 'Schema for reusable template shells.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Template name.'),
            _prop('extends', type: 'String', description: 'Base template.'),
            _prop('layout', type: 'List', description: 'Layout matrix.'),
            _prop('defaultSlots', type: 'Map', description: 'Default slots.'),
            _prop('variants', type: 'Map', description: 'Variant shells.'),
            _prop('initialState', type: 'Map', description: 'Initial state.'),
          ],
          slots: <QLCoreSlotSpec>[
            _slot('default', description: 'Default slot.'),
            _slot('header', description: 'Header slot.'),
            _slot('body', description: 'Body slot.'),
            _slot('footer', description: 'Footer slot.'),
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'workflow': _schema(
          name: 'workflow',
          summary: 'Declarative workflow graph schema.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Workflow name.'),
            _prop('steps', type: 'List', description: 'Ordered steps.'),
            _prop('transitions', type: 'Map', description: 'Transition map.'),
            _prop('guards', type: 'Map', description: 'Guard conditions.'),
            _prop('actions', type: 'Map', description: 'Action hooks.'),
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'state_machine': _schema(
          name: 'state_machine',
          summary: 'Declarative state machine schema.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Machine name.'),
            _prop('states', type: 'Map', description: 'State table.'),
            _prop('events', type: 'Map', description: 'Event table.'),
            _prop('transitions', type: 'Map', description: 'Transition table.'),
            _prop('initial', type: 'String', description: 'Initial state.'),
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'route': _schema(
          name: 'route',
          summary: 'Route and shell schema.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Route name.'),
            _prop('path', type: 'String', description: 'Route path.'),
            _prop('shell', type: 'String', description: 'Shell template.'),
            _prop('guards', type: 'Map', description: 'Guard rules.'),
            _prop('metadata',
                type: 'Map<String, dynamic>', description: 'Route metadata.'),
          ],
          slots: <QLCoreSlotSpec>[
            _slot('page', description: 'Page slot.'),
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'pack': _schema(
          name: 'pack',
          summary: 'Reusable design-system or app pack schema.',
          category: 'manifest',
          props: <QLCorePropSpec>[
            _prop('name', type: 'String', description: 'Pack name.'),
            _prop('components', type: 'Map', description: 'Component pack.'),
            _prop('templates', type: 'Map', description: 'Template pack.'),
            _prop('schemas', type: 'Map', description: 'Schema pack.'),
            _prop('routes', type: 'Map', description: 'Route pack.'),
            _prop('metadata',
                type: 'Map<String, dynamic>', description: 'Pack metadata.'),
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'action': _schema(
          name: 'action',
          summary: 'Interactive gesture and command core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('bindPressure',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindState',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindX',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindY',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('href', type: 'String', description: 'href value.'),
            _prop('icon', type: 'String', description: 'icon value.'),
            _prop('margin', type: 'double', description: 'margin value.'),
            _prop('matrixBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('text', type: 'String', description: 'text value.'),
            _prop('value', type: 'dynamic', description: 'value value.')
          ],
          slots: <QLCoreSlotSpec>[_slot('icon', description: 'icon slot.')],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'box': _schema(
          name: 'box',
          summary: 'Layout and container core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('clipKind', type: 'dynamic', description: 'clipKind value.'),
            _prop('cols', type: 'List', description: 'cols value.'),
            _prop('curve', type: 'dynamic', description: 'curve value.'),
            _prop('direction',
                type: 'dynamic', description: 'direction value.'),
            _prop('dragAxis', type: 'dynamic', description: 'dragAxis value.'),
            _prop('dragData', type: 'dynamic', description: 'dragData value.'),
            _prop('fill', type: 'Color', description: 'fill value.'),
            _prop('fractions',
                type: 'dynamic', description: 'fractions value.'),
            _prop('gridCols', type: 'dynamic', description: 'gridCols value.'),
            _prop('gridRows', type: 'dynamic', description: 'gridRows value.'),
            _prop('heroTag', type: 'dynamic', description: 'heroTag value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('justify', type: 'dynamic', description: 'justify value.'),
            _prop('margin', type: 'double', description: 'margin value.'),
            _prop('matrix', type: 'dynamic', description: 'matrix value.'),
            _prop('matrixBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('opacityBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('rows', type: 'List', description: 'rows value.'),
            _prop('scale', type: 'double', description: 'scale value.'),
            _prop('semanticLabel',
                type: 'dynamic', description: 'semanticLabel value.'),
            _prop('style', type: 'String', description: 'style value.'),
            _prop('transformBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('transition',
                type: 'dynamic', description: 'transition value.'),
            _prop('variant', type: 'String', description: 'variant value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'canvas': _schema(
          name: 'canvas',
          summary: 'Procedural drawing and shader core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('baseline', type: 'dynamic', description: 'baseline value.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('commands', type: 'List', description: 'commands value.'),
            _prop('mode', type: 'String', description: 'mode value.'),
            _prop('shapeDef', type: 'dynamic', description: 'shapeDef value.'),
            _prop('src', type: 'String', description: 'src value.'),
            _prop('uniformBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'connect': _schema(
          name: 'connect',
          summary: 'Connectivity and contract bridge core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('activeRole',
                type: 'String', description: 'activeRole value.'),
            _prop('channel', type: 'String', description: 'channel value.'),
            _prop('contract', type: 'String', description: 'contract value.'),
            _prop('fallback', type: 'String', description: 'fallback value.'),
            _prop('focusChannel',
                type: 'dynamic', description: 'focusChannel value.'),
            _prop('heroTag', type: 'dynamic', description: 'heroTag value.'),
            _prop('phaseChannel',
                type: 'dynamic', description: 'phaseChannel value.'),
            _prop('roleNames', type: 'List', description: 'roleNames value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'control': _schema(
          name: 'control',
          summary: 'Selection, navigation, and control core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('heroKey', type: 'dynamic', description: 'heroKey value.'),
            _prop('id', type: 'String', description: 'id value.'),
            _prop('initialState',
                type: 'dynamic', description: 'initialState value.'),
            _prop('namespace', type: 'String', description: 'namespace value.'),
            _prop('routeKey', type: 'String', description: 'routeKey value.'),
            _prop('selectionKey',
                type: 'String', description: 'selectionKey value.'),
            _prop('stateKey', type: 'String', description: 'stateKey value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'data': _schema(
          name: 'data',
          summary: 'Collection and repetition core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('as', type: 'dynamic', description: 'as value.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('cols', type: 'List', description: 'cols value.'),
            _prop('direction',
                type: 'dynamic', description: 'direction value.'),
            _prop('empty', type: 'dynamic', description: 'empty value.'),
            _prop('header', type: 'dynamic', description: 'header value.'),
            _prop('indexAs', type: 'dynamic', description: 'indexAs value.'),
            _prop('pipeline', type: 'dynamic', description: 'pipeline value.'),
            _prop('searchBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.')
          ],
          slots: <QLCoreSlotSpec>[
            _slot('empty', description: 'empty slot.'),
            _slot('header', description: 'header slot.')
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'decoration': _schema(
          name: 'decoration',
          summary: 'Styling and surface decoration core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('mergeStyle', type: 'bool', description: 'mergeStyle value.'),
            _prop('style', type: 'String', description: 'style value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'field': _schema(
          name: 'field',
          summary: 'Form field and input core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('id', type: 'String', description: 'id value.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('prefix', type: 'dynamic', description: 'prefix value.'),
            _prop('suffix', type: 'dynamic', description: 'suffix value.')
          ],
          slots: <QLCoreSlotSpec>[
            _slot('prefix', description: 'prefix slot.'),
            _slot('suffix', description: 'suffix slot.')
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'layout': _schema(
          name: 'layout',
          summary: 'Layout selection and composition core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('id', type: 'String', description: 'id value.'),
            _prop('layoutId', type: 'dynamic', description: 'layoutId value.'),
            _prop('match', type: 'dynamic', description: 'match value.'),
            _prop('selectedStyle',
                type: 'dynamic', description: 'selectedStyle value.'),
            _prop('style', type: 'String', description: 'style value.'),
            _prop('text', type: 'String', description: 'text value.'),
            _prop('value', type: 'dynamic', description: 'value value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'media': _schema(
          name: 'media',
          summary: 'Image, video, chart, and audio core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('audioUrl', type: 'dynamic', description: 'audioUrl value.'),
            _prop('chartType',
                type: 'dynamic', description: 'chartType value.'),
            _prop('error', type: 'dynamic', description: 'error value.'),
            _prop('fit', type: 'String', description: 'fit value.'),
            _prop('fontFamily',
                type: 'dynamic', description: 'fontFamily value.'),
            _prop('id', type: 'String', description: 'id value.'),
            _prop('path', type: 'String', description: 'path value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('placeholderBase64',
                type: 'dynamic', description: 'placeholderBase64 value.'),
            _prop('poster', type: 'dynamic', description: 'poster value.'),
            _prop('src', type: 'String', description: 'src value.'),
            _prop('subtitleUrl',
                type: 'dynamic', description: 'subtitleUrl value.')
          ],
          slots: <QLCoreSlotSpec>[
            _slot('error', description: 'error slot.'),
            _slot('placeholder', description: 'placeholder slot.')
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'chart': _schema(
          name: 'chart',
          summary: 'High-performance chart visualization core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('chartType',
                type: 'String', description: 'Chart type such as line or bar.'),
            _prop('color', type: 'Color', description: 'Primary chart color.'),
            _prop('data',
                type: 'List', description: 'Series data for the chart.'),
            _prop('showAxes',
                type: 'bool', description: 'Show axis scaffolding.'),
            _prop('showGrid', type: 'bool', description: 'Show grid lines.'),
            _prop('animated',
                type: 'bool', description: 'Animate chart entrance.'),
            _prop('lineWidth',
                type: 'double', description: 'Line stroke width.'),
            _prop('tooltip',
                type: 'dynamic', description: 'Tooltip slot or template.'),
            _prop('palette',
                type: 'List', description: 'Optional chart palette.'),
            _prop('stacked',
                type: 'bool', description: 'Stack series where supported.'),
            _prop('smooth',
                type: 'bool', description: 'Use smooth curves when supported.')
          ],
          slots: <QLCoreSlotSpec>[
            _slot('tooltip', description: 'Tooltip slot.'),
            _slot('header', description: 'Header slot.'),
            _slot('footer', description: 'Footer slot.'),
            _slot('overlay', description: 'Overlay slot.')
          ],
          metadata: const <String, dynamic>{
            'source': 'built-in',
            'core': 'chart'
          },
        ),
        'animation': _schema(
          name: 'animation',
          summary: 'High-performance animation motion core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('animationType',
                type: 'String',
                description: 'Animation variant such as fade or scale.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('curve', type: 'String', description: 'Curve identifier.'),
            _prop('delayMs',
                type: 'int', description: 'Delay before animation starts.'),
            _prop('durationMs',
                type: 'int',
                description: 'Animation duration in milliseconds.'),
            _prop('from',
                type: 'double', description: 'Starting scalar value.'),
            _prop('to', type: 'double', description: 'Ending scalar value.'),
            _prop('fromX', type: 'double', description: 'Start X translation.'),
            _prop('fromY', type: 'double', description: 'Start Y translation.'),
            _prop('toX', type: 'double', description: 'End X translation.'),
            _prop('toY', type: 'double', description: 'End Y translation.')
          ],
          slots: <QLCoreSlotSpec>[
            _slot('child', description: 'Animated child.'),
            _slot('from', description: 'Starting state slot.'),
            _slot('to', description: 'Ending state slot.')
          ],
          metadata: const <String, dynamic>{
            'source': 'built-in',
            'core': 'animation'
          },
        ),
        'portal': _schema(
          name: 'portal',
          summary: 'Overlay, sheet, and dialog core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('bgEffect', type: 'Color', description: 'bgEffect value.'),
            _prop('content', type: 'dynamic', description: 'content value.'),
            _prop('edge', type: 'dynamic', description: 'edge value.'),
            _prop('resizeEdges',
                type: 'dynamic', description: 'resizeEdges value.'),
            _prop('sheetAlignment',
                type: 'dynamic', description: 'sheetAlignment value.'),
            _prop('trigger', type: 'dynamic', description: 'trigger value.'),
            _prop('triggerBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.')
          ],
          slots: <QLCoreSlotSpec>[
            _slot('content', description: 'Primary content slot.'),
            _slot('trigger', description: 'trigger slot.')
          ],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'system': _schema(
          name: 'system',
          summary: 'System behaviors, lifecycle, and orchestration core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('as', type: 'dynamic', description: 'as value.'),
            _prop('axis', type: 'dynamic', description: 'axis value.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindOutput',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindSource',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindX',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('bindY',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('direction',
                type: 'dynamic', description: 'direction value.'),
            _prop('indexAs', type: 'dynamic', description: 'indexAs value.'),
            _prop('initialState',
                type: 'dynamic', description: 'initialState value.'),
            _prop('mode', type: 'String', description: 'mode value.'),
            _prop('outputBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('pipeline', type: 'dynamic', description: 'pipeline value.'),
            _prop('props',
                type: 'Map<String, dynamic>', description: 'props value.'),
            _prop('task', type: 'dynamic', description: 'task value.'),
            _prop('template', type: 'dynamic', description: 'template value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'template': _schema(
          name: 'template',
          summary: 'Reusable composition and content template core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('activeFill',
                type: 'Color', description: 'activeFill value.'),
            _prop('avatars', type: 'List', description: 'avatars value.'),
            _prop('backText', type: 'dynamic', description: 'backText value.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('categories', type: 'List', description: 'categories value.'),
            _prop('cells', type: 'List', description: 'cells value.'),
            _prop('children', type: 'List', description: 'children value.'),
            _prop('columns', type: 'List', description: 'columns value.'),
            _prop('doneText', type: 'dynamic', description: 'doneText value.'),
            _prop('dragData', type: 'dynamic', description: 'dragData value.'),
            _prop('entries', type: 'List', description: 'entries value.'),
            _prop('heroId', type: 'dynamic', description: 'heroId value.'),
            _prop('intent', type: 'String', description: 'intent value.'),
            _prop('itemScale',
                type: 'dynamic', description: 'itemScale value.'),
            _prop('itemStyle',
                type: 'dynamic', description: 'itemStyle value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('nextText', type: 'dynamic', description: 'nextText value.'),
            _prop('onDone',
                type: 'Callback', description: 'Event callback for done.'),
            _prop('onSelect',
                type: 'Callback', description: 'Event callback for select.'),
            _prop('onToggle',
                type: 'Callback', description: 'Event callback for toggle.'),
            _prop('prevText', type: 'dynamic', description: 'prevText value.'),
            _prop('rows', type: 'List', description: 'rows value.'),
            _prop('steps', type: 'List', description: 'steps value.'),
            _prop('subtitle', type: 'dynamic', description: 'subtitle value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'text': _schema(
          name: 'text',
          summary: 'Text rendering and content core.',
          category: 'core',
          props: <QLCorePropSpec>[
            _prop('__subType',
                type: 'String', description: 'Internal subtype discriminator.'),
            _prop('overflow', type: 'dynamic', description: 'overflow value.'),
            _prop('style', type: 'String', description: 'style value.'),
            _prop('text', type: 'String', description: 'text value.'),
            _prop('value', type: 'dynamic', description: 'value value.')
          ],
          slots: <QLCoreSlotSpec>[],
          metadata: const <String, dynamic>{'source': 'built-in'},
        ),
        'row': _schema(
          name: 'row',
          extendsName: 'box',
          summary: 'Alias for box:row.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:row'},
        ),
        'col': _schema(
          name: 'col',
          extendsName: 'box',
          summary: 'Alias for box:col.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:col'},
        ),
        'stack': _schema(
          name: 'stack',
          extendsName: 'box',
          summary: 'Alias for box:stack.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:stack'},
        ),
        'wrap': _schema(
          name: 'wrap',
          extendsName: 'box',
          summary: 'Alias for box:wrap.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:wrap'},
        ),
        'grid': _schema(
          name: 'grid',
          extendsName: 'box',
          summary: 'Alias for box:grid.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:grid'},
        ),
        'masonry': _schema(
          name: 'masonry',
          extendsName: 'box',
          summary: 'Alias for box:masonry.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:masonry'},
        ),
        'morph': _schema(
          name: 'morph',
          extendsName: 'box',
          summary: 'Alias for box:morph.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'box:morph'},
        ),
        'surface': _schema(
          name: 'surface',
          extendsName: 'box',
          summary: 'Alias for box:surface.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'box:surface'},
        ),
        'flow': _schema(
          name: 'flow',
          extendsName: 'control',
          summary: 'Alias for control:flow.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'control:flow'},
        ),
        'workflow': _schema(
          name: 'workflow',
          extendsName: 'control',
          summary: 'Alias for control:flow.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'control:flow'},
        ),
        'shell': _schema(
          name: 'shell',
          extendsName: 'box',
          summary: 'Alias for box:shell.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:shell'},
        ),
        'viewport': _schema(
          name: 'viewport',
          extendsName: 'box',
          summary: 'Alias for box:viewport.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:viewport'},
        ),
        'responsive': _schema(
          name: 'responsive',
          extendsName: 'box',
          summary: 'Alias for box:responsive.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:responsive'},
        ),
        'decorate': _schema(
          name: 'decorate',
          extendsName: 'decoration',
          summary: 'Alias for decoration:merge.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'decoration:merge'},
        ),
        'highlight': _schema(
          name: 'highlight',
          extendsName: 'decoration',
          summary: 'Alias for decoration:text.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'decoration:text'},
        ),
        'markup': _schema(
          name: 'markup',
          extendsName: 'decoration',
          summary: 'Alias for decoration:text.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'decoration:text'},
        ),
        'measure': _schema(
          name: 'measure',
          extendsName: 'box',
          summary: 'Alias for box:measure.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:measure'},
        ),
        'builder': _schema(
          name: 'builder',
          extendsName: 'box',
          summary: 'Alias for box:builder.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:builder'},
        ),
        'layer': _schema(
          name: 'layer',
          extendsName: 'box',
          summary: 'Alias for box:layer.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:layer'},
        ),
        'matrix': _schema(
          name: 'matrix',
          extendsName: 'box',
          summary: 'Alias for box:matrix.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('children', type: 'List', description: 'children value.'),
            _prop('items', type: 'List', description: 'items value.'),
            _prop('align', type: 'String', description: 'align value.'),
            _prop('padding', type: 'double', description: 'padding value.'),
            _prop('margin', type: 'double', description: 'margin value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'box:matrix'},
        ),
        'sliver_plane': _schema(
          name: 'sliver_plane',
          extendsName: 'data',
          summary: 'Alias for data:sliver_plane.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'data:sliver_plane'},
        ),
        'sliver': _schema(
          name: 'sliver',
          extendsName: 'data',
          summary: 'Alias for data:sliver.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'data:sliver'},
        ),
        'shader': _schema(
          name: 'shader',
          extendsName: 'canvas',
          summary: 'Alias for canvas:shader.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'canvas:shader'},
        ),
        'raw_pointer': _schema(
          name: 'raw_pointer',
          extendsName: 'action',
          summary: 'Alias for action:raw_pointer.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'action:raw_pointer'},
        ),
        'pointer': _schema(
          name: 'pointer',
          extendsName: 'action',
          summary: 'Alias for action:pointer.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'action:pointer'},
        ),
        'focus': _schema(
          name: 'focus',
          extendsName: 'action',
          summary: 'Alias for action:focus.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'action:focus'},
        ),
        'sync_scroll': _schema(
          name: 'sync_scroll',
          extendsName: 'system',
          summary: 'Alias for system:sync_scroll.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'system:sync_scroll'},
        ),
        'worker': _schema(
          name: 'worker',
          extendsName: 'system',
          summary: 'Alias for system:worker.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'system:worker'},
        ),
        'ticker': _schema(
          name: 'ticker',
          extendsName: 'system',
          summary: 'Alias for system:ticker.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'system:ticker'},
        ),
        'overlay_entry': _schema(
          name: 'overlay_entry',
          extendsName: 'portal',
          summary: 'Alias for portal:overlay_entry.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'portal:overlay_entry'},
        ),
        'overlay': _schema(
          name: 'overlay',
          extendsName: 'portal',
          summary: 'Alias for portal:overlay.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'portal:overlay'},
        ),
        'form_scope': _schema(
          name: 'form_scope',
          extendsName: 'control',
          summary: 'Alias for control:form_scope.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'control:form_scope'},
        ),
        'omega_macro': _schema(
          name: 'omega_macro',
          extendsName: 'system',
          summary: 'Alias for system:omega_macro.',
          category: 'alias',
          props: <QLCorePropSpec>[],
          metadata: const <String, dynamic>{'aliasOf': 'system:omega_macro'},
        ),
        'button': _schema(
          name: 'button',
          extendsName: 'action',
          summary: 'Alias for action:button.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('text', type: 'String', description: 'text value.'),
            _prop('icon', type: 'String', description: 'icon value.'),
            _prop('loading', type: 'dynamic', description: 'loading value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('onTap',
                type: 'Callback', description: 'Event callback for tap.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'action:button'},
        ),
        'tap': _schema(
          name: 'tap',
          extendsName: 'action',
          summary: 'Alias for action:button.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('text', type: 'String', description: 'text value.'),
            _prop('icon', type: 'String', description: 'icon value.'),
            _prop('loading', type: 'dynamic', description: 'loading value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('onTap',
                type: 'Callback', description: 'Event callback for tap.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'action:button'},
        ),
        'press': _schema(
          name: 'press',
          extendsName: 'action',
          summary: 'Alias for action:button.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('text', type: 'String', description: 'text value.'),
            _prop('icon', type: 'String', description: 'icon value.'),
            _prop('loading', type: 'dynamic', description: 'loading value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('onTap',
                type: 'Callback', description: 'Event callback for tap.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'action:button'},
        ),
        'hover_action': _schema(
          name: 'hover_action',
          extendsName: 'action',
          summary: 'Alias for action:hover.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('text', type: 'String', description: 'text value.'),
            _prop('icon', type: 'String', description: 'icon value.'),
            _prop('loading', type: 'dynamic', description: 'loading value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('onTap',
                type: 'Callback', description: 'Event callback for tap.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'action:hover'},
        ),
        'text_field': _schema(
          name: 'text_field',
          extendsName: 'field',
          summary: 'Alias for field:text.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:text'},
        ),
        'textarea': _schema(
          name: 'textarea',
          extendsName: 'field',
          summary: 'Alias for field:multiline.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:multiline'},
        ),
        'email_field': _schema(
          name: 'email_field',
          extendsName: 'field',
          summary: 'Alias for field:email.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:email'},
        ),
        'password_field': _schema(
          name: 'password_field',
          extendsName: 'field',
          summary: 'Alias for field:password.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:password'},
        ),
        'number_field': _schema(
          name: 'number_field',
          extendsName: 'field',
          summary: 'Alias for field:number.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:number'},
        ),
        'search_field': _schema(
          name: 'search_field',
          extendsName: 'field',
          summary: 'Alias for field:search.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:search'},
        ),
        'date_field': _schema(
          name: 'date_field',
          extendsName: 'field',
          summary: 'Alias for field:date.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:date'},
        ),
        'select_field': _schema(
          name: 'select_field',
          extendsName: 'field',
          summary: 'Alias for field:select.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:select'},
        ),
        'toggle': _schema(
          name: 'toggle',
          extendsName: 'field',
          summary: 'Alias for field:toggle.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:toggle'},
        ),
        'slider': _schema(
          name: 'slider',
          extendsName: 'field',
          summary: 'Alias for field:slider.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('label', type: 'String', description: 'label value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('disabled', type: 'bool', description: 'disabled value.'),
            _prop('readOnly', type: 'bool', description: 'readOnly value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'field:slider'},
        ),
        'image': _schema(
          name: 'image',
          extendsName: 'media',
          summary: 'Alias for media:image.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('src', type: 'String', description: 'src value.'),
            _prop('path', type: 'String', description: 'path value.'),
            _prop('fit', type: 'String', description: 'fit value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('poster', type: 'dynamic', description: 'poster value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'media:image'},
        ),
        'avatar': _schema(
          name: 'avatar',
          extendsName: 'media',
          summary: 'Alias for media:avatar.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('src', type: 'String', description: 'src value.'),
            _prop('path', type: 'String', description: 'path value.'),
            _prop('fit', type: 'String', description: 'fit value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('poster', type: 'dynamic', description: 'poster value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'media:avatar'},
        ),
        'video': _schema(
          name: 'video',
          extendsName: 'media',
          summary: 'Alias for media:video.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('src', type: 'String', description: 'src value.'),
            _prop('path', type: 'String', description: 'path value.'),
            _prop('fit', type: 'String', description: 'fit value.'),
            _prop('placeholder',
                type: 'String', description: 'placeholder value.'),
            _prop('poster', type: 'dynamic', description: 'poster value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'media:video'},
        ),
        'chart_alias': _schema(
          name: 'chart_alias',
          extendsName: 'chart',
          summary: 'Alias for the chart core.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('chartType', type: 'String', description: 'chartType value.'),
            _prop('data', type: 'List', description: 'data value.'),
            _prop('showGrid', type: 'bool', description: 'showGrid value.'),
            _prop('showAxes', type: 'bool', description: 'showAxes value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'chart'},
        ),
        'animation_alias': _schema(
          name: 'animation_alias',
          extendsName: 'animation',
          summary: 'Alias for the animation core.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('animationType',
                type: 'String', description: 'animationType value.'),
            _prop('durationMs', type: 'int', description: 'durationMs value.'),
            _prop('bind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'animation'},
        ),
        'dialog': _schema(
          name: 'dialog',
          extendsName: 'portal',
          summary: 'Alias for portal:dialog.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('trigger', type: 'dynamic', description: 'trigger value.'),
            _prop('content', type: 'dynamic', description: 'content value.'),
            _prop('triggerBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('align', type: 'String', description: 'align value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'portal:dialog'},
        ),
        'drawer': _schema(
          name: 'drawer',
          extendsName: 'portal',
          summary: 'Alias for portal:sheet.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('trigger', type: 'dynamic', description: 'trigger value.'),
            _prop('content', type: 'dynamic', description: 'content value.'),
            _prop('triggerBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('align', type: 'String', description: 'align value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'portal:sheet'},
        ),
        'sheet': _schema(
          name: 'sheet',
          extendsName: 'portal',
          summary: 'Alias for portal:sheet.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('trigger', type: 'dynamic', description: 'trigger value.'),
            _prop('content', type: 'dynamic', description: 'content value.'),
            _prop('triggerBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('align', type: 'String', description: 'align value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'portal:sheet'},
        ),
        'popover': _schema(
          name: 'popover',
          extendsName: 'portal',
          summary: 'Alias for portal:popover.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('trigger', type: 'dynamic', description: 'trigger value.'),
            _prop('content', type: 'dynamic', description: 'content value.'),
            _prop('triggerBind',
                type: 'Binding',
                description: 'Runtime binding key for lazy state lookup.'),
            _prop('align', type: 'String', description: 'align value.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'portal:popover'},
        ),
        'tabs': _schema(
          name: 'tabs',
          extendsName: 'control',
          summary: 'Alias for control:tabs.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('items', type: 'List', description: 'items value.'),
            _prop('selected', type: 'bool', description: 'selected value.'),
            _prop('onSelect',
                type: 'Callback', description: 'Event callback for select.'),
            _prop('onToggle',
                type: 'Callback', description: 'Event callback for toggle.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'control:tabs'},
        ),
        'segment': _schema(
          name: 'segment',
          extendsName: 'control',
          summary: 'Alias for control:tabs.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('items', type: 'List', description: 'items value.'),
            _prop('selected', type: 'bool', description: 'selected value.'),
            _prop('onSelect',
                type: 'Callback', description: 'Event callback for select.'),
            _prop('onToggle',
                type: 'Callback', description: 'Event callback for toggle.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'control:tabs'},
        ),
        'stepper': _schema(
          name: 'stepper',
          extendsName: 'control',
          summary: 'Alias for control:stepper.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('items', type: 'List', description: 'items value.'),
            _prop('selected', type: 'bool', description: 'selected value.'),
            _prop('onSelect',
                type: 'Callback', description: 'Event callback for select.'),
            _prop('onToggle',
                type: 'Callback', description: 'Event callback for toggle.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'control:stepper'},
        ),
        'accordion': _schema(
          name: 'accordion',
          extendsName: 'control',
          summary: 'Alias for control:accordion.',
          category: 'alias',
          props: <QLCorePropSpec>[
            _prop('items', type: 'List', description: 'items value.'),
            _prop('selected', type: 'bool', description: 'selected value.'),
            _prop('onSelect',
                type: 'Callback', description: 'Event callback for select.'),
            _prop('onToggle',
                type: 'Callback', description: 'Event callback for toggle.')
          ],
          metadata: const <String, dynamic>{'aliasOf': 'control:accordion'},
        ),
      };
}

QLCoreSchemaDescriptor _schema({
  required String name,
  String? extendsName,
  String summary = '',
  String category = 'core',
  List<QLCorePropSpec> props = const <QLCorePropSpec>[],
  List<QLCoreSlotSpec> slots = const <QLCoreSlotSpec>[],
  Map<String, dynamic> metadata = const <String, dynamic>{},
  bool lazy = true,
}) =>
    QLCoreSchemaDescriptor(
      name: name,
      extendsName: extendsName,
      summary: summary,
      category: category,
      props: props,
      slots: slots,
      metadata: metadata,
      lazy: lazy,
    );

QLCorePropSpec _prop(
  String name, {
  required String type,
  String? description,
  bool required = false,
  bool nullable = true,
  dynamic defaultValue,
  List<String> enumValues = const <String>[],
  Map<String, dynamic> extras = const <String, dynamic>{},
}) =>
    QLCorePropSpec(
      name: name,
      type: type,
      description: description,
      required: required,
      nullable: nullable,
      defaultValue: defaultValue,
      enumValues: enumValues,
      extras: extras,
    );

QLCoreSlotSpec _slot(
  String name, {
  String? description,
  bool required = false,
  Map<String, dynamic> extras = const <String, dynamic>{},
}) =>
    QLCoreSlotSpec(
      name: name,
      description: description,
      required: required,
      extras: extras,
    );
