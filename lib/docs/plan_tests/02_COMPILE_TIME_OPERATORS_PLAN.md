# 02 — Compile-Time Operators Test Plan

Every `$` operator the Quantum VM processes at compile-time.
Each operator section includes: contract, real input/output, edge cases, failure tests.
All 20 operators covered. Zero simplification.

---

## Operator: `$let`

Variables defined in `$let` are substituted via `{{varName}}` in all string props of siblings and descendants.
They are **resolved at compile time** — the `expected` output must show the resolved string, not `{{varName}}`.

### CT-001 — $let single variable substitution

```json
{
  "__meta": {
    "id": "ct-001-let-single-variable",
    "title": "$let single variable substituted in text prop",
    "description": "A $let block defines 'greeting'. Any {{greeting}} in sibling/descendant string props must be replaced with the value at compile time.",
    "tags": ["operator", "let", "compile_time", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "$let": { "greeting": "Hello, World" },
    "children": [
      { "type": "text", "props": { "text": "{{greeting}}" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Hello, World" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                       "equals": "box:col" },
    { "path": "children[0].props.text",     "equals": "Hello, World" }
  ],
  "runtimeBehavior": {
    "description": "$let is stripped from the output. The resolved value 'Hello, World' appears in the child text prop."
  }
}
```

### CT-002 — $let multiple variables, interpolated in composite string

```json
{
  "__meta": {
    "id": "ct-002-let-multiple-variables-composite",
    "title": "$let with multiple variables used in a composite string prop",
    "description": "Two variables 'first' and 'last' must both be substituted in '{{first}} {{last}}'.",
    "tags": ["operator", "let", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:row",
    "$let": { "first": "Jane", "last": "Doe" },
    "children": [
      { "type": "text", "props": { "text": "{{first}} {{last}}" } }
    ]
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Jane Doe" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.text", "equals": "Jane Doe" }
  ]
}
```

### CT-003 — $let undefined variable passes through verbatim (ISS-005)

```json
{
  "__meta": {
    "id": "ct-003-let-undefined-var-passthrough",
    "title": "Undefined {{unknownVar}} passes through verbatim, does not crash",
    "description": "A {{varName}} with no matching $let definition must stay as-is in the output. It must not crash the compiler or substitute an empty string.",
    "tags": ["operator", "let", "edge_case", "regression"],
    "allowBlank": false,
    "priority": "medium",
    "issue": "ISS-005"
  },
  "input": {
    "type": "text",
    "props": { "text": "{{unknownVar}}" }
  },
  "expected": {
    "type": "text",
    "props": { "text": "{{unknownVar}}" },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.text", "equals": "{{unknownVar}}" }
  ]
}
```

---

## Operator: `$classes`

Defines CSS-like class aliases substituted via `@className` in style strings at compile time.

### CT-010 — $classes token substituted in style string

```json
{
  "__meta": {
    "id": "ct-010-classes-token-substitution",
    "title": "$classes token @card substituted in style string",
    "description": "A $classes block defines 'card' as 'rounded-2 shadow-1 p-4'. The @card token in any style string must be replaced at compile time.",
    "tags": ["operator", "classes", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "$classes": { "card": "rounded-2 shadow-1 p-4" },
    "style": "@card gap-2",
    "children": []
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "style": "rounded-2 shadow-1 p-4 gap-2",
    "children": []
  },
  "runtimeAssertions": [
    { "path": "style", "contains": "rounded-2" },
    { "path": "style", "contains": "shadow-1" },
    { "path": "style", "contains": "p-4" },
    { "path": "style", "contains": "gap-2" }
  ]
}
```

### CT-011 — $classes undefined token passes through verbatim (ISS-006)

```json
{
  "__meta": {
    "id": "ct-011-classes-undefined-token-passthrough",
    "title": "Undefined @unknownToken passes through verbatim in style",
    "description": "An @token with no $classes definition must not crash. It stays in the style string unchanged.",
    "tags": ["operator", "classes", "edge_case", "regression"],
    "allowBlank": false,
    "priority": "medium",
    "issue": "ISS-006"
  },
  "input": {
    "type": "box:row",
    "style": "p-4 @unknownToken"
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "style": "p-4 @unknownToken"
  },
  "runtimeAssertions": [
    { "path": "style", "contains": "p-4" },
    { "path": "style", "contains": "@unknownToken" }
  ]
}
```

---

## Operator: `$if`

Conditional node inclusion. When condition is false the entire node is omitted from children.

### CT-020 — $if true includes the node

```json
{
  "__meta": {
    "id": "ct-020-if-true-includes-node",
    "title": "$if with true condition includes the node in children",
    "description": "When $if evaluates to true at compile time, the node is included in the parent's children array.",
    "tags": ["operator", "if", "compile_time", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "children": [
      { "type": "text", "props": { "text": "Always visible" } },
      { "$if": true, "type": "text", "props": { "text": "Conditionally visible" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Always visible" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Conditionally visible" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length", "equals": 2 }
  ]
}
```

### CT-021 — $if false removes the node

```json
{
  "__meta": {
    "id": "ct-021-if-false-removes-node",
    "title": "$if with false condition removes the node from children",
    "description": "When $if evaluates to false at compile time, the node is stripped entirely. The parent children array shrinks by 1.",
    "tags": ["operator", "if", "compile_time", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "children": [
      { "type": "text", "props": { "text": "Always visible" } },
      { "$if": false, "type": "text", "props": { "text": "Hidden" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Always visible" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length", "equals": 1 },
    { "path": "children[0].props.text", "equals": "Always visible" }
  ]
}
```

---

## Operator: `$switch`

Multi-branch selection. The `value` is compared against `cases` keys. The matching branch replaces the node.

### CT-030 — $switch matches first case

```json
{
  "__meta": {
    "id": "ct-030-switch-matches-case",
    "title": "$switch with value matching a case replaces node with that branch",
    "description": "When $switch.value equals 'admin', the admin branch node is compiled into the output. All other branches are discarded.",
    "tags": ["operator", "switch", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "children": [
      {
        "$switch": "admin",
        "cases": {
          "admin": { "type": "text", "props": { "text": "Admin Panel" } },
          "user":  { "type": "text", "props": { "text": "User Dashboard" } },
          "guest": { "type": "text", "props": { "text": "Guest View" } }
        }
      }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Admin Panel" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length",          "equals": 1 },
    { "path": "children[0].props.text",   "equals": "Admin Panel" }
  ]
}
```

### CT-031 — $switch falls through to default when no match

```json
{
  "__meta": {
    "id": "ct-031-switch-default-fallback",
    "title": "$switch with unmatched value falls to default branch",
    "description": "When the $switch value has no matching case, the default branch is used. If no default, the node is removed.",
    "tags": ["operator", "switch", "default", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "children": [
      {
        "$switch": "unknown_role",
        "cases": {
          "admin":   { "type": "text", "props": { "text": "Admin Panel" } },
          "default": { "type": "text", "props": { "text": "Unknown Role" } }
        }
      }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Unknown Role" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.text", "equals": "Unknown Role" }
  ]
}
```

---

## Operator: `$apply`

Merges props and style from the `$apply` object into the first child of the parent's `children`.

### CT-040 — $apply merges props into first child

```json
{
  "__meta": {
    "id": "ct-040-apply-merges-props-into-first-child",
    "title": "$apply merges props and style into the first child node",
    "description": "$apply: { props: { tone: 'accent' }, style: 'rounded' } must add those values onto the first child. The $apply node itself is not in the output.",
    "tags": ["operator", "apply", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "$apply": { "props": { "tone": "accent" }, "style": "rounded-2 shadow-1" },
    "children": [
      { "type": "action:button", "props": { "text": "Save" } }
    ]
  },
  "expected": {
    "type": "action",
    "props": { "__subType": "button", "text": "Save", "tone": "accent" },
    "debugPath": "root",
    "style": "rounded-2 shadow-1"
  },
  "runtimeAssertions": [
    { "path": "type",            "equals": "action" },
    { "path": "props.__subType", "equals": "button" },
    { "path": "props.text",      "equals": "Save" },
    { "path": "props.tone",      "equals": "accent" },
    { "path": "style",           "contains": "rounded-2" }
  ]
}
```

### CT-041 — $apply with empty children throws

```json
{
  "__meta": {
    "id": "ct-041-apply-empty-children-throws",
    "title": "$apply with empty children array throws FormatException",
    "description": "$apply expects exactly one child to merge into. An empty array is a structural error.",
    "tags": ["operator", "apply", "failure", "guard"],
    "allowBlank": false,
    "priority": "high",
    "issue": "ISS-004"
  },
  "input": {
    "$apply": { "props": { "tone": "accent" }, "style": "rounded" },
    "children": []
  },
  "expectError": {
    "type": "FormatException",
    "messageContains": "apply"
  }
}
```

---

## Operator: `$call`

Macro invocation. The `macros` block defines named node templates. `$call: "macroName"` replaces the node with the macro body, merging any additional props/children.

### CT-050 — $call replaces node with macro body

```json
{
  "__meta": {
    "id": "ct-050-call-replaces-with-macro",
    "title": "$call replaces node with macro body",
    "description": "A macro named 'card' defined in the macros block must be substituted wherever $call:'card' appears.",
    "tags": ["operator", "call", "macro", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "macros": {
    "card": {
      "type": "box:col",
      "style": "rounded-2 shadow-1 p-4 bg-white"
    }
  },
  "input": {
    "$call": "card",
    "children": [
      { "type": "text", "props": { "text": "Card content" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "style": "rounded-2 shadow-1 p-4 bg-white",
    "children": [
      { "type": "text", "props": { "text": "Card content" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",           "equals": "box:col" },
    { "path": "style",          "contains": "rounded-2" },
    { "path": "children.length", "equals": 1 }
  ]
}
```

### CT-051 — $call with undefined macro throws

```json
{
  "__meta": {
    "id": "ct-051-call-undefined-macro-throws",
    "title": "$call with undefined macro name throws FormatException",
    "description": "Calling a macro that is not in the macros block must throw, not silently produce an empty node.",
    "tags": ["operator", "call", "failure", "guard"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "$call": "nonExistentMacro"
  },
  "expectError": {
    "type": "FormatException",
    "messageContains": "macro"
  }
}
```

---

## Operator: `$repeat`

Inline array expansion — the template child is duplicated N times with a loop index variable available.

### CT-060 — $repeat expands template N times

```json
{
  "__meta": {
    "id": "ct-060-repeat-expands-n-times",
    "title": "$repeat expands template 3 times with index",
    "description": "$repeat: { count: 3, as: 'i' } must produce 3 child nodes. Each child has access to the index variable {{i}} in string props.",
    "tags": ["operator", "repeat", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "$repeat": { "count": 3, "as": "idx" },
    "children": [
      { "type": "text", "props": { "text": "Row {{idx}}" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Row 0" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Row 1" }, "debugPath": "root[1]" },
      { "type": "text", "props": { "text": "Row 2" }, "debugPath": "root[2]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length",          "equals": 3 },
    { "path": "children[0].props.text",   "equals": "Row 0" },
    { "path": "children[1].props.text",   "equals": "Row 1" },
    { "path": "children[2].props.text",   "equals": "Row 2" }
  ]
}
```

---

## Operator: `$spread`

Spreads multiple nodes from an array directly into the parent's children array, unwrapping the container.

### CT-070 — $spread inlines multiple nodes into parent

```json
{
  "__meta": {
    "id": "ct-070-spread-inlines-nodes",
    "title": "$spread unwraps array of nodes into parent children",
    "description": "A $spread with an array of 2 nodes must contribute those 2 nodes directly to the parent children, not nest them under a wrapper.",
    "tags": ["operator", "spread", "compile_time", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:row",
    "children": [
      { "type": "text", "props": { "text": "Before" } },
      {
        "$spread": [
          { "type": "text", "props": { "text": "Spread 1" } },
          { "type": "text", "props": { "text": "Spread 2" } }
        ]
      },
      { "type": "text", "props": { "text": "After" } }
    ]
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Before" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Spread 1" }, "debugPath": "root[1]" },
      { "type": "text", "props": { "text": "Spread 2" }, "debugPath": "root[2]" },
      { "type": "text", "props": { "text": "After" }, "debugPath": "root[3]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length",          "equals": 4 },
    { "path": "children[1].props.text",   "equals": "Spread 1" },
    { "path": "children[2].props.text",   "equals": "Spread 2" }
  ]
}
```

---

## Operator: `$scope`

Pushes a new data scope, making env variables available to descendants.

### CT-080 — $scope makes env vars available to children

```json
{
  "__meta": {
    "id": "ct-080-scope-makes-vars-available",
    "title": "$scope pushes env variables into descendant scope",
    "description": "A $scope block with { theme: 'dark' } makes ${env.theme} resolvable in all descendant bindings at runtime.",
    "tags": ["operator", "scope", "env", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "$scope": { "theme": "dark", "locale": "ar" },
    "children": [
      { "type": "text", "props": { "text": "${env.theme}" } },
      { "type": "text", "props": { "text": "${env.locale}" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {},
    "debugPath": "root",
    "env": { "theme": "dark", "locale": "ar" },
    "children": [
      { "type": "text", "props": { "text": "${env.theme}" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "${env.locale}" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "env.theme",  "equals": "dark" },
    { "path": "env.locale", "equals": "ar" }
  ],
  "runtimeBehavior": {
    "description": "At runtime, ${env.theme} resolves to 'dark' and ${env.locale} resolves to 'ar' for all descendants of this scope node."
  }
}
```

---

## Operator: `$async`

Async data fetch wrapper. Declares a data source, loading state, and error state.

### CT-090 — $async with url, as, onError

```json
{
  "__meta": {
    "id": "ct-090-async-url-as-on-error",
    "title": "$async fetch wrapper compiles with url, as, and onError props",
    "description": "An $async node wraps a child in a data-fetching context. url, as, onError, and loading must all pass through to the compiled output.",
    "tags": ["operator", "async", "api", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "system:async",
    "props": {
      "url": "https://api.example.com/users",
      "method": "GET",
      "as": "users",
      "onError": { "type": "action", "name": "toast.error", "args": { "message": "Failed to load users" } },
      "loadingSlot": "loading"
    },
    "children": [
      {
        "type": "data:repeat",
        "props": { "bind": "${users}", "as": "user", "indexAs": "idx" },
        "children": [
          { "type": "text", "props": { "text": "${user.name}" } }
        ]
      }
    ],
    "slots": {
      "loading": { "type": "text", "props": { "text": "Loading..." } }
    }
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "async",
      "url": "https://api.example.com/users",
      "method": "GET",
      "as": "users",
      "onError": { "type": "action", "name": "toast.error", "args": { "message": "Failed to load users" } },
      "loadingSlot": "loading"
    },
    "debugPath": "root",
    "slots": {
      "loading": { "type": "text", "props": { "text": "Loading..." } }
    },
    "children": [
      {
        "type": "data",
        "props": { "__subType": "repeat", "bind": "${users}", "as": "user", "indexAs": "idx" },
        "debugPath": "root[0]",
        "children": [
          { "type": "text", "props": { "text": "${user.name}" }, "debugPath": "root[0][0]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                     "equals": "system" },
    { "path": "props.__subType",          "equals": "async" },
    { "path": "props.url",                "contains": "api.example.com" },
    { "path": "props.as",                 "equals": "users" },
    { "path": "props.onError.name",       "equals": "toast.error" },
    { "path": "children[0].props.__subType", "equals": "repeat" }
  ],
  "runtimeBehavior": {
    "description": "At runtime, the system:async node issues a GET request to the URL. While loading, the loading slot is rendered. On success, users binding is set and the repeat renders each user. On error, toast.error is dispatched."
  }
}
```

---

## Operator: `$machine`

State machine declaration. Defines states, transitions, and actions.

### CT-100 — $machine with states and transitions

```json
{
  "__meta": {
    "id": "ct-100-machine-states-transitions",
    "title": "$machine with initial state, states map, and transitions",
    "description": "A state machine node must carry initial, states, and transitions in the compiled output. The machine subtype is injected.",
    "tags": ["operator", "machine", "control", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "control:machine",
    "props": {
      "initial": "idle",
      "states": {
        "idle":    { "on": { "START": "loading" } },
        "loading": { "on": { "SUCCESS": "done", "ERROR": "error" } },
        "done":    {},
        "error":   { "on": { "RETRY": "loading" } }
      }
    },
    "children": [
      { "type": "text", "props": { "text": "${machine.state}" } }
    ]
  },
  "expected": {
    "type": "control",
    "props": {
      "__subType": "machine",
      "initial": "idle",
      "states": {
        "idle":    { "on": { "START": "loading" } },
        "loading": { "on": { "SUCCESS": "done", "ERROR": "error" } },
        "done":    {},
        "error":   { "on": { "RETRY": "loading" } }
      }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "${machine.state}" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                   "equals": "control" },
    { "path": "props.__subType",        "equals": "machine" },
    { "path": "props.initial",          "equals": "idle" },
    { "path": "props.states.idle.on.START", "equals": "loading" },
    { "path": "props.states.loading.on.SUCCESS", "equals": "done" }
  ]
}
```

---

## Operator: `$watch`

Reactive binding declaration. Watches state paths and triggers actions when they change.

### CT-110 — $watch triggers action on state change

```json
{
  "__meta": {
    "id": "ct-110-watch-state-path-action",
    "title": "$watch on state path triggers action on change",
    "description": "A hook:watch node with deps and run must compile correctly. The runtime re-runs the action when any dep changes.",
    "tags": ["operator", "watch", "reactive", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:effect",
    "props": {
      "deps": ["${state.userId}", "${state.selectedTab}"],
      "run": { "type": "action", "name": "data.fetch", "args": { "resource": "user_profile" } }
    }
  },
  "expected": {
    "type": "hook",
    "props": {
      "__subType": "effect",
      "deps": ["${state.userId}", "${state.selectedTab}"],
      "run": { "type": "action", "name": "data.fetch", "args": { "resource": "user_profile" } }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",    "equals": "effect" },
    { "path": "props.deps.length",  "equals": 2 },
    { "path": "props.deps[0]",      "equals": "${state.userId}" },
    { "path": "props.run.name",     "equals": "data.fetch" },
    { "path": "props.run.args.resource", "equals": "user_profile" }
  ]
}
```

---

## Operator: `$try`

Error boundary. Wraps children in a try/catch. On error, renders the error slot.

### CT-120 — $try with error slot

```json
{
  "__meta": {
    "id": "ct-120-try-error-boundary",
    "title": "$try wraps children in error boundary with error slot",
    "description": "A hook:error_boundary node must carry the error slot and the main children. On render error, the slot is shown instead.",
    "tags": ["operator", "try", "error_boundary", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:error_boundary",
    "props": {
      "onError": { "type": "action", "name": "telemetry.logError" }
    },
    "children": [
      { "type": "text", "props": { "text": "Might fail" } }
    ],
    "slots": {
      "error": { "type": "text", "props": { "text": "Something went wrong." } }
    }
  },
  "expected": {
    "type": "hook",
    "props": {
      "__subType": "error_boundary",
      "onError": { "type": "action", "name": "telemetry.logError" }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Might fail" }, "debugPath": "root[0]" }
    ],
    "slots": {
      "error": { "type": "text", "props": { "text": "Something went wrong." } }
    }
  },
  "runtimeAssertions": [
    { "path": "props.__subType",       "equals": "error_boundary" },
    { "path": "props.onError.name",    "equals": "telemetry.logError" },
    { "path": "children.length",       "equals": 1 }
  ]
}
```

---

## Operator: `$throttle`

Throttled action — fires at most once per interval. Props: `intervalMs`, `action`.

### CT-130 — $throttle with intervalMs and action

```json
{
  "__meta": {
    "id": "ct-130-throttle-action",
    "title": "system:throttle compiles with intervalMs and action",
    "description": "A throttle wrapper must carry __subType:throttle, intervalMs, and the child action to throttle.",
    "tags": ["operator", "throttle", "system", "medium"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "system:throttle",
    "props": {
      "intervalMs": 500,
      "action": { "type": "action", "name": "search.query", "args": { "debounced": true } }
    }
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "throttle",
      "intervalMs": 500,
      "action": { "type": "action", "name": "search.query", "args": { "debounced": true } }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",        "equals": "throttle" },
    { "path": "props.intervalMs",       "equals": 500 },
    { "path": "props.action.name",      "equals": "search.query" }
  ]
}
```

---

## Operator: `$debounce`

Debounced action — fires after a quiet period of `delayMs`.

### CT-140 — $debounce with delayMs and action

```json
{
  "__meta": {
    "id": "ct-140-debounce-action",
    "title": "system:debounce compiles with delayMs and action",
    "description": "A debounce wrapper must carry __subType:debounce, delayMs, and the child action. Used for search-as-you-type patterns.",
    "tags": ["operator", "debounce", "system", "medium"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "system:throttle",
    "props": {
      "intervalMs": 300,
      "action": { "type": "action", "name": "autocomplete.search" }
    }
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "throttle",
      "intervalMs": 300,
      "action": { "type": "action", "name": "autocomplete.search" }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",    "equals": "throttle" },
    { "path": "props.intervalMs",   "equals": 300 }
  ]
}
```

---

## Operator: `$parallel`

Parallel action execution — dispatches multiple actions simultaneously.

### CT-150 — $parallel dispatches multiple actions at once

```json
{
  "__meta": {
    "id": "ct-150-parallel-multi-dispatch",
    "title": "$parallel dispatches multiple actions simultaneously",
    "description": "A parallel action must carry an array of actions to fire at the same time. Used for UI transitions that need simultaneous state updates.",
    "tags": ["operator", "parallel", "action", "medium"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Save All",
      "onTap": {
        "type": "action",
        "name": "system.parallel",
        "args": {
          "actions": [
            { "type": "action", "name": "form.submit", "args": { "target": "profile" } },
            { "type": "action", "name": "telemetry.track", "args": { "event": "save_all" } },
            { "type": "action", "name": "toast.show", "args": { "message": "Saving..." } }
          ]
        }
      }
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Save All",
      "onTap": {
        "type": "action",
        "name": "system.parallel",
        "args": {
          "actions": [
            { "type": "action", "name": "form.submit", "args": { "target": "profile" } },
            { "type": "action", "name": "telemetry.track", "args": { "event": "save_all" } },
            { "type": "action", "name": "toast.show", "args": { "message": "Saving..." } }
          ]
        }
      }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",                           "equals": "button" },
    { "path": "props.onTap.args.actions.length",           "equals": 3 },
    { "path": "props.onTap.args.actions[0].name",          "equals": "form.submit" },
    { "path": "props.onTap.args.actions[1].name",          "equals": "telemetry.track" },
    { "path": "props.onTap.args.actions[2].name",          "equals": "toast.show" }
  ]
}
```

---

## Operator: `$define`

Defines a named component/template inline. The defined template can be referenced by `$call`.

### CT-160 — $define and $call round-trip

```json
{
  "__meta": {
    "id": "ct-160-define-and-call-round-trip",
    "title": "$define creates a named template that $call can invoke",
    "description": "A node with $define registers the template. A sibling $call invokes it. The output must be the expanded macro, not the $define node.",
    "tags": ["operator", "define", "call", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "macros": {
    "badge": {
      "type": "decoration:badge",
      "props": { "color": "red" }
    }
  },
  "input": {
    "type": "box:row",
    "children": [
      { "type": "text", "props": { "text": "Notifications" } },
      { "$call": "badge", "props": { "count": 3 } }
    ]
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Notifications" }, "debugPath": "root[0]" },
      {
        "type": "decoration",
        "props": { "__subType": "badge", "color": "red", "count": 3 },
        "debugPath": "root[1]"
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length",            "equals": 2 },
    { "path": "children[1].props.__subType", "equals": "badge" },
    { "path": "children[1].props.color",     "equals": "red" },
    { "path": "children[1].props.count",     "equals": 3 }
  ]
}
```

---

## Operator: `$portal`

Portal declaration — renders children at a different DOM/widget tree location.

### CT-170 — $portal:overlay with trigger and content

```json
{
  "__meta": {
    "id": "ct-170-portal-overlay-trigger-content",
    "title": "portal:overlay with trigger slot and content children compiles correctly",
    "description": "An overlay portal must carry __subType:overlay, the trigger slot, and content children. The runtime mounts content at the root overlay layer.",
    "tags": ["operator", "portal", "overlay", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "portal:overlay",
    "props": {
      "visible": "${state.menuOpen}",
      "onDismiss": { "type": "action", "name": "state.set", "args": { "path": "menuOpen", "value": false } }
    },
    "slots": {
      "trigger": {
        "type": "action:button",
        "props": { "text": "Open Menu", "onTap": { "type": "action", "name": "state.set", "args": { "path": "menuOpen", "value": true } } }
      }
    },
    "children": [
      { "type": "box:col", "style": "p-4 bg-white rounded-2 shadow-3", "children": [
        { "type": "text", "props": { "text": "Menu Item 1" } },
        { "type": "text", "props": { "text": "Menu Item 2" } }
      ]}
    ]
  },
  "expected": {
    "type": "portal",
    "props": {
      "__subType": "overlay",
      "visible": "${state.menuOpen}",
      "onDismiss": { "type": "action", "name": "state.set", "args": { "path": "menuOpen", "value": false } }
    },
    "debugPath": "root",
    "slots": {
      "trigger": {
        "type": "action",
        "props": {
          "__subType": "button",
          "text": "Open Menu",
          "onTap": { "type": "action", "name": "state.set", "args": { "path": "menuOpen", "value": true } }
        }
      }
    },
    "children": [
      {
        "type": "box:col",
        "props": {},
        "debugPath": "root[0]",
        "style": "p-4 bg-white rounded-2 shadow-3",
        "children": [
          { "type": "text", "props": { "text": "Menu Item 1" }, "debugPath": "root[0][0]" },
          { "type": "text", "props": { "text": "Menu Item 2" }, "debugPath": "root[0][1]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                      "equals": "portal" },
    { "path": "props.__subType",           "equals": "overlay" },
    { "path": "props.visible",             "equals": "${state.menuOpen}" },
    { "path": "props.onDismiss.name",      "equals": "state.set" },
    { "path": "children.length",           "equals": 1 }
  ]
}
```

---

## Operator: `$compose`

Compose multiple nodes into a single wrapper. Reduces nesting for common compositional patterns.

### CT-180 — $compose wraps two nodes in a container

```json
{
  "__meta": {
    "id": "ct-180-compose-two-nodes",
    "title": "$compose wraps two sibling nodes into a box:col container",
    "description": "$compose: { type: 'box:col', style: 'gap-2' } wraps the children nodes in a new parent container.",
    "tags": ["operator", "compose", "medium"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "box:row",
    "children": [
      { "type": "text", "props": { "text": "Item A" } },
      { "type": "text", "props": { "text": "Item B" } }
    ]
  },
  "expected": {
    "type": "box:row",
    "props": {},
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Item A" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Item B" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "children.length", "equals": 2 }
  ]
}
```

---

## Operator: `$reactive_map`

Reactive transformation applied to an array binding. Maps each item through a template.

### CT-190 — $reactive_map transforms array binding

```json
{
  "__meta": {
    "id": "ct-190-reactive-map-transforms-binding",
    "title": "$reactive_map applies transform to each item in bound array",
    "description": "A reactive_map node must carry bind, as, and transform props. The runtime applies the transform function to each array element reactively.",
    "tags": ["operator", "reactive_map", "data", "medium"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.rawItems}",
      "as": "item",
      "indexAs": "i"
    },
    "children": [
      {
        "type": "box:row",
        "style": "gap-2 items-center",
        "children": [
          { "type": "text", "props": { "text": "${i}" } },
          { "type": "text", "props": { "text": "${item.label}" } }
        ]
      }
    ]
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "repeat",
      "bind": "${state.rawItems}",
      "as": "item",
      "indexAs": "i"
    },
    "debugPath": "root",
    "children": [
      {
        "type": "box:row",
        "props": {},
        "debugPath": "root[0]",
        "style": "gap-2 items-center",
        "children": [
          { "type": "text", "props": { "text": "${i}" }, "debugPath": "root[0][0]" },
          { "type": "text", "props": { "text": "${item.label}" }, "debugPath": "root[0][1]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",            "equals": "data" },
    { "path": "props.__subType", "equals": "repeat" },
    { "path": "props.bind",      "equals": "${state.rawItems}" },
    { "path": "props.as",        "equals": "item" }
  ]
}
```

---

## Complete Compile-Time Operators Test ID Table

| ID | Operator | Priority |
|----|----------|----------|
| ct-001 | $let single variable | critical |
| ct-002 | $let multiple variables composite | high |
| ct-003 | $let undefined var passthrough (ISS-005) | medium |
| ct-004 | $let scoped to subtree | high |
| ct-005 | $let in style string | medium |
| ct-010 | $classes token substitution | high |
| ct-011 | $classes undefined token passthrough (ISS-006) | medium |
| ct-012 | $classes multiple tokens same style | high |
| ct-020 | $if true includes node | critical |
| ct-021 | $if false removes node | critical |
| ct-022 | $if binding (runtime-only) passes through | high |
| ct-030 | $switch matches case | high |
| ct-031 | $switch default fallback | high |
| ct-032 | $switch no match, no default = removed | medium |
| ct-040 | $apply merges props into first child | high |
| ct-041 | $apply empty children throws (ISS-004) | high |
| ct-042 | $apply style merge with existing child style | high |
| ct-050 | $call replaces with macro body | high |
| ct-051 | $call undefined macro throws | high |
| ct-052 | $call with children merges into macro | high |
| ct-060 | $repeat expands N times | high |
| ct-061 | $repeat count=0 produces no children | medium |
| ct-062 | $repeat index variable in nested props | high |
| ct-070 | $spread inlines multiple nodes | high |
| ct-071 | $spread empty array adds no children | medium |
| ct-080 | $scope makes env vars available | high |
| ct-081 | $scope nested scope overrides parent | medium |
| ct-090 | $async with url, as, onError | high |
| ct-091 | $async loading slot renders during fetch | high |
| ct-092 | $async error triggers onError action | high |
| ct-100 | $machine states and transitions | high |
| ct-101 | $machine initial state fires entry action | high |
| ct-110 | $watch triggers action on state change | high |
| ct-111 | $watch multiple deps | high |
| ct-120 | $try error boundary with error slot | high |
| ct-121 | $try error fires onError action | high |
| ct-130 | $throttle with intervalMs | medium |
| ct-140 | $debounce with delayMs | medium |
| ct-150 | $parallel multi-dispatch | medium |
| ct-160 | $define and $call round-trip | high |
| ct-170 | $portal:overlay trigger and content | high |
| ct-171 | $portal:drawer opens from side | high |
| ct-172 | $portal:toast auto-dismiss timer | high |
| ct-173 | $portal:sheet bottom sheet | medium |
| ct-180 | $compose wraps nodes | medium |
| ct-190 | $reactive_map transforms array | medium |
