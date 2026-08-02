/*
 * ============================================================================
 * File: qte_reactive.dart
 * 
 * Description:
 * Implements a reactive watcher for the Quantum Test Engine that monitors state changes
 * within the Quantum Layout data store. It tracks when specific keys are updated,
 * records the dispatched actions, and provides utilities to wait asynchronously for
 * signals or expected state values during test execution.
 * 
 * Key Components:
 * - QTESignalEvent: Represents a change in a monitored store key.
 * - QTEActionCallEvent: Records the invocation of an SDUI action and its payload.
 * - QTEReactiveWatcher: Subscribes to the QLDataStore to track state mutations and action triggers.
 * 
 * Dependencies/Relationships:
 * Depends on quantum_layout (QLDataStore).
 * Used extensively by qte_interaction.dart and qte_assertion.dart to verify that
 * user interactions produced the expected logical side effects.
 * 
 * Notes:
 * The watcher must be explicitly started and stopped. It polls or hooks into persistence
 * listeners to detect differences from the _lastKnownValues cache.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE REACTIVE WATCHER — qte_reactive.dart
// Listens to QLDataStore signals, records key changes, waits for specific values.
// ══════════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:quantum_layout/quantum.dart';

class QTESignalEvent {
  final String key;
  final dynamic previousValue;
  final dynamic newValue;
  final DateTime timestamp;
  final String stepId;

  const QTESignalEvent({
    required this.key,
    required this.previousValue,
    required this.newValue,
    required this.timestamp,
    required this.stepId,
  });

  Map<String, dynamic> toJson() => {
    'key': key,
    'previousValue': previousValue?.toString(),
    'newValue': newValue?.toString(),
    'timestamp': timestamp.toIso8601String(),
    'stepId': stepId,
  };

  @override
  String toString() =>
      '[QTESignal] $key: ${previousValue?.toString() ?? "null"} → ${newValue?.toString() ?? "null"} (step: $stepId)';
}

class QTEActionCallEvent {
  final String actionName;
  final Map<String, dynamic> payload;
  final dynamic result;
  final DateTime timestamp;
  final String stepId;
  final bool succeeded;

  const QTEActionCallEvent({
    required this.actionName,
    required this.payload,
    this.result,
    required this.timestamp,
    required this.stepId,
    this.succeeded = true,
  });

  Map<String, dynamic> toJson() => {
    'actionName': actionName,
    'payload': payload,
    'result': result?.toString(),
    'timestamp': timestamp.toIso8601String(),
    'stepId': stepId,
    'succeeded': succeeded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────

class QTEReactiveWatcher {
  final QLDataStore store;

  final List<QTESignalEvent> _signalEvents = [];
  final List<QTEActionCallEvent> _actionEvents = [];
  final Map<String, dynamic> _lastKnownValues = {};
  final Map<String, int> _rebuildCounts = {};

  String _currentStepId = '';
  VoidCallback? _storeListener;
  bool _active = false;

  QTEReactiveWatcher(this.store);

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  void start() {
    if (_active) return;
    _active = true;
    _storeListener = _onStoreChange;
    store.addPersistenceListener(_storeListener!);
    debugPrint('[QTEReactive] Watcher started');
  }

  void stop() {
    if (!_active) return;
    _active = false;
    if (_storeListener != null) {
      try { store.removePersistenceListener(_storeListener!); } catch (_) {}
      _storeListener = null;
    }
    debugPrint('[QTEReactive] Watcher stopped');
  }

  void setCurrentStep(String stepId) {
    _currentStepId = stepId;
  }

  void reset() {
    _signalEvents.clear();
    _actionEvents.clear();
    _lastKnownValues.clear();
    _rebuildCounts.clear();
  }

  // ── Store change listener ──────────────────────────────────────────────────
  void _onStoreChange() {
    // We detect what changed by comparing to last known values.
    // For each key we care about, check if value changed.
    for (final key in List<String>.from(_lastKnownValues.keys)) {
      final current = store.get(key);
      final previous = _lastKnownValues[key];
      if (current != previous) {
        _signalEvents.add(QTESignalEvent(
          key: key,
          previousValue: previous,
          newValue: current,
          timestamp: DateTime.now(),
          stepId: _currentStepId,
        ));
        _lastKnownValues[key] = current;
      }
    }
  }

  // ── Watch a specific store key ─────────────────────────────────────────────
  void watchKey(String key) {
    if (!_lastKnownValues.containsKey(key)) {
      _lastKnownValues[key] = store.get(key);
    }
  }

  void watchKeys(Iterable<String> keys) {
    for (final k in keys) {
      watchKey(k);
    }
  }

  // ── Track action calls ─────────────────────────────────────────────────────
  void recordAction(String name, Map<String, dynamic> payload,
      {dynamic result, bool succeeded = true}) {
    _actionEvents.add(QTEActionCallEvent(
      actionName: name,
      payload: payload,
      result: result,
      timestamp: DateTime.now(),
      stepId: _currentStepId,
      succeeded: succeeded,
    ));
  }

  // ── Track widget rebuilds ─────────────────────────────────────────────────
  void recordRebuild(String widgetKey) {
    _rebuildCounts[widgetKey] = (_rebuildCounts[widgetKey] ?? 0) + 1;
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  bool wasKeyChanged(String key) =>
      _signalEvents.any((e) => e.key == key);

  bool wasSignalEmitted(String key) => wasKeyChanged(key);

  dynamic latestSignalValue(String key) {
    final events = _signalEvents.where((e) => e.key == key).toList();
    return events.isEmpty ? null : events.last.newValue;
  }

  bool wasActionCalled(String actionName) =>
      _actionEvents.any((e) => e.actionName == actionName);

  dynamic latestActionResult(String actionName) {
    final events = _actionEvents.where((e) => e.actionName == actionName).toList();
    return events.isEmpty ? null : events.last.result;
  }

  int rebuildCount(String widgetKey) => _rebuildCounts[widgetKey] ?? 0;

  List<QTESignalEvent> get allSignalEvents => List.unmodifiable(_signalEvents);
  List<QTEActionCallEvent> get allActionEvents => List.unmodifiable(_actionEvents);

  // ── Wait for signal ────────────────────────────────────────────────────────
  Future<bool> waitForSignal(
    String key, {
    dynamic expectedValue,
    int timeoutMs = 3000,
    int pollIntervalMs = 50,
  }) async {
    watchKey(key);
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      final current = store.get(key);
      if (expectedValue == null) {
        // Just wait for any change
        if (wasKeyChanged(key)) return true;
      } else {
        // Wait for specific value
        if (_valuesMatch(current, expectedValue)) return true;
      }
      await Future.delayed(Duration(milliseconds: pollIntervalMs));
    }
    return false;
  }

  bool _valuesMatch(dynamic actual, dynamic expected) {
    if (actual == expected) return true;
    if (actual?.toString() == expected?.toString()) return true;
    return false;
  }

  // ── Snapshot ──────────────────────────────────────────────────────────────
  Map<String, dynamic> snapshot() => {
    'signalEvents': _signalEvents.map((e) => e.toJson()).toList(),
    'actionEvents': _actionEvents.map((e) => e.toJson()).toList(),
    'rebuildCounts': Map<String, dynamic>.from(_rebuildCounts),
    'watchedKeys': List<String>.from(_lastKnownValues.keys),
  };
}
