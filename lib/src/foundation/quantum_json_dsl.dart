/*
 * ============================================================================
 * File: quantum_json_dsl.dart
 * 
 * Description:
 * JSON-native Component and Layout Definition Layer. Provides a high-performance 
 * system for defining UI templates and matrix layouts dynamically via JSON without 
 * needing to recompile the Dart codebase.
 * 
 * Key Components:
 * - QJsonPresetEngine: Registry and compiler for JSON-driven templates with defaults.
 * - _PresetRecord: Immutable compiled representation of a template.
 * - QJsonDSL: A batch registry API supporting polymorphic component definitions.
 * 
 * Dependencies/Relationships:
 * Heavily intertwined with quantum_matrix_engine.dart and quantum_core.dart. 
 * Core enabling module for Server-Driven UI (SDUI) configurations.
 * 
 * Notes:
 * Extremely cache-heavy to ensure O(1) template resolution. Replaces traditional 
 * Dart instantiations with hashed blueprint definitions.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// quantum_json_dsl.dart
//
// JSON-NATIVE COMPONENT & LAYOUT DEFINITION LAYER
//
// Lets you define ANYTHING in the engine by throwing plain JSON/Map objects:
//
//   ┌──────────────────────────────────────────────────────────────────────┐
//   │  QJsonPresetEngine.define({                                            │
//   │    "type": "template",                                               │
//   │    "name": "MyCard",              ← registered plugin type           │
//   │    "props": { "title":"", "color":"#fff" }, ← typed default props    │
//   │    "slots": ["header","body","footer"],     ← slot names              │
//   │    "ui": { "type": "box", "children": [...] }   ← compiled once      │
//   │  });                                                                  │
//   │                                                                      │
//   │  QuantumVM.instance.defineMatrixLayout({                             │
//   │    "type": "layout",                                                 │
//   │    "name": "AppShell",                                               │
//   │    "gap": 8,                                                         │
//   │    "matrix": """                                                     │
//   │      1fr 3fr 1fr                                                     │
//   │      nav main aside | 60px                                           │
//   │      nav footer footer | 48px                                        │
//   │    """,                                                              │
//   │    "variants": {                                                     │
//   │      "mobile": "1fr\nnav | 48px\nmain | 1fr\nfooter | 48px"        │
//   │    },                                                                │
//   │    "slots": {                                                        │
//   │      "nav":    { "scrollable": false, "zIndex": 10 },               │
//   │      "main":   { "scrollable": true  },                              │
//   │      "aside":  { "padding": 16 },                                   │
//   │      "footer": { "floating": false }                                 │
//   │    }                                                                 │
//   │  });                                                                 │
//   └──────────────────────────────────────────────────────────────────────┘
//
// PERFORMANCE CONTRACT:
//   • Every JSON definition is hashed and compiled exactly once.
//   • Subsequent calls with the same hash are O(1) no-ops (cache hit).
//   • Template rendering uses the AOT-compiled QLBlueprint.
//     No extra JSON parsing on hot path.
//   • Prop merging uses a flat hash-map lookup — zero allocation on cache hit.
//   • Matrix compilation is cached by (cols+rows+slots) hash fingerprint.
//   • Hot-swap: re-defining a name with a *different* hash re-compiles once.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../quantum.dart';
// ──────────────────────────────────────────────────────────────────────────────
// SECTION 1 — Template Engine (QJsonPresetEngine)
// ──────────────────────────────────────────────────────────────────────────────

/// High-performance JSON-native template registry.
///
/// A "template" is a reusable component fully described by a plain JSON/Map
/// object. It compiles exactly once and thereafter renders with O(1) prop
/// look-up and zero-allocation hot paths.
///
/// ### JSON schema (all fields except [name] are optional)
/// ```json
/// {
///   "type": "template",        // must be "template" or omitted
///   "name": "MyCard",          // required — the registered plugin type name
///   "props": {                 // default prop values (type-hinted coercions)
///     "title": "",
///     "color": "#ffffff",
///     "count": 0
///   },
///   "slots": ["header", "body"], // named slots forwarded from usage site
///   "ui": { ... }              // THE compiled UI tree (QLBlueprint JSON)
/// }
/// ```
class QJsonPresetEngine {
  QJsonPresetEngine._();

  // Singleton definition registry: name → compiled record
  static final Map<String, _PresetRecord> _registry = {};

  // Fingerprint cache: definition hash → record (guards re-compilation)
  static final Map<int, _PresetRecord> _fingerprintCache = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Define a template from a plain JSON/Map.
  ///
  /// Supported JSON keys:
  /// - `name` / `id`: registry key.
  /// - `props` / `defaultProps`: default props merged with usage props.
  /// - `slots`: either a list of slot names or a map of slot-name → default
  ///   slot blueprint JSON.
  /// - `ui` / `template` / `view` / `layout`: compiled UI blueprint.
  ///
  /// The map **must** contain a `"name"` key.
  ///
  /// Calling [define] with the same [json] hash is a guaranteed O(1) no-op.
  /// Calling it with the same name but a different [json] hot-swaps the
  /// definition and re-registers the plugin.
  static void define(Map<String, dynamic> json) {
    final int fingerprint = QLStableHasher.of(json);

    // Fast path: already compiled with this exact JSON.
    final existing = _fingerprintCache[fingerprint];
    if (existing != null) return; // nothing changed — O(1) exit

    final String name = (json['name'] ?? json['id'] ?? '').toString().trim();
    if (name.isEmpty) {
      throw ArgumentError(
          '[QJsonPresetEngine.define] JSON must have a non-empty "name" field.');
    }

    final Map<String, dynamic> defaultProps =
        _extractDefaultProps(json['props'] ?? json['defaultProps']);
    final Map<String, QLBlueprint> defaultSlots =
        _extractSlotBlueprints(json['slots']);
    final List<String> slotNames = defaultSlots.isNotEmpty
        ? defaultSlots.keys.toList(growable: false)
        : _extractSlotNames(json['slots']);
    final String description =
        (json['description'] ?? json['summary'] ?? '').toString();
    final Map<String, dynamic> params =
        _extractMap(json['params'] ?? json['parameters']);
    final List<String> tags = _extractTags(json['tags']);
    final String engine =
        (json['engine'] ?? 'QJsonPresetEngine').toString();
    final Map<String, dynamic> metadata =
        _extractMap(json['metadata'] ?? json['meta']);
    final Map<String, dynamic> paramSchema = <String, dynamic>{
      'type': 'object',
      'properties': {
        for (final entry in defaultProps.entries)
          entry.key: _schemaForValue(entry.value),
      },
      'required': defaultProps.keys.toList(growable: false),
      'slotNames': slotNames,
    };
    final Map<String, dynamic> infoSchema = <String, dynamic>{
      'name': name,
      'kind': 'preset',
      'description': description.isNotEmpty ? description : 'Template $name',
      'engine': engine,
      'tags': tags,
      'slotNames': slotNames,
      'defaultPropsKeys': defaultProps.keys.toList(growable: false),
    };

    // Compile the UI tree — exactly once, cached by fingerprint.
    final dynamic rawUi =
        json['ui'] ?? json['template'] ?? json['view'] ?? json['layout'];
    QLBlueprint? compiledUi;
    if (rawUi != null) {
      // Use QLCompiler — leverages its own built-in LRU blueprint cache.
      compiledUi = QLCompiler.compile(rawUi, const {}, const {});
    }

    final Map<String, dynamic> mergedMetadata = <String, dynamic>{
      ...metadata,
      'paramSchema': paramSchema,
      'infoSchema': infoSchema,
      'slotNames': slotNames,
      'defaultPropsKeys': defaultProps.keys.toList(growable: false),
    };

    final record = _PresetRecord(
      name: name,
      fingerprint: fingerprint,
      defaultProps: Map<String, dynamic>.unmodifiable(defaultProps),
      defaultSlots: Map<String, QLBlueprint>.unmodifiable(defaultSlots),
      slotNames: List<String>.unmodifiable(slotNames),
      description: description,
      params: Map<String, dynamic>.unmodifiable(params),
      tags: List<String>.unmodifiable(tags),
      engine: engine,
      metadata: Map<String, dynamic>.unmodifiable(mergedMetadata),
      compiledUi: compiledUi,
    );

    _registry[name] = record;
    _fingerprintCache[fingerprint] = record;

    // Register as a native QuantumVM plugin so the SDUI engine can resolve it.
    QuantumVM.instance.registerPlugin(
      _PresetDrivenPlugin(record),
      description:
          description.isNotEmpty ? description : 'Template ${record.name}',
      params: params.isNotEmpty ? params : defaultProps,
      engine: engine,
      metadata: {
        ...mergedMetadata,
        'defaultSlots': defaultSlots.keys.toList(growable: false),
      },
      tags: tags,
    );

    if (kDebugMode) {
      debugPrint(
          '✅ [QJsonPresetEngine] Registered template "${record.name}" '
          '(slots: ${slotNames.join(", ")}, '
          'props: ${defaultProps.keys.join(", ")})');
    }
  }

  @visibleForTesting
  static void clear() {
    _registry.clear();
    _fingerprintCache.clear();
  }

  /// Define multiple templates at once (batch, zero extra overhead).
  static List<String> get registryNames =>
      List<String>.unmodifiable(_registry.keys);

  static Map<String, dynamic>? describe(String name) {
    final rec = _registry[name];
    if (rec == null) return null;
    return rec.toMap();
  }

  static Map<String, dynamic> snapshot() => {
        'count': _registry.length,
        'items': _registry.values.map((r) => r.toMap()).toList(growable: false),
      };

  static void defineAll(List<Map<String, dynamic>> templates) {
    for (final t in templates) {
      define(t);
    }
  }

  /// Retrieve a compiled record — useful for introspection / hot-reload.
  static _PresetRecord? lookup(String name) => _registry[name];

  /// Remove a template by name (useful for hot-reload dev cycles).
  static void undefine(String name) {
    final rec = _registry.remove(name);
    if (rec != null) _fingerprintCache.remove(rec.fingerprint);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  static Map<String, dynamic> _schemaForValue(dynamic value) {
    if (value == null) {
      return const <String, dynamic>{'type': 'dynamic', 'nullable': true};
    }
    if (value is bool) return const <String, dynamic>{'type': 'bool'};
    if (value is int) return const <String, dynamic>{'type': 'int'};
    if (value is double) return const <String, dynamic>{'type': 'double'};
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
        'properties': {
          for (final entry in value.entries)
            entry.key.toString(): _schemaForValue(entry.value),
        },
      };
    }
    return <String, dynamic>{'type': value.runtimeType.toString()};
  }

  static Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is! Map) return const {};
    final Map<String, dynamic> out = {};
    raw.forEach((k, v) {
      out[k.toString()] = v;
    });
    return out;
  }

  static List<String> _extractTags(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return const [];
  }

  static Map<String, dynamic> _extractDefaultProps(dynamic raw) {
    if (raw is! Map) return const {};
    final Map<String, dynamic> out = {};
    raw.forEach((k, v) {
      out[k.toString()] = v;
    });
    return out;
  }

  static Map<String, QLBlueprint> _extractSlotBlueprints(dynamic raw) {
    if (raw is! Map) return const {};
    final Map<String, QLBlueprint> out = {};
    raw.forEach((slotName, slotValue) {
      final String key = slotName.toString();
      if (slotValue is Map) {
        out[key] = QLBlueprint.fromJson(
          Map<String, dynamic>.from(slotValue.cast<String, dynamic>()),
          path: 'template.slots[$key]',
        );
      } else if (slotValue is QLBlueprint) {
        out[key] = slotValue;
      }
    });
    return out;
  }

  static List<String> _extractSlotNames(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is Map) return raw.keys.map((k) => k.toString()).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return const [];
  }
}
// ──────────────────────────────────────────────────────────────────────────────
// Compiled template record — immutable, shared across all render calls
// ──────────────────────────────────────────────────────────────────────────────

class _PresetRecord {
  final String name;
  final int fingerprint;
  final Map<String, dynamic> defaultProps;
  final Map<String, QLBlueprint> defaultSlots;
  final List<String> slotNames;
  final String description;
  final Map<String, dynamic> params;
  final List<String> tags;
  final String engine;
  final Map<String, dynamic> metadata;
  final QLBlueprint? compiledUi; // null → pass-through slot "body"

  const _PresetRecord({
    required this.name,
    required this.fingerprint,
    required this.defaultProps,
    required this.defaultSlots,
    required this.slotNames,
    required this.description,
    required this.params,
    required this.tags,
    required this.engine,
    required this.metadata,
    required this.compiledUi,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'fingerprint': fingerprint,
        'description': description,
        'params': params,
        'tags': tags,
        'engine': engine,
        if (metadata['paramSchema'] != null)
          'paramSchema': metadata['paramSchema'],
        if (metadata['infoSchema'] != null)
          'infoSchema': metadata['infoSchema'],
        'metadata': metadata,
        'defaultProps': defaultProps,
        'defaultSlots': defaultSlots.keys.toList(growable: false),
        'slotNames': slotNames,
        'compiledUi': compiledUi?.toJson(),
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// Plugin — bridges _PresetRecord into the QuantumVM plugin system
// ──────────────────────────────────────────────────────────────────────────────

class _PresetDrivenPlugin extends QLPlugin implements QLWidgetCapability {
  final _PresetRecord _record;

  _PresetDrivenPlugin(this._record);

  @override
  String get type => _record.name;

  @override
  Map<String, dynamic> get defaultProps => _record.defaultProps;

  @override
  Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store) {
    // Merge default props with usage-site props (usage wins).
    // Zero allocation on cache hit: the defaultProps map is already frozen.
    final Map<String, dynamic> env =
        QLDataScope.ofNode(ctx)?.localData ?? const {};

    // 🚀 FIX: Resolve props securely into their own map
    final Map<String, dynamic> resolvedProps = {
      ..._record.defaultProps,
    };
    node.props.forEach((k, v) {
      resolvedProps[k] = QLDataBinder.resolveAOT(v, ctx, env, store);
    });

    final Map<String, QLBlueprint> resolvedSlots = <String, QLBlueprint>{
      ..._record.defaultSlots,
      ...node.slots,
    };

    final QLBlueprint mergedNode = QLBlueprint(
      type: node.type,
      props: resolvedProps,
      style: node.style,
      children: node.children,
      slots: resolvedSlots,
      debugPath: node.debugPath,
    );

    // 🚀 FIX: Nest the resolved props under the 'props' key for AST interpolation
    final Map<String, dynamic> mergedEnv = <String, dynamic>{
      ...env,
      'props': resolvedProps,
      r'$props': resolvedProps,
      'slots': resolvedSlots,
      r'$slots': resolvedSlots,
    };
    // If the template has a compiled UI blueprint, render it.
    if (_record.compiledUi != null) {
      final QLBlueprint compiledRoot = QLBlueprint(
        type: _record.compiledUi!.type,
        props: _record.compiledUi!.props,
        style: _record.compiledUi!.style,
        children: _record.compiledUi!.children,
        slots: {
          ..._record.compiledUi!.slots,
          ...resolvedSlots,
        },
        debugPath: _record.compiledUi!.debugPath,
      );

      final Widget child = QuantumVM.instance.renderWidget(ctx, compiledRoot);

      return QLDataScope(
        localData: mergedEnv,
        moduleStore: store,
        child: child,
      );
    }

    // No UI blueprint → render children/slots directly (pure slot passthrough).
    final qlCtx = QLContext(ctx, mergedNode, mergedEnv, store);
    final List<Widget> slotWidgets = [];

    for (final slotName in _record.slotNames) {
      final w = qlCtx.slot(slotName);
      if (w != null) slotWidgets.add(w);
    }

    if (slotWidgets.isEmpty) {
      slotWidgets.addAll(qlCtx.children);
    }

    if (slotWidgets.length == 1) return slotWidgets.first;
    if (slotWidgets.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: slotWidgets,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 2 — JSON-native defineMatrixLayout
// ──────────────────────────────────────────────────────────────────────────────

/// JSON schema accepted by [QuantumVMJsonDslExtension.defineMatrixLayout]:
///
/// ```json
/// {
///   "type": "layout",      // optional, ignored
///   "name": "AppShell",    // required — plugin type name
///   "gap":  8,             // optional (default 0)
///   "matrix": "...",       // ASCII grid string (default breakpoint)
///
///   // Per-breakpoint overrides (sm / md / lg / xl)
///   "sm": "...",
///   "md": "...",
///   "lg": "...",
///   "xl": "...",
///
///   // Named variants (e.g. dark, compact, mobile)
///   "variants": {
///     "mobile": "...",
///     "tablet": "..."
///   },
///
///   // Per-slot config
///   "slots": {
///     "nav":    { "scrollable": false, "floating": false, "zIndex": 10, "padding": 8, "align": "stretch" },
///     "main":   { "scrollable": true  },
///     "footer": { "zIndex": 5 }
///   }
/// }
/// ```
extension QuantumVMJsonDslExtension on QuantumVM {
  /// Define a matrix layout from a plain JSON/Map object.
  ///
  /// This is the zero-boilerplate alternative to the builder-based
  /// [defineMatrixLayout] that already exists on [QuantumVM].
  /// Both methods produce identical [QMatrixLayoutDef] objects and share the
  /// same compiled-slot hash-map cache.
  ///
  /// Subsequent calls with identical JSON fingerprints are O(1) no-ops.
  void defineMatrixLayoutJson(Map<String, dynamic> json) {
    final int fingerprint = QLStableHasher.of(json);

    if (_QLayoutJsonRegistry._has(fingerprint)) return;

    final String name = (json['name'] ?? json['id'] ?? '').toString().trim();
    if (name.isEmpty) {
      throw ArgumentError(
          '[defineMatrixLayoutJson] JSON must have a non-empty "name" field.');
    }

    final Map<String, dynamic> j = Map.unmodifiable(json);
    final Map<String, dynamic> defaultProps = _extractDefaultProps(
      j['defaultProps'] ?? j['props'],
    );
    final Map<String, dynamic> paramSchema = <String, dynamic>{
      'type': 'object',
      'properties': {
        for (final entry in defaultProps.entries)
          entry.key: QJsonPresetEngine._schemaForValue(entry.value),
      },
      'required': defaultProps.keys.toList(growable: false),
      'slotNames': QJsonPresetEngine._extractSlotNames(j['slots']),
      'variantNames': (j['variants'] is Map)
          ? (j['variants'] as Map)
              .keys
              .map((e) => e.toString())
              .toList(growable: false)
          : const <String>[],
    };
    final Map<String, dynamic> infoSchema = <String, dynamic>{
      'name': name,
      'kind': 'layout',
      'description': (j['description'] ?? j['summary'] ?? 'Matrix layout $name')
          .toString(),
      'gap': j['gap'] ?? 0,
      'slotNames': QJsonPresetEngine._extractSlotNames(j['slots']),
      'variantNames': (j['variants'] is Map)
          ? (j['variants'] as Map)
              .keys
              .map((e) => e.toString())
              .toList(growable: false)
          : const <String>[],
      'defaultPropsKeys': defaultProps.keys.toList(growable: false),
    };

    _QLayoutJsonRegistry._register(fingerprint, name);

    defineMatrixLayout(
      name,
      (b) {
        b.defaultGap = _toDouble(j['gap'], 0.0);

        final String dm =
            (j['matrix'] ?? j['grid'] ?? j['ascii'] ?? '').toString();
        if (dm.isNotEmpty) b.matrix(dm);

        for (final bp in ['sm', 'md', 'lg', 'xl']) {
          final v = j[bp];
          if (v is String && v.isNotEmpty) b.breakpoint(bp, v);
        }

        final dynamic rv = j['variants'];
        if (rv is Map) {
          rv.forEach((vN, vG) {
            if (vG is String && vG.isNotEmpty) b.variant(vN.toString(), vG);
            if (vG is Map) {
              vG.forEach((bp, grid) {
                if (grid is String && grid.isNotEmpty) {
                  b.variantBreakpoint(vN.toString(), bp.toString(), grid);
                }
              });
            }
          });
        }

        final dynamic rs = j['slots'];
        if (rs is Map) {
          rs.forEach((sN, sC) {
            if (sC is Map) {
              b.slot(
                sN.toString(),
                scrollable: _toBool(sC['scrollable'], false),
                floating: _toBool(sC['floating'], false),
                preserveOverlap: _toBool(sC['preserveOverlap'], false),
                draggable: _toBool(sC['draggable'], false),
                resizable: _toBool(sC['resizable'], false),
                reorderable: _toBool(sC['reorderable'], false),
                align: (sC['align'] ?? 'stretch').toString(),
                zIndex: _toInt(sC['zIndex'], 0),
                padding: _toDouble(sC['padding'], 0.0),
                margin: _toDouble(sC['margin'], 0.0),
                useHero: _toBool(sC['useHero'], false),
                heroTag: sC['heroTag'],
                resizeHandle: _parseResizeHandle(sC['resizeHandle']),
              );
            }
          });
        }
      },
      defaultProps: defaultProps,
      description: (j['description'] ?? j['summary'] ?? 'Matrix layout $name')
          .toString(),
      params: {
        'gap': j['gap'] ?? 0,
        'matrix': j['matrix'] ?? j['grid'] ?? j['ascii'] ?? '',
        'variants': j['variants'] ?? const {},
        'slots': j['slots'] ?? const {},
        'defaultProps': defaultProps,
      },
      metadata: {
        'source': 'json',
        'name': name,
        'description': j['description'] ?? j['summary'] ?? '',
        'paramSchema': paramSchema,
        'infoSchema': infoSchema,
      },
      tags: QJsonPresetEngine._extractTags(j['tags']),
    );

    if (kDebugMode) {
      final rawSlots = j['slots'];
      debugPrint('✅ [QLayout] Registered matrix layout "$name" '
          '(gap: ${j['gap'] ?? 0}, '
          'slots: ${rawSlots is Map ? rawSlots.keys.join(", ") : "none"})');
    }
  }
  // ── Coercion helpers ───────────────────────────────────────────────────────

  static double _toDouble(dynamic v, double def) {
    if (v == null) return def;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? def;
  }

  static int _toInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? def;
  }

  static bool _toBool(dynamic v, bool def) {
    if (v == null) return def;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return def;
  }
}

/// Internal fingerprint registry — prevents double compilation.
String _extractName(Map<String, dynamic> json) {
  return (json['alias'] ?? json['name'] ?? json['key'] ?? json['id'] ?? '')
      .toString()
      .trim();
}

Map<String, dynamic> _extractDefaultProps(dynamic raw) {
  if (raw is! Map) return const <String, dynamic>{};
  final Map<String, dynamic> out = <String, dynamic>{};
  raw.forEach((k, v) {
    out[k.toString()] = v;
  });
  return out;
}

QMatrixResizeHandle _parseResizeHandle(dynamic raw) {
  final s = raw?.toString().toLowerCase() ?? '';
  switch (s) {
    case 'topleft':
    case 'top_left':
      return QMatrixResizeHandle.topLeft;
    case 'topright':
    case 'top_right':
      return QMatrixResizeHandle.topRight;
    case 'bottomleft':
    case 'bottom_left':
      return QMatrixResizeHandle.bottomLeft;
    case 'bottomright':
    case 'bottom_right':
      return QMatrixResizeHandle.bottomRight;
    case 'left':
      return QMatrixResizeHandle.left;
    case 'right':
      return QMatrixResizeHandle.right;
    case 'top':
      return QMatrixResizeHandle.top;
    case 'bottom':
      return QMatrixResizeHandle.bottom;
    case 'none':
    default:
      return QMatrixResizeHandle.none;
  }
}

abstract final class _QLayoutJsonRegistry {
  static final Map<int, String> _fingerprints = {};

  static bool _has(int fingerprint) => _fingerprints.containsKey(fingerprint);

  static void _register(int fingerprint, String name) {
    _fingerprints[fingerprint] = name;
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 3 — Batch define (convenience)
// ──────────────────────────────────────────────────────────────────────────────

/// Call once at app start to define all templates AND layouts from a single
/// mixed list.  Each entry must have a `"type"` field:
///
///   * `"template"` → forwarded to [QJsonPresetEngine.define]
///   * `"layout"` → forwarded to [QuantumVM.defineMatrixLayoutJson]
///
/// Any other value is silently ignored (useful for forward-compatibility).
///
/// ```dart
/// QJsonDSL.defineAll([
///   { "type": "template", "name": "Card", "props": {...}, "ui": {...} },
///   { "type": "layout",   "name": "AppShell", "matrix": "...", ... },
/// ]);
/// ```
abstract final class QJsonDSL {
  /// Register all templates and layouts from [definitions].
  static void defineAll(List<Map<String, dynamic>> definitions) {
    for (final def in definitions) {
      final String t = (def['type'] ?? '').toString().toLowerCase();
      switch (t) {
        case 'template':
          QJsonPresetEngine.define(def);
          break;
        case 'layout':
          QuantumVM.instance.defineMatrixLayoutJson(def);
          break;
        case 'decoration':
          QuantumVM.instance.defineDecorationJson(def);
          break;
        default:
          // Auto-detect: if it has "matrix" or "grid", treat as layout.
          // If it has "ui" or "template", treat as template.
          if (def.containsKey('matrix') ||
              def.containsKey('grid') ||
              def.containsKey('ascii')) {
            QuantumVM.instance.defineMatrixLayoutJson(def);
          } else if (def.containsKey('ui') ||
              def.containsKey('template') ||
              def.containsKey('view')) {
            QJsonPresetEngine.define(def);
          } else if (def.containsKey('target')) {
            QuantumVM.instance.defineDecorationJson(def);
          }
      }
    }
  }

  /// Convenience: define a single entry (auto-detects type).
  /// Supports full registry objects with `aliases`, `template(s)`, and `layout(s)`.
  static void define(Map<String, dynamic> json) {
    if (json.containsKey('aliases') ||
        json.containsKey('alias') ||
        json.containsKey('templates') ||
        json.containsKey('template') ||
        json.containsKey('layouts') ||
        json.containsKey('layout') ||
        json.containsKey('decorations') ||
        json.containsKey('decoration') ||
        json.containsKey('target') ||
        json.containsKey('box') ||
        json.containsKey('action') ||
        json.containsKey('field') ||
        json.containsKey('text') ||
        json.containsKey('media') ||
        json.containsKey('data') ||
        json.containsKey('portal') ||
        json.containsKey('control') ||
        json.containsKey('canvas') ||
        json.containsKey('system') ||
        json.containsKey('design_system') ||
        json.containsKey('designSystem') ||
        json.containsKey('manifest') ||
        json.containsKey('components') ||
        json.containsKey('component') ||
        json.containsKey('workflows') ||
        json.containsKey('workflow') ||
        json.containsKey('stateMachines') ||
        json.containsKey('state_machine') ||
        json.containsKey('routes') ||
        json.containsKey('route') ||
        json.containsKey('packs') ||
        json.containsKey('pack')) {
      QuantumVM.instance.defineOmniRegistryJson(json);
      return;
    }
    defineAll([json]);
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION 4 — QuantumVMMicroPlugin extension for JSON-native template define
// ──────────────────────────────────────────────────────────────────────────────

/// Adds [QJsonPresetEngine.define] as a first-class method on [QuantumVM] itself,
/// matching the existing [QuantumVMMicroPlugin] API style.
extension QuantumVMTemplateJsonExtension on QuantumVM {
  /// Define a template via JSON — identical to [QJsonPresetEngine.define].
  ///
  /// ```dart
  /// QuantumVM.instance.definePreset({
  ///   "name": "ProfileCard",
  ///   "props": { "name": "", "avatarUrl": "" },
  ///   "slots": ["header", "body"],
  ///   "ui": {
  ///     "type": "col",
  ///     "children": [
  ///       { "type": "avatar", "props": { "url": "{{avatarUrl}}" } },
  ///       { "type": "text",   "props": { "value": "{{name}}" } }
  ///     ]
  ///   }
  /// });
  /// ```
  void definePreset(Map<String, dynamic> json) =>
      QJsonPresetEngine.define(json);

  /// Batch-define templates and/or layouts in one call.
  void defineAllJson(List<Map<String, dynamic>> definitions) =>
      QJsonDSL.defineAll(definitions);

  void defineAliasJson(Map<String, dynamic> json) {
    final String alias = _extractName(json);
    final String target =
        (json['target'] ?? json['type'] ?? '').toString().trim();
    if (alias.isEmpty || target.isEmpty) {
      throw ArgumentError(
          '[defineAliasJson] JSON must contain non-empty "alias"/"name" and "target"/"type" fields.');
    }
    defineAlias(alias, target,
        defaultProps:
            _extractDefaultProps(json['defaultProps'] ?? json['props']));
  }

  void defineAliasesJson(Map<String, dynamic> aliases) {
    for (final entry in aliases.entries) {
      final dynamic value = entry.value;
      if (value is String) {
        defineAlias(entry.key.toString(), value);
        continue;
      }
      if (value is Map) {
        final Map<String, dynamic> json =
            Map<String, dynamic>.from(value.cast<String, dynamic>());
        json.putIfAbsent('alias', () => entry.key.toString());
        defineAliasJson(json);
      }
    }
  }

  void defineOmniRegistryJson(Map<String, dynamic> json) {
    final dynamic designSystem =
        json['design_system'] ?? json['designSystem'] ?? json['manifest'];
    if (designSystem is Map) {
      QuantumVM.instance.installDesignSystemManifest(
        Map<String, dynamic>.from(designSystem.cast<String, dynamic>()),
        manifestId: json['id']?.toString() ?? json['name']?.toString(),
      );
    }

    final dynamic aliasSection = json['aliases'] ?? json['alias'];
    if (aliasSection is Map) {
      defineAliasesJson(aliasSection.cast<String, dynamic>());
    }

    final dynamic componentSection = json['components'] ?? json['component'];
    if (componentSection is Map) {
      for (final entry in componentSection.entries) {
        final dynamic value = entry.value;
        if (value is String) {
          defineAlias(entry.key.toString(), value);
          continue;
        }
        if (value is Map) {
          final Map<String, dynamic> c =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          c.putIfAbsent('name', () => entry.key.toString());
          final dynamic target = c['target'] ?? c['type'];
          if (target is String && target.isNotEmpty) {
            defineAliasJson(c);
          }
        }
      }
    }

    for (final core in const [
      'box',
      'action',
      'field',
      'text',
      'media',
      'data',
      'portal',
      'control',
      'canvas',
      'system',
      'decoration',
      'chart',
    ]) {
      final dynamic coreSection = json[core];
      if (coreSection is Map) {
        for (final entry in coreSection.entries) {
          final dynamic value = entry.value;
          if (value is String) {
            defineAlias(entry.key.toString(), value);
          } else if (value is Map) {
            final Map<String, dynamic> nested =
                Map<String, dynamic>.from(value.cast<String, dynamic>());
            nested.putIfAbsent('alias', () => entry.key.toString());
            nested.putIfAbsent('target', () => '$core:${entry.key}');
            defineAliasJson(nested);
          }
        }
      }
    }

    final dynamic templateSection = json['templates'] ?? json['template'];
    if (templateSection is Map) {
      for (final entry in templateSection.entries) {
        final dynamic value = entry.value;
        if (value is Map) {
          final Map<String, dynamic> t =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          t.putIfAbsent('name', () => entry.key.toString());
          QJsonPresetEngine.define(t);
        }
      }
    }

    final dynamic layoutSection = json['layouts'] ?? json['layout'];
    if (layoutSection is Map) {
      for (final entry in layoutSection.entries) {
        final dynamic value = entry.value;
        if (value is Map) {
          final Map<String, dynamic> l =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          l.putIfAbsent('name', () => entry.key.toString());
          defineMatrixLayoutJson(l);
        }
      }
    }

    final dynamic decorationSection = json['decorations'] ?? json['decoration'];
    if (decorationSection is Map) {
      for (final entry in decorationSection.entries) {
        final dynamic value = entry.value;
        if (value is String) {
          QuantumVM.instance.defineAlias(entry.key.toString(), value);
          continue;
        }
        if (value is Map) {
          final Map<String, dynamic> d =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          d.putIfAbsent('alias', () => entry.key.toString());
          defineDecorationJson(d);
        }
      }
    }

    final dynamic chartSection = json['charts'] ?? json['chart'];
    if (chartSection is Map) {
      for (final entry in chartSection.entries) {
        final dynamic value = entry.value;
        if (value is String) {
          QuantumVM.instance.defineAlias(entry.key.toString(), value);
          continue;
        }
        if (value is Map) {
          final Map<String, dynamic> c =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          c.putIfAbsent('alias', () => entry.key.toString());
          c.putIfAbsent('target', () => 'media:chart');
          c.putIfAbsent(
              'defaultProps', () => {'chartType': entry.key.toString()});
          defineAliasJson(c);
        }
      }
    }
  }

  /// Define a reusable decoration alias or decoration family from JSON.
  ///
  /// Supported keys:
  /// - `alias` / `name`: alias name.
  /// - `target` / `type`: target core path like `decoration:text`.
  /// - `defaultProps` / `props`: default prop set applied automatically.
  ///
  /// If you want multiple decorations at once, use
  /// `defineOmniRegistryJson({... 'decorations': {...} ...})`.
  void defineDecorationJson(Map<String, dynamic> json) {
    final String alias = _extractName(json);
    final String target = (json['target'] ?? json['type'] ?? 'decoration:merge')
        .toString()
        .trim();
    if (alias.isEmpty || target.isEmpty) {
      throw ArgumentError(
          '[defineDecorationJson] JSON must contain non-empty "alias"/"name" and "target"/"type" fields.');
    }
    QuantumVM.instance.defineAlias(
      alias,
      target,
      defaultProps: _extractDefaultProps(json['defaultProps'] ?? json['props']),
    );
  }

  /// Registers the SDUI-level plugins that allow defining templates and layouts
  /// dynamically directly from the JSON UI tree.
  /// Node types registered: `define_template`, `define_layout`, `define_all`.
  void registerJsonDslPlugins() {
    define('define_template', (ctx) {
      QJsonPresetEngine.define(ctx.node.props);
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });

    define('define_layout', (ctx) {
      defineMatrixLayoutJson(ctx.node.props);
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });

    define('define_alias', (ctx) {
      defineAliasJson(ctx.node.props);
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });

    define('define_decoration', (ctx) {
      defineDecorationJson(ctx.node.props);
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });

    define('define_omni', (ctx) {
      defineOmniRegistryJson(ctx.node.props);
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });

    define('define_design_system', (ctx) {
      final raw = Map<String, dynamic>.from(ctx.node.props);
      final dynamic designSystem =
          raw['design_system'] ?? raw['designSystem'] ?? raw['manifest'] ?? raw;
      if (designSystem is Map) {
        QuantumVM.instance.installDesignSystemManifest(
          Map<String, dynamic>.from(designSystem.cast<String, dynamic>()),
          manifestId: raw['id']?.toString() ?? raw['name']?.toString(),
        );
      }
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });

    define('define_all', (ctx) {
      final definitions = ctx.list('definitions');
      QJsonDSL.defineAll(definitions.cast<Map<String, dynamic>>());
      final children = ctx.children;
      if (children.isEmpty) return const SizedBox.shrink();
      if (children.length == 1) return children.first;
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    });
  }
}
