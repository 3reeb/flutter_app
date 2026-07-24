import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../quantum.dart';

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

  bool has(String path) => get(path) != null;

  void sweep(String pathPrefix) {
    _invalidateReadCache(pathPrefix);

    final keys = _signals.keys
        .where((key) => key.startsWith(pathPrefix))
        .toList(growable: false);

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
    register('append', _append, kind: 'mutation');
    register('prepend', _prepend, kind: 'mutation');
    register('patch', _patch, kind: 'mutation');
    register('toggle', _toggle, kind: 'mutation');
    register('increment', _increment, kind: 'mutation');
    register('decrement', _decrement, kind: 'mutation');

    register('get', _get, kind: 'query');
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
      }
    } else if (kind == 'query') {
      switch (op) {
        case 'get':
        case 'resolve':
          return _get(store, payload, ctx);
        case 'snapshot':
          return _snapshot(store, payload, ctx);
        case 'keys':
          return _keys(store, payload, ctx);
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
    final by = (payload['by'] as num?)?.toDouble() ?? 1.0;
    final next = (current is num ? current.toDouble() : 0.0) + by;
    store.set(path, next);
    return next;
  }

  FutureOr<dynamic> _decrement(QLDataStore store, Map<String, dynamic> payload,
      QLSliceExecutionContext ctx) {
    final path = payload['path']?.toString() ?? payload['key']?.toString();
    if (path == null || path.isEmpty) return null;
    final current = store.get(path);
    final by = (payload['by'] as num?)?.toDouble() ?? 1.0;
    final next = (current is num ? current.toDouble() : 0.0) - by;
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

class QLDataSourceHandle {
  final String name;
  Map<String, dynamic> config;
  final QLAsyncSignal<dynamic> signal;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  QLDataSourceHandle({required this.name, required this.config})
      : signal = QLAsyncRegistry.instance.get<dynamic>('dataSources.$name');

  bool get isStreaming =>
      config['stream'] is Map ||
      config['subscribe'] == true ||
      config['realtime'] == true ||
      config['type']?.toString() == 'realtime' ||
      config['type']?.toString() == 'media' ||
      config['type']?.toString() == 'stream' ||
      config['direction']?.toString() != 'outboundOnly';

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
      if (type == 'media') {
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
        domain == 'task' ||
        action == 'subscribe' ||
        action == 'firehose' ||
        action == 'adaptive_stream';
  }

  dynamic _normalizeStreamEvent(Map<String, dynamic> event) {
    if (event.containsKey('data')) return event['data'];
    if (event.containsKey('bytes')) return event['bytes'];
    if (event.containsKey('event') && event.containsKey('payload')) {
      return event['payload'];
    }
    return event;
  }

  Future<dynamic> refresh({Map<String, dynamic>? overrides}) async {
    await _subscription?.cancel();
    _subscription = null;
    final request = _buildRequest(overrides: overrides);
    _enterLoading();

    if (_shouldStreamRequest(request)) {
      final completer = Completer<dynamic>();
      var firstEvent = true;
      _subscription = Quantum.runStreamAction(request).listen(
        (event) {
          final value = _normalizeStreamEvent(event);
          _enterData(value);
          if (firstEvent) {
            firstEvent = false;
            if (!completer.isCompleted) completer.complete(value);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _enterError(error, stackTrace);
          if (!completer.isCompleted)
            completer.completeError(error, stackTrace);
        },
        onDone: () {
          if (signal.loading.value) {
            signal.loading.setSilent(false);
            signal.loading.forceNotify();
          }
        },
        cancelOnError: false,
      );
      return completer.future;
    }

    final result = await Quantum.runAction(request);
    if (result['success'] == true) {
      final data = result['data'];
      _enterData(data);
      return data;
    }
    final error = result['error'] ?? 'Unknown datasource error';
    _enterError(StateError(error.toString()), StackTrace.current);
    return null;
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
    final existing = _sources[name];
    if (existing != null) {
      existing.config = config;
      return existing;
    }
    final handle = QLDataSourceHandle(name: name, config: config);
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
    Map<String, dynamic>? metadata,
    QLSliceExecutionContext? ctx,
  }) {
    final handle = _sources[sourceName];
    if (handle == null) {
      if (defaultValue != null) store.set(statePath, defaultValue);
      return () {};
    }

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
  });

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
