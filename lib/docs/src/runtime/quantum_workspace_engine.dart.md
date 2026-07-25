# `src/runtime/quantum_workspace_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM WORKSPACE ENGINE v3.0 - UNCOMPROMISED GPU RENDERER

## Dependencies
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Internal framework dependency: `../foundation/quantum_primitives.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 14: `abstract final class QLSpaceFlags {` — Provides a static namespace of constants and helper methods under `QLSpaceFlags`.
- Line 24: `class QLWorkspaceController {` — Defines the `QLWorkspaceController` type and its fields, methods, and lifecycle.
- Line 64: `class QLWorkspace extends MultiChildRenderObjectWidget {` — Defines the `QLWorkspace` type and its fields, methods, and lifecycle.
- Line 96: `class QLSpaceParentData extends ContainerBoxParentData<RenderBox> {` — Defines the `QLSpaceParentData` type and its fields, methods, and lifecycle.
- Line 100: `class QLSpaceParentDataWidget extends ParentDataWidget<QLSpaceParentData> {` — Defines the `QLSpaceParentDataWidget` type and its fields, methods, and lifecycle.
- Line 121: `class RenderQuantumWorkspace extends RenderBox` — Defines the `RenderQuantumWorkspace` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 33: `void loadMemory(` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 41: `void pan(double dx, double dy) {` — Part of the public or internal API; it is named `pan` and contributes to this file’s behavior.
- Line 47: `void zoom(double delta) {` — Part of the public or internal API; it is named `zoom` and contributes to this file’s behavior.
- Line 53: `void hideNode(int index, bool hidden) {` — Part of the public or internal API; it is named `hideNode` and contributes to this file’s behavior.
- Line 83: `RenderQuantumWorkspace createRenderObject(BuildContext context) {` — Factory entry point that constructs and returns the platform- or configuration-specific implementation.
- Line 88: `void updateRenderObject(` — Updates internal state or a derived representation.
- Line 106: `void applyParentData(RenderObject renderObject) {` — Part of the public or internal API; it is named `applyParentData` and contributes to this file’s behavior.
- Line 158: `void setupParentData(covariant RenderObject child) {` — Part of the public or internal API; it is named `setupParentData` and contributes to this file’s behavior.
- Line 164: `void performLayout() {` — Part of the public or internal API; it is named `performLayout` and contributes to this file’s behavior.
- Line 227: `void paint(PaintingContext context, Offset offset) {` — Paints the object onto a canvas or render surface.
- Line 267: `void handleEvent(PointerEvent event, BoxHitTestEntry entry) {` — Part of the public or internal API; it is named `handleEvent` and contributes to this file’s behavior.
- Line 317: `bool hitTest(BoxHitTestResult result, {required Offset position}) {` — Part of the public or internal API; it is named `hitTest` and contributes to this file’s behavior.
- Line 327: `bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {` — Part of the public or internal API; it is named `hitTestChildren` and contributes to this file’s behavior.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 358 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 13 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
