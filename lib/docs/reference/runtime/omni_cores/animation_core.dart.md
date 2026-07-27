# `src/runtime/omni_cores/animation_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 3: `Widget _buildAnimation(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildAnimation` and contributes to this file’s behavior.
- Line 198: `void _registerAnimationAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerAnimationAliases` and contributes to this file’s behavior.
- Line 245: `class _QLStaggerNode extends StatefulWidget {` — Defines the `_QLStaggerNode` type and its fields, methods, and lifecycle.
- Line 259: `class _QLStaggerNodeState extends State<_QLStaggerNode>` — Defines the `_QLStaggerNodeState` type and its fields, methods, and lifecycle.
- Line 298: `class _QLSkeletonWidget extends StatefulWidget {` — Defines the `_QLSkeletonWidget` type and its fields, methods, and lifecycle.
- Line 306: `class _QLSkeletonWidgetState extends State<_QLSkeletonWidget>` — Defines the `_QLSkeletonWidgetState` type and its fields, methods, and lifecycle.
- Line 348: `class _QLKeyframeNode extends StatefulWidget {` — Defines the `_QLKeyframeNode` type and its fields, methods, and lifecycle.
- Line 363: `class _QLKeyframeNodeState extends State<_QLKeyframeNode>` — Defines the `_QLKeyframeNodeState` type and its fields, methods, and lifecycle.
- Line 404: `class _QLSequenceNode extends StatefulWidget {` — Defines the `_QLSequenceNode` type and its fields, methods, and lifecycle.
- Line 412: `class _QLSequenceNodeState extends State<_QLSequenceNode>` — Defines the `_QLSequenceNodeState` type and its fields, methods, and lifecycle.
- Line 447: `class _QLParticleNode extends StatefulWidget {` — Defines the `_QLParticleNode` type and its fields, methods, and lifecycle.
- Line 457: `class _QLParticleNodeState extends State<_QLParticleNode>` — Defines the `_QLParticleNodeState` type and its fields, methods, and lifecycle.
- Line 492: `class _ParticlePainter extends CustomPainter {` — Defines the `_ParticlePainter` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 263: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 275: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 281: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 310: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 318: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 324: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 367: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 373: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 379: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 417: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 437: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 443: `Widget build(BuildContext context) =>` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 462: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 472: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 478: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 498: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 511: `bool shouldRepaint(covariant _ParticlePainter old) =>` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 513 lines in the source file.
- 13 top-level declarations detected by static analysis.
- 17 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
