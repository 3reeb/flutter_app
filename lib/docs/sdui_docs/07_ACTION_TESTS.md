# 07 — Action Tests

Contracts for action_core: button, gesture, pointer, focus, hover, double-tap, long-press, chip.

---

## What "action tests" mean in the JSON contract

Action tests verify that event listeners and interactive elements are correctly constructed in the blueprint so that the runtime can bind real Flutter gesture callbacks.

Using `runtimeAssertions`, these tests programmatically verify:
1. `__subType` is injected correctly from colon syntax (e.g., `action:gesture` -> `gesture`).
2. Action descriptor objects (`type: "action"`, `name: "..."`, `args: {...}`) are passed through correctly.
3. Event names like `onTap`, `onLongPress`, `onHover`, `onFocus` are preserved as keys in `props`.

Using `runtimeBehavior`, these tests document what the runtime *actually does* when the event fires (e.g., dispatching to the action pipeline, modifying navigation stack, updating state).

---

## Core routing for action nodes

`type: "action:button"` → compiled to `type: "action"`, `props.__subType = "button"`
`type: "action:gesture"` → compiled to `type: "action"`, `props.__subType = "gesture"`
etc.

All action subtypes share the same compile-time contract: `__subType` injection + props round-trip.

---

## Folder: `cases/action/`

Naming: `action_NNN_NNN.json`

---

## Button contracts

### ACT-001 — Basic button compiles with intent

```json
{
  "__meta": {
    "id": "action-001-button-intent",
    "title": "action:button with intent prop compiles correctly",
    "description": "A button must carry __subType:button and its intent prop. Missing intent falls back to 'default' in the renderer.",
    "tags": ["action", "button", "intent"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Save",
      "intent": "primary",
      "onTap": { "type": "action", "name": "form.submit" }
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Save",
      "intent": "primary",
      "onTap": { "type": "action", "name": "form.submit" }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "type",                      "equals": "action" },
    { "path": "props.__subType",           "equals": "button" },
    { "path": "props.intent",              "equals": "primary" },
    { "path": "props.intent",              "oneOf": ["primary", "secondary", "danger", "default"] },
    { "path": "props.onTap.type",          "equals": "action" },
    { "path": "props.onTap.name",          "equals": "form.submit" }
  ],
  "runtimeBehavior": {
    "gesture":       "tap",
    "description":   "When the button is tapped, the runtime dispatches the form.submit action to the pipeline.",
    "dispatches":    "form.submit",
    "event":         "onTap"
  }
}
```

### ACT-002 — Button with disabled state binding

```json
{
  "__meta": {
    "id": "action-002-button-disabled-binding",
    "title": "Button disabled prop accepts state binding",
    "description": "disabled:true/false or a binding like disabled:'${state.loading}' must pass through. Renderer evaluates it at runtime.",
    "tags": ["action", "button", "disabled", "binding"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Submit",
      "disabled": "${state.loading}"
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Submit",
      "disabled": "${state.loading}"
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.disabled",            "equals": "${state.loading}" },
    { "path": "props.disabled",            "contains": "state.loading" }
  ],
  "runtimeBehavior": {
    "description":   "At runtime, if state.loading evaluates to true, the button ignores taps and renders with reduced opacity. Taps are dropped.",
    "bindingTarget": "state.loading",
    "evaluatedAs":   [true, false]
  }
}
```

---

## Gesture contracts

### ACT-010 — Gesture onTap passes through

```json
{
  "__meta": {
    "id": "action-010-gesture-on-tap",
    "title": "action:gesture with onTap action ref compiles correctly",
    "description": "A gesture wrapper must have __subType:gesture injected and carry the full onTap action descriptor object. The renderer attaches the callback using the descriptor.",
    "tags": ["action", "gesture", "onTap"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:gesture",
    "props": {
      "onTap": { "type": "action", "name": "nav.push", "args": { "route": "/detail" } }
    },
    "children": [
      {
        "type": "box:row",
        "style": "p-4",
        "children": [
          { "type": "text", "props": { "text": "Tap to navigate" } }
        ]
      }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "gesture",
      "onTap": { "type": "action", "name": "nav.push", "args": { "route": "/detail" } }
    },
    "debugPath": "root",
    "children": [
      {
        "type": "box:row",
        "props": {},
        "debugPath": "root[0]",
        "style": "p-4",
        "children": [
          { "type": "text", "props": { "text": "Tap to navigate" }, "debugPath": "root[0][0]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                          "equals": "action" },
    { "path": "props.__subType",               "equals": "gesture" },
    { "path": "props.onTap.type",              "equals": "action" },
    { "path": "props.onTap.name",              "equals": "nav.push" },
    { "path": "props.onTap.args.route",        "equals": "/detail" },
    { "path": "children.length",               "equals": 1 }
  ],
  "runtimeBehavior": {
    "gesture":        "tap",
    "description":    "When tapped, the runtime dispatches nav.push with args.route=/detail. The navigator pushes the /detail route onto the navigation stack. The child box:row remains visible and tappable after navigation.",
    "event":          "onTap",
    "dispatches":     "nav.push",
    "args":           { "route": "/detail" },
    "expectedResult": "Navigation stack has /detail pushed on top"
  }
}
```

### ACT-011 — Gesture with multiple event handlers

```json
{
  "__meta": {
    "id": "action-011-gesture-multi-event",
    "title": "Gesture node with onTap, onLongPress, and onDoubleTap",
    "description": "Multiple gesture handlers must all survive compilation. If any key is stripped, that gesture becomes dead code.",
    "tags": ["action", "gesture", "onTap", "onLongPress", "onDoubleTap"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:gesture",
    "props": {
      "onTap": { "type": "action", "name": "item.select" },
      "onLongPress": { "type": "action", "name": "item.contextMenu" },
      "onDoubleTap": { "type": "action", "name": "item.rename" }
    },
    "children": [
      { "type": "text", "props": { "text": "Interactive item" } }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "gesture",
      "onTap": { "type": "action", "name": "item.select" },
      "onLongPress": { "type": "action", "name": "item.contextMenu" },
      "onDoubleTap": { "type": "action", "name": "item.rename" }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Interactive item" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.onTap.name",          "equals": "item.select" },
    { "path": "props.onLongPress.name",    "equals": "item.contextMenu" },
    { "path": "props.onDoubleTap.name",    "equals": "item.rename" }
  ],
  "runtimeBehavior": {
    "description": "All three gesture recognizers are registered simultaneously on the same widget. Long press fires after 500ms delay. Double tap prevents onTap from firing if a second tap is detected within 300ms."
  }
}
```

---

## Long press and double tap

### ACT-020 — Long press with delay prop

```json
{
  "__meta": {
    "id": "action-020-long-press-delay",
    "title": "action:long_press with durationMs prop compiles correctly",
    "description": "Long press delay in ms must survive compilation. Missing durationMs uses the system default (500ms), which may not match UX spec.",
    "tags": ["action", "long_press", "duration"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "action:long_press",
    "props": {
      "durationMs": 800,
      "onLongPress": { "type": "action", "name": "card.menu" }
    },
    "children": [
      { "type": "text", "props": { "text": "Hold me" } }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "long_press",
      "durationMs": 800,
      "onLongPress": { "type": "action", "name": "card.menu" }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Hold me" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "long_press" },
    { "path": "props.durationMs",          "equals": 800 },
    { "path": "props.onLongPress.name",    "equals": "card.menu" }
  ],
  "runtimeBehavior": {
    "gesture":       "long-press",
    "description":   "The gesture recognizer waits for 800ms of continuous contact before firing card.menu action.",
    "timeout":       "800ms",
    "dispatches":    "card.menu"
  }
}
```

---

## Hover contract

### ACT-030 — Hover with onEnter and onLeave

```json
{
  "__meta": {
    "id": "action-030-hover-enter-leave",
    "title": "action:hover with onEnter and onLeave compiles correctly",
    "description": "Hover interaction must carry both onEnter and onLeave. Missing either causes partial hover behavior.",
    "tags": ["action", "hover", "onEnter", "onLeave"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:hover",
    "props": {
      "onEnter": { "type": "action", "name": "tooltip.show" },
      "onLeave": { "type": "action", "name": "tooltip.hide" }
    },
    "children": [
      { "type": "text", "props": { "text": "Hover me" } }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "hover",
      "onEnter": { "type": "action", "name": "tooltip.show" },
      "onLeave": { "type": "action", "name": "tooltip.hide" }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Hover me" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "hover" },
    { "path": "props.onEnter.name",        "equals": "tooltip.show" },
    { "path": "props.onLeave.name",        "equals": "tooltip.hide" }
  ],
  "runtimeBehavior": {
    "interaction":   "pointer-hover",
    "description":   "Pointer enters widget bounds -> tooltip.show is dispatched. Pointer leaves widget bounds -> tooltip.hide is dispatched.",
    "onEnterFires":  "tooltip.show",
    "onLeaveFires":  "tooltip.hide"
  }
}
```

---

## Focus contract

### ACT-040 — Focus with onFocus and onBlur

```json
{
  "__meta": {
    "id": "action-040-focus-blur",
    "title": "action:focus with onFocus and onBlur compiles correctly",
    "description": "Focus handlers must both survive compilation. Used for accessibility and form validation triggers.",
    "tags": ["action", "focus", "onFocus", "onBlur", "accessibility"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:focus",
    "props": {
      "onFocus": { "type": "action", "name": "field.markActive" },
      "onBlur": { "type": "action", "name": "field.validate" }
    },
    "children": [
      { "type": "field", "props": { "__subType": "email", "placeholder": "Enter email" } }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "focus",
      "onFocus": { "type": "action", "name": "field.markActive" },
      "onBlur": { "type": "action", "name": "field.validate" }
    },
    "debugPath": "root",
    "children": [
      {
        "type": "field",
        "props": { "__subType": "email", "placeholder": "Enter email" },
        "debugPath": "root[0]"
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "focus" },
    { "path": "props.onFocus.name",        "equals": "field.markActive" },
    { "path": "props.onBlur.name",         "equals": "field.validate" }
  ],
  "runtimeBehavior": {
    "interaction":   "focus",
    "description":   "When the email field receives focus (via tap or keyboard tab), field.markActive is dispatched. When focus moves away, field.validate is dispatched.",
    "onFocusFires":  "field.markActive",
    "onBlurFires":   "field.validate"
  }
}
```

---

## Chip contract

### ACT-050 — Chip with selected state

```json
{
  "__meta": {
    "id": "action-050-chip-selected",
    "title": "action:chip with selected binding compiles correctly",
    "description": "A chip must carry selected as a binding. The renderer uses it to toggle the active style.",
    "tags": ["action", "chip", "selected", "binding"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "action:chip",
    "props": {
      "label": "Flutter",
      "selected": "${state.selectedTags.contains('flutter')}",
      "onToggle": { "type": "action", "name": "tags.toggle", "args": { "tag": "flutter" } }
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "chip",
      "label": "Flutter",
      "selected": "${state.selectedTags.contains('flutter')}",
      "onToggle": { "type": "action", "name": "tags.toggle", "args": { "tag": "flutter" } }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",           "equals": "chip" },
    { "path": "props.selected",            "contains": "state.selectedTags" },
    { "path": "props.onToggle.name",       "equals": "tags.toggle" },
    { "path": "props.onToggle.args.tag",   "equals": "flutter" }
  ],
  "runtimeBehavior": {
    "interaction":   "toggle",
    "description":   "At runtime, the selected binding is evaluated. If true, the chip renders as 'active'. When tapped, onToggle dispatches the tags.toggle action with tag=flutter.",
    "bindingEvaluates": "true / false",
    "dispatches":    "tags.toggle"
  }
}
```

---

## Action failure contracts

### ACT-090 — Action node with no subType must fall back to gesture

```json
{
  "__meta": {
    "id": "action-090-bare-action-type",
    "title": "Plain 'action' type with no subType compiles to gesture fallback",
    "description": "When type:'action' is used with no __subType, the core must route to the gesture default.",
    "tags": ["action", "fallback", "gesture"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "action",
    "props": {
      "onTap": { "type": "action", "name": "do.something" }
    },
    "children": [
      { "type": "text", "props": { "text": "Click me" } }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "onTap": { "type": "action", "name": "do.something" }
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Click me" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                      "equals": "action" },
    { "path": "props.__subType",           "notNull": false },
    { "path": "props.onTap.name",          "equals": "do.something" }
  ],
  "runtimeBehavior": {
    "fallback":      "gesture",
    "description":   "The runtime implicitly treats this as a gesture node and binds onTap to do.something."
  }
}
```
