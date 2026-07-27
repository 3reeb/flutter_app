---
file: lib/src/runtime/quantum_vm_init.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: ca2abf5a3224a158e45d24ae66386b214cec6ce9e253e8107b887a58be5d185c
source_line_count: 501
public_surface_count: 3
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

# Test Specification: `src/runtime/quantum_vm_init.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `_BuiltInActionPlugin`
- `LambdaActionPlugin`
- `initQuantumBuiltIns`

### Imports

- `package:flutter/material.dart`
- `dart:typed_data`
- `../ui/quantum_theme_engine.dart`
- `../ui/quantum_components.dart`
- `../ui/quantum_behaviors.dart`
- `../ui/quantum_navigation_engine.dart`
- `quantum_data_orchestrator.dart`
- `quantum_omni_registry.dart`
- `quantum_core_schema_registry.dart`
- `quantum_sdui_type_engine.dart`
- `quantum_vm.dart`
- `quantum_data_pipeline.dart`
- `../../quantum.dart`

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

- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- local dependency `../ui/quantum_theme_engine.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../ui/quantum_components.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../ui/quantum_behaviors.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../ui/quantum_navigation_engine.dart` is part of the integration surface and should be tested alongside this file.
- dependency `quantum_data_orchestrator.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_omni_registry.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_core_schema_registry.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_sdui_type_engine.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_vm.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_data_pipeline.dart` should be validated as a potential compatibility boundary.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_vm_init.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
