# `src/foundation/quantum_json_dsl.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: JSON-NATIVE COMPONENT & LAYOUT DEFINITION LAYER

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `quantum_matrix_engine.dart`.

## Top-level declarations
- Line 78: `class QJsonTemplateEngine_D {` — Defines the `QJsonTemplateEngine_D` type and its fields, methods, and lifecycle.
- Line 326: `class _TemplateRecord {` — Defines the `_TemplateRecord` type and its fields, methods, and lifecycle.
- Line 376: `class _TemplateDrivenPlugin extends QLPlugin implements QLWidgetCapability {` — Defines the `_TemplateDrivenPlugin` type and its fields, methods, and lifecycle.
- Line 503: `extension QuantumVMJsonDslExtension on QuantumVM {` — Extends an existing type with convenience helpers without changing the original class.
- Line 666: `String _extractName(Map<String, dynamic> json) {` — Part of the public or internal API; it is named `_extractName` and contributes to this file’s behavior.
- Line 672: `Map<String, dynamic> _extractDefaultProps(dynamic raw) {` — Part of the public or internal API; it is named `_extractDefaultProps` and contributes to this file’s behavior.
- Line 681: `QMatrixResizeHandle _parseResizeHandle(dynamic raw) {` — Part of the public or internal API; it is named `_parseResizeHandle` and contributes to this file’s behavior.
- Line 710: `abstract final class _QLayoutJsonRegistry {` — Provides a static namespace of constants and helper methods under `_QLayoutJsonRegistry`.
- Line 738: `abstract final class QJsonDSL {` — Provides a static namespace of constants and helper methods under `QJsonDSL`.
- Line 819: `extension QuantumVMTemplateJsonExtension on QuantumVM {` — Extends an existing type with convenience helpers without changing the original class.

## Important members and helpers
- Line 353: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 388: `Widget buildWidget(BuildContext ctx, QLBlueprint node, QLDataStore store) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 512: `void defineMatrixLayoutJson(Map<String, dynamic> json) {` — Part of the public or internal API; it is named `defineMatrixLayoutJson` and contributes to this file’s behavior.
- Line 836: `void defineTemplate(Map<String, dynamic> json) =>` — Part of the public or internal API; it is named `defineTemplate` and contributes to this file’s behavior.
- Line 840: `void defineAllJson(List<Map<String, dynamic>> definitions) =>` — Part of the public or internal API; it is named `defineAllJson` and contributes to this file’s behavior.
- Line 843: `void defineAliasJson(Map<String, dynamic> json) {` — Part of the public or internal API; it is named `defineAliasJson` and contributes to this file’s behavior.
- Line 856: `void defineAliasesJson(Map<String, dynamic> aliases) {` — Part of the public or internal API; it is named `defineAliasesJson` and contributes to this file’s behavior.
- Line 872: `void defineOmniRegistryJson(Map<String, dynamic> json) {` — Part of the public or internal API; it is named `defineOmniRegistryJson` and contributes to this file’s behavior.
- Line 1011: `void defineDecorationJson(Map<String, dynamic> json) {` — Part of the public or internal API; it is named `defineDecorationJson` and contributes to this file’s behavior.
- Line 1030: `void registerJsonDslPlugins() {` — Registers a resource, manifest, or handler into the owning registry.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 1124 lines in the source file.
- 10 top-level declarations detected by static analysis.
- 10 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
