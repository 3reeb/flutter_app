# `src/plugins/native/quantum_notifications.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `class SimpleNotification {` — Defines the `SimpleNotification` type and its fields, methods, and lifecycle.
- Line 30: `class NotificationTap {` — Defines the `NotificationTap` type and its fields, methods, and lifecycle.
- Line 51: `class _ShowCodec extends QLChannelCodec<SimpleNotification, bool> {` — Defines the `_ShowCodec` type and its fields, methods, and lifecycle.
- Line 57: `class _ShowBridge extends QLMethodBridge<SimpleNotification, bool> {` — Defines the `_ShowBridge` type and its fields, methods, and lifecycle.
- Line 62: `class _CancelBridge extends QLMethodBridge<int, bool> {` — Defines the `_CancelBridge` type and its fields, methods, and lifecycle.
- Line 67: `class _IntBoolCodec extends QLChannelCodec<int, bool> {` — Defines the `_IntBoolCodec` type and its fields, methods, and lifecycle.
- Line 73: `class _TapStreamBridge extends QLEventBridge<NotificationTap> {` — Defines the `_TapStreamBridge` type and its fields, methods, and lifecycle.
- Line 82: `class QuantumNotifications {` — Defines the `QuantumNotifications` type and its fields, methods, and lifecycle.

## Important members and helpers
- Line 22: `Map<String, dynamic> toMap() => {` — Converts the object into another representation.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 109 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 1 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
