# `src/runtime/quantum_sdui_type_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM SDUI TYPE ENGINE — schema export + TypeScript bundle generator

## Dependencies
- Core Dart library: `dart:convert`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `quantum_core_schema_registry.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `import {`.
- Exports `export const $bundleName = defineQuantumSduiBundle($json as const);`.
- Exports `export const quantumSdui = createQuantumSduiTypeEngine($bundleName);`.
- Exports `export const q = createQuantumDslHelpers($bundleName);`.
- Exports `export type QuantumSduiBundle = typeof $bundleName;`.
- Exports `export type QuantumSduiEngine = typeof quantumSdui;`.
- Exports `export type QuantumDslHelpers = typeof q;`.

## Top-level declarations
- Line 28: `class QuantumSduiTypeBundle {` — Defines the `QuantumSduiTypeBundle` type and its fields, methods, and lifecycle.
- Line 40: `final class QuantumSduiTypeEngine {` — Part of the public or internal API; it is named `QuantumSduiTypeEngine` and contributes to this file’s behavior.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 245 lines in the source file.
- 2 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
