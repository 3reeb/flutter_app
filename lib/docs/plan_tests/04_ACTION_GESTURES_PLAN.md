# 04 — Action & Gestures Test Plan

Every action subtype — button, gesture, hover, focus, chip, long_press, double_tap.
Every test includes compile contract, disabled-state binding, action descriptor,
pipeline array form, and executionSteps with real WidgetTester interactions.

---

## action:button

### AG-001 — Full button with intent, icon, loading, disabled state binding

```json
{
  "__meta": {
    "id": "ag-001-button-full-props",
    "title": "action:button with intent, icon, loading, and disabled binding",
    "description": "A production button must carry __subType:button, text, intent, icon, disabled binding, and loading binding. Missing any breaks the visual state machine.",
    "tags": ["action", "button", "intent", "disabled", "loading", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Save Changes",
      "intent": "primary",
      "icon": "save",
      "disabled": "${state.isSaving}",
      "loading": "${state.isSaving}",
      "onTap": { "type": "action", "name": "form.submit", "args": { "target": "profile" } }
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Save Changes",
      "intent": "primary",
      "icon": "save",
      "disabled": "${state.isSaving}",
      "loading": "${state.isSaving}",
      "onTap": { "type": "action", "name": "form.submit", "args": { "target": "profile" } }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "type",                  "equals": "action" },
    { "path": "props.__subType",       "equals": "button" },
    { "path": "props.intent",          "equals": "primary" },
    { "path": "props.intent",          "oneOf": ["primary", "secondary", "danger", "default", "ghost"] },
    { "path": "props.disabled",        "equals": "${state.isSaving}" },
    { "path": "props.disabled",        "contains": "state.isSaving" },
    { "path": "props.loading",         "equals": "${state.isSaving}" },
    { "path": "props.onTap.name",      "equals": "form.submit" },
    { "path": "props.onTap.args.target", "equals": "profile" }
  ],
  "runtimeBehavior": {
    "gesture": "tap",
    "description": "When state.isSaving is false: button is enabled, shows 'Save Changes' text. When state.isSaving is true: button is disabled, shows loading spinner. Tap fires form.submit with target:profile.",
    "dispatches": "form.submit",
    "args": { "target": "profile" }
  }
}
```

### AG-002 — Button onTap pipeline array form

```json
{
  "__meta": {
    "id": "ag-002-button-ontap-pipeline-array",
    "title": "action:button onTap as pipeline array with multiple steps",
    "description": "The pipeline array form of onTap must pass through verbatim. The runtime executes each step in sequence.",
    "tags": ["action", "button", "pipeline", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Delete",
      "intent": "danger",
      "onTap": [
        { "action": "state.set", "path": "isDeleting", "value": true },
        { "action": "api.delete", "resource": "item", "id": "${state.selectedId}" },
        { "action": "state.set", "path": "isDeleting", "value": false },
        { "action": "nav.pop" }
      ]
    }
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "button",
      "text": "Delete",
      "intent": "danger",
      "onTap": [
        { "action": "state.set", "path": "isDeleting", "value": true },
        { "action": "api.delete", "resource": "item", "id": "${state.selectedId}" },
        { "action": "state.set", "path": "isDeleting", "value": false },
        { "action": "nav.pop" }
      ]
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.__subType",          "equals": "button" },
    { "path": "props.intent",             "equals": "danger" },
    { "path": "props.onTap.length",       "equals": 4 },
    { "path": "props.onTap[0].action",    "equals": "state.set" },
    { "path": "props.onTap[1].action",    "equals": "api.delete" },
    { "path": "props.onTap[3].action",    "equals": "nav.pop" }
  ]
}
```

### AG-003 — Button with executionSteps: tap, expectState, confirm counter increments

```json
{
  "__meta": {
    "id": "ag-003-button-tap-increments-counter",
    "title": "Tapping an increment button updates state.count in the live store",
    "description": "A button bound to an increment action must update the reactive store when tapped. The executionSteps verify the live state, not just the blueprint.",
    "tags": ["action", "button", "execution", "state", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "count": 0 },
    "type": "box:col",
    "style": "p-4 gap-4",
    "children": [
      { "type": "text", "props": { "text": "Count: ${state.count}" } },
      {
        "type": "action:button",
        "props": {
          "text": "Increment",
          "intent": "primary",
          "onTap": [{ "action": "increment", "path": "count", "amount": 1 }]
        }
      }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "count": 0 } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:col",
      "props": {},
      "debugPath": "root",
      "style": "p-4 gap-4",
      "children": [
        { "type": "text", "props": { "text": "Count: ${state.count}" }, "debugPath": "root[0]" },
        {
          "type": "action",
          "props": {
            "__subType": "button",
            "text": "Increment",
            "intent": "primary",
            "onTap": [{ "action": "increment", "path": "count", "amount": 1 }]
          },
          "debugPath": "root[1]"
        }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "props.initialState.count",                "equals": 0 },
    { "path": "children[0].children[1].props.__subType", "equals": "button" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Increment" },
    { "action": "tap", "finder": { "type": "text", "match": "Increment" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "count", "equals": 1 },
    { "action": "tap", "finder": { "type": "text", "match": "Increment" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "count", "equals": 2 },
    { "action": "repeat", "times": 3, "steps": [
      { "action": "tap", "finder": { "type": "text", "match": "Increment" } },
      { "action": "pumpAndSettle" }
    ]},
    { "action": "expectState", "path": "count", "equals": 5 }
  ]
}
```

### AG-004 — Button danger variant with confirmation dialog flow

```json
{
  "__meta": {
    "id": "ag-004-button-danger-confirm-flow",
    "title": "Danger button opens confirmation overlay before destructive action",
    "description": "A delete button should open a confirm dialog first. Cancel does not dispatch delete. Confirm does. Tests two-step destructive action flow.",
    "tags": ["action", "button", "danger", "portal", "execution", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "showConfirm": false, "deleted": false },
    "type": "box:col",
    "children": [
      {
        "type": "action:button",
        "props": {
          "text": "Delete Account",
          "intent": "danger",
          "onTap": [{ "action": "state.set", "path": "showConfirm", "value": true }]
        }
      },
      {
        "type": "portal:overlay",
        "props": {
          "visible": "${state.showConfirm}",
          "onDismiss": { "type": "action", "name": "state.set", "args": { "path": "showConfirm", "value": false } }
        },
        "children": [
          { "type": "box:col", "style": "bg-white rounded-2 p-6 gap-4", "children": [
            { "type": "text", "props": { "text": "Are you sure? This cannot be undone." } },
            { "type": "box:row", "style": "gap-2", "children": [
              { "type": "action:button", "props": { "text": "Cancel", "intent": "secondary",
                "onTap": [{ "action": "state.set", "path": "showConfirm", "value": false }] } },
              { "type": "action:button", "props": { "text": "Confirm Delete", "intent": "danger",
                "onTap": [
                  { "action": "state.set", "path": "deleted", "value": true },
                  { "action": "state.set", "path": "showConfirm", "value": false }
                ] } }
            ]}
          ]}
        ]
      }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "showConfirm": false, "deleted": false } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:col", "props": {}, "debugPath": "root",
      "children": [
        {
          "type": "action",
          "props": { "__subType": "button", "text": "Delete Account", "intent": "danger",
            "onTap": [{ "action": "state.set", "path": "showConfirm", "value": true }] },
          "debugPath": "root[0]"
        },
        {
          "type": "portal",
          "props": { "__subType": "overlay", "visible": "${state.showConfirm}",
            "onDismiss": { "type": "action", "name": "state.set", "args": { "path": "showConfirm", "value": false } } },
          "debugPath": "root[1]",
          "children": [{
            "type": "box:col", "props": {}, "debugPath": "root[1][0]", "style": "bg-white rounded-2 p-6 gap-4",
            "children": [
              { "type": "text", "props": { "text": "Are you sure? This cannot be undone." }, "debugPath": "root[1][0][0]" },
              { "type": "box:row", "props": {}, "debugPath": "root[1][0][1]", "style": "gap-2", "children": [
                { "type": "action", "props": { "__subType": "button", "text": "Cancel", "intent": "secondary",
                  "onTap": [{ "action": "state.set", "path": "showConfirm", "value": false }] }, "debugPath": "root[1][0][1][0]" },
                { "type": "action", "props": { "__subType": "button", "text": "Confirm Delete", "intent": "danger",
                  "onTap": [
                    { "action": "state.set", "path": "deleted", "value": true },
                    { "action": "state.set", "path": "showConfirm", "value": false }
                  ] }, "debugPath": "root[1][0][1][1]" }
              ]}
            ]
          }]
        }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "props.initialState.showConfirm", "equals": false },
    { "path": "props.initialState.deleted",     "equals": false }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "showConfirm", "equals": false },
    { "action": "tap", "finder": { "type": "text", "match": "Delete Account" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "showConfirm", "equals": true },
    { "action": "tap", "finder": { "type": "text", "match": "Cancel" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "showConfirm", "equals": false },
    { "action": "expectState", "path": "deleted", "equals": false },
    { "action": "tap", "finder": { "type": "text", "match": "Delete Account" } },
    { "action": "pumpAndSettle" },
    { "action": "tap", "finder": { "type": "text", "match": "Confirm Delete" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "deleted", "equals": true },
    { "action": "expectState", "path": "showConfirm", "equals": false }
  ]
}
```

---

## action:gesture

### AG-010 — Gesture with onTap, onLongPress, onDoubleTap all active

```json
{
  "__meta": {
    "id": "ag-010-gesture-three-handlers",
    "title": "action:gesture with onTap, onLongPress, onDoubleTap all surviving compilation",
    "description": "A list card that supports tap (open), long-press (context menu), and double-tap (quick-edit) must have all three handlers intact. If any is stripped, that gesture becomes dead code.",
    "tags": ["action", "gesture", "onTap", "onLongPress", "onDoubleTap", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "action:gesture",
    "props": {
      "onTap":       { "type": "action", "name": "item.open",        "args": { "id": "${item.id}" } },
      "onLongPress": { "type": "action", "name": "item.contextMenu", "args": { "id": "${item.id}" } },
      "onDoubleTap": { "type": "action", "name": "item.quickEdit",   "args": { "id": "${item.id}" } }
    },
    "children": [
      {
        "type": "box:row",
        "style": "p-3 gap-3 items-center",
        "children": [
          { "type": "media", "props": { "__subType": "avatar", "src": "${item.avatar}" } },
          { "type": "text", "props": { "text": "${item.title}" } }
        ]
      }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "gesture",
      "onTap":       { "type": "action", "name": "item.open",        "args": { "id": "${item.id}" } },
      "onLongPress": { "type": "action", "name": "item.contextMenu", "args": { "id": "${item.id}" } },
      "onDoubleTap": { "type": "action", "name": "item.quickEdit",   "args": { "id": "${item.id}" } }
    },
    "debugPath": "root",
    "children": [
      {
        "type": "box:row",
        "props": {},
        "debugPath": "root[0]",
        "style": "p-3 gap-3 items-center",
        "children": [
          { "type": "media", "props": { "__subType": "avatar", "src": "${item.avatar}" }, "debugPath": "root[0][0]" },
          { "type": "text", "props": { "text": "${item.title}" }, "debugPath": "root[0][1]" }
        ]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                     "equals": "action" },
    { "path": "props.__subType",          "equals": "gesture" },
    { "path": "props.onTap.name",         "equals": "item.open" },
    { "path": "props.onLongPress.name",   "equals": "item.contextMenu" },
    { "path": "props.onDoubleTap.name",   "equals": "item.quickEdit" },
    { "path": "children.length",          "equals": 1 },
    { "path": "children[0].type",         "equals": "box:row" }
  ],
  "runtimeBehavior": {
    "description": "Single tap fires item.open. Long press (500ms+) fires item.contextMenu. Double tap prevents the single-tap onTap from firing and fires item.quickEdit instead. All three recognizers are active simultaneously."
  }
}
```

### AG-011 — Gesture with nav.push and args

```json
{
  "__meta": {
    "id": "ag-011-gesture-nav-push",
    "title": "action:gesture onTap dispatches nav.push to detail screen",
    "description": "A tappable list row must navigate to the detail screen. The args.route and args.params must survive compilation.",
    "tags": ["action", "gesture", "navigation", "onTap", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "tapped": false },
    "type": "action:gesture",
    "props": {
      "onTap": { "type": "action", "name": "nav.push", "args": { "route": "/product/detail", "params": { "id": "${item.id}", "from": "list" } } }
    },
    "children": [
      { "type": "text", "props": { "text": "Navigate to Detail" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "tapped": false } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "action",
      "props": {
        "__subType": "gesture",
        "onTap": { "type": "action", "name": "nav.push", "args": { "route": "/product/detail", "params": { "id": "${item.id}", "from": "list" } } }
      },
      "debugPath": "root",
      "children": [
        { "type": "text", "props": { "text": "Navigate to Detail" }, "debugPath": "root[0]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType",               "equals": "gesture" },
    { "path": "children[0].props.onTap.name",              "equals": "nav.push" },
    { "path": "children[0].props.onTap.args.route",        "equals": "/product/detail" },
    { "path": "children[0].props.onTap.args.params.from",  "equals": "list" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Navigate to Detail" },
    { "action": "tap", "finder": { "type": "text", "match": "Navigate to Detail" } },
    { "action": "pumpAndSettle" }
  ]
}
```

---

## action:hover

### AG-020 — Hover with tooltip show/hide

```json
{
  "__meta": {
    "id": "ag-020-hover-tooltip-show-hide",
    "title": "action:hover onEnter shows tooltip, onLeave hides it",
    "description": "A hover wrapper for a help icon must fire tooltip.show on enter and tooltip.hide on leave. Both handlers must survive compilation.",
    "tags": ["action", "hover", "tooltip", "onEnter", "onLeave", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:hover",
    "props": {
      "onEnter": { "type": "action", "name": "tooltip.show", "args": { "id": "help-tooltip", "text": "Click for help" } },
      "onLeave": { "type": "action", "name": "tooltip.hide", "args": { "id": "help-tooltip" } }
    },
    "children": [
      { "type": "media", "props": { "__subType": "icon", "name": "help_outline", "size": 20 } }
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "hover",
      "onEnter": { "type": "action", "name": "tooltip.show", "args": { "id": "help-tooltip", "text": "Click for help" } },
      "onLeave": { "type": "action", "name": "tooltip.hide", "args": { "id": "help-tooltip" } }
    },
    "debugPath": "root",
    "children": [
      { "type": "media", "props": { "__subType": "icon", "name": "help_outline", "size": 20 }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",            "equals": "hover" },
    { "path": "props.onEnter.name",         "equals": "tooltip.show" },
    { "path": "props.onEnter.args.id",      "equals": "help-tooltip" },
    { "path": "props.onLeave.name",         "equals": "tooltip.hide" },
    { "path": "children[0].props.__subType", "equals": "icon" }
  ],
  "runtimeBehavior": {
    "interaction": "pointer-hover",
    "description": "Pointer enters icon bounds → tooltip.show dispatched with id:help-tooltip. Tooltip widget appears. Pointer leaves → tooltip.hide dispatched. Tooltip widget disappears.",
    "onEnterFires": "tooltip.show",
    "onLeaveFires": "tooltip.hide"
  }
}
```

---

## action:focus

### AG-030 — Focus with onFocus (mark active) and onBlur (validate)

```json
{
  "__meta": {
    "id": "ag-030-focus-blur-validate",
    "title": "action:focus wraps email field with onFocus and onBlur validation",
    "description": "A focus wrapper activates validation on blur. onFocus marks the field as touched. onBlur triggers field.validate. Both handlers must compile correctly.",
    "tags": ["action", "focus", "onFocus", "onBlur", "validation", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "emailTouched": false, "emailError": "" },
    "type": "action:focus",
    "props": {
      "onFocus": [
        { "action": "state.set", "path": "emailTouched", "value": true }
      ],
      "onBlur": [
        { "action": "field.validate", "field": "email", "rule": "required|email" },
        { "action": "state.set", "path": "emailError", "value": "${validationResult.email}" }
      ]
    },
    "children": [
      { "type": "field", "props": { "__subType": "email", "placeholder": "Enter email address", "bind": "${state.emailValue}" } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "emailTouched": false, "emailError": "" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "action",
      "props": {
        "__subType": "focus",
        "onFocus": [{ "action": "state.set", "path": "emailTouched", "value": true }],
        "onBlur": [
          { "action": "field.validate", "field": "email", "rule": "required|email" },
          { "action": "state.set", "path": "emailError", "value": "${validationResult.email}" }
        ]
      },
      "debugPath": "root",
      "children": [
        { "type": "field", "props": { "__subType": "email", "placeholder": "Enter email address", "bind": "${state.emailValue}" }, "debugPath": "root[0]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.__subType",         "equals": "focus" },
    { "path": "children[0].props.onFocus.length",    "equals": 1 },
    { "path": "children[0].props.onBlur.length",     "equals": 2 },
    { "path": "children[0].props.onFocus[0].action", "equals": "state.set" },
    { "path": "children[0].props.onBlur[0].action",  "equals": "field.validate" }
  ]
}
```

---

## action:chip

### AG-040 — Chip filter group with mutual exclusivity

```json
{
  "__meta": {
    "id": "ag-040-chip-filter-group-mutual-exclusive",
    "title": "Chip filter group — selecting one deselects others",
    "description": "A filter bar with status chips (All, Active, Archived). Selecting one sets state.filter. Each chip's selected binding checks against state.filter.",
    "tags": ["action", "chip", "filter", "selected", "execution", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "filter": "all" },
    "type": "box:row",
    "style": "gap-2 p-2",
    "children": [
      { "type": "action:chip", "props": { "label": "All",      "selected": "${state.filter == 'all'}",      "onToggle": { "type": "action", "name": "state.set", "args": { "path": "filter", "value": "all" } } } },
      { "type": "action:chip", "props": { "label": "Active",   "selected": "${state.filter == 'active'}",   "onToggle": { "type": "action", "name": "state.set", "args": { "path": "filter", "value": "active" } } } },
      { "type": "action:chip", "props": { "label": "Archived", "selected": "${state.filter == 'archived'}", "onToggle": { "type": "action", "name": "state.set", "args": { "path": "filter", "value": "archived" } } } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "filter": "all" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:row", "props": {}, "debugPath": "root", "style": "gap-2 p-2",
      "children": [
        { "type": "action", "props": { "__subType": "chip", "label": "All",      "selected": "${state.filter == 'all'}",      "onToggle": { "type": "action", "name": "state.set", "args": { "path": "filter", "value": "all" } } }, "debugPath": "root[0]" },
        { "type": "action", "props": { "__subType": "chip", "label": "Active",   "selected": "${state.filter == 'active'}",   "onToggle": { "type": "action", "name": "state.set", "args": { "path": "filter", "value": "active" } } }, "debugPath": "root[1]" },
        { "type": "action", "props": { "__subType": "chip", "label": "Archived", "selected": "${state.filter == 'archived'}", "onToggle": { "type": "action", "name": "state.set", "args": { "path": "filter", "value": "archived" } } }, "debugPath": "root[2]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "props.initialState.filter",              "equals": "all" },
    { "path": "children[0].children[0].props.__subType", "equals": "chip" },
    { "path": "children[0].children.length",             "equals": 3 }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "filter", "equals": "all" },
    { "action": "tap", "finder": { "type": "text", "match": "Active" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "filter", "equals": "active" },
    { "action": "tap", "finder": { "type": "text", "match": "Archived" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "filter", "equals": "archived" },
    { "action": "tap", "finder": { "type": "text", "match": "All" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "filter", "equals": "all" }
  ]
}
```

---

## action:long_press

### AG-050 — Long press with 800ms duration and context menu

```json
{
  "__meta": {
    "id": "ag-050-long-press-800ms-context-menu",
    "title": "action:long_press with 800ms durationMs and context menu dispatch",
    "description": "A file item that shows a context menu on long press. durationMs:800 and onLongPress action must survive compilation.",
    "tags": ["action", "long_press", "duration", "context_menu", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "action:long_press",
    "props": {
      "durationMs": 800,
      "onLongPress": { "type": "action", "name": "file.contextMenu", "args": { "fileId": "${item.id}", "position": "pointer" } }
    },
    "children": [
      { "type": "box:row", "style": "p-3 gap-3", "children": [
        { "type": "media", "props": { "__subType": "icon", "name": "folder", "size": 24 } },
        { "type": "text", "props": { "text": "${item.name}" } }
      ]}
    ]
  },
  "expected": {
    "type": "action",
    "props": {
      "__subType": "long_press",
      "durationMs": 800,
      "onLongPress": { "type": "action", "name": "file.contextMenu", "args": { "fileId": "${item.id}", "position": "pointer" } }
    },
    "debugPath": "root",
    "children": [
      { "type": "box:row", "props": {}, "debugPath": "root[0]", "style": "p-3 gap-3", "children": [
        { "type": "media", "props": { "__subType": "icon", "name": "folder", "size": 24 }, "debugPath": "root[0][0]" },
        { "type": "text", "props": { "text": "${item.name}" }, "debugPath": "root[0][1]" }
      ]}
    ]
  },
  "runtimeAssertions": [
    { "path": "props.__subType",            "equals": "long_press" },
    { "path": "props.durationMs",           "equals": 800 },
    { "path": "props.durationMs",           "greaterThan": 0 },
    { "path": "props.onLongPress.name",     "equals": "file.contextMenu" },
    { "path": "props.onLongPress.args.position", "equals": "pointer" }
  ],
  "runtimeBehavior": {
    "gesture": "long-press",
    "description": "Gesture recognizer waits for 800ms of continuous contact. After 800ms, dispatches file.contextMenu with fileId and position:pointer. Short taps (<800ms) do not fire the action.",
    "timeout": "800ms",
    "dispatches": "file.contextMenu"
  }
}
```

---

## Complete Action & Gestures Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| ag-001 | button full props: intent, icon, disabled, loading | critical |
| ag-002 | button onTap as pipeline array | critical |
| ag-003 | button tap increments counter (execution) | critical |
| ag-004 | button danger with confirm dialog flow (execution) | critical |
| ag-005 | button with secondary intent | high |
| ag-006 | button with ghost/outline intent | medium |
| ag-007 | button disabled blocks tap (execution) | high |
| ag-008 | button with loading spinner (execution) | high |
| ag-009 | button icon-only (no text prop) | medium |
| ag-010 | gesture three handlers: tap+longPress+doubleTap | critical |
| ag-011 | gesture nav.push with params | critical |
| ag-012 | gesture with state toggle on tap | high |
| ag-013 | gesture onDragStart/onDragEnd lifecycle | high |
| ag-014 | gesture no subType falls back to gesture | medium |
| ag-020 | hover tooltip show/hide | high |
| ag-021 | hover state toggle (isHovered binding) | high |
| ag-022 | hover with onMove handler | medium |
| ag-030 | focus/blur validation trigger | high |
| ag-031 | focus with keyboard tab navigation | high |
| ag-032 | focus with form field error display | high |
| ag-040 | chip filter group mutual exclusivity (execution) | high |
| ag-041 | chip multi-select (multiple chips active) | high |
| ag-042 | chip with badge count | medium |
| ag-050 | long_press 800ms context menu | high |
| ag-051 | long_press default 500ms | medium |
| ag-052 | long_press prevented when disabled | medium |
| ag-060 | double_tap quick-edit action | medium |
| ag-061 | double_tap prevents single-tap firing | medium |
