# `src/features/media/quantum_image_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM IMAGE ENGINE v10.0 - OMEGA CDN OPTIMIZER & DISK CACHE BRIDGE

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Internal framework dependency: `../../foundation/quantum_primitives.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.
- Internal framework dependency: `../../plugins/quantum_media_api.dart`.

## Top-level declarations
- Line 23: `abstract class QLImageResolver {` — Defines the abstract `QLImageResolver` contract used by implementations elsewhere in the framework.
- Line 28: `class QLDefaultCdnResolver extends QLImageResolver {` — Defines the `QLDefaultCdnResolver` type and its fields, methods, and lifecycle.
- Line 52: `class QuantumImagePipeline {` — Defines the `QuantumImagePipeline` type and its fields, methods, and lifecycle.
- Line 251: `class QLImage extends StatefulWidget {` — Defines the `QLImage` type and its fields, methods, and lifecycle.
- Line 275: `class _QLImageState extends State<QLImage> with SingleTickerProviderStateMixin {` — Defines the `_QLImageState` type and its fields, methods, and lifecycle.
- Line 368: `class _QLHardwareImagePainter extends CustomPainter {` — Defines the `_QLHardwareImagePainter` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 24: `String rewrite(String url, int width, int height, int quality);` — Part of the public or internal API; it is named `rewrite` and contributes to this file’s behavior.
- Line 25: `Future<Map<String, Uint8List>> fetchBatch(List<String> urls) async => {};` — Fetches data from the configured source, often over the network or from a cache.
- Line 33: `String rewrite(String url, int width, int height, int quality) {` — Part of the public or internal API; it is named `rewrite` and contributes to this file’s behavior.
- Line 113: `Future<Uint8List?> _fetchResolverBytes(String url) async {` — Part of the public or internal API; it is named `_fetchResolverBytes` and contributes to this file’s behavior.
- Line 124: `Future<Uint8List> _fetchBytes(String url) async {` — Part of the public or internal API; it is named `_fetchBytes` and contributes to this file’s behavior.
- Line 215: `Future<ui.Image> _zeroCopyDecode(Uint8List bytes) async {` — Part of the public or internal API; it is named `_zeroCopyDecode` and contributes to this file’s behavior.
- Line 222: `void _cacheImage(String key, ui.Image image) {` — Part of the public or internal API; it is named `_cacheImage` and contributes to this file’s behavior.
- Line 230: `void _markUsed(String key) {` — Part of the public or internal API; it is named `_markUsed` and contributes to this file’s behavior.
- Line 235: `void _evictIfNeeded() {` — Part of the public or internal API; it is named `_evictIfNeeded` and contributes to this file’s behavior.
- Line 283: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 290: `void _decodePlaceholder() async {` — Part of the public or internal API; it is named `_decodePlaceholder` and contributes to this file’s behavior.
- Line 300: `void _requestImage(double width, double height) {` — Part of the public or internal API; it is named `_requestImage` and contributes to this file’s behavior.
- Line 317: `void _onImageUpdate() {` — Part of the public or internal API; it is named `_onImageUpdate` and contributes to this file’s behavior.
- Line 325: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 333: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 384: `void paint(Canvas canvas, Size size) {` — Paints the object onto a canvas or render surface.
- Line 405: `void _paintImageNative(` — Part of the public or internal API; it is named `_paintImageNative` and contributes to this file’s behavior.
- Line 419: `bool shouldRepaint(_QLHardwareImagePainter old) =>` — Part of the public or internal API; it is named `shouldRepaint` and contributes to this file’s behavior.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 423 lines in the source file.
- 6 top-level declarations detected by static analysis.
- 18 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
