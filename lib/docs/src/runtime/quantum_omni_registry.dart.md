# `src/runtime/quantum_omni_registry.dart`

## What this file is
A registry module. It stores keyed definitions or instances, exposes lookup and registration helpers, and centralizes a class of metadata that multiple runtime subsystems consume.

Author-intent note: QUANTUM OMNI REGISTRY v17.0 — 16-CORE OMEGA+ BUILD (SPATIAL/GPU/DECORATION/CHART/ANIMATION EXTENDED)

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:ui`.
- Core Dart library: `dart:async`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Flutter framework import: `package:flutter/gestures.dart`.
- Internal framework dependency: `quantum_template_engine.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `../foundation/quantum_json_dsl.dart`.
- Internal framework dependency: `../features/charts/quantum_charts.dart`.
- Internal framework dependency: `../foundation/quantum_matrix_engine.dart`.
- part 'omni_cores/box_core.dart';
- part 'omni_cores/action_core.dart';
- part 'omni_cores/field_core.dart';
- part 'omni_cores/text_core.dart';
- part 'omni_cores/media_core.dart';
- part 'omni_cores/visual_core.dart';
- part 'omni_cores/hook_core.dart';
- part 'omni_cores/data_core.dart';
- part 'omni_cores/portal_core.dart';
- part 'omni_cores/control_core.dart';
- part 'omni_cores/canvas_core.dart';
- part 'omni_cores/system_core.dart';
- part 'omni_cores/layout_core.dart';
- part 'omni_cores/decoration_core.dart';
- part 'omni_cores/template_core.dart';
- part 'omni_cores/connect_core.dart';
- part 'omni_cores/chart_core.dart';
- part 'omni_cores/animation_core.dart';
- part 'omni_cores/stream_core.dart';
- part 'omni_cores/collab_core.dart';

## Top-level declarations
- Line 61: `class _AliasContext extends QLContext {` — Defines the `_AliasContext` type and its fields, methods, and lifecycle.
- Line 84: `void clearQuantumInputRegistry() {` — Part of the public or internal API; it is named `clearQuantumInputRegistry` and contributes to this file’s behavior.
- Line 145: `abstract final class QDesignMatrix {` — Provides a static namespace of constants and helper methods under `QDesignMatrix`.
- Line 348: `void registerOmniComponents(QuantumVM vm) {` — Registers a resource, manifest, or handler into the owning registry.

## Important members and helpers
- Line 102: `T Function(QLFormController form) creator,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.

## How it works
A registry file is centered on keyed lookup and controlled registration. Other subsystems depend on it when they need a single source of truth for loaded definitions or active instances.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 456 lines in the source file.
- 4 top-level declarations detected by static analysis.
- 1 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
