# `src/foundation/quantum_primitives.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: QUANTUM CORE PRIMITIVES ENGINE v8.0 - OMNI-MATRIX DOD BUILD

## Dependencies
- Core Dart library: `dart:ui`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/gestures.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 33: `abstract final class QLSafe {` — Provides a static namespace of constants and helper methods under `QLSafe`.
- Line 62: `typedef _QLEqualityCheck<T> = bool Function(T a, T b);` — Declares the `_QLEqualityCheck` type alias so callback signatures stay readable and consistent.
- Line 65: `bool _defaultEqual<T>(T a, T b) => identical(a, b) || a == b;` — Part of the public or internal API; it is named `_defaultEqual<T>` and contributes to this file’s behavior.
- Line 67: `abstract final class QLArena {` — Provides a static namespace of constants and helper methods under `QLArena`.
- Line 101: `abstract class QLReactiveContext {` — Defines the abstract `QLReactiveContext` contract used by implementations elsewhere in the framework.
- Line 105: `abstract class QLSignalBase<T> extends ChangeNotifier {` — Defines the abstract `QLSignalBase<T>` contract used by implementations elsewhere in the framework.
- Line 110: `typedef QLMutable<T> = QLSignal<T>;` — Declares the `QLMutable` type alias so callback signatures stay readable and consistent.
- Line 112: `class QLSignal<T> extends QLSignalBase<T> implements ValueListenable<T> {` — Defines the `QLSignal<T>` type and its fields, methods, and lifecycle.
- Line 179: `class QLComputed<T> extends QLSignalBase<T> implements QLReactiveContext {` — Defines the `QLComputed<T>` type and its fields, methods, and lifecycle.
- Line 256: `mixin QLReactiveRenderMixin on RenderObject {` — Part of the public or internal API; it is named `RenderObject` and contributes to this file’s behavior.
- Line 286: `typedef QLDerivativeFunc = void Function(` — Declares the `QLDerivativeFunc` type alias so callback signatures stay readable and consistent.
- Line 289: `abstract final class QLPhysicsTicker {` — Provides a static namespace of constants and helper methods under `QLPhysicsTicker`.
- Line 304: `class QLIntegratorRK4 {` — Defines the `QLIntegratorRK4` type and its fields, methods, and lifecycle.
- Line 342: `class QLComponentArray {` — Defines the `QLComponentArray` type and its fields, methods, and lifecycle.
- Line 356: `class QLSoAEngine {` — Defines the `QLSoAEngine` type and its fields, methods, and lifecycle.
- Line 563: `class QLNodeConfig {` — Defines the `QLNodeConfig` type and its fields, methods, and lifecycle.
- Line 594: `class RenderQLNode extends RenderProxyBox with QLReactiveRenderMixin {` — Defines the `RenderQLNode` type and its fields, methods, and lifecycle.
- Line 797: `class QLPointerEvent {` — Defines the `QLPointerEvent` type and its fields, methods, and lifecycle.
- …and 7 more top-level declarations.

## Important members and helpers
- Line 102: `void track(QLSignalBase signal);` — Part of the public or internal API; it is named `track` and contributes to this file’s behavior.
- Line 134: `T update(void Function(T state) mutator) {` — Updates internal state or a derived representation.
- Line 141: `void setSilent(T next) => _value = next;` — Part of the public or internal API; it is named `setSilent` and contributes to this file’s behavior.
- Line 143: `void forceNotify() {` — Part of the public or internal API; it is named `forceNotify` and contributes to this file’s behavior.
- Line 155: `void Function(T event) onData, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 157: `void Function()? onDone,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 168: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 193: `void track(QLSignalBase signal) {` — Part of the public or internal API; it is named `track` and contributes to this file’s behavior.
- Line 201: `void _markDirty() {` — Part of the public or internal API; it is named `_markDirty` and contributes to this file’s behavior.
- Line 208: `void _recompute() {` — Part of the public or internal API; it is named `_recompute` and contributes to this file’s behavior.
- Line 247: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 260: `void watch(QLSignalBase? signal, VoidCallback action) {` — Observes a value or stream and mirrors changes into the local model.
- Line 270: `void watchPaint(QLSignalBase? s) => watch(s, markNeedsPaint);` — Observes a value or stream and mirrors changes into the local model.
- Line 271: `void watchLayout(QLSignalBase? s) => watch(s, markNeedsLayout);` — Observes a value or stream and mirrors changes into the local model.
- Line 272: `void watchSemantics(QLSignalBase? s) => watch(s, markNeedsSemanticsUpdate);` — Observes a value or stream and mirrors changes into the local model.
- Line 275: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 319: `void step(double dt, QLDerivativeFunc evaluate) {` — Part of the public or internal API; it is named `step` and contributes to this file’s behavior.
- Line 349: `double get(int entity, int offset) => data[entity * stride + offset];` — Part of the public or internal API; it is named `get` and contributes to this file’s behavior.
- Line 352: `void set(int entity, int offset, double value) =>` — Part of the public or internal API; it is named `set` and contributes to this file’s behavior.
- Line 389: `void registerComponent(String name, int stride) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 393: `QLComponentArray comp(String name) => _components[name]!;` — Part of the public or internal API; it is named `comp` and contributes to this file’s behavior.
- Line 395: `int spawn({int parentId = -1, int edgeType = 0}) {` — Part of the public or internal API; it is named `spawn` and contributes to this file’s behavior.
- Line 412: `void computeWorldTransforms() {` — Part of the public or internal API; it is named `computeWorldTransforms` and contributes to this file’s behavior.
- Line 435: `void updateSpatialHash(int entity) {` — Updates internal state or a derived representation.
- …and 25 more member declarations or helpers.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 1033 lines in the source file.
- 25 top-level declarations detected by static analysis.
- 49 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
