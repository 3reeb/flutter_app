# `src/runtime/omni_cores/portal_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildPortal(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildPortal` and contributes to this file’s behavior.
- Line 243: `class _QLOverlayEntryNode extends StatefulWidget {` — Defines the `_QLOverlayEntryNode` type and its fields, methods, and lifecycle.
- Line 253: `class _QLOverlayEntryNodeState extends State<_QLOverlayEntryNode> {` — Defines the `_QLOverlayEntryNodeState` type and its fields, methods, and lifecycle.
- Line 309: `void _registerPortalAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerPortalAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 9: `QLBackgroundEffect parseEffect(String effect) {` — Parses a serialized input into the framework’s structured model.
- Line 22: `QLSheetEdge parseEdge(String edge) {` — Parses a serialized input into the framework’s structured model.
- Line 35: `QLResizeEdge parseResizeEdge(String edge) {` — Parses a serialized input into the framework’s structured model.
- Line 71: `QLSpatialConfig buildConfig(BuildContext mountCtx) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 257: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 264: `void didUpdateWidget(covariant _QLOverlayEntryNode oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 273: `void _onTriggerChanged() {` — Part of the public or internal API; it is named `_onTriggerChanged` and contributes to this file’s behavior.
- Line 295: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 302: `Widget build(BuildContext context) => const SizedBox.shrink();` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 316 lines in the source file.
- 4 top-level declarations detected by static analysis.
- 9 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
