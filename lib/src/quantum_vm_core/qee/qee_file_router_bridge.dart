/*
 * ============================================================================
 * File: qee_file_router_bridge.dart
 * 
 * Description:
 * Acts as the translation bridge between the file-system-based routing logic 
 * (QuantumFileRouter) and the internal execution models of QNodeRegistry. 
 * It discovers, parses, and commits layouts, middleware, and pages into the QEE.
 * 
 * Key Components:
 * - QFileRouterBridge: Scans asset manifests, groups special route files, and 
 *   dispatches them to the registry.
 * - QBridgeSyncResult: Summary of synced/modified node elements.
 * 
 * Dependencies/Relationships:
 * Consumes raw file strings or YAML config, parses it, and creates config records 
 * (e.g., QLayoutConfig) which are upserted into QNodeRegistry.
 * 
 * Notes:
 * Relies on deterministic hashing to avoid unnecessary registry writes on hot reloads 
 * when files haven't changed.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE FILE ROUTER BRIDGE — qee_file_router_bridge.dart
//
// The ONLY place where QuantumFileRouter talks to QNodeRegistry.
// All other code stays cleanly separated.
//
// Responsibilities:
//   1. Convert QLFileRouteEntry → QPageNode (via QNodeRegistry.upsertPage)
//   2. Discover and register all special files in the pages directory:
//        _layout.yaml, _meta.yaml, _middleware.yaml,
//        _error.yaml, _loading.yaml, _not_found.yaml
//   3. Build resolution context for each page:
//      - Layout chain: all _layout files from root to page's directory
//      - Middleware chain: all _middleware files from root to page's directory
//      - Meta override: deepest _meta.yaml wins
//      - Error/Loading/NotFound override: deepest wins
//   4. Emit only the nodes that have CHANGED since the last sync
//      (uses version hash comparison to avoid unnecessary re-registration)
//
// This bridge runs ONCE during app boot (after file router discovers routes)
// and again only if routes change (dev hot reload or dynamic route updates).
// ════════════════════════════════════════════════════════════════════════════

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'qee_registry.dart';
import 'qee_serializer.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — SPECIAL FILE NAMES
// ─────────────────────────────────────────────────────────────────────────────

abstract final class _SpecialFile {
  static const layout     = '_layout';
  static const meta       = '_meta';
  static const middleware = '_middleware';
  static const error      = '_error';
  static const loading    = '_loading';
  static const notFound   = '_not_found';

  static const allNames = {layout, meta, middleware, error, loading, notFound};
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — SYNC RESULT
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a bridge sync operation.
@immutable
class QBridgeSyncResult {
  /// Number of page nodes registered/updated.
  final int pagesRegistered;

  /// Number of layout nodes registered/updated.
  final int layoutsRegistered;

  /// Number of middleware nodes registered/updated.
  final int middlewaresRegistered;

  /// Number of meta/error/loading/notFound nodes registered/updated.
  final int wrapperNodesRegistered;

  /// Number of nodes that were skipped (no change since last sync).
  final int skipped;

  const QBridgeSyncResult({
    required this.pagesRegistered,
    required this.layoutsRegistered,
    required this.middlewaresRegistered,
    required this.wrapperNodesRegistered,
    required this.skipped,
  });

  int get total =>
      pagesRegistered + layoutsRegistered + middlewaresRegistered + wrapperNodesRegistered;

  @override
  String toString() => 'QBridgeSyncResult(total=$total, pages=$pagesRegistered, '
      'layouts=$layoutsRegistered, middlewares=$middlewaresRegistered, '
      'wrappers=$wrapperNodesRegistered, skipped=$skipped)';
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — BRIDGE
// ─────────────────────────────────────────────────────────────────────────────

/// Bridge between [QuantumFileRouter] and [QNodeRegistry].
///
/// Converts the file router's discovered routes into QEE node registrations.
/// This is the ONLY place where file router output enters QEE.
class QFileRouterBridge {
  static final QFileRouterBridge instance = QFileRouterBridge._();
  QFileRouterBridge._();

  // Track sync hashes to detect changes and skip unchanged nodes
  final Map<String, int> _syncedHashes = {};

  // Asset manifest discovery cache (asset path → YAML string)
  final Map<String, String?> _assetCache = {};

  // ── Public API ────────────────────────────────────────────────────────────

  /// Sync all discovered file routes to the QEE registry.
  ///
  /// [entries]: the route entries from QuantumFileRouter
  /// [allAssetPaths]: all asset paths in the manifest (for special file discovery)
  /// [pagesDir]: base pages directory prefix, e.g. `'assets/pages'`
  /// [appId]: the app ID (null = root app)
  Future<QBridgeSyncResult> sync({
    required List<QLFileRouteEntryLite> entries,
    required List<String> allAssetPaths,
    required String pagesDir,
    String? appId,
  }) async {
    int pagesReg = 0, layoutsReg = 0, middlewaresReg = 0, wrappersReg = 0, skipped = 0;

    // Build the special-file index from all asset paths
    final specialIndex = _buildSpecialFileIndex(allAssetPaths, pagesDir);

    // Register all special nodes first (layouts, middlewares, meta, etc.)
    // so that pages can reference them.
    final regResult = await _registerSpecialNodes(
      specialIndex: specialIndex,
      pagesDir: pagesDir,
      appId: appId,
    );

    layoutsReg = regResult.layoutsRegistered;
    middlewaresReg = regResult.middlewaresRegistered;
    wrappersReg = regResult.wrapperNodesRegistered;
    skipped += regResult.skipped;

    // Register all pages
    for (final entry in entries) {
      final hash = _hashEntry(entry);
      final existing = _syncedHashes[entry.assetPath];
      if (existing == hash) {
        skipped++;
        continue;
      }

      await _registerPage(entry, pagesDir: pagesDir, appId: appId);
      _syncedHashes[entry.assetPath] = hash;
      pagesReg++;
    }

    if (kDebugMode) {
      final result = QBridgeSyncResult(
        pagesRegistered: pagesReg,
        layoutsRegistered: layoutsReg,
        middlewaresRegistered: middlewaresReg,
        wrapperNodesRegistered: wrappersReg,
        skipped: skipped,
      );
      debugPrint('[QEE Bridge] Sync complete: $result');
    }

    return QBridgeSyncResult(
      pagesRegistered: pagesReg,
      layoutsRegistered: layoutsReg,
      middlewaresRegistered: middlewaresReg,
      wrapperNodesRegistered: wrappersReg,
      skipped: skipped,
    );
  }

  // ── Special file index ────────────────────────────────────────────────────

  /// Builds a map of directoryPath → {specialFileName → assetPath}
  /// for all special files found in the pages directory.
  Map<String, Map<String, String>> _buildSpecialFileIndex(
    List<String> allAssetPaths,
    String pagesDir,
  ) {
    final index = <String, Map<String, String>>{};
    final prefix = pagesDir.endsWith('/') ? pagesDir : '$pagesDir/';

    for (final assetPath in allAssetPaths) {
      if (!assetPath.startsWith(prefix)) continue;

      final relative = assetPath.substring(prefix.length);
      final lastSlash = relative.lastIndexOf('/');
      final filename = lastSlash >= 0
          ? relative.substring(lastSlash + 1)
          : relative;

      // Strip extension
      final lastDot = filename.lastIndexOf('.');
      final baseName = lastDot >= 0 ? filename.substring(0, lastDot) : filename;

      if (!_SpecialFile.allNames.contains(baseName)) continue;

      // Extract directory path (relative to pagesDir)
      final dirPath = lastSlash >= 0 ? relative.substring(0, lastSlash + 1) : '';

      index.putIfAbsent(dirPath, () => {})[baseName] = assetPath;
    }

    return index;
  }

  // ── Register special nodes ────────────────────────────────────────────────

  Future<QBridgeSyncResult> _registerSpecialNodes({
    required Map<String, Map<String, String>> specialIndex,
    required String pagesDir,
    String? appId,
  }) async {
    int layoutsReg = 0, middlewaresReg = 0, wrappersReg = 0, skipped = 0;

    for (final entry in specialIndex.entries) {
      final dirPath = entry.key;
      final files = entry.value;

      // _layout
      if (files.containsKey(_SpecialFile.layout)) {
        final assetPath = files[_SpecialFile.layout]!;
        final hash = _hashString(assetPath);
        if (_syncedHashes[assetPath] != hash) {
          final body = await _loadAssetBody(assetPath);
          await QNodeRegistry.instance.upsertLayout(QLayoutConfig(
            layoutId: dirPath.isEmpty ? '_root' : dirPath,
            directoryPath: dirPath,
            appId: appId,
            assetPath: assetPath,
            body: body,
          ));
          _syncedHashes[assetPath] = hash;
          layoutsReg++;
        } else {
          skipped++;
        }
      }

      // _middleware
      if (files.containsKey(_SpecialFile.middleware)) {
        final assetPath = files[_SpecialFile.middleware]!;
        final hash = _hashString(assetPath);
        if (_syncedHashes[assetPath] != hash) {
          final steps = await _loadMiddlewareSteps(assetPath);
          await QNodeRegistry.instance.upsertMiddleware(QMiddlewareConfig(
            middlewareId: dirPath.isEmpty ? '_root_mw' : '${dirPath}_mw',
            directoryPath: dirPath,
            appId: appId,
            assetPath: assetPath,
            steps: steps,
          ));
          _syncedHashes[assetPath] = hash;
          middlewaresReg++;
        } else {
          skipped++;
        }
      }

      // _meta
      if (files.containsKey(_SpecialFile.meta)) {
        final assetPath = files[_SpecialFile.meta]!;
        final hash = _hashString(assetPath);
        if (_syncedHashes[assetPath] != hash) {
          final metaData = await _loadMetaData(assetPath);
          await QNodeRegistry.instance.upsertMeta(QMetaConfig(
            metaId: dirPath.isEmpty ? '_root_meta' : '${dirPath}_meta',
            directoryPath: dirPath,
            appId: appId,
            assetPath: assetPath,
            title: metaData['title'] as String?,
            titleTemplate: metaData['titleTemplate'] as String?,
            description: metaData['description'] as String?,
            openGraph: _toStringMap(metaData['openGraph']),
            twitterCard: _toStringMap(metaData['twitterCard']),
            extra: _toStringMap(metaData['extra']),
          ));
          _syncedHashes[assetPath] = hash;
          wrappersReg++;
        } else {
          skipped++;
        }
      }

      // _error
      if (files.containsKey(_SpecialFile.error)) {
        final assetPath = files[_SpecialFile.error]!;
        final hash = _hashString(assetPath);
        if (_syncedHashes[assetPath] != hash) {
          final body = await _loadAssetBody(assetPath);
          await QNodeRegistry.instance.upsertError(QErrorConfig(
            errorId: dirPath.isEmpty ? '_root_error' : '${dirPath}_error',
            directoryPath: dirPath,
            appId: appId,
            assetPath: assetPath,
            body: body,
          ));
          _syncedHashes[assetPath] = hash;
          wrappersReg++;
        } else {
          skipped++;
        }
      }

      // _loading
      if (files.containsKey(_SpecialFile.loading)) {
        final assetPath = files[_SpecialFile.loading]!;
        final hash = _hashString(assetPath);
        if (_syncedHashes[assetPath] != hash) {
          final body = await _loadAssetBody(assetPath);
          final loadingData = await _loadRawMap(assetPath);
          await QNodeRegistry.instance.upsertLoading(QLoadingConfig(
            loadingId: dirPath.isEmpty ? '_root_loading' : '${dirPath}_loading',
            directoryPath: dirPath,
            appId: appId,
            assetPath: assetPath,
            body: body,
            isFullPage: loadingData['fullPage'] as bool? ?? true,
            minDisplayMs: (loadingData['minDisplayMs'] as num?)?.toInt() ?? 0,
          ));
          _syncedHashes[assetPath] = hash;
          wrappersReg++;
        } else {
          skipped++;
        }
      }

      // _not_found
      if (files.containsKey(_SpecialFile.notFound)) {
        final assetPath = files[_SpecialFile.notFound]!;
        final hash = _hashString(assetPath);
        if (_syncedHashes[assetPath] != hash) {
          final body = await _loadAssetBody(assetPath);
          await QNodeRegistry.instance.upsertNotFound(QNotFoundConfig(
            notFoundId: dirPath.isEmpty ? '_root_nf' : '${dirPath}_nf',
            directoryPath: dirPath,
            appId: appId,
            assetPath: assetPath,
            body: body,
            isCatchAll: true,
          ));
          _syncedHashes[assetPath] = hash;
          wrappersReg++;
        } else {
          skipped++;
        }
      }
    }

    await QNodeRegistry.instance.flushResolution();

    return QBridgeSyncResult(
      pagesRegistered: 0,
      layoutsRegistered: layoutsReg,
      middlewaresRegistered: middlewaresReg,
      wrapperNodesRegistered: wrappersReg,
      skipped: skipped,
    );
  }

  // ── Register a page ───────────────────────────────────────────────────────

  Future<void> _registerPage(
    QLFileRouteEntryLite entry, {
    required String pagesDir,
    String? appId,
  }) async {
    final body = await _loadAssetBody(entry.assetPath);

    // Load static props if any (defined in the page config's 'props:' key)
    final pageMap = await _loadRawMap(entry.assetPath);
    final props = pageMap['props'];
    final pageProps = props is Map
        ? Map<String, dynamic>.from(props)
        : const <String, dynamic>{};

    await QNodeRegistry.instance.upsertPage(QPageConfig(
      routePath: entry.routePath,
      appId: appId,
      assetPath: entry.assetPath,
      paramNames: entry.paramNames,
      isCatchAll: entry.isCatchAll,
      body: body,
      pageProps: pageProps,
    ));
  }

  // ── Asset loading helpers ─────────────────────────────────────────────────

  Future<QPageBody?> _loadAssetBody(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      return QPageBody(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _loadRawMap(String assetPath) async {
    try {
      final cached = _assetCache[assetPath];
      final raw = cached ?? await rootBundle.loadString(assetPath);
      if (cached == null) _assetCache[assetPath] = raw;

      if (raw.trim().startsWith('{')) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      // Basic YAML → Map (forward to existing QLYamlEngine if available)
      return _parseSimpleYaml(raw);
    } catch (_) {
      return const {};
    }
  }

  Future<List<QMiddlewareStep>> _loadMiddlewareSteps(String assetPath) async {
    final map = await _loadRawMap(assetPath);
    final stepsRaw = map['steps'];
    if (stepsRaw is! List) return const [];

    return stepsRaw
        .whereType<Map>()
        .map((s) {
          final params = s['params'];
          return QMiddlewareStep(
            type: s['type']?.toString() ?? '',
            params: params is Map
                ? Map<String, dynamic>.from(params)
                : const {},
            isAsync: s['async'] == true,
            description: s['description']?.toString(),
          );
        })
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> _loadMetaData(String assetPath) async {
    return _loadRawMap(assetPath);
  }

  // ── Utility helpers ───────────────────────────────────────────────────────

  static Map<String, String> _toStringMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  /// Minimal YAML parser for flat key: value maps.
  /// For nested structures, the full QLYamlEngine should be used.
  static Map<String, dynamic> _parseSimpleYaml(String yaml) {
    final result = <String, dynamic>{};
    for (final line in yaml.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final colonIdx = trimmed.indexOf(':');
      if (colonIdx <= 0) continue;
      final key = trimmed.substring(0, colonIdx).trim();
      final value = trimmed.substring(colonIdx + 1).trim();
      if (value.isEmpty) {
        result[key] = null;
        continue;
      }
      // Type coercion
      if (value == 'true') {
        result[key] = true;
      } else if (value == 'false') result[key] = false;
      else if (value == 'null') result[key] = null;
      else {
        final num? numVal = num.tryParse(value);
        result[key] = numVal ?? _stripQuotes(value);
      }
    }
    return result;
  }

  static String _stripQuotes(String s) {
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }

  static int _hashString(String s) {
    return QNodeIdGen.hash(s);
  }

  static int _hashEntry(QLFileRouteEntryLite e) {
    return QNodeIdGen.hash(
      '${e.assetPath}:${e.routePath}:${e.paramNames.join(',')}:${e.isCatchAll}',
    );
  }

  /// Invalidate the cache for a given asset path (on hot reload / dev mode).
  void invalidate(String assetPath) {
    _syncedHashes.remove(assetPath);
    _assetCache.remove(assetPath);
  }

  /// Invalidate all cached state — forces full re-sync on next call.
  void invalidateAll() {
    _syncedHashes.clear();
    _assetCache.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §4 — LITE ENTRY (bridge-facing view of QLFileRouteEntry)
// ─────────────────────────────────────────────────────────────────────────────

/// A minimal view of a file route entry used by the bridge.
/// This avoids importing the full QLFileRouteEntry which has Flutter deps.
@immutable
class QLFileRouteEntryLite {
  final String assetPath;
  final String routePath;
  final List<String> paramNames;
  final bool isCatchAll;

  const QLFileRouteEntryLite({
    required this.assetPath,
    required this.routePath,
    this.paramNames = const [],
    this.isCatchAll = false,
  });

  /// Convert from a full QLFileRouteEntry.
  /// Used inside quantum_file_router.dart.
  factory QLFileRouteEntryLite.fromEntry(dynamic entry) {
    // Dynamic dispatch to avoid a hard import cycle
    return QLFileRouteEntryLite(
      assetPath: (entry as dynamic).assetPath as String,
      routePath: entry.routePath as String,
      paramNames: List<String>.from(entry.paramNames as List? ?? const []),
      isCatchAll: entry.isCatchAll as bool? ?? false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §5 — APP NODE BUILDER
// ─────────────────────────────────────────────────────────────────────────────

/// Builds and registers a [QAppNode] from a discovered app directory.
///
/// Called during bootstrap to register the root app and any sub-apps.
class QAppNodeBuilder {
  static Future<QNodeRef<QAppNode>> buildAndRegister({
    required String appId,
    required String pagesDir,
    required String initialRoute,
    String? assetPath,
    bool deepLinkEnabled = false,
  }) async {
    return QNodeRegistry.instance.upsertApp(QAppConfig(
      appId: appId,
      assetPath: assetPath,
      routerConfig: QAppRouterConfig(
        pagesDir: pagesDir,
        initialRoute: initialRoute,
        deepLinkEnabled: deepLinkEnabled,
      ),
    ));
  }
}
