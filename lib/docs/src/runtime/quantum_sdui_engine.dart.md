# `src/runtime/quantum_sdui_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

Author-intent note: QUANTUM SDUI ENGINE v1.0 — ENCRYPTED SERVER-DRIVEN UI

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:collection`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Pub package import: `package:crypto/crypto.dart`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Pub package import: `package:http/http.dart`.
- Internal framework dependency: `quantum_permissions.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `../foundation/quantum_yaml_engine.dart`.

## Top-level declarations
- Line 37: `class QuantumSduiException implements Exception {` — Defines the `QuantumSduiException` type and its fields, methods, and lifecycle.
- Line 65: `class SduiEncryptedPayload {` — Defines the `SduiEncryptedPayload` type and its fields, methods, and lifecycle.
- Line 130: `class SduiKeyStore {` — Defines the `SduiKeyStore` type and its fields, methods, and lifecycle.
- Line 222: `class SduiReplayGuard {` — Defines the `SduiReplayGuard` type and its fields, methods, and lifecycle.
- Line 278: `abstract final class _AesGcm {` — Provides a static namespace of constants and helper methods under `_AesGcm`.
- Line 422: `class _AesEngine {` — Defines the `_AesEngine` type and its fields, methods, and lifecycle.
- Line 541: `class QuantumSduiEngine {` — Defines the `QuantumSduiEngine` type and its fields, methods, and lifecycle.
- Line 816: `class QLApiRequest {` — Defines the `QLApiRequest` type and its fields, methods, and lifecycle.
- Line 835: `class QLApiResponse {` — Defines the `QLApiResponse` type and its fields, methods, and lifecycle.
- Line 852: `class QuantumApiEngine {` — Defines the `QuantumApiEngine` type and its fields, methods, and lifecycle.
- Line 1033: `class _SduiFetchAction extends QLActionPlugin {` — Defines the `_SduiFetchAction` type and its fields, methods, and lifecycle.
- Line 1062: `class _ApiReadAction extends QLActionPlugin {` — Defines the `_ApiReadAction` type and its fields, methods, and lifecycle.
- Line 1083: `class _ApiWriteAction extends QLActionPlugin {` — Defines the `_ApiWriteAction` type and its fields, methods, and lifecycle.
- Line 1115: `class QLSduiWidget extends StatefulWidget {` — Defines the `QLSduiWidget` type and its fields, methods, and lifecycle.
- Line 1146: `class _QLSduiWidgetState extends State<QLSduiWidget> {` — Defines the `_QLSduiWidgetState` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 43: `String toString() =>` — Converts the object into another representation.
- Line 98: `Map<String, dynamic> toJson() => {` — Converts the object into another representation.
- Line 117: `String toString() => 'SduiEncryptedPayload(v=$version,kid=$keyId,${ct.length}b)';` — Converts the object into another representation.
- Line 139: `void registerKey({` — Registers a resource, manifest, or handler into the owning registry.
- Line 153: `void deriveAndRegister({` — Part of the public or internal API; it is named `deriveAndRegister` and contributes to this file’s behavior.
- Line 165: `void registerBase64({` — Registers a resource, manifest, or handler into the owning registry.
- Line 182: `bool hasKey(String kid) => _keys.containsKey(kid);` — Part of the public or internal API; it is named `hasKey` and contributes to this file’s behavior.
- Line 184: `void removeKey(String kid) {` — Removes a previously registered item or association.
- Line 192: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 235: `bool claimNonce(String nonce) {` — Part of the public or internal API; it is named `claimNonce` and contributes to this file’s behavior.
- Line 265: `void clear() {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 427: `Uint8List encryptBlock(Uint8List block) {` — Part of the public or internal API; it is named `encryptBlock` and contributes to this file’s behavior.
- Line 502: `void _addRoundKey(List<List<int>> s, int round) {` — Part of the public or internal API; it is named `_addRoundKey` and contributes to this file’s behavior.
- Line 512: `void _subBytes(List<List<int>> s) {` — Part of the public or internal API; it is named `_subBytes` and contributes to this file’s behavior.
- Line 517: `void _shiftRows(List<List<int>> s) {` — Part of the public or internal API; it is named `_shiftRows` and contributes to this file’s behavior.
- Line 526: `void _mixColumns(List<List<int>> s) {` — Part of the public or internal API; it is named `_mixColumns` and contributes to this file’s behavior.
- Line 566: `Future<QLBlueprint> decryptAndCompile(` — Part of the public or internal API; it is named `decryptAndCompile` and contributes to this file’s behavior.
- Line 684: `SduiEncryptedPayload encrypt(` — Part of the public or internal API; it is named `encrypt` and contributes to this file’s behavior.
- Line 733: `Future<QLBlueprint> processRaw(` — Part of the public or internal API; it is named `processRaw` and contributes to this file’s behavior.
- Line 763: `void clearCache() => _blueprintCache.clear();` — Part of the public or internal API; it is named `clearCache` and contributes to this file’s behavior.
- Line 861: `void useClient(http.Client client) {` — Part of the public or internal API; it is named `useClient` and contributes to this file’s behavior.
- Line 875: `void configure({` — Part of the public or internal API; it is named `configure` and contributes to this file’s behavior.
- Line 885: `void setHeader(String key, String value) => _defaultHeaders[key] = value;` — Part of the public or internal API; it is named `setHeader` and contributes to this file’s behavior.
- Line 886: `void setAuthToken(String token) => setHeader('Authorization', 'Bearer $token');` — Part of the public or internal API; it is named `setAuthToken` and contributes to this file’s behavior.
- …and 14 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- It depends on the `http` package for browser-side networking support.

## File size
- 1221 lines in the source file.
- 15 top-level declarations detected by static analysis.
- 38 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
