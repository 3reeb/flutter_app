# `src/plugins/adapters/quantum_firebase_adapters.dart`

## What this file is
An adapter set that maps the shared API surface onto a particular backend or environment such as local, mock, universal, or Firebase behavior.

Author-intent note: import 'dart:io'; // <-- Add this import

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:typed_data`.
- Pub package import: `package:firebase_auth/firebase_auth.dart`.
- Pub package import: `package:cloud_firestore/cloud_firestore.dart`.
- Pub package import: `package:firebase_database/firebase_database.dart`.
- Pub package import: `package:firebase_storage/firebase_storage.dart`.
- Core Dart library: `dart:io`.
- Internal framework dependency: `../quantum_api_engine.dart`.
- Internal framework dependency: `../quantum_auth_engine.dart`.
- Internal framework dependency: `../quantum_media_api.dart`.
- Internal framework dependency: `../quantum_socket_engine.dart`.
- Internal framework dependency: `../internal/quantum_socket_stream_hub.dart`.

## Top-level declarations
- Line 24: `class FirebaseAuthDriver implements AuthDriver {` — Defines the `FirebaseAuthDriver` type and its fields, methods, and lifecycle.
- Line 418: `class FirebaseApiDriver implements VaultDriver {` — Defines the `FirebaseApiDriver` type and its fields, methods, and lifecycle.
- Line 692: `class FirebaseSocketDriver` — Defines the `FirebaseSocketDriver` type and its fields, methods, and lifecycle.
- Line 795: `class FirebaseMediaStorageBridge {` — Defines the `FirebaseMediaStorageBridge` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 51: `Future<SessionContext> _mapUserToSession(fb_auth.User? user,` — Part of the public or internal API; it is named `_mapUserToSession` and contributes to this file’s behavior.
- Line 82: `AuthException _mapFirebaseError(dynamic e) {` — Part of the public or internal API; it is named `_mapFirebaseError` and contributes to this file’s behavior.
- Line 91: `Future<void> initialize(Map<String, dynamic> config) async {` — Initializes internal state and prepares the object for use.
- Line 96: `Future<AuthResult<SessionContext>> register(AuthRequest request) async {` — Registers a resource, manifest, or handler into the owning registry.
- Line 114: `Future<AuthResult<SessionContext>> login(AuthRequest request) async {` — Part of the public or internal API; it is named `login` and contributes to this file’s behavior.
- Line 132: `Future<AuthResult<SessionContext>> refreshSession(` — Part of the public or internal API; it is named `refreshSession` and contributes to this file’s behavior.
- Line 149: `Future<AuthResult<void>> revokeSession(SessionContext session) async =>` — Part of the public or internal API; it is named `revokeSession` and contributes to this file’s behavior.
- Line 153: `Future<AuthResult<void>> logout(SessionContext session) async {` — Part of the public or internal API; it is named `logout` and contributes to this file’s behavior.
- Line 166: `Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async {` — Part of the public or internal API; it is named `requestOtp` and contributes to this file’s behavior.
- Line 196: `Future<AuthResult<SessionContext>> verifyOtp(` — Part of the public or internal API; it is named `verifyOtp` and contributes to this file’s behavior.
- Line 217: `Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,` — Updates internal state or a derived representation.
- Line 240: `Future<AuthResult<void>> verifyEmail(String token) async {` — Part of the public or internal API; it is named `verifyEmail` and contributes to this file’s behavior.
- Line 251: `Future<AuthResult<void>> resendVerification() async {` — Part of the public or internal API; it is named `resendVerification` and contributes to this file’s behavior.
- Line 261: `Future<AuthResult<void>> forgotPassword(String email) async {` — Part of the public or internal API; it is named `forgotPassword` and contributes to this file’s behavior.
- Line 271: `Future<AuthResult<AuthChallenge>> beginBiometricAuth(` — Part of the public or internal API; it is named `beginBiometricAuth` and contributes to this file’s behavior.
- Line 280: `Future<AuthResult<SessionContext>> completeBiometricAuth(` — Part of the public or internal API; it is named `completeBiometricAuth` and contributes to this file’s behavior.
- Line 289: `Future<AuthResult<void>> resetPassword(` — Resets the object back to a known baseline state.
- Line 300: `Future<AuthResult<SessionContext>> changePassword(` — Part of the public or internal API; it is named `changePassword` and contributes to this file’s behavior.
- Line 324: `Future<AuthResult<void>> unlockAccount(String token) async =>` — Part of the public or internal API; it is named `unlockAccount` and contributes to this file’s behavior.
- Line 329: `Future<AuthResult<void>> revokeAllSessions(` — Part of the public or internal API; it is named `revokeAllSessions` and contributes to this file’s behavior.
- Line 337: `Future<AuthResult<SessionContext>> linkProvider(` — Part of the public or internal API; it is named `linkProvider` and contributes to this file’s behavior.
- Line 354: `Future<AuthResult<SessionContext>> unlinkProvider(` — Part of the public or internal API; it is named `unlinkProvider` and contributes to this file’s behavior.
- Line 367: `Future<AuthResult<List<String>>> discoverAuthMethods(` — Part of the public or internal API; it is named `discoverAuthMethods` and contributes to this file’s behavior.
- Line 375: `Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(` — Part of the public or internal API; it is named `beginPasskeyRegistration` and contributes to this file’s behavior.
- …and 21 more member declarations or helpers.

## How it works
Adapter modules provide backend-specific implementations behind one shared contract. The rest of the framework can switch between mock, local, universal, or Firebase behavior without changing call sites.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 837 lines in the source file.
- 4 top-level declarations detected by static analysis.
- 45 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
