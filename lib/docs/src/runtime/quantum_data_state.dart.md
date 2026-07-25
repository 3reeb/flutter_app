# `src/runtime/quantum_data_state.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 10: `typedef QLJsonMap = Map<String, dynamic>;` — Declares the `QLJsonMap` type alias so callback signatures stay readable and consistent.
- Line 11: `typedef QLJsonList = List<dynamic>;` — Declares the `QLJsonList` type alias so callback signatures stay readable and consistent.
- Line 16: `final class QLRuntimeSupport {` — Part of the public or internal API; it is named `QLRuntimeSupport` and contributes to this file’s behavior.
- Line 81: `class QLRuntimeCacheStats {` — Defines the `QLRuntimeCacheStats` type and its fields, methods, and lifecycle.
- Line 105: `class QLRuntimeCacheConfig {` — Defines the `QLRuntimeCacheConfig` type and its fields, methods, and lifecycle.
- Line 117: `class _QLRuntimeCacheEntry<T> {` — Defines the `_QLRuntimeCacheEntry<T>` type and its fields, methods, and lifecycle.
- Line 140: `final class QLRuntimeCacheSizer {` — Part of the public or internal API; it is named `QLRuntimeCacheSizer` and contributes to this file’s behavior.
- Line 166: `class QLNullContext implements BuildContext {` — Defines the `QLNullContext` type and its fields, methods, and lifecycle.
- Line 176: `class QLRuntimeCache<T> {` — Defines the `QLRuntimeCache<T>` type and its fields, methods, and lifecycle.
- Line 296: `abstract class QLActionPlugin {` — Defines the abstract `QLActionPlugin` contract used by implementations elsewhere in the framework.
- Line 301: `class _QLAsyncBindingHooks {` — Defines the `_QLAsyncBindingHooks` type and its fields, methods, and lifecycle.
- Line 313: `class QLStoreRegistry {` — Defines the `QLStoreRegistry` type and its fields, methods, and lifecycle.
- Line 379: `typedef QLMutationFn = FutureOr<dynamic> Function(` — Declares the `QLMutationFn` type alias so callback signatures stay readable and consistent.
- Line 382: `typedef QLQueryFn = Future<dynamic> Function(` — Declares the `QLQueryFn` type alias so callback signatures stay readable and consistent.
- Line 385: `class QLDataStore {` — Defines the `QLDataStore` type and its fields, methods, and lifecycle.
- Line 811: `class _ComputationNode {` — Defines the `_ComputationNode` type and its fields, methods, and lifecycle.
- Line 850: `class QLDataScope extends InheritedWidget {` — Defines the `QLDataScope` type and its fields, methods, and lifecycle.
- Line 912: `String _qlCanonicalStatePath(Object path) =>` — Part of the public or internal API; it is named `_qlCanonicalStatePath` and contributes to this file’s behavior.
- …and 17 more top-level declarations.

## Important members and helpers
- Line 96: `Map<String, int> toMap() => <String, int>{` — Converts the object into another representation.
- Line 132: `bool isExpired(DateTime now) {` — Part of the public or internal API; it is named `isExpired` and contributes to this file’s behavior.
- Line 173: `dynamic noSuchMethod(Invocation invocation) => null;` — Part of the public or internal API; it is named `noSuchMethod` and contributes to this file’s behavior.
- Line 206: `T put(Object key, T value, {int? weight, Duration? ttl}) {` — Part of the public or internal API; it is named `put` and contributes to this file’s behavior.
- Line 224: `T getOrPut(Object key, T Function() loader, {int? weight, Duration? ttl}) {` — Part of the public or internal API; it is named `getOrPut` and contributes to this file’s behavior.
- Line 230: `bool contains(Object key) {` — Part of the public or internal API; it is named `contains` and contributes to this file’s behavior.
- Line 240: `void remove(Object key) {` — Removes a previously registered item or association.
- Line 245: `void removeWhere(` — Removes a previously registered item or association.
- Line 246: `bool Function(Object key, _QLRuntimeCacheEntry<T> entry) test) {` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 257: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 262: `void sweepExpired() {` — Part of the public or internal API; it is named `sweepExpired` and contributes to this file’s behavior.
- Line 270: `void compact() {` — Part of the public or internal API; it is named `compact` and contributes to this file’s behavior.
- Line 283: `void _evictIfNeeded() {` — Part of the public or internal API; it is named `_evictIfNeeded` and contributes to this file’s behavior.
- Line 297: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 320: `QLDataStore get(String namespace) {` — Part of the public or internal API; it is named `get` and contributes to this file’s behavior.
- Line 326: `bool exists(String namespace) =>` — Part of the public or internal API; it is named `exists` and contributes to this file’s behavior.
- Line 329: `void destroy(String namespace) {` — Part of the public or internal API; it is named `destroy` and contributes to this file’s behavior.
- Line 339: `void clearAll() {` — Part of the public or internal API; it is named `clearAll` and contributes to this file’s behavior.
- Line 349: `Map<String, dynamic> snapshot({bool includeDefault = true}) {` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 452: `void bindAsync(String basePath, QLAsyncSignal<dynamic> asyncSignal) {` — Binds this object to another signal, stream, or controller.
- Line 470: `void syncData() => set(dataKey, asyncSignal.data.value);` — Part of the public or internal API; it is named `syncData` and contributes to this file’s behavior.
- Line 471: `void syncLoading() => set(loadKey, asyncSignal.loading.value);` — Part of the public or internal API; it is named `syncLoading` and contributes to this file’s behavior.
- Line 472: `void syncError() => set(errorKey, asyncSignal.error.value?.toString());` — Part of the public or internal API; it is named `syncError` and contributes to this file’s behavior.
- Line 485: `void registerComputed(String targetKey, List<String> dependencies,` — Registers a resource, manifest, or handler into the owning registry.
- …and 64 more member declarations or helpers.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 2350 lines in the source file.
- 35 top-level declarations detected by static analysis.
- 88 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
