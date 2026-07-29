# 11 — Navigation Test Plan

Tests for nav.push, nav.pop, nav.replace, deep links, and navigation guards.

---

## Navigation Actions

### NAV-001 — nav.push with arguments

```json
{
  "__meta": {
    "id": "nav-001-push-arguments",
    "title": "nav.push action passes route and arguments",
    "description": "Navigation action must serialize route and params correctly.",
    "tags": ["nav", "push", "execution", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Go to Profile",
      "onTap": [{ "action": "nav.push", "route": "/profile", "args": { "id": "123" } }]
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Go to Profile",
      "onTap": [{ "action": "nav.push", "route": "/profile", "args": { "id": "123" } }]
    },
    "debugPath": "root"
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "tap", "finder": { "type": "text", "match": "Go to Profile" } },
    { "action": "expectDispatched", "name": "nav.push", "args": { "route": "/profile", "args": { "id": "123" } } }
  ]
}
```

---

## Complete Navigation Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| nav-001 | nav.push with args | critical |
| nav-002 | nav.pop (back navigation) | high |
| nav-003 | nav.replace clears current stack entry | high |
| nav-004 | nav.clearStack root reset | high |
| nav-010 | nav.push blocked by guard | critical |
