# Quantum SDUI — Comprehensive Test Plan
## Master Index (`plan_tests/`)

> **Zero simplification. Zero happy-path only. Zero missing features.**
> Every document here is a production-grade contract that drives real JSON test cases,
> real WidgetTester executionSteps, and real state mutations.

---

## Scope

This plan covers **every layer** of the Quantum SDUI runtime:

| Layer | What is tested |
|-------|---------------|
| JSON Contract | Colon-syntax normalization, type routing, `__subType` injection |
| Compile-time operators | `$let`, `$apply`, `$if`, `$classes`, `$switch`, `$repeat`, `$call`, `$async`, `$machine`, `$portal`, `$watch`, `$try`, `$throttle`, `$debounce`, `$parallel`, `$reactive_map`, `$compose`, `$layout`, `$scope`, `$define`, `$spread` |
| Widget rendering | box:row, box:col, box:scroll, box:wrap, box:grid, box:stack, box:layer, box:shell, box:split, box:aspect |
| Actions | button, gesture, hover, focus, chip, long_press, double_tap |
| Data & State | store_provider, repeat, stream, slice, paginated, table, kanban |
| Hooks | effect, guard, memo, atom, interval, error_boundary |
| System | timer, async, worker, throttle |
| Portals | overlay, drawer, toast, sheet, menu, dropdown |
| Controls | form_scope, tabs, stepper, accordion, machine |
| Fields | text, password, email, toggle, radio, slider, textarea |
| Media | icon, video, avatar, audio, svg_path |
| Decoration | blur, gradient, border, shadow, badge, skeleton |
| Canvas | draw, plot, shader, shape |
| Stream | ws, sse, tick, ring, multiplex |
| Collab | presence, cursor, awareness, lock, patch |
| Visual | chart, animation, scene, overlay, compose |
| Auth flows | Full login widget, logout, session refresh, unauthorized redirect |
| API calls | HTTP GET/POST, encrypted SDUI payload, WebSocket, SSE, error boundaries |
| Table rendering | data:table, data:paginated, column bindings, sort, filter |
| Forms | Full form scope, validation, submit, server errors, field-level errors |
| Navigation | nav.push, nav.pop, nav.replace, guarded routes, back-stack |
| Performance | Large trees, deep trees, wide trees, repeat with 500 items |
| Memory | Scope cleanup, store isolation, no-double-wrap |
| Regression | All known ISS-* bugs pinned with minimal reproduction cases |
| Runtime execution | WidgetTester E2E: tap, enterText, scroll, expectState, expectGeometry |

---

## Files in this folder

| File | What it documents |
|------|------------------|
| [01_NORMALIZATION_PLAN.md](01_NORMALIZATION_PLAN.md) | JSON contract, colon syntax, type routing — 40+ tests |
| [02_COMPILE_TIME_OPERATORS_PLAN.md](02_COMPILE_TIME_OPERATORS_PLAN.md) | All 20 compile-time operators with real inputs/outputs |
| [03_WIDGET_LAYOUT_PLAN.md](03_WIDGET_LAYOUT_PLAN.md) | All box:* subtypes, sizing, drag, resize, rotate, split |
| [04_ACTION_GESTURES_PLAN.md](04_ACTION_GESTURES_PLAN.md) | action:button/gesture/hover/focus/chip/long_press with execution |
| [05_DATA_STATE_PLAN.md](05_DATA_STATE_PLAN.md) | store, repeat, slice, stream, atom, effect, pipeline |
| [06_PORTAL_OVERLAY_PLAN.md](06_PORTAL_OVERLAY_PLAN.md) | overlay, drawer, toast, sheet, menu, dropdown |
| [07_CONTROL_FORMS_PLAN.md](07_CONTROL_FORMS_PLAN.md) | form_scope, tabs, stepper, accordion, full form flows |
| [08_AUTH_LOGIN_LOGOUT_PLAN.md](08_AUTH_LOGIN_LOGOUT_PLAN.md) | Full login widget, logout, session, guarded routes |
| [09_API_CALLS_PLAN.md](09_API_CALLS_PLAN.md) | HTTP, WebSocket, SSE, encrypted SDUI, error boundaries |
| [10_TABLE_RENDERING_PLAN.md](10_TABLE_RENDERING_PLAN.md) | data:table, paginated, sort, filter, kanban |
| [11_NAVIGATION_PLAN.md](11_NAVIGATION_PLAN.md) | nav.push/pop/replace, guards, deep-links, back-stack |
| [12_HOOKS_SYSTEM_PLAN.md](12_HOOKS_SYSTEM_PLAN.md) | effect, atom, memo, guard, interval, error_boundary, timer |
| [13_FIELD_CORE_PLAN.md](13_FIELD_CORE_PLAN.md) | All field subtypes: password, email, slider, toggle, radio |
| [14_MEDIA_DECORATION_PLAN.md](14_MEDIA_DECORATION_PLAN.md) | media:icon/video/avatar, decoration:blur/gradient/shadow |
| [15_PERFORMANCE_PLAN.md](15_PERFORMANCE_PLAN.md) | 50/100/500 child trees, depth guard, macro expansion |
| [16_MEMORY_REGRESSION_PLAN.md](16_MEMORY_REGRESSION_PLAN.md) | Scope cleanup, leak detection, all ISS-* regressions |
| [17_RUNTIME_EXECUTION_PLAN.md](17_RUNTIME_EXECUTION_PLAN.md) | Full E2E WidgetTester flows: login to submit to state to navigate |
| [18_ENCRYPTION_SECURITY_PLAN.md](18_ENCRYPTION_SECURITY_PLAN.md) | AES-256-GCM, HMAC, replay protection, key rotation |
| [19_JSON_TEST_CASES_CATALOG.md](19_JSON_TEST_CASES_CATALOG.md) | Full catalog of all planned JSON test files with IDs |
| [20_CI_COMMANDS_REFERENCE.md](20_CI_COMMANDS_REFERENCE.md) | All flutter test commands, filters, and CI gates |

---

## Test case naming (canonical)

```
<category>_<NNN>_<NNN>.json
```

Place all new JSON test cases in:
```
lib/test/generated/sdui_json_runtime_behavior_test/cases/<category>/
```

New categories introduced by this plan:

| Category | Folder name | Examples |
|----------|-------------|---------|
| Auth flows | auth/ | auth_001_001.json — full login widget |
| API | api/ | api_001_001.json — HTTP GET SDUI payload |
| Table | table/ | table_001_001.json — data:table column binding |
| Navigation | nav/ | nav_001_001.json — nav.push with args |
| Portal | portal/ | portal_001_001.json — overlay trigger |
| Forms | forms/ | forms_001_001.json — full form_scope |
| Security | security/ | security_001_001.json — encrypted payload |

---

## Priority matrix

| Priority | Count planned | What |
|----------|--------------|------|
| critical | 80+ | Type routing, state wrapping, form submit, login, auth guards |
| high | 120+ | All action handlers, field validation, table paging, portal triggers |
| medium | 80+ | Decorations, media, canvas, advanced operators |
| low | 40+ | Edge cases, cosmetic props, optional fields |

**Total: 320+ planned test cases across all categories.**

---

## How to run

```bash
# All tests
flutter test lib/test/generated/sdui_json_runtime_behavior_test/

# Only new auth tests
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "auth"

# Only new portal tests
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "portal"

# Only critical priority
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "critical"

# Only execution tests (WidgetTester E2E)
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "execution"
```
