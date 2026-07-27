# `src/ui/quantum_telemetry_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM TELEMETRY ENGINE v2.0 — PRODUCTION GRADE

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:io`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/widgets.dart`.

## Top-level declarations
- Line 52: `enum TelemetryKind {` — Enumerates the finite states or modes supported by `TelemetryKind`.
- Line 111: `abstract final class TelemetryFlags {` — Provides a static namespace of constants and helper methods under `TelemetryFlags`.
- Line 145: `class TelemetryConfig {` — Defines the `TelemetryConfig` type and its fields, methods, and lifecycle.
- Line 243: `abstract final class TelemetryHash {` — Provides a static namespace of constants and helper methods under `TelemetryHash`.
- Line 264: `class SymbolCache {` — Defines the `SymbolCache` type and its fields, methods, and lifecycle.
- Line 297: `class TelemetryRecord {` — Defines the `TelemetryRecord` type and its fields, methods, and lifecycle.
- Line 369: `class TelemetryFilter {` — Defines the `TelemetryFilter` type and its fields, methods, and lifecycle.
- Line 448: `class TelemetrySnapshot {` — Defines the `TelemetrySnapshot` type and its fields, methods, and lifecycle.
- Line 522: `class TelemetryStore {` — Defines the `TelemetryStore` type and its fields, methods, and lifecycle.
- Line 665: `class _OpenSpan {` — Defines the `_OpenSpan` type and its fields, methods, and lifecycle.
- Line 682: `class _ImageSpan {` — Defines the `_ImageSpan` type and its fields, methods, and lifecycle.
- Line 697: `class _DataSpan {` — Defines the `_DataSpan` type and its fields, methods, and lifecycle.
- Line 733: `class TelemetryController extends ChangeNotifier with WidgetsBindingObserver {` — Defines the `TelemetryController` type and its fields, methods, and lifecycle.
- Line 1406: `class TelemetryNavigatorObserver extends NavigatorObserver {` — Defines the `TelemetryNavigatorObserver` type and its fields, methods, and lifecycle.
- Line 1528: `class TelemetryScope extends StatefulWidget {` — Defines the `TelemetryScope` type and its fields, methods, and lifecycle.
- Line 1562: `class _TelemetryScopeState extends State<TelemetryScope> {` — Defines the `_TelemetryScopeState` type and its fields, methods, and lifecycle.
- Line 1849: `abstract final class TelemetryVMBridge {` — Provides a static namespace of constants and helper methods under `TelemetryVMBridge`.
- Line 1945: `extension TelemetrySnapshotAnalytics on TelemetrySnapshot {` — Extends an existing type with convenience helpers without changing the original class.
- …and 7 more top-level declarations.

## Important members and helpers
- Line 272: `int intern(String value) {` — Part of the public or internal API; it is named `intern` and contributes to this file’s behavior.
- Line 284: `void clear() => _recent.clear();` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 287: `Map<int, String> snapshot() => Map<int, String>.from(_recent);` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 333: `DateTime toUtc(DateTime sessionStartUtc) =>` — Converts the object into another representation.
- Line 348: `Map<String, dynamic> toJson({bool includeLabels = true}) {` — Converts the object into another representation.
- Line 413: `bool matches(TelemetryRecord record, DateTime sessionStartUtc) {` — Part of the public or internal API; it is named `matches` and contributes to this file’s behavior.
- Line 465: `Map<String, dynamic> toJson({bool includeLabels = true}) => {` — Converts the object into another representation.
- Line 479: `Map<TelemetryKind, int> countByKind() {` — Part of the public or internal API; it is named `countByKind` and contributes to this file’s behavior.
- Line 486: `Map<String, int> countByTargetLabel() {` — Part of the public or internal API; it is named `countByTargetLabel` and contributes to this file’s behavior.
- Line 497: `Map<String, int> durationByTargetLabel() {` — Part of the public or internal API; it is named `durationByTargetLabel` and contributes to this file’s behavior.
- Line 538: `void reset() {` — Resets the object back to a known baseline state.
- Line 546: `bool _sameEvent(int base, int kindAndFlags, int targetHash, int contextHash) =>` — Part of the public or internal API; it is named `_sameEvent` and contributes to this file’s behavior.
- Line 554: `bool tryMerge(` — Part of the public or internal API; it is named `tryMerge` and contributes to this file’s behavior.
- Line 583: `void pushEvent({` — Part of the public or internal API; it is named `pushEvent` and contributes to this file’s behavior.
- Line 653: `Uint8List exportBinary() {` — Part of the public or internal API; it is named `exportBinary` and contributes to this file’s behavior.
- Line 777: `void configure(TelemetryConfig config) {` — Part of the public or internal API; it is named `configure` and contributes to this file’s behavior.
- Line 784: `void install({TelemetryConfig? config}) {` — Part of the public or internal API; it is named `install` and contributes to this file’s behavior.
- Line 828: `void disposeTelemetry() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 839: `void setEnabled(bool value) {` — Part of the public or internal API; it is named `setEnabled` and contributes to this file’s behavior.
- Line 847: `void setScopeEnabled(String name, bool enabled) {` — Part of the public or internal API; it is named `setScopeEnabled` and contributes to this file’s behavior.
- Line 853: `bool isScopeEnabled(String name) {` — Part of the public or internal API; it is named `isScopeEnabled` and contributes to this file’s behavior.
- Line 859: `T withDisabled<T>(T Function() body) {` — Part of the public or internal API; it is named `withDisabled<T>` and contributes to this file’s behavior.
- Line 864: `T withContext<T>(String context, T Function() body) {` — Part of the public or internal API; it is named `withContext<T>` and contributes to this file’s behavior.
- Line 869: `void reset() {` — Resets the object back to a known baseline state.
- …and 81 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 2552 lines in the source file.
- 25 top-level declarations detected by static analysis.
- 105 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
