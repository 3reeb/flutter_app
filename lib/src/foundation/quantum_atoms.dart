/*
 * ============================================================================
 * File: quantum_atoms.dart
 * 
 * Description:
 * Reactive State Atoms and Atom Families. Provides atomic, composable units of state 
 * for managing application data globally or in isolated scopes without passing variables 
 * down the widget tree.
 * 
 * Key Components:
 * - QLStateAtom: A distinct, reactive unit of read/write state.
 * - QLComputedAtom: A derived atom that automatically recomputes when its dependencies change.
 * - QLAtomFamily: A factory for creating parameterized atoms dynamically (e.g., fetching by ID).
 * 
 * Dependencies/Relationships:
 * Built on quantum_primitives.dart. Widely utilized by business logic controllers 
 * and UI components to maintain global shared state efficiently.
 * 
 * Notes:
 * Heavily inspired by Recoil/Jotai. Highly optimized to prevent unnecessary re-evaluations 
 * of derived state.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../quantum.dart';
import 'quantum_reactive_graph.dart';

typedef QLAtomEquals<T> = bool Function(T a, T b);
typedef QLAtomDecoder<T> = T Function(dynamic value);
typedef QLAtomEncoder<T> = dynamic Function(T value);

bool _qlAtomDefaultEquals<T>(T a, T b) => identical(a, b) || a == b;

/// A small mutable atom built on top of [QLSignal].
///
/// This is intentionally thin: it reuses the existing signal machinery rather
/// than creating a second state system. The extra value here is the developer
/// ergonomics: typed helpers, named keys, equality guards, and atom families.
class QLStateAtom<T> extends QLSignal<T> {
  final String key;
  final QLAtomEquals<T> equals;
  final bool keepAlive;

  QLStateAtom(
    this.key,
    T initial, {
    QLAtomEquals<T>? equals,
    this.keepAlive = true,
  })  : equals = equals ?? _qlAtomDefaultEquals,
        super(initial);

  @override
  set value(T next) {
    if (equals(super.value, next)) return;
    super.value = next;
  }

  /// Computes a new value based on the current state, and assigns it.
  /// (Named `updateValue` to avoid signature collisions with `QLSignal.update`)
  T updateValue(T Function(T current) mutate) {
    final next = mutate(value);
    value = next;
    return next;
  }

  void reset(T next) => value = next;

  void toggle() {
    if (value is bool) {
      value = (!(value as bool)) as T;
    } else {
      throw StateError('QLStateAtom<$T>[$key] cannot toggle a non-bool value.');
    }
  }

  QLComputedAtom<R> select<R>(
    R Function(T value) mapper, {
    QLAtomEquals<R>? equals,
    String? label,
  }) {
    return QLComputedAtom<R>(
      label ?? '$key.select',
      () => mapper(value),
      equals: equals,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// A derived atom that keeps the same zero-boilerplate API shape as a state
/// atom, but evaluates lazily and batches dependency changes microtask-by-
/// microtask via [QLDerivedSignal].
class QLComputedAtom<T> extends QLDerivedSignal<T> {
  final String key;
  final QLAtomEquals<T> equals;
  final bool keepAlive;

  QLComputedAtom(
    this.key,
    T Function() compute, {
    QLAtomEquals<T>? equals,
    this.keepAlive = true,
  })  : equals = equals ?? _qlAtomDefaultEquals,
        super(compute, equals: equals ?? _qlAtomDefaultEquals);

  QLComputedAtom<R> select<R>(
    R Function(T value) mapper, {
    QLAtomEquals<R>? equals,
    String? label,
  }) {
    return QLComputedAtom<R>(
      label ?? '$key.select',
      () => mapper(value),
      equals: equals,
    );
  }
}

/// A typed bridge from a store path to a reactive atom.
///
/// It reuses the existing [QLSignalProxy] so the store remains the source of
/// truth. The atom simply gives callers a typed, ergonomic view over that path.
class QLStoreAtom<T> extends QLSignalProxy<T> {
  final QLDataStore store;
  final String path;
  final QLAtomDecoder<T> decode;
  final QLAtomEncoder<T> encode;

  QLStoreAtom(
    this.store,
    this.path, {
    required this.decode,
    required this.encode,
  }) : super(store.signal(path), decode, encode);
}

/// A simple memory-friendly atom family with LRU eviction.
///
/// The family only holds the most recent [maxEntries] atoms. When an atom is
/// evicted, [disposeAtom] is called so callers can release listeners and other
/// resources.
class QLAtomFamily<K, A> {
  final int maxEntries;
  final A Function(K key) create;
  final void Function(A atom)? disposeAtom;
  final LinkedHashMap<K, A> _cache = LinkedHashMap<K, A>();

  QLAtomFamily({
    required this.create,
    this.maxEntries = 256,
    this.disposeAtom,
  });

  A call(K key) {
    final existing = _cache.remove(key);
    if (existing != null) {
      _cache[key] = existing;
      return existing;
    }

    final atom = create(key);
    _cache[key] = atom;
    _evictIfNeeded();
    return atom;
  }

  bool contains(K key) => _cache.containsKey(key);

  void remove(K key) {
    final atom = _cache.remove(key);
    if (atom != null) disposeAtom?.call(atom);
  }

  void clear() {
    final keys = _cache.keys.toList(growable: false);
    for (final key in keys) {
      remove(key);
    }
  }

  Iterable<K> get keys => _cache.keys;
  Iterable<A> get values => _cache.values;
  int get length => _cache.length;

  void _evictIfNeeded() {
    while (_cache.length > maxEntries) {
      final victimKey = _cache.keys.first;
      final victim = _cache.remove(victimKey);
      if (victim != null) disposeAtom?.call(victim);
    }
  }
}

/// Atom helpers wired directly into the existing store/runtime.
extension QLDataStoreAtomExt on QLDataStore {
  /// A local mutable atom that is independent from the store tree.
  QLStateAtom<T> stateAtom<T>(
    String key,
    T initial, {
    QLAtomEquals<T>? equals,
  }) {
    return QLStateAtom<T>(
      key,
      initial,
      equals: equals,
    );
  }

  /// A derived atom that can read any store-backed path inside its compute.
  QLComputedAtom<T> computedAtom<T>(
    String key,
    T Function() compute, {
    QLAtomEquals<T>? equals,
  }) {
    return QLComputedAtom<T>(
      key,
      compute,
      equals: equals,
    );
  }

  /// A typed, store-backed atom view for a single path.
  QLStoreAtom<T> pathAtom<T>(
    String path, {
    required QLAtomDecoder<T> decode,
    required QLAtomEncoder<T> encode,
  }) {
    return QLStoreAtom<T>(
      this,
      path,
      decode: decode,
      encode: encode,
    );
  }

  /// A convenience view for primitive paths that already store the right type.
  ///
  /// This is the common case for strings, numbers, booleans, maps, and lists.
  QLStoreAtom<T> typedPathAtom<T>(
    String path, {
    T? fallback,
  }) {
    return QLStoreAtom<T>(
      this,
      path,
      decode: (value) {
        if (value is T) return value;
        if (fallback != null) return fallback;
        throw StateError('QLDataStore path "$path" does not contain a $T.');
      },
      encode: (value) => value,
    );
  }
}

extension QuantumVMAtomExt on QuantumVM {
  QLStateAtom<T> stateAtom<T>(
    String key,
    T initial, {
    QLAtomEquals<T>? equals,
  }) {
    return QLStateAtom<T>(
      key,
      initial,
      equals: equals,
    );
  }

  QLComputedAtom<T> computedAtom<T>(
    String key,
    T Function() compute, {
    QLAtomEquals<T>? equals,
  }) {
    return QLComputedAtom<T>(
      key,
      compute,
      equals: equals,
    );
  }

  QLStoreAtom<T> storeAtom<T>(
    String path, {
    required QLAtomDecoder<T> decode,
    required QLAtomEncoder<T> encode,
  }) {
    return store.pathAtom<T>(
      path,
      decode: decode,
      encode: encode,
    );
  }

  QLStoreAtom<T> typedStoreAtom<T>(String path, {T? fallback}) {
    return store.typedPathAtom<T>(path, fallback: fallback);
  }
}

/// Bridges any signal-like atom into an existing Flutter [ListenableBuilder].
class QLAtomBuilder<T> extends StatelessWidget {
  final QLSignalBase<T> atom;
  final Widget Function(BuildContext context, T value) builder;

  const QLAtomBuilder({
    super.key,
    required this.atom,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: atom,
      builder: (context, _) => builder(context, atom.value),
    );
  }
}
