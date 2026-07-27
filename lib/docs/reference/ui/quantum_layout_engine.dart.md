# `src/ui/quantum_layout_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM LAYOUT ENGINE (QLE) v14.0 — HIGH-PERFORMANCE VIRTUALIZED DOM

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Flutter framework import: `package:flutter/widgets.dart`.
- Internal framework dependency: `../foundation/quantum_core.dart`.
- Internal framework dependency: `../foundation/quantum_primitives.dart`.

## Top-level declarations
- Line 31: `enum QLayoutType { grid, masonry, row, col, wrap, stack, split, morph, none }` — Enumerates the finite states or modes supported by `QLayoutType`.
- Line 33: `enum QFlowDirection { row, column, rowDense, columnDense, masonry }` — Enumerates the finite states or modes supported by `QFlowDirection`.
- Line 35: `enum QAlign { start, center, end, stretch, baseline }` — Enumerates the finite states or modes supported by `QAlign`.
- Line 37: `enum QJustify { start, center, end, stretch, spaceBetween, spaceAround }` — Enumerates the finite states or modes supported by `QJustify`.
- Line 45: `class QuantumLayoutScope extends InheritedWidget {` — Defines the `QuantumLayoutScope` type and its fields, methods, and lifecycle.
- Line 66: `class QuantumScrollScope extends InheritedWidget {` — Defines the `QuantumScrollScope` type and its fields, methods, and lifecycle.
- Line 88: `class QuantumLayout extends StatelessWidget {` — Defines the `QuantumLayout` type and its fields, methods, and lifecycle.
- Line 178: `class QuantumGrid extends MultiChildRenderObjectWidget {` — Defines the `QuantumGrid` type and its fields, methods, and lifecycle.
- Line 236: `class QuantumParentData extends ContainerBoxParentData<RenderBox> {` — Defines the `QuantumParentData` type and its fields, methods, and lifecycle.
- Line 250: `class QuantumItem extends ParentDataWidget<QuantumParentData> {` — Defines the `QuantumItem` type and its fields, methods, and lifecycle.
- Line 315: `class RenderQuantumGrid extends RenderBox` — Defines the `RenderQuantumGrid` type and its fields, methods, and lifecycle.
- Line 1092: `class QuantumFlex extends StatelessWidget {` — Defines the `QuantumFlex` type and its fields, methods, and lifecycle.
- Line 1143: `class QuantumSplitPane extends StatefulWidget {` — Defines the `QuantumSplitPane` type and its fields, methods, and lifecycle.
- Line 1163: `class _QuantumSplitPaneState extends State<QuantumSplitPane> {` — Defines the `_QuantumSplitPaneState` type and its fields, methods, and lifecycle.
- Line 1289: `class QuantumMorphSurface extends StatefulWidget {` — Defines the `QuantumMorphSurface` type and its fields, methods, and lifecycle.
- Line 1307: `class _QuantumMorphSurfaceState extends State<QuantumMorphSurface> {` — Defines the `_QuantumMorphSurfaceState` type and its fields, methods, and lifecycle.
- Line 1376: `class _QuantumFlexibleResolution {` — Defines the `_QuantumFlexibleResolution` type and its fields, methods, and lifecycle.
- Line 1388: `class QuantumFlexible extends StatelessWidget {` — Defines the `QuantumFlexible` type and its fields, methods, and lifecycle.
- …and 5 more top-level declarations.

## Important members and helpers
- Line 59: `bool updateShouldNotify(QuantumLayoutScope oldWidget) {` — Updates internal state or a derived representation.
- Line 80: `bool updateShouldNotify(QuantumScrollScope oldWidget) =>` — Updates internal state or a derived representation.
- Line 119: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 126: `Widget _buildEngine() {` — Part of the public or internal API; it is named `_buildEngine` and contributes to this file’s behavior.
- Line 204: `RenderQuantumGrid createRenderObject(BuildContext context) {` — Factory entry point that constructs and returns the platform- or configuration-specific implementation.
- Line 220: `void updateRenderObject(` — Updates internal state or a derived representation.
- Line 277: `void applyParentData(RenderObject renderObject) {` — Part of the public or internal API; it is named `applyParentData` and contributes to this file’s behavior.
- Line 282: `void setIfChanged<T>(T current, T next, void Function(T) setter) {` — Part of the public or internal API; it is named `setIfChanged<T>` and contributes to this file’s behavior.
- Line 437: `void markZOrderDirty() {` — Part of the public or internal API; it is named `markZOrderDirty` and contributes to this file’s behavior.
- Line 443: `void setupParentData(RenderBox child) {` — Part of the public or internal API; it is named `setupParentData` and contributes to this file’s behavior.
- Line 450: `int _clampInt(int value, int minValue, int maxValue) {` — Part of the public or internal API; it is named `_clampInt` and contributes to this file’s behavior.
- Line 457: `double _finiteOrZero(double v) => QLSafe.finite(v, 0.0);` — Part of the public or internal API; it is named `_finiteOrZero` and contributes to this file’s behavior.
- Line 459: `void _ensureBitmask(int rows, int cols) {` — Part of the public or internal API; it is named `_ensureBitmask` and contributes to this file’s behavior.
- Line 479: `void _occupy(int r, int c, int rSpan, int cSpan) {` — Part of the public or internal API; it is named `_occupy` and contributes to this file’s behavior.
- Line 504: `void _ensureRegisters(int reqCols, int reqRows) {` — Part of the public or internal API; it is named `_ensureRegisters` and contributes to this file’s behavior.
- Line 522: `void _cacheChildren() {` — Part of the public or internal API; it is named `_cacheChildren` and contributes to this file’s behavior.
- Line 536: `void performLayout() {` — Part of the public or internal API; it is named `performLayout` and contributes to this file’s behavior.
- Line 578: `void paint(PaintingContext context, Offset offset) {` — Paints the object onto a canvas or render surface.
- Line 593: `bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {` — Part of the public or internal API; it is named `hitTestChildren` and contributes to this file’s behavior.
- Line 1079: `double computeMinIntrinsicWidth(double height) => 0.0;` — Part of the public or internal API; it is named `computeMinIntrinsicWidth` and contributes to this file’s behavior.
- Line 1081: `double computeMaxIntrinsicWidth(double height) => 0.0;` — Part of the public or internal API; it is named `computeMaxIntrinsicWidth` and contributes to this file’s behavior.
- Line 1083: `double computeMinIntrinsicHeight(double width) => 0.0;` — Part of the public or internal API; it is named `computeMinIntrinsicHeight` and contributes to this file’s behavior.
- Line 1085: `double computeMaxIntrinsicHeight(double width) => 0.0;` — Part of the public or internal API; it is named `computeMaxIntrinsicHeight` and contributes to this file’s behavior.
- Line 1127: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- …and 34 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 1827 lines in the source file.
- 23 top-level declarations detected by static analysis.
- 58 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
