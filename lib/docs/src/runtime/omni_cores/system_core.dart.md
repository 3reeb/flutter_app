# `src/runtime/omni_cores/system_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildSystem(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildSystem` and contributes to this file’s behavior.
- Line 290: `class _QLSystemAsyncNode extends StatefulWidget {` — Defines the `_QLSystemAsyncNode` type and its fields, methods, and lifecycle.
- Line 305: `class _QLSystemAsyncNodeState extends State<_QLSystemAsyncNode> {` — Defines the `_QLSystemAsyncNodeState` type and its fields, methods, and lifecycle.
- Line 364: `class _QLSystemRateLimitNode extends StatefulWidget {` — Defines the `_QLSystemRateLimitNode` type and its fields, methods, and lifecycle.
- Line 374: `class _QLSystemRateLimitNodeState extends State<_QLSystemRateLimitNode> {` — Defines the `_QLSystemRateLimitNodeState` type and its fields, methods, and lifecycle.
- Line 387: `class _QLLifecycleNode extends StatefulWidget {` — Defines the `_QLLifecycleNode` type and its fields, methods, and lifecycle.
- Line 396: `class _QLLifecycleNodeState extends State<_QLLifecycleNode> {` — Defines the `_QLLifecycleNodeState` type and its fields, methods, and lifecycle.
- Line 414: `class _QLVsyncTimerNode extends StatefulWidget {` — Defines the `_QLVsyncTimerNode` type and its fields, methods, and lifecycle.
- Line 428: `class _QLVsyncTimerNodeState extends State<_QLVsyncTimerNode>` — Defines the `_QLVsyncTimerNodeState` type and its fields, methods, and lifecycle.
- Line 456: `class _QLDataPipeNode extends StatefulWidget {` — Defines the `_QLDataPipeNode` type and its fields, methods, and lifecycle.
- Line 475: `class _QLDataPipeNodeState extends State<_QLDataPipeNode> {` — Defines the `_QLDataPipeNodeState` type and its fields, methods, and lifecycle.
- Line 526: `class _QLKineticPipeNode extends StatefulWidget {` — Defines the `_QLKineticPipeNode` type and its fields, methods, and lifecycle.
- Line 541: `class _QLKineticPipeNodeState extends State<_QLKineticPipeNode>` — Defines the `_QLKineticPipeNodeState` type and its fields, methods, and lifecycle.
- Line 591: `void _registerSystemAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerSystemAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 310: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 315: `void _run() async {` — Part of the public or internal API; it is named `_run` and contributes to this file’s behavior.
- Line 335: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 377: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 383: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 398: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 405: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 411: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 434: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 446: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 452: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 479: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 487: `void didUpdateWidget(covariant _QLDataPipeNode oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 499: `void _process() {` — Part of the public or internal API; it is named `_process` and contributes to this file’s behavior.
- Line 516: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 522: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 549: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 556: `void _onSourceUpdate() {` — Part of the public or internal API; it is named `_onSourceUpdate` and contributes to this file’s behavior.
- Line 581: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 588: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 600 lines in the source file.
- 14 top-level declarations detected by static analysis.
- 21 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
