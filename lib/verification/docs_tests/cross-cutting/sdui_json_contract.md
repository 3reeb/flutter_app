---
title: Quantum SDUI JSON contract and omni core catalog
last_reviewed: "2026-07-26"
kind: cross-cutting test specification
status: draft
---

# Quantum SDUI JSON contract and omni core catalog

This document describes the SDUI surface as a testable JSON contract rather than a loose widget tree. It is the authoritative reference for writing data-driven tests that scan JSON files, validate source contracts, and exercise the live SDUI type export.

## What this covers

- encrypted SDUI payload transport and replay protection
- runtime type export via `QuantumSduiTypeEngine`
- JSON-driven test discovery and execution
- the `src/runtime/omni_cores/` subtype catalog
- the JSON fields used by the SDUI test runner
- source-level regression checks that protect against silent contract drift
- manifest-shape checks for the JSON test files themselves

## SDUI runtime layers

| Layer             | File                                               | Purpose                                                                        |
| ----------------- | -------------------------------------------------- | ------------------------------------------------------------------------------ |
| Transport         | `src/runtime/quantum_sdui_engine.dart`             | encrypted payloads, key rotation, replay protection, and client orchestration  |
| Type export       | `src/runtime/quantum_sdui_type_engine.dart`        | live registry snapshot, design-system export, and TypeScript bundle generation |
| JSON test engine  | `src/runtime/quantum_sdui_test_engine.dart`        | platform-aware export for the JSON test engine                                 |
| IO test engine    | `src/runtime/quantum_sdui_test_engine_io.dart`     | folder discovery, JSON loading, compile/render probes, blank-frame detection   |
| Shared test model | `src/runtime/quantum_sdui_test_engine_shared.dart` | portable viewport, metadata, result, and report types                          |
| Omni registry     | `src/runtime/quantum_omni_registry.dart`           | the runtime registry that routes SDUI subtypes into concrete builders          |

## JSON test folder contract

The `test/sdui_json/` directory is scanned recursively. Every `.json` file becomes one or more executable Flutter tests.

| File                                            | Role                                                                                   |
| ----------------------------------------------- | -------------------------------------------------------------------------------------- |
| `test/sdui_json/omni_cores_catalog.json`        | master source-derived catalog for the 20 omni-core files                               |
| `test/sdui_json/sdui_runtime_contract.json`     | runtime contract checks for the SDUI engine, type export, registry, and snapshot layer |
| `test/sdui_json/sdui_json_schema_contract.json` | schema validation for the JSON manifest format itself                                  |
| `test/sdui_json/omni_cores/*.json`              | optional per-core contract shards that can be added without changing Dart test code    |

## Canonical SDUI JSON surface

The runtime accepts SDUI payloads and test specs through JSON-shaped maps. The following keys appear repeatedly across the runtime and test layers.

| Key                                | Meaning                                           |
| ---------------------------------- | ------------------------------------------------- |
| `type`                             | root node type or runtime family                  |
| `subType`                          | concrete subtype handled by an omni-core builder  |
| `children` / `child`               | nested widget nodes                               |
| `bind`                             | store path or runtime binding key                 |
| `id` / `name` / `title`            | stable identifiers used by registries and reports |
| `label` / `value` / `text`         | user-facing content or node payload               |
| `style` / `props`                  | presentation and configuration blocks             |
| `slots` / `events`                 | embedded child nodes and action handlers          |
| `env` / `meta`                     | per-case environment and test metadata            |
| `__meta` / `_meta`                 | test-only metadata wrappers                       |
| `__viewport`                       | viewport override for render tests                |
| `__env`                            | environment block for JSON-driven tests           |
| `__tags`                           | free-form indexing tags                           |
| `__expect` / `__assert` / `__test` | test-only expectation blocks                      |
| `__name`                           | test-only display title                           |
| `cases` / `tests` / `rows`         | executable test rows in a manifest                |
| `sourcePath`                       | file to inspect for the contract                  |
| `sourceSha256`                     | pinned source fingerprint                         |
| `lineCountAtLeast`                 | lower bound for regression coverage               |
| `snapshotPath`                     | runtime export path used by snapshot assertions   |

## Supported dynamic JSON test actions

The JSON runner is intentionally explicit. Each case can request one or more of the following assertion kinds.

| Assertion kind                  | Behavior                                                                               |
| ------------------------------- | -------------------------------------------------------------------------------------- |
| `source_contains_all`           | Every listed string must appear in the target source file.                             |
| `source_contains_any`           | At least one listed string must appear in the target source file.                      |
| `source_not_contains`           | None of the listed strings may appear in the target source file.                       |
| `subtypes_exact`                | The extracted `subType ==` catalog must exactly match the expected list.               |
| `subtypes_contains`             | The extracted subtype catalog must include every expected subtype.                     |
| `builder_contains`              | The source file must contain every listed builder symbol.                              |
| `line_count_at_least`           | The file must meet or exceed the minimum line count.                                   |
| `source_sha256_matches`         | The source hash must match a pinned reference value.                                   |
| `snapshot_path_not_empty`       | A dotted snapshot path must resolve to a non-empty value in the live SDUI type export. |
| `json_round_trip`               | The JSON source must decode and re-encode without producing an empty payload.          |
| `json_round_trip_strict`        | The JSON source must remain stable after decode/encode/decode normalization.           |
| `json_root_keys_contains`       | The root JSON object must contain every expected key.                                  |
| `json_root_keys_exact`          | The root JSON object must contain exactly the expected keys.                           |
| `json_meta_keys_contains`       | The metadata block must contain every expected key.                                    |
| `json_meta_keys_exact`          | The metadata block must contain exactly the expected keys.                             |
| `json_case_count_at_least`      | The manifest must contain at least the requested number of cases.                      |
| `json_case_count_exact`         | The manifest must contain exactly the requested number of cases.                       |
| `json_case_keys_contains`       | Every manifest row must contain the requested keys.                                    |
| `json_case_keys_exact`          | Every manifest row must contain exactly the requested keys.                            |
| `json_case_ids_unique`          | Every manifest row id must be non-empty and unique.                                    |
| `json_case_assertions_nonempty` | Every case must have at least one assertion.                                           |
| `json_assertion_kinds_allowed`  | Every assertion kind in the manifest must be one of the allowed kinds.                 |

## Omni core subtype catalog

| Core file              | Builders                                                           | Subtype count | Observed subtypes                                                                                                                                                                                                                                     | Observed JSON keys                        | Source lines |
| ---------------------- | ------------------------------------------------------------------ | ------------: | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------- | -----------: |
| `action_core.dart`     | `_buildAction`                                                     |            11 | `button`, `chip`, `double_tap`, `focus`, `gesture`, `hover`, `icon_button`, `long_press`, `pointer`, `raw_pointer`, `viewport`                                                                                                                        | —                                         |          337 |
| `animation_core.dart`  | `_buildAnimation`                                                  |             0 | —                                                                                                                                                                                                                                                     | —                                         |          514 |
| `box_core.dart`        | `_buildBox, _buildSmartScrollViewport`                             |            23 | `aspect`, `builder`, `col`, `expanded`, `flexible`, `grid`, `layer`, `masonry`, `matrix`, `measure`, `morph`, `responsive`, `row`, `safe`, `scroll`, `shell`, `split`, `stack`, `sticky`, `surface`, `viewport`, `virtual_grid`, `wrap`               | —                                         |          719 |
| `canvas_core.dart`     | `_buildCanvas`                                                     |             4 | `draw`, `plot`, `shader`, `shape`                                                                                                                                                                                                                     | —                                         |          283 |
| `chart_core.dart`      | `_buildChart`                                                      |             0 | —                                                                                                                                                                                                                                                     | —                                         |           48 |
| `collab_core.dart`     | `_buildCollab`                                                     |             5 | `awareness`, `cursor`, `lock`, `patch`, `presence`                                                                                                                                                                                                    | —                                         |          194 |
| `connect_core.dart`    | `_buildConnect`                                                    |             0 | —                                                                                                                                                                                                                                                     | —                                         |          328 |
| `control_core.dart`    | `_buildControl`                                                    |            11 | `accordion`, `architecture`, `flow`, `form_scope`, `machine`, `optimistic`, `reducer`, `saga`, `stepper`, `tabs`, `tca`                                                                                                                               | —                                         |          487 |
| `data_core.dart`       | `_buildData`                                                       |            17 | `aggregate`, `cursor`, `diff`, `grid`, `infinite`, `kanban`, `masonry`, `paginated`, `realtime`, `repeat`, `slice`, `sliver`, `sliver_plane`, `stream`, `table`, `timeline`, `virtual_scroll`                                                         | —                                         |          311 |
| `decoration_core.dart` | `_buildDecoration, _buildDecorationRichText`                       |            10 | `badge`, `blur`, `border`, `gradient`, `rich`, `ripple`, `shadow`, `skeleton`, `span`, `text`                                                                                                                                                         | —                                         |          219 |
| `field_core.dart`      | `_buildField`                                                      |            13 | `cell`, `email`, `multiline`, `number`, `password`, `radio`, `rich_text`, `search`, `slider`, `tel`, `textarea`, `toggle`, `url`                                                                                                                      | —                                         |          521 |
| `hook_core.dart`       | `_buildHook`                                                       |            16 | `atom`, `bridge`, `change`, `delegate`, `effect`, `error_boundary`, `guard`, `interval`, `lifecycle`, `memo`, `mount`, `observable`, `ref`, `scope`, `slice`, `store`                                                                                 | `type`, `props`, `debugPath`              |          523 |
| `layout_core.dart`     | `_buildLayout, _buildDecorationPartSpan, _buildDecorationRichText` |             0 | —                                                                                                                                                                                                                                                     | —                                         |          992 |
| `media_core.dart`      | `_buildMedia`                                                      |            11 | `audio`, `audio_visualizer`, `avatar`, `camera`, `canvas_video`, `icon`, `path`, `stream`, `svg_path`, `video`, `webrtc`                                                                                                                              | —                                         |          397 |
| `portal_core.dart`     | `_buildPortal`                                                     |            14 | `anchored_floating`, `context_menu`, `context_panel`, `drawer`, `dropdown`, `expandable_inline`, `flyout`, `menu`, `overlay`, `overlay_entry`, `popover`, `sheet`, `toast`, `window`                                                                  | —                                         |          759 |
| `stream_core.dart`     | `_buildStream`                                                     |             5 | `multiplex`, `ring`, `sse`, `tick`, `ws`                                                                                                                                                                                                              | —                                         |          181 |
| `system_core.dart`     | `_buildSystem, _buildSmartScrollViewport`                          |            21 | `async`, `clipboard`, `data_pipe`, `debounce`, `download`, `geo`, `haptic`, `kinetic_pipe`, `macro`, `notification`, `omega_macro`, `repeater`, `sensor`, `share`, `store_provider`, `sync_scroll`, `throttle`, `ticker`, `timer`, `upload`, `worker` | —                                         |          601 |
| `template_core.dart`   | `_buildTemplate`                                                   |             0 | —                                                                                                                                                                                                                                                     | `props`, `children`, `slots`, `debugPath` |         3102 |
| `text_core.dart`       | `_buildText`                                                       |             6 | `code`, `h1`, `h2`, `h3`, `label`, `rich`                                                                                                                                                                                                             | —                                         |          190 |
| `visual_core.dart`     | `_buildVisual, _buildAnimation, _buildBox`                         |            24 | `action`, `animation`, `box`, `canvas`, `chart`, `compose`, `connect`, `control`, `data`, `decoration`, `delegate`, `field`, `layer`, `layout`, `media`, `overlay`, `portal`, `scene`, `shell`, `stack`, `surface`, `system`, `template`, `text`      | `type`, `props`, `debugPath`              |          309 |

## Notes for production-grade coverage

- Prefer `subtypes_exact` for catalog files so the list is pinned and reviewable.
- Pair every source contract with a snapshot assertion for the runtime registry.
- Use `source_sha256_matches` for files whose exact shape matters.
- Keep `json_round_trip_strict` on manifest files so edits cannot silently change the machine-readable structure.
- When a source file has no subtypes, the suite still checks its builder entry points and runtime snapshot presence.

## Example manifest shape

```json
{
  "__meta": {
    "id": "omni-cores-catalog",
    "title": "Omni cores subtype and JSON key catalog",
    "description": "Source-derived JSON contract for every file in lib/src/runtime/omni_cores.",
    "tags": ["sdui", "omni_cores", "catalog", "source-derived", "runtime"],
    "allowBlank": true
  },
  "cases": [
    {
      "id": "box-declaration-contract",
      "title": "box_core.dart declaration contract",
      "sourcePath": "src/runtime/omni_cores/box_core.dart",
      "assertions": [
        { "kind": "source_contains_all", "values": ["_buildBox"] },
        { "kind": "subtypes_exact", "expected": ["aspect", "builder", "col"] }
      ]
    }
  ]
}
```

The suite automatically discovers every JSON file in this folder recursively.

## Nested manifest model

The JSON runner now understands nested groups as first-class test structure. A manifest may contain a flat root `cases` array, a recursive `groups` tree, or both.

| Node            | Keys                                                                                                         | Purpose                                                |
| --------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------ |
| Suite           | `__meta`, `meta`, `cases`, `tests`, `rows`, `groups`, `sections`                                             | Root manifest metadata and entry points                |
| Group           | `id`, `name`, `title`, `description`, `tags`, `cases`, `tests`, `rows`, `groups`, `sections`                 | Organize contracts by feature family, module, or layer |
| Case            | `id`, `title`, `description`, `sourcePath`, `snapshotPath`, `sourceSha256`, `lineCountAtLeast`, `assertions` | Execute one contract row                               |
| Assertion block | `kind`, `values`, `expected`, `value`, `path`, `assertions`                                                  | Compose checks, including nested `all` / `any` / `not` |

### Deep JSON path checks

The path engine uses dotted access with optional array indexes, for example:

- `groups`
- `groups[0]`
- `groups[0].groups[0]`
- `groups[0].groups[0].rows[1].assertions[0].kind`

### Advanced assertion kinds

| Kind                        | Purpose                                                                               |
| --------------------------- | ------------------------------------------------------------------------------------- |
| `all`                       | Run every nested assertion and require all of them to pass.                           |
| `any`                       | Pass when at least one nested assertion passes.                                       |
| `not`                       | Pass only when the nested assertion block fails.                                      |
| `json_path_exists`          | Confirm that a deep JSON path resolves to a value.                                    |
| `json_path_not_empty`       | Confirm that a deep JSON path resolves to a non-blank value.                          |
| `json_path_equals`          | Compare a deep JSON path against an expected scalar string.                           |
| `json_path_contains_all`    | Require every expected item to appear at a deep path.                                 |
| `json_path_contains_any`    | Require at least one expected item at a deep path.                                    |
| `json_path_keys_contains`   | Require an object node to contain the listed keys.                                    |
| `json_path_keys_exact`      | Require an object node to contain exactly the listed keys.                            |
| `json_path_length_at_least` | Require a list, map, or string to meet a minimum size.                                |
| `json_path_length_exact`    | Require a list, map, or string to match an exact size.                                |
| `json_path_type_is`         | Require the resolved node to be `list`, `map`, `string`, `number`, `bool`, or `null`. |

### New nested fixtures

- `test/sdui_json/omni_cores_nested_catalog.json`
- `test/sdui_json/sdui_runtime_nested_contract.json`

These fixtures keep the original source contracts, but organize them into a more realistic nested runtime shape.
