# `src/foundation/quantum_yaml_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM YAML ENGINE v1.1 — OMEGA YAML-FIRST CONFIG SYSTEM

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:io`.
- Pub package import: `package:http/http.dart`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../foundation/quantum_isolate_bridge.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Pub package import: `package:yaml/yaml.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 35: `class QuantumYamlException implements Exception {` — Defines the `QuantumYamlException` type and its fields, methods, and lifecycle.
- Line 58: `class QLYamlNode {` — Defines the `QLYamlNode` type and its fields, methods, and lifecycle.
- Line 130: `class _ImportFrame {` — Defines the `_ImportFrame` type and its fields, methods, and lifecycle.
- Line 162: `class QLYamlEnv {` — Defines the `QLYamlEnv` type and its fields, methods, and lifecycle.
- Line 189: `class QuantumYamlEngine {` — Defines the `QuantumYamlEngine` type and its fields, methods, and lifecycle.
- Line 636: `abstract final class QLYamlConfig {` — Provides a static namespace of constants and helper methods under `QLYamlConfig`.
- Line 723: `class QLAppYamlConfig {` — Defines the `QLAppYamlConfig` type and its fields, methods, and lifecycle.
- Line 849: `class QLYamlThemeConfig {` — Defines the `QLYamlThemeConfig` type and its fields, methods, and lifecycle.
- Line 894: `enum QLYamlSemanticType {` — Enumerates the finite states or modes supported by `QLYamlSemanticType`.
- Line 909: `class QLPageYamlConfig {` — Defines the `QLPageYamlConfig` type and its fields, methods, and lifecycle.
- Line 1054: `void applyYamlMacros(Map<String, dynamic> macros) {` — Part of the public or internal API; it is named `applyYamlMacros` and contributes to this file’s behavior.
- Line 1065: `void applyYamlSchemas(Map<String, dynamic> schemas) {` — Part of the public or internal API; it is named `applyYamlSchemas` and contributes to this file’s behavior.
- Line 1077: `void applyYamlPipes(Map<String, dynamic> pipes) {` — Part of the public or internal API; it is named `applyYamlPipes` and contributes to this file’s behavior.
- Line 1088: `void applyYamlState(Map<String, dynamic> state) {` — Part of the public or internal API; it is named `applyYamlState` and contributes to this file’s behavior.

## Important members and helpers
- Line 42: `String toString() {` — Converts the object into another representation.
- Line 109: `QLYamlNode path(List<String> segments) {` — Part of the public or internal API; it is named `path` and contributes to this file’s behavior.
- Line 123: `String toString() => _raw.toString();` — Converts the object into another representation.
- Line 137: `bool contains(String candidate) {` — Part of the public or internal API; it is named `contains` and contributes to this file’s behavior.
- Line 239: `Future<Map<String, dynamic>> load(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 273: `Future<QLYamlNode> loadNode(String assetPath,` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 281: `Future<Map<String, dynamic>> parseString(` — Parses a serialized input into the framework’s structured model.
- Line 300: `void clearCaches() {` — Part of the public or internal API; it is named `clearCaches` and contributes to this file’s behavior.
- Line 306: `void clearCache() => clearCaches();` — Part of the public or internal API; it is named `clearCache` and contributes to this file’s behavior.
- Line 309: `Future<void> warmAll(List<String> assetPaths) async {` — Part of the public or internal API; it is named `warmAll` and contributes to this file’s behavior.
- Line 315: `Future<Map<String, dynamic>> _loadInternal(` — Part of the public or internal API; it is named `_loadInternal` and contributes to this file’s behavior.
- Line 363: `Future<String> _loadRawString(String path, {bool useCache = true}) async {` — Part of the public or internal API; it is named `_loadRawString` and contributes to this file’s behavior.
- Line 417: `Future<dynamic> _parseRaw(String raw) async {` — Part of the public or internal API; it is named `_parseRaw` and contributes to this file’s behavior.
- Line 445: `Future<dynamic> _resolveImports(` — Part of the public or internal API; it is named `_resolveImports` and contributes to this file’s behavior.
- Line 496: `Future<dynamic> _resolveImportDirective(` — Part of the public or internal API; it is named `_resolveImportDirective` and contributes to this file’s behavior.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on the `http` package for browser-side networking support.

## File size
- 1091 lines in the source file.
- 14 top-level declarations detected by static analysis.
- 15 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
