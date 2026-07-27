# `src/foundation/quantum_render_scheduler.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: QUANTUM RENDER SCHEDULER v1.0 — FRAME-BUDGET RENDER QUEUE

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/widgets.dart`.
- Internal framework dependency: `quantum_primitives.dart`.
- Internal framework dependency: `../ui/quantum_scene_layer.dart`.

## Top-level declarations
- Line 80: `enum QLRenderPriority {` — Enumerates the finite states or modes supported by `QLRenderPriority`.
- Line 93: `abstract final class QLFrameBudget {` — Provides a static namespace of constants and helper methods under `QLFrameBudget`.
- Line 128: `class QLRenderWorkItem {` — Defines the `QLRenderWorkItem` type and its fields, methods, and lifecycle.
- Line 157: `class QLRenderScheduler {` — Defines the `QLRenderScheduler` type and its fields, methods, and lifecycle.
- Line 275: `class QLBatchedSceneLayer extends QLSceneLayer {` — Defines the `QLBatchedSceneLayer` type and its fields, methods, and lifecycle.
- Line 345: `class QLAdaptiveThrottle<T> {` — Defines the `QLAdaptiveThrottle<T>` type and its fields, methods, and lifecycle.
- Line 408: `class QLRenderScope extends InheritedWidget {` — Defines the `QLRenderScope` type and its fields, methods, and lifecycle.
- Line 436: `class QLFrameMonitor extends StatefulWidget {` — Defines the `QLFrameMonitor` type and its fields, methods, and lifecycle.
- Line 450: `class _QLFrameMonitorState extends State<QLFrameMonitor>` — Defines the `_QLFrameMonitorState` type and its fields, methods, and lifecycle.
- Line 540: `extension QLSceneLayerSchedulerExt on QLSceneLayer {` — Extends an existing type with convenience helpers without changing the original class.
- Line 557: `extension QLSignalThrottleExt<T> on QLSignalBase<T> {` — Extends an existing type with convenience helpers without changing the original class.

## Important members and helpers
- Line 179: `void enqueue(QLRenderWorkItem item) {` — Part of the public or internal API; it is named `enqueue` and contributes to this file’s behavior.
- Line 188: `void enqueueAll(List<QLRenderWorkItem> items) {` — Part of the public or internal API; it is named `enqueueAll` and contributes to this file’s behavior.
- Line 198: `void cancel(String id) {` — Part of the public or internal API; it is named `cancel` and contributes to this file’s behavior.
- Line 207: `void _scheduleFlush() {` — Part of the public or internal API; it is named `_scheduleFlush` and contributes to this file’s behavior.
- Line 213: `void _flush(Duration _) {` — Part of the public or internal API; it is named `_flush` and contributes to this file’s behavior.
- Line 286: `void scheduledUpdate(` — Part of the public or internal API; it is named `scheduledUpdate` and contributes to this file’s behavior.
- Line 302: `void scheduledUpdateBatch(` — Part of the public or internal API; it is named `scheduledUpdateBatch` and contributes to this file’s behavior.
- Line 304: `QLFragmentDraw Function(int id) drawFactory, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 360: `void push(T value) {` — Part of the public or internal API; it is named `push` and contributes to this file’s behavior.
- Line 366: `void _scheduleFlush() {` — Part of the public or internal API; it is named `_scheduleFlush` and contributes to this file’s behavior.
- Line 372: `void _flush(Duration _) {` — Part of the public or internal API; it is named `_flush` and contributes to this file’s behavior.
- Line 386: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 424: `bool updateShouldNotify(QLRenderScope old) => priority != old.priority;` — Updates internal state or a derived representation.
- Line 459: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 465: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 471: `void didChangeMetrics() {` — Part of the public or internal API; it is named `didChangeMetrics` and contributes to this file’s behavior.
- Line 486: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 543: `void scheduleUpdate(` — Part of the public or internal API; it is named `scheduleUpdate` and contributes to this file’s behavior.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 571 lines in the source file.
- 11 top-level declarations detected by static analysis.
- 18 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
