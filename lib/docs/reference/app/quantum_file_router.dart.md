# `src/app/quantum_file_router.dart`

## What this file is
A file-based routing subsystem. It discovers route assets, converts naming conventions into URL patterns, caches route metadata, and exposes runtime route injection and invalidation.

Author-intent note: QUANTUM FILE ROUTER v1.0 — NEXT.JS-STYLE FILE-BASED ROUTING

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 33: `class QLFileRouteEntry {` — Defines the `QLFileRouteEntry` type and its fields, methods, and lifecycle.
- Line 74: `abstract final class QLFileRouteParser {` — Provides a static namespace of constants and helper methods under `QLFileRouteParser`.
- Line 181: `class QuantumFileRouter {` — Defines the `QuantumFileRouter` type and its fields, methods, and lifecycle.
- Line 572: `class _DirTree {` — Defines the `_DirTree` type and its fields, methods, and lifecycle.
- Line 582: `class _LazyPagePolicyMiddleware extends QLMiddleware {` — Defines the `_LazyPagePolicyMiddleware` type and its fields, methods, and lifecycle.
- Line 635: `class _YamlMiddleware extends QLMiddleware {` — Defines the `_YamlMiddleware` type and its fields, methods, and lifecycle.
- Line 681: `class _QLFileRouteView extends StatefulWidget {` — Defines the `_QLFileRouteView` type and its fields, methods, and lifecycle.
- Line 698: `class _QLFileRouteViewState extends State<_QLFileRouteView> {` — Defines the `_QLFileRouteViewState` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 201: `Future<Map<String, dynamic>> loadAssetManifest() => _loadAssetManifest();` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 207: `Future<List<QLRoute>> buildRoutes(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 226: `Future<List<QLRoute>> buildRoutesFromManifest(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 289: `void addRoute(QLRoute route) {` — Adds a child item, event, route, or data chunk to the current collection.
- Line 295: `void removeRoute(String path) {` — Removes a previously registered item or association.
- Line 300: `void invalidateCache() {` — Part of the public or internal API; it is named `invalidateCache` and contributes to this file’s behavior.
- Line 309: `Future<Map<String, dynamic>> _loadAssetManifest() async {` — Part of the public or internal API; it is named `_loadAssetManifest` and contributes to this file’s behavior.
- Line 332: `bool _isSupportedFormat(String path) {` — Part of the public or internal API; it is named `_isSupportedFormat` and contributes to this file’s behavior.
- Line 338: `bool _isSpecialFile(String path) {` — Part of the public or internal API; it is named `_isSpecialFile` and contributes to this file’s behavior.
- Line 346: `Future<_DirTree> _buildDirTree(` — Part of the public or internal API; it is named `_buildDirTree` and contributes to this file’s behavior.
- Line 370: `QLFileRouteEntry _enrichEntry(` — Part of the public or internal API; it is named `_enrichEntry` and contributes to this file’s behavior.
- Line 420: `int _compareEntries(QLFileRouteEntry a, QLFileRouteEntry b) {` — Part of the public or internal API; it is named `_compareEntries` and contributes to this file’s behavior.
- Line 432: `Future<QLRoute?> _buildRoute(` — Part of the public or internal API; it is named `_buildRoute` and contributes to this file’s behavior.
- Line 506: `Future<QLPageYamlConfig?> _loadPageConfigCached(String assetPath) async {` — Part of the public or internal API; it is named `_loadPageConfigCached` and contributes to this file’s behavior.
- Line 532: `QLMiddleware _mapToMiddleware(Map<String, dynamic> def) {` — Part of the public or internal API; it is named `_mapToMiddleware` and contributes to this file’s behavior.
- Line 536: `QLTransitionType _parseTransition(String name) {` — Part of the public or internal API; it is named `_parseTransition` and contributes to this file’s behavior.
- Line 549: `String _interpolateSeo(` — Part of the public or internal API; it is named `_interpolateSeo` and contributes to this file’s behavior.
- Line 707: `void reassemble() {` — Part of the public or internal API; it is named `reassemble` and contributes to this file’s behavior.
- Line 725: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 731: `void didUpdateWidget(covariant _QLFileRouteView oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 816: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
Route discovery starts from the asset manifest, then file names are normalized into route patterns, layouts, middleware, and metadata before the final route list is cached.
Runtime mutation is supported through explicit add/remove/invalidate APIs, so the app can refresh route data without a full rebuild of the underlying manifest.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 874 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 22 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
