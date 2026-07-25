# `src/plugins/native/quantum_microphone.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `class AudioRecordingResult {` — Defines the `AudioRecordingResult` type and its fields, methods, and lifecycle.
- Line 30: `class _VoidBoolCodec extends QLChannelCodec<void, bool> {` — Defines the `_VoidBoolCodec` type and its fields, methods, and lifecycle.
- Line 36: `class _ResultCodec extends QLChannelCodec<void, AudioRecordingResult> {` — Defines the `_ResultCodec` type and its fields, methods, and lifecycle.
- Line 42: `class _StartBridge extends QLMethodBridge<void, bool> {` — Defines the `_StartBridge` type and its fields, methods, and lifecycle.
- Line 47: `class _StopBridge extends QLMethodBridge<void, AudioRecordingResult> {` — Defines the `_StopBridge` type and its fields, methods, and lifecycle.
- Line 52: `class _AmplitudeStreamBridge extends QLEventBridge<double> {` — Defines the `_AmplitudeStreamBridge` type and its fields, methods, and lifecycle.
- Line 57: `class _VoidDoubleCodec extends QLChannelCodec<void, double> {` — Defines the `_VoidDoubleCodec` type and its fields, methods, and lifecycle.
- Line 67: `class QuantumMicrophone {` — Defines the `QuantumMicrophone` type and its fields, methods, and lifecycle.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 94 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
