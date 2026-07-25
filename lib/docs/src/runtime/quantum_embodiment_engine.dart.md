# `src/runtime/quantum_embodiment_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM EMBODIMENT ENGINE (QEE) v1.0 — RUNTIME INTERACTION ENGINE

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:io`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Pub package import: `package:path_provider/path_provider.dart`.
- Pub package import: `package:sqflite/sqflite.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 49: `enum QEEStatus { passed, failed, skipped, error, cancelled }` — Enumerates the finite states or modes supported by `QEEStatus`.
- Line 52: `enum QEEKind {` — Enumerates the finite states or modes supported by `QEEKind`.
- Line 69: `enum PolicySeverity { observe, warn, error, fatal }` — Enumerates the finite states or modes supported by `PolicySeverity`.
- Line 72: `enum PolicyTriggerEvent {` — Enumerates the finite states or modes supported by `PolicyTriggerEvent`.
- Line 83: `enum QEEProbeKind { ui, data, layout, telemetry, memory, error, all }` — Enumerates the finite states or modes supported by `QEEProbeKind`.
- Line 86: `class QEEConfig {` — Defines the `QEEConfig` type and its fields, methods, and lifecycle.
- Line 121: `class QEEDataSnapshot {` — Defines the `QEEDataSnapshot` type and its fields, methods, and lifecycle.
- Line 153: `class QEEUiNode {` — Defines the `QEEUiNode` type and its fields, methods, and lifecycle.
- Line 209: `class QEELayoutProbe {` — Defines the `QEELayoutProbe` type and its fields, methods, and lifecycle.
- Line 234: `class QEETelemetryProbe {` — Defines the `QEETelemetryProbe` type and its fields, methods, and lifecycle.
- Line 254: `class QEEMemoryProbe {` — Defines the `QEEMemoryProbe` type and its fields, methods, and lifecycle.
- Line 269: `class QEEErrorProbe {` — Defines the `QEEErrorProbe` type and its fields, methods, and lifecycle.
- Line 281: `class QEEProbeResult {` — Defines the `QEEProbeResult` type and its fields, methods, and lifecycle.
- Line 308: `class QEEExecResult {` — Defines the `QEEExecResult` type and its fields, methods, and lifecycle.
- Line 338: `class QEEExecutors {` — Defines the `QEEExecutors` type and its fields, methods, and lifecycle.
- Line 351: `class QEEJsonExecutor {` — Defines the `QEEJsonExecutor` type and its fields, methods, and lifecycle.
- Line 416: `class QEEDataExecutor {` — Defines the `QEEDataExecutor` type and its fields, methods, and lifecycle.
- Line 519: `class QEEActionExecutor {` — Defines the `QEEActionExecutor` type and its fields, methods, and lifecycle.
- …and 22 more top-level declarations.

## Important members and helpers
- Line 128: `dynamic liveRead(String path) => QuantumVM.instance.store.get(path);` — Part of the public or internal API; it is named `liveRead` and contributes to this file’s behavior.
- Line 131: `dynamic read(String path) {` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 144: `bool pathEquals(String path, dynamic expected) => read(path) == expected;` — Part of the public or internal API; it is named `pathEquals` and contributes to this file’s behavior.
- Line 145: `bool pathMatches(String path, bool Function(dynamic) predicate) =>` — Part of the public or internal API; it is named `pathMatches` and contributes to this file’s behavior.
- Line 148: `Map<String, dynamic> toMap() => Map.unmodifiable(signals);` — Converts the object into another representation.
- Line 171: `bool hasWidget(String typeName) {` — Part of the public or internal API; it is named `hasWidget` and contributes to this file’s behavior.
- Line 180: `int countWidgets(String typeName) {` — Part of the public or internal API; it is named `countWidgets` and contributes to this file’s behavior.
- Line 196: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 224: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 245: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 263: `Map<String, dynamic> toMap() =>` — Converts the object into another representation.
- Line 276: `Map<String, dynamic> toMap() =>` — Converts the object into another representation.
- Line 291: `Map<String, dynamic> toMap() {` — Converts the object into another representation.
- Line 330: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 356: `Future<QEEExecResult> inject(dynamic jsonOrMap,` — Part of the public or internal API; it is named `inject` and contributes to this file’s behavior.
- Line 378: `Future<QLBlueprint> compile(dynamic jsonOrMap,` — Part of the public or internal API; it is named `compile` and contributes to this file’s behavior.
- Line 387: `Future<QEEExecResult> injectAndProfile(dynamic jsonOrMap,` — Part of the public or internal API; it is named `injectAndProfile` and contributes to this file’s behavior.
- Line 422: `QEEExecResult set(String path, dynamic value) {` — Part of the public or internal API; it is named `set` and contributes to this file’s behavior.
- Line 436: `QEEExecResult merge(Map<String, dynamic> data, {bool clearMissing = false}) {` — Part of the public or internal API; it is named `merge` and contributes to this file’s behavior.
- Line 449: `dynamic get(String path) => _store.get(path);` — Part of the public or internal API; it is named `get` and contributes to this file’s behavior.
- Line 452: `QEEExecResult assertPath(String path, dynamic expected,` — Part of the public or internal API; it is named `assertPath` and contributes to this file’s behavior.
- Line 467: `QEEExecResult assertPathWhere(String path, bool Function(dynamic) predicate,` — Part of the public or internal API; it is named `assertPathWhere` and contributes to this file’s behavior.
- Line 481: `QEEDataSnapshot snapshot() => QEEDataSnapshot(` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 487: `Map<String, dynamic> diff(QEEDataSnapshot before, QEEDataSnapshot after) {` — Part of the public or internal API; it is named `diff` and contributes to this file’s behavior.
- …and 93 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 2364 lines in the source file.
- 40 top-level declarations detected by static analysis.
- 117 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
