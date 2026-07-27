# `src/ui/quantum_animation_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM ANIMATION ENGINE v2.0 — OMEGA TIMELINE + iOS SPRING CORE

## Dependencies
- Core Dart library: `dart:math`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 41: `typedef QLLerp<T> = T Function(T a, T b, double t);` — Declares the `QLLerp` type alias so callback signatures stay readable and consistent.
- Line 45: `abstract final class QLLerps {` — Provides a static namespace of constants and helper methods under `QLLerps`.
- Line 117: `Float32List _getLUT(Curve curve) {` — Part of the public or internal API; it is named `_getLUT` and contributes to this file’s behavior.
- Line 129: `double _evalLUT(Float32List lut, double t) {` — Part of the public or internal API; it is named `_evalLUT` and contributes to this file’s behavior.
- Line 146: `class QLSpringCurve extends Curve {` — Defines the `QLSpringCurve` type and its fields, methods, and lifecycle.
- Line 209: `abstract final class QLSprings {` — Provides a static namespace of constants and helper methods under `QLSprings`.
- Line 233: `class QLKeyframe<T> {` — Defines the `QLKeyframe<T>` type and its fields, methods, and lifecycle.
- Line 244: `class QLTimeline {` — Defines the `QLTimeline` type and its fields, methods, and lifecycle.
- Line 606: `T _evalKf<T>(List<QLKeyframe<T>> kfs, double t) {` — Part of the public or internal API; it is named `_evalKf<T>` and contributes to this file’s behavior.
- Line 625: `void _noopEval(double t) {}` — Part of the public or internal API; it is named `_noopEval` and contributes to this file’s behavior.
- Line 645: `mixin QLTimelineMixin<T extends StatefulWidget> on State<T>, TickerProvider {` — Part of the public or internal API; it is named `TickerProvider` and contributes to this file’s behavior.
- Line 677: `class QLAnimatedWidget<T> extends StatelessWidget {` — Defines the `QLAnimatedWidget<T>` type and its fields, methods, and lifecycle.
- Line 705: `class QLGlassConfig {` — Defines the `QLGlassConfig` type and its fields, methods, and lifecycle.
- Line 732: `abstract final class QLGlassPresets {` — Provides a static namespace of constants and helper methods under `QLGlassPresets`.
- Line 765: `class QLGlassLayer extends StatelessWidget {` — Defines the `QLGlassLayer` type and its fields, methods, and lifecycle.
- Line 846: `class QLBehaviorAnimator {` — Defines the `QLBehaviorAnimator` type and its fields, methods, and lifecycle.
- Line 965: `class QLTransitionPreset {` — Defines the `QLTransitionPreset` type and its fields, methods, and lifecycle.
- Line 983: `abstract final class QLTransitionPresets {` — Provides a static namespace of constants and helper methods under `QLTransitionPresets`.
- …and 7 more top-level declarations.

## Important members and helpers
- Line 204: `double transformInternal(double t) =>` — Part of the public or internal API; it is named `transformInternal` and contributes to this file’s behavior.
- Line 280: `void _ensureCap(int req) {` — Part of the public or internal API; it is named `_ensureCap` and contributes to this file’s behavior.
- Line 316: `int _alloc(String id) {` — Part of the public or internal API; it is named `_alloc` and contributes to this file’s behavior.
- Line 324: `void _calcDuration() {` — Part of the public or internal API; it is named `_calcDuration` and contributes to this file’s behavior.
- Line 402: `void updateSpringTarget(String id, double target) {` — Updates internal state or a derived representation.
- Line 409: `void setSpringPosition(String id, double pos) {` — Part of the public or internal API; it is named `setSpringPosition` and contributes to this file’s behavior.
- Line 435: `void parallel(List<String> ids, {Duration startAt = Duration.zero}) {` — Part of the public or internal API; it is named `parallel` and contributes to this file’s behavior.
- Line 441: `void sequence(List<String> ids, {Duration startAt = Duration.zero}) {` — Part of the public or internal API; it is named `sequence` and contributes to this file’s behavior.
- Line 451: `void stagger(List<String> ids, {required Duration offset, Duration startAt = Duration.zero}) {` — Part of the public or internal API; it is named `stagger` and contributes to this file’s behavior.
- Line 463: `void play({double speed = 1.0, bool loop = false, bool pingPong = false}) {` — Starts playback or execution.
- Line 469: `void reverse({double speed = 1.0}) {` — Part of the public or internal API; it is named `reverse` and contributes to this file’s behavior.
- Line 475: `void pause() { _playing = false; _ticker.stop(); }` — Pauses playback or execution.
- Line 477: `void reset() {` — Resets the object back to a known baseline state.
- Line 486: `void seek(double t) {` — Jumps to a specific time or offset.
- Line 493: `void _wake() {` — Part of the public or internal API; it is named `_wake` and contributes to this file’s behavior.
- Line 499: `void _onTick(Duration elapsed) {` — Part of the public or internal API; it is named `_onTick` and contributes to this file’s behavior.
- Line 529: `void _applyElapsed(double elapsedMs) {` — Part of the public or internal API; it is named `_applyElapsed` and contributes to this file’s behavior.
- Line 557: `void _integrateSpring(int idx, double dt) {` — Part of the public or internal API; it is named `_integrateSpring` and contributes to this file’s behavior.
- Line 601: `void dispose() => _ticker.dispose();` — Releases listeners, controllers, caches, and other owned resources.
- Line 649: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 655: `void initTimeline() {}` — Initializes internal state and prepares the object for use.
- Line 658: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 690: `Widget build(BuildContext context) => AnimatedBuilder(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 722: `QLGlassConfig copyWith({` — Creates a modified copy while preserving unchanged values.
- …and 25 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 1294 lines in the source file.
- 25 top-level declarations detected by static analysis.
- 49 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
