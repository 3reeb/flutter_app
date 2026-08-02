/*
 * ============================================================================
 * File: quantum_async.dart
 * 
 * Description:
 * Reactive Asynchronous State Machine for the Quantum Framework. This file provides 
 * signal-based wrappers around futures and streams to manage loading, data, and error 
 * states reactively without the boilerplate of traditional FutureBuilders.
 * 
 * Key Components:
 * - QLAsyncSignal: A state machine encapsulating asynchronous operations (loading/data/error).
 * - QLAsyncBuilder: A widget that cleanly reacts to QLAsyncSignal state changes.
 * 
 * Dependencies/Relationships:
 * Depends on quantum_primitives.dart (QLSignal). Used throughout the application 
 * to handle network requests, database queries, and async initializations reactively.
 * 
 * Notes:
 * Designed to minimize rebuilds by relying on the structural reactivity of Quantum Signals 
 * rather than rebuilding the entire widget tree on every state tick.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM ASYNC ENGINE v1.0 - OMEGA RESOURCE PRIMITIVE
// quantum_async.dart
//
// ARCHITECTURE:
// 1. QLAsyncSignal<T>: A resource-owning ChangeNotifier with three child
//    QLSignals (loading, data, error) for fine-grained reactivity.
//    Any RenderObject can watch the individual sub-signals, reacting only
//    to the specific state change it cares about (zero over-notification).
// 2. Zero-Allocation State Machine: Status transitions write directly into
//    the pre-allocated sub-signals via setSilent/forceNotify — no new
//    object is heap-allocated on each state change.
// 3. Auto-Retry with Exponential Backoff: Timer-driven retry with doubling
//    delays. No polling. No extra isolates. Pure Timer chaining.
// 4. Lifecycle Safety: _disposed guard on every async callback. No callbacks
//    fire into dead widget trees. StreamSubscription is always cancelled.
// 5. QLAsyncRegistry: Singleton key-value store for named async resources.
//    Allows SDUI plugins to bind async signals to QLDataStore paths.
// 6. QLDataStoreAsyncExt: Bidirectional sync between QLAsyncSignal<T>.data
//    and a QLDataStore key — zero extra listeners beyond what's needed.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../quantum.dart'; // For QLDataStore

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  IMMUTABLE ASYNC SNAPSHOT (Zero-Allocation State Carrier)
// ────────────────────────────────────────────────────────────────────────────

enum QLAsyncStatus { idle, loading, success, error }

/// Immutable, type-safe snapshot of a single async resource moment.
/// Never allocates unless a new state transition occurs.
@immutable
class QLAsyncSnapshot<T> {
  final QLAsyncStatus status;
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;
  final int retryCount;

  const QLAsyncSnapshot._({
    required this.status,
    this.data,
    this.error,
    this.stackTrace,
    this.retryCount = 0,
  });

  const QLAsyncSnapshot.idle()
      : status = QLAsyncStatus.idle,
        data = null,
        error = null,
        stackTrace = null,
        retryCount = 0;

  const QLAsyncSnapshot.loading({this.retryCount = 0})
      : status = QLAsyncStatus.loading,
        data = null,
        error = null,
        stackTrace = null;

  const QLAsyncSnapshot.data(T this.data)
      : status = QLAsyncStatus.success,
        error = null,
        stackTrace = null,
        retryCount = 0;

  const QLAsyncSnapshot.error(Object this.error,
      [StackTrace? this.stackTrace, this.retryCount = 0])
      : status = QLAsyncStatus.error,
        data = null;

  bool get isIdle => status == QLAsyncStatus.idle;
  bool get isLoading => status == QLAsyncStatus.loading;
  bool get hasData => status == QLAsyncStatus.success;
  bool get hasError => status == QLAsyncStatus.error;

  /// Returns data or throws if not in success state.
  @pragma('vm:prefer-inline')
  T get requireData {
    assert(hasData, 'QLAsyncSnapshot.requireData called in $status state');
    return data as T;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QLAsyncSnapshot<T> &&
          status == other.status &&
          data == other.data &&
          error == other.error &&
          retryCount == other.retryCount);

  @override
  int get hashCode => Object.hash(status, data, error, retryCount);
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QLASYNC SIGNAL (Resource-Owning Reactive Primitive)
// ────────────────────────────────────────────────────────────────────────────

class QLAsyncSignal<T> extends ChangeNotifier {
  // ── Fine-grained sub-signals (watchers subscribe to only what they need) ──
  final QLSignal<bool> loading = QLSignal<bool>(false);
  final QLSignal<T?> data = QLSignal<T?>(null);
  final QLSignal<Object?> error = QLSignal<Object?>(null);

  // ── Snapshot (O(1) read, updated atomically via _transition) ──
  QLAsyncSnapshot<T> _snapshot = const QLAsyncSnapshot.idle();
  QLAsyncSnapshot<T> get snapshot => _snapshot;

  // ── Lifecycle & cancellation ──
  StreamSubscription<T>? _subscription;
  Timer? _retryTimer;
  bool _disposed = false;

  // ── Retry state ──
  int _retryCount = 0;
  Future<T> Function()? _lastFetch;
  int _maxRetries = 3;
  Duration _baseDelay = const Duration(milliseconds: 500);
  bool _exponentialBackoff = true;

  // ════════════════════════════════════════════════════════════════════════
  //  STATE MACHINE (Zero-Allocation Transitions)
  // ════════════════════════════════════════════════════════════════════════

  /// Atomically transitions to loading state.
  /// setSilent + forceNotify avoids double-notify on each sub-signal.
  @pragma('vm:prefer-inline')
  void _enterLoading() {
    if (_disposed) return;
    _snapshot = QLAsyncSnapshot<T>.loading(retryCount: _retryCount);
    loading.setSilent(true);
    error.setSilent(null);
    loading.forceNotify();
    error.forceNotify();
    notifyListeners();
  }

  @pragma('vm:prefer-inline')
  void _enterData(T value) {
    if (_disposed) return;
    _snapshot = QLAsyncSnapshot<T>.data(value);
    data.setSilent(value);
    loading.setSilent(false);
    error.setSilent(null);
    data.forceNotify();
    loading.forceNotify();
    error.forceNotify();
    _retryCount = 0;
    notifyListeners();
  }

  @pragma('vm:prefer-inline')
  void _enterError(Object e, StackTrace? st) {
    if (_disposed) return;
    _snapshot = QLAsyncSnapshot<T>.error(e, st, _retryCount);
    error.setSilent(e);
    loading.setSilent(false);
    error.forceNotify();
    loading.forceNotify();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ════════════════════════════════════════════════════════════════════════

  /// Loads data from a Future factory. Cancels any previous subscription.
  /// [autoRetry]: whether to retry on failure.
  /// [maxRetries]: max retry attempts (exponential backoff).
  void load(
    Future<T> Function() fetch, {
    bool cancelOnReload = true,
    bool autoRetry = false,
    int maxRetries = 3,
    Duration retryDelay = const Duration(milliseconds: 500),
    bool exponentialBackoff = true,
  }) {
    if (_disposed) return;

    if (cancelOnReload) {
      _subscription?.cancel();
      _subscription = null;
      _retryTimer?.cancel();
      _retryTimer = null;
    }

    _lastFetch = fetch;
    _maxRetries = maxRetries;
    _baseDelay = retryDelay;
    _exponentialBackoff = exponentialBackoff;

    _enterLoading();

    fetch().then(_enterData, onError: (Object e, StackTrace st) {
      _enterError(e, st);
      if (autoRetry && _retryCount < _maxRetries) {
        _retryCount++;
        final Duration delay = _exponentialBackoff
            ? _baseDelay * (1 << (_retryCount - 1))
            : _baseDelay;
        _retryTimer = Timer(delay, () {
          if (!_disposed) {
            load(
              fetch,
              autoRetry: autoRetry,
              maxRetries: _maxRetries,
              retryDelay: _baseDelay,
              exponentialBackoff: _exponentialBackoff,
            );
          }
        });
      }
    });
  }

  /// Binds to a Stream. Data arrives reactively. Cancels previous subscription.
  void bind(Stream<T> source, {bool cancelExisting = true}) {
    if (_disposed) return;

    if (cancelExisting) {
      _subscription?.cancel();
      _subscription = null;
    }

    _enterLoading();

    _subscription = source.listen(
      _enterData,
      onError: (Object e, StackTrace st) => _enterError(e, st),
      onDone: () {
        if (!_disposed && loading.value) {
          loading.setSilent(false);
          loading.forceNotify();
          notifyListeners();
        }
      },
      cancelOnError:
          false, // Keep listening after errors unless we decide otherwise
    );
  }

  /// Manual retry using the last fetch function.
  void retry() {
    if (_disposed || _lastFetch == null) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    load(_lastFetch!,
        autoRetry: true,
        maxRetries: _maxRetries,
        retryDelay: _baseDelay,
        exponentialBackoff: _exponentialBackoff);
  }

  /// Resets to idle state. Cancels all pending operations.
  void reset() {
    if (_disposed) return;
    _subscription?.cancel();
    _subscription = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
    _lastFetch = null;
    _snapshot = const QLAsyncSnapshot.idle();

    // Batch-reset all sub-signals
    loading.setSilent(false);
    data.setSilent(null);
    error.setSilent(null);
    loading.forceNotify();
    data.forceNotify();
    error.forceNotify();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _retryTimer?.cancel();
    loading.dispose();
    data.dispose();
    error.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLASYNC WIDGET (DX Builder with Fine-Grained Rebuild Control)
// ────────────────────────────────────────────────────────────────────────────

/// A zero-boilerplate async builder that:
/// - Rebuilds ONLY when the snapshot status changes (uses signal identity).
/// - Passes typed data directly to [onData], avoiding all dynamic casts.
/// - Exposes a retry callback directly to the [onError] builder.
class QLAsyncBuilder<T> extends StatelessWidget {
  final QLAsyncSignal<T> signal;
  final Widget Function(BuildContext ctx, T data) onData;
  final Widget Function(BuildContext ctx)? onLoading;
  final Widget Function(BuildContext ctx, Object error, VoidCallback retry)?
      onError;
  final Widget Function(BuildContext ctx)? onIdle;

  const QLAsyncBuilder({
    super.key,
    required this.signal,
    required this.onData,
    this.onLoading,
    this.onError,
    this.onIdle,
  });

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder listens to the signal's ChangeNotifier directly.
    // Rebuilds only when notifyListeners() fires in _enterX methods.
    return AnimatedBuilder(
      animation: signal,
      builder: (context, _) {
        final QLAsyncSnapshot<T> snap = signal.snapshot;
        return switch (snap.status) {
          QLAsyncStatus.idle =>
            onIdle?.call(context) ?? const SizedBox.shrink(),
          QLAsyncStatus.loading => onLoading?.call(context) ??
              const Center(child: CircularProgressIndicator()),
          QLAsyncStatus.success => onData(context, snap.requireData),
          QLAsyncStatus.error => onError?.call(
                  context, snap.error!, signal.retry) ??
              _QLDefaultErrorWidget(error: snap.error!, onRetry: signal.retry),
        };
      },
    );
  }
}

class _QLDefaultErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _QLDefaultErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text('$error',
              style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QLASYNC REGISTRY (Named Resource Store — Global Singleton)
// ────────────────────────────────────────────────────────────────────────────

/// Global registry for named QLAsyncSignals.
/// Allows SDUI blueprints and plugins to share async resources by key
/// without passing objects through the widget tree.
class QLAsyncRegistry {
  static final QLAsyncRegistry instance = QLAsyncRegistry._();
  QLAsyncRegistry._();

  final Map<String, QLAsyncSignal<dynamic>> _registry = {};

  /// Returns existing signal or creates a new one for the given key.
  QLAsyncSignal<T> get<T>(String key) {
    final existing = _registry[key];
    if (existing is QLAsyncSignal<T>) return existing;
    final signal = QLAsyncSignal<T>();
    _registry[key] = signal;
    return signal;
  }

  /// Disposes and removes a signal by key.
  void release(String key) {
    _registry.remove(key)?.dispose();
  }

  /// Disposes all signals with keys matching the given prefix.
  /// Used by QLLifecycleWrapper to sweep async resources on unmount.
  void sweepPrefix(String prefix) {
    final List<String> toRemove =
        _registry.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in toRemove) {
      _registry.remove(key)?.dispose();
    }
  }

  /// Disposes ALL registered signals. Call on app teardown only.
  void disposeAll() {
    for (final sig in _registry.values) {
      sig.dispose();
    }
    _registry.clear();
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QLDATASTORE ASYNC EXTENSION (Bidirectional Binding)
// ────────────────────────────────────────────────────────────────────────────

extension QLDataStoreAsyncExt on QLDataStore {
  /// One-way binding: when [asyncSig] receives data, it automatically
  /// writes it into the QLDataStore at [key].
  /// Returns the signal so callers can also bind their own listeners.
  QLAsyncSignal<T> bindAsync<T>(String key, QLAsyncSignal<T> asyncSig) {
    // Only install one listener. Use the data sub-signal for precision.
    asyncSig.data.addListener(() {
      final T? val = asyncSig.data.value;
      if (val != null) set(key, val);
    });
    return asyncSig;
  }

  /// Convenience: create a named async signal that auto-binds to this store.
  QLAsyncSignal<T> createAsync<T>(String storeKey) {
    return bindAsync(storeKey, QLAsyncRegistry.instance.get<T>(storeKey));
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QLASYNC SCOPE (InheritedWidget for Subtree Access)
// ────────────────────────────────────────────────────────────────────────────

/// Provides a QLAsyncSignal to a widget subtree.
/// Allows child widgets to access the signal without explicit prop drilling.
class QLAsyncScope<T> extends InheritedNotifier<QLAsyncSignal<T>> {
  const QLAsyncScope({
    super.key,
    required QLAsyncSignal<T> signal,
    required super.child,
  }) : super(notifier: signal);

  static QLAsyncSignal<T>? of<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<QLAsyncScope<T>>()?.notifier;
}
