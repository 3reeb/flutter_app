# 08 — Data and State Tests

Contracts for `data_core`, `system_core` (store_provider), `hook_core` (atom, slice, effect),
`quantum_data_state.dart`, and `quantum_data_pipeline.dart`.

---

## What "data and state tests" mean in the JSON contract

Data and state tests verify that bindings, scopes, stores, and reactive primitives are correctly configured in the JSON tree.

By using `runtimeAssertions` and `runtimeBehavior`, we verify:
1. `initialState` dictionaries are properly wired to `system:store_provider` wrappers.
2. `bind`, `as`, and `indexAs` properties are passed unadulterated into data nodes.
3. String interpolation syntax (`${state.field}`) is not prematurely evaluated at compile time.
4. Hooks carry their dependencies and defaults intact.

The `runtimeBehavior` annotations document the actual state mutation, rendering expansion (e.g. 1 template row -> N actual rows), and reactive consequences of these nodes.

---

## Folder: `cases/data_state/`

Naming: `data_state_NNN_NNN.json`

---

## Store / state contracts

### DS-001 — State wrapping adds exactly one store_provider

```json
{
  "__meta": {
    "id": "ds-001-state-wraps-to-store-provider",
    "title": "State field on root wraps to system:store_provider",
    "description": "Any node with a top-level state field must be wrapped in a single store_provider. This is the VM's automatic state injection rule.",
    "tags": ["data_state", "state", "store_provider"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "name": "dashboard",
    "state": {
      "user": { "name": "Alice", "role": "admin" },
      "filter": "all"
    },
    "type": "box:col",
    "style": "p-6",
    "children": [
      { "type": "text", "props": { "text": "${state.user.name}" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "store_provider",
      "initialState": {
        "user": { "name": "Alice", "role": "admin" },
        "filter": "all"
      }
    },
    "debugPath": "dashboard.store_provider",
    "children": [
      {
        "type": "box:col",
        "props": {},
        "debugPath": "dashboard",
        "style": "p-6",
        "children": [
          { "type": "text", "props": { "text": "${state.user.name}" }, "debugPath": "dashboard[0]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                                      "equals": "system" },
    { "path": "props.__subType",                           "equals": "store_provider" },
    { "path": "props.initialState.user.name",              "equals": "Alice" },
    { "path": "props.initialState.user.role",              "equals": "admin" },
    { "path": "props.initialState.filter",                 "equals": "all" },
    { "path": "debugPath",                                 "equals": "dashboard.store_provider" },
    { "path": "children.length",                           "equals": 1 },
    { "path": "children[0].type",                          "equals": "box:col" },
    { "path": "children[0].debugPath",                     "equals": "dashboard" },
    { "path": "children[0].children[0].props.text",        "equals": "${state.user.name}" }
  ],
  "runtimeBehavior": {
    "description":     "At runtime, the store_provider creates a reactive store with initialState. Bindings like ${state.user.name} read from the store and resolve to 'Alice'. Mutations to state.user.name (via actions) trigger re-renders of all nodes bound to that path.",
    "initialState":    { "user": { "name": "Alice", "role": "admin" }, "filter": "all" },
    "binding":         "${state.user.name}",
    "resolvedValue":   "Alice",
    "mutationAction":  { "type": "action", "name": "state.set", "args": { "path": "user.name", "value": "Bob" } },
    "afterMutation":   "Alice → Bob (triggers re-render)"
  }
}
```

### DS-002 — Nested state objects in initialState preserve structure

```json
{
  "__meta": {
    "id": "ds-002-nested-state-structure",
    "title": "Deeply nested initialState preserves exact structure",
    "description": "The initialState must be passed verbatim to the store_provider without flattening or re-keying.",
    "tags": ["data_state", "state", "nested"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "name": "settings",
    "state": {
      "ui": {
        "theme": "dark",
        "sidebar": { "open": true, "width": 280 }
      },
      "prefs": { "lang": "en", "notifications": true }
    },
    "type": "text",
    "props": { "text": "Settings panel" }
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "store_provider",
      "initialState": {
        "ui": {
          "theme": "dark",
          "sidebar": { "open": true, "width": 280 }
        },
        "prefs": { "lang": "en", "notifications": true }
      }
    },
    "debugPath": "settings.store_provider",
    "children": [
      { "type": "text", "props": { "text": "Settings panel" }, "debugPath": "settings" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.initialState.ui.theme",            "equals": "dark" },
    { "path": "props.initialState.ui.sidebar.open",     "equals": true },
    { "path": "props.initialState.ui.sidebar.width",    "equals": 280 },
    { "path": "props.initialState.prefs.lang",          "equals": "en" }
  ],
  "runtimeBehavior": {
    "description": "The runtime maintains the nested structure exactly. A binding of ${state.ui.sidebar.width} correctly accesses the value 280."
  }
}
```

---

## Data repeat contracts

### DS-010 — data:repeat minimal

```json
{
  "__meta": {
    "id": "ds-010-data-repeat-minimal",
    "title": "Minimal data:repeat with bind/as/indexAs",
    "description": "The repeat node must carry __subType, bind, as, and indexAs. The child template must be under children. This is the base contract for all list rendering.",
    "tags": ["data_state", "data", "repeat"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "data:repeat",
    "props": {
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
    { "path": "type",                         "equals": "data" },
    { "path": "props.__subType",              "equals": "repeat" },
    { "path": "props.bind",                   "equals": "${state.items}" },
    { "path": "props.as",                     "equals": "item" },
    { "path": "props.indexAs",                "equals": "i" },
    { "path": "children.length",              "equals": 1 },
    { "path": "children[0].props.text",       "equals": "${item.name}" }
  ],
  "runtimeBehavior": {
    "description":    "At runtime with state.items = [{name:'A'},{name:'B'}], the runtime renders 2 instances of the child template. Each instance has item bound to the current element and i bound to the index.",
    "renderedCount":  2,
    "instance0":      { "item": { "name": "A" }, "i": 0, "text": "A" },
    "instance1":      { "item": { "name": "B" }, "i": 1, "text": "B" }
  }
}
```

---

## Hook atom contract

### DS-040 — hook:atom with key and defaultValue

```json
{
  "__meta": {
    "id": "ds-040-hook-atom-default-value",
    "title": "hook:atom with key and defaultValue compiles correctly",
    "description": "An atom hook declares a named reactive signal. key and defaultValue must survive compilation for the runtime to register the signal.",
    "tags": ["data_state", "hook", "atom", "signal"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:atom",
    "props": {
      "key": "isDarkMode",
      "defaultValue": false,
      "persist": true
    },
    "children": [
      { "type": "text", "props": { "text": "${isDarkMode}" } }
    ]
  },
  "expected": {
    "type": "hook",
    "props": {
      "__subType": "atom",
      "key": "isDarkMode",
      "defaultValue": false,
      "persist": true
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "${isDarkMode}" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "atom" },
    { "path": "props.key",                 "equals": "isDarkMode" },
    { "path": "props.defaultValue",        "equals": false },
    { "path": "props.persist",             "equals": true }
  ],
  "runtimeBehavior": {
    "description": "At runtime, a local signal named 'isDarkMode' is created with value false. Bindings to ${isDarkMode} automatically update when the atom is mutated."
  }
}
```

---

## Hook effect contract

### DS-050 — hook:effect with deps and run action

```json
{
  "__meta": {
    "id": "ds-050-hook-effect-deps",
    "title": "hook:effect with deps array and run action compiles correctly",
    "description": "An effect hook must carry __subType:effect, deps array, and run action. The runtime re-runs the action when any dep changes.",
    "tags": ["data_state", "hook", "effect", "reactive"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:effect",
    "props": {
      "deps": ["${state.userId}", "${state.tab}"],
      "run": { "type": "action", "name": "data.fetch", "args": { "resource": "user_profile" } }
    }
  },
  "expected": {
    "type": "hook",
    "props": {
      "__subType": "effect",
      "deps": ["${state.userId}", "${state.tab}"],
      "run": { "type": "action", "name": "data.fetch", "args": { "resource": "user_profile" } }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "effect" },
    { "path": "props.deps.length",         "equals": 2 },
    { "path": "props.deps[0]",             "equals": "${state.userId}" },
    { "path": "props.run.name",            "equals": "data.fetch" }
  ],
  "runtimeBehavior": {
    "description": "The runtime evaluates the deps array. Whenever the resolved value of state.userId or state.tab changes, the data.fetch action is dispatched automatically."
  }
}
```

---

## System timer contract

### DS-060 — system:timer with onComplete action

```json
{
  "__meta": {
    "id": "ds-060-system-timer-on-complete",
    "title": "system:timer with durationMs and onComplete compiles correctly",
    "description": "A timer node fires onComplete after durationMs. Both props must survive compilation.",
    "tags": ["data_state", "system", "timer", "action"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "system:timer",
    "props": {
      "durationMs": 3000,
      "onComplete": { "type": "action", "name": "toast.dismiss" }
    }
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "timer",
      "durationMs": 3000,
      "onComplete": { "type": "action", "name": "toast.dismiss" }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "timer" },
    { "path": "props.durationMs",          "equals": 3000 },
    { "path": "props.onComplete.name",     "equals": "toast.dismiss" }
  ],
  "runtimeBehavior": {
    "description": "The runtime starts a countdown. After exactly 3000ms, it dispatches the toast.dismiss action."
  }
}
```
