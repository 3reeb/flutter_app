# `src/foundation/quantum_isolate_worker.dart`

## What this file is
A foundation module. These files define the base reactive state, async primitives, parsing utilities, data structures, math helpers, and error-handling machinery used everywhere else.

Author-intent note: QUANTUM ISOLATE WORKER ENGINE v1.0 — ZERO-COPY BACKGROUND COMPUTE

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:isolate`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:convert`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 69: `class QLTransferableBuffer {` — Defines the `QLTransferableBuffer` type and its fields, methods, and lifecycle.
- Line 115: `class _WorkerRequest {` — Defines the `_WorkerRequest` type and its fields, methods, and lifecycle.
- Line 123: `class _WorkerResponse {` — Defines the `_WorkerResponse` type and its fields, methods, and lifecycle.
- Line 132: `class _WorkerBootstrap {` — Defines the `_WorkerBootstrap` type and its fields, methods, and lifecycle.
- Line 146: `abstract class QLWorkerTask<TInput, TOutput> {` — Defines the abstract `QLWorkerTask<TInput,` contract used by implementations elsewhere in the framework.
- Line 171: `class QLIsolateWorker {` — Defines the `QLIsolateWorker` type and its fields, methods, and lifecycle.
- Line 331: `class QLWorkerPool {` — Defines the `QLWorkerPool` type and its fields, methods, and lifecycle.
- Line 384: `class QLFloat64BatchTask extends QLWorkerTask<Float64List, Float64List> {` — Defines the `QLFloat64BatchTask` type and its fields, methods, and lifecycle.
- Line 414: `class QLJsonDecodeTask extends QLWorkerTask<String, Map<String, dynamic>> {` — Defines the `QLJsonDecodeTask` type and its fields, methods, and lifecycle.
- Line 436: `extension QLAsyncWorkerExt<T> on QLAsyncSignal<T> {` — Extends an existing type with convenience helpers without changing the original class.
- Line 467: `class QLZeroCopyPipelineTask extends QLWorkerTask<dynamic, dynamic> {` — Defines the `QLZeroCopyPipelineTask` type and its fields, methods, and lifecycle.
- Line 511: `class QLEcsSyncTask extends QLWorkerTask<dynamic, void> {` — Defines the `QLEcsSyncTask` type and its fields, methods, and lifecycle.
- Line 544: `class QLSpatialProjectionTask` — Defines the `QLSpatialProjectionTask` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 96: `Float64List decodeFloat64() {` — Deserializes a serialized input into the runtime form.
- Line 102: `Uint8List decodeUint8() {` — Deserializes a serialized input into the runtime form.
- Line 149: `dynamic encode(TInput input);` — Serializes the object into a portable or wire-ready form.
- Line 152: `dynamic compute(dynamic encoded);` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 155: `TOutput decode(dynamic raw);` — Deserializes a serialized input into the runtime form.
- Line 208: `Future<SendPort> _ensureSpawned(dynamic Function(dynamic) handler) async {` — Part of the public or internal API; it is named `_ensureSpawned` and contributes to this file’s behavior.
- Line 299: `TOutput Function(TInput) fn,` — Part of the public or internal API; it is named `Function` and contributes to this file’s behavior.
- Line 307: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 362: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 390: `dynamic encode(Float64List input) =>` — Serializes the object into a portable or wire-ready form.
- Line 396: `dynamic compute(dynamic encoded) {` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 406: `Float64List decode(dynamic raw) {` — Deserializes a serialized input into the runtime form.
- Line 418: `dynamic encode(String input) => input;` — Serializes the object into a portable or wire-ready form.
- Line 421: `dynamic compute(dynamic encoded) {` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 432: `Map<String, dynamic> decode(dynamic raw) => Map<String, dynamic>.from(raw as Map);` — Deserializes a serialized input into the runtime form.
- Line 473: `dynamic encode(dynamic input) {` — Serializes the object into a portable or wire-ready form.
- Line 480: `dynamic compute(dynamic encoded) {` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 508: `dynamic decode(dynamic raw) => raw;` — Deserializes a serialized input into the runtime form.
- Line 517: `dynamic encode(dynamic input) {` — Serializes the object into a portable or wire-ready form.
- Line 523: `dynamic compute(dynamic encoded) {` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 528: `void decode(dynamic raw) {` — Deserializes a serialized input into the runtime form.
- Line 547: `dynamic encode(Map<String, dynamic> input) => input;` — Serializes the object into a portable or wire-ready form.
- Line 550: `dynamic compute(dynamic encoded) {` — Part of the public or internal API; it is named `compute` and contributes to this file’s behavior.
- Line 603: `Float64List decode(dynamic raw) {` — Deserializes a serialized input into the runtime form.
- …and 1 more member declarations or helpers.

## How it works
Foundation files are the deepest reusable layer. They typically define the signal graph, async state machine, validators, parsers, low-level geometry, and error isolation that the rest of the framework reuses.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It uses isolates, so lifecycle, messaging, and transferable data handling are important to the implementation.

## File size
- 612 lines in the source file.
- 13 top-level declarations detected by static analysis.
- 25 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
