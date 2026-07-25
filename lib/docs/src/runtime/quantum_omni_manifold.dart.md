# `src/runtime/quantum_omni_manifold.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

Author-intent note: QUANTUM OMNI MANIFOLD v3.0 - UNCOMPROMISED SPATIAL ISOLATE CALCULATOR

## Dependencies
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 13: `class QLManifoldSpatialTask` — Defines the `QLManifoldSpatialTask` type and its fields, methods, and lifecycle.
- Line 142: `void registerOmniManifold(QuantumVM vm) {` — Registers a resource, manifest, or handler into the owning registry.

## Important members and helpers
- Line 16: `dynamic encode(Map<String, dynamic> input) => input;` — Serializes the object into a portable or wire-ready form.
- Line 19: `dynamic compute(dynamic encoded) {` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 38: `double resolveAxis(Map rule, dynamic record, int loopIdx, String axis) {` — Resolves an abstract value into a concrete runtime value or path.
- Line 129: `Map<String, dynamic> decode(dynamic raw) {` — Deserializes a serialized input into the runtime form.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 261 lines in the source file.
- 2 top-level declarations detected by static analysis.
- 4 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
