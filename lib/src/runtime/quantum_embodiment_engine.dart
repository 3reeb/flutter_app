// ════════════════════════════════════════════════════════════════════════════
// QUANTUM EMBODIMENT ENGINE (QEE) v1.0 — RUNTIME INTERACTION ENGINE
// quantum_embodiment_engine.dart
//
// The AI's hands, eyes, and ears. Not a test runner — a live environment
// simulator that lets you execute, observe, inject, assert, trace, and
// persist ANY operation the Quantum framework can perform.
//
// ARCHITECTURE (9 sections):
//  §0  Types & Enums        — status, kind, severity, trigger taxonomy
//  §1  Probe Layer          — UI, data, layout, telemetry, memory, vm, error
//  §2  Executor Layer       — widget, vm, json, data, action, layout, script
//  §3  Assertion Engine     — typed matchers + diff
//  §4  Trace & Step         — structured execution record with diffs
//  §5  Policy Engine        — runtime watchers + persistent assertion rules
//  §6  Store Layer          — SQLite persistence + full query API
//  §7  QEmbodiment          — top-level DSL singleton
//  §8  ScenarioBuilder      — fluent multi-step builder
//  §9  SafeWrapper          — client-side zero-overhead harness widget
//
// PERFORMANCE DESIGN:
//  • Stopwatch microsecond resolution on every step — zero blocking I/O
//  • All hot paths annotated @pragma('vm:prefer-inline')
//  • Lazy data snapshot — O(1) read from existing QLDataStore map copy
//  • SQLite write is unawaited / fire-and-forget — never blocks execution
//  • Policy evaluation is O(n·policies) per step, skipped in kReleaseMode
//  • SafeWrapper has exactly zero cost in kReleaseMode (compile-time const)
// ════════════════════════════════════════════════════════════════════════════

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io' show ProcessInfo;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:quantum_layout/quantum.dart';
// ─────────────────────────────────────────────────────────────────────── §0 ─
//  TYPES, ENUMS & CONFIG
// ────────────────────────────────────────────────────────────────────────────

/// Overall result of a QEE execution (trace or step).
enum QEEStatus { passed, failed, skipped, error, cancelled }

/// The kind of operation a step represents.
enum QEEKind {
  widget,
  vm,
  json,
  data,
  action,
  layout,
  theme,
  navigation,
  schema,
  api,
  script,
  assertion,
  probe,
}

/// Policy violation severity.
enum PolicySeverity { observe, warn, error, fatal }

/// When a policy rule is evaluated.
enum PolicyTriggerEvent {
  onStepStart,
  onStepEnd,
  onDataChange,
  onAction,
  onRender,
  onError,
  always,
}

/// Which probes to collect on a step.
enum QEEProbeKind { ui, data, layout, telemetry, memory, error, all }

/// Configures the QEE runtime globally.
class QEEConfig {
  /// Custom SQLite path. Defaults to `<appDocDir>/qee_store.db`.
  final String? dbPath;

  /// Whether to collect data-store snapshots per step.
  final bool captureData;

  /// Whether to attach TelemetryController events to each step.
  final bool captureTelemetry;

  /// Whether to measure RSS memory delta per step (non-release only).
  final bool captureMemory;

  /// Print a rich log line on each step completion.
  final bool verboseLog;

  /// If true, a [PolicySeverity.fatal] violation throws immediately.
  final bool fatalThrows;

  const QEEConfig({
    this.dbPath,
    this.captureData = true,
    this.captureTelemetry = true,
    this.captureMemory = !kReleaseMode,
    this.verboseLog = !kReleaseMode,
    this.fatalThrows = true,
  });
}

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  PROBE LAYER — everything the engine can observe
// ────────────────────────────────────────────────────────────────────────────

/// Immutable snapshot of the QLDataStore at a point in time.
@immutable
class QEEDataSnapshot {
  final Map<String, dynamic> signals;
  final DateTime capturedAt;

  const QEEDataSnapshot(this.signals, this.capturedAt);

  /// Read any path from the LIVE store (not this snapshot) for quick assertions.
  dynamic liveRead(String path) => QuantumVM.instance.store.get(path);

  /// Read from the snapshot (immutable, captured at step end).
  dynamic read(String path) {
    final strides = QLPathUtils.resolve(path);
    if (strides.isEmpty) return null;
    dynamic cur = signals[strides.first.toString()];
    for (int i = 1; i < strides.length && cur != null; i++) {
      final s = strides[i];
      if (cur is Map) cur = cur[s.toString()];
      else if (cur is List && s is int && s < cur.length) cur = cur[s];
      else return null;
    }
    return cur;
  }

  bool pathEquals(String path, dynamic expected) => read(path) == expected;
  bool pathMatches(String path, bool Function(dynamic) predicate) =>
      predicate(read(path));

  Map<String, dynamic> toMap() => Map.unmodifiable(signals);
}

/// Lightweight node in the observed widget tree.
@immutable
class QEEUiNode {
  final String type;
  final String? widgetKey;
  final Size? size;
  final Offset? position;
  final int depth;
  final List<QEEUiNode> children;

  const QEEUiNode({
    required this.type,
    this.widgetKey,
    this.size,
    this.position,
    this.depth = 0,
    this.children = const [],
  });

  /// True if [typeName] appears anywhere in this subtree.
  bool hasWidget(String typeName) {
    if (type.contains(typeName)) return true;
    for (final c in children) {
      if (c.hasWidget(typeName)) return true;
    }
    return false;
  }

  /// Count occurrences of [typeName] in this subtree.
  int countWidgets(String typeName) {
    int count = type.contains(typeName) ? 1 : 0;
    for (final c in children) count += c.countWidgets(typeName);
    return count;
  }

  /// First matching node or null.
  QEEUiNode? find(String typeName) {
    if (type.contains(typeName)) return this;
    for (final c in children) {
      final f = c.find(typeName);
      if (f != null) return f;
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
        'type': type,
        if (widgetKey != null) 'key': widgetKey,
        if (size != null) 'size': {'w': size!.width, 'h': size!.height},
        if (position != null) 'pos': {'x': position!.dx, 'y': position!.dy},
        'depth': depth,
        if (children.isNotEmpty)
          'children': children.map((c) => c.toMap()).toList(),
      };
}

/// Layout metrics from a measurement pass.
@immutable
class QEELayoutProbe {
  final Size? rootSize;
  final bool hasOverflow;
  final List<String> overflowPaths;
  final Map<String, Size> namedSizes;

  const QEELayoutProbe({
    this.rootSize,
    this.hasOverflow = false,
    this.overflowPaths = const [],
    this.namedSizes = const {},
  });

  bool get hasNoOverflow => !hasOverflow;

  Map<String, dynamic> toMap() => {
        if (rootSize != null)
          'rootSize': {'w': rootSize!.width, 'h': rootSize!.height},
        'hasOverflow': hasOverflow,
        'overflowPaths': overflowPaths,
      };
}

/// Telemetry events captured from TelemetryController during a step.
@immutable
class QEETelemetryProbe {
  final int eventCount;
  final Map<String, int> kindCounts;
  final List<Map<String, dynamic>> recentEvents;

  const QEETelemetryProbe({
    this.eventCount = 0,
    this.kindCounts = const {},
    this.recentEvents = const [],
  });

  Map<String, dynamic> toMap() => {
        'eventCount': eventCount,
        'kinds': kindCounts,
        if (recentEvents.isNotEmpty) 'recent': recentEvents,
      };
}

/// Memory RSS before/after a step.
@immutable
class QEEMemoryProbe {
  final int rssBefore;
  final int rssAfter;

  const QEEMemoryProbe({required this.rssBefore, required this.rssAfter});

  int get rssDelta => rssAfter - rssBefore;
  bool get grew => rssDelta > 0;

  Map<String, dynamic> toMap() =>
      {'before': rssBefore, 'after': rssAfter, 'delta': rssDelta};
}

/// Errors captured during step execution.
@immutable
class QEEErrorProbe {
  final List<String> messages;

  const QEEErrorProbe({this.messages = const []});

  bool get hasErrors => messages.isNotEmpty;

  Map<String, dynamic> toMap() =>
      {'count': messages.length, 'messages': messages};
}

/// Aggregates all probe types into one object per step.
class QEEProbeResult {
  QEEUiNode? ui;
  QEEDataSnapshot? data;
  QEELayoutProbe? layout;
  QEETelemetryProbe? telemetry;
  QEEMemoryProbe? memory;
  QEEErrorProbe? error;

  QEEProbeResult();

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{};
    if (ui != null) m['ui'] = ui!.toMap();
    if (data != null) m['data'] = data!.toMap();
    if (layout != null) m['layout'] = layout!.toMap();
    if (telemetry != null) m['telemetry'] = telemetry!.toMap();
    if (memory != null) m['memory'] = memory!.toMap();
    if (error != null) m['error'] = error!.toMap();
    return m;
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  EXECUTOR LAYER — everything the engine can do
// ────────────────────────────────────────────────────────────────────────────

/// Result of a single execution operation.
class QEEExecResult {
  final bool success;
  final dynamic output;
  final String? error;
  final int durationUs;
  final Map<String, dynamic> meta;

  const QEEExecResult._({
    required this.success,
    this.output,
    this.error,
    required this.durationUs,
    this.meta = const {},
  });

  factory QEEExecResult.ok(dynamic output, int us,
          {Map<String, dynamic> meta = const {}}) =>
      QEEExecResult._(success: true, output: output, durationUs: us, meta: meta);

  factory QEEExecResult.fail(String error, int us) =>
      QEEExecResult._(success: false, error: error, durationUs: us);

  Map<String, dynamic> toMap() => {
        'success': success,
        if (error != null) 'error': error,
        if (meta.isNotEmpty) 'meta': meta,
      };
}

/// Surface exposed to a step callback: all executors bundled together.
class QEEExecutors {
  final QEEJsonExecutor json = QEEJsonExecutor._();
  final QEEDataExecutor data = QEEDataExecutor._();
  final QEEActionExecutor action = QEEActionExecutor._();
  final QEEVmExecutor vm = QEEVmExecutor._();
  final QEESchemaExecutor schema = QEESchemaExecutor._();
  final QEEScriptExecutor script = QEEScriptExecutor._();

  QEEExecutors._();
}

// ── JSON Executor ──────────────────────────────────────────────────────────

class QEEJsonExecutor {
  QEEJsonExecutor._();

  /// Inject raw JSON/YAML (String or Map), compile through QLCompiler,
  /// return the compiled [QLBlueprint].
  Future<QEEExecResult> inject(dynamic jsonOrMap,
      {Map<String, dynamic> macros = const {},
      Map<String, dynamic> env = const {}}) async {
    final sw = Stopwatch()..start();
    try {
      final Map<String, dynamic> raw = jsonOrMap is String
          ? QLFormatParser.parse(jsonOrMap)
          : Map<String, dynamic>.from(jsonOrMap as Map);
      final blueprint = await QLCompiler.compileAsync(raw, macros, env);
      sw.stop();
      return QEEExecResult.ok(blueprint, sw.elapsedMicroseconds, meta: {
        'type': blueprint.type,
        'children': blueprint.children.length,
        'style': blueprint.style ?? '',
      });
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// Compile only (no Flutter widget), returning the [QLBlueprint].
  Future<QLBlueprint> compile(dynamic jsonOrMap,
      {Map<String, dynamic> macros = const {}}) async {
    final raw = jsonOrMap is String
        ? QLFormatParser.parse(jsonOrMap)
        : Map<String, dynamic>.from(jsonOrMap as Map);
    return QLCompiler.compileAsync(raw, macros);
  }

  /// Inject and immediately measure compilation time + cache statistics.
  Future<QEEExecResult> injectAndProfile(dynamic jsonOrMap,
      {Map<String, dynamic> macros = const {}}) async {
    final sw = Stopwatch()..start();
    final statsBefore = QLCompiler.cacheStats();
    try {
      final raw = jsonOrMap is String
          ? QLFormatParser.parse(jsonOrMap)
          : Map<String, dynamic>.from(jsonOrMap as Map);
      final blueprint = await QLCompiler.compileAsync(raw, macros);
      sw.stop();
      final statsAfter = QLCompiler.cacheStats();
      return QEEExecResult.ok(blueprint, sw.elapsedMicroseconds, meta: {
        'type': blueprint.type,
        'cacheHitsBefore': statsBefore.values
            .map((s) => s.hits)
            .fold(0, (a, b) => a + b),
        'cacheHitsAfter': statsAfter.values
            .map((s) => s.hits)
            .fold(0, (a, b) => a + b),
      });
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }
}

// ── Data Executor ──────────────────────────────────────────────────────────

class QEEDataExecutor {
  QEEDataExecutor._();

  QLDataStore get _store => QuantumVM.instance.store;

  /// Set a single path in the global QLDataStore.
  QEEExecResult set(String path, dynamic value) {
    final sw = Stopwatch()..start();
    try {
      _store.set(path, value);
      sw.stop();
      return QEEExecResult.ok({'path': path, 'value': value},
          sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// Merge a map atomically into the global store.
  QEEExecResult merge(Map<String, dynamic> data, {bool clearMissing = false}) {
    final sw = Stopwatch()..start();
    try {
      _store.merge(data, clearMissing: clearMissing);
      sw.stop();
      return QEEExecResult.ok({'merged': data.length}, sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// Read the live value at [path].
  dynamic get(String path) => _store.get(path);

  /// Assert that live value at [path] equals [expected].
  QEEExecResult assertPath(String path, dynamic expected,
      {String? label}) {
    final sw = Stopwatch()..start();
    final actual = _store.get(path);
    sw.stop();
    if (actual == expected) {
      return QEEExecResult.ok(
          {'path': path, 'value': actual}, sw.elapsedMicroseconds);
    }
    return QEEExecResult.fail(
        '${label ?? path}: expected $expected, got $actual',
        sw.elapsedMicroseconds);
  }

  /// Assert that live value at [path] satisfies [predicate].
  QEEExecResult assertPathWhere(String path, bool Function(dynamic) predicate,
      {String? label}) {
    final sw = Stopwatch()..start();
    final actual = _store.get(path);
    final ok = predicate(actual);
    sw.stop();
    return ok
        ? QEEExecResult.ok({'path': path}, sw.elapsedMicroseconds)
        : QEEExecResult.fail(
            '${label ?? path}: predicate failed on $actual',
            sw.elapsedMicroseconds);
  }

  /// Take a snapshot of the current store.
  QEEDataSnapshot snapshot() => QEEDataSnapshot(
        Map<String, dynamic>.from(_store.snapshot),
        DateTime.now(),
      );

  /// Diff two snapshots, returning changed/added/removed paths.
  Map<String, dynamic> diff(QEEDataSnapshot before, QEEDataSnapshot after) {
    final changed = <String, Map<String, dynamic>>{};
    final added = <String>[];
    final removed = <String>[];
    for (final key in after.signals.keys) {
      if (!before.signals.containsKey(key)) {
        added.add(key);
      } else if (before.signals[key] != after.signals[key]) {
        changed[key] = {
          'before': before.signals[key],
          'after': after.signals[key],
        };
      }
    }
    for (final key in before.signals.keys) {
      if (!after.signals.containsKey(key)) removed.add(key);
    }
    return {'changed': changed, 'added': added, 'removed': removed};
  }

  /// Save current store to a named checkpoint (uses QLDataStore history).
  void checkpoint() => _store.saveSnapshot();

  /// Rollback to last checkpoint.
  void rollback() => _store.rollback();

  /// Sweep (clear) all keys under [pathPrefix].
  void sweep(String pathPrefix) => _store.sweep(pathPrefix);
}

// ── Action Executor ────────────────────────────────────────────────────────

class QEEActionExecutor {
  QEEActionExecutor._();

  /// Run a named action with [ctx] (no Flutter BuildContext required).
  /// Uses QuantumVM.triggerActions with an env map as pipeline environment.
  Future<QEEExecResult> run(String actionName, Map<String, dynamic> ctx) async {
    final sw = Stopwatch()..start();
    try {
      await QuantumVM.instance.triggerActions(
        [{'action': actionName, ...ctx}],
        null,
        env: ctx,
      );
      sw.stop();
      return QEEExecResult.ok(
          {'action': actionName}, sw.elapsedMicroseconds,
          meta: ctx);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(
          'Action "$actionName" failed: $e', sw.elapsedMicroseconds);
    }
  }

  /// Run a complete action pipeline (list of action maps / tuples).
  Future<QEEExecResult> pipeline(List<dynamic> steps,
      {Map<String, dynamic> env = const {}}) async {
    final sw = Stopwatch()..start();
    try {
      await QuantumVM.instance.triggerActions(steps, null, env: Map<String, dynamic>.from(env));
      sw.stop();
      return QEEExecResult.ok({'steps': steps.length}, sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }
}

// ── VM Executor ────────────────────────────────────────────────────────────

class QEEVmExecutor {
  QEEVmExecutor._();

  /// Compile a raw node map and capture timing + cache stats.
  QEEExecResult compile(Map<String, dynamic> node,
      {Map<String, dynamic> macros = const {}}) {
    final sw = Stopwatch()..start();
    try {
      final blueprint = QLCompiler.compile(node, macros);
      sw.stop();
      final stats = QLCompiler.cacheStats();
      return QEEExecResult.ok(blueprint, sw.elapsedMicroseconds, meta: {
        'type': blueprint.type,
        'blueprintCacheHits': stats['blueprints']?.hits ?? 0,
        'macroCacheHits': stats['macros']?.hits ?? 0,
      });
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// Snapshot all current cache statistics.
  Map<String, Map<String, int>> cacheStats() =>
      QuantumVM.instance.runtimeCacheStats();

  /// List all registered action names.
  List<String> registeredActions() =>
      QuantumVM.instance.registeredActionNames;

  /// List all registered plugin type names.
  List<String> registeredPlugins() =>
      QuantumVM.instance.registeredPluginNames;

  /// List all registered module IDs.
  List<String> registeredModules() =>
      QLModuleRegistry.instance.registeredModuleIds;

  /// List all registered aliases.
  List<String> registeredAliases() =>
      QuantumVM.instance.registeredAliasNames;

  /// Force-clear all VM caches (useful before benchmarking cold-path).
  void clearCaches() => QuantumVM.instance.clearRuntimeCaches();

  /// Get a full registry snapshot for the live VM, modules, schemas, layouts,
  /// templates, aliases, pipes, and actions.
  Map<String, dynamic> registrySnapshot({String? kind, String? query}) =>
      QuantumVM.instance.registrySnapshot(kind: kind, query: query);

  /// Inspect a single registry item by name.
  Map<String, dynamic>? describeRegistryItem(String name, {String? kind}) =>
      QuantumVM.instance.describeRegistryItem(name, kind: kind);

  /// Search registry entries using the same query path as the VM snapshot.
  List<Map<String, dynamic>> searchRegistry({String? kind, String? query}) =>
      QuantumVM.instance
          .registryEntries(kind: kind, query: query)
          .map((e) => e.toMap())
          .toList(growable: false);

  /// Peek schema metadata without forcing additional work.
  Map<String, dynamic>? schemaDetails(String name) =>
      QuantumCoreSchemaRegistry.instance.describeCached(name);

  /// Resolve schema metadata lazily from the core catalog or file-backed sources.
  Future<Map<String, dynamic>?> schemaDetailsAsync(String name) =>
      QuantumCoreSchemaRegistry.instance.describeAny(name);

  /// Resolve a nested schema field path from the schema descriptor itself.
  dynamic schemaField(String name, String path) {
    final schema = QuantumCoreSchemaRegistry.instance.describeCached(name);
    if (schema == null) return null;
    dynamic current = schema;
    for (final part in path.split('.')) {
      if (current is Map) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  /// Export the live SDUI schema bundle (all sections) as a data map.
  Map<String, dynamic> exportSchemaBundle({
    String? kind,
    String? query,
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportSnapshot(
        kind: kind,
        query: query,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Export the live SDUI schema bundle as pretty-printed JSON.
  String exportSchemaJson({
    String? kind,
    String? query,
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportJson(
        kind: kind,
        query: query,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Export a TypeScript bundle file that creates a strongly typed SDUI engine.
  String exportSchemaTypeScriptBundle({
    String? kind,
    String? query,
    String bundleName = 'quantumSduiBundle',
    String engineImportPath = './quantum_sdui_type_engine',
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportTypeScriptBundle(
        kind: kind,
        query: query,
        bundleName: bundleName,
        engineImportPath: engineImportPath,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Export the full bundle wrapper containing JSON + TS source.
  QuantumSduiTypeBundle exportSchemaBundlePackage({
    String? kind,
    String? query,
    String bundleName = 'quantumSduiBundle',
    String engineImportPath = './quantum_sdui_type_engine',
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportBundle(
        kind: kind,
        query: query,
        bundleName: bundleName,
        engineImportPath: engineImportPath,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );
}

// ── Schema Executor ────────────────────────────────────────────────────────

class QEESchemaExecutor {
  QEESchemaExecutor._();

  /// Create a standalone instance for use outside of [QEEExecutors].
  factory QEESchemaExecutor.standalone() => QEESchemaExecutor._();

  /// Validate [data] against a registered schema by [name].
  QEEExecResult validate(String schemaName, Map<String, dynamic> data) {
    final sw = Stopwatch()..start();
    try {
      final bp = QLSchemaRegistry.instance.getSchema(schemaName);
      if (bp == null) {
        sw.stop();
        return QEEExecResult.fail(
            'Schema "$schemaName" not found', sw.elapsedMicroseconds);
      }
      final errors = bp.validate(data);
      sw.stop();
      return errors.isEmpty
          ? QEEExecResult.ok({'valid': true, 'schema': schemaName},
              sw.elapsedMicroseconds)
          : QEEExecResult.fail(errors.join('; '), sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// Parse + validate a raw record through a schema. Returns cleaned record.
  QEEExecResult parse(String schemaName, Map<String, dynamic> data) {
    final sw = Stopwatch()..start();
    try {
      final bp = QLSchemaRegistry.instance.getSchema(schemaName);
      if (bp == null) {
        sw.stop();
        return QEEExecResult.fail(
            'Schema "$schemaName" not found', sw.elapsedMicroseconds);
      }
      final parsed = bp.parse(data);
      sw.stop();
      return QEEExecResult.ok(parsed, sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// List all known schema names.
  List<String> allSchemas() =>
      QLSchemaRegistry.instance.allSchemaNames;

  /// Describe a registered schema lazily from the core registry.
  Map<String, dynamic>? describeCore(String name) =>
      QuantumCoreSchemaRegistry.instance.describeCached(name);

  /// Describe a registered schema asynchronously, including file-backed entries.
  Future<Map<String, dynamic>?> describeCoreAsync(String name) =>
      QuantumCoreSchemaRegistry.instance.describeAny(name);
}

// ── Script Executor ────────────────────────────────────────────────────────

class QEEScriptExecutor {
  QEEScriptExecutor._();

  /// Run a synchronous Dart lambda with access to the live QuantumVM.
  QEEExecResult run(dynamic Function(QuantumVM vm) fn) {
    final sw = Stopwatch()..start();
    try {
      final result = fn(QuantumVM.instance);
      sw.stop();
      return QEEExecResult.ok(result, sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }

  /// Run an asynchronous Dart lambda with access to the live QuantumVM.
  Future<QEEExecResult> runAsync(
      Future<dynamic> Function(QuantumVM vm) fn) async {
    final sw = Stopwatch()..start();
    try {
      final result = await fn(QuantumVM.instance);
      sw.stop();
      return QEEExecResult.ok(result, sw.elapsedMicroseconds);
    } catch (e) {
      sw.stop();
      return QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  ASSERTION ENGINE — typed, composable, chainable
// ────────────────────────────────────────────────────────────────────────────

class _AssertRecord {
  final String label;
  final bool passed;
  final String? detail;
  const _AssertRecord(this.label, this.passed, {this.detail});
}

/// Fluent assertion builder. All methods return `this` for chaining.
class QEEAssertions {
  final List<_AssertRecord> _records = [];
  bool _allPassed = true;

  bool get allPassed => _allPassed;
  int get passedCount => _records.where((r) => r.passed).length;
  int get failedCount => _records.where((r) => !r.passed).length;
  List<_AssertRecord> get records => List.unmodifiable(_records);

  void _add(String label, bool passed, {String? detail}) {
    _records.add(_AssertRecord(label, passed, detail: detail));
    if (!passed) _allPassed = false;
  }

  QEEAssertions isTrue(bool condition, {String label = 'isTrue'}) {
    _add(label, condition);
    return this;
  }

  QEEAssertions isFalse(bool condition, {String label = 'isFalse'}) {
    _add(label, !condition);
    return this;
  }

  QEEAssertions equals(dynamic actual, dynamic expected,
      {String label = 'equals'}) {
    final ok = actual == expected;
    _add(label, ok, detail: ok ? null : 'Expected $expected, got $actual');
    return this;
  }

  QEEAssertions notEquals(dynamic actual, dynamic unexpected,
      {String label = 'notEquals'}) {
    _add(label, actual != unexpected);
    return this;
  }

  QEEAssertions notNull(dynamic value, {String label = 'notNull'}) {
    _add(label, value != null, detail: value == null ? 'Was null' : null);
    return this;
  }

  QEEAssertions isNull(dynamic value, {String label = 'isNull'}) {
    _add(label, value == null, detail: value != null ? 'Was $value' : null);
    return this;
  }

  QEEAssertions contains(dynamic value, Iterable collection,
      {String label = 'contains'}) {
    final ok = collection.contains(value);
    _add(label, ok, detail: ok ? null : '$value not in collection');
    return this;
  }

  QEEAssertions hasLength(dynamic collection, int expectedLen,
      {String label = 'hasLength'}) {
    final len = (collection as dynamic).length as int? ?? -1;
    final ok = len == expectedLen;
    _add(label, ok, detail: ok ? null : 'Expected length $expectedLen, got $len');
    return this;
  }

  /// Assert that the LIVE data store path equals [expected].
  QEEAssertions dataPath(String path, dynamic expected,
      {String? label}) {
    final actual = QuantumVM.instance.store.get(path);
    final ok = actual == expected;
    _add(label ?? 'data:$path', ok,
        detail: ok ? null : 'path="$path": expected $expected, got $actual');
    return this;
  }

  /// Assert that the LIVE data store path satisfies [predicate].
  QEEAssertions dataPathWhere(String path, bool Function(dynamic) predicate,
      {String? label}) {
    final actual = QuantumVM.instance.store.get(path);
    _add(label ?? 'data:$path', predicate(actual));
    return this;
  }

  /// Assert that [probe] has no captured errors.
  QEEAssertions noErrors(QEEProbeResult probe, {String label = 'noErrors'}) {
    final ok = probe.error == null || !probe.error!.hasErrors;
    _add(label, ok,
        detail: ok ? null : 'Errors: ${probe.error?.messages.join(', ')}');
    return this;
  }

  /// Assert that [probe] has no layout overflow.
  QEEAssertions layoutNoOverflow(QEEProbeResult probe,
      {String label = 'layoutNoOverflow'}) {
    final ok = probe.layout == null || probe.layout!.hasNoOverflow;
    _add(label, ok,
        detail: ok ? null : 'Overflow at: ${probe.layout?.overflowPaths.join(", ")}');
    return this;
  }

  /// Assert the exec result was successful.
  QEEAssertions execSucceeded(QEEExecResult result,
      {String label = 'execSucceeded'}) {
    _add(label, result.success,
        detail: result.success ? null : result.error);
    return this;
  }

  /// Assert that [ui] tree contains a widget of [typeName].
  QEEAssertions uiHasWidget(QEEUiNode? ui, String typeName,
      {String? label}) {
    final ok = ui?.hasWidget(typeName) ?? false;
    _add(label ?? 'ui:$typeName', ok,
        detail: ok ? null : '"$typeName" not in UI tree');
    return this;
  }

  /// Custom assertion with a user lambda.
  QEEAssertions custom(String label, bool Function() fn) {
    bool ok = false;
    String? detail;
    try {
      ok = fn();
    } catch (e) {
      detail = 'Exception: $e';
    }
    _add(label, ok, detail: detail);
    return this;
  }

  Map<String, dynamic> toMap() => {
        'allPassed': _allPassed,
        'total': _records.length,
        'passed': passedCount,
        'failed': failedCount,
        'records': _records
            .map((r) => {
                  'label': r.label,
                  'passed': r.passed,
                  if (r.detail != null) 'detail': r.detail,
                })
            .toList(),
      };
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  TRACE & STEP — the permanent execution record
// ────────────────────────────────────────────────────────────────────────────

/// A single named operation inside a trace.
class QEEStep {
  final String id;
  final String label;
  final QEEKind kind;
  final DateTime startedAt;
  final int durationUs;
  final QEEExecResult execResult;
  final QEEProbeResult probe;
  final QEEAssertions assertions;
  final Map<String, dynamic> meta;
  QEEStatus status;

  QEEStep({
    required this.id,
    required this.label,
    required this.kind,
    required this.startedAt,
    required this.durationUs,
    required this.execResult,
    required this.probe,
    required this.assertions,
    this.meta = const {},
    this.status = QEEStatus.passed,
  });

  bool get passed => status == QEEStatus.passed;
  String get durationMs => '${(durationUs / 1000).toStringAsFixed(2)}ms';

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'kind': kind.name,
        'startedAt': startedAt.toIso8601String(),
        'durationUs': durationUs,
        'status': status.name,
        'exec': execResult.toMap(),
        if (probe.toMap().isNotEmpty) 'probe': probe.toMap(),
        'assertions': assertions.toMap(),
        if (meta.isNotEmpty) 'meta': meta,
      };
}

/// A policy violation captured during a trace.
class QEEPolicyViolation {
  final String policyName;
  final PolicySeverity severity;
  final String stepId;
  final String detail;
  final DateTime at;

  const QEEPolicyViolation({
    required this.policyName,
    required this.severity,
    required this.stepId,
    required this.detail,
    required this.at,
  });

  Map<String, dynamic> toMap() => {
        'policy': policyName,
        'severity': severity.name,
        'step': stepId,
        'detail': detail,
        'at': at.toIso8601String(),
      };
}

/// Aggregated stats for a complete trace.
@immutable
class QEESummary {
  final int totalSteps;
  final int passedSteps;
  final int failedSteps;
  final int skippedSteps;
  final int totalDurationUs;
  final int policyViolations;
  final int memDeltaBytes;

  const QEESummary({
    required this.totalSteps,
    required this.passedSteps,
    required this.failedSteps,
    required this.skippedSteps,
    required this.totalDurationUs,
    required this.policyViolations,
    required this.memDeltaBytes,
  });

  bool get allPassed => failedSteps == 0 && policyViolations == 0;
  String get totalDurationMs =>
      '${(totalDurationUs / 1000).toStringAsFixed(2)}ms';

  Map<String, dynamic> toMap() => {
        'totalSteps': totalSteps,
        'passedSteps': passedSteps,
        'failedSteps': failedSteps,
        'skippedSteps': skippedSteps,
        'totalDurationUs': totalDurationUs,
        'totalDurationMs': totalDurationMs,
        'policyViolations': policyViolations,
        'memDeltaBytes': memDeltaBytes,
        'allPassed': allPassed,
      };
}

/// The complete record of a QEE run.
class QEETrace {
  final String id;
  final String name;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final List<QEEStep> steps;
  final List<QEEPolicyViolation> violations;
  final DateTime startedAt;
  DateTime? completedAt;
  QEEStatus status;
  QEESummary? summary;

  QEETrace({
    required this.id,
    required this.name,
    required this.tags,
    required this.metadata,
    required this.startedAt,
    this.status = QEEStatus.passed,
  })  : steps = [],
        violations = [];

  void _finalize() {
    completedAt = DateTime.now();
    int passed = 0, failed = 0, skipped = 0, totalUs = 0, memDelta = 0;
    for (final s in steps) {
      totalUs += s.durationUs;
      memDelta += s.probe.memory?.rssDelta ?? 0;
      switch (s.status) {
        case QEEStatus.passed:
          passed++;
          break;
        case QEEStatus.failed:
        case QEEStatus.error:
          failed++;
          break;
        case QEEStatus.skipped:
          skipped++;
          break;
        default:
          break;
      }
    }
    summary = QEESummary(
      totalSteps: steps.length,
      passedSteps: passed,
      failedSteps: failed,
      skippedSteps: skipped,
      totalDurationUs: totalUs,
      policyViolations: violations.length,
      memDeltaBytes: memDelta,
    );
    if (failed > 0 ||
        violations.any((v) =>
            v.severity == PolicySeverity.fatal ||
            v.severity == PolicySeverity.error)) {
      status = QEEStatus.failed;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'tags': tags,
        'metadata': metadata,
        'startedAt': startedAt.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'status': status.name,
        if (summary != null) 'summary': summary!.toMap(),
        'steps': steps.map((s) => s.toMap()).toList(),
        if (violations.isNotEmpty)
          'violations': violations.map((v) => v.toMap()).toList(),
      };

  String toPrettyJson() =>
      const JsonEncoder.withIndent('  ').convert(toMap());

  /// Compare to [other] — returns regressions, fixes, and new/removed steps.
  Map<String, dynamic> diff(QEETrace other) {
    final thisMap = {for (final s in steps) s.label: s};
    final otherMap = {for (final s in other.steps) s.label: s};
    final changed = <Map<String, dynamic>>[];
    final added = <String>[];
    final removed = <String>[];
    for (final label in otherMap.keys) {
      if (!thisMap.containsKey(label)) {
        added.add(label);
      } else if (thisMap[label]!.status != otherMap[label]!.status) {
        changed.add({
          'label': label,
          'from': thisMap[label]!.status.name,
          'to': otherMap[label]!.status.name,
        });
      }
    }
    for (final label in thisMap.keys) {
      if (!otherMap.containsKey(label)) removed.add(label);
    }
    return {
      'added': added,
      'removed': removed,
      'changed': changed,
      'regressions': changed.where((c) => c['to'] == 'failed').length,
      'fixes': changed.where((c) => c['to'] == 'passed').length,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  POLICY ENGINE — runtime watchers + persistent assertion rules
// ────────────────────────────────────────────────────────────────────────────

/// A named rule evaluated against probe data during / after a step.
///
/// Return `null` from [evaluate] = no violation.
/// Return a non-null string = violation message.
class QEEPolicy {
  final String id;
  final String name;
  final List<String> tags;
  final PolicySeverity severity;
  final PolicyTriggerEvent triggerEvent;

  /// Glob-style string. Only triggers when step label contains this substring.
  /// Null = match all steps.
  final String? targetPattern;

  /// The evaluation function. Return null for pass, string for violation.
  final String? Function(QEEProbeResult probe, QEEStep? step) evaluate;

  bool enabled;

  QEEPolicy({
    required this.id,
    required this.name,
    required this.evaluate,
    this.tags = const [],
    this.severity = PolicySeverity.warn,
    this.triggerEvent = PolicyTriggerEvent.onStepEnd,
    this.targetPattern,
    this.enabled = true,
  });

  bool _matchesStep(String label) {
    if (targetPattern == null) return true;
    return label.contains(targetPattern!);
  }

  Map<String, dynamic> toStorageMap() => {
        'id': id,
        'name': name,
        'tags': tags,
        'severity': severity.name,
        'triggerEvent': triggerEvent.name,
        if (targetPattern != null) 'targetPattern': targetPattern,
        'enabled': enabled,
      };
}

/// Manages all registered policies.
class QEEPolicyEngine {
  static final QEEPolicyEngine instance = QEEPolicyEngine._();
  QEEPolicyEngine._();

  final LinkedHashMap<String, QEEPolicy> _policies =
      LinkedHashMap<String, QEEPolicy>();

  void register(QEEPolicy policy) => _policies[policy.id] = policy;
  void unregister(String id) => _policies.remove(id);
  void setEnabled(String id, {required bool enabled}) =>
      _policies[id]?.enabled = enabled;

  List<QEEPolicy> get all => List.unmodifiable(_policies.values);

  /// Evaluate all applicable policies for [event], [probe], [step].
  List<QEEPolicyViolation> evaluate({
    required QEEProbeResult probe,
    required QEEStep step,
    required PolicyTriggerEvent event,
  }) {
    if (kReleaseMode || _policies.isEmpty) return const [];
    final violations = <QEEPolicyViolation>[];
    for (final p in _policies.values) {
      if (!p.enabled) continue;
      if (p.triggerEvent != event &&
          p.triggerEvent != PolicyTriggerEvent.always) continue;
      if (!p._matchesStep(step.label)) continue;
      final msg = p.evaluate(probe, step);
      if (msg != null) {
        violations.add(QEEPolicyViolation(
          policyName: p.name,
          severity: p.severity,
          stepId: step.id,
          detail: msg,
          at: DateTime.now(),
        ));
      }
    }
    return violations;
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  STORE LAYER — SQLite persistence + full query API
// ────────────────────────────────────────────────────────────────────────────

/// Query filter for the persistence store.
class QEEStoreQuery {
  final List<String>? tags;
  final QEEStatus? status;
  final DateTime? after;
  final DateTime? before;
  final String? nameContains;
  final int limit;
  final int offset;
  final bool newestFirst;

  const QEEStoreQuery({
    this.tags,
    this.status,
    this.after,
    this.before,
    this.nameContains,
    this.limit = 50,
    this.offset = 0,
    this.newestFirst = true,
  });
}

/// Lightweight stored trace (no full JSON loaded unless [rawJson] requested).
@immutable
class QEEStoredTrace {
  final String id;
  final String name;
  final List<String> tags;
  final QEEStatus status;
  final DateTime createdAt;
  final int durationMs;
  final Map<String, dynamic> metadata;
  final Map<String, dynamic> summary;
  final String? rawJson;

  const QEEStoredTrace({
    required this.id,
    required this.name,
    required this.tags,
    required this.status,
    required this.createdAt,
    required this.durationMs,
    required this.metadata,
    required this.summary,
    this.rawJson,
  });
}

/// SQLite-backed persistence layer.
class QEEStore {
  static final QEEStore instance = QEEStore._();
  QEEStore._();

  Database? _db;
  bool _initialized = false;

  static const _traces = 'qee_traces';
  static const _steps = 'qee_steps';
  static const _policies = 'qee_policies';

  Future<void> initialize({String? dbPath}) async {
    if (_initialized) return;
    String path = dbPath ??
        '${(await getApplicationDocumentsDirectory()).path}/qee_store.db';
    _db = await openDatabase(path, version: 1, onCreate: _schema);
    _initialized = true;
  }

  Future<void> _schema(Database db, int v) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_traces (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        duration_ms INTEGER NOT NULL DEFAULT 0,
        metadata TEXT NOT NULL DEFAULT '{}',
        summary TEXT NOT NULL DEFAULT '{}',
        raw_json TEXT
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_steps (
        id TEXT PRIMARY KEY, trace_id TEXT NOT NULL,
        step_index INTEGER NOT NULL, label TEXT NOT NULL,
        kind TEXT NOT NULL, status TEXT NOT NULL,
        duration_us INTEGER NOT NULL DEFAULT 0,
        started_at TEXT NOT NULL,
        exec_json TEXT NOT NULL DEFAULT '{}',
        probe_json TEXT NOT NULL DEFAULT '{}',
        assertions_json TEXT NOT NULL DEFAULT '{}',
        meta_json TEXT NOT NULL DEFAULT '{}'
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_policies (
        id TEXT PRIMARY KEY, name TEXT NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        severity TEXT NOT NULL DEFAULT 'warn',
        trigger_event TEXT NOT NULL DEFAULT 'onStepEnd',
        target_pattern TEXT, enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_traces_status ON $_traces (status)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_traces_created ON $_traces (created_at)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_steps_trace ON $_steps (trace_id, step_index)');
  }

  Future<void> _ensure() async {
    if (!_initialized) await initialize();
  }

  // ── TRACES ────────────────────────────────────────────────────────────────

  /// Persist a completed trace. Fire-and-forget by default.
  Future<void> save(QEETrace trace) async {
    await _ensure();
    final sumMap = trace.summary?.toMap() ?? {};
    final durMs =
        ((sumMap['totalDurationUs'] as int? ?? 0) / 1000).round();
    final db = _db!;
    await db.transaction((txn) async {
      await txn.insert(
        _traces,
        {
          'id': trace.id,
          'name': trace.name,
          'tags': jsonEncode(trace.tags),
          'status': trace.status.name,
          'created_at': trace.startedAt.toIso8601String(),
          'duration_ms': durMs,
          'metadata': jsonEncode(trace.metadata),
          'summary': jsonEncode(sumMap),
          'raw_json': trace.toPrettyJson(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (int i = 0; i < trace.steps.length; i++) {
        final s = trace.steps[i];
        await txn.insert(
          _steps,
          {
            'id': s.id,
            'trace_id': trace.id,
            'step_index': i,
            'label': s.label,
            'kind': s.kind.name,
            'status': s.status.name,
            'duration_us': s.durationUs,
            'started_at': s.startedAt.toIso8601String(),
            'exec_json': jsonEncode(s.execResult.toMap()),
            'probe_json': jsonEncode(s.probe.toMap()),
            'assertions_json': jsonEncode(s.assertions.toMap()),
            'meta_json': jsonEncode(s.meta),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Query stored traces with filters.
  Future<List<QEEStoredTrace>> query(QEEStoreQuery q) async {
    await _ensure();
    final where = <String>[];
    final args = <dynamic>[];
    if (q.status != null) {
      where.add('status = ?');
      args.add(q.status!.name);
    }
    if (q.after != null) {
      where.add('created_at > ?');
      args.add(q.after!.toIso8601String());
    }
    if (q.before != null) {
      where.add('created_at < ?');
      args.add(q.before!.toIso8601String());
    }
    if (q.nameContains != null) {
      where.add('name LIKE ?');
      args.add('%${q.nameContains}%');
    }
    final rows = await _db!.query(
      _traces,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: q.newestFirst ? 'created_at DESC' : 'created_at ASC',
      limit: q.limit,
      offset: q.offset,
    );
    final out = <QEEStoredTrace>[];
    for (final row in rows) {
      final tags =
          List<String>.from(jsonDecode(row['tags'] as String? ?? '[]') as List);
      if (q.tags != null &&
          q.tags!.isNotEmpty &&
          !q.tags!.any((t) => tags.contains(t))) continue;
      out.add(_rowToStored(row, tags: tags));
    }
    return out;
  }

  QEEStoredTrace _rowToStored(Map<String, dynamic> row,
      {List<String>? tags}) {
    final t = tags ??
        List<String>.from(
            jsonDecode(row['tags'] as String? ?? '[]') as List);
    return QEEStoredTrace(
      id: row['id'] as String,
      name: row['name'] as String,
      tags: t,
      status: QEEStatus.values.firstWhere(
          (s) => s.name == (row['status'] as String),
          orElse: () => QEEStatus.error),
      createdAt: DateTime.parse(row['created_at'] as String),
      durationMs: row['duration_ms'] as int? ?? 0,
      metadata: Map<String, dynamic>.from(
          jsonDecode(row['metadata'] as String? ?? '{}') as Map),
      summary: Map<String, dynamic>.from(
          jsonDecode(row['summary'] as String? ?? '{}') as Map),
      rawJson: row['raw_json'] as String?,
    );
  }

  /// Load a single trace by id (includes full raw JSON).
  Future<QEEStoredTrace?> get(String id) async {
    await _ensure();
    final rows = await _db!
        .query(_traces, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToStored(rows.first);
  }

  /// Update metadata for a stored trace.
  Future<void> updateMetadata(String id, Map<String, dynamic> meta) async {
    await _ensure();
    await _db!.update(_traces, {'metadata': jsonEncode(meta)},
        where: 'id = ?', whereArgs: [id]);
  }

  /// Delete a trace and its steps.
  Future<void> delete(String id) async {
    await _ensure();
    await _db!.transaction((txn) async {
      await txn.delete(_steps, where: 'trace_id = ?', whereArgs: [id]);
      await txn.delete(_traces, where: 'id = ?', whereArgs: [id]);
    });
  }

  /// Delete all traces matching the filter. Returns count deleted.
  Future<int> deleteWhere({
    List<String>? tags,
    QEEStatus? status,
    DateTime? before,
  }) async {
    final toDelete = await query(
        QEEStoreQuery(tags: tags, status: status, before: before, limit: 9999));
    int n = 0;
    for (final t in toDelete) {
      await delete(t.id);
      n++;
    }
    return n;
  }

  /// Count stored traces (with optional status filter).
  Future<int> count({QEEStatus? status}) async {
    await _ensure();
    final rows = await _db!.query(
      _traces,
      columns: ['COUNT(*) as c'],
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.name] : null,
    );
    return (rows.firstOrNull?['c'] as int?) ?? 0;
  }

  // ── POLICIES ─────────────────────────────────────────────────────────────

  /// Persist a policy so it survives restarts.
  Future<void> savePolicy(QEEPolicy policy) async {
    await _ensure();
    final m = policy.toStorageMap();
    await _db!.insert(
      _policies,
      {
        'id': m['id'],
        'name': m['name'],
        'tags': jsonEncode(m['tags'] ?? []),
        'severity': m['severity'],
        'trigger_event': m['triggerEvent'],
        'target_pattern': m['targetPattern'],
        'enabled': (m['enabled'] as bool) ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Toggle a policy's enabled state (in-memory + on-disk).
  Future<void> updatePolicyEnabled(String id, {required bool enabled}) async {
    await _ensure();
    await _db!.update(_policies, {'enabled': enabled ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    QEEPolicyEngine.instance.setEnabled(id, enabled: enabled);
  }

  /// Delete a policy from disk and unregister from runtime.
  Future<void> deletePolicy(String id) async {
    await _ensure();
    await _db!.delete(_policies, where: 'id = ?', whereArgs: [id]);
    QEEPolicyEngine.instance.unregister(id);
  }

  /// Wipe all QEE data.
  Future<void> nuke() async {
    await _ensure();
    await _db!.delete(_steps);
    await _db!.delete(_traces);
    await _db!.delete(_policies);
  }

  Future<void> close() async {
    await _db?.close();
    _initialized = false;
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  QEMBODIMENT — top-level singleton API
// ────────────────────────────────────────────────────────────────────────────

/// The Quantum Embodiment Engine.
///
/// **Single-step run:**
/// ```dart
/// final trace = await QEmbodiment.run(
///   name: 'cart total is positive',
///   tags: ['data', 'cart'],
///   exec: (e) async {
///     e.data.set('cart.total', 42);
///     return QEEExecResult.ok(null, 0);
///   },
///   assert_: (a, p) => a.dataPath('cart.total', 42),
/// );
/// print(trace.summary!.allPassed); // true
/// ```
///
/// **Multi-step scenario:**
/// ```dart
/// final trace = await QEmbodiment.scenario(name: 'checkout flow')
///   .step('merge cart', (e) async {
///     return e.data.merge({'cart.items': [{'id': 'p1', 'qty': 2}]});
///   })
///   .step('run checkout action', (e) async {
///     return e.action.run('cart.checkout', {'currency': 'USD'});
///   })
///   .step('assert cleared', (e) async {
///     return e.data.assertPath('cart.items', []);
///   })
///   .run();
/// ```
///
/// **JSON injection:**
/// ```dart
/// final trace = await QEmbodiment.run(
///   name: 'compile product card',
///   exec: (e) => e.json.inject({
///     'type': 'box:col',
///     'children': [{'type': 'text', 'props': {'text': 'Hello'}}],
///   }),
/// );
/// ```
///
/// **Policy (persistent rule):**
/// ```dart
/// QEmbodiment.policy(
///   id: 'no-negative-total',
///   name: 'Cart total must be positive',
///   severity: PolicySeverity.error,
///   evaluate: (probe, step) {
///     final total = QuantumVM.instance.store.get('cart.total');
///     if (total is num && total < 0) return 'Negative cart total: $total';
///     return null;
///   },
/// );
/// ```
class QEmbodiment {
  static final QEmbodiment _i = QEmbodiment._();
  static QEmbodiment get instance => _i;
  QEmbodiment._();

  QEEConfig _config = const QEEConfig();
  bool _storeReady = false;

  static QEEPolicyEngine get policies => QEEPolicyEngine.instance;
  static QEEStore get store => QEEStore.instance;

  /// Initialize the engine globally. Call once at app startup (or test setUp).
  ///
  /// ```dart
  /// await QEmbodiment.configure(const QEEConfig(verboseLog: true));
  /// ```
  static Future<void> configure(QEEConfig config) async {
    _i._config = config;
    await QEEStore.instance.initialize(dbPath: config.dbPath);
    _i._storeReady = true;
  }


  /// Get a full registry snapshot from the live VM.
  static Map<String, dynamic> registrySnapshot({String? kind, String? query}) =>
      QuantumVM.instance.registrySnapshot(kind: kind, query: query);

  /// Inspect a single registry item.
  static Map<String, dynamic>? registryItem(String name, {String? kind}) =>
      QuantumVM.instance.describeRegistryItem(name, kind: kind);

  /// Search registry entries.
  static List<Map<String, dynamic>> registrySearch(
          {String? kind, String? query}) =>
      QuantumVM.instance
          .registryEntries(kind: kind, query: query)
          .map((e) => e.toMap())
          .toList(growable: false);

  /// Export the live SDUI schema bundle (all sections) as a data map.
  static Map<String, dynamic> exportSchemaBundle({
    String? kind,
    String? query,
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportSnapshot(
        kind: kind,
        query: query,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Export the live SDUI schema bundle as pretty-printed JSON.
  static String exportSchemaJson({
    String? kind,
    String? query,
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportJson(
        kind: kind,
        query: query,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Export a TypeScript bundle file that creates a strongly typed SDUI engine.
  static String exportSchemaTypeScriptBundle({
    String? kind,
    String? query,
    String bundleName = 'quantumSduiBundle',
    String engineImportPath = './quantum_sdui_type_engine',
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportTypeScriptBundle(
        kind: kind,
        query: query,
        bundleName: bundleName,
        engineImportPath: engineImportPath,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Export the full bundle wrapper containing JSON + TS source.
  static QuantumSduiTypeBundle exportSchemaBundlePackage({
    String? kind,
    String? query,
    String bundleName = 'quantumSduiBundle',
    String engineImportPath = './quantum_sdui_type_engine',
    bool includeRegistry = true,
    bool includeCoreSchemas = true,
    bool includeDesignSystems = true,
    bool includeOmniCores = true,
    bool includeDslOperators = true,
    bool includeAliasRegistry = true,
  }) =>
      QuantumSduiTypeEngine.exportBundle(
        kind: kind,
        query: query,
        bundleName: bundleName,
        engineImportPath: engineImportPath,
        includeRegistry: includeRegistry,
        includeCoreSchemas: includeCoreSchemas,
        includeDesignSystems: includeDesignSystems,
        includeOmniCores: includeOmniCores,
        includeDslOperators: includeDslOperators,
        includeAliasRegistry: includeAliasRegistry,
      );

  /// Register a named runtime policy.
  ///
  /// [persist] = true → also writes to SQLite so it reloads after restart.
  static void policy({
    required String id,
    required String name,
    required String? Function(QEEProbeResult probe, QEEStep? step) evaluate,
    PolicySeverity severity = PolicySeverity.warn,
    PolicyTriggerEvent trigger = PolicyTriggerEvent.onStepEnd,
    String? targetPattern,
    List<String> tags = const [],
    bool persist = false,
  }) {
    final p = QEEPolicy(
      id: id,
      name: name,
      evaluate: evaluate,
      severity: severity,
      triggerEvent: trigger,
      targetPattern: targetPattern,
      tags: tags,
    );
    QEEPolicyEngine.instance.register(p);
    if (persist) {
      QEEStore.instance.savePolicy(p).ignore();
    }
  }

  /// Execute a single named operation and return its [QEETrace].
  static Future<QEETrace> run({
    required String name,
    required Future<QEEExecResult> Function(QEEExecutors) exec,
    void Function(QEEAssertions assertions, QEEProbeResult probe)? assert_,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
    Set<QEEProbeKind> probes = const {QEEProbeKind.data, QEEProbeKind.error},
    QEEKind kind = QEEKind.script,
  }) =>
      _i._runSingle(
        name: name,
        exec: exec,
        assert_: assert_,
        tags: tags,
        metadata: metadata,
        probes: probes,
        kind: kind,
      );

  /// Create a fluent multi-step [ScenarioBuilder].
  static ScenarioBuilder scenario({
    required String name,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  }) =>
      ScenarioBuilder._(name: name, tags: tags, metadata: metadata);

  // ── Internal execution core ───────────────────────────────────────────────

  Future<QEETrace> _runSingle({
    required String name,
    required Future<QEEExecResult> Function(QEEExecutors) exec,
    void Function(QEEAssertions, QEEProbeResult)? assert_,
    required List<String> tags,
    required Map<String, dynamic> metadata,
    required Set<QEEProbeKind> probes,
    required QEEKind kind,
  }) async {
    final trace = QEETrace(
      id: _uid(),
      name: name,
      tags: tags,
      metadata: metadata,
      startedAt: DateTime.now(),
    );
    final step = await _executeStep(
      label: name,
      kind: kind,
      exec: exec,
      assert_: assert_,
      probes: probes,
    );
    trace.steps.add(step);
    final viol = QEEPolicyEngine.instance.evaluate(
      probe: step.probe,
      step: step,
      event: PolicyTriggerEvent.onStepEnd,
    );
    trace.violations.addAll(viol);
    _handleViolations(viol);
    trace._finalize();
    if (_storeReady) _fireAndForget(QEEStore.instance.save(trace));
    if (_config.verboseLog) _printTrace(trace);
    return trace;
  }

  Future<QEEStep> _executeStep({
    required String label,
    required QEEKind kind,
    required Future<QEEExecResult> Function(QEEExecutors) exec,
    void Function(QEEAssertions, QEEProbeResult)? assert_,
    required Set<QEEProbeKind> probes,
  }) async {
    final id = _uid();
    final startedAt = DateTime.now();
    final rssBefore = _shouldCaptureMem(probes)
        ? ProcessInfo.currentRss
        : 0;

    final executors = QEEExecutors._();
    QEEExecResult execResult;
    final errors = <String>[];
    final sw = Stopwatch()..start();

    try {
      execResult = await exec(executors);
    } catch (e) {
      sw.stop();
      errors.add(e.toString());
      execResult = QEEExecResult.fail(e.toString(), sw.elapsedMicroseconds);
    }
    sw.stop();

    final probe = QEEProbeResult();
    final all = probes.contains(QEEProbeKind.all);

    if (all || probes.contains(QEEProbeKind.data)) {
      probe.data = QEEDataSnapshot(
        Map<String, dynamic>.from(QuantumVM.instance.store.snapshot),
        DateTime.now(),
      );
    }
    if ((all || probes.contains(QEEProbeKind.memory)) &&
        _config.captureMemory) {
      probe.memory = QEEMemoryProbe(
          rssBefore: rssBefore, rssAfter: ProcessInfo.currentRss);
    }
    if (all || probes.contains(QEEProbeKind.telemetry)) {
      probe.telemetry = _snapTelemetry();
    }
    if (all || probes.contains(QEEProbeKind.error)) {
      probe.error = QEEErrorProbe(messages: errors);
    }

    final assertions = QEEAssertions();
    if (!execResult.success) {
      assertions._add('exec.success', false, detail: execResult.error);
    }
    try {
      assert_?.call(assertions, probe);
    } catch (e) {
      assertions._add('assert_callback', false, detail: 'Assert threw: $e');
    }

    final status = assertions.allPassed && execResult.success
        ? QEEStatus.passed
        : QEEStatus.failed;

    return QEEStep(
      id: id,
      label: label,
      kind: kind,
      startedAt: startedAt,
      durationUs: sw.elapsedMicroseconds,
      execResult: execResult,
      probe: probe,
      assertions: assertions,
      status: status,
    );
  }

  bool _shouldCaptureMem(Set<QEEProbeKind> probes) =>
      !kReleaseMode &&
      _config.captureMemory &&
      (probes.contains(QEEProbeKind.all) ||
          probes.contains(QEEProbeKind.memory));

  QEETelemetryProbe _snapTelemetry() {
    if (!_config.captureTelemetry) return const QEETelemetryProbe();
    try {
      final snap = TelemetryController.instance.snapshot();
      final kinds = <String, int>{};
      final recent = <Map<String, dynamic>>[];
      for (final r in snap.records) {
        kinds[r.kind.name] = (kinds[r.kind.name] ?? 0) + 1;
        if (recent.length < 20) {
          recent.add({'kind': r.kind.name, 'label': r.targetLabel});
        }
      }
      return QEETelemetryProbe(
          eventCount: snap.records.length,
          kindCounts: kinds,
          recentEvents: recent);
    } catch (_) {
      return const QEETelemetryProbe();
    }
  }

  void _handleViolations(List<QEEPolicyViolation> viol) {
    for (final v in viol) {
      if (_config.verboseLog) {
        final icon = switch (v.severity) {
          PolicySeverity.fatal => '💥',
          PolicySeverity.error => '❌',
          PolicySeverity.warn => '⚠️',
          PolicySeverity.observe => '👁',
        };
        print('[QEE Policy] $icon [${v.policyName}] ${v.detail}');
      }
      if (v.severity == PolicySeverity.fatal && _config.fatalThrows) {
        throw QEEPolicyViolationException(v);
      }
    }
  }

  void _printTrace(QEETrace trace) {
    final s = trace.summary;
    if (s == null) return;
    final icon = s.allPassed ? '✅' : '❌';
    print('[QEE] $icon "${trace.name}" '
        '${s.passedSteps}/${s.totalSteps} passed | ${s.totalDurationMs}'
        '${s.policyViolations > 0 ? ' | ⚠️ ${s.policyViolations} policy violations' : ''}');
    for (final step in trace.steps) {
      final si = step.passed ? '  ✓' : '  ✗';
      print('$si [${step.kind.name}] ${step.label} (${step.durationMs})');
      for (final r in step.assertions.records.where((r) => !r.passed)) {
        print('       → ${r.label}: ${r.detail ?? 'failed'}');
      }
    }
  }

  static String _uid() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final h = (ts ^ (ts >> 15) ^ (ts << 7)) & 0x7FFFFFFF;
    return '${ts.toRadixString(36)}-${h.toRadixString(36)}';
  }

  static void _fireAndForget(Future<void> f) => f.ignore();
}

/// Thrown when a [PolicySeverity.fatal] policy fires with [QEEConfig.fatalThrows] = true.
class QEEPolicyViolationException implements Exception {
  final QEEPolicyViolation violation;
  const QEEPolicyViolationException(this.violation);
  @override
  String toString() =>
      'QEEPolicyViolationException: [${violation.policyName}] ${violation.detail}';
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  SCENARIO BUILDER — fluent multi-step runner
// ────────────────────────────────────────────────────────────────────────────

typedef QEEStepFn = Future<QEEExecResult> Function(QEEExecutors e);

class _StepDef {
  final String label;
  final QEEStepFn fn;
  final QEEKind kind;
  final void Function(QEEAssertions, QEEProbeResult)? assert_;
  final Set<QEEProbeKind> probes;
  final Map<String, dynamic> meta;
  final bool skip;

  const _StepDef({
    required this.label,
    required this.fn,
    required this.kind,
    required this.assert_,
    required this.probes,
    required this.meta,
    required this.skip,
  });
}

/// Fluent builder for multi-step scenarios.
///
/// ```dart
/// final trace = await QEmbodiment.scenario(
///   name: 'full user signup',
///   tags: ['e2e', 'auth'],
///   metadata: {'env': 'staging'},
/// )
///   .step('fill form', (e) async {
///     return e.data.merge({'form.email': 'a@b.com', 'form.name': 'Alice'});
///   })
///   .step('submit', (e) async {
///     return e.action.run('auth.register', {'redirect': '/home'});
///   })
///   .step('verify session', (e) async {
///     return e.data.assertPath('session.userId', isNotNull: true);
///   })
///   .stopOnFirstFailure()
///   .run();
/// ```
class ScenarioBuilder {
  final String _name;
  final List<String> _tags;
  Map<String, dynamic> _metadata;
  final List<_StepDef> _steps = [];
  void Function(QEEStep step)? _onStepComplete;
  bool _stopOnFirst = false;
  bool _rollbackOnFail = false;

  ScenarioBuilder._({
    required String name,
    List<String> tags = const [],
    Map<String, dynamic> metadata = const {},
  })  : _name = name,
        _tags = List.from(tags),
        _metadata = Map.from(metadata);

  /// Add a named step to the scenario.
  ScenarioBuilder step(
    String label,
    QEEStepFn fn, {
    QEEKind kind = QEEKind.script,
    void Function(QEEAssertions a, QEEProbeResult p)? assert_,
    Set<QEEProbeKind> probes = const {
      QEEProbeKind.data,
      QEEProbeKind.error
    },
    Map<String, dynamic> meta = const {},
    bool skip = false,
  }) {
    _steps.add(_StepDef(
      label: label,
      fn: fn,
      kind: kind,
      assert_: assert_,
      probes: probes,
      meta: meta,
      skip: skip,
    ));
    return this;
  }

  /// Attach additional metadata.
  ScenarioBuilder withMetadata(Map<String, dynamic> meta) {
    _metadata = {..._metadata, ...meta};
    return this;
  }

  /// Subscribe to step completion events for live progress.
  ScenarioBuilder onStepComplete(void Function(QEEStep step) cb) {
    _onStepComplete = cb;
    return this;
  }

  /// Abort the scenario after the first failing step.
  ScenarioBuilder stopOnFirstFailure() {
    _stopOnFirst = true;
    return this;
  }

  /// Rollback the QLDataStore to pre-scenario state if any step fails.
  ScenarioBuilder rollbackOnFailure() {
    _rollbackOnFail = true;
    return this;
  }

  /// Execute the scenario and return a [QEETrace].
  Future<QEETrace> run() async {
    final engine = QEmbodiment._i;
    final trace = QEETrace(
      id: QEmbodiment._uid(),
      name: _name,
      tags: _tags,
      metadata: _metadata,
      startedAt: DateTime.now(),
    );

    if (_rollbackOnFail) QuantumVM.instance.store.saveSnapshot();

    for (final def in _steps) {
      QEEStep step;
      if (def.skip) {
        step = QEEStep(
          id: QEmbodiment._uid(),
          label: def.label,
          kind: def.kind,
          startedAt: DateTime.now(),
          durationUs: 0,
          execResult: QEEExecResult.ok(null, 0),
          probe: QEEProbeResult(),
          assertions: QEEAssertions(),
          status: QEEStatus.skipped,
          meta: def.meta,
        );
      } else {
        step = await engine._executeStep(
          label: def.label,
          kind: def.kind,
          exec: def.fn,
          assert_: def.assert_,
          probes: def.probes,
        );
        // Attach step-level meta
        final mutable = Map<String, dynamic>.from(step.meta);
        mutable.addAll(def.meta);
      }
      trace.steps.add(step);

      final viol = QEEPolicyEngine.instance.evaluate(
        probe: step.probe,
        step: step,
        event: PolicyTriggerEvent.onStepEnd,
      );
      trace.violations.addAll(viol);
      engine._handleViolations(viol);

      _onStepComplete?.call(step);

      if (!step.passed && _stopOnFirst) {
        if (engine._config.verboseLog) {
          print('[QEE] ⛔ Scenario stopped after failed step: "${step.label}"');
        }
        break;
      }
    }

    trace._finalize();

    if (!trace.summary!.allPassed && _rollbackOnFail) {
      QuantumVM.instance.store.rollback();
    }

    if (engine._storeReady) {
      QEmbodiment._fireAndForget(QEEStore.instance.save(trace));
    }
    if (engine._config.verboseLog) engine._printTrace(trace);
    return trace;
  }
}

// ─────────────────────────────────────────────────────────────────────── §9 ─
//  SAFE WRAPPER — client-side zero-overhead render harness
// ────────────────────────────────────────────────────────────────────────────

/// Wraps any Flutter widget and probes its render timing.
///
/// **Release mode**: compile-time pure passthrough — zero overhead.
/// **Debug/Profile mode**: captures build count + timing and fires [onProbe].
///
/// ```dart
/// QEEWrapper(
///   name: 'ProductCard',
///   tags: ['ui', 'products'],
///   child: ProductCard(product: product),
///   onProbe: (r) => print('${r.name}: ${r.durationMs} | rebuilds=${r.buildCount}'),
/// )
/// ```
class QEEWrapper extends StatefulWidget {
  final String name;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final Widget child;

  /// Fires after every frame with render probe data (debug/profile only).
  final void Function(QEERenderProbeResult result)? onProbe;

  const QEEWrapper({
    super.key,
    required this.name,
    required this.child,
    this.tags = const [],
    this.metadata = const {},
    this.onProbe,
  });

  @override
  State<QEEWrapper> createState() => _QEEWrapperState();
}

class _QEEWrapperState extends State<QEEWrapper> {
  int _buildCount = 0;
  final Stopwatch _sw = Stopwatch();
  DateTime? _firstAt;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return widget.child; // Zero-overhead passthrough

    _sw.reset();
    _sw.start();
    _buildCount++;
    _firstAt ??= DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sw.stop();
      widget.onProbe?.call(QEERenderProbeResult(
        name: widget.name,
        buildCount: _buildCount,
        firstBuildAt: _firstAt!,
        lastBuildDurationUs: _sw.elapsedMicroseconds,
        tags: widget.tags,
        metadata: widget.metadata,
      ));
    });

    return widget.child;
  }
}

/// Render probe data from a [QEEWrapper].
@immutable
class QEERenderProbeResult {
  final String name;
  final int buildCount;
  final DateTime firstBuildAt;
  final int lastBuildDurationUs;
  final List<String> tags;
  final Map<String, dynamic> metadata;

  const QEERenderProbeResult({
    required this.name,
    required this.buildCount,
    required this.firstBuildAt,
    required this.lastBuildDurationUs,
    required this.tags,
    required this.metadata,
  });

  String get durationMs =>
      '${(lastBuildDurationUs / 1000).toStringAsFixed(3)}ms';

  Map<String, dynamic> toMap() => {
        'name': name,
        'buildCount': buildCount,
        'firstBuildAt': firstBuildAt.toIso8601String(),
        'lastBuildDurationUs': lastBuildDurationUs,
        'tags': tags,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}
