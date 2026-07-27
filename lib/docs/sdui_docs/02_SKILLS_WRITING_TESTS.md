# 02 — Skills: Writing Tests

How to author, name, and organize SDUI JSON test cases so the runner picks them up automatically.

---

## 1. Test case anatomy

Every file must be a single JSON object with these top-level keys:

```
__meta            required — identification and documentation
input             required — the SDUI JSON fed to QLCompiler.compile()
env               optional — top-level env object passed to the compiler
macros            optional — named macros available during compilation
expected          required unless expectError present — exact snapshot of blueprint.toJson()
expectError       required unless expected present — { type, messageContains }
runtimeAssertions optional — path-based precise value checks on the compiled output
runtimeBehavior   optional — documentation for widget-level gesture/drag/resize/rotate outcomes
```

**Never** include both `expected` and `expectError` in the same file.

---

## 2. `__meta` fields

```json
{
  "__meta": {
    "id"          : "widget-slider-width-001",
    "title"       : "Slider width is constrained to parent",
    "description" : "A slider inside a fixed-width column must not overflow. This catches the unconstrained-width bug from issue #412.",
    "tags"        : ["widget", "field", "slider", "sizing"],
    "allowBlank"  : false,
    "priority"    : "critical",
    "issue"       : "GH-412"
  }
}
```

| Field | Required | Purpose |
|---|---|---|
| `id` | yes | Unique ID used by the runner to deduplicate |
| `title` | yes | Human-readable test name |
| `description` | yes | Why this test exists; what regression it prevents |
| `tags` | yes | Array of strings for filtering and grouping |
| `allowBlank` | yes | Usually false; true only for empty-output tests |
| `priority` | no | `"critical"`, `"high"`, `"medium"`, `"low"` |
| `issue` | no | Reference to issue ID if it is a regression test |

---

## 3. runtimeAssertions

The runner evaluates these assertions against the actual compiled JSON output. Use them to verify specific property values, deeply nested items, and lengths.

```json
"runtimeAssertions": [
  { "path": "props.draggable",           "equals": true },
  { "path": "props.dragAxis",            "oneOf": ["x", "y", "both"] },
  { "path": "props.minWidth",            "greaterThan": 0 },
  { "path": "props.dragHandleSelector",  "startsWith": "." },
  { "path": "children.length",           "equals": 3 }
]
```

See [06_WIDGET_TESTS.md](06_WIDGET_TESTS.md) for full operator list.

---

## 4. runtimeBehavior

This object documents the actual execution-time consequence of the JSON node. The test runner prints it, but doesn't assert on it programmatically.

```json
"runtimeBehavior": {
  "gesture":         "drag",
  "description":     "Dragging 100px right gives offsetX:100",
  "axis":            "x",
  "expectedOffsetX": 100
}
```

---

## 5. Naming convention

File: `<category>_<NNN>_<NNN>.json`

Examples:
- `widget_001_001.json` — widget sizing, test #1
- `action_005_005.json` — action/gesture, test #5
- `perf_001_001.json` — performance, test #1
- `memory_003_003.json` — memory, test #3
- `issue_002_002.json` — regression, test #2

The double number `NNN_NNN` follows the existing convention and allows future grouping.
IDs within a folder must be unique.

---

## 6. Folder layout

```
cases/
  basic/              — minimal nodes, normalization, raw strings
  compile_time/       — operators: $let, $apply, $if, $classes, $switch
  operators/          — all other authoring operators
  state_and_pipeline/ — store, pipeline, repeat, slice
  nested/             — complex multi-layer compositions
  failure/            — expected compile failures
  widget/             — sizing, dragging, resizing, layout constraints
  action/             — button, gesture, hover, long_press, focus
  data_state/         — data binding, signals, stores, scopes
  performance/        — compile-time throughput, large trees
  memory/             — leak, scope cleanup, large data binding
  issue/              — regressions pinned to issue IDs
```

---

## 7. Step-by-step: writing a new test

1. **Pick a gap** — identify a behavior not covered by existing cases.
2. **Write the input** — author the minimal JSON that exercises the behavior.
3. **Derive the expected** — trace through the normalization rules manually or run the compiler once and pin the output. Be sure your expected shows **RESOLVED** values (e.g. `$let` replacements expanded) not templates!
4. **Write runtimeAssertions** — add targeted path checks for the most important props.
5. **Write runtimeBehavior** — add documentation describing the widget behavior.
6. **Fill `__meta`** — unique id, clear title, honest description.
7. **Place in the right folder** — match the category.
8. **Add to README** — one line in the folder's README.md.
9. **Run** — `flutter test lib/test/generated/sdui_json_runtime_behavior_test/` and confirm the test passes and prints output correctly.

---

## 8. Complexity ladder

Start simple, grow complexity:

| Level | What to test |
|---|---|
| L0 | Bare string, bare number, null handling |
| L1 | Single node with one prop |
| L2 | Single node with props + style |
| L3 | Node with children (2–3 levels) |
| L4 | Operator (`$let`, `$apply`) on a small tree |
| L5 | State root wrapping with initialState |
| L6 | Data repeat with state binding |
| L7 | Action node triggering a named action |
| L8 | Portal overlay triggered by action |
| L9 | Multi-root page combining layout, data, portals, and hooks |
| L10 | Edge case / regression / error boundary |

Write tests in order — a green L5 builds confidence before attempting L8.

---

## 9. Common mistakes

| Mistake | Fix |
|---|---|
| Missing `debugPath` in `expected` | Every node in `expected` must have `debugPath` |
| Forgetting `props: {}` on box nodes | The VM always emits props, even if empty |
| Using `type: "action:button"` in expected | Expected must have `type: "action"` + `props.__subType: "button"` |
| Omitting `__subType` in expected for non-box colon nodes | VM injects it; your expected must include it |
| Comparing only the first level of children | `_diffJson` is recursive; every nested node is checked |
| Using unresolved bindings in `expected` for compile-time ops | `$let` and `$classes` resolve at compile time. Use the resolved string in `expected`! |
| Duplicate `id` across files | IDs are used to deduplicate; must be globally unique |

---

## 10. Macro and env usage

```json
{
  "macros": {
    "card": {
      "type": "box:col",
      "style": "rounded-2 shadow-1 p-4"
    }
  },
  "env": {
    "theme": "dark",
    "locale": "en"
  },
  "input": {
    "$call": "card",
    "children": [
      { "type": "text", "props": { "text": "Hello" } }
    ]
  }
}
```

Macros let you define reusable nodes. Env provides global variables available in bindings.

---

## 11. Writing a failure test

```json
{
  "__meta": {
    "id": "failure-null-type",
    "title": "null type field throws FormatException",
    "description": "A node with type=null must fail with a clear error, not silently render.",
    "tags": ["failure", "null", "guard"],
    "allowBlank": false
  },
  "input": { "type": null, "props": {} },
  "expectError": {
    "type": "FormatException",
    "messageContains": "type"
  }
}
```

The runner will assert that:
- A `FormatException` is thrown (matched by `runtimeType.toString()`)
- The message contains `"type"`
