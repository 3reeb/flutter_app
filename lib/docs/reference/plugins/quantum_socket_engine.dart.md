# `src/plugins/quantum_socket_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:io`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Internal framework dependency: `../foundation/quantum_isolate_bridge.dart`.
- Internal framework dependency: `internal/quantum_socket_stream_hub.dart`.
- Internal framework dependency: `quantum_auth_engine.dart`.

## Top-level declarations
- Line 19: `class VaultSocketException implements Exception {` — Defines the `VaultSocketException` type and its fields, methods, and lifecycle.
- Line 32: `enum SocketState { disconnected, connecting, connected, reconnecting, error }` — Enumerates the finite states or modes supported by `SocketState`.
- Line 34: `enum SocketDataType { text, json, binary }` — Enumerates the finite states or modes supported by `SocketDataType`.
- Line 36: `enum SocketPattern { pubsub, rpc_request, rpc_response, stream_chunk, system }` — Enumerates the finite states or modes supported by `SocketPattern`.
- Line 38: `class SocketMessage {` — Defines the `SocketMessage` type and its fields, methods, and lifecycle.
- Line 114: `abstract class SocketDriver {` — Defines the abstract `SocketDriver` contract used by implementations elsewhere in the framework.
- Line 130: `class NativeWebSocketDriver` — Defines the `NativeWebSocketDriver` type and its fields, methods, and lifecycle.
- Line 208: `class QuantumSocketConfig {` — Defines the `QuantumSocketConfig` type and its fields, methods, and lifecycle.
- Line 232: `class QuantumSocketEngine {` — Defines the `QuantumSocketEngine` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 25: `String toString() => 'VaultSocketException($code): $message';` — Converts the object into another representation.
- Line 85: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 120: `Future<void> connect(String url, Map<String, dynamic> options);` — Part of the public or internal API; it is named `connect` and contributes to this file’s behavior.
- Line 121: `Future<void> disconnect();` — Part of the public or internal API; it is named `disconnect` and contributes to this file’s behavior.
- Line 122: `Future<void> send(SocketMessage message);` — Part of the public or internal API; it is named `send` and contributes to this file’s behavior.
- Line 123: `Future<void> sendRawBinary(Uint8List data);` — Part of the public or internal API; it is named `sendRawBinary` and contributes to this file’s behavior.
- Line 139: `Future<void> connect(String url, Map<String, dynamic> options) async {` — Part of the public or internal API; it is named `connect` and contributes to this file’s behavior.
- Line 180: `Future<void> send(SocketMessage message) async {` — Part of the public or internal API; it is named `send` and contributes to this file’s behavior.
- Line 191: `Future<void> sendRawBinary(Uint8List data) async {` — Part of the public or internal API; it is named `sendRawBinary` and contributes to this file’s behavior.
- Line 197: `Future<void> disconnect() async {` — Part of the public or internal API; it is named `disconnect` and contributes to this file’s behavior.
- Line 265: `void _setupEncryption() {` — Part of the public or internal API; it is named `_setupEncryption` and contributes to this file’s behavior.
- Line 337: `void useOutbound(FutureOr<SocketMessage> Function(SocketMessage) middleware) {` — Part of the public or internal API; it is named `useOutbound` and contributes to this file’s behavior.
- Line 341: `void useInbound(FutureOr<SocketMessage> Function(SocketMessage) middleware) {` — Part of the public or internal API; it is named `useInbound` and contributes to this file’s behavior.
- Line 347: `Future<void> connect() async {` — Part of the public or internal API; it is named `connect` and contributes to this file’s behavior.
- Line 354: `Future<void> disconnect() async {` — Part of the public or internal API; it is named `disconnect` and contributes to this file’s behavior.
- Line 364: `Future<void> updateConfig(QuantumSocketConfig newConfig) async {` — Updates internal state or a derived representation.
- Line 374: `Future<void> _attemptConnection() async {` — Part of the public or internal API; it is named `_attemptConnection` and contributes to this file’s behavior.
- Line 389: `void _handleDisconnect() {` — Part of the public or internal API; it is named `_handleDisconnect` and contributes to this file’s behavior.
- Line 478: `Future<void> emit(String channel, String event, dynamic payload) async {` — Part of the public or internal API; it is named `emit` and contributes to this file’s behavior.
- Line 492: `Future<SocketMessage> request(String channel, String event, dynamic payload,` — Part of the public or internal API; it is named `request` and contributes to this file’s behavior.
- Line 528: `Stream<SocketMessage> subscribe(String channel) {` — Part of the public or internal API; it is named `subscribe` and contributes to this file’s behavior.
- Line 557: `Future<void> sendBinary(Uint8List data) async {` — Part of the public or internal API; it is named `sendBinary` and contributes to this file’s behavior.
- Line 597: `Future<void> dispose() async {` — Releases listeners, controllers, caches, and other owned resources.
- …and 4 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 606 lines in the source file.
- 9 top-level declarations detected by static analysis.
- 28 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
