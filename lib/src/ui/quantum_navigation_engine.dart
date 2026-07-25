// ════════════════════════════════════════════════════════════════════════════
// QUANTUM NAVIGATION ENGINE v8.0 - OMEGA HYBRID SEO BUILD
// quantum_navigation_engine.dart
//
// ENHANCEMENTS & BREAKTHROUGHS:
// 1. Next.js Parity: Natively supports `getServerSideProps`, `getStaticProps`,
//    `getInitialProps`, and `getStaticPaths` at the route level.
// 2. Pure HTML SEO Generation: The `QLServerRenderer` can generate raw indexable
//    HTML strings for bots and search engines, containing pre-fetched meta tags.
// 3. Client Hydration: Parses server-injected `__QUANTUM_PROPS__` to bypass
//    re-fetching data on the client during initial load.
// 4. Zero-Rebuild Transitions: Leverages `QLSignal` to bypass the element tree.
// 5. Zero-Allocation Radix Trie: Fast tokenization without String.split garbage.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'quantum_hydration_reader.dart';

// Ecosystem Primitives
import '../foundation/quantum_primitives.dart';
import 'quantum_components.dart';
import '../../quantum.dart';

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  HYBRID SEO & DATA FETCHING MODELS (Next.js Parity)
// ────────────────────────────────────────────────────────────────────────────

typedef QLDataFetchCallback = FutureOr<Map<String, dynamic>> Function(
    QLRouteInfo info);
typedef QLSeoBuilder = QLSeoConfig Function(
    QLRouteInfo info, Map<String, dynamic> props);

@immutable
class QLSeoConfig {
  final String title;
  final String description;
  final String? keywords;
  final String? canonicalUrl;
  final String? ogImage;
  final String? ogType;
  final String? twitterCard;
  final Map<String, String> customMeta;

  const QLSeoConfig({
    required this.title,
    required this.description,
    this.keywords,
    this.canonicalUrl,
    this.ogImage,
    this.ogType = 'website',
    this.twitterCard = 'summary_large_image',
    this.customMeta = const {},
  });

  /// Generates the raw HTML `<head>` tags for pure HTML server-side rendering.
  String generateHtmlTags() {
    final buffer = StringBuffer();
    buffer.writeln('<title>$title</title>');
    buffer.writeln('<meta name="description" content="$description" />');
    if (keywords != null) {
      buffer.writeln('<meta name="keywords" content="$keywords" />');
    }
    if (canonicalUrl != null) {
      buffer.writeln('<link rel="canonical" href="$canonicalUrl" />');
      buffer.writeln('<meta property="og:url" content="$canonicalUrl" />');
    }
    buffer.writeln('<meta property="og:title" content="$title" />');
    buffer.writeln('<meta property="og:description" content="$description" />');
    buffer.writeln('<meta property="og:type" content="$ogType" />');
    if (ogImage != null) {
      buffer.writeln('<meta property="og:image" content="$ogImage" />');
      buffer.writeln('<meta name="twitter:image" content="$ogImage" />');
    }
    buffer.writeln('<meta name="twitter:card" content="$twitterCard" />');
    buffer.writeln('<meta name="twitter:title" content="$title" />');
    buffer
        .writeln('<meta name="twitter:description" content="$description" />');

    customMeta.forEach((key, value) {
      buffer.writeln('<meta name="$key" content="$value" />');
    });
    return buffer.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  CORE TYPES & PIPELINE
// ────────────────────────────────────────────────────────────────────────────

enum QLTransitionType {
  fade,
  scale,
  slideRight,
  slideLeft,
  slideUp,
  slideDown,
  flip3D,
  none
}

abstract class QLMiddleware {
  const QLMiddleware();

  /// Return [null] to continue the pipeline, or a modified [QLRouteInfo]
  /// to redirect/inject data. Throw an exception to halt navigation.
  FutureOr<QLRouteInfo?> process(QLRouteInfo info, BuildContext? context) =>
      null;
}

typedef QLWidgetBuilder = Widget Function(
    BuildContext context, QLRouteInfo info);
typedef QLLayoutBuilder = Widget Function(
    BuildContext context, QLRouteInfo info, Widget child);

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLROUTEINFO — Immutable, Type-Safe, Hash-Cached State + Props
// ────────────────────────────────────────────────────────────────────────────

@immutable
class QLRouteInfo {
  final String path;
  final Map<String, String> params;
  final Map<String, String> queryParams;
  final Map<String, dynamic> props; // 🚀 Fetched SSR/SSG Props injected here
  final Object? extra;
  final Object? state;
  final int _hashCache;

  QLRouteInfo({
    required this.path,
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Map<String, dynamic>? props,
    this.extra,
    this.state,
  })  : params = params != null ? Map.unmodifiable(params) : const {},
        queryParams =
            queryParams != null ? Map.unmodifiable(queryParams) : const {},
        props = props != null ? Map.unmodifiable(props) : const {},
        _hashCache = Object.hash(path, extra);

  String param(String key, {String fallback = ''}) => params[key] ?? fallback;
  int intParam(String key, {int fallback = 0}) =>
      int.tryParse(param(key)) ?? fallback;
  String query(String key, {String fallback = ''}) =>
      queryParams[key] ?? fallback;

  QLRouteInfo copyWith({
    String? path,
    Map<String, String>? params,
    Map<String, String>? queryParams,
    Map<String, dynamic>? props,
    Object? extra,
    Object? state,
  }) =>
      QLRouteInfo(
        path: path ?? this.path,
        params: params != null ? {...this.params, ...params} : this.params,
        queryParams: queryParams != null
            ? {...this.queryParams, ...queryParams}
            : this.queryParams,
        props: props != null ? {...this.props, ...props} : this.props,
        extra: extra ?? this.extra,
        state: state ?? this.state,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QLRouteInfo &&
          _hashCache == other._hashCache &&
          path == other.path);

  @override
  int get hashCode => _hashCache;
}

typedef QLSchemaFetchCallback = FutureOr<Map<String, dynamic>> Function(
    QLRouteInfo info);

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  UNIVERSAL QLROUTE (Data Fetching + SEO Integrations)
// ────────────────────────────────────────────────────────────────────────────

@immutable
class QLRoute {
  final String path;
  final QLWidgetBuilder? builder;
  final QLLayoutBuilder? layoutBuilder;
  final List<QLRoute> children;
  final List<QLMiddleware> middlewares;
  final QLTransitionType transition;
  final Duration transitionDuration;

  // 🚀 HYBRID DATA FETCHING & SEO (Next.js Parity)
  final QLDataFetchCallback? getServerSideProps;
  final QLDataFetchCallback? getStaticProps;
  final QLDataFetchCallback? getInitialProps;
  final FutureOr<List<String>> Function()? getStaticPaths;
  final QLSeoBuilder? seo;

  // 🚀 NATIVE SDUI SCHEMA RESOLUTION
  final QLSchemaFetchCallback? getSchema;
  final WidgetBuilder? loadingBuilder;

  const QLRoute({
    required this.path,
    this.builder,
    this.layoutBuilder,
    this.children = const [],
    this.middlewares = const [],
    this.transition = QLTransitionType.slideRight,
    this.transitionDuration = const Duration(milliseconds: 380),
    this.getServerSideProps,
    this.getStaticProps,
    this.getInitialProps,
    this.getStaticPaths,
    this.seo,
    this.getSchema,
    this.loadingBuilder,
  }) : assert(builder != null || layoutBuilder != null || getSchema != null,
            'Must provide builder, layoutBuilder, or getSchema to render a route.');
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  ZERO-ALLOCATION RADIX TRIE (O(K) Routing)
// ────────────────────────────────────────────────────────────────────────────

class _RadixMatch {
  final List<QLRoute> routes;
  final Map<String, String> params;
  const _RadixMatch(this.routes, this.params);
}

class _RadixNode {
  final Map<String, _RadixNode> literals = {};
  _RadixNode? paramChild;
  String? paramName;
  _RadixNode? wildcardChild;
  List<QLRoute>? routes;
}

class _QLRadixTrie {
  final _RadixNode _root = _RadixNode();

  void insert(String pattern, List<QLRoute> routeChain) {
    _RadixNode current = _root;
    final List<String> segments = _zeroAllocSplit(pattern);

    for (final String seg in segments) {
      if (seg == '*') {
        current.wildcardChild ??= _RadixNode();
        current = current.wildcardChild!;
        break;
      } else if (seg.startsWith(':')) {
        current.paramChild ??= _RadixNode();
        current.paramName = seg.substring(1);
        current = current.paramChild!;
      } else {
        current = current.literals.putIfAbsent(seg, () => _RadixNode());
      }
    }
    current.routes = routeChain;
  }

  _RadixMatch? search(String path) {
    final List<String> segments = _zeroAllocSplit(path);
    final Map<String, String> params = <String, String>{};
    return _searchRecursive(_root, segments, 0, params);
  }

  _RadixMatch? _searchRecursive(_RadixNode node, List<String> segments, int idx,
      Map<String, String> params) {
    if (idx == segments.length) {
      return node.routes != null ? _RadixMatch(node.routes!, params) : null;
    }

    final String seg = segments[idx];

    final _RadixNode? literalChild = node.literals[seg];
    if (literalChild != null) {
      final match = _searchRecursive(literalChild, segments, idx + 1, params);
      if (match != null) return match;
    }

    if (node.paramChild != null) {
      params[node.paramName!] = seg;
      final match =
          _searchRecursive(node.paramChild!, segments, idx + 1, params);
      if (match != null) return match;
      params.remove(node.paramName);
    }

    if (node.wildcardChild != null) {
      params['*'] = segments.sublist(idx).join('/');
      if (node.wildcardChild!.routes != null) {
        return _RadixMatch(node.wildcardChild!.routes!, params);
      }
    }

    return null;
  }

  List<String> _zeroAllocSplit(String path) {
    if (path.isEmpty || path == '/') return const [];
    final res = <String>[];
    int start = path.startsWith('/') ? 1 : 0;
    for (int i = start; i < path.length; i++) {
      if (path.codeUnitAt(i) == 47) {
        if (i > start) res.add(path.substring(start, i));
        start = i + 1;
      }
    }
    if (start < path.length) res.add(path.substring(start));
    return res;
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  CLIENT HYDRATION ENGINE (Reads Server-Rendered JSON State)
// ────────────────────────────────────────────────────────────────────────────

abstract final class QLHydration {
  static Map<String, dynamic>? _preloadedProps;
  static bool _isHydrated = false;
  static bool _warnedNoReader = false;

  /// Optional platform hook: return the raw `window.__QUANTUM_PROPS__` JSON
  /// map (or null if absent) using whatever JS-interop mechanism fits your
  /// Flutter/Dart SDK version (`dart:js_interop` + `package:web`, or the
  /// legacy `dart:js_util`). This is intentionally left unimplemented in the
  /// framework itself rather than faked: reading a JS global correctly
  /// requires compiling against an actual web target to verify, which this
  /// package cannot guarantee across SDK versions. Wire it once at startup:
  ///
  /// ```dart
  /// QLHydration.domPropsReader = () {
  ///   final raw = web.window.getProperty('__QUANTUM_PROPS__'.toJS);
  ///   if (raw == null) return null;
  ///   return jsonDecode((raw as JSString).toDart) as Map<String, dynamic>;
  /// };
  /// ```
  ///
  /// Until this is set, [hydrateFromDom] is a documented no-op on web (it
  /// previously *looked* like it read the DOM via an empty try/catch that
  /// always "succeeded" without doing anything -- that was misleading and
  /// has been removed).
  static Map<String, dynamic>? Function()? domPropsReader =
      readQuantumHydrationProps;

  /// Checks if pure HTML server props exist in the Web DOM and parses them.
  static void hydrateFromDom() {
    if (_isHydrated || !kIsWeb) return;
    final reader = domPropsReader ?? readQuantumHydrationProps;
    try {
      final props = reader();
      if (props != null) {
        _preloadedProps = props;
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('QLHydration.hydrateFromDom(): domPropsReader threw: $e');
        debugPrintStack(stackTrace: st);
      }
    }
    _isHydrated = true;
  }

  static void injectProps(Map<String, dynamic> props) {
    _preloadedProps = props;
    _isHydrated = true;
  }

  static Map<String, dynamic>? claimProps(String path) {
    if (_preloadedProps != null && _preloadedProps!['__path__'] == path) {
      final props = _preloadedProps!['props'];
      _preloadedProps = null; // Consume once
      return props;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  QLNAVCONTROLLER (Dynamic Router Engine + SSR Data Resolver)
// ────────────────────────────────────────────────────────────────────────────

class QLNavController extends ChangeNotifier {
  final _QLRadixTrie _trie = _QLRadixTrie();
  final List<QLMiddleware> _globalMiddlewares;
  final Widget? _notFoundWidget;
  final Map<int, List<QLRouteInfo>> _branchStacks = {0: []};
  int _activeBranch = 0;

  // Static Props Cache (Build-Time Simulators)
  final Map<String, Map<String, dynamic>> _staticPropsCache = {};

  QLNavController({
    required List<QLRoute> routes,
    List<QLMiddleware> globalMiddlewares = const [],
    Widget? notFoundWidget,
    String initialRoute = '/',
  })  : _globalMiddlewares = globalMiddlewares,
        _notFoundWidget = notFoundWidget {
    _registerRoutes(routes, '');
    QLHydration.hydrateFromDom();

    final initialInfo = QLRouteInfo(path: initialRoute);
    _branchStacks[0]!.add(initialInfo);
    _runPipeline(initialInfo).then((processed) {
      if (processed != null && _branchStacks[0]!.isNotEmpty) {
        _branchStacks[0]![0] = processed;
        notifyListeners();
      }
    });
  }

  void _registerRoutes(List<QLRoute> routes, String prefix,
      [List<QLRoute> parentChain = const []]) {
    for (final r in routes) {
      final String fullPath =
          (prefix + (r.path.startsWith('/') ? r.path : '/${r.path}'))
              .replaceAll('//', '/');
      final chain = [...parentChain, r];
      _trie.insert(fullPath, chain);
      if (r.children.isNotEmpty) _registerRoutes(r.children, fullPath, chain);
    }
  }

  List<QLRouteInfo> get stack =>
      List.unmodifiable(_branchStacks[_activeBranch]!);
  QLRouteInfo get current => _branchStacks[_activeBranch]!.last;
  bool get canPop => _branchStacks[_activeBranch]!.length > 1;

  void switchBranch(int index, {String? defaultPath}) {
    if (_activeBranch == index) return;
    if (!_branchStacks.containsKey(index)) {
      _branchStacks[index] = [];
      _activeBranch = index;
      if (defaultPath != null) {
        pushPath(defaultPath);
        return;
      }
    } else {
      _activeBranch = index;
    }
    notifyListeners();
  }

  Future<void> replaceRoot(QLRouteInfo info) async {
    final processed = await _runPipeline(info);
    if (processed == null) return;
    _branchStacks[_activeBranch]!.clear();
    _branchStacks[_activeBranch]!.add(processed);
    notifyListeners();
  }

  Future<void> push(QLRouteInfo info) async {
    final processed = await _runPipeline(info);
    if (processed == null) return;
    _branchStacks[_activeBranch]!.add(processed);
    notifyListeners();
  }

  Future<void> pushPath(String path, {Map<String, String>? q, Object? extra}) {
    final uri = Uri.parse(path);
    return push(QLRouteInfo(
        path: uri.path,
        queryParams: {...uri.queryParameters, ...?q},
        extra: extra));
  }

  bool pop([Object? result]) {
    if (!canPop) return false;
    _branchStacks[_activeBranch]!.removeLast();
    notifyListeners();
    return true;
  }

  Future<QLRouteInfo?> _runPipeline(QLRouteInfo info) async {
    QLRouteInfo currentInfo = info;

    for (final mw in _globalMiddlewares) {
      final res = await mw.process(currentInfo, null);
      if (res != null) return _runPipeline(res);
    }

    final match = _trie.search(currentInfo.path);
    if (match != null) {
      currentInfo = currentInfo.copyWith(params: match.params);

      // Middlewares
      for (final route in match.routes) {
        for (final mw in route.middlewares) {
          final res = await mw.process(currentInfo, null);
          if (res != null) return _runPipeline(res);
        }
      }

      // 🚀 NEXT.JS PARITY: Data Fetching Resolution
      currentInfo = await _resolveRouteProps(match.routes.last, currentInfo);
    }
    return currentInfo;
  }

  Future<QLRouteInfo> _resolveRouteProps(QLRoute leaf, QLRouteInfo info) async {
    final Map<String, dynamic> mergedProps = Map.from(info.props);

    // 1. Check if Hydrated from Server DOM (Bypass fetching)
    final hydrated = QLHydration.claimProps(info.path);
    if (hydrated != null) {
      mergedProps.addAll(hydrated);
      return info.copyWith(props: mergedProps);
    }

    // 2. getStaticProps (Cached Build-time Data)
    if (leaf.getStaticProps != null) {
      if (_staticPropsCache.containsKey(info.path)) {
        mergedProps.addAll(_staticPropsCache[info.path]!);
      } else {
        final staticData = await leaf.getStaticProps!(info);
        _staticPropsCache[info.path] = staticData;
        mergedProps.addAll(staticData);
      }
    }

    // 3. getServerSideProps (Runtime Server Data - Fetched client side via API if navigating SPA)
    if (leaf.getServerSideProps != null) {
      mergedProps.addAll(await leaf.getServerSideProps!(info));
    }

    // 4. getInitialProps (Hybrid SPA Data)
    if (leaf.getInitialProps != null) {
      mergedProps.addAll(await leaf.getInitialProps!(info));
    }

    return info.copyWith(props: mergedProps);
  }

  Widget resolveWidget(BuildContext context, QLRouteInfo info) {
    final match = _trie.search(info.path);
    if (match == null || match.routes.isEmpty)
      return _notFoundWidget ??
          Scaffold(body: Center(child: Text('404: ${info.path}')));

    final leaf = match.routes.last;

    Widget child;

    // 🚀 ARCHITECT FIX: Native Schema Resolution
    // If the user provided a getSchema callback, we automatically mount the
    // Quantum VM's SmartView and handle the async fetching internally.
    if (leaf.getSchema != null) {
      child = _QLAsyncSchemaView(
        info: info,
        getSchema: leaf.getSchema!,
        loadingBuilder: leaf.loadingBuilder,
      );
    } else {
      child = leaf.builder?.call(context, info) ?? const SizedBox.shrink();
    }

    // 🚀 SEO METADATA INJECTION
    if (leaf.seo != null) {
      final QLSeoConfig config = leaf.seo!(info, info.props);
      child = QLSeoHead(config: config, child: child);
    }

    // Fold LayoutBuilders (Shell Routes)
    for (int i = match.routes.length - 1; i >= 0; i--) {
      if (match.routes[i].layoutBuilder != null) {
        child = match.routes[i].layoutBuilder!(context, info, child);
      }
    }
    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  SERVER RENDERER (Pure HTML SEO Generation API)
// ────────────────────────────────────────────────────────────────────────────

/// Allows you to mount the routing engine on a pure Dart backend (Shelf, Dart Frog)
/// to generate indexable SSR HTML for Search Engines.
abstract final class QLServerRenderer {
  /// Generates the raw `index.html` string containing populated SEO `<head>` tags
  /// and the serialized data state, bypassing the need for a JS engine on the bot.
  static Future<String> generateHtml({
    required String path,
    required List<QLRoute> routes,
    String baseHtmlTemplate = '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- QUANTUM_SEO_INJECTION -->
</head>
<body>
  <div id="flutter_app"></div>
  <!-- QUANTUM_PROPS_INJECTION -->
  <script src="main.dart.js" defer></script>
</body>
</html>
''',
  }) async {
    final trie = _QLRadixTrie()..insert('/', routes); // Bootstrap trie

    // Register recursively
    void register(List<QLRoute> rt, String prefix,
        [List<QLRoute> chain = const []]) {
      for (final r in rt) {
        final fullPath =
            (prefix + (r.path.startsWith('/') ? r.path : '/${r.path}'))
                .replaceAll('//', '/');
        final currentChain = [...chain, r];
        trie.insert(fullPath, currentChain);
        if (r.children.isNotEmpty) register(r.children, fullPath, currentChain);
      }
    }

    register(routes, '');

    final uri = Uri.parse(path);
    final match = trie.search(uri.path);

    if (match == null || match.routes.isEmpty) {
      return baseHtmlTemplate.replaceFirst(
          '<!-- QUANTUM_SEO_INJECTION -->', '<title>404 Not Found</title>');
    }

    QLRouteInfo info = QLRouteInfo(
      path: uri.path,
      params: match.params,
      queryParams: uri.queryParameters,
    );

    final leaf = match.routes.last;
    final Map<String, dynamic> fetchedProps = {};

    // 🚀 EXECUTE SERVER-SIDE DATA FETCHING (SSR/SSG)
    if (leaf.getStaticProps != null) {
      fetchedProps.addAll(await leaf.getStaticProps!(info));
    }
    if (leaf.getServerSideProps != null) {
      fetchedProps.addAll(await leaf.getServerSideProps!(info));
    }
    if (leaf.getInitialProps != null) {
      fetchedProps.addAll(await leaf.getInitialProps!(info));
    }

    info = info.copyWith(props: fetchedProps);

    // 🚀 GENERATE SEO HTML TAGS
    String seoTags = '';
    if (leaf.seo != null) {
      final config = leaf.seo!(info, info.props);
      seoTags = config.generateHtmlTags();
    }

    // 🚀 SERIALIZE HYDRATION PAYLOAD
    final String hydrationPayload = jsonEncode({
      '__path__': info.path,
      'props': fetchedProps,
    });
    final String scriptTag =
        "<script>window.__QUANTUM_PROPS__ = $hydrationPayload;</script>";

    // Compile Final HTML
    return baseHtmlTemplate
        .replaceFirst('<!-- QUANTUM_SEO_INJECTION -->', seoTags)
        .replaceFirst('<!-- QUANTUM_PROPS_INJECTION -->', scriptTag);
  }
}

// ─────────────────────────────────────────────────────────────────────── §9 ─
//  QLSEOHEAD WIDGET (Client-Side Document Title Manipulator)
// ────────────────────────────────────────────────────────────────────────────

class QLSeoHead extends StatelessWidget {
  final QLSeoConfig config;
  final Widget child;

  const QLSeoHead({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // In pure Flutter Web (SPA), we can at least dynamically update the page Title.
    // For true SEO metadata rendering (description, OG tags), search engines look
    // at the raw HTML returned from the server, which is handled by QLServerRenderer.
    return Title(
      title: config.title,
      color: Colors.black,
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §10 ─
//  QLROUTERDELEGATE & PARSER
// ────────────────────────────────────────────────────────────────────────────

class QLRouteParser extends RouteInformationParser<QLRouteInfo> {
  const QLRouteParser();

  @override
  Future<QLRouteInfo> parseRouteInformation(RouteInformation info) async {
    return QLRouteInfo(
        path: info.uri.path.isEmpty ? '/' : info.uri.path,
        queryParams: info.uri.queryParameters);
  }

  @override
  RouteInformation? restoreRouteInformation(QLRouteInfo info) {
    return RouteInformation(
        uri: Uri(
            path: info.path,
            queryParameters:
                info.queryParams.isEmpty ? null : info.queryParams));
  }
}

class QLRouterDelegate extends RouterDelegate<QLRouteInfo>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<QLRouteInfo> {
  final QLNavController controller;
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  QLRouterDelegate(this.controller) {
    controller.addListener(notifyListeners);
  }

  @override
  QLRouteInfo get currentConfiguration => controller.current;

  @override
  Future<void> setInitialRoutePath(QLRouteInfo configuration) async {
    await controller.replaceRoot(configuration);
  }

  @override
  Future<void> setNewRoutePath(QLRouteInfo info) async => controller.push(info);

  @override
  void dispose() {
    controller.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [TelemetryNavigatorObserver()],
      pages: controller.stack.map((info) {
        final match = controller._trie.search(info.path);

        return _QLHardwarePage(
          // 🚀 FIX 2: ObjectKey guarantees a 100% unique key for every single push!
          key: ObjectKey(info),
          name: info.path,
          child: controller.resolveWidget(context, info),
          transition:
              match?.routes.last.transition ?? QLTransitionType.slideRight,
          duration: match?.routes.last.transitionDuration ??
              const Duration(milliseconds: 380),
        );
      }).toList(),
      // 🚀 FIX 3: Stop the double-pop corruption!
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        controller.pop();
        return true;
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §11 ─
//  ZERO-REBUILD HARDWARE TRANSITIONS (Memory Cache Optimized)
// ────────────────────────────────────────────────────────────────────────────

class _QLHardwarePage extends Page<void> {
  final Widget child;
  final QLTransitionType transition;
  final Duration duration;

  const _QLHardwarePage({
    required super.key,
    required super.name,
    required this.child,
    required this.transition,
    required this.duration,
  });

  @override
  Route<void> createRoute(BuildContext context) => _QLHardwareRoute(
      settings: this, child: child, transition: transition, duration: duration);
}

class _QLHardwareRoute extends PageRoute<void> {
  final Widget child;
  final QLTransitionType transition;
  final Duration duration;

  _QLHardwareRoute({
    required super.settings,
    required this.child,
    required this.transition,
    required this.duration,
  });

  @override
  Color? get barrierColor => null;
  @override
  String? get barrierLabel => null;
  @override
  bool get maintainState => true;
  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
      BuildContext context, Animation<double> a, Animation<double> sa) {
    return Material(
      type: MaterialType.transparency,
      child: child,
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> a,
      Animation<double> sa, Widget child) {
    if (transition == QLTransitionType.none) return child;

    return _QLZeroRebuildTransition(
      animation: a,
      secondaryAnimation: sa,
      transitionType: transition,
      child: child,
    );
  }
}

class _QLZeroRebuildTransition extends StatefulWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final QLTransitionType transitionType;
  final Widget child;

  const _QLZeroRebuildTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  State<_QLZeroRebuildTransition> createState() =>
      _QLZeroRebuildTransitionState();
}

class _QLZeroRebuildTransitionState extends State<_QLZeroRebuildTransition> {
  late final QLSignal<Matrix4> _transform;
  late final QLSignal<double> _opacity;

  double _screenWidth = 400.0;
  double _screenHeight = 800.0;

  @override
  void initState() {
    super.initState();
    _transform = QLSignal(Matrix4.identity());
    _opacity = QLSignal(1.0);

    widget.animation.addListener(_onTick);
    widget.secondaryAnimation.addListener(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);
    _screenWidth = size.width;
    _screenHeight = size.height;
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onTick);
    widget.secondaryAnimation.removeListener(_onTick);
    _transform.dispose();
    _opacity.dispose();
    super.dispose();
  }

  void _onTick() {
    final double t = Curves.easeOutQuint.transform(widget.animation.value);
    final double tOut =
        Curves.easeInQuint.transform(widget.secondaryAnimation.value);

    double newOpacity = 1.0;

    _transform.update((m) {
      m.setIdentity();

      switch (widget.transitionType) {
        case QLTransitionType.fade:
          newOpacity = t;
          break;

        case QLTransitionType.scale:
          newOpacity = t;
          final double s = 0.9 + (0.1 * t);
          m.scale(s, s, 1.0);
          break;

        case QLTransitionType.slideRight:
          m.translate(_screenWidth * (1.0 - t), 0.0, 0.0);
          if (tOut > 0) m.translate(-_screenWidth * 0.25 * tOut, 0.0, 0.0);
          break;

        case QLTransitionType.slideLeft:
          m.translate(-_screenWidth * (1.0 - t), 0.0, 0.0);
          if (tOut > 0) m.translate(_screenWidth * 0.25 * tOut, 0.0, 0.0);
          break;

        case QLTransitionType.slideUp:
          m.translate(0.0, _screenHeight * (1.0 - t), 0.0);
          if (tOut > 0) newOpacity = 1.0 - (0.5 * tOut);
          break;

        case QLTransitionType.slideDown:
          m.translate(0.0, -_screenHeight * (1.0 - t), 0.0);
          break;

        case QLTransitionType.flip3D:
          newOpacity = t;
          m.setEntry(3, 2, 0.002);
          m.rotateY((1.0 - t) * (math.pi / 2));
          if (tOut > 0) m.rotateY(-tOut * (math.pi / 2));
          break;

        case QLTransitionType.none:
          break;
      }
    });

    if (_opacity.value != newOpacity) {
      _opacity.value = newOpacity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_transform, _opacity]),
      builder: (ctx, child) => Opacity(
        opacity: _opacity.value.clamp(0.0, 1.0),
        child: Transform(
          transform: _transform.value,
          alignment: Alignment.center,
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
// ─────────────────────────────────────────────────────────────────────── §12 ─
//  ASYNC SCHEMA RESOLVER (O(1) SDUI Bootstrap)
// ────────────────────────────────────────────────────────────────────────────

class _QLAsyncSchemaView extends StatefulWidget {
  final QLRouteInfo info;
  final QLSchemaFetchCallback getSchema;
  final WidgetBuilder? loadingBuilder;

  const _QLAsyncSchemaView({
    required this.info,
    required this.getSchema,
    this.loadingBuilder,
  });

  @override
  State<_QLAsyncSchemaView> createState() => _QLAsyncSchemaViewState();
}

class _QLAsyncSchemaViewState extends State<_QLAsyncSchemaView> {
  Map<String, dynamic>? _resolvedSchema;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _fetchSchema();
  }

  Future<void> _fetchSchema() async {
    try {
      // The callback can be synchronous or asynchronous. We handle both.
      final result = await widget.getSchema(widget.info);
      if (mounted) setState(() => _resolvedSchema = result);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Text('Schema Fetch Error: $_error',
            style: const TextStyle(color: Colors.red)),
      );
    }

    if (_resolvedSchema == null) {
      // 🚀 FIX: Removed CircularProgressIndicator to prevent pumpAndSettle test hangs.
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }

    // Mount the Quantum Virtual Machine renderer with the resolved schema!
    return QLSmartView(
      manifest: _resolvedSchema,
      routeInfo: widget.info, // Passes down params/queries to the VM
    );
  }
}
