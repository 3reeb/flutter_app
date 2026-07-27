# `src/ui/quantum_theme_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM THEME ENGINE (QTE) v14.0 — OMEGA DoD 4x32 SIMD CORE (QLE Enhanced)

## Dependencies
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:ui`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 20: `abstract final class QF32 {` — Provides a static namespace of constants and helper methods under `QF32`.
- Line 46: `abstract final class QC32 {` — Provides a static namespace of constants and helper methods under `QC32`.
- Line 64: `abstract final class QI32 {` — Provides a static namespace of constants and helper methods under `QI32`.
- Line 79: `abstract final class QLayoutFlags {` — Provides a static namespace of constants and helper methods under `QLayoutFlags`.
- Line 109: `abstract final class QRenderFlags {` — Provides a static namespace of constants and helper methods under `QRenderFlags`.
- Line 126: `abstract final class QTextFlags {` — Provides a static namespace of constants and helper methods under `QTextFlags`.
- Line 140: `abstract final class QStateFlags {` — Provides a static namespace of constants and helper methods under `QStateFlags`.
- Line 153: `abstract final class QContextBits {` — Provides a static namespace of constants and helper methods under `QContextBits`.
- Line 167: `extension type const QToken(int id) {` — Extends an existing type with convenience helpers without changing the original class.
- Line 176: `final class QTokenRecord {` — Part of the public or internal API; it is named `QTokenRecord` and contributes to this file’s behavior.
- Line 191: `final class QThemeToken {` — Part of the public or internal API; it is named `QThemeToken` and contributes to this file’s behavior.
- Line 206: `final class QThemeDictionary {` — Part of the public or internal API; it is named `QThemeDictionary` and contributes to this file’s behavior.
- Line 310: `final class QThemeGraph {` — Part of the public or internal API; it is named `QThemeGraph` and contributes to this file’s behavior.
- Line 463: `abstract final class QMorpher {` — Provides a static namespace of constants and helper methods under `QMorpher`.
- Line 514: `abstract final class QStyleTokenizer {` — Provides a static namespace of constants and helper methods under `QStyleTokenizer`.
- Line 536: `class QSimdArena {` — Defines the `QSimdArena` type and its fields, methods, and lifecycle.
- Line 668: `class QCompiler {` — Defines the `QCompiler` type and its fields, methods, and lifecycle.
- Line 1250: `class QEngine {` — Defines the `QEngine` type and its fields, methods, and lifecycle.
- …and 6 more top-level declarations.

## Important members and helpers
- Line 229: `void ingestGroup(String groupName, Object? group) {` — Part of the public or internal API; it is named `ingestGroup` and contributes to this file’s behavior.
- Line 276: `Map<String, dynamic> toJson() => <String, dynamic>{` — Converts the object into another representation.
- Line 290: `QThemeDictionary merge(QThemeDictionary other) {` — Part of the public or internal API; it is named `merge` and contributes to this file’s behavior.
- Line 320: `void load(QThemeDictionary next) {` — Loads data or metadata from a source, then resolves it into the in-memory model.
- Line 358: `void _resolveAll() {` — Part of the public or internal API; it is named `_resolveAll` and contributes to this file’s behavior.
- Line 361: `int resolveColorByName(String name) {` — Resolves an abstract value into a concrete runtime value or path.
- Line 416: `int color(String name, {int fallback = 0}) {` — Part of the public or internal API; it is named `color` and contributes to this file’s behavior.
- Line 422: `double number(String name, {double fallback = 0.0}) {` — Part of the public or internal API; it is named `number` and contributes to this file’s behavior.
- Line 428: `String text(String name, {String fallback = ''}) {` — Part of the public or internal API; it is named `text` and contributes to this file’s behavior.
- Line 434: `bool contains(String name) => nameToId.containsKey(name);` — Part of the public or internal API; it is named `contains` and contributes to this file’s behavior.
- Line 436: `List<String> names() => List<String>.unmodifiable(nameToId.keys);` — Part of the public or internal API; it is named `names` and contributes to this file’s behavior.
- Line 438: `Map<String, dynamic> snapshot() => <String, dynamic>{` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 563: `void _initBuffers() {` — Part of the public or internal API; it is named `_initBuffers` and contributes to this file’s behavior.
- Line 583: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 599: `int allocate() {` — Part of the public or internal API; it is named `allocate` and contributes to this file’s behavior.
- Line 604: `int registerObject(Object obj) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 612: `void _expand() {` — Part of the public or internal API; it is named `_expand` and contributes to this file’s behavior.
- Line 636: `void copyFrom(QSimdArena other) {` — Part of the public or internal API; it is named `copyFrom` and contributes to this file’s behavior.
- Line 678: `void setThemeGraph(QThemeGraph theme) {` — Part of the public or internal API; it is named `setThemeGraph` and contributes to this file’s behavior.
- Line 682: `QToken compile(` — Part of the public or internal API; it is named `compile` and contributes to this file’s behavior.
- Line 1291: `void initialize({int initialCapacity = 4096, int ecsCapacity = 100000}) {` — Initializes internal state and prepares the object for use.
- Line 1309: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 1323: `QToken compileStyle(String style, {int contextMask = 0}) {` — Part of the public or internal API; it is named `compileStyle` and contributes to this file’s behavior.
- Line 1328: `void loadThemeDictionary(QThemeDictionary dictionary) {` — Loads data or metadata from a source, then resolves it into the in-memory model.
- …and 19 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on `dart:ui`, so it is likely dealing with paint, image decode, or render-surface work.

## File size
- 2046 lines in the source file.
- 24 top-level declarations detected by static analysis.
- 43 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
