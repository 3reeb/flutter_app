# `src/app/quantum_app_entry.dart`

## What this file is
An app-level support module. These files usually connect boot-time config, shell behavior, HTTP transport, or file routing into the overall Flutter application.

Author-intent note: QUANTUM APP ENTRY v1.0 — SINGLE-FILE APP BOOTSTRAPPER

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:io`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `quantum_boot_schema.dart`.

## Top-level declarations
- Line 36: `class QLYamlAppEnv {` — Defines the `QLYamlAppEnv` type and its fields, methods, and lifecycle.
- Line 60: `class QuantumAppManifest {` — Defines the `QuantumAppManifest` type and its fields, methods, and lifecycle.
- Line 260: `QuantumAppManifest quantumApp({` — Part of the public or internal API; it is named `quantumApp` and contributes to this file’s behavior.
- Line 296: `void bootQuantumManifestApp(QuantumAppManifest manifest) {` — Part of the public or internal API; it is named `bootQuantumManifestApp` and contributes to this file’s behavior.
- Line 312: `void bootQuantumYamlApp(` — Part of the public or internal API; it is named `bootQuantumYamlApp` and contributes to this file’s behavior.
- Line 331: `class _QuantumBootLoader extends StatefulWidget {` — Defines the `_QuantumBootLoader` type and its fields, methods, and lifecycle.
- Line 348: `class _QuantumBootLoaderState extends State<_QuantumBootLoader> {` — Defines the `_QuantumBootLoaderState` type and its fields, methods, and lifecycle.
- Line 458: `class _QuantumYamlAppRoot extends StatefulWidget {` — Defines the `_QuantumYamlAppRoot` type and its fields, methods, and lifecycle.
- Line 466: `class _QuantumYamlAppRootState extends State<_QuantumYamlAppRoot> {` — Defines the `_QuantumYamlAppRootState` type and its fields, methods, and lifecycle.
- Line 568: `Future<QuantumAppConfig> _buildAppConfig({` — Part of the public or internal API; it is named `_buildAppConfig` and contributes to this file’s behavior.
- Line 642: `void _applySduiConfig(Map<String, dynamic> sduiConfig) {` — Part of the public or internal API; it is named `_applySduiConfig` and contributes to this file’s behavior.
- Line 675: `List<QLRoute> _buildExplicitRoutes(dynamic routesConfig) {` — Part of the public or internal API; it is named `_buildExplicitRoutes` and contributes to this file’s behavior.
- Line 694: `QLTransitionType _parseTransition(String? name) =>` — Part of the public or internal API; it is named `_parseTransition` and contributes to this file’s behavior.
- Line 749: `List<QuantumDomain> _buildDomainsFromYaml(` — Part of the public or internal API; it is named `_buildDomainsFromYaml` and contributes to this file’s behavior.
- Line 764: `class _QLFileRouteViewStatic extends StatefulWidget {` — Defines the `_QLFileRouteViewStatic` type and its fields, methods, and lifecycle.
- Line 773: `class _QLFileRouteViewStaticState extends State<_QLFileRouteViewStatic> {` — Defines the `_QLFileRouteViewStaticState` type and its fields, methods, and lifecycle.
- Line 891: `class _DefaultBootLoader extends StatelessWidget {` — Defines the `_DefaultBootLoader` type and its fields, methods, and lifecycle.
- Line 912: `class _DefaultErrorApp extends StatelessWidget {` — Defines the `_DefaultErrorApp` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 108: `Future<void> Function()? onBoot,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 109: `Future<void> Function(BuildContext context)? onReady,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 137: `Future<void> Function()? onBoot,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 138: `Future<void> Function(BuildContext context)? onReady,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 200: `QuantumAppManifest copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 213: `Future<void> Function()? onBoot,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 214: `Future<void> Function(BuildContext context)? onReady,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 236: `QuantumAppManifest withDomain(QuantumDomain domain) => copyWith(` — Part of the public or internal API; it is named `withDomain` and contributes to this file’s behavior.
- Line 240: `QuantumAppConfig toAppConfig() {` — Converts the object into another representation.
- Line 273: `Future<void> Function()? onBoot,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 274: `Future<void> Function(BuildContext context)? onReady,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 314: `void Function(QLYamlAppEnv env)? extend,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 315: `Widget Function()? loadingApp,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 316: `Widget Function(dynamic error)? errorApp,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 359: `void reassemble() {` — Part of the public or internal API; it is named `reassemble` and contributes to this file’s behavior.
- Line 381: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 389: `void _startDevWatcher() {` — Part of the public or internal API; it is named `_startDevWatcher` and contributes to this file’s behavior.
- Line 411: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 439: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 470: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 524: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 530: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 570: `void Function(QLYamlAppEnv env)? extend,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 780: `void reassemble() {` — Part of the public or internal API; it is named `reassemble` and contributes to this file’s behavior.
- …and 7 more member declarations or helpers.

## How it works
App-level modules wire the framework together for startup, shell rendering, HTTP transport, and file routing. They are the glue between core runtime and the shipped app.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 950 lines in the source file.
- 18 top-level declarations detected by static analysis.
- 31 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
