// ════════════════════════════════════════════════════════════════════════════
// QUANTUM FILE ROUTER v2.0 — PAGE-AWARE / NESTED / LAYOUT-DRIVEN
// quantum_file_router.dart
//
// Goals:
//   • Next.js-style file routing, but page-aware and layout-aware
//   • Nested pages via folder structure + route groups
//   • Per-page route/layout overrides from page manifest
//   • Lazy page config loading
//   • Inherited _layout / _middleware / _meta support
//   • Stable route caching by asset manifest hash
//   • Minimal runtime work: parse once, compile page on demand
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../quantum.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — ROUTE ENTRY
// ─────────────────────────────────────────────────────────────────────────────

/// Internal record describing one discovered page file.
@immutable
class QLFileRouteEntry {
  /// The asset path, e.g. `pages/users/[id].yaml`
  final String assetPath;

  /// The resolved route pattern, e.g. `/users/:id`
  final String routePath;

  /// Whether this is a catch-all (`[...slug]`)
  final bool isCatchAll;

  /// Named capture groups in order (from `[param]` segments).
  final List<String> paramNames;

  /// If set, overrides the radix-trie match with regex matching.
  final String? urlPatternOverride;

  /// Page-level route override from page config, e.g. `/dashboard/home`.
  final String? routePathOverride;

  /// Layout file asset path for this route (if any).
  final String? layoutAssetPath;

  /// Middleware list (from `_middleware.yaml` in parent dirs).
  final List<Map<String, dynamic>> inheritedMiddlewares;

  /// Default meta from `_meta.yaml` in parent dirs.
  final Map<String, dynamic> inheritedMeta;

  const QLFileRouteEntry({
    required this.assetPath,
    required this.routePath,
    this.isCatchAll = false,
    this.paramNames = const [],
    this.urlPatternOverride,
    this.routePathOverride,
    this.layoutAssetPath,
    this.inheritedMiddlewares = const [],
    this.inheritedMeta = const {},
  });

  QLFileRouteEntry copyWith({
    String? routePath,
    bool? isCatchAll,
    List<String>? paramNames,
    String? urlPatternOverride,
    String? routePathOverride,
    String? layoutAssetPath,
    List<Map<String, dynamic>>? inheritedMiddlewares,
    Map<String, dynamic>? inheritedMeta,
  }) {
    return QLFileRouteEntry(
      assetPath: assetPath,
      routePath: routePath ?? this.routePath,
      isCatchAll: isCatchAll ?? this.isCatchAll,
      paramNames: paramNames ?? this.paramNames,
      urlPatternOverride: urlPatternOverride ?? this.urlPatternOverride,
      routePathOverride: routePathOverride ?? this.routePathOverride,
      layoutAssetPath: layoutAssetPath ?? this.layoutAssetPath,
      inheritedMiddlewares: inheritedMiddlewares ?? this.inheritedMiddlewares,
      inheritedMeta: inheritedMeta ?? this.inheritedMeta,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — FILE ROUTE PARSER
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QLFileRouteParser {
  // Files that are framework config — NEVER treated as routes.
  static const Set<String> _reservedUppercase = {
    'APP',
    'THEME',
    'ROUTES',
    'DOMAINS',
    'PIPES',
    'ACTIONS',
    'MACROS',
    'SCHEMAS',
    'GUARDS',
    'SDUI',
    'ENV',
  };

  // Directory-level special files
  static const Set<String> _specialFiles = {
    '_layout',
    '_middleware',
    '_meta',
    '_error',
    '_loading',
  };

  static bool isSpecial(String filename) => _specialFiles.contains(filename);

  static bool isPageFile(String assetPath, String pagesDir) {
    final parsed = parse(assetPath, pagesDir);
    return parsed != null;
  }

  /// Convert asset path like `pages/users/[id]/page.yaml`
  /// into a route pattern `/users/:id`.
  ///
  /// Supported leaf files:
  ///   • `index.yaml` / `page.yaml` → folder route
  ///   • `[id].yaml` → `:id`
  ///   • `[...slug].yaml` → `*`
  /// Route groups like `(marketing)` are ignored in the route path.
  static QLFileRouteEntry? parse(String assetPath, String pagesDir) {
    String relative = assetPath;
    final prefix = pagesDir.endsWith('/') ? pagesDir : '$pagesDir/';
    if (!relative.startsWith(prefix)) return null;
    relative = relative.substring(prefix.length);

    final lastDot = relative.lastIndexOf('.');
    final String noExt =
        lastDot != -1 ? relative.substring(0, lastDot) : relative;

    final List<String> segments = noExt.split('/');
    if (segments.isEmpty) return null;

    final String filename = segments.last;

    // Skip reserved uppercase config files.
    if (_reservedUppercase.contains(filename.toUpperCase()) &&
        filename == filename.toUpperCase()) {
      return null;
    }

    // Skip special underscore files.
    if (_specialFiles.contains(filename)) return null;

    final List<String> routeSegments = [];
    final List<String> paramNames = [];
    bool isCatchAll = false;

    for (int i = 0; i < segments.length; i++) {
      final String seg = segments[i];
      final bool isLast = i == segments.length - 1;

      // Ignore route groups like (marketing), (auth), etc.
      if (seg.startsWith('(') && seg.endsWith(')')) continue;

      if (seg.startsWith('[...') && seg.endsWith(']')) {
        final paramName = seg.substring(4, seg.length - 1);
        paramNames.add(paramName);
        isCatchAll = true;
        routeSegments.add('*');
        continue;
      }

      if (seg.startsWith('[') && seg.endsWith(']')) {
        final paramName = seg.substring(1, seg.length - 1);
        paramNames.add(paramName);
        routeSegments.add(':$paramName');
        continue;
      }

      // index.yaml/page.yaml map to parent route
      if (isLast &&
          (seg == 'index' ||
              seg == 'INDEX' ||
              seg == 'page' ||
              seg == 'PAGE' ||
              seg == 'route' ||
              seg == 'ROUTE')) {
        continue;
      }

      routeSegments.add(seg);
    }

    final String routePath =
        routeSegments.isEmpty ? '/' : '/${routeSegments.join('/')}';

    return QLFileRouteEntry(
      assetPath: assetPath,
      routePath: routePath,
      isCatchAll: isCatchAll,
      paramNames: paramNames,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — PAGE LOAD RECORD
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class _PageLoadRecord {
  final Map<String, dynamic> raw;
  final QLPageYamlConfig config;

  const _PageLoadRecord({
    required this.raw,
    required this.config,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — FILE ROUTER
// ─────────────────────────────────────────────────────────────────────────────

class QuantumFileRouter {
  static final QuantumFileRouter instance = QuantumFileRouter._();
  QuantumFileRouter._();

  // Cached route list — invalidated when asset manifest hash changes
  List<QLRoute>? _cachedRoutes;
  int _manifestHash = 0;

  // Lazy page config cache — loaded only when the route is used.
  final Map<String, _PageLoadRecord> _pageLoadCache = {};
  final Map<String, Future<_PageLoadRecord?>> _pageLoadInFlight = {};

  // Runtime-injected routes (highest priority)
  final List<QLRoute> _runtimeRoutes = [];
  List<QLRoute> get runtimeRoutes => List.unmodifiable(_runtimeRoutes);

  // Regex override cache: pattern → compiled RegExp
  final Map<String, RegExp> _regexCache = {};

  /// Load the Flutter asset manifest and return it as a plain map.
  Future<Map<String, dynamic>> loadAssetManifest() => _loadAssetManifest();

  /// Scan the Flutter asset manifest for all files under [pagesDir] and build
  /// a fully-assembled list of [QLRoute] objects.
  ///
  /// Results are cached by manifest hash — subsequent calls cost O(1).
  Future<List<QLRoute>> buildRoutes(
    String pagesDir, {
    List<QLRoute> explicitRoutes = const [],
    Widget? notFoundWidget,
    Widget? loadingWidget,
    bool useCache = true,
  }) async {
    final Map<String, dynamic> manifest = await loadAssetManifest();
    return buildRoutesFromManifest(
      manifest,
      pagesDir,
      explicitRoutes: explicitRoutes,
      notFoundWidget: notFoundWidget,
      loadingWidget: loadingWidget,
      useCache: useCache,
    );
  }

  /// Build routes from an already-loaded asset manifest.
  Future<List<QLRoute>> buildRoutesFromManifest(
    Map<String, dynamic> manifest,
    String pagesDir, {
    List<QLRoute> explicitRoutes = const [],
    Widget? notFoundWidget,
    Widget? loadingWidget,
    bool useCache = true,
  }) async {
    final int manifestHash = Object.hash(manifest.hashCode, pagesDir);

    if (useCache && _cachedRoutes != null && _manifestHash == manifestHash) {
      return [
        ..._runtimeRoutes,
        ...explicitRoutes,
        ..._cachedRoutes!,
      ];
    }

    final String normalDir = pagesDir.endsWith('/') ? pagesDir : '$pagesDir/';
    final List<String> pageAssets = manifest.keys
        .where((k) =>
            k.startsWith(normalDir) &&
            _isSupportedFormat(k) &&
            !_isSpecialFile(k))
        .toList(growable: false);

    final _DirTree dirTree = await _buildDirTree(manifest, normalDir);

    final List<QLFileRouteEntry> entries = [];
    int parsed = 0;
    for (final assetPath in pageAssets) {
      final entry = QLFileRouteParser.parse(assetPath, pagesDir);
      if (entry == null) continue;

      final loaded = await _loadPageLoadCached(assetPath);
      final merged = _applyPageOverrides(entry, loaded?.raw, dirTree);
      entries.add(merged);

      if ((++parsed & 0x3f) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    entries.sort(_compareEntries);

    final List<QLRoute> fileRoutes = [];
    int built = 0;
    for (final entry in entries) {
      final route = await _buildRoute(
        entry,
        loadingWidget: loadingWidget,
        notFoundWidget: notFoundWidget,
      );
      if (route != null) fileRoutes.add(route);
      if ((++built & 0x1f) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    _cachedRoutes = fileRoutes;
    _manifestHash = manifestHash;

    return [
      ..._runtimeRoutes,
      ...explicitRoutes,
      ...fileRoutes,
    ];
  }

  /// Inject a route at runtime (e.g. from native Dart code).
  /// Runtime routes take precedence over file-based routes.
  void addRoute(QLRoute route) {
    _runtimeRoutes.removeWhere((r) => r.path == route.path);
    _runtimeRoutes.add(route);
  }

  /// Remove a runtime-injected route.
  void removeRoute(String path) {
    _runtimeRoutes.removeWhere((r) => r.path == path);
  }

  /// Invalidate the route cache (call after hot-reload or asset change).
  void invalidateCache() {
    _cachedRoutes = null;
    _manifestHash = 0;
    _pageLoadCache.clear();
    _pageLoadInFlight.clear();
    _regexCache.clear();
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loadAssetManifest() async {
    try {
      final AssetManifest manifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> assets = manifest.listAssets();
      final Map<String, dynamic> map = {};
      for (final asset in assets) {
        map[asset] = true;
      }
      return map;
    } catch (_) {
      try {
        final String manifestStr =
            await rootBundle.loadString('AssetManifest.json');
        return Map<String, dynamic>.from(jsonDecode(manifestStr) as Map);
      } catch (_) {
        return const <String, dynamic>{};
      }
    }
  }

  bool _isSupportedFormat(String path) {
    return path.endsWith('.yaml') ||
        path.endsWith('.yml') ||
        path.endsWith('.json');
  }

  bool _isSpecialFile(String path) {
    final filename = path.split('/').last.split('.').first;
    return QLFileRouteParser._specialFiles.contains(filename) ||
        (filename == filename.toUpperCase() &&
            QLFileRouteParser._reservedUppercase
                .contains(filename.toUpperCase()));
  }

  Future<_DirTree> _buildDirTree(
    Map<String, dynamic> manifest,
    String pagesDir,
  ) async {
    final tree = _DirTree()..pagesDir = pagesDir;

    for (final path in manifest.keys) {
      if (!path.startsWith(pagesDir)) continue;

      final filename = path.split('/').last.split('.').first;
      final dir = path.substring(0, path.lastIndexOf('/'));

      if (filename == '_layout') {
        tree.layouts[dir] = path;
      } else if (filename == '_middleware') {
        final raw = await QuantumYamlEngine.instance.load(path);
        tree.middlewares[dir] = raw;
      } else if (filename == '_meta') {
        final raw = await QuantumYamlEngine.instance.load(path);
        tree.metas[dir] = raw;
      } else if (filename == '_page' || filename == '_route') {
        tree.pageManifests[dir] = path;
      }
    }

    return tree;
  }

  QLFileRouteEntry _applyPageOverrides(
    QLFileRouteEntry entry,
    Map<String, dynamic>? raw,
    _DirTree tree,
  ) {
    final dir = entry.assetPath.substring(0, entry.assetPath.lastIndexOf('/'));

    String relativeDir = dir;
    final String normalizedPagesDir = tree.pagesDir;
    if (relativeDir.startsWith(normalizedPagesDir)) {
      relativeDir = relativeDir.substring(normalizedPagesDir.length);
    }
    if (relativeDir.startsWith('/')) relativeDir = relativeDir.substring(1);

    final parts = relativeDir.split('/').where((s) => s.isNotEmpty).toList();

    String? layoutAssetPath;
    final List<Map<String, dynamic>> middlewares = [];
    final Map<String, dynamic> meta = {};

    String currentDir = normalizedPagesDir;
    for (final part in ['', ...parts]) {
      if (part.isNotEmpty) currentDir = '$currentDir/$part';

      if (tree.layouts.containsKey(currentDir) && layoutAssetPath == null) {
        layoutAssetPath = tree.layouts[currentDir];
      }
      if (tree.middlewares.containsKey(currentDir)) {
        final m = tree.middlewares[currentDir]!;
        if (m['middlewares'] is List) {
          for (final mw in m['middlewares'] as List) {
            if (mw is Map) middlewares.add(Map<String, dynamic>.from(mw));
          }
        }
      }
      if (tree.metas.containsKey(currentDir)) {
        meta.addAll(tree.metas[currentDir]!);
      }
    }

    final String? routeOverride = _extractRouteOverride(raw);
    final String? layoutOverride = _extractLayoutOverride(raw);

    return QLFileRouteEntry(
      assetPath: entry.assetPath,
      routePath: entry.routePath,
      isCatchAll: entry.isCatchAll,
      paramNames: entry.paramNames,
      urlPatternOverride:
          _extractUrlPatternOverride(raw) ?? entry.urlPatternOverride,
      routePathOverride: routeOverride,
      layoutAssetPath:
          layoutOverride ?? layoutAssetPath ?? entry.layoutAssetPath,
      inheritedMiddlewares: [
        ...entry.inheritedMiddlewares,
        ...middlewares,
      ],
      inheritedMeta: {
        ...entry.inheritedMeta,
        ...meta,
        if (raw != null && raw['meta'] is Map)
          ...Map<String, dynamic>.from(raw['meta'] as Map),
      },
    );
  }

  String? _extractRouteOverride(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final dynamic value = raw['route'] ?? raw['path'] ?? raw['routePath'];
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return text;
  }

  String? _extractLayoutOverride(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final dynamic value =
        raw['layout'] ?? raw['layoutPath'] ?? raw['layoutAssetPath'];
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return text;
  }

  String? _extractUrlPatternOverride(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final dynamic value = raw['urlPattern'] ?? raw['pattern'] ?? raw['regex'];
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return text;
  }

  int _compareEntries(QLFileRouteEntry a, QLFileRouteEntry b) {
    if (a.isCatchAll && !b.isCatchAll) return 1;
    if (!a.isCatchAll && b.isCatchAll) return -1;

    final aParams = a.paramNames.length;
    final bParams = b.paramNames.length;
    if (aParams != bParams) return aParams - bParams;

    return a.effectiveRoutePath.compareTo(b.effectiveRoutePath);
  }

  Future<QLRoute?> _buildRoute(
    QLFileRouteEntry entry, {
    Widget? loadingWidget,
    Widget? notFoundWidget,
  }) async {
    final _PageLoadRecord? pageLoad =
        await _loadPageLoadCached(entry.assetPath);
    final Map<String, dynamic> raw = pageLoad?.raw ?? const {};
    final QLPageYamlConfig? pageConfig = pageLoad?.config;

    final String routePath =
        (entry.routePathOverride ?? entry.effectiveRoutePath).trim();

    final List<QLMiddleware> middlewares = [
      ...entry.inheritedMiddlewares.map(_mapToMiddleware),
      _LazyPagePolicyMiddleware(
        entry.assetPath,
        loader: _loadPageLoadCached,
      ),
    ];

    final QLSeoBuilder? seoBuilder = (info, props) {
      final Map<String, dynamic> inheritedMeta = entry.inheritedMeta;
      final String title = _coerceText(
        raw['metaTitle'] ??
            pageConfig?.metaTitle ??
            inheritedMeta['title'] ??
            '',
      );
      final String description = _coerceText(
        raw['metaDescription'] ??
            pageConfig?.metaDescription ??
            inheritedMeta['description'] ??
            '',
      );

      if (title.isEmpty &&
          description.isEmpty &&
          inheritedMeta.isEmpty &&
          pageConfig == null) {
        return QLSeoConfig(
          title: '',
          description: '',
          keywords: null,
          ogImage: null,
          customMeta: const {},
        );
      }

      return QLSeoConfig(
        title: _interpolateSeo(title, info, props),
        description: _interpolateSeo(description, info, props),
        keywords: _coerceText(
          raw['metaKeywords'] ??
              pageConfig?.metaKeywords ??
              inheritedMeta['keywords'],
        ),
        ogImage: _coerceText(
          raw['metaOgImage'] ??
              pageConfig?.metaOgImage ??
              inheritedMeta['ogImage'],
        ),
        customMeta: {
          ..._mapStringDynamic(raw['meta'] ?? const {}),
          ...(pageConfig?.customMeta ?? const {}),
        },
      );
    };

    QLDataFetchCallback? serverPropsFn;
    serverPropsFn = (info) async {
      final _PageLoadRecord? loaded =
          await _loadPageLoadCached(entry.assetPath);
      final pageConfigLocal = loaded?.config;
      final Map<String, dynamic> result = {};
      final spConfig =
          loaded?.raw['serverProps'] ?? pageConfigLocal?.serverProps;
      if (spConfig is Map && spConfig.isNotEmpty) {
        final action = spConfig['action']?.toString();
        if (action != null && action.isNotEmpty) {
          result['__serverProps'] = Map<String, dynamic>.from(spConfig);
          result['__routeInfo'] = {
            'params': info.params,
            'query': info.queryParams,
          };
        }
      }
      return result;
    };

    final QLWidgetBuilder builder = (context, info) => _QLFileRouteView(
          pageAssetPath: entry.assetPath,
          layoutAssetPath: entry.layoutAssetPath,
          routeInfo: info,
          loadingWidget: loadingWidget ?? notFoundWidget,
        );

    return QLRoute(
      path: routePath,
      builder: builder,
      middlewares: middlewares,
      transition: _parseTransition(
        _coerceText(
            raw['transition'] ?? pageConfig?.transition ?? 'slideRight'),
      ),
      transitionDuration: Duration(
        milliseconds: _coerceInt(
          raw['transitionDuration'] ?? pageConfig?.transitionDurationMs ?? 380,
          fallback: 380,
        ),
      ),
      seo: seoBuilder,
      getServerSideProps: serverPropsFn,
    );
  }

  Future<_PageLoadRecord?> _loadPageLoadCached(String assetPath) async {
    final cached = _pageLoadCache[assetPath];
    if (cached != null) return cached;

    final inflight = _pageLoadInFlight[assetPath];
    if (inflight != null) return inflight;

    final future = () async {
      try {
        final raw = await QuantumYamlEngine.instance.load(assetPath);
        final config = QLPageYamlConfig.fromMap(raw);
        final record = _PageLoadRecord(raw: raw, config: config);
        _pageLoadCache[assetPath] = record;
        return record;
      } catch (e, st) {
        debugPrint(
            '[QuantumFileRouter] Failed to lazy-load $assetPath: $e\n$st');
        return null;
      }
    }();

    _pageLoadInFlight[assetPath] = future;
    try {
      return await future;
    } finally {
      _pageLoadInFlight.remove(assetPath);
    }
  }

  QLMiddleware _mapToMiddleware(Map<String, dynamic> def) {
    return _YamlMiddleware(def);
  }

  QLTransitionType _parseTransition(String name) {
    switch (name.toLowerCase()) {
      case 'fade':
        return QLTransitionType.fade;
      case 'scale':
        return QLTransitionType.scale;
      case 'slideleft':
      case 'slide_left':
        return QLTransitionType.slideLeft;
      case 'slideup':
      case 'slide_up':
        return QLTransitionType.slideUp;
      case 'slidedown':
      case 'slide_down':
        return QLTransitionType.slideDown;
      case 'flip3d':
      case 'flip':
        return QLTransitionType.flip3D;
      case 'none':
        return QLTransitionType.none;
      default:
        return QLTransitionType.slideRight;
    }
  }

  String _interpolateSeo(
    String template,
    QLRouteInfo info,
    Map<String, dynamic> props,
  ) {
    if (!template.contains('{{')) return template;
    return template.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
      final path = match.group(1)!.trim();
      if (path.startsWith('param.')) {
        return info.params[path.substring(6)] ?? '';
      }
      if (path.startsWith('query.')) {
        return info.queryParams[path.substring(6)] ?? '';
      }
      if (path.startsWith('props.')) {
        return props[path.substring(6)]?.toString() ?? '';
      }
      return props[path]?.toString() ?? '';
    });
  }

  Map<String, dynamic> _mapStringDynamic(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(
        value.map((k, v) => MapEntry(k.toString(), v)),
      );
    }
    return const <String, dynamic>{};
  }

  String _coerceText(dynamic value) => value?.toString().trim() ?? '';

  int _coerceInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

extension on QLFileRouteEntry {
  String get effectiveRoutePath => routePath;
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 — DIRECTORY TREE HELPER
// ─────────────────────────────────────────────────────────────────────────────

class _DirTree {
  final Map<String, String> layouts = {};
  final Map<String, Map<String, dynamic>> middlewares = {};
  final Map<String, Map<String, dynamic>> metas = {};
  final Map<String, String> pageManifests = {};
  String pagesDir = 'pages';
}

// ─────────────────────────────────────────────────────────────────────────────
// §6 — LAZY PAGE POLICY MIDDLEWARE
// ─────────────────────────────────────────────────────────────────────────────

class _LazyPagePolicyMiddleware extends QLMiddleware {
  final String assetPath;
  final Future<_PageLoadRecord?> Function(String assetPath) loader;

  _LazyPagePolicyMiddleware(this.assetPath, {required this.loader});

  @override
  FutureOr<QLRouteInfo?> process(
    QLRouteInfo info,
    BuildContext? context,
  ) async {
    final loaded = await loader(assetPath);
    final pageConfig = loaded?.config;
    if (pageConfig == null) return null;

    for (final guard in pageConfig.guards) {
      final result = await _applyGuard(guard, info, context);
      if (result != null) return result;
    }
    return null;
  }

  FutureOr<QLRouteInfo?> _applyGuard(
    Map<String, dynamic> def,
    QLRouteInfo info,
    BuildContext? context,
  ) async {
    final type = def['type']?.toString() ?? 'passthrough';
    switch (type) {
      case 'redirect':
        final String? cond = def['condition']?.toString();
        if (cond != null) {
          final val = QuantumVM.instance.store.get(cond);
          if (val == null || val == false || val == '' || val == 0) {
            final String to = def['to']?.toString() ?? '/';
            return info.copyWith(path: to);
          }
        }
        return null;
      case 'inject':
        final Map<String, dynamic> extra = def['data'] is Map
            ? Map<String, dynamic>.from(def['data'] as Map)
            : {};
        if (extra.isNotEmpty) {
          return info.copyWith(props: extra);
        }
        return null;
      case 'allow':
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §7 — YAML MIDDLEWARE ADAPTER
// ─────────────────────────────────────────────────────────────────────────────

class _YamlMiddleware extends QLMiddleware {
  final Map<String, dynamic> def;
  const _YamlMiddleware(this.def);

  @override
  FutureOr<QLRouteInfo?> process(
    QLRouteInfo info,
    BuildContext? context,
  ) async {
    final type = def['type']?.toString() ?? 'passthrough';
    switch (type) {
      case 'redirect':
        final String to = def['to']?.toString() ?? '/';
        final String? cond = def['condition']?.toString();
        if (cond == null || cond.isEmpty) {
          return info.copyWith(path: to);
        }
        final val = QuantumVM.instance.store.get(cond);
        if (val == null || val == false || val == '' || val == 0) {
          return info.copyWith(path: to);
        }
        return null;
      case 'inject':
        final Map<String, dynamic> extra = def['data'] is Map
            ? Map<String, dynamic>.from(def['data'] as Map)
            : {};
        if (extra.isNotEmpty) {
          return info.copyWith(props: extra);
        }
        return null;
      case 'block':
        return info.copyWith(path: def['to']?.toString() ?? '/');
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §8 — FILE ROUTE VIEW
// ─────────────────────────────────────────────────────────────────────────────

class _QLFileRouteView extends StatefulWidget {
  final String pageAssetPath;
  final String? layoutAssetPath;
  final QLRouteInfo routeInfo;
  final Widget? loadingWidget;

  const _QLFileRouteView({
    required this.pageAssetPath,
    required this.routeInfo,
    this.layoutAssetPath,
    this.loadingWidget,
  });

  @override
  State<_QLFileRouteView> createState() => _QLFileRouteViewState();
}

class _QLFileRouteViewState extends State<_QLFileRouteView> {
  QLBlueprint? _pageAst;
  QLBlueprint? _layoutAst;
  Map<String, dynamic>? _pageConfig;
  Map<String, dynamic>? _rawPage;
  bool _error = false;
  String _errorMsg = '';

  @override
  void reassemble() {
    super.reassemble();
    rootBundle.evict(widget.pageAssetPath);
    if (widget.layoutAssetPath != null) {
      rootBundle.evict(widget.layoutAssetPath!);
    }

    QuantumYamlEngine.instance.clearCaches();
    QuantumFileRouter.instance.invalidateCache();
    QuantumVM.instance.clearRuntimeCaches();

    _compile();
  }

  @override
  void initState() {
    super.initState();
    _compile();
  }

  @override
  void didUpdateWidget(covariant _QLFileRouteView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageAssetPath != widget.pageAssetPath ||
        oldWidget.routeInfo != widget.routeInfo ||
        oldWidget.layoutAssetPath != widget.layoutAssetPath) {
      _compile();
    }
  }

  Future<void> _compile() async {
    try {
      final _PageLoadRecord pageLoad =
          (await QuantumFileRouter.instance._loadPageLoadCached(
                widget.pageAssetPath,
              )) ??
              _PageLoadRecord(
                raw:
                    await QuantumYamlEngine.instance.load(widget.pageAssetPath),
                config: QLPageYamlConfig.fromMap(
                  await QuantumYamlEngine.instance.load(widget.pageAssetPath),
                ),
              );

      final Map<String, dynamic> raw = pageLoad.raw;
      final QLPageYamlConfig pageCfg = pageLoad.config;
      _rawPage = raw;

      if (pageCfg.macros.isNotEmpty) applyYamlMacros(pageCfg.macros);
      if (pageCfg.schemas.isNotEmpty) applyYamlSchemas(pageCfg.schemas);
      if (pageCfg.state.isNotEmpty) {
        QLStoreRegistry.instance
            .get(raw['module']?.toString() ?? 'default')
            .merge(pageCfg.state);
      }

      if (pageCfg.pipelines.isNotEmpty) {
        await QuantumDataOrchestrator.bootstrap(
          {'pipelines': pageCfg.pipelines},
          context,
        );
      }

      final Map<String, dynamic> compileEnv = {
        ...raw['env'] is Map
            ? Map<String, dynamic>.from(raw['env'] as Map)
            : {},
        r'$route': {
          'path': widget.routeInfo.path,
          'param': widget.routeInfo.params,
          'query': widget.routeInfo.queryParams,
          'props': widget.routeInfo.props,
        },
        r'$page': {
          'path': widget.pageAssetPath,
          'layout': raw['layout'] ??
              raw['layoutPath'] ??
              widget.layoutAssetPath ??
              '',
        },
      };

      final Map<String, dynamic> allMacros = {
        ...QLModuleRegistry.instance.macrosFor('default'),
        ...pageCfg.macros,
      };

      final dynamic uiNode = pageCfg.ui ?? raw['ui'] ?? raw;
      final QLBlueprint pageAst =
          await QLCompiler.compileAsync(uiNode, allMacros, compileEnv);

      QLBlueprint? layoutAst;
      final String? effectiveLayoutPath = _effectiveLayoutPath(raw);
      final String? layoutAssetPath =
          effectiveLayoutPath ?? widget.layoutAssetPath;

      if (layoutAssetPath != null && layoutAssetPath.isNotEmpty) {
        final Map<String, dynamic> layoutRaw =
            await QuantumYamlEngine.instance.load(layoutAssetPath);
        final dynamic layoutUiNode =
            layoutRaw['ui'] ?? layoutRaw['view'] ?? layoutRaw;
        layoutAst =
            await QLCompiler.compileAsync(layoutUiNode, allMacros, compileEnv);
      }

      if (mounted) {
        setState(() {
          _pageAst = pageAst;
          _layoutAst = layoutAst;
          _pageConfig = raw;
          _error = false;
          _errorMsg = '';
        });
      }
    } catch (e, st) {
      debugPrint(
        '[QuantumFileRouter] Compile error for ${widget.pageAssetPath}: $e\n$st',
      );
      if (mounted) {
        setState(() {
          _error = true;
          _errorMsg = e.toString();
        });
      }
    }
  }

  String? _effectiveLayoutPath(Map<String, dynamic> raw) {
    final dynamic value =
        raw['layout'] ?? raw['layoutPath'] ?? raw['layoutAssetPath'];
    final String text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return kDebugMode
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'QuantumFileRouter Error:\n$_errorMsg',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    if (_pageAst == null) {
      return widget.loadingWidget ?? const SizedBox.shrink();
    }

    final String moduleName = _pageConfig?['module']?.toString() ?? 'default';

    Widget pageWidget = QLDataScope(
      moduleStore: QLStoreRegistry.instance.get(moduleName),
      localData: {
        r'$route': {
          'path': widget.routeInfo.path,
          'param': widget.routeInfo.params,
          'query': widget.routeInfo.queryParams,
          'props': widget.routeInfo.props,
        },
        r'$page': {
          'path': widget.pageAssetPath,
          'layout': _effectiveLayoutPath(_rawPage ?? const {}) ??
              widget.layoutAssetPath ??
              '',
        },
      },
      child: Builder(
        builder: (c) => QuantumVM.instance.renderWidget(c, _pageAst!),
      ),
    );

    if (_layoutAst != null) {
      pageWidget = QLDataScope(
        moduleStore: QLStoreRegistry.instance.get('default'),
        localData: {
          r'$page': pageWidget,
          r'$route': {
            'path': widget.routeInfo.path,
            'param': widget.routeInfo.params,
            'query': widget.routeInfo.queryParams,
          },
        },
        child: Builder(
          builder: (c) => QuantumVM.instance.renderWidget(c, _layoutAst!),
        ),
      );
    }

    return pageWidget;
  }
}
