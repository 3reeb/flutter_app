# SDUI Docs — Master Index

This folder is the authoritative skill+contract+instruction reference for the Quantum SDUI runtime.
Every file is dense and real. No padding, no happy-path-only coverage.

## Files

| File | Purpose |
|------|---------|
| [01_JSON_CONTRACT.md](01_JSON_CONTRACT.md) | Canonical JSON shape, colon normalization rules, box vs non-box routing |
| [02_SKILLS_WRITING_TESTS.md](02_SKILLS_WRITING_TESTS.md) | How to write and organize JSON test cases from scratch |
| [03_PERFORMANCE_TESTS.md](03_PERFORMANCE_TESTS.md) | Runtime performance contracts — compile time, render throughput, large trees |
| [04_ISSUE_TESTS.md](04_ISSUE_TESTS.md) | Regression and known-issue test contracts — overflow, binding errors, malformed nodes |
| [05_MEMORY_TESTS.md](05_MEMORY_TESTS.md) | Memory usage contracts — leak detection, scope cleanup, large data binding |
| [06_WIDGET_TESTS.md](06_WIDGET_TESTS.md) | Widget-level JSON contracts — sizing, drag, resize, layout constraints, gestures |
| [07_ACTION_TESTS.md](07_ACTION_TESTS.md) | Action contract — button, gesture, pointer, focus, hover, double-tap, long-press |
| [08_DATA_STATE_TESTS.md](08_DATA_STATE_TESTS.md) | Data and state contract — store, pipeline, repeat, bindings, slice, signals |
| [09_FOLDER_STRUCTURE.md](09_FOLDER_STRUCTURE.md) | Canonical test folder layout and naming conventions |
| [10_RUNTIME_EXECUTION_TESTS.md](10_RUNTIME_EXECUTION_TESTS.md) | Real runtime execution — testing final screen renders, reactive state, and API behaviors |

## Quick Reference — Test Case JSON Shape

```json
{
  "__meta": {
    "id": "unique-kebab-id",
    "title": "One-line human title",
    "description": "Why this test exists and what it catches.",
    "tags": ["category", "subtype"],
    "allowBlank": false
  },
  "input": { "type": "...", "props": {} },
  "env": {},
  "macros": {},
  "expected": { "type": "...", "props": {}, "debugPath": "root" },
  "runtimeAssertions": [
    { "path": "props.someField", "equals": "value" }
  ],
  "runtimeBehavior": {
    "gesture": "drag",
    "description": "Explains runtime consequence of interaction"
  }
}
```

Use `expectError` instead of `expected` when the test must fail:

```json
{
  "expectError": {
    "type": "FormatException",
    "messageContains": "Missing type"
  }
}
```
