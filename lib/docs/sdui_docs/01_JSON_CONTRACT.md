# 01 — JSON Contract

The single source of truth for what the Quantum VM accepts and normalizes.
Read this before writing any test or building any feature.

---

## 1. Canonical node shape

Every node the VM accepts must be one of:
- A plain **string** → normalized to `{ type: "text", props: { text: <value> } }`
- A **number** → normalized to `{ type: "text", props: { text: "<value>" } }`
- A **node object** with a `type` field

```json
{
  "type"      : "box:row",
  "props"     : { "gap": 16 },
  "style"     : "p-4 items-center",
  "children"  : [],
  "slots"     : {},
  "name"      : "optional-scope-name",
  "slot"      : "optional-slot-key",
  "env"       : {},
  "debugPath" : "root"
}
```

Fields `name`, `slot`, `env`, `debugPath` are optional in authoring JSON.
The VM injects `debugPath` during compilation.

---

## 2. Colon syntax normalization

The VM splits `type` on `:` and applies these rules:

| Input type | Behavior | Output type | props.__subType |
|---|---|---|---|
| `box:row` | box family — keeps colon | `box:row` | _(none)_ |
| `box:col` | box family — keeps colon | `box:col` | _(none)_ |
| `box:*` | any box subtype | `box:*` | _(none)_ |
| `action:button` | non-box colon → subtype injected | `action` | `"button"` |
| `data:repeat` | non-box colon | `data` | `"repeat"` |
| `system:timer` | non-box colon | `system` | `"timer"` |
| `hook:effect` | non-box colon | `hook` | `"effect"` |
| `text` (no colon) | no change | `text` | _(none)_ |

**Rule**: `box:*` is the ONLY family that keeps the colon in the output type.
All other `base:subtype` forms strip the colon and push subtype into `props.__subType`.

---

## 3. Explicit `props.__subType` (authoring form)

The runtime also accepts explicit `__subType` in props directly:

```json
{
  "type": "data",
  "props": {
    "__subType": "repeat",
    "bind": "${state.items}",
    "as": "item",
    "indexAs": "index"
  }
}
```

This is equivalent to using `type: "data:repeat"`.

---

## 4. State root wrapping

If a node has a top-level `state` field, the VM wraps it in a `system:store_provider`:

```json
{
  "name": "my_panel",
  "state": { "count": 0 },
  "type": "text",
  "props": { "text": "Hello" }
}
```

Compiles to:

```json
{
  "type": "system",
  "props": { "__subType": "store_provider", "initialState": { "count": 0 } },
  "debugPath": "my_panel.store_provider",
  "children": [
    { "type": "text", "props": { "text": "Hello" }, "debugPath": "my_panel" }
  ]
}
```

---

## 5. Operators (compile-time transforms)

These are stripped from the output. They exist only in authoring JSON:

| Operator | What it does |
|---|---|
| `$let` | Defines local variables; substituted via `{{varName}}` in string props |
| `$classes` | Defines class alias tokens; substituted via `@className` in style strings |
| `$if` | Conditional inclusion of a node |
| `$repeat` | Inline repeat (not data-core repeat) |
| `$call` | Macro invocation |
| `$switch` | Multi-branch selection |
| `$apply` | Merges props and style into the first child |
| `$spread` | Spread multiple nodes into parent children |
| `$scope` | Pushes a new data scope |
| `$define` | Defines a named component/template |
| `$async` | Async data fetch wrapper |
| `$machine` | State machine declaration |
| `$portal` | Portal declaration |
| `$watch` | Reactive binding declaration |
| `$try` | Try/catch error boundary |
| `$throttle` | Throttled action |
| `$debounce` | Debounced action |
| `$parallel` | Parallel action execution |
| `$reactive_map` | Reactive map transform |
| `$compose` | Compose multiple nodes |
| `$layout` | Layout override |

---

## 6. String binding syntax

Runtime bindings use `${...}` expressions:

```
${state.user.name}        — read from store
${item.title}             — read from repeat scope
${index}                  — repeat index
${env.theme}              — read from env
```

These are NOT resolved at compile time. They pass through as raw strings.
Tests that check compiled output should keep bindings verbatim in `expected`.

---

## 7. Core routing table (abbreviated)

| `type` | Core file | Key subtypes |
|---|---|---|
| `box:*` | box_core | row, col, stack, grid, scroll, wrap, layer, shell |
| `action` | action_core | button, gesture, hover, focus, chip, long_press |
| `field` | field_core | password, email, toggle, radio, slider, textarea |
| `text` | text_core | h1, h2, h3, label, code, rich |
| `media` | media_core | icon, video, avatar, audio, svg_path |
| `data` | data_core | repeat, stream, slice, paginated, table, kanban |
| `portal` | portal_core | overlay, drawer, toast, sheet, menu, dropdown |
| `control` | control_core | form_scope, tabs, stepper, accordion, machine |
| `hook` | hook_core | effect, guard, memo, atom, interval, error_boundary |
| `system` | system_core | timer, async, worker, store_provider, throttle |
| `decoration` | decoration_core | blur, gradient, border, shadow, badge, skeleton |
| `canvas` | canvas_core | draw, plot, shader, shape |
| `stream` | stream_core | ws, sse, tick, ring, multiplex |
| `collab` | collab_core | presence, cursor, awareness, lock, patch |
| `visual` | visual_core | chart, animation, scene, overlay, compose |

---

## 8. debugPath convention

| Node position | debugPath value |
|---|---|
| Root node (no name) | `"root"` |
| Root node with `name: "panel"` | `"panel"` |
| First child of root | `"root[0]"` |
| Second child of root | `"root[1]"` |
| First child of root[1] | `"root[1][0]"` |
| State wrapper | `"panel.store_provider"` |

---

## 9. Required vs optional fields in expected output

The `_diffJson` helper in the test runner checks:
1. All keys in `expected` must exist in `actual` — missing keys fail.
2. All keys in `actual` must exist in `expected` — extra keys fail.
3. Values must match exactly (recursive for objects and arrays).

So your `expected` must be an **exact** snapshot — include `debugPath` on every node.
