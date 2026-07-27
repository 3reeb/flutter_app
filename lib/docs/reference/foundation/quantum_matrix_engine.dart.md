# `src/foundation/quantum_matrix_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: - Accessibility semantics with logical vs visual ordering

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `quantum_primitives.dart`.
- Internal framework dependency: `../ui/quantum_layout_engine.dart`.

## Top-level declarations
- Line 35: `enum QMatrixSemanticsOrder {` — Enumerates the finite states or modes supported by `QMatrixSemanticsOrder`.
- Line 41: `enum QMatrixTextDirectionMode {` — Enumerates the finite states or modes supported by `QMatrixTextDirectionMode`.
- Line 47: `enum QMatrixInteractionMode {` — Enumerates the finite states or modes supported by `QMatrixInteractionMode`.
- Line 54: `enum QMatrixResizeHandle {` — Enumerates the finite states or modes supported by `QMatrixResizeHandle`.
- Line 66: `class QMatrixInteractionController extends ChangeNotifier {` — Defines the `QMatrixInteractionController` type and its fields, methods, and lifecycle.
- Line 172: `class QMatrixSlotRuntimeOverride {` — Defines the `QMatrixSlotRuntimeOverride` type and its fields, methods, and lifecycle.
- Line 264: `class QMatrixSlotDef {` — Defines the `QMatrixSlotDef` type and its fields, methods, and lifecycle.
- Line 322: `class _CompiledSlot {` — Defines the `_CompiledSlot` type and its fields, methods, and lifecycle.
- Line 366: `class _CompiledMatrixData {` — Defines the `_CompiledMatrixData` type and its fields, methods, and lifecycle.
- Line 422: `class QMatrixLayoutDef {` — Defines the `QMatrixLayoutDef` type and its fields, methods, and lifecycle.
- Line 444: `abstract final class QMatrixLayoutRegistry {` — Provides a static namespace of constants and helper methods under `QMatrixLayoutRegistry`.
- Line 606: `class QMatrixBuilder {` — Defines the `QMatrixBuilder` type and its fields, methods, and lifecycle.
- Line 796: `class QuantumMatrixParentData extends ContainerBoxParentData<RenderBox> {` — Defines the `QuantumMatrixParentData` type and its fields, methods, and lifecycle.
- Line 828: `class QuantumMatrixNode extends MultiChildRenderObjectWidget {` — Defines the `QuantumMatrixNode` type and its fields, methods, and lifecycle.
- Line 890: `class RenderQuantumMatrix extends RenderBox` — Defines the `RenderQuantumMatrix` type and its fields, methods, and lifecycle.
- Line 1646: `class _PaintEntry {` — Defines the `_PaintEntry` type and its fields, methods, and lifecycle.
- Line 1656: `Map<String, dynamic> _asStringKeyedMap(dynamic raw) {` — Part of the public or internal API; it is named `_asStringKeyedMap` and contributes to this file’s behavior.
- Line 1664: `Map<String, QMatrixSlotRuntimeOverride> _parseMatrixSlotOverrides(dynamic raw) {` — Part of the public or internal API; it is named `_parseMatrixSlotOverrides` and contributes to this file’s behavior.
- …and 9 more top-level declarations.

## Important members and helpers
- Line 80: `void setVisualOrder(List<String>? order) {` — Part of the public or internal API; it is named `setVisualOrder` and contributes to this file’s behavior.
- Line 85: `void bringToFront(String slotName) {` — Part of the public or internal API; it is named `bringToFront` and contributes to this file’s behavior.
- Line 93: `void sendToBack(String slotName) {` — Part of the public or internal API; it is named `sendToBack` and contributes to this file’s behavior.
- Line 101: `void setGridPlacement(` — Part of the public or internal API; it is named `setGridPlacement` and contributes to this file’s behavior.
- Line 121: `void setPixelOffset(String slotName, Offset offset) {` — Part of the public or internal API; it is named `setPixelOffset` and contributes to this file’s behavior.
- Line 130: `void setPixelSize(String slotName, Size size) {` — Part of the public or internal API; it is named `setPixelSize` and contributes to this file’s behavior.
- Line 139: `void setZIndex(String slotName, int zIndex) {` — Part of the public or internal API; it is named `setZIndex` and contributes to this file’s behavior.
- Line 148: `void setHidden(String slotName, bool hidden) {` — Part of the public or internal API; it is named `setHidden` and contributes to this file’s behavior.
- Line 157: `void clearSlot(String slotName) {` — Part of the public or internal API; it is named `clearSlot` and contributes to this file’s behavior.
- Line 163: `void clearAll() {` — Part of the public or internal API; it is named `clearAll` and contributes to this file’s behavior.
- Line 222: `Map<String, dynamic> toJson() => <String, dynamic>{` — Converts the object into another representation.
- Line 241: `QMatrixSlotRuntimeOverride copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 295: `Map<String, dynamic> toJson() => {` — Converts the object into another representation.
- Line 614: `void matrix(String asciiGrid) => _defaultGrid = asciiGrid;` — Part of the public or internal API; it is named `matrix` and contributes to this file’s behavior.
- Line 616: `void breakpoint(String name, String asciiGrid) =>` — Part of the public or internal API; it is named `breakpoint` and contributes to this file’s behavior.
- Line 619: `void variant(String name, String asciiGrid) {` — Part of the public or internal API; it is named `variant` and contributes to this file’s behavior.
- Line 624: `void variantBreakpoint(String name, String breakpoint, String asciiGrid) {` — Part of the public or internal API; it is named `variantBreakpoint` and contributes to this file’s behavior.
- Line 629: `void slot(` — Part of the public or internal API; it is named `slot` and contributes to this file’s behavior.
- Line 764: `QMatrixLayoutDef buildDef() {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 856: `RenderQuantumMatrix createRenderObject(BuildContext context) {` — Factory entry point that constructs and returns the platform- or configuration-specific implementation.
- Line 871: `void updateRenderObject(` — Updates internal state or a derived representation.
- Line 1015: `void attach(PipelineOwner owner) {` — Part of the public or internal API; it is named `attach` and contributes to this file’s behavior.
- Line 1023: `void detach() {` — Part of the public or internal API; it is named `detach` and contributes to this file’s behavior.
- Line 1032: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- …and 31 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 2460 lines in the source file.
- 27 top-level declarations detected by static analysis.
- 55 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
