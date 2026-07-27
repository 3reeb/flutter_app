# `src/features/media/quantum_media_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM MEDIA ENGINE v10.0 - OMEGA TIKTOK/NETFLIX PARITY BUILD

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:convert`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Pub package import: `package:video_player/video_player.dart`.
- Internal framework dependency: `../../foundation/quantum_primitives.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.
- Internal framework dependency: `../../../quantum.dart`.
- Internal framework dependency: `../../plugins/quantum_media_api.dart`.

## Top-level declarations
- Line 28: `enum QLStreamFormat { auto, hls, dash, ss, other }` — Enumerates the finite states or modes supported by `QLStreamFormat`.
- Line 31: `class QLMediaPolicy {` — Defines the `QLMediaPolicy` type and its fields, methods, and lifecycle.
- Line 41: `class QLMediaSource {` — Defines the `QLMediaSource` type and its fields, methods, and lifecycle.
- Line 75: `class QLSubtitleTrack {` — Defines the `QLSubtitleTrack` type and its fields, methods, and lifecycle.
- Line 98: `abstract final class QLSubtitleParser {` — Provides a static namespace of constants and helper methods under `QLSubtitleParser`.
- Line 152: `class QLMediaPlaybackController {` — Defines the `QLMediaPlaybackController` type and its fields, methods, and lifecycle.
- Line 356: `class QuantumMediaOrchestrator {` — Defines the `QuantumMediaOrchestrator` type and its fields, methods, and lifecycle.
- Line 420: `class QLVideoLifecycleWrapper extends StatefulWidget {` — Defines the `QLVideoLifecycleWrapper` type and its fields, methods, and lifecycle.
- Line 445: `class _QLVideoLifecycleWrapperState extends State<QLVideoLifecycleWrapper> {` — Defines the `_QLVideoLifecycleWrapperState` type and its fields, methods, and lifecycle.
- Line 534: `class QLVideoSurface extends StatelessWidget {` — Defines the `QLVideoSurface` type and its fields, methods, and lifecycle.
- Line 572: `class QLSubtitleOverlay extends StatelessWidget {` — Defines the `QLSubtitleOverlay` type and its fields, methods, and lifecycle.
- Line 611: `void registerQuantumMediaComponents(QuantumVM vm) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 672: `class _QLFeedDisposer extends StatefulWidget {` — Defines the `_QLFeedDisposer` type and its fields, methods, and lifecycle.
- Line 680: `class _QLFeedDisposerState extends State<_QLFeedDisposer> {` — Defines the `_QLFeedDisposerState` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 186: `Future<void> initialize({bool playOnReady = false}) async {` — Initializes internal state and prepares the object for use.
- Line 264: `void _onHardwareUpdate() {` — Part of the public or internal API; it is named `_onHardwareUpdate` and contributes to this file’s behavior.
- Line 294: `void _startSyncWatchdog() {` — Part of the public or internal API; it is named `_startSyncWatchdog` and contributes to this file’s behavior.
- Line 309: `Future<void> play() async {` — Starts playback or execution.
- Line 320: `Future<void> pause() async {` — Pauses playback or execution.
- Line 330: `Future<void> seek(Duration time) async {` — Jumps to a specific time or offset.
- Line 338: `void setVolume(double v) {` — Part of the public or internal API; it is named `setVolume` and contributes to this file’s behavior.
- Line 344: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 367: `void onIndexChanged(int newIndex) {` — Event handler or lifecycle callback.
- Line 381: `void _runGarbageCollectionAndPrefetch() {` — Part of the public or internal API; it is named `_runGarbageCollectionAndPrefetch` and contributes to this file’s behavior.
- Line 410: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 450: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 456: `Future<void> _initializeSafe() async {` — Part of the public or internal API; it is named `_initializeSafe` and contributes to this file’s behavior.
- Line 469: `void didUpdateWidget(covariant QLVideoLifecycleWrapper oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 479: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 485: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 546: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 577: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 682: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 688: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `video_player`, so playback state and buffering behavior are delegated to Flutter’s media plugin stack.

## File size
- 689 lines in the source file.
- 14 top-level declarations detected by static analysis.
- 20 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
