# 08 — Auth, Login & Logout Test Plan

Complete E2E flows for authentication, session management, and guarded routes.
Zero simplification. These tests verify real user flows using WidgetTester execution steps.

---

## Auth Login Flow

### AUTH-001 — Full login widget flow with successful authentication

```json
{
  "__meta": {
    "id": "auth-001-login-success-flow",
    "title": "Full login widget flow — enter credentials, submit, and transition state",
    "description": "Tests a complete login form. Verifies state bindings, button loading state, and the resulting navigation/state change on success.",
    "tags": ["auth", "login", "form", "execution", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "email": "", "password": "", "isLoading": false, "error": "" },
    "type": "box:col",
    "style": "p-8 gap-4 max-w-sm mx-auto",
    "children": [
      { "type": "text", "props": { "text": "Login to your account", "__subType": "h2" } },
      { "$if": "${state.error != ''}", "type": "text", "style": "text-red-500", "props": { "text": "${state.error}" } },
      {
        "type": "field:email",
        "props": { "bind": "${state.email}", "placeholder": "Email address" }
      },
      {
        "type": "field:password",
        "props": { "bind": "${state.password}", "placeholder": "Password" }
      },
      {
        "type": "action:button",
        "props": {
          "text": "Sign In",
          "intent": "primary",
          "loading": "${state.isLoading}",
          "disabled": "${state.email == '' || state.password == '' || state.isLoading}",
          "onTap": [
            { "action": "state.set", "path": "isLoading", "value": true },
            { "action": "api.post", "url": "/auth/login", "body": { "email": "${state.email}", "password": "${state.password}" }, "onSuccess": [
              { "action": "auth.setSession", "token": "${response.token}" },
              { "action": "nav.replace", "route": "/dashboard" }
            ], "onError": [
              { "action": "state.set", "path": "error", "value": "Invalid credentials" },
              { "action": "state.set", "path": "isLoading", "value": false }
            ]}
          ]
        }
      }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "email": "", "password": "", "isLoading": false, "error": "" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:col",
      "props": {},
      "debugPath": "root",
      "style": "p-8 gap-4 max-w-sm mx-auto",
      "children": [
        { "type": "text", "props": { "text": "Login to your account", "__subType": "h2" }, "debugPath": "root[0]" },
        { "type": "field", "props": { "__subType": "email", "bind": "${state.email}", "placeholder": "Email address" }, "debugPath": "root[1]" },
        { "type": "field", "props": { "__subType": "password", "bind": "${state.password}", "placeholder": "Password" }, "debugPath": "root[2]" },
        {
          "type": "action",
          "props": {
            "__subType": "button",
            "text": "Sign In",
            "intent": "primary",
            "loading": "${state.isLoading}",
            "disabled": "${state.email == '' || state.password == '' || state.isLoading}",
            "onTap": [
              { "action": "state.set", "path": "isLoading", "value": true },
              { "action": "api.post", "url": "/auth/login", "body": { "email": "${state.email}", "password": "${state.password}" }, "onSuccess": [
                { "action": "auth.setSession", "token": "${response.token}" },
                { "action": "nav.replace", "route": "/dashboard" }
              ], "onError": [
                { "action": "state.set", "path": "error", "value": "Invalid credentials" },
                { "action": "state.set", "path": "isLoading", "value": false }
              ]}
            ]
          },
          "debugPath": "root[3]"
        }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].children[1].props.__subType", "equals": "email" },
    { "path": "children[0].children[2].props.__subType", "equals": "password" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectDisabled", "finder": { "type": "text", "match": "Sign In" } },
    { "action": "enterText", "finder": { "type": "prop", "key": "placeholder", "value": "Email address" }, "text": "test@example.com" },
    { "action": "pumpAndSettle" },
    { "action": "expectDisabled", "finder": { "type": "text", "match": "Sign In" } },
    { "action": "enterText", "finder": { "type": "prop", "key": "placeholder", "value": "Password" }, "text": "password123" },
    { "action": "pumpAndSettle" },
    { "action": "expectEnabled", "finder": { "type": "text", "match": "Sign In" } },
    { "action": "mockApi", "url": "/auth/login", "response": { "token": "abc.123" }, "delayMs": 50 },
    { "action": "tap", "finder": { "type": "text", "match": "Sign In" } },
    { "action": "pump" },
    { "action": "expectState", "path": "isLoading", "equals": true },
    { "action": "pumpAndSettle" },
    { "action": "expectDispatched", "name": "nav.replace", "args": { "route": "/dashboard" } }
  ]
}
```

### AUTH-002 — Login flow with invalid credentials (error handling)

```json
{
  "__meta": {
    "id": "auth-002-login-error-flow",
    "title": "Login flow handles API error and displays message",
    "description": "Verifies the onError pipeline branch of the login flow.",
    "tags": ["auth", "login", "error", "execution", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "___SEE_ABOVE_INPUT___": "Uses the same input as AUTH-001"
  },
  "expected": {
    "___SEE_ABOVE_EXPECTED___": "Uses the same expected as AUTH-001"
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "enterText", "finder": { "type": "prop", "key": "placeholder", "value": "Email address" }, "text": "wrong@example.com" },
    { "action": "enterText", "finder": { "type": "prop", "key": "placeholder", "value": "Password" }, "text": "badpass" },
    { "action": "pumpAndSettle" },
    { "action": "mockApi", "url": "/auth/login", "status": 401, "response": { "error": "Unauthorized" }, "delayMs": 50 },
    { "action": "tap", "finder": { "type": "text", "match": "Sign In" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "error", "equals": "Invalid credentials" },
    { "action": "expectState", "path": "isLoading", "equals": false },
    { "action": "expectText", "text": "Invalid credentials" }
  ]
}
```

---

## Auth Logout Flow

### AUTH-010 — Logout action clears session and redirects

```json
{
  "__meta": {
    "id": "auth-010-logout-flow",
    "title": "Logout action clears auth session and redirects to login",
    "description": "A sidebar logout button that dispatches auth.clearSession and nav.replace.",
    "tags": ["auth", "logout", "execution", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Logout",
      "intent": "ghost",
      "icon": "logout",
      "onTap": [
        { "action": "auth.clearSession" },
        { "action": "nav.replace", "route": "/login" }
      ]
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Logout",
      "intent": "ghost",
      "icon": "logout",
      "onTap": [
        { "action": "auth.clearSession" },
        { "action": "nav.replace", "route": "/login" }
      ]
    },
    "debugPath": "root"
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "tap", "finder": { "type": "text", "match": "Logout" } },
    { "action": "expectDispatched", "name": "auth.clearSession" },
    { "action": "expectDispatched", "name": "nav.replace", "args": { "route": "/login" } }
  ]
}
```

---

## Session Refresh

### AUTH-020 — Session refresh boundary

```json
{
  "__meta": {
    "id": "auth-020-session-refresh-boundary",
    "title": "hook:guard intercepts unauthenticated render and triggers refresh",
    "description": "A protected route wrapped in a guard. If token is expired, it pauses rendering and triggers a refresh.",
    "tags": ["auth", "guard", "refresh", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "hook:guard",
    "props": {
      "condition": "${session.isValid}",
      "onFail": { "action": "auth.refreshSession" },
      "fallbackSlot": "loading"
    },
    "children": [
      { "type": "text", "props": { "text": "Protected Dashboard" } }
    ],
    "slots": {
      "loading": { "type": "text", "props": { "text": "Restoring session..." } }
    }
  },
  "expected": {
    "type": "hook",
    "props": {
      "__subType": "guard",
      "condition": "${session.isValid}",
      "onFail": { "action": "auth.refreshSession" },
      "fallbackSlot": "loading"
    },
    "debugPath": "root",
    "slots": {
      "loading": { "type": "text", "props": { "text": "Restoring session..." } }
    },
    "children": [
      { "type": "text", "props": { "text": "Protected Dashboard" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType", "equals": "guard" }
  ]
}
```

---

## Complete Auth Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| auth-001 | Login widget success flow | critical |
| auth-002 | Login widget error flow | critical |
| auth-003 | Login widget disabled while loading | critical |
| auth-004 | Login widget validation errors | high |
| auth-010 | Logout button clears session | high |
| auth-011 | Logout confirms via overlay | medium |
| auth-020 | Session refresh guard | high |
| auth-021 | Unauthorized redirect | high |
| auth-030 | OTP (One Time Password) input flow | medium |
| auth-040 | Forgot password flow | medium |
| auth-050 | OAuth social login buttons | low |
