# `src/runtime/quantum_permissions.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:convert`.
- Internal framework dependency: `../plugins/quantum_auth_engine.dart`.

## Top-level declarations
- Line 10: `class QuantumPermissionException implements Exception {` — Defines the `QuantumPermissionException` type and its fields, methods, and lifecycle.
- Line 21: `class QuantumPermissionDecision {` — Defines the `QuantumPermissionDecision` type and its fields, methods, and lifecycle.
- Line 54: `class QuantumPermissionContext {` — Defines the `QuantumPermissionContext` type and its fields, methods, and lifecycle.
- Line 170: `class QuantumPermissionRegistry {` — Defines the `QuantumPermissionRegistry` type and its fields, methods, and lifecycle.
- Line 186: `class QuantumPermissionEngine {` — Defines the `QuantumPermissionEngine` type and its fields, methods, and lifecycle.
- Line 975: `extension QuantumSessionPermissionExtensions on SessionContext {` — Extends an existing type with convenience helpers without changing the original class.
- Line 1065: `dynamic _lookupAny(List<dynamic> sources, String path) {` — Part of the public or internal API; it is named `_lookupAny` and contributes to this file’s behavior.
- Line 1074: `dynamic _lookup(dynamic source, List<String> parts) {` — Part of the public or internal API; it is named `_lookup` and contributes to this file’s behavior.
- Line 1093: `Set<String> _mergeStringSets(Iterable<dynamic> values) {` — Part of the public or internal API; it is named `_mergeStringSets` and contributes to this file’s behavior.

## Important members and helpers
- Line 18: `String toString() => 'QuantumPermissionException($code): $message';` — Converts the object into another representation.
- Line 46: `Map<String, dynamic> toJson() => <String, dynamic>{` — Converts the object into another representation.
- Line 110: `Set<String> get roles => _mergeStringSets([` — Part of the public or internal API; it is named `_mergeStringSets` and contributes to this file’s behavior.
- Line 120: `Set<String> get permissions => _mergeStringSets([` — Part of the public or internal API; it is named `_mergeStringSets` and contributes to this file’s behavior.
- Line 130: `Set<String> get features => _mergeStringSets([` — Part of the public or internal API; it is named `_mergeStringSets` and contributes to this file’s behavior.
- Line 139: `Set<String> get subscriptions => _mergeStringSets([` — Part of the public or internal API; it is named `_mergeStringSets` and contributes to this file’s behavior.
- Line 150: `dynamic claim(String key) {` — Part of the public or internal API; it is named `claim` and contributes to this file’s behavior.
- Line 160: `bool hasRole(String role) => roles.contains(role);` — Part of the public or internal API; it is named `hasRole` and contributes to this file’s behavior.
- Line 161: `bool hasPermission(String permission) => permissions.contains(permission);` — Part of the public or internal API; it is named `hasPermission` and contributes to this file’s behavior.
- Line 162: `bool hasFeature(String featureName) => features.contains(featureName);` — Part of the public or internal API; it is named `hasFeature` and contributes to this file’s behavior.
- Line 163: `bool hasSubscription(String value) => subscriptions.contains(value);` — Part of the public or internal API; it is named `hasSubscription` and contributes to this file’s behavior.
- Line 165: `bool opIs(String value) => operation == value;` — Part of the public or internal API; it is named `opIs` and contributes to this file’s behavior.
- Line 166: `bool scopeIs(String value) =>` — Part of the public or internal API; it is named `scopeIs` and contributes to this file’s behavior.
- Line 177: `void register(String name, dynamic rule) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 181: `dynamic resolve(String name) => _rules[name];` — Resolves an abstract value into a concrete runtime value or path.
- Line 182: `bool contains(String name) => _rules.containsKey(name);` — Part of the public or internal API; it is named `contains` and contributes to this file’s behavior.
- Line 183: `void clear() => _rules.clear();` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 194: `QuantumPermissionDecision evaluate(` — Part of the public or internal API; it is named `evaluate` and contributes to this file’s behavior.
- Line 215: `bool allows(` — Part of the public or internal API; it is named `allows` and contributes to this file’s behavior.
- Line 222: `QuantumPermissionDecision require(` — Part of the public or internal API; it is named `require` and contributes to this file’s behavior.
- Line 976: `QuantumPermissionContext permissionContext({` — Part of the public or internal API; it is named `permissionContext` and contributes to this file’s behavior.
- Line 1001: `bool can(` — Part of the public or internal API; it is named `can` and contributes to this file’s behavior.
- Line 1028: `bool hasRoleValue(String role) => roles.contains(role);` — Part of the public or internal API; it is named `hasRoleValue` and contributes to this file’s behavior.
- Line 1029: `bool hasPermissionValue(String permission) =>` — Part of the public or internal API; it is named `hasPermissionValue` and contributes to this file’s behavior.
- …and 26 more member declarations or helpers.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 1112 lines in the source file.
- 9 top-level declarations detected by static analysis.
- 50 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
