# 09 — API Calls & Networking Test Plan

Testing HTTP GET/POST, WebSocket streams, SSE, Encrypted SDUI payloads, and API error boundaries.

---

## HTTP Actions

### API-001 — Simple HTTP GET to fetch list

```json
{
  "__meta": {
    "id": "api-001-http-get-list",
    "title": "api.get action fetches data and stores in state",
    "description": "An action dispatching api.get must execute the HTTP request and trigger onSuccess pipeline.",
    "tags": ["api", "http", "get", "execution", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "items": [], "loading": false },
    "type": "action:button",
    "props": {
      "text": "Load Items",
      "onTap": [
        { "action": "state.set", "path": "loading", "value": true },
        { "action": "api.get", "url": "/items", "onSuccess": [
          { "action": "state.set", "path": "items", "value": "${response.data}" },
          { "action": "state.set", "path": "loading", "value": false }
        ]}
      ]
    }
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "items": [], "loading": false } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "action",
      "props": {
        "__subType": "button",
        "text": "Load Items",
        "onTap": [
          { "action": "state.set", "path": "loading", "value": true },
          { "action": "api.get", "url": "/items", "onSuccess": [
            { "action": "state.set", "path": "items", "value": "${response.data}" },
            { "action": "state.set", "path": "loading", "value": false }
          ]}
        ]
      },
      "debugPath": "root"
    }]
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "mockApi", "url": "/items", "response": { "data": ["Apple", "Banana"] } },
    { "action": "tap", "finder": { "type": "text", "match": "Load Items" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "items", "equals": ["Apple", "Banana"] }
  ]
}
```

### API-002 — HTTP POST form data

```json
{
  "__meta": {
    "id": "api-002-http-post-form",
    "title": "api.post action sends body payload",
    "description": "Verifies that api.post extracts state bindings and sends them in the request body.",
    "tags": ["api", "http", "post", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "name": "John", "age": 30 },
    "type": "action:button",
    "props": {
      "text": "Submit",
      "onTap": [
        { "action": "api.post", "url": "/users", "body": { "name": "${state.name}", "age": "${state.age}" } }
      ]
    }
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "name": "John", "age": 30 } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "action",
      "props": {
        "__subType": "button",
        "text": "Submit",
        "onTap": [
          { "action": "api.post", "url": "/users", "body": { "name": "${state.name}", "age": "${state.age}" } }
        ]
      },
      "debugPath": "root"
    }]
  }
}
```

---

## Encrypted API (SDUI over AES-GCM)

### API-010 — Fetching encrypted SDUI payload

```json
{
  "__meta": {
    "id": "api-010-encrypted-sdui-payload",
    "title": "Encrypted SDUI fetch using system:async",
    "description": "system:async node fetching from an encrypted endpoint must trigger decryption and parsing.",
    "tags": ["api", "sdui", "encrypted", "security", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "system:async",
    "props": {
      "url": "/secure/dashboard",
      "method": "GET",
      "encrypted": true
    },
    "children": [
      { "type": "text", "props": { "text": "Loaded secure content" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": {
      "__subType": "async",
      "url": "/secure/dashboard",
      "method": "GET",
      "encrypted": true
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Loaded secure content" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.encrypted", "equals": true }
  ]
}
```

---

## API Error Handling

### API-020 — API Error triggers onError callback

```json
{
  "__meta": {
    "id": "api-020-http-error-callback",
    "title": "API failure executes onError pipeline",
    "description": "A 500 server error must trigger the onError pipeline, skipping onSuccess.",
    "tags": ["api", "error", "execution", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "status": "idle" },
    "type": "action:button",
    "props": {
      "text": "Break API",
      "onTap": [
        { "action": "api.get", "url": "/fail", 
          "onSuccess": [{ "action": "state.set", "path": "status", "value": "success" }],
          "onError": [{ "action": "state.set", "path": "status", "value": "error" }] 
        }
      ]
    }
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "status": "idle" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "action",
      "props": {
        "__subType": "button",
        "text": "Break API",
        "onTap": [
          { "action": "api.get", "url": "/fail", 
            "onSuccess": [{ "action": "state.set", "path": "status", "value": "success" }],
            "onError": [{ "action": "state.set", "path": "status", "value": "error" }] 
          }
        ]
      },
      "debugPath": "root"
    }]
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "mockApi", "url": "/fail", "status": 500, "response": {} },
    { "action": "tap", "finder": { "type": "text", "match": "Break API" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "status", "equals": "error" }
  ]
}
```

---

## Complete API Calls Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| api-001 | api.get to state | critical |
| api-002 | api.post with body | critical |
| api-003 | api.put update | high |
| api-004 | api.delete resource | high |
| api-010 | Encrypted SDUI payload GET | critical |
| api-011 | Encrypted SDUI payload POST | high |
| api-020 | API onError fallback | critical |
| api-021 | API retry on timeout | medium |
| api-030 | WebSocket open connection | high |
| api-031 | WebSocket send message | high |
| api-040 | SSE stream connection | high |
