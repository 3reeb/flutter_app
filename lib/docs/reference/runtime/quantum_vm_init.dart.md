# `src/runtime/quantum_vm_init.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

Author-intent note: QUANTUM VIRTUAL MACHINE INITIALIZER v13.0 - OMEGA BUILD

## Dependencies
- Flutter framework import: `package:flutter/material.dart`.
- Core Dart library: `dart:typed_data`.
- Internal framework dependency: `../ui/quantum_theme_engine.dart`.
- Internal framework dependency: `../ui/quantum_components.dart`.
- Internal framework dependency: `../ui/quantum_behaviors.dart`.
- Internal framework dependency: `../ui/quantum_navigation_engine.dart`.
- Internal framework dependency: `quantum_data_orchestrator.dart`.
- Internal framework dependency: `quantum_omni_registry.dart`.
- Internal framework dependency: `quantum_core_schema_registry.dart`.
- Internal framework dependency: `quantum_sdui_type_engine.dart`.
- Internal framework dependency: `quantum_vm.dart`.
- Internal framework dependency: `quantum_data_pipeline.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 27: `class _BuiltInActionPlugin extends QLActionPlugin {` — Defines the `_BuiltInActionPlugin` type and its fields, methods, and lifecycle.
- Line 37: `void initQuantumBuiltIns(QuantumVM vm) {` — Initializes internal state and prepares the object for use.
- Line 489: `class LambdaActionPlugin extends QLActionPlugin {` — Defines the `LambdaActionPlugin` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 32: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 496: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 500 lines in the source file.
- 3 top-level declarations detected by static analysis.
- 2 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
