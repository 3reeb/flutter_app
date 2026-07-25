# `src/plugins/quantum_auth_engine.dart`

## What this file is
A subsystem engine. Files with this role typically own state, lifecycle, rendering, decoding, or orchestration for one feature area and expose a higher-level API to the rest of the framework.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Pub package import: `package:crypto/crypto.dart`.
- Internal framework dependency: `../foundation/quantum_isolate_bridge.dart`.

## Top-level declarations
- Line 12: `typedef JsonMap = Map<String, dynamic>;` — Declares the `JsonMap` type alias so callback signatures stay readable and consistent.
- Line 13: `typedef NowFn = DateTime Function();` — Declares the `NowFn` type alias so callback signatures stay readable and consistent.
- Line 14: `typedef LoggerFn = void Function(String message);` — Declares the `LoggerFn` type alias so callback signatures stay readable and consistent.
- Line 16: `enum AuthProvider {` — Enumerates the finite states or modes supported by `AuthProvider`.
- Line 27: `enum OtpChannel { sms, email, voice, push, totp, custom }` — Enumerates the finite states or modes supported by `OtpChannel`.
- Line 29: `enum AuthChallengeType {` — Enumerates the finite states or modes supported by `AuthChallengeType`.
- Line 41: `enum AuthChallengeState { pending, verified, consumed, expired, failed }` — Enumerates the finite states or modes supported by `AuthChallengeState`.
- Line 43: `enum SecurityScope { sessionBound, userBound, deviceBound, appBound }` — Enumerates the finite states or modes supported by `SecurityScope`.
- Line 45: `class AuthException implements Exception {` — Defines the `AuthException` type and its fields, methods, and lifecycle.
- Line 56: `class AuthResult<T> {` — Defines the `AuthResult<T>` type and its fields, methods, and lifecycle.
- Line 77: `class SessionContext {` — Defines the `SessionContext` type and its fields, methods, and lifecycle.
- Line 179: `class AuthRequest {` — Defines the `AuthRequest` type and its fields, methods, and lifecycle.
- Line 191: `class AuthChallenge {` — Defines the `AuthChallenge` type and its fields, methods, and lifecycle.
- Line 249: `class AuthCapabilities {` — Defines the `AuthCapabilities` type and its fields, methods, and lifecycle.
- Line 281: `class AuthPolicy {` — Defines the `AuthPolicy` type and its fields, methods, and lifecycle.
- Line 317: `abstract class AuthSecretStore {` — Defines the abstract `AuthSecretStore` contract used by implementations elsewhere in the framework.
- Line 325: `class MemoryAuthSecretStore implements AuthSecretStore {` — Defines the `MemoryAuthSecretStore` type and its fields, methods, and lifecycle.
- Line 359: `class AuthSecurityEngine {` — Defines the `AuthSecurityEngine` type and its fields, methods, and lifecycle.
- …and 4 more top-level declarations.

## Important members and helpers
- Line 53: `String toString() => 'AuthException($code): $message';` — Converts the object into another representation.
- Line 104: `Map<String, dynamic> toJson() => {` — Converts the object into another representation.
- Line 128: `SessionContext copyWith({` — Creates a modified copy while preserving unchanged values.
- Line 150: `List<String> _strings(dynamic raw) {` — Part of the public or internal API; it is named `_strings` and contributes to this file’s behavior.
- Line 162: `List<String> get roles => _strings(claims['roles'] ?? claims['role']);` — Part of the public or internal API; it is named `_strings` and contributes to this file’s behavior.
- Line 165: `List<String> get features => _strings(` — Part of the public or internal API; it is named `_strings` and contributes to this file’s behavior.
- Line 167: `List<String> get subscriptions => _strings(` — Part of the public or internal API; it is named `_strings` and contributes to this file’s behavior.
- Line 170: `bool hasRole(String role) => roles.contains(role);` — Part of the public or internal API; it is named `hasRole` and contributes to this file’s behavior.
- Line 171: `bool hasPermission(String permission) => permissions.contains(permission);` — Part of the public or internal API; it is named `hasPermission` and contributes to this file’s behavior.
- Line 172: `bool hasFeature(String feature) => features.contains(feature);` — Part of the public or internal API; it is named `hasFeature` and contributes to this file’s behavior.
- Line 173: `bool hasSubscription(String subscription) =>` — Part of the public or internal API; it is named `hasSubscription` and contributes to this file’s behavior.
- Line 176: `dynamic claim(String key) => claims[key];` — Part of the public or internal API; it is named `claim` and contributes to this file’s behavior.
- Line 216: `Map<String, dynamic> toJson() => {` — Converts the object into another representation.
- Line 318: `Future<void> init();` — Initializes internal state and prepares the object for use.
- Line 319: `Future<String?> read(String key);` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 320: `Future<void> write(String key, String value);` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 321: `Future<void> delete(String key);` — Part of the public or internal API; it is named `delete` and contributes to this file’s behavior.
- Line 322: `Future<void> clear({String? prefix});` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 330: `Future<void> init() async {}` — Initializes internal state and prepares the object for use.
- Line 333: `Future<String?> read(String key) async => _values[key];` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 336: `Future<void> write(String key, String value) async {` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 342: `Future<void> delete(String key) async {` — Part of the public or internal API; it is named `delete` and contributes to this file’s behavior.
- Line 348: `Future<void> clear({String? prefix}) async {` — Part of the public or internal API; it is named `clear` and contributes to this file’s behavior.
- Line 367: `Map<String, String> signPayload(` — Part of the public or internal API; it is named `signPayload` and contributes to this file’s behavior.
- …and 94 more member declarations or helpers.

## How it works
Files in this group usually own a self-contained state machine or controller. They combine helper methods, cached state, and lifecycle hooks to keep the rest of the system simple.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 1747 lines in the source file.
- 22 top-level declarations detected by static analysis.
- 118 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
