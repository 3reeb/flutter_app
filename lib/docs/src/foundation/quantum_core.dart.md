# `src/foundation/quantum_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:typed_data`.
- Pub package import: `package:yaml/yaml.dart`.
- Core Dart library: `dart:math`.

## Top-level declarations
- Line 11: `abstract final class QLNodeState {` — Provides a static namespace of constants and helper methods under `QLNodeState`.
- Line 28: `enum QLSleepPolicy { never, manual, auto }` — Enumerates the finite states or modes supported by `QLSleepPolicy`.
- Line 30: `class QLNodeError {` — Defines the `QLNodeError` type and its fields, methods, and lifecycle.
- Line 36: `typedef QLValidator<T> = QLNodeError? Function(T value, Object graph);` — Declares the `QLValidator` type alias so callback signatures stay readable and consistent.
- Line 37: `typedef QLAsyncValidator<T> = Future<QLNodeError?> Function(` — Declares the `QLAsyncValidator` type alias so callback signatures stay readable and consistent.
- Line 40: `typedef QLFastMiddleware<T> = T Function(T incoming, T current);` — Declares the `QLFastMiddleware` type alias so callback signatures stay readable and consistent.
- Line 41: `typedef QLValueTransform<T> = T Function(T incoming);` — Declares the `QLValueTransform` type alias so callback signatures stay readable and consistent.
- Line 43: `abstract final class QLFieldType {` — Provides a static namespace of constants and helper methods under `QLFieldType`.
- Line 61: `abstract final class QLFieldFlags {` — Provides a static namespace of constants and helper methods under `QLFieldFlags`.
- Line 119: `abstract final class QLPathUtils {` — Provides a static namespace of constants and helper methods under `QLPathUtils`.
- Line 220: `abstract class QLDisposable {` — Defines the abstract `QLDisposable` contract used by implementations elsewhere in the framework.
- Line 224: `class QLProjection {` — Defines the `QLProjection` type and its fields, methods, and lifecycle.
- Line 237: `class QLChangeBatch {` — Defines the `QLChangeBatch` type and its fields, methods, and lifecycle.
- Line 242: `class QLFieldPathView {` — Defines the `QLFieldPathView` type and its fields, methods, and lifecycle.
- Line 251: `abstract final class QLFormatParser {` — Provides a static namespace of constants and helper methods under `QLFormatParser`.
- Line 295: `abstract final class QParser {` — Provides a static namespace of constants and helper methods under `QParser`.
- Line 426: `sealed class QSize {` — Part of the public or internal API; it is named `QSize` and contributes to this file’s behavior.
- Line 430: `class QFixed extends QSize {` — Defines the `QFixed` type and its fields, methods, and lifecycle.
- …and 8 more top-level declarations.

## Important members and helpers
- Line 221: `void dispose();` — Releases listeners, controllers, caches, and other owned resources.
- Line 228: `void select(int fieldIndex) {` — Part of the public or internal API; it is named `select` and contributes to this file’s behavior.
- Line 232: `bool isSelected(int fieldIndex) {` — Part of the public or internal API; it is named `isSelected` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 650 lines in the source file.
- 26 top-level declarations detected by static analysis.
- 3 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
