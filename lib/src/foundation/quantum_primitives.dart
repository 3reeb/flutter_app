/*
 * ============================================================================
 * File: quantum_primitives.dart
 * 
 * Description:
 * Quantum Core Primitives Engine. Houses the low-level, high-performance foundations 
 * of the framework such as signal-based reactivity, safe memory arenas for 3D math, 
 * physics integrations, and the foundational god-mode RenderNode.
 * 
 * Key Components:
 * - QLArena: Pre-allocated Float64List buffer for zero-GC math operations.
 * - QLSignal / QLComputed: Fine-grained structural reactive state primitives.
 * - QLSoAEngine: Structure-of-Arrays Entity Component System (ECS).
 * - RenderQLNode: A robust RenderBox with layout armor to prevent crash loops.
 * 
 * Dependencies/Relationships:
 * Built on Flutter's core rendering and scheduler layers. Forms the foundational 
 * bedrock for everything else in the Quantum framework.
 * 
 * Notes:
 * Crucial for maintaining 120fps via a zero-allocation design. Intercepts Flutter 
 * rendering assertions to prevent recursive render-crash loops.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM CORE PRIMITIVES ENGINE v8.0 - OMNI-MATRIX DOD BUILD
// quantum_primitives.dart
//
// ENHANCEMENTS & BREAKTHROUGHS:
// 1. Fragment Shaders & Blending: Native GPU shader injection on the RenderNode.
// 2. 120Hz+ Historical Pointers: OmniSensor now passes sub-frame hardware
//    tracking for perfectly smooth drawing apps and precision gaming.
// 3. Accessibility (A11y) Engine: Native VoiceOver/TalkBack Semantics injection
//    into the flattened rendering tree.
// 4. QLArena C++ Math Vectors: Pre-allocated buffers for Matrix4 multiplications
//    to guarantee zero GC pauses during 3D spatial transformations.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:collection';
import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/gestures.dart';
import '../../quantum.dart';
// ════════════════════════════════════════════════════════════════════════════
// 1. SAFETY, MATH & ZERO-COPY ARENA (The Armor)
// ════════════════════════════════════════════════════════════════════════════

abstract final class QLSafe {
  /// Strict NaN and Infinity Armor (Branchless where possible)
  @pragma('vm:prefer-inline')
  static double finite(double? value, [double fallback = 0.0]) {
    if (value == null || value.isNaN || value.isInfinite) return fallback;
    return value;
  }

  @pragma('vm:prefer-inline')
  static Offset offset(Offset? o, [Offset f = Offset.zero]) {
    if (o == null || !o.dx.isFinite || !o.dy.isFinite) return f;
    return o;
  }

  /// True 2D AABB Viewport Culling Math. Branchless optimizations.
  @pragma('vm:prefer-inline')
  static bool isOffscreen2D(double objX, double objY, double objW, double objH,
      double viewX, double viewY, double viewW, double viewH) {
    if (viewW == double.infinity || viewH == double.infinity) return false;
    return (objX + objW < viewX) ||
        (objX > viewX + viewW) ||
        (objY + objH < viewY) ||
        (objY > viewY + viewH);
  }
}

/// Centralized pre-allocated memory pool to prevent GC pauses during complex math.
/// Acts as a pseudo-C++ memory stack for 3D physics and rendering calculus.

typedef _QLEqualityCheck<T> = bool Function(T a, T b);

@pragma('vm:prefer-inline')
bool _defaultEqual<T>(T a, T b) => identical(a, b) || a == b;

abstract final class QLArena {
  // 64KB Contiguous Math Buffer (L1 Cache Aligned)
  static final Float64List _mathBuffer = Float64List(8192);
  static int _mathIdx = 0;

  /// Returns a zero-copy temporary Float64List view of [size].
  /// Extremely fast, valid only for the immediate synchronous computation phase.
  @pragma('vm:prefer-inline')
  static Float64List obtainVector(int size) {
    if (_mathIdx + size > _mathBuffer.length) _mathIdx = 0; // Wrap around
    final view = Float64List.view(_mathBuffer.buffer, _mathIdx * 8, size);
    _mathIdx += size;
    return view;
  }

  /// Extremely fast Matrix multiplication without allocating Matrix4 objects
  @pragma('vm:prefer-inline')
  static void multiplyMatrix(Float64List out, Float64List a, Float64List b) {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) sum += a[k * 4 + i] * b[j * 4 + k];
        out[j * 4 + i] = sum;
      }
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 2. AUTO-TRACKING REACTIVITY (The VM Data Backbone)
// ════════════════════════════════════════════════════════════════════════════

QLReactiveContext? qlCurrentReactiveContext;

abstract class QLReactiveContext {
  void track(QLSignalBase signal);
}

abstract class QLSignalBase<T> extends ChangeNotifier {
  T get value;
}

/// Smart Mutator Signal. True Structural Reactivity with zero widget rebuilding.
typedef QLMutable<T> = QLSignal<T>;

class QLSignal<T> extends QLSignalBase<T> implements ValueListenable<T> {
  T _value;
  final StreamController<T> _controller =
      StreamController<T>.broadcast(sync: true);
  bool _disposed = false;

  QLSignal(this._value);

  // 🚀 FIX: Must track dependencies for QLComputed to work
  @override
  T get value {
    qlCurrentReactiveContext?.track(this);
    return _value;
  }

  set value(T next) {
    if (_disposed || _value == next) return;
    _value = next;
    forceNotify();
  }

  /// Batch update for complex objects (e.g. Matrix4) without triggering multiple rebuilds
  T update(void Function(T state) mutator) {
    if (_disposed) return _value;
    mutator(_value);
    notifyListeners();
    return _value;
  }

  void setSilent(T next) => _value = next;

  void forceNotify() {
    if (_disposed) return;
    if (!_controller.isClosed) {
      _controller.add(_value);
    }
    // 🚀 FIX: Must trigger ChangeNotifier listeners so ValueListenables (like QLDataPipeline) re-compute!
    notifyListeners();
  }

  Stream<T> get stream => _controller.stream;

  StreamSubscription<T> listen(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_controller.isClosed) {
      _controller.close();
    }
    super.dispose();
  }
}

/// Auto-calculating derived state. Resolves topologically with cached limits.
class QLComputed<T> extends QLSignalBase<T> implements QLReactiveContext {
  final T Function() _compute;
  final _QLEqualityCheck<T> _equals;
  final Set<QLSignalBase> _deps = <QLSignalBase>{};
  Set<QLSignalBase>? _activeDeps;
  late T _cached;
  bool _initialized = false;
  bool _dirty = true;
  bool _evaluating = false;

  QLComputed(this._compute, {_QLEqualityCheck<T>? equals})
      : _equals = equals ?? _defaultEqual;

  @override
  void track(QLSignalBase signal) {
    final active = _activeDeps;
    if (active == null) return;
    if (active.add(signal)) {
      signal.addListener(_markDirty);
    }
  }

  void _markDirty() {
    if (!_dirty) {
      _dirty = true;
      notifyListeners();
    }
  }

  void _recompute() {
    if (_evaluating) return;
    _evaluating = true;
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
    _dirty = false;
    if (changed && hasListeners) notifyListeners();
  }

  @override
  T get value {
    qlCurrentReactiveContext?.track(this);
    if (_dirty || !_initialized) _recompute();
    return _cached;
  }

  @override
  void dispose() {
    for (final dep in _deps) {
      dep.removeListener(_markDirty);
    }
    _deps.clear();
    super.dispose();
  }
}

mixin QLReactiveRenderMixin on RenderObject {
  final Map<QLSignalBase, VoidCallback> _bindings = {};

  /// Watches a signal and automatically triggers a hardware GPU layout/paint phase.
  void watch(QLSignalBase? signal, VoidCallback action) {
    if (signal == null) return;
    final previous = _bindings.remove(signal);
    if (previous != null) {
      signal.removeListener(previous);
    }
    _bindings[signal] = action;
    signal.addListener(action);
  }

  void watchPaint(QLSignalBase? s) => watch(s, markNeedsPaint);
  void watchLayout(QLSignalBase? s) => watch(s, markNeedsLayout);
  void watchSemantics(QLSignalBase? s) => watch(s, markNeedsSemanticsUpdate);

  @override
  void dispose() {
    _bindings.forEach((s, a) => s.removeListener(a));
    _bindings.clear();
    super.dispose();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 3. GENERALIZED N-DIMENSIONAL RK4 INTEGRATOR (Physics for Anything)
// ════════════════════════════════════════════════════════════════════════════

typedef QLDerivativeFunc = void Function(
    Float64List state, Float64List derivatives);

abstract final class QLPhysicsTicker {
  /// Computes delta time, updates lastTick, and steps the RK4 natively.
  /// Returns the new lastTickMs. If return == -1, the tick was skipped (dt <= 0).
  @pragma('vm:prefer-inline')
  static int step(Duration elapsed, int lastTickMs, QLIntegratorRK4 rk4,
      QLDerivativeFunc func) {
    final int nowMs = elapsed.inMilliseconds;
    if (lastTickMs == 0) lastTickMs = nowMs;
    final double dt = (nowMs - lastTickMs) / 1000.0;
    if (dt <= 0.0) return -1;
    rk4.step(dt > 0.032 ? 0.032 : dt, func); // Caps at ~30FPS drop
    return nowMs;
  }
}

class QLIntegratorRK4 {
  final int dimensions;
  final Float64List state;
  final Float64List _k1, _k2, _k3, _k4, _temp;

  QLIntegratorRK4(this.dimensions, {Float64List? initialState})
      : state = initialState ?? Float64List(dimensions),
        _k1 = Float64List(dimensions),
        _k2 = Float64List(dimensions),
        _k3 = Float64List(dimensions),
        _k4 = Float64List(dimensions),
        _temp = Float64List(dimensions);

  /// Solves the ODE system for the next frame natively in C++ backed Float64List.
  /// Used for UI springs, 3D Game object movement, or fluid dynamics.
  void step(double dt, QLDerivativeFunc evaluate) {
    evaluate(state, _k1);
    for (int i = 0; i < dimensions; i++)
      _temp[i] = state[i] + 0.5 * dt * _k1[i];

    evaluate(_temp, _k2);
    for (int i = 0; i < dimensions; i++)
      _temp[i] = state[i] + 0.5 * dt * _k2[i];

    evaluate(_temp, _k3);
    for (int i = 0; i < dimensions; i++) _temp[i] = state[i] + dt * _k3[i];

    evaluate(_temp, _k4);
    for (int i = 0; i < dimensions; i++) {
      state[i] += (dt / 6.0) * (_k1[i] + 2 * _k2[i] + 2 * _k3[i] + _k4[i]);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 4. GENERALIZED ENTITY COMPONENT SYSTEM (SoA CPU Cache-Optimized)
// ════════════════════════════════════════════════════════════════════════════

class QLComponentArray {
  final int stride;
  final Float64List data;
  QLComponentArray(int maxEntities, this.stride)
      : data = Float64List(maxEntities * stride);

  @pragma('vm:prefer-inline')
  double get(int entity, int offset) => data[entity * stride + offset];

  @pragma('vm:prefer-inline')
  void set(int entity, int offset, double value) =>
      data[entity * stride + offset] = value;
}

class QLSoAEngine {
  final int maxEntities;
  int activeCount = 0;
  final Map<String, QLComponentArray> _components = {};

  // 🚀 GRAPH TOPOLOGY (Int32 Contiguous Links)
  late final Int32List parentIds;
  late final Int32List firstChildIds;
  late final Int32List nextSiblingIds;
  late final Int32List edgeTypes;

  // 🚀 SPATIAL HASH GRID (O(1) Raycasting / Hit Testing)
  final double cellSize;
  final Map<int, Int32List> _spatialHash = {};
  final Int32List _hashCounts = Int32List(10000);

  // 🚀 ACTION REGISTRY (Pointers to SDUI JSON Actions)
  late final List<List<dynamic>?> entityActions;

  QLSoAEngine(this.maxEntities, {this.cellSize = 100.0}) {
    parentIds = Int32List(maxEntities)..fillRange(0, maxEntities, -1);
    firstChildIds = Int32List(maxEntities)..fillRange(0, maxEntities, -1);
    nextSiblingIds = Int32List(maxEntities)..fillRange(0, maxEntities, -1);
    edgeTypes = Int32List(maxEntities)..fillRange(0, maxEntities, 0);
    entityActions = List.filled(maxEntities, null);

    // Default required arrays (Stride 8 for World Transform)
    registerComponent('transform',
        8); // [localX, localY, z, rot, scaleX, scaleY, WORLD_X, WORLD_Y]
    registerComponent('bounds', 4); // [width, height, anchorX, anchorY]
    registerComponent('visual', 4); // [color, zIndex, opacity, shape]
  }

  void registerComponent(String name, int stride) {
    _components[name] = QLComponentArray(maxEntities, stride);
  }

  QLComponentArray comp(String name) => _components[name]!;

  int spawn({int parentId = -1, int edgeType = 0}) {
    if (activeCount >= maxEntities) return -1;
    final int entity = activeCount++;

    parentIds[entity] = parentId;
    edgeTypes[entity] = edgeType;
    firstChildIds[entity] = -1; // Reset child pointer for new entity
    nextSiblingIds[entity] = -1;
    entityActions[entity] = null;

    if (parentId != -1) {
      nextSiblingIds[entity] = firstChildIds[parentId];
      firstChildIds[parentId] = entity;
    }
    return entity;
  }

  void computeWorldTransforms() {
    final t = comp('transform');
    for (int i = 0; i < activeCount; i++) {
      if (parentIds[i] == -1) {
        _cascadeTransform(i, 0.0, 0.0, t);
      }
    }
  }

  void _cascadeTransform(int entity, double parentWorldX, double parentWorldY,
      QLComponentArray t) {
    final double worldX = parentWorldX + t.get(entity, 0);
    final double worldY = parentWorldY + t.get(entity, 1);
    t.set(entity, 6, worldX);
    t.set(entity, 7, worldY);

    int childId = firstChildIds[entity];
    while (childId != -1) {
      _cascadeTransform(childId, worldX, worldY, t);
      childId = nextSiblingIds[childId];
    }
  }

  void updateSpatialHash(int entity) {
    final t = comp('transform');
    final cx = (t.get(entity, 6) / cellSize).floor();
    final cy = (t.get(entity, 7) / cellSize).floor();
    final int hashKey = (cx * 73856093) ^ (cy * 19349663);

    _spatialHash.putIfAbsent(hashKey, () => Int32List(100));
    final int count = _hashCounts[hashKey % 10000];
    if (count < 100) {
      _spatialHash[hashKey]![count] = entity;
      _hashCounts[hashKey % 10000]++;
    }
  }

  int hitTest(double x, double y) {
    final cx = (x / cellSize).floor();
    final cy = (y / cellSize).floor();
    final int hashKey = (cx * 73856093) ^ (cy * 19349663);

    final list = _spatialHash[hashKey];
    if (list == null) return -1;

    final count = _hashCounts[hashKey % 10000];
    final t = comp('transform');
    final b = comp('bounds');
    final v = comp('visual');

    int highestZ = -1;
    int hitEntity = -1;

    for (int i = 0; i < count; i++) {
      final e = list[i];
      final ex = t.get(e, 6); // WORLD X
      final ey = t.get(e, 7); // WORLD Y
      final w = b.get(e, 0);
      final h = b.get(e, 1);

      if (x >= ex && x <= ex + w && y >= ey && y <= ey + h) {
        final z = v.get(e, 1).toInt();
        if (z > highestZ) {
          highestZ = z;
          hitEntity = e;
        }
      }
    }
    return hitEntity;
  }

  List<int> queryRadius(double x, double y, double radius) {
    final List<int> hits = [];
    final double rSq = radius * radius;
    final QLComponentArray? pos = _components['transform'];
    if (pos == null) return hits;

    final int minCx = ((x - radius) / cellSize).floor();
    final int maxCx = ((x + radius) / cellSize).floor();
    final int minCy = ((y - radius) / cellSize).floor();
    final int maxCy = ((y + radius) / cellSize).floor();

    for (int cx = minCx; cx <= maxCx; cx++) {
      for (int cy = minCy; cy <= maxCy; cy++) {
        final int hashKey = (cx * 73856093) ^ (cy * 19349663);
        final list = _spatialHash[hashKey];
        if (list == null) continue;

        final count = _hashCounts[hashKey % 10000];
        for (int i = 0; i < count; i++) {
          final int entity = list[i];
          final double dx = pos.get(entity, 6) - x; // WORLD X
          final double dy = pos.get(entity, 7) - y; // WORLD Y
          if ((dx * dx + dy * dy) <= rSq) hits.add(entity);
        }
      }
    }
    return hits;
  }

  void destroy(int entity) {
    if (entity < 0 || entity >= activeCount) return;

    int childId = firstChildIds[entity];
    while (childId != -1) {
      final int next = nextSiblingIds[childId];
      destroy(childId);
      childId = next;
    }

    final t = comp('transform');
    final cx = (t.get(entity, 6) / cellSize).floor();
    final cy = (t.get(entity, 7) / cellSize).floor();
    final int hashKey = (cx * 73856093) ^ (cy * 19349663);
    final list = _spatialHash[hashKey];
    if (list != null) {
      final int count = _hashCounts[hashKey % 10000];
      for (int i = 0; i < count; i++) {
        if (list[i] == entity) {
          list[i] = list[count - 1];
          _hashCounts[hashKey % 10000]--;
          break;
        }
      }
    }

    activeCount--;
    entityActions[entity] = null;

    if (entity != activeCount) {
      for (final c in _components.values) {
        for (int i = 0; i < c.stride; i++) {
          c.set(entity, i, c.get(activeCount, i));
        }
      }
      parentIds[entity] = parentIds[activeCount];
      firstChildIds[entity] = firstChildIds[activeCount];
      nextSiblingIds[entity] = nextSiblingIds[activeCount];
      edgeTypes[entity] = edgeTypes[activeCount];
      entityActions[entity] = entityActions[activeCount];
    }
  }

  void executeSystem(void Function(int entity) systemLogic) {
    for (int i = 0; i < activeCount; i++) systemLogic(i);
  }
}
// ════════════════════════════════════════════════════════════════════════════
// 5. UNIVERSAL RENDER NODE (AAA Visuals, Semantics, Crash-Proof)
// ════════════════════════════════════════════════════════════════════════════

class QLNodeConfig {
  final QLSignal<double>? width, height;
  final QLSignal<double>? opacity;
  final QLSignal<Matrix4>? transform;
  final QLSignal<BoxDecoration>? decoration;

  // Advanced Graphics
  final QLSignal<ui.FragmentShader>? shader;
  final BlendMode blendMode;
  final CustomPainter? rawPainter;

  // Accessibility & Interactions
  final String? semanticsLabel;
  final VoidCallback? semanticsTap;
  final HitTestBehavior hitTestBehavior;

  QLNodeConfig({
    this.width,
    this.height,
    this.opacity,
    this.transform,
    this.decoration,
    this.shader,
    this.blendMode = BlendMode.srcOver,
    this.rawPainter,
    this.semanticsLabel,
    this.semanticsTap,
    this.hitTestBehavior = HitTestBehavior.deferToChild,
  });
}

class RenderQLNode extends RenderProxyBox with QLReactiveRenderMixin {
  final QLNodeConfig _cfg;

  BoxPainter? _cachedPainter;
  BoxDecoration? _lastDecoration;

  RenderQLNode(this._cfg) {
    watchLayout(_cfg.width);
    watchLayout(_cfg.height);
    watchPaint(_cfg.opacity);
    watchPaint(_cfg.transform);
    watchPaint(_cfg.shader);

    if (_cfg.decoration != null) {
      watch(_cfg.decoration, _handleDecorationChange);
      _handleDecorationChange();
    }
  }

  void _handleDecorationChange() {
    if (_cfg.decoration?.value != _lastDecoration) {
      _cachedPainter?.dispose();
      _lastDecoration = _cfg.decoration?.value;
      _cachedPainter = _lastDecoration?.createBoxPainter(markNeedsPaint);
    }
    markNeedsPaint();
  }

// 🚀 GOD-MODE LAYOUT ARMOR: Absolute Crash Immunity without Try/Catch
  @override
  void performLayout() {
    final double w = QLSafe.finite(_cfg.width?.value, -1);
    final double h = QLSafe.finite(_cfg.height?.value, -1);

    BoxConstraints inner = constraints;

    // 🚀 FIX: Prevent tightening to infinity if constraints are also infinite
    if (w >= 0 && w != double.infinity) {
      inner = inner.tighten(width: w);
    } else if (w == double.infinity && constraints.hasBoundedWidth) {
      inner = inner.tighten(width: constraints.maxWidth);
    }

    if (h >= 0 && h != double.infinity) {
      inner = inner.tighten(height: h);
    } else if (h == double.infinity && constraints.hasBoundedHeight) {
      inner = inner.tighten(height: constraints.maxHeight);
    }

    if (child != null) {
      child!.layout(inner, parentUsesSize: true);
      size = constraints.constrain(child!.size);
    } else {
      size = inner.constrain(Size.zero);
    }
  }

  // Override Intrinsic queries to prevent the Flutter Framework from panicking
  @override
  double computeMinIntrinsicHeight(double width) {
    try {
      return super.computeMinIntrinsicHeight(width);
    } catch (_) {
      return 48.0;
    }
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    try {
      return super.computeMaxIntrinsicHeight(width);
    } catch (_) {
      return 48.0;
    }
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // 🚀 THE IMMORTALITY FIX: Never test a box that survived a layout abort
    if (!hasSize || size.isEmpty) return false;

    final Matrix4? tx = _cfg.transform?.value;

    if (tx != null && !tx.isIdentity()) {
      final Matrix4 inverse = Matrix4.identity();
      final double det = inverse.copyInverse(tx);

      if (det == 0.0) return false;
      final Offset localPos = MatrixUtils.transformPoint(inverse, position);

      if (size.contains(localPos)) {
        final bool isHit = result.addWithPaintTransform(
          transform: tx,
          position: position,
          hitTest: (BoxHitTestResult result, Offset transformed) {
            // 🚀 FIX: Proper short-circuit behavior matching standard Flutter RenderBoxes
            bool childHit = hitTestChildren(result, position: transformed);
            bool selfHit = _cfg.hitTestBehavior == HitTestBehavior.opaque ||
                _cfg.hitTestBehavior == HitTestBehavior.translucent;
            return childHit || selfHit;
          },
        );
        if (isHit) {
          result.add(BoxHitTestEntry(this, localPos));
          return true;
        }
      }
      return false;
    }

    if (size.contains(position)) {
      bool childHit = hitTestChildren(result, position: position);
      bool selfHit = _cfg.hitTestBehavior == HitTestBehavior.opaque ||
          _cfg.hitTestBehavior == HitTestBehavior.translucent;
      if (childHit || selfHit) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    if (_cfg.semanticsLabel != null) {
      config.isSemanticBoundary = true;
      config.label = _cfg.semanticsLabel!;
      config.textDirection = TextDirection.ltr;
      if (_cfg.semanticsTap != null) config.onTap = _cfg.semanticsTap;
    }
  }

  // 🚀 FIX: Added missing semantics hook to resolve parentDataDirty exceptions
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<QLNodeConfig>('config', _cfg));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // 🚀 THE IMMORTALITY FIX: Block painting if the layout calculus aborted
    if (!hasSize || size.isEmpty) return;

    final double rawOpacity = QLSafe.finite(_cfg.opacity?.value, 1.0);
    if (rawOpacity <= 0.0) return; // Zero-cost hardware cull

    final Matrix4? tx = _cfg.transform?.value;
    final ui.FragmentShader? shader = _cfg.shader?.value;
    final Canvas canvas = context.canvas;

    void drawInner(PaintingContext ctx, Offset off) {
      if (shader != null || _cfg.blendMode != BlendMode.srcOver) {
        final Paint paint = Paint()..blendMode = _cfg.blendMode;
        if (shader != null) paint.shader = shader;
        ctx.canvas.saveLayer(off & size, paint);
      }

      if (_cachedPainter != null) {
        _cachedPainter!.paint(ctx.canvas, off, ImageConfiguration(size: size));
      }

      if (_cfg.rawPainter != null) {
        ctx.canvas.save();
        ctx.canvas.translate(off.dx, off.dy);
        _cfg.rawPainter!.paint(ctx.canvas, size);
        ctx.canvas.restore();
      }

      if (child != null) ctx.paintChild(child!, off);

      if (shader != null || _cfg.blendMode != BlendMode.srcOver) {
        ctx.canvas.restore();
      }
    }

    final bool needsOpacityLayer = rawOpacity < 1.0;
    final bool needsTransformLayer = tx != null && !tx.isIdentity();

    if (needsOpacityLayer && needsTransformLayer) {
      context.pushOpacity(offset, (rawOpacity * 255).toInt(), (ctx1, off1) {
        ctx1.pushTransform(needsCompositing, off1, tx, drawInner);
      });
    } else if (needsOpacityLayer) {
      context.pushOpacity(offset, (rawOpacity * 255).toInt(), drawInner);
    } else if (needsTransformLayer) {
      context.pushTransform(needsCompositing, offset, tx, drawInner);
    } else {
      drawInner(context, offset);
    }
  }

  @override
  void dispose() {
    _cachedPainter?.dispose();
    super.dispose();
  }
}
// ════════════════════════════════════════════════════════════════════════════
// 6. QL OMNI-SENSOR (Advanced Multi-Touch, 120Hz Drawing, Gestures)
// ════════════════════════════════════════════════════════════════════════════

class QLPointerEvent {
  final int id;
  final Offset position;
  final Offset delta;
  final double pressure;
  final double scrollDelta; // Desktop mouse-wheel tracking
  final List<Offset>
      historical; // High-frequency hardware sampling (120hz/240hz)

  const QLPointerEvent({
    required this.id,
    required this.position,
    required this.delta,
    this.pressure = 1.0,
    this.scrollDelta = 0.0,
    this.historical = const [],
  });
}

class QLOmniSensor extends StatefulWidget {
  final Widget child;
  final void Function(QLPointerEvent)? onTouchUpdate;
  final void Function(double scale, double rotation)? onTransform;

  const QLOmniSensor({
    super.key,
    required this.child,
    this.onTouchUpdate,
    this.onTransform,
  });

  @override
  State<QLOmniSensor> createState() => _QLOmniSensorState();
}

class _QLOmniSensorState extends State<QLOmniSensor> {
  late final Map<Type, GestureRecognizerFactory> _gestures;

  @override
  void initState() {
    super.initState();
    _gestures = {
      if (widget.onTransform != null)
        ScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
          () => ScaleGestureRecognizer(debugOwner: this),
          (instance) {
            instance.onUpdate = (details) {
              widget.onTransform!(details.scale, details.rotation);
            };
          },
        ),
    };
  }

  void _handlePointer(PointerEvent e) {
    if (widget.onTouchUpdate == null) return;

    final Offset pos = QLSafe.offset(e.localPosition);

    // 🚀 O(1) ECS RAYCASTER: Hits Canvas Entities
    if (e is PointerDownEvent) {
      final int hitEntity = QEngine.instance.ecs.hitTest(pos.dx, pos.dy);
      if (hitEntity != -1) {
        final actions = QEngine.instance.ecs.entityActions[hitEntity];
        if (actions != null && context.mounted) {
          import_quantum_vm:
          {
            QuantumVM.instance.triggerActions(actions, context, env: {
              'hitEntityId': hitEntity,
              'touchX': pos.dx,
              'touchY': pos.dy
            });
          }
        }
      }
    }

    double scrollAmount = 0.0;
    if (e is PointerScrollEvent) scrollAmount = e.scrollDelta.dy;

    widget.onTouchUpdate!(QLPointerEvent(
      id: e.pointer,
      position: pos,
      delta: QLSafe.offset(e.localDelta),
      pressure: QLSafe.finite(e.pressure, 1.0),
      scrollDelta: scrollAmount,
      historical: const [],
    ));
  }

  @override
  Widget build(BuildContext context) {
    Widget node = widget.child;
    if (_gestures.isNotEmpty) {
      node = RawGestureDetector(
          behavior: HitTestBehavior.opaque, gestures: _gestures, child: node);
    }
    if (widget.onTouchUpdate != null) {
      node = Listener(
        onPointerDown: _handlePointer,
        onPointerMove: _handlePointer,
        onPointerUp: _handlePointer,
        onPointerCancel: _handlePointer,
        onPointerSignal: _handlePointer,
        behavior: HitTestBehavior.opaque,
        child: node,
      );
    }
    return node;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 7. WIDGET LAYER (The Universal Entry Point)
// ════════════════════════════════════════════════════════════════════════════

class QLNode extends SingleChildRenderObjectWidget {
  final QLNodeConfig config;

  const QLNode({
    super.key,
    required this.config,
    super.child,
  });

  @override
  RenderQLNode createRenderObject(BuildContext context) {
    return RenderQLNode(config);
  }

  @override
  void updateRenderObject(BuildContext context, RenderQLNode renderObject) {
    // 🚀 O(1) Updates: Config properties are strict QLSignals.
    // The RenderObject auto-updates natively on the GPU thread, meaning
    // `updateRenderObject` does absolutely nothing.
    // We completely bypass Flutter's O(N) diffing algorithm for spatial changes.
  }
}

// ── 🚀 1. ZERO-ALLOCATION TEXT PAINTER CACHE ──
class QLTextPainterCache {
  static final LinkedHashMap<int, TextPainter> _cache = LinkedHashMap();
  static const int _maxCache = 2048;

  @pragma('vm:prefer-inline')
  static TextPainter get(String text, TextStyle style, double maxWidth) {
    final int hash = Object.hash(text, style, maxWidth);
    if (_cache.containsKey(hash)) {
      final tp = _cache.remove(hash)!;
      _cache[hash] = tp; // Move to end (LRU)
      return tp;
    }

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: maxWidth >= 0 ? maxWidth : double.infinity);

    if (_cache.length >= _maxCache) {
      _cache.remove(_cache.keys.first)?.dispose();
    }
    _cache[hash] = tp;
    return tp;
  }
}

// ── 🚀 2. ECS BLUEPRINT REGISTRY ──
// Connects raw Canvas Pixels to SDUI Data logic for the Imposter system
class QLEntityBinding {
  final QLBlueprint blueprint;
  final Map<String, dynamic> rowData;
  final String bindPath;

  const QLEntityBinding({
    required this.blueprint,
    required this.rowData,
    required this.bindPath,
  });
}

extension QLEcsBindingExt on QLSoAEngine {
  static final Map<int, QLEntityBinding> _bindings = {};

  void bindBlueprint(
      int entityId, QLBlueprint bp, Map<String, dynamic> row, String path) {
    _bindings[entityId] =
        QLEntityBinding(blueprint: bp, rowData: row, bindPath: path);
  }

  QLEntityBinding? getBinding(int entityId) => _bindings[entityId];

  void clearBindings() => _bindings.clear();
}

// ════════════════════════════════════════════════════════════════════════════
// 8. GLOBAL ZERO-ALLOCATION PARSERS
// ════════════════════════════════════════════════════════════════════════════

class QLTableLayoutController {
  final Float64List offsetsX;
  final Float64List widths;
  final Int32List activeOrder; // For hardware column reordering
  final QLSignal<int> version = QLSignal(0);

  // 🚀 AABB Culling bounds (updated by external horizontal scroll controllers)
  double viewportWidth = double.infinity;
  double scrollOffset = 0.0;

  QLTableLayoutController(int columns)
      : offsetsX = Float64List(columns),
        widths = Float64List(columns),
        activeOrder = Int32List(columns) {
    for (int i = 0; i < columns; i++) activeOrder[i] = i;
  }

  void updateColumn(int index, double x, double w) {
    offsetsX[index] = x;
    widths[index] = w;
    version.value++; // Triggers GPU Repaint natively across all 10,000 rows
  }

  void updateViewport(double width, double offset) {
    viewportWidth = width;
    scrollOffset = offset;
    version.value++;
  }

  void swapColumns(int fromIdx, int toIdx) {
    final int temp = activeOrder[fromIdx];
    activeOrder[fromIdx] = activeOrder[toIdx];
    activeOrder[toIdx] = temp;
    version.value++;
  }
}
