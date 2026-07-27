# SDUI runtime and JSON contract spec

This document is the single SDUI reference for authoring JSON that the Quantum runtime can compile and run.
It focuses on the JSON contract, the runtime split, the omni-core folder, the state and pipeline files, the VM, and the TypeScript authoring toolkit.

## How the app runs
1. Author JSON in the TypeScript toolkit or directly as JSON.
2. The runtime normalizes the node shape in `quantum_vm.dart`.
3. The VM routes the node to a core in `src/runtime/omni_cores/`.
4. State lives in `quantum_data_state.dart` and record processing lives in `quantum_data_pipeline.dart`.
5. The renderer, export tools, and type-export tools all consume the same runtime contract.

## Canonical JSON shape

A normal node uses these fields:

- `type`: the node type or `base:subtype` form.
- `props`: runtime properties and DSL metadata.
- `style`: a space-separated style string.
- `children`: ordered child nodes.
- `slots`: named slot nodes.
- `name`, `slot`, `env`, and `debugPath`: extra runtime metadata.

The runtime normalization in `quantum_vm.dart` splits colon syntax with `type.split(':')` and behaves like this:

- `box:*` keeps the public `type` as `box:*`.
- every other `base:subtype` form normalizes `type` to the base type and writes `props.__subType = subtype`.

That means the exported JSON is canonical, but the authoring JSON can still use the more expressive colon form.

### Minimal exported node
```json
{
  "type": "text",
  "props": { "text": "Hello" },
  "children": []
}
```

### Canonical box subtype example
```json
{
  "type": "box:row",
  "props": { "gap": 16, "align": "center" },
  "children": [
    { "type": "text", "props": { "text": "Left" } },
    { "type": "text", "props": { "text": "Right" } }
  ]
}
```

### Canonical non-box subtype example
```json
{
  "type": "data",
  "props": {
    "__subType": "repeat",
    "bind": "${state.items}",
    "as": "item",
    "indexAs": "index"
  },
  "children": [
    { "type": "text", "props": { "text": "${item.title}" } }
  ]
}
```

## Runtime file map

- `src/runtime/quantum_vm.dart` — The compiler and renderer. It normalizes colon syntax, resolves aliases, renders widgets, exports registry snapshots, and exposes the `QuantumVM` runtime.
- `src/runtime/quantum_data_state.dart` — The shared data store layer. It contains signals, computed state, slice registries, data scopes, persistence, and binding helpers.
- `src/runtime/quantum_data_pipeline.dart` — The flat record pipeline. It handles filtering, searching, sorting, paging, aggregation, indexing, partial hydration, and pipeline snapshots.
- `src/runtime/quantum_omni_registry.dart` — The registry that routes runtime nodes to the omni-core builders and registers aliases, slots, and behavior hooks.
- `src/runtime/quantum_sdui_engine.dart` — Encrypted SDUI transport and runtime API client for fetching, decrypting, caching, and executing SDUI payloads.
- `src/runtime/quantum_sdui_type_engine.dart` — Exports the live runtime snapshot and generates the TypeScript bundle for external type-safe tooling.
- `src/runtime/quantum_core_schema_registry.dart` — Lazy core schema catalog with file-backed descriptors and alias overlays.
- `src/runtime/quantum_core_file_registry.dart` — Lazy core file registry for file-backed runtime content, templates, and macros.
- `src/runtime/quantum_template_engine.dart` — AOT template engine for template inheritance, variants, slot defaults, and transforms.
- `src/runtime/quantum_design_system_manifest.dart` — JSON-first design system manifest and bundle model for aliases, templates, layouts, actions, behaviors, and component metadata.
- `src/runtime/quantum_data_orchestrator.dart` — Bootstrap/orchestration layer that connects manifests, the state store, and the pipeline without duplicating those responsibilities.
- `src/runtime/quantum_domain_builder.dart` — Fluent domain builder for packaging routes, plugins, actions, native bridges, and initial store data.
- `src/runtime/quantum_workspace_engine.dart` — Workspace controller and GPU-oriented spatial rendering engine.
- `src/runtime/quantum_widget_image_exporter.dart` — Offscreen PNG export path for rendering widgets and capturing images from SDUI JSON.
- `src/runtime/quantum_export_web_bridge.dart` — Web-side export bridge used by the external render pipeline.
- `src/runtime/quantum_omni_manifold.dart` — Isolate-backed spatial calculator used by the workspace/manifold layer.

## `src/runtime/omni_cores` folder

Each file below is separate on purpose. The VM loads these cores individually, and the JSON `type` / `props.__subType` combination decides which builder runs.

### `src/runtime/omni_cores/box_core.dart`
layout primitives and structural containers.

Handles these subtype values:

- `split`
- `expanded`
- `flexible`
- `morph`
- `safe`
- `aspect`
- `sticky`
- `virtual_grid`
- `measure`
- `builder`
- `matrix`
- `layer`
- `surface`
- `shell`
- `responsive`
- `viewport`
- `row`
- `col`
- `stack`
- `wrap`
- `grid`
- `masonry`
- `scroll`

### `src/runtime/omni_cores/action_core.dart`
interaction, gesture, pointer, and button behaviors.

Handles these subtype values:

- `gesture`
- `viewport`
- `raw_pointer`
- `pointer`
- `focus`
- `button`
- `icon_button`
- `chip`
- `long_press`
- `double_tap`
- `hover`

### `src/runtime/omni_cores/field_core.dart`
form controls and input widgets.

Handles these subtype values:

- `password`
- `email`
- `tel`
- `url`
- `number`
- `textarea`
- `multiline`
- `search`
- `toggle`
- `radio`
- `slider`
- `cell`
- `rich_text`

### `src/runtime/omni_cores/text_core.dart`
text rendering and label variants.

Handles these subtype values:

- `h1`
- `h2`
- `h3`
- `label`
- `code`
- `rich`

### `src/runtime/omni_cores/media_core.dart`
media and asset renderers.

Handles these subtype values:

- `icon`
- `svg_path`
- `path`
- `video`
- `avatar`
- `audio`
- `camera`
- `stream`
- `audio_visualizer`
- `webrtc`
- `canvas_video`

### `src/runtime/omni_cores/visual_core.dart`
cross-core visual composition and scene routing.

Handles these subtype values:

- `chart`
- `animation`
- `canvas`
- `portal`
- `connect`
- `field`
- `box`
- `media`
- `system`
- `template`
- `action`
- `control`
- `data`
- `layout`
- `decoration`
- `text`
- `delegate`
- `scene`
- `stack`
- `overlay`
- `shell`
- `surface`
- `layer`
- `compose`

### `src/runtime/omni_cores/hook_core.dart`
reactive lifecycle, effects, guards, memo, and store hooks.

Handles these subtype values:

- `guard`
- `memo`
- `scope`
- `delegate`
- `effect`
- `change`
- `lifecycle`
- `mount`
- `bridge`
- `store`
- `atom`
- `slice`
- `ref`
- `interval`
- `observable`
- `error_boundary`

### `src/runtime/omni_cores/data_core.dart`
lists, streaming, pagination, slices, and record-driven rendering.

Handles these subtype values:

- `sliver_plane`
- `sliver`
- `repeat`
- `stream`
- `diff`
- `slice`
- `cursor`
- `realtime`
- `paginated`
- `virtual_scroll`
- `aggregate`
- `timeline`
- `infinite`
- `kanban`
- `table`
- `grid`
- `masonry`

### `src/runtime/omni_cores/portal_core.dart`
overlays, drawers, sheets, menus, and floating surfaces.

Handles these subtype values:

- `overlay_entry`
- `overlay`
- `drawer`
- `toast`
- `window`
- `expandable_inline`
- `sheet`
- `popover`
- `menu`
- `context_menu`
- `dropdown`
- `flyout`
- `context_panel`
- `anchored_floating`

### `src/runtime/omni_cores/control_core.dart`
state machines, tabs, steppers, forms, and flow controllers.

Handles these subtype values:

- `form_scope`
- `tabs`
- `stepper`
- `accordion`
- `flow`
- `tca`
- `architecture`
- `machine`
- `reducer`
- `optimistic`
- `saga`

### `src/runtime/omni_cores/canvas_core.dart`
draw, plot, shader, and custom painter style primitives.

Handles these subtype values:

- `draw`
- `plot`
- `shader`
- `shape`

### `src/runtime/omni_cores/system_core.dart`
system-level effects, async, workers, telemetry, and utilities.

Handles these subtype values:

- `timer`
- `data_pipe`
- `kinetic_pipe`
- `omega_macro`
- `macro`
- `worker`
- `sync_scroll`
- `ticker`
- `repeater`
- `store_provider`
- `async`
- `throttle`
- `debounce`
- `geo`
- `haptic`
- `clipboard`
- `upload`
- `download`
- `notification`
- `share`
- `sensor`

### `src/runtime/omni_cores/layout_core.dart`
matrix-layout and responsive layout registry integration.

This core is registry-driven and does not advertise a fixed `subType` list in the source file.

### `src/runtime/omni_cores/decoration_core.dart`
text styling, borders, shadows, badges, blur, skeleton, ripple.

Handles these subtype values:

- `text`
- `rich`
- `span`
- `blur`
- `gradient`
- `border`
- `shadow`
- `badge`
- `skeleton`
- `ripple`

### `src/runtime/omni_cores/template_core.dart`
template inheritance, variants, slots, and transforms.

This core is registry-driven and does not advertise a fixed `subType` list in the source file.

### `src/runtime/omni_cores/connect_core.dart`
connective behaviors and interaction contracts.

This core is registry-driven and does not advertise a fixed `subType` list in the source file.

### `src/runtime/omni_cores/chart_core.dart`
chart aliasing and chart-type registry integration.

This core is registry-driven and does not advertise a fixed `subType` list in the source file.

### `src/runtime/omni_cores/animation_core.dart`
animation wrappers, transitions, and signal-driven motion.

This core is registry-driven and does not advertise a fixed `subType` list in the source file.

### `src/runtime/omni_cores/stream_core.dart`
stream transports and event channels.

Handles these subtype values:

- `ws`
- `sse`
- `tick`
- `ring`
- `multiplex`

### `src/runtime/omni_cores/collab_core.dart`
collaboration primitives for presence, cursor, locking, and patching.

Handles these subtype values:

- `presence`
- `cursor`
- `awareness`
- `lock`
- `patch`

## Omni-core behavior notes

- `action_core.dart` handles pointer and gesture routing, including `button`, `icon_button`, `chip`, `hover`, `focus`, `viewport`, and raw pointer injection.
- `box_core.dart` handles layout primitives such as row, col, stack, grid, shell, matrix, viewport, sticky, and virtual-grid style containers.
- `data_core.dart` is the core most directly tied to list rendering and state-driven repetition; it is the main place where `repeat`, `stream`, `diff`, `slice`, `cursor`, and virtualization live.
- `layout_core.dart` bridges matrix layout definitions from the registry into rendered widgets.
- `portal_core.dart` is the place for overlays, drawers, sheets, menus, flyouts, and floating UI surfaces.
- `system_core.dart` covers timers, async, workers, repeaters, throttling, debouncing, clipboard, upload/download, share, notifications, and similar runtime effects.

## State, pipeline, and VM details

### `quantum_data_state.dart`
This file holds the shared runtime state layer. The important public pieces are:

- `QLDataStore` — the main store with `signal`, `get`, `set`, `merge`, `transaction`, `saveSnapshot`, `rollback`, `refresh`, `push`, and persistence hooks.
- `QLDataScope` — the local data envelope used by repeated items, slots, and nested runtime scopes.
- `QLSliceRegistry` and `QLDataSourceRegistry` — registries for slice execution and data-source resolution.
- `QLStoreRegistry` — store lookup and registration.
- `QLSignalProxy` — reactive proxy surface for store bindings.

### `quantum_data_pipeline.dart`
This file processes records before they are exposed to UI renderers. The important public pieces are:

- `QLDataPipeline` — the flat-cache pipeline with filtering, search, sorting, paging, aggregates, ingestion, patching, partial hydration, and snapshot export.
- `QLPipelineDelegate` — the delegate interface for fetch and partial fetch.
- `QLPipelineRegistry` — pipeline registration and lookup.
- `QLDataPipelineReadPlan` — read-plan structure used by the pipeline logic.

### `quantum_vm.dart`
This file is the core compiler/rendering VM. The important public pieces are:

- `QuantumVM` — registry installation, alias resolution, module registration, snapshot export, widget rendering, action execution, and string compilation.
- `QuantumVMRoot` — app bootstrap and root VM entry widget.
- `QLContext` — the runtime read context passed to builders.
- `QLBlueprint` — the compiled node/blueprint representation.
- `QLPipes` — pipe helpers and runtime pipeline definitions.

Important VM responsibilities:

- colon syntax normalization
- alias default-prop application
- `props.__subType` injection for non-box colon nodes
- slot preservation and debug-path propagation
- registry snapshot export for type tooling

## TypeScript authoring toolkit

The TypeScript toolkit exists to author SDUI JSON without losing the runtime shape. It preserves authoring operators like `$define`, `$let`, `$if`, `$repeat`, `$call`, `$switch`, `$async`, `$stream`, `$machine`, `$portal`, `$watch`, `$try`, `$layout`, `$compose`, `$apply`, `$scope`, `$spread`, `$throttle`, `$debounce`, `$parallel`, `$reactive_map`, and `$classes` while still emitting plain JSON.

### What the updated TS file provides

- Stronger type information for the known omni-core roots and subtype catalog.
- A generic `sdui.subtype(root, subType, init)` helper that matches the runtime normalization rules.
- A `sdui.core(...)` alias for the same subtype helper.
- A corrected `repeat()` helper that emits the `data` core with `props.__subType = 'repeat'` and the runtime bindings needed by `data_core.dart`.
- A corrected `stream()` helper that emits the `data` core with `props.__subType = 'stream'` and stores the stream bind metadata in JSON.
- The existing fluent builder, emitter, validator, and example app stay available.

### TS authoring example
```ts
import { sdui, toNativeJson } from './sdui_ts_toolkit_preserve';

const page = sdui.page([
  sdui.row([
    sdui.text("Dashboard", { style: "text-2xl font-bold" }),
    sdui.button("Refresh", { props: { intent: "primary" } })
  ], { style: 'items-center justify-between gap-16 p-20' }),

  sdui.repeat("${state.items}",
    sdui.row([
      sdui.text("${item.title}"),
      sdui.text("${item.status}", { style: "text-slate-500" })
    ]),
    "item",
    "index"
  ),
], { style: 'gap-16 p-24' });

console.log(toNativeJson(page, { pretty: true, includeDebugPath: false }));
```

### JSON exported by that example
```json
{
  "type": "page",
  "props": {},
  "style": "gap-16 p-24",
  "children": [
    {
      "type": "box:row",
      "props": {},
      "style": "items-center justify-between gap-16 p-20",
      "children": [
        { "type": "text", "props": { "text": "Dashboard" }, "style": "text-2xl font-bold" },
        { "type": "action:button", "props": { "text": "Refresh", "intent": "primary" } }
      ]
    },
    {
      "type": "data",
      "props": {
        "__subType": "repeat",
        "bind": "${state.items}",
        "as": "item",
        "indexAs": "index"
      },
      "children": [
        {
          "type": "box:row",
          "props": {},
          "children": [
            { "type": "text", "props": { "text": "${item.title}" } },
            { "type": "text", "props": { "text": "${item.status}" }, "style": "text-slate-500" }
          ]
        }
      ]
    }
  ]
}
```

## JSON writing rules you should keep using

- Use `type` for the node family or the `box:*` structural subtype.
- Use `props.__subType` for non-box subtype routing.
- Put runtime inputs such as `bind`, `href`, `chartType`, `layoutId`, `durationMs`, `animationType`, and `channel` in `props` unless the runtime file expects a dedicated top-level field.
- Keep `children` as the visible tree and `slots` for named regions.
- Preserve `debugPath` during authoring when you need traceable error output.

## File inventory summary

The repo also contains the surrounding runtime pieces that feed the same contract:

- `src/runtime/quantum_sdui_engine.dart`
- `src/runtime/quantum_sdui_type_engine.dart`
- `src/runtime/quantum_core_schema_registry.dart`
- `src/runtime/quantum_core_file_registry.dart`
- `src/runtime/quantum_template_engine.dart`
- `src/runtime/quantum_design_system_manifest.dart`
- `src/runtime/quantum_domain_builder.dart`
- `src/runtime/quantum_data_orchestrator.dart`
- `src/runtime/quantum_workspace_engine.dart`
- `src/runtime/quantum_widget_image_exporter.dart`
- `src/runtime/quantum_export_web_bridge.dart`
- `src/runtime/quantum_omni_manifold.dart`

That is the contract surface the SDUI JSON must satisfy to run end to end.

## Audit summary

- The SDUI contract was re-audited against the live runtime surface, including the VM, type engine, omni-core files, and the test helper.
- The existing test-manifest coverage was expanded into a separate `verification/sdui_json_tests/` documentation tree so the plan stays isolated from runnable fixtures.
- The new test plan now calls out the full compile-time operator catalogue, the runtime snapshot export shape, the colon-normalization rules, and the full omni-core subtype inventory.
- The nested-composition coverage now starts with the smallest legal node and grows into large mixed trees that combine data, layout, portals, overlays, and reactive bindings.
