# `src/plugins/native/quantum_camera.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `enum CameraLens { front, back }` — Enumerates the finite states or modes supported by `CameraLens`.
- Line 11: `enum FlashMode { off, auto, on }` — Enumerates the finite states or modes supported by `FlashMode`.
- Line 13: `class CameraConfig {` — Defines the `CameraConfig` type and its fields, methods, and lifecycle.
- Line 31: `class MediaResult {` — Defines the `MediaResult` type and its fields, methods, and lifecycle.
- Line 52: `class _InitCodec extends QLChannelCodec<CameraConfig, bool> {` — Defines the `_InitCodec` type and its fields, methods, and lifecycle.
- Line 60: `class _MediaCodec extends QLChannelCodec<void, MediaResult> {` — Defines the `_MediaCodec` type and its fields, methods, and lifecycle.
- Line 69: `class _InitBridge extends QLMethodBridge<CameraConfig, bool> {` — Defines the `_InitBridge` type and its fields, methods, and lifecycle.
- Line 82: `class _VoidBoolCodec extends QLChannelCodec<void, bool> {` — Defines the `_VoidBoolCodec` type and its fields, methods, and lifecycle.
- Line 90: `class _DisposeBridgeImpl extends QLMethodBridge<void, bool> {` — Defines the `_DisposeBridgeImpl` type and its fields, methods, and lifecycle.
- Line 97: `class _TakePhotoBridge extends QLMethodBridge<void, MediaResult> {` — Defines the `_TakePhotoBridge` type and its fields, methods, and lifecycle.
- Line 104: `class _StartVideoBridge extends QLMethodBridge<void, bool> {` — Defines the `_StartVideoBridge` type and its fields, methods, and lifecycle.
- Line 111: `class _StopVideoBridge extends QLMethodBridge<void, MediaResult> {` — Defines the `_StopVideoBridge` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 24: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.
- Line 55: `dynamic encode(CameraConfig args) => args.toMap();` — Serializes the object into a portable or wire-ready form.
- Line 57: `bool decode(dynamic data) => data == true;` — Deserializes a serialized input into the runtime form.
- Line 63: `dynamic encode(void args) => null;` — Serializes the object into a portable or wire-ready form.
- Line 65: `MediaResult decode(dynamic data) =>` — Deserializes a serialized input into the runtime form.
- Line 85: `dynamic encode(void args) => null;` — Serializes the object into a portable or wire-ready form.
- Line 87: `bool decode(dynamic data) => data == true;` — Deserializes a serialized input into the runtime form.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 155 lines in the source file.
- 12 top-level declarations detected by static analysis.
- 7 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
