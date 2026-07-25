# `src/runtime/omni_cores/template_core.dart`

## What this file is
A core primitives file. These modules define low-level types, flags, value objects, or utility abstractions used throughout the framework.

## Dependencies
- part of '../quantum_omni_registry.dart';

## Top-level declarations
- Line 3: `void _registerRichDesignSystemTemplates(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerRichDesignSystemTemplates` and contributes to this file’s behavior.
- Line 1331: `Widget _buildTemplate(QLContext rawCtx) {` — Part of the public or internal API; it is named `_buildTemplate` and contributes to this file’s behavior.
- Line 1346: `class _QTemplateInstanceNode extends StatefulWidget {` — Defines the `_QTemplateInstanceNode` type and its fields, methods, and lifecycle.
- Line 1355: `class _QTemplateInstanceNodeState extends State<_QTemplateInstanceNode> {` — Defines the `_QTemplateInstanceNodeState` type and its fields, methods, and lifecycle.
- Line 1387: `class _QLTickerNode extends StatefulWidget {` — Defines the `_QLTickerNode` type and its fields, methods, and lifecycle.
- Line 1395: `class _QLTickerNodeState extends State<_QLTickerNode>` — Defines the `_QLTickerNodeState` type and its fields, methods, and lifecycle.
- Line 1421: `class _QLFlowControllerNode extends StatefulWidget {` — Defines the `_QLFlowControllerNode` type and its fields, methods, and lifecycle.
- Line 1444: `class _QLFlowControllerNodeState extends State<_QLFlowControllerNode> {` — Defines the `_QLFlowControllerNodeState` type and its fields, methods, and lifecycle.
- Line 1471: `class _QLStickyDelegate extends SliverPersistentHeaderDelegate {` — Defines the `_QLStickyDelegate` type and its fields, methods, and lifecycle.
- Line 1491: `void _registerPowerFieldTemplates(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerPowerFieldTemplates` and contributes to this file’s behavior.
- Line 2179: `void _registerBuiltInTemplates(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerBuiltInTemplates` and contributes to this file’s behavior.
- Line 2226: `void _registerGeneralBuiltInTemplates(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerGeneralBuiltInTemplates` and contributes to this file’s behavior.
- Line 3036: `void _registerTemplateAliases(QuantumVM vm) {` — Part of the public or internal API; it is named `_registerTemplateAliases` and contributes to this file’s behavior.

## Important members and helpers
- Line 4: `QLBlueprint bp(Map<String, dynamic> json) => QLBlueprint.fromJson(json);` — Part of the public or internal API; it is named `bp` and contributes to this file’s behavior.
- Line 6: `Map<String, dynamic> node(` — Part of the public or internal API; it is named `node` and contributes to this file’s behavior.
- Line 21: `QLBlueprint cloneNode(` — Part of the public or internal API; it is named `cloneNode` and contributes to this file’s behavior.
- Line 44: `List<QLBlueprint> buildRecursiveMenuItems(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 112: `List<QLBlueprint> buildRowsFromRecords(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1359: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 1371: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 1377: `Widget build(BuildContext context) {` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1401: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 1412: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 1418: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1448: `void initState() {` — Initializes internal state and prepares the object for use.
- Line 1454: `void dispose() {` — Releases listeners, controllers, caches, and other owned resources.
- Line 1463: `Widget build(BuildContext context) => widget.child;` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1483: `Widget build(` — Builds or transforms a runtime structure, often a widget tree, route list, or manifest.
- Line 1487: `bool shouldRebuild(covariant _QLStickyDelegate old) =>` — Part of the public or internal API; it is named `shouldRebuild` and contributes to this file’s behavior.
- Line 2227: `QLBlueprint bp(Map<String, dynamic> json) => QLBlueprint.fromJson(json);` — Part of the public or internal API; it is named `bp` and contributes to this file’s behavior.
- Line 2229: `Map<String, dynamic> node(` — Part of the public or internal API; it is named `node` and contributes to this file’s behavior.
- Line 2242: `Map<String, dynamic> txt(String value,` — Part of the public or internal API; it is named `txt` and contributes to this file’s behavior.
- Line 2246: `Map<String, dynamic> setState(String key, dynamic value) =>` — Part of the public or internal API; it is named `setState` and contributes to this file’s behavior.
- Line 2249: `int clampIndex(dynamic raw, int length) {` — Part of the public or internal API; it is named `clampIndex` and contributes to this file’s behavior.
- Line 2257: `String stateKey(QTemplateContext ctx, String localName) {` — Part of the public or internal API; it is named `stateKey` and contributes to this file’s behavior.
- Line 2262: `List<QLBlueprint> navItems(` — Part of the public or internal API; it is named `navItems` and contributes to this file’s behavior.

## How it works
These files define the basic primitives that every higher-level module builds on. The emphasis is on stable low-level types, flags, and helpers rather than UI or app policy.

## Dependency and design notes
- The dependencies are mostly internal framework modules, so the file participates in a tightly coupled but structured runtime graph.

## File size
- 3101 lines in the source file.
- 13 top-level declarations detected by static analysis.
- 23 member-like declarations/helpers detected by static analysis.

## Reading order
Start with the top-level declarations, then follow the member list for the most important behaviors. If this file is a barrel export, platform stub, or config template, the dependency section is often the most important part because it explains what the file connects to rather than what it computes locally.
