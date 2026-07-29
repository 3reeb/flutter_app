# 07 — Controls & Forms Test Plan

Tests for form scopes, input fields, complex validation rules, form submission, and composite controls (steppers, tabs).

---

## Form Scope & Validation

### CF-001 — form_scope gathers all fields and validates on submit

```json
{
  "__meta": {
    "id": "cf-001-form-scope-validation-submit",
    "title": "control:form_scope validates all descendants before triggering onSubmit",
    "description": "A form scope isolates validation. On submit, it runs validation on every inner field. If valid, onSubmit fires. If invalid, field errors are shown.",
    "tags": ["form", "validation", "submit", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "email": "", "username": "", "formValid": true },
    "type": "control:form_scope",
    "props": {
      "onSubmit": [
        { "action": "api.post", "url": "/register", "body": { "email": "${state.email}", "username": "${state.username}" } }
      ]
    },
    "children": [
      { "type": "box:col", "style": "gap-4", "children": [
        { "type": "field:email", "props": { "bind": "${state.email}", "rule": "required|email" } },
        { "type": "field:text", "props": { "bind": "${state.username}", "rule": "required|min:3" } },
        { "type": "action:button", "props": { "text": "Register", "onTap": [{ "action": "form.submit" }] } }
      ]}
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "email": "", "username": "", "formValid": true } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "control",
      "props": {
        "__subType": "form_scope",
        "onSubmit": [
          { "action": "api.post", "url": "/register", "body": { "email": "${state.email}", "username": "${state.username}" } }
        ]
      },
      "debugPath": "root",
      "children": [
        { "type": "box:col", "props": {}, "debugPath": "root[0]", "style": "gap-4", "children": [
          { "type": "field", "props": { "__subType": "email", "bind": "${state.email}", "rule": "required|email" }, "debugPath": "root[0][0]" },
          { "type": "field", "props": { "__subType": "text", "bind": "${state.username}", "rule": "required|min:3" }, "debugPath": "root[0][1]" },
          { "type": "action", "props": { "__subType": "button", "text": "Register", "onTap": [{ "action": "form.submit" }] }, "debugPath": "root[0][2]" }
        ]}
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType", "equals": "form_scope" },
    { "path": "children[0].children[0].children[0].props.__subType", "equals": "email" },
    { "path": "children[0].children[0].children[1].props.__subType", "equals": "text" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "tap", "finder": { "type": "text", "match": "Register" } },
    { "action": "pumpAndSettle" },
    { "action": "expectDispatched", "name": "api.post", "count": 0 },
    { "action": "enterText", "finder": { "type": "type", "match": "EmailField" }, "text": "test@example.com" },
    { "action": "enterText", "finder": { "type": "type", "match": "TextField" }, "text": "Bob" },
    { "action": "tap", "finder": { "type": "text", "match": "Register" } },
    { "action": "pumpAndSettle" },
    { "action": "expectDispatched", "name": "api.post", "count": 1 }
  ]
}
```

---

## Server Errors

### CF-010 — Form applies server validation errors

```json
{
  "__meta": {
    "id": "cf-010-form-server-errors",
    "title": "form_scope applies server validation errors to fields",
    "description": "When an API request fails with a 422 Unprocessable Entity, form.setErrors distributes the errors to the bound fields.",
    "tags": ["form", "validation", "server", "execution", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "username": "John" },
    "type": "control:form_scope",
    "props": {
      "onSubmit": [
        { "action": "api.post", "url": "/user", "body": { "username": "${state.username}" }, "onError": [
          { "action": "form.setErrors", "errors": "${response.errors}" }
        ]}
      ]
    },
    "children": [
      { "type": "field:text", "props": { "bind": "${state.username}", "name": "username" } },
      { "type": "action:button", "props": { "text": "Save", "onTap": [{ "action": "form.submit" }] } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "username": "John" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "control",
      "props": {
        "__subType": "form_scope",
        "onSubmit": [
          { "action": "api.post", "url": "/user", "body": { "username": "${state.username}" }, "onError": [
            { "action": "form.setErrors", "errors": "${response.errors}" }
          ]}
        ]
      },
      "debugPath": "root",
      "children": [
        { "type": "field", "props": { "__subType": "text", "bind": "${state.username}", "name": "username" }, "debugPath": "root[0]" },
        { "type": "action", "props": { "__subType": "button", "text": "Save", "onTap": [{ "action": "form.submit" }] }, "debugPath": "root[1]" }
      ]
    }]
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "mockApi", "url": "/user", "status": 422, "response": { "errors": { "username": "Username already taken." } } },
    { "action": "tap", "finder": { "type": "text", "match": "Save" } },
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Username already taken." }
  ]
}
```

---

## Controls

### CF-020 — control:tabs navigation and state

```json
{
  "__meta": {
    "id": "cf-020-tabs-navigation",
    "title": "control:tabs manages active tab state",
    "description": "Tabs control manages which child panel is visible based on the active tab index.",
    "tags": ["control", "tabs", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "activeTab": 0 },
    "type": "control:tabs",
    "props": {
      "bind": "${state.activeTab}",
      "tabs": [ "Details", "Reviews" ]
    },
    "children": [
      { "type": "text", "props": { "text": "Details Panel" } },
      { "type": "text", "props": { "text": "Reviews Panel" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "activeTab": 0 } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "control",
      "props": { "__subType": "tabs", "bind": "${state.activeTab}", "tabs": [ "Details", "Reviews" ] },
      "debugPath": "root",
      "children": [
        { "type": "text", "props": { "text": "Details Panel" }, "debugPath": "root[0]" },
        { "type": "text", "props": { "text": "Reviews Panel" }, "debugPath": "root[1]" }
      ]
    }]
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Details Panel" },
    { "action": "tap", "finder": { "type": "text", "match": "Reviews" } },
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Reviews Panel" }
  ]
}
```

---

## Complete Control & Forms Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| cf-001 | form_scope validation & submit flow | critical |
| cf-002 | nested form_scopes isolation | high |
| cf-010 | form_scope server errors distribution | critical |
| cf-011 | field validation (required, email, min) | high |
| cf-012 | field regex custom validation | medium |
| cf-020 | control:tabs navigation | high |
| cf-021 | control:stepper sequential steps | high |
| cf-022 | control:accordion collapsible panels | medium |
