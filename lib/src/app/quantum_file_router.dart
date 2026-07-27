// ════════════════════════════════════════════════════════════════════════════
// QUANTUM FILE ROUTER v1.0 — NEXT.JS-STYLE FILE-BASED ROUTING
// quantum_file_router.dart
//
// FEATURES:
// 1. Auto-discovers YAML/JSON pages from the Flutter asset manifest
// 2. [param] → :param dynamic segment
// 3. [...slug] → wildcard catch-all
// 4. _layout.yaml → wraps all sibling routes in a layout
// 5. _middleware.yaml → applies guards/middleware to all siblings
// 6. _meta.yaml → default SEO/props for directory
// 7. Per-file URL regex override via `urlPattern:` field
// 8. Runtime route injection (addRoute / removeRoute)
// 9. File-priority ordering: explicit ROUTES.yaml > file-based > default
// 10. O(1) cache: resolved QLRoute list cached by asset manifest hash
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../quantum.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  ROUTE ENTRY — Describes a discovered file-based route
// ────────────────────────────────────────────────────────────────────────────

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
    this.layoutAssetPath,
    this.inheritedMiddlewares = const [],
    this.inheritedMeta = const {},
  });
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  FILE ROUTE PARSER — filename → route pattern
// ────────────────────────────────────────────────────────────────────────────

abstract final class QLFileRouteParser {
  // Files that are framework config — NEVER treated as routes
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

  /// Convert an asset path like `pages/users/[id]/posts/[postId].yaml`
  /// into a route pattern `/users/:id/posts/:postId`.
  static QLFileRouteEntry? parse(String assetPath, String pagesDir) {
    // Strip leading pagesDir
    String relative = assetPath;
    final prefix = pagesDir.endsWith('/') ? pagesDir : '$pagesDir/';
    if (!relative.startsWith(prefix)) return null;
    relative = relative.substring(prefix.length);

    // Strip extension
    final lastDot = relative.lastIndexOf('.');
    final String noExt =
        lastDot != -1 ? relative.substring(0, lastDot) : relative;

    // Split into segments
    final List<String> segments = noExt.split('/');
    if (segments.isEmpty) return null;

    final String filename = segments.last;

    // Skip reserved uppercase config files
    if (_reservedUppercase.contains(filename.toUpperCase()) &&
        filename == filename.toUpperCase()) {
      return null;
    }

    // Skip special underscore files (layout, middleware, meta, etc.)
    if (_specialFiles.contains(filename)) return null;

    // Build route path
    final List<String> routeSegments = [];
    final List<String> paramNames = [];
    bool isCatchAll = false;

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final bool isLast = i == segments.length - 1;

      if (seg.startsWith('[...') && seg.endsWith(']')) {
        // Catch-all: [...slug] → *
        final paramName = seg.substring(4, seg.length - 1);
        paramNames.add(paramName);
        isCatchAll = true;
        routeSegments.add('*');
      } else if (seg.startsWith('[') && seg.endsWith(']')) {
        // Dynamic: [id] → :id
        final paramName = seg.substring(1, seg.length - 1);
        paramNames.add(paramName);
        routeSegments.add(':$paramName');
      } else if (isLast && (seg == 'index' || seg == 'INDEX')) {
        // index.yaml → parent route (no extra segment)
        // Already handled: routeSegments stays as parent path
      } else {
        routeSegments.add(seg);
      }
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

  /// Check whether a path segment file is a special directory file.
  static bool isSpecial(String filename) => _specialFiles.contains(filename);

  /// Check whether an asset is a page file (not config, not special).
  static bool isPageFile(String assetPath, String pagesDir) {
    final parsed = parse(assetPath, pagesDir);
    return parsed != null;
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  FILE ROUTER — scans asset manifest and builds QLRoute list
// ────────────────────────────────────────────────────────────────────────────

class QuantumFileRouter {
  static final QuantumFileRouter instance = QuantumFileRouter._();
  QuantumFileRouter._();

  // Cached route list — invalidated when asset manifest hash changes
  List<QLRoute>? _cachedRoutes;
  int _manifestHash = 0;

  // Lazy page config cache — loaded only when the route is used.
  final Map<String, QLPageYamlConfig> _pageConfigCache = {};
  final Map<String, Future<QLPageYamlConfig?>> _pageConfigInFlight = {};

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
      entries.add(_enrichEntry(entry, dirTree, pagesDir));
      if ((++parsed & 0x3f) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    entries.sort(_compareEntries);

    final List<QLRoute> fileRoutes = [];
    int built = 0;
    for (final entry in entries) {
      final route = await _buildRoute(entry, loadingWidget: loadingWidget);
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
    _pageConfigCache.clear();
    _pageConfigInFlight.clear();
  }

  // ── Internal Helpers ───────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loadAssetManifest() async {
    try {
      // 🚀 THE FIX: Flutter 3.16+ modern AssetManifest API
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
        // Fallback for older Flutter versions
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
      Map<String, dynamic> manifest, String pagesDir) async {
    final tree = _DirTree();

    // Find all _layout, _middleware, _meta files
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
      }
    }

    return tree;
  }

  QLFileRouteEntry _enrichEntry(
      QLFileRouteEntry entry, _DirTree tree, String pagesDir) {
    final String dir =
        entry.assetPath.substring(0, entry.assetPath.lastIndexOf('/'));

    // 🚀 FIX 1: Safely extract relative path regardless of trailing slashes
    String relativeDir = dir;
    if (relativeDir.startsWith(pagesDir)) {
      relativeDir = relativeDir.substring(pagesDir.length);
    }
    if (relativeDir.startsWith('/')) relativeDir = relativeDir.substring(1);

    final parts = relativeDir.split('/').where((s) => s.isNotEmpty).toList();

    String? layoutAssetPath;
    final List<Map<String, dynamic>> middlewares = [];
    final Map<String, dynamic> meta = {};

    String currentDir = pagesDir;
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

    return QLFileRouteEntry(
      assetPath: entry.assetPath,
      routePath: entry.routePath,
      isCatchAll: entry.isCatchAll,
      paramNames: entry.paramNames,
      urlPatternOverride: entry.urlPatternOverride,
      layoutAssetPath: layoutAssetPath,
      inheritedMiddlewares: middlewares,
      inheritedMeta: meta,
    );
  }

  int _compareEntries(QLFileRouteEntry a, QLFileRouteEntry b) {
    // Catch-all routes always last
    if (a.isCatchAll && !b.isCatchAll) return 1;
    if (!a.isCatchAll && b.isCatchAll) return -1;
    // More specific (fewer params) first
    final aParams = a.paramNames.length;
    final bParams = b.paramNames.length;
    if (aParams != bParams) return aParams - bParams;
    // Alphabetical
    return a.routePath.compareTo(b.routePath);
  }

  Future<QLRoute?> _buildRoute(
    QLFileRouteEntry entry, {
    Widget? loadingWidget,
  }) async {
    final String routePath = entry.routePath;

    final List<QLMiddleware> middlewares = [
      ...entry.inheritedMiddlewares.map(_mapToMiddleware),
      _LazyPagePolicyMiddleware(
        entry.assetPath,
        loader: _loadPageConfigCached,
      ),
    ];

    final QLSeoBuilder? seoBuilder = (info, props) {
      final cached = _pageConfigCache[entry.assetPath];
      final Map<String, dynamic> inheritedMeta = entry.inheritedMeta;
      final String title =
          cached?.metaTitle ?? inheritedMeta['title']?.toString() ?? '';
      final String description = cached?.metaDescription ??
          inheritedMeta['description']?.toString() ??
          '';
      if (title.isEmpty &&
          description.isEmpty &&
          inheritedMeta.isEmpty &&
          cached == null) {
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
        keywords: cached?.metaKeywords ?? inheritedMeta['keywords']?.toString(),
        ogImage: cached?.metaOgImage ?? inheritedMeta['ogImage']?.toString(),
        customMeta: {...cached?.customMeta ?? const {}},
      );
    };

    QLDataFetchCallback? serverPropsFn;
    serverPropsFn = (info) async {
      final pageConfig = await _loadPageConfigCached(entry.assetPath);
      final Map<String, dynamic> result = {};
      final spConfig = pageConfig?.serverProps;
      if (spConfig != null && spConfig.isNotEmpty) {
        final action = spConfig['action']?.toString();
        if (action != null && action.isNotEmpty) {
          result['__serverProps'] = spConfig;
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
          loadingWidget: loadingWidget,
        );

    return QLRoute(
      path: routePath,
      builder: builder,
      middlewares: middlewares,
      transition: QLTransitionType.slideRight,
      transitionDuration: const Duration(milliseconds: 380),
      seo: seoBuilder,
      getServerSideProps: serverPropsFn,
    );
  }

  Future<QLPageYamlConfig?> _loadPageConfigCached(String assetPath) async {
    final cached = _pageConfigCache[assetPath];
    if (cached != null) return cached;
    final inflight = _pageConfigInFlight[assetPath];
    if (inflight != null) return inflight;

    final future = () async {
      try {
        final raw = await QuantumYamlEngine.instance.load(assetPath);
        final pageConfig = QLPageYamlConfig.fromMap(raw);
        _pageConfigCache[assetPath] = pageConfig;
        return pageConfig;
      } catch (e) {
        debugPrint('[QuantumFileRouter] Failed to lazy-load $assetPath: $e');
        return null;
      }
    }();

    _pageConfigInFlight[assetPath] = future;
    try {
      return await future;
    } finally {
      _pageConfigInFlight.remove(assetPath);
    }
  }

  QLMiddleware _mapToMiddleware(Map<String, dynamic> def) {
    return _YamlMiddleware(def);
  }

  QLTransitionType _parseTransition(String name) {
    return switch (name.toLowerCase()) {
      'fade' => QLTransitionType.fade,
      'scale' => QLTransitionType.scale,
      'slideleft' || 'slide_left' => QLTransitionType.slideLeft,
      'slideup' || 'slide_up' => QLTransitionType.slideUp,
      'slidedown' || 'slide_down' => QLTransitionType.slideDown,
      'flip3d' || 'flip' => QLTransitionType.flip3D,
      'none' => QLTransitionType.none,
      _ => QLTransitionType.slideRight,
    };
  }

  String _interpolateSeo(
      String template, QLRouteInfo info, Map<String, dynamic> props) {
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
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  DIRECTORY TREE HELPER
// ────────────────────────────────────────────────────────────────────────────

class _DirTree {
  final Map<String, String> layouts = {};
  final Map<String, Map<String, dynamic>> middlewares = {};
  final Map<String, Map<String, dynamic>> metas = {};
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  LAZY PAGE POLICY MIDDLEWARE
// ────────────────────────────────────────────────────────────────────────────

class _LazyPagePolicyMiddleware extends QLMiddleware {
  final String assetPath;
  final Future<QLPageYamlConfig?> Function(String assetPath) loader;

  _LazyPagePolicyMiddleware(this.assetPath, {required this.loader});

  @override
  FutureOr<QLRouteInfo?> process(
      QLRouteInfo info, BuildContext? context) async {
    final pageConfig = await loader(assetPath);
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
      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  YAML MIDDLEWARE ADAPTER
// ────────────────────────────────────────────────────────────────────────────

class _YamlMiddleware extends QLMiddleware {
  final Map<String, dynamic> def;
  const _YamlMiddleware(this.def);

  @override
  FutureOr<QLRouteInfo?> process(
      QLRouteInfo info, BuildContext? context) async {
    // YAML middleware can declare:
    //   type: redirect | guard | inject
    //   condition: <store path or action>
    //   redirect: <path>
    //   inject: <Map to merge into props>
    final String type = def['type']?.toString() ?? 'passthrough';

    switch (type) {
      case 'redirect':
        final String? cond = def['condition']?.toString();
        if (cond != null) {
          // Check condition against store
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

      default:
        return null;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  FILE ROUTE VIEW WIDGET — renders a YAML page at runtime
// ────────────────────────────────────────────────────────────────────────────

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
  bool _error = false;
  String _errorMsg = '';

  // 🚀 ADD THIS: Safe Hot Reload Hook
  @override
  void reassemble() {
    super.reassemble();
    // 1. Kick the file out of Flutter's internal bundle cache
    rootBundle.evict(widget.pageAssetPath);
    if (widget.layoutAssetPath != null) {
      rootBundle.evict(widget.layoutAssetPath!);
    }

    // 2. Clear Quantum's RAM so it reads the new YAML
    QuantumYamlEngine.instance.clearCaches();
    QuantumFileRouter.instance.invalidateCache();
    QuantumVM.instance.clearRuntimeCaches();

    // 3. Re-draw safely
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
        oldWidget.routeInfo != widget.routeInfo) {
      _compile();
    }
  }

  Future<void> _compile() async {
    try {
      // Load page YAML
      final Map<String, dynamic> raw =
          await QuantumYamlEngine.instance.load(widget.pageAssetPath);
      final QLPageYamlConfig pageCfg = QLPageYamlConfig.fromMap(raw);

      // Register page-level macros, schemas, state
      if (pageCfg.macros.isNotEmpty) applyYamlMacros(pageCfg.macros);
      if (pageCfg.schemas.isNotEmpty) applyYamlSchemas(pageCfg.schemas);
      if (pageCfg.state.isNotEmpty) {
        QLStoreRegistry.instance
            .get(raw['module']?.toString() ?? 'default')
            .merge(pageCfg.state);
      }

      // Register page-level pipelines
      if (pageCfg.pipelines.isNotEmpty) {
        await QuantumDataOrchestrator.bootstrap(
            {'pipelines': pageCfg.pipelines}, context);
      }

      // Build compile env
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
      };

      // All macros (including page-local)
      final Map<String, dynamic> allMacros = {
        ...QLModuleRegistry.instance.macrosFor('default'),
        ...pageCfg.macros,
      };

      // Compile page UI
      final dynamic uiNode = pageCfg.ui ?? raw['ui'] ?? raw;
      final QLBlueprint pageAst =
          await QLCompiler.compileAsync(uiNode, allMacros, compileEnv);

      // Compile layout if present
      QLBlueprint? layoutAst;
      if (widget.layoutAssetPath != null) {
        final Map<String, dynamic> layoutRaw =
            await QuantumYamlEngine.instance.load(widget.layoutAssetPath!);
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
        });
      }
    } catch (e, st) {
      debugPrint(
          '[QuantumFileRouter] Compile error for ${widget.pageAssetPath}: $e\n$st');
      if (mounted)
        setState(() {
          _error = true;
          _errorMsg = e.toString();
        });
    }
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
                      decoration: TextDecoration.none),
                ),
              ),
            )
          : const SizedBox.shrink();
    }

    if (_pageAst == null) {
      return widget.loadingWidget ?? const SizedBox.shrink();
    }

    Widget pageWidget = QLDataScope(
      moduleStore: QLStoreRegistry.instance
          .get(_pageConfig?['module']?.toString() ?? 'default'),
      localData: {
        r'$route': {
          'path': widget.routeInfo.path,
          'param': widget.routeInfo.params,
          'query': widget.routeInfo.queryParams,
          'props': widget.routeInfo.props,
        },
      },
      // 🚀 FIX 1: Wrap in Builder so the VM reads the localData we just created!
      child: Builder(
          builder: (c) => QuantumVM.instance.renderWidget(c, _pageAst!)),
    );

    // Wrap in layout if present
    if (_layoutAst != null) {
      pageWidget = QLDataScope(
        moduleStore: QLStoreRegistry.instance.get('default'),
        localData: {
          r'$page': pageWidget,
          r'$route': {
            'path': widget.routeInfo.path,
            'param': widget.routeInfo.params,
          },
        },
        // 🚀 FIX 1: Wrap in Builder here too!
        child: Builder(
            builder: (c) => QuantumVM.instance.renderWidget(c, _layoutAst!)),
      );
    }

    return pageWidget;
  }
}
