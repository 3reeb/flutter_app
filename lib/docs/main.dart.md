# `main.dart`

## What this file is
The app entrypoint. It initializes the VM, assembles the showcase application, registers routes, and wires the demo actions, overlays, forms, exports, and navigation examples together.

## Dependencies
- Flutter framework import: `package:flutter/material.dart`.
- Flutter framework import: `package:flutter/services.dart`.
- Internal framework dependency: `quantum.dart`.

## Top-level declarations
- Line 6: `void main() {` — Part of the public or internal API; it is named `main` and contributes to this file’s behavior.
- Line 94: `Map<String, dynamic> _homeRoute(QLRouteInfo info) => {` — Part of the public or internal API; it is named `_homeRoute` and contributes to this file’s behavior.
- Line 147: `Map<String, dynamic> _kinematicsRoute(QLRouteInfo info) =>` — Part of the public or internal API; it is named `_kinematicsRoute` and contributes to this file’s behavior.
- Line 209: `Map<String, dynamic> _themingRoute(QLRouteInfo info) =>` — Part of the public or internal API; it is named `_themingRoute` and contributes to this file’s behavior.
- Line 299: `Map<String, dynamic> _graphicsRoute(QLRouteInfo info) =>` — Part of the public or internal API; it is named `_graphicsRoute` and contributes to this file’s behavior.
- Line 363: `Map<String, dynamic> _controlsRoute(QLRouteInfo info) =>` — Part of the public or internal API; it is named `_controlsRoute` and contributes to this file’s behavior.
- Line 477: `Map<String, dynamic> _pageShell(` — Part of the public or internal API; it is named `_pageShell` and contributes to this file’s behavior.
- Line 516: `Map<String, dynamic> _section(String title, Map<String, dynamic> body) => {` — Part of the public or internal API; it is named `_section` and contributes to this file’s behavior.
- Line 529: `Map<String, dynamic> _demoBox(String text, {String color = 'blue'}) => {` — Part of the public or internal API; it is named `_demoBox` and contributes to this file’s behavior.
- Line 535: `Map<String, dynamic> _txt(String t, {String? style}) => {` — Part of the public or internal API; it is named `_txt` and contributes to this file’s behavior.
- Line 541: `Map<String, dynamic> _navCard(` — Part of the public or internal API; it is named `_navCard` and contributes to this file’s behavior.
- Line 568: `Map<String, dynamic> _btn(String text, String color,` — Part of the public or internal API; it is named `_btn` and contributes to this file’s behavior.
- Line 584: `Map<String, dynamic> _closeBtn() => {` — Part of the public or internal API; it is named `_closeBtn` and contributes to this file’s behavior.
- Line 597: `Map<String, dynamic> _modalCard(String title, String body) => {` — Part of the public or internal API; it is named `_modalCard` and contributes to this file’s behavior.
- Line 614: `Widget _toastUI(String text) => Container(` — Part of the public or internal API; it is named `_toastUI` and contributes to this file’s behavior.
- Line 627: `Map<String, dynamic> _flexRoute(QLRouteInfo info) => _pageShell('Flex & Flow', [` — Part of the public or internal API; it is named `_flexRoute` and contributes to this file’s behavior.
- Line 656: `Map<String, dynamic> _gridRoute(QLRouteInfo info) =>` — Part of the public or internal API; it is named `_gridRoute` and contributes to this file’s behavior.
- Line 681: `Map<String, dynamic> _advancedRoute(QLRouteInfo info) =>` — Part of the public or internal API; it is named `_advancedRoute` and contributes to this file’s behavior.
- …and 11 more top-level declarations.

## Important members and helpers
- Line 971: `Future<void> _runExport() async {` — Part of the public or internal API; it is named `_runExport` and contributes to this file’s behavior.
- Line 999: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1080: `Future<void> _exportProductCard(BuildContext ctx) async {` — Part of the public or internal API; it is named `_exportProductCard` and contributes to this file’s behavior.
- Line 1103: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1148: `Future<void> _exportOgImage(BuildContext ctx) async {` — Part of the public or internal API; it is named `_exportOgImage` and contributes to this file’s behavior.
- Line 1165: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1213: `Future<void> _runBatch(BuildContext ctx) async {` — Part of the public or internal API; it is named `_runBatch` and contributes to this file’s behavior.
- Line 1225: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1264: `Future<void> _export() async {` — Part of the public or internal API; it is named `_export` and contributes to this file’s behavior.
- Line 1284: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1326: `Future<void> _export() async {` — Part of the public or internal API; it is named `_export` and contributes to this file’s behavior.
- Line 1353: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.

## How it works
Startup begins in `main()`, which initializes the VM and boots the app with a configured `QuantumAppConfig`.
The route builders in this file construct nested page/data structures for the demo shells, so the entrypoint doubles as the showcase catalog and the app launcher.
The export helpers at the bottom turn demo content into generated output, which is why this file contains both UI route composition and export orchestration.

## Dependency and design notes
- It depends on the `quantum.dart` barrel export, which means it can access the framework-wide public surface from a single import.
- It uses Flutter APIs directly, so widget lifecycles, render objects, or theming behavior are part of its runtime contract.
- This file is unusually large because it combines app bootstrapping, demo route construction, and export utilities in one place.

## File size
- 1429 lines in the source file.
- 29 top-level declarations detected by static analysis.
- 12 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.


## Studio updates
- Added clipboard paste flow for SDUI JSON.
- Added JSON export helper and responsive desktop/mobile layout.
- Preserves raw JSON so Quantum VM compiles the same document that is exported.


## Studio controls added in the latest update
- Clipboard paste is still supported, but now the app also exposes explicit example registration.
- The studio keeps a local example registry, can run all examples, and isolates failures per example.
- Error output is shown as selectable text and can be copied from the UI.
- The render health section reports compile/test outcomes for the full registered suite.
- Mobile and desktop layouts share the same workflow, so the studio is usable across screen sizes.
