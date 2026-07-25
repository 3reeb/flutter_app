# `src/runtime/quantum_vm.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

Author-intent note: QUANTUM VIRTUAL MACHINE (QVM) v11.0 - GOD-MODE OMEGA CORE

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:math`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Pub package import: `package:collection/collection.dart`.
- Internal framework dependency: `../../quantum.dart`.
- part 'quantum_vm_components.dart';

## Top-level declarations
- Line 25: `class QuantumSecurityException implements Exception {` — Defines the `QuantumSecurityException` type and its fields, methods, and lifecycle.
- Line 32: `class QLSchemaSlice {` — Defines the `QLSchemaSlice` type and its fields, methods, and lifecycle.
- Line 39: `class QLLazySchemaView {` — Defines the `QLLazySchemaView` type and its fields, methods, and lifecycle.
- Line 72: `enum QLModuleVisibility { public, local, owner, secure }` — Enumerates the finite states or modes supported by `QLModuleVisibility`.
- Line 74: `class QLModuleAccessPolicy {` — Defines the `QLModuleAccessPolicy` type and its fields, methods, and lifecycle.
- Line 126: `class QLModuleRecord {` — Defines the `QLModuleRecord` type and its fields, methods, and lifecycle.
- Line 152: `class QLModuleRegistry {` — Defines the `QLModuleRegistry` type and its fields, methods, and lifecycle.
- Line 297: `class QLRegistryEntry {` — Defines the `QLRegistryEntry` type and its fields, methods, and lifecycle.
- Line 338: `class QuantumExtensionBundle {` — Defines the `QuantumExtensionBundle` type and its fields, methods, and lifecycle.
- Line 356: `abstract final class QLStableHasher {` — Provides a static namespace of constants and helper methods under `QLStableHasher`.
- Line 386: `abstract class QLPipes {` — Defines the abstract `QLPipes` contract used by implementations elsewhere in the framework.
- Line 710: `abstract final class QLSignalBatch {` — Provides a static namespace of constants and helper methods under `QLSignalBatch`.
- Line 741: `abstract final class QLPluginStreamRegistry {` — Provides a static namespace of constants and helper methods under `QLPluginStreamRegistry`.
- Line 750: `class QLBlueprint {` — Defines the `QLBlueprint` type and its fields, methods, and lifecycle.
- Line 808: `abstract final class QLCompiler {` — Provides a static namespace of constants and helper methods under `QLCompiler`.
- Line 1927: `class ParsedToken {` — Defines the `ParsedToken` type and its fields, methods, and lifecycle.
- Line 1933: `class _QLMacroSlots {` — Defines the `_QLMacroSlots` type and its fields, methods, and lifecycle.
- Line 1943: `class _QLMacroSlotList {` — Defines the `_QLMacroSlotList` type and its fields, methods, and lifecycle.
- …and 42 more top-level declarations.

## Important members and helpers
- Line 29: `String toString() => 'QuantumSecurityException: $message';` — Converts the object into another representation.
- Line 60: `Map<String, dynamic> pick(Iterable<String> names) {` — Part of the public or internal API; it is named `pick` and contributes to this file’s behavior.
- Line 101: `bool allows({` — Part of the public or internal API; it is named `allows` and contributes to this file’s behavior.
- Line 161: `QLModuleRecord register(Map<String, dynamic> manifest, {String? id}) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 192: `bool exists(String id) => _modules.containsKey(id);` — Part of the public or internal API; it is named `exists` and contributes to this file’s behavior.
- Line 195: `QLModuleRecord require(String id) {` — Part of the public or internal API; it is named `require` and contributes to this file’s behavior.
- Line 203: `bool canUse(String requester, String target, {String? ownerId}) {` — Part of the public or internal API; it is named `canUse` and contributes to this file’s behavior.
- Line 210: `List<String> importsFor(String moduleId) {` — Part of the public or internal API; it is named `importsFor` and contributes to this file’s behavior.
- Line 220: `dynamic section(String moduleId, Object path,` — Part of the public or internal API; it is named `section` and contributes to this file’s behavior.
- Line 247: `Map<String, dynamic> macrosFor(String moduleId, {String? ownerId}) {` — Part of the public or internal API; it is named `macrosFor` and contributes to this file’s behavior.
- Line 263: `void clear({String? moduleId}) {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 276: `Map<String, dynamic> snapshot({String requester = 'default'}) =>` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 294: `List<String> ids() => _modules.keys.toList(growable: false);` — Part of the public or internal API; it is named `ids` and contributes to this file’s behavior.
- Line 320: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 767: `Map<String, dynamic> toJson() => <String, dynamic>{` — Converts the object into another representation.
- Line 1619: `void addSlot(Map<String, dynamic> target, String name, dynamic raw) {` — Adds a child item, event, route, or data chunk to the current collection.
- Line 2137: `Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store);` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2141: `Widget buildSliver(BuildContext ctx, QLBlueprint node, QLDataStore store);` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2145: `Widget buildLayout(BuildContext ctx, QLBlueprint node, List<Widget> children,` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2150: `QLFragmentDraw buildFragment(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2155: `Widget buildKinetic(QLContext ctx, QLBlueprint node,` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2161: `dynamic buildInput(QLContext ctx, QLBlueprint node);` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2162: `void onTaskCompleted(QLContext ctx, dynamic result, QLDataStore store);` — Event handler or lifecycle callback.
- Line 2166: `Future<dynamic> executeSandboxed(` — Part of the public or internal API; it is named `executeSandboxed` and contributes to this file’s behavior.
- …and 102 more member declarations or helpers.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 7058 lines in the source file.
- 60 top-level declarations detected by static analysis.
- 126 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
