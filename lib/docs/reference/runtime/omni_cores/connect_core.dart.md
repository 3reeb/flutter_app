# `src/runtime/omni_cores/connect_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `typedef QLBehaviorBuilder = Widget Function(QLContext ctx, Widget child);` — Declares the `QLBehaviorBuilder` type alias so callback signatures stay readable and consistent.
- Line 7: `class QLBehaviorRegistry {` — Defines the `QLBehaviorRegistry` type and its fields, methods, and lifecycle.
- Line 128: `class _QLHoverScaleBehavior extends StatefulWidget {` — Defines the `_QLHoverScaleBehavior` type and its fields, methods, and lifecycle.
- Line 133: `class _QLHoverScaleBehaviorState extends State<_QLHoverScaleBehavior> {` — Defines the `_QLHoverScaleBehaviorState` type and its fields, methods, and lifecycle.
- Line 145: `class _QLPressFeedbackBehavior extends StatefulWidget {` — Defines the `_QLPressFeedbackBehavior` type and its fields, methods, and lifecycle.
- Line 150: `class _QLPressFeedbackBehaviorState extends State<_QLPressFeedbackBehavior> {` — Defines the `_QLPressFeedbackBehaviorState` type and its fields, methods, and lifecycle.
- Line 163: `class QLBehaviorNode extends StatelessWidget {` — Defines the `QLBehaviorNode` type and its fields, methods, and lifecycle.
- Line 196: `Widget _firstChildOr(QLContext ctx, Widget fallback) =>` — Part of the public or internal API; it is named `_firstChildOr` and contributes to this file’s behavior.
- Line 199: `Widget _buildConnect(QLContext ctx) {` — Part of the public or internal API; it is named `_buildConnect` and contributes to this file’s behavior.
- Line 307: `void registerConnectOmniNodes(QuantumVM vm) {` — Registers a resource, manifest, or handler into the owning registry.

## Important members and helpers
- Line 136: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 153: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 176: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 327 lines in the source file.
- 10 top-level declarations detected by static analysis.
- 3 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
