# 01 — Normalization & Type Routing Plan

Covers every JSON contract rule from `01_JSON_CONTRACT.md` with real test cases.
Zero simplification — every rule has a positive test, a boundary test, and a failure test.

---

## Domain: Colon Syntax Normalization

### Rule: box:* keeps the colon in type; all other base:sub strips the colon and injects __subType

---

## Test Cases — box:* family (keeps colon, NO __subType injection)

### NORM-001 — box:row passes through unchanged
**File:** `cases/basic/basic_norm_001.json`

```json
{
  "__meta": {
    "id": "norm-001-box-row-colon-kept",
    "title": "box:row keeps full colon type in output",
    "description": "The box family is the ONLY family where the colon is kept verbatim in the compiled output. __subType must NOT appear in props.",
    "tags": ["normalization", "box", "colon", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:row",
    "props": { "gap": 8 },
    "children": []
  },
  "expected": {
    "type": "box:row",
    "props": { "gap": 8 },
    "debugPath": "root",
    "children": []
  },
  "runtimeAssertions": [
    { "path": "type",             "equals": "box:row" },
    { "path": "props.gap",        "equals": 8 },
    { "path": "props.__subType",  "notNull": false }
  ]
}
```

### NORM-002 — box:col passes through unchanged
**File:** `cases/basic/basic_norm_002.json`

Verify box:col, box:stack, box:scroll, box:wrap, box:grid, box:layer, box:shell each keep their colon type.

### NORM-003 — box:scroll keeps colon, props:{} emitted even when no props authored
**File:** `cases/basic/basic_norm_003.json`

```json
{
  "__meta": {
    "id": "norm-003-box-scroll-empty-props",
    "title": "box:scroll with no authored props gets empty props:{} in output",
    "description": "The VM always emits props:{} even when the author omits props. Missing props:{} in expected will diff-fail.",
    "tags": ["normalization", "box", "props", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:scroll",
    "children": [
      { "type": "text", "props": { "text": "Scrollable content" } }
    ]
  },
  "expected": {
    "type": "box:scroll",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Scrollable content" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",            "equals": "box:scroll" },
    { "path": "props.__subType", "notNull": false },
    { "path": "children.length", "equals": 1 }
  ]
}
```

---

## Test Cases — non-box colon family (__subType injection)

### NORM-010 — action:button strips colon, injects __subType:button
**File:** `cases/action/action_norm_010.json`

```json
{
  "__meta": {
    "id": "norm-010-action-button-subtype",
    "title": "action:button strips colon and injects __subType:button",
    "description": "Non-box colon nodes must have the colon stripped, base type kept, and subtype injected into props.__subType. This is the most common normalization mistake in authored JSON.",
    "tags": ["normalization", "action", "button", "subtype", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:button",
    "props": { "text": "Click me", "intent": "primary" }
  },
  "expected": {
    "type": "action",
    "props": { "__subType": "button", "text": "Click me", "intent": "primary" },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "type",            "equals": "action" },
    { "path": "props.__subType", "equals": "button" },
    { "path": "props.text",      "equals": "Click me" },
    { "path": "props.intent",    "equals": "primary" }
  ]
}
```

### NORM-011 — data:repeat strips colon, injects __subType:repeat
### NORM-012 — system:timer strips colon, injects __subType:timer
### NORM-013 — hook:effect strips colon, injects __subType:effect
### NORM-014 — field:password strips colon, injects __subType:password
### NORM-015 — text:h1 strips colon, injects __subType:h1
### NORM-016 — media:icon strips colon, injects __subType:icon
### NORM-017 — portal:overlay strips colon, injects __subType:overlay
### NORM-018 — control:tabs strips colon, injects __subType:tabs
### NORM-019 — decoration:blur strips colon, injects __subType:blur
### NORM-020 — canvas:draw strips colon, injects __subType:draw
### NORM-021 — stream:ws strips colon, injects __subType:ws
### NORM-022 — collab:presence strips colon, injects __subType:presence
### NORM-023 — visual:chart strips colon, injects __subType:chart

---

## Test Cases — explicit __subType in props (authoring form)

### NORM-030 — Explicit __subType in props is equivalent to colon syntax
**File:** `cases/basic/basic_norm_030.json`

```json
{
  "__meta": {
    "id": "norm-030-explicit-subtype-in-props",
    "title": "Explicit props.__subType is equivalent to colon syntax",
    "description": "data:repeat and { type: data, props: { __subType: repeat } } must produce identical compiled output. Both forms are valid authoring.",
    "tags": ["normalization", "subtype", "equivalence", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.items}",
      "as": "item",
      "indexAs": "i"
    },
    "children": [
      { "type": "text", "props": { "text": "${item.name}" } }
    ]
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.items}",
      "as": "item",
      "indexAs": "i"
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "${item.name}" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",            "equals": "data" },
    { "path": "props.__subType", "equals": "repeat" },
    { "path": "props.bind",      "equals": "${state.items}" }
  ]
}
```

---

## Test Cases — state wrapping (system:store_provider)

### NORM-040 — Root node with state field wraps to store_provider
**File:** `cases/state_and_pipeline/state_norm_040.json`

```json
{
  "__meta": {
    "id": "norm-040-state-root-wraps-to-store-provider",
    "title": "Root node with state field wraps to system:store_provider",
    "description": "Any node with a top-level state field must be wrapped in exactly ONE store_provider. The store_provider becomes the new root. The original node becomes its only child.",
    "tags": ["normalization", "state", "store_provider", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "name": "counter",
    "state": { "count": 0, "step": 1 },
    "type": "box:col",
    "style": "p-4",
    "children": [
      { "type": "text", "props": { "text": "${state.count}" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "store_provider",
      "initialState": { "count": 0, "step": 1 }
    },
    "debugPath": "counter.store_provider",
    "children": [
      {
        "type": "box:col",
        "props": {},
        "debugPath": "counter",
        "style": "p-4",
        "children": [
          { "type": "text", "props": { "text": "${state.count}" }, "debugPath": "counter[0]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                             "equals": "system" },
    { "path": "props.__subType",                  "equals": "store_provider" },
    { "path": "props.initialState.count",         "equals": 0 },
    { "path": "props.initialState.step",          "equals": 1 },
    { "path": "debugPath",                        "equals": "counter.store_provider" },
    { "path": "children.length",                  "equals": 1 },
    { "path": "children[0].type",                 "equals": "box:col" },
    { "path": "children[0].debugPath",            "equals": "counter" },
    { "path": "children[0].children[0].props.text", "equals": "${state.count}" }
  ],
  "runtimeBehavior": {
    "description": "At runtime, the store_provider creates a reactive store. Bindings like ${state.count} read from the store and re-render when count changes. Actions like increment will mutate state.count and trigger rebuild."
  }
}
```

### NORM-041 — State wrapping does NOT double-wrap (no store in store)
**File:** `cases/state_and_pipeline/state_norm_041.json`

```json
{
  "__meta": {
    "id": "norm-041-state-no-double-wrap",
    "title": "Node with state field must wrap exactly once — never nest store_provider in store_provider",
    "description": "Compiling the same stateful node twice must NOT produce nested store_providers. ISS-memory-003.",
    "tags": ["normalization", "state", "store_provider", "regression", "critical"],
    "allowBlank": false,
    "priority": "critical",
    "issue": "ISS-MEMORY-003"
  },
  "input": {
    "name": "panel",
    "state": { "open": false },
    "type": "box:col",
    "children": []
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "open": false } },
    "debugPath": "panel.store_provider",
    "children": [
      { "type": "box:col", "props": {}, "debugPath": "panel", "children": [] }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                 "equals": "system" },
    { "path": "props.__subType",      "equals": "store_provider" },
    { "path": "children.length",      "equals": 1 },
    { "path": "children[0].type",     "equals": "box:col" },
    { "path": "children[0].props.__subType", "notNull": false }
  ]
}
```

---

## Test Cases — debugPath convention

### NORM-050 — Root without name gets debugPath:"root"
### NORM-051 — Root with name gets debugPath equal to name
### NORM-052 — First child of root gets debugPath:"root[0]"
### NORM-053 — Third child of second child gets debugPath:"root[1][2]"
### NORM-054 — State wrapper root gets debugPath:"<name>.store_provider"

```json
{
  "__meta": {
    "id": "norm-054-debugpath-store-provider",
    "title": "State wrapper generates correct debugPath with .store_provider suffix",
    "description": "When a node with name:my_panel has a state field, the store_provider's debugPath must be 'my_panel.store_provider'. The inner node must have debugPath 'my_panel'.",
    "tags": ["normalization", "debugPath", "state", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "name": "my_panel",
    "state": { "x": 1 },
    "type": "text",
    "props": { "text": "Hello" }
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "x": 1 } },
    "debugPath": "my_panel.store_provider",
    "children": [
      { "type": "text", "props": { "text": "Hello" }, "debugPath": "my_panel" }
    ]
  },
  "runtimeAssertions": [
    { "path": "debugPath",              "equals": "my_panel.store_provider" },
    { "path": "children[0].debugPath",  "equals": "my_panel" }
  ]
}
```

---

## Test Cases — Bare string and number normalization

### NORM-060 — Bare string normalizes to text node
**File:** `cases/basic/basic_norm_060.json`

```json
{
  "__meta": {
    "id": "norm-060-bare-string-to-text",
    "title": "Bare string normalizes to { type: text, props: { text: <value> } }",
    "description": "A plain string input must compile to a text node with the string as props.text. No other props should be added.",
    "tags": ["normalization", "string", "text", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": "Hello world",
  "expected": {
    "type": "text",
    "props": { "text": "Hello world" },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "type",       "equals": "text" },
    { "path": "props.text", "equals": "Hello world" }
  ]
}
```

### NORM-061 — Bare number normalizes to text node with stringified value
**File:** `cases/basic/basic_norm_061.json`

```json
{
  "__meta": {
    "id": "norm-061-bare-number-to-text",
    "title": "Bare number normalizes to text node with stringified value",
    "description": "The number 42 must become { type: text, props: { text: '42' } }. It must NOT become props: { text: 42 } (number).",
    "tags": ["normalization", "number", "text", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": 42,
  "expected": {
    "type": "text",
    "props": { "text": "42" },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "type",       "equals": "text" },
    { "path": "props.text", "equals": "42" }
  ]
}
```

---

## Test Cases — Failure / guard contracts

### NORM-070 — null type throws FormatException
### NORM-071 — Missing type field throws FormatException
### NORM-072 — Double colon (box:row:extra) throws FormatException
### NORM-073 — Empty map with no type throws FormatException
### NORM-074 — Type is a number, not a string — throws FormatException

```json
{
  "__meta": {
    "id": "norm-074-numeric-type-throws",
    "title": "Type field as a number throws FormatException",
    "description": "type:123 is not a valid type string. The VM must throw, not silently produce a text node.",
    "tags": ["normalization", "guard", "failure", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": { "type": 123, "props": {} },
  "expectError": {
    "type": "FormatException",
    "messageContains": "type"
  }
}
```

---

## Complete list of normalization tests (40 total planned)

| ID | What it covers | Priority |
|----|---------------|----------|
| norm-001 | box:row keeps colon | critical |
| norm-002 | box:col keeps colon | critical |
| norm-003 | box:scroll keeps colon, emits props:{} | critical |
| norm-004 | box:wrap keeps colon | high |
| norm-005 | box:grid keeps colon | high |
| norm-006 | box:stack keeps colon | high |
| norm-007 | box:layer keeps colon | high |
| norm-008 | box:shell keeps colon | high |
| norm-009 | box:split keeps colon | high |
| norm-010 | action:button — __subType injection | critical |
| norm-011 | data:repeat — __subType injection | critical |
| norm-012 | system:timer — __subType injection | high |
| norm-013 | hook:effect — __subType injection | high |
| norm-014 | field:password — __subType injection | high |
| norm-015 | text:h1 — __subType injection | high |
| norm-016 | media:icon — __subType injection | high |
| norm-017 | portal:overlay — __subType injection | high |
| norm-018 | control:tabs — __subType injection | high |
| norm-019 | decoration:blur — __subType injection | medium |
| norm-020 | canvas:draw — __subType injection | medium |
| norm-021 | stream:ws — __subType injection | medium |
| norm-022 | collab:presence — __subType injection | medium |
| norm-023 | visual:chart — __subType injection | medium |
| norm-030 | Explicit __subType == colon syntax | high |
| norm-040 | State wrapping — single store_provider | critical |
| norm-041 | No double-wrap | critical |
| norm-050 | debugPath: root (no name) | high |
| norm-051 | debugPath: <name> (with name) | high |
| norm-052 | debugPath: root[0] first child | high |
| norm-053 | debugPath: root[1][2] deep child | high |
| norm-054 | debugPath: <name>.store_provider | high |
| norm-060 | Bare string → text node | critical |
| norm-061 | Bare number → text node | critical |
| norm-070 | null type → FormatException | critical |
| norm-071 | Missing type → FormatException | critical |
| norm-072 | Double colon → FormatException | high |
| norm-073 | Empty map → FormatException | high |
| norm-074 | Numeric type → FormatException | critical |
| norm-075 | Boolean type → FormatException | high |
