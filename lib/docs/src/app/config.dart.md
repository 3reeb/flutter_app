# `src/app/config.dart`

## What this file is
An app-level support module. These files usually connect boot-time config, shell behavior, HTTP transport, or file routing into the overall Flutter application.

Author-intent note: Single-source config schema for the Quantum framework.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:io`.
- Pub package import: `package:crypto/crypto.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../foundation/quantum_yaml_engine.dart`.
- Internal framework dependency: `../ui/quantum_navigation_engine.dart`.
- Internal framework dependency: `../plugins/quantum_api_engine.dart`.
- Internal framework dependency: `../plugins/quantum_api_shell.dart`.
- Internal framework dependency: `quantum_app_entry.dart`.
- Internal framework dependency: `quantum_app_shell.dart`.
- Internal framework dependency: `quantum_boot_schema.dart`.
- Internal framework dependency: `quantum_http_transport.dart`.
- Internal framework dependency: `quantum_file_router.dart`.

## Top-level declarations
- Line 41: `class QuantumBuildDefines {` — Defines the `QuantumBuildDefines` type and its fields, methods, and lifecycle.
- Line 62: `class QuantumBuildOverlay {` — Defines the `QuantumBuildOverlay` type and its fields, methods, and lifecycle.
- Line 111: `enum QuantumConfigSourceKind {` — Enumerates the finite states or modes supported by `QuantumConfigSourceKind`.
- Line 119: `enum QuantumConfigListMergeMode {` — Enumerates the finite states or modes supported by `QuantumConfigListMergeMode`.
- Line 126: `class QuantumConfigSourceResult {` — Defines the `QuantumConfigSourceResult` type and its fields, methods, and lifecycle.
- Line 150: `typedef QuantumConfigSourceLoader = Future<QuantumConfigSourceResult> Function(` — Declares the `QuantumConfigSourceLoader` type alias so callback signatures stay readable and consistent.
- Line 156: `class QuantumConfigSourceContext {` — Defines the `QuantumConfigSourceContext` type and its fields, methods, and lifecycle.
- Line 173: `abstract class QuantumConfigSource {` — Defines the abstract `QuantumConfigSource` contract used by implementations elsewhere in the framework.
- Line 200: `class QuantumInlineConfigSource extends QuantumConfigSource {` — Defines the `QuantumInlineConfigSource` type and its fields, methods, and lifecycle.
- Line 229: `class QuantumAssetConfigSource extends QuantumConfigSource {` — Defines the `QuantumAssetConfigSource` type and its fields, methods, and lifecycle.
- Line 266: `class QuantumFileConfigSource extends QuantumConfigSource {` — Defines the `QuantumFileConfigSource` type and its fields, methods, and lifecycle.
- Line 300: `class QuantumHttpConfigSource extends QuantumConfigSource {` — Defines the `QuantumHttpConfigSource` type and its fields, methods, and lifecycle.
- Line 409: `class QuantumCustomConfigSource extends QuantumConfigSource {` — Defines the `QuantumCustomConfigSource` type and its fields, methods, and lifecycle.
- Line 434: `class QuantumConfigMergePolicy {` — Defines the `QuantumConfigMergePolicy` type and its fields, methods, and lifecycle.
- Line 451: `class QuantumConfigSecurityPolicy {` — Defines the `QuantumConfigSecurityPolicy` type and its fields, methods, and lifecycle.
- Line 492: `class QuantumConfigCachePolicy {` — Defines the `QuantumConfigCachePolicy` type and its fields, methods, and lifecycle.
- Line 515: `class QuantumConfigThemeSection {` — Defines the `QuantumConfigThemeSection` type and its fields, methods, and lifecycle.
- Line 546: `class QuantumConfigRouterSection {` — Defines the `QuantumConfigRouterSection` type and its fields, methods, and lifecycle.
- …and 21 more top-level declarations.

## Important members and helpers
- Line 194: `Future<QuantumConfigSourceResult> load(QuantumConfigSourceContext context);` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 213: `Future<QuantumConfigSourceResult> load(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 246: `Future<QuantumConfigSourceResult> load(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 283: `Future<QuantumConfigSourceResult> load(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 327: `Future<QuantumConfigSourceResult> load(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 424: `Future<QuantumConfigSourceResult> load(QuantumConfigSourceContext context) {` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 476: `bool isLocked(String path) {` — Part of the public or internal API; it is named `isLocked` and contributes to this file’s behavior.
- Line 483: `bool isSensitive(String path) {` — Part of the public or internal API; it is named `isSensitive` and contributes to this file’s behavior.
- Line 534: `Map<String, dynamic> toLegacyMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 559: `Map<String, dynamic> toLegacyMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 577: `Map<String, dynamic> toLegacyMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 593: `Map<String, dynamic> toLegacyMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 637: `Map<String, dynamic> toLegacyMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 687: `Map<String, dynamic> toLegacyMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 738: `List<QuantumConfigSource> orderedSources() {` — Part of the public or internal API; it is named `orderedSources` and contributes to this file’s behavior.
- Line 773: `QuantumConfigRoot withBuildOverlay(QuantumBuildOverlay overlay) {` — Part of the public or internal API; it is named `withBuildOverlay` and contributes to this file’s behavior.
- Line 786: `QuantumConfigRoot withExtras(Map<String, dynamic> newExtras) {` — Part of the public or internal API; it is named `withExtras` and contributes to this file’s behavior.
- Line 822: `QuantumConfigResolutionReport copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 856: `QLAppYamlConfig toYamlConfig() => QLAppYamlConfig.fromMap(raw);` — Converts the object into another representation.
- Line 858: `Future<QuantumAppManifest> toManifest({` — Converts the object into another representation.
- Line 863: `Future<void> Function()? onBoot,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 864: `Future<void> Function(BuildContext context)? onReady,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 895: `Map<String, dynamic> toApiBootstrapMap() {` — Converts the object into another representation.
- Line 926: `QuantumConfig toQuantumRuntimeConfig() {` — Converts the object into another representation.
- …and 6 more member declarations or helpers.

## How it works
App-level modules wire the framework together for startup, shell rendering, HTTP transport, and file routing. They are the glue between core runtime and the shipped app.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 1325 lines in the source file.
- 39 top-level declarations detected by static analysis.
- 30 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
