# `src/runtime/quantum_core_file_registry.dart`

## What this file is
A registry module. It stores keyed definitions or instances, exposes lookup and registration helpers, and centralizes a class of metadata that multiple runtime subsystems consume.

Author-intent note: Folder-based, lazy, override-friendly registry for macros, templates,

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 15: `typedef QLCoreFileLoader = Future<Map<String, dynamic>> Function(` — Declares the `QLCoreFileLoader` type alias so callback signatures stay readable and consistent.
- Line 19: `class QLCoreFileDescriptor {` — Defines the `QLCoreFileDescriptor` type and its fields, methods, and lifecycle.
- Line 53: `final class QLCoreFileRegistry {` — Part of the public or internal API; it is named `QLCoreFileRegistry` and contributes to this file’s behavior.

## Important members and helpers
- Line 40: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 95: `String _resolveCoreFromFolder(String path, {String? explicitCore}) {` — Part of the public or internal API; it is named `_resolveCoreFromFolder` and contributes to this file’s behavior.
- Line 113: `String _resolveTypeName(String path, {String? explicitType}) {` — Part of the public or internal API; it is named `_resolveTypeName` and contributes to this file’s behavior.
- Line 120: `String _key(String core, String typeName) =>` — Part of the public or internal API; it is named `_key` and contributes to this file’s behavior.
- Line 123: `void registerFolder(String folder, String core) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 129: `void registerBuiltIn(` — Registers a resource, manifest, or handler into the owning registry.
- Line 144: `void registerOverride(` — Registers a resource, manifest, or handler into the owning registry.
- Line 159: `void register(` — Registers a resource, manifest, or handler into the owning registry.
- Line 175: `void _register(` — Part of the public or internal API; it is named `_register` and contributes to this file’s behavior.
- Line 256: `Future<Map<String, dynamic>?> resolve(` — Resolves an abstract value into a concrete runtime value or path.
- Line 303: `Future<Map<String, dynamic>?> resolvePath(` — Resolves an abstract value into a concrete runtime value or path.
- Line 313: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 321: `Map<String, dynamic> snapshot({String? core}) {` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.

## How it works
A registry file is centered on keyed lookup and controlled registration. Other subsystems depend on it when they need a single source of truth for loaded definitions or active instances.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 330 lines in the source file.
- 3 top-level declarations detected by static analysis.
- 13 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
