# `src/features/charts/quantum_charts.dart`

## What this file is
A feature module under the framework feature set. It usually contains a specialized engine for charts or media processing built on top of the common primitives.

Author-intent note: OMEGA CHART ENGINE (PURE FLUTTER, SIMD OPTIMIZED, ZERO-COPY)

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../../quantum.dart`.
- Flutter framework import: `package:flutter/foundation.dart`.

## Top-level declarations
- Line 11: `enum QLChartType {` — Enumerates the finite states or modes supported by `QLChartType`.
- Line 31: `class QLChartDataBuffer {` — Defines the `QLChartDataBuffer` type and its fields, methods, and lifecycle.
- Line 105: `class QLUniversalChart extends StatefulWidget {` — Defines the `QLUniversalChart` type and its fields, methods, and lifecycle.
- Line 133: `class _QLUniversalChartState extends State<QLUniversalChart>` — Defines the `_QLUniversalChartState` type and its fields, methods, and lifecycle.
- Line 321: `class _QLGridPainter extends CustomPainter {` — Defines the `_QLGridPainter` type and its fields, methods, and lifecycle.
- Line 358: `class _QLCrosshairPainter extends CustomPainter {` — Defines the `_QLCrosshairPainter` type and its fields, methods, and lifecycle.
- Line 388: `class _QLDataPainter extends CustomPainter {` — Defines the `_QLDataPainter` type and its fields, methods, and lifecycle.
- Line 776: `Widget buildChart(QLContext ctx, QLChartType type) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## Important members and helpers
- Line 57: `double safeDouble(dynamic val, double fallback) {` — Part of the public or internal API; it is named `safeDouble` and contributes to this file’s behavior.
- Line 146: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 159: `void didUpdateWidget(covariant QLUniversalChart oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 168: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 175: `void _handleHover(QLPointerEvent e, Size size) {` — Part of the public or internal API; it is named `_handleHover` and contributes to this file’s behavior.
- Line 230: `void _handleExit() {` — Part of the public or internal API; it is named `_handleExit` and contributes to this file’s behavior.
- Line 236: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 326: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 355: `bool shouldRepaint(_QLGridPainter old) => old.color != color;` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.
- Line 364: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 385: `bool shouldRepaint(_QLCrosshairPainter old) => old.pos != pos;` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.
- Line 404: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 425: `double mapX(double val) =>` — Part of the public or internal API; it is named `mapX` and contributes to this file’s behavior.
- Line 428: `double mapY(double val) => rY == 0` — Part of the public or internal API; it is named `mapY` and contributes to this file’s behavior.
- Line 772: `bool shouldRepaint(_QLDataPainter old) =>` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.

## How it works
Feature modules sit on top of the core primitives and provide specialized behavior such as charts, images, or media playback. They often cache decoded data and expose a richer API than the lower layers.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 809 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 15 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
