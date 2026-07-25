# `src/app/quantum_boot_schema.dart`

## What this file is
An app-level support module. These files usually connect boot-time config, shell behavior, HTTP transport, or file routing into the overall Flutter application.

Author-intent note: QUANTUM BOOT SCHEMA — schema-first, lazy-loaded file catalog

## Dependencies
- Core Dart library: `dart:async`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `../runtime/quantum_core_schema_registry.dart`.

## Top-level declarations
- Line 20: `class QuantumBootSchema {` — Defines the `QuantumBootSchema` type and its fields, methods, and lifecycle.
- Line 309: `final class QuantumBootCatalog {` — Part of the public or internal API; it is named `QuantumBootCatalog` and contributes to this file’s behavior.

## Important members and helpers
- Line 165: `void installDefaults() {` — Part of the public or internal API; it is named `installDefaults` and contributes to this file’s behavior.
- Line 184: `QuantumBootSchema copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 212: `Future<void> registerManifest(Map<String, dynamic> manifest) async {` — Registers a resource, manifest, or handler into the owning registry.
- Line 244: `Future<Map<String, dynamic>?> load(String core, String typeName,` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 250: `Future<void> ensure(String core, String typeName,` — Guarantees that the named resource exists or has been registered before use.
- Line 260: `Future<void> ensureTemplate(String name) => ensure('template', name);` — Guarantees that the named resource exists or has been registered before use.
- Line 261: `Future<void> ensureMacro(String name) => ensure('macro', name);` — Guarantees that the named resource exists or has been registered before use.
- Line 262: `Future<void> ensureBox(String name) => ensure('box', name);` — Guarantees that the named resource exists or has been registered before use.
- Line 263: `Future<void> ensureLayout(String name) async {` — Guarantees that the named resource exists or has been registered before use.
- Line 270: `Future<void> preloadAll() async {` — Part of the public or internal API; it is named `preloadAll` and contributes to this file’s behavior.
- Line 299: `String _resolveTypeName(String path) {` — Part of the public or internal API; it is named `_resolveTypeName` and contributes to this file’s behavior.
- Line 315: `void configure(QuantumBootSchema schema) {` — Part of the public or internal API; it is named `configure` and contributes to this file’s behavior.
- Line 320: `Future<void> registerManifest(Map<String, dynamic> manifest) async {` — Registers a resource, manifest, or handler into the owning registry.
- Line 326: `Future<void> ensure(String core, String name, {bool useCache = true}) async {` — Guarantees that the named resource exists or has been registered before use.
- Line 331: `Future<void> ensureTemplate(String name) => ensure('template', name);` — Guarantees that the named resource exists or has been registered before use.
- Line 332: `Future<void> ensureMacro(String name) => ensure('macro', name);` — Guarantees that the named resource exists or has been registered before use.
- Line 333: `Future<void> ensureBox(String name) => ensure('box', name);` — Guarantees that the named resource exists or has been registered before use.
- Line 334: `Future<void> ensureLayout(String name) => ensure('layout', name);` — Guarantees that the named resource exists or has been registered before use.

## How it works
App-level modules wire the framework together for startup, shell rendering, HTTP transport, and file routing. They are the glue between core runtime and the shipped app.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 335 lines in the source file.
- 2 top-level declarations detected by static analysis.
- 18 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
