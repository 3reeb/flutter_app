import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/ql_path_utils.dart';
import '../core/ql_types.dart';
import '../storage/ql_storage_adapter.dart';
import '../storage/ql_ram_storage_adapter.dart';
import 'ql_signal.dart';
import 'ql_computation_dag.dart';

class QLDataStore implements QLDisposable {
  final String namespace;
  final QLStorageAdapter storage;

  QLDataStore({required this.namespace, QLStorageAdapter? storageAdapter})
      : storage = storageAdapter ?? QLRAMStorageAdapter();

  final Map<String, QLSignal<dynamic>> _signals = <String, QLSignal<dynamic>>{};
  final Map<String, List<QLComputationNode>> _dependencyGraph =
      <String, List<QLComputationNode>>{};
  final Map<String, QLComputationNode> _computedRegistry =
      <String, QLComputationNode>{};

  final Map<String, Set<String>> _pathIndex = <String, Set<String>>{};
  final List<Map<String, dynamic>> _history = <Map<String, dynamic>>[];
  static const int _maxHistory = 50;

  bool _isBatching = false;
  int _batchDepth = 0;
  final Set<String> _txDirtyKeys = <String>{};
  final Set<QLSignal<dynamic>> _dirtySignals = <QLSignal<dynamic>>{};

  bool get isBatching => _isBatching;
  Map<String, dynamic> get snapshot =>
      Map.unmodifiable(_signals.map((k, v) => MapEntry(k, v.value)));

  QLSignal<dynamic> signal(String key) {
    return _signals.putIfAbsent(key, () {
      _indexSignalKey(key);
      return QLSignal<dynamic>(storage.read(key));
    });
  }

  QLSignal<dynamic>? maybeSignal(String key) => _signals[key];

  void registerDirtySignal(QLSignal<dynamic> sig) => _dirtySignals.add(sig);
  void registerTxDirtyKey(String key) => _txDirtyKeys.add(key);

  void set(String path, dynamic value) {
    transaction(() {
      final List<dynamic> strides = QLPathUtils.resolve(path);
      if (strides.isEmpty) return;

      final rootKey = strides.first.toString();
      final rootSignal = signal(rootKey);

      final nextRoot = _immutableMutate(rootSignal.value, strides, 1, value);
      if (EqualityComparer.equals(rootSignal.value, nextRoot)) return;

      _txDirtyKeys.add(path);
      _txDirtyKeys.add(rootKey);

      rootSignal.setSilent(nextRoot);
      _dirtySignals.add(rootSignal);
      storage.write(rootKey, nextRoot);
      _notifyCascades(path);
    });
  }

  dynamic get(Object path) {
    final List<dynamic> strides =
        path is List ? path : QLPathUtils.resolve(path.toString());
    if (strides.isEmpty) return null;

    final rootKey = strides.first.toString();
    dynamic current = _signals[rootKey]?.value ?? storage.read(rootKey);

    for (int i = 1; i < strides.length && current != null; i++) {
      final Object key = strides[i];
      if (current is Map) {
        current = current[key.toString()];
      } else if (current is List && key is int) {
        current = (key >= 0 && key < current.length) ? current[key] : null;
      } else {
        return null;
      }
    }
    return current;
  }

  bool has(String path) => get(path) != null;

  void merge(Map<String, dynamic> data) {
    transaction(() {
      data.forEach((k, v) => set(k, v));
    });
  }

  void sweep(String path) {
    transaction(() {
      final List<dynamic> strides = QLPathUtils.resolve(path);
      if (strides.isEmpty) return;

      final rootKey = strides.first.toString();
      final rootSignal = _signals[rootKey];
      if (rootSignal == null) return;

      if (strides.length == 1) {
        _signals.remove(rootKey)?.dispose();
        _unindexSignalKey(rootKey);
        storage.delete(rootKey);
        return;
      }

      final nextRoot = _immutableDelete(rootSignal.value, strides, 1);
      rootSignal.setSilent(nextRoot);
      _dirtySignals.add(rootSignal);
      _txDirtyKeys.add(rootKey);
      storage.write(rootKey, nextRoot);
    });
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

    if (_batchDepth == 0 && _txDirtyKeys.isNotEmpty) {
      _commitTransaction();
    }
  }

  void saveSnapshot() {
    if (_history.length >= _maxHistory) _history.removeAt(0);
    _history.add(snapshot);
  }

  void rollback() {
    if (_history.isEmpty) return;
    merge(_history.removeLast());
  }

  void registerComputed(
      String targetKey,
      List<String> dependencies,
      dynamic Function(List<dynamic>) calculator) {
    final node = QLComputationNode(
        targetKey, signal(targetKey), dependencies, calculator, this);
    _computedRegistry[targetKey] = node;

    for (final dep in dependencies) {
      _dependencyGraph.putIfAbsent(dep, () => <QLComputationNode>[]).add(node);
    }
    node.evaluateSilent();
  }

  void _commitTransaction() {
    _evaluateTopologicalComputes();
    for (final sig in _dirtySignals) {
      sig.forceNotify();
    }
    _txDirtyKeys.clear();
    _dirtySignals.clear();
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
    final Map<String, dynamic> copy =
        Map<String, dynamic>.from(current is Map ? current : <String, dynamic>{});
    copy[mapKey] = _immutableMutate(
      copy[mapKey] ?? (createList ? <dynamic>[] : <String, dynamic>{}),
      strides,
      index + 1,
      value,
    );
    return copy;
  }

  dynamic _immutableDelete(
      dynamic current, List<dynamic> strides, int index) {
    if (current == null) return null;
    final Object key = strides[index];
    final bool isLast = index == strides.length - 1;

    if (current is Map) {
      final String mapKey = key.toString();
      final copy = Map<String, dynamic>.from(current);
      if (isLast) {
        copy.remove(mapKey);
      } else {
        copy[mapKey] = _immutableDelete(copy[mapKey], strides, index + 1);
      }
      return copy;
    }

    if (current is List && key is int) {
      final copy = List<dynamic>.from(current);
      if (key < 0 || key >= copy.length) return current;
      if (isLast) {
        copy.removeAt(key);
      } else {
        copy[key] = _immutableDelete(copy[key], strides, index + 1);
      }
      return copy;
    }
    return current;
  }

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

  void _notifyCascades(String mutatedPath) {
    for (final prefix in QLPathUtils.prefixes(mutatedPath)) {
      final bucket = _pathIndex[prefix];
      if (bucket == null) continue;
      for (final key in bucket) {
        final sig = _signals[key];
        if (sig != null) _dirtySignals.add(sig);
      }
    }
  }

  @override
  void dispose() {
    for (final sig in _signals.values) {
      sig.dispose();
    }
    _signals.clear();
    _computedRegistry.clear();
    _dependencyGraph.clear();
    _pathIndex.clear();
    _history.clear();
  }
}
