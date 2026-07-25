# `src/runtime/omni_cores/box_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

Author-intent note: QUANTUM OMNI REGISTRY — BOX & LAYOUT FACTORY

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 12: `Widget _buildBox(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildBox` and contributes to this file’s behavior.
- Line 574: `class _QLMeasureNode extends SingleChildRenderObjectWidget {` — Defines the `_QLMeasureNode` type and its fields, methods, and lifecycle.
- Line 594: `class _RenderMeasureNode extends RenderProxyBox {` — Defines the `_RenderMeasureNode` type and its fields, methods, and lifecycle.
- Line 618: `Widget _applyImplicitBehaviors(_AliasContext ctx, Widget child) {` — Part of the public or internal API; it is named `_applyImplicitBehaviors` and contributes to this file’s behavior.
- Line 648: `Widget _buildSmartScrollViewport({required Axis axis, required Widget child}) {` — Part of the public or internal API; it is named `_buildSmartScrollViewport` and contributes to this file’s behavior.
- Line 664: `void _registerBoxAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerBoxAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 17: `Matrix4 _matrix4FromDynamic(dynamic v) {` — Part of the public or internal API; it is named `_matrix4FromDynamic` and contributes to this file’s behavior.
- Line 34: `Curve _curveFromName(String name) {` — Part of the public or internal API; it is named `_curveFromName` and contributes to this file’s behavior.
- Line 582: `RenderObject createRenderObject(BuildContext context) =>` — Factory entry point that constructs and returns the platform- or configuration-specific implementation.
- Line 586: `void updateRenderObject(` — Updates internal state or a derived representation.
- Line 602: `void performLayout() {` — Part of the public or internal API; it is named `performLayout` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 720 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 5 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
