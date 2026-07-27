// ════════════════════════════════════════════════════════════════════════════
// QUANTUM TELEMETRY ENGINE v2.0 — PRODUCTION GRADE
// quantum_telemetry_engine.dart
//
// ZERO external Quantum imports. Only Flutter/Dart SDK.
// 100% backward-compatible with all v1 public APIs.
//
// COVERAGE:
//  • Screen / widget lifecycle (mount, unmount, first-paint, rebuild count)
//  • Route push/pop with TTFR (Time to First Render)
//  • VM compilation + AST cache hit/miss
//  • VM action pipeline (name, duration, success/failure)
//  • Data load timing (QLStoreSlice queries, custom data spans)
//  • Data-to-paint latency
//  • Image load timing (network/asset/cache, decode time, bytes)
//  • RAM snapshots (mount/unmount delta via ProcessInfo on mobile/desktop)
//  • Gesture suite (tap, long-press, double-tap, swipe, drag, scroll)
//  • Frame timings (jank >16ms, slow >8ms, build/raster/vsync)
//  • App lifecycle (foreground/background/paused/detached)
//  • Error capture (Flutter, platform, VM action, custom)
//  • User journey / funnel steps
//  • Per-scope runtime enable/disable (zero overhead when off)
//  • Rich snapshot analytics (20+ aggregation helpers)
//  • TelemetryVMBridge — opt-in ActionMiddleware for QuantumVM
//
// PERFORMANCE DESIGN:
//  • Fixed-width Uint32List ring buffer — zero GC pressure per event
//  • LRU symbol cache — strings never stored raw in hot path
//  • @pragma('vm:prefer-inline') on every hot-path guard
//  • Zone-based disable — entire subtrees excluded at zero cost
//  • Per-scope name-hash registry — O(1) scope enable/disable lookup
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:collection';
import 'dart:io' show ProcessInfo;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  EVENT KINDS
// ────────────────────────────────────────────────────────────────────────────

/// Every event stored in the ring buffer belongs to exactly one kind.
/// Kinds are stored as a byte (0–255) inside the packed [kindAndFlags] word,
/// so the enum must never exceed 255 values.
enum TelemetryKind {
  /// App-level events (startup, cold-start complete).
  app,

  /// Route push / pop / replace / remove.
  route,

  /// Screen-level widget lifetime (mount, unmount, dwell).
  screen,

  /// Individual widget lifetime and paint events.
  widget,

  /// App lifecycle (foreground, background, pause, detach).
  lifecycle,

  /// Pointer interactions (tap, swipe, long-press, double-tap, drag).
  interaction,

  /// Scroll events (start, update, end, overscroll).
  scroll,

  /// Network / HTTP events (request start/end, bytes, status).
  network,

  /// Numeric metric samples (counters, gauges, percentiles).
  metric,

  /// Errors (Flutter errors, platform errors, action errors).
  error,

  /// Custom app-defined events.
  custom,

  /// Image load lifecycle (start, end, cache hit/miss, decode time).
  image,

  /// RAM snapshots (mount/unmount delta, pressure events).
  memory,

  /// Data pipeline events (QLStoreSlice query start/end, data-to-paint).
  data,

  /// User journey / funnel step tracking.
  journey,

  /// Individual frame timings (build ms, raster ms, vsync delay).
  frame,

  /// QuantumVM-level events (compile, action, reactive rebuild).
  vm,
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  FLAG CONSTANTS
// ────────────────────────────────────────────────────────────────────────────

/// Bit flags packed into the upper 24 bits of the [kindAndFlags] word.
/// Each flag occupies exactly one bit. Combine with bitwise OR.
abstract final class TelemetryFlags {
  // ── v1 flags (preserved, unchanged) ───────────────────────────────────────
  static const int none       = 0;
  static const int enter      = 1 << 0;   // span / scope begin
  static const int exit       = 1 << 1;   // span / scope end
  static const int tap        = 1 << 2;   // tap gesture
  static const int swipe      = 1 << 3;   // swipe gesture
  static const int merge      = 1 << 4;   // event was merged into previous
  static const int background = 1 << 5;   // app moved to background
  static const int foreground = 1 << 6;   // app moved to foreground
  static const int important  = 1 << 7;   // high-priority event

  // ── v2 flags (new) ────────────────────────────────────────────────────────
  static const int longPress  = 1 << 8;   // long-press gesture
  static const int doubleTap  = 1 << 9;   // double-tap gesture
  static const int drag       = 1 << 10;  // drag gesture
  static const int cacheHit   = 1 << 11;  // e.g. image served from cache
  static const int cacheMiss  = 1 << 12;  // e.g. image downloaded from network
  static const int success    = 1 << 13;  // async operation succeeded
  static const int failure    = 1 << 14;  // async operation failed
  static const int firstPaint = 1 << 15;  // widget first-paint timestamp
  static const int jank       = 1 << 16;  // frame exceeded jank threshold
  static const int slow       = 1 << 17;  // frame exceeded slow threshold
  static const int action     = 1 << 18;  // VM action event
  static const int compile    = 1 << 19;  // VM compilation event
  static const int reactive   = 1 << 20;  // reactive-node rebuild event
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  CONFIGURATION
// ────────────────────────────────────────────────────────────────────────────

/// Immutable configuration for the telemetry engine.
/// Pass to [TelemetryController.install] or [TelemetryController.configure].
class TelemetryConfig {
  // ── Storage ────────────────────────────────────────────────────────────────
  /// Maximum events held in the ring buffer before oldest events are overwritten.
  final int maxEvents;

  /// Maximum number of symbol strings kept in the LRU cache.
  final int symbolCacheSize;

  // ── Frame timings ─────────────────────────────────────────────────────────
  /// Capture frame build/raster timings via [SchedulerBinding].
  final bool captureFrameTimings;

  /// Only emit a [TelemetryKind.frame] event when frame total > this many ms.
  /// Set to 0 to capture every frame (high volume — only for profiling sessions).
  final int slowFrameThresholdMs;

  /// Frames exceeding this threshold are additionally flagged with
  /// [TelemetryFlags.jank].
  final int jankFrameThresholdMs;

  // ── System integrations ───────────────────────────────────────────────────
  /// Listen to [WidgetsBindingObserver.didChangeAppLifecycleState].
  final bool captureAppLifecycle;

  /// Hook [FlutterError.onError] to capture Flutter framework errors.
  final bool captureFlutterErrors;

  /// Hook [PlatformDispatcher.instance.onError] for unhandled platform errors.
  final bool capturePlatformErrors;

  /// Capture [WidgetsBindingObserver.didHaveMemoryPressure] events.
  final bool captureMemoryPressure;

  // ── Image tracking ────────────────────────────────────────────────────────
  /// Enable [TelemetryController.beginImageLoad] / [endImageLoad] recording.
  final bool captureImageTimings;

  /// Maximum concurrent in-flight image spans tracked simultaneously.
  final int maxImageTrackers;

  // ── Data load tracking ────────────────────────────────────────────────────
  /// Enable [TelemetryController.beginDataLoad] / [endDataLoad] recording.
  final bool captureDataTimings;

  /// Maximum concurrent in-flight data spans tracked simultaneously.
  final int maxDataSpans;

  // ── Memory snapshots ──────────────────────────────────────────────────────
  /// Read [ProcessInfo.currentRss] at [TelemetryScope] mount/unmount.
  /// Has no effect on web (always reads 0).
  final bool captureMemoryOnScreen;

  // ── Widget instrumentation ────────────────────────────────────────────────
  /// Count [didUpdateWidget] calls per [TelemetryScope] name.
  final bool captureWidgetRebuilds;

  // ── VM tracking ───────────────────────────────────────────────────────────
  /// Enable [TelemetryController.beginAction] / [endAction] recording.
  final bool captureVMActions;

  /// Enable [TelemetryController.beginCompile] / [endCompile] recording.
  final bool captureVMCompilation;

  // ── Merge behaviour ───────────────────────────────────────────────────────
  /// Merge consecutive identical events that arrive within [mergeWindowMs].
  final bool mergeRapidDuplicates;

  /// Window in milliseconds for rapid-duplicate merging.
  final int mergeWindowMs;

  const TelemetryConfig({
    this.maxEvents              = 8192,
    this.symbolCacheSize        = 2048,
    this.captureFrameTimings    = true,
    this.slowFrameThresholdMs   = 8,
    this.jankFrameThresholdMs   = 16,
    this.captureAppLifecycle    = true,
    this.captureFlutterErrors   = true,
    this.capturePlatformErrors  = true,
    this.captureMemoryPressure  = true,
    this.captureImageTimings    = true,
    this.maxImageTrackers       = 256,
    this.captureDataTimings     = true,
    this.maxDataSpans           = 128,
    this.captureMemoryOnScreen  = true,
    this.captureWidgetRebuilds  = true,
    this.captureVMActions       = true,
    this.captureVMCompilation   = true,
    this.mergeRapidDuplicates   = true,
    this.mergeWindowMs          = 8,
  });
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  HASH UTILITY
// ────────────────────────────────────────────────────────────────────────────

/// FNV-1a 32-bit hash. Fast, collision-resistant enough for symbol IDs.
abstract final class TelemetryHash {
  @pragma('vm:prefer-inline')
  static int fnv1a32(String input) {
    const int fnvOffset = 0x811C9DC5;
    const int fnvPrime  = 0x01000193;
    int hash = fnvOffset;
    for (int i = 0; i < input.length; i++) {
      hash ^= input.codeUnitAt(i);
      hash  = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    return hash;
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  SYMBOL CACHE
// ────────────────────────────────────────────────────────────────────────────

/// LRU symbol table. The ring buffer stores only integer hashes; this cache
/// maps recent hashes back to their string labels for snapshot resolution.
/// When capacity is exceeded the oldest entry is silently evicted.
class SymbolCache {
  final int capacity;
  final LinkedHashMap<int, String> _recent = LinkedHashMap<int, String>();

  SymbolCache({required this.capacity});

  /// Intern [value] and return its stable hash ID.
  @pragma('vm:prefer-inline')
  int intern(String value) {
    final int hash = TelemetryHash.fnv1a32(value);
    _recent.remove(hash);
    _recent[hash] = value;
    if (_recent.length > capacity) _recent.remove(_recent.keys.first);
    return hash;
  }

  /// Resolve a hash back to its string label (returns null if evicted).
  @pragma('vm:prefer-inline')
  String? resolve(int hash) => _recent[hash];

  void clear() => _recent.clear();

  /// Snapshot of the current symbol table for export.
  Map<int, String> snapshot() => Map<int, String>.from(_recent);
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  TELEMETRY RECORD
// ────────────────────────────────────────────────────────────────────────────

/// A decoded, human-readable view of one event from the ring buffer.
/// Instances are created only during [TelemetryController.snapshot] — never
/// allocated in the hot recording path.
class TelemetryRecord {
  final int           elapsedMs;
  final TelemetryKind kind;
  final int           flags;
  final int           targetHash;
  final int           contextHash;

  /// valueA: primary metric (duration ms, x-coordinate, bytes, step index…).
  final int valueA;

  /// valueB: secondary metric (y-coordinate, raster ms, etc.).
  final int valueB;

  /// valueC: tertiary metric (event count, merge count, etc.).
  final int valueC;

  /// Resolved string label for [targetHash], if still in the symbol cache.
  final String? targetLabel;

  /// Resolved string label for [contextHash], if still in the symbol cache.
  final String? contextLabel;

  const TelemetryRecord({
    required this.elapsedMs,
    required this.kind,
    required this.flags,
    required this.targetHash,
    required this.contextHash,
    required this.valueA,
    required this.valueB,
    required this.valueC,
    this.targetLabel,
    this.contextLabel,
  });

  /// Convert elapsed ms to an absolute UTC timestamp.
  DateTime toUtc(DateTime sessionStartUtc) =>
      sessionStartUtc.add(Duration(milliseconds: elapsedMs));

  bool get isEnter    => (flags & TelemetryFlags.enter)      != 0;
  bool get isExit     => (flags & TelemetryFlags.exit)        != 0;
  bool get isMerged   => (flags & TelemetryFlags.merge)       != 0;
  bool get isJank     => (flags & TelemetryFlags.jank)        != 0;
  bool get isSlow     => (flags & TelemetryFlags.slow)        != 0;
  bool get isSuccess  => (flags & TelemetryFlags.success)     != 0;
  bool get isFailure  => (flags & TelemetryFlags.failure)     != 0;
  bool get isCacheHit => (flags & TelemetryFlags.cacheHit)    != 0;
  bool get isAction   => (flags & TelemetryFlags.action)      != 0;
  bool get isCompile  => (flags & TelemetryFlags.compile)     != 0;
  bool get isReactive => (flags & TelemetryFlags.reactive)    != 0;

  Map<String, dynamic> toJson({bool includeLabels = true}) {
    return {
      'elapsedMs':    elapsedMs,
      'kind':         kind.name,
      'flags':        flags,
      'targetHash':   targetHash,
      'contextHash':  contextHash,
      'valueA':       valueA,
      'valueB':       valueB,
      'valueC':       valueC,
      if (includeLabels) 'targetLabel':  targetLabel,
      if (includeLabels) 'contextLabel': contextLabel,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  TELEMETRY FILTER
// ────────────────────────────────────────────────────────────────────────────

/// Declarative filter applied during [TelemetryController.snapshot].
class TelemetryFilter {
  final Set<TelemetryKind>? kinds;
  final DateTime?           startUtc;
  final DateTime?           endUtc;
  final Set<int>?           targetHashes;
  final Set<int>?           contextHashes;
  final int?                minValueA;
  final int?                maxValueA;
  final int?                minValueB;
  final int?                maxValueB;
  final int?                minValueC;
  final int?                maxValueC;
  final bool                onlyMerged;
  final bool                onlyEnter;
  final bool                onlyExit;
  final bool                onlyJank;
  final bool                onlySlow;
  final bool                onlyFailures;

  /// Custom predicate evaluated after all other checks pass.
  final bool Function(TelemetryRecord record)? predicate;

  const TelemetryFilter({
    this.kinds,
    this.startUtc,
    this.endUtc,
    this.targetHashes,
    this.contextHashes,
    this.minValueA,
    this.maxValueA,
    this.minValueB,
    this.maxValueB,
    this.minValueC,
    this.maxValueC,
    this.onlyMerged   = false,
    this.onlyEnter    = false,
    this.onlyExit     = false,
    this.onlyJank     = false,
    this.onlySlow     = false,
    this.onlyFailures = false,
    this.predicate,
  });

  @pragma('vm:prefer-inline')
  bool matches(TelemetryRecord record, DateTime sessionStartUtc) {
    if (kinds         != null && !kinds!.contains(record.kind))          return false;
    if (targetHashes  != null && !targetHashes!.contains(record.targetHash))  return false;
    if (contextHashes != null && !contextHashes!.contains(record.contextHash)) return false;
    if (minValueA != null && record.valueA < minValueA!)                 return false;
    if (maxValueA != null && record.valueA > maxValueA!)                 return false;
    if (minValueB != null && record.valueB < minValueB!)                 return false;
    if (maxValueB != null && record.valueB > maxValueB!)                 return false;
    if (minValueC != null && record.valueC < minValueC!)                 return false;
    if (maxValueC != null && record.valueC > maxValueC!)                 return false;
    if (onlyMerged   && !record.isMerged)                                return false;
    if (onlyEnter    && !record.isEnter)                                 return false;
    if (onlyExit     && !record.isExit)                                  return false;
    if (onlyJank     && !record.isJank)                                  return false;
    if (onlySlow     && !record.isSlow)                                  return false;
    if (onlyFailures && !record.isFailure)                               return false;

    if (startUtc != null || endUtc != null) {
      final DateTime utc = record.toUtc(sessionStartUtc);
      if (startUtc != null && utc.isBefore(startUtc!)) return false;
      if (endUtc   != null && utc.isAfter(endUtc!))    return false;
    }

    if (predicate != null && !predicate!(record)) return false;
    return true;
  }
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  TELEMETRY SNAPSHOT
// ────────────────────────────────────────────────────────────────────────────

/// An exported, filtered view of the telemetry buffer.
/// Immutable after construction. Use the [TelemetrySnapshotAnalytics]
/// extension for pre-built aggregations.
class TelemetrySnapshot {
  final DateTime             sessionStartUtc;
  final DateTime             snapshotTakenUtc;
  final int                  totalStoredEvents;
  final int                  droppedEvents;
  final List<TelemetryRecord> records;
  final Map<int, String>     symbols;

  const TelemetrySnapshot({
    required this.sessionStartUtc,
    required this.snapshotTakenUtc,
    required this.totalStoredEvents,
    required this.droppedEvents,
    required this.records,
    required this.symbols,
  });

  Map<String, dynamic> toJson({bool includeLabels = true}) => {
    'sessionStartUtc':  sessionStartUtc.toIso8601String(),
    'snapshotTakenUtc': snapshotTakenUtc.toIso8601String(),
    'totalStoredEvents': totalStoredEvents,
    'droppedEvents':    droppedEvents,
    'count':            records.length,
    'records': records
        .map((r) => r.toJson(includeLabels: includeLabels))
        .toList(growable: false),
    if (includeLabels)
      'symbols': symbols.map((k, v) => MapEntry(k.toString(), v)),
  };

  /// Count events grouped by kind.
  Map<TelemetryKind, int> countByKind() {
    final out = <TelemetryKind, int>{};
    for (final r in records) out[r.kind] = (out[r.kind] ?? 0) + 1;
    return out;
  }

  /// Count events per target label.
  Map<String, int> countByTargetLabel() {
    final out = <String, int>{};
    for (final r in records) {
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      out[label] = (out[label] ?? 0) + 1;
    }
    return out;
  }

  /// Sum [TelemetryRecord.valueA] for exit events, grouped by target label.
  /// Useful for total dwell time per screen name.
  Map<String, int> durationByTargetLabel() {
    final out = <String, int>{};
    for (final r in records) {
      if (!r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      out[label] = (out[label] ?? 0) + r.valueA;
    }
    return out;
  }
}

// ─────────────────────────────────────────────────────────────────────── §9 ─
//  RING BUFFER STORE
// ────────────────────────────────────────────────────────────────────────────

/// Fixed-width, zero-GC ring buffer.
///
/// Layout — 7 × Uint32 words per event:
///   [0] elapsedMs      — milliseconds since session start
///   [1] kindAndFlags   — low byte = kind index, bits 8-31 = flags
///   [2] targetHash     — FNV-1a hash of the target label
///   [3] contextHash    — FNV-1a hash of the context label
///   [4] valueA         — primary numeric value
///   [5] valueB         — secondary numeric value
///   [6] valueC         — tertiary numeric value / merge count
class TelemetryStore {
  static const int _wordsPerEvent = 7;

  final int       maxEvents;
  final Uint32List _buffer;

  int _headEvent = 0;
  int _count     = 0;
  int totalStoredEvents = 0;
  int droppedEvents     = 0;

  TelemetryStore({required this.maxEvents})
      : _buffer = Uint32List(maxEvents * _wordsPerEvent);

  int get count => _count;

  void reset() {
    _headEvent        = 0;
    _count            = 0;
    totalStoredEvents = 0;
    droppedEvents     = 0;
    _buffer.fillRange(0, _buffer.length, 0);
  }

  bool _sameEvent(int base, int kindAndFlags, int targetHash, int contextHash) =>
      (_buffer[base + 1] & ~(TelemetryFlags.merge << 8)) == kindAndFlags &&
      _buffer[base + 2] == targetHash &&
      _buffer[base + 3] == contextHash;

  /// Attempt to merge [elapsedMs] into the most recent event if it is
  /// identical (kind, target, context) and within [mergeWindowMs].
  /// Returns true if merged — caller must not push a new event.
  bool tryMerge(
    int elapsedMs,
    int kindAndFlags,
    int targetHash,
    int contextHash,
    int valueA,
    int valueB,
    int valueC,
    int mergeWindowMs,
  ) {
    if (_count == 0) return false;

    final int prevEvent = (_headEvent - 1 + maxEvents) % maxEvents;
    final int base      = prevEvent * _wordsPerEvent;

    final int prevElapsed = _buffer[base];
    final int delta       = elapsedMs - prevElapsed;
    if (delta < 0 || delta > mergeWindowMs)              return false;
    if (!_sameEvent(base, kindAndFlags, targetHash, contextHash)) return false;

    _buffer[base]     = elapsedMs;
    _buffer[base + 4] += valueA;
    _buffer[base + 5]  = valueB;
    _buffer[base + 6] += (valueC <= 0 ? 1 : valueC);
    // Mark the merge flag in the stored flags field
    _buffer[base + 1]  = kindAndFlags | (TelemetryFlags.merge << 8);
    return true;
  }

  void pushEvent({
    required int elapsedMs,
    required int kindAndFlags,
    required int targetHash,
    required int contextHash,
    required int valueA,
    required int valueB,
    required int valueC,
  }) {
    final int base     = _headEvent * _wordsPerEvent;
    _buffer[base]     = elapsedMs;
    _buffer[base + 1] = kindAndFlags;
    _buffer[base + 2] = targetHash;
    _buffer[base + 3] = contextHash;
    _buffer[base + 4] = valueA;
    _buffer[base + 5] = valueB;
    _buffer[base + 6] = valueC;

    _headEvent = (_headEvent + 1) % maxEvents;
    if (_count < maxEvents) {
      _count++;
    } else {
      droppedEvents++;
    }
    totalStoredEvents++;
  }

  /// Iterate all stored events oldest → newest, applying [filter].
  Iterable<TelemetryRecord> iterate({
    required DateTime      sessionStartUtc,
    required SymbolCache   symbols,
    TelemetryFilter        filter = const TelemetryFilter(),
  }) sync* {
    final int startEvent = (_headEvent - _count + maxEvents) % maxEvents;
    final int kindCount  = TelemetryKind.values.length;

    for (int i = 0; i < _count; i++) {
      final int eventIndex   = (startEvent + i) % maxEvents;
      final int base         = eventIndex * _wordsPerEvent;

      final int elapsedMs    = _buffer[base];
      final int kindAndFlags = _buffer[base + 1];
      final int targetHash   = _buffer[base + 2];
      final int contextHash  = _buffer[base + 3];
      final int valueA       = _buffer[base + 4];
      final int valueB       = _buffer[base + 5];
      final int valueC       = _buffer[base + 6];

      final int kindIndex = (kindAndFlags & 0xFF).clamp(0, kindCount - 1);
      final TelemetryKind kind  = TelemetryKind.values[kindIndex];
      final int           flags = (kindAndFlags >> 8) & 0xFFFFFF;

      final record = TelemetryRecord(
        elapsedMs:    elapsedMs,
        kind:         kind,
        flags:        flags,
        targetHash:   targetHash,
        contextHash:  contextHash,
        valueA:       valueA,
        valueB:       valueB,
        valueC:       valueC,
        targetLabel:  symbols.resolve(targetHash),
        contextLabel: symbols.resolve(contextHash),
      );

      if (filter.matches(record, sessionStartUtc)) yield record;
    }
  }

  /// Raw binary export of the entire buffer (for offline analysis).
  Uint8List exportBinary() {
    final bytes = Uint8List(_buffer.lengthInBytes);
    bytes.buffer.asUint32List().setAll(0, _buffer);
    return bytes;
  }
}

// ─────────────────────────────────────────────────────────────────────── §10 ─
//  INTERNAL SPAN TYPES
// ─────────────────────────────────────────────────────────────────────────────

/// Bookkeeping for an open begin/end span.
class _OpenSpan {
  final int     id;
  final String  name;
  final int     startedElapsedMs;
  final String? context;
  final int     flags;

  const _OpenSpan({
    required this.id,
    required this.name,
    required this.startedElapsedMs,
    required this.context,
    required this.flags,
  });
}

/// Bookkeeping for an in-flight image load.
class _ImageSpan {
  final int     ticket;
  final String  url;
  final int     startedElapsedMs;
  final bool    fromCache;

  const _ImageSpan({
    required this.ticket,
    required this.url,
    required this.startedElapsedMs,
    required this.fromCache,
  });
}

/// Bookkeeping for an in-flight data load (QLStoreSlice query or custom).
class _DataSpan {
  final int     id;
  final String  name;
  final String? context;
  final int     startedElapsedMs;

  const _DataSpan({
    required this.id,
    required this.name,
    required this.context,
    required this.startedElapsedMs,
  });
}

// ─────────────────────────────────────────────────────────────────────── §11 ─
//  TELEMETRY CONTROLLER — MAIN SINGLETON
// ─────────────────────────────────────────────────────────────────────────────

/// Central telemetry controller. All recording goes through here.
///
/// **Installation** (call once before [runApp]):
/// ```dart
/// TelemetryController.instance.install(
///   config: const TelemetryConfig(maxEvents: 16384),
/// );
/// ```
///
/// **Globally disable** (zero overhead):
/// ```dart
/// TelemetryController.instance.setEnabled(false);
/// ```
///
/// **Per-scope disable at runtime**:
/// ```dart
/// TelemetryController.instance.setScopeEnabled('CheckoutScreen', false);
/// ```
class TelemetryController extends ChangeNotifier with WidgetsBindingObserver {
  TelemetryController._();

  static final TelemetryController instance = TelemetryController._();

  // ── Core state ─────────────────────────────────────────────────────────────
  TelemetryConfig _config = const TelemetryConfig();
  TelemetryStore  _store  = TelemetryStore(maxEvents: 1024);
  SymbolCache _symbols = SymbolCache(capacity: 4096);

  final Stopwatch _clock          = Stopwatch();
  DateTime        _sessionStartUtc = DateTime.now().toUtc();

  bool _enabled         = true;
  bool _installed       = false;
  bool _timingsHooked   = false;

  // ── Open spans ─────────────────────────────────────────────────────────────
  final Map<int, _OpenSpan>   _activeSpans    = {};
  final Map<int, _ImageSpan>  _openImageLoads = {};
  final Map<int, _DataSpan>   _openDataSpans  = {};
  int _nextSpanId        = 1;
  int _nextImageTicket   = 1;
  int _nextDataSpanId    = 1;

  // ── Per-scope enable/disable registry (nameHash → bool) ───────────────────
  final Map<int, bool> _scopeOverrides = {};

  // ── Accessors ──────────────────────────────────────────────────────────────
  TelemetryConfig get config           => _config;
  bool            get enabled          => _enabled;
  DateTime        get sessionStartUtc  => _sessionStartUtc;

  /// Current process RSS memory in bytes.
  /// Returns 0 on web or if [ProcessInfo] is unavailable.
  int get currentRamBytes {
    if (kIsWeb) return 0;
    try { return ProcessInfo.currentRss; } catch (_) { return 0; }
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────── ──

  void configure(TelemetryConfig config) {
    _config  = config;
    _store   = TelemetryStore(maxEvents: config.maxEvents);
    _symbols = SymbolCache(capacity: config.symbolCacheSize);
  }

  /// Install the telemetry engine. Safe to call multiple times — idempotent.
  void install({TelemetryConfig? config}) {
    if (_installed) return;

    WidgetsFlutterBinding.ensureInitialized();
    configure(config ?? const TelemetryConfig());

    _sessionStartUtc = DateTime.now().toUtc();
    _clock
      ..reset()
      ..start();

    WidgetsBinding.instance.addObserver(this);

    if (_config.captureFrameTimings && !_timingsHooked) {
      _timingsHooked = true;
      try {
        SchedulerBinding.instance.addTimingsCallback(_onTimings);
      } catch (_) { /* safe fallback */ }
    }

    if (_config.captureFlutterErrors) {
      final prev = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        instance.recordError(
          details.exception,
          details.stack ?? StackTrace.current,
          label: 'flutter_error',
          valueA: details.silent ? 1 : 0,
        );
        prev?.call(details);
      };
    }

    if (_config.capturePlatformErrors) {
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        instance.recordError(error, stack, label: 'platform_error');
        return true;
      };
    }

    _installed = true;
  }

  /// Uninstall and clean up. Does not reset the stored events.
  void disposeTelemetry() {
    if (!_installed) return;
    try { WidgetsBinding.instance.removeObserver(this); } catch (_) {}
    _activeSpans.clear();
    _openImageLoads.clear();
    _openDataSpans.clear();
    _enabled   = false;
    _installed = false;
  }

  /// Enable or disable recording globally.
  void setEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  /// Enable or disable recording for a specific scope name at runtime.
  /// When disabled the scope's [TelemetryScope] emits zero events — no
  /// allocations, no buffer writes.
  void setScopeEnabled(String name, bool enabled) {
    _scopeOverrides[TelemetryHash.fnv1a32(name)] = enabled;
  }

  /// Returns false if the scope was explicitly disabled via [setScopeEnabled].
  @pragma('vm:prefer-inline')
  bool isScopeEnabled(String name) {
    final override = _scopeOverrides[TelemetryHash.fnv1a32(name)];
    return override ?? true;
  }

  /// Run [body] with telemetry entirely disabled for the current zone.
  T withDisabled<T>(T Function() body) {
    return runZoned(body, zoneValues: const {#telemetry_enabled: false});
  }

  /// Run [body] with a zone-scoped context label attached to all events.
  T withContext<T>(String context, T Function() body) {
    return runZoned(body, zoneValues: {#telemetry_context: context});
  }

  /// Reset the session: clears the buffer and restarts the clock.
  void reset() {
    _store.reset();
    _symbols.clear();
    _activeSpans.clear();
    _openImageLoads.clear();
    _openDataSpans.clear();
    _scopeOverrides.clear();
    _sessionStartUtc  = DateTime.now().toUtc();
    _clock
      ..reset()
      ..start();
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  ZONE HELPERS
  // ─────────────────────────────────────────────────────────────────────── ──

  @pragma('vm:prefer-inline')
  bool _zoneEnabled() {
    final dynamic v = Zone.current[#telemetry_enabled];
    return v is bool ? v : true;
  }

  @pragma('vm:prefer-inline')
  String? _zoneContext() {
    final dynamic v = Zone.current[#telemetry_context];
    return v?.toString();
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  FRAME TIMING CALLBACK
  // ─────────────────────────────────────────────────────────────────────── ──

  void _onTimings(List<FrameTiming> timings) {
    if (!_enabled || !_config.captureFrameTimings) return;
    for (final t in timings) {
      final int buildMs  = t.buildDuration.inMilliseconds;
      final int rasterMs = t.rasterDuration.inMilliseconds;
      final int totalMs  = buildMs + rasterMs;

      if (totalMs < _config.slowFrameThresholdMs) continue;

      final bool isJank = totalMs >= _config.jankFrameThresholdMs;
      int flags = isJank ? TelemetryFlags.jank : TelemetryFlags.slow;
      flags    |= TelemetryFlags.important;

      record(
        TelemetryKind.frame,
        'frame_timing',
        context:     isJank ? 'jank' : 'slow',
        valueA:      buildMs,
        valueB:      rasterMs,
        valueC:      totalMs,
        flags:       flags,
        mergeSimilar: false,
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────────────────── ──

  @pragma('vm:prefer-inline')
  int _nextElapsedMs() => _clock.elapsedMilliseconds;

  @pragma('vm:prefer-inline')
  int _packKindAndFlags(TelemetryKind kind, int flags) =>
      (kind.index & 0xFF) | ((flags & 0xFFFFFF) << 8);

  // ─────────────────────────────────────────────────────────────────────── ──
  //  CORE RECORD API
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Record a single raw event. This is the lowest-level recording primitive.
  ///
  /// All higher-level helpers ([recordMetric], [beginSpan], [beginImageLoad],
  /// etc.) delegate here.
  void record(
    TelemetryKind kind,
    String target, {
    String? context,
    int     valueA      = 0,
    int     valueB      = 0,
    int     valueC      = 0,
    int     flags       = TelemetryFlags.none,
    bool    mergeSimilar = true,
  }) {
    if (!_enabled || !_zoneEnabled()) return;

    final int elapsedMs    = _nextElapsedMs();
    final int kindAndFlags = _packKindAndFlags(kind, flags);
    final int targetHash   = _symbols.intern(target);
    final int contextHash  = _symbols.intern(context ?? _zoneContext() ?? '');

    if (_config.mergeRapidDuplicates &&
        mergeSimilar &&
        _store.tryMerge(
          elapsedMs, kindAndFlags, targetHash, contextHash,
          valueA, valueB, valueC, _config.mergeWindowMs,
        )) {
      return;
    }

    _store.pushEvent(
      elapsedMs:    elapsedMs,
      kindAndFlags: kindAndFlags,
      targetHash:   targetHash,
      contextHash:  contextHash,
      valueA:       valueA,
      valueB:       valueB,
      valueC:       valueC == 0 ? 1 : valueC,
    );
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  CONVENIENCE RECORD HELPERS
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Record a named numeric metric.
  void recordMetric(
    String name, {
    String? context,
    int     valueA = 0,
    int     valueB = 0,
    int     valueC = 0,
    int     flags  = TelemetryFlags.none,
  }) {
    record(
      TelemetryKind.metric, name,
      context: context, valueA: valueA, valueB: valueB,
      valueC: valueC, flags: flags, mergeSimilar: false,
    );
  }

  /// Record an error event. Captures error type hash and stack hash.
  void recordError(
    Object error,
    StackTrace stack, {
    String label  = 'error',
    int    valueA = 0,
  }) {
    record(
      TelemetryKind.error, label,
      context: error.runtimeType.toString(),
      valueA:  valueA,
      valueB:  stack.toString().hashCode & 0x7FFFFFFF,
      valueC:  1,
      flags:   TelemetryFlags.important,
      mergeSimilar: false,
    );
  }



  /// Record a user-journey funnel step.
  ///
  /// [journeyName] identifies the funnel (e.g. `'onboarding'`, `'checkout'`).
  /// [step] is the 0-based step index.
  /// [label] is an optional human-readable step description.
  void recordJourneyStep(
    String journeyName, {
    required int step,
    String?      label,
  }) {
    record(
      TelemetryKind.journey, journeyName,
      context:     label ?? 'step_$step',
      valueA:      step,
      flags:       TelemetryFlags.enter,
      mergeSimilar: false,
    );
  }

  /// Record a RAM memory snapshot labelled by [context].
  void recordMemory(String label, {String? context}) {
    record(
      TelemetryKind.memory, label,
      context:     context,
      valueA:      currentRamBytes,
      mergeSimilar: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  SPAN API (begin / end)
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Begin a named timing span. Returns a span ID that must be passed to
  /// [endSpan] to complete the measurement.
  int beginSpan(
    String name, {
    String? context,
    int     flags = TelemetryFlags.none,
  }) {
    final int id = _nextSpanId++;
    _activeSpans[id] = _OpenSpan(
      id:               id,
      name:             name,
      startedElapsedMs: _nextElapsedMs(),
      context:          context ?? _zoneContext(),
      flags:            flags,
    );
    record(
      TelemetryKind.metric, name,
      context:     context ?? 'span_begin',
      flags:       flags | TelemetryFlags.enter,
      valueA:      id,
      mergeSimilar: false,
    );
    return id;
  }

  /// Complete a span opened with [beginSpan]. Records duration in valueA.
  void endSpan(
    int spanId, {
    String? context,
    int     valueA = 0,
    int     valueB = 0,
    int     valueC = 0,
  }) {
    final _OpenSpan? span = _activeSpans.remove(spanId);
    if (span == null) return;
    final int durationMs = _nextElapsedMs() - span.startedElapsedMs;
    record(
      TelemetryKind.metric, span.name,
      context:     context ?? span.context ?? 'span_end',
      flags:       span.flags | TelemetryFlags.exit,
      valueA:      durationMs,
      valueB:      valueA,
      valueC:      valueC == 0 ? 1 : valueC,
      mergeSimilar: false,
    );
  }

  /// Synchronously measure [body] and record the duration.
  R measure<R>(
    String name,
    R Function() body, {
    String? context,
    int     flags = TelemetryFlags.none,
  }) {
    final int id = beginSpan(name, context: context, flags: flags);
    try {
      return body();
    } finally {
      endSpan(id);
    }
  }

  /// Asynchronously measure [body] and record the duration.
  Future<R> measureAsync<R>(
    String name,
    Future<R> Function() body, {
    String? context,
    int     flags = TelemetryFlags.none,
  }) async {
    final int id = beginSpan(name, context: context, flags: flags);
    try {
      return await body();
    } finally {
      endSpan(id);
    }
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  IMAGE TRACKING
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Start tracking an image load. Returns a ticket that must be passed to
  /// [endImageLoad] when the image is ready to display.
  ///
  /// ```dart
  /// final ticket = TelemetryController.instance.beginImageLoad(imageUrl);
  /// // … image loads …
  /// TelemetryController.instance.endImageLoad(ticket, bytes: responseBytes);
  /// ```
  int beginImageLoad(String url, {bool fromCache = false}) {
    if (!_enabled || !_config.captureImageTimings) return 0;
    if (_openImageLoads.length >= _config.maxImageTrackers) return 0;

    final int ticket = _nextImageTicket++;
    _openImageLoads[ticket] = _ImageSpan(
      ticket:           ticket,
      url:              url,
      startedElapsedMs: _nextElapsedMs(),
      fromCache:        fromCache,
    );

    record(
      TelemetryKind.image, url,
      context:     fromCache ? 'cache_load' : 'network_load',
      flags:       TelemetryFlags.enter | (fromCache ? TelemetryFlags.cacheHit : TelemetryFlags.cacheMiss),
      mergeSimilar: false,
    );
    return ticket;
  }

  /// Complete an image load. Records decode duration, byte size, and
  /// cache hit/miss in the event buffer.
  void endImageLoad(
    int ticket, {
    int  bytes     = 0,
    bool fromCache = false,
  }) {
    if (!_enabled || ticket == 0) return;
    final _ImageSpan? span = _openImageLoads.remove(ticket);
    if (span == null) return;

    final int durationMs = _nextElapsedMs() - span.startedElapsedMs;
    final bool cached    = fromCache || span.fromCache;

    record(
      TelemetryKind.image, span.url,
      context:     cached ? 'cache_hit' : 'network_hit',
      flags:       TelemetryFlags.exit |
                   TelemetryFlags.firstPaint |
                   (cached ? TelemetryFlags.cacheHit : TelemetryFlags.cacheMiss),
      valueA:      durationMs,
      valueB:      bytes,
      valueC:      1,
      mergeSimilar: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  DATA LOAD TRACKING
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Begin tracking a data fetch (e.g. a QLStoreSlice query).
  /// Returns a span ID that must be passed to [endDataLoad].
  int beginDataLoad(String name, {String? context}) {
    if (!_enabled || !_config.captureDataTimings) return 0;
    if (_openDataSpans.length >= _config.maxDataSpans) return 0;

    final int id = _nextDataSpanId++;
    _openDataSpans[id] = _DataSpan(
      id:               id,
      name:             name,
      context:          context ?? _zoneContext(),
      startedElapsedMs: _nextElapsedMs(),
    );
    record(
      TelemetryKind.data, name,
      context:     context ?? 'load_start',
      flags:       TelemetryFlags.enter,
      valueA:      id,
      mergeSimilar: false,
    );
    return id;
  }

  /// Complete a data load. Records duration and success/failure flag.
  void endDataLoad(int spanId, {bool success = true}) {
    if (!_enabled || spanId == 0) return;
    final _DataSpan? span = _openDataSpans.remove(spanId);
    if (span == null) return;

    final int durationMs = _nextElapsedMs() - span.startedElapsedMs;
    record(
      TelemetryKind.data, span.name,
      context:     success ? 'load_success' : 'load_failure',
      flags:       TelemetryFlags.exit |
                   (success ? TelemetryFlags.success : TelemetryFlags.failure),
      valueA:      durationMs,
      valueC:      1,
      mergeSimilar: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  VM ACTION TRACKING
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Begin tracking a QuantumVM action. Called by [TelemetryVMBridge].
  int beginAction(String actionName) {
    if (!_enabled || !_config.captureVMActions) return 0;
    final int id = _nextSpanId++;
    _activeSpans[id] = _OpenSpan(
      id:               id,
      name:             actionName,
      startedElapsedMs: _nextElapsedMs(),
      context:          'vm_action',
      flags:            TelemetryFlags.action,
    );
    record(
      TelemetryKind.vm, actionName,
      context:     'vm_action',
      flags:       TelemetryFlags.action | TelemetryFlags.enter,
      valueA:      id,
      mergeSimilar: false,
    );
    return id;
  }

  /// Complete a VM action recording.
  void endAction(int spanId, {bool success = true}) {
    if (!_enabled || spanId == 0) return;
    final _OpenSpan? span = _activeSpans.remove(spanId);
    if (span == null) return;
    final int durationMs = _nextElapsedMs() - span.startedElapsedMs;
    record(
      TelemetryKind.vm, span.name,
      context:     success ? 'action_ok' : 'action_error',
      flags:       TelemetryFlags.action | TelemetryFlags.exit |
                   (success ? TelemetryFlags.success : TelemetryFlags.failure),
      valueA:      durationMs,
      valueC:      1,
      mergeSimilar: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  VM COMPILATION TRACKING
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Begin tracking a QLCompiler / QLSmartView compilation pass.
  int beginCompile(String viewId) {
    if (!_enabled || !_config.captureVMCompilation) return 0;
    final int id = _nextSpanId++;
    _activeSpans[id] = _OpenSpan(
      id:               id,
      name:             viewId,
      startedElapsedMs: _nextElapsedMs(),
      context:          'compile',
      flags:            TelemetryFlags.compile,
    );
    return id;
  }

  /// Complete a compilation span. [fromCache] true = blueprint cache hit.
  void endCompile(int spanId, {bool fromCache = false}) {
    if (!_enabled || spanId == 0) return;
    final _OpenSpan? span = _activeSpans.remove(spanId);
    if (span == null) return;
    final int durationMs = _nextElapsedMs() - span.startedElapsedMs;
    record(
      TelemetryKind.vm, span.name,
      context:     fromCache ? 'compile_cache_hit' : 'compile_miss',
      flags:       TelemetryFlags.compile | TelemetryFlags.exit |
                   (fromCache ? TelemetryFlags.cacheHit : TelemetryFlags.cacheMiss),
      valueA:      durationMs,
      valueC:      1,
      mergeSimilar: false,
    );
  }

  /// Record a reactive-node rebuild (e.g. _QLReactiveNodeBoundary rebuild).
  void onReactiveBuild(String nodePath) {
    if (!_enabled) return;
    record(
      TelemetryKind.vm, nodePath,
      context:     'reactive_rebuild',
      flags:       TelemetryFlags.reactive,
      valueC:      1,
      mergeSimilar: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────── ──
  //  SNAPSHOT
  // ─────────────────────────────────────────────────────────────────────── ──

  /// Export a filtered snapshot of the event buffer for analysis.
  TelemetrySnapshot snapshot({
    TelemetryFilter filter        = const TelemetryFilter(),
    bool            includeLabels = true,
  }) {
    final records = _store
        .iterate(
          sessionStartUtc: _sessionStartUtc,
          symbols:         _symbols,
          filter:          filter,
        )
        .toList(growable: false);

    return TelemetrySnapshot(
      sessionStartUtc:   _sessionStartUtc,
      snapshotTakenUtc:  DateTime.now().toUtc(),
      totalStoredEvents: _store.totalStoredEvents,
      droppedEvents:     _store.droppedEvents,
      records:           records,
      symbols: includeLabels ? _symbols.snapshot() : const <int, String>{},
    );
  }

  /// Export the raw binary buffer (for offline analysis tooling).
  Uint8List exportBinary() => _store.exportBinary();

  // ─────────────────────────────────────────────────────────────────────── ──
  //  APP LIFECYCLE OBSERVER (WidgetsBindingObserver)
  // ─────────────────────────────────────────────────────────────────────── ──

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_config.captureAppLifecycle) return;
    record(
      TelemetryKind.lifecycle, 'app_lifecycle',
      context:     state.name,
      flags:       state == AppLifecycleState.resumed
                   ? TelemetryFlags.foreground
                   : TelemetryFlags.background,
      mergeSimilar: false,
    );
  }

  @override
  void didHaveMemoryPressure() {
    if (!_config.captureMemoryPressure) return;
    record(
      TelemetryKind.memory, 'memory_pressure',
      flags:       TelemetryFlags.important,
      valueA:      currentRamBytes,
      mergeSimilar: false,
    );
  }

  @override
  void didChangeMetrics() {
    record(
      TelemetryKind.lifecycle, 'metrics_changed',
      mergeSimilar: false,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §12 ─
//  NAVIGATOR OBSERVER
// ─────────────────────────────────────────────────────────────────────────────

/// Drop-in [NavigatorObserver] that records route push/pop/replace/remove
/// with accurate dwell-time measurements and TTFR (Time to First Render).
///
/// Add to [MaterialApp.navigatorObservers]:
/// ```dart
/// navigatorObservers: [TelemetryNavigatorObserver()],
/// ```
class TelemetryNavigatorObserver extends NavigatorObserver {
  final TelemetryController telemetry;

  /// Map route → elapsed-ms when the route was pushed.
  final Map<Route<dynamic>, int> _routeStartedAt = {};

  TelemetryNavigatorObserver({TelemetryController? telemetry})
      : telemetry = telemetry ?? TelemetryController.instance;

  String _routeName(Route<dynamic> route) =>
      route.settings.name ?? route.runtimeType.toString();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final int now = telemetry._nextElapsedMs();
    _routeStartedAt[route] = now;

    telemetry.record(
      TelemetryKind.route, _routeName(route),
      context:     'push',
      flags:       TelemetryFlags.enter,
      mergeSimilar: false,
    );

    // Schedule TTFR (Time to First Render) measurement.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final int ttfrMs = telemetry._nextElapsedMs() - now;
      telemetry.record(
        TelemetryKind.route, _routeName(route),
        context:     'ttfr',
        flags:       TelemetryFlags.firstPaint,
        valueA:      ttfrMs,
        mergeSimilar: false,
      );
    });

    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final int started     = _routeStartedAt.remove(route) ?? telemetry._nextElapsedMs();
    final int durationMs  = telemetry._nextElapsedMs() - started;

    telemetry.record(
      TelemetryKind.route, _routeName(route),
      context:     'pop',
      flags:       TelemetryFlags.exit,
      valueA:      durationMs,
      mergeSimilar: false,
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int now = telemetry._nextElapsedMs();

    if (oldRoute != null) {
      final int started    = _routeStartedAt.remove(oldRoute) ?? now;
      final int durationMs = now - started;
      telemetry.record(
        TelemetryKind.route, _routeName(oldRoute),
        context:     'replace_exit',
        flags:       TelemetryFlags.exit,
        valueA:      durationMs,
        mergeSimilar: false,
      );
    }

    if (newRoute != null) {
      _routeStartedAt[newRoute] = now;
      telemetry.record(
        TelemetryKind.route, _routeName(newRoute),
        context:     'replace_enter',
        flags:       TelemetryFlags.enter,
        mergeSimilar: false,
      );
    }

    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final int started    = _routeStartedAt.remove(route) ?? telemetry._nextElapsedMs();
    final int durationMs = telemetry._nextElapsedMs() - started;

    telemetry.record(
      TelemetryKind.route, _routeName(route),
      context:     'remove',
      flags:       TelemetryFlags.exit,
      valueA:      durationMs,
      mergeSimilar: false,
    );
    super.didRemove(route, previousRoute);
  }
}

// ─────────────────────────────────────────────────────────────────────── §13 ─
//  TELEMETRY SCOPE WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// A zero-overhead instrumentation wrapper for any widget or screen.
///
/// Each [TelemetryScope] tracks:
/// - Lifecycle: mount / unmount / dwell time
/// - First paint (time from `initState` → first frame callback)
/// - Rebuild count (via `didUpdateWidget`)
/// - Pointer gestures: tap, swipe, long-press, double-tap
/// - Scroll events
/// - Optional RAM delta at mount/unmount
///
/// **Runtime disable** (per-scope, zero overhead):
/// ```dart
/// TelemetryController.instance.setScopeEnabled('CheckoutScreen', false);
/// ```
///
/// **Widget-level disable** (static):
/// ```dart
/// TelemetryScope(name: 'CheckoutScreen', enabled: false, child: ...)
/// ```
class TelemetryScope extends StatefulWidget {
  final String  name;
  final Widget  child;

  // ── Feature toggles ────────────────────────────────────────────────────────
  final bool enabled;
  final bool trackLifecycle;
  final bool trackPointer;
  final bool trackScroll;
  final bool trackRebuilds;
  final bool trackFirstPaint;
  final bool trackMemory;
  final bool trackLongPress;
  final bool trackDoubleTap;

  const TelemetryScope({
    super.key,
    required this.name,
    required this.child,
    this.enabled        = true,
    this.trackLifecycle = true,
    this.trackPointer   = true,
    this.trackScroll    = true,
    this.trackRebuilds  = true,
    this.trackFirstPaint = true,
    this.trackMemory    = false,  // heavier — opt-in
    this.trackLongPress  = true,
    this.trackDoubleTap  = false, // opt-in
  });

  @override
  State<TelemetryScope> createState() => _TelemetryScopeState();
}

class _TelemetryScopeState extends State<TelemetryScope> {
  final TelemetryController _t = TelemetryController.instance;

  int? _mountedAtMs;
  int  _mountRam     = 0;
  int  _rebuildCount = 0;

  // Gesture tracking
  Offset? _pointerDown;
  int?    _pointerDownAtMs;

  // Long press tracking
  int? _longPressStartMs;

  @pragma('vm:prefer-inline')
  bool get _active =>
      widget.enabled && _t.enabled && _t.isScopeEnabled(widget.name);

  // ─────────────────────────────────────────────────────────────────────────
  //  LIFECYCLE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (!_active || !widget.trackLifecycle) return;

    _mountedAtMs = _t._nextElapsedMs();

    if (widget.trackMemory) {
      _mountRam = _t.currentRamBytes;
      _t.record(
        TelemetryKind.memory, widget.name,
        context:     'mount_ram',
        valueA:      _mountRam,
        mergeSimilar: false,
      );
    }

    _t.record(
      TelemetryKind.screen, widget.name,
      context:     'mount',
      flags:       TelemetryFlags.enter,
      mergeSimilar: false,
    );

    if (widget.trackFirstPaint) {
      final int mountMs = _mountedAtMs!;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final int firstPaintMs = _t._nextElapsedMs() - mountMs;
        _t.record(
          TelemetryKind.widget, widget.name,
          context:     'first_paint',
          flags:       TelemetryFlags.firstPaint,
          valueA:      firstPaintMs,
          mergeSimilar: false,
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant TelemetryScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active || !widget.trackRebuilds) return;
    _rebuildCount++;
    _t.record(
      TelemetryKind.widget, widget.name,
      context:     'rebuild',
      flags:       TelemetryFlags.reactive,
      valueA:      _rebuildCount,
      mergeSimilar: true,
    );
  }

  @override
  void dispose() {
    if (_active && widget.trackLifecycle && _mountedAtMs != null) {
      final int durationMs = _t._nextElapsedMs() - _mountedAtMs!;
      _t.record(
        TelemetryKind.screen, widget.name,
        context:     'unmount',
        flags:       TelemetryFlags.exit,
        valueA:      durationMs,
        valueB:      _rebuildCount,
        mergeSimilar: false,
      );

      if (widget.trackMemory) {
        final int nowRam   = _t.currentRamBytes;
        final int deltaRam = nowRam - _mountRam;
        _t.record(
          TelemetryKind.memory, widget.name,
          context:     'unmount_ram_delta',
          valueA:      nowRam,
          valueB:      deltaRam,
          mergeSimilar: false,
        );
      }
    }
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  POINTER HANDLING
  // ─────────────────────────────────────────────────────────────────────────

  void _handlePointerDown(PointerDownEvent e) {
    if (!_active || !widget.trackPointer) return;
    _pointerDown      = e.localPosition;
    _pointerDownAtMs  = _t._nextElapsedMs();
    _t.record(
      TelemetryKind.interaction, widget.name,
      context: 'pointer_down',
      valueA:  e.localPosition.dx.round(),
      valueB:  e.localPosition.dy.round(),
      mergeSimilar: false,
    );
  }

  void _handlePointerUp(PointerUpEvent e) {
    if (!_active || !widget.trackPointer) return;
    if (_pointerDown == null || _pointerDownAtMs == null) return;

    final Offset up         = e.localPosition;
    final double dx         = (up.dx - _pointerDown!.dx).abs();
    final double dy         = (up.dy - _pointerDown!.dy).abs();
    final int    durationMs = _t._nextElapsedMs() - _pointerDownAtMs!;
    final bool   isSwipe    = (dx + dy) > 10;

    _t.record(
      TelemetryKind.interaction, widget.name,
      context:     isSwipe ? 'swipe' : 'tap',
      flags:       isSwipe ? TelemetryFlags.swipe : TelemetryFlags.tap,
      valueA:      up.dx.round(),
      valueB:      up.dy.round(),
      valueC:      durationMs,
      mergeSimilar: false,
    );

    _pointerDown     = null;
    _pointerDownAtMs = null;
  }

  void _handlePointerCancel(PointerCancelEvent e) {
    if (!_active || !widget.trackPointer) return;
    _t.record(
      TelemetryKind.interaction, widget.name,
      context:     'pointer_cancel',
      mergeSimilar: false,
    );
    _pointerDown     = null;
    _pointerDownAtMs = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LONG PRESS / DOUBLE TAP GESTURE CALLBACKS
  // ─────────────────────────────────────────────────────────────────────────

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_active || !widget.trackLongPress) return;
    _longPressStartMs = _t._nextElapsedMs();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_active || !widget.trackLongPress || _longPressStartMs == null) return;
    final int durationMs = _t._nextElapsedMs() - _longPressStartMs!;
    _t.record(
      TelemetryKind.interaction, widget.name,
      context:     'long_press',
      flags:       TelemetryFlags.longPress,
      valueA:      details.localPosition.dx.round(),
      valueB:      details.localPosition.dy.round(),
      valueC:      durationMs,
      mergeSimilar: false,
    );
    _longPressStartMs = null;
  }

  void _handleDoubleTap() {
    if (!_active || !widget.trackDoubleTap) return;
    _t.record(
      TelemetryKind.interaction, widget.name,
      context:     'double_tap',
      flags:       TelemetryFlags.doubleTap,
      mergeSimilar: false,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  SCROLL
  // ─────────────────────────────────────────────────────────────────────────

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_active || !widget.trackScroll) return false;

    final String ctx = switch (notification.runtimeType) {
      ScrollStartNotification  => 'scroll_start',
      ScrollUpdateNotification => 'scroll_update',
      ScrollEndNotification    => 'scroll_end',
      UserScrollNotification   => 'user_scroll',
      OverscrollNotification   => 'overscroll',
      _                        => 'scroll',
    };

    final int pixels       = notification.metrics.pixels.round();
    final int extentBefore = notification.metrics.extentBefore.round();
    final int extentAfter  = notification.metrics.extentAfter.round();

    _t.record(
      TelemetryKind.scroll, widget.name,
      context:     ctx,
      valueA:      pixels,
      valueB:      extentBefore,
      valueC:      extentAfter,
      mergeSimilar: notification is ScrollUpdateNotification,
    );

    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    Widget child = widget.child;

    if (_active && widget.trackScroll) {
      child = NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: child,
      );
    }

    if (_active && (widget.trackLongPress || widget.trackDoubleTap)) {
      child = GestureDetector(
        behavior:             HitTestBehavior.translucent,
        onLongPressStart:     widget.trackLongPress ? _handleLongPressStart : null,
        onLongPressEnd:       widget.trackLongPress ? _handleLongPressEnd   : null,
        onDoubleTap:          widget.trackDoubleTap ? _handleDoubleTap      : null,
        child: child,
      );
    }

    if (_active && widget.trackPointer) {
      child = Listener(
        behavior:        HitTestBehavior.translucent,
        onPointerDown:   _handlePointerDown,
        onPointerUp:     _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: child,
      );
    }

    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────── §14 ─
//  VM BRIDGE — OPT-IN QUANTUMVM INTEGRATION
// ─────────────────────────────────────────────────────────────────────────────

/// Opt-in bridge that connects [TelemetryController] to the QuantumVM action
/// pipeline and compilation system.
///
/// **Usage** (call once, before or after [TelemetryController.install]):
/// ```dart
/// // In main.dart or QuantumVM.initialize():
/// QuantumVM.instance.setMiddlewares([
///   TelemetryVMBridge.buildActionMiddleware(),
///   // …other middlewares…
/// ]);
/// ```
///
/// **QLSmartView integration** (wrap _processManifest manually):
/// ```dart
/// final ticket = TelemetryVMBridge.beginSmartViewCompile(viewId);
/// await QLCompiler.compileAsync(uiNode, macros, env);
/// TelemetryVMBridge.endSmartViewCompile(ticket);
/// ```
///
/// This class has **zero imports from quantum_vm.dart** — it is fully
/// self-contained inside `quantum_telemetry_engine.dart`. The VM side
/// only needs to call the returned `Function` / methods.
abstract final class TelemetryVMBridge {

  /// Build an [ActionMiddleware]-compatible closure for use with
  /// `QuantumVM.instance.setMiddlewares([...])`.
  ///
  /// The returned function has the exact signature required by
  /// `ActionMiddleware` in `quantum_vm.dart`:
  /// ```dart
  /// typedef ActionMiddleware = Future<void> Function(
  ///   String action,
  ///   Map<String, dynamic> payload,
  ///   Future<void> Function() next,
  /// );
  /// ```
  ///
  /// Call this at startup:
  /// ```dart
  /// QuantumVM.instance.setMiddlewares([TelemetryVMBridge.buildActionMiddleware()]);
  /// ```
  static Future<void> Function(
    String action,
    Map<String, dynamic> payload,
    Future<void> Function() next,
  ) buildActionMiddleware() {
    return (String action, Map<String, dynamic> payload, Future<void> Function() next) async {
      final ctrl   = TelemetryController.instance;
      final spanId = ctrl.beginAction(action);
      try {
        await next();
        ctrl.endAction(spanId, success: true);
      } catch (e) {
        ctrl.endAction(spanId, success: false);
        rethrow;
      }
    };
  }

  // ── QLSmartView compilation hooks ─────────────────────────────────────────

  /// Begin tracking a QLSmartView / QLCompiler compile pass for [viewId].
  /// Returns a ticket to pass to [endSmartViewCompile].
  static int beginSmartViewCompile(String viewId) =>
      TelemetryController.instance.beginCompile(viewId);

  /// Complete a compilation pass started with [beginSmartViewCompile].
  /// Set [fromCache] = true if the blueprint was served from the AST cache.
  static void endSmartViewCompile(int ticket, {bool fromCache = false}) =>
      TelemetryController.instance.endCompile(ticket, fromCache: fromCache);

  /// Record the first-frame timestamp of a QLSmartView after its AST is built.
  /// Call this inside an `addPostFrameCallback` inside `QLSmartView.build()`.
  static void onSmartViewFirstFrame(String viewId, int compileStartMs) {
    final ctrl = TelemetryController.instance;
    if (!ctrl.enabled) return;
    final int ttfr = ctrl._nextElapsedMs() - compileStartMs;
    ctrl.record(
      TelemetryKind.vm, viewId,
      context:     'smart_view_first_frame',
      flags:       TelemetryFlags.firstPaint | TelemetryFlags.compile,
      valueA:      ttfr,
      mergeSimilar: false,
    );
  }

  // ── Reactive rebuild hook ─────────────────────────────────────────────────

  /// Call from `_QLReactiveNodeBoundary._buildSafeContent` to count rebuilds.
  /// This is a one-liner addition — zero behavioural change:
  /// ```dart
  /// TelemetryVMBridge.onReactiveBuild(widget.node.debugPath);
  /// ```
  static void onReactiveBuild(String nodePath) =>
      TelemetryController.instance.onReactiveBuild(nodePath);

  // ── Data load hooks (QLStoreSlice / _SliceQueryPlugin) ───────────────────

  /// Begin tracking a QLStoreSlice query load.
  /// ```dart
  /// // In _SliceQueryPlugin.execute():
  /// final ticket = TelemetryVMBridge.beginQueryLoad('cart.loadCart');
  /// ```
  static int beginQueryLoad(String queryName) =>
      TelemetryController.instance.beginDataLoad(queryName, context: 'vm_query');

  /// Complete a QLStoreSlice query load.
  static void endQueryLoad(int ticket, {bool success = true}) =>
      TelemetryController.instance.endDataLoad(ticket, success: success);
}

// ─────────────────────────────────────────────────────────────────────── §15 ─
//  SNAPSHOT ANALYTICS EXTENSION
// ─────────────────────────────────────────────────────────────────────────────

/// Pre-built analytics aggregations on top of [TelemetrySnapshot].
/// All methods are O(n) in the number of records — take snapshots at the
/// reporting layer, not in the hot path.
extension TelemetrySnapshotAnalytics on TelemetrySnapshot {

  // ─── Session ──────────────────────────────────────────────────────────────

  /// Total wall-clock time of the session.
  Duration get totalSessionTime => Duration(
    milliseconds: snapshotTakenUtc.difference(sessionStartUtc).inMilliseconds,
  );

  // ─── Screen dwell times ───────────────────────────────────────────────────

  /// Average time spent on each screen in milliseconds.
  /// Only considers [TelemetryKind.screen] exit events (unmount).
  Map<String, int> avgDwellTimeByScreen() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.screen || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }

  // ─── Widget first paint ───────────────────────────────────────────────────

  /// Average first-paint latency per widget scope name (ms).
  Map<String, int> avgFirstPaintByWidget() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.widget) continue;
      if ((r.flags & TelemetryFlags.firstPaint) == 0) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }

  // ─── Rebuild counts ───────────────────────────────────────────────────────

  /// Total rebuild count per widget scope name.
  Map<String, int> rebuildCountByWidget() {
    final out = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.widget) continue;
      if ((r.flags & TelemetryFlags.reactive) == 0) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      // valueA carries the running rebuild count at event time; take the max.
      if ((out[label] ?? 0) < r.valueA) out[label] = r.valueA;
    }
    return out;
  }

  /// The [limit] most-rebuilt widgets, ordered descending.
  List<MapEntry<String, int>> topRebuildWidgets({int limit = 10}) {
    final counts = rebuildCountByWidget().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return counts.take(limit).toList();
  }

  // ─── Data timings ─────────────────────────────────────────────────────────

  /// Average data fetch duration per data-load name (ms).
  Map<String, int> avgDataLoadDurationByName() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.data || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }

  /// Data load failure rate per name (0.0–1.0).
  Map<String, double> dataLoadFailureRate() {
    final totals   = <String, int>{};
    final failures = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.data || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label]   = (totals[label] ?? 0) + 1;
      if (r.isFailure) failures[label] = (failures[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, (failures[k] ?? 0) / v));
  }

  // ─── Image timings ────────────────────────────────────────────────────────

  /// Average image load time per URL label (ms).
  Map<String, int> avgImageLoadTimeByUrl() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.image || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }

  /// Image cache hit ratio (0.0–1.0) across all image events.
  double get imageCacheHitRate {
    int hits = 0, total = 0;
    for (final r in records) {
      if (r.kind != TelemetryKind.image || !r.isExit) continue;
      total++;
      if (r.isCacheHit) hits++;
    }
    return total == 0 ? 0.0 : hits / total;
  }

  // ─── Frame performance ────────────────────────────────────────────────────

  /// All jank frames (total build+raster > jank threshold).
  List<TelemetryRecord> jankFrames({int thresholdMs = 16}) =>
      records.where((r) =>
        r.kind == TelemetryKind.frame &&
        r.isJank &&
        r.valueC >= thresholdMs,
      ).toList(growable: false);

  /// All slow frames (total > slow threshold but below jank threshold).
  List<TelemetryRecord> slowFrames({int thresholdMs = 8}) =>
      records.where((r) =>
        r.kind == TelemetryKind.frame &&
        r.isSlow &&
        !r.isJank,
      ).toList(growable: false);

  /// Total number of jank frames recorded.
  int get totalJankFrames =>
      records.where((r) => r.kind == TelemetryKind.frame && r.isJank).length;

  /// Average total frame time in milliseconds (build + raster).
  double get avgFrameMs {
    final frames = records
        .where((r) => r.kind == TelemetryKind.frame)
        .toList(growable: false);
    if (frames.isEmpty) return 0.0;
    return frames.fold<int>(0, (s, r) => s + r.valueC) / frames.length;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  /// Average VM action duration per action name (ms).
  Map<String, int> avgActionDurationByName() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.vm || !r.isAction || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }

  /// Action failure rate per name (0.0–1.0).
  Map<String, double> actionFailureRate() {
    final totals   = <String, int>{};
    final failures = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.vm || !r.isAction || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label]   = (totals[label] ?? 0) + 1;
      if (r.isFailure) failures[label] = (failures[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, (failures[k] ?? 0) / v));
  }

  // ─── Compilation ─────────────────────────────────────────────────────────

  /// Average compile duration per view ID (ms).
  Map<String, int> avgCompileDurationByView() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.vm || !r.isCompile || !r.isExit) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }

  /// Compile cache hit rate (0.0–1.0).
  double get compileCacheHitRate {
    int hits = 0, total = 0;
    for (final r in records) {
      if (r.kind != TelemetryKind.vm || !r.isCompile || !r.isExit) continue;
      total++;
      if (r.isCacheHit) hits++;
    }
    return total == 0 ? 0.0 : hits / total;
  }

  // ─── Reactive hotspots ────────────────────────────────────────────────────

  /// The [limit] most-rebuilt reactive node paths, ordered descending.
  List<MapEntry<String, int>> reactiveRebuildHotspots({int limit = 10}) {
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.vm || !r.isReactive) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      counts[label] = (counts[label] ?? 0) + r.valueC;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // ─── Interactions ─────────────────────────────────────────────────────────

  /// Total recorded interactions (taps + swipes + long-press + double-tap).
  int get totalInteractions =>
      records.where((r) => r.kind == TelemetryKind.interaction).length;

  /// The [limit] most-tapped widget scope names.
  List<MapEntry<String, int>> topTappedWidgets({int limit = 10}) {
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.interaction) continue;
      if ((r.flags & TelemetryFlags.tap) == 0) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// Maximum scroll depth (pixels) per screen scope name.
  Map<String, int> scrollDepthByScreen() {
    final out = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.scroll) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      if ((out[label] ?? 0) < r.valueA) out[label] = r.valueA;
    }
    return out;
  }

  // ─── Memory ───────────────────────────────────────────────────────────────

  /// Peak RSS bytes per screen scope name.
  Map<String, int> peakRamByScreen() {
    final out = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.memory) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      if ((out[label] ?? 0) < r.valueA) out[label] = r.valueA;
    }
    return out;
  }

  /// RAM delta (bytes) at unmount, per screen scope name.
  /// Positive = memory was allocated; negative = freed.
  Map<String, int> ramDeltaByScreen() {
    final out = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.memory) continue;
      final ctx = r.contextLabel ?? '';
      if (!ctx.contains('delta')) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      out[label] = r.valueB; // valueB = delta bytes
    }
    return out;
  }

  // ─── Errors ───────────────────────────────────────────────────────────────

  /// Error event count per error type.
  Map<String, int> errorCountByType() {
    final out = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.error) continue;
      final label = r.contextLabel ?? r.targetLabel ?? 'unknown';
      out[label] = (out[label] ?? 0) + 1;
    }
    return out;
  }

  // ─── User Journey / Funnel ────────────────────────────────────────────────

  /// All journey step events for [journeyName], in chronological order.
  List<TelemetryRecord> journeyFunnel(String journeyName) {
    final hash = TelemetryHash.fnv1a32(journeyName);
    return records
        .where((r) => r.kind == TelemetryKind.journey && r.targetHash == hash)
        .toList(growable: false);
  }

  /// Count of events at each step index for [journeyName].
  /// Use this to find at which step users drop off.
  Map<int, int> journeyStepCounts(String journeyName) {
    final out = <int, int>{};
    for (final r in journeyFunnel(journeyName)) {
      out[r.valueA] = (out[r.valueA] ?? 0) + 1;
    }
    return out;
  }

  // ─── Route TTFR ──────────────────────────────────────────────────────────

  /// Average TTFR (Time to First Render) per route name (ms).
  Map<String, int> avgTtfrByRoute() {
    final totals = <String, int>{};
    final counts = <String, int>{};
    for (final r in records) {
      if (r.kind != TelemetryKind.route) continue;
      if ((r.flags & TelemetryFlags.firstPaint) == 0) continue;
      final label = r.targetLabel ?? 'hash:${r.targetHash}';
      totals[label] = (totals[label] ?? 0) + r.valueA;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return totals.map((k, v) => MapEntry(k, v ~/ (counts[k] ?? 1)));
  }
}

// ─────────────────────────────────────────────────────────────────────── §16 ─
//  TELEMETRY TIMING EXTENSION (v1 BACKWARD COMPATIBILITY)
// ─────────────────────────────────────────────────────────────────────────────

/// Shorthand helpers on [TelemetryController]. Fully backward-compatible with v1.
extension TelemetryTiming on TelemetryController {
  /// Synchronously time [body] under the given span [name].
  T track<T>(
    String name,
    T Function() body, {
    String? context,
    int     flags = TelemetryFlags.none,
  }) {
    return measure<T>(name, body, context: context, flags: flags);
  }

  /// Asynchronously time [body] under the given span [name].
  Future<T> trackAsync<T>(
    String name,
    Future<T> Function() body, {
    String? context,
    int     flags = TelemetryFlags.none,
  }) {
    return measureAsync<T>(name, body, context: context, flags: flags);
  }
}

// ─────────────────────────────────────────────────────────────────────── §17 ─
//  USAGE REFERENCE
// ─────────────────────────────────────────────────────────────────────────────
//
// ── 1. Install (in main.dart, before runApp) ─────────────────────────────────
//
//   void main() {
//     TelemetryController.instance.install(
//       config: const TelemetryConfig(
//         maxEvents:            16384,
//         captureFrameTimings:  true,
//         captureVMActions:     true,
//         captureVMCompilation: true,
//         captureImageTimings:  true,
//         captureMemoryOnScreen: true,
//       ),
//     );
//
//     runApp(MaterialApp(
//       navigatorObservers: [TelemetryNavigatorObserver()],
//       home: MyApp(),
//     ));
//   }
//
// ── 2. Wrap screens / widgets ─────────────────────────────────────────────────
//
//   TelemetryScope(
//     name: 'HomeScreen',
//     trackFirstPaint: true,
//     trackMemory:     true,
//     trackLongPress:  true,
//     child: HomeScreenBody(),
//   )
//
// ── 3. Track images ───────────────────────────────────────────────────────────
//
//   final ticket = TelemetryController.instance.beginImageLoad(imageUrl);
//   // … load image …
//   TelemetryController.instance.endImageLoad(ticket, bytes: 24500);
//
// ── 4. Track data fetches ─────────────────────────────────────────────────────
//
//   final span = TelemetryController.instance.beginDataLoad('products_feed');
//   try {
//     final data = await api.getProducts();
//     TelemetryController.instance.endDataLoad(span, success: true);
//   } catch (_) {
//     TelemetryController.instance.endDataLoad(span, success: false);
//   }
//
// ── 5. Track VM actions (via QuantumVM middleware) ────────────────────────────
//
//   QuantumVM.instance.setMiddlewares([
//     TelemetryVMBridge.buildActionMiddleware(),
//   ]);
//
// ── 6. Track QLSmartView compile+render ──────────────────────────────────────
//
//   // Inside _QLSmartViewState._processManifest():
//   final ticket = TelemetryVMBridge.beginSmartViewCompile(widget.manifest['id'] ?? 'view');
//   final ast = await QLCompiler.compileAsync(uiNode, macros, env);
//   TelemetryVMBridge.endSmartViewCompile(ticket);
//
// ── 7. Disable a scope at runtime ────────────────────────────────────────────
//
//   TelemetryController.instance.setScopeEnabled('CheckoutScreen', false);
//
// ── 8. Take a snapshot and analyse ───────────────────────────────────────────
//
//   final snap = TelemetryController.instance.snapshot();
//   final dwellTimes   = snap.avgDwellTimeByScreen();
//   final jankFrames   = snap.jankFrames(thresholdMs: 16);
//   final topTaps      = snap.topTappedWidgets(limit: 5);
//   final actionTimes  = snap.avgActionDurationByName();
//   final ttfr         = snap.avgTtfrByRoute();
//   final cacheHitRate = snap.imageCacheHitRate;
//   final funnel       = snap.journeyFunnel('onboarding');
//
// ── 9. Journey / funnel step tracking ────────────────────────────────────────
//
//   TelemetryController.instance.recordJourneyStep('onboarding', step: 0, label: 'welcome');
//   TelemetryController.instance.recordJourneyStep('onboarding', step: 1, label: 'permissions');
//   TelemetryController.instance.recordJourneyStep('onboarding', step: 2, label: 'account_created');
//
// ── 10. Globally disable (zero overhead) ─────────────────────────────────────
//
//   TelemetryController.instance.setEnabled(false);
//
// ── 11. Disable within a specific code section ───────────────────────────────
//
//   TelemetryController.instance.withDisabled(() {
//     // This entire block emits zero telemetry events.
//     someNoisyOperation();
//   });


// ─────────────────────────────────────────────────────────────────────── §18 ─
//  V1 BACKWARD-COMPATIBILITY SHIMS
//  These names were referenced by quantum_app_shell.dart before the v2 rewrite.
//  All existing call-sites continue to compile without modification.
// ─────────────────────────────────────────────────────────────────────────────

// ── QLType ───────────────────────────────────────────────────────────────────
enum QLType {
  app, route, screen, widget, lifecycle, interaction, scroll,
  network, metric, error, custom, image, memory, data, journey, frame, vm,
  anomaly,
}

TelemetryKind _qlTypeToKind(QLType t) {
  switch (t) {
    case QLType.app:         return TelemetryKind.app;
    case QLType.route:       return TelemetryKind.route;
    case QLType.screen:      return TelemetryKind.screen;
    case QLType.widget:      return TelemetryKind.widget;
    case QLType.lifecycle:   return TelemetryKind.lifecycle;
    case QLType.interaction: return TelemetryKind.interaction;
    case QLType.scroll:      return TelemetryKind.scroll;
    case QLType.network:     return TelemetryKind.network;
    case QLType.metric:      return TelemetryKind.metric;
    case QLType.error:       return TelemetryKind.error;
    case QLType.custom:      return TelemetryKind.custom;
    case QLType.image:       return TelemetryKind.image;
    case QLType.memory:      return TelemetryKind.memory;
    case QLType.data:        return TelemetryKind.data;
    case QLType.journey:     return TelemetryKind.journey;
    case QLType.frame:       return TelemetryKind.frame;
    case QLType.vm:          return TelemetryKind.vm;
    case QLType.anomaly:     return TelemetryKind.error;
  }
}

// ── QuantumTelemetry — v1 facade over TelemetryController ───────────────────
class QuantumTelemetry {
  QuantumTelemetry._();
  static final QuantumTelemetry instance = QuantumTelemetry._();

  void install({TelemetryConfig? config}) =>
      TelemetryController.instance.install(config: config);

  bool get enabled => TelemetryController.instance.enabled;
  void setEnabled(bool v) => TelemetryController.instance.setEnabled(v);

  void record(
    QLType type,
    String target, {
    String? context,
    int valueA = 0,
    int valueB = 0,
    int valueC = 0,
    int flags  = TelemetryFlags.none,
  }) {
    TelemetryController.instance.record(
      _qlTypeToKind(type), target,
      context:      context,
      valueA:       valueA,
      valueB:       valueB,
      valueC:       valueC,
      flags: type == QLType.anomaly ? flags | TelemetryFlags.important : flags,
      mergeSimilar: false,
    );
  }

  void recordError(Object error, StackTrace stack, {String label = 'error'}) =>
      TelemetryController.instance.recordError(error, stack, label: label);

  TelemetrySnapshot snapshot({TelemetryFilter filter = const TelemetryFilter()}) =>
      TelemetryController.instance.snapshot(filter: filter);
}

// ── QuantumSingularity — app-root error-boundary launcher ───────────────────
abstract final class QuantumSingularity {
  static void ignite({
    required Widget Function() appBuilder,
    void Function()? bootSequence,
    Widget Function(dynamic error, StackTrace stack, Map<String, dynamic> dump)?
        fallbackUI,
  }) {
    TelemetryController.instance.install();
    Widget buildRoot() {
      try {
        bootSequence?.call();
      } catch (e, st) {
        TelemetryController.instance
            .recordError(e, st, label: 'singularity_boot_failure');
        if (fallbackUI != null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Builder(builder: (ctx) => fallbackUI(e, st, {'phase': 'boot'})),
          );
        }
        rethrow;
      }
      return appBuilder();
    }
    runApp(_QuantumSingularityRoot(builder: buildRoot, fallbackUI: fallbackUI));
  }
}

class _QuantumSingularityRoot extends StatefulWidget {
  final Widget Function() builder;
  final Widget Function(dynamic, StackTrace, Map<String, dynamic>)? fallbackUI;
  const _QuantumSingularityRoot({required this.builder, this.fallbackUI});

  @override
  State<_QuantumSingularityRoot> createState() =>
      _QuantumSingularityRootState();
}

class _QuantumSingularityRootState extends State<_QuantumSingularityRoot> {
  Object?     _fatalError;
  StackTrace? _fatalStack;

  @override
  void initState() {
    super.initState();
    if (widget.fallbackUI == null) return;
    final FlutterExceptionHandler? prev = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted && !details.silent) {
        setState(() {
          _fatalError = details.exception;
          _fatalStack = details.stack ?? StackTrace.current;
        });
      }
      prev?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null && widget.fallbackUI != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (ctx) => widget.fallbackUI!(_fatalError!, _fatalStack!, {}),
        ),
      );
    }
    try {
      return widget.builder();
    } catch (e, st) {
      TelemetryController.instance
          .recordError(e, st, label: 'singularity_root_crash');
      if (widget.fallbackUI != null) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Builder(
            builder: (ctx) => widget.fallbackUI!(e, st, {'phase': 'build'}),
          ),
        );
      }
      rethrow;
    }
  }
}
