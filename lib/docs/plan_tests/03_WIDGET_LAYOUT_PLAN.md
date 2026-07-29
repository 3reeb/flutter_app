# 03 — Widget & Layout Test Plan

All box:* subtypes, sizing props, drag/resize/rotate interactions, and layout geometry contracts.
Every test has a compile contract, runtimeAssertions, and (for interactive types) executionSteps.

---

## box:row

### WL-001 — box:row with gap, alignment, and children

```json
{
  "__meta": {
    "id": "wl-001-box-row-gap-alignment",
    "title": "box:row with gap and alignment props compiles verbatim",
    "description": "A row with gap, mainAxisAlignment, crossAxisAlignment must carry all three props. The VM must not rename or drop alignment keys.",
    "tags": ["widget", "box", "row", "layout", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:row",
    "props": { "gap": 16, "mainAxisAlignment": "spaceBetween", "crossAxisAlignment": "center" },
    "style": "px-4 py-2",
    "children": [
      { "type": "text", "props": { "text": "Left" } },
      { "type": "text", "props": { "text": "Right" } }
    ]
  },
  "expected": {
    "type": "box:row",
    "props": { "gap": 16, "mainAxisAlignment": "spaceBetween", "crossAxisAlignment": "center" },
    "debugPath": "root",
    "style": "px-4 py-2",
    "children": [
      { "type": "text", "props": { "text": "Left" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Right" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                       "equals": "box:row" },
    { "path": "props.gap",                  "equals": 16 },
    { "path": "props.mainAxisAlignment",    "equals": "spaceBetween" },
    { "path": "props.crossAxisAlignment",   "equals": "center" },
    { "path": "props.gap",                  "greaterThan": 0 },
    { "path": "children.length",            "equals": 2 }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Left" },
    { "action": "expectText", "text": "Right" },
    { "action": "expectGeometry",
      "finder": { "type": "text", "match": "Left" },
      "rect": { "left": 0, "tolerance": 8 }
    }
  ]
}
```

### WL-002 — box:row with flex weights on children

```json
{
  "__meta": {
    "id": "wl-002-box-row-flex-weights",
    "title": "box:row children with flex weights produce correct proportional layout",
    "description": "A row where first child has flex:2 and second has flex:1 must render first child at 2/3 width. Tests flex prop pass-through.",
    "tags": ["widget", "box", "row", "flex", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:row",
    "props": { "gap": 0 },
    "children": [
      { "type": "box:col", "props": { "flex": 2, "width": "fill" }, "children": [
        { "type": "text", "props": { "text": "Main" } }
      ]},
      { "type": "box:col", "props": { "flex": 1, "width": "fill" }, "children": [
        { "type": "text", "props": { "text": "Side" } }
      ]}
    ]
  },
  "expected": {
    "type": "box:row",
    "props": { "gap": 0 },
    "debugPath": "root",
    "children": [
      { "type": "box:col", "props": { "flex": 2, "width": "fill" }, "debugPath": "root[0]",
        "children": [{ "type": "text", "props": { "text": "Main" }, "debugPath": "root[0][0]" }]
      },
      { "type": "box:col", "props": { "flex": 1, "width": "fill" }, "debugPath": "root[1]",
        "children": [{ "type": "text", "props": { "text": "Side" }, "debugPath": "root[1][0]" }]
      }
    ]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.flex", "equals": 2 },
    { "path": "children[1].props.flex", "equals": 1 },
    { "path": "children[0].props.flex", "greaterThan": 0 }
  ]
}
```

---

## box:col

### WL-010 — box:col with padding and gap

```json
{
  "__meta": {
    "id": "wl-010-box-col-padding-gap",
    "title": "box:col with padding and gap compiles verbatim",
    "description": "A column with vertical layout, padding, and gap must carry all props unchanged.",
    "tags": ["widget", "box", "col", "layout", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": { "gap": 12, "padding": 16 },
    "style": "bg-surface",
    "children": [
      { "type": "text", "props": { "text": "Title" } },
      { "type": "text", "props": { "text": "Subtitle" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": { "gap": 12, "padding": 16 },
    "debugPath": "root",
    "style": "bg-surface",
    "children": [
      { "type": "text", "props": { "text": "Title" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Subtitle" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.gap",     "equals": 12 },
    { "path": "props.padding", "equals": 16 },
    { "path": "children.length", "equals": 2 }
  ]
}
```

---

## box:scroll

### WL-020 — box:scroll vertical with physics

```json
{
  "__meta": {
    "id": "wl-020-box-scroll-vertical-physics",
    "title": "box:scroll with axis and physics compiles correctly",
    "description": "A scroll container with axis:vertical and physics:bouncing must carry both props for the renderer to build the right ScrollPhysics.",
    "tags": ["widget", "box", "scroll", "physics", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:scroll",
    "props": { "axis": "vertical", "physics": "bouncing", "padding": 8 },
    "children": [
      { "type": "text", "props": { "text": "Item 1" } },
      { "type": "text", "props": { "text": "Item 2" } },
      { "type": "text", "props": { "text": "Item 3" } }
    ]
  },
  "expected": {
    "type": "box:scroll",
    "props": { "axis": "vertical", "physics": "bouncing", "padding": 8 },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Item 1" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Item 2" }, "debugPath": "root[1]" },
      { "type": "text", "props": { "text": "Item 3" }, "debugPath": "root[2]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.axis",    "equals": "vertical" },
    { "path": "props.physics", "equals": "bouncing" },
    { "path": "props.axis",    "oneOf": ["vertical", "horizontal"] }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Item 1" },
    { "action": "expectText", "text": "Item 2" }
  ]
}
```

### WL-021 — box:scroll horizontal with many children, scroll to find offscreen item

```json
{
  "__meta": {
    "id": "wl-021-box-scroll-horizontal-find-offscreen",
    "title": "box:scroll horizontal scrolls to reveal offscreen content",
    "description": "A horizontal scroll with enough content to overflow must allow scrolling via drag. The last item must be found after scrolling.",
    "tags": ["widget", "box", "scroll", "horizontal", "execution", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "selected": "" },
    "type": "box:scroll",
    "props": { "axis": "horizontal" },
    "children": [
      { "type": "action:button", "props": { "text": "Tab A", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "A" } } } },
      { "type": "action:button", "props": { "text": "Tab B", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "B" } } } },
      { "type": "action:button", "props": { "text": "Tab C", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "C" } } } },
      { "type": "action:button", "props": { "text": "Tab D", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "D" } } } },
      { "type": "action:button", "props": { "text": "Tab E", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "E" } } } },
      { "type": "action:button", "props": { "text": "Tab F", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "F" } } } }
    ]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "selected": "" } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:scroll",
      "props": { "axis": "horizontal" },
      "debugPath": "root",
      "children": [
        { "type": "action", "props": { "__subType": "button", "text": "Tab A", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "A" } } }, "debugPath": "root[0]" },
        { "type": "action", "props": { "__subType": "button", "text": "Tab B", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "B" } } }, "debugPath": "root[1]" },
        { "type": "action", "props": { "__subType": "button", "text": "Tab C", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "C" } } }, "debugPath": "root[2]" },
        { "type": "action", "props": { "__subType": "button", "text": "Tab D", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "D" } } }, "debugPath": "root[3]" },
        { "type": "action", "props": { "__subType": "button", "text": "Tab E", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "E" } } }, "debugPath": "root[4]" },
        { "type": "action", "props": { "__subType": "button", "text": "Tab F", "onTap": { "type": "action", "name": "state.set", "args": { "path": "selected", "value": "F" } } }, "debugPath": "root[5]" }
      ]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.axis", "equals": "horizontal" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "scrollUntilVisible",
      "finder": { "type": "text", "match": "Tab F" },
      "scrollable": { "type": "type", "match": "Scrollable", "contains": true },
      "delta": 200, "maxScrolls": 10
    },
    { "action": "pumpAndSettle" },
    { "action": "tap", "finder": { "type": "text", "match": "Tab F" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "selected", "equals": "F" }
  ]
}
```

---

## box:wrap

### WL-030 — box:wrap with spacing and runSpacing

```json
{
  "__meta": {
    "id": "wl-030-box-wrap-spacing",
    "title": "box:wrap with spacing, runSpacing, and alignment compiles correctly",
    "description": "A wrap layout for tag chips must carry spacing, runSpacing, and alignment. Missing spacing props cause chips to render with 0 gap.",
    "tags": ["widget", "box", "wrap", "spacing", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:wrap",
    "props": { "spacing": 8, "runSpacing": 8, "alignment": "start" },
    "children": [
      { "type": "action:chip", "props": { "label": "Flutter" } },
      { "type": "action:chip", "props": { "label": "Dart" } },
      { "type": "action:chip", "props": { "label": "Firebase" } }
    ]
  },
  "expected": {
    "type": "box:wrap",
    "props": { "spacing": 8, "runSpacing": 8, "alignment": "start" },
    "debugPath": "root",
    "children": [
      { "type": "action", "props": { "__subType": "chip", "label": "Flutter" }, "debugPath": "root[0]" },
      { "type": "action", "props": { "__subType": "chip", "label": "Dart" }, "debugPath": "root[1]" },
      { "type": "action", "props": { "__subType": "chip", "label": "Firebase" }, "debugPath": "root[2]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.spacing",    "equals": 8 },
    { "path": "props.runSpacing", "equals": 8 },
    { "path": "props.alignment",  "equals": "start" },
    { "path": "children.length",  "equals": 3 },
    { "path": "children[0].props.__subType", "equals": "chip" }
  ]
}
```

---

## box:grid

### WL-040 — box:grid with columns and cross/main axis spacing

```json
{
  "__meta": {
    "id": "wl-040-box-grid-columns-spacing",
    "title": "box:grid with columns, crossAxisSpacing, mainAxisSpacing compiles correctly",
    "description": "A photo gallery grid must carry the column count and spacing props. Dropping them produces a broken 1-column list.",
    "tags": ["widget", "box", "grid", "columns", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:grid",
    "props": { "columns": 3, "crossAxisSpacing": 8, "mainAxisSpacing": 8, "childAspectRatio": 1.0 },
    "children": [
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/100" } },
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/101" } },
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/102" } }
    ]
  },
  "expected": {
    "type": "box:grid",
    "props": { "columns": 3, "crossAxisSpacing": 8, "mainAxisSpacing": 8, "childAspectRatio": 1.0 },
    "debugPath": "root",
    "children": [
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/100" }, "debugPath": "root[0]" },
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/101" }, "debugPath": "root[1]" },
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/102" }, "debugPath": "root[2]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.columns",           "equals": 3 },
    { "path": "props.crossAxisSpacing",  "equals": 8 },
    { "path": "props.mainAxisSpacing",   "equals": 8 },
    { "path": "props.childAspectRatio",  "equals": 1.0 },
    { "path": "children.length",         "equals": 3 }
  ]
}
```

---

## box:stack

### WL-050 — box:stack with positioned children

```json
{
  "__meta": {
    "id": "wl-050-box-stack-positioned-children",
    "title": "box:stack with positioned children compiles correctly",
    "description": "A stack allows absolute positioning of children. Position props (top, left, right, bottom) on children must survive compilation.",
    "tags": ["widget", "box", "stack", "position", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "type": "box:stack",
    "props": { "alignment": "topLeft" },
    "children": [
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/200", "width": 200, "height": 200 } },
      { "type": "decoration:badge", "props": { "count": 5, "position": "topRight", "top": 4, "right": 4 } }
    ]
  },
  "expected": {
    "type": "box:stack",
    "props": { "alignment": "topLeft" },
    "debugPath": "root",
    "children": [
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/200", "width": 200, "height": 200 }, "debugPath": "root[0]" },
      { "type": "decoration", "props": { "__subType": "badge", "count": 5, "position": "topRight", "top": 4, "right": 4 }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                            "equals": "box:stack" },
    { "path": "props.alignment",                 "equals": "topLeft" },
    { "path": "children[1].props.count",         "equals": 5 },
    { "path": "children[1].props.top",           "equals": 4 },
    { "path": "children[1].props.right",         "equals": 4 }
  ]
}
```

---

## box:shell

### WL-060 — box:shell with appBar slot and drawer

```json
{
  "__meta": {
    "id": "wl-060-box-shell-appbar-drawer",
    "title": "box:shell with appBar slot, drawer slot, and FAB compiles correctly",
    "description": "A Scaffold-equivalent box:shell must carry all slots: appBar, drawer, floatingActionButton. Missing slot keys mean those features don't render.",
    "tags": ["widget", "box", "shell", "scaffold", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:shell",
    "slots": {
      "appBar": {
        "type": "box:row",
        "props": { "height": 56 },
        "children": [
          { "type": "text", "props": { "text": "My App", "__subType": "h1" } }
        ]
      },
      "floatingActionButton": {
        "type": "action:button",
        "props": { "icon": "add", "intent": "primary", "onTap": { "type": "action", "name": "nav.push", "args": { "route": "/new" } } }
      }
    },
    "children": [
      { "type": "text", "props": { "text": "Body content" } }
    ]
  },
  "expected": {
    "type": "box:shell",
    "props": {},
    "debugPath": "root",
    "slots": {
      "appBar": {
        "type": "box:row",
        "props": { "height": 56 },
        "children": [
          { "type": "text", "props": { "text": "My App", "__subType": "h1" } }
        ]
      },
      "floatingActionButton": {
        "type": "action",
        "props": { "__subType": "button", "icon": "add", "intent": "primary", "onTap": { "type": "action", "name": "nav.push", "args": { "route": "/new" } } }
      }
    },
    "children": [
      { "type": "text", "props": { "text": "Body content" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "type",                                         "equals": "box:shell" },
    { "path": "children.length",                              "equals": 1 },
    { "path": "children[0].props.text",                       "equals": "Body content" }
  ],
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "expectText", "text": "Body content" }
  ]
}
```

---

## box:split

### WL-070 — box:split horizontal at 0.3 ratio with resizable divider

```json
{
  "__meta": {
    "id": "wl-070-box-split-horizontal-ratio",
    "title": "box:split horizontal at 0.3 ratio with resizable divider",
    "description": "A split layout at 30/70 must carry ratio:0.3, axis:horizontal, and resizable:true. Dropping any prop breaks the split calculation.",
    "tags": ["widget", "box", "split", "ratio", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:split",
    "props": { "ratio": 0.3, "axis": "horizontal", "resizable": true, "minRatio": 0.1, "maxRatio": 0.9 },
    "children": [
      { "type": "text", "props": { "text": "Left Panel" } },
      { "type": "text", "props": { "text": "Right Panel" } }
    ]
  },
  "expected": {
    "type": "box:split",
    "props": { "ratio": 0.3, "axis": "horizontal", "resizable": true, "minRatio": 0.1, "maxRatio": 0.9 },
    "debugPath": "root",
    "children": [
      { "type": "text", "props": { "text": "Left Panel" }, "debugPath": "root[0]" },
      { "type": "text", "props": { "text": "Right Panel" }, "debugPath": "root[1]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.ratio",     "equals": 0.3 },
    { "path": "props.ratio",     "greaterThan": 0 },
    { "path": "props.ratio",     "lessThan": 1 },
    { "path": "props.axis",      "equals": "horizontal" },
    { "path": "props.axis",      "oneOf": ["horizontal", "vertical"] },
    { "path": "props.resizable", "equals": true },
    { "path": "props.minRatio",  "equals": 0.1 },
    { "path": "props.maxRatio",  "equals": 0.9 },
    { "path": "children.length", "equals": 2 }
  ],
  "runtimeBehavior": {
    "gesture": "resize",
    "description": "Left panel = 30% width. Right = 70%. Dragging divider right 50px adds 50/(total_width) to ratio. Clamped to [0.1, 0.9].",
    "initialRatio": 0.3,
    "dividerDragDeltaX": 50,
    "clampMin": 0.1,
    "clampMax": 0.9
  }
}
```

---

## box:aspect

### WL-080 — box:aspect for 16:9 video ratio

```json
{
  "__meta": {
    "id": "wl-080-box-aspect-16-9-video",
    "title": "box:aspect ratio 1.777 for 16:9 video container",
    "description": "A video player wrapper must use ratio:1.777 (~16:9). The runtime computes height = width / ratio. Dropping ratio collapses height to 0.",
    "tags": ["widget", "box", "aspect", "ratio", "video", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:aspect",
    "props": { "ratio": 1.777 },
    "children": [
      { "type": "media", "props": { "__subType": "video", "src": "${state.videoUrl}", "autoPlay": false, "controls": true } }
    ]
  },
  "expected": {
    "type": "box:aspect",
    "props": { "ratio": 1.777 },
    "debugPath": "root",
    "children": [
      { "type": "media", "props": { "__subType": "video", "src": "${state.videoUrl}", "autoPlay": false, "controls": true }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.ratio",                   "equals": 1.777 },
    { "path": "props.ratio",                   "greaterThan": 1 },
    { "path": "children[0].props.__subType",   "equals": "video" },
    { "path": "children[0].props.controls",    "equals": true }
  ]
}
```

---

## Draggable Props

### WL-090 — Draggable with both axes, snap, and lifecycle handlers

```json
{
  "__meta": {
    "id": "wl-090-draggable-both-snap-handlers",
    "title": "Draggable box with dragAxis:both, snapToGrid, and full lifecycle handlers",
    "description": "A freely draggable widget with grid snap and start/update/end handlers must carry all props. Any missing prop disables that behavior.",
    "tags": ["widget", "drag", "snap", "handlers", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "state": { "dragX": 0, "dragY": 0 },
    "type": "box:col",
    "props": {
      "draggable": true,
      "dragAxis": "both",
      "initialX": 0,
      "initialY": 0,
      "snapToGrid": true,
      "gridSize": 16,
      "onDragStart":  { "type": "action", "name": "drag.start" },
      "onDragUpdate": { "type": "action", "name": "drag.update", "args": { "storePosition": true } },
      "onDragEnd":    { "type": "action", "name": "drag.end", "args": { "persistToServer": true } }
    },
    "children": [{ "type": "text", "props": { "text": "Drag me" } }]
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "dragX": 0, "dragY": 0 } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "box:col",
      "props": {
        "draggable": true,
        "dragAxis": "both",
        "initialX": 0,
        "initialY": 0,
        "snapToGrid": true,
        "gridSize": 16,
        "onDragStart":  { "type": "action", "name": "drag.start" },
        "onDragUpdate": { "type": "action", "name": "drag.update", "args": { "storePosition": true } },
        "onDragEnd":    { "type": "action", "name": "drag.end", "args": { "persistToServer": true } }
      },
      "debugPath": "root",
      "children": [{ "type": "text", "props": { "text": "Drag me" }, "debugPath": "root[0]" }]
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].props.draggable",             "equals": true },
    { "path": "children[0].props.dragAxis",              "equals": "both" },
    { "path": "children[0].props.snapToGrid",            "equals": true },
    { "path": "children[0].props.gridSize",              "equals": 16 },
    { "path": "children[0].props.gridSize",              "greaterThan": 0 },
    { "path": "children[0].props.onDragStart.name",      "equals": "drag.start" },
    { "path": "children[0].props.onDragUpdate.name",     "equals": "drag.update" },
    { "path": "children[0].props.onDragEnd.name",        "equals": "drag.end" },
    { "path": "children[0].props.onDragEnd.args.persistToServer", "equals": true }
  ],
  "runtimeBehavior": {
    "gesture": "drag",
    "description": "dragAxis:both allows movement in X and Y. snapToGrid:true with gridSize:16 snaps final position to nearest 16px increment. onDragEnd fires after gesture ends, dispatching drag.end with persistToServer:true.",
    "rawDeltaX": 25, "expectedSnappedX": 32,
    "rawDeltaY": 10, "expectedSnappedY": 16
  }
}
```

---

## Resizable Props

### WL-100 — Resizable with all 8 handles, constraints, and lifecycle handlers

```json
{
  "__meta": {
    "id": "wl-100-resizable-all-handles-constraints",
    "title": "Resizable box with all 8 handles, min/max constraints, and lifecycle handlers",
    "description": "A fully resizable panel must carry resizable:true, all 8 handle directions, dimension constraints, and start/end handlers. Any missing prop disables a resize direction or removes the lifecycle callback.",
    "tags": ["widget", "resize", "handles", "constraints", "handlers", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "resizable": true,
      "handles": ["n", "s", "e", "w", "ne", "nw", "se", "sw"],
      "width": 400, "height": 300,
      "minWidth": 200, "maxWidth": 1200,
      "minHeight": 100, "maxHeight": 800,
      "onResizeStart": { "type": "action", "name": "panel.resizeStart" },
      "onResizeEnd":   { "type": "action", "name": "panel.resizeEnd", "args": { "emitDimensions": true } }
    },
    "children": [{ "type": "text", "props": { "text": "Resizable panel" } }]
  },
  "expected": {
    "type": "box:col",
    "props": {
      "resizable": true,
      "handles": ["n", "s", "e", "w", "ne", "nw", "se", "sw"],
      "width": 400, "height": 300,
      "minWidth": 200, "maxWidth": 1200,
      "minHeight": 100, "maxHeight": 800,
      "onResizeStart": { "type": "action", "name": "panel.resizeStart" },
      "onResizeEnd":   { "type": "action", "name": "panel.resizeEnd", "args": { "emitDimensions": true } }
    },
    "debugPath": "root",
    "children": [{ "type": "text", "props": { "text": "Resizable panel" }, "debugPath": "root[0]" }]
  },
  "runtimeAssertions": [
    { "path": "props.resizable",                       "equals": true },
    { "path": "props.handles.length",                  "equals": 8 },
    { "path": "props.handles[0]",                      "equals": "n" },
    { "path": "props.handles[4]",                      "equals": "ne" },
    { "path": "props.handles[7]",                      "equals": "sw" },
    { "path": "props.width",                           "equals": 400 },
    { "path": "props.minWidth",                        "equals": 200 },
    { "path": "props.maxWidth",                        "equals": 1200 },
    { "path": "props.onResizeEnd.args.emitDimensions", "equals": true }
  ],
  "runtimeBehavior": {
    "gesture": "resize",
    "handle": "e",
    "dragDeltaX": 300,
    "initialWidth": 400,
    "expectedWidth": 700,
    "clampMax": 1200,
    "description": "Dragging east handle 300px: new width = 400+300 = 700 (within max:1200). Dragging further 600px: clamped at 1200. onResizeEnd dispatches panel.resizeEnd with {width:1200, height:300}."
  }
}
```

---

## Rotatable Props

### WL-110 — Rotatable with angle constraints and snap

```json
{
  "__meta": {
    "id": "wl-110-rotatable-angle-constraints-snap",
    "title": "Rotatable widget with angle, min/max, and snapAngle compiles correctly",
    "description": "A rotatable image widget must carry all rotation constraints. Missing snapAngle disables snapping. Missing min/max allows unlimited rotation.",
    "tags": ["widget", "rotate", "angle", "constraints", "snap", "critical"],
    "allowBlank": false,
    "priority": "critical"
  },
  "input": {
    "type": "box:col",
    "props": {
      "rotatable": true,
      "angle": 0.0,
      "minAngle": -180.0,
      "maxAngle": 180.0,
      "snapAngle": 45.0,
      "onRotateStart": { "type": "action", "name": "rotate.begin" },
      "onRotateEnd":   { "type": "action", "name": "rotate.commit", "args": { "emitAngle": true } }
    },
    "children": [
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/200" } }
    ]
  },
  "expected": {
    "type": "box:col",
    "props": {
      "rotatable": true,
      "angle": 0.0,
      "minAngle": -180.0,
      "maxAngle": 180.0,
      "snapAngle": 45.0,
      "onRotateStart": { "type": "action", "name": "rotate.begin" },
      "onRotateEnd":   { "type": "action", "name": "rotate.commit", "args": { "emitAngle": true } }
    },
    "debugPath": "root",
    "children": [
      { "type": "media", "props": { "__subType": "avatar", "src": "https://picsum.photos/200" }, "debugPath": "root[0]" }
    ]
  },
  "runtimeAssertions": [
    { "path": "props.rotatable",                   "equals": true },
    { "path": "props.angle",                       "equals": 0.0 },
    { "path": "props.minAngle",                    "equals": -180.0 },
    { "path": "props.maxAngle",                    "equals": 180.0 },
    { "path": "props.snapAngle",                   "equals": 45.0 },
    { "path": "props.onRotateEnd.args.emitAngle",  "equals": true }
  ],
  "runtimeBehavior": {
    "gesture": "rotate",
    "initialAngle": 0.0,
    "gestureAngle": 70.0,
    "expectedAngle": 45.0,
    "description": "Rotating 70° from 0° snaps to 45° (nearest multiple of snapAngle:45). Rotating 135° from 0° snaps to 135° (still within maxAngle:180). Rotating 200° would be clamped to 180°."
  }
}
```

---

## Sizing Contracts

### WL-120 — Fixed width and height pass through numerically

```json
{
  "__meta": {
    "id": "wl-120-fixed-width-height-numeric",
    "title": "Numeric width:320, height:48 pass through unchanged",
    "description": "Numeric sizing must not be cast to string or rounded. The VM must preserve the exact integer value.",
    "tags": ["widget", "sizing", "width", "height", "critical"],
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
    { "path": "props.width",  "greaterThan": 0 }
  ]
}
```

### WL-121 — String sizing: fill, auto, wrap, expand

```json
{
  "__meta": {
    "id": "wl-121-string-sizing-fill-auto",
    "title": "String sizing values fill/auto/wrap/expand pass through unchanged",
    "description": "Width expressed as 'fill' or 'auto' must not be cast to a number. The renderer reads the string to apply its own sizing logic.",
    "tags": ["widget", "sizing", "string", "high"],
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
  ]
}
```

---

## Complete Widget Layout Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| wl-001 | box:row gap, alignment, children | critical |
| wl-002 | box:row flex weights | high |
| wl-003 | box:row with mainAxisSize:min | medium |
| wl-010 | box:col padding and gap | critical |
| wl-011 | box:col with crossAxisAlignment:stretch | high |
| wl-020 | box:scroll vertical with physics | high |
| wl-021 | box:scroll horizontal, scroll to find offscreen | high |
| wl-022 | box:scroll with onScrollEnd action | medium |
| wl-030 | box:wrap spacing and runSpacing | high |
| wl-031 | box:wrap with direction:rtl | medium |
| wl-040 | box:grid columns and spacing | high |
| wl-041 | box:grid with responsive breakpoints | medium |
| wl-050 | box:stack with positioned children | high |
| wl-051 | box:stack overflow:clip | medium |
| wl-060 | box:shell appBar and FAB slots | critical |
| wl-061 | box:shell with drawer and endDrawer | high |
| wl-070 | box:split horizontal at 0.3 ratio | critical |
| wl-071 | box:split vertical at 0.5 ratio | high |
| wl-072 | box:split minRatio/maxRatio clamp | high |
| wl-080 | box:aspect 16:9 video ratio | critical |
| wl-081 | box:aspect 1:1 square ratio | medium |
| wl-090 | Draggable both axes with snap and handlers | critical |
| wl-091 | Draggable x-only axis constraint | high |
| wl-092 | Draggable y-only axis constraint | high |
| wl-093 | Draggable with boundaries (minX, maxX) | high |
| wl-100 | Resizable all 8 handles | critical |
| wl-101 | Resizable e+w only (width-only resize) | high |
| wl-102 | Resizable n+s only (height-only resize) | high |
| wl-103 | Resize clamped at maxWidth | high |
| wl-110 | Rotatable with snap and min/max | critical |
| wl-111 | Rotate clamped at maxAngle | high |
| wl-112 | Rotate no snap (snapAngle omitted) | medium |
| wl-120 | Numeric width/height pass-through | critical |
| wl-121 | String sizing: fill, auto, wrap, expand | high |
| wl-122 | Percentage sizing: 50% | medium |
| wl-130 | Nested 3-level children with correct debugPaths | critical |
| wl-131 | 10-deep nested layout no overflow | high |
| wl-140 | box:layer z-index and opacity | medium |
| wl-141 | box:layer with position: absolute | medium |
| wl-150 | Geometry check: row with justify-between | high |
| wl-151 | Geometry check: col with items-center | high |
| wl-152 | Geometry check: nested shell body sizing | high |
