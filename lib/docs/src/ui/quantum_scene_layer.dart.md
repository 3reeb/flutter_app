# `src/ui/quantum_scene_layer.dart`

## What this file is
A UI-layer implementation file. It owns widget composition, layout, interactions, theming, telemetry, overlays, hydration, or other Flutter-facing behavior.

Author-intent note: QUANTUM SCENE LAYER v1.0 - RETAINED-MODE 2D/3D DRAW ENGINE

## Dependencies
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Internal framework dependency: `../foundation/quantum_primitives.dart`.

## Top-level declarations
- Line 48: `typedef QLFragmentDraw = void Function(Canvas canvas, Size size);` — Declares the `QLFragmentDraw` type alias so callback signatures stay readable and consistent.
- Line 54: `class _DirtyBitfield {` — Defines the `_DirtyBitfield` type and its fields, methods, and lifecycle.
- Line 110: `class _QLFragment {` — Defines the `_QLFragment` type and its fields, methods, and lifecycle.
- Line 133: `class QLSceneLayer extends ChangeNotifier {` — Defines the `QLSceneLayer` type and its fields, methods, and lifecycle.
- Line 273: `class QLScenePainter extends CustomPainter {` — Defines the `QLScenePainter` type and its fields, methods, and lifecycle.
- Line 301: `class QLSceneLayerWidget extends StatefulWidget {` — Defines the `QLSceneLayerWidget` type and its fields, methods, and lifecycle.
- Line 319: `class _QLSceneLayerWidgetState extends State<QLSceneLayerWidget> {` — Defines the `_QLSceneLayerWidgetState` type and its fields, methods, and lifecycle.
- Line 363: `class QLSoASceneBridge {` — Defines the `QLSoASceneBridge` type and its fields, methods, and lifecycle.
- Line 409: `class QLSceneStack extends StatefulWidget {` — Defines the `QLSceneStack` type and its fields, methods, and lifecycle.
- Line 425: `class _QLSceneStackState extends State<QLSceneStack> {` — Defines the `_QLSceneStackState` type and its fields, methods, and lifecycle.
- Line 480: `class QLChartLayer {` — Defines the `QLChartLayer` type and its fields, methods, and lifecycle.
- Line 526: `class QLChartLayerWidget extends StatefulWidget {` — Defines the `QLChartLayerWidget` type and its fields, methods, and lifecycle.
- Line 540: `class _QLChartLayerWidgetState extends State<QLChartLayerWidget> {` — Defines the `_QLChartLayerWidgetState` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 64: `void mark(int id) {` — Part of the public or internal API; it is named `mark` and contributes to this file’s behavior.
- Line 71: `bool isSet(int id) {` — Part of the public or internal API; it is named `isSet` and contributes to this file’s behavior.
- Line 78: `void clear(int id) {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 93: `void clearAll() {` — Part of the public or internal API; it is named `clearAll` and contributes to this file’s behavior.
- Line 97: `void _ensureCapacity(int wordIndex) {` — Part of the public or internal API; it is named `_ensureCapacity` and contributes to this file’s behavior.
- Line 149: `void update(int id, QLFragmentDraw draw, {int zLevel = 0}) {` — Updates internal state or a derived representation.
- Line 167: `void invalidate(int id) {` — Part of the public or internal API; it is named `invalidate` and contributes to this file’s behavior.
- Line 174: `void invalidateAll() {` — Part of the public or internal API; it is named `invalidateAll` and contributes to this file’s behavior.
- Line 180: `void remove(int id) {` — Removes a previously registered item or association.
- Line 190: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 209: `void _paint(Canvas canvas, Size size) {` — Part of the public or internal API; it is named `_paint` and contributes to this file’s behavior.
- Line 259: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 279: `void paint(Canvas canvas, Size size) => layer._paint(canvas, size);` — Paints the object onto a canvas or render surface.
- Line 282: `bool shouldRepaint(QLScenePainter old) =>` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.
- Line 287: `bool shouldRebuildSemantics(QLScenePainter old) => false;` — Part of the public or internal API; it is named `shouldRebuildSemantics` and contributes to this file’s behavior.
- Line 324: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 331: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 337: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 378: `void syncEntity(int entityId, {int zLevel = 0}) {` — Part of the public or internal API; it is named `syncEntity` and contributes to this file’s behavior.
- Line 387: `void syncAll({int Function(int entity)? zLevelFn}) {` — Part of the public or internal API; it is named `syncAll` and contributes to this file’s behavior.
- Line 394: `void destroyEntity(int entityId) {` — Part of the public or internal API; it is named `destroyEntity` and contributes to this file’s behavior.
- Line 430: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 436: `void didChangeDependencies() {` — Part of the public or internal API; it is named `didChangeDependencies` and contributes to this file’s behavior.
- Line 447: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- …and 11 more member declarations or helpers.

## How it works
The UI layer is where the framework becomes Flutter widgets, render objects, animations, overlays, and input handling. These modules tend to connect signals and controllers to visible behavior.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 590 lines in the source file.
- 13 top-level declarations detected by static analysis.
- 35 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
