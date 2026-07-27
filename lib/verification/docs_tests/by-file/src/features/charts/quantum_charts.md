---
file: lib/src/features/charts/quantum_charts.dart
layer: features
kind: test specification
role: feature-charts
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: cabe7f1499b19a1610df7fae33d8fb2cb26dbe665c94472a6093777d8aec8539
source_line_count: 810
public_surface_count: 8
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

# Test Specification: `src/features/charts/quantum_charts.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

chart data shaping, rendering contracts, and update stability.

## Source surface discovered

### Public surface

- `QLChartDataBuffer`
- `QLUniversalChart`
- `_QLUniversalChartState`
- `_QLGridPainter`
- `_QLCrosshairPainter`
- `_QLDataPainter`
- `QLChartType`
- `buildChart`

### Imports

- `dart:collection`
- `package:flutter/material.dart`
- `../../../quantum.dart`
- `package:flutter/foundation.dart`

## Testing priorities

- **smoke** — chart engine bootstrap and simple render path
- **edges** — empty datasets and malformed series
- **rendering** — stable chart build/update behavior
- **integration** — layout and theme consumers
- **performance** — large series and update churn
- **regression** — axis drift and stale render state

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

- dependency `dart:collection` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/features/charts/quantum_charts.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
