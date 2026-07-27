# 05 — Memory Tests

Contracts for detecting memory leaks, scope pollution, and unbounded allocation in the Quantum runtime.

---

## Why JSON tests can catch memory bugs

JSON tests compile a node tree and assert the output shape.
Memory bugs show up as:

1. **Scope pollution** — a `$let` or `$scope` from one tree leaks into the next compile call.
2. **Macro cache bloat** — macros registered in one test persist in the next (if the registry is a singleton).
3. **State wrapper accumulation** — multiple `state` nodes on the same name create stacked store_providers.
4. **Children reference sharing** — two compiled trees sharing the same mutable children list.

The JSON test runner calls `QLCompiler.compile()` once per test in isolation.
Memory tests verify that each call produces a *clean* output with no leftover artifacts.

---

## Folder: `cases/memory/`

Naming: `memory_NNN_NNN.json`

---

## Pattern 1 — Scope isolation: `$let` must not bleed

```json
{
  "__meta": {
    "id": "memory-001-let-scope-isolation",
    "title": "$let variables are local to the node tree",
    "description": "Variables defined in $let must not persist to sibling or parent scopes. Each compile call starts clean.",
    "tags": ["memory", "scope", "let"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "$let": { "label": "Card A" },
    "children": [
      { "type": "text", "props": { "text": "{{label}}" } },
      {
        "type": "box:row",
        "children": [
          { "type": "text", "props": { "text": "{{label}}" } }
        ]
      }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Card A" }, "debugPath": "root[0]" },
      {
        "type": "box:row",
        "props": {},
        "debugPath": "root[1]",
        "children": [
          { "type": "text", "props": { "text": "Card A" }, "debugPath": "root[1][0]" }
        ]
      }
    ]
  }
}
```

### What this proves
- `{{label}}` resolves to `"Card A"` inside the tree.
- `{{label}}` in the sibling row still resolves (scope is inherited downward, not leaked sideways).
- A second compile call with a *different* tree would NOT see `label`.

---

## Pattern 2 — Macro registry does not grow between calls

```json
{
  "__meta": {
    "id": "memory-002-macro-isolation",
    "title": "Macros defined in one compile call are not visible in the next",
    "description": "If the macro registry is a singleton without cleanup, macros leak across tests. This test ensures the output contains no macro-expanded artifacts that don't belong to the input.",
    "tags": ["memory", "macro", "isolation"],
    "allowBlank": false,
    "priority": "high"
  },
  "macros": {
    "pill": {
      "type": "box:row",
      "style": "rounded-full px-3 py-1"
    }
  },
  "input": {
    "$call": "pill",
    "children": [
      { "type": "text", "props": { "text": "Tag" } }
    ]
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "style": "rounded-full px-3 py-1",
    "children": [
      { "type": "text", "props": { "text": "Tag" }, "debugPath": "root[0]" }
    ]
  }
}
```

---

## Pattern 3 — Store provider does not double-wrap same name

```json
{
  "__meta": {
    "id": "memory-003-store-no-double-wrap",
    "title": "Single state field produces exactly one store_provider",
    "description": "A node with state must be wrapped in exactly one system:store_provider. Double wrapping indicates a registration leak.",
    "tags": ["memory", "state", "store", "wrap"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "name": "counter",
    "state": { "count": 0 },
    "type": "text",
    "props": { "text": "${state.count}" }
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "store_provider",
      "initialState": { "count": 0 }
    },
    "debugPath": "counter.store_provider",
    "children": [
      {
        "type": "text",
        "props": { "text": "${state.count}" },
        "debugPath": "counter"
      }
    ]
  }
}
```

---

## Pattern 4 — Large `$let` dictionary does not survive the compile call

```json
{
  "__meta": {
    "id": "memory-004-large-let-cleanup",
    "title": "50-variable $let dictionary resolves cleanly and leaves no residue",
    "description": "A large let dictionary must resolve all references and produce a clean output without carrying the dictionary forward.",
    "tags": ["memory", "let", "large"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "$let": {
      "v01": "a", "v02": "b", "v03": "c", "v04": "d", "v05": "e",
      "v06": "f", "v07": "g", "v08": "h", "v09": "i", "v10": "j"
    },
    "children": [
      { "type": "text", "props": { "text": "{{v01}}-{{v10}}" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "a-j" }, "debugPath": "root[0]" }
    ]
  }
}
```

---

## Pattern 5 — `data:repeat` template children are not shared by reference

```json
{
  "__meta": {
    "id": "memory-005-repeat-template-copy",
    "title": "repeat template children are independent copies, not shared references",
    "description": "If the VM reuses the same child list object across repeat iterations, mutating one item corrupts all. The compiled output must be a clean snapshot.",
    "tags": ["memory", "data", "repeat", "reference"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.list}",
      "as": "row",
      "indexAs": "i"
    },
    "children": [
      { "type": "text", "props": { "text": "${row.name}" } }
    ]
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.list}",
      "as": "row",
      "indexAs": "i"
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "${row.name}" }, "debugPath": "root[0]" }
    ]
  }
}
```

---

## Pattern 6 — `hook:scope` does not leak data to parent scope

```json
{
  "__meta": {
    "id": "memory-006-hook-scope-isolation",
    "title": "hook:scope data does not leak to parent node",
    "description": "A hook:scope creates a local data envelope. Its internal data must not be visible to the parent or siblings.",
    "tags": ["memory", "hook", "scope", "isolation"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "children": [
      {
        "type": "hook",
        "props": { "__subType": "scope", "data": { "secret": "inner" } },
        "children": [
          { "type": "text", "props": { "text": "${secret}" } }
        ]
      },
      { "type": "text", "props": { "text": "outer-has-no-secret" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      {
        "type": "hook",
        "props": { "__subType": "scope", "data": { "secret": "inner" } },
        "debugPath": "root[0]",
        "children": [
          { "type": "text", "props": { "text": "${secret}" }, "debugPath": "root[0][0]" }
        ]
      },
      { "type": "text", "props": { "text": "outer-has-no-secret" }, "debugPath": "root[1]" }
    ]
  }
}
```

---

## External memory checks (not JSON)

Run these in Dart or using `flutter drive` with memory profiling:

| Check | Target |
|---|---|
| Compile 1000 trees sequentially, measure heap growth | < 5 MB net growth |
| Compile tree with 500-item repeat, force GC, measure retained | < 2 MB |
| Register 100 macros, compile empty node, measure retained macro store | 0 MB growth if not used |
| Compile store-wrapped tree, dispose, measure retained store | 0 references retained |

If any check fails, file an issue and add a JSON regression test in `cases/issue/`.
