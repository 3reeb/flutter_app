/*
 * ============================================================================
 * File: qee_registry.dart
 * 
 * Description:
 * The primary singleton API (QEE / QNodeRegistry) orchestrating all CRUD 
 * operations for engine nodes. It wraps caching, encryption, serialization, and 
 * storage behind a simple, unified interface to ensure data integrity and 
 * invariant adherence.
 * 
 * Key Components:
 * - QNodeRegistry: Public facade for bootstrapping and dispatching node updates.
 * - Config DTOs (e.g., QPageConfig): Data-transfer objects defining node inputs.
 * 
 * Dependencies/Relationships:
 * Coordinates QDiskStore, QMemoryCache, QNodeStore, QNodeResolver, 
 * QCryptoEngine, and QNodeEncoder.
 * 
 * Notes:
 * Acts as the definitive source of truth. Nodes must not be directly pushed 
 * into caches or disk without passing through this registry.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE REGISTRY — qee_registry.dart
//
// The single public API for all QEE operations.
// This is the ONLY entry point to the engine — no other code reaches
// directly into QDiskStore, QMemoryCache, or QNodeStore.
//
// Singleton: QNodeRegistry.instance
// Convenience alias: QEE (same object)
//
// All create/upsert operations:
//   validate → serialize → resolve → encrypt → disk write → L2 cache
//
// All read operations:
//   L1 check → L2 check → disk load → decrypt → deserialize → L1+L2 populate
//
// All delete operations:
//   evict from L1/L2 → disk mark-free → remove from node store
//
// Single-instance invariant:
//   Same nodeId always resolves to the same object reference in memory.
//   If node is already in store, return existing ref — never allocate twice.
//
// Sealed invariant:
//   Nodes are immutable after registration. update/upsert = delete + re-create.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'qee_crypto.dart';
import 'qee_disk_store_stub.dart' show QDiskStore; // abstract interface
import 'qee_memory_cache.dart';
import 'qee_node_types.dart';
import 'qee_resolver.dart';
import 'qee_serializer.dart';

export 'qee_node_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CONFIG DTOs (input to create/upsert methods)
// ─────────────────────────────────────────────────────────────────────────────

/// Input config for registering a page.
@immutable
class QPageConfig {
  final String routePath;
  final String? appId;
  final String? assetPath;
  final List<String> paramNames;
  final bool isCatchAll;
  final QPageBody? body;
  final Map<String, dynamic> pageProps;

  const QPageConfig({
    required this.routePath,
    this.appId,
    this.assetPath,
    this.paramNames = const [],
    this.isCatchAll = false,
    this.body,
    this.pageProps = const {},
  });
}

/// Input config for registering a layout.
@immutable
class QLayoutConfig {
  final String layoutId;
  final String directoryPath;
  final String? appId;
  final String? assetPath;
  final QPageBody? body;

  const QLayoutConfig({
    required this.layoutId,
    required this.directoryPath,
    this.appId,
    this.assetPath,
    this.body,
  });
}

/// Input config for registering a middleware.
@immutable
class QMiddlewareConfig {
  final String middlewareId;
  final String directoryPath;
  final String? appId;
  final String? assetPath;
  final List<QMiddlewareStep> steps;

  const QMiddlewareConfig({
    required this.middlewareId,
    required this.directoryPath,
    required this.steps,
    this.appId,
    this.assetPath,
  });
}

/// Input config for registering a meta node.
@immutable
class QMetaConfig {
  final String metaId;
  final String directoryPath;
  final String? appId;
  final String? assetPath;
  final String? title;
  final String? titleTemplate;
  final String? description;
  final Map<String, String> openGraph;
  final Map<String, String> twitterCard;
  final Map<String, String> extra;

  const QMetaConfig({
    required this.metaId,
    required this.directoryPath,
    this.appId,
    this.assetPath,
    this.title,
    this.titleTemplate,
    this.description,
    this.openGraph = const {},
    this.twitterCard = const {},
    this.extra = const {},
  });
}

/// Input config for registering an error node.
@immutable
class QErrorConfig {
  final String errorId;
  final String directoryPath;
  final String? appId;
  final String? assetPath;
  final QPageBody? body;
  final Map<String, dynamic> props;

  const QErrorConfig({
    required this.errorId,
    required this.directoryPath,
    this.appId,
    this.assetPath,
    this.body,
    this.props = const {},
  });
}

/// Input config for registering a loading node.
@immutable
class QLoadingConfig {
  final String loadingId;
  final String directoryPath;
  final String? appId;
  final String? assetPath;
  final QPageBody? body;
  final bool isFullPage;
  final int minDisplayMs;

  const QLoadingConfig({
    required this.loadingId,
    required this.directoryPath,
    this.appId,
    this.assetPath,
    this.body,
    this.isFullPage = true,
    this.minDisplayMs = 0,
  });
}

/// Input config for registering a not-found node.
@immutable
class QNotFoundConfig {
  final String notFoundId;
  final String directoryPath;
  final String? appId;
  final String? assetPath;
  final QPageBody? body;
  final bool isCatchAll;

  const QNotFoundConfig({
    required this.notFoundId,
    required this.directoryPath,
    this.appId,
    this.assetPath,
    this.body,
    this.isCatchAll = true,
  });
}

/// Input config for registering a module.
@immutable
class QModuleConfig {
  final String moduleId;
  final String? appId;
  final String? assetPath;
  final QModulePolicy policy;
  final List<QSliceConfig> slices;
  final List<QDataSourceConfig> dataSources;
  final Map<String, dynamic> macros;
  final Map<String, dynamic> schemas;
  final Map<String, dynamic> actions;
  final List<String> imports;

  const QModuleConfig({
    required this.moduleId,
    required this.policy,
    this.appId,
    this.assetPath,
    this.slices = const [],
    this.dataSources = const [],
    this.macros = const {},
    this.schemas = const {},
    this.actions = const {},
    this.imports = const [],
  });
}

/// Input config for registering an app.
@immutable
class QAppConfig {
  final String appId;
  final String? assetPath;
  final QAppRouterConfig routerConfig;

  const QAppConfig({
    required this.appId,
    this.assetPath,
    this.routerConfig = const QAppRouterConfig(),
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — REGISTRY
// ─────────────────────────────────────────────────────────────────────────────

/// The public API for all QEE node operations.
/// Single source of truth for all node config in the application.
class QNodeRegistry {
  static final QNodeRegistry instance = QNodeRegistry._();
  QNodeRegistry._();

  late final QDiskStore _disk;
  late final QMemoryCache _cache;
  final QNodeStore _store = QNodeStore.instance;
  final QNodeResolver _resolver = QNodeResolver.instance;
  final QCryptoEngine _crypto = QCryptoEngine.instance;

  bool _initialized = false;
  int _diskHits = 0;
  int _diskMisses = 0;

  // Pending nodes waiting for batch resolution
  final List<QBaseNode> _pendingResolution = [];
  Timer? _resolveDebounce;

  // ── Initialization ────────────────────────────────────────────────────────

  /// Initialize the QEE. Must be called once before any operations.
  /// Boots the crypto engine, opens the disk store, loads the index.
  Future<void> initialize({
    String namespace = 'qee',
    String? customKeyHex,
  }) async {
    if (_initialized) return;

    // Initialize crypto (loads or generates master key)
    await _crypto.initialize(customKeyHex: customKeyHex);

    // Initialize disk store (platform-specific)
    _disk = QDiskStore.create();
    await _disk.initialize(namespace);

    // Initialize memory cache
    _cache = QMemoryCache(
      maxL2Entries: 2048,
      maxL2WeightBytes: 16 * 1024 * 1024,
    );
    _cache.attachMemoryPressureListener();

    // Wire up the node store loader
    _store.setLoader(_loadFromDisk);

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[QEE] Initialized. Disk nodes: ${_disk.count}');
    }
  }

  // ── LIST ──────────────────────────────────────────────────────────────────

  List<QNodeRef<QPageNode>> listPages({String? appId}) {
    return _store.pages
        .where((p) => appId == null || p.appId == appId)
        .map((p) => QNodeRef<QPageNode>(p.nodeId))
        .toList(growable: false);
  }

  List<QNodeRef<QAppNode>> listApps() {
    return _store.apps
        .map((a) => QNodeRef<QAppNode>(a.nodeId))
        .toList(growable: false);
  }

  List<QNodeRef<QModuleNode>> listModules({
    QModuleKind? kind,
    String? appId,
  }) {
    return _store.modules
        .where((m) =>
            (appId == null || m.appId == appId) &&
            (kind == null || m.moduleKind == kind))
        .map((m) => QNodeRef<QModuleNode>(m.nodeId))
        .toList(growable: false);
  }

  List<QNodeRef<QLayoutNode>> listLayouts({String? appId}) {
    return _store.layouts
        .where((l) => appId == null || l.appId == appId)
        .map((l) => QNodeRef<QLayoutNode>(l.nodeId))
        .toList(growable: false);
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  Future<QPageNode?> readPage(String routePath, {String? appId}) async {
    final nodeId = QNodeIdGen.pageId(routePath, appId: appId);
    return _loadNode<QPageNode>(nodeId);
  }

  Future<QAppNode?> readApp(String appId) async {
    final nodeId = QNodeIdGen.appId(appId);
    return _loadNode<QAppNode>(nodeId);
  }

  Future<QModuleNode?> readModule(
    String moduleId, {
    String? requesterId,
    String? appId,
  }) async {
    final nodeId = QNodeIdGen.moduleId(moduleId, appId: appId);
    final module = await _loadNode<QModuleNode>(nodeId);
    if (module != null && requesterId != null) {
      _assertAccess(requesterId, module);
    }
    return module;
  }

  Future<QLayoutNode?> readLayout(String layoutId, {String? appId}) async {
    final nodeId = QNodeIdGen.layoutId(layoutId, appId: appId);
    return _loadNode<QLayoutNode>(nodeId);
  }

  Future<QMetaNode?> readMeta(String directoryPath, {String? appId}) async {
    final nodeId = QNodeIdGen.metaId(directoryPath, appId: appId);
    return _loadNode<QMetaNode>(nodeId);
  }

  Future<QErrorNode?> readError(String directoryPath, {String? appId}) async {
    final nodeId = QNodeIdGen.errorId(directoryPath, appId: appId);
    return _loadNode<QErrorNode>(nodeId);
  }

  Future<QLoadingNode?> readLoading(String directoryPath, {String? appId}) async {
    final nodeId = QNodeIdGen.loadingId(directoryPath, appId: appId);
    return _loadNode<QLoadingNode>(nodeId);
  }

  Future<QNotFoundNode?> readNotFound(String directoryPath, {String? appId}) async {
    final nodeId = QNodeIdGen.notFoundId(directoryPath, appId: appId);
    return _loadNode<QNotFoundNode>(nodeId);
  }

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<QNodeRef<QPageNode>> createPage(QPageConfig config) async {
    final nodeId = QNodeIdGen.pageId(config.routePath, appId: config.appId);
    if (_disk.has(nodeId)) {
      throw QNodeSealedException(nodeId);
    }
    return _writePageNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QAppNode>> createApp(QAppConfig config) async {
    final nodeId = QNodeIdGen.appId(config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeAppNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QModuleNode>> createModule(QModuleConfig config) async {
    final nodeId = QNodeIdGen.moduleId(config.moduleId, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeModuleNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QLayoutNode>> createLayout(QLayoutConfig config) async {
    final nodeId = QNodeIdGen.layoutId(config.directoryPath, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeLayoutNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QMetaNode>> createMeta(QMetaConfig config) async {
    final nodeId = QNodeIdGen.metaId(config.directoryPath, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeMetaNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QMiddlewareNode>> createMiddleware(QMiddlewareConfig config) async {
    final nodeId = QNodeIdGen.middlewareId(config.directoryPath, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeMiddlewareNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QErrorNode>> createError(QErrorConfig config) async {
    final nodeId = QNodeIdGen.errorId(config.directoryPath, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeErrorNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QLoadingNode>> createLoading(QLoadingConfig config) async {
    final nodeId = QNodeIdGen.loadingId(config.directoryPath, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeLoadingNode(config, nodeId, version: 1);
  }

  Future<QNodeRef<QNotFoundNode>> createNotFound(QNotFoundConfig config) async {
    final nodeId = QNodeIdGen.notFoundId(config.directoryPath, appId: config.appId);
    if (_disk.has(nodeId)) throw QNodeSealedException(nodeId);
    return _writeNotFoundNode(config, nodeId, version: 1);
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<QNodeRef<QPageNode>> updatePage(String routePath, QPageConfig config, {String? appId}) async {
    final nodeId = QNodeIdGen.pageId(routePath, appId: appId);
    final existing = _disk.storedVersion(nodeId);
    await _evictNode(nodeId);
    return _writePageNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QModuleNode>> updateModule(String moduleId, QModuleConfig config, {String? appId}) async {
    final nodeId = QNodeIdGen.moduleId(moduleId, appId: appId);
    final existing = _disk.storedVersion(nodeId);
    await _evictNode(nodeId);
    return _writeModuleNode(config, nodeId, version: existing + 1);
  }

  // ── UPSERT ────────────────────────────────────────────────────────────────

  Future<QNodeRef<QPageNode>> upsertPage(QPageConfig config) async {
    final nodeId = QNodeIdGen.pageId(config.routePath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writePageNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QAppNode>> upsertApp(QAppConfig config) async {
    final nodeId = QNodeIdGen.appId(config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeAppNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QModuleNode>> upsertModule(QModuleConfig config) async {
    final nodeId = QNodeIdGen.moduleId(config.moduleId, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeModuleNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QLayoutNode>> upsertLayout(QLayoutConfig config) async {
    final nodeId = QNodeIdGen.layoutId(config.directoryPath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeLayoutNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QMetaNode>> upsertMeta(QMetaConfig config) async {
    final nodeId = QNodeIdGen.metaId(config.directoryPath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeMetaNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QMiddlewareNode>> upsertMiddleware(QMiddlewareConfig config) async {
    final nodeId = QNodeIdGen.middlewareId(config.directoryPath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeMiddlewareNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QErrorNode>> upsertError(QErrorConfig config) async {
    final nodeId = QNodeIdGen.errorId(config.directoryPath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeErrorNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QLoadingNode>> upsertLoading(QLoadingConfig config) async {
    final nodeId = QNodeIdGen.loadingId(config.directoryPath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeLoadingNode(config, nodeId, version: existing + 1);
  }

  Future<QNodeRef<QNotFoundNode>> upsertNotFound(QNotFoundConfig config) async {
    final nodeId = QNodeIdGen.notFoundId(config.directoryPath, appId: config.appId);
    final existing = _disk.storedVersion(nodeId);
    if (existing > 0) await _evictNode(nodeId);
    return _writeNotFoundNode(config, nodeId, version: existing + 1);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deletePage(String routePath, {String? appId}) async {
    final nodeId = QNodeIdGen.pageId(routePath, appId: appId);
    await _deleteNode(nodeId);
  }

  Future<void> deleteApp(String appId) async {
    final nodeId = QNodeIdGen.appId(appId);
    await _deleteNode(nodeId);
  }

  Future<void> deleteModule(String moduleId, {String? appId}) async {
    final nodeId = QNodeIdGen.moduleId(moduleId, appId: appId);
    await _deleteNode(nodeId);
  }

  Future<void> deleteLayout(String directoryPath, {String? appId}) async {
    final nodeId = QNodeIdGen.layoutId(directoryPath, appId: appId);
    await _deleteNode(nodeId);
  }

  // ── CACHE CONTROL ─────────────────────────────────────────────────────────

  bool isCached(int nodeId) =>
      _store.containsSync(nodeId) || _cache.has(nodeId);

  Future<void> warmCache(List<int> nodeIds) async {
    for (final id in nodeIds) {
      if (!isCached(id)) {
        await _loadFromDisk(id);
      }
    }
  }

  void evict(int nodeId) {
    _cache.evict(nodeId);
    _store.evict(nodeId);
  }

  void evictAll() {
    _cache.evictAll();
    _store.evictAll();
  }

  // ── SNAPSHOT & STATS ──────────────────────────────────────────────────────

  QEngineSnapshot snapshot() {
    return QEngineSnapshot(
      pageCount: _store.pages.length,
      appCount: _store.apps.length,
      moduleCount: _store.modules.length,
      layoutCount: _store.layouts.length,
      metaCount: _store.metas.length,
      middlewareCount: _store.middlewares.length,
      errorCount: _store.errors.length,
      loadingCount: _store.loadings.length,
      notFoundCount: _store.notFounds.length,
      nodesLoadedInMemory: _store.totalLoaded,
      cacheStats: cacheStats(),
      takenAt: DateTime.now(),
    );
  }

  QCacheStats cacheStats() {
    final memStats = _cache.stats();
    return QCacheStats(
      l1Hits: memStats.l1Hits,
      l1Misses: memStats.l1Misses,
      l2Hits: memStats.l2Hits,
      l2Misses: memStats.l2Misses,
      diskHits: _diskHits,
      diskMisses: _diskMisses,
      evictions: memStats.evictions,
      currentL1Count: memStats.currentL1Count,
      currentL2Count: memStats.currentL2Count,
      currentDiskCount: _disk.count,
      totalWeightBytes: memStats.totalWeightBytes,
    );
  }

  // ── FLUSH ─────────────────────────────────────────────────────────────────

  Future<void> flush() => _disk.flush();

  /// Force any debounced resolution work to complete before returning.
  /// Useful in tests and after batch registrations when callers need
  /// fully wired refs immediately.
  Future<void> flushResolution() async {
    final timer = _resolveDebounce;
    _resolveDebounce = null;
    timer?.cancel();
    await _runBatchResolve();
  }

  // ── INTERNAL WRITE HELPERS ────────────────────────────────────────────────

  Future<QNodeRef<QPageNode>> _writePageNode(
    QPageConfig config,
    int nodeId,
    {required int version}
  ) async {
    int flags = QNodeFlags.isSealed;
    if (config.isCatchAll) flags |= QNodeFlags.isCatchAll;
    if (config.paramNames.isNotEmpty) flags |= QNodeFlags.hasParams;
    if (config.body != null) flags |= QNodeFlags.hasBody;

    final node = QPageNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: flags,
      routePath: config.routePath,
      appId: config.appId,
      assetPath: config.assetPath,
      paramNames: config.paramNames,
      body: config.body,
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QPageNode>(nodeId);
  }

  Future<QNodeRef<QAppNode>> _writeAppNode(
    QAppConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QAppNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed,
      appId: config.appId,
      assetPath: config.assetPath,
      routerConfig: config.routerConfig,
      pageRefs: const [],
      publicModuleRefs: const [],
      privateModuleRefs: const [],
      sharedModuleRefs: const [],
    );

    await _serializeAndStore(node, version: version);
    _store.put(node);
    return QNodeRef<QAppNode>(nodeId);
  }

  Future<QNodeRef<QModuleNode>> _writeModuleNode(
    QModuleConfig config,
    int nodeId,
    {required int version}
  ) async {
    int flags = QNodeFlags.isSealed;
    flags |= switch (config.policy.kind) {
      QModuleKind.public  => QNodeFlags.isPublic,
      QModuleKind.private => QNodeFlags.isPrivate,
      QModuleKind.shared  => QNodeFlags.isShared,
    };

    final node = QModuleNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: flags,
      moduleId: config.moduleId,
      appId: config.appId,
      assetPath: config.assetPath,
      policy: config.policy,
      slices: config.slices,
      dataSources: config.dataSources,
      macros: config.macros,
      schemas: config.schemas,
      actions: config.actions,
      imports: config.imports,
      bakedStaticValues: const [],
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QModuleNode>(nodeId);
  }

  Future<QNodeRef<QLayoutNode>> _writeLayoutNode(
    QLayoutConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QLayoutNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed | QNodeFlags.isComposing,
      layoutId: config.layoutId,
      directoryPath: config.directoryPath,
      appId: config.appId,
      assetPath: config.assetPath,
      body: config.body,
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QLayoutNode>(nodeId);
  }

  Future<QNodeRef<QMetaNode>> _writeMetaNode(
    QMetaConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QMetaNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed | QNodeFlags.isOverridable,
      metaId: config.metaId,
      directoryPath: config.directoryPath,
      appId: config.appId,
      assetPath: config.assetPath,
      title: config.title,
      titleTemplate: config.titleTemplate,
      description: config.description,
      openGraph: config.openGraph,
      twitterCard: config.twitterCard,
      extra: config.extra,
      raw: const {},
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QMetaNode>(nodeId);
  }

  Future<QNodeRef<QMiddlewareNode>> _writeMiddlewareNode(
    QMiddlewareConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QMiddlewareNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed | QNodeFlags.isComposing,
      middlewareId: config.middlewareId,
      directoryPath: config.directoryPath,
      appId: config.appId,
      assetPath: config.assetPath,
      steps: config.steps,
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QMiddlewareNode>(nodeId);
  }

  Future<QNodeRef<QErrorNode>> _writeErrorNode(
    QErrorConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QErrorNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed | QNodeFlags.isOverridable,
      errorId: config.errorId,
      directoryPath: config.directoryPath,
      appId: config.appId,
      assetPath: config.assetPath,
      body: config.body,
      props: config.props,
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QErrorNode>(nodeId);
  }

  Future<QNodeRef<QLoadingNode>> _writeLoadingNode(
    QLoadingConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QLoadingNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed | QNodeFlags.isOverridable,
      loadingId: config.loadingId,
      directoryPath: config.directoryPath,
      appId: config.appId,
      assetPath: config.assetPath,
      body: config.body,
      isFullPage: config.isFullPage,
      minDisplayMs: config.minDisplayMs,
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QLoadingNode>(nodeId);
  }

  Future<QNodeRef<QNotFoundNode>> _writeNotFoundNode(
    QNotFoundConfig config,
    int nodeId,
    {required int version}
  ) async {
    final node = QNotFoundNode(
      nodeId: nodeId,
      version: version,
      sealedAt: DateTime.now().millisecondsSinceEpoch,
      flags: QNodeFlags.isSealed | QNodeFlags.isOverridable,
      notFoundId: config.notFoundId,
      directoryPath: config.directoryPath,
      appId: config.appId,
      assetPath: config.assetPath,
      body: config.body,
      isCatchAll: config.isCatchAll,
    );

    await _serializeAndStore(node, version: version);
    _scheduleBatchResolve(node);
    return QNodeRef<QNotFoundNode>(nodeId);
  }

  // ── Core serialize + store ────────────────────────────────────────────────

  Future<void> _serializeAndStore(QBaseNode node, {required int version}) async {
    // Serialize to binary
    final plaintext = QNodeEncoder.encode(node);

    // Encrypt
    final encrypted = _crypto.encrypt(plaintext);

    // Write to disk
    await _disk.write(node.nodeId, encrypted, version: version);

    // Store decoded node in memory
    _store.put(node);

    // Populate L2 cache
    _cache.put(node.nodeId, node);
  }

  // ── Core load from disk ───────────────────────────────────────────────────

  Future<QBaseNode?> _loadFromDisk(int nodeId) async {
    // Check L2 cache first (L1 is checked by the caller via QNodeStore.resolve)
    final cached = _cache.get<QBaseNode>(nodeId);
    if (cached != null) {
      _store.put(cached);
      return cached;
    }

    // Load from disk
    if (!_disk.has(nodeId)) {
      _diskMisses++;
      return null;
    }

    final encrypted = await _disk.read(nodeId);
    if (encrypted == null) {
      _diskMisses++;
      return null;
    }

    _diskHits++;

    // Decrypt
    Uint8List plaintext;
    try {
      plaintext = _crypto.decrypt(encrypted);
    } on QCryptoTamperException {
      if (kDebugMode) {
        debugPrint('[QEE] Tamper detected for node $nodeId — deleting from disk');
      }
      await _disk.delete(nodeId);
      return null;
    }

    // Deserialize
    QBaseNode node;
    try {
      node = QNodeDecoder.decode(plaintext);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[QEE] Deserialization error for node $nodeId: $e');
      }
      return null;
    }

    // Store in memory cache + node store
    _store.put(node);
    _cache.put(nodeId, node);
    return node;
  }

  Future<T?> _loadNode<T extends QBaseNode>(int nodeId) async {
    // Fast path: already in memory store
    final inMemory = _store.resolveSync<T>(nodeId);
    if (inMemory != null) return inMemory;

    // Slow path: load from disk
    return (await _loadFromDisk(nodeId)) as T?;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteNode(int nodeId) async {
    await _evictNode(nodeId);
    await _disk.delete(nodeId);
  }

  Future<void> _evictNode(int nodeId) async {
    _cache.evict(nodeId);
    _store.evict(nodeId);
  }

  // ── Access control ────────────────────────────────────────────────────────

  void _assertAccess(String requesterId, QModuleNode module) {
    if (!module.policy.canAccess(requesterId)) {
      throw QAccessDeniedException(
        requesterId: requesterId,
        moduleId: module.moduleId,
        reason: switch (module.moduleKind) {
          QModuleKind.private =>
            'Module is private — only accessible from its own app',
          QModuleKind.shared =>
            'Requester not in allowedApps list: ${module.policy.allowedAppIds}',
          QModuleKind.public =>
            'Should not happen — public modules allow all requesters',
        },
      );
    }
  }

  // ── Batch resolution (debounced) ──────────────────────────────────────────

  void _scheduleBatchResolve(QBaseNode node) {
    _pendingResolution.add(node);

    // Debounce: resolve after a short delay to batch multiple registrations
    _resolveDebounce?.cancel();
    _resolveDebounce = Timer(const Duration(milliseconds: 50), _runBatchResolve);
  }

  Future<void> _runBatchResolve() async {
    if (_pendingResolution.isEmpty) return;

    final batch = List<QBaseNode>.from(_pendingResolution);
    _pendingResolution.clear();

    // Build the full node map for resolution context
    final allNodes = <int, QBaseNode>{};
    for (final node in _store.pages) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.layouts) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.middlewares) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.metas) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.errors) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.loadings) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.notFounds) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.modules) {
      allNodes[node.nodeId] = node;
    }
    for (final node in _store.apps) {
      allNodes[node.nodeId] = node;
    }

    // Run resolver
    try {
      final result = _resolver.resolve(batch, allNodes);

      // Persist resolved nodes back to disk + memory
      for (final resolved in result.resolvedNodes.values) {
        final existing = allNodes[resolved.nodeId];
        if (existing == resolved) continue; // no change

        // Re-serialize updated node to disk
        final plaintext = QNodeEncoder.encode(resolved);
        final encrypted = _crypto.encrypt(plaintext);
        await _disk.write(
          resolved.nodeId,
          encrypted,
          version: resolved.version,
        );

        // Update memory store
        _store.put(resolved);
        _cache.put(resolved.nodeId, resolved);
      }

      if (result.hasWarnings && kDebugMode) {
        for (final w in result.warnings) {
          debugPrint('[QEE] Resolver warning: $w');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[QEE] Resolver error: $e');
    }
  }

  bool get isInitialized => _initialized;
}

/// Top-level convenience alias for [QNodeRegistry.instance].
QNodeRegistry get QEE => QNodeRegistry.instance;
