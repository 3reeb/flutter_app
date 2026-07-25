# `src/runtime/omni_cores/action_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 6: `Widget _buildAction(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildAction` and contributes to this file’s behavior.
- Line 178: `void _injectRawPointer(QLContext ctx, PointerEvent e, String bindX,` — Part of the public or internal API; it is named `_injectRawPointer` and contributes to this file’s behavior.
- Line 195: `class _QLRawGestureNode extends StatelessWidget {` — Defines the `_QLRawGestureNode` type and its fields, methods, and lifecycle.
- Line 235: `class _QLViewportNode extends StatefulWidget {` — Defines the `_QLViewportNode` type and its fields, methods, and lifecycle.
- Line 243: `class _QLViewportNodeState extends State<_QLViewportNode> {` — Defines the `_QLViewportNodeState` type and its fields, methods, and lifecycle.
- Line 287: `void _registerActionAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerActionAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 30: `void _safeCall(Function? fn) {` — Part of the public or internal API; it is named `_safeCall` and contributes to this file’s behavior.
- Line 202: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 247: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 281: `Widget build(BuildContext context) => RawGestureDetector(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 336 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 4 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
