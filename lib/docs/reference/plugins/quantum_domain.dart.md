# `src/plugins/quantum_domain.dart`

## What this file is
A plugin/runtime integration module. These files connect the core framework to APIs, sockets, auth, media, domain logic, or plugin adapters.

## Dependencies
- Core Dart library: `dart:async`.
- Core Dart library: `dart:typed_data`.
- Flutter framework import: `package:flutter/widgets.dart`.
- Internal framework dependency: `../app/quantum_app_shell.dart`.
- Internal framework dependency: `../../quantum.dart`.
- Internal framework dependency: `quantum_api_shell.dart`.
- Exports `quantum_api_shell.dart`.

## Top-level declarations
- Line 14: `typedef QuantumPayloadBuilder = Map<String, dynamic> Function(` — Declares the `QuantumPayloadBuilder` type alias so callback signatures stay readable and consistent.
- Line 22: `QuantumDomain quantumApiShellDomain({` — Part of the public or internal API; it is named `quantumApiShellDomain` and contributes to this file’s behavior.
- Line 59: `class QuantumShellApiClient implements QuantumApiClient {` — Defines the `QuantumShellApiClient` type and its fields, methods, and lifecycle.
- Line 154: `class _QuantumShellAuthClient implements QuantumAuthClient {` — Defines the `_QuantumShellAuthClient` type and its fields, methods, and lifecycle.
- Line 181: `class QuantumStreamRegistry {` — Defines the `QuantumStreamRegistry` type and its fields, methods, and lifecycle.
- Line 248: `class _QuantumRunAction extends QLActionPlugin {` — Defines the `_QuantumRunAction` type and its fields, methods, and lifecycle.
- Line 262: `class _QuantumDomainAction extends QLActionPlugin {` — Defines the `_QuantumDomainAction` type and its fields, methods, and lifecycle.
- Line 279: `class _QuantumStreamStartAction extends QLActionPlugin {` — Defines the `_QuantumStreamStartAction` type and its fields, methods, and lifecycle.
- Line 314: `class _QuantumStreamCancelAction extends QLActionPlugin {` — Defines the `_QuantumStreamCancelAction` type and its fields, methods, and lifecycle.
- Line 327: `class _QuantumStreamCancelAllAction extends QLActionPlugin {` — Defines the `_QuantumStreamCancelAllAction` type and its fields, methods, and lifecycle.
- Line 338: `class _QuantumStreamInAction extends QLActionPlugin {` — Defines the `_QuantumStreamInAction` type and its fields, methods, and lifecycle.
- Line 354: `class _QuantumStreamOutAction extends QLActionPlugin {` — Defines the `_QuantumStreamOutAction` type and its fields, methods, and lifecycle.
- Line 372: `Map<String, dynamic> _requestFromPayload(` — Part of the public or internal API; it is named `_requestFromPayload` and contributes to this file’s behavior.
- Line 415: `void _normalizeBinaryArgs(Map<String, dynamic> request) {` — Part of the public or internal API; it is named `_normalizeBinaryArgs` and contributes to this file’s behavior.
- Line 428: `void _storeResult(` — Part of the public or internal API; it is named `_storeResult` and contributes to this file’s behavior.
- Line 436: `dynamic _unwrap(Map<String, dynamic> result) {` — Part of the public or internal API; it is named `_unwrap` and contributes to this file’s behavior.
- Line 441: `String _collectionWriteAction(String op, {String? id}) {` — Part of the public or internal API; it is named `_collectionWriteAction` and contributes to this file’s behavior.

## Important members and helpers
- Line 68: `Future<void> init() async {` — Initializes internal state and prepares the object for use.
- Line 79: `Future<dynamic> executeRead({` — Part of the public or internal API; it is named `executeRead` and contributes to this file’s behavior.
- Line 101: `Future<dynamic> executeWrite({` — Part of the public or internal API; it is named `executeWrite` and contributes to this file’s behavior.
- Line 121: `QuantumAuthClient auth() => _QuantumShellAuthClient(this);` — Part of the public or internal API; it is named `auth` and contributes to this file’s behavior.
- Line 124: `Future<dynamic> cacheGet(String key) async {` — Part of the public or internal API; it is named `cacheGet` and contributes to this file’s behavior.
- Line 134: `Future<void> cacheSet(String key, dynamic value) async {` — Part of the public or internal API; it is named `cacheSet` and contributes to this file’s behavior.
- Line 144: `Future<void> cacheRemove(String key) async {` — Part of the public or internal API; it is named `cacheRemove` and contributes to this file’s behavior.
- Line 160: `Future<dynamic> login(Map body) => _auth('login', body);` — Part of the public or internal API; it is named `login` and contributes to this file’s behavior.
- Line 163: `Future<dynamic> register(Map body) => _auth('register', body);` — Registers a resource, manifest, or handler into the owning registry.
- Line 166: `Future<dynamic> logout() => _auth('logout', const {});` — Part of the public or internal API; it is named `logout` and contributes to this file’s behavior.
- Line 169: `Future<dynamic> me() => _auth('me', const {});` — Part of the public or internal API; it is named `me` and contributes to this file’s behavior.
- Line 171: `Future<dynamic> _auth(String action, Map body) async {` — Part of the public or internal API; it is named `_auth` and contributes to this file’s behavior.
- Line 250: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 267: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 281: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 316: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 329: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 340: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 356: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.

## How it works
Plugin modules expose domain-, API-, socket-, auth-, and media-related capabilities in a framework-friendly form. They often pair a high-level contract with one or more backend adapters.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 474 lines in the source file.
- 17 top-level declarations detected by static analysis.
- 19 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
