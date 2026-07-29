# 06 — Widget Tests

JSON contracts for layout constraints, sizing, dragging, resizing, rotating, and widget-level behavior.

---

## What "widget tests" mean in the JSON contract

Widget tests verify three things simultaneously:

1. **Blueprint shape** (`expected`) — the compiled output has the exact props the runtime needs.
2. **Runtime assertions** (`runtimeAssertions`) — every individual prop value is checked at its exact type and value using path-based extractors. This catches silent type coercions, missing sub-keys, and wrong enum values.
3. **Runtime behavior** (`runtimeBehavior`) — annotates what the widget does when the user interacts with it. This documents the gesture math (offsets, clamp values, snap increments) in the same test file that checks the compiled output.

### Why runtimeAssertions?

The `expected` snapshot checks the full blueprint structure at once and fails on any diff. `runtimeAssertions` provides surgical per-prop checks:

```
expected snapshot: fails if "handles[4]" is "ne" but expected "nw" — tells you there is a diff
runtimeAssertion:  { "path": "props.handles[4]", "equals": "ne" } — tells you exactly what value the runtime will see
```

Use both together. The snapshot tells you *that* something changed. The assertions tell you *what* the runtime will use at execution time.

---

## runtimeAssertions field syntax

```json
"runtimeAssertions": [
  { "path": "props.draggable",           "equals": true },
  { "path": "props.dragAxis",            "oneOf": ["x", "y", "both"] },
  { "path": "props.handles[0]",          "equals": "n" },
  { "path": "props.handles.length",      "equals": 8 },
  { "path": "props.minWidth",            "greaterThan": 0 },
  { "path": "props.maxWidth",            "lessThan": 9999 },
  { "path": "props.dragHandleSelector",  "startsWith": "." },
  { "path": "props.bind",               "contains": "state." },
  { "path": "props.angle",              "notNull": true }
]
```

| Operator | Type | What it checks |
|---|---|---|
| `equals` | any | Exact value match |
| `oneOf` | array | Value is one of the listed options |
| `greaterThan` | number | Numeric lower bound (exclusive) |
| `lessThan` | number | Numeric upper bound (exclusive) |
| `startsWith` | string | String prefix match |
| `contains` | string | Substring match |
| `notNull` | boolean | Path exists and value is non-null |
| `length` | number | Array/string/map length check |

### Path syntax

```
"props.draggable"       → node.props.draggable
"props.handles[0]"      → node.props.handles[0]
"props.handles.length"  → node.props.handles.length  (array length)
"children[0].type"      → node.children[0].type
"children[0].props.text" → node.children[0].props.text
"debugPath"             → node.debugPath
```

---

## runtimeBehavior field

Use `runtimeBehavior` to document widget-level gesture results in the test file itself. This is **not asserted programmatically** by the JSON runner (it requires WidgetTester), but it is printed during test execution and lives alongside the compiled output check:

```json
"runtimeBehavior": {
  "gesture":         "drag",
  "description":     "Dragging 100px right gives offsetX:100",
  "axis":            "x",
  "deltaX":          100,
  "expectedOffsetX": 100
}
```

For resize:
```json
"runtimeBehavior": {
  "gesture":            "resize",
  "handle":             "e",
  "dragDeltaX":         100,
  "initialWidth":       400,
  "expectedWidth":      500,
  "clampMax":           800
}
```

For rotate:
```json
"runtimeBehavior": {
  "gesture":           "rotate",
  "initialAngle":      0.0,
  "gestureRotateDelta": 60.0,
  "snapAngle":         45.0,
  "expectedAngle":     45.0
}
```

---

## Folder: `cases/widget/`

Naming: `widget_NNN_NNN.json`

---

## Sizing contracts

### WGT-001 — Fixed width and height props round-trip

```json
{
  "__meta": {
    "id": "widget-001-fixed-size",
    "title": "Fixed width and height props compile verbatim",
    "description": "A box with explicit width/height must carry those values unchanged. The VM must not strip or coerce numeric sizing props.",
    "tags": ["widget", "sizing", "width", "height"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:row",
    "props": { "width": 320, "height": 48 },
    "children": []
  },
  "expected": {
    "type": "box:row",
    "props": { "width": 320, "height": 48 },
    "debugPath": "root",
    "children": []
  },
  "runtimeAssertions": [
    { "path": "props.width",  "equals": 320 },
    { "path": "props.height", "equals": 48 },
    { "path": "props.width",  "greaterThan": 0 },
    { "path": "props.height", "greaterThan": 0 }
  ],
  "runtimeBehavior": {
    "description": "The box renders at exactly 320×48 logical pixels regardless of parent constraints."
  }
}
```

### WGT-002 — String sizing (CSS-like) round-trips

```json
{
  "__meta": {
    "id": "widget-002-string-sizing",
    "title": "String width/height values pass through unchanged",
    "description": "Width expressed as '100%' or 'fill' must not be cast to a number.",
    "tags": ["widget", "sizing", "string"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "props": { "width": "fill", "height": "auto" }
  },
  "expected": {
    "type": "box:col",
    "props": { "width": "fill", "height": "auto" },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.width",  "equals": "fill" },
    { "path": "props.height", "equals": "auto" },
    { "path": "props.width",  "oneOf": ["fill", "auto", "wrap", "expand"] }
  ],
  "runtimeBehavior": {
    "description": "width:'fill' expands to full parent width. height:'auto' sizes to intrinsic content height."
  }
}
```

### WGT-003 — `box:aspect` ratio prop compiles correctly

```json
{
  "__meta": {
    "id": "widget-003-aspect-ratio",
    "title": "box:aspect ratio prop is preserved",
    "description": "An aspect box must carry the ratio prop. Dropping it collapses the child to zero height.",
    "tags": ["widget", "aspect", "ratio", "sizing"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:aspect",
    "props": { "ratio": 1.777 },
    "children": [
      { "type": "media", "props": { "__subType": "video", "src": "${state.videoUrl}" } }
    ]
  },
  "expected": {
    "type": "box:aspect",
    "props": { "ratio": 1.777 },
    "debugPath": "root",
    "children": [
      {
        "type": "media",
        "props": { "__subType": "video", "src": "${state.videoUrl}" },
        "debugPath": "root[0]"
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.ratio",    "equals": 1.777 },
    { "path": "props.ratio",    "greaterThan": 1 },
    { "path": "children.length", "equals": 1 },
    { "path": "children[0].props.__subType", "equals": "video" }
  ],
  "runtimeBehavior": {
    "description": "box:aspect renders at ratio 16:9 (~1.777). Height = width / 1.777. Gives 16:9 video aspect regardless of parent width."
  }
}
```

---

## Drag contracts

### WGT-010 — Draggable prop compiles correctly

```json
{
  "__meta": {
    "id": "widget-010-draggable-prop",
    "title": "draggable prop on box node compiles verbatim",
    "description": "A box with draggable:true must carry that prop in the compiled blueprint. Missing it disables drag entirely.",
    "tags": ["widget", "drag", "props"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "draggable": true,
      "dragAxis": "both",
      "dragHandleSelector": ".drag-handle"
    },
    "children": [
      { "type": "text", "props": { "text": "Drag me" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {
      "draggable": true,
      "dragAxis": "both",
      "dragHandleSelector": ".drag-handle"
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Drag me" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.draggable",          "equals": true },
    { "path": "props.dragAxis",           "equals": "both" },
    { "path": "props.dragAxis",           "oneOf": ["x", "y", "both"] },
    { "path": "props.dragHandleSelector", "startsWith": "." }
  ],
  "runtimeBehavior": {
    "gesture":         "drag",
    "description":     "dragAxis:both allows movement in X and Y. dragHandleSelector restricts the drag trigger to the .drag-handle element.",
    "axis":            "both",
    "deltaX":          50,
    "deltaY":          30,
    "expectedOffsetX": 50,
    "expectedOffsetY": 30
  }
}
```

### WGT-011 — Drag with constrained axis

```json
{
  "__meta": {
    "id": "widget-011-drag-axis-constrained",
    "title": "dragAxis:x constrains drag to horizontal only",
    "description": "A horizontally constrained draggable must have dragAxis:'x'. The runtime uses this to lock Y movement.",
    "tags": ["widget", "drag", "axis"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:row",
    "props": { "draggable": true, "dragAxis": "x" }
  },
  "expected": {
    "type": "box:row",
    "props": { "draggable": true, "dragAxis": "x" },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.draggable", "equals": true },
    { "path": "props.dragAxis",  "equals": "x" }
  ],
  "runtimeBehavior": {
    "gesture":         "drag",
    "description":     "Y movement is clamped to 0. Dragging diagonally 100px right, 80px down results in offset {dx:100, dy:0}.",
    "axis":            "x",
    "rawDeltaX":       100,
    "rawDeltaY":       80,
    "expectedOffsetX": 100,
    "expectedOffsetY": 0
  }
}
```

### WGT-012 — Drag with snap grid

```json
{
  "__meta": {
    "id": "widget-012-drag-snap-grid",
    "title": "snapToGrid prop compiles with grid size",
    "description": "A draggable with grid snapping must carry snapToGrid and gridSize props. Missing gridSize defaults to 1 (no snap).",
    "tags": ["widget", "drag", "snap", "grid"],
    "allowBlank": false,
    "priority": "medium"
  },
  "input": {
    "type": "box:col",
    "props": { "draggable": true, "snapToGrid": true, "gridSize": 16 }
  },
  "expected": {
    "type": "box:col",
    "props": { "draggable": true, "snapToGrid": true, "gridSize": 16 },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.draggable",  "equals": true },
    { "path": "props.snapToGrid", "equals": true },
    { "path": "props.gridSize",   "equals": 16 },
    { "path": "props.gridSize",   "greaterThan": 0 }
  ],
  "runtimeBehavior": {
    "gesture":           "drag",
    "description":       "Dragging 20px right snaps to 16px (nearest multiple of gridSize:16). Dragging 10px snaps to 16px (rounds to nearest).",
    "gridSize":          16,
    "rawDeltaX":         20,
    "expectedSnappedX":  16,
    "rawDeltaX2":        10,
    "expectedSnappedX2": 16
  }
}
```

### WGT-061 — Drag with onDragStart/onDragEnd action handlers

```json
{
  "__meta": {
    "id": "widget-061-drag-with-handlers",
    "title": "Draggable widget with onDragStart and onDragEnd action handlers",
    "description": "Drag lifecycle handlers must survive compilation. The runtime fires them at gesture start and end.",
    "tags": ["widget", "drag", "handlers", "action"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "draggable": true,
      "dragAxis": "both",
      "initialX": 0,
      "initialY": 0,
      "onDragStart":  { "type": "action", "name": "drag.start" },
      "onDragEnd":    { "type": "action", "name": "drag.end", "args": { "persist": true } },
      "onDragUpdate": { "type": "action", "name": "drag.update" }
    }
  },
  "expected": {
    "type": "box:col",
    "props": {
      "draggable": true,
      "dragAxis": "both",
      "initialX": 0,
      "initialY": 0,
      "onDragStart":  { "type": "action", "name": "drag.start" },
      "onDragEnd":    { "type": "action", "name": "drag.end", "args": { "persist": true } },
      "onDragUpdate": { "type": "action", "name": "drag.update" }
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.draggable",               "equals": true },
    { "path": "props.initialX",                "equals": 0 },
    { "path": "props.initialY",                "equals": 0 },
    { "path": "props.onDragStart.name",        "equals": "drag.start" },
    { "path": "props.onDragEnd.name",          "equals": "drag.end" },
    { "path": "props.onDragEnd.args.persist",  "equals": true },
    { "path": "props.onDragUpdate.name",       "equals": "drag.update" }
  ],
  "runtimeBehavior": {
    "gesture":           "drag",
    "lifecycleEvents":   ["onDragStart", "onDragUpdate × N", "onDragEnd"],
    "onDragEndPayload":  { "dx": 100, "dy": 50 }
  }
}
```

---

## Resize contracts

### WGT-020 — Resizable props compile correctly

```json
{
  "__meta": {
    "id": "widget-020-resizable-handles",
    "title": "Resizable box with all handles compiles correctly",
    "description": "A resizable box must carry resizable:true and the handles array. Missing handles disables resize directions.",
    "tags": ["widget", "resize", "handles"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "resizable": true,
      "handles": ["n", "s", "e", "w", "ne", "nw", "se", "sw"],
      "minWidth": 120,
      "minHeight": 80,
      "maxWidth": 800,
      "maxHeight": 600
    },
    "children": [
      { "type": "text", "props": { "text": "Resize me" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {
      "resizable": true,
      "handles": ["n", "s", "e", "w", "ne", "nw", "se", "sw"],
      "minWidth": 120,
      "minHeight": 80,
      "maxWidth": 800,
      "maxHeight": 600
    },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Resize me" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.resizable",      "equals": true },
    { "path": "props.handles.length", "equals": 8 },
    { "path": "props.handles[0]",     "equals": "n" },
    { "path": "props.handles[6]",     "equals": "se" },
    { "path": "props.minWidth",       "equals": 120 },
    { "path": "props.maxWidth",       "equals": 800 },
    { "path": "props.minWidth",       "greaterThan": 0 },
    { "path": "props.maxWidth",       "greaterThan": 120 }
  ],
  "runtimeBehavior": {
    "gesture":           "resize",
    "description":       "Dragging 'e' handle 200px right: width += 200 (capped at maxWidth:800). Corner handles change both dimensions simultaneously.",
    "eastDragDelta":     200,
    "expectedWidthChange": "+200 (capped at maxWidth 800)"
  }
}
```

### WGT-021 — Resize with only horizontal handles

```json
{
  "__meta": {
    "id": "widget-021-resize-horizontal-only",
    "title": "Resizable with only e/w handles limits resize to width",
    "description": "East and west handles let users change width only. Missing n/s handles must not enable vertical resize.",
    "tags": ["widget", "resize", "horizontal"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:col",
    "props": { "resizable": true, "handles": ["e", "w"] }
  },
  "expected": {
    "type": "box:col",
    "props": { "resizable": true, "handles": ["e", "w"] },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.resizable",      "equals": true },
    { "path": "props.handles.length", "equals": 2 },
    { "path": "props.handles[0]",     "equals": "e" },
    { "path": "props.handles[1]",     "equals": "w" }
  ],
  "runtimeBehavior": {
    "gesture":          "resize",
    "description":      "Only horizontal resize allowed. Vertical drag on handles is ignored. Height remains constant.",
    "heightChange":     0,
    "verticalDragIgnored": true
  }
}
```

### WGT-062 — Resize with onResizeStart/onResizeEnd handlers

```json
{
  "__meta": {
    "id": "widget-062-resize-with-lifecycle-handlers",
    "title": "Resizable widget with onResizeStart, onResizeEnd, and min/max constraints",
    "description": "Resize lifecycle handlers and dimension constraints must all survive compilation.",
    "tags": ["widget", "resize", "handlers", "constraints"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "resizable": true,
      "handles": ["e", "w", "s", "se"],
      "width": 400, "height": 300,
      "minWidth": 200, "maxWidth": 800,
      "minHeight": 150, "maxHeight": 600,
      "onResizeStart": { "type": "action", "name": "resize.start" },
      "onResizeEnd":   { "type": "action", "name": "resize.end", "args": { "emitDimensions": true } }
    }
  },
  "expected": { "... see actual test file ..." },
  "runtimeAssertions": [
    { "path": "props.resizable",                     "equals": true },
    { "path": "props.handles.length",                "equals": 4 },
    { "path": "props.width",                         "equals": 400 },
    { "path": "props.onResizeEnd.args.emitDimensions", "equals": true }
  ],
  "runtimeBehavior": {
    "gesture":            "resize",
    "onResizeEndPayload": { "width": 500, "height": 300 }
  }
}
```

---

## Rotate contracts

### WGT-060 — Rotatable with angle constraints

```json
{
  "__meta": {
    "id": "widget-060-rotate-angle-constraints",
    "title": "Rotatable widget with angle, minAngle, maxAngle compiles correctly",
    "description": "rotatable:true plus angle/minAngle/maxAngle/snapAngle must all survive compilation. The runtime uses these to clamp and snap rotation.",
    "tags": ["widget", "rotate", "angle", "constraints"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "rotatable": true,
      "angle": 45.0,
      "minAngle": -90.0,
      "maxAngle": 90.0,
      "snapAngle": 15.0
    }
  },
  "expected": {
    "type": "box:col",
    "props": {
      "rotatable": true,
      "angle": 45.0,
      "minAngle": -90.0,
      "maxAngle": 90.0,
      "snapAngle": 15.0
    },
    "debugPath": "root"
  },
  "runtimeAssertions": [
    { "path": "props.rotatable", "equals": true },
    { "path": "props.angle",     "equals": 45.0 },
    { "path": "props.minAngle",  "equals": -90.0 },
    { "path": "props.maxAngle",  "equals": 90.0 },
    { "path": "props.snapAngle", "equals": 15.0 },
    { "path": "props.angle",     "greaterThan": -91 },
    { "path": "props.angle",     "lessThan": 91 }
  ],
  "runtimeBehavior": {
    "gesture":           "rotate",
    "description":       "Rotating +60° from 45° gives 90° (clamped at maxAngle). snapAngle:15 snaps to nearest 15° increment.",
    "initialAngle":      45.0,
    "gestureAngle":      60.0,
    "expectedAngle":     90.0,
    "clampedByMaxAngle": true,
    "snapAngle":         15.0
  }
}
```

### WGT-064 — Rotate with snap and lifecycle handlers

```json
{
  "__meta": {
    "id": "widget-064-rotate-snap-angle",
    "title": "Rotate widget with snap angle and lifecycle handlers",
    "description": "snapAngle:45 snaps rotation to multiples of 45°. Handlers fire at start/end of gesture.",
    "tags": ["widget", "rotate", "snap", "handlers"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:row",
    "props": {
      "rotatable": true,
      "angle": 0.0,
      "snapAngle": 45.0,
      "onRotateStart":  { "type": "action", "name": "rotate.start" },
      "onRotateEnd":    { "type": "action", "name": "rotate.end", "args": { "emitAngle": true } }
    }
  },
  "expected": { "... see actual test file ..." },
  "runtimeAssertions": [
    { "path": "props.rotatable",                 "equals": true },
    { "path": "props.snapAngle",                 "equals": 45.0 },
    { "path": "props.onRotateEnd.args.emitAngle", "equals": true }
  ],
  "runtimeBehavior": {
    "gesture":        "rotate",
    "gestureAngle":   60.0,
    "expectedAngle":  45.0,
    "lifecycleEvents": ["onRotateStart", "onRotateEnd"]
  }
}
```

---

## Split contracts

### WGT-030 — `box:split` ratio and axis

```json
{
  "__meta": {
    "id": "widget-030-split-ratio-axis",
    "title": "box:split with ratio and axis compiles correctly",
    "description": "A horizontal split at 0.3 ratio must carry ratio:0.3 and axis:'horizontal'. The renderer uses both props to size panels.",
    "tags": ["widget", "split", "ratio", "axis"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:split",
    "props": { "ratio": 0.3, "axis": "horizontal", "resizable": true },
    "children": [
      { "type": "text", "props": { "text": "Left panel" } },
      { "type": "text", "props": { "text": "Right panel" } }
    ]
  },
  "expected": {
    "type": "box:split",
    "props": { "ratio": 0.3, "axis": "horizontal", "resizable": true },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Left panel" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Right panel" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.ratio",      "equals": 0.3 },
    { "path": "props.ratio",      "greaterThan": 0 },
    { "path": "props.ratio",      "lessThan": 1 },
    { "path": "props.axis",       "equals": "horizontal" },
    { "path": "props.axis",       "oneOf": ["horizontal", "vertical"] },
    { "path": "props.resizable",  "equals": true },
    { "path": "children.length",  "equals": 2 }
  ],
  "runtimeBehavior": {
    "description":  "Left panel = 30% of total width. Right panel = 70%. Dragging divider changes ratio continuously. Clamped to 0.05–0.95.",
    "initialRatio": 0.3,
    "minRatio":     0.05,
    "maxRatio":     0.95
  }
}
```

---

## Field sizing contracts

### WGT-040 — Slider min/max/step

All slider constraints must compile verbatim. The runtime step-snaps dragged values:

```
dragPosition: 37% → rawValue: 37 → steppedValue: 35 (step:5, nearest = 35)
```

`runtimeAssertions` verify:
- `props.min` equals the authored value
- `props.max` equals the authored value  
- `props.defaultValue` is within `[min, max]`
- `props.bind` contains the state path

---

## How to write a widget test checklist

1. **Identify the prop that drives behavior** (e.g., `width`, `handles`, `ratio`, `angle`).
2. **Write the minimal input** — only include props needed to trigger the behavior.
3. **Mirror those props exactly in `expected`** — if the VM strips or mutates them, the test fails.
4. **Add `runtimeAssertions`** — one assertion per significant prop, using the right operator:
   - Use `equals` for exact values
   - Use `oneOf` for enum values
   - Use `greaterThan`/`lessThan` for numeric constraints
   - Use `startsWith`/`contains` for strings with patterns
   - Use array index paths for ordered items: `handles[0]`, `handles[1]`
5. **Add `runtimeBehavior`** — document the gesture math so the expected runtime result is recorded next to the compiled output.
6. **Add a boundary test** — test the invalid or out-of-range value in a sibling `expectError` case.
7. **Tag appropriately** — `["widget", "sizing"|"drag"|"resize"|"rotate"|"split"]`.


## Geometry and position checks

The runner now supports `expectGeometry` for a single widget and `expectOrder` for comparing two widgets. Use these to verify:

- exact or approximate size
- top-left / bottom-right placement
- width and height under `w-full` / `justify-between` / `items-center`
- spacing between siblings in rows, columns, wrap layouts, and nested shells

A typical row layout check now looks like this:

```json
{
  "action": "expectGeometry",
  "finder": { "type": "text", "match": "Left" },
  "rect": { "left": 0, "top": 0, "tolerance": 8 }
}
```

Use `expectOrder` when the exact bounds are not important and the relative placement is.
