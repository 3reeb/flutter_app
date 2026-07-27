# `src/runtime/quantum_core_schema_registry.dart`

## What this file is
A registry module. It stores keyed definitions or instances, exposes lookup and registration helpers, and centralizes a class of metadata that multiple runtime subsystems consume.

Author-intent note: QUANTUM CORE SCHEMA REGISTRY — lazy file-backed schema catalog

## Dependencies
- Core Dart library: `dart:async`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../foundation/quantum_yaml_engine.dart`.
- Internal framework dependency: `quantum_core_file_registry.dart`.

## Top-level declarations
- Line 20: `class QLCorePropSpec {` — Defines the `QLCorePropSpec` type and its fields, methods, and lifecycle.
- Line 56: `class QLCoreSlotSpec {` — Defines the `QLCoreSlotSpec` type and its fields, methods, and lifecycle.
- Line 79: `class QLCoreSchemaDescriptor {` — Defines the `QLCoreSchemaDescriptor` type and its fields, methods, and lifecycle.
- Line 146: `final class QuantumCoreSchemaRegistry {` — Part of the public or internal API; it is named `QuantumCoreSchemaRegistry` and contributes to this file’s behavior.
- Line 1986: `QLCoreSchemaDescriptor _schema({` — Part of the public or internal API; it is named `_schema` and contributes to this file’s behavior.
- Line 2007: `QLCorePropSpec _prop(` — Part of the public or internal API; it is named `_prop` and contributes to this file’s behavior.
- Line 2028: `QLCoreSlotSpec _slot(` — Part of the public or internal API; it is named `_slot` and contributes to this file’s behavior.

## Important members and helpers
- Line 41: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 69: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 100: `Map<String, dynamic> _mergeMaps(` — Part of the public or internal API; it is named `_mergeMaps` and contributes to this file’s behavior.
- Line 112: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 124: `QLCoreSchemaDescriptor merge(QLCoreSchemaDescriptor parent) {` — Part of the public or internal API; it is named `merge` and contributes to this file’s behavior.
- Line 161: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 170: `void installDefaults({` — Part of the public or internal API; it is named `installDefaults` and contributes to this file’s behavior.
- Line 198: `void registerCore(String name, QLCoreSchemaDescriptor schema) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 203: `void registerAlias(String name, QLCoreSchemaDescriptor schema,` — Registers a resource, manifest, or handler into the owning registry.
- Line 212: `void registerFileSource(String name, String assetPath,` — Registers a resource, manifest, or handler into the owning registry.
- Line 224: `bool hasName(String name) =>` — Part of the public or internal API; it is named `hasName` and contributes to this file’s behavior.
- Line 245: `Future<QLCoreSchemaDescriptor?> resolve(String name) async {` — Resolves an abstract value into a concrete runtime value or path.
- Line 267: `Future<Map<String, dynamic>?> describe(String name) async {` — Part of the public or internal API; it is named `describe` and contributes to this file’s behavior.
- Line 272: `Map<String, dynamic>? describeCached(String name) => peek(name)?.toMap();` — Part of the public or internal API; it is named `describeCached` and contributes to this file’s behavior.
- Line 274: `Future<Map<String, dynamic>?> describeAny(String name) async =>` — Part of the public or internal API; it is named `describeAny` and contributes to this file’s behavior.
- Line 279: `Map<String, dynamic> snapshot() => <String, dynamic>{` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 286: `String exportMarkdown() {` — Part of the public or internal API; it is named `exportMarkdown` and contributes to this file’s behavior.
- Line 317: `Future<void> _seedBuiltIns() async {` — Part of the public or internal API; it is named `_seedBuiltIns` and contributes to this file’s behavior.
- …and 5 more member declarations or helpers.

## How it works
A registry file is centered on keyed lookup and controlled registration. Other subsystems depend on it when they need a single source of truth for loaded definitions or active instances.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 2039 lines in the source file.
- 7 top-level declarations detected by static analysis.
- 29 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
