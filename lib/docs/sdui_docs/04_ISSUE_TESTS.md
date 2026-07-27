# 04 — Issue Tests

Regression test contracts for known bugs, edge cases, and guard trips.
Each entry below maps to a real failure mode. Pin it with a JSON test so it never comes back.

---

## Folder: `cases/issue/`

Naming: `issue_NNN_NNN.json`
Every issue test MUST include `"issue": "GH-NNN"` or similar in `__meta`.

---

## Registered issue contracts

### ISS-001 — AST overflow guard at depth 129

**What broke**: Trees deeper than 128 levels caused an infinite loop or corrupted output.
**Guard**: VM throws `FormatException("AST overflow")` at depth 129.

```json
{
  "__meta": {
    "id": "issue-001-ast-overflow-129",
    "title": "Tree at depth 129 trips AST overflow guard",
    "description": "Ensures the VM throws FormatException with 'overflow' in the message when nesting exceeds 128 levels.",
    "tags": ["issue", "overflow", "guard"],
    "allowBlank": false,
    "priority": "critical",
    "issue": "ISS-001"
  },
  "input": { "___SEE_FAILURE_FOLDER": "failure_001_001.json" },
  "expectError": {
    "type": "FormatException",
    "messageContains": "overflow"
  }
}
```

### ISS-002 — Missing `type` field throws, not silently renders

**What broke**: A node with no `type` produced a blank widget with no error.

```json
{
  "__meta": {
    "id": "issue-002-missing-type",
    "title": "Missing type field must throw, not render blank",
    "description": "A map with no type key must fail with a FormatException. Silent blank render is the failure mode.",
    "tags": ["issue", "validation", "type"],
    "allowBlank": false,
    "priority": "critical",
    "issue": "ISS-002"
  },
  "input": { "props": { "text": "oops" }, "children": [] },
  "expectError": {
    "type": "FormatException",
    "messageContains": "type"
  }
}
```

### ISS-003 — `null` type field throws cleanly

```json
{
  "__meta": {
    "id": "issue-003-null-type",
    "title": "null type field throws FormatException",
    "description": "type:null must not be coerced to the string 'null'. Must throw.",
    "tags": ["issue", "null", "type"],
    "allowBlank": false,
    "priority": "critical",
    "issue": "ISS-003"
  },
  "input": { "type": null, "props": {} },
  "expectError": {
    "type": "FormatException",
    "messageContains": "type"
  }
}
```

### ISS-004 — `$apply` with no children must not crash

```json
{
  "__meta": {
    "id": "issue-004-apply-no-children",
    "title": "$apply with empty children list must throw or return null gracefully",
    "description": "$apply expects exactly one child. An empty children array is a structural error.",
    "tags": ["issue", "apply", "guard"],
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

### ISS-005 — `$let` variable not defined, substitution leaves `{{name}}`

```json
{
  "__meta": {
    "id": "issue-005-let-undefined-var",
    "title": "Undefined $let variable passes through unresolved",
    "description": "{{unknownVar}} with no matching $let definition must pass through verbatim, not crash.",
    "tags": ["issue", "let", "substitution"],
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
  }
}
```

### ISS-006 — `$classes` token not defined, `@token` stays in style

```json
{
  "__meta": {
    "id": "issue-006-classes-undefined-token",
    "title": "Undefined @class token stays verbatim in style string",
    "description": "@unknownToken with no $classes definition must not crash or strip the style. It stays as-is.",
    "tags": ["issue", "classes", "style"],
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
  }
}
```

### ISS-007 — `data:repeat` missing `bind` must throw

```json
{
  "__meta": {
    "id": "issue-007-repeat-missing-bind",
    "title": "data:repeat without bind prop must throw",
    "description": "The data_core expects a bind prop. Missing bind is a contract violation.",
    "tags": ["issue", "data", "repeat", "guard"],
    "allowBlank": false,
    "priority": "critical",
    "issue": "ISS-007"
  },
  "input": {
    "type": "data",
    "props": { "__subType": "repeat", "as": "item" },
    "children": [
      { "type": "text", "props": { "text": "${item.name}" } }
    ]
  },
  "expectError": {
    "type": "FormatException",
    "messageContains": "bind"
  }
}
```

### ISS-008 — Double colon in type (`box:row:extra`) must throw

```json
{
  "__meta": {
    "id": "issue-008-double-colon",
    "title": "Double colon in type throws FormatException",
    "description": "box:row:extra is not a valid type. The VM must not silently split on the first colon and ignore the rest.",
    "tags": ["issue", "type", "colon", "guard"],
    "allowBlank": false,
    "priority": "high",
    "issue": "ISS-008"
  },
  "input": {
    "type": "box:row:extra",
    "props": {}
  },
  "expectError": {
    "type": "FormatException",
    "messageContains": "type"
  }
}
```

### ISS-009 — `box:col` with `props.__subType` already set must not double-inject

```json
{
  "__meta": {
    "id": "issue-009-box-no-subtype-injection",
    "title": "box:col must not have __subType injected into props",
    "description": "box:* is the only family that keeps the colon in the output type. __subType must NOT be injected for box nodes.",
    "tags": ["issue", "box", "subtype", "normalization"],
    "allowBlank": false,
    "priority": "critical",
    "issue": "ISS-009"
  },
  "input": {
    "type": "box:col",
    "props": { "gap": 8 }
  },
  "expected": {
    "type": "box:col",
    "props": { "gap": 8 },
    "debugPath": "root"
  }
}
```

### ISS-010 — Empty string input must throw, not silently compile

```json
{
  "__meta": {
    "id": "issue-010-empty-string-input",
    "title": "Empty string input must compile to text with empty text prop, not crash",
    "description": "A bare empty string should become { type: text, props: { text: '' } }. Never crash.",
    "tags": ["issue", "string", "edge-case"],
    "allowBlank": true,
    "priority": "medium",
    "issue": "ISS-010"
  },
  "input": "",
  "expected": {
    "type": "text",
    "props": { "text": "" },
    "debugPath": "root"
  }
}
```

---

## Issue test writing guide

1. Open the related GitHub/linear issue.
2. Write the **minimal** input that reproduces the bug.
3. Set `expectError` if the correct behavior is a failure, `expected` if it should succeed.
4. Tag with the issue number in `__meta.issue`.
5. Add priority `"critical"` for any data-corruption or infinite-loop class bug.
6. Commit the test BEFORE fixing the bug so you can watch it go from red to green.
