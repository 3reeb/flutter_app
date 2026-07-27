---
file: lib/src/ui/quantum_components.dart
layer: ui
kind: test specification
role: ui-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 935e73896cc9ad6d9eff4c3cd2b03d27c2344e9059a159d7bd239527ea5e3138
source_line_count: 1517
public_surface_count: 30
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

# Test Specification: `src/ui/quantum_components.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

UI composition, state sync, hydration, rendering stability, and input behavior.

## Source surface discovered

### Public surface

- `QLSensor`
- `_QLSensorState`
- `QLSpace`
- `_QLRow`
- `_QLColumn`
- `_QLAdaptive`
- `QLViewport`
- `_QLViewportState`
- `QLSpacer`
- `QLDivider`
- `QLScrollCoordinator`
- `QLCarousel`
- `_QLCarouselState`
- `QLDots`
- `QLSwipeAction`
- `_QLSpringMorphState`
- `QLAccordion`
- `_QLAccordionState`
- `QLSpringMorph`
- `_QLSwipeActionState`
- `QLStickyLayer`
- `_QLStickyLayerState`
- `QLHeroEngine`
- `QLSlider`

### Imports

- `dart:async`
- `dart:typed_data`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `package:flutter/rendering.dart`
- `package:flutter/scheduler.dart`
- `package:flutter/services.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — widget/controller bootstrap and stable build
- **edges** — empty input, invalid state, and malformed schema
- **input** — focus, validation, and event handling
- **layout** — measurement and rebuild stability
- **hydration** — read/hydrate reattachment behavior
- **performance** — build churn and low-copy updates
- **regression** — stale UI state, duplicate listeners, and hidden eager work

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
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/rendering.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/scheduler.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/services.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/ui/quantum_components.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
