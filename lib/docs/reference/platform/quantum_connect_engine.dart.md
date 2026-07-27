# `src/platform/quantum_connect_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: STATUS: newly written, additive, NOT yet run through `flutter analyze` or

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 77: `class QLChannel<T> {` — Defines the `QLChannel<T>` type and its fields, methods, and lifecycle.
- Line 122: `class QLChannelHub {` — Defines the `QLChannelHub` type and its fields, methods, and lifecycle.
- Line 163: `class QLChannelBuilder<T> extends StatefulWidget {` — Defines the `QLChannelBuilder<T>` type and its fields, methods, and lifecycle.
- Line 179: `class _QLChannelBuilderState<T> extends State<QLChannelBuilder<T>> {` — Defines the `_QLChannelBuilderState<T>` type and its fields, methods, and lifecycle.
- Line 221: `typedef QLRouteTitleResolver = String Function(QLRouteInfo info);` — Declares the `QLRouteTitleResolver` type alias so callback signatures stay readable and consistent.
- Line 223: `String _defaultRouteTitle(QLRouteInfo info) {` — Part of the public or internal API; it is named `_defaultRouteTitle` and contributes to this file’s behavior.
- Line 249: `class QLNavBridge {` — Defines the `QLNavBridge` type and its fields, methods, and lifecycle.
- Line 285: `enum QLPressPhase {` — Enumerates the finite states or modes supported by `QLPressPhase`.
- Line 295: `typedef QLPressPhaseCallback = void Function(QLPressPhase phase, double dragDy);` — Declares the `QLPressPhaseCallback` type alias so callback signatures stay readable and consistent.
- Line 308: `class QLPressGesture extends StatefulWidget {` — Defines the `QLPressGesture` type and its fields, methods, and lifecycle.
- Line 332: `class _QLPressGestureState extends State<QLPressGesture> {` — Defines the `_QLPressGestureState` type and its fields, methods, and lifecycle.
- Line 414: `class QLMorphSlot extends StatelessWidget {` — Defines the `QLMorphSlot` type and its fields, methods, and lifecycle.
- Line 454: `enum QLBackRevealMode { none, longPress }` — Enumerates the finite states or modes supported by `QLBackRevealMode`.
- Line 465: `class QLSmartBackButton extends StatefulWidget {` — Defines the `QLSmartBackButton` type and its fields, methods, and lifecycle.
- Line 483: `class _QLSmartBackButtonState extends State<QLSmartBackButton> {` — Defines the `_QLSmartBackButtonState` type and its fields, methods, and lifecycle.
- Line 532: `class _DefaultBackTag extends StatelessWidget {` — Defines the `_DefaultBackTag` type and its fields, methods, and lifecycle.
- Line 561: `class QLFocusRevealField<T> extends StatefulWidget {` — Defines the `QLFocusRevealField<T>` type and its fields, methods, and lifecycle.
- Line 577: `class _QLFocusRevealFieldState<T> extends State<QLFocusRevealField<T>> {` — Defines the `_QLFocusRevealFieldState<T>` type and its fields, methods, and lifecycle.
- …and 1 more top-level declarations.

## Important members and helpers
- Line 87: `T valueOr(T fallback) => _hasValue ? (_value as T) : fallback;` — Part of the public or internal API; it is named `valueOr` and contributes to this file’s behavior.
- Line 89: `void publish(T value) {` — Part of the public or internal API; it is named `publish` and contributes to this file’s behavior.
- Line 100: `VoidCallback subscribe(void Function(T value) onChange) {` — Part of the public or internal API; it is named `subscribe` and contributes to this file’s behavior.
- Line 108: `VoidCallback bindSignal(QLSignalBase<T> signal, {bool publishInitial = true}) {` — Binds this object to another signal, stream, or controller.
- Line 109: `void sync() => publish(signal.value);` — Part of the public or internal API; it is named `sync` and contributes to this file’s behavior.
- Line 145: `void publish<T>(String name, T value) => channel<T>(name).publish(value);` — Part of the public or internal API; it is named `publish<T>` and contributes to this file’s behavior.
- Line 147: `T valueOr<T>(String name, T fallback) {` — Part of the public or internal API; it is named `valueOr<T>` and contributes to this file’s behavior.
- Line 153: `bool exists(String name) => _channels.containsKey(name);` — Part of the public or internal API; it is named `exists` and contributes to this file’s behavior.
- Line 157: `void resetForTesting() => _channels.clear();` — Resets the object back to a known baseline state.
- Line 185: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 190: `void _bind() {` — Part of the public or internal API; it is named `_bind` and contributes to this file’s behavior.
- Line 199: `void didUpdateWidget(covariant QLChannelBuilder<T> oldWidget) {` — Part of the public or internal API; it is named `didUpdateWidget` and contributes to this file’s behavior.
- Line 208: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 214: `Widget build(BuildContext context) => widget.builder(context, _value);` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 256: `void publish() {` — Part of the public or internal API; it is named `publish` and contributes to this file’s behavior.
- Line 336: `void _emit(QLPressPhase phase) {` — Part of the public or internal API; it is named `_emit` and contributes to this file’s behavior.
- Line 341: `void _onStart(LongPressStartDetails details) {` — Part of the public or internal API; it is named `_onStart` and contributes to this file’s behavior.
- Line 346: `void _onMove(LongPressMoveUpdateDetails details) {` — Part of the public or internal API; it is named `_onMove` and contributes to this file’s behavior.
- Line 389: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 429: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 496: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 537: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 579: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 589: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- …and 7 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 632 lines in the source file.
- 19 top-level declarations detected by static analysis.
- 31 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
