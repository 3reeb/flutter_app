# `src/foundation/quantum_atoms.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

## Dependencies
- Core Dart library: `dart:collection`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `quantum_reactive_graph.dart`.

## Top-level declarations
- Line 9: `typedef QLAtomEquals<T> = bool Function(T a, T b);` — Declares the `QLAtomEquals` type alias so callback signatures stay readable and consistent.
- Line 10: `typedef QLAtomDecoder<T> = T Function(dynamic value);` — Declares the `QLAtomDecoder` type alias so callback signatures stay readable and consistent.
- Line 11: `typedef QLAtomEncoder<T> = dynamic Function(T value);` — Declares the `QLAtomEncoder` type alias so callback signatures stay readable and consistent.
- Line 13: `bool _qlAtomDefaultEquals<T>(T a, T b) => identical(a, b) || a == b;` — Part of the public or internal API; it is named `_qlAtomDefaultEquals<T>` and contributes to this file’s behavior.
- Line 20: `class QLStateAtom<T> extends QLSignal<T> {` — Defines the `QLStateAtom<T>` type and its fields, methods, and lifecycle.
- Line 78: `class QLComputedAtom<T> extends QLDerivedSignal<T> {` — Defines the `QLComputedAtom<T>` type and its fields, methods, and lifecycle.
- Line 108: `class QLStoreAtom<T> extends QLSignalProxy<T> {` — Defines the `QLStoreAtom<T>` type and its fields, methods, and lifecycle.
- Line 127: `class QLAtomFamily<K, A> {` — Defines the `QLAtomFamily<K,` type and its fields, methods, and lifecycle.
- Line 180: `extension QLDataStoreAtomExt on QLDataStore {` — Extends an existing type with convenience helpers without changing the original class.
- Line 241: `extension QuantumVMAtomExt on QuantumVM {` — Extends an existing type with convenience helpers without changing the original class.
- Line 284: `class QLAtomBuilder<T> extends StatelessWidget {` — Defines the `QLAtomBuilder<T>` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 41: `T updateValue(T Function(T current) mutate) {` — Updates internal state or a derived representation.
- Line 47: `void reset(T next) => value = next;` — Resets the object back to a known baseline state.
- Line 49: `void toggle() {` — Converts the object into another representation.
- Line 58: `R Function(T value) mapper, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 70: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 85: `T Function() compute, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 92: `R Function(T value) mapper, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 139: `A call(K key) {` — Part of the public or internal API; it is named `call` and contributes to this file’s behavior.
- Line 152: `bool contains(K key) => _cache.containsKey(key);` — Part of the public or internal API; it is named `contains` and contributes to this file’s behavior.
- Line 154: `void remove(K key) {` — Removes a previously registered item or association.
- Line 159: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 170: `void _evictIfNeeded() {` — Part of the public or internal API; it is named `_evictIfNeeded` and contributes to this file’s behavior.
- Line 197: `T Function() compute, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 256: `T Function() compute, {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 295: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 301 lines in the source file.
- 11 top-level declarations detected by static analysis.
- 15 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
