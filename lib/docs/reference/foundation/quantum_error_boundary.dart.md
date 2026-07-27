# `src/foundation/quantum_error_boundary.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: QUANTUM ERROR BOUNDARY v1.0 - STRUCTURED SUBTREE FAULT ISOLATION

## Dependencies
- Core Dart library: `dart:async`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Internal framework dependency: `quantum_primitives.dart`.

## Top-level declarations
- Line 54: `abstract final class QLErrorBoundaryConfig {` — Provides a static namespace of constants and helper methods under `QLErrorBoundaryConfig`.
- Line 58: `abstract final class QLErrorUtils {` — Provides a static namespace of constants and helper methods under `QLErrorUtils`.
- Line 85: `enum QLErrorSeverity { recoverable, fatal }` — Enumerates the finite states or modes supported by `QLErrorSeverity`.
- Line 88: `class QLErrorState {` — Defines the `QLErrorState` type and its fields, methods, and lifecycle.
- Line 131: `class QLErrorBoundaryScope extends InheritedWidget {` — Defines the `QLErrorBoundaryScope` type and its fields, methods, and lifecycle.
- Line 163: `class _QLDefaultFallback extends StatelessWidget {` — Defines the `_QLDefaultFallback` type and its fields, methods, and lifecycle.
- Line 252: `class QLErrorBoundary extends StatefulWidget {` — Defines the `QLErrorBoundary` type and its fields, methods, and lifecycle.
- Line 292: `class _QLErrorBoundaryState extends State<QLErrorBoundary> {` — Defines the `_QLErrorBoundaryState` type and its fields, methods, and lifecycle.
- Line 460: `mixin QLErrorBoundaryReporter<T extends StatefulWidget> on State<T> {` — Part of the public or internal API; it is named `State<T>` and contributes to this file’s behavior.
- Line 487: `extension QLErrorBoundaryExt on Widget {` — Extends an existing type with convenience helpers without changing the original class.

## Important members and helpers
- Line 109: `QLErrorState withRetry() => QLErrorState(` — Part of the public or internal API; it is named `withRetry` and contributes to this file’s behavior.
- Line 119: `String toString() =>` — Converts the object into another representation.
- Line 141: `void report(Object error,` — Part of the public or internal API; it is named `report` and contributes to this file’s behavior.
- Line 155: `bool updateShouldNotify(QLErrorBoundaryScope old) =>` — Updates internal state or a derived representation.
- Line 170: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 297: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 305: `void _installFrameworkErrorHandler() {` — Part of the public or internal API; it is named `_installFrameworkErrorHandler` and contributes to this file’s behavior.
- Line 346: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 354: `void _captureError(` — Part of the public or internal API; it is named `_captureError` and contributes to this file’s behavior.
- Line 390: `void _retry() {` — Part of the public or internal API; it is named `_retry` and contributes to this file’s behavior.
- Line 405: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 462: `Future<void> runSafe(Future<void> Function() action,` — Part of the public or internal API; it is named `runSafe` and contributes to this file’s behavior.
- Line 472: `void reportError(Object error, {StackTrace? stackTrace, String? context}) {` — Part of the public or internal API; it is named `reportError` and contributes to this file’s behavior.
- Line 476: `void _route(Object error, StackTrace? stackTrace, String? context) {` — Part of the public or internal API; it is named `_route` and contributes to this file’s behavior.
- Line 489: `Widget withErrorBoundary({` — Part of the public or internal API; it is named `withErrorBoundary` and contributes to this file’s behavior.
- Line 490: `Widget Function(BuildContext ctx, QLErrorState error, VoidCallback? retry)?` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 503 lines in the source file.
- 10 top-level declarations detected by static analysis.
- 16 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
