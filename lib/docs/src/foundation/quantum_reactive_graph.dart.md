# `src/foundation/quantum_reactive_graph.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: QUANTUM REACTIVE GRAPH ENGINE v1.0 — SIGNAL-DRIVEN ANIMATION COMPOSITOR

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Internal framework dependency: `quantum_primitives.dart`.
- Internal framework dependency: `../ui/quantum_animation_engine.dart`.

## Top-level declarations
- Line 57: `typedef QLEqualityCheck<T> = bool Function(T a, T b);` — Declares the `QLEqualityCheck` type alias so callback signatures stay readable and consistent.
- Line 60: `bool _defaultEqual<T>(T a, T b) => identical(a, b) || a == b;` — Part of the public or internal API; it is named `_defaultEqual<T>` and contributes to this file’s behavior.
- Line 81: `class QLSelector<TIn, TOut> extends QLSignalBase<TOut> {` — Defines the `QLSelector<TIn,` type and its fields, methods, and lifecycle.
- Line 149: `class QLDerivedSignal<T> extends QLSignalBase<T> implements QLReactiveContext {` — Defines the `QLDerivedSignal<T>` type and its fields, methods, and lifecycle.
- Line 267: `class QLReactiveBinding {` — Defines the `QLReactiveBinding` type and its fields, methods, and lifecycle.
- Line 328: `class QLAnimGraph {` — Defines the `QLAnimGraph` type and its fields, methods, and lifecycle.
- Line 397: `mixin QLAnimGraphMixin<T extends StatefulWidget> on State<T> {` — Part of the public or internal API; it is named `State<T>` and contributes to this file’s behavior.
- Line 435: `class QLReactiveTween extends StatefulWidget {` — Defines the `QLReactiveTween` type and its fields, methods, and lifecycle.
- Line 459: `class _QLReactiveTweenState extends State<QLReactiveTween>` — Defines the `_QLReactiveTweenState` type and its fields, methods, and lifecycle.
- Line 527: `class QLAnimCompositor {` — Defines the `QLAnimCompositor` type and its fields, methods, and lifecycle.
- Line 628: `extension QLSignalReactiveExt<T> on QLSignalBase<T> {` — Extends an existing type with convenience helpers without changing the original class.
- Line 635: `extension QLDoubleSignalReactiveExt on QLSignalBase<double> {` — Extends an existing type with convenience helpers without changing the original class.

## Important members and helpers
- Line 111: `void _onSourceChange() {` — Part of the public or internal API; it is named `_onSourceChange` and contributes to this file’s behavior.
- Line 126: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 171: `void track(QLSignalBase signal) {` — Part of the public or internal API; it is named `track` and contributes to this file’s behavior.
- Line 179: `void _markDirty() {` — Part of the public or internal API; it is named `_markDirty` and contributes to this file’s behavior.
- Line 187: `void _flush() {` — Part of the public or internal API; it is named `_flush` and contributes to this file’s behavior.
- Line 193: `void _recompute() {` — Part of the public or internal API; it is named `_recompute` and contributes to this file’s behavior.
- Line 234: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 285: `void attach() {` — Part of the public or internal API; it is named `attach` and contributes to this file’s behavior.
- Line 293: `void detach() {` — Part of the public or internal API; it is named `detach` and contributes to this file’s behavior.
- Line 300: `void _onSourceChange() {` — Part of the public or internal API; it is named `_onSourceChange` and contributes to this file’s behavior.
- Line 334: `void bind(String name, QLReactiveBinding binding) {` — Binds this object to another signal, stream, or controller.
- Line 341: `QLReactiveBinding bindSignal({` — Binds this object to another signal, stream, or controller.
- Line 346: `double Function(double)? transform,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 359: `void activate() {` — Part of the public or internal API; it is named `activate` and contributes to this file’s behavior.
- Line 368: `void deactivate() {` — Part of the public or internal API; it is named `deactivate` and contributes to this file’s behavior.
- Line 377: `void unbind(String name) {` — Part of the public or internal API; it is named `unbind` and contributes to this file’s behavior.
- Line 382: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 401: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 407: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 464: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 494: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 537: `QLAnimCompositor addSpring(` — Adds a child item, event, route, or data chunk to the current collection.
- Line 542: `double Function(double)? transform,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 567: `QLAnimCompositor addReactiveTween<T>(` — Adds a child item, event, route, or data chunk to the current collection.
- …and 5 more member declarations or helpers.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 650 lines in the source file.
- 12 top-level declarations detected by static analysis.
- 29 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
