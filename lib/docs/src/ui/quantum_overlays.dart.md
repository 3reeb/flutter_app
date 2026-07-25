# `src/ui/quantum_overlays.dart`

## What this file is
A UI-layer implementation file. It owns widget composition, layout, interactions, theming, telemetry, overlays, hydration, or other Flutter-facing behavior.

Author-intent note: Quantum ecosystem — only the barrel import is needed after decoupling.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:math`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 27: `abstract final class QLNodeFlags {` — Provides a static namespace of constants and helper methods under `QLNodeFlags`.
- Line 44: `enum QLTransitionMode {` — Enumerates the finite states or modes supported by `QLTransitionMode`.
- Line 55: `enum QLBackgroundEffect { none, blur, zoomBack, darken }` — Enumerates the finite states or modes supported by `QLBackgroundEffect`.
- Line 57: `enum QLSheetEdge { top, bottom, left, right }` — Enumerates the finite states or modes supported by `QLSheetEdge`.
- Line 59: `enum QLResizeEdge {` — Enumerates the finite states or modes supported by `QLResizeEdge`.
- Line 71: `enum QLInteractionMode { none, drag, resize }` — Enumerates the finite states or modes supported by `QLInteractionMode`.
- Line 73: `typedef QLOverlayBuilder = Widget Function(` — Declares the `QLOverlayBuilder` type alias so callback signatures stay readable and consistent.
- Line 79: `class QLSpatialConfig {` — Defines the `QLSpatialConfig` type and its fields, methods, and lifecycle.
- Line 431: `class _QLSpatialNodeState {` — Defines the `_QLSpatialNodeState` type and its fields, methods, and lifecycle.
- Line 450: `class _QLSpatialRegistry {` — Defines the `_QLSpatialRegistry` type and its fields, methods, and lifecycle.
- Line 557: `class QuantumOverlay {` — Defines the `QuantumOverlay` type and its fields, methods, and lifecycle.
- Line 761: `class _QLNodeWrapper {` — Defines the `_QLNodeWrapper` type and its fields, methods, and lifecycle.
- Line 784: `class QLOverlayRoot extends StatefulWidget {` — Defines the `QLOverlayRoot` type and its fields, methods, and lifecycle.
- Line 792: `class _QLOverlayRootState extends State<QLOverlayRoot> {` — Defines the `_QLOverlayRootState` type and its fields, methods, and lifecycle.
- Line 871: `class _QLUniversalNode extends StatefulWidget {` — Defines the `_QLUniversalNode` type and its fields, methods, and lifecycle.
- Line 883: `class _QLUniversalNodeState extends State<_QLUniversalNode>` — Defines the `_QLUniversalNodeState` type and its fields, methods, and lifecycle.
- Line 1554: `extension QuantumOverlayContextExt on BuildContext {` — Extends an existing type with convenience helpers without changing the original class.

## Important members and helpers
- Line 454: `int insert(int id, int parentId, int zIndex, int flags) {` — Part of the public or internal API; it is named `insert` and contributes to this file’s behavior.
- Line 466: `void updateBounds(` — Updates internal state or a derived representation.
- Line 476: `void remove(int id) {` — Removes a previously registered item or association.
- Line 483: `int hitTest(double x, double y) {` — Part of the public or internal API; it is named `hitTest` and contributes to this file’s behavior.
- Line 502: `Set<int> ancestrySafeSet(int hitId) {` — Part of the public or internal API; it is named `ancestrySafeSet` and contributes to this file’s behavior.
- Line 517: `List<int> getDismissibleIds(double x, double y) {` — Part of the public or internal API; it is named `getDismissibleIds` and contributes to this file’s behavior.
- Line 550: `bool isEmpty() => _nodes.isEmpty;` — Part of the public or internal API; it is named `isEmpty` and contributes to this file’s behavior.
- Line 580: `void resetForTesting() {` — Resets the object back to a known baseline state.
- Line 590: `void _handleGlobalPointerDown(Offset pos) {` — Part of the public or internal API; it is named `_handleGlobalPointerDown` and contributes to this file’s behavior.
- Line 598: `void _handleEscape() {` — Part of the public or internal API; it is named `_handleEscape` and contributes to this file’s behavior.
- Line 607: `void _closeNode(int id) {` — Part of the public or internal API; it is named `_closeNode` and contributes to this file’s behavior.
- Line 615: `void closeTop() {` — Closes the underlying resource and releases any native handles.
- Line 621: `void _cleanupNode(int id) {` — Part of the public or internal API; it is named `_cleanupNode` and contributes to this file’s behavior.
- Line 629: `void _recalculateBackgroundEffects() {` — Part of the public or internal API; it is named `_recalculateBackgroundEffects` and contributes to this file’s behavior.
- Line 704: `Future<T?> mount<T>(` — Part of the public or internal API; it is named `mount<T>` and contributes to this file’s behavior.
- Line 716: `void completeNull() {` — Part of the public or internal API; it is named `completeNull` and contributes to this file’s behavior.
- Line 738: `Widget buildMasterStack() {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 794: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 800: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 909: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 920: `void didChangeDependencies() {` — Part of the public or internal API; it is named `didChangeDependencies` and contributes to this file’s behavior.
- Line 1051: `void beginExit(VoidCallback onComplete) {` — Part of the public or internal API; it is named `beginExit` and contributes to this file’s behavior.
- Line 1119: `bool ok(QLResizeEdge e) {` — Part of the public or internal API; it is named `ok` and contributes to this file’s behavior.
- Line 1331: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- …and 19 more member declarations or helpers.

## How it works
The UI layer is where the framework becomes Flutter widgets, render objects, animations, overlays, and input handling. These modules tend to connect signals and controllers to visible behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 1771 lines in the source file.
- 17 top-level declarations detected by static analysis.
- 43 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
