# `src/runtime/omni_cores/collab_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

Author-intent note: COLLAB CORE — Real-time collaboration primitives

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 8: `Widget _buildCollab(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildCollab` and contributes to this file’s behavior.
- Line 71: `final class _QLCollabRegistry {` — Part of the public or internal API; it is named `_QLCollabRegistry` and contributes to this file’s behavior.
- Line 121: `class _QLCursorOverlayNode extends StatefulWidget {` — Defines the `_QLCursorOverlayNode` type and its fields, methods, and lifecycle.
- Line 129: `class _QLCursorOverlayNodeState extends State<_QLCursorOverlayNode> {` — Defines the `_QLCursorOverlayNodeState` type and its fields, methods, and lifecycle.
- Line 151: `class _CursorDot extends StatelessWidget {` — Defines the `_CursorDot` type and its fields, methods, and lifecycle.
- Line 166: `class _QLCollabLockNode extends StatefulWidget {` — Defines the `_QLCollabLockNode` type and its fields, methods, and lifecycle.
- Line 173: `class _QLCollabLockNodeState extends State<_QLCollabLockNode> {` — Defines the `_QLCollabLockNodeState` type and its fields, methods, and lifecycle.
- Line 188: `void _registerCollabAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerCollabAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 89: `bool tryLock(String resource, String userId) {` — Part of the public or internal API; it is named `tryLock` and contributes to this file’s behavior.
- Line 95: `void releaseLock(String resource, String userId) {` — Part of the public or internal API; it is named `releaseLock` and contributes to this file’s behavior.
- Line 99: `bool isLocked(String resource, String userId) {` — Part of the public or internal API; it is named `isLocked` and contributes to this file’s behavior.
- Line 105: `void updatePresence(String room, List<dynamic> users) {` — Updates internal state or a derived representation.
- Line 109: `void updateCursor(String room, String userId, double x, double y) {` — Updates internal state or a derived representation.
- Line 114: `void updateAwareness(String room, Map<String, dynamic> data) {` — Updates internal state or a derived representation.
- Line 131: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 193 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 7 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
