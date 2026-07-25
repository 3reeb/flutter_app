# `src/app/quantum.config.dart.example`

## What this file is
A developer-facing example configuration file. It shows the intended shape of the real configuration object and provides stronger default values for app, API, security, merge, cache, and source sections.

Author-intent note: Copy this file to `quantum.config.dart` and edit the single source of truth.

## Dependencies
- Internal framework dependency: `quantum.config.dart`.

## Top-level declarations
- No top-level type or function declarations were detected.

## Important members and helpers
- No member declarations were detected beyond the top level.

## How it works
The real work is configuration composition: multiple sections are grouped into a single immutable root so that app, API, security, merge, cache, and source policy can be resolved together.
The example variant demonstrates the intended shape of the configuration tree and acts as a high-signal template for people wiring the app for the first time.

## Dependency and design notes
- The config tree is intentionally nested so policy, routing, API, cache, and boot defaults stay coordinated.

## File size
- 146 lines in the source file.
- 0 top-level declarations detected by static analysis.
- 0 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
