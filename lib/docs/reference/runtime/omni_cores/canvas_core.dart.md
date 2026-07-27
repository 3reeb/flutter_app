# `src/runtime/omni_cores/canvas_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 5: `Widget _buildCanvas(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildCanvas` and contributes to this file’s behavior.
- Line 94: `class _QLVertexPlotPainter extends CustomPainter {` — Defines the `_QLVertexPlotPainter` type and its fields, methods, and lifecycle.
- Line 169: `class _QLProceduralCanvasNode extends StatefulWidget {` — Defines the `_QLProceduralCanvasNode` type and its fields, methods, and lifecycle.
- Line 178: `class _QLProceduralCanvasNodeState extends State<_QLProceduralCanvasNode> {` — Defines the `_QLProceduralCanvasNodeState` type and its fields, methods, and lifecycle.
- Line 246: `class _QLProceduralPainter extends CustomPainter {` — Defines the `_QLProceduralPainter` type and its fields, methods, and lifecycle.
- Line 279: `void _registerCanvasAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerCanvasAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 116: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 165: `bool shouldRepaint(covariant _QLVertexPlotPainter old) => true;` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.
- Line 183: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 189: `void didUpdateWidget(covariant _QLProceduralCanvasNode old) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 194: `void _compile() {` — Part of the public or internal API; it is named `_compile` and contributes to this file’s behavior.
- Line 214: `double _n(dynamic v) {` — Part of the public or internal API; it is named `_n` and contributes to this file’s behavior.
- Line 237: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 252: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 275: `bool shouldRepaint(covariant _QLProceduralPainter old) =>` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 282 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 9 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
