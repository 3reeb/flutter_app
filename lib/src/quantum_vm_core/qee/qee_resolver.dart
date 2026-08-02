/*
 * ============================================================================
 * File: qee_resolver.dart
 * 
 * Description:
 * Executes graph resolution logic post-node-registration. It pre-computes 
 * nested composition chains (e.g., layout wrapping, middleware pipelining) and 
 * override resolutions (e.g., most-specific meta tags), enabling instant O(1) 
 * resolution during UI rendering.
 * 
 * Key Components:
 * - QNodeResolver: Core class that builds a directory tree context and assigns 
 *   pointers (parentLayoutRef, 
extRef) between related nodes.
 * 
 * Dependencies/Relationships:
 * Intercepts pending nodes from QNodeRegistry and processes them prior to 
 * their final sealing.
 * 
 * Notes:
 * Also responsible for detecting circular references (e.g., recursive layouts) 
 * and aborting registration appropriately.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE RESOLVER — qee_resolver.dart
//
// Node graph resolution engine.
//
// Responsibility:
//   After a batch of nodes is registered, the resolver:
//     1. Builds a dependency graph of all nodes.
//     2. Resolves all QNodeRef<T> pointers (links parent layouts, middleware
//        chains, meta inheritance, etc.).
//     3. Pre-computes all composition chains so lookup at render time
//        is O(1) with no graph traversal.
//     4. Bakes static slice values into QModuleNode._bakedStaticValues.
//     5. Detects circular references.
//
// Resolution rules:
//   LAYOUT:     composition chain — innermost QLayoutNode has parentLayoutRef
//               pointing to the next-outer layout. Chain built from
//               directory structure (root → leaf).
//   MIDDLEWARE: composition chain — outermost QMiddlewareNode has nextRef
//               pointing to next-inner. Chain built from root → leaf.
//               A page's middlewareRef = outermost in its chain.
//   META:       override — most-specific (deepest directory) wins.
//               Pages carry the metaRef of the deepest applicable meta node.
//   ERROR:      override — most-specific wins.
//   LOADING:    override — most-specific wins.
//   NOT_FOUND:  override — most-specific wins.
//   PAGE:       references resolved layout/meta/middleware/error/loading/notFound.
// ════════════════════════════════════════════════════════════════════════════

import 'qee_node_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — DIRECTORY TREE MODEL
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single directory in the pages tree.
/// Built from asset paths during resolution.
class _DirNode {
  final String path; // e.g. 'pages/users/'

  // Nodes at this directory level (null if not defined here)
  int? layoutNodeId;
  int? middlewareNodeId;
  int? metaNodeId;
  int? errorNodeId;
  int? loadingNodeId;
  int? notFoundNodeId;

  // Children directories
  final Map<String, _DirNode> children = {};

  // Pages at this directory level
  final List<int> pageNodeIds = [];

  _DirNode(this.path);
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — RESOLUTION CONTEXT
// ─────────────────────────────────────────────────────────────────────────────

/// Accumulated resolution state as we walk down the directory tree.
class _ResolutionCtx {
  // Layout chain: ordered list from outermost to innermost
  final List<int> layoutChain; // nodeIds, index 0 = outermost

  // Middleware chain: ordered list from outermost to innermost
  final List<int> middlewareChain;

  // Most specific override winners (deepest so far)
  int? metaNodeId;
  int? errorNodeId;
  int? loadingNodeId;
  int? notFoundNodeId;

  _ResolutionCtx({
    List<int>? layoutChain,
    List<int>? middlewareChain,
    this.metaNodeId,
    this.errorNodeId,
    this.loadingNodeId,
    this.notFoundNodeId,
  })  : layoutChain = layoutChain ?? [],
        middlewareChain = middlewareChain ?? [];

  _ResolutionCtx extend(_DirNode dir) {
    // Layout and middleware COMPOSE (append)
    final newLayoutChain = [
      ...layoutChain,
      if (dir.layoutNodeId != null) dir.layoutNodeId!,
    ];
    final newMiddlewareChain = [
      ...middlewareChain,
      if (dir.middlewareNodeId != null) dir.middlewareNodeId!,
    ];

    // Overridable: most specific (current dir) wins if defined
    return _ResolutionCtx(
      layoutChain: newLayoutChain,
      middlewareChain: newMiddlewareChain,
      metaNodeId: dir.metaNodeId ?? metaNodeId,
      errorNodeId: dir.errorNodeId ?? errorNodeId,
      loadingNodeId: dir.loadingNodeId ?? loadingNodeId,
      notFoundNodeId: dir.notFoundNodeId ?? notFoundNodeId,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — RESOLVER
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves all cross-node references for a set of registered nodes.
///
/// Returns a [QResolutionResult] containing:
///   - Updated nodes with all refs pre-resolved.
///   - Layout chain pairs (inner → parent).
///   - Middleware chain pairs (this → next).
class QNodeResolver {
  static final QNodeResolver instance = QNodeResolver._();
  QNodeResolver._();

  /// Resolve all refs for the given nodes.
  ///
  /// [allNodes]: all currently registered nodes (used for lookups).
  ///
  /// Returns [QResolutionResult] — the resolved/updated nodes.
  QResolutionResult resolve(
    List<QBaseNode> pendingNodes,
    Map<int, QBaseNode> allNodes,
    {String? appId}
  ) {
    final result = QResolutionResult();

    // Separate by kind
    final pages = <int, QPageNode>{};
    final layouts = <int, QLayoutNode>{};
    final middlewares = <int, QMiddlewareNode>{};
    final metas = <int, QMetaNode>{};
    final errors = <int, QErrorNode>{};
    final loadings = <int, QLoadingNode>{};
    final notFounds = <int, QNotFoundNode>{};

    for (final node in pendingNodes) {
      switch (node.kind) {
        case QNodeKind.page:       pages[node.nodeId] = node as QPageNode;
        case QNodeKind.layout:     layouts[node.nodeId] = node as QLayoutNode;
        case QNodeKind.middleware: middlewares[node.nodeId] = node as QMiddlewareNode;
        case QNodeKind.meta:       metas[node.nodeId] = node as QMetaNode;
        case QNodeKind.error:      errors[node.nodeId] = node as QErrorNode;
        case QNodeKind.loading:    loadings[node.nodeId] = node as QLoadingNode;
        case QNodeKind.notFound:   notFounds[node.nodeId] = node as QNotFoundNode;
        case QNodeKind.module:
          _bakeStaticSlices(node as QModuleNode, result);
        case QNodeKind.app:
          result.resolvedNodes[node.nodeId] = node;
        default:
          result.resolvedNodes[node.nodeId] = node;
      }
    }

    // Build directory tree from all page-level nodes
    final tree = _buildDirTree(layouts, middlewares, metas, errors, loadings, notFounds);

    // Resolve layout chains (build parentLayoutRef links)
    _resolveLayoutChains(layouts, tree, result);

    // Resolve middleware chains (build nextRef links)
    _resolveMiddlewareChains(middlewares, tree, result);

    // Resolve page refs (walk tree to find applicable nodes)
    _resolvePages(pages, tree, result, appId: appId);

    // Check for circular references
    _detectCircularLayouts(result.resolvedNodes);
    _detectCircularMiddlewares(result.resolvedNodes);

    return result;
  }

  // ── Directory tree builder ────────────────────────────────────────────────

  _DirNode _buildDirTree(
    Map<int, QLayoutNode> layouts,
    Map<int, QMiddlewareNode> middlewares,
    Map<int, QMetaNode> metas,
    Map<int, QErrorNode> errors,
    Map<int, QLoadingNode> loadings,
    Map<int, QNotFoundNode> notFounds,
  ) {
    final root = _DirNode('');

    void insert(_DirNode current, String path, void Function(_DirNode) setter) {
      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      var node = current;
      for (final seg in segments) {
        node = node.children.putIfAbsent(seg, () => _DirNode('${node.path}$seg/'));
      }
      setter(node);
    }

    for (final n in layouts.values) {
      insert(root, n.directoryPath, (d) => d.layoutNodeId = n.nodeId);
    }
    for (final n in middlewares.values) {
      insert(root, n.directoryPath, (d) => d.middlewareNodeId = n.nodeId);
    }
    for (final n in metas.values) {
      insert(root, n.directoryPath, (d) => d.metaNodeId = n.nodeId);
    }
    for (final n in errors.values) {
      insert(root, n.directoryPath, (d) => d.errorNodeId = n.nodeId);
    }
    for (final n in loadings.values) {
      insert(root, n.directoryPath, (d) => d.loadingNodeId = n.nodeId);
    }
    for (final n in notFounds.values) {
      insert(root, n.directoryPath, (d) => d.notFoundNodeId = n.nodeId);
    }

    return root;
  }

  // ── Layout chain resolution ───────────────────────────────────────────────
  // Walk tree: parent layout → child layout. child.parentLayoutRef = parent.

  void _resolveLayoutChains(
    Map<int, QLayoutNode> layouts,
    _DirNode root,
    QResolutionResult result,
  ) {
    void walkLayouts(_DirNode dir, int? parentLayoutId) {
      final currentLayoutId = dir.layoutNodeId;

      if (currentLayoutId != null) {
        final layout = layouts[currentLayoutId]!;
        // Link this layout to its parent
        final updated = QLayoutNode(
          nodeId: layout.nodeId,
          version: layout.version,
          sealedAt: layout.sealedAt,
          flags: layout.flags | QNodeFlags.isSealed,
          layoutId: layout.layoutId,
          directoryPath: layout.directoryPath,
          appId: layout.appId,
          assetPath: layout.assetPath,
          parentLayoutRef: parentLayoutId != null
              ? QNodeRef<QLayoutNode>(parentLayoutId)
              : null,
          body: layout.body,
        );
        result.resolvedNodes[updated.nodeId] = updated;
      }

      // Recurse into children
      for (final child in dir.children.values) {
        walkLayouts(child, currentLayoutId ?? parentLayoutId);
      }
    }

    walkLayouts(root, null);

    // Add unresolved layouts (those not in any directory — shouldn't happen)
    for (final layout in layouts.values) {
      result.resolvedNodes.putIfAbsent(layout.nodeId, () => layout);
    }
  }

  // ── Middleware chain resolution ───────────────────────────────────────────
  // Walk tree: parent middleware → child middleware. parent.nextRef = child.

  void _resolveMiddlewareChains(
    Map<int, QMiddlewareNode> middlewares,
    _DirNode root,
    QResolutionResult result,
  ) {
    void walkMiddlewares(_DirNode dir, int? childMiddlewareId) {
      final currentId = dir.middlewareNodeId;

      if (currentId != null) {
        final mw = middlewares[currentId]!;
        // This middleware's nextRef = the inner (deeper) middleware
        // We resolve this in a second pass — first pass collects the chain.
        // For now, store as-is; second pass fills nextRef.
        result.resolvedNodes.putIfAbsent(mw.nodeId, () => mw);
      }

      // Recurse first (depth-first to collect children)
      for (final child in dir.children.values) {
        walkMiddlewares(child, currentId);
      }

      // Now that children are walked, update this node's nextRef
      if (currentId != null) {
        final mw = middlewares[currentId]!;
        // Find the direct child's middleware
        int? directChildId;
        for (final child in dir.children.values) {
          if (child.middlewareNodeId != null) {
            directChildId = child.middlewareNodeId;
            break;
          }
        }

        if (directChildId != null) {
          final updated = QMiddlewareNode(
            nodeId: mw.nodeId,
            version: mw.version,
            sealedAt: mw.sealedAt,
            flags: mw.flags | QNodeFlags.isSealed,
            middlewareId: mw.middlewareId,
            directoryPath: mw.directoryPath,
            appId: mw.appId,
            assetPath: mw.assetPath,
            nextRef: QNodeRef<QMiddlewareNode>(directChildId),
            steps: mw.steps,
          );
          result.resolvedNodes[updated.nodeId] = updated;
        }
      }
    }

    walkMiddlewares(root, null);

    // Ensure all middlewares are in result
    for (final mw in middlewares.values) {
      result.resolvedNodes.putIfAbsent(mw.nodeId, () => mw);
    }
  }

  // ── Page resolution ───────────────────────────────────────────────────────

  void _resolvePages(
    Map<int, QPageNode> pages,
    _DirNode root,
    QResolutionResult result,
    {String? appId}
  ) {
    // For each page, walk its directory path upward to collect context
    for (final page in pages.values) {
      final ctx = _walkToPage(root, page.assetPath ?? page.routePath);
      final resolved = _applyContextToPage(page, ctx, result);
      result.resolvedNodes[resolved.nodeId] = resolved;
    }
  }

  _ResolutionCtx _walkToPage(_DirNode root, String assetPath) {
    // Strip 'pages/' prefix and get directory segments
    var path = assetPath;
    if (path.startsWith('pages/')) path = path.substring(6);

    final segments = path.split('/');
    // Last segment is the file itself — walk to its parent directory
    final dirSegments = segments.length > 1
        ? segments.sublist(0, segments.length - 1)
        : <String>[];

    var ctx = _ResolutionCtx().extend(root);
    var currentDir = root;

    for (final seg in dirSegments) {
      final child = currentDir.children[seg] ??
          // Try without extension / param expansion
          currentDir.children.entries
              .firstWhere(
                (e) => _matchSegment(e.key, seg),
                orElse: () => MapEntry(seg, _DirNode('')),
              )
              .value;
      ctx = ctx.extend(child);
      currentDir = child;
    }

    return ctx;
  }

  bool _matchSegment(String pattern, String actual) {
    if (pattern == actual) return true;
    if (pattern.startsWith('[') && pattern.endsWith(']')) return true;
    if (pattern.startsWith('(') && pattern.endsWith(')')) return true;
    return false;
  }

  QPageNode _applyContextToPage(
    QPageNode page,
    _ResolutionCtx ctx,
    QResolutionResult result,
  ) {
    // Innermost layout in the chain
    final innermostLayoutId = ctx.layoutChain.isNotEmpty
        ? ctx.layoutChain.last
        : null;

    // Outermost middleware in the chain
    final outermostMiddlewareId = ctx.middlewareChain.isNotEmpty
        ? ctx.middlewareChain.first
        : null;

    return QPageNode(
      nodeId: page.nodeId,
      version: page.version,
      sealedAt: page.sealedAt,
      flags: page.flags | QNodeFlags.isSealed,
      routePath: page.routePath,
      appId: page.appId,
      assetPath: page.assetPath,
      paramNames: page.paramNames,
      layoutRef: innermostLayoutId != null
          ? QNodeRef<QLayoutNode>(innermostLayoutId)
          : null,
      metaRef: ctx.metaNodeId != null
          ? QNodeRef<QMetaNode>(ctx.metaNodeId!)
          : null,
      middlewareRef: outermostMiddlewareId != null
          ? QNodeRef<QMiddlewareNode>(outermostMiddlewareId)
          : null,
      errorRef: ctx.errorNodeId != null
          ? QNodeRef<QErrorNode>(ctx.errorNodeId!)
          : null,
      loadingRef: ctx.loadingNodeId != null
          ? QNodeRef<QLoadingNode>(ctx.loadingNodeId!)
          : null,
      notFoundRef: ctx.notFoundNodeId != null
          ? QNodeRef<QNotFoundNode>(ctx.notFoundNodeId!)
          : null,
      body: page.body,
    );
  }

  // ── Static state baking ───────────────────────────────────────────────────

  void _bakeStaticSlices(QModuleNode module, QResolutionResult result) {
    final baked = <dynamic>[];
    for (final slice in module.slices) {
      for (final field in slice.fields.values) {
        if (field.isStatic) {
          baked.add(field.staticValue);
        }
      }
    }

    final updated = QModuleNode(
      nodeId: module.nodeId,
      version: module.version,
      sealedAt: module.sealedAt,
      flags: module.flags | QNodeFlags.isSealed,
      moduleId: module.moduleId,
      appId: module.appId,
      assetPath: module.assetPath,
      policy: module.policy,
      slices: module.slices,
      dataSources: module.dataSources,
      macros: module.macros,
      schemas: module.schemas,
      actions: module.actions,
      imports: module.imports,
      bakedStaticValues: baked,
    );

    result.resolvedNodes[updated.nodeId] = updated;
  }

  // ── Circular reference detection ──────────────────────────────────────────

  void _detectCircularLayouts(Map<int, QBaseNode> nodes) {
    final layouts = nodes.values.whereType<QLayoutNode>();
    for (final layout in layouts) {
      final visited = <int>{};
      QLayoutNode? current = layout;
      while (current != null) {
        if (!visited.add(current.nodeId)) {
          throw QCircularRefException(visited.toList());
        }
        final parentRef = current.parentLayoutRef;
        current = parentRef != null
            ? nodes[parentRef.nodeId] as QLayoutNode?
            : null;
      }
    }
  }

  void _detectCircularMiddlewares(Map<int, QBaseNode> nodes) {
    final middlewares = nodes.values.whereType<QMiddlewareNode>();
    for (final mw in middlewares) {
      final visited = <int>{};
      QMiddlewareNode? current = mw;
      while (current != null) {
        if (!visited.add(current.nodeId)) {
          throw QCircularRefException(visited.toList());
        }
        final nextRef = current.nextRef;
        current = nextRef != null
            ? nodes[nextRef.nodeId] as QMiddlewareNode?
            : null;
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — RESOLUTION RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a resolution pass.
class QResolutionResult {
  /// All resolved/updated nodes, keyed by nodeId.
  /// Merge this into the node store after resolution.
  final Map<int, QBaseNode> resolvedNodes = {};

  /// Any errors encountered during resolution.
  final List<String> warnings = [];

  bool get hasWarnings => warnings.isNotEmpty;
}
