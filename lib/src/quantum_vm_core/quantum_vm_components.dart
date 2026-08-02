/*
 * ============================================================================
 * File: quantum_vm_components.dart
 * 
 * Description:
 * Manages the definition, resolution, and instantiation of Quantum components. 
 * It extracts component definitions (props, hooks, state, ui) from blueprints 
 * and binds them to the Flutter rendering pipeline.
 * 
 * Key Components:
 * - _QLComponentDefinition: Represents a fully parsed component manifest.
 * - _AliasContext: A specialized QLContext for deriving default styling and intents.
 * - _buildComponent: The central dispatcher for instantiating component instances.
 * 
 * Dependencies/Relationships:
 * A part of quantum_vm.dart. Acts as the bridge between the compiled QLBlueprint 
 * AST and actual Flutter widget composition.
 * 
 * Notes:
 * Includes sophisticated logic for merging properties, resolving slots, and caching 
 * definitions to ensure smooth low-code component rendering.
 * ============================================================================
 */
part of 'quantum_vm.dart';

typedef QuantumComponentBuilder = Widget Function(
  BuildContext context,
  QLBlueprint node,
  QLDataStore store,
);

class _AliasContext extends QLContext {
  _AliasContext(QLContext base)
      : super(base.flutterContext, base.node, base.env, base.store);

  String get intent =>
      string('intent', fallback: string('tone', fallback: 'slate-900'));
  String get fill =>
      string('fill', fallback: string('variant', fallback: 'surface'));
  String get depth => string('depth', fallback: 'flat');
  String get edge => string('edge', fallback: 'none');
  String get shape => string('shape', fallback: 'rounded');
  String get scale => string('scale', fallback: string('size', fallback: 'md'));
}

extension QLContextSubtype on QLContext {
  @pragma('vm:prefer-inline')
  String resolvedSubType({String fallback = ''}) {
    final dynamic explicit = node.props['__subType'];
    final String explicitStr = explicit?.toString() ?? '';
    if (explicitStr.isNotEmpty) return explicitStr;

    final String nodeType = node.type.toString();
    if (nodeType.contains(':')) {
      final String suffix = nodeType.split(':').last;
      if (suffix.isNotEmpty) return suffix;
    }

    if (nodeType == 'row' ||
        nodeType == 'col' ||
        nodeType == 'wrap' ||
        nodeType == 'stack' ||
        nodeType == 'grid' ||
        nodeType == 'masonry') {
      return nodeType;
    }

    return fallback;
  }
}

final QLRuntimeCache<_QLComponentDefinition> _componentDefinitionCache =
    QLRuntimeCache<_QLComponentDefinition>(
  config: const QLRuntimeCacheConfig(
    maxEntries: 512,
    maxWeight: 8 * 1024 * 1024,
  ),
);

final Map<String, _QLComponentDefinition> _componentDefinitionsByName =
    <String, _QLComponentDefinition>{};

Map<String, dynamic>? _nativeComponentDescribe(String name) {
  final definition = _componentDefinitionsByName[name];
  if (definition == null) return null;
  return <String, dynamic>{
    'id': 'native_component:$name',
    'kind': 'native_component',
    'name': definition.name,
    'description': definition.description,
    'engine': 'QuantumVM',
    'tags': const ['native_component', 'native'],
    'params': definition.toMetadata()['paramSchema'],
    'metadata': definition.toMetadata(),
    'registeredAt': DateTime.now().toIso8601String(),
  };
}

Widget _buildComponent(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String kind = ctx.resolvedSubType(fallback: 'use');

  switch (kind) {
    case 'define':
      return _buildComponentDefine(ctx);
    case 'use':
    case 'instance':
    case 'render':
      return _buildComponentUse(ctx);
    case 'scoped':
      return _buildComponentScoped(ctx);
    case 'link':
      return _buildComponentLink(ctx);
    default:
      return _buildComponentUse(ctx);
  }
}

void _registerComponentAliases(QuantumVM vm) {}

Widget _buildComponentDefine(_AliasContext ctx) {
  final _QLComponentDefinition definition = _compileComponentDefinition(ctx);
  _registerComponentDefinition(definition);

  final bool preview = ctx.boolean('preview') || ctx.boolean('render');
  if (!preview) return const SizedBox.shrink();

  return _QLComponentRuntimeHost(
    definition: definition,
    sourceNode: ctx.node,
    sourceCtx: ctx,
    definitionOverride: definition,
    preview: true,
  );
}

Widget _buildComponentUse(_AliasContext ctx) {
  final String name = ctx.string('name').trim();
  final String typeName = name.isNotEmpty
      ? name
      : (ctx.node.props['component']?.toString().trim().isNotEmpty == true
          ? ctx.node.props['component'].toString().trim()
          : '');

  if (typeName.isEmpty) {
    final _QLComponentDefinition inline = _compileComponentDefinition(ctx);
    if (inline.name.startsWith('anonymous:')) {
      return _QLComponentRuntimeHost(
        definition: inline,
        sourceNode: ctx.node,
        sourceCtx: ctx,
        definitionOverride: inline,
      );
    }
    _registerComponentDefinition(inline);
    return _QLComponentRuntimeHost(
      definition: inline,
      sourceNode: ctx.node,
      sourceCtx: ctx,
      definitionOverride: inline,
    );
  }

  final _QLComponentDefinition? definition =
      _resolveComponentDefinition(typeName, ctx);
  if (definition == null) {
    final QuantumComponentBuilder? builtIn = null;
    if (builtIn != null) {
      return builtIn(ctx.flutterContext, ctx.node, ctx.store);
    }

    if (kDebugMode) {
      debugPrint('🚨 [QuantumVM] Missing component definition: $typeName');
    }
    return const SizedBox.shrink();
  }

  return _QLComponentRuntimeHost(
    definition: definition,
    sourceNode: ctx.node,
    sourceCtx: ctx,
  );
}

Widget _buildComponentScoped(_AliasContext ctx) {
  final _QLComponentDefinition inline = _compileComponentDefinition(ctx);
  _registerComponentDefinition(inline);
  return _QLComponentRuntimeHost(
    definition: inline,
    sourceNode: ctx.node,
    sourceCtx: ctx,
    definitionOverride: inline,
  );
}

Widget _buildComponentLink(_AliasContext ctx) {
  final _QLComponentDefinition inline = _compileComponentDefinition(ctx);
  _registerComponentDefinition(inline);
  return _QLComponentRuntimeHost(
    definition: inline,
    sourceNode: ctx.node,
    sourceCtx: ctx,
    definitionOverride: inline,
  );
}

void _registerComponentDefinition(_QLComponentDefinition definition) {
  _componentDefinitionsByName[definition.name] = definition;
  _componentDefinitionCache.put(definition.fingerprint, definition);
}

_QLComponentDefinition? _resolveComponentDefinition(
  String name,
  _AliasContext ctx,
) {
  final _QLComponentDefinition? cached = _componentDefinitionsByName[name];
  if (cached != null) return cached;

  final Map<String, dynamic> raw = _componentRawMap(ctx);
  if (raw.isEmpty) return _componentDefinitionsByName[name];
  final _QLComponentDefinition compiled = _compileDefinitionFromRaw(
    raw,
    debugPath: ctx.node.debugPath,
    fallbackName: name,
    sourceNode: ctx.node,
  );
  _componentDefinitionsByName[compiled.name] = compiled;
  return compiled;
}

_QLComponentDefinition _compileComponentDefinition(_AliasContext ctx) {
  final Map<String, dynamic> raw = _componentRawMap(ctx);
  final String fallbackName = ctx.string('name').trim().isNotEmpty
      ? ctx.string('name').trim()
      : (raw['name']?.toString().trim().isNotEmpty == true
          ? raw['name'].toString().trim()
          : 'anonymous:${ctx.node.debugPath}');
  return _compileDefinitionFromRaw(
    raw,
    debugPath: ctx.node.debugPath,
    fallbackName: fallbackName,
    sourceNode: ctx.node,
  );
}

Map<String, dynamic> _componentSchemaForValue(dynamic value) {
  if (value == null)
    return const <String, dynamic>{'type': 'dynamic', 'nullable': true};
  if (value is bool) return const <String, dynamic>{'type': 'bool'};
  if (value is int) return const <String, dynamic>{'type': 'int'};
  if (value is double) return const <String, dynamic>{'type': 'double'};
  if (value is String)
    return <String, dynamic>{'type': 'String', 'example': value};
  if (value is List) {
    return <String, dynamic>{
      'type': 'List<dynamic>',
      'items': value.isEmpty
          ? const <String, dynamic>{'type': 'dynamic'}
          : _componentSchemaForValue(value.first),
    };
  }
  if (value is Map) {
    return <String, dynamic>{
      'type': 'Map<String, dynamic>',
      'properties': {
        for (final entry in value.entries)
          entry.key.toString(): _componentSchemaForValue(entry.value),
      },
    };
  }
  return <String, dynamic>{'type': value.runtimeType.toString()};
}

Map<String, dynamic> _componentRawMap(_AliasContext ctx) {
  final Map<String, dynamic> raw = <String, dynamic>{};

  final dynamic embedded = ctx.node.props['definition'] ??
      ctx.node.props['component'] ??
      ctx.node.props['spec'] ??
      ctx.node.props['payload'];
  if (embedded is Map) raw.addAll(Map<String, dynamic>.from(embedded));

  // Direct properties are treated as shorthand definition fields.
  for (final entry in ctx.node.props.entries) {
    final String key = entry.key.toString();
    if (key == '__subType' ||
        key == 'definition' ||
        key == 'component' ||
        key == 'spec' ||
        key == 'payload') {
      continue;
    }
    raw.putIfAbsent(key, () => entry.value);
  }

  raw.putIfAbsent('name', () => ctx.string('name'));
  raw.putIfAbsent('description', () => ctx.string('description'));
  raw.putIfAbsent('props', () => ctx.node.props['props']);
  raw.putIfAbsent('state', () => ctx.node.props['state']);
  raw.putIfAbsent('computed', () => ctx.node.props['computed']);
  raw.putIfAbsent('hooks', () => ctx.node.props['hooks']);
  raw.putIfAbsent('links', () => ctx.node.props['links']);
  raw.putIfAbsent('variants', () => ctx.node.props['variants']);
  raw.putIfAbsent('animations', () => ctx.node.props['animations']);
  raw.putIfAbsent('ui', () => ctx.node.props['ui']);
  raw.putIfAbsent('slots', () => ctx.node.props['slots']);

  if (raw['ui'] == null && ctx.node.children.isNotEmpty) {
    if (ctx.node.children.length == 1) {
      raw['ui'] = ctx.node.children.first.toJson();
    } else {
      raw['ui'] = {
        'type': 'box:col',
        'children': ctx.node.children.map((c) => c.toJson()).toList(
              growable: false,
            ),
      };
    }
  }

  if (raw['slots'] == null && ctx.node.slots.isNotEmpty) {
    raw['slots'] = ctx.node.slots.map((k, v) => MapEntry(k, v.toJson()));
  }

  return raw;
}

_QLComponentDefinition _compileDefinitionFromRaw(
  Map<String, dynamic> raw, {
  required String debugPath,
  required String fallbackName,
  required QLBlueprint sourceNode,
}) {
  final Map<String, dynamic> normalized = Map<String, dynamic>.from(raw);
  normalized.putIfAbsent('name', () => fallbackName);

  final String name = normalized['name']?.toString().trim().isNotEmpty == true
      ? normalized['name'].toString().trim()
      : fallbackName;
  final String description = normalized['description']?.toString() ?? '';

  final Map<String, dynamic> props = _asMap(normalized['props']);
  final Map<String, dynamic> state = _asMap(normalized['state']);
  final Map<String, dynamic> links = _asMap(normalized['links']);
  final Map<String, dynamic> variants = _asMap(normalized['variants']);
  final Map<String, dynamic> animations = _asMap(normalized['animations']);
  final Map<String, dynamic> metadata = _asMap(normalized['metadata']);

  // Extract missing fields here
  final Map<String, dynamic> runtime = _qlDeepMergeMaps(<dynamic>[
    _asMap(normalized['runtime']),
    _asMap(normalized['omni']),
    _asMap(metadata['runtime']),
    _asMap(metadata['omni']),
    _asMap(metadata['media']),
    _asMap(metadata['stream']),
    _asMap(metadata['cache']),
    _asMap(metadata['batch']),
    _asMap(metadata['presentation']),
    _asMap(metadata['resource']),
    _asMap(metadata['pagination']),
    _asMap(metadata['network']),
    _asMap(metadata['select']),
  ]);
  final Map<String, dynamic> policy = _qlDeepMergeMaps(<dynamic>[
    _asMap(normalized['policy']),
    _asMap(normalized['policies']),
    _asMap(metadata['policy']),
    _asMap(metadata['policies']),
    _asMap(metadata['guard']),
    _asMap(metadata['permissions']),
    _asMap(metadata['permission']),
  ]);
  final List<String> capabilities = _qlUniqueStrings(<dynamic>[
    ..._qlStringList(normalized['capabilities']),
    ..._qlStringList(runtime['capabilities']),
    ..._qlStringList(runtime['features']),
    ..._qlStringList(policy['capabilities']),
    ..._qlStringList(policy['features']),
    ..._qlStringList(metadata['capabilities']),
    ..._qlStringList(metadata['features']),
    if (_asMap(runtime['media']).isNotEmpty) 'media',
    if (_asMap(runtime['stream']).isNotEmpty) 'stream',
    if (_asMap(runtime['cache']).isNotEmpty) 'cache',
    if (_asMap(runtime['batch']).isNotEmpty) 'batch',
    if (_asMap(runtime['presentation']).isNotEmpty) 'presentation',
  ]);

  final Map<String, _QLComponentComputedSpec> computed =
      _parseComputed(normalized['computed']);
  final _QLComponentHookBundle hooks = _parseHooks(normalized['hooks']);

  final QLBlueprint ui = _resolveComponentUi(
    normalized['ui'],
    debugPath: '$debugPath.ui',
    fallbackNode: sourceNode,
    children: sourceNode.children,
  );

  final Map<String, QLBlueprint> slots = <String, QLBlueprint>{};
  final Map<String, dynamic> rawSlots = _asMap(normalized['slots']);
  for (final entry in rawSlots.entries) {
    slots[entry.key] = _blueprintFromDynamic(
      entry.value,
      path: '$debugPath.slots[${entry.key}]',
      fallbackType: 'box',
    );
  }
  for (final entry in sourceNode.slots.entries) {
    slots[entry.key] = entry.value;
  }

  final int fingerprint = QLStableHasher.of(<String, dynamic>{
    'name': name,
    'description': description,
    'props': props,
    'state': state,
    'links': links,
    'variants': variants,
    'animations': animations,
    'runtime': runtime,
    'policy': policy,
    'capabilities': capabilities,
    'computed': computed.map((k, v) => MapEntry(k, v.toJson())),
    'hooks': hooks.toJson(),
    'ui': ui.toJson(),
    'slots': slots.map((k, v) => MapEntry(k, v.toJson())),
    'metadata': metadata,
  });

  return _QLComponentDefinition(
    name: name,
    description: description,
    props: props,
    state: state,
    links: links,
    variants: variants,
    animations: animations,
    metadata: metadata,
    runtime: runtime, // <-- Added
    policy: policy, // <-- Added
    capabilities: capabilities, // <-- Added
    computed: computed,
    hooks: hooks,
    ui: ui,
    slots: slots,
    fingerprint: fingerprint,
  );
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic raw) {
  if (raw is List) return List<dynamic>.from(raw);
  if (raw == null) return <dynamic>[];
  return <dynamic>[raw];
}

_QLComponentComputedSpec _parseComputedSpec(
  String key,
  dynamic raw,
) {
  if (raw is Map) {
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    return _QLComponentComputedSpec(
      key: key,
      deps: _normalizeDependencies(map['deps'] ?? map['dependencies']),
      op: map['op']?.toString().trim().isNotEmpty == true
          ? map['op'].toString().trim()
          : 'copy',
      args: _asList(map['args']).cast<dynamic>(),
      fallback: map.containsKey('fallback') ? map['fallback'] : null,
      immediate: map['immediate'] == true,
    );
  }

  if (raw is List) {
    return _QLComponentComputedSpec(
      key: key,
      deps: raw.map((e) => e.toString()).toList(growable: false),
      op: 'copy',
      args: const <dynamic>[],
      fallback: null,
      immediate: false,
    );
  }

  return _QLComponentComputedSpec(
    key: key,
    deps: const <String>[],
    op: 'constant',
    args: <dynamic>[raw],
    fallback: raw,
    immediate: false,
  );
}

Map<String, _QLComponentComputedSpec> _parseComputed(dynamic raw) {
  final Map<String, _QLComponentComputedSpec> out =
      <String, _QLComponentComputedSpec>{};
  if (raw is Map) {
    for (final entry in raw.entries) {
      out[entry.key.toString()] =
          _parseComputedSpec(entry.key.toString(), entry.value);
    }
  }
  return out;
}

List<String> _normalizeDependencies(dynamic raw) {
  final List<dynamic> deps = _asList(raw);
  return deps
      .map((e) => e.toString().trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);
}

_QLComponentHookBundle _parseHooks(dynamic raw) {
  if (raw is! Map) {
    return const _QLComponentHookBundle();
  }

  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  return _QLComponentHookBundle(
    mountActions: _parseActionList(
      map['mount'] ?? map['onMount'] ?? map['init'],
    ),
    unmountActions: _parseActionList(
      map['unmount'] ?? map['onUnmount'] ?? map['dispose'],
    ),
    effects: _parseEffects(map['effect'] ?? map['effects'] ?? map['watch']),
    bridge: _parseActionList(map['bridge']),
    guard: _parseActionList(map['guard']),
    memo: _parseActionList(map['memo']),
    scope: _asMap(map['scope']),
    controller: _parseActionList(map['controller'] ?? map['controllers']),
  );
}

List<dynamic> _parseActionList(dynamic raw) {
  if (raw == null) return const <dynamic>[];
  if (raw is List) return List<dynamic>.from(raw);
  if (raw is Map && raw.containsKey('actions')) {
    return _asList(raw['actions']);
  }
  return <dynamic>[raw];
}

List<_QLComponentEffectSpec> _parseEffects(dynamic raw) {
  final List<_QLComponentEffectSpec> out = <_QLComponentEffectSpec>[];
  if (raw == null) return out;
  if (raw is List) {
    for (final item in raw) {
      final spec = _parseSingleEffect(item);
      if (spec != null) out.add(spec);
    }
    return out;
  }
  final spec = _parseSingleEffect(raw);
  if (spec != null) out.add(spec);
  return out;
}

_QLComponentEffectSpec? _parseSingleEffect(dynamic raw) {
  if (raw is! Map) return null;
  final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
  return _QLComponentEffectSpec(
    deps: _normalizeDependencies(map['deps'] ?? map['dependencies']),
    actions: _parseActionList(map['actions'] ?? map['then']),
    debounceMs: map['debounceMs'] is int
        ? map['debounceMs'] as int
        : int.tryParse(map['debounceMs']?.toString() ?? '') ?? 0,
    immediate: map['immediate'] == true,
  );
}

QLBlueprint _blueprintFromDynamic(
  dynamic raw, {
  required String path,
  required String fallbackType,
}) {
  if (raw is QLBlueprint) return raw;
  if (raw is Map) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    json.putIfAbsent('type', () => fallbackType);
    return QLBlueprint.fromJson(json, path: path);
  }
  return QLBlueprint(
    type: fallbackType,
    props: <String, dynamic>{'value': raw},
    children: const <QLBlueprint>[],
    debugPath: path,
  );
}

QLBlueprint _resolveComponentUi(
  dynamic raw, {
  required String debugPath,
  required QLBlueprint fallbackNode,
  required List<QLBlueprint> children,
}) {
  if (raw is QLBlueprint) return raw;
  if (raw is Map) {
    final Map<String, dynamic> json = Map<String, dynamic>.from(raw);
    json.putIfAbsent('type', () => 'box:col');
    return QLBlueprint.fromJson(json, path: debugPath);
  }
  if (raw is List) {
    return QLBlueprint(
      type: 'box:col',
      props: const <String, dynamic>{},
      children: raw
          .whereType<Map>()
          .toList(growable: false)
          .asMap()
          .entries
          .map((e) => QLBlueprint.fromJson(
                Map<String, dynamic>.from(e.value),
                path: '$debugPath[${e.key}]',
              ))
          .toList(growable: false),
      debugPath: debugPath,
    );
  }
  if (children.isNotEmpty) {
    if (children.length == 1) return children.first;
    return QLBlueprint(
      type: 'box:col',
      props: const <String, dynamic>{},
      children: List<QLBlueprint>.from(children),
      debugPath: debugPath,
    );
  }
  return QLBlueprint(
    type: fallbackNode.type,
    props: const <String, dynamic>{},
    children: const <QLBlueprint>[],
    debugPath: debugPath,
  );
}

final QLRuntimeCache<Map<String, dynamic>> _componentRuntimeProfileCache =
    QLRuntimeCache<Map<String, dynamic>>(
  config: const QLRuntimeCacheConfig(
    maxEntries: 256,
    maxWeight: 4 * 1024 * 1024,
  ),
);

class _QLBlueprintRuntimeRule {
  final String name;
  final Map<String, dynamic> match;
  final Map<String, dynamic> apply;

  const _QLBlueprintRuntimeRule({
    required this.name,
    required this.match,
    required this.apply,
  });
}

Map<String, dynamic> _qlCloneMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<String> _qlStringList(dynamic raw) {
  if (raw == null) return <String>[];
  if (raw is List) {
    final out = <String>[];
    for (final item in raw) {
      final value = item?.toString().trim() ?? '';
      if (value.isNotEmpty) out.add(value);
    }
    return out;
  }
  final String value = raw.toString().trim();
  if (value.isEmpty) return <String>[];
  if (value.contains(',')) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  return <String>[value];
}

List<String> _qlUniqueStrings(Iterable<dynamic> values) {
  final seen = <String>{};
  final out = <String>[];
  for (final value in values) {
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty || seen.contains(text)) continue;
    seen.add(text);
    out.add(text);
  }
  return out;
}

Map<String, dynamic> _qlDeepMergeMaps(Iterable<dynamic> maps) {
  final out = <String, dynamic>{};
  for (final raw in maps) {
    if (raw is! Map) continue;
    _qlDeepMergeInto(out, Map<String, dynamic>.from(raw));
  }
  return out;
}

void _qlDeepMergeInto(
    Map<String, dynamic> target, Map<String, dynamic> source) {
  for (final entry in source.entries) {
    final dynamic existing = target[entry.key];
    final dynamic next = entry.value;
    if (existing is Map && next is Map) {
      final merged = Map<String, dynamic>.from(existing);
      _qlDeepMergeInto(merged, Map<String, dynamic>.from(next));
      target[entry.key] = merged;
    } else if (existing is List && next is List) {
      target[entry.key] = <dynamic>[...existing, ...next];
    } else {
      target[entry.key] = next;
    }
  }
}

Map<String, dynamic> _qlSelectPathTree(List<String> parts) {
  if (parts.isEmpty) return <String, dynamic>{};
  final Map<String, dynamic> root = <String, dynamic>{};
  Map<String, dynamic> cursor = root;
  for (int i = 0; i < parts.length; i++) {
    final String part = parts[i].trim();
    if (part.isEmpty) continue;
    if (i == parts.length - 1) {
      cursor[part] = true;
    } else {
      final next = <String, dynamic>{};
      cursor[part] = next;
      cursor = next;
    }
  }
  return root;
}

Object _qlNormalizeSelect(dynamic raw) {
  if (raw == null) return <String, dynamic>{};
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final String value = raw.trim();
    if (value.isEmpty) return <String, dynamic>{};
    if (value == '*') return <String, dynamic>{'*': true};
    return _qlSelectPathTree(value.split('.'));
  }
  if (raw is List) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final item in raw) {
      final Object normalized = _qlNormalizeSelect(item);
      if (normalized is bool) {
        if (normalized) out['*'] = true;
        continue;
      }
      if (normalized is Map) {
        _qlDeepMergeInto(out, Map<String, dynamic>.from(normalized));
      }
    }
    return out;
  }
  if (raw is Map) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final entry in raw.entries) {
      final String key = entry.key.toString().trim();
      if (key.isEmpty) continue;
      final dynamic value = entry.value;
      if (value == null) {
        out[key] = true;
        continue;
      }
      final Object normalized = _qlNormalizeSelect(value);
      if (normalized is bool || normalized is Map) {
        out[key] = normalized;
      } else {
        out[key] = true;
      }
    }
    return out;
  }
  return <String, dynamic>{'*': true};
}

List<String> _qlFlattenSelectPaths(dynamic raw, {String prefix = ''}) {
  final Object normalized = _qlNormalizeSelect(raw);
  if (normalized is bool) {
    if (!normalized) return const <String>[];
    return <String>[prefix.isEmpty ? '*' : prefix];
  }
  if (normalized is! Map) return const <String>[];
  if (normalized['*'] == true) {
    return <String>[prefix.isEmpty ? '*' : '$prefix.*'];
  }

  final List<String> out = <String>[];
  for (final entry in normalized.entries) {
    final String key = entry.key.toString();
    if (key == '*') {
      out.add(prefix.isEmpty ? '*' : '$prefix.*');
      continue;
    }
    final String nextPrefix = prefix.isEmpty ? key : '$prefix.$key';
    final dynamic value = entry.value;
    if (value == true) {
      out.add(nextPrefix);
    } else {
      out.addAll(_qlFlattenSelectPaths(value, prefix: nextPrefix));
    }
  }
  return out;
}

Object? _qlProjectBySelectValue(dynamic value, dynamic select) {
  final Object normalized = _qlNormalizeSelect(select);
  if (normalized is bool) {
    return normalized ? value : null;
  }
  if (normalized is! Map) return value;
  if (normalized['*'] == true) return value;

  if (value is Map) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final entry in normalized.entries) {
      final String key = entry.key.toString();
      if (key == '*') {
        out.addAll(Map<String, dynamic>.from(value));
        continue;
      }
      if (!value.containsKey(key)) continue;
      final Object? projected =
          _qlProjectBySelectValue(value[key], entry.value);
      if (projected != null) {
        out[key] = projected;
      } else if (entry.value is bool && entry.value == true) {
        out[key] = value[key];
      }
    }
    return out;
  }

  if (value is List) {
    return value.map((item) {
      if (item is Map) {
        return _qlProjectBySelectValue(item, normalized);
      }
      return item;
    }).toList(growable: false);
  }

  return value;
}

Map<String, dynamic> _qlProjectBySelectMap(
  Map<String, dynamic> source,
  dynamic select,
) {
  final Object normalized = _qlNormalizeSelect(select);
  if (normalized is bool) {
    return normalized ? Map<String, dynamic>.from(source) : <String, dynamic>{};
  }
  if (normalized is! Map) return Map<String, dynamic>.from(source);
  if (normalized['*'] == true) return Map<String, dynamic>.from(source);

  final Map<String, dynamic> out = <String, dynamic>{};
  for (final entry in normalized.entries) {
    final String key = entry.key.toString();
    if (key == '*') {
      out.addAll(source);
      continue;
    }
    if (!source.containsKey(key)) continue;
    final Object? projected = _qlProjectBySelectValue(source[key], entry.value);
    if (projected != null) {
      out[key] = projected;
    } else if (entry.value is bool && entry.value == true) {
      out[key] = source[key];
    }
  }
  return out;
}

bool _qlStringMatches(dynamic expected, String actual) {
  if (expected == null) return true;
  if (expected is List) {
    for (final item in expected) {
      if (_qlStringMatches(item, actual)) return true;
    }
    return false;
  }
  final String text = expected.toString().trim();
  if (text.isEmpty || text == '*') return true;
  if (text.startsWith('!')) return actual != text.substring(1);
  return actual == text;
}

bool _qlValueMatches(dynamic expected, dynamic actual) {
  if (expected == null) return true;
  if (expected is bool) return expected == actual;
  if (expected is num && actual is num) return expected == actual;
  if (expected is String && actual is String)
    return _qlStringMatches(expected, actual);
  if (expected is List) {
    if (actual is List) {
      return expected.any((e) => actual.any((a) => _qlValueMatches(e, a)));
    }
    return expected.any((e) => _qlValueMatches(e, actual));
  }
  if (expected is Map && actual is Map) {
    final Map<String, dynamic> expectedMap =
        Map<String, dynamic>.from(expected);
    final Map<String, dynamic> actualMap = Map<String, dynamic>.from(actual);
    for (final entry in expectedMap.entries) {
      if (!actualMap.containsKey(entry.key)) return false;
      if (!_qlValueMatches(entry.value, actualMap[entry.key])) return false;
    }
    return true;
  }
  return expected.toString() == actual?.toString();
}

List<_QLBlueprintRuntimeRule> _qlParseBlueprintRules(dynamic raw,
    {String prefix = 'rule'}) {
  final List<_QLBlueprintRuntimeRule> out = <_QLBlueprintRuntimeRule>[];
  if (raw == null) return out;
  if (raw is List) {
    for (int i = 0; i < raw.length; i++) {
      final dynamic item = raw[i];
      if (item is Map) {
        out.add(_qlRuleFromMap(Map<String, dynamic>.from(item), '$prefix[$i]'));
      }
    }
    return out;
  }
  if (raw is Map) {
    if (raw.containsKey('rules') || raw.containsKey('nodeRules')) {
      out.addAll(_qlParseBlueprintRules(
        raw['rules'] ?? raw['nodeRules'],
        prefix: prefix,
      ));
      return out;
    }
    out.add(_qlRuleFromMap(Map<String, dynamic>.from(raw), prefix));
  }
  return out;
}

_QLBlueprintRuntimeRule _qlRuleFromMap(
  Map<String, dynamic> raw,
  String fallbackName,
) {
  final Map<String, dynamic> match = _qlCloneMap(
    raw['match'] ?? raw['when'] ?? raw['if'] ?? raw['where'],
  );
  final Map<String, dynamic> apply = _qlCloneMap(
    raw['apply'] ?? raw['then'] ?? raw['set'] ?? raw['do'],
  );

  final Map<String, dynamic> generatedApply = <String, dynamic>{};
  if (apply.isNotEmpty) {
    generatedApply.addAll(apply);
  } else {
    for (final key in <String>[
      'props',
      'style',
      'type',
      'wrap',
      'wrapProps',
      'wrapStyle',
      'slots',
      'children',
      'replaceChildren',
      'appendChildren',
      'prependChildren',
      'select',
      'cache',
      'media',
      'stream',
      'batch',
      'presentation',
      'resource',
      'runtime',
      'policy',
      'permissions',
      'guard',
      'override',
      'mergeProps',
      'flags',
    ]) {
      if (raw.containsKey(key)) {
        generatedApply[key] = raw[key];
      }
    }
  }

  final Map<String, dynamic> generatedMatch = match.isNotEmpty
      ? match
      : <String, dynamic>{
          for (final key in <String>[
            'type',
            'types',
            'subType',
            'subTypes',
            'path',
            'pathPrefix',
            'pathContains',
            'feature',
            'schema',
            'operation',
            'resource',
            'pattern',
            'props',
            'anyProps',
            'allProps',
            'hasChildren',
            'minChildren',
            'maxChildren',
          ])
            if (raw.containsKey(key)) key: raw[key],
        };

  return _QLBlueprintRuntimeRule(
    name: raw['name']?.toString().trim().isNotEmpty == true
        ? raw['name'].toString().trim()
        : fallbackName,
    match: generatedMatch,
    apply: generatedApply,
  );
}

List<_QLBlueprintRuntimeRule> _qlCollectBlueprintRules(
  Map<String, dynamic> runtime,
  Map<String, dynamic> policy,
) {
  final List<_QLBlueprintRuntimeRule> rules = <_QLBlueprintRuntimeRule>[];

  final Map<String, dynamic> runtimeDefaults = _qlCloneMap(runtime['defaults']);
  if (runtimeDefaults.isNotEmpty) {
    rules.add(
      _QLBlueprintRuntimeRule(
        name: 'runtime.defaults',
        match: const <String, dynamic>{},
        apply: <String, dynamic>{'props': runtimeDefaults},
      ),
    );
  }

  final Map<String, dynamic> policyDefaults = _qlCloneMap(policy['defaults']);
  if (policyDefaults.isNotEmpty) {
    rules.add(
      _QLBlueprintRuntimeRule(
        name: 'policy.defaults',
        match: const <String, dynamic>{},
        apply: <String, dynamic>{'props': policyDefaults},
      ),
    );
  }

  rules.addAll(
      _qlParseBlueprintRules(runtime['rules'], prefix: 'runtime.rules'));
  rules.addAll(_qlParseBlueprintRules(runtime['nodeRules'],
      prefix: 'runtime.nodeRules'));
  rules.addAll(_qlParseBlueprintRules(policy['rules'], prefix: 'policy.rules'));
  rules.addAll(
      _qlParseBlueprintRules(policy['nodeRules'], prefix: 'policy.nodeRules'));

  final Map<String, dynamic> runtimeOverrides =
      _qlCloneMap(runtime['overrides']);
  if (runtimeOverrides.isNotEmpty) {
    rules.add(
      _QLBlueprintRuntimeRule(
        name: 'runtime.overrides',
        match: const <String, dynamic>{},
        apply: <String, dynamic>{'props': runtimeOverrides},
      ),
    );
  }

  final Map<String, dynamic> policyOverrides = _qlCloneMap(policy['overrides']);
  if (policyOverrides.isNotEmpty) {
    rules.add(
      _QLBlueprintRuntimeRule(
        name: 'policy.overrides',
        match: const <String, dynamic>{},
        apply: <String, dynamic>{'props': policyOverrides},
      ),
    );
  }

  return rules;
}

bool _qlBlueprintRuleMatches(
  QLBlueprint node,
  String path,
  _QLBlueprintRuntimeRule rule,
  Map<String, dynamic> env,
) {
  final Map<String, dynamic> match = rule.match;
  if (match.isEmpty) return true;

  final String type = node.type;
  final String subType = type.contains(':') ? type.split(':').last : type;
  final Map<String, dynamic> props = node.props;
  final Map<String, dynamic> component = _qlCloneMap(env['component']);
  final Map<String, dynamic> runtime = _qlCloneMap(env['componentRuntime']);
  final Map<String, dynamic> presentation =
      _qlCloneMap(env['componentPresentation']);
  final Map<String, dynamic> media = _qlCloneMap(env['componentMedia']);
  final Map<String, dynamic> stream = _qlCloneMap(env['componentStream']);

  if (match.containsKey('type') && !_qlStringMatches(match['type'], type))
    return false;
  if (match.containsKey('types') && !_qlStringMatches(match['types'], type))
    return false;
  if (match.containsKey('subType') &&
      !_qlStringMatches(match['subType'], subType)) return false;
  if (match.containsKey('subTypes') &&
      !_qlStringMatches(match['subTypes'], subType)) return false;

  final String? feature =
      runtime['feature']?.toString() ?? component['feature']?.toString();
  final String? schema =
      runtime['schema']?.toString() ?? component['schema']?.toString();
  final String? operation =
      runtime['operation']?.toString() ?? component['operation']?.toString();
  final String? resource = runtime['resource']?.toString() ??
      component['resource']?.toString() ??
      component['name']?.toString();
  final String? pattern = presentation['pattern']?.toString() ??
      runtime['pattern']?.toString() ??
      media['pattern']?.toString() ??
      stream['pattern']?.toString();

  if (match.containsKey('feature') &&
      !_qlStringMatches(match['feature'], feature ?? '')) return false;
  if (match.containsKey('schema') &&
      !_qlStringMatches(match['schema'], schema ?? '')) return false;
  if (match.containsKey('operation') &&
      !_qlStringMatches(match['operation'], operation ?? '')) return false;
  if (match.containsKey('resource') &&
      !_qlStringMatches(match['resource'], resource ?? '')) return false;
  if (match.containsKey('pattern') &&
      !_qlStringMatches(match['pattern'], pattern ?? '')) return false;

  if (match.containsKey('path') && !_qlStringMatches(match['path'], path))
    return false;
  if (match.containsKey('pathPrefix')) {
    final String prefix = match['pathPrefix']?.toString() ?? '';
    if (prefix.isNotEmpty && !path.startsWith(prefix)) return false;
  }
  if (match.containsKey('pathContains')) {
    final String needle = match['pathContains']?.toString() ?? '';
    if (needle.isNotEmpty && !path.contains(needle)) return false;
  }

  if (match.containsKey('hasChildren')) {
    final bool expected = match['hasChildren'] == true;
    if ((node.children.isNotEmpty) != expected) return false;
  }
  if (match.containsKey('minChildren')) {
    final int minChildren =
        int.tryParse(match['minChildren']?.toString() ?? '') ?? 0;
    if (node.children.length < minChildren) return false;
  }
  if (match.containsKey('maxChildren')) {
    final int maxChildren =
        int.tryParse(match['maxChildren']?.toString() ?? '') ?? 0;
    if (node.children.length > maxChildren) return false;
  }

  if (match.containsKey('props')) {
    final Map<String, dynamic> expected = _qlCloneMap(match['props']);
    for (final entry in expected.entries) {
      if (!props.containsKey(entry.key)) return false;
      if (!_qlValueMatches(entry.value, props[entry.key])) return false;
    }
  }
  if (match.containsKey('anyProps')) {
    final List<String> keys = _qlStringList(match['anyProps']);
    if (keys.isNotEmpty && !keys.any(props.containsKey)) return false;
  }
  if (match.containsKey('allProps')) {
    final List<String> keys = _qlStringList(match['allProps']);
    if (keys.isNotEmpty && !keys.every(props.containsKey)) return false;
  }

  return true;
}

QLBlueprint _qlApplyBlueprintRule(
  QLBlueprint node,
  _QLBlueprintRuntimeRule rule,
  Map<String, dynamic> env,
) {
  final Map<String, dynamic> apply = rule.apply;
  if (apply.isEmpty) return node;

  final Map<String, dynamic> props = Map<String, dynamic>.from(node.props);
  final dynamic mergedProps =
      apply['props'] ?? apply['set'] ?? apply['mergeProps'];
  if (mergedProps is Map) {
    _qlDeepMergeInto(props, Map<String, dynamic>.from(mergedProps));
  }
  final dynamic overrideProps = apply['override'];
  if (overrideProps is Map) {
    props.addAll(Map<String, dynamic>.from(overrideProps));
  }
  for (final key in <String>[
    'select',
    'cache',
    'media',
    'stream',
    'batch',
    'presentation',
    'resource',
    'runtime',
    'policy',
    'permissions',
    'guard',
  ]) {
    if (apply.containsKey(key)) {
      props[key] = apply[key];
    }
  }
  final dynamic flags = apply['flags'];
  if (flags is Map) {
    _qlDeepMergeInto(props, Map<String, dynamic>.from(flags));
  }

  final String type = apply['type']?.toString().trim().isNotEmpty == true
      ? apply['type'].toString().trim()
      : node.type;
  final String? style =
      apply.containsKey('style') ? apply['style']?.toString() : node.style;

  final Map<String, QLBlueprint> slots =
      Map<String, QLBlueprint>.from(node.slots);
  final dynamic slotRaw = apply['slots'];
  if (slotRaw is Map) {
    for (final entry in slotRaw.entries) {
      slots[entry.key.toString()] = _blueprintFromDynamic(
        entry.value,
        path: '${node.debugPath}.rules[${rule.name}].slots[${entry.key}]',
        fallbackType: 'box',
      );
    }
  }

  List<QLBlueprint> children = List<QLBlueprint>.from(node.children);
  final dynamic replaceChildren = apply['children'];
  if (replaceChildren is List && apply['replaceChildren'] == true) {
    children = replaceChildren
        .asMap()
        .entries
        .map((e) => _blueprintFromDynamic(
              e.value,
              path: '${node.debugPath}.rules[${rule.name}].children[${e.key}]',
              fallbackType: 'box',
            ))
        .toList(growable: false);
  } else {
    final dynamic prependChildren = apply['prependChildren'];
    if (prependChildren is List && prependChildren.isNotEmpty) {
      final resolved = prependChildren
          .asMap()
          .entries
          .map((e) => _blueprintFromDynamic(
                e.value,
                path: '${node.debugPath}.rules[${rule.name}].prepend[${e.key}]',
                fallbackType: 'box',
              ))
          .toList(growable: false);
      children = <QLBlueprint>[...resolved, ...children];
    }
    final dynamic appendChildren = apply['appendChildren'];
    if (appendChildren is List && appendChildren.isNotEmpty) {
      final resolved = appendChildren
          .asMap()
          .entries
          .map((e) => _blueprintFromDynamic(
                e.value,
                path: '${node.debugPath}.rules[${rule.name}].append[${e.key}]',
                fallbackType: 'box',
              ))
          .toList(growable: false);
      children = <QLBlueprint>[...children, ...resolved];
    }
  }

  QLBlueprint current = QLBlueprint(
    type: type,
    props: props,
    style: style,
    children: children,
    slots: slots,
    debugPath: node.debugPath,
  );

  final dynamic wrap = apply['wrap'] ?? apply['wrapper'];
  if (wrap != null) {
    final String wrapType = wrap is Map
        ? (wrap['type']?.toString().trim().isNotEmpty == true
            ? wrap['type'].toString().trim()
            : 'box')
        : wrap.toString().trim();
    final Map<String, dynamic> wrapProps = wrap is Map
        ? _qlCloneMap(wrap['props'] ?? wrap['wrapProps'])
        : _qlCloneMap(apply['wrapProps'] ?? apply['wrapperProps']);
    final String? wrapStyle = wrap is Map
        ? wrap['style']?.toString()
        : apply['wrapStyle']?.toString() ?? apply['wrapperStyle']?.toString();
    current = QLBlueprint(
      type: wrapType.isEmpty ? 'box' : wrapType,
      props: wrapProps,
      style: wrapStyle,
      children: <QLBlueprint>[current],
      debugPath: '${node.debugPath}.rules[${rule.name}].wrap',
    );
  }

  return current;
}

QLBlueprint _qlApplyBlueprintRules(
  QLBlueprint node,
  List<_QLBlueprintRuntimeRule> rules,
  Map<String, dynamic> env,
) {
  QLBlueprint current = QLBlueprint(
    type: node.type,
    props: Map<String, dynamic>.from(node.props),
    style: node.style,
    children: node.children
        .map((child) => _qlApplyBlueprintRules(child, rules, env))
        .toList(growable: false),
    slots: node.slots.map(
      (k, v) => MapEntry(k, _qlApplyBlueprintRules(v, rules, env)),
    ),
    debugPath: node.debugPath,
  );

  for (final rule in rules) {
    if (_qlBlueprintRuleMatches(current, current.debugPath, rule, env)) {
      current = _qlApplyBlueprintRule(current, rule, env);
    }
  }
  return current;
}

Map<String, dynamic> _buildComponentRuntimeProfile(
  _QLComponentDefinition definition,
  QLBlueprint sourceNode,
  _AliasContext sourceCtx,
) {
  final int signature = QLStableHasher.of(<String, dynamic>{
    'fingerprint': definition.fingerprint,
    'source': sourceNode.toJson(),
    'variant': sourceCtx.string('variant'),
    'runtime': definition.runtime,
    'policy': definition.policy,
    'capabilities': definition.capabilities,
  });

  return _componentRuntimeProfileCache.getOrPut(signature, () {
    final Map<String, dynamic> nodeRuntime = _qlDeepMergeMaps(<dynamic>[
      definition.runtime,
      _qlCloneMap(sourceNode.props['runtime']),
      _qlCloneMap(sourceNode.props['omni']),
      _qlCloneMap(sourceNode.props['capabilities']),
    ]);
    final Map<String, dynamic> nodePolicy = _qlDeepMergeMaps(<dynamic>[
      definition.policy,
      _qlCloneMap(sourceNode.props['policy']),
      _qlCloneMap(sourceNode.props['policies']),
      _qlCloneMap(sourceNode.props['guard']),
      _qlCloneMap(sourceNode.props['permissions']),
    ]);

    final Map<String, dynamic> media = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['media'],
      nodeRuntime['media'],
      sourceNode.props['media'],
      definition.metadata['media'],
    ]);
    final Map<String, dynamic> stream = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['stream'],
      nodeRuntime['stream'],
      sourceNode.props['stream'],
      definition.metadata['stream'],
    ]);
    final Map<String, dynamic> cache = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['cache'],
      nodeRuntime['cache'],
      sourceNode.props['cache'],
      nodePolicy['cache'],
      definition.metadata['cache'],
    ]);
    final Map<String, dynamic> batch = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['batch'],
      nodeRuntime['batch'],
      sourceNode.props['batch'],
      definition.metadata['batch'],
    ]);
    final Map<String, dynamic> presentation = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['presentation'],
      nodeRuntime['presentation'],
      sourceNode.props['presentation'],
      definition.metadata['presentation'],
    ]);
    final Map<String, dynamic> resource = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['resource'],
      nodeRuntime['resource'],
      sourceNode.props['resource'],
      sourceNode.props['resources'],
      definition.metadata['resource'],
    ]);
    final Map<String, dynamic> pagination = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['pagination'],
      nodeRuntime['pagination'],
      sourceNode.props['pagination'],
      sourceNode.props['cursor'],
      definition.metadata['pagination'],
    ]);
    final Map<String, dynamic> network = _qlDeepMergeMaps(<dynamic>[
      definition.runtime['network'],
      nodeRuntime['network'],
      sourceNode.props['network'],
      definition.metadata['network'],
    ]);

    final dynamic selectRaw = nodeRuntime['select'] ??
        nodeRuntime['projection'] ??
        nodeRuntime['fields'] ??
        sourceNode.props['select'] ??
        sourceNode.props['projection'] ??
        sourceNode.props['fields'] ??
        definition.metadata['select'];
    final Object select = _qlNormalizeSelect(selectRaw);
    final List<String> selectPaths = _qlFlattenSelectPaths(select);

    final List<String> capabilities = _qlUniqueStrings(<dynamic>[
      ...definition.capabilities,
      ..._qlStringList(nodeRuntime['capabilities']),
      ..._qlStringList(nodeRuntime['features']),
      ..._qlStringList(nodePolicy['capabilities']),
      ..._qlStringList(nodePolicy['features']),
      ..._qlStringList(sourceNode.props['capabilities']),
      ..._qlStringList(sourceNode.props['features']),
      ..._qlStringList(definition.metadata['capabilities']),
      ..._qlStringList(definition.metadata['features']),
      if (media.isNotEmpty) 'media',
      if (stream.isNotEmpty) 'stream',
      if (cache.isNotEmpty) 'cache',
      if (batch.isNotEmpty) 'batch',
      if (pagination.isNotEmpty) 'pagination',
      if (presentation.isNotEmpty) 'presentation',
    ]);

    final List<_QLBlueprintRuntimeRule> rules = _qlCollectBlueprintRules(
      nodeRuntime,
      nodePolicy,
    );

    return <String, dynamic>{
      'signature': signature,
      'runtime': nodeRuntime,
      'policy': nodePolicy,
      'media': media,
      'stream': stream,
      'cache': cache,
      'batch': batch,
      'presentation': presentation,
      'resource': resource,
      'pagination': pagination,
      'network': network,
      'select': select,
      'selectPaths': List<String>.unmodifiable(selectPaths),
      'capabilities': List<String>.unmodifiable(capabilities),
      'rules': List<_QLBlueprintRuntimeRule>.unmodifiable(rules),
    };
  });
}

class _QLComponentDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> props;
  final Map<String, dynamic> state;
  final Map<String, dynamic> links;
  final Map<String, dynamic> variants;
  final Map<String, dynamic> animations;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> runtime;
  final Map<String, dynamic> policy;
  final List<String> capabilities;
  final Map<String, _QLComponentComputedSpec> computed;
  final _QLComponentHookBundle hooks;
  final QLBlueprint ui;
  final Map<String, QLBlueprint> slots;
  final int fingerprint;

  const _QLComponentDefinition({
    required this.name,
    required this.description,
    required this.props,
    required this.state,
    required this.links,
    required this.variants,
    required this.animations,
    required this.metadata,
    required this.runtime,
    required this.policy,
    required this.capabilities,
    required this.computed,
    required this.hooks,
    required this.ui,
    required this.slots,
    required this.fingerprint,
  });

  factory _QLComponentDefinition.fromMap(
    Map<String, dynamic> raw, {
    required String debugPath,
    required String fallbackName,
    required QLBlueprint sourceNode,
  }) {
    final Map<String, dynamic> normalized = Map<String, dynamic>.from(raw);
    normalized.putIfAbsent('name', () => fallbackName);

    final String name = normalized['name']?.toString().trim().isNotEmpty == true
        ? normalized['name'].toString().trim()
        : fallbackName;
    final String description = normalized['description']?.toString() ?? '';
    final Map<String, dynamic> props = _asMap(normalized['props']);
    final Map<String, dynamic> state = _asMap(normalized['state']);
    final Map<String, dynamic> links = _asMap(normalized['links']);
    final Map<String, dynamic> variants = _asMap(normalized['variants']);
    final Map<String, dynamic> animations = _asMap(normalized['animations']);
    final Map<String, dynamic> metadata = _asMap(normalized['metadata']);
    final Map<String, dynamic> runtime = _qlDeepMergeMaps(<dynamic>[
      _asMap(normalized['runtime']),
      _asMap(normalized['omni']),
      _asMap(metadata['runtime']),
      _asMap(metadata['omni']),
      _asMap(metadata['media']),
      _asMap(metadata['stream']),
      _asMap(metadata['cache']),
      _asMap(metadata['batch']),
      _asMap(metadata['presentation']),
      _asMap(metadata['resource']),
      _asMap(metadata['pagination']),
      _asMap(metadata['network']),
      _asMap(metadata['select']),
    ]);
    final Map<String, dynamic> policy = _qlDeepMergeMaps(<dynamic>[
      _asMap(normalized['policy']),
      _asMap(normalized['policies']),
      _asMap(metadata['policy']),
      _asMap(metadata['policies']),
      _asMap(metadata['guard']),
      _asMap(metadata['permissions']),
    ]);
    final List<String> capabilities = _qlUniqueStrings(<dynamic>[
      ..._qlStringList(normalized['capabilities']),
      ..._qlStringList(runtime['capabilities']),
      ..._qlStringList(runtime['features']),
      ..._qlStringList(policy['capabilities']),
      ..._qlStringList(policy['features']),
      ..._qlStringList(metadata['capabilities']),
      ..._qlStringList(metadata['features']),
      if (_asMap(runtime['media']).isNotEmpty) 'media',
      if (_asMap(runtime['stream']).isNotEmpty) 'stream',
      if (_asMap(runtime['cache']).isNotEmpty) 'cache',
      if (_asMap(runtime['batch']).isNotEmpty) 'batch',
      if (_asMap(runtime['presentation']).isNotEmpty) 'presentation',
    ]);
    final Map<String, _QLComponentComputedSpec> computed =
        _parseComputed(normalized['computed']);
    final _QLComponentHookBundle hooks = _parseHooks(normalized['hooks']);

    final QLBlueprint ui = _resolveComponentUi(
      normalized['ui'] ?? normalized['children'],
      debugPath: '$debugPath.ui',
      fallbackNode: QLBlueprint(
        type: 'box:col',
        props: const <String, dynamic>{},
        children: const <QLBlueprint>[],
        debugPath: debugPath,
      ),
      children: sourceNode.children,
    );

    final Map<String, QLBlueprint> slots = <String, QLBlueprint>{};
    final Map<String, dynamic> rawSlots = _asMap(normalized['slots']);
    for (final entry in rawSlots.entries) {
      slots[entry.key] = _blueprintFromDynamic(
        entry.value,
        path: '$debugPath.slots[${entry.key}]',
        fallbackType: 'box',
      );
    }

    final int fingerprint = QLStableHasher.of(<String, dynamic>{
      'name': name,
      'description': description,
      'props': props,
      'state': state,
      'links': links,
      'variants': variants,
      'animations': animations,
      'runtime': runtime,
      'policy': policy,
      'capabilities': capabilities,
      'computed': computed.map((k, v) => MapEntry(k, v.toJson())),
      'hooks': hooks.toJson(),
      'ui': ui.toJson(),
      'slots': slots.map((k, v) => MapEntry(k, v.toJson())),
      'metadata': metadata,
    });

    return _QLComponentDefinition(
      name: name,
      description: description,
      props: props,
      state: state,
      links: links,
      variants: variants,
      animations: animations,
      metadata: metadata,
      runtime: runtime,
      policy: policy,
      capabilities: capabilities,
      computed: computed,
      hooks: hooks,
      ui: ui,
      slots: slots,
      fingerprint: fingerprint,
    );
  }

  Map<String, dynamic> toMetadata() => <String, dynamic>{
        'name': name,
        'description': description,
        'componentSpec': toMap(),
        'runtime': runtime,
        'policy': policy,
        'capabilities': capabilities,
        'paramSchema': <String, dynamic>{
          'type': 'object',
          'properties': {
            for (final entry in props.entries)
              entry.key: _componentSchemaForValue(entry.value),
          },
          'required': props.keys.toList(growable: false),
        },
        'infoSchema': <String, dynamic>{
          'name': name,
          'kind': 'native_component',
          'description': description,
          'capabilities': capabilities,
          'runtimeKeys': runtime.keys.toList(growable: false),
          'policyKeys': policy.keys.toList(growable: false),
          'slotNames': slots.keys.toList(growable: false),
        },
      };

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'description': description,
        'props': props,
        'state': state,
        'links': links,
        'variants': variants,
        'animations': animations,
        'metadata': metadata,
        'runtime': runtime,
        'policy': policy,
        'capabilities': capabilities,
        'computed': computed.map((k, v) => MapEntry(k, v.toMap())),
        'hooks': hooks.toJson(),
        'ui': ui.toJson(),
        'slots': slots.map((k, v) => MapEntry(k, v.toJson())),
        'fingerprint': fingerprint,
      };
}

class _QLComponentComputedSpec {
  final String key;
  final List<String> deps;
  final String op;
  final List<dynamic> args;
  final dynamic fallback;
  final bool immediate;

  const _QLComponentComputedSpec({
    required this.key,
    required this.deps,
    required this.op,
    required this.args,
    required this.fallback,
    required this.immediate,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'key': key,
        'deps': deps,
        'op': op,
        'args': args,
        'fallback': fallback,
        'immediate': immediate,
      };

  Map<String, dynamic> toJson() => toMap();
}

class _QLComponentEffectSpec {
  final List<String> deps;
  final List<dynamic> actions;
  final int debounceMs;
  final bool immediate;

  const _QLComponentEffectSpec({
    required this.deps,
    required this.actions,
    required this.debounceMs,
    required this.immediate,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'deps': deps,
        'actions': actions,
        'debounceMs': debounceMs,
        'immediate': immediate,
      };
}

class _QLComponentHookBundle {
  final List<dynamic> mountActions;
  final List<dynamic> unmountActions;
  final List<_QLComponentEffectSpec> effects;
  final List<dynamic> bridge;
  final List<dynamic> guard;
  final List<dynamic> memo;
  final Map<String, dynamic> scope;
  final List<dynamic> controller;

  const _QLComponentHookBundle({
    this.mountActions = const <dynamic>[],
    this.unmountActions = const <dynamic>[],
    this.effects = const <_QLComponentEffectSpec>[],
    this.bridge = const <dynamic>[],
    this.guard = const <dynamic>[],
    this.memo = const <dynamic>[],
    this.scope = const <String, dynamic>{},
    this.controller = const <dynamic>[],
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'mountActions': mountActions,
        'unmountActions': unmountActions,
        'effects': effects.map((e) => e.toJson()).toList(growable: false),
        'bridge': bridge,
        'guard': guard,
        'memo': memo,
        'scope': scope,
        'controller': controller,
      };
}

class _QLComponentRuntimeHost extends StatefulWidget {
  final _QLComponentDefinition definition;
  final QLBlueprint sourceNode;
  final _AliasContext sourceCtx;
  final _QLComponentDefinition? definitionOverride;
  final bool preview;

  const _QLComponentRuntimeHost({
    required this.definition,
    required this.sourceNode,
    required this.sourceCtx,
    this.definitionOverride,
    this.preview = false,
  });

  @override
  State<_QLComponentRuntimeHost> createState() =>
      _QLComponentRuntimeHostState();
}

class _QLComponentRuntimeHostState extends State<_QLComponentRuntimeHost> {
  late final String _namespace;
  late QLDataStore _store;
  Listenable _merged = _noopListenable;
  final Map<_QLComponentEffectSpec, List<_QLComponentSignalBinding>>
      _effectBindings =
      <_QLComponentEffectSpec, List<_QLComponentSignalBinding>>{};
  final Map<_QLComponentEffectSpec, Timer?> _effectTimers =
      <_QLComponentEffectSpec, Timer?>{};
  bool _didMount = false;
  Map<String, dynamic>? _cachedEnv;
  Map<String, dynamic>? _cachedState;
  Map<String, dynamic>? _cachedProps;
  Map<String, dynamic>? _cachedLinks;
  Map<String, dynamic>? _cachedRuntimeProfile;

  _QLComponentDefinition get _definition =>
      widget.definitionOverride ?? widget.definition;

  SessionContext _sessionFromEnv(Map<String, dynamic> env) {
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

  Map<String, dynamic> _runtimeProfile() {
    final Map<String, dynamic> profile = _cachedRuntimeProfile ??
        _buildComponentRuntimeProfile(
            _definition, widget.sourceNode, widget.sourceCtx);
    _cachedRuntimeProfile = profile;
    return profile;
  }

  QuantumPermissionDecision _permissionDecision(BuildContext context) {
    final Map<String, dynamic> env = _componentEnv(context);
    final Map<String, dynamic> profile = _runtimeProfile();
    final dynamic rule = _definition.metadata['permission'] ??
        _definition.metadata['permissions'] ??
        _definition.metadata['guard'] ??
        _definition.metadata['policy'] ??
        profile['policy']['permission'] ??
        profile['policy']['permissions'] ??
        profile['runtime']['permission'] ??
        profile['runtime']['permissions'] ??
        profile['runtime']['guard'];
    if (rule == null) {
      return const QuantumPermissionDecision.allow('no component rule');
    }
    return QuantumPermissionEngine.instance.evaluate(
      rule,
      QuantumPermissionContext.fromSession(
        _sessionFromEnv(env),
        env: env,
        data: <String, dynamic>{
          'props': _cachedProps ?? const <String, dynamic>{},
          'state': _cachedState ?? const <String, dynamic>{},
          'links': _cachedLinks ?? const <String, dynamic>{},
          'definition': _definition.toMap(),
          'runtime': profile,
        },
        scope: 'component',
        resource: _definition.name,
        operation: 'render',
        feature: profile['runtime']['feature']?.toString() ??
            _definition.metadata['feature']?.toString(),
        schema: profile['runtime']['schema']?.toString() ??
            _definition.metadata['schema']?.toString(),
      ),
      meta: <String, dynamic>{'component': _definition.name},
    );
  }

  @override
  void initState() {
    super.initState();
    _namespace =
        'component:${_definition.name}:${widget.sourceNode.debugPath}:${_definition.fingerprint}';
    _store = QLStoreRegistry.instance.get(_namespace);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRuntimeState();
  }

  @override
  void didUpdateWidget(covariant _QLComponentRuntimeHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _cachedRuntimeProfile = null;
    _syncRuntimeState();
  }

  void _syncRuntimeState() {
    if (!_permissionDecision(context).allowed) {
      return;
    }
    _refreshRuntimeCache();
    _syncStoreInputs();
    _syncComputed();
    _syncWatchers();
    _syncEffects();
    if (!_didMount) {
      _didMount = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _runActions(_definition.hooks.mountActions);
      });
    }
  }

  void _syncStoreInputs() {
    final _QLComponentDefinition def = _definition;
    final Map<String, dynamic> instanceProps = _resolveInstanceProps();
    final Map<String, dynamic> instanceLinks = _resolveLinks(context);
    final Map<String, dynamic> variantProps =
        _resolveVariantProps(instanceProps);

    _store.transaction(() {
      _store.sweep('props.');
      _store.sweep('links.');

      for (final entry
          in {...def.props, ...instanceProps, ...variantProps}.entries) {
        _store.set('props.${entry.key}', entry.value);
      }

      for (final entry in {...def.links, ...instanceLinks}.entries) {
        _store.set('links.${entry.key}', entry.value);
      }

      final Map<String, dynamic> initialState = {
        ...def.state,
        ..._asMap(widget.sourceNode.props['state']),
      };
      final bool resetState = widget.sourceCtx.boolean('resetState');
      for (final entry in initialState.entries) {
        if (resetState || _store.get(entry.key) == null) {
          _store.set(entry.key, entry.value);
        }
      }
    });
  }

  void _syncComputed() {
    final def = _definition;
    for (final entry in def.computed.entries) {
      final spec = entry.value;
      _store.registerComputed(
        spec.key,
        spec.deps,
        (values) => _executeComputed(spec, values),
      );
    }
  }

  void _syncWatchers() {
    final Set<String> watchKeys = <String>{
      ..._definition.state.keys,
      ..._definition.computed.keys,
      ..._definition.links.keys,
    };
    final List<Listenable> listeners = <Listenable>[];
    for (final key in watchKeys) {
      listeners.add(_store.signal(key));
    }
    _merged = listeners.isEmpty ? _noopListenable : Listenable.merge(listeners);
  }

  void _syncEffects() {
    for (final bindings in _effectBindings.values) {
      for (final binding in bindings) {
        binding.signal.removeListener(binding.listener);
      }
    }
    _effectBindings.clear();
    for (final timer in _effectTimers.values) {
      timer?.cancel();
    }
    _effectTimers.clear();

    for (final effect in _definition.hooks.effects) {
      final List<_QLComponentSignalBinding> bindings =
          <_QLComponentSignalBinding>[];
      void runEffect() {
        final Timer? existing = _effectTimers[effect];
        existing?.cancel();
        if (effect.debounceMs > 0) {
          _effectTimers[effect] = Timer(
            Duration(milliseconds: effect.debounceMs),
            () => _runActions(effect.actions),
          );
        } else {
          _runActions(effect.actions);
        }
      }

      for (final dep in effect.deps) {
        final signal = _store.signal(dep);
        final VoidCallback listener = runEffect;
        signal.addListener(listener);
        bindings.add(_QLComponentSignalBinding(signal, listener));
      }
      _effectBindings[effect] = bindings;
      if (effect.immediate) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _runActions(effect.actions);
        });
      }
    }
  }

  Map<String, dynamic> _resolveInstanceProps() {
    final Map<String, dynamic> result = <String, dynamic>{};
    final Map<String, dynamic> raw = _asMap(widget.sourceNode.props['props']);
    final Map<String, dynamic> direct = <String, dynamic>{};
    for (final entry in widget.sourceNode.props.entries) {
      final String key = entry.key.toString();
      if (_internalComponentKeys.contains(key)) continue;
      direct[key] = entry.value;
    }
    result.addAll(_definition.props);
    result.addAll(raw);
    result.addAll(direct);
    result.addAll(_resolveVariantProps(result));

    final String variant = widget.sourceCtx.string('variant').trim();
    if (variant.isNotEmpty) {
      final dynamic variantMap = _definition.variants[variant];
      if (variantMap is Map) {
        result.addAll(Map<String, dynamic>.from(variantMap));
      }
    }
    return result;
  }

  Map<String, dynamic> _resolveVariantProps(Map<String, dynamic> baseProps) {
    final dynamic raw = widget.sourceNode.props['variants'];
    if (raw is! Map) return <String, dynamic>{};
    final String active = widget.sourceCtx.string('variant').trim();
    if (active.isEmpty) return <String, dynamic>{};
    final dynamic variant = raw[active];
    if (variant is Map) {
      return Map<String, dynamic>.from(variant);
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _resolveLinks(BuildContext context) {
    final Map<String, dynamic> result = <String, dynamic>{};
    final Map<String, dynamic> raw = _asMap(widget.sourceNode.props['links']);
    for (final entry in raw.entries) {
      result[entry.key] = _resolveLinkValue(context, entry.value);
    }
    return result;
  }

  dynamic _resolveLinkValue(BuildContext context, dynamic raw) {
    final Map<String, dynamic> env = _componentEnv(context);
    return QLDataBinder.resolveAOT(raw, context, env, _store);
  }

  void _refreshRuntimeCache([BuildContext? context]) {
    final Map<String, dynamic> stateSnapshot =
        Map<String, dynamic>.from(_store.snapshot);
    final Map<String, dynamic> propsSnapshot =
        _snapshotByPrefixFrom(stateSnapshot, 'props.');
    final Map<String, dynamic> linksSnapshot =
        _snapshotByPrefixFrom(stateSnapshot, 'links.');
    final BuildContext? effectiveContext = context ?? this.context;
    final QLDataScope? parentScope = effectiveContext != null
        ? QLDataScope.readNode(effectiveContext)
        : null;
    final Map<String, dynamic> parentData = parentScope?.localData ?? const {};
    final Map<String, dynamic> rootData = (widget.sourceCtx.env['root'] is Map)
        ? Map<String, dynamic>.from(widget.sourceCtx.env['root'] as Map)
        : parentData;

    final Map<String, dynamic> runtimeProfile = _runtimeProfile();
    final Object selectSpec = runtimeProfile['select'];
    final Map<String, dynamic> selectedProps =
        _qlProjectBySelectMap(propsSnapshot, selectSpec);
    final Map<String, dynamic> selectedState =
        _qlProjectBySelectMap(stateSnapshot, selectSpec);
    final Map<String, dynamic> selectedLinks =
        _qlProjectBySelectMap(linksSnapshot, selectSpec);
    final List<String> selectPaths =
        List<String>.from(runtimeProfile['selectPaths'] as List);
    final Map<String, dynamic> projection = <String, dynamic>{
      'select': selectSpec,
      'paths': selectPaths,
      'props': selectedProps,
      'state': selectedState,
      'links': selectedLinks,
      'coverage': <String, dynamic>{
        'selectedProps': selectedProps.keys.toList(growable: false),
        'selectedState': selectedState.keys.toList(growable: false),
        'selectedLinks': selectedLinks.keys.toList(growable: false),
        'selectPaths': selectPaths,
        'projectionMode': selectPaths.isNotEmpty,
      },
    };

    _cachedState = stateSnapshot;
    _cachedProps = propsSnapshot;
    _cachedLinks = linksSnapshot;
    _cachedEnv = <String, dynamic>{
      ...widget.sourceCtx.env,
      ...stateSnapshot,
      ...propsSnapshot,
      ...linksSnapshot,
      'component': <String, dynamic>{
        'name': _definition.name,
        'description': _definition.description,
        'namespace': _namespace,
        'fingerprint': _definition.fingerprint,
        'runtime': runtimeProfile['runtime'],
        'policy': runtimeProfile['policy'],
        'select': selectSpec,
        'cache': runtimeProfile['cache'],
        'media': runtimeProfile['media'],
        'stream': runtimeProfile['stream'],
        'batch': runtimeProfile['batch'],
        'presentation': runtimeProfile['presentation'],
        'resource': runtimeProfile['resource'],
        'pagination': runtimeProfile['pagination'],
        'network': runtimeProfile['network'],
        'capabilities': runtimeProfile['capabilities'],
      },
      'componentRuntime': runtimeProfile['runtime'],
      'componentPolicy': runtimeProfile['policy'],
      'componentMedia': runtimeProfile['media'],
      'componentStream': runtimeProfile['stream'],
      'componentCache': runtimeProfile['cache'],
      'componentBatch': runtimeProfile['batch'],
      'componentPresentation': runtimeProfile['presentation'],
      'componentResource': runtimeProfile['resource'],
      'componentPagination': runtimeProfile['pagination'],
      'componentNetwork': runtimeProfile['network'],
      'componentCapabilities': runtimeProfile['capabilities'],
      'componentSelect': selectSpec,
      'componentSelectPaths': selectPaths,
      'componentProjection': projection,
      'componentCacheCoverage': projection['coverage'],
      'componentVisible': <String, dynamic>{
        'props': selectedProps,
        'state': selectedState,
        'links': selectedLinks,
      },
      'self': <String, dynamic>{
        'props': propsSnapshot,
        'state': stateSnapshot,
        'links': linksSnapshot,
        'visible': <String, dynamic>{
          'props': selectedProps,
          'state': selectedState,
          'links': selectedLinks,
        },
      },
      'parent': parentData,
      'root': rootData,
    };
  }

  Map<String, dynamic> _componentEnv(BuildContext context) {
    if (_cachedEnv == null) _refreshRuntimeCache(context);
    return _cachedEnv!;
  }

  Map<String, dynamic> _snapshotByPrefixFrom(
    Map<String, dynamic> snapshot,
    String prefix,
  ) {
    final Map<String, dynamic> out = <String, dynamic>{};
    for (final entry in snapshot.entries) {
      final String key = entry.key;
      if (!key.startsWith(prefix)) continue;
      out[key.substring(prefix.length)] = entry.value;
    }
    return out;
  }

  void _runActions(List<dynamic> actions) {
    if (actions.isEmpty) return;
    // ignore: discarded_futures
    QuantumVM.instance.triggerActions(
      actions,
      context,
      env: _componentEnv(context),
    );
  }

  dynamic _executeComputed(
      _QLComponentComputedSpec spec, List<dynamic> values) {
    final List<dynamic> args = spec.args;
    final dynamic fallback = spec.fallback;
    final String op = spec.op.toLowerCase();

    switch (op) {
      case 'constant':
        return args.isNotEmpty ? args.first : fallback;
      case 'copy':
        for (final value in values) {
          if (value != null) return value;
        }
        return fallback;
      case 'concat':
        final StringBuffer buffer = StringBuffer();
        for (final value in values) {
          if (value != null) buffer.write(value.toString());
        }
        for (final arg in args) {
          if (arg != null) buffer.write(arg.toString());
        }
        return buffer.toString();
      case 'sum':
        double total = 0.0;
        for (final value in values) {
          total += _asDouble(value);
        }
        for (final arg in args) {
          total += _asDouble(arg);
        }
        return total;
      case 'product':
        double total = 1.0;
        for (final value in values) {
          total *= _asDouble(value, fallback: 1.0);
        }
        for (final arg in args) {
          total *= _asDouble(arg, fallback: 1.0);
        }
        return total;
      case 'min':
        final List<double> nums = values.map((v) => _asDouble(v)).toList();
        nums.addAll(args.map((a) => _asDouble(a)));
        return nums.isEmpty ? fallback : nums.reduce(math.min);
      case 'max':
        final List<double> nums = values.map((v) => _asDouble(v)).toList();
        nums.addAll(args.map((a) => _asDouble(a)));
        return nums.isEmpty ? fallback : nums.reduce(math.max);
      case 'and':
        bool result = true;
        for (final value in values) {
          result = result && _asBool(value);
        }
        for (final arg in args) {
          result = result && _asBool(arg);
        }
        return result;
      case 'or':
        bool result = false;
        for (final value in values) {
          result = result || _asBool(value);
        }
        for (final arg in args) {
          result = result || _asBool(arg);
        }
        return result;
      case 'not':
        final dynamic value = values.isNotEmpty ? values.first : fallback;
        return !_asBool(value);
      case 'eq':
        final dynamic left = values.isNotEmpty ? values.first : null;
        final dynamic right = args.isNotEmpty ? args.first : fallback;
        return _equals(left, right);
      case 'neq':
        final dynamic left = values.isNotEmpty ? values.first : null;
        final dynamic right = args.isNotEmpty ? args.first : fallback;
        return !_equals(left, right);
      case 'gt':
        return _asDouble(values.isNotEmpty ? values.first : null) >
            _asDouble(args.isNotEmpty ? args.first : fallback);
      case 'gte':
        return _asDouble(values.isNotEmpty ? values.first : null) >=
            _asDouble(args.isNotEmpty ? args.first : fallback);
      case 'lt':
        return _asDouble(values.isNotEmpty ? values.first : null) <
            _asDouble(args.isNotEmpty ? args.first : fallback);
      case 'lte':
        return _asDouble(values.isNotEmpty ? values.first : null) <=
            _asDouble(args.isNotEmpty ? args.first : fallback);
      case 'first':
        return values.isNotEmpty ? values.first : fallback;
      case 'last':
        return values.isNotEmpty ? values.last : fallback;
      case 'list':
        return List<dynamic>.from(values);
      case 'pick':
        final int index =
            int.tryParse(args.isNotEmpty ? args.first.toString() : '0') ?? 0;
        if (index < 0 || index >= values.length) return fallback;
        return values[index];
      case 'coalesce':
        for (final value in values) {
          if (value != null) return value;
        }
        return fallback;
      default:
        return values.isNotEmpty ? values.first : fallback;
    }
  }

  double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String lower = value?.toString().toLowerCase() ?? '';
    return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
  }

  QLBlueprint _renderBlueprint(
    QLBlueprint blueprint,
    BuildContext context,
    Map<String, dynamic> env, {
    Map<String, dynamic>? runtimeProfile,
  }) {
    final Map<String, dynamic> resolvedProps = <String, dynamic>{};
    blueprint.props.forEach((key, value) {
      resolvedProps[key] = QLDataBinder.resolveAOT(value, context, env, _store);
    });

    final QLBlueprint resolved = QLBlueprint(
      type: blueprint.type,
      props: resolvedProps,
      style: blueprint.style,
      children: blueprint.children
          .map((c) =>
              _renderBlueprint(c, context, env, runtimeProfile: runtimeProfile))
          .toList(growable: false),
      slots: blueprint.slots.map(
        (k, v) => MapEntry(k,
            _renderBlueprint(v, context, env, runtimeProfile: runtimeProfile)),
      ),
      debugPath: blueprint.debugPath,
    );

    final Map<String, dynamic> profile = runtimeProfile ?? _runtimeProfile();
    final List<_QLBlueprintRuntimeRule> rules =
        List<_QLBlueprintRuntimeRule>.from(profile['rules'] as List);
    final QLBlueprint ruled =
        rules.isEmpty ? resolved : _qlApplyBlueprintRules(resolved, rules, env);
    return _applyAnimations(ruled);
  }

  QLBlueprint _applyAnimations(QLBlueprint blueprint) {
    if (_definition.animations.isEmpty) return blueprint;
    QLBlueprint current = blueprint;
    for (final entry in _definition.animations.entries) {
      final dynamic raw = entry.value;
      final Map<String, dynamic> config = raw is Map
          ? Map<String, dynamic>.from(raw)
          : <String, dynamic>{'type': raw};
      final String type = config['type']?.toString().trim().isNotEmpty == true
          ? config['type'].toString().trim()
          : (config['animationType']?.toString().trim().isNotEmpty == true
              ? config['animationType'].toString().trim()
              : 'signal');
      current = QLBlueprint(
        type: 'animation',
        props: <String, dynamic>{
          ...config,
          'animationType': type,
        },
        children: <QLBlueprint>[current],
        debugPath: '${blueprint.debugPath}.animations[${entry.key}]',
      );
    }
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final decision = _permissionDecision(context);
    if (!decision.allowed) {
      return const SizedBox.shrink();
    }
    return AnimatedBuilder(
      animation: _merged,
      builder: (_, __) {
        _refreshRuntimeCache(context);
        final Map<String, dynamic> env = _componentEnv(context);

        final int depth = (env['__component_depth'] as int?) ?? 0;
        if (depth > 50) {
          return const SizedBox
              .shrink(); // Prevent infinite recursion stack overflow
        }
        final Map<String, dynamic> nextEnv = Map<String, dynamic>.from(env);
        nextEnv['__component_depth'] = depth + 1;

        final Map<String, dynamic> profile = _runtimeProfile();
        final QLBlueprint renderedUi = _renderBlueprint(
          _definition.ui,
          context,
          nextEnv,
          runtimeProfile: profile,
        );
        return QLDataScope(
          localData: nextEnv,
          moduleStore: _store,
          child: QuantumVM.instance.renderWidget(context, renderedUi),
        );
      },
    );
  }

  @override
  void dispose() {
    for (final entry in _effectBindings.entries) {
      for (final binding in entry.value) {
        binding.signal.removeListener(binding.listener);
      }
    }
    for (final timer in _effectTimers.values) {
      timer?.cancel();
    }
    if (_definition.hooks.unmountActions.isNotEmpty) {
      // ignore: discarded_futures
      QuantumVM.instance.triggerActions(
        _definition.hooks.unmountActions,
        context,
        env: _componentEnv(context),
      );
    }
    QLStoreRegistry.instance.destroy(_namespace);
    super.dispose();
  }
}

class _QLComponentSignalBinding {
  final QLSignal<dynamic> signal;
  final VoidCallback listener;

  const _QLComponentSignalBinding(this.signal, this.listener);
}

final _NoopListenable _noopListenable = _NoopListenable.instance;

bool _equals(dynamic a, dynamic b) => identical(a, b) || a == b;

double _asDouble(dynamic value, {double fallback = 0.0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final String lower = value?.toString().toLowerCase() ?? '';
  return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on';
}

const Set<String> _internalComponentKeys = <String>{
  'name',
  'description',
  'definition',
  'component',
  'spec',
  'payload',
  'props',
  'state',
  'computed',
  'hooks',
  'links',
  'variants',
  'animations',
  'ui',
  'slots',
  'preview',
  'render',
  'resetState',
  'variant',
  'key',
  'as',
  'runtime',
  'policy',
  'policies',
  'permissions',
  'permission',
  'guard',
  'capabilities',
  'features',
  'media',
  'stream',
  'cache',
  'batch',
  'presentation',
  'resource',
  'resources',
  'pagination',
  'projection',
  'select',
  'fields',
  'network',
  '__subType',
};
