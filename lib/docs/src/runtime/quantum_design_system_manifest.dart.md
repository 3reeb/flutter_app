# `src/runtime/quantum_design_system_manifest.dart`

## What this file is
A manifest or catalog file. It collects structured metadata into a form that other runtime components can inspect, preload, validate, or resolve lazily.

Author-intent note: JSON-first compiler for design systems, components, templates, layouts,

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.

## Top-level declarations
- Line 12: `class QuantumDesignSystemBundle {` — Defines the `QuantumDesignSystemBundle` type and its fields, methods, and lifecycle.
- Line 98: `abstract final class QuantumDesignSystemCompiler {` — Provides a static namespace of constants and helper methods under `QuantumDesignSystemCompiler`.
- Line 247: `final class _SectionCollector {` — Part of the public or internal API; it is named `_SectionCollector` and contributes to this file’s behavior.

## Important members and helpers
- Line 74: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.
- Line 264: `void ingest(Map<String, dynamic> root) {` — Part of the public or internal API; it is named `ingest` and contributes to this file’s behavior.
- Line 334: `void _ingestAliases(Map<String, dynamic> raw) {` — Part of the public or internal API; it is named `_ingestAliases` and contributes to this file’s behavior.
- Line 355: `void _ingestCoreSection(Map<String, dynamic> root, String key) {` — Part of the public or internal API; it is named `_ingestCoreSection` and contributes to this file’s behavior.
- Line 380: `void _ingestStructuredSection(` — Part of the public or internal API; it is named `_ingestStructuredSection` and contributes to this file’s behavior.
- Line 404: `Map<String, dynamic> toMap() => <String, dynamic>{` — Converts the object into another representation.

## How it works
Manifest files keep structured metadata in a resolved form that can be consumed lazily by loaders, validators, or runtime builders.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 465 lines in the source file.
- 3 top-level declarations detected by static analysis.
- 6 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
