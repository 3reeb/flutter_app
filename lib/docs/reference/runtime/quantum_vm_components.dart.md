# `src/runtime/quantum_vm_components.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

## Dependencies
- part of 'quantum_vm.dart';

## Top-level declarations
- Line 3: `typedef QuantumComponentBuilder = Widget Function(` — Declares the `QuantumComponentBuilder` type alias so callback signatures stay readable and consistent.
- Line 9: `class _AliasContext extends QLContext {` — Defines the `_AliasContext` type and its fields, methods, and lifecycle.
- Line 23: `extension QLContextSubtype on QLContext {` — Extends an existing type with convenience helpers without changing the original class.
- Line 71: `Widget _buildComponent(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildComponent` and contributes to this file’s behavior.
- Line 91: `void _registerComponentAliases(QuantumVM vm) {}` — Part of the public or internal API; it is named `_registerComponentAliases` and contributes to this file’s behavior.
- Line 93: `Widget _buildComponentDefine(_AliasContext ctx) {` — Part of the public or internal API; it is named `_buildComponentDefine` and contributes to this file’s behavior.
- Line 109: `Widget _buildComponentUse(_AliasContext ctx) {` — Part of the public or internal API; it is named `_buildComponentUse` and contributes to this file’s behavior.
- Line 157: `Widget _buildComponentScoped(_AliasContext ctx) {` — Part of the public or internal API; it is named `_buildComponentScoped` and contributes to this file’s behavior.
- Line 168: `Widget _buildComponentLink(_AliasContext ctx) {` — Part of the public or internal API; it is named `_buildComponentLink` and contributes to this file’s behavior.
- Line 179: `void _registerComponentDefinition(_QLComponentDefinition definition) {` — Part of the public or internal API; it is named `_registerComponentDefinition` and contributes to this file’s behavior.
- Line 218: `Map<String, dynamic> _componentSchemaForValue(dynamic value) {` — Part of the public or internal API; it is named `_componentSchemaForValue` and contributes to this file’s behavior.
- Line 246: `Map<String, dynamic> _componentRawMap(_AliasContext ctx) {` — Part of the public or internal API; it is named `_componentRawMap` and contributes to this file’s behavior.
- Line 423: `Map<String, dynamic> _asMap(dynamic raw) {` — Part of the public or internal API; it is named `_asMap` and contributes to this file’s behavior.
- Line 428: `List<dynamic> _asList(dynamic raw) {` — Part of the public or internal API; it is named `_asList` and contributes to this file’s behavior.
- Line 473: `Map<String, _QLComponentComputedSpec> _parseComputed(dynamic raw) {` — Part of the public or internal API; it is named `_parseComputed` and contributes to this file’s behavior.
- Line 485: `List<String> _normalizeDependencies(dynamic raw) {` — Part of the public or internal API; it is named `_normalizeDependencies` and contributes to this file’s behavior.
- Line 515: `List<dynamic> _parseActionList(dynamic raw) {` — Part of the public or internal API; it is named `_parseActionList` and contributes to this file’s behavior.
- Line 524: `List<_QLComponentEffectSpec> _parseEffects(dynamic raw) {` — Part of the public or internal API; it is named `_parseEffects` and contributes to this file’s behavior.
- …and 30 more top-level declarations.

## Important members and helpers
- Line 25: `String resolvedSubType({String fallback = ''}) {` — Resolves an abstract value into a concrete runtime value or path.
- Line 1623: `Map<String, dynamic> toMetadata() => <String, dynamic>{` — Converts the object into another representation.
- Line 1649: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 1686: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 1695: `Map<String, dynamic> toJson() => toMap();` — Converts the object into another representation.
- Line 1711: `Map<String, dynamic> toJson() => <String, dynamic>{` — Converts the object into another representation.
- Line 1740: `Map<String, dynamic> toJson() => <String, dynamic>{` — Converts the object into another representation.
- Line 1791: `SessionContext _sessionFromEnv(Map<String, dynamic> env) {` — Part of the public or internal API; it is named `_sessionFromEnv` and contributes to this file’s behavior.
- Line 1816: `Map<String, dynamic> _runtimeProfile() {` — Part of the public or internal API; it is named `_runtimeProfile` and contributes to this file’s behavior.
- Line 1824: `QuantumPermissionDecision _permissionDecision(BuildContext context) {` — Part of the public or internal API; it is named `_permissionDecision` and contributes to this file’s behavior.
- Line 1864: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 1872: `void didChangeDependencies() {` — Part of the public or internal API; it is named `didChangeDependencies` and contributes to this file’s behavior.
- Line 1878: `void didUpdateWidget(covariant _QLComponentRuntimeHost oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 1884: `void _syncRuntimeState() {` — Part of the public or internal API; it is named `_syncRuntimeState` and contributes to this file’s behavior.
- Line 1902: `void _syncStoreInputs() {` — Part of the public or internal API; it is named `_syncStoreInputs` and contributes to this file’s behavior.
- Line 1935: `void _syncComputed() {` — Part of the public or internal API; it is named `_syncComputed` and contributes to this file’s behavior.
- Line 1947: `void _syncWatchers() {` — Part of the public or internal API; it is named `_syncWatchers` and contributes to this file’s behavior.
- Line 1960: `void _syncEffects() {` — Part of the public or internal API; it is named `_syncEffects` and contributes to this file’s behavior.
- Line 1975: `void runEffect() {` — Part of the public or internal API; it is named `runEffect` and contributes to this file’s behavior.
- Line 2367: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 2403: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- …and 10 more member declarations or helpers.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 2491 lines in the source file.
- 48 top-level declarations detected by static analysis.
- 34 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
