# `src/ui/quantum_navigation_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM NAVIGATION ENGINE v8.0 - OMEGA HYBRID SEO BUILD

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:math`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `quantum_hydration_reader.dart`.
- Internal framework dependency: `../foundation/quantum_primitives.dart`.
- Internal framework dependency: `quantum_components.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 33: `typedef QLDataFetchCallback = FutureOr<Map<String, dynamic>> Function(` — Declares the `QLDataFetchCallback` type alias so callback signatures stay readable and consistent.
- Line 35: `typedef QLSeoBuilder = QLSeoConfig Function(` — Declares the `QLSeoBuilder` type alias so callback signatures stay readable and consistent.
- Line 39: `class QLSeoConfig {` — Defines the `QLSeoConfig` type and its fields, methods, and lifecycle.
- Line 95: `enum QLTransitionType {` — Enumerates the finite states or modes supported by `QLTransitionType`.
- Line 106: `abstract class QLMiddleware {` — Defines the abstract `QLMiddleware` contract used by implementations elsewhere in the framework.
- Line 115: `typedef QLWidgetBuilder = Widget Function(` — Declares the `QLWidgetBuilder` type alias so callback signatures stay readable and consistent.
- Line 117: `typedef QLLayoutBuilder = Widget Function(` — Declares the `QLLayoutBuilder` type alias so callback signatures stay readable and consistent.
- Line 125: `class QLRouteInfo {` — Defines the `QLRouteInfo` type and its fields, methods, and lifecycle.
- Line 183: `typedef QLSchemaFetchCallback = FutureOr<Map<String, dynamic>> Function(` — Declares the `QLSchemaFetchCallback` type alias so callback signatures stay readable and consistent.
- Line 191: `class QLRoute {` — Defines the `QLRoute` type and its fields, methods, and lifecycle.
- Line 234: `class _RadixMatch {` — Defines the `_RadixMatch` type and its fields, methods, and lifecycle.
- Line 240: `class _RadixNode {` — Defines the `_RadixNode` type and its fields, methods, and lifecycle.
- Line 248: `class _QLRadixTrie {` — Defines the `_QLRadixTrie` type and its fields, methods, and lifecycle.
- Line 328: `abstract final class QLHydration {` — Provides a static namespace of constants and helper methods under `QLHydration`.
- Line 393: `class QLNavController extends ChangeNotifier {` — Defines the `QLNavController` type and its fields, methods, and lifecycle.
- Line 590: `abstract final class QLServerRenderer {` — Provides a static namespace of constants and helper methods under `QLServerRenderer`.
- Line 685: `class QLSeoHead extends StatelessWidget {` — Defines the `QLSeoHead` type and its fields, methods, and lifecycle.
- Line 712: `class QLRouteParser extends RouteInformationParser<QLRouteInfo> {` — Defines the `QLRouteParser` type and its fields, methods, and lifecycle.
- …and 7 more top-level declarations.

## Important members and helpers
- Line 61: `String generateHtmlTags() {` — Part of the public or internal API; it is named `generateHtmlTags` and contributes to this file’s behavior.
- Line 147: `String param(String key, {String fallback = ''}) => params[key] ?? fallback;` — Part of the public or internal API; it is named `param` and contributes to this file’s behavior.
- Line 148: `int intParam(String key, {int fallback = 0}) =>` — Part of the public or internal API; it is named `intParam` and contributes to this file’s behavior.
- Line 150: `String query(String key, {String fallback = ''}) =>` — Part of the public or internal API; it is named `query` and contributes to this file’s behavior.
- Line 153: `QLRouteInfo copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 251: `void insert(String pattern, List<QLRoute> routeChain) {` — Part of the public or internal API; it is named `insert` and contributes to this file’s behavior.
- Line 309: `List<String> _zeroAllocSplit(String path) {` — Part of the public or internal API; it is named `_zeroAllocSplit` and contributes to this file’s behavior.
- Line 423: `void _registerRoutes(List<QLRoute> routes, String prefix,` — Part of the public or internal API; it is named `_registerRoutes` and contributes to this file’s behavior.
- Line 440: `void switchBranch(int index, {String? defaultPath}) {` — Part of the public or internal API; it is named `switchBranch` and contributes to this file’s behavior.
- Line 455: `Future<void> replaceRoot(QLRouteInfo info) async {` — Part of the public or internal API; it is named `replaceRoot` and contributes to this file’s behavior.
- Line 463: `Future<void> push(QLRouteInfo info) async {` — Part of the public or internal API; it is named `push` and contributes to this file’s behavior.
- Line 470: `Future<void> pushPath(String path, {Map<String, String>? q, Object? extra}) {` — Part of the public or internal API; it is named `pushPath` and contributes to this file’s behavior.
- Line 478: `bool pop([Object? result]) {` — Part of the public or internal API; it is named `pop` and contributes to this file’s behavior.
- Line 485: `Future<QLRouteInfo?> _runPipeline(QLRouteInfo info) async {` — Part of the public or internal API; it is named `_runPipeline` and contributes to this file’s behavior.
- Line 511: `Future<QLRouteInfo> _resolveRouteProps(QLRoute leaf, QLRouteInfo info) async {` — Part of the public or internal API; it is named `_resolveRouteProps` and contributes to this file’s behavior.
- Line 545: `Widget resolveWidget(BuildContext context, QLRouteInfo info) {` — Resolves an abstract value into a concrete runtime value or path.
- Line 615: `void register(List<QLRoute> rt, String prefix,` — Registers a resource, manifest, or handler into the owning registry.
- Line 696: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 716: `Future<QLRouteInfo> parseRouteInformation(RouteInformation info) async {` — Parses a serialized input into the framework’s structured model.
- Line 746: `Future<void> setInitialRoutePath(QLRouteInfo configuration) async {` — Part of the public or internal API; it is named `setInitialRoutePath` and contributes to this file’s behavior.
- Line 751: `Future<void> setNewRoutePath(QLRouteInfo info) async => controller.push(info);` — Part of the public or internal API; it is named `setNewRoutePath` and contributes to this file’s behavior.
- Line 754: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 760: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 832: `Widget buildPage(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- …and 9 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 1038 lines in the source file.
- 25 top-level declarations detected by static analysis.
- 33 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
