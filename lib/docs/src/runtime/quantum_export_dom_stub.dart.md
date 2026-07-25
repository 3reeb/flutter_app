# `src/runtime/quantum_export_dom_stub.dart`

## What this file is
A stub implementation used when the current platform does not support the hydration reader behavior. It intentionally stays minimal so unsupported builds still compile cleanly.

Author-intent note: QUANTUM EXPORT DOM HELPER — stub (non-web platforms)

## Dependencies
- Flutter framework import: `package:flutter/foundation.dart`.

## Top-level declarations
- Line 11: `void writePngToDom(String base64Png) {` — Part of the public or internal API; it is named `writePngToDom` and contributes to this file’s behavior.
- Line 16: `void signalReady() {` — Part of the public or internal API; it is named `signalReady` and contributes to this file’s behavior.
- Line 20: `void signalError(String message) {` — Part of the public or internal API; it is named `signalError` and contributes to this file’s behavior.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
This file is a compile-time fallback. It intentionally does very little so unsupported platforms can still build while the real behavior lives in the platform-specific file.

## Dependency and design notes
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- This file is intentionally minimal and acts as a fallback rather than the main implementation.

## File size
- 22 lines in the source file.
- 3 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
