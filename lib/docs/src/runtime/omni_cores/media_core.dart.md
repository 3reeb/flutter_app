# `src/runtime/omni_cores/media_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

Author-intent note: QUANTUM OMNI REGISTRY — MEDIA ENGINE (PURE RENDER, ZERO-GC)

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 12: `Widget _buildMedia(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildMedia` and contributes to this file’s behavior.
- Line 222: `class _QLAudioPlayerNode extends StatefulWidget {` — Defines the `_QLAudioPlayerNode` type and its fields, methods, and lifecycle.
- Line 239: `class _QLAudioPlayerNodeState extends State<_QLAudioPlayerNode> {` — Defines the `_QLAudioPlayerNodeState` type and its fields, methods, and lifecycle.
- Line 260: `class _QLAudioVisualizerNode extends StatefulWidget {` — Defines the `_QLAudioVisualizerNode` type and its fields, methods, and lifecycle.
- Line 277: `class _QLAudioVisualizerNodeState extends State<_QLAudioVisualizerNode> {` — Defines the `_QLAudioVisualizerNodeState` type and its fields, methods, and lifecycle.
- Line 291: `class _QLCompiledPathNode extends StatefulWidget {` — Defines the `_QLCompiledPathNode` type and its fields, methods, and lifecycle.
- Line 312: `class _QLCompiledPathNodeState extends State<_QLCompiledPathNode> {` — Defines the `_QLCompiledPathNodeState` type and its fields, methods, and lifecycle.
- Line 349: `class _RawPathPainter extends CustomPainter {` — Defines the `_RawPathPainter` type and its fields, methods, and lifecycle.
- Line 387: `void _registerMediaAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerMediaAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 245: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 279: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 316: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 322: `void didUpdateWidget(covariant _QLCompiledPathNode old) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 329: `Path _fastParseSvg(String svg) {` — Part of the public or internal API; it is named `_fastParseSvg` and contributes to this file’s behavior.
- Line 336: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 362: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 376: `bool shouldRepaint(covariant _RawPathPainter old) =>` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 396 lines in the source file.
- 9 top-level declarations detected by static analysis.
- 8 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
