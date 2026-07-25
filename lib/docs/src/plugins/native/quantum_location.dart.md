# `src/plugins/native/quantum_location.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `class LocationData {` — Defines the `LocationData` type and its fields, methods, and lifecycle.
- Line 30: `class _VoidLocationCodec extends QLChannelCodec<void, LocationData> {` — Defines the `_VoidLocationCodec` type and its fields, methods, and lifecycle.
- Line 36: `class _CurrentLocationBridge extends QLMethodBridge<void, LocationData> {` — Defines the `_CurrentLocationBridge` type and its fields, methods, and lifecycle.
- Line 41: `class _LocationStreamBridge extends QLEventBridge<LocationData> {` — Defines the `_LocationStreamBridge` type and its fields, methods, and lifecycle.
- Line 50: `class QuantumLocation {` — Defines the `QuantumLocation` type and its fields, methods, and lifecycle.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 70 lines in the source file.
- 5 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
