# `src/runtime/quantum_data_pipeline.dart`

## What this file is
A framework source file that participates in the Quantum runtime.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `quantum_data_state.dart`.
- Internal framework dependency: `../foundation/quantum_primitives.dart`.
- Internal framework dependency: `../foundation/quantum_core.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 13: `enum QLPipelineMode { collection, single }` — Enumerates the finite states or modes supported by `QLPipelineMode`.
- Line 15: `enum QLExecutionMode { client, server, isolate, auto }` — Enumerates the finite states or modes supported by `QLExecutionMode`.
- Line 17: `class QLPrefetchConfig {` — Defines the `QLPrefetchConfig` type and its fields, methods, and lifecycle.
- Line 27: `class QLAggregateOp {` — Defines the `QLAggregateOp` type and its fields, methods, and lifecycle.
- Line 39: `abstract class QLPipelineDelegate {` — Defines the abstract `QLPipelineDelegate` contract used by implementations elsewhere in the framework.
- Line 47: `class QLDataPipeline {` — Defines the `QLDataPipeline` type and its fields, methods, and lifecycle.
- Line 955: `class QLPipelineRegistry {` — Defines the `QLPipelineRegistry` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 40: `Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state);` — Fetches data from the configured source, often over the network or from a cache.
- Line 41: `Future<List<Map<String, dynamic>>> fetchPartial(` — Fetches data from the configured source, often over the network or from a cache.
- Line 137: `Map<String, dynamic> snapshot() {` — Part of the public or internal API; it is named `snapshot` and contributes to this file’s behavior.
- Line 162: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 190: `void setFilters(Map<int, String> next) {` — Part of the public or internal API; it is named `setFilters` and contributes to this file’s behavior.
- Line 195: `void setSearchQuery(String query) {` — Part of the public or internal API; it is named `setSearchQuery` and contributes to this file’s behavior.
- Line 199: `void setSort(int fieldIndex, {bool ascending = true}) {` — Part of the public or internal API; it is named `setSort` and contributes to this file’s behavior.
- Line 204: `void setPage(int pageIndex) {` — Part of the public or internal API; it is named `setPage` and contributes to this file’s behavior.
- Line 208: `void clearFilters() {` — Part of the public or internal API; it is named `clearFilters` and contributes to this file’s behavior.
- Line 213: `void replaceAll(dynamic rawData, {List<String>? selectedFields}) {` — Part of the public or internal API; it is named `replaceAll` and contributes to this file’s behavior.
- Line 224: `Map<String, dynamic> recordAsMap(int realIdx) => getAsMap(realIdx);` — Part of the public or internal API; it is named `recordAsMap` and contributes to this file’s behavior.
- Line 228: `void _buildIndices() {` — Part of the public or internal API; it is named `_buildIndices` and contributes to this file’s behavior.
- Line 238: `void _updateIndexEntries(` — Part of the public or internal API; it is named `_updateIndexEntries` and contributes to this file’s behavior.
- Line 277: `void _updateSearchCache(int recordIdx, List<dynamic> flat) {` — Part of the public or internal API; it is named `_updateSearchCache` and contributes to this file’s behavior.
- Line 295: `void _expandMasks(int minCapacity) {` — Part of the public or internal API; it is named `_expandMasks` and contributes to this file’s behavior.
- Line 311: `void _markLoadedBits(int recordIdx, QLProjection? proj, bool full) {` — Part of the public or internal API; it is named `_markLoadedBits` and contributes to this file’s behavior.
- Line 330: `List<dynamic> _flattenMap(Map<String, dynamic> parsed, QLProjection? proj) {` — Part of the public or internal API; it is named `_flattenMap` and contributes to this file’s behavior.
- Line 339: `dynamic _readAt(Map<String, dynamic> root, List<dynamic> path) {` — Part of the public or internal API; it is named `_readAt` and contributes to this file’s behavior.
- Line 397: `void ingest(dynamic rawData, {List<String>? selectedFields}) {` — Part of the public or internal API; it is named `ingest` and contributes to this file’s behavior.
- Line 512: `void patch(String recordId, Map<String, dynamic> delta) {` — Part of the public or internal API; it is named `patch` and contributes to this file’s behavior.
- Line 562: `Future<void> ensureFields(` — Guarantees that the named resource exists or has been registered before use.
- Line 623: `void notifyScrollIndex(int currentIndex) {` — Notifies listeners that an observed value has changed.
- Line 681: `void registerAggregates(List<QLAggregateOp> ops) {` — Registers a resource, manifest, or handler into the owning registry.
- Line 935: `Map<String, dynamic> getAsMap(int realIdx) {` — Part of the public or internal API; it is named `getAsMap` and contributes to this file’s behavior.
- …and 16 more member declarations or helpers.

## How it works
This file belongs to the Quantum framework and participates in the broader composition of runtime, UI, data, or integration behavior.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 988 lines in the source file.
- 7 top-level declarations detected by static analysis.
- 40 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
