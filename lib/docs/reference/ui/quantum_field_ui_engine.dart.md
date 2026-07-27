# `src/ui/quantum_field_ui_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM FIELD UI ENGINE v2.0 - OMEGA HEADLESS PRIMITIVES

## Dependencies
- Core Dart library: `dart:math`.
- Flutter framework import: `package:flutter/gestures.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `internal/quantum_focus_sync.dart`.

## Top-level declarations
- Line 33: `class QLFieldUIState {` — Defines the `QLFieldUIState` type and its fields, methods, and lifecycle.
- Line 54: `class QLSliderUIState extends QLFieldUIState {` — Defines the `QLSliderUIState` type and its fields, methods, and lifecycle.
- Line 77: `class QLReactiveTextBridge extends TextEditingController {` — Defines the `QLReactiveTextBridge` type and its fields, methods, and lifecycle.
- Line 124: `class QLRawTextInput extends StatefulWidget {` — Defines the `QLRawTextInput` type and its fields, methods, and lifecycle.
- Line 163: `class _QLRawTextInputState extends State<QLRawTextInput> {` — Defines the `_QLRawTextInputState` type and its fields, methods, and lifecycle.
- Line 296: `class QLRawToggle extends StatefulWidget {` — Defines the `QLRawToggle` type and its fields, methods, and lifecycle.
- Line 315: `class _QLRawToggleState extends State<QLRawToggle>` — Defines the `_QLRawToggleState` type and its fields, methods, and lifecycle.
- Line 425: `class QLRawOption<T> extends StatefulWidget {` — Defines the `QLRawOption<T>` type and its fields, methods, and lifecycle.
- Line 446: `class _QLRawOptionState<T> extends State<QLRawOption<T>>` — Defines the `_QLRawOptionState<T>` type and its fields, methods, and lifecycle.
- Line 566: `class QLRawSlider extends StatefulWidget {` — Defines the `QLRawSlider` type and its fields, methods, and lifecycle.
- Line 588: `class _QLRawSliderState extends State<QLRawSlider> {` — Defines the `_QLRawSliderState` type and its fields, methods, and lifecycle.
- Line 753: `class QLRawTrigger extends StatefulWidget {` — Defines the `QLRawTrigger` type and its fields, methods, and lifecycle.
- Line 770: `class _QLRawTriggerState extends State<QLRawTrigger> {` — Defines the `_QLRawTriggerState` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 87: `void _onEngineDataChanged() {` — Part of the public or internal API; it is named `_onEngineDataChanged` and contributes to this file’s behavior.
- Line 111: `void _onFlutterUiChanged() {` — Part of the public or internal API; it is named `_onFlutterUiChanged` and contributes to this file’s behavior.
- Line 117: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 175: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 196: `void _checkEmptyState() {` — Part of the public or internal API; it is named `_checkEmptyState` and contributes to this file’s behavior.
- Line 203: `void _onEngineStateFlagsChanged() {` — Part of the public or internal API; it is named `_onEngineStateFlagsChanged` and contributes to this file’s behavior.
- Line 213: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 225: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 323: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 335: `void _syncFocus() {` — Part of the public or internal API; it is named `_syncFocus` and contributes to this file’s behavior.
- Line 339: `void _onEngineFlagsChanged() {` — Part of the public or internal API; it is named `_onEngineFlagsChanged` and contributes to this file’s behavior.
- Line 343: `void _onDataChanged() {` — Part of the public or internal API; it is named `_onDataChanged` and contributes to this file’s behavior.
- Line 350: `void _toggle() {` — Part of the public or internal API; it is named `_toggle` and contributes to this file’s behavior.
- Line 358: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 368: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 456: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 468: `void _syncFocus() {` — Part of the public or internal API; it is named `_syncFocus` and contributes to this file’s behavior.
- Line 476: `void _onEngineFlagsChanged() {` — Part of the public or internal API; it is named `_onEngineFlagsChanged` and contributes to this file’s behavior.
- Line 496: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 506: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 596: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 650: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 659: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 775: `void initState() {` — Initializes internal state and prepares the object for use.
- …and 11 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 854 lines in the source file.
- 13 top-level declarations detected by static analysis.
- 35 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
