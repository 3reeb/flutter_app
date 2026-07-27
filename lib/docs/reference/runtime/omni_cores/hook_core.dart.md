# `src/runtime/omni_cores/hook_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 3: `String _hookSignature(dynamic value) {` — Part of the public or internal API; it is named `_hookSignature` and contributes to this file’s behavior.
- Line 34: `QLBlueprint _cloneBlueprintAs(` — Part of the public or internal API; it is named `_cloneBlueprintAs` and contributes to this file’s behavior.
- Line 53: `class _QLHookLifecycleNode extends StatefulWidget {` — Defines the `_QLHookLifecycleNode` type and its fields, methods, and lifecycle.
- Line 68: `class _QLHookLifecycleNodeState extends State<_QLHookLifecycleNode> {` — Defines the `_QLHookLifecycleNodeState` type and its fields, methods, and lifecycle.
- Line 91: `class _QLHookEffectNode extends StatefulWidget {` — Defines the `_QLHookEffectNode` type and its fields, methods, and lifecycle.
- Line 108: `class _QLHookEffectNodeState extends State<_QLHookEffectNode> {` — Defines the `_QLHookEffectNodeState` type and its fields, methods, and lifecycle.
- Line 142: `Widget _buildHook(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildHook` and contributes to this file’s behavior.
- Line 341: `void _registerHookAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerHookAliases` and contributes to this file’s behavior.
- Line 366: `class _QLRefNode extends StatefulWidget {` — Defines the `_QLRefNode` type and its fields, methods, and lifecycle.
- Line 380: `class _QLRefNodeState extends State<_QLRefNode> {` — Defines the `_QLRefNodeState` type and its fields, methods, and lifecycle.
- Line 400: `class _QLIntervalNode extends StatefulWidget {` — Defines the `_QLIntervalNode` type and its fields, methods, and lifecycle.
- Line 418: `class _QLIntervalNodeState extends State<_QLIntervalNode> {` — Defines the `_QLIntervalNodeState` type and its fields, methods, and lifecycle.
- Line 446: `class _QLObservableNode extends StatefulWidget {` — Defines the `_QLObservableNode` type and its fields, methods, and lifecycle.
- Line 460: `class _QLObservableNodeState extends State<_QLObservableNode> {` — Defines the `_QLObservableNodeState` type and its fields, methods, and lifecycle.
- Line 484: `class _QLErrorBoundaryNode extends StatefulWidget {` — Defines the `_QLErrorBoundaryNode` type and its fields, methods, and lifecycle.
- Line 493: `class _QLErrorBoundaryNodeState extends State<_QLErrorBoundaryNode> {` — Defines the `_QLErrorBoundaryNodeState` type and its fields, methods, and lifecycle.
- Line 510: `class _QLErrorCatcher extends StatelessWidget {` — Defines the `_QLErrorCatcher` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 70: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 82: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 88: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 112: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 122: `void didUpdateWidget(covariant _QLHookEffectNode oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 129: `void _scheduleEffect({required bool force}) {` — Part of the public or internal API; it is named `_scheduleEffect` and contributes to this file’s behavior.
- Line 139: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 146: `Widget buildBody(BuildContext buildContext) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 383: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 388: `dynamic read() => _value;` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 389: `void write(dynamic v) {` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 394: `Widget build(BuildContext context) => QLDataScope(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 421: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 436: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 442: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 464: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 472: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 478: `Widget build(BuildContext context) => QLDataScope(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 496: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 515: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 522 lines in the source file.
- 17 top-level declarations detected by static analysis.
- 20 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
