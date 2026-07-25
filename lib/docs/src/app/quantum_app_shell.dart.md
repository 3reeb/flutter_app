# `src/app/quantum_app_shell.dart`

## What this file is
An app-level support module. These files usually connect boot-time config, shell behavior, HTTP transport, or file routing into the overall Flutter application.

Author-intent note: API CLIENT STUBS (To ensure standalone compilation)

## Dependencies
- Core Dart library: `dart:async`.
- Flutter framework import: `package:flutter/foundation.dart`.
- Flutter framework import: `package:flutter/material.dart`.
- Internal framework dependency: `../../quantum.dart`.

## Top-level declarations
- Line 16: `abstract class QuantumApiClient {` — Defines the abstract `QuantumApiClient` contract used by implementations elsewhere in the framework.
- Line 32: `abstract class QuantumAuthClient {` — Defines the abstract `QuantumAuthClient` contract used by implementations elsewhere in the framework.
- Line 39: `typedef QuantumActionFactory = QLActionPlugin Function(` — Declares the `QuantumActionFactory` type alias so callback signatures stay readable and consistent.
- Line 42: `class QuantumRuntimeServices {` — Defines the `QuantumRuntimeServices` type and its fields, methods, and lifecycle.
- Line 60: `class QuantumProductionRegistry {` — Defines the `QuantumProductionRegistry` type and its fields, methods, and lifecycle.
- Line 166: `class _SetStateAction extends QLActionPlugin {` — Defines the `_SetStateAction` type and its fields, methods, and lifecycle.
- Line 179: `class _MergeStateAction extends QLActionPlugin {` — Defines the `_MergeStateAction` type and its fields, methods, and lifecycle.
- Line 191: `class _ToggleStateAction extends QLActionPlugin {` — Defines the `_ToggleStateAction` type and its fields, methods, and lifecycle.
- Line 203: `class _RemoveStateAction extends QLActionPlugin {` — Defines the `_RemoveStateAction` type and its fields, methods, and lifecycle.
- Line 214: `class _ApiReadAction extends QLActionPlugin {` — Defines the `_ApiReadAction` type and its fields, methods, and lifecycle.
- Line 236: `class _ApiWriteAction extends QLActionPlugin {` — Defines the `_ApiWriteAction` type and its fields, methods, and lifecycle.
- Line 257: `enum _AuthOp { login, register, logout, me }` — Enumerates the finite states or modes supported by `_AuthOp`.
- Line 259: `class _AuthAction extends QLActionPlugin {` — Defines the `_AuthAction` type and its fields, methods, and lifecycle.
- Line 280: `enum _CacheOp { get, set, remove }` — Enumerates the finite states or modes supported by `_CacheOp`.
- Line 282: `class _CacheAction extends QLActionPlugin {` — Defines the `_CacheAction` type and its fields, methods, and lifecycle.
- Line 304: `dynamic _storeResult(` — Part of the public or internal API; it is named `_storeResult` and contributes to this file’s behavior.
- Line 320: `class QuantumAppEnvironment {` — Defines the `QuantumAppEnvironment` type and its fields, methods, and lifecycle.
- Line 350: `typedef QuantumDomainOrchestrator = FutureOr<void> Function(` — Declares the `QuantumDomainOrchestrator` type alias so callback signatures stay readable and consistent.
- …and 9 more top-level declarations.

## Important members and helpers
- Line 18: `Future<void> init();` — Initializes internal state and prepares the object for use.
- Line 19: `Future<dynamic> executeRead(` — Part of the public or internal API; it is named `executeRead` and contributes to this file’s behavior.
- Line 21: `Future<dynamic> executeWrite(` — Part of the public or internal API; it is named `executeWrite` and contributes to this file’s behavior.
- Line 26: `QuantumAuthClient auth();` — Part of the public or internal API; it is named `auth` and contributes to this file’s behavior.
- Line 27: `Future<dynamic> cacheGet(String key);` — Part of the public or internal API; it is named `cacheGet` and contributes to this file’s behavior.
- Line 28: `Future<void> cacheSet(String key, dynamic value);` — Part of the public or internal API; it is named `cacheSet` and contributes to this file’s behavior.
- Line 29: `Future<void> cacheRemove(String key);` — Part of the public or internal API; it is named `cacheRemove` and contributes to this file’s behavior.
- Line 33: `Future<dynamic> login(Map body);` — Part of the public or internal API; it is named `login` and contributes to this file’s behavior.
- Line 34: `Future<dynamic> register(Map body);` — Registers a resource, manifest, or handler into the owning registry.
- Line 35: `Future<dynamic> logout();` — Part of the public or internal API; it is named `logout` and contributes to this file’s behavior.
- Line 36: `Future<dynamic> me();` — Part of the public or internal API; it is named `me` and contributes to this file’s behavior.
- Line 46: `Future<QuantumApiClient?> ensureApi() async {` — Guarantees that the named resource exists or has been registered before use.
- Line 99: `void install([QuantumVM? target]) {` — Part of the public or internal API; it is named `install` and contributes to this file’s behavior.
- Line 114: `void _registerActions(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerActions` and contributes to this file’s behavior.
- Line 121: `Map<String, QLActionPlugin> _actionMap() => {` — Part of the public or internal API; it is named `_actionMap` and contributes to this file’s behavior.
- Line 168: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 181: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 193: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 205: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 218: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 241: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 264: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 287: `Future<dynamic> execute(` — Part of the public or internal API; it is named `execute` and contributes to this file’s behavior.
- Line 619: `void reassemble() {` — Part of the public or internal API; it is named `reassemble` and contributes to this file’s behavior.
- …and 3 more member declarations or helpers.

## How it works
App-level modules wire the framework together for startup, shell rendering, HTTP transport, and file routing. They are the glue between core runtime and the shipped app.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 696 lines in the source file.
- 27 top-level declarations detected by static analysis.
- 27 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
