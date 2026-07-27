# 03 — Performance Tests

Contracts and JSON patterns for measuring and protecting runtime compile performance.

---

## What "performance" means in this test suite

Performance tests do NOT run timers or benchmarks inside JSON.
Instead they define **structural contracts** that prevent regressions in compilation speed:

1. **Large tree contracts** — trees above N nodes must compile without error (no O(n²) blowup).
2. **Deep tree contracts** — trees approaching the AST overflow guard must compile up to N−1 depth and fail at guard depth.
3. **Wide tree contracts** — single node with M children must compile in one pass.
4. **Repeat-large contracts** — data repeat nodes with large item counts must normalize correctly.
5. **Macro expansion contracts** — deeply nested macro calls must not stack-overflow.

Actual timing is measured by the benchmark harness in CI. These JSON files pin **correctness under load**, not wall-clock time.

---

## Folder: `cases/performance/`

Naming: `perf_NNN_NNN.json`

### Level 1 — Wide tree (50 children)

```json
{
  "__meta": {
    "id": "perf-wide-50-children",
    "title": "50 sibling text nodes compile without error",
    "description": "A row with 50 direct children must compile fully. Catches any O(n) per-child allocation bug.",
    "tags": ["performance", "wide", "children"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:row",
    "style": "gap-2 flex-wrap",
    "children": [
      { "type": "text", "props": { "text": "item-01" } },
      { "type": "text", "props": { "text": "item-02" } },
      "... (repeat to 50)"
    ]
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "style": "gap-2 flex-wrap",
    "children": [
      { "type": "text", "props": { "text": "item-01" }, "debugPath": "root[0]" },
      "..."
    ]
  }
}
```

### Level 2 — Deep tree (at guard boundary minus 1)

The AST overflow guard fires at depth 129.
Test at depth 128 (should pass) and depth 130 (should throw):

**perf-deep-128-passes.json** → `expected` snapshot with 128 levels
**perf-deep-130-fails.json** → `expectError: { type: "FormatException", messageContains: "overflow" }`

### Level 3 — Repeat with 500 item template

```json
{
  "__meta": {
    "id": "perf-repeat-500-items",
    "title": "data:repeat template with 500-item schema compiles correctly",
    "description": "The repeat node must normalize props and pass through without expanding items at compile time.",
    "tags": ["performance", "data", "repeat"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.largeList}",
      "as": "item",
      "indexAs": "idx"
    },
    "children": [
      {
        "type": "box:row",
        "style": "gap-2",
        "children": [
          { "type": "text", "props": { "text": "${item.id}" } },
          { "type": "text", "props": { "text": "${item.label}" } }
        ]
      }
    ]
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.largeList}",
      "as": "item",
      "indexAs": "idx"
    },
    "debugPath": "root",
    "children": [
      {
        "type": "box:row",
        "props": {},
        "debugPath": "root[0]",
        "style": "gap-2",
        "children": [
          { "type": "text", "props": { "text": "${item.id}" }, "debugPath": "root[0][0]" },
          { "type": "text", "props": { "text": "${item.label}" }, "debugPath": "root[0][1]" }
        ]
      }
    ]
  }
}
```

### Level 4 — Macro expansion depth

```json
{
  "__meta": {
    "id": "perf-macro-nested-5-levels",
    "title": "Macro called 5 levels deep compiles without stack overflow",
    "description": "Recursive macro expansion must be guarded. 5 levels is safe; test ensures it produces correct output.",
    "tags": ["performance", "macro", "expansion"],
    "allowBlank": false
  },
  "macros": {
    "section": {
      "type": "box:col",
      "style": "p-4 gap-2"
    }
  },
  "input": {
    "$call": "section",
    "children": [
      { "$call": "section", "children": [
        { "$call": "section", "children": [
          { "type": "text", "props": { "text": "deep" } }
        ]}
      ]}
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "style": "p-4 gap-2",
    "children": [
      {
        "type": "box:col",
        "props": {},
        "debugPath": "root[0]",
        "style": "p-4 gap-2",
        "children": [
          {
            "type": "box:col",
            "props": {},
            "debugPath": "root[0][0]",
            "style": "p-4 gap-2",
            "children": [
              { "type": "text", "props": { "text": "deep" }, "debugPath": "root[0][0][0]" }
            ]
          }
        ]
      }
    ]
  }
}
```

---

## What to measure externally (not in JSON)

Run these benchmarks in the Dart benchmark harness, not in JSON test files:

| Benchmark | Target |
|---|---|
| Compile a 10-node tree | < 1 ms |
| Compile a 100-node tree | < 5 ms |
| Compile a 500-node tree | < 25 ms |
| Compile a 1000-node tree | < 100 ms |
| `$let` substitution (50 bindings) | < 2 ms overhead |
| Macro expansion (20 unique macros) | < 3 ms overhead |

If any benchmark regresses by > 20%, add a JSON regression test that pins the structural contract.

---

## CI check

After any change to `quantum_vm.dart` or any omni-core, run:

```bash
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "perf-"
```

This runs only the performance-tagged cases and fails fast on structural regressions.
