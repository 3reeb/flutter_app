# `src/ui/quantum_behaviors.dart`

## What this file is
A UI-layer implementation file. It owns widget composition, layout, interactions, theming, telemetry, overlays, hydration, or other Flutter-facing behavior.

Author-intent note: QUANTUM BEHAVIORS ENGINE v8.0 - OMEGA DOD SINGULARITY

## Dependencies
- Core Dart library: `dart:math`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Core Dart library: `dart:async`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 30: `class QLDragConfig {` — Defines the `QLDragConfig` type and its fields, methods, and lifecycle.
- Line 52: `class QLMultiSplit extends StatefulWidget {` — Defines the `QLMultiSplit` type and its fields, methods, and lifecycle.
- Line 74: `class _QLMultiSplitState extends State<QLMultiSplit> {` — Defines the `_QLMultiSplitState` type and its fields, methods, and lifecycle.
- Line 206: `class _QLMultiSplitDelegate extends MultiChildLayoutDelegate {` — Defines the `_QLMultiSplitDelegate` type and its fields, methods, and lifecycle.
- Line 272: `class QLMorphSurface extends StatefulWidget {` — Defines the `QLMorphSurface` type and its fields, methods, and lifecycle.
- Line 294: `class _QLMorphSurfaceState extends State<QLMorphSurface> {` — Defines the `_QLMorphSurfaceState` type and its fields, methods, and lifecycle.
- Line 410: `class QLSpatialCanvas extends StatefulWidget {` — Defines the `QLSpatialCanvas` type and its fields, methods, and lifecycle.
- Line 429: `class _QLSpatialCanvasState extends State<QLSpatialCanvas>` — Defines the `_QLSpatialCanvasState` type and its fields, methods, and lifecycle.
- Line 560: `class QLFluidBoard extends StatefulWidget {` — Defines the `QLFluidBoard` type and its fields, methods, and lifecycle.
- Line 580: `class _QLFluidBoardState extends State<QLFluidBoard> {` — Defines the `_QLFluidBoardState` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 79: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 94: `void _onDragUpdate(int dividerIndex, double delta, double totalSize) {` — Part of the public or internal API; it is named `_onDragUpdate` and contributes to this file’s behavior.
- Line 142: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 148: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 218: `void performLayout(Size size) {` — Part of the public or internal API; it is named `performLayout` and contributes to this file’s behavior.
- Line 266: `bool shouldRelayout(covariant _QLMultiSplitDelegate oldDelegate) => true;` — Part of the public or internal API; it is named `shouldRelayout` and contributes to this file’s behavior.
- Line 300: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 310: `void _applyDelta(Offset delta, int cornerMask) {` — Part of the public or internal API; it is named `_applyDelta` and contributes to this file’s behavior.
- Line 345: `Widget _handle(int cornerMask, Alignment align) {` — Part of the public or internal API; it is named `_handle` and contributes to this file’s behavior.
- Line 377: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 383: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 440: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 445: `void _tickMomentum(Duration elapsed) {` — Part of the public or internal API; it is named `_tickMomentum` and contributes to this file’s behavior.
- Line 470: `void _enforceBoundaries(Matrix4 m) {` — Part of the public or internal API; it is named `_enforceBoundaries` and contributes to this file’s behavior.
- Line 491: `void _onScaleStart(ScaleStartDetails d) {` — Part of the public or internal API; it is named `_onScaleStart` and contributes to this file’s behavior.
- Line 499: `void _onScaleUpdate(ScaleUpdateDetails d) {` — Part of the public or internal API; it is named `_onScaleUpdate` and contributes to this file’s behavior.
- Line 526: `void _onScaleEnd(ScaleEndDetails d) {` — Part of the public or internal API; it is named `_onScaleEnd` and contributes to this file’s behavior.
- Line 533: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 539: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 590: `void didChangeDependencies() {` — Part of the public or internal API; it is named `didChangeDependencies` and contributes to this file’s behavior.
- Line 643: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 651: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- …and 1 more member declarations or helpers.

## How it works
The UI layer is where the framework becomes Flutter widgets, render objects, animations, overlays, and input handling. These modules tend to connect signals and controllers to visible behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 757 lines in the source file.
- 10 top-level declarations detected by static analysis.
- 25 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
