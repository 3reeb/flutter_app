# `src/runtime/omni_cores/field_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildField(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildField` and contributes to this file’s behavior.
- Line 444: `class _QLInlineCellNode extends StatefulWidget {` — Defines the `_QLInlineCellNode` type and its fields, methods, and lifecycle.
- Line 449: `class _QLInlineCellNodeState extends State<_QLInlineCellNode> {` — Defines the `_QLInlineCellNodeState` type and its fields, methods, and lifecycle.
- Line 483: `class _QLRichTextNode extends StatefulWidget {` — Defines the `_QLRichTextNode` type and its fields, methods, and lifecycle.
- Line 488: `class _QLRichTextNodeState extends State<_QLRichTextNode> {` — Defines the `_QLRichTextNodeState` type and its fields, methods, and lifecycle.
- Line 509: `void _registerFieldAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerFieldAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 454: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 460: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 520 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 2 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
