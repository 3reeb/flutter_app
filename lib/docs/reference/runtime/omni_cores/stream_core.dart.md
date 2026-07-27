# `src/runtime/omni_cores/stream_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

Author-intent note: STREAM CORE — Real-time streaming primitives (WebSocket, SSE, Ring, Ticker)

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 8: `Widget _buildStream(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildStream` and contributes to this file’s behavior.
- Line 60: `class _QLWebSocketNode extends StatefulWidget {` — Defines the `_QLWebSocketNode` type and its fields, methods, and lifecycle.
- Line 67: `class _QLWebSocketNodeState extends State<_QLWebSocketNode> {` — Defines the `_QLWebSocketNodeState` type and its fields, methods, and lifecycle.
- Line 102: `class _QLSSENode extends StatefulWidget {` — Defines the `_QLSSENode` type and its fields, methods, and lifecycle.
- Line 109: `class _QLSSENodeState extends State<_QLSSENode> {` — Defines the `_QLSSENodeState` type and its fields, methods, and lifecycle.
- Line 124: `class _QLTickNode extends StatefulWidget {` — Defines the `_QLTickNode` type and its fields, methods, and lifecycle.
- Line 129: `class _QLTickNodeState extends State<_QLTickNode> {` — Defines the `_QLTickNodeState` type and its fields, methods, and lifecycle.
- Line 139: `class _QLRingBufferNode extends StatefulWidget {` — Defines the `_QLRingBufferNode` type and its fields, methods, and lifecycle.
- Line 144: `class _QLRingBufferNodeState extends State<_QLRingBufferNode> {` — Defines the `_QLRingBufferNodeState` type and its fields, methods, and lifecycle.
- Line 175: `void _registerStreamAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerStreamAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 73: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 79: `void _connect() async {` — Part of the public or internal API; it is named `_connect` and contributes to this file’s behavior.
- Line 93: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 158: `void _onValue() => _push(_sig!.value);` — Part of the public or internal API; it is named `_onValue` and contributes to this file’s behavior.
- Line 160: `void _push(dynamic v) {` — Part of the public or internal API; it is named `_push` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 180 lines in the source file.
- 10 top-level declarations detected by static analysis.
- 5 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
