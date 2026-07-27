import 'dart:collection';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:quantum_layout/quantum.dart';
// Moved from quantum_omni_registry.dart: template feature

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  HYBRID AOT TEMPLATE ENGINE (THE OMEGA COMPILER)
// ────────────────────────────────────────────────────────────────────────────

/// Internal raw descriptor stored before lazy inheritance resolution.
class _PendingTemplateDef {
  final String alias;
  final List<String>? layout;
  final Map<String, dynamic> defaultSlots;
  final Map<String, String> guards;
  final Map<String, dynamic> transforms;
  final Map<String, dynamic> hero;
  final Map<String, Map<String, dynamic>> variants;
  final Map<String, dynamic> initialState;
  final QNativeTemplateBuilder? nativeBuilder;
  final String? extendsAlias;
  final bool mergeWithBase;

  const _PendingTemplateDef({
    required this.alias,
    this.layout,
    required this.defaultSlots,
    required this.guards,
    required this.transforms,
    required this.hero,
    required this.variants,
    required this.initialState,
    this.nativeBuilder,
    this.extendsAlias,
    required this.mergeWithBase,
  });
}

abstract final class QTemplateEngine {
  /// Fully resolved, cached template definitions (keyed by alias.hashCode).
  static final Map<int, TemplateDef> _registry = <int, TemplateDef>{};

  /// Raw definitions waiting for lazy inheritance resolution.
  static final Map<int, _PendingTemplateDef> _pending =
      <int, _PendingTemplateDef>{};
  static final Map<int, String> _aliasNames = <int, String>{};

  /// Guards against circular inheritance chains during resolution.
  static final Set<int> _resolving = <int>{};
  static bool _frozen = false;

  static void freeze() => _frozen = true;
  static void unfreeze() => _frozen = false;

  static void clear() {
    if (_frozen) return;
    _registry.clear();
    _pending.clear();
    _aliasNames.clear();
    _resolving.clear();
  }

  /// O(1) check — triggers lazy resolution if needed.
  @pragma('vm:prefer-inline')
  static bool hasDef(String alias) => getDef(alias) != null;

  /// O(1) hot-path lookup after the first call.  On first call for a given
  /// alias the full inheritance chain is resolved, merged, and permanently
  /// cached — so subsequent calls are a single int-keyed HashMap read.
  static TemplateDef? getDef(String alias) {
    final int key = alias.hashCode;
    final TemplateDef? cached = _registry[key];
    if (cached != null) return cached;

    final _PendingTemplateDef? pending = _pending[key];
    if (pending == null) return null;

    // Cycle detection: if we are already in the middle of resolving this alias
    // (e.g. A extends B extends A) just return null for the circular parent.
    if (_resolving.contains(key)) return null;
    _resolving.add(key);

    try {
      // Recursively resolve base first so the full chain is ready.
      final TemplateDef? base = (pending.extendsAlias != null &&
              pending.extendsAlias!.trim().isNotEmpty)
          ? getDef(pending.extendsAlias!.trim())
          : null;

      final Map<String, dynamic> mergedDefaultSlots = pending.mergeWithBase
          ? _deepMergeMap(base?.defaultSlots, pending.defaultSlots)
          : Map<String, dynamic>.from(pending.defaultSlots);

      final Map<String, String> mergedGuards = pending.mergeWithBase
          ? _mergeStringMap(base?.guards, pending.guards)
          : Map<String, String>.from(pending.guards);

      final Map<String, dynamic> mergedTransforms = pending.mergeWithBase
          ? _deepMergeMap(base?.transforms, pending.transforms)
          : Map<String, dynamic>.from(pending.transforms);

      final Map<String, dynamic> mergedHero = pending.mergeWithBase
          ? _deepMergeMap(base?.hero, pending.hero)
          : Map<String, dynamic>.from(pending.hero);

      final Map<String, Map<String, dynamic>> mergedVariants =
          pending.mergeWithBase
              ? _deepMergeVariantMap(base?.variants, pending.variants)
              : _cloneVariantMap(pending.variants);

      final Map<String, dynamic> mergedInitialState = pending.mergeWithBase
          ? _deepMergeMap(base?.initialState, pending.initialState)
          : Map<String, dynamic>.from(pending.initialState);

      final QNativeTemplateBuilder? resolvedNativeBuilder =
          pending.nativeBuilder ??
              (pending.mergeWithBase ? base?.nativeBuilder : null);

      Int32List binaryLayout;
      Map<int, String> hashToSlot;
      int maxR = 1;
      int maxC = 1;

      if (pending.layout != null && pending.layout!.isNotEmpty) {
        final compiled = _compileLayout(pending.layout!);
        binaryLayout = compiled.binaryLayout;
        hashToSlot = compiled.hashToSlot;
        maxR = compiled.maxR;
        maxC = compiled.maxC;
      } else if (pending.mergeWithBase && base != null) {
        binaryLayout = base.binaryLayout;
        hashToSlot = base.hashToSlot;
        maxR = base.maxR;
        maxC = base.maxC;
      } else {
        binaryLayout = Int32List(0);
        hashToSlot = <int, String>{};
      }

      final TemplateDef resolved = TemplateDef(
        alias: pending.alias,
        binaryLayout: binaryLayout,
        hashToSlot: hashToSlot,
        guards: mergedGuards,
        transforms: mergedTransforms,
        hero: mergedHero,
        variants: mergedVariants,
        defaultSlots: mergedDefaultSlots,
        initialState: mergedInitialState,
        maxR: maxR,
        maxC: maxC,
        nativeBuilder: resolvedNativeBuilder,
      );

      // Promote from pending → resolved cache, and remove from pending.
      _registry[key] = resolved;
      _pending.remove(key);
      return resolved;
    } finally {
      _resolving.remove(key);
    }
  }

  @pragma('vm:prefer-inline')
  static String? aliasOf(String alias) => _aliasNames[alias.hashCode];

  static List<String> aliases() => _aliasNames.values.toList(growable: false);

  static void defineMany(
    Map<String, Map<String, dynamic>> defs, {
    Map<String, QNativeTemplateBuilder>? nativeBuilders,
  }) {
    for (final entry in defs.entries) {
      final config = Map<String, dynamic>.from(entry.value);
      define(
        entry.key,
        layout: (config['layout'] as List?)?.map((e) => e.toString()).toList(),
        defaultSlots:
            (config['defaultSlots'] as Map?)?.cast<String, dynamic>() ??
                const {},
        guards: (config['guards'] as Map?)?.cast<String, String>() ?? const {},
        transforms:
            (config['transforms'] as Map?)?.cast<String, dynamic>() ?? const {},
        hero: (config['hero'] as Map?)?.cast<String, dynamic>() ?? const {},
        variants: (config['variants'] as Map?)
                ?.cast<String, Map<String, dynamic>>() ??
            const {},
        initialState:
            (config['initialState'] as Map?)?.cast<String, dynamic>() ??
                const {},
        nativeBuilder: nativeBuilders?[entry.key],
        extendsAlias: config['extends']?.toString(),
        mergeWithBase: config['mergeWithBase'] != false,
      );
    }
  }

  static void define(
    String alias, {
    List<String>? layout,
    Map<String, dynamic> defaultSlots = const {},
    Map<String, String> guards = const {},
    Map<String, dynamic> transforms = const {},
    Map<String, dynamic> hero = const {},
    Map<String, Map<String, dynamic>> variants = const {},
    Map<String, dynamic> initialState = const {},
    QNativeTemplateBuilder? nativeBuilder,
    String? extendsAlias,
    bool mergeWithBase = true,
  }) {
    if (_frozen) {
      throw StateError('QTemplateEngine is frozen. Call unfreeze() first.');
    }

    final String key = alias.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(alias, 'alias', 'Alias cannot be empty.');
    }

    // Store raw args for lazy resolution — do NOT merge now.
    // Inheritance chain is resolved on the first getDef() call.
    _pending[key.hashCode] = _PendingTemplateDef(
      alias: key,
      layout: layout,
      defaultSlots: defaultSlots,
      guards: guards,
      transforms: transforms,
      hero: hero,
      variants: variants,
      initialState: initialState,
      nativeBuilder: nativeBuilder,
      extendsAlias: extendsAlias,
      mergeWithBase: mergeWithBase,
    );
    // Remove any stale resolved entry so getDef() re-resolves fresh.
    _registry.remove(key.hashCode);
    _aliasNames[key.hashCode] = key;
  }

  static void defineVariant(
    String alias,
    String variantName,
    Map<String, Map<String, dynamic>> variantMap,
  ) {
    final def = getDef(alias);
    if (def == null) return;
    final next = _cloneVariantMap(def.variants);
    next[variantName] = _deepMergeVariantSlotMap(next[variantName], variantMap);
    _registry[alias.hashCode] = TemplateDef(
      alias: def.alias,
      binaryLayout: def.binaryLayout,
      hashToSlot: def.hashToSlot,
      guards: def.guards,
      transforms: def.transforms,
      hero: def.hero,
      variants: next,
      defaultSlots: def.defaultSlots,
      initialState: def.initialState,
      maxR: def.maxR,
      maxC: def.maxC,
      nativeBuilder: def.nativeBuilder,
    );
  }

  static void defineSlot(
    String alias,
    String slotName, {
    Map<String, dynamic>? defaultJson,
    dynamic transform,
    String? guard,
    dynamic hero,
  }) {
    final def = getDef(alias);
    if (def == null) return;

    final mergedDefaults = Map<String, dynamic>.from(def.defaultSlots);
    if (defaultJson != null) mergedDefaults[slotName] = defaultJson;

    final mergedTransforms = Map<String, dynamic>.from(def.transforms);
    if (transform != null) mergedTransforms[slotName] = transform;

    final mergedGuards = Map<String, String>.from(def.guards);
    if (guard != null) mergedGuards[slotName] = guard;

    final mergedHero = Map<String, dynamic>.from(def.hero);
    if (hero != null) mergedHero[slotName] = hero;

    _registry[alias.hashCode] = TemplateDef(
      alias: def.alias,
      binaryLayout: def.binaryLayout,
      hashToSlot: def.hashToSlot,
      guards: mergedGuards,
      transforms: mergedTransforms,
      hero: mergedHero,
      variants: def.variants,
      defaultSlots: mergedDefaults,
      initialState: def.initialState,
      maxR: def.maxR,
      maxC: def.maxC,
      nativeBuilder: def.nativeBuilder,
    );
  }

  static void remove(String alias) {
    if (_frozen) return;
    _registry.remove(alias.hashCode);
    _aliasNames.remove(alias.hashCode);
  }

  static _LayoutCompileResult _compileLayout(List<String> layout) {
    final Map<String, _GridRect> rects = <String, _GridRect>{};
    int maxR = 1;
    int maxC = 1;

    for (int r = 0; r < layout.length; r++) {
      final cols = layout[r]
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .toList(growable: false);

      for (int c = 0; c < cols.length; c++) {
        final slot = cols[c];
        if (slot == '.') continue;

        final int rr = r + 1;
        final int cc = c + 1;

        final rect = rects[slot];
        if (rect == null) {
          rects[slot] = _GridRect(rr, cc, rr, cc);
        } else {
          if (rr > rect.maxR) rect.maxR = rr;
          if (cc > rect.maxC) rect.maxC = cc;
        }

        if (rr > maxR) maxR = rr;
        if (cc > maxC) maxC = cc;
      }
    }

    final Int32List binaryLayout = Int32List(rects.length * 2);
    final Map<int, String> hashToSlot = <int, String>{};

    int i = 0;
    rects.forEach((slot, rect) {
      final int rSpan = rect.maxR - rect.minR + 1;
      final int cSpan = rect.maxC - rect.minC + 1;
      final int hash = slot.hashCode;

      hashToSlot[hash] = slot;
      binaryLayout[i++] = hash;
      binaryLayout[i++] =
          (rect.minR << 24) | (rect.minC << 16) | (rSpan << 8) | cSpan;
    });

    return _LayoutCompileResult(
      binaryLayout: binaryLayout,
      hashToSlot: hashToSlot,
      maxR: maxR,
      maxC: maxC,
    );
  }

  static Map<String, dynamic> _deepMergeMap(
    Map<String, dynamic>? base,
    Map<String, dynamic> extra,
  ) {
    if (base == null || base.isEmpty) return Map<String, dynamic>.from(extra);
    final out = Map<String, dynamic>.from(base);
    extra.forEach((key, value) {
      final existing = out[key];
      if (existing is Map && value is Map) {
        out[key] = _deepMergeMap(
          Map<String, dynamic>.from(existing.cast<String, dynamic>()),
          Map<String, dynamic>.from(value.cast<String, dynamic>()),
        );
      } else if (existing is List && value is List) {
        out[key] = List<dynamic>.from(value);
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  static Map<String, String> _mergeStringMap(
    Map<String, String>? base,
    Map<String, String> extra,
  ) {
    if (base == null || base.isEmpty) return Map<String, String>.from(extra);
    final out = Map<String, String>.from(base);
    out.addAll(extra);
    return out;
  }

  static Map<String, Map<String, dynamic>> _cloneVariantMap(
    Map<String, Map<String, dynamic>> variants,
  ) {
    final out = <String, Map<String, dynamic>>{};
    variants.forEach((variantKey, slotMap) {
      out[variantKey] = _deepMergeVariantSlotMap(null, slotMap);
    });
    return out;
  }

  static Map<String, Map<String, dynamic>> _deepMergeVariantMap(
    Map<String, Map<String, dynamic>>? base,
    Map<String, Map<String, dynamic>> extra,
  ) {
    final out = base == null
        ? <String, Map<String, dynamic>>{}
        : _cloneVariantMap(base);
    extra.forEach((variantKey, slotMap) {
      out[variantKey] = _deepMergeVariantSlotMap(out[variantKey], slotMap);
    });
    return out;
  }

  static Map<String, dynamic> _deepMergeVariantSlotMap(
    Map<String, dynamic>? base,
    Map<String, dynamic> extra,
  ) {
    if (base == null || base.isEmpty) return Map<String, dynamic>.from(extra);
    final out = Map<String, dynamic>.from(base);
    extra.forEach((slot, value) {
      final existing = out[slot];
      if (existing is Map && value is Map) {
        out[slot] = _deepMergeMap(
          Map<String, dynamic>.from(existing.cast<String, dynamic>()),
          Map<String, dynamic>.from(value.cast<String, dynamic>()),
        );
      } else {
        out[slot] = value;
      }
    });
    return out;
  }
}

class _LayoutCompileResult {
  final Int32List binaryLayout;
  final Map<int, String> hashToSlot;
  final int maxR;
  final int maxC;

  const _LayoutCompileResult({
    required this.binaryLayout,
    required this.hashToSlot,
    required this.maxR,
    required this.maxC,
  });
}

typedef QNativeTemplateBuilder = Widget Function(QTemplateContext ctx);

class _GridRect {
  int minR, minC, maxR, maxC;
  _GridRect(this.minR, this.minC, this.maxR, this.maxC);
}

class TemplateDef {
  final String alias;
  final Int32List binaryLayout;
  final Map<int, String> hashToSlot; // O(1) Reverse lookup for binary layout
  final Map<String, String> guards;
  final Map<String, dynamic>
      transforms; // String (CSS) or Map (AST Node Override)
  final Map<String, dynamic> hero; // String (Tag) or Map (Config)
  final Map<String, Map<String, dynamic>> variants; // Variant-based overrides
  final Map<String, dynamic> defaultSlots;
  final Map<String, dynamic> initialState; // Local component state
  final QNativeTemplateBuilder? nativeBuilder;
  final int maxR, maxC;

  const TemplateDef({
    required this.alias,
    required this.binaryLayout,
    required this.hashToSlot,
    required this.guards,
    required this.transforms,
    required this.hero,
    required this.variants,
    required this.defaultSlots,
    required this.initialState,
    required this.maxR,
    required this.maxC,
    this.nativeBuilder,
  });
}

/// The God-Mode Context. Unifies Slots, Layouts, Variants, Heroes, and State into a single API.

/// The God-Mode Context. Unifies Slots, Layouts, Variants, Heroes, and State into a single API.
class QTemplateContext {
  final QLContext core;
  final TemplateDef def;
  final String instanceId;

  QTemplateContext(this.core, this.def, this.instanceId);

  BuildContext get context => core.flutterContext;
  QLDataStore get store => core.store;
  Map<String, dynamic> get env => core.env;
  QLBlueprint get node => core.node;

  T prop<T>(String key, {T? fallback}) => core.prop<T>(key, fallback: fallback);
  String string(String key, {String fallback = ''}) =>
      core.string(key, fallback: fallback);
  bool boolean(String key, {bool fallback = false}) =>
      core.boolean(key, fallback: fallback);
  int integer(String key, {int fallback = 0}) =>
      core.integer(key, fallback: fallback);
  double number(String key, {double fallback = 0.0}) =>
      core.number(key, fallback: fallback);
  List<dynamic> list(String key, {List<dynamic> fallback = const []}) =>
      core.list(key, fallback: fallback);
  Map<K, V> map<K, V>(String key, {Map<K, V> fallback = const {}}) =>
      core.map<K, V>(key, fallback: fallback);
  VoidCallback? action(String eventKey, {Map<String, dynamic>? localPayload}) =>
      core.action(eventKey, localPayload: localPayload);

  dynamic eval(dynamic expr) =>
      QLDataBinder.resolveAOT(expr, context, env, store);

  String stateKey(String key) => '${instanceId}_$key';

  String? resolveSlotName(String name) => name;

  bool checkGuard(String slotName) {
    final resolved = resolveSlotName(slotName) ?? slotName;
    final String? guardExpr = def.guards[resolved];
    if (guardExpr == null) return true;
    final dynamic resolvedValue = eval(guardExpr);
    if (resolvedValue is bool) return resolvedValue;
    if (resolvedValue == 'true' || resolvedValue == '1') return true;
    return core.boolean(guardExpr);
  }

  void _mergeAst(Map<String, dynamic> target, dynamic override) {
    if (override == null) return;
    if (override is String) {
      final existing = target['style'];
      target['style'] = existing == null ? override : '$existing $override';
      return;
    }

    if (override is Map) {
      if (override['type'] != null) target['type'] = override['type'];
      if (override['style'] != null) {
        final existing = target['style'];
        target['style'] = existing == null
            ? override['style']
            : '$existing ${override['style']}';
      }
      if (override['props'] is Map) {
        target['props'] ??= <String, dynamic>{};
        (target['props'] as Map).addAll(override['props']);
      }
      if (override['children'] is List) {
        target['children'] = override['children'];
      }
      if (override['slots'] is Map) {
        target['slots'] ??= <String, dynamic>{};
        (target['slots'] as Map).addAll(override['slots']);
      }
    }
  }

  Widget? slot(
    String name, {
    String? nativeType,
    Map<String, dynamic>? nativeProps,
    List<QLBlueprint>? nativeChildren,
    Widget? nativeWidgetOverride,
  }) {
    final Widget built = buildSlot(
      name,
      nativeType: nativeType,
      nativeProps: nativeProps,
      nativeChildren: nativeChildren,
      nativeWidgetOverride: nativeWidgetOverride,
    );
    return built is SizedBox && built.width == 0.0 && built.height == 0.0
        ? null
        : built;
  }

  Widget buildSlot(
    String name, {
    String? nativeType,
    Map<String, dynamic>? nativeProps,
    List<QLBlueprint>? nativeChildren,
    Widget? nativeWidgetOverride,
  }) {
    final resolvedName = resolveSlotName(name) ?? name;
    if (!checkGuard(resolvedName)) return const SizedBox.shrink();
    if (nativeWidgetOverride != null) {
      final Map<String, dynamic> tAst = {};
      _mergeAst(tAst, def.transforms[resolvedName]);
      if (tAst['style'] != null) {
        return Q(
          tAst['style'].toString(),
          suppressParentData: true,
          children: [nativeWidgetOverride],
        );
      }
      return nativeWidgetOverride;
    }

    final QLBlueprint? userSlot =
        core.node.slots[resolvedName] ?? core.node.slots[name];
    final Map<String, dynamic>? defaultJson =
        def.defaultSlots[resolvedName] ?? def.defaultSlots[name];

    if (userSlot == null &&
        defaultJson == null &&
        nativeChildren == null &&
        nativeType == null) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> ast = {
      'type': 'box:col',
      'props': <String, dynamic>{},
      'children': <QLBlueprint>[],
    };

    if (defaultJson != null) _mergeAst(ast, defaultJson);
    _mergeAst(ast, def.transforms[resolvedName] ?? def.transforms[name]);

    def.variants.forEach((variantKey, variantConfig) {
      final currentVariantValue = string(variantKey);
      if (currentVariantValue.isNotEmpty &&
          variantConfig.containsKey(currentVariantValue)) {
        final variantOverrides = variantConfig[currentVariantValue];
        if (variantOverrides is Map &&
            variantOverrides.containsKey(resolvedName)) {
          _mergeAst(ast, variantOverrides[resolvedName]);
        } else if (variantOverrides is Map &&
            variantOverrides.containsKey(name)) {
          _mergeAst(ast, variantOverrides[name]);
        }
      }
    });

    if (userSlot != null) {
      if (userSlot.type != 'empty' && userSlot.type != 'override') {
        ast['type'] = userSlot.props.containsKey('__subType')
            ? '${userSlot.type}:${userSlot.props['__subType']}'
            : userSlot.type;
      }
      (ast['props'] as Map).addAll(userSlot.props);
      if (userSlot.style != null && userSlot.style!.isNotEmpty) {
        ast['style'] = ast['style'] == null
            ? userSlot.style
            : '${ast['style']} ${userSlot.style}';
      }
      if (userSlot.children.isNotEmpty) ast['children'] = userSlot.children;
      if (userSlot.slots.isNotEmpty) ast['slots'] = userSlot.slots;
    }

    if (nativeType != null) ast['type'] = nativeType;
    if (nativeProps != null) (ast['props'] as Map).addAll(nativeProps);
    if (nativeChildren != null) ast['children'] = nativeChildren;

    final aliasDef = QuantumVM.instance.getAlias(ast['type']);
    if (aliasDef != null) {
      ast['type'] = aliasDef['type'];
      final defaultProps =
          Map<String, dynamic>.from(aliasDef['props'] as Map? ?? {});
      defaultProps
          .forEach((k, v) => (ast['props'] as Map).putIfAbsent(k, () => v));
    }

    final colonParts = ast['type'].toString().split(':');
    ast['type'] = colonParts[0];
    if (colonParts.length > 1) {
      (ast['props'] as Map)['__subType'] = colonParts[1];
    }

    final QLBlueprint merged = QLBlueprint(
      type: ast['type'],
      props: ast['props'],
      style: ast['style'],
      children: ast['children'],
      slots: userSlot?.slots ?? const {},
      debugPath: '${core.node.debugPath}.$resolvedName',
    );

    Widget rendered = QuantumVM.instance.renderWidget(context, merged);

    final heroConf = def.hero[resolvedName] ?? def.hero[name];
    if (heroConf != null) {
      String tag = '';
      bool enabled = true;
      String flight = '';
      if (heroConf is String) {
        tag = eval(heroConf)?.toString() ?? '';
      } else if (heroConf is Map) {
        tag = eval(heroConf['tag'])?.toString() ?? '';
        final dynamic enabledRaw = eval(heroConf['enabled']);
        enabled = enabledRaw == null ? true : enabledRaw == true;
        flight = eval(heroConf['flight'])?.toString() ?? '';
      }
      if (tag.isNotEmpty && enabled) {
        rendered = Hero(
          tag: tag,
          flightShuttleBuilder: flight == 'fade'
              ? (flightContext, animation, flightDirection, fromHeroContext,
                  toHeroContext) {
                  return FadeTransition(
                    opacity:
                        animation.drive(Tween<double>(begin: 0.0, end: 1.0)),
                    child: toHeroContext.widget,
                  );
                }
              : null,
          child: rendered,
        );
      }
    }

    return rendered;
  }

  Widget buildLayout({Map<String, Widget>? nativeSlotOverrides}) {
    if (def.binaryLayout.isEmpty) {
      final Set<String> activeSlots = {
        ...def.defaultSlots.keys,
        ...core.node.slots.keys
      };
      return Q(
        'col w-full',
        children: activeSlots.map((s) {
          final override = nativeSlotOverrides?[s];
          return override != null
              ? override // FIX: Use override directly. Prevents double-box wrapping!
              : buildSlot(s);
        }).toList(growable: false),
      );
    }

    final List<Widget> gridChildren = <Widget>[];
    final layout = def.binaryLayout;

    for (int i = 0; i < layout.length; i += 2) {
      final int hash = layout[i];
      final int packed = layout[i + 1];

      final int minR = (packed >> 24) & 0xFF;
      final int minC = (packed >> 16) & 0xFF;
      final int rSpan = (packed >> 8) & 0xFF;
      final int cSpan = packed & 0xFF;

      final String? slotName = def.hashToSlot[hash];
      if (slotName != null) {
        final Widget child = nativeSlotOverrides != null &&
                nativeSlotOverrides.containsKey(slotName)
            ? nativeSlotOverrides[
                slotName]! // FIX: Use override directly. Prevents double-box wrapping!
            : buildSlot(slotName);

        if (child is! SizedBox) {
          gridChildren.add(
            QuantumItem(
              rowStart: minR,
              rowEnd: minR + rSpan,
              colStart: minC,
              colEnd: minC + cSpan,
              child: child,
            ),
          );
        }
      }
    }

    return QuantumGrid(
      rows: core.string('gridRows', fallback: 'repeat(${def.maxR}, auto)'),
      columns: core.string('gridCols', fallback: 'repeat(${def.maxC}, 1fr)'),
      columnGap: core.number('gap', fallback: 0),
      rowGap: core.number('gap', fallback: 0),
      children: gridChildren,
    );
  }
}
