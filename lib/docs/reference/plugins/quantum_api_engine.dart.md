# `src/plugins/quantum_api_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: Assuming these are in your project

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:typed_data`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:io`.
- Core Dart library: `dart:math`.
- Pub package import: `package:crypto/crypto.dart`.
- Internal framework dependency: `../foundation/quantum_isolate_bridge.dart`.
- Internal framework dependency: `../foundation/quantum_schema.dart`.
- Internal framework dependency: `../foundation/quantum_core.dart`.
- Internal framework dependency: `../runtime/quantum_permissions.dart`.
- Internal framework dependency: `quantum_auth_engine.dart`.
- Internal framework dependency: `quantum_media_api.dart`.
- Internal framework dependency: `quantum_socket_engine.dart`.

## Top-level declarations
- Line 25: `typedef JsonEncoderFn = dynamic Function(dynamic value);` — Declares the `JsonEncoderFn` type alias so callback signatures stay readable and consistent.
- Line 26: `typedef JsonDecoderFn = dynamic Function(dynamic value);` — Declares the `JsonDecoderFn` type alias so callback signatures stay readable and consistent.
- Line 28: `typedef ProgressListener = void Function(TransferProgress progress);` — Declares the `ProgressListener` type alias so callback signatures stay readable and consistent.
- Line 30: `enum CachePolicyMode {` — Enumerates the finite states or modes supported by `CachePolicyMode`.
- Line 38: `enum OfflineMode { disabled, readThrough, writeQueue, fullOffline }` — Enumerates the finite states or modes supported by `OfflineMode`.
- Line 40: `enum StreamDirection { bidirectional, inboundOnly, outboundOnly }` — Enumerates the finite states or modes supported by `StreamDirection`.
- Line 42: `enum RequestPriority { low, normal, high, instant }` — Enumerates the finite states or modes supported by `RequestPriority`.
- Line 44: `class VaultStreamException implements Exception {` — Defines the `VaultStreamException` type and its fields, methods, and lifecycle.
- Line 55: `class ApiResult<T> {` — Defines the `ApiResult<T>` type and its fields, methods, and lifecycle.
- Line 82: `class RuntimeTrace {` — Defines the `RuntimeTrace` type and its fields, methods, and lifecycle.
- Line 106: `class QueryPolicy {` — Defines the `QueryPolicy` type and its fields, methods, and lifecycle.
- Line 154: `class CacheEntry {` — Defines the `CacheEntry` type and its fields, methods, and lifecycle.
- Line 209: `class CacheStats {` — Defines the `CacheStats` type and its fields, methods, and lifecycle.
- Line 223: `class AccessPolicy {` — Defines the `AccessPolicy` type and its fields, methods, and lifecycle.
- Line 237: `class SecurityPolicy {` — Defines the `SecurityPolicy` type and its fields, methods, and lifecycle.
- Line 263: `class OfflinePolicy {` — Defines the `OfflinePolicy` type and its fields, methods, and lifecycle.
- Line 283: `class BatchPolicy {` — Defines the `BatchPolicy` type and its fields, methods, and lifecycle.
- Line 297: `class StreamPolicy {` — Defines the `StreamPolicy` type and its fields, methods, and lifecycle.
- …and 61 more top-level declarations.

## Important members and helpers
- Line 52: `String toString() => 'VaultStreamException($code): $message';` — Converts the object into another representation.
- Line 129: `QueryPolicy copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 185: `bool isExpired(DateTime now) {` — Part of the public or internal API; it is named `isExpired` and contributes to this file’s behavior.
- Line 190: `CacheEntry touch(DateTime now) {` — Converts the object into another representation.
- Line 389: `bool isExpired(DateTime now) =>` — Part of the public or internal API; it is named `isExpired` and contributes to this file’s behavior.
- Line 412: `Future<void> initialize(Map<String, dynamic> config);` — Initializes internal state and prepares the object for use.
- Line 413: `Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 415: `Future<ApiResult<dynamic>> write(` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 418: `Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `subscribe` and contributes to this file’s behavior.
- Line 420: `Future<void> dispose();` — Releases listeners, controllers, caches, and other owned resources.
- Line 446: `Future<void> initialize(Map<String, dynamic> config) async {}` — Initializes internal state and prepares the object for use.
- Line 448: `void _injectHeaders(HttpClientRequest request, DriverContext context) {` — Part of the public or internal API; it is named `_injectHeaders` and contributes to this file’s behavior.
- Line 459: `Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 488: `Future<ApiResult<dynamic>> write(` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 523: `Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `subscribe` and contributes to this file’s behavior.
- Line 550: `Future<ApiResult<dynamic>> fetch() => read(` — Fetches data from the configured source, often over the network or from a cache.
- Line 569: `Future<void> dispose() async => _client.close(force: true);` — Releases listeners, controllers, caches, and other owned resources.
- Line 581: `Future<void> initialize(Map<String, dynamic> config) async {}` — Initializes internal state and prepares the object for use.
- Line 584: `Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 597: `Future<ApiResult<dynamic>> write(` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 611: `Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `subscribe` and contributes to this file’s behavior.
- Line 624: `Future<void> dispose() async {} // Engine disposed globally` — Releases listeners, controllers, caches, and other owned resources.
- Line 640: `Future<void> init();` — Initializes internal state and prepares the object for use.
- Line 642: `Future<String?> read(String key);` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- …and 218 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 3319 lines in the source file.
- 79 top-level declarations detected by static analysis.
- 242 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
