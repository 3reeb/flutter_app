---
file: lib/src/foundation/quantum_render_scheduler.dart
layer: foundation
kind: test specification
role: render-scheduler
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: b121492e0477309b9a5a96015e4dd62bed0c3c1266d0c1b38531ab3a72cef222
source_line_count: 572
public_surface_count: 11
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

# Test Specification: `src/foundation/quantum_render_scheduler.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

frame scheduling, coalescing, prioritization, and starvation resistance.

## Source surface discovered

### Public surface

- `QLFrameBudget`
- `QLRenderWorkItem`
- `QLRenderScheduler`
- `QLBatchedSceneLayer`
- `QLAdaptiveThrottle`
- `QLRenderScope`
- `QLFrameMonitor`
- `_QLFrameMonitorState`
- `QLRenderPriority`
- `QLSceneLayerSchedulerExt`
- `QLSignalThrottleExt`

### Imports

- `dart:async`
- `dart:collection`
- `dart:typed_data`
- `package:flutter/foundation.dart`
- `package:flutter/scheduler.dart`
- `package:flutter/widgets.dart`
- `quantum_primitives.dart`
- `../ui/quantum_scene_layer.dart`

## Testing priorities

- **smoke** — single frame scheduling
- **edges** — empty queue and invalid slot handling
- **coalescing** — merge repeated requests
- **prioritization** — high/low priority ordering
- **performance** — busy queue and starvation resistance
- **regression** — dropped frame and duplicate dispatch

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

- dependency `dart:async` should be validated as a potential compatibility boundary.
- dependency `dart:collection` should be validated as a potential compatibility boundary.
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/scheduler.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/widgets.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `quantum_primitives.dart` should be validated as a potential compatibility boundary.
- local dependency `../ui/quantum_scene_layer.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/foundation/quantum_render_scheduler.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
