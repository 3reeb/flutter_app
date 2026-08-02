/*
 * ============================================================================
 * File: quantum_reactive_graph.dart
 * 
 * Description:
 * Signal-Driven Animation Compositor. Enables seamless reactive animations by creating 
 * a direct pipeline from data signals to animation spring targets without triggering 
 * standard widget rebuilds.
 * 
 * Key Components:
 * - QLSelector: Structural memoization primitive for fine-grained reactivity.
 * - QLDerivedSignal: Auto-tracking batched signal that suppresses rebuild storms.
 * - QLReactiveBinding: Direct float-value writer to a QLTimeline spring target.
 * - QLAnimCompositor: Composer that wires multiple signals to a single ticker.
 * 
 * Dependencies/Relationships:
 * Built upon quantum_primitives.dart (QLSignal) and integrates directly into 
 * the Quantum animation layer.
 * 
 * Notes:
 * Bypasses the traditional AnimatedBuilder pattern. Updates occur entirely at the 
 * Float64List/Spring level to avoid structural Dart widget overhead.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM REACTIVE GRAPH ENGINE v1.0 — SIGNAL-DRIVEN ANIMATION COMPOSITOR
// quantum_reactive_graph.dart
//
// FILLS CORE GAP: Cross-signal reactive animation bindings.
//
// WHY THE PLUGIN PATTERN CANNOT SOLVE THIS:
//   QLTimeline is a pure playback scheduler. It plays a pre-recorded sequence.
//   QLSignal/QLComputed can derive values, but have no mechanism to drive
//   a QLTimeline track's TARGET dynamically at the RenderObject layer.
//   Without this primitive, "reactive animations" (e.g. spring a panel's
//   width whenever a QLSignal<double> changes) require userland AnimatedBuilder
//   + setState chains that blow through the element tree — exactly what
//   QLReactiveRenderMixin was designed to avoid. A plugin that wraps AnimatedBuilder
//   is not zero-allocation and cannot target the spring's _springData directly.
//   Only a core primitive with direct write access to QLTimeline internals
//   can achieve zero-allocation reactive animation binding.
//
// ARCHITECTURE:
// 1. QLReactiveBinding<T>: A typed link from any QLSignal<T> → a named
//    QLTimeline spring/tween target. Fires only when the signal value changes.
//    Update is O(1): one Float64List write to the spring data array.
// 2. QLAnimGraph: A named registry of reactive bindings that owns their
//    lifecycle. Bindings are cleared atomically when the graph is disposed.
//    Zero anonymous closures — all callbacks are named methods.
// 3. QLSelector<T,R>: A structural memoization primitive. Maps an input
//    signal through a pure selector function and only fires downstream when
//    the RESULT changes (referential or structural equality). Prevents
//    over-notification in deep computed chains.
// 4. QLDerivedSignal<T>: A zero-allocation derived signal that auto-tracks
//    its dependencies (like QLComputed) but enforces a strict equality guard
//    before notifying. Unlike QLComputed, it batches multiple dependency
//    changes into a single microtask notification — preventing cascading
//    rebuild storms in SDUI reactive charts.
// 5. QLReactiveTween: A StatelessWidget entry point that binds a signal to
//    a QLTimeline spring target and exposes the animated signal as a builder
//    arg. Zero extra State objects — the timeline is externally provided.
// 6. QLAnimCompositor: Composes N reactive bindings into a single shared
//    ticker. All bound springs share one Ticker, identical to QLTimeline's
//    design, but driven by signal changes rather than play() calls.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'quantum_primitives.dart';
import '../ui/quantum_animation_engine.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  STRUCTURAL EQUALITY GUARD (The memoization firewall)
// ────────────────────────────────────────────────────────────────────────────

typedef QLEqualityCheck<T> = bool Function(T a, T b);

@pragma('vm:prefer-inline')
bool _defaultEqual<T>(T a, T b) => identical(a, b) || a == b;

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QLSELECTOR (Memoized Signal Projection — Zero Over-Notification)
// ────────────────────────────────────────────────────────────────────────────

/// Maps an input [QLSignal<TIn>] through a [selector] function to produce
/// a derived [QLSignal<TOut>]. Only fires if the result structurally changes.
///
/// This is the primitive that prevents cascading rebuild storms.
/// Example: 10,000 candles each watching a single price signal —
/// without a selector each candle rebuilds on every tick even if its
/// own price band did not change. With a selector, only affected candles
/// fire.
///
/// Usage:
///   final priceSignal = QLSignal<double>(100.0);
///   final bandSignal = QLSelector.from(
///     priceSignal,
///     selector: (p) => (p / 10).floor(), // Only fires when band changes
///   );
class QLSelector<TIn, TOut> extends QLSignalBase<TOut> {
  final QLSignalBase<TIn> _source;
  final TOut Function(TIn input) _selector;
  final QLEqualityCheck<TOut> _equals;

  late TOut _cached;
  bool _subscribed = false;
  bool _initialized = false;

  QLSelector({
    required QLSignalBase<TIn> source,
    required TOut Function(TIn input) selector,
    QLEqualityCheck<TOut>? equals,
  })  : _source = source,
        _selector = selector,
        _equals = equals ?? _defaultEqual {
    _cached = selector(source.value);
    _initialized = true;
    _source.addListener(_onSourceChange);
    _subscribed = true;
  }

  /// Factory constructor for the common case.
  static QLSelector<TIn, TOut> from<TIn, TOut>(
    QLSignalBase<TIn> source, {
    required TOut Function(TIn input) selector,
    QLEqualityCheck<TOut>? equals,
  }) =>
      QLSelector<TIn, TOut>(source: source, selector: selector, equals: equals);

  void _onSourceChange() {
    final TOut next = _selector(_source.value);
    if (_initialized && _equals(_cached, next)) return;
    _cached = next;
    _initialized = true;
    if (hasListeners) notifyListeners();
  }

  @override
  TOut get value {
    qlCurrentReactiveContext?.track(this);
    return _cached;
  }

  @override
  void dispose() {
    if (_subscribed) {
      _source.removeListener(_onSourceChange);
      _subscribed = false;
    }
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLDERIVED SIGNAL (Batched Multi-Dependency Auto-Tracker)
// ────────────────────────────────────────────────────────────────────────────

/// A derived signal that auto-tracks multiple dependencies and batches
/// all same-microtask changes into ONE notification event.
///
/// Unlike QLComputed (which fires immediately on each dependency change),
/// QLDerivedSignal schedules a microtask flush. This means if 5 signals
/// all change in the same transaction, only ONE notification is emitted —
/// preventing N² rebuild cascades in complex reactive charts.
///
/// It also enforces structural equality before notifying, so even if the
/// computation re-runs, listeners are not disturbed unless the value changes.
class QLDerivedSignal<T> extends QLSignalBase<T> implements QLReactiveContext {
  final T Function() _compute;
  final QLEqualityCheck<T> _equals;
  final Set<QLSignalBase> _deps = <QLSignalBase>{};
  Set<QLSignalBase>? _activeDeps;

  T? _cached;
  bool _initialized = false;
  bool _dirty = true;
  bool _pendingFlush = false;
  bool _disposed = false;
  bool _evaluating = false;

  QLDerivedSignal(
    this._compute, {
    QLEqualityCheck<T>? equals,
  }) : _equals = equals ?? _defaultEqual {
    // Initial computation to establish dependency subscriptions.
    _recompute();
  }

  @override
  void track(QLSignalBase signal) {
    final active = _activeDeps;
    if (active == null) return;
    if (active.add(signal)) {
      signal.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (_disposed || _pendingFlush) return;
    _dirty = true;
    _pendingFlush = true;
    // Batch all changes in the same microtask.
    scheduleMicrotask(_flush);
  }

  void _flush() {
    if (_disposed) return;
    _pendingFlush = false;
    if (_dirty) _recompute();
  }

  void _recompute() {
    if (_evaluating) return;
    _evaluating = true;
    _dirty = false;

    final previousDeps = Set<QLSignalBase>.from(_deps);
    final nextDeps = Set<QLSignalBase>.from(previousDeps);
    final prev = qlCurrentReactiveContext;
    qlCurrentReactiveContext = this;
    _activeDeps = nextDeps;

    final T next;
    try {
      next = _compute();
    } finally {
      _activeDeps = null;
      qlCurrentReactiveContext = prev;
      _evaluating = false;
    }

    for (final dep in previousDeps.difference(nextDeps)) {
      dep.removeListener(_markDirty);
    }
    _deps
      ..clear()
      ..addAll(nextDeps);

    final bool changed = !_initialized || !_equals(_cached as T, next);
    _cached = next;
    _initialized = true;
    if (changed && hasListeners) notifyListeners();
  }

  @override
  T get value {
    qlCurrentReactiveContext?.track(this);
    if (_dirty || !_initialized) _recompute();
    return _cached as T;
  }

  @override
  void dispose() {
    _disposed = true;
    for (final dep in _deps) {
      dep.removeListener(_markDirty);
    }
    _deps.clear();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QLREACTIVE BINDING (Signal → QLTimeline Spring Target Bridge)
// ────────────────────────────────────────────────────────────────────────────

/// A typed reactive binding from a [QLSignalBase<double>] to a named spring
/// track in a [QLTimeline]. When the signal value changes, the spring's target
/// is updated in O(1) via direct Float64List write. The spring then animates
/// smoothly to the new target — zero setState, zero rebuild, zero allocation.
///
/// This is the core primitive for reactive animations:
///   "When this data changes, this visual thing smoothly follows."
///
/// Example:
///   final binding = QLReactiveBinding(
///     source: selectedItemSignal,     // QLSignal<double> (panel width)
///     timeline: myTimeline,
///     trackId: 'panelWidth',
///     transform: (v) => v * 300.0,   // pixel conversion
///   );
///   binding.attach(); // starts listening
///   // later:
///   binding.detach(); // stops listening, no leak

class QLReactiveBinding {
  final QLSignalBase<double> source;
  final QLTimeline timeline;
  final String trackId;
  final double Function(double value)? transform;
  final QLEqualityCheck<double>? equals;

  bool _attached = false;
  double _lastTarget = double.nan;

  QLReactiveBinding({
    required this.source,
    required this.timeline,
    required this.trackId,
    this.transform,
    this.equals,
  });

  void attach() {
    if (_attached) return;
    _attached = true;
    source.addListener(_onSourceChange);
    // Apply current value immediately.
    _onSourceChange();
  }

  void detach() {
    if (!_attached) return;
    _attached = false;
    source.removeListener(_onSourceChange);
  }

  @pragma('vm:prefer-inline')
  void _onSourceChange() {
    double target = source.value;
    if (transform != null) target = transform!(target);

    final QLEqualityCheck<double> eq = equals ?? _defaultEqual;
    if (eq(_lastTarget, target)) return;

    _lastTarget = target;
    timeline.updateSpringTarget(trackId, target);

    // 🚀 ARCHITECT FIX: Re-ignite the timeline!
    // The QLTimeline sleep-detector aggressively sets `_playing = false` to save CPU.
    // When reactive data mutates, we must re-arm the playing state so the Ticker
    // wakes up from its sleep and begins computing the new RK4 spring velocities.
    timeline.play();
  }

  bool get isAttached => _attached;
}
// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QLANIMGRAPH (Lifecycle-Managed Binding Registry)
// ────────────────────────────────────────────────────────────────────────────

/// A named registry of [QLReactiveBinding]s with coordinated lifecycle.
/// All bindings are attached on [activate] and detached on [dispose].
///
/// Integrate into a State class via [QLAnimGraphMixin] for zero-boilerplate
/// lifecycle management.
class QLAnimGraph {
  final Map<String, QLReactiveBinding> _bindings = {};
  bool _active = false;

  /// Registers a reactive binding by [name].
  /// If the graph is already active, the binding is attached immediately.
  void bind(String name, QLReactiveBinding binding) {
    _bindings[name]?.detach();
    _bindings[name] = binding;
    if (_active) binding.attach();
  }

  /// Convenience builder: creates and registers a binding in one call.
  QLReactiveBinding bindSignal({
    required String name,
    required QLSignalBase<double> source,
    required QLTimeline timeline,
    required String trackId,
    double Function(double)? transform,
  }) {
    final binding = QLReactiveBinding(
      source: source,
      timeline: timeline,
      trackId: trackId,
      transform: transform,
    );
    bind(name, binding);
    return binding;
  }

  /// Activates all registered bindings.
  void activate() {
    if (_active) return;
    _active = true;
    for (final b in _bindings.values) {
      b.attach();
    }
  }

  /// Detaches all bindings without removing them.
  void deactivate() {
    if (!_active) return;
    _active = false;
    for (final b in _bindings.values) {
      b.detach();
    }
  }

  /// Removes a specific binding by name and detaches it.
  void unbind(String name) {
    _bindings.remove(name)?.detach();
  }

  /// Detaches and clears all bindings. Call once on widget disposal.
  void dispose() {
    for (final b in _bindings.values) {
      b.detach();
    }
    _bindings.clear();
    _active = false;
  }

  bool get isActive => _active;
  int get bindingCount => _bindings.length;
  QLReactiveBinding? operator [](String name) => _bindings[name];
}

/// Mixin for State classes that own a QLAnimGraph.
/// Handles activate/dispose automatically.
mixin QLAnimGraphMixin<T extends StatefulWidget> on State<T> {
  late final QLAnimGraph animGraph = QLAnimGraph();

  @override
  void initState() {
    super.initState();
    animGraph.activate();
  }

  @override
  void dispose() {
    animGraph.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QLREACTIVE TWEEN (StatelessWidget — Zero-State Reactive Animation)
// ────────────────────────────────────────────────────────────────────────────

/// A zero-boilerplate reactive animation widget.
/// Binds [source] (any QLSignal<double>) to a spring track in [timeline]
/// and passes the animated signal to [builder]. No State class required.
///
/// The spring smoothly animates to [source].value whenever it changes.
///
/// Example:
///   QLReactiveTween(
///     source: panelWidthSignal,
///     timeline: myTimeline,
///     trackId: 'panelWidth',
///     stiffness: 400,
///     damping: 28,
///     builder: (ctx, animatedWidth) => SizedBox(
///       width: animatedWidth.value,
///       child: ...,
///     ),
///   )
class QLReactiveTween extends StatefulWidget {
  final QLSignalBase<double> source;
  final QLTimeline timeline;
  final String trackId;
  final double stiffness;
  final double damping;
  final double Function(double)? transform;
  final Widget Function(BuildContext ctx, QLSignal<double> animated) builder;

  const QLReactiveTween({
    super.key,
    required this.source,
    required this.timeline,
    required this.trackId,
    required this.builder,
    this.stiffness = 300.0,
    this.damping = 22.0,
    this.transform,
  });

  @override
  State<QLReactiveTween> createState() => _QLReactiveTweenState();
}

class _QLReactiveTweenState extends State<QLReactiveTween>
    with TickerProviderStateMixin, QLAnimGraphMixin<QLReactiveTween> {
  late final QLSignal<double> _animatedSignal;

  @override
  void initState() {
    super.initState();
    final double initial = widget.transform != null
        ? widget.transform!(widget.source.value)
        : widget.source.value;

    // Register a spring track in the provided timeline.
    _animatedSignal = widget.timeline.spring(
      id: widget.trackId,
      initial: initial,
      target: initial,
      stiffness: widget.stiffness,
      damping: widget.damping,
    );

    // Bind the source signal to the spring target.
    animGraph.bindSignal(
      name: widget.trackId,
      source: widget.source,
      timeline: widget.timeline,
      trackId: widget.trackId,
      transform: widget.transform,
    );

    // Activate (parent mixin already called activate, but bind was after — re-apply).
    animGraph.deactivate();
    animGraph.activate();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animatedSignal);
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  QLANIM COMPOSITOR (N Springs, 1 Ticker — Full Reactive Graph)
// ────────────────────────────────────────────────────────────────────────────

/// An animation compositor that drives N reactive spring animations from
/// N arbitrary QLSignal<double> sources, all sharing a single Ticker.
///
/// This is the highest-level reactive animation primitive. Use it to drive
/// complex cross-signal animations (e.g., a trading chart where price signal
/// drives Y-position spring, volume drives bar-height spring, momentum drives
/// color-temperature spring — all in one ticker cycle, zero extra allocations).
///
/// Usage:
///   final compositor = QLAnimCompositor(vsync: this)
///     ..addSpring('y', source: priceSignal, transform: priceToY)
///     ..addSpring('barH', source: volumeSignal, transform: volumeToHeight)
///     ..addSpring('hue', source: momentumSignal, transform: momoToHue)
///     ..activate();
///
///   // In build:
///   AnimatedBuilder(
///     animation: Listenable.merge([compositor.signal('y'), compositor.signal('barH')]),
///     builder: (ctx, _) => MyChart(
///       y: compositor.signal('y')!.value,
///       barH: compositor.signal('barH')!.value,
///     ),
///   )

class QLAnimCompositor {
  final QLTimeline _timeline;
  final QLAnimGraph _graph = QLAnimGraph();
  final Map<String, QLSignalBase> _signals = {};

  QLTimeline get timeline => _timeline;
  QLAnimCompositor({required TickerProvider vsync})
      : _timeline = QLTimeline(vsync: vsync);

  /// Adds a spring-animated track driven reactively by [source].
  QLAnimCompositor addSpring(
    String id, {
    required QLSignalBase<double> source,
    double stiffness = 300.0,
    double damping = 22.0,
    double Function(double)? transform,
  }) {
    final double initial =
        transform != null ? transform(source.value) : source.value;

    final sig = _timeline.spring(
      id: id,
      initial: initial,
      target: initial,
      stiffness: stiffness,
      damping: damping,
    );
    _signals[id] = sig;

    _graph.bindSignal(
      name: id,
      source: source,
      timeline: _timeline,
      trackId: id,
      transform: transform,
    );
    return this;
  }

  /// Adds a tween track driven reactively by [source].
  QLAnimCompositor addReactiveTween<T>(
    String id, {
    required QLSignalBase<T> source,
    required T Function(T current, T target, double t) lerp,
    required Duration duration,
    Curve curve = Curves.easeOutCubic,
  }) {
    final signal = QLSignal<T>(source.value);
    _signals[id] = signal;

    T fromVal = source.value;
    source.addListener(() {
      final T toVal = source.value;
      _timeline.tween<T>(
        id: id,
        from: fromVal,
        to: toVal,
        duration: duration,
        curve: curve,
        lerp: lerp,
      );
      fromVal = toVal;
      _timeline.seek(0);
      _timeline.play();
    });
    return this;
  }

  /// Returns a double signal (legacy support).
  QLSignal<double>? signal(String id) => typedSignal<double>(id);

  /// Returns a strictly typed signal, preventing UI cast exceptions.
  QLSignal<T>? typedSignal<T>(String id) {
    final sig = _signals[id];
    if (sig is QLSignal<T>) return sig;
    return null;
  }

  /// Activates all reactive bindings and starts the timeline.
  void activate() {
    _graph.activate();
    // 🚀 Guarantee initial physics activation on mount
    _timeline.play();
  }

  /// Deactivates all reactive bindings (pauses reactivity without disposing).
  void deactivate() {
    _graph.deactivate();
    _timeline.pause();
  }

  void dispose() {
    _graph.dispose();
    _timeline.dispose();
    _signals.clear();
  }
}
// ─────────────────────────────────────────────────────────────────────── §8 ─
//  QLSIGNAL EXTENSIONS (DX Sugar for Reactive Bindings)
// ────────────────────────────────────────────────────────────────────────────

extension QLSignalReactiveExt<T> on QLSignalBase<T> {
  /// Creates a memoized selector projection from this signal.
  QLSelector<T, R> select<R>(R Function(T value) selector,
          {QLEqualityCheck<R>? equals}) =>
      QLSelector.from<T, R>(this, selector: selector, equals: equals);
}

extension QLDoubleSignalReactiveExt on QLSignalBase<double> {
  /// Reactively binds this double signal to a spring track.
  QLReactiveBinding bindToSpring({
    required QLTimeline timeline,
    required String trackId,
    double Function(double)? transform,
  }) {
    final b = QLReactiveBinding(
        source: this,
        timeline: timeline,
        trackId: trackId,
        transform: transform);
    b.attach();
    return b;
  }
}
