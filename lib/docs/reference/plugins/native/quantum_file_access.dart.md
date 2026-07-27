# `src/plugins/native/quantum_file_access.dart`

## What this file is
A native capability plugin wrapper. Each file exposes one device-level capability such as camera, calendar, location, microphone, phone, contacts, files, notifications, or photos.

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.
- Internal framework dependency: `../../platform/quantum_native_bridge.dart`.
- Internal framework dependency: `../../foundation/quantum_async.dart`.

## Top-level declarations
- Line 9: `class PickedDocument {` — Defines the `PickedDocument` type and its fields, methods, and lifecycle.
- Line 30: `class _VoidDocsCodec extends QLChannelCodec<void, List<PickedDocument>> {` — Defines the `_VoidDocsCodec` type and its fields, methods, and lifecycle.
- Line 39: `class _PickDocumentsBridge extends QLMethodBridge<void, List<PickedDocument>> {` — Defines the `_PickDocumentsBridge` type and its fields, methods, and lifecycle.
- Line 44: `class _ReadRawCodec extends QLChannelCodec<String, Uint8List> {` — Defines the `_ReadRawCodec` type and its fields, methods, and lifecycle.
- Line 50: `class _ReadBytesBridge extends QLMethodBridge<String, Uint8List> {` — Defines the `_ReadBytesBridge` type and its fields, methods, and lifecycle.
- Line 55: `class _WriteRawCodec extends QLChannelCodec<Map<String, dynamic>, bool> {` — Defines the `_WriteRawCodec` type and its fields, methods, and lifecycle.
- Line 61: `class _WriteBytesBridge extends QLMethodBridge<Map<String, dynamic>, bool> {` — Defines the `_WriteBytesBridge` type and its fields, methods, and lifecycle.
- Line 70: `class QuantumFileAccess {` — Defines the `QuantumFileAccess` type and its fields, methods, and lifecycle.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
Each native plugin wrapper isolates one device capability behind a small Dart-facing API, typically by forwarding requests to a platform channel or native bridge.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.

## File size
- 97 lines in the source file.
- 8 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
