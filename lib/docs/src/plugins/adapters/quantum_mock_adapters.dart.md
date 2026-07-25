# `src/plugins/adapters/quantum_mock_adapters.dart`

## What this file is
An adapter set that maps the shared API surface onto a particular backend or environment such as local, mock, universal, or Firebase behavior.

Author-intent note: SECTION 1: MOCK NETWORK CONFIGURATION

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:convert`.
- Core Dart library: `dart:math`.
- Core Dart library: `dart:typed_data`.
- Internal framework dependency: `../quantum_api_engine.dart`.
- Internal framework dependency: `../quantum_auth_engine.dart`.
- Internal framework dependency: `../quantum_socket_engine.dart`.
- Internal framework dependency: `../internal/quantum_socket_stream_hub.dart`.
- Internal framework dependency: `../quantum_media_api.dart`.

## Top-level declarations
- Line 20: `class MockNetworkConfig {` — Defines the `MockNetworkConfig` type and its fields, methods, and lifecycle.
- Line 51: `class SocketException implements Exception {` — Defines the `SocketException` type and its fields, methods, and lifecycle.
- Line 62: `class MockApiDriver implements VaultDriver {` — Defines the `MockApiDriver` type and its fields, methods, and lifecycle.
- Line 281: `class MockAuthDriver implements AuthDriver {` — Defines the `MockAuthDriver` type and its fields, methods, and lifecycle.
- Line 648: `class MockSocketDriver extends QLSocketDriverBase<SocketState, SocketMessage>` — Defines the `MockSocketDriver` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 31: `Future<void> simulate() async {` — Part of the public or internal API; it is named `simulate` and contributes to this file’s behavior.
- Line 55: `String toString() => 'SocketException: $message';` — Converts the object into another representation.
- Line 75: `Future<void> initialize(Map<String, dynamic> config) async {}` — Initializes internal state and prepares the object for use.
- Line 77: `String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();` — Part of the public or internal API; it is named `_generateId` and contributes to this file’s behavior.
- Line 80: `Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `read` and contributes to this file’s behavior.
- Line 179: `Future<ApiResult<dynamic>> write(` — Part of the public or internal API; it is named `write` and contributes to this file’s behavior.
- Line 264: `Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,` — Part of the public or internal API; it is named `subscribe` and contributes to this file’s behavior.
- Line 271: `Future<void> dispose() async {` — Releases listeners, controllers, caches, and other owned resources.
- Line 303: `Future<void> initialize(Map<String, dynamic> config) async {}` — Initializes internal state and prepares the object for use.
- Line 305: `String _generateToken(String userId) =>` — Part of the public or internal API; it is named `_generateToken` and contributes to this file’s behavior.
- Line 308: `SessionContext _buildSession(String userId, Map<String, dynamic> user) {` — Part of the public or internal API; it is named `_buildSession` and contributes to this file’s behavior.
- Line 321: `Future<AuthResult<SessionContext>> login(AuthRequest request) async {` — Part of the public or internal API; it is named `login` and contributes to this file’s behavior.
- Line 366: `Future<AuthResult<SessionContext>> register(AuthRequest request) async {` — Registers a resource, manifest, or handler into the owning registry.
- Line 390: `Future<AuthResult<SessionContext>> refreshSession(` — Part of the public or internal API; it is named `refreshSession` and contributes to this file’s behavior.
- Line 409: `Future<AuthResult<void>> logout(SessionContext session) async {` — Part of the public or internal API; it is named `logout` and contributes to this file’s behavior.
- Line 415: `Future<AuthResult<void>> revokeSession(SessionContext session) =>` — Part of the public or internal API; it is named `revokeSession` and contributes to this file’s behavior.
- Line 419: `Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,` — Updates internal state or a derived representation.
- Line 439: `Future<AuthResult<void>> forgotPassword(String email) async {` — Part of the public or internal API; it is named `forgotPassword` and contributes to this file’s behavior.
- Line 445: `Future<AuthResult<void>> resetPassword(` — Resets the object back to a known baseline state.
- Line 452: `Future<AuthResult<SessionContext>> changePassword(` — Part of the public or internal API; it is named `changePassword` and contributes to this file’s behavior.
- Line 464: `Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async {` — Part of the public or internal API; it is named `requestOtp` and contributes to this file’s behavior.
- Line 480: `Future<AuthResult<SessionContext>> verifyOtp(` — Part of the public or internal API; it is named `verifyOtp` and contributes to this file’s behavior.
- Line 494: `Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(` — Part of the public or internal API; it is named `beginPasskeyRegistration` and contributes to this file’s behavior.
- Line 510: `Future<AuthResult<SessionContext>> completePasskeyRegistration(` — Part of the public or internal API; it is named `completePasskeyRegistration` and contributes to this file’s behavior.
- …and 20 more member declarations or helpers.

## How it works
Adapter modules provide backend-specific implementations behind one shared contract. The rest of the framework can switch between mock, local, universal, or Firebase behavior without changing call sites.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 721 lines in the source file.
- 5 top-level declarations detected by static analysis.
- 44 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
