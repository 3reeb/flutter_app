# `src/runtime/omni_cores/layout_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildLayout(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildLayout` and contributes to this file’s behavior.
- Line 32: `void _registerRichSpatialLayouts(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerRichSpatialLayouts` and contributes to this file’s behavior.
- Line 752: `TextStyle _resolveDecorationTextStyle(` — Part of the public or internal API; it is named `_resolveDecorationTextStyle` and contributes to this file’s behavior.
- Line 814: `InlineSpan _buildDecorationPartSpan(` — Part of the public or internal API; it is named `_buildDecorationPartSpan` and contributes to this file’s behavior.
- Line 871: `Widget _buildDecorationRichText(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildDecorationRichText` and contributes to this file’s behavior.
- Line 950: `void _registerLayoutAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerLayoutAliases` and contributes to this file’s behavior.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 991 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
