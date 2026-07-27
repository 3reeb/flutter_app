# `src/ui/quantum_shape_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

## Dependencies
- Core Dart library: `dart:math`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.

## Top-level declarations
- Line 7: `enum QShapeType { rect, rrect, circle, pill, polygon }` — Enumerates the finite states or modes supported by `QShapeType`.
- Line 9: `enum QBooleanOp { union, subtract, intersect, exclude }` — Enumerates the finite states or modes supported by `QBooleanOp`.
- Line 13: `class QShapeValue {` — Defines the `QShapeValue` type and its fields, methods, and lifecycle.
- Line 57: `class QShapePoint {` — Defines the `QShapePoint` type and its fields, methods, and lifecycle.
- Line 95: `class QShapePrimitive {` — Defines the `QShapePrimitive` type and its fields, methods, and lifecycle.
- Line 161: `class QBooleanShapeOp {` — Defines the `QBooleanShapeOp` type and its fields, methods, and lifecycle.
- Line 191: `class QBooleanShapeDef {` — Defines the `QBooleanShapeDef` type and its fields, methods, and lifecycle.
- Line 240: `class QLShapeNode extends SingleChildRenderObjectWidget {` — Defines the `QLShapeNode` type and its fields, methods, and lifecycle.
- Line 287: `class RenderQLShape extends RenderProxyBox {` — Defines the `RenderQLShape` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 20: `double resolve(double maxSpace, {double fallback = 0.0}) {` — Resolves an abstract value into a concrete runtime value or path.
- Line 63: `Offset resolve(Size size) {` — Resolves an abstract value into a concrete runtime value or path.
- Line 217: `void addLegacy(String key, QBooleanOp op) {` — Adds a child item, event, route, or data chunk to the current collection.
- Line 262: `RenderQLShape createRenderObject(BuildContext context) {` — Factory entry point that constructs and returns the platform- or configuration-specific implementation.
- Line 275: `void updateRenderObject(BuildContext context, RenderQLShape renderObject) {` — Updates internal state or a derived representation.
- Line 325: `void attach(PipelineOwner owner) {` — Part of the public or internal API; it is named `attach` and contributes to this file’s behavior.
- Line 331: `void detach() {` — Part of the public or internal API; it is named `detach` and contributes to this file’s behavior.
- Line 382: `void _onRepaintTick() {` — Part of the public or internal API; it is named `_onRepaintTick` and contributes to this file’s behavior.
- Line 387: `double _resolve(dynamic value, double maxSpace, {double fallback = 0.0}) {` — Part of the public or internal API; it is named `_resolve` and contributes to this file’s behavior.
- Line 398: `Rect _buildRect(QShapePrimitive p, Size size) {` — Part of the public or internal API; it is named `_buildRect` and contributes to this file’s behavior.
- Line 411: `void _buildPrimitive(Path targetPath, QShapePrimitive p, Size size) {` — Part of the public or internal API; it is named `_buildPrimitive` and contributes to this file’s behavior.
- Line 471: `void _compilePath(Size size) {` — Part of the public or internal API; it is named `_compilePath` and contributes to this file’s behavior.
- Line 511: `void performLayout() {` — Part of the public or internal API; it is named `performLayout` and contributes to this file’s behavior.
- Line 528: `void paint(PaintingContext context, Offset offset) {` — Paints the object onto a canvas or render surface.
- Line 584: `bool hitTest(BoxHitTestResult result, {required Offset position}) {` — Part of the public or internal API; it is named `hitTest` and contributes to this file’s behavior.
- Line 602: `bool hitTestSelf(Offset position) => _compiledPath.contains(position);` — Part of the public or internal API; it is named `hitTestSelf` and contributes to this file’s behavior.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 603 lines in the source file.
- 9 top-level declarations detected by static analysis.
- 16 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
