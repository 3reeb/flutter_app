# 05 — Data, State, and Pipeline Test Plan

Tests for reactive state wrapping, data iteration, reactive scopes, streams, effects, and complex data components.

---

## State Provider & Wrapping

### DS-001 — Root state wrapping with nested object

```json
{
  "__meta": {
    "id": "ds-001-state-wrapping-nested-object",
    "title": "Root node with deep state wraps to store_provider",
    "description": "A node with a complex state object must wrap itself in a system:store_provider. Deep bindings must resolve correctly.",
    "tags": ["data", "state", "store_provider", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": {
      "user": { "profile": { "name": "Alice", "age": 30 }, "settings": { "theme": "dark" } }
    },
    "type": "box:col",
    "children": [
      { "type": "text", "props": { "text": "${state.user.profile.name}" } },
      { "type": "text", "props": { "text": "${state.user.settings.theme}" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "store_provider",
      "initialState": {
        "user": { "profile": { "name": "Alice", "age": 30 }, "settings": { "theme": "dark" } }
      }
    },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:col",
      "props": {},
      "debugPath": "root",
      "children": [
        { "type": "text", "props": { "text": "${state.user.profile.name}" }, "debugPath": "root[0]" },
        { "type": "text", "props": { "text": "${state.user.settings.theme}" }, "debugPath": "root[1]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "props.initialState.user.profile.name", "equals": "Alice" },
    { "path": "children[0].children[0].props.text", "equals": "${state.user.profile.name}" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Alice" },
    { "action": "expectText", "text": "dark" }
  ]
}
```

---

## data:repeat

### DS-010 — data:repeat array iteration with stable keys

```json
{
  "__meta": {
    "id": "ds-010-repeat-stable-keys",
    "title": "data:repeat iterates bound array with keyBy prop",
    "description": "A repeat node maps an array from state. The keyBy prop must survive compilation to ensure stable widget keys at runtime.",
    "tags": ["data", "repeat", "iteration", "keyBy", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "todos": [{ "id": "1", "text": "Buy milk" }, { "id": "2", "text": "Read book" }] },
    "type": "data:repeat",
    "props": { "bind": "${state.todos}", "as": "todo", "indexAs": "idx", "keyBy": "id" },
    "children": [
      { "type": "text", "props": { "text": "${idx}: ${todo.text}" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "todos": [{ "id": "1", "text": "Buy milk" }, { "id": "2", "text": "Read book" }] } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "data",
      "props": { "__subType": "repeat", "bind": "${state.todos}", "as": "todo", "indexAs": "idx", "keyBy": "id" },
      "debugPath": "root",
      "children": [
        { "type": "text", "props": { "text": "${idx}: ${todo.text}" }, "debugPath": "root[0]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType", "equals": "repeat" },
    { "path": "children[0].props.bind",      "equals": "${state.todos}" },
    { "path": "children[0].props.keyBy",     "equals": "id" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "0: Buy milk" },
    { "action": "expectText", "text": "1: Read book" }
  ]
}
```

---

## data:slice

### DS-020 — data:slice extracts partial state into scope

```json
{
  "__meta": {
    "id": "ds-020-slice-sub-scope",
    "title": "data:slice extracts sub-object into local scope",
    "description": "Slice creates a new scoped environment where 'as' points to the 'bind' target, shortening binding paths for children.",
    "tags": ["data", "slice", "scope", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "app": { "currentUser": { "name": "Bob" } } },
    "type": "data:slice",
    "props": { "bind": "${state.app.currentUser}", "as": "user" },
    "children": [
      { "type": "text", "props": { "text": "${user.name}" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "app": { "currentUser": { "name": "Bob" } } } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "data",
      "props": { "__subType": "slice", "bind": "${state.app.currentUser}", "as": "user" },
      "debugPath": "root",
      "children": [
        { "type": "text", "props": { "text": "${user.name}" }, "debugPath": "root[0]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType", "equals": "slice" },
    { "path": "children[0].props.bind",      "equals": "${state.app.currentUser}" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Bob" }
  ]
}
```

---

## data:stream

### DS-030 — WebSocket stream with reconnect

```json
{
  "__meta": {
    "id": "ds-030-stream-websocket",
    "title": "data:stream establishes WebSocket and binds to local scope",
    "description": "A stream wrapper must carry the URL, format, and connection props. Runtime manages the WS connection.",
    "tags": ["data", "stream", "ws", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "data:stream",
    "props": {
      "url": "wss://example.com/live",
      "format": "json",
      "as": "event",
      "reconnect": true,
      "reconnectDelayMs": 1000
    },
    "children": [
      { "type": "text", "props": { "text": "Latest: ${event.type}" } }
    ]
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "stream",
      "url": "wss://example.com/live",
      "format": "json",
      "as": "event",
      "reconnect": true,
      "reconnectDelayMs": 1000
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Latest: ${event.type}" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",        "equals": "stream" },
    { "path": "props.url",              "equals": "wss://example.com/live" },
    { "path": "props.reconnect",        "equals": true }
  ]
}
```

---

## data:table

### DS-040 — data:table with columns and sort action

```json
{
  "__meta": {
    "id": "ds-040-table-columns-sort",
    "title": "data:table with column definitions and sortable fields",
    "description": "A table must carry its columns array. The runtime renders the header and maps the bound data array to rows.",
    "tags": ["data", "table", "columns", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "users": [{ "id": 1, "name": "Eve" }, { "id": 2, "name": "Adam" }] },
    "type": "data:table",
    "props": {
      "bind": "${state.users}",
      "columns": [
        { "key": "id", "label": "ID", "sortable": true },
        { "key": "name", "label": "Name", "sortable": true }
      ],
      "onSort": { "type": "action", "name": "table.sort" }
    }
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "users": [{ "id": 1, "name": "Eve" }, { "id": 2, "name": "Adam" }] } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "data",
      "props": {
        "__subType": "table",
        "bind": "${state.users}",
        "columns": [
          { "key": "id", "label": "ID", "sortable": true },
          { "key": "name", "label": "Name", "sortable": true }
        ],
        "onSort": { "type": "action", "name": "table.sort" }
      },
      "debugPath": "root"
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType",      "equals": "table" },
    { "path": "children[0].props.columns.length", "equals": 2 },
    { "path": "children[0].props.columns[1].key", "equals": "name" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Name" },
    { "action": "expectText", "text": "Eve" },
    { "action": "tap", "finder": { "type": "text", "match": "Name" } },
    { "action": "pumpAndSettle" }
  ]
}
```

---

## data:paginated

### DS-050 — data:paginated with totalCount and page action

```json
{
  "__meta": {
    "id": "ds-050-paginated-list",
    "title": "data:paginated wrapping a repeat with next page action",
    "description": "Paginated wraps a data list with page state. onNextPage must fire when next is tapped.",
    "tags": ["data", "paginated", "list", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "data:paginated",
    "props": {
      "bind": "${state.results}",
      "totalCount": "${state.total}",
      "pageSize": 20,
      "onNextPage": { "type": "action", "name": "api.fetchNext" }
    }
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "paginated",
      "bind": "${state.results}",
      "totalCount": "${state.total}",
      "pageSize": 20,
      "onNextPage": { "type": "action", "name": "api.fetchNext" }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",       "equals": "paginated" },
    { "path": "props.totalCount",      "equals": "${state.total}" },
    { "path": "props.pageSize",        "equals": 20 }
  ]
}
```

---

## hook:atom

### DS-060 — hook:atom creates local reactive value

```json
{
  "__meta": {
    "id": "ds-060-atom-local-state",
    "title": "hook:atom provides local state independent of global store",
    "description": "An atom defines a minimal scoped state. The binding uses ${atom.key}.",
    "tags": ["hook", "atom", "state", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:atom",
    "props": { "key": "tab", "defaultValue": "home" },
    "children": [
      { "type": "text", "props": { "text": "${tab}" } }
    ]
  },
  "expected": {
    "type": "hook",
    "props": { "__subType": "atom", "key": "tab", "defaultValue": "home" },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "${tab}" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",    "equals": "atom" },
    { "path": "props.key",          "equals": "tab" },
    { "path": "props.defaultValue", "equals": "home" }
  ]
}
```

---

## hook:effect

### DS-070 — hook:effect runs action when deps change

```json
{
  "__meta": {
    "id": "ds-070-effect-deps-trigger",
    "title": "hook:effect runs action when dependencies array changes",
    "description": "The effect hook must compile with deps and run props. Runtime observes deps and executes run.",
    "tags": ["hook", "effect", "reactive", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "query": "test" },
    "type": "hook:effect",
    "props": {
      "deps": ["${state.query}"],
      "run": { "type": "action", "name": "search.execute", "args": { "q": "${state.query}" } }
    },
    "children": [
      { "type": "text", "props": { "text": "Searching ${state.query}..." } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "query": "test" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "hook",
      "props": {
        "__subType": "effect",
        "deps": ["${state.query}"],
        "run": { "type": "action", "name": "search.execute", "args": { "q": "${state.query}" } }
      },
      "debugPath": "root",
      "children": [
        { "type": "text", "props": { "text": "Searching ${state.query}..." }, "debugPath": "root[0]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType",       "equals": "effect" },
    { "path": "children[0].props.deps.length",     "equals": 1 },
    { "path": "children[0].props.run.name",        "equals": "search.execute" }
  ]
}
```

---

## hook:memo

### DS-080 — hook:memo caches compute result

```json
{
  "__meta": {
    "id": "ds-080-memo-compute-deps",
    "title": "hook:memo with compute action and deps caches result",
    "description": "Memo stores the result of the compute action in 'as'. It only recomputes if deps change.",
    "tags": ["hook", "memo", "performance", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:memo",
    "props": {
      "as": "expensiveResult",
      "deps": ["${state.items.length}"],
      "compute": { "type": "action", "name": "math.sum", "args": { "list": "${state.items}" } }
    },
    "children": [
      { "type": "text", "props": { "text": "Sum: ${expensiveResult}" } }
    ]
  },
  "expected": {
    "type": "hook",
    "props": {
      "__subType": "memo",
      "as": "expensiveResult",
      "deps": ["${state.items.length}"],
      "compute": { "type": "action", "name": "math.sum", "args": { "list": "${state.items}" } }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Sum: ${expensiveResult}" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType", "equals": "memo" },
    { "path": "props.as",        "equals": "expensiveResult" }
  ]
}
```

---

## data:kanban

### DS-090 — data:kanban board with columns and drag

```json
{
  "__meta": {
    "id": "ds-090-kanban-board",
    "title": "data:kanban renders board with drag-and-drop between columns",
    "description": "A kanban component must accept columns and items, and a callback for drag events.",
    "tags": ["data", "kanban", "drag", "medium"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "data:kanban",
    "props": {
      "columns": [{ "id": "todo", "title": "To Do" }, { "id": "done", "title": "Done" }],
      "bind": "${state.tasks}",
      "onCardMove": { "type": "action", "name": "kanban.move" }
    }
  },
  "expected": {
    "type": "data",
    "props": {
      "__subType": "kanban",
      "columns": [{ "id": "todo", "title": "To Do" }, { "id": "done", "title": "Done" }],
      "bind": "${state.tasks}",
      "onCardMove": { "type": "action", "name": "kanban.move" }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",          "equals": "kanban" },
    { "path": "props.columns.length",     "equals": 2 },
    { "path": "props.onCardMove.name",    "equals": "kanban.move" }
  ]
}
```

---

## Complete Data & State Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| ds-001 | state wrapping deep object | critical |
| ds-002 | state wrapping multi-field | critical |
| ds-003 | state mutation updates bindings (execution) | critical |
| ds-010 | data:repeat keyBy stable keys | critical |
| ds-011 | data:repeat empty list renders nothing | high |
| ds-012 | data:repeat with filter prop | high |
| ds-013 | data:repeat matrix (nested repeats) | medium |
| ds-020 | data:slice creates sub-scope | high |
| ds-021 | data:slice updates when parent state changes | high |
| ds-030 | data:stream websocket | high |
| ds-031 | data:stream SSE (Server-Sent Events) | high |
| ds-032 | data:stream tick interval | medium |
| ds-040 | data:table columns and sortable | critical |
| ds-041 | data:table empty state | high |
| ds-042 | data:table column custom renderer slot | medium |
| ds-050 | data:paginated list with next page action | high |
| ds-051 | data:paginated infinite scroll trigger | high |
| ds-060 | hook:atom local state | high |
| ds-061 | hook:atom persist to local storage | medium |
| ds-070 | hook:effect deps trigger action | high |
| ds-071 | hook:effect onMount (empty deps) | high |
| ds-072 | hook:effect cleanup action | medium |
| ds-080 | hook:memo caches result | high |
| ds-090 | data:kanban columns and drag callback | medium |
| ds-091 | data:kanban empty column | medium |
