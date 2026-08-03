# Quantum Test Engine (QTE) — 100% Reliability & Zero Runtime Issues Execution Plan

## Executive Summary
The **Quantum Test Engine (QTE)** in `lib/sdui_tests` is a self-contained, JSON-driven SDUI test harness. 
To ensure 100% confidence when running SDUI test suites, this plan outlines the root cause analysis, fixes, and enhancements required to guarantee zero runtime failures across widget finding, gesture execution, reactive state matching, type verification, and performance profiling.

---

## 1. Root Cause Diagnostics of Identified Runtime Failures

### A. Widget Finding Failure (`Widget not found` / `Bad state: No element`)
- **Symptom:** Tests like `button_basic.test.json` and `form_journey.test.json` fail with `Widget not found: testId="..."` or interaction errors `Bad state: No element`.
- **Root Cause:** 
  1. SDUI nodes rendered via `QuantumVM` / `QEE` with `"testId": "foo"` or `"key": "foo"` in JSON props were not automatically wrapped or assigned matching Flutter `ValueKey`s (`ValueKey('__qte_testId_foo')` or `ValueKey('foo')`).
  2. `qte_render_probe.dart` was strictly matching `ValueKey('__qte_testId_${target.value}')` without robust fallbacks (such as matching `Key(target.value)`, semantics labels, element tooltips, or child widget text).
  3. `qte_host_widget.dart` did not apply a key-wrapping transformer over SDUI blueprints before rendering.

### B. Type Mismatch Failure (`Type mismatch: actual _Map<String, dynamic> vs expected _Map`)
- **Symptom:** Assertion `errors_cleared` fails with `Type mismatch (actual: _Map<String, dynamic>) (expected: _Map)`.
- **Root Cause:**
  1. `stateType` assertion in `qte_assertion.dart` compared string values of `actual.runtimeType.toString()` directly against `expected.toString()`.
  2. Dart's runtime type for JSON objects is `_Map<String, dynamic>` or `_Map<dynamic, dynamic>`, whereas JSON test definitions specify generic type names like `"object"`, `"Map"`, `"map"`, `"list"`, `"array"`, `"string"`, `"number"`, etc.

### C. Gesture Execution & Async Timing Issues
- **Symptom:** Rapid interactions (`type`, `tap`, `scroll`) occasionally throw unhandled state errors if widgets are still building or settling.
- **Root Cause:**
  1. `qte_interaction.dart` called `_findTarget(ix)` directly without checking `tester.any(finder)` or awaiting microtasks/settling.
  2. Text entering into editable fields did not ensure the focus was properly requested or that `EditableText` / `TextField` inner nodes were focused before calling `tester.enterText`.

### D. Project Import & Compilation Integrity
- **Symptom:** Workspace compilation errors occurred due to moved imports (`network.dart` and `network_shell.dart` moved from `src/runtime/api/` to `src/platform/api/`).
- **Status:** Resolved in `quantum_image_engine.dart`, `quantum_media_engine.dart`, `quantum_permissions.dart`, `quantum_data_state.dart`, `quantum_domain_builder.dart`, and `quantum.config.dart`.

---

## 2. Planned Technical Enhancements in `lib/sdui_tests/engine`

### Component 1: `qte_render_probe.dart` & Target Resolution
- **Enhancement:** Upgrade `findByTarget` to support multi-layer fallback search:
  1. Try `ValueKey('__qte_testId_${target.value}')`.
  2. Try `ValueKey(target.value)` and `Key(target.value)`.
  3. Try `find.bySemanticsLabel(target.value)`.
  4. Try matching widget text content (`find.text(target.value)` or `find.textContaining(target.value)`).
  5. Try predicate search matching widget properties (`testId`, `key`, `id`, `name`).
- **Benefit:** Ensures 100% target resolution accuracy regardless of how the underlying widget tree renders the SDUI components.

### Component 2: `qte_host_widget.dart` & SDUI Blueprint Key Pre-processing
- **Enhancement:** Implement an automatic node Key Decorator in `QTEHostBuilder` / `_SDUIRenderer`.
  - Traverse the SDUI JSON blueprint recursively before rendering.
  - If a node defines `testId` or `key`, inject explicit `key` metadata so QuantumVM builds the widget with `ValueKey('__qte_testId_${testId}')` and `ValueKey(key)`.

### Component 3: `qte_assertion.dart` & Smart Type / State Matching
- **Enhancement:** Overhaul `stateType` and value matcher logic:
  - Map generic JSON type names (`"object"`, `"map"`, `"dict"`, `"list"`, `"array"`, `"string"`, `"number"`, `"int"`, `"double"`, `"boolean"`, `"bool"`) to Dart type checks (`is Map`, `is List`, `is String`, `is num`, `is int`, `is double`, `is bool`).
  - Gracefully handle `_Map<String, dynamic>` as matching `"object"`, `"Map"`, and `"_Map"`.
  - Enhance numeric equality checks with small float tolerance for coordinates, dimensions, and opacity.

### Component 4: `qte_interaction.dart` & Robust Action Execution
- **Enhancement:**
  - Wrap interaction target lookup with retry/settling logic (`pumpAndSettle` with timeout).
  - Provide descriptive `QTEInteractionResult.fail` error messages instead of unhandled exceptions when targets are missing or disabled.
  - Fix `type` text interaction to auto-focus target inputs (`TextField`, `EditableText`, or custom SDUI text fields) before entering text.

### Component 5: Test Suite Validation (`lib/sdui_tests/tests/*.test.json`)
- **Enhancement:** Audit all sample test JSON files (`button_basic.test.json`, `form_journey.test.json`, `layout_resize.test.json`, `reactive_data.test.json`) to verify schema compliance and assertions.

---

## 3. Verification Plan

### Automated Tests
- Run `flutter test test/sdui_json_tests.dart` to verify all SDUI test files pass cleanly.
- Verify 100% step completion and 100% assertion pass rates across:
  - `button_basic.test.json`
  - `form_journey.test.json`
  - `layout_resize.test.json`
  - `reactive_data.test.json`

### Static Analysis
- Run `dart analyze lib/sdui_tests` to ensure zero lints or analysis errors.

---

## 4. Folder Structure Location
This plan file is maintained directly inside `lib/sdui_tests/plan/SDUI_TESTS_EXECUTION_PLAN.md` per user specification.
