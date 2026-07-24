// ════════════════════════════════════════════════════════════════════════════
// QUANTUM CORE FILE REGISTRY
//
// Folder-based, lazy, override-friendly registry for macros, templates,
// layouts, and any other registered core content.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../quantum.dart';

typedef QLCoreFileLoader = Future<Map<String, dynamic>> Function(
    String assetPath);

@immutable
class QLCoreFileDescriptor {
  final String core;
  final String typeName;
  final String assetPath;
  final bool builtIn;
  final String source;
  final Map<String, dynamic> metadata;
  final DateTime registeredAt;

  const QLCoreFileDescriptor({
    required this.core,
    required this.typeName,
    required this.assetPath,
    required this.builtIn,
    required this.source,
    required this.metadata,
    required this.registeredAt,
  });

  String get key => '$core::$typeName';

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': key,
        'kind': 'core-file',
        'core': core,
        'name': typeName,
        'assetPath': assetPath,
        'builtIn': builtIn,
        'source': source,
        if (metadata['paramSchema'] != null) 'paramSchema': metadata['paramSchema'],
        if (metadata['infoSchema'] != null) 'infoSchema': metadata['infoSchema'],
      };
}

final class QLCoreFileRegistry {
  static final QLCoreFileRegistry instance = QLCoreFileRegistry._();
  QLCoreFileRegistry._();

  static QLCoreFileLoader _loader =
      (assetPath) => QuantumYamlEngine.instance.load(assetPath);

  static void setLoader(QLCoreFileLoader loader) {
    _loader = loader;
  }

  final Map<String, QLCoreFileDescriptor> _builtIns = {};
  final Map<String, QLCoreFileDescriptor> _overrides = {};
  final Map<String, String> _folderToCore = {};

  final QLRuntimeCache<Map<String, dynamic>> _resolvedCache =
      QLRuntimeCache<Map<String, dynamic>>(
    config: const QLRuntimeCacheConfig(
      maxEntries: 1024,
      maxWeight: 24 * 1024 * 1024,
    ),
  );

  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  static String _norm(String path) =>
      path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

  static String _stem(String path) {
    final String norm = _norm(path);
    final String file = norm.split('/').last;
    final int dot = file.lastIndexOf('.');
    return dot == -1 ? file : file.substring(0, dot);
  }

  static String _defaultCore(String path) {
    final String norm = _norm(path);
    final parts = norm.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length < 2) return 'root';
    return parts.first;
  }

  String _resolveCoreFromFolder(String path, {String? explicitCore}) {
    if (explicitCore != null && explicitCore.trim().isNotEmpty) {
      return explicitCore.trim();
    }
    final String norm = _norm(path);
    final parts = norm.split('/').where((p) => p.isNotEmpty).toList();
    for (int i = parts.length - 2; i >= 0; i--) {
      final joined = parts.take(i + 1).join('/');
      final mapped = _folderToCore[joined];
      if (mapped != null && mapped.isNotEmpty) return mapped;
    }
    if (parts.isNotEmpty) {
      final mappedRoot = _folderToCore[parts.first];
      if (mappedRoot != null && mappedRoot.isNotEmpty) return mappedRoot;
    }
    return _defaultCore(norm);
  }

  String _resolveTypeName(String path, {String? explicitType}) {
    final String stem = explicitType != null && explicitType.trim().isNotEmpty
        ? explicitType.trim()
        : _stem(path);
    return stem;
  }

  String _key(String core, String typeName) =>
      '${core.trim()}::${typeName.trim()}';

  void registerFolder(String folder, String core) {
    final String key = _norm(folder);
    if (key.isEmpty) return;
    _folderToCore[key] = core.trim();
  }

  void registerBuiltIn(
    String assetPath, {
    String? core,
    String? typeName,
    Map<String, dynamic> metadata = const {},
  }) {
    _register(
      assetPath,
      core: core,
      typeName: typeName,
      metadata: metadata,
      builtIn: true,
    );
  }

  void registerOverride(
    String assetPath, {
    String? core,
    String? typeName,
    Map<String, dynamic> metadata = const {},
  }) {
    _register(
      assetPath,
      core: core,
      typeName: typeName,
      metadata: metadata,
      builtIn: false,
    );
  }

  void register(
    String assetPath, {
    String? core,
    String? typeName,
    bool builtIn = false,
    Map<String, dynamic> metadata = const {},
  }) {
    _register(
      assetPath,
      core: core,
      typeName: typeName,
      metadata: metadata,
      builtIn: builtIn,
    );
  }

  void _register(
    String assetPath, {
    String? core,
    String? typeName,
    required bool builtIn,
    Map<String, dynamic> metadata = const {},
  }) {
    final String norm = _norm(assetPath);
    final String resolvedCore =
        _resolveCoreFromFolder(norm, explicitCore: core);
    final String resolvedType = _resolveTypeName(norm, explicitType: typeName);
    final desc = QLCoreFileDescriptor(
      core: resolvedCore,
      typeName: resolvedType,
      assetPath: norm,
      builtIn: builtIn,
      source: builtIn ? 'built-in' : 'override',
      metadata:
          metadata.isEmpty ? const {} : Map<String, dynamic>.from(metadata),
      registeredAt: DateTime.now(),
    );

    final key = _key(resolvedCore, resolvedType);
    if (builtIn) {
      _builtIns[key] = desc;
    } else {
      _overrides[key] = desc;
    }
    _resolvedCache.remove(key);
  }

  QLCoreFileDescriptor? descriptor(String core, String typeName) {
    final key = _key(core, typeName);
    return _overrides[key] ?? _builtIns[key];
  }

  QLCoreFileDescriptor? descriptorByKey(String key) {
    final normalized = key.trim();
    if (normalized.isEmpty) return null;
    if (normalized.contains('::')) {
      final parts = normalized.split('::');
      if (parts.length >= 2) {
        return descriptor(parts.first, parts.sublist(1).join('::'));
      }
    }
    if (normalized.contains('/')) {
      final parts = normalized.split('/');
      if (parts.length >= 2) {
        return descriptor(parts.first,
            parts.sublist(1).join('/').replaceFirst(RegExp(r'\.[^.]+$'), ''));
      }
    }
    final parts = normalized.split(':');
    if (parts.length == 2) {
      return descriptor(parts.first, parts.last);
    }
    return descriptorForPath(normalized);
  }

  QLCoreFileDescriptor? descriptorForPath(String path, {String? core}) {
    final normPath = _norm(path);
    for (final desc in descriptors(core: core)) {
      if (desc.assetPath == normPath) return desc;
    }
    return null;
  }

  Iterable<QLCoreFileDescriptor> descriptors({String? core}) sync* {
    final keys = <String>{..._builtIns.keys, ..._overrides.keys};
    for (final key in keys) {
      final parts = key.split('::');
      if (parts.length != 2) continue;
      final item = _overrides[key] ?? _builtIns[key];
      if (item == null) continue;
      if (core != null && core.trim().isNotEmpty && item.core != core.trim()) {
        continue;
      }
      yield item;
    }
  }

  Future<Map<String, dynamic>?> resolve(
    String core,
    String typeName, {
    bool useCache = true,
  }) async {
    final key = _key(core, typeName);
    final descriptor = this.descriptor(core, typeName);
    if (descriptor == null) return null;

    if (useCache) {
      final cached = _resolvedCache.get(key);
      if (cached != null) return cached;
      final inflight = _inFlight[key];
      if (inflight != null) return inflight;
    }

    final future = () async {
      final loaded = await _loader(descriptor.assetPath);
      final result = <String, dynamic>{
        ...loaded,
        '_core': descriptor.core,
        '_type': descriptor.typeName,
        '_assetPath': descriptor.assetPath,
        '_builtIn': descriptor.builtIn,
        '_source': descriptor.source,
      };
      if (descriptor.metadata.isNotEmpty) {
        result['_metadata'] = descriptor.metadata;
      }
      if (useCache) {
        _resolvedCache.put(
          key,
          result,
          weight: QLRuntimeCacheSizer.estimate(result),
        );
      }
      return result;
    }();

    if (useCache) _inFlight[key] = future;
    try {
      return await future;
    } finally {
      if (useCache) _inFlight.remove(key);
    }
  }

  Future<Map<String, dynamic>?> resolvePath(
    String path, {
    String? core,
    bool useCache = true,
  }) {
    final descriptor = descriptorForPath(path, core: core);
    if (descriptor == null) return Future.value(null);
    return resolve(descriptor.core, descriptor.typeName, useCache: useCache);
  }

  void clear() {
    _builtIns.clear();
    _overrides.clear();
    _folderToCore.clear();
    _resolvedCache.clear();
    _inFlight.clear();
  }

  Map<String, dynamic> snapshot({String? core}) {
    final items =
        descriptors(core: core).map((e) => e.toMap()).toList(growable: false);
    return {
      'items': items,
    };
  }

  int get count => descriptors().length;
}
