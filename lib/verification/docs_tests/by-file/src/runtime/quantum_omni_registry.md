---
file: lib/src/runtime/quantum_omni_registry.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: f43ff071d31cafe18a63df869dfb15967dfb080779671877d604d49bca93f01f
source_line_count: 457
public_surface_count: 4
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

# Test Specification: `src/runtime/quantum_omni_registry.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `_AliasContext`
- `QDesignMatrix`
- `clearQuantumInputRegistry`
- `registerOmniComponents`

### Imports

- `dart:collection`
- `dart:typed_data`
- `dart:async`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `package:flutter/rendering.dart`
- `package:flutter/scheduler.dart`
- `package:flutter/services.dart`
- `package:flutter/gestures.dart`
- `quantum_template_engine.dart`
- `../../quantum.dart`
- `../foundation/quantum_json_dsl.dart`
- `../features/charts/quantum_charts.dart`
- `../foundation/quantum_matrix_engine.dart`

## Testing priorities

- **smoke** — runtime object creation and lookup
- **edges** — empty registry and malformed runtime inputs
- **registry** — register/resolve/remove behavior
- **integration** — state, pipeline, VM, and UI consumers
- **performance** — hot-path reuse and lazy loading
- **regression** — silent stale state and hidden eager loads

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
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- dependency `dart:async` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/rendering.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/scheduler.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/services.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/gestures.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `quantum_template_engine.dart` should be validated as a potential compatibility boundary.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../foundation/quantum_json_dsl.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../features/charts/quantum_charts.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../foundation/quantum_matrix_engine.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_omni_registry.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## SDUI JSON contract integration

The omni registry is validated by the executable JSON suite in `docs_tests/cross-cutting/sdui_json_contract.md`. That suite verifies the registry bootstrap symbols, the part-file wiring, and the source-derived subtype catalogs for `src/runtime/omni_cores/`.

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.
