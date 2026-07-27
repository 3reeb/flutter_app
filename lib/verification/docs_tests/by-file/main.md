---
file: main.dart
layer: root
kind: test specification
role: root-entry
test_status: draft
last_reviewed: '2026-07-26'
source_sha256: 576d965b32cdd3f7e0ee2032acb99b272f18605aa83b49bb2c37c08826cc0bcc
source_line_count: 2036
public_surface_count: 9
regeneration_triggers:
- Any signature, branch, or contract change in the source file
- Any change in an imported neighbor that affects this file's behavior
- Any update to cache, lazy-load, serialization, registry, or platform logic
coverage_targets:
- public API
- failure paths
- performance
- integration boundaries
- regression traps
---

# Test Specification: `main.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

entry-point wiring, exports, and top-level bootstrap behavior.

## Source surface discovered

### Public surface

- `SduiStudioWidget`
- `_SduiStudioWidgetState`
- `_MeasureSize`
- `_MeasureSizeRenderObject`
- `_StudioExample`
- `_ExampleHealthResult`
- `_LineNumberGutter`
- `_DotGridPainter`
- `main`

### Imports

- `dart:convert`
- `package:flutter/material.dart`
- `package:flutter/services.dart`
- `src/runtime/quantum_sdui_test_engine_io.dart`
- `package:flutter/rendering.dart`
- `downloader.dart`
- `quantum.dart`

## Testing priorities

- **smoke** — entry-point export sanity
- **edges** — missing config and empty bootstrap data
- **bootstrap** — top-level initialization order
- **integration** — docs, app, and runtime handoff
- **regression** — export drift and stale boot wiring

## Failure modes this spec must catch

- silent coercion of invalid values
- hidden eager loading before the first access boundary
- duplicate side effects on repeat calls
- stale cache or registry state after mutation
- accidental loss of metadata, ordering, or shape
- incorrect platform fallback selection

## Performance and memory goals

- prefer stable reuse on repeated work
- avoid copying large collections unless the contract says so
- keep first-access work explicit for lazy branches
- keep hot-path lookup cost low
- preserve allocation discipline on repeated mutation

## Integration notes

- dependency `dart:convert` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/services.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `src/runtime/quantum_sdui_test_engine_io.dart` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/rendering.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `downloader.dart` should be validated as a potential compatibility boundary.
- dependency `quantum.dart` should be validated as a potential compatibility boundary.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/main.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
