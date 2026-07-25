# `src/runtime/omni_cores/control_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildControl(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildControl` and contributes to this file’s behavior.
- Line 216: `final class _QLMachineRegistry {` — Part of the public or internal API; it is named `_QLMachineRegistry` and contributes to this file’s behavior.
- Line 225: `class _QLMachineController {` — Defines the `_QLMachineController` type and its fields, methods, and lifecycle.
- Line 287: `class _QLMachineNode extends StatefulWidget {` — Defines the `_QLMachineNode` type and its fields, methods, and lifecycle.
- Line 302: `class _QLMachineNodeState extends State<_QLMachineNode> {` — Defines the `_QLMachineNodeState` type and its fields, methods, and lifecycle.
- Line 363: `class _QLOptimisticNode extends StatefulWidget {` — Defines the `_QLOptimisticNode` type and its fields, methods, and lifecycle.
- Line 379: `class _QLOptimisticNodeState extends State<_QLOptimisticNode> {` — Defines the `_QLOptimisticNodeState` type and its fields, methods, and lifecycle.
- Line 411: `class _QLLocalReducerNode extends StatefulWidget {` — Defines the `_QLLocalReducerNode` type and its fields, methods, and lifecycle.
- Line 425: `class _QLLocalReducerNodeState extends State<_QLLocalReducerNode> {` — Defines the `_QLLocalReducerNodeState` type and its fields, methods, and lifecycle.
- Line 460: `void _registerControlAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerControlAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 220: `void register(String id, _QLMachineController ctrl) => _machines[id] = ctrl;` — Registers a resource, manifest, or handler into the owning registry.
- Line 222: `void remove(String id) => _machines.remove(id);` — Removes a previously registered item or association.
- Line 241: `bool can(String event) {` — Part of the public or internal API; it is named `can` and contributes to this file’s behavior.
- Line 251: `void send(String event, {Map<String, dynamic>? payload}) {` — Part of the public or internal API; it is named `send` and contributes to this file’s behavior.
- Line 262: `void _invokeEntry(String state) {` — Part of the public or internal API; it is named `_invokeEntry` and contributes to this file’s behavior.
- Line 283: `bool matches(String s) => current == s;` — Part of the public or internal API; it is named `matches` and contributes to this file’s behavior.
- Line 284: `bool matchesAny(List<String> list) => list.contains(current);` — Part of the public or internal API; it is named `matchesAny` and contributes to this file’s behavior.
- Line 305: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 325: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 331: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 381: `void _apply() {` — Part of the public or internal API; it is named `_apply` and contributes to this file’s behavior.
- Line 388: `void _rollback() {` — Part of the public or internal API; it is named `_rollback` and contributes to this file’s behavior.
- Line 394: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 428: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 433: `Future<void> dispatch(String type, Map<String, dynamic> payload) async {` — Part of the public or internal API; it is named `dispatch` and contributes to this file’s behavior.
- Line 441: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 486 lines in the source file.
- 10 top-level declarations detected by static analysis.
- 16 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
