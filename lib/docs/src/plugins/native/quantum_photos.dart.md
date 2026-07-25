# `src/plugins/native/quantum_photos.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `class MediaFile {` — Defines the `MediaFile` type and its fields, methods, and lifecycle.
- Line 29: `class PickerConfig {` — Defines the `PickerConfig` type and its fields, methods, and lifecycle.
- Line 48: `class _PickerCodec extends QLChannelCodec<PickerConfig, List<MediaFile>> {` — Defines the `_PickerCodec` type and its fields, methods, and lifecycle.
- Line 57: `class _PickMediaBridge extends QLMethodBridge<PickerConfig, List<MediaFile>> {` — Defines the `_PickMediaBridge` type and its fields, methods, and lifecycle.
- Line 66: `class QuantumPhotos {` — Defines the `QuantumPhotos` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 38: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 79 lines in the source file.
- 5 top-level declarations detected by static analysis.
- 1 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
