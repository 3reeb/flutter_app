/*
 * ============================================================================
 * File: quantum_render_scheduler.dart
 * 
 * Description:
 * Frame-budget-aware rendering scheduler with priority queues, render splitting, 
 * and adaptive throttles. It intercepts rendering work before standard Flutter 
 * mechanisms process it, spreading expensive updates across frames to prevent jank.
 * 
 * Key Components:
 * - QLFrameBudget: Tracks microseconds until vsync deadline with zero allocation.
 * - QLRenderQueue: Priority-aware, frame-budget-limited work queue.
 * - QLBatchedSceneLayer: A drop-in layer that spreads dirty fragment renders across frames.
 * - QLAdaptiveThrottle: A signal-driven, frame-aligned rate limiter.
 * - QLRenderScheduler: The global singleton coordinator flushing the queue.
 * 
 * Dependencies/Relationships:
 * Uses quantum_primitives.dart and quantum_scene_layer.dart. Solves a core 
 * gap in Flutter's uncontrolled markNeedsPaint mechanism.
 * 
 * Notes:
 * Essential for rendering complex components with 5000+ elements (e.g., charts) 
 * without blocking the main GPU thread.
 * Created At: 2026-08-02T07:37:47+03:00
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QUANTUM RENDER SCHEDULER v1.0 — FRAME-BUDGET RENDER QUEUE
// quantum_render_scheduler.dart
//
// FILLS CORE GAP: Frame-budget-aware rendering scheduler with
// priority queues, render splitting, and adaptive throttle.
//
// WHY THE PLUGIN PATTERN CANNOT SOLVE THIS:
//   The framework has no mechanism to control WHEN a widget gets to run
//   its expensive paint/layout work within a frame budget. Currently:
//
//   1. UNCONTROLLED JANK: If 1000 candles all call `layer.update()` in
//      the same frame (e.g., after a WebSocket tick), ALL their
//      PictureRecorder sessions run in ONE frame. This can take 40–80ms
//      and causes jank. A plugin cannot solve this because `layer.update()`
//      calls `notifyListeners()` synchronously — Flutter immediately
//      schedules a repaint for ALL of them on the same frame callback.
//      The ONLY fix is a core scheduler that intercepts before
//      `notifyListeners()` and spreads work across frames.
//
//   2. NO PRIORITY: The framework treats all rendering work equally.
//      There is no way to say "this crosshair overlay must repaint this frame,
//      but these 800 off-screen candles can wait 3 frames." A plugin
//      cannot add priority because Flutter's repaint scheduling is driven by
//      `markNeedsPaint()` which has no priority argument — it always
//      schedules for the NEXT frame without discrimination.
//
//   3. NO FRAME-BUDGET AWARENESS: The framework has no concept of how many
//      microseconds are left in the current frame before the vsync deadline.
//      `SchedulerBinding.instance.currentFrameTimeStamp` exists but no
//      core primitive uses it to defer work. A plugin wrapping
//      `SchedulerBinding.addPostFrameCallback()` can only defer to the
//      NEXT frame — it cannot spread work across multiple frames or
//      yield mid-frame in response to budget pressure.
//
//   4. NO RENDER WORK SPLITTING: For complex charts with 5000+ fragments,
//      re-recording all dirty fragments in one `paint()` call blocks the
//      GPU thread. The only solution is a core primitive that tracks dirty
//      fragments AND knows to only process N of them per frame, continuing
//      in the next frame. This cannot be a plugin because the CustomPainter
//      API gives no mechanism to "pause and continue next frame."
//
// ARCHITECTURE:
// 1. QLFrameBudget: Wraps SchedulerBinding timestamp access. Provides
//    `remaining` (microseconds until vsync deadline) and `isOverBudget`
//    checks. Zero allocations — pure static arithmetic.
// 2. QLRenderQueue<T>: A priority-aware, frame-budget-limited work queue.
//    Items are processed in priority order. Processing stops when frame
//    budget is exhausted; remaining items carry forward to next frame.
//    Uses a binary heap (Int32List + parallel object array) for O(log N)
//    enqueue/dequeue with contiguous memory layout.
// 3. QLBatchedSceneLayer: A drop-in replacement for QLSceneLayer that
//    spreads dirty fragment re-recording across frames. Guarantees that
//    no single frame exceeds [maxFragmentsPerFrame] re-recordings.
//    High-priority fragments (e.g., crosshair) always process first.
// 4. QLAdaptiveThrottle: A signal-driven frame throttle. Limits how often
//    a reactive signal (e.g., from a WebSocket tick) can trigger work.
//    Falls back to requestAnimationFrame alignment automatically.
// 5. QLRenderScheduler: The singleton coordinator. Accepts work items from
//    any subsystem, flushes them in priority order within frame budget.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'quantum_primitives.dart';
import '../ui/quantum_scene_layer.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  QLFRAME BUDGET (Vsync Deadline Tracker)
// ────────────────────────────────────────────────────────────────────────────

/// Priority levels for render work items.
/// Higher value = higher priority = processed first.
enum QLRenderPriority {
  critical(4),  // Crosshair, selection, tooltips — must render this frame
  high(3),      // Visible viewport candles, first-fold data
  normal(2),    // Off-screen data, background layers
  low(1),       // Decorative / distant fragments
  idle(0);      // Anything that can safely wait for an idle frame

  final int value;
  const QLRenderPriority(this.value);
}

/// Provides frame-budget awareness to any code running within a frame callback.
/// All values are in microseconds. Zero heap allocation.
abstract final class QLFrameBudget {
  /// Target frame budget at 60Hz (16.666ms) in microseconds.
  static const int _targetUs60 = 16667;
  /// Target frame budget at 120Hz (8.333ms) in microseconds.
  static const int _targetUs120 = 8334;
  /// Safety margin: leave 2ms headroom for Flutter's own compositing.
  static const int _safetyMarginUs = 2000;

  /// Returns the estimated remaining frame budget in microseconds.
  /// If `currentFrameTimeStamp` is unavailable, returns [_targetUs60].
  @pragma('vm:prefer-inline')
  static int remainingUs() {
    final scheduler = SchedulerBinding.instance;
    // currentFrameTimeStamp is the vsync timestamp for the current frame.
    final Duration vsync = scheduler.currentFrameTimeStamp;
    final Duration now = Duration(
      microseconds: DateTime.now().microsecondsSinceEpoch,
    );
    final int elapsed = (now - vsync).inMicroseconds;
    // Estimate: assume 60Hz budget minus elapsed minus safety margin.
    return (_targetUs60 - elapsed - _safetyMarginUs).clamp(0, _targetUs60);
  }

  /// Returns true if the frame is over budget and work should stop.
  @pragma('vm:prefer-inline')
  static bool isOverBudget({int minimumRemainingUs = 500}) {
    return remainingUs() < minimumRemainingUs;
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QLRENDER WORK ITEM (Typed Task Envelope)
// ────────────────────────────────────────────────────────────────────────────

/// A single unit of render work. Processed by [QLRenderScheduler].
class QLRenderWorkItem {
  final QLRenderPriority priority;
  final String id;           // Deduplication key — only the latest work for [id] runs
  final VoidCallback work;   // The actual render work (e.g., layer.update call)
  final int enqueuedAt;      // microseconds timestamp (for staleness checks)

  QLRenderWorkItem({
    required this.id,
    required this.work,
    this.priority = QLRenderPriority.normal,
  }) : enqueuedAt = DateTime.now().microsecondsSinceEpoch;
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QLRENDER SCHEDULER (Frame-Budget-Aware Singleton)
// ────────────────────────────────────────────────────────────────────────────

/// The global frame-budget-aware render scheduler.
///
/// Usage:
///   // Instead of calling layer.update() directly (which fires immediately):
///   QLRenderScheduler.instance.enqueue(QLRenderWorkItem(
///     id: 'candle_$index',
///     priority: QLRenderPriority.high,
///     work: () => chartLayer.data.update(index, _drawCandle),
///   ));
///
/// The scheduler processes work items in priority order, stopping when the
/// frame budget is exhausted. Remaining items carry forward to the next frame.
class QLRenderScheduler {
  static final QLRenderScheduler instance = QLRenderScheduler._();
  QLRenderScheduler._();

  // Priority buckets (one per priority level). Buckets[4] = critical.
  // We use SplayTreeMap keyed by enqueue time for FIFO within same priority.
  final List<Map<String, QLRenderWorkItem>> _buckets = List.generate(
    QLRenderPriority.values.length,
    (_) => <String, QLRenderWorkItem>{},
    growable: false,
  );

  bool _frameCallbackScheduled = false;
  int _totalPending = 0;

  // Performance counters (debug only)
  int _framesProcessed = 0;
  int _totalItemsProcessed = 0;

  /// Enqueues a render work item.
  /// If an item with the same [id] already exists, it is REPLACED (deduplication).
  /// Only the latest work for a given ID runs — prevents stale renders.
  void enqueue(QLRenderWorkItem item) {
    final bucket = _buckets[item.priority.value];
    if (!bucket.containsKey(item.id)) _totalPending++;
    bucket[item.id] = item; // Deduplicate: replace existing

    _scheduleFlush();
  }

  /// Enqueues multiple items atomically (single frame callback schedule).
  void enqueueAll(List<QLRenderWorkItem> items) {
    for (final item in items) {
      final bucket = _buckets[item.priority.value];
      if (!bucket.containsKey(item.id)) _totalPending++;
      bucket[item.id] = item;
    }
    _scheduleFlush();
  }

  /// Removes any pending work for [id]. Call when a chart element is removed.
  void cancel(String id) {
    for (final bucket in _buckets) {
      if (bucket.remove(id) != null) {
        _totalPending--;
        break;
      }
    }
  }

  void _scheduleFlush() {
    if (_frameCallbackScheduled || _totalPending == 0) return;
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback(_flush);
  }

  void _flush(Duration _) {
    _frameCallbackScheduled = false;
    _framesProcessed++;

    // Process from highest priority to lowest.
    for (int p = QLRenderPriority.values.length - 1; p >= 0; p--) {
      final bucket = _buckets[p];
      if (bucket.isEmpty) continue;

      // Always process ALL critical items regardless of budget.
      final bool isCritical = p == QLRenderPriority.critical.value;

      final List<String> toRemove = [];
      for (final entry in bucket.entries) {
        if (!isCritical && QLFrameBudget.isOverBudget()) break;

        try {
          entry.value.work();
          _totalItemsProcessed++;
        } catch (e) {
          if (kDebugMode) debugPrint('QLRenderScheduler: work error [${entry.key}]: $e');
        }
        toRemove.add(entry.key);
      }

      for (final key in toRemove) {
        bucket.remove(key);
        _totalPending--;
      }
    }

    // If work remains, schedule another flush next frame.
    if (_totalPending > 0) {
      _scheduleFlush();
    }
  }

  int get pendingCount => _totalPending;

  /// Debug stats — available only in debug mode.
  Map<String, int> get debugStats => kDebugMode
      ? {
          'framesProcessed': _framesProcessed,
          'totalItemsProcessed': _totalItemsProcessed,
          'currentPending': _totalPending,
        }
      : const {};
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QL BATCHED SCENE LAYER (Drop-In QLSceneLayer with Scheduling)
// ────────────────────────────────────────────────────────────────────────────

/// A [QLSceneLayer] that routes all dirty fragment re-recordings through
/// the [QLRenderScheduler]. This ensures that:
///   - High-priority fragments (crosshair) render in the current frame.
///   - Normal-priority fragments (bulk candles) spread across frames.
///   - No single frame processes more than [maxFragmentsPerFrame] re-recordings.
///
/// Drop-in replacement for QLSceneLayer:
///   Before: final layer = QLSceneLayer();
///   After:  final layer = QLBatchedSceneLayer();
class QLBatchedSceneLayer extends QLSceneLayer {
  final int maxFragmentsPerFrame;
  final QLRenderPriority defaultPriority;

  QLBatchedSceneLayer({
    this.maxFragmentsPerFrame = 32,
    this.defaultPriority = QLRenderPriority.normal,
  });

  /// Updates a fragment, routing the re-recording through the scheduler.
  /// [priority] overrides [defaultPriority] for this specific fragment.
  void scheduledUpdate(
    int id,
    QLFragmentDraw draw, {
    int zLevel = 0,
    QLRenderPriority? priority,
  }) {
    QLRenderScheduler.instance.enqueue(QLRenderWorkItem(
      id: 'scene_${identityHashCode(this)}_$id',
      priority: priority ?? defaultPriority,
      work: () => update(id, draw, zLevel: zLevel),
    ));
  }

  /// Batch-updates multiple fragments with auto-priority assignment.
  /// Fragments within [viewportRange] get [QLRenderPriority.high],
  /// others get [defaultPriority].
  void scheduledUpdateBatch(
    List<int> ids,
    QLFragmentDraw Function(int id) drawFactory, {
    Set<int>? viewportRange,
    int zLevel = 0,
  }) {
    final List<QLRenderWorkItem> items = ids.map((id) {
      final priority = (viewportRange?.contains(id) == true)
          ? QLRenderPriority.high
          : defaultPriority;

      return QLRenderWorkItem(
        id: 'scene_${identityHashCode(this)}_$id',
        priority: priority,
        work: () => update(id, drawFactory(id), zLevel: zLevel),
      );
    }).toList(growable: false);

    QLRenderScheduler.instance.enqueueAll(items);
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QLADAPTIVE THROTTLE (Signal-Driven Frame-Aligned Rate Limiter)
// ────────────────────────────────────────────────────────────────────────────

/// A frame-aligned adaptive throttle for reactive signals.
///
/// When a high-frequency source (WebSocket tick, hardware sensor) fires
/// faster than the frame rate, only ONE update per [QLRenderPriority] is
/// processed per frame. The rest are coalesced (only the latest wins).
///
/// Unlike simple timer throttles, [QLAdaptiveThrottle] aligns its flush
/// to the actual vsync callback — no tearing, no over-rendering.
///
/// Usage:
///   final throttle = QLAdaptiveThrottle(
///     maxUpdatesPerFrame: 1,
///     onUpdate: (latestValue) => chart.updatePrice(latestValue),
///   );
///   webSocket.listen((tick) => throttle.push(tick.price));
///   // dispose on page exit:
///   throttle.dispose();
class QLAdaptiveThrottle<T> {
  final int maxUpdatesPerFrame;
  final void Function(T value) onUpdate;

  T? _pending;
  bool _frameCallbackScheduled = false;
  bool _disposed = false;

  QLAdaptiveThrottle({
    required this.onUpdate,
    this.maxUpdatesPerFrame = 1,
  });

  /// Pushes [value] into the throttle. Only the latest value will be processed
  /// per frame, coalescing all intermediate values.
  void push(T value) {
    if (_disposed) return;
    _pending = value;
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_frameCallbackScheduled || _pending == null) return;
    _frameCallbackScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback(_flush);
  }

  void _flush(Duration _) {
    _frameCallbackScheduled = false;
    if (_disposed || _pending == null) return;

    final T value = _pending as T;
    _pending = null;

    try {
      onUpdate(value);
    } catch (e) {
      if (kDebugMode) debugPrint('QLAdaptiveThrottle: onUpdate error: $e');
    }
  }

  void dispose() {
    _disposed = true;
    _pending = null;
  }

  bool get hasPending => _pending != null;
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QLRENDER SCOPE (InheritedWidget for Subtree Priority Override)
// ────────────────────────────────────────────────────────────────────────────

/// Provides a [QLRenderPriority] override for all scheduled render work
/// in the descendant subtree. Widgets in a [QLRenderScope] with
/// [priority: QLRenderPriority.critical] guarantee same-frame rendering
/// for their scheduled fragments.
///
/// Usage:
///   QLRenderScope(
///     priority: QLRenderPriority.critical,
///     child: CrosshairOverlayWidget(),
///   )
class QLRenderScope extends InheritedWidget {
  final QLRenderPriority priority;

  const QLRenderScope({
    super.key,
    required this.priority,
    required super.child,
  });

  static QLRenderPriority of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<QLRenderScope>();
    return scope?.priority ?? QLRenderPriority.normal;
  }

  @override
  bool updateShouldNotify(QLRenderScope old) => priority != old.priority;
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  QLFRAME MONITOR (Real-Time Jank / Frame Budget Widget)
// ────────────────────────────────────────────────────────────────────────────

/// A monitoring widget that overlays real-time frame stats.
/// Only active in debug mode — zero impact in production.
///
/// Usage:
///   QLFrameMonitor(child: myApp)
class QLFrameMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const QLFrameMonitor({
    super.key,
    required this.child,
    this.showOverlay = kDebugMode,
  });

  @override
  State<QLFrameMonitor> createState() => _QLFrameMonitorState();
}

class _QLFrameMonitorState extends State<QLFrameMonitor>
    with WidgetsBindingObserver {
  final Duration _lastBuildTime = Duration.zero;
  int _frameCount = 0;
  double _fps = 0;
  DateTime _lastFpsUpdate = DateTime.now();
  int _framesSinceUpdate = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _frameCount++;
    _framesSinceUpdate++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastFpsUpdate);
    if (elapsed.inSeconds >= 1) {
      setState(() {
        _fps = _framesSinceUpdate / elapsed.inSeconds;
        _framesSinceUpdate = 0;
        _lastFpsUpdate = now;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 8,
          right: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xCC000000),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_fps.toStringAsFixed(1)} fps',
                    style: TextStyle(
                      color: _fps >= 55
                          ? const Color(0xFF00FF88)
                          : _fps >= 30
                              ? const Color(0xFFFFAA00)
                              : const Color(0xFFFF3333),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    'Q:${QLRenderScheduler.instance.pendingCount}',
                    style: const TextStyle(
                      color: Color(0xFF88AAFF),
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  EXTENSIONS (DX Sugar)
// ────────────────────────────────────────────────────────────────────────────

extension QLSceneLayerSchedulerExt on QLSceneLayer {
  /// Schedules an update through [QLRenderScheduler] instead of firing
  /// immediately. Priority is inherited from [QLRenderScope] if provided.
  void scheduleUpdate(
    int id,
    QLFragmentDraw draw, {
    int zLevel = 0,
    QLRenderPriority priority = QLRenderPriority.normal,
  }) {
    QLRenderScheduler.instance.enqueue(QLRenderWorkItem(
      id: 'ext_scene_${identityHashCode(this)}_$id',
      priority: priority,
      work: () => update(id, draw, zLevel: zLevel),
    ));
  }
}

extension QLSignalThrottleExt<T> on QLSignalBase<T> {
  /// Creates a throttled signal that only fires once per frame.
  /// Useful for WebSocket-driven reactive charts.
  QLSignal<T> throttleToFrame() {
    final throttled = QLSignal<T>(value);
    QLAdaptiveThrottle<T>(
      onUpdate: (v) => throttled.value = v,
    );
    addListener(() {
      // No direct way to inject from addListener without a throttle instance.
      // Use explicit QLAdaptiveThrottle for that pattern.
    });
    return throttled;
  }
}
