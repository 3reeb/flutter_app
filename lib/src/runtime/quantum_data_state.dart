import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_layout/quantum.dart';
import 'package:quantum_layout/src/runtime/api/network_shell.dart';

typedef QLJsonMap = Map<String, dynamic>;
typedef QLJsonList = List<dynamic>;

/// Shared runtime utilities. Keep all cross-file helper logic here so the
/// pipeline and orchestrator stay lean and do not duplicate parsing/casting
/// or context resolution work.
final class QLRuntimeSupport {
  static BuildContext resolveContext(BuildContext? context,
      {String fallbackKey = 'rootContext'}) {
    if (context != null) return context;

    final fallback =
        QLNativeBridgeRegistry.instance.resolve<dynamic>(fallbackKey);

    if (fallback is BuildContext) return fallback;
    if (fallback is Element) return fallback;

    return const QLNullContext();
  }

  static QLJsonMap mapOf(dynamic value, {Map<String, dynamic>? fallback}) {
    if (value is Map) return Map<String, dynamic>.from(value as Map);
    return fallback ?? <String, dynamic>{};
  }

  static List<Map<String, dynamic>> recordsOf(dynamic value) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList(growable: false);
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final data = map['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList(growable: false);
      }
    }

    return const [];
  }

  static dynamic lastResult(Map<String, dynamic> env) {
    if (env.containsKey(r'$lastResult')) return env[r'$lastResult'];
    if (env.containsKey('\$lastResult')) return env['\$lastResult'];
    return null;
  }

  static bool pathAffects(String changedPath, String watchedPath) {
    if (changedPath == watchedPath) return true;
    return changedPath.startsWith('$watchedPath.') ||
        changedPath.startsWith('$watchedPath[') ||
        watchedPath.startsWith('$changedPath.') ||
        watchedPath.startsWith('$changedPath[');
  }

  static String canonicalPath(Object path) {
    if (path is List) return QLPathUtils.canonicalize(path);
    return path.toString();
  }

  static String safeString(dynamic value) => value?.toString() ?? '';
}

class QLRuntimeCacheStats {
  final int entries;
  final int hits;
  final int misses;
  final int evictions;
  final int weight;

  const QLRuntimeCacheStats({
    required this.entries,
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.weight,
  });

  Map<String, int> toMap() => <String, int>{
        'entries': entries,
        'hits': hits,
        'misses': misses,
        'evictions': evictions,
        'weight': weight,
      };
}

class QLRuntimeCacheConfig {
  final int maxEntries;
  final int maxWeight;
  final Duration? defaultTtl;

  const QLRuntimeCacheConfig({
    this.maxEntries = 3072,
    this.maxWeight = 8 * 1024 * 1024,
    this.defaultTtl,
  });
}

class _QLRuntimeCacheEntry<T> {
  final T value;
  final int weight;
  final DateTime createdAt;
  DateTime lastAccessAt;
  final Duration? ttl;

  _QLRuntimeCacheEntry({
    required this.value,
    required this.weight,
    required this.createdAt,
    required this.lastAccessAt,
    required this.ttl,
  });

  bool isExpired(DateTime now) {
    final Duration? effectiveTtl = ttl;
    if (effectiveTtl == null) return false;
    if (effectiveTtl <= Duration.zero) return true;
    return now.difference(createdAt) >= effectiveTtl;
  }
}

final class QLRuntimeCacheSizer {
  static int estimate(dynamic value, [int depth = 0]) {
    if (depth > 8 || value == null) return 0;
    if (value is String) return value.length * 2;
    if (value is num) return 8;
    if (value is bool) return 1;
    if (value is Uint8List) return value.lengthInBytes;
    if (value is List) {
      var size = 24;
      for (final item in value) {
        size += estimate(item, depth + 1);
      }
      return size;
    }
    if (value is Map) {
      var size = 48;
      for (final entry in value.entries) {
        size += estimate(entry.key, depth + 1);
        size += estimate(entry.value, depth + 1);
      }
      return size;
    }
    return 32;
  }
}

class QLNullContext implements BuildContext {
  const QLNullContext();

  @override
  bool get mounted => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class QLRuntimeCache<T> {
  final QLRuntimeCacheConfig config;
  final LinkedHashMap<Object, _QLRuntimeCacheEntry<T>> _entries =
      LinkedHashMap<Object, _QLRuntimeCacheEntry<T>>();

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  int _weight = 0;

  QLRuntimeCache({this.config = const QLRuntimeCacheConfig()});

  T? get(Object key) {
    final now = DateTime.now();
    final entry = _entries.remove(key);
    if (entry == null) {
      _misses++;
      return null;
    }
    if (entry.isExpired(now)) {
      _weight -= entry.weight;
      _misses++;
      return null;
    }
    entry.lastAccessAt = now;
    _entries[key] = entry;
    _hits++;
    return entry.value;
  }

  T put(Object key, T value, {int? weight, Duration? ttl}) {
    final now = DateTime.now();
    final entryWeight = weight ?? QLRuntimeCacheSizer.estimate(value);
    final previous = _entries.remove(key);
    if (previous != null) _weight -= previous.weight;

    _entries[key] = _QLRuntimeCacheEntry<T>(
      value: value,
      weight: entryWeight,
      createdAt: now,
      lastAccessAt: now,
      ttl: ttl ?? config.defaultTtl,
    );
    _weight += entryWeight;
    _evictIfNeeded();
    return value;
  }

  T getOrPut(Object key, T Function() loader, {int? weight, Duration? ttl}) {
    final cached = get(key);
    if (cached != null) return cached;
    return put(key, loader(), weight: weight, ttl: ttl);
  }

  bool contains(Object key) {
    final entry = _entries[key];
    if (entry == null) return false;
    if (entry.isExpired(DateTime.now())) {
      remove(key);
      return false;
    }
    return true;
  }

  void remove(Object key) {
    final previous = _entries.remove(key);
    if (previous != null) _weight -= previous.weight;
  }

  void removeWhere(
      bool Function(Object key, _QLRuntimeCacheEntry<T> entry) test) {
    final keys = _entries.keys.toList(growable: false);
    for (final key in keys) {
      final entry = _entries[key];
      if (entry != null && test(key, entry)) {
        _entries.remove(key);
        _weight -= entry.weight;
      }
    }
  }

  void clear() {
    _entries.clear();
    _weight = 0;
  }

  void sweepExpired() {
    final now = DateTime.now();
    removeWhere((_, entry) => entry.isExpired(now));
  }

  /// Compacts the cache by removing expired items first and then trimming the
  /// least-recently used tail until the cache fits within its configured
  /// entry and weight budgets. Useful after large SDUI / manifest bursts.
  void compact() {
    sweepExpired();
    _evictIfNeeded();
  }

  QLRuntimeCacheStats get stats => QLRuntimeCacheStats(
        entries: _entries.length,
        hits: _hits,
        misses: _misses,
        evictions: _evictions,
        weight: _weight,
      );

  void _evictIfNeeded() {
    while (_entries.length > config.maxEntries ||
        (config.maxWeight > 0 && _weight > config.maxWeight)) {
      final victimKey = _entries.keys.isEmpty ? null : _entries.keys.first;
      if (victimKey == null) break;
      final victim = _entries.remove(victimKey);
      if (victim != null) _weight -= victim.weight;
      _evictions++;
    }
  }
}

/// Base interface for any action plugin registered into the central VM.
abstract class QLActionPlugin {
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore store, BuildContext ctx);
}

class _QLAsyncBindingHooks {
  final VoidCallback syncData;
  final VoidCallback syncLoading;
  final VoidCallback syncError;

  const _QLAsyncBindingHooks({
    required this.syncData,
    required this.syncLoading,
    required this.syncError,
  });
}

class QLStoreRegistry {
  static final QLStoreRegistry instance = QLStoreRegistry._();
  QLStoreRegistry._();

  final Map<String, QLDataStore> _stores = <String, QLDataStore>{};
  late final QLDataStore defaultStore = QLDataStore(namespace: 'default');

  QLDataStore get(String namespace) {
    if (namespace == 'default') return defaultStore;
    return _stores.putIfAbsent(
        namespace, () => QLDataStore(namespace: namespace));
  }

  bool exists(String namespace) =>
      namespace == 'default' || _stores.containsKey(namespace);

  void destroy(String namespace) {
    if (namespace == 'default') {
      defaultStore.sweep('');
      defaultStore.clearCache();
      return;
    }
    final store = _stores.remove(namespace);
    store?.dispose();
  }

  void clearAll() {
    for (final store in _stores.values) {
      store.dispose();
    }
    _stores.clear();
    defaultStore.sweep('');
    defaultStore.clearCache();
  }

  /// Export a lightweight snapshot of every mounted store namespace.
  Map<String, dynamic> snapshot({bool includeDefault = true}) {
    final namespaces = <Map<String, dynamic>>[];
    if (includeDefault) {
      namespaces.add(_storeSnapshot('default', defaultStore));
    }
    for (final entry in _stores.entries) {
      namespaces.add(_storeSnapshot(entry.key, entry.value));
    }
    return <String, dynamic>{
      'count': namespaces.length,
      'namespaces': namespaces,
    };
  }

  Map<String, dynamic> _storeSnapshot(String namespace, QLDataStore store) {
    return <String, dynamic>{
      'namespace': namespace,
      'signalCount': store.signalCount,
      'computedCount': store.computedCount,
      'cacheStats': {
        'hits': store.cacheStats.hits,
        'misses': store.cacheStats.misses,
        'evictions': store.cacheStats.evictions,
        'weight': store.cacheStats.weight,
      },
      'state': store.snapshot,
    };
  }
}

typedef QLMutationFn = FutureOr<dynamic> Function(
    QLDataStore store, Map<String, dynamic> payload);

typedef QLQueryFn = Future<dynamic> Function(
    QLDataStore store, Map<String, dynamic> payload);

class QLDataStore {
  final String namespace;

  QLDataStore({required this.namespace});

  final Map<String, QLSignal<dynamic>> _signals = <String, QLSignal<dynamic>>{};
  final Map<String, List<_ComputationNode>> _dependencyGraph =
      <String, List<_ComputationNode>>{};
  final Map<String, _ComputationNode> _computedRegistry =
      <String, _ComputationNode>{};
  final List<VoidCallback> _persistenceListeners = <VoidCallback>[];
  final QLRuntimeCache<dynamic> _readCache = QLRuntimeCache<dynamic>(
    config: const QLRuntimeCacheConfig(
      maxEntries: 4096,
      maxWeight: 2 * 1024 * 1024,
    ),
  );
  static final Object _nullCacheSentinel = Object();

  final Map<String, Set<String>> _pathIndex = <String, Set<String>>{};
  final Map<String, QLAsyncSignal<dynamic>> _asyncBindings =
      <String, QLAsyncSignal<dynamic>>{};
  final Map<String, _QLAsyncBindingHooks> _asyncBindingHooks =
      <String, _QLAsyncBindingHooks>{};

  bool _isBatching = false;
  bool get isBatching => _isBatching;
  bool _commitQueued = false;
  int _batchDepth = 0;
  final Set<String> _txDirtyKeys = <String>{};
  final Set<QLSignal<dynamic>> _dirtySignals = <QLSignal<dynamic>>{};

  final List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];
  static const int _maxHistory = 20;

  Map<String, dynamic> get snapshot => Map.unmodifiable(
        _signals.map((k, v) => MapEntry(k, v.value)),
      );

  int get signalCount => _signals.length;
  int get computedCount => _computedRegistry.length;
  List<String> get signalKeys => List<String>.unmodifiable(_signals.keys);
  List<String> get computedKeys =>
      List<String>.unmodifiable(_computedRegistry.keys);

  void _indexSignalKey(String key) {
    for (final prefix in QLPathUtils.prefixes(key)) {
      _pathIndex.putIfAbsent(prefix, () => <String>{}).add(key);
    }
  }

  void _unindexSignalKey(String key) {
    for (final prefix in QLPathUtils.prefixes(key)) {
      final bucket = _pathIndex[prefix];
      if (bucket == null) continue;
      bucket.remove(key);
      if (bucket.isEmpty) _pathIndex.remove(prefix);
    }
  }

// 🚀 ADD THIS TO QLDataStore (quantum_data_state.dart)
  void setSilent(String path, dynamic value) {
    if (!path.contains('.') && !path.contains('[')) {
      final sig = signal(path);
      sig.setSilent(value);
      // We manually update the read cache so subsequent gets see the silent write
      _invalidateReadCache(path);
      return;
    }

    final strides = QLPathUtils.resolve(path);
    if (strides.isEmpty) return;

    final rootKey = strides.first.toString();
    final rootSignal = signal(rootKey);
    final nextRoot = _immutableMutate(rootSignal.value, strides, 1, value);
    if (rootSignal.value == nextRoot) return;

    _invalidateReadCache(path);
    _invalidateReadCache(rootKey);
    rootSignal.setSilent(nextRoot);

    final direct = _signals[path];
    if (direct != null && direct != rootSignal) {
      direct.setSilent(value);
    }
  }

  QLSignal<dynamic> signal(String key) => _signals.putIfAbsent(key, () {
        _indexSignalKey(key);
        return QLSignal<dynamic>(null);
      });

  QLSignal<dynamic>? maybeSignal(String key) => _signals[key];

  void bindAsync(String basePath, QLAsyncSignal<dynamic> asyncSignal) {
    final previous = _asyncBindingHooks.remove(basePath);
    if (previous != null) {
      final existing = _asyncBindings[basePath];
      existing?.data.removeListener(previous.syncData);
      existing?.loading.removeListener(previous.syncLoading);
      existing?.error.removeListener(previous.syncError);
    }

    _asyncBindings[basePath] = asyncSignal;
    final dataKey = '$basePath.data';
    final loadKey = '$basePath.loading';
    final errorKey = '$basePath.error';

    set(dataKey, asyncSignal.data.value);
    set(loadKey, asyncSignal.loading.value);
    set(errorKey, asyncSignal.error.value?.toString());

    void syncData() => set(dataKey, asyncSignal.data.value);
    void syncLoading() => set(loadKey, asyncSignal.loading.value);
    void syncError() => set(errorKey, asyncSignal.error.value?.toString());

    asyncSignal.data.addListener(syncData);
    asyncSignal.loading.addListener(syncLoading);
    asyncSignal.error.addListener(syncError);

    _asyncBindingHooks[basePath] = _QLAsyncBindingHooks(
      syncData: syncData,
      syncLoading: syncLoading,
      syncError: syncError,
    );
  }

  void registerComputed(String targetKey, List<String> dependencies,
      dynamic Function(List<dynamic>) calculator) {
    final previous = _computedRegistry[targetKey];
    if (previous != null) {
      for (final dep in previous.dependencies) {
        final bucket = _dependencyGraph[dep];
        bucket?.remove(previous);
        if (bucket != null && bucket.isEmpty) {
          _dependencyGraph.remove(dep);
        }
      }
    }

    final node = _ComputationNode(
      targetKey,
      signal(targetKey),
      dependencies,
      calculator,
      this,
    );
    _computedRegistry[targetKey] = node;

    for (final dep in dependencies) {
      _dependencyGraph.putIfAbsent(dep, () => <_ComputationNode>[]).add(node);
    }

    node.evaluateSilent();
    _scheduleCommit();
  }

  void transaction(VoidCallback block) {
    _batchDepth++;
    _isBatching = true;
    try {
      block();
    } finally {
      _batchDepth--;
      _isBatching = _batchDepth > 0;
    }

    if (_batchDepth == 0 && _txDirtyKeys.isNotEmpty && !_commitQueued) {
      _commitQueued = true;
      scheduleMicrotask(() {
        _commitQueued = false;
        _commitTransaction();
      });
    }
  }

  void _commitTransaction() {
    if (_txDirtyKeys.isEmpty) return;

    _evaluateTopologicalComputes();

    for (final sig in _dirtySignals) {
      sig.forceNotify();
    }

    _txDirtyKeys.clear();
    _dirtySignals.clear();
    _notifyPersistence();
  }

  dynamic _immutableMutate(
      dynamic current, List<dynamic> strides, int index, dynamic value) {
    if (index == strides.length) return value;

    final Object key = strides[index];
    final bool createList =
        index < strides.length - 1 && strides[index + 1] is int;

    if (current is List && key is int) {
      final List<dynamic> copy = List<dynamic>.from(current);
      while (copy.length <= key) {
        copy.add(null);
      }
      copy[key] = _immutableMutate(
        copy[key] ?? (createList ? <dynamic>[] : <String, dynamic>{}),
        strides,
        index + 1,
        value,
      );
      return copy;
    }

    final String mapKey = key.toString();
    final Map<String, dynamic> copy = Map<String, dynamic>.from(
      current is Map ? current : <String, dynamic>{},
    );
    copy[mapKey] = _immutableMutate(
      copy[mapKey] ?? (createList ? <dynamic>[] : <String, dynamic>{}),
      strides,
      index + 1,
      value,
    );
    return copy;
  }

  void set(String path, dynamic value) {
    transaction(() {
      if (!path.contains('.') && !path.contains('[')) {
        final sig = signal(path);
        if (sig.value == value) return;
        _invalidateReadCache(path);
        _txDirtyKeys.add(path);
        sig.setSilent(value);
        _dirtySignals.add(sig);
        _notifyCascades(path);
        return;
      }

      final strides = QLPathUtils.resolve(path);
      if (strides.isEmpty) return;

      final rootKey = strides.first.toString();
      final rootSignal = signal(rootKey);
      final nextRoot = _immutableMutate(rootSignal.value, strides, 1, value);
      if (rootSignal.value == nextRoot) return;

      _invalidateReadCache(path);
      _invalidateReadCache(rootKey);
      _txDirtyKeys.add(path);
      _txDirtyKeys.add(rootKey);
      rootSignal.setSilent(nextRoot);
      _dirtySignals.add(rootSignal);

      final direct = _signals[path];
      if (direct != null && direct != rootSignal && direct.value != value) {
        direct.setSilent(value);
        _dirtySignals.add(direct);
      }

      _notifyCascades(path);
    });
  }

  dynamic get(Object path) {
    final String cacheKey = QLRuntimeSupport.canonicalPath(path);
    final cached = _readCache.get(cacheKey);
    if (identical(cached, _nullCacheSentinel)) return null;
    if (cached != null) return cached;

    final List<dynamic> strides =
        path is List ? path : QLPathUtils.resolve(path.toString());
    if (strides.isEmpty) return null;

    final rootKey = strides.first.toString();
    dynamic current = _signals[rootKey]?.value;

    for (int i = 1; i < strides.length && current != null; i++) {
      final Object key = strides[i];
      if (current is Map) {
        current = current[key.toString()];
      } else if (current is List && key is int) {
        current = (key >= 0 && key < current.length) ? current[key] : null;
      } else {
        current = null;
        break;
      }
    }

    _readCache.put(
      cacheKey,
      current ?? _nullCacheSentinel,
      weight: current == null ? 1 : null,
    );
    return current;
  }

  void merge(Map<String, dynamic> data, {bool clearMissing = false}) {
    transaction(() {
      if (clearMissing) {
        final missing = _signals.keys
            .where((k) => !data.containsKey(k))
            .toList(growable: false);
        for (final key in missing) {
          final node = _computedRegistry.remove(key);
          if (node != null) {
            for (final dep in node.dependencies) {
              final bucket = _dependencyGraph[dep];
              bucket?.remove(node);
              if (bucket != null && bucket.isEmpty) {
                _dependencyGraph.remove(dep);
              }
            }
          }
          final sig = _signals.remove(key);
          sig?.dispose();
          _unindexSignalKey(key);
        }
      }
      data.forEach(set);
    });
  }

  void saveSnapshot() {
    if (_history.length >= _maxHistory) _history.removeAt(0);
    _history.add(snapshot);
  }

  void rollback() {
    if (_history.isEmpty) return;
    merge(_history.removeLast(), clearMissing: true);
  }

  void clearCache() => _readCache.clear();

  QLRuntimeCacheStats get cacheStats => _readCache.stats;

  bool has(String path) {
    final List<dynamic> strides = QLPathUtils.resolve(
      QLRuntimeSupport.canonicalPath(path),
    );
    if (strides.isEmpty) return false;

    dynamic current = snapshot;
    for (var i = 0; i < strides.length; i++) {
      final segment = strides[i];
      if (i == 0) {
        if (current is! Map) return false;
        final key = segment.toString();
        if (!current.containsKey(key)) return false;
        current = current[key];
      } else if (current is Map) {
        final key = segment.toString();
        if (!current.containsKey(key)) return false;
        current = current[key];
      } else if (current is List && segment is int) {
        if (segment < 0 || segment >= current.length) return false;
        current = current[segment];
      } else {
        return false;
      }

      if (current == null && i < strides.length - 1) {
        return false;
      }
    }

    return true;
  }

  void sweep(String pathPrefix) {
    final canonicalPrefix = QLRuntimeSupport.canonicalPath(pathPrefix);
    _invalidateReadCache(canonicalPrefix);

    final prefixSegments = QLPathUtils.resolve(canonicalPrefix);
    final keys = _signals.keys.toList(growable: false);
    bool changed = false;

    if (prefixSegments.isEmpty) {
      for (final key in keys) {
        final node = _computedRegistry.remove(key);
        if (node != null) {
          for (final dep in node.dependencies) {
            final bucket = _dependencyGraph[dep];
            bucket?.remove(node);
            if (bucket != null && bucket.isEmpty) {
              _dependencyGraph.remove(dep);
            }
          }
        }
        _dependencyGraph.remove(key);
        final notifier = _signals.remove(key);
        notifier?.dispose();
        _unindexSignalKey(key);
        changed = true;
      }
      if (changed) _scheduleCommit();
      return;
    }

    for (final key in keys) {
      final keySegments = QLPathUtils.resolve(key);
      final isExactOrDescendant =
          _qlPathStartsWith(keySegments, prefixSegments);
      final isAncestor = _qlPathStartsWith(prefixSegments, keySegments) &&
          keySegments.length < prefixSegments.length;

      if (isExactOrDescendant) {
        final node = _computedRegistry.remove(key);
        if (node != null) {
          for (final dep in node.dependencies) {
            final bucket = _dependencyGraph[dep];
            bucket?.remove(node);
            if (bucket != null && bucket.isEmpty) {
              _dependencyGraph.remove(dep);
            }
          }
        }
        _dependencyGraph.remove(key);
        final notifier = _signals.remove(key);
        notifier?.dispose();
        _unindexSignalKey(key);
        changed = true;
        continue;
      }

      if (!isAncestor) continue;
      final rootSignal = _signals[key];
      if (rootSignal == null) continue;
      final relative = prefixSegments.sublist(keySegments.length);
      final updated = _qlImmutableDelete(rootSignal.value, relative, 0);
      if (identical(updated, _qlDeleteNoop) || updated == rootSignal.value) {
        continue;
      }
      rootSignal.setSilent(updated);
      _dirtySignals.add(rootSignal);
      _txDirtyKeys.add(key);
      _invalidateReadCache(key);
      _notifyCascades(key);
      changed = true;
    }

    if (changed) {
      _scheduleCommit();
    }
  }

  void dispose() {
    for (final entry in _asyncBindingHooks.entries) {
      final asyncSignal = _asyncBindings[entry.key];
      if (asyncSignal == null) continue;
      asyncSignal.data.removeListener(entry.value.syncData);
      asyncSignal.loading.removeListener(entry.value.syncLoading);
      asyncSignal.error.removeListener(entry.value.syncError);
    }
    _asyncBindings.clear();
    _asyncBindingHooks.clear();
    sweep('');
    clearCache();
    _persistenceListeners.clear();
    _history.clear();
  }

  void addPersistenceListener(VoidCallback listener) =>
      _persistenceListeners.add(listener);

  void removePersistenceListener(VoidCallback listener) =>
      _persistenceListeners.remove(listener);

  void _notifyPersistence() {
    for (final listener in _persistenceListeners) {
      listener();
    }
  }

  void _scheduleCommit() {
    if (_batchDepth > 0 || _commitQueued || _txDirtyKeys.isEmpty) return;
    _commitQueued = true;
    scheduleMicrotask(() {
      _commitQueued = false;
      _commitTransaction();
    });
  }

  void _invalidateReadCache(String mutatedPath) {
    _readCache.removeWhere((key, _) {
      if (key is! String) return false;
      return key == mutatedPath ||
          key.startsWith('$mutatedPath.') ||
          key.startsWith('$mutatedPath[') ||
          mutatedPath.startsWith('$key.') ||
          mutatedPath.startsWith('$key[');
    });
  }

  void _notifyCascades(String mutatedPath) {
    final Set<String> dirty = <String>{};
    for (final prefix in QLPathUtils.prefixes(mutatedPath)) {
      final bucket = _pathIndex[prefix];
      if (bucket != null) dirty.addAll(bucket);
    }

    for (final key in dirty) {
      if (key == mutatedPath) continue;
      final sig = _signals[key];
      if (sig != null) {
        _txDirtyKeys.add(key);
        _dirtySignals.add(sig);
      }
    }
  }

  void _evaluateTopologicalComputes() {
    if (_txDirtyKeys.isEmpty || _computedRegistry.isEmpty) return;

    final Set<String> toEvaluate = <String>{};
    final List<String> queue = _txDirtyKeys.toList(growable: true);

    for (int i = 0; i < queue.length; i++) {
      final dependents = _dependencyGraph[queue[i]];
      if (dependents == null) continue;

      for (final node in dependents) {
        if (toEvaluate.add(node.targetKey)) {
          queue.add(node.targetKey);
        }
      }
    }

    for (final key in toEvaluate) {
      _computedRegistry[key]?.evaluateSilent();
    }
  }

  Map<String, dynamic> getAll() => snapshot;
}

class _ComputationNode {
  final String targetKey;
  final QLSignal<dynamic> targetSignal;
  final List<String> dependencies;
  final dynamic Function(List<dynamic> values) calculator;
  final QLDataStore store;

  _ComputationNode(this.targetKey, this.targetSignal, this.dependencies,
      this.calculator, this.store);

  void evaluateSilent() {
    final values =
        dependencies.map((k) => store.get(k)).toList(growable: false);
    final result = calculator(values);

    if (targetSignal.value == result) return;

    targetSignal.setSilent(result);
    store._dirtySignals.add(targetSignal);
    store._txDirtyKeys.add(targetKey);
    store._invalidateReadCache(targetKey);

    if (targetKey.contains('.') || targetKey.contains('[')) {
      final strides = QLPathUtils.resolve(targetKey);
      if (strides.isNotEmpty) {
        final rootKey = strides.first.toString();
        final rootSignal = store.signal(rootKey);
        final nextRoot =
            store._immutableMutate(rootSignal.value, strides, 1, result);
        if (rootSignal.value != nextRoot) {
          rootSignal.setSilent(nextRoot);
          store._dirtySignals.add(rootSignal);
          store._txDirtyKeys.add(rootKey);
        }
      }
    }
  }
}

class QLDataScope extends InheritedWidget {
  final Map<String, dynamic> localData;
  final QLDataStore? localStore;
  final QLDataStore? moduleStore;

  const QLDataScope({
    super.key,
    this.localData = const {},
    this.localStore,
    this.moduleStore,
    required super.child,
  });

  static QLDataScope? ofNode(BuildContext context) {
    try {
      if (!context.mounted) return null;
      return context.dependOnInheritedWidgetOfExactType<QLDataScope>();
    } catch (_) {
      return null;
    }
  }

  static QLDataScope? readNode(BuildContext context) {
    try {
      if (!context.mounted) return null;
      final element =
          context.getElementForInheritedWidgetOfExactType<QLDataScope>();
      return element?.widget as QLDataScope?;
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> of(BuildContext context) =>
      readNode(context)?.localData ?? const {};

  static QLDataStore resolveStore(BuildContext? context) {
    if (context == null) return QLStoreRegistry.instance.defaultStore;

    QLDataStore? resolved;
    try {
      context.visitAncestorElements((element) {
        final widget = element.widget;
        if (widget is QLDataScope) {
          if (widget.localStore != null) {
            resolved = widget.localStore;
            return false;
          }
          if (widget.moduleStore != null) {
            resolved = widget.moduleStore;
            return false;
          }
        }
        return true;
      });
    } catch (_) {
      // Fall through to the nearest readable scope / default store.
    }

    if (resolved != null) return resolved!;

    final scope = readNode(context);
    return scope?.localStore ??
        scope?.moduleStore ??
        QLStoreRegistry.instance.defaultStore;
  }

  @override
  bool updateShouldNotify(QLDataScope old) =>
      localData != old.localData ||
      localStore != old.localStore ||
      moduleStore != old.moduleStore;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>(
        'localData keys', localData.keys.join(', ')));
    properties.add(DiagnosticsProperty<String>(
        'localStore', localStore != null ? 'Present' : 'Null'));
    properties.add(DiagnosticsProperty<String>(
        'moduleStore', moduleStore != null ? 'Present' : 'Null'));
  }
}

String _qlCanonicalStatePath(Object path) =>
    QLRuntimeSupport.canonicalPath(path);

Map<String, dynamic> _qlMapOf(dynamic value) {
  if (value is Map)
    return Map<String, dynamic>.from(value.cast<String, dynamic>());
  return <String, dynamic>{};
}

List<dynamic> _qlListOf(dynamic value) {
  if (value is List) return List<dynamic>.from(value);
  if (value is Set) return value.toList(growable: false);
  if (value == null) return const [];
  return <dynamic>[value];
}

bool _qlHasBindingSpec(Map<String, dynamic> map) {
  return map.containsKey('mode') ||
      map.containsKey('from') ||
      map.containsKey('source') ||
      map.containsKey('dataSource') ||
      map.containsKey('bind') ||
      map.containsKey('merge') ||
      map.containsKey('transform') ||
      map.containsKey('subscribe') ||
      map.containsKey('realtime');
}

bool _qlHasComputedSpec(Map<String, dynamic> map) {
  return map.containsKey('deps') ||
      map.containsKey('dependencies') ||
      map.containsKey('expr') ||
      map.containsKey('compute') ||
      map.containsKey('op') ||
      map.containsKey('strategy');
}

bool _qlHasStrategySpec(Map<String, dynamic> map) {
  return map.containsKey('strategy') ||
      map.containsKey('op') ||
      map.containsKey('type') ||
      map.containsKey('steps') ||
      map.containsKey('action');
}

dynamic _qlDeepMergeValue(dynamic current, dynamic incoming,
    {String merge = 'replace'}) {
  switch (merge) {
    case 'replace':
      return incoming;
    case 'mergeMap':
    case 'merge':
    case 'hybrid':
      if (current is Map && incoming is Map) {
        final out = Map<String, dynamic>.from(current.cast<String, dynamic>());
        for (final entry in incoming.entries) {
          final key = entry.key.toString();
          final prev = out[key];
          final next = entry.value;
          if (prev is Map && next is Map) {
            out[key] = _qlDeepMergeValue(prev, next, merge: 'mergeMap');
          } else {
            out[key] = next;
          }
        }
        return out;
      }
      if (current is List && incoming is List) {
        return <dynamic>[...current, ...incoming];
      }
      return incoming;
    case 'append':
      if (current is List) {
        if (incoming is List) return <dynamic>[...current, ...incoming];
        return <dynamic>[...current, incoming];
      }
      if (incoming is List) return incoming;
      return <dynamic>[current, incoming];
    case 'prepend':
      if (current is List) {
        if (incoming is List) return <dynamic>[...incoming, ...current];
        return <dynamic>[incoming, ...current];
      }
      if (incoming is List) return incoming;
      return <dynamic>[incoming, current];
    case 'appendById':
      if (current is List && incoming is List) {
        final out = <dynamic>[...current];
        final seen = <String>{};
        for (final item in out) {
          if (item is Map) {
            final id = item['id']?.toString() ?? item['key']?.toString();
            if (id != null && id.isNotEmpty) seen.add(id);
          }
        }
        for (final item in incoming) {
          if (item is Map) {
            final id = item['id']?.toString() ?? item['key']?.toString();
            if (id != null && id.isNotEmpty) {
              if (seen.add(id)) out.add(item);
              continue;
            }
          }
          out.add(item);
        }
        return out;
      }
      return _qlDeepMergeValue(current, incoming, merge: 'append');
    default:
      return incoming;
  }
}

const Object _qlDeleteNoop = Object();

bool _qlPathStartsWith(List<dynamic> path, List<dynamic> prefix) {
  if (prefix.length > path.length) return false;
  for (var i = 0; i < prefix.length; i++) {
    final a = path[i];
    final b = prefix[i];
    if (a is int || b is int) {
      if (a is! int || b is! int || a != b) return false;
    } else if (a.toString() != b.toString()) {
      return false;
    }
  }
  return true;
}

dynamic _qlImmutableDelete(
  dynamic current,
  List<dynamic> strides,
  int index,
) {
  if (index >= strides.length) return _qlDeleteNoop;
  if (current == null) return _qlDeleteNoop;

  final key = strides[index];
  final bool isLast = index == strides.length - 1;

  if (current is Map) {
    final mapKey = key.toString();
    if (!current.containsKey(mapKey)) return _qlDeleteNoop;
    if (isLast) {
      final copy = Map<String, dynamic>.from(current.cast<String, dynamic>());
      copy.remove(mapKey);
      return copy;
    }

    final child = current[mapKey];
    final next = _qlImmutableDelete(child, strides, index + 1);
    if (identical(next, _qlDeleteNoop)) return _qlDeleteNoop;
    final copy = Map<String, dynamic>.from(current.cast<String, dynamic>());
    copy[mapKey] = next;
    return copy;
  }

  if (current is List) {
    final idx = key is int ? key : int.tryParse(key.toString());
    if (idx == null || idx < 0 || idx >= current.length) return _qlDeleteNoop;
    if (isLast) {
      final copy = List<dynamic>.from(current);
      copy.removeAt(idx);
      return copy;
    }

    final child = current[idx];
    final next = _qlImmutableDelete(child, strides, index + 1);
    if (identical(next, _qlDeleteNoop)) return _qlDeleteNoop;
    final copy = List<dynamic>.from(current);
    copy[idx] = next;
    return copy;
  }

  return _qlDeleteNoop;
}

dynamic _qlReadPathValue(dynamic root, Object path) {
  final strides = path is List ? path : QLPathUtils.resolve(path.toString());
  if (strides.isEmpty) return root;
  dynamic current = root;
  for (final stride in strides) {
    if (current == null) return null;
    if (current is Map) {
      current = current[stride.toString()];
    } else if (current is List && stride is int) {
      current =
          (stride >= 0 && stride < current.length) ? current[stride] : null;
    } else {
      return null;
    }
  }
  return current;
}

@immutable
class QLSliceFieldPolicy {
  final String path;
  final String storageMode;
  final bool reactive;
  final bool immutable;
  final bool readOnly;
  final bool lazy;
  final bool streaming;
  final bool cacheResults;
  final bool pinInMemory;
  final bool sensitive;
  final String? resourceId;
  final String? resolver;
  final Map<String, dynamic> metadata;

  const QLSliceFieldPolicy({
    required this.path,
    this.storageMode = 'hot',
    this.reactive = true,
    this.immutable = false,
    this.readOnly = false,
    this.lazy = false,
    this.streaming = false,
    this.cacheResults = true,
    this.pinInMemory = false,
    this.sensitive = false,
    this.resourceId,
    this.resolver,
    this.metadata = const {},
  });

  factory QLSliceFieldPolicy.from(dynamic raw, {String path = ''}) {
    if (raw is! Map) {
      return QLSliceFieldPolicy(path: path);
    }
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    return QLSliceFieldPolicy(
      path: path.isNotEmpty ? path : map['path']?.toString() ?? '',
      storageMode: map['storageMode']?.toString() ??
          map['storage']?.toString() ??
          map['mode']?.toString() ??
          'hot',
      reactive: map['reactive'] != false,
      immutable: map['immutable'] == true || map['frozen'] == true,
      readOnly: map['readOnly'] == true || map['readonly'] == true,
      lazy: map['lazy'] == true || map['defer'] == true,
      streaming: map['streaming'] == true || map['stream'] == true,
      cacheResults: map['cache'] != false && map['cacheResults'] != false,
      pinInMemory: map['pin'] == true || map['pinInMemory'] == true,
      sensitive: map['sensitive'] == true || map['secret'] == true,
      resourceId: map['resourceId']?.toString() ??
          map['id']?.toString() ??
          map['ref']?.toString(),
      resolver: map['resolver']?.toString(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'path': path,
        'storageMode': storageMode,
        'reactive': reactive,
        'immutable': immutable,
        'readOnly': readOnly,
        'lazy': lazy,
        'streaming': streaming,
        'cacheResults': cacheResults,
        'pinInMemory': pinInMemory,
        'sensitive': sensitive,
        if (resourceId != null) 'resourceId': resourceId,
        if (resolver != null) 'resolver': resolver,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QLSliceResourceRef {
  final String id;
  final String scheme;
  final String uri;
  final bool cacheable;
  final bool streaming;
  final bool lazy;
  final String? mimeType;
  final Map<String, dynamic> metadata;

  const QLSliceResourceRef({
    required this.id,
    required this.scheme,
    required this.uri,
    this.cacheable = true,
    this.streaming = false,
    this.lazy = true,
    this.mimeType,
    this.metadata = const {},
  });

  factory QLSliceResourceRef.from(dynamic raw, {String fallbackId = ''}) {
    if (raw is QLSliceResourceRef) return raw;
    if (raw is! Map) {
      final uri = raw?.toString() ?? '';
      final scheme = uri.contains(':') ? uri.split(':').first : 'ref';
      final id = fallbackId.isNotEmpty ? fallbackId : uri;
      return QLSliceResourceRef(id: id, scheme: scheme, uri: uri);
    }
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    final uri = map['uri']?.toString() ??
        map['source']?.toString() ??
        map['path']?.toString() ??
        map['value']?.toString() ??
        '';
    final scheme = map['scheme']?.toString() ??
        (uri.contains(':') ? uri.split(':').first : 'ref');
    final id = map['id']?.toString() ??
        map['resourceId']?.toString() ??
        map['name']?.toString() ??
        fallbackId;
    return QLSliceResourceRef(
      id: id.isEmpty ? uri : id,
      scheme: scheme,
      uri: uri,
      cacheable: map['cacheable'] != false && map['cache'] != false,
      streaming: map['streaming'] == true || map['stream'] == true,
      lazy: map['lazy'] != false,
      mimeType: map['mimeType']?.toString() ?? map['contentType']?.toString(),
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : <String, dynamic>{},
    );
  }

  String get cacheKey => '$scheme::$id::$uri';

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'scheme': scheme,
        'uri': uri,
        'cacheable': cacheable,
        'streaming': streaming,
        'lazy': lazy,
        if (mimeType != null) 'mimeType': mimeType,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

typedef QLSliceResourceResolver = FutureOr<dynamic> Function(
  QLSliceResourceRef ref,
  QLSliceExecutionContext ctx,
);

@immutable
class QLSliceProtection {
  final String level;
  final String? ownerId;
  final Set<String> allowUsers;
  final Set<String> allowRoles;
  final Set<String> denyUsers;
  final Set<String> denyRoles;
  final bool requireAuth;
  final bool requireFreshSession;
  final bool redactInSnapshots;
  final Map<String, dynamic> metadata;

  const QLSliceProtection({
    this.level = 'public',
    this.ownerId,
    this.allowUsers = const {},
    this.allowRoles = const {},
    this.denyUsers = const {},
    this.denyRoles = const {},
    this.requireAuth = false,
    this.requireFreshSession = false,
    this.redactInSnapshots = false,
    this.metadata = const {},
  });

  factory QLSliceProtection.from(dynamic raw) {
    if (raw is! Map) return const QLSliceProtection();
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    Set<String> _stringSet(dynamic value) => value is Iterable
        ? value.map((e) => e.toString()).where((v) => v.isNotEmpty).toSet()
        : const <String>{};
    return QLSliceProtection(
      level:
          map['level']?.toString() ?? map['visibility']?.toString() ?? 'public',
      ownerId: map['ownerId']?.toString() ?? map['owner']?.toString(),
      allowUsers: _stringSet(map['allowUsers'] ?? map['users']),
      allowRoles: _stringSet(map['allowRoles'] ?? map['roles']),
      denyUsers: _stringSet(map['denyUsers']),
      denyRoles: _stringSet(map['denyRoles']),
      requireAuth: map['requireAuth'] == true || map['authRequired'] == true,
      requireFreshSession:
          map['requireFreshSession'] == true || map['freshSession'] == true,
      redactInSnapshots:
          map['redactInSnapshots'] == true || map['redact'] == true,
      metadata: map['metadata'] is Map
          ? Map<String, dynamic>.from(map['metadata'] as Map)
          : <String, dynamic>{},
    );
  }

  bool allows(
    SessionContext? session, {
    String? namespace,
    Map<String, dynamic> claims = const {},
  }) {
    if (level == 'public') return true;
    if (session == null || !session.isAuthenticated) {
      return !requireAuth && level != 'secure';
    }
    if (requireFreshSession && session.isExpired) return false;
    if (ownerId != null && session.userId != ownerId && level == 'owner') {
      return false;
    }
    if (allowUsers.contains(session.userId) || allowUsers.contains('*')) {
      return true;
    }
    final roles = _claimStrings(session.claims['roles'] ?? claims['roles']);
    if (roles.any(allowRoles.contains) || allowRoles.contains('*')) {
      return true;
    }
    if (denyUsers.contains(session.userId) || denyUsers.contains('*')) {
      return false;
    }
    if (roles.any(denyRoles.contains) || denyRoles.contains('*')) {
      return false;
    }
    return switch (level) {
      'local' => namespace != null && namespace.isNotEmpty,
      'owner' => ownerId != null && session.userId == ownerId,
      'authenticated' => session.isAuthenticated,
      'secure' => session.isAuthenticated,
      _ => true,
    };
  }

  Map<String, dynamic> toMap({bool redact = false}) => <String, dynamic>{
        'level': level,
        if (!redact && ownerId != null) 'ownerId': ownerId,
        'requireAuth': requireAuth,
        'requireFreshSession': requireFreshSession,
        'redactInSnapshots': redactInSnapshots,
        if (!redact) 'allowUsers': allowUsers.toList(growable: false),
        if (!redact) 'allowRoles': allowRoles.toList(growable: false),
        if (!redact) 'denyUsers': denyUsers.toList(growable: false),
        if (!redact) 'denyRoles': denyRoles.toList(growable: false),
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

@immutable
class QLSliceResourceState {
  final QLSliceResourceRef ref;
  final QLSliceFieldPolicy policy;
  final dynamic value;

  const QLSliceResourceState({
    required this.ref,
    required this.policy,
    this.value,
  });

  bool get isResolved => value != null;
}

final class QLSliceResourceRegistry {
  static final QLSliceResourceRegistry instance = QLSliceResourceRegistry._();
  QLSliceResourceRegistry._();

  final Map<String, QLSliceResourceResolver> _schemes =
      <String, QLSliceResourceResolver>{};
  final Map<String, QLSliceResourceResolver> _ids =
      <String, QLSliceResourceResolver>{};
  final QLRuntimeCache<dynamic> _cache = QLRuntimeCache<dynamic>(
    config: const QLRuntimeCacheConfig(
      maxEntries: 1024,
      maxWeight: 16 * 1024 * 1024,
    ),
  );

  void registerScheme(String scheme, QLSliceResourceResolver resolver) {
    _schemes[scheme.trim().toLowerCase()] = resolver;
  }

  void registerResource(String id, QLSliceResourceResolver resolver) {
    _ids[id.trim()] = resolver;
  }

  bool hasResolver(QLSliceResourceRef ref) =>
      _ids.containsKey(ref.id) ||
      _schemes.containsKey(ref.scheme.toLowerCase());

  FutureOr<dynamic> resolve(
    QLSliceResourceRef ref,
    QLSliceExecutionContext ctx, {
    bool cache = true,
  }) {
    final cacheKey = '${ctx.namespace}::${ref.cacheKey}';
    if (cache && ref.cacheable) {
      final cached = _cache.get(cacheKey);
      if (cached != null) return cached;
    }

    final resolver =
        _ids[ref.id] ?? _schemes[ref.scheme.toLowerCase()] ?? _schemes['*'];
    if (resolver == null) return ref;

    final resolved = resolver(ref, ctx);
    if (resolved is Future) {
      if (!cache || !ref.cacheable) return resolved;
      return resolved.then((value) {
        if (value != null) {
          _cache.put(cacheKey, value,
              weight: QLRuntimeCacheSizer.estimate(value));
        }
        return value;
      });
    }

    if (cache && ref.cacheable && resolved != null) {
      _cache.put(cacheKey, resolved,
          weight: QLRuntimeCacheSizer.estimate(resolved));
    }
    return resolved;
  }

  void clear() => _cache.clear();
}

SessionContext? _qlSessionFromEnv(Map<String, dynamic> env) {
  final dynamic raw = env['session'] ?? env['auth'] ?? env['context'];
  if (raw is SessionContext) return raw;
  if (raw is Map) {
    final map = Map<String, dynamic>.from(raw);
    return SessionContext(
      userId: map['userId']?.toString(),
      sessionId: map['sessionId']?.toString(),
      accessToken: map['accessToken']?.toString(),
      refreshToken: map['refreshToken']?.toString(),
      expiresAt: map['expiresAt'] is DateTime
          ? map['expiresAt'] as DateTime
          : DateTime.tryParse(map['expiresAt']?.toString() ?? ''),
      claims: map['claims'] is Map
          ? Map<String, dynamic>.from(map['claims'] as Map)
          : <String, dynamic>{},
      authProviderUsed: map['authProviderUsed']?.toString() ?? 'none',
      deviceId: map['deviceId']?.toString(),
    );
  }
  return null;
}

List<String> _claimStrings(dynamic value) {
  if (value == null) return const <String>[];
  if (value is Iterable) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return <String>[value.toString()];
}

@immutable
class QLSliceExecutionContext {
  final String namespace;
  final String sliceName;
  final String? schema;
  final String? dataSource;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> sliceDefinition;
  final QLStoreSlice slice;

  const QLSliceExecutionContext({
    required this.namespace,
    required this.sliceName,
    required this.schema,
    required this.dataSource,
    required this.metadata,
    required this.sliceDefinition,
    required this.slice,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'namespace': namespace,
        'sliceName': sliceName,
        'schema': schema,
        'dataSource': dataSource,
        'metadata': metadata,
        'definition': sliceDefinition,
        'stateKeys': slice.state.keys.toList(growable: false),
        'computedKeys': slice.computed.keys.toList(growable: false),
        'mutationKeys': slice.mutations.keys.toList(growable: false),
        'queryKeys': slice.queries.keys.toList(growable: false),
        'pipelineKeys': slice.pipelines.keys.toList(growable: false),
      };
}

typedef QLSliceStrategyFn = FutureOr<dynamic> Function(
  QLDataStore store,
  Map<String, dynamic> payload,
  QLSliceExecutionContext ctx,
);

class QLSliceStrategyRegistry {
  static final QLSliceStrategyRegistry instance = QLSliceStrategyRegistry._();
  QLSliceStrategyRegistry._() {
    _registerDefaults();
  }

  final Map<String, QLSliceStrategyFn> _strategies =
      <String, QLSliceStrategyFn>{};

  String _key(String kind, String name) => '$kind::$name';

  void register(String name, QLSliceStrategyFn fn, {String kind = 'mutation'}) {
    _strategies[_key(kind, name)] = fn;
  }

  bool has(String name, {String kind = 'mutation'}) =>
      _strategies.containsKey(_key(kind, name));

  FutureOr<dynamic> execute(
    String name,
    QLDataStore store,
    Map<String, dynamic> payload,
    QLSliceExecutionContext ctx, {
    String kind = 'mutation',
  }) {
    final fn = _strategies[_key(kind, name)];
    if (fn != null) {
      return fn(store, payload, ctx);
    }

    final dynamic localSpec = ctx.slice.strategies[name];
    if (localSpec != null) {
      final Map<String, dynamic> merged = <String, dynamic>{
        if (localSpec is Map)
          ...Map<String, dynamic>.from(localSpec.cast<String, dynamic>()),
        if (localSpec is String) 'op': localSpec,
        if (localSpec is List) 'steps': localSpec,
        ...payload,
      };
      final String localKind =
          merged['kind']?.toString() ?? merged['type']?.toString() ?? kind;
      return _builtinExecute(localKind, name, store, merged, ctx);
    }

    return _builtinExecute(kind, name, store, payload, ctx);
  }

  void _registerDefaults() {
    register('state.set', _stateSet, kind: 'mutation');
    register('state.merge', _stateMerge, kind: 'mutation');
    register('state.remove', _stateRemove, kind: 'mutation');
    register('create', _create, kind: 'mutation');
    register('update', _update, kind: 'mutation');
    register('upsert', _upsert, kind: 'mutation');
    register('delete', _delete, kind: 'mutation');
    register('push', _push, kind: 'mutation');
    register('pop', _pop, kind: 'mutation');
    register('move', _move, kind: 'mutation');
    register('reorder', _reorder, kind: 'mutation');
    register('publish', _publish, kind: 'mutation');
    register('append', _append, kind: 'mutation');
    register('prepend', _prepend, kind: 'mutation');
    register('patch', _patch, kind: 'mutation');
    register('toggle', _toggle, kind: 'mutation');
    register('increment', _increment, kind: 'mutation');
    register('decrement', _decrement, kind: 'mutation');
    register('aggregate', _aggregate, kind: 'query');

    register('get', _get, kind: 'query');
    register('read', _read, kind: 'query');
    register('query', _query, kind: 'query');
    register('subscribe', _subscribe, kind: 'query');
    register('listen', _listen, kind: 'query');
    register('snapshot', _snapshot, kind: 'query');
    register('keys', _keys, kind: 'query');
    register('resolve', _resolve, kind: 'query');

    register('refresh', _refreshPipeline, kind: 'pipeline');
    register('patch', _patchPipeline, kind: 'pipeline');

    register('identity', _identity, kind: 'transform');
    register('merge', _mergeTransform, kind: 'transform');
    register('append', _appendTransform, kind: 'transform');
    register('appendById', _appendByIdTransform, kind: 'transform');
    register('prepend', _prependTransform, kind: 'transform');
    register('first', _firstTransform, kind: 'transform');
    register('count', _countTransform, kind: 'transform');
    register('notNull', _notNullTransform, kind: 'transform');
  }

  FutureOr<dynamic> _builtinExecute(String kind, String name, QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final op = payload['op']?.toString() ??
        payload['type']?.toString() ??
        payload['strategy']?.toString() ??
        name;

    if (kind == 'mutation') {
      switch (op) {
        case 'set':
        case 'state.set':
          return _stateSet(store, payload, ctx);
        case 'merge':
        case 'state.merge':
          return _stateMerge(store, payload, ctx);
        case 'remove':
        case 'state.remove':
          return _stateRemove(store, payload, ctx);
        case 'create':
          return _create(store, payload, ctx);
        case 'update':
          return _update(store, payload, ctx);
        case 'upsert':
          return _upsert(store, payload, ctx);
        case 'delete':
          return _delete(store, payload, ctx);
        case 'push':
          return _push(store, payload, ctx);
        case 'pop':
          return _pop(store, payload, ctx);
        case 'move':
          return _move(store, payload, ctx);
        case 'reorder':
          return _reorder(store, payload, ctx);
        case 'publish':
          return _publish(store, payload, ctx);
        case 'append':
          return _append(store, payload, ctx);
        case 'prepend':
          return _prepend(store, payload, ctx);
        case 'patch':
          return _patch(store, payload, ctx);
        case 'toggle':
          return _toggle(store, payload, ctx);
        case 'increment':
          return _increment(store, payload, ctx);
        case 'decrement':
          return _decrement(store, payload, ctx);
        case 'aggregate':
          return _aggregate(store, payload, ctx);
      }
    } else if (kind == 'query') {
      switch (op) {
        case 'get':
        case 'resolve':
          return _get(store, payload, ctx);
        case 'read':
          return _read(store, payload, ctx);
        case 'query':
          return _query(store, payload, ctx);
        case 'subscribe':
          return _subscribe(store, payload, ctx);
        case 'listen':
          return _listen(store, payload, ctx);
        case 'snapshot':
          return _snapshot(store, payload, ctx);
        case 'keys':
          return _keys(store, payload, ctx);
        case 'aggregate':
          return _aggregate(store, payload, ctx);
      }
    } else if (kind == 'pipeline') {
      switch (op) {
        case 'refresh':
          return _refreshPipeline(store, payload, ctx);
        case 'patch':
          return _patchPipeline(store, payload, ctx);
      }
    } else if (kind == 'transform') {
      switch (op) {
        case 'merge':
          return _mergeTransform(store, payload, ctx);
        case 'append':
          return _appendTransform(store, payload, ctx);
        case 'appendById':
          return _appendByIdTransform(store, payload, ctx);
        case 'prepend':
          return _prependTransform(store, payload, ctx);
        case 'first':
          return _firstTransform(store, payload, ctx);
        case 'count':
          return _countTransform(store, payload, ctx);
        case 'notNull':
          return _notNullTransform(store, payload, ctx);
        case 'identity':
          return _identity(store, payload, ctx);
      }
    }

    return payload['value'] ?? payload['data'] ?? payload;
  }

  dynamic _resolveTargetValue(QLDataStore store, Map<String, dynamic> payload) {
    final path = payload['path']?.toString() ??
        payload['key']?.toString() ??
        payload['target']?.toString();
    if (path == null || path.isEmpty) return null;
    return store.get(path);
  }

  FutureOr<dynamic> _stateSet(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final value = payload.containsKey('value')
        ? payload['value']
        : payload.containsKey('data')
            ? payload['data']
            : payload['payload'];
    store.set(path, value);
    return value;
  }

  FutureOr<dynamic> _stateMerge(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    final value = payload.containsKey('value')
        ? payload['value']
        : payload.containsKey('data')
            ? payload['data']
            : payload['payload'];
    if (path == null || path.isEmpty) {
      if (value is Map) {
        store.merge(Map<String, dynamic>.from(value),
            clearMissing: payload['clearMissing'] == true);
      }
      return value;
    }
    final current = store.get(path);
    final mergeMode = payload['merge']?.toString() ?? 'mergeMap';
    final merged = _qlDeepMergeValue(current, value, merge: mergeMode);
    store.set(path, merged);
    return merged;
  }

  FutureOr<dynamic> _stateRemove(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    store.sweep(path);
    return null;
  }

  FutureOr<dynamic> _append(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path);
    final value = payload.containsKey('value')
        ? payload['value']
        : payload.containsKey('data')
            ? payload['data']
            : payload['payload'];
    final next = _qlDeepMergeValue(current, value, merge: 'append');
    store.set(path, next);
    return next;
  }

  FutureOr<dynamic> _prepend(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path);
    final value = payload.containsKey('value')
        ? payload['value']
        : payload.containsKey('data')
            ? payload['data']
            : payload['payload'];
    final next = _qlDeepMergeValue(current, value, merge: 'prepend');
    store.set(path, next);
    return next;
  }

  FutureOr<dynamic> _patch(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path);
    final patch = payload.containsKey('patch')
        ? payload['patch']
        : payload.containsKey('value')
            ? payload['value']
            : payload['payload'];
    if (current is Map && patch is Map) {
      final next = Map<String, dynamic>.from(current.cast<String, dynamic>());
      next.addAll(Map<String, dynamic>.from(patch.cast<String, dynamic>()));
      store.set(path, next);
      return next;
    }
    if (patch != null) {
      store.set(path, patch);
    }
    return patch;
  }

  FutureOr<dynamic> _toggle(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path) == true;
    final next = !current;
    store.set(path, next);
    return next;
  }

  FutureOr<dynamic> _increment(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path);
    final by = (payload['by'] ?? payload['amount'] ?? payload['step']) as num?;
    final next =
        (current is num ? current.toDouble() : 0.0) + (by?.toDouble() ?? 1.0);
    store.set(path, next);
    return next;
  }

  FutureOr<dynamic> _decrement(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path);
    final by = (payload['by'] ?? payload['amount'] ?? payload['step']) as num?;
    final next =
        (current is num ? current.toDouble() : 0.0) - (by?.toDouble() ?? 1.0);
    store.set(path, next);
    return next;
  }

  FutureOr<dynamic> _get(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    return _resolveTargetValue(store, payload);
  }

  FutureOr<dynamic> _snapshot(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    return store.snapshot;
  }

  FutureOr<dynamic> _keys(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    return store.signalKeys;
  }

  FutureOr<dynamic> _resolve(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString();
    if (path == null || path.isEmpty) return null;
    return store.get(path);
  }

  FutureOr<dynamic> _refreshPipeline(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) async {
    final pipelineId = payload['pipelineId']?.toString() ??
        payload['id']?.toString() ??
        payload['path']?.toString();
    if (pipelineId == null || pipelineId.isEmpty) return null;
    final pipeline = QLPipelineRegistry.instance.get(pipelineId);
    if (pipeline.delegate == null) return null;
    final state = payload['state'] is Map
        ? Map<String, dynamic>.from(payload['state'] as Map)
        : <String, dynamic>{};
    final data = await pipeline.delegate!.fetch(state);
    pipeline.ingest(data);
    return data;
  }

  FutureOr<dynamic> _patchPipeline(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final pipelineId = payload['pipelineId']?.toString() ??
        payload['id']?.toString() ??
        payload['path']?.toString();
    final recordId = payload['recordId']?.toString() ??
        payload['id']?.toString() ??
        payload['key']?.toString();
    final delta = payload['delta'] ?? payload['patch'] ?? payload['value'];
    if (pipelineId == null || pipelineId.isEmpty) return null;
    if (recordId == null || recordId.isEmpty) return null;
    if (delta is! Map) return null;
    QLPipelineRegistry.instance.get(pipelineId).patch(
          recordId,
          Map<String, dynamic>.from(delta.cast<String, dynamic>()),
        );
    return delta;
  }

  FutureOr<dynamic> _identity(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    return payload['value'] ?? payload['data'] ?? payload['payload'];
  }

  FutureOr<dynamic> _mergeTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final current = payload['current'];
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    return _qlDeepMergeValue(current, incoming, merge: 'mergeMap');
  }

  FutureOr<dynamic> _appendTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final current = payload['current'];
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    return _qlDeepMergeValue(current, incoming, merge: 'append');
  }

  FutureOr<dynamic> _appendByIdTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final current = payload['current'];
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    return _qlDeepMergeValue(current, incoming, merge: 'appendById');
  }

  FutureOr<dynamic> _prependTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final current = payload['current'];
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    return _qlDeepMergeValue(current, incoming, merge: 'prepend');
  }

  FutureOr<dynamic> _firstTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    if (incoming is List) return incoming.isEmpty ? null : incoming.first;
    return incoming;
  }

  FutureOr<dynamic> _countTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    if (incoming is List) return incoming.length;
    if (incoming is Map) return incoming.length;
    return incoming == null ? 0 : 1;
  }

  FutureOr<dynamic> _notNullTransform(QLDataStore store,
      Map<String, dynamic> payload, QLSliceExecutionContext ctx) {
    final incoming = payload['value'] ?? payload['data'] ?? payload['payload'];
    return incoming != null;
  }
}

String? _resolveSourceName(
    QLSliceExecutionContext ctx, Map<String, dynamic> payload) {
  final raw = payload['source'] ??
      payload['dataSource'] ??
      payload['bind'] ??
      ctx.dataSource;
  final name = raw?.toString().trim() ?? '';
  return name.isEmpty ? null : name;
}

String? _resolvePath(Map<String, dynamic> payload) {
  final path = payload['path'] ??
      payload['key'] ??
      payload['target'] ??
      payload['statePath'] ??
      payload['field'];
  final value = path?.toString().trim() ?? '';
  return value.isEmpty ? null : value;
}

FutureOr<dynamic> _dispatchDataOperation(
  String operation,
  QLDataStore store,
  Map<String, dynamic> payload,
  QLSliceExecutionContext ctx, {
  required bool query,
}) {
  final sourceName = _resolveSourceName(ctx, payload);
  if (sourceName != null && QLDataSourceRegistry.instance.exists(sourceName)) {
    return QLDataSourceRegistry.instance.execute(
      sourceName,
      operation,
      payload,
      ctx: ctx,
    );
  }

  return _dispatchLocalOperation(
    operation,
    store,
    payload,
    ctx,
    query: query,
  );
}

dynamic _dispatchLocalOperation(
  String operation,
  QLDataStore store,
  Map<String, dynamic> payload,
  QLSliceExecutionContext ctx, {
  required bool query,
}) {
  final path = _resolvePath(payload) ?? ctx.namespace;
  final value = payload['value'] ?? payload['data'] ?? payload['payload'];

  switch (operation) {
    case 'read':
    case 'get':
      return path == null ? store.getAll() : store.read(path);
    case 'query':
    case 'readMany':
      return store.query(path,
          where: payload['where'] is Map
              ? Map<String, dynamic>.from(payload['where'] as Map)
              : null,
          select: payload['select'] is Iterable
              ? List<String>.from(
                  (payload['select'] as Iterable).map((e) => e.toString()))
              : null);
    case 'create':
      if (path != null) {
        return store.create(path, value);
      }
      return value;
    case 'update':
    case 'patch':
      if (path != null) {
        return store.update(path, value);
      }
      return value;
    case 'upsert':
      if (path != null) {
        return store.upsert(path, value);
      }
      return value;
    case 'delete':
    case 'remove':
      if (path != null) {
        return store.delete(path);
      }
      return null;
    case 'push':
    case 'append':
      if (path != null) {
        return store.push(path, value);
      }
      return value;
    case 'pop':
      if (path != null) {
        return store.pop(path,
            index: (payload['index'] as num?)?.toInt() ?? -1);
      }
      return null;
    case 'move':
      if (path != null) {
        return store.move(
          path,
          (payload['from'] as num?)?.toInt() ?? 0,
          (payload['to'] as num?)?.toInt() ?? 0,
        );
      }
      return null;
    case 'reorder':
      if (path != null) {
        final order = (payload['order'] as List? ?? const [])
            .map((e) => e is num ? e.toInt() : int.tryParse('$e') ?? 0)
            .toList(growable: false);
        return store.reorder(path, order);
      }
      return null;
    case 'increment':
      if (path != null) {
        return store.increment(path, (payload['amount'] as num?) ?? 1);
      }
      return value;
    case 'decrement':
      if (path != null) {
        return store.decrement(path, (payload['amount'] as num?) ?? 1);
      }
      return value;
    case 'aggregate':
      if (path != null) {
        return store.aggregate(
          path,
          op: payload['aggregate']?.toString() ??
              payload['op']?.toString() ??
              'count',
          field: payload['field']?.toString(),
        );
      }
      return null;
    case 'publish':
      if (path != null) {
        return store.publish(path, value);
      }
      return value;
    case 'subscribe':
    case 'listen':
      if (path != null) {
        return store.subscribe(path);
      }
      return Stream<dynamic>.value(null);
    default:
      return value ?? store.read(path ?? '');
  }
}

FutureOr<dynamic> _create(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('create', store, payload, ctx, query: false);
}

FutureOr<dynamic> _update(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('update', store, payload, ctx, query: false);
}

FutureOr<dynamic> _push(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('push', store, payload, ctx, query: false);
}

FutureOr<dynamic> _read(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('read', store, payload, ctx, query: true);
}

FutureOr<dynamic> _query(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('query', store, payload, ctx, query: true);
}

FutureOr<dynamic> _subscribe(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('subscribe', store, payload, ctx, query: true);
}

FutureOr<dynamic> _listen(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('listen', store, payload, ctx, query: true);
}

FutureOr<dynamic> _publish(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('publish', store, payload, ctx, query: false);
}

FutureOr<dynamic> _aggregate(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('aggregate', store, payload, ctx, query: true);
}

FutureOr<dynamic> _move(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('move', store, payload, ctx, query: false);
}

FutureOr<dynamic> _reorder(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('reorder', store, payload, ctx, query: false);
}

FutureOr<dynamic> _upsert(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('upsert', store, payload, ctx, query: false);
}

FutureOr<dynamic> _delete(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('delete', store, payload, ctx, query: false);
}

FutureOr<dynamic> _pop(QLDataStore store, Map<String, dynamic> payload,
    QLSliceExecutionContext ctx) {
  return _dispatchDataOperation('pop', store, payload, ctx, query: false);
}

class QLDataSourceHandle {
  final String name;
  Map<String, dynamic> config;
  final QLAsyncSignal<dynamic> signal;
  StreamSubscription<Map<String, dynamic>>? _subscription;
  final List<Map<String, dynamic>> _pendingWrites = <Map<String, dynamic>>[];

  QLDataSourceHandle({required this.name, required this.config})
      : signal = QLAsyncRegistry.instance.get<dynamic>('dataSources.$name');

  String? get schemaName =>
      config['schema']?.toString() ?? config['schemaName']?.toString();

  bool get smartSelectEnabled => config['smartSelect'] != false;
  bool get localFirstEnabled =>
      config['localFirst'] == true || config['offlineQueue'] == true;

  QLSchemaBlueprint? get _schemaBlueprint {
    final name = schemaName;
    if (name == null || name.isEmpty) return null;
    return QLSchemaRegistry.instance.getSchema(name);
  }

  bool get isStreaming =>
      config['stream'] is Map ||
      config['subscribe'] == true ||
      config['realtime'] == true ||
      _matchesSourceType(config['type']) ||
      config['type']?.toString() == 'stream' ||
      config['direction']?.toString() != 'outboundOnly';

  Future<dynamic> executeOperation(
    String operation, {
    Map<String, dynamic>? payload,
  }) async {
    final args = payload == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(payload);

    switch (operation) {
      case 'read':
      case 'query':
      case 'readOne':
      case 'readMany':
      case 'subscribe':
      case 'listen':
        return refresh(overrides: args);
      case 'publish':
      case 'push':
        return push(args['payload'] ?? args['value'] ?? args);
      default:
        final request = _buildRequest(overrides: args);
        request['action'] = request['action']?.toString().isNotEmpty == true
            ? request['action']
            : operation;
        request['args']['op'] = operation;
        return await Quantum.runAction(request);
    }
  }

  void _enterLoading() {
    signal.loading.setSilent(true);
    signal.error.setSilent(null);
    signal.loading.forceNotify();
    signal.error.forceNotify();
  }

  void _enterData(dynamic value) {
    signal.data.setSilent(value);
    signal.loading.setSilent(false);
    signal.error.setSilent(null);
    signal.data.forceNotify();
    signal.loading.forceNotify();
    signal.error.forceNotify();
  }

  void _enterError(Object error, StackTrace? stackTrace) {
    signal.error.setSilent(error);
    signal.loading.setSilent(false);
    signal.error.forceNotify();
    signal.loading.forceNotify();
  }

  Future<dynamic> refresh({Map<String, dynamic>? overrides}) async {
    await _subscription?.cancel();
    _subscription = null;

    final request = _buildRequest(overrides: overrides);
    final args = request['args'] is Map
        ? Map<String, dynamic>.from(request['args'] as Map)
        : <String, dynamic>{};
    request['args'] = args;

    final smartSelect = _smartSelectForRequest(request);
    if (smartSelect.isNotEmpty) {
      args['select'] = smartSelect;
      args['fields'] = smartSelect;
    }

    _enterLoading();

    if (_shouldStreamRequest(request)) {
      final completer = Completer<dynamic>();
      var firstEvent = true;

      _subscription = Quantum.runStreamAction(request).listen(
        (event) {
          final value = _mergeIncomingData(_normalizeStreamEvent(event));
          _enterData(value);
          if (firstEvent) {
            firstEvent = false;
            if (!completer.isCompleted) completer.complete(value);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _enterError(error, stackTrace);
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (signal.loading.value) {
            signal.loading.setSilent(false);
            signal.loading.forceNotify();
          }
          unawaited(_flushQueuedWrites());
        },
        cancelOnError: false,
      );
      return completer.future;
    }

    try {
      final result = await Quantum.runAction(request);
      if (result['success'] == true) {
        final data = _mergeIncomingData(result['data']);
        _enterData(data);
        unawaited(_flushQueuedWrites());
        return data;
      }

      final error = result['error'] ?? 'Unknown datasource error';
      final failure = StateError(error.toString());
      _enterError(failure, StackTrace.current);
      if (localFirstEnabled) {
        final optimistic = _optimisticResult(
          request['action']?.toString() ?? 'read',
          <String, dynamic>{
            'data': args['data'],
            'value': args['value'],
            'payload': args['payload'],
            'amount': args['amount'],
            'index': args['index'],
            'order': args['order'],
          },
        );
        if (optimistic != null) {
          signal.data.setSilent(optimistic);
          signal.data.forceNotify();
          return optimistic;
        }
      }
      return null;
    } catch (error, stackTrace) {
      if (localFirstEnabled) {
        _queueWrite(request);
        final optimistic = _optimisticResult(
          request['action']?.toString() ?? 'read',
          <String, dynamic>{
            'data': args['data'],
            'value': args['value'],
            'payload': args['payload'],
            'amount': args['amount'],
            'index': args['index'],
            'order': args['order'],
          },
        );
        if (optimistic != null) {
          signal.data.setSilent(optimistic);
          signal.data.forceNotify();
          return optimistic;
        }
      }
      _enterError(
          error, stackTrace is StackTrace ? stackTrace : StackTrace.current);
      rethrow;
    }
  }

  Future<void> push(dynamic payload) async {
    final outbound =
        Map<String, dynamic>.from(config['outbound'] as Map? ?? const {});
    final request = <String, dynamic>{
      'domain': outbound['domain'] ??
          config['pushDomain'] ??
          config['domain'] ??
          'realtime',
      'action': outbound['action'] ??
          config['pushAction'] ??
          config['emitAction'] ??
          'emit',
      'resource': outbound['resource'] ?? config['resource'],
      'args': <String, dynamic>{
        ..._qlMapOf(outbound['args']),
        ..._qlMapOf(config['pushArgs']),
        'payload': payload,
      },
    };
    await Quantum.runAction(request);
  }

  void registerBindingRequirements(
      {Iterable<String>? select, bool? smartSelect}) {
    if (smartSelect != null) {
      config['smartSelect'] = smartSelect;
    }
    final normalized = _normalizeSelectList(select);
    if (normalized.isEmpty) return;

    final existing = _normalizeSelectList(
      config['select'] ?? config['fields'] ?? config['projection'],
    );

    final merged = <String>{
      ...existing,
      ...normalized,
    }.toList(growable: false);

    config['select'] = merged;
    config['fields'] = merged;
    config['projection'] = merged;
  }

  List<String> _normalizeSelectList(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    if (raw is Map) {
      return raw.keys.map((e) => e.toString()).toList(growable: false);
    }
    if (raw is Iterable) {
      final out = <String>[];
      for (final item in raw) {
        final value = item?.toString().trim() ?? '';
        if (value.isNotEmpty) out.add(value);
      }
      return out.toSet().toList(growable: false);
    }
    final value = raw.toString().trim();
    return value.isEmpty ? const <String>[] : <String>[value];
  }

  Map<String, dynamic>? _firstMapLike(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value.cast<String, dynamic>());
    }
    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          return Map<String, dynamic>.from(item.cast<String, dynamic>());
        }
      }
    }
    return null;
  }

  List<String> _smartSelectForRequest(Map<String, dynamic> request) {
    if (!smartSelectEnabled) return const <String>[];

    final select = _normalizeSelectList(
      request['args'] is Map
          ? (request['args'] as Map)['select'] ??
              (request['args'] as Map)['fields']
          : null,
    );
    final configured = _normalizeSelectList(
      config['select'] ?? config['fields'] ?? config['projection'],
    );
    final schema = _schemaBlueprint;
    final current = signal.data.value;

    final desired = select.isNotEmpty
        ? select
        : (configured.isNotEmpty
            ? configured
            : (schema?.fieldPaths() ??
                _normalizeSelectList(_firstMapLike(current)?.keys)));

    if (desired.isEmpty) return const <String>[];

    if (schema != null) {
      final cachedRecord = _firstMapLike(current);
      return schema.missingSelection(
        cachedRecord: cachedRecord,
        select: desired,
      );
    }

    final known = <String>{};
    final cachedRecord = _firstMapLike(current);
    if (cachedRecord != null) {
      known.addAll(cachedRecord.keys.map((e) => e.toString()));
    }
    return desired.where((field) => !known.contains(field)).toList(
          growable: false,
        );
  }

  dynamic _mergeIncomingData(dynamic incoming) {
    final current = signal.data.value;
    if (incoming == null) return incoming;

    if (current is Map && incoming is Map) {
      final schema = _schemaBlueprint;
      if (schema != null) {
        return _qlMergeProjectedMaps(
          Map<String, dynamic>.from(current.cast<String, dynamic>()),
          Map<String, dynamic>.from(incoming.cast<String, dynamic>()),
        );
      }
      return _qlDeepMergeValue(current, incoming, merge: 'mergeMap');
    }

    if (current is List && incoming is List) {
      return _qlMergeListRecords(current, incoming);
    }

    if (incoming is Map && current is List) {
      return _qlMergeListRecords(current, <dynamic>[incoming]);
    }

    return incoming;
  }

  dynamic _optimisticResult(String operation, Map<String, dynamic> payload) {
    final current = signal.data.value;
    final data = payload['data'] ?? payload['value'] ?? payload['payload'];

    switch (operation) {
      case 'create':
      case 'update':
      case 'upsert':
      case 'patch':
      case 'set':
        if (current is Map && data is Map) {
          return _qlDeepMergeValue(current, data, merge: 'mergeMap');
        }
        return data ?? current;
      case 'delete':
        return null;
      case 'push':
      case 'append':
        if (current is List) {
          final next = List<dynamic>.from(current);
          if (data is List) {
            next.addAll(data);
          } else {
            next.add(data);
          }
          return next;
        }
        return data is List
            ? data
            : <dynamic>[if (current != null) current, data];
      case 'pop':
        if (current is List && current.isNotEmpty) {
          final next = List<dynamic>.from(current);
          final index = (payload['index'] as num?)?.toInt() ??
              (payload['at'] as num?)?.toInt() ??
              next.length - 1;
          if (index >= 0 && index < next.length) {
            next.removeAt(index);
          } else {
            next.removeLast();
          }
          return next;
        }
        return current;
      case 'move':
      case 'reorder':
        if (current is List) {
          final order = payload['order'];
          if (order is List) {
            final next = <dynamic>[];
            for (final item in order) {
              final idx = item is num ? item.toInt() : int.tryParse('$item');
              if (idx != null && idx >= 0 && idx < current.length) {
                next.add(current[idx]);
              }
            }
            return next;
          }
        }
        return current;
      case 'increment':
      case 'decrement':
        final amount = (payload['amount'] as num?) ?? 1;
        if (current is num) {
          return operation == 'increment' ? current + amount : current - amount;
        }
        return data ?? current;
      default:
        return data ?? current;
    }
  }

  Future<void> _flushQueuedWrites() async {
    if (_pendingWrites.isEmpty) return;
    final queued = List<Map<String, dynamic>>.from(_pendingWrites);
    _pendingWrites.clear();

    for (final request in queued) {
      try {
        await Quantum.runAction(request);
      } catch (_) {
        _pendingWrites.add(request);
      }
    }
  }

  void _queueWrite(Map<String, dynamic> request) {
    if (!localFirstEnabled) return;
    _pendingWrites.add(Map<String, dynamic>.from(request));
  }

  Map<String, dynamic> _buildRequest({Map<String, dynamic>? overrides}) {
    final request = <String, dynamic>{
      if (config['domain'] != null) 'domain': config['domain'],
      if (config['action'] != null) 'action': config['action'],
      if (config['resource'] != null) 'resource': config['resource'],
      if (config['slug'] != null) 'slug': config['slug'],
      if (config['collection'] != null) 'resource': config['collection'],
      'args': _qlMapOf(config['args']),
    };

    if (config['query'] is Map) {
      request['args'] = {
        ..._qlMapOf(request['args']),
        'query': _qlMapOf(config['query']),
      };
    }
    if (config['body'] is Map) {
      request['args'] = {
        ..._qlMapOf(request['args']),
        'data': _qlMapOf(config['body']),
      };
    }
    if (config['params'] is Map) {
      request['args'] = {
        ..._qlMapOf(request['args']),
        ..._qlMapOf(config['params']),
      };
    }
    if (config['payload'] is Map) {
      request['args'] = {
        ..._qlMapOf(request['args']),
        ..._qlMapOf(config['payload']),
      };
    }

    if (overrides != null) {
      request['args'] = {
        ..._qlMapOf(request['args']),
        ...overrides,
      };
    }

    if (!request.containsKey('domain')) {
      final type = config['type']?.toString() ?? '';
      if (_matchesSourceType(type)) {
        request['domain'] = 'media';
        request['action'] =
            request['action'] ?? config['mediaAction'] ?? 'adaptive_stream';
      } else if (type == 'realtime' ||
          type == 'socket' ||
          config['realtime'] == true ||
          config['subscribe'] == true ||
          config['stream'] is Map) {
        request['domain'] = 'realtime';
        request['action'] =
            request['action'] ?? config['streamAction'] ?? 'subscribe';
      } else {
        request['domain'] = config['domain'] ?? 'api_collection';
        request['action'] =
            request['action'] ?? config['fetchAction'] ?? 'readMany';
      }
    }

    request['args'] = _qlMapOf(request['args']);
    if (config['policy'] is Map) {
      request['args']['policy'] = _qlMapOf(config['policy']);
    }
    return request;
  }

  bool _shouldStreamRequest(Map<String, dynamic> request) {
    if (config['stream'] is Map) return true;
    if (config['subscribe'] == true || config['realtime'] == true) return true;
    final domain = request['domain']?.toString() ?? '';
    final action = request['action']?.toString() ?? '';
    return domain == 'realtime' ||
        domain == 'media' ||
        domain == 'asset' ||
        domain == 'file' ||
        domain == 'task' ||
        action == 'subscribe' ||
        action == 'firehose' ||
        action == 'adaptive_stream';
  }

  bool _matchesSourceType(dynamic type) {
    final normalized = type?.toString().trim().toLowerCase() ?? '';
    return normalized == 'media' ||
        normalized == 'asset' ||
        normalized == 'file' ||
        normalized == 'upload' ||
        normalized == 'streamable_media';
  }

  dynamic _normalizeStreamEvent(Map<String, dynamic> event) {
    if (event.containsKey('data')) return event['data'];
    if (event.containsKey('bytes')) return event['bytes'];
    if (event.containsKey('event') && event.containsKey('payload')) {
      return event['payload'];
    }
    return event;
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

class QLDataSourceRegistry {
  static final QLDataSourceRegistry instance = QLDataSourceRegistry._();
  QLDataSourceRegistry._();

  final Map<String, QLDataSourceHandle> _sources =
      <String, QLDataSourceHandle>{};
  final Map<String, List<VoidCallback>> _namespaceTeardowns =
      <String, List<VoidCallback>>{};

  QLDataSourceHandle register(String name, Map<String, dynamic> config) {
    final mutableConfig = Map<String, dynamic>.from(config);
    final existing = _sources[name];
    if (existing != null) {
      existing.config = mutableConfig;
      return existing;
    }
    final handle = QLDataSourceHandle(name: name, config: mutableConfig);
    _sources[name] = handle;
    if (config['seed'] != null) {
      handle.signal.data.setSilent(config['seed']);
      handle.signal.data.forceNotify();
    } else if (config['initial'] != null) {
      handle.signal.data.setSilent(config['initial']);
      handle.signal.data.forceNotify();
    }
    if (config['autoStart'] == true ||
        config['subscribe'] == true ||
        config['realtime'] == true ||
        config['lifecycle'] == 'onMount') {
      unawaited(handle.refresh());
    }
    return handle;
  }

  bool exists(String name) => _sources.containsKey(name);
  QLDataSourceHandle? get(String name) => _sources[name];

  Future<dynamic> refresh(String name,
      {Map<String, dynamic>? overrides}) async {
    final handle = _sources[name];
    if (handle == null) return null;
    return await handle.refresh(overrides: overrides);
  }

  Future<void> push(String name, dynamic payload) async {
    final handle = _sources[name];
    if (handle == null) return;
    await handle.push(payload);
  }

  VoidCallback attachStateBinding({
    required String namespace,
    required QLDataStore store,
    required String sourceName,
    required String statePath,
    String? sourcePath,
    String merge = 'replace',
    dynamic defaultValue,
    String? transform,
    bool subscribe = true,
    Iterable<String>? select,
    bool smartSelect = true,
    Map<String, dynamic>? metadata,
    QLSliceExecutionContext? ctx,
  }) {
    final handle = _sources[sourceName];
    if (handle == null) {
      if (defaultValue != null) store.set(statePath, defaultValue);
      return () {};
    }

    handle.registerBindingRequirements(
        select: select, smartSelect: smartSelect);

    final effectiveCtx = ctx ??
        QLSliceExecutionContext(
          namespace: namespace,
          sliceName: namespace.split('.').last,
          schema: null,
          dataSource: sourceName,
          metadata: metadata ?? const <String, dynamic>{},
          sliceDefinition: const <String, dynamic>{},
          slice: QLStoreSlice(namespace: namespace),
        );

    bool active = true;

    dynamic applyTransform(dynamic value) {
      if (!active || transform == null || transform.isEmpty) return value;
      final transformed = QLSliceStrategyRegistry.instance.execute(
        transform,
        store,
        <String, dynamic>{
          'value': value,
          'current': store.get(statePath),
          'path': statePath,
          'source': sourceName,
          'sourcePath': sourcePath,
          'metadata': metadata ?? const <String, dynamic>{},
        },
        effectiveCtx,
        kind: 'transform',
      );
      if (transformed is Future) {
        // Avoid async gap inside listener; fall back to raw value and let a
        // future refresh cycle provide transformed output.
        return value;
      }
      return transformed;
    }

    void sync() {
      if (!active) return;
      final raw = handle.signal.data.value;
      dynamic next = sourcePath == null || sourcePath.isEmpty
          ? raw
          : _qlReadPathValue(raw, sourcePath);
      next = applyTransform(next);
      if (!active) return;
      final current = store.get(statePath);
      final merged = _qlDeepMergeValue(current, next, merge: merge);
      if (current != merged) {
        store.set(statePath, merged);
      }
    }

    void onData() {
      if (!active) return;
      sync();
    }

    void onLoading() {
      if (!active || !subscribe) return;
      if (defaultValue != null && store.get(statePath) == null) {
        store.set(statePath, defaultValue);
      }
    }

    handle.signal.data.addListener(onData);
    handle.signal.loading.addListener(onLoading);

    sync();

    final cancel = () {
      if (!active) return;
      active = false;
      handle.signal.data.removeListener(onData);
      handle.signal.loading.removeListener(onLoading);
    };
    _namespaceTeardowns
        .putIfAbsent(namespace, () => <VoidCallback>[])
        .add(cancel);
    return cancel;
  }

  Future<dynamic> execute(
    String name,
    String operation,
    Map<String, dynamic> payload, {
    QLSliceExecutionContext? ctx,
  }) async {
    final handle = _sources[name];
    if (handle == null) return null;
    return await handle.executeOperation(operation, payload: payload);
  }

  void detachNamespace(String namespace) {
    final teardowns = _namespaceTeardowns.remove(namespace);
    if (teardowns != null) {
      for (final cancel in teardowns) {
        try {
          cancel();
        } catch (_) {}
      }
    }
  }

  void clear() {
    detachNamespace('*');
    for (final handle in _sources.values) {
      handle.dispose();
    }
    _sources.clear();
    _namespaceTeardowns.clear();
  }

  Map<String, dynamic> snapshot() => <String, dynamic>{
        'count': _sources.length,
        'sources': _sources.entries
            .map((e) => <String, dynamic>{
                  'name': e.key,
                  'type': e.value.config['type'],
                  'domain': e.value.config['domain'],
                  'action': e.value.config['action'],
                  'resource': e.value.config['resource'],
                  'streaming': e.value.isStreaming,
                  'status': e.value.signal.snapshot.status.name,
                })
            .toList(growable: false),
      };
}

class QLStoreSlice {
  final String namespace;
  final String? schema;
  final String? dataSource;
  final Map<String, dynamic> state;
  final Map<String, dynamic> computed;
  final Map<String, dynamic> mutations;
  final Map<String, dynamic> queries;
  final Map<String, dynamic> pipelines;
  final Map<String, dynamic> strategies;
  final Map<String, dynamic> metadata;
  final Map<String, QLSliceFieldPolicy> fieldPolicies;
  final Map<String, QLSliceResourceRef> resources;
  final QLSliceProtection protection;
  final Map<String, dynamic> runtime;

  const QLStoreSlice({
    required this.namespace,
    this.schema,
    this.dataSource,
    this.state = const {},
    this.computed = const {},
    this.mutations = const {},
    this.queries = const {},
    this.pipelines = const {},
    this.strategies = const {},
    this.metadata = const {},
    this.fieldPolicies = const {},
    this.resources = const {},
    this.protection = const QLSliceProtection(),
    this.runtime = const {},
  });

  factory QLStoreSlice.fromMap(
    String namespace,
    Map<String, dynamic> raw,
  ) {
    Map<String, dynamic> _map(dynamic value) => value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};

    Map<String, QLSliceFieldPolicy> _fieldPolicies(dynamic value) {
      if (value is! Map) return const <String, QLSliceFieldPolicy>{};
      return value.map(
        (key, val) => MapEntry(
          key.toString(),
          QLSliceFieldPolicy.from(val, path: key.toString()),
        ),
      );
    }

    Map<String, QLSliceResourceRef> _resources(dynamic value) {
      if (value is! Map) return const <String, QLSliceResourceRef>{};
      return value.map(
        (key, val) => MapEntry(
          key.toString(),
          QLSliceResourceRef.from(val, fallbackId: key.toString()),
        ),
      );
    }

    final runtime = <String, dynamic>{
      ..._map(raw['runtime']),
      ..._map(raw['slice']),
      ..._map(raw['behavior']),
      ..._map(raw['options']),
    };

    return QLStoreSlice(
      namespace: namespace,
      schema: raw['schema']?.toString(),
      dataSource: raw['dataSource']?.toString(),
      state: _map(raw['state']),
      computed: _map(raw['computed']),
      mutations: _map(raw['mutations']),
      queries: _map(raw['queries']),
      pipelines: _map(raw['pipelines']),
      strategies: _map(raw['strategies']),
      metadata: _map(raw['metadata']),
      fieldPolicies: <String, QLSliceFieldPolicy>{
        ..._fieldPolicies(raw['fieldPolicies']),
        ..._fieldPolicies(raw['statePolicy']),
        ..._fieldPolicies(raw['fields']),
      },
      resources: <String, QLSliceResourceRef>{
        ..._resources(raw['resources']),
        ..._resources(raw['assets']),
        ..._resources(raw['media']),
        ..._resources(raw['files']),
      },
      protection: QLSliceProtection.from(
        raw['protection'] ?? raw['access'] ?? raw['security'],
      ),
      runtime: runtime,
    );
  }

  bool get immutable =>
      runtime['immutable'] == true || runtime['frozen'] == true;
  bool get reactive => runtime['reactive'] != false;
  bool get lazy => runtime['lazy'] == true || runtime['defer'] == true;
  bool get staticOnly =>
      runtime['static'] == true || runtime['mode'] == 'static';

  QLSliceFieldPolicy policyFor(String path) {
    return fieldPolicies[path] ??
        fieldPolicies[path.replaceAll(RegExp(r'^\$?state\.'), '')] ??
        QLSliceFieldPolicy(
            path: path, reactive: reactive, immutable: immutable);
  }

  QLSliceResourceRef? resource(String id) => resources[id];

  FutureOr<dynamic> resolveResource(
    String id,
    QLSliceExecutionContext ctx, {
    bool cache = true,
  }) {
    final ref = resources[id];
    if (ref == null) return null;
    return QLSliceResourceRegistry.instance.resolve(ref, ctx, cache: cache);
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'namespace': namespace,
        'schema': schema,
        'dataSource': dataSource,
        'state': state,
        'computed': computed,
        'mutations': mutations,
        'queries': queries,
        'pipelines': pipelines,
        'strategies': strategies,
        'metadata': metadata,
      };

  QLStoreSlice merge(QLStoreSlice other) => QLStoreSlice(
        namespace: namespace,
        schema: other.schema ?? schema,
        dataSource: other.dataSource ?? dataSource,
        state: {...state, ...other.state},
        computed: {...computed, ...other.computed},
        mutations: {...mutations, ...other.mutations},
        queries: {...queries, ...other.queries},
        pipelines: {...pipelines, ...other.pipelines},
        strategies: {...strategies, ...other.strategies},
        metadata: {...metadata, ...other.metadata},
      );
}

class QLSliceRegistry {
  static final QLSliceRegistry instance = QLSliceRegistry._();
  QLSliceRegistry._();

  final Map<String, QLStoreSlice> _mounted = <String, QLStoreSlice>{};

  /// Wire this up during VM initialization if you want slice actions to be
  /// globally addressable.
  static void Function(String actionName, QLActionPlugin plugin)?
      actionRegistrar;

  void mount(QLStoreSlice slice) {
    final existing = _mounted[slice.namespace];
    if (existing != null) {
      unmount(slice.namespace);
    }

    _mounted[slice.namespace] = slice;
    final store = QLStoreRegistry.instance.get(slice.namespace);
    final sliceName = slice.namespace.split('.').last;
    final executionCtx = QLSliceExecutionContext(
      namespace: slice.namespace,
      sliceName: sliceName,
      schema: slice.schema,
      dataSource: slice.dataSource,
      metadata: slice.metadata,
      sliceDefinition: slice.toMap(),
      slice: slice,
    );

    store.transaction(() {
      slice.state.forEach((key, value) {
        if (value is Map && _qlHasBindingSpec(value.cast<String, dynamic>())) {
          final binding =
              Map<String, dynamic>.from(value.cast<String, dynamic>());
          final String mode = binding['mode']?.toString().trim() ?? '';
          final defaultValue = binding.containsKey('default')
              ? binding['default']
              : binding.containsKey('initial')
                  ? binding['initial']
                  : binding.containsKey('value')
                      ? binding['value']
                      : null;
          if (defaultValue != null) {
            store.set(key, defaultValue);
          }

          final bool hasExplicitRemoteBinding = binding.containsKey('source') ||
              binding.containsKey('dataSource') ||
              binding.containsKey('from') ||
              binding.containsKey('sourcePath') ||
              binding.containsKey('path') ||
              mode == 'remote' ||
              mode == 'hybrid' ||
              mode == 'stream' ||
              mode == 'realtime';

          if (!hasExplicitRemoteBinding || mode == 'local') {
            return;
          }

          final String? rawSource = (binding['source'] ??
                  binding['dataSource'] ??
                  slice.dataSource ??
                  binding['from'])
              ?.toString();
          if (rawSource == null || rawSource.isEmpty) {
            return;
          }

          final String bindingPath = binding['from']?.toString() ??
              binding['sourcePath']?.toString() ??
              binding['path']?.toString() ??
              '';

          final parsedSource = rawSource.contains('.') &&
                  QLDataSourceRegistry.instance
                      .exists(rawSource.split('.').first)
              ? rawSource.split('.').first
              : rawSource;
          final parsedPath = bindingPath.isEmpty
              ? null
              : (bindingPath.startsWith('dataSource.')
                  ? bindingPath.substring('dataSource.'.length)
                  : (parsedSource != rawSource &&
                          bindingPath.startsWith('$parsedSource.')
                      ? bindingPath.substring(parsedSource.length + 1)
                      : bindingPath));

          QLDataSourceRegistry.instance.attachStateBinding(
            namespace: slice.namespace,
            store: store,
            sourceName: parsedSource,
            statePath: key,
            sourcePath: parsedPath,
            merge: binding['merge']?.toString() ??
                (mode == 'hybrid' ? 'mergeMap' : 'replace'),
            defaultValue: defaultValue,
            transform: binding['transform']?.toString(),
            subscribe: binding['subscribe'] != false,
            select: binding['select'] is Iterable
                ? List<String>.from(
                    (binding['select'] as Iterable).map((e) => e.toString()),
                  )
                : (binding['fields'] is Iterable
                    ? List<String>.from(
                        (binding['fields'] as Iterable)
                            .map((e) => e.toString()),
                      )
                    : const <String>[]),
            smartSelect: binding['smartSelect'] != false,
            metadata: binding['metadata'] is Map
                ? Map<String, dynamic>.from(binding['metadata'] as Map)
                : const <String, dynamic>{},
            ctx: executionCtx,
          );
          return;
        }
        store.set(key, value);
      });
    });

    slice.computed.forEach((key, spec) {
      final parsed = _parseComputedSpec(key.toString(), spec, slice, store,
          ctx: executionCtx);
      if (parsed != null) {
        store.registerComputed(key.toString(), parsed.deps, parsed.compute);
      }
    });

    if (actionRegistrar != null) {
      slice.mutations.forEach((name, spec) {
        actionRegistrar!(
          '${slice.namespace}.$name',
          _SliceMutationPlugin(
            store,
            executionCtx,
            name.toString(),
            spec,
            slice,
          ),
        );
      });

      slice.queries.forEach((name, spec) {
        actionRegistrar!(
          '${slice.namespace}.$name',
          _SliceQueryPlugin(
            store,
            executionCtx,
            name.toString(),
            spec,
            slice,
          ),
        );
      });
    } else {
      debugPrint(
        'QLSliceRegistry: actionRegistrar is not set. '
        'Slice [${slice.namespace}] mounted without global actions.',
      );
    }
  }

  void unmount(String namespace) {
    final slice = _mounted.remove(namespace);
    if (slice == null) return;
    QLDataSourceRegistry.instance.detachNamespace(namespace);
    for (final id
        in QLPipelineRegistry.instance.ids().toList(growable: false)) {
      if (id.startsWith('$namespace.')) {
        QLPipelineRegistry.instance.destroy(id);
      }
    }
    QLStoreRegistry.instance.get(namespace).sweep('');
  }

  void clear() {
    final namespaces = _mounted.keys.toList(growable: false);
    for (final ns in namespaces) {
      unmount(ns);
    }
  }

  /// Export a snapshot of mounted slices and their declared contract.
  Map<String, dynamic> snapshot() => <String, dynamic>{
        'count': _mounted.length,
        'namespaces': _mounted.entries
            .map((e) => <String, dynamic>{
                  'namespace': e.key,
                  'schema': e.value.schema,
                  'dataSource': e.value.dataSource,
                  'stateKeys': e.value.state.keys.toList(growable: false),
                  'computedKeys': e.value.computed.keys.toList(growable: false),
                  'mutationKeys':
                      e.value.mutations.keys.toList(growable: false),
                  'queryKeys': e.value.queries.keys.toList(growable: false),
                  'pipelineKeys':
                      e.value.pipelines.keys.toList(growable: false),
                })
            .toList(growable: false),
      };

  QLStoreSlice? operator [](String namespace) => _mounted[namespace];
}

({List<String> deps, dynamic Function(List<dynamic>) compute})?
    _parseComputedSpec(
  String key,
  dynamic spec,
  QLStoreSlice slice,
  QLDataStore store, {
  required QLSliceExecutionContext ctx,
}) {
  if (spec is Map) {
    final map = Map<String, dynamic>.from(spec.cast<String, dynamic>());
    final deps = _qlListOf(map['deps'] ?? map['dependencies'])
        .map((e) => e.toString())
        .toList(growable: false);
    final expr = map['expr']?.toString() ?? map['compute']?.toString() ?? '';
    final op = map['op']?.toString() ?? map['strategy']?.toString() ?? '';
    final args = _qlListOf(map['args']);
    final fallback = map['fallback'];
    final immediate = map['immediate'] == true;

    if (expr.isNotEmpty) {
      final parsed = QLCompiler.parseTokensAndDeps(expr);
      final normalizedDeps = parsed.deps.map((d) {
        if (d.startsWith('state.')) return d.substring(6);
        if (d.startsWith(r'$state.')) return d.substring(7);
        return d;
      }).toList(growable: false);
      return (
        deps: normalizedDeps,
        compute: (List<dynamic> values) => QLDataBinder.resolveAOT(
              {'_isTokenized': true, 'tokens': parsed.tokens},
              QLRuntimeSupport.resolveContext(null),
              {},
              store,
            ),
      );
    }

    if (deps.isNotEmpty) {
      return (
        deps: deps,
        compute: (List<dynamic> values) {
          final payload = <String, dynamic>{
            'current': values.isNotEmpty ? values.first : null,
            'value': values.isNotEmpty ? values.first : null,
            'values': values,
            'args': args,
            'fallback': fallback,
            'immediate': immediate,
            'op': op,
          };
          final result = QLSliceStrategyRegistry.instance.execute(
            op.isEmpty ? 'identity' : op,
            store,
            payload,
            ctx,
            kind: 'transform',
          );
          if (result is Future) {
            return values.isNotEmpty ? values.first : fallback;
          }
          return result;
        },
      );
    }
  } else if (spec is List) {
    final deps = spec.whereType<String>().toList(growable: false);
    if (deps.isNotEmpty) {
      return (
        deps: deps,
        compute: (List<dynamic> values) =>
            values.isNotEmpty ? values.first : null,
      );
    }
  }
  return null;
}

class _SliceMutationPlugin extends QLActionPlugin {
  final QLDataStore _store;
  final QLSliceExecutionContext _ctx;
  final String _name;
  final dynamic _spec;
  final QLStoreSlice _slice;

  _SliceMutationPlugin(
      this._store, this._ctx, this._name, this._spec, this._slice);

  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore _, BuildContext ctx) async {
    final mergedPayload = <String, dynamic>{
      if (_spec is Map)
        ...Map<String, dynamic>.from((_spec as Map).cast<String, dynamic>()),
      ...payload,
    };
    final strategy = mergedPayload['strategy']?.toString() ??
        mergedPayload['op']?.toString() ??
        mergedPayload['type']?.toString() ??
        _name;

    if (mergedPayload['steps'] is List || mergedPayload['action'] != null) {
      final steps = mergedPayload['steps'] is List
          ? List<dynamic>.from(mergedPayload['steps'] as List)
          : _spec is List
              ? List<dynamic>.from(_spec as List)
              : <dynamic>[
                  if (mergedPayload['action'] != null) mergedPayload['action'],
                ];
      final env = Map<String, dynamic>.from(mergedPayload);
      await QuantumVM.instance.triggerActions(steps, ctx, env: env);
      return env[r'$lastResult'];
    }

    return await QLSliceStrategyRegistry.instance.execute(
      strategy,
      _store,
      mergedPayload,
      _ctx,
      kind: 'mutation',
    );
  }
}

class _SliceQueryPlugin extends QLActionPlugin {
  final QLDataStore _store;
  final QLSliceExecutionContext _ctx;
  final String _name;
  final dynamic _spec;
  final QLStoreSlice _slice;
  final String _dataKey;
  final String _loadKey;
  final String _errKey;

  _SliceQueryPlugin(
    this._store,
    this._ctx,
    this._name,
    this._spec,
    this._slice,
  )   : _dataKey = '$_name.data',
        _loadKey = '$_name.loading',
        _errKey = '$_name.error';

  @override
  Future<dynamic> execute(
      Map<String, dynamic> payload, QLDataStore _, BuildContext ctx) async {
    _store.set(_loadKey, true);
    _store.set(_errKey, null);

    final mergedPayload = <String, dynamic>{
      if (_spec is Map)
        ...Map<String, dynamic>.from((_spec as Map).cast<String, dynamic>()),
      ...payload,
    };
    final strategy = mergedPayload['strategy']?.toString() ??
        mergedPayload['op']?.toString() ??
        mergedPayload['type']?.toString() ??
        _name;

    final int ticket = TelemetryVMBridge.beginQueryLoad(
        mergedPayload['id']?.toString() ?? strategy);
    try {
      dynamic result;
      if (mergedPayload['steps'] is List || mergedPayload['action'] != null) {
        final steps = mergedPayload['steps'] is List
            ? List<dynamic>.from(mergedPayload['steps'] as List)
            : _spec is List
                ? List<dynamic>.from(_spec as List)
                : <dynamic>[
                    if (mergedPayload['action'] != null)
                      mergedPayload['action'],
                  ];
        final env = Map<String, dynamic>.from(mergedPayload);
        await QuantumVM.instance.triggerActions(steps, ctx, env: env);
        result = env[r'$lastResult'];
      } else {
        result = await QLSliceStrategyRegistry.instance.execute(
          strategy,
          _store,
          mergedPayload,
          _ctx,
          kind: 'query',
        );
      }

      _store.transaction(() {
        _store.set(_dataKey, result);
        _store.set(_loadKey, false);
      });
      TelemetryVMBridge.endQueryLoad(ticket, success: true);
      return result;
    } catch (e) {
      TelemetryVMBridge.endQueryLoad(ticket, success: false);
      _store.transaction(() {
        _store.set(_errKey, e.toString());
        _store.set(_loadKey, false);
      });
      rethrow;
    }
  }
}

class QLSignalProxy<T> extends QLSignal<T> {
  final QLSignal<dynamic> source;
  final T Function(dynamic) decoder;
  final dynamic Function(T) encoder;

  QLSignalProxy(this.source, this.decoder, this.encoder)
      : super(decoder(source.value)) {
    source.addListener(_syncFromSource);
  }

  void _syncFromSource() {
    final val = decoder(source.value);
    if (super.value != val) {
      super.setSilent(val);
      Future.microtask(() => super.forceNotify());
    }
  }

  @override
  set value(T newValue) {
    if (super.value == newValue) return;
    super.setSilent(newValue);
    source.value = encoder(newValue);
    Future.microtask(() => super.forceNotify());
  }

  @override
  void dispose() {
    source.removeListener(_syncFromSource);
    super.dispose();
  }
}

dynamic _qlMergeProjectedMaps(dynamic current, dynamic incoming) {
  if (current is! Map || incoming is! Map) return incoming;
  final out = Map<String, dynamic>.from(current.cast<String, dynamic>());
  for (final entry in incoming.entries) {
    final key = entry.key.toString();
    final next = entry.value;
    final prev = out[key];
    if (prev is Map && next is Map) {
      out[key] = _qlMergeProjectedMaps(prev, next);
    } else if (prev is List && next is List) {
      out[key] = _qlMergeListRecords(prev, next);
    } else {
      out[key] = next;
    }
  }
  return out;
}

List<dynamic> _qlMergeListRecords(List<dynamic> current, List<dynamic> incoming,
    {String idField = 'id'}) {
  final out = List<dynamic>.from(current);
  final indexById = <String, int>{};

  for (var i = 0; i < out.length; i++) {
    final item = out[i];
    if (item is Map) {
      final id = item[idField]?.toString() ?? item['key']?.toString();
      if (id != null && id.isNotEmpty) {
        indexById[id] = i;
      }
    }
  }

  for (final item in incoming) {
    if (item is Map) {
      final id = item[idField]?.toString() ?? item['key']?.toString();
      if (id != null && id.isNotEmpty) {
        final idx = indexById[id];
        if (idx != null) {
          out[idx] = _qlMergeProjectedMaps(out[idx], item);
          continue;
        }
        indexById[id] = out.length;
      }
    }
    out.add(item);
  }

  return out;
}

void _qlWriteProjectedPath(
  Map<String, dynamic> target,
  List<dynamic> strides,
  dynamic value,
) {
  if (strides.isEmpty) return;
  dynamic current = target;
  for (int i = 0; i < strides.length - 1; i++) {
    final seg = strides[i];
    final next = strides[i + 1];
    if (current is Map) {
      final key = seg.toString();
      current.putIfAbsent(
        key,
        () => next is int ? <dynamic>[] : <String, dynamic>{},
      );
      current = current[key];
    } else if (current is List) {
      final idx = seg is int ? seg : int.tryParse(seg.toString()) ?? 0;
      while (current.length <= idx) {
        current.add(next is int ? <dynamic>[] : <String, dynamic>{});
      }
      current = current[idx];
    } else {
      return;
    }
  }

  final last = strides.last;
  if (current is Map) {
    current[last.toString()] = value;
  } else if (current is List) {
    final idx = last is int ? last : int.tryParse(last.toString()) ?? 0;
    while (current.length <= idx) {
      current.add(null);
    }
    current[idx] = value;
  }
}

Map<String, dynamic> _qlProjectMapBySelect(
  Map<String, dynamic> source,
  Iterable<String> select,
) {
  final out = <String, dynamic>{};
  for (final raw in select) {
    final path = raw.trim();
    if (path.isEmpty) continue;
    final value = _qlReadPathValue(source, path);
    if (value == null) continue;
    _qlWriteProjectedPath(out, QLPathUtils.resolve(path), value);
  }
  return out;
}

dynamic _qlProjectValue(dynamic source, Iterable<String> select) {
  if (source is Map) {
    return _qlProjectMapBySelect(
      Map<String, dynamic>.from(source.cast<String, dynamic>()),
      select,
    );
  }
  if (source is List) {
    return source
        .map((item) => _qlProjectValue(item, select))
        .toList(growable: false);
  }
  return source;
}

bool _qlMatchesWhere(dynamic item, Map<String, dynamic> where) {
  if (where.isEmpty) return true;
  if (item is! Map) return false;
  final map = Map<String, dynamic>.from(item.cast<String, dynamic>());
  for (final entry in where.entries) {
    final key = entry.key.toString();
    final expected = entry.value;
    final actual = _qlReadPathValue(map, key);
    if (expected is Map) {
      final inner = Map<String, dynamic>.from(expected.cast<String, dynamic>());
      if (inner.containsKey('equals') && actual != inner['equals'])
        return false;
      if (inner.containsKey('contains') &&
          !actual.toString().contains(inner['contains'].toString())) {
        return false;
      }
      if (inner.containsKey('gt') &&
          !(actual is num && actual > (inner['gt'] as num))) return false;
      if (inner.containsKey('gte') &&
          !(actual is num && actual >= (inner['gte'] as num))) return false;
      if (inner.containsKey('lt') &&
          !(actual is num && actual < (inner['lt'] as num))) return false;
      if (inner.containsKey('lte') &&
          !(actual is num && actual <= (inner['lte'] as num))) return false;
      continue;
    }
    if (actual != expected) return false;
  }
  return true;
}

extension QLDataStoreUnifiedOps on QLDataStore {
  dynamic read(String path, {Iterable<String>? select}) {
    final value = get(path);
    if (select == null || select.isEmpty) return value;
    return _qlProjectValue(value, select);
  }

  List<Map<String, dynamic>> query(
    String path, {
    Map<String, dynamic>? where,
    Iterable<String>? select,
    String? search,
    int? limit,
    int? offset,
    String? sortBy,
    bool descending = false,
  }) {
    final raw = get(path);
    final list = raw is List ? raw : <dynamic>[if (raw != null) raw];
    final filtered = list.where((item) {
      if (where != null && !_qlMatchesWhere(item, where)) return false;
      if (search != null && search.isNotEmpty) {
        return item.toString().toLowerCase().contains(search.toLowerCase());
      }
      return true;
    }).map((item) {
      if (item is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(item);
        return select == null || select.isEmpty
            ? map
            : _qlProjectMapBySelect(map, select);
      }
      if (item is Map) {
        final map = Map<String, dynamic>.from(item.cast<String, dynamic>());
        return select == null || select.isEmpty
            ? map
            : _qlProjectMapBySelect(map, select);
      }
      return <String, dynamic>{'value': item};
    }).toList(growable: false);

    if (sortBy != null && sortBy.isNotEmpty) {
      filtered.sort((a, b) {
        final av = _qlReadPathValue(a, sortBy);
        final bv = _qlReadPathValue(b, sortBy);
        final cmp = av.toString().compareTo(bv.toString());
        return descending ? -cmp : cmp;
      });
    }

    final start = offset == null || offset <= 0 ? 0 : offset;
    final end = limit == null
        ? filtered.length
        : (start + limit).clamp(0, filtered.length);
    if (start >= filtered.length) return const <Map<String, dynamic>>[];
    return filtered.sublist(start, end);
  }

  Map<String, dynamic> create(String path, dynamic value) {
    if (value is Map) {
      final next = Map<String, dynamic>.from(value.cast<String, dynamic>());
      if (path.isEmpty) {
        set(path, next);
        return next;
      }
      final current = get(path);
      if (current is List) {
        final merged = List<dynamic>.from(current)..add(next);
        set(path, merged);
      } else {
        set(path, next);
      }
      return next;
    }
    set(path, value);
    return <String, dynamic>{'value': value};
  }

  Map<String, dynamic> update(String path, dynamic value) {
    final current = get(path);
    if (current is Map && value is Map) {
      final merged = _qlMergeProjectedMaps(current, value);
      set(path, merged);
      return Map<String, dynamic>.from(merged.cast<String, dynamic>());
    }
    set(path, value);
    return value is Map
        ? Map<String, dynamic>.from(value.cast<String, dynamic>())
        : <String, dynamic>{'value': value};
  }

  Map<String, dynamic> upsert(String path, dynamic value,
      {String idField = 'id'}) {
    final current = get(path);
    if (current is List && value is Map) {
      final next = List<dynamic>.from(current);
      final id = value[idField]?.toString();
      if (id != null && id.isNotEmpty) {
        final idx = next.indexWhere(
            (item) => item is Map && item[idField]?.toString() == id);
        if (idx >= 0) {
          next[idx] = _qlMergeProjectedMaps(next[idx], value);
        } else {
          next.add(value);
        }
      } else {
        next.add(value);
      }
      set(path, next);
      return Map<String, dynamic>.from(value.cast<String, dynamic>());
    }
    return update(path, value);
  }

  dynamic delete(String path) {
    final current = get(path);
    sweep(path);
    return current;
  }

  dynamic push(String path, dynamic value) {
    final current = get(path);
    final next = current is List
        ? List<dynamic>.from(current)
        : <dynamic>[if (current != null) current];
    if (value is List) {
      next.addAll(value);
    } else {
      next.add(value);
    }
    set(path, next);
    return next;
  }

  dynamic pop(String path, {int index = -1}) {
    final current = get(path);
    if (current is! List || current.isEmpty) return null;
    final next = List<dynamic>.from(current);
    final idx = index < 0 ? next.length - 1 : index;
    if (idx < 0 || idx >= next.length) return null;
    final removed = next.removeAt(idx);
    set(path, next);
    return removed;
  }

  dynamic move(String path, int from, int to) {
    final current = get(path);
    if (current is! List || current.isEmpty) return current;
    final next = List<dynamic>.from(current);
    if (from < 0 || from >= next.length) return current;
    final item = next.removeAt(from);
    final target = to.clamp(0, next.length);
    next.insert(target, item);
    set(path, next);
    return next;
  }

  dynamic reorder(String path, List<int> order) {
    final current = get(path);
    if (current is! List || current.isEmpty) return current;
    final next = <dynamic>[];
    for (final idx in order) {
      if (idx >= 0 && idx < current.length) {
        next.add(current[idx]);
      }
    }
    if (next.isEmpty) return current;
    set(path, next);
    return next;
  }

  num increment(String path, [num amount = 1]) {
    final current = get(path);
    final next = (current is num ? current : 0) + amount;
    set(path, next);
    return next;
  }

  num decrement(String path, [num amount = 1]) {
    final current = get(path);
    final next = (current is num ? current : 0) - amount;
    set(path, next);
    return next;
  }

  num aggregate(String path, {String op = 'count', String? field}) {
    final current = get(path);
    final list =
        current is List ? current : <dynamic>[if (current != null) current];
    final values = <num>[];
    for (final item in list) {
      if (field == null) {
        if (item is num) values.add(item);
        continue;
      }
      final raw = _qlReadPathValue(item, field);
      if (raw is num) {
        values.add(raw);
      } else if (raw != null) {
        final parsed = num.tryParse(raw.toString());
        if (parsed != null) values.add(parsed);
      }
    }

    switch (op) {
      case 'sum':
        return values.fold<num>(0, (a, b) => a + b);
      case 'avg':
        return values.isEmpty
            ? 0
            : values.fold<num>(0, (a, b) => a + b) / values.length;
      case 'min':
        return values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
      case 'max':
        return values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
      default:
        return list.length;
    }
  }

  Stream<dynamic> subscribe(String path) => signal(path).stream;

  StreamSubscription<dynamic> listen(
    String path,
    void Function(dynamic event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return signal(path).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void publish(String path, dynamic value) {
    set(path, value);
  }
}
