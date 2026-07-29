# 17 — Runtime Execution Test Plan

Comprehensive E2E execution tests. These test cases define complex UI interactions that the `WidgetTester` runs on the compiled SDUI blueprint.

---

## Complex Interactions

### EXEC-001 — Multi-step form submission flow

```json
{
  "__meta": {
    "id": "exec-001-multi-step-form",
    "title": "Multi-step form wizard execution",
    "description": "Test a wizard that progresses through multiple steps via state changes.",
    "tags": ["execution", "form", "wizard", "state", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "step": 1, "name": "" },
    "type": "box:col",
    "children": [
      { "$if": "${state.step == 1}", "type": "box:col", "children": [
        { "type": "text", "props": { "text": "Step 1" } },
        { "type": "field:text", "props": { "bind": "${state.name}", "placeholder": "Name" } },
        { "type": "action:button", "props": { "text": "Next", "onTap": [{ "action": "state.set", "path": "step", "value": 2 }] } }
      ]},
      { "$if": "${state.step == 2}", "type": "box:col", "children": [
        { "type": "text", "props": { "text": "Step 2: Hello ${state.name}" } },
        { "type": "action:button", "props": { "text": "Back", "onTap": [{ "action": "state.set", "path": "step", "value": 1 }] } }
      ]}
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "step": 1, "name": "" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:col", "props": {}, "debugPath": "root", "children": [
        { "type": "box:col", "props": {}, "debugPath": "root[0]", "children": [
          { "type": "text", "props": { "text": "Step 1" }, "debugPath": "root[0][0]" },
          { "type": "field", "props": { "__subType": "text", "bind": "${state.name}", "placeholder": "Name" }, "debugPath": "root[0][1]" },
          { "type": "action", "props": { "__subType": "button", "text": "Next", "onTap": [{ "action": "state.set", "path": "step", "value": 2 }] }, "debugPath": "root[0][2]" }
        ]}
      ]
    }]
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Step 1" },
    { "action": "enterText", "finder": { "type": "type", "match": "TextField" }, "text": "Alice" },
    { "action": "tap", "finder": { "type": "text", "match": "Next" } },
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Step 2: Hello Alice" },
    { "action": "tap", "finder": { "type": "text", "match": "Back" } },
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Step 1" }
  ]
}
```

---

## Complete Execution Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| exec-001 | Multi-step form wizard | critical |
| exec-002 | Drag and drop sorting | high |
| exec-003 | Swipe to dismiss list item | high |
| exec-004 | Scroll pagination triggering API | critical |
