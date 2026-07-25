# `src/runtime/quantum_template_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: Moved from quantum_omni_registry.dart: template feature

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/rendering.dart`.
- Flutter framework import: `package:flutter/scheduler.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Flutter framework import: `package:flutter/gestures.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 21: `class _PendingTemplateDef {` — Defines the `_PendingTemplateDef` type and its fields, methods, and lifecycle.
- Line 49: `abstract final class QTemplateEngine {` — Provides a static namespace of constants and helper methods under `QTemplateEngine`.
- Line 450: `class _LayoutCompileResult {` — Defines the `_LayoutCompileResult` type and its fields, methods, and lifecycle.
- Line 464: `typedef QNativeTemplateBuilder = Widget Function(QTemplateContext ctx);` — Declares the `QNativeTemplateBuilder` type alias so callback signatures stay readable and consistent.
- Line 466: `class _GridRect {` — Defines the `_GridRect` type and its fields, methods, and lifecycle.
- Line 471: `class TemplateDef {` — Defines the `TemplateDef` type and its fields, methods, and lifecycle.
- Line 504: `class QTemplateContext {` — Defines the `QTemplateContext` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 516: `T prop<T>(String key, {T? fallback}) => core.prop<T>(key, fallback: fallback);` — Part of the public or internal API; it is named `prop<T>` and contributes to this file’s behavior.
- Line 517: `String string(String key, {String fallback = ''}) =>` — Part of the public or internal API; it is named `string` and contributes to this file’s behavior.
- Line 519: `bool boolean(String key, {bool fallback = false}) =>` — Part of the public or internal API; it is named `boolean` and contributes to this file’s behavior.
- Line 521: `int integer(String key, {int fallback = 0}) =>` — Part of the public or internal API; it is named `integer` and contributes to this file’s behavior.
- Line 523: `double number(String key, {double fallback = 0.0}) =>` — Part of the public or internal API; it is named `number` and contributes to this file’s behavior.
- Line 525: `List<dynamic> list(String key, {List<dynamic> fallback = const []}) =>` — Part of the public or internal API; it is named `list` and contributes to this file’s behavior.
- Line 532: `dynamic eval(dynamic expr) =>` — Part of the public or internal API; it is named `eval` and contributes to this file’s behavior.
- Line 535: `String stateKey(String key) => '${instanceId}_$key';` — Part of the public or internal API; it is named `stateKey` and contributes to this file’s behavior.
- Line 539: `bool checkGuard(String slotName) {` — Part of the public or internal API; it is named `checkGuard` and contributes to this file’s behavior.
- Line 549: `void _mergeAst(Map<String, dynamic> target, dynamic override) {` — Part of the public or internal API; it is named `_mergeAst` and contributes to this file’s behavior.
- Line 598: `Widget buildSlot(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 736: `Widget buildLayout({Map<String, Widget>? nativeSlotOverrides}) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 795 lines in the source file.
- 7 top-level declarations detected by static analysis.
- 12 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
