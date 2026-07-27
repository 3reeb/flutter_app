# `src/foundation/quantum_async.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: QUANTUM ASYNC ENGINE v1.0 - OMEGA RESOURCE PRIMITIVE

## Dependencies
- Core Dart library: `dart:async`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 35: `enum QLAsyncStatus { idle, loading, success, error }` — Enumerates the finite states or modes supported by `QLAsyncStatus`.
- Line 40: `class QLAsyncSnapshot<T> {` — Defines the `QLAsyncSnapshot<T>` type and its fields, methods, and lifecycle.
- Line 108: `class QLAsyncSignal<T> extends ChangeNotifier {` — Defines the `QLAsyncSignal<T>` type and its fields, methods, and lifecycle.
- Line 304: `class QLAsyncBuilder<T> extends StatelessWidget {` — Defines the `QLAsyncBuilder<T>` type and its fields, methods, and lifecycle.
- Line 344: `class _QLDefaultErrorWidget extends StatelessWidget {` — Defines the `_QLDefaultErrorWidget` type and its fields, methods, and lifecycle.
- Line 374: `class QLAsyncRegistry {` — Defines the `QLAsyncRegistry` type and its fields, methods, and lifecycle.
- Line 417: `extension QLDataStoreAsyncExt on QLDataStore {` — Extends an existing type with convenience helpers without changing the original class.
- Line 442: `class QLAsyncScope<T> extends InheritedNotifier<QLAsyncSignal<T>> {` — Defines the `QLAsyncScope<T>` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 125: `Future<T> Function()? _lastFetch;` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 137: `void _enterLoading() {` — Part of the public or internal API; it is named `_enterLoading` and contributes to this file’s behavior.
- Line 148: `void _enterData(T value) {` — Part of the public or internal API; it is named `_enterData` and contributes to this file’s behavior.
- Line 162: `void _enterError(Object e, StackTrace? st) {` — Part of the public or internal API; it is named `_enterError` and contributes to this file’s behavior.
- Line 179: `void load(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 180: `Future<T> Function() fetch, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 226: `void bind(Stream<T> source, {bool cancelExisting = true}) {` — Binds this object to another signal, stream, or controller.
- Line 252: `void retry() {` — Part of the public or internal API; it is named `retry` and contributes to this file’s behavior.
- Line 264: `void reset() {` — Resets the object back to a known baseline state.
- Line 285: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 322: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 350: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 390: `void release(String key) {` — Part of the public or internal API; it is named `release` and contributes to this file’s behavior.
- Line 396: `void sweepPrefix(String prefix) {` — Part of the public or internal API; it is named `sweepPrefix` and contributes to this file’s behavior.
- Line 405: `void disposeAll() {` — Releases listeners, controllers, caches, and other owned resources.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 451 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 15 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
