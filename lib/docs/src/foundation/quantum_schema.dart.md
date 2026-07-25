# `src/foundation/quantum_schema.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:typed_data`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 9: `class QLBlockPayload {` — Defines the `QLBlockPayload` type and its fields, methods, and lifecycle.
- Line 22: `class QLSchemaFieldSpec {` — Defines the `QLSchemaFieldSpec` type and its fields, methods, and lifecycle.
- Line 89: `class QLSchemaBlueprint {` — Defines the `QLSchemaBlueprint` type and its fields, methods, and lifecycle.
- Line 653: `abstract final class QLSchemaCompiler {` — Provides a static namespace of constants and helper methods under `QLSchemaCompiler`.
- Line 926: `class QLSchemaRegistry {` — Defines the `QLSchemaRegistry` type and its fields, methods, and lifecycle.
- Line 1009: `extension QLSchemaRegistryInspector on QLSchemaRegistry {` — Extends an existing type with convenience helpers without changing the original class.

## Important members and helpers
- Line 15: `bool containsKey(String key) => data.containsKey(key);` — Part of the public or internal API; it is named `containsKey` and contributes to this file’s behavior.
- Line 16: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 104: `QLProjection createProjection(List<String> paths) {` — Factory entry point that constructs and returns the platform- or configuration-specific implementation.
- Line 114: `List<String> expandSelection(List<String> paths) {` — Part of the public or internal API; it is named `expandSelection` and contributes to this file’s behavior.
- Line 144: `int getIndex(String path) => byPath[path]?.index ?? -1;` — Part of the public or internal API; it is named `getIndex` and contributes to this file’s behavior.
- Line 148: `List<String> fieldPaths() =>` — Part of the public or internal API; it is named `fieldPaths` and contributes to this file’s behavior.
- Line 151: `Map<String, dynamic> parse(` — Parses a serialized input into the framework’s structured model.
- Line 191: `Map<String, dynamic> serialize(` — Serializes the object into a portable or wire-ready form.
- Line 220: `List<String> validate(` — Part of the public or internal API; it is named `validate` and contributes to this file’s behavior.
- Line 345: `List<String> _validateItem(` — Part of the public or internal API; it is named `_validateItem` and contributes to this file’s behavior.
- Line 392: `dynamic _parseValue(QLSchemaFieldSpec spec, dynamic raw) {` — Part of the public or internal API; it is named `_parseValue` and contributes to this file’s behavior.
- Line 431: `dynamic _serializeValue(QLSchemaFieldSpec spec, dynamic raw) {` — Part of the public or internal API; it is named `_serializeValue` and contributes to this file’s behavior.
- Line 458: `dynamic _parseItem(QLSchemaFieldSpec spec, dynamic raw) {` — Part of the public or internal API; it is named `_parseItem` and contributes to this file’s behavior.
- Line 487: `dynamic _serializeItem(QLSchemaFieldSpec spec, dynamic raw) {` — Part of the public or internal API; it is named `_serializeItem` and contributes to this file’s behavior.
- Line 516: `dynamic _parseBlockValue(QLSchemaFieldSpec spec, dynamic raw) {` — Part of the public or internal API; it is named `_parseBlockValue` and contributes to this file’s behavior.
- Line 526: `dynamic _serializeBlockValue(QLSchemaFieldSpec spec, dynamic raw) {` — Part of the public or internal API; it is named `_serializeBlockValue` and contributes to this file’s behavior.
- Line 592: `bool _isEmpty(dynamic value) {` — Part of the public or internal API; it is named `_isEmpty` and contributes to this file’s behavior.
- Line 600: `dynamic _readAt(Map<String, dynamic> root, List<dynamic> path) {` — Part of the public or internal API; it is named `_readAt` and contributes to this file’s behavior.
- Line 683: `void flatten(QLSchemaFieldSpec spec) {` — Part of the public or internal API; it is named `flatten` and contributes to this file’s behavior.
- Line 933: `void register(QLSchemaBlueprint schema) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 937: `void registerRaw(String name, Map<String, dynamic> definition) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 950: `bool hasSchema(String name) => _schemas.containsKey(name);` — Part of the public or internal API; it is named `hasSchema` and contributes to this file’s behavior.
- Line 952: `QLSchemaBlueprint compile(String name, Map<String, dynamic> definition) {` — Part of the public or internal API; it is named `compile` and contributes to this file’s behavior.
- Line 983: `Map<String, dynamic> snapshot() => {` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- …and 3 more member declarations or helpers.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.

## File size
- 1014 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 27 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
