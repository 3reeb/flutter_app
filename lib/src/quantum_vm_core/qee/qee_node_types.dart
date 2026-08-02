/*
 * ============================================================================
 * File: qee_node_types.dart
 * 
 * Description:
 * Defines the unified, immutable data structures representing all node types 
 * within the QEE. Enforces that all layouts, modules, and wrappers are uniquely 
 * addressable and read-only post-registration.
 * 
 * Key Components:
 * - QBaseNode: Abstract baseline with ID, version, and bit-packed flags.
 * - QPageNode, QLayoutNode, QMiddlewareNode, etc.: Concrete semantic blueprints.
 * - QNodeRef: 8-byte pointer type for O(1) cross-node links.
 * - QPageContext: Runtime parameter and state carrier (not persisted).
 * 
 * Dependencies/Relationships:
 * Universally utilized by caching, resolution, serialization, and layout systems.
 * 
 * Notes:
 * Nodes use deterministic 64-bit hashing for identity, ensuring single-instance 
 * caching semantics.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE NODE TYPES — qee_node_types.dart
//
// Unified node type system for the Quantum Execution Engine.
//
// Rules:
//  • All nodes are immutable (sealed) after registration.
//  • All nodes are identified by a 64-bit integer node ID (O(1) lookup).
//  • QNodeRef<T> is a lightweight pointer — 8 bytes on the wire.
//  • QPageContext is runtime-only — never stored in the engine.
//  • _layout and _middleware COMPOSE (wrap) — inner wraps inside outer.
//  • _meta, _error, _loading, _not_found OVERRIDE — most specific wins.
//  • All wrappers receive the current QPageContext (routeParams + pageProps)
//    at render time, even when defined at a parent directory level.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — NODE KIND
// ─────────────────────────────────────────────────────────────────────────────

/// The kind of a QEE node. Stored as a single byte in the binary format.
enum QNodeKind {
  app(0x01),
  page(0x02),
  module(0x03),
  layout(0x04),
  meta(0x05),
  middleware(0x06),
  error(0x07),
  loading(0x08),
  notFound(0x09);

  final int code;
  const QNodeKind(this.code);

  static QNodeKind fromCode(int code) {
    for (final kind in QNodeKind.values) {
      if (kind.code == code) return kind;
    }
    throw ArgumentError('Unknown QNodeKind code: 0x${code.toRadixString(16)}');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — NODE FLAGS (bit-packed booleans)
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QNodeFlags {
  static const int isCatchAll        = 1 << 0;
  static const int hasParams         = 1 << 1;
  static const int hasStaticState    = 1 << 2;
  static const int isOverridable     = 1 << 3;  // meta/error/loading/notFound
  static const int isComposing       = 1 << 4;  // layout/middleware (wrap, not override)
  static const int hasBody           = 1 << 5;
  static const int isPublic          = 1 << 6;  // module public
  static const int isPrivate         = 1 << 7;  // module private
  static const int isShared          = 1 << 8;  // module shared
  static const int hasParentRef      = 1 << 9;
  static const int isSealed          = 1 << 10; // node is read-only
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — NODE REF — 8-byte lightweight pointer
// ─────────────────────────────────────────────────────────────────────────────

/// A lightweight reference to any QEE node.
/// Resolved on demand — O(1) lookup from the in-memory node store.
/// Stored as a single uint64 (8 bytes) in the binary format.
@immutable
class QNodeRef<T extends QBaseNode> {
  final int nodeId;

  const QNodeRef(this.nodeId);

  /// Synchronous resolve — returns null if node is not in memory cache.
  /// Use when you know the node is already loaded.
  T? resolveSync() => QNodeStore.instance.resolveSync<T>(nodeId);

  /// Async resolve — loads from disk cache if not in memory.
  Future<T?> resolve() => QNodeStore.instance.resolve<T>(nodeId);

  @override
  bool operator ==(Object other) =>
      other is QNodeRef<T> && other.nodeId == nodeId;

  @override
  int get hashCode => nodeId.hashCode;

  @override
  String toString() => 'QNodeRef<${T.toString()}>($nodeId)';
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — PAGE CONTEXT — runtime-only, never stored in the engine
// ─────────────────────────────────────────────────────────────────────────────

/// Runtime context passed to ALL page-level nodes at render time.
/// This includes: the page itself, its layout(s), middleware(s), error,
/// loading, not_found, and meta — even those defined at parent directory level.
///
/// Critical: this is NEVER stored in the encrypted node. It is created fresh
/// on every navigation and passed down as a ValueNotifier so that only
/// the widgets that USE a specific param rebuild when that param changes.
@immutable
class QPageContext {
  /// The matched route path, e.g. `/users/:id`
  final String routePath;

  /// The resolved route parameters, e.g. `{id: '123', tab: 'settings'}`
  final Map<String, String> routeParams;

  /// URL query parameters, e.g. `{page: '2', sort: 'asc'}`
  final Map<String, String> queryParams;

  /// The static props declared in the page config (baked at registration time)
  final Map<String, dynamic> pageProps;

  /// The app this page belongs to (null = root app)
  final String? appId;

  /// The full matched URL, e.g. `/users/123?page=2`
  final String fullUrl;

  /// Previous page's route path (for transition animations)
  final String? previousRoutePath;

  const QPageContext({
    required this.routePath,
    required this.routeParams,
    required this.queryParams,
    required this.pageProps,
    required this.fullUrl,
    this.appId,
    this.previousRoutePath,
  });

  /// Empty context — used as initial value before first navigation.
  static const QPageContext empty = QPageContext(
    routePath: '/',
    routeParams: {},
    queryParams: {},
    pageProps: {},
    fullUrl: '/',
  );

  /// Access a route param, returns `defaultValue` if missing.
  String param(String name, {String defaultValue = ''}) =>
      routeParams[name] ?? defaultValue;

  /// Access a query param, returns `defaultValue` if missing.
  String query(String name, {String defaultValue = ''}) =>
      queryParams[name] ?? defaultValue;

  /// Access a page prop, returns `defaultValue` if missing.
  T prop<T>(String name, {T? defaultValue}) {
    final val = pageProps[name];
    if (val is T) return val;
    return defaultValue as T;
  }

  QPageContext copyWith({
    String? routePath,
    Map<String, String>? routeParams,
    Map<String, String>? queryParams,
    Map<String, dynamic>? pageProps,
    String? appId,
    String? fullUrl,
    String? previousRoutePath,
  }) {
    return QPageContext(
      routePath: routePath ?? this.routePath,
      routeParams: routeParams ?? this.routeParams,
      queryParams: queryParams ?? this.queryParams,
      pageProps: pageProps ?? this.pageProps,
      appId: appId ?? this.appId,
      fullUrl: fullUrl ?? this.fullUrl,
      previousRoutePath: previousRoutePath ?? this.previousRoutePath,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QPageContext &&
      other.routePath == routePath &&
      other.fullUrl == fullUrl &&
      _mapsEqual(other.routeParams, routeParams) &&
      _mapsEqual(other.queryParams, queryParams);

  @override
  int get hashCode => Object.hash(routePath, fullUrl);

  static bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

/// ValueNotifier for surgical page context updates.
/// All layout/error/loading/meta/middleware widgets listen to this.
/// On navigation: `notifier.value = newContext` triggers ONLY widgets
/// that explicitly read the changed props.
class QPageContextNotifier extends ValueNotifier<QPageContext> {
  QPageContextNotifier([super.value = QPageContext.empty]);

  /// Update only the route params without rebuilding widgets that
  /// only read pageProps or queryParams.
  void updateRouteParams(Map<String, String> params) {
    if (value.routeParams == params) return;
    value = value.copyWith(routeParams: params);
  }

  /// Full navigation update.
  void navigate(QPageContext context) {
    if (value == context) return;
    value = context;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 — PAGE BODY — lazy-compiled config
// ─────────────────────────────────────────────────────────────────────────────

/// The compiled body of a page or layout.
/// Stored as a compact binary blob inside the encrypted node.
/// Deserialized lazily on first access.
class QPageBody {
  final Uint8List _bytes;

  // Lazily deserialized raw config map (only populated on demand)
  Map<String, dynamic>? _cachedConfig;

  QPageBody(this._bytes);

  /// Raw bytes length — useful for cache weight calculation.
  int get byteLength => _bytes.length;

  /// The raw bytes (encrypted form is stored in QDiskStore; these are plaintext).
  Uint8List get bytes => _bytes;

  /// Lazily deserialize to a config map.
  /// The format is whatever `QLFormatParser` / `QLCompiler` expects.
  Map<String, dynamic> toConfig() {
    return _cachedConfig ??= _deserializeConfig(_bytes);
  }

  static Map<String, dynamic> _deserializeConfig(Uint8List bytes) {
    // Config is stored as a length-prefixed JSON blob inside the binary node.
    // The QNodeDecoder handles the outer binary envelope;
    // the inner JSON (for the SDUI/QL UI tree) is preserved as-is for
    // compatibility with the existing QLCompiler pipeline.
    if (bytes.isEmpty) return const {};
    // Forward-compatible: parse as UTF-8 JSON config
    try {
      // ignore: avoid_dynamic_calls
      final str = String.fromCharCodes(bytes);
      // Basic check — actual parsing done by QLFormatParser when needed
      if (str.startsWith('{') || str.startsWith('[')) {
        // Return a wrapper that the caller can pass to QLFormatParser
        return {'__raw__': str, '__bodyBytes__': bytes};
      }
    } catch (_) {}
    return {'__bodyBytes__': bytes};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §6 — BASE NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all QEE nodes.
///
/// All nodes are immutable after `sealed = true` is set by the registry.
/// The [nodeId] is a deterministic 64-bit hash of (kind + appId + identity key).
@immutable
abstract class QBaseNode {
  /// Unique 64-bit identifier (deterministic hash of kind+appId+routePath/moduleId/etc.)
  final int nodeId;

  /// Node kind — determines how this node is interpreted.
  final QNodeKind kind;

  /// Monotonically increasing version number. Incremented on each upsert.
  final int version;

  /// Unix millisecond timestamp when this node was sealed (written to disk).
  final int sealedAt;

  /// Bit-flag set. See [QNodeFlags].
  final int flags;

  const QBaseNode({
    required this.nodeId,
    required this.kind,
    required this.version,
    required this.sealedAt,
    required this.flags,
  });

  bool get isSealed => (flags & QNodeFlags.isSealed) != 0;

  /// Estimated memory weight in bytes (for cache eviction scoring).
  int get weight;
}

// ─────────────────────────────────────────────────────────────────────────────
// §7 — PAGE NODE
// ─────────────────────────────────────────────────────────────────────────────

/// A fully file-route page.
///
/// Owns references to all its inherited/overridden page-level nodes.
/// The layout ref points to the INNERMOST layout in the chain (the chain
/// itself is traversed via [QLayoutNode.parentLayoutRef]).
///
/// On navigation: ONLY the page body changes. All layout/error/loading/meta
/// nodes stay alive and receive the new [QPageContext] without rebuilding.
@immutable
class QPageNode extends QBaseNode {
  /// The route pattern, e.g. `/users/:id` or `/blog/[...slug]`
  final String routePath;

  /// The app this page belongs to (null = root app)
  final String? appId;

  /// The asset path of the page file, e.g. `pages/users/[id].yaml`
  final String? assetPath;

  /// Named URL params in order, e.g. `['id']` for `/users/:id`
  final List<String> paramNames;

  /// Reference to the INNERMOST layout in the composition chain.
  /// Follow [QLayoutNode.parentLayoutRef] to traverse to the root.
  /// Layout wraps page content; never rebuilds on navigation.
  final QNodeRef<QLayoutNode>? layoutRef;

  /// Reference to the most-specific (deepest directory) meta node.
  /// Meta can be overridden at any directory level.
  final QNodeRef<QMetaNode>? metaRef;

  /// Reference to the OUTERMOST middleware in the composition chain.
  /// Follow [QMiddlewareNode.nextRef] to reach inner middlewares.
  /// Middleware composes (outer runs first, then inner).
  final QNodeRef<QMiddlewareNode>? middlewareRef;

  /// Reference to the most-specific error boundary node.
  /// Overridable at any directory level.
  final QNodeRef<QErrorNode>? errorRef;

  /// Reference to the most-specific loading node.
  /// Overridable at any directory level.
  final QNodeRef<QLoadingNode>? loadingRef;

  /// Reference to the most-specific not-found node.
  /// Overridable at any directory level. Per-page 404 handling.
  final QNodeRef<QNotFoundNode>? notFoundRef;

  /// The compiled page body (lazy — null until loaded from disk).
  final QPageBody? body;

  const QPageNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.routePath,
    required this.paramNames,
    this.appId,
    this.assetPath,
    this.layoutRef,
    this.metaRef,
    this.middlewareRef,
    this.errorRef,
    this.loadingRef,
    this.notFoundRef,
    this.body,
  }) : super(kind: QNodeKind.page);

  bool get isCatchAll => (flags & QNodeFlags.isCatchAll) != 0;
  bool get hasParams => paramNames.isNotEmpty;

  @override
  int get weight {
    int w = 128; // base
    w += routePath.length * 2;
    w += assetPath?.length ?? 0;
    w += paramNames.length * 16;
    w += body?.byteLength ?? 0;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §8 — LAYOUT NODE
// ─────────────────────────────────────────────────────────────────────────────

/// A layout wraps pages. Layouts COMPOSE — they never override each other.
///
/// Given:
///   pages/_layout.yaml       (A — outer)
///   pages/users/_layout.yaml (B — inner)
///   pages/users/[id].yaml    (page)
///
/// The render tree is: A → B → page_slot
///
/// A and B are NEVER rebuilt when navigating between pages under `users/`.
/// Only the `page_slot` is swapped. Both A and B receive the current
/// [QPageContext] via [QPageContextNotifier].
///
/// [parentLayoutRef] points to the OUTER layout (parent directory's layout).
/// The root layout has [parentLayoutRef] == null.
@immutable
class QLayoutNode extends QBaseNode {
  /// Stable ID for this layout, derived from its asset path.
  final String layoutId;

  /// The app this layout belongs to (null = root app).
  final String? appId;

  /// The asset path of the _layout file.
  final String? assetPath;

  /// Directory path this layout governs, e.g. `pages/users/`
  final String directoryPath;

  /// The OUTER layout (parent directory's _layout).
  /// null if this is the root-most layout.
  final QNodeRef<QLayoutNode>? parentLayoutRef;

  /// The compiled layout body (lazy).
  final QPageBody? body;

  const QLayoutNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.layoutId,
    required this.directoryPath,
    this.appId,
    this.assetPath,
    this.parentLayoutRef,
    this.body,
  }) : super(kind: QNodeKind.layout);

  bool get hasParent => parentLayoutRef != null;

  @override
  int get weight {
    int w = 96;
    w += layoutId.length * 2;
    w += directoryPath.length * 2;
    w += body?.byteLength ?? 0;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §9 — MIDDLEWARE NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one level of middleware in the composition chain.
///
/// Middleware COMPOSES — never overrides. Given:
///   pages/_middleware.yaml       (M1 — outer, runs first)
///   pages/users/_middleware.yaml (M2 — inner, runs after M1)
///
/// [nextRef] points from M1 → M2.
/// M1 and M2 both receive the current [QPageContext].
///
/// Middleware runs before the page is rendered (navigation guard).
/// It can: redirect, block, set state, log, etc.
@immutable
class QMiddlewareNode extends QBaseNode {
  final String middlewareId;
  final String? appId;
  final String? assetPath;
  final String directoryPath;

  /// The INNER (next) middleware in the chain (runs after this one).
  final QNodeRef<QMiddlewareNode>? nextRef;

  /// The ordered list of middleware steps to execute.
  final List<QMiddlewareStep> steps;

  const QMiddlewareNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.middlewareId,
    required this.directoryPath,
    required this.steps,
    this.appId,
    this.assetPath,
    this.nextRef,
  }) : super(kind: QNodeKind.middleware);

  bool get hasNext => nextRef != null;

  @override
  int get weight {
    int w = 80;
    w += middlewareId.length * 2;
    w += steps.length * 64;
    return w;
  }
}

/// A single step in a middleware chain.
@immutable
class QMiddlewareStep {
  /// Step type: `'auth'`, `'redirect'`, `'guard'`, `'log'`, `'rateLimit'`, etc.
  final String type;

  /// Static parameters for this step (baked at registration time).
  final Map<String, dynamic> params;

  /// Whether this step is async (needs to await before proceeding).
  final bool isAsync;

  /// Human-readable description (debug only).
  final String? description;

  const QMiddlewareStep({
    required this.type,
    required this.params,
    this.isAsync = false,
    this.description,
  });

  @override
  String toString() => 'QMiddlewareStep($type)';
}

/// Result of executing a middleware chain.
enum QMiddlewareResult {
  /// Allow navigation to proceed.
  next,

  /// Block navigation and show an error.
  block,

  /// Redirect to a different route.
  redirect,
}

@immutable
class QMiddlewareOutcome {
  final QMiddlewareResult result;

  /// For [QMiddlewareResult.redirect]: the target route path.
  final String? redirectTo;

  /// For [QMiddlewareResult.block]: the error message.
  final String? errorMessage;

  const QMiddlewareOutcome.next()
      : result = QMiddlewareResult.next,
        redirectTo = null,
        errorMessage = null;

  const QMiddlewareOutcome.block(this.errorMessage)
      : result = QMiddlewareResult.block,
        redirectTo = null;

  const QMiddlewareOutcome.redirect(this.redirectTo)
      : result = QMiddlewareResult.redirect,
        errorMessage = null;

  bool get allowed => result == QMiddlewareResult.next;
}

// ─────────────────────────────────────────────────────────────────────────────
// §10 — META NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Metadata for a page or directory.
///
/// Meta OVERRIDES — most specific (deepest directory) wins.
/// The winning meta node receives the current [QPageContext] at render time,
/// so `title: "User {{routeParams.id}}"` resolves correctly even if the
/// meta is defined at a parent directory level.
@immutable
class QMetaNode extends QBaseNode {
  final String metaId;
  final String? appId;
  final String? assetPath;
  final String directoryPath;

  /// Static title (may contain `{{param}}` placeholders resolved at render time)
  final String? title;

  /// Title template, e.g. `'%s | My App'` — `%s` replaced with page title.
  final String? titleTemplate;

  /// Static description.
  final String? description;

  /// Open Graph tags: `{og:image: '...', og:type: 'website', ...}`
  final Map<String, String> openGraph;

  /// Twitter Card tags.
  final Map<String, String> twitterCard;

  /// Additional arbitrary meta tags.
  final Map<String, String> extra;

  /// Raw map for forward compatibility.
  final Map<String, dynamic> raw;

  const QMetaNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.metaId,
    required this.directoryPath,
    required this.raw,
    this.appId,
    this.assetPath,
    this.title,
    this.titleTemplate,
    this.description,
    this.openGraph = const {},
    this.twitterCard = const {},
    this.extra = const {},
  }) : super(kind: QNodeKind.meta);

  /// Resolve title with route params substituted.
  String resolveTitle(QPageContext ctx) {
    if (title == null) return '';
    return _resolveTemplate(title!, ctx);
  }

  /// Resolve description with route params substituted.
  String resolveDescription(QPageContext ctx) {
    if (description == null) return '';
    return _resolveTemplate(description!, ctx);
  }

  static String _resolveTemplate(String template, QPageContext ctx) {
    var result = template;
    ctx.routeParams.forEach((key, value) {
      result = result.replaceAll('{{routeParams.$key}}', value);
      result = result.replaceAll('{{params.$key}}', value);
      result = result.replaceAll('{{$key}}', value);
    });
    ctx.queryParams.forEach((key, value) {
      result = result.replaceAll('{{query.$key}}', value);
    });
    ctx.pageProps.forEach((key, value) {
      result = result.replaceAll('{{props.$key}}', value.toString());
    });
    return result;
  }

  @override
  int get weight {
    int w = 128;
    w += (title?.length ?? 0) * 2;
    w += (description?.length ?? 0) * 2;
    w += openGraph.length * 64;
    w += twitterCard.length * 64;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §11 — ERROR NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Error boundary config for a page or directory.
///
/// Error OVERRIDES — most specific wins.
/// Receives full [QPageContext] at render time.
/// Can access `{{routeParams.id}}`, `{{error.message}}`, etc.
@immutable
class QErrorNode extends QBaseNode {
  final String errorId;
  final String? appId;
  final String? assetPath;
  final String directoryPath;

  /// The compiled body of the error UI (lazy).
  final QPageBody? body;

  /// Static props to pass to the error widget (template vars resolved at render time).
  final Map<String, dynamic> props;

  const QErrorNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.errorId,
    required this.directoryPath,
    required this.props,
    this.appId,
    this.assetPath,
    this.body,
  }) : super(kind: QNodeKind.error);

  @override
  int get weight {
    int w = 80;
    w += errorId.length * 2;
    w += body?.byteLength ?? 0;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §12 — LOADING NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Loading overlay config for a page or directory.
///
/// Loading OVERRIDES — most specific wins.
/// Receives full [QPageContext] at render time.
@immutable
class QLoadingNode extends QBaseNode {
  final String loadingId;
  final String? appId;
  final String? assetPath;
  final String directoryPath;

  /// The compiled body of the loading UI (lazy).
  final QPageBody? body;

  /// Whether this loading node shows a full-page overlay or an inline indicator.
  final bool isFullPage;

  /// Minimum display duration in milliseconds (prevents flash of loading state).
  final int minDisplayMs;

  const QLoadingNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.loadingId,
    required this.directoryPath,
    this.isFullPage = true,
    this.minDisplayMs = 0,
    this.appId,
    this.assetPath,
    this.body,
  }) : super(kind: QNodeKind.loading);

  @override
  int get weight {
    int w = 80;
    w += loadingId.length * 2;
    w += body?.byteLength ?? 0;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §13 — NOT FOUND NODE
// ─────────────────────────────────────────────────────────────────────────────

/// 404 Not Found config for a page or directory.
///
/// NotFound OVERRIDES — most specific wins.
/// Applies within the scope of its directory (per-page 404 handling).
/// Also passed to all nested pages that don't define their own.
/// Receives full [QPageContext] at render time.
@immutable
class QNotFoundNode extends QBaseNode {
  final String notFoundId;
  final String? appId;
  final String? assetPath;
  final String directoryPath;

  /// The compiled body of the 404 UI (lazy).
  final QPageBody? body;

  /// If true, this not-found node handles all unmatched sub-routes under its directory.
  final bool isCatchAll;

  const QNotFoundNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.notFoundId,
    required this.directoryPath,
    this.isCatchAll = true,
    this.appId,
    this.assetPath,
    this.body,
  }) : super(kind: QNodeKind.notFound);

  @override
  int get weight {
    int w = 80;
    w += notFoundId.length * 2;
    w += body?.byteLength ?? 0;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §14 — MODULE NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Module kind — controls who can access this module.
enum QModuleKind {
  /// Accessible from any app.
  public,

  /// Only accessible from the app that owns it.
  private,

  /// Accessible from apps listed in [QModulePolicy.allowedAppIds].
  shared,
}

/// Access policy for a shared module.
@immutable
class QModulePolicy {
  final QModuleKind kind;

  /// For [QModuleKind.shared]: the list of app IDs allowed to access this module.
  final List<String> allowedAppIds;

  /// For [QModuleKind.shared]: whether to also require authentication.
  final bool requireAuth;

  const QModulePolicy({
    required this.kind,
    this.allowedAppIds = const [],
    this.requireAuth = false,
  });

  bool canAccess(String requesterId, {bool isAuthenticated = false}) {
    return switch (kind) {
      QModuleKind.public => true,
      QModuleKind.private => false,
      QModuleKind.shared =>
        allowedAppIds.contains(requesterId) || allowedAppIds.contains('*'),
    };
  }

  factory QModulePolicy.fromMap(Map<String, dynamic> map) {
    final kindStr = map['kind']?.toString() ?? 'private';
    final kind = switch (kindStr) {
      'public' => QModuleKind.public,
      'shared' => QModuleKind.shared,
      _ => QModuleKind.private,
    };
    final allowed = map['allowedApps'];
    return QModulePolicy(
      kind: kind,
      allowedAppIds: allowed is List
          ? allowed.map((e) => e.toString()).toList(growable: false)
          : const [],
      requireAuth: map['requireAuth'] == true,
    );
  }
}

/// A slice of static state baked directly into the engine.
///
/// Static values (e.g. theme colors, feature flags) are baked at
/// registration time and stored in the encrypted node blob.
/// They are read at pointer-dereference speed from the mmap view.
///
/// Dynamic values (bound to a data source at runtime) have [isStatic] = false
/// and are managed by the external data state engine.
@immutable
class QSliceConfig {
  final String sliceName;

  /// The fields of this slice.
  final Map<String, QSliceField> fields;

  const QSliceConfig({
    required this.sliceName,
    required this.fields,
  });

  factory QSliceConfig.fromMap(String name, Map<String, dynamic> map) {
    final fields = <String, QSliceField>{};
    map.forEach((key, value) {
      if (value is Map) {
        fields[key] = QSliceField.fromMap(key, Map<String, dynamic>.from(value));
      } else {
        // Shorthand: `color: '#fff'` → static field
        fields[key] = QSliceField(
          fieldName: key,
          isStatic: true,
          staticValue: value,
          type: _inferType(value),
        );
      }
    });
    return QSliceConfig(sliceName: name, fields: fields);
  }

  static String _inferType(dynamic value) {
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is String) return 'String';
    if (value is List) return 'List';
    if (value is Map) return 'Map';
    return 'dynamic';
  }
}

@immutable
class QSliceField {
  final String fieldName;

  /// true = value is baked into the engine node at registration time.
  /// false = value is managed by the external data state engine.
  final bool isStatic;

  /// Only valid when [isStatic] = true.
  final dynamic staticValue;

  /// Default fallback value.
  final dynamic defaultValue;

  /// Dart type name.
  final String type;

  /// For dynamic fields: the data source ID that provides the value.
  final String? dataSourceId;

  const QSliceField({
    required this.fieldName,
    required this.isStatic,
    required this.type,
    this.staticValue,
    this.defaultValue,
    this.dataSourceId,
  });

  factory QSliceField.fromMap(String name, Map<String, dynamic> map) {
    final isStatic = map['static'] == true || !map.containsKey('dataSource');
    return QSliceField(
      fieldName: name,
      isStatic: isStatic,
      type: map['type']?.toString() ?? 'dynamic',
      staticValue: isStatic ? map['value'] ?? map['default'] : null,
      dataSourceId: map['dataSource']?.toString(),
    );
  }
}

/// A reference to an external data source.
@immutable
class QDataSourceConfig {
  final String id;
  final String type; // 'http', 'firebase', 'sqlite', 'mock', etc.
  final Map<String, dynamic> config;
  final String? endpoint;
  final String? method;
  final Map<String, String>? headers;
  final Map<String, String>? queryParams;
  final dynamic body;
  final int cacheSeconds;
  final bool requiresAuth;

  const QDataSourceConfig({
    required this.id,
    required this.type,
    this.config = const {},
    this.endpoint,
    this.method,
    this.headers,
    this.queryParams,
    this.body,
    this.cacheSeconds = 0,
    this.requiresAuth = false,
  });

  factory QDataSourceConfig.fromMap(String id, Map<String, dynamic> map) {
    return QDataSourceConfig(
      id: id,
      type: map['type']?.toString() ?? 'http',
      config: Map<String, dynamic>.from(map)..remove('type'),
    );
  }
}

/// A bundled config group — lives in `public/`, `private/`, or `shared/`.
///
/// Contains: slices, dataSources, macros, schemas, actions, imports.
/// Nothing else lives in those folders.
@immutable
class QModuleNode extends QBaseNode {
  final String moduleId;
  final String? appId;
  final String? assetPath;

  /// Access control.
  final QModulePolicy policy;

  /// Slice configs — static values baked in, dynamic values external.
  final List<QSliceConfig> slices;

  /// Data source declarations.
  final List<QDataSourceConfig> dataSources;

  /// Macro definitions.
  final Map<String, dynamic> macros;

  /// Schema definitions.
  final Map<String, dynamic> schemas;

  /// Action definitions.
  final Map<String, dynamic> actions;

  /// IDs of other modules this one imports.
  final List<String> imports;

  /// Pre-baked static state values (extracted from slices at registration time).
  /// Stored as an ordered flat list for O(1) index-based access via mmap.
  final List<dynamic> _bakedStaticValues;

  const QModuleNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.moduleId,
    required this.policy,
    required this.slices,
    required this.dataSources,
    required this.macros,
    required this.schemas,
    required this.actions,
    required this.imports,
    required List<dynamic> bakedStaticValues,
    this.appId,
    this.assetPath,
  })  : _bakedStaticValues = bakedStaticValues,
        super(kind: QNodeKind.module);

  List<dynamic> get bakedStaticValues => List.unmodifiable(_bakedStaticValues);

  QModuleKind get moduleKind => policy.kind;

  /// Read a baked static state value by field index.
  /// O(1) — no allocation, no JSON parse, direct list access.
  T? staticValue<T>(int fieldIndex) {
    if (fieldIndex < 0 || fieldIndex >= _bakedStaticValues.length) return null;
    final v = _bakedStaticValues[fieldIndex];
    return v is T ? v : null;
  }

  /// Lookup baked static value by slice name + field name.
  T? staticValueByName<T>(String sliceName, String fieldName) {
    int idx = 0;
    for (final slice in slices) {
      for (final entry in slice.fields.entries) {
        if (slice.sliceName == sliceName && entry.key == fieldName) {
          return staticValue<T>(idx);
        }
        if (entry.value.isStatic) idx++;
      }
    }
    return null;
  }

  @override
  int get weight {
    int w = 256;
    w += moduleId.length * 2;
    w += slices.length * 128;
    w += dataSources.length * 64;
    w += macros.length * 64;
    w += schemas.length * 64;
    w += _bakedStaticValues.length * 32;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §15 — APP NODE
// ─────────────────────────────────────────────────────────────────────────────

/// Router config for an isolated sub-app.
@immutable
class QAppRouterConfig {
  final String initialRoute;
  final String pagesDir;
  final bool deepLinkEnabled;
  final Map<String, dynamic> raw;

  const QAppRouterConfig({
    this.initialRoute = '/',
    this.pagesDir = 'pages',
    this.deepLinkEnabled = false,
    this.raw = const {},
  });

  factory QAppRouterConfig.fromMap(Map<String, dynamic> map) {
    return QAppRouterConfig(
      initialRoute: map['initialRoute']?.toString() ?? '/',
      pagesDir: map['pagesDir']?.toString() ?? 'pages',
      deepLinkEnabled: map['deepLink'] == true,
      raw: map,
    );
  }
}

/// An isolated sub-application with its own router and module scoping.
///
/// An app has:
///   • `pages/` — file-path-based router (fully isolated from parent router)
///   • `public/` — modules accessible from any app
///   • `private/` — modules only for this app
///   • `shared/` — modules accessible from allowed apps only (policy-gated)
///   • Any other folders for reusable config (components/, services/, etc.)
///     — flexible, not enforced by the engine
///
/// Cross-app navigation must go through a `public` or `shared` module.
@immutable
class QAppNode extends QBaseNode {
  final String appId;
  final String? assetPath;
  final QAppRouterConfig routerConfig;

  /// All pages registered under this app's `pages/` folder.
  final List<QNodeRef<QPageNode>> pageRefs;

  /// Modules in `public/` — accessible from any app.
  final List<QNodeRef<QModuleNode>> publicModuleRefs;

  /// Modules in `private/` — only accessible from this app.
  final List<QNodeRef<QModuleNode>> privateModuleRefs;

  /// Modules in `shared/` — accessible from allowed apps.
  final List<QNodeRef<QModuleNode>> sharedModuleRefs;

  /// Root-level layout for all pages in this app (if `pages/_layout.yaml` exists).
  final QNodeRef<QLayoutNode>? rootLayoutRef;

  /// Root-level error boundary.
  final QNodeRef<QErrorNode>? rootErrorRef;

  /// Root-level loading node.
  final QNodeRef<QLoadingNode>? rootLoadingRef;

  /// Root-level not-found node.
  final QNodeRef<QNotFoundNode>? rootNotFoundRef;

  /// Root-level meta node.
  final QNodeRef<QMetaNode>? rootMetaRef;

  /// Root-level middleware (outermost in the chain).
  final QNodeRef<QMiddlewareNode>? rootMiddlewareRef;

  const QAppNode({
    required super.nodeId,
    required super.version,
    required super.sealedAt,
    required super.flags,
    required this.appId,
    required this.routerConfig,
    required this.pageRefs,
    required this.publicModuleRefs,
    required this.privateModuleRefs,
    required this.sharedModuleRefs,
    this.assetPath,
    this.rootLayoutRef,
    this.rootErrorRef,
    this.rootLoadingRef,
    this.rootNotFoundRef,
    this.rootMetaRef,
    this.rootMiddlewareRef,
  }) : super(kind: QNodeKind.app);

  int get pageCount => pageRefs.length;
  int get moduleCount =>
      publicModuleRefs.length + privateModuleRefs.length + sharedModuleRefs.length;

  @override
  int get weight {
    int w = 256;
    w += appId.length * 2;
    w += pageRefs.length * 8;
    w += publicModuleRefs.length * 8;
    w += privateModuleRefs.length * 8;
    w += sharedModuleRefs.length * 8;
    return w;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §16 — NODE STORE — single source of truth (in-memory resolved layer)
// ─────────────────────────────────────────────────────────────────────────────

/// Internal in-memory node store.
/// NOT part of the public API — only accessed via [QNodeRef.resolveSync] / [QNodeRef.resolve].
///
/// QNodeStore holds every deserialized node that is currently in memory.
/// Backed by [QMemoryCache] + [QDiskStore] (via [QNodeRegistry]).
class QNodeStore {
  static final QNodeStore instance = QNodeStore._();
  QNodeStore._();

  // Internal typed maps for O(1) synchronous access.
  final Map<int, QPageNode> _pages = {};
  final Map<int, QAppNode> _apps = {};
  final Map<int, QModuleNode> _modules = {};
  final Map<int, QLayoutNode> _layouts = {};
  final Map<int, QMetaNode> _metas = {};
  final Map<int, QMiddlewareNode> _middlewares = {};
  final Map<int, QErrorNode> _errors = {};
  final Map<int, QLoadingNode> _loadings = {};
  final Map<int, QNotFoundNode> _notFounds = {};

  /// Callback to load a node from disk when not in memory.
  /// Set by [QNodeRegistry] during initialization.
  Future<QBaseNode?> Function(int nodeId)? _loader;

  void setLoader(Future<QBaseNode?> Function(int nodeId) loader) {
    _loader = loader;
  }

  /// Synchronous resolve — returns null if not in memory.
  T? resolveSync<T extends QBaseNode>(int nodeId) {
    final map = _mapFor<T>();
    return map[nodeId] as T?;
  }

  /// Async resolve — loads from disk if not in memory.
  Future<T?> resolve<T extends QBaseNode>(int nodeId) async {
    final inMemory = resolveSync<T>(nodeId);
    if (inMemory != null) return inMemory;

    final loader = _loader;
    if (loader == null) return null;

    final loaded = await loader(nodeId);
    if (loaded == null) return null;

    put(loaded);
    return loaded as T?;
  }

  /// Store a node in the appropriate typed map.
  void put(QBaseNode node) {
    switch (node.kind) {
      case QNodeKind.page:
        _pages[node.nodeId] = node as QPageNode;
      case QNodeKind.app:
        _apps[node.nodeId] = node as QAppNode;
      case QNodeKind.module:
        _modules[node.nodeId] = node as QModuleNode;
      case QNodeKind.layout:
        _layouts[node.nodeId] = node as QLayoutNode;
      case QNodeKind.meta:
        _metas[node.nodeId] = node as QMetaNode;
      case QNodeKind.middleware:
        _middlewares[node.nodeId] = node as QMiddlewareNode;
      case QNodeKind.error:
        _errors[node.nodeId] = node as QErrorNode;
      case QNodeKind.loading:
        _loadings[node.nodeId] = node as QLoadingNode;
      case QNodeKind.notFound:
        _notFounds[node.nodeId] = node as QNotFoundNode;
    }
  }

  /// Remove a node from memory.
  void evict(int nodeId) {
    _pages.remove(nodeId);
    _apps.remove(nodeId);
    _modules.remove(nodeId);
    _layouts.remove(nodeId);
    _metas.remove(nodeId);
    _middlewares.remove(nodeId);
    _errors.remove(nodeId);
    _loadings.remove(nodeId);
    _notFounds.remove(nodeId);
  }

  /// Remove all nodes from memory.
  void evictAll() {
    _pages.clear();
    _apps.clear();
    _modules.clear();
    _layouts.clear();
    _metas.clear();
    _middlewares.clear();
    _errors.clear();
    _loadings.clear();
    _notFounds.clear();
  }

  bool containsSync(int nodeId) {
    return _pages.containsKey(nodeId) ||
        _apps.containsKey(nodeId) ||
        _modules.containsKey(nodeId) ||
        _layouts.containsKey(nodeId) ||
        _metas.containsKey(nodeId) ||
        _middlewares.containsKey(nodeId) ||
        _errors.containsKey(nodeId) ||
        _loadings.containsKey(nodeId) ||
        _notFounds.containsKey(nodeId);
  }

  int get totalLoaded =>
      _pages.length +
      _apps.length +
      _modules.length +
      _layouts.length +
      _metas.length +
      _middlewares.length +
      _errors.length +
      _loadings.length +
      _notFounds.length;

  // Typed maps for generic resolution
  Map<int, dynamic> _mapFor<T extends QBaseNode>() {
    if (T == QPageNode) return _pages;
    if (T == QAppNode) return _apps;
    if (T == QModuleNode) return _modules;
    if (T == QLayoutNode) return _layouts;
    if (T == QMetaNode) return _metas;
    if (T == QMiddlewareNode) return _middlewares;
    if (T == QErrorNode) return _errors;
    if (T == QLoadingNode) return _loadings;
    if (T == QNotFoundNode) return _notFounds;
    return {};
  }

  // Typed list views for registry listing
  List<QPageNode> get pages => List.unmodifiable(_pages.values);
  List<QAppNode> get apps => List.unmodifiable(_apps.values);
  List<QModuleNode> get modules => List.unmodifiable(_modules.values);
  List<QLayoutNode> get layouts => List.unmodifiable(_layouts.values);
  List<QMetaNode> get metas => List.unmodifiable(_metas.values);
  List<QMiddlewareNode> get middlewares => List.unmodifiable(_middlewares.values);
  List<QErrorNode> get errors => List.unmodifiable(_errors.values);
  List<QLoadingNode> get loadings => List.unmodifiable(_loadings.values);
  List<QNotFoundNode> get notFounds => List.unmodifiable(_notFounds.values);
}

// ─────────────────────────────────────────────────────────────────────────────
// §17 — SNAPSHOT & STATS
// ─────────────────────────────────────────────────────────────────────────────

@immutable
class QEngineSnapshot {
  final int pageCount;
  final int appCount;
  final int moduleCount;
  final int layoutCount;
  final int metaCount;
  final int middlewareCount;
  final int errorCount;
  final int loadingCount;
  final int notFoundCount;
  final int nodesLoadedInMemory;
  final QCacheStats cacheStats;
  final DateTime takenAt;

  const QEngineSnapshot({
    required this.pageCount,
    required this.appCount,
    required this.moduleCount,
    required this.layoutCount,
    required this.metaCount,
    required this.middlewareCount,
    required this.errorCount,
    required this.loadingCount,
    required this.notFoundCount,
    required this.nodesLoadedInMemory,
    required this.cacheStats,
    required this.takenAt,
  });

  int get totalNodes =>
      pageCount +
      appCount +
      moduleCount +
      layoutCount +
      metaCount +
      middlewareCount +
      errorCount +
      loadingCount +
      notFoundCount;

  @override
  String toString() =>
      'QEngineSnapshot(total=$totalNodes, inMemory=$nodesLoadedInMemory, '
      'pages=$pageCount, layouts=$layoutCount, modules=$moduleCount)';
}

@immutable
class QCacheStats {
  final int l1Hits;
  final int l1Misses;
  final int l2Hits;
  final int l2Misses;
  final int diskHits;
  final int diskMisses;
  final int evictions;
  final int currentL1Count;
  final int currentL2Count;
  final int currentDiskCount;
  final int totalWeightBytes;

  const QCacheStats({
    required this.l1Hits,
    required this.l1Misses,
    required this.l2Hits,
    required this.l2Misses,
    required this.diskHits,
    required this.diskMisses,
    required this.evictions,
    required this.currentL1Count,
    required this.currentL2Count,
    required this.currentDiskCount,
    required this.totalWeightBytes,
  });

  double get l1HitRate =>
      (l1Hits + l1Misses) == 0 ? 0 : l1Hits / (l1Hits + l1Misses);
  double get l2HitRate =>
      (l2Hits + l2Misses) == 0 ? 0 : l2Hits / (l2Hits + l2Misses);

  Map<String, dynamic> toMap() => {
        'l1': {'hits': l1Hits, 'misses': l1Misses, 'hitRate': l1HitRate, 'count': currentL1Count},
        'l2': {'hits': l2Hits, 'misses': l2Misses, 'hitRate': l2HitRate, 'count': currentL2Count},
        'disk': {'hits': diskHits, 'misses': diskMisses, 'count': currentDiskCount},
        'evictions': evictions,
        'totalWeightBytes': totalWeightBytes,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// §18 — EXCEPTIONS
// ─────────────────────────────────────────────────────────────────────────────

class QAccessDeniedException implements Exception {
  final String requesterId;
  final String moduleId;
  final String reason;

  const QAccessDeniedException({
    required this.requesterId,
    required this.moduleId,
    required this.reason,
  });

  @override
  String toString() =>
      'QAccessDeniedException: "$requesterId" cannot access module '
      '"$moduleId". Reason: $reason';
}

class QNodeNotFoundException implements Exception {
  final int nodeId;
  final String? hint;

  const QNodeNotFoundException(this.nodeId, {this.hint});

  @override
  String toString() =>
      'QNodeNotFoundException: Node $nodeId not found.${hint != null ? ' Hint: $hint' : ''}';
}

class QNodeSealedException implements Exception {
  final int nodeId;
  const QNodeSealedException(this.nodeId);

  @override
  String toString() =>
      'QNodeSealedException: Node $nodeId is read-only after sealing. '
      'Use upsert() to create a new version.';
}

class QCircularRefException implements Exception {
  final List<int> cycle;
  const QCircularRefException(this.cycle);

  @override
  String toString() =>
      'QCircularRefException: Circular reference detected: '
      '${cycle.map((id) => id.toString()).join(' → ')}';
}
