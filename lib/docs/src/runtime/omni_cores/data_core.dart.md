# `src/runtime/omni_cores/data_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildData(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildData` and contributes to this file’s behavior.
- Line 305: `void _registerDataAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerDataAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 248: `Map<String, dynamic> _getMapData(int i) {` — Part of the public or internal API; it is named `_getMapData` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 310 lines in the source file.
- 2 top-level declarations detected by static analysis.
- 1 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
