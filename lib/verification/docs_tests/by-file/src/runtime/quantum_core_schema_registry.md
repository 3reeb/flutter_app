---
file: lib/src/runtime/quantum_core_schema_registry.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 90bf9c28fc72ad3a4a5dfa27291f3cac07dbd0dbb63835d2f49c7b4f9ec61ece
source_line_count: 2112
public_surface_count: 7
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

# Test Specification: `src/runtime/quantum_core_schema_registry.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `QLCorePropSpec`
- `QLCoreSlotSpec`
- `QLCoreSchemaDescriptor`
- `QuantumCoreSchemaRegistry`
- `_schema`
- `_prop`
- `_slot`

### Imports

- `dart:async`
- `package:flutter/foundation.dart`
- `../foundation/quantum_yaml_engine.dart`
- `quantum_core_file_registry.dart`

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

- dependency `dart:async` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../foundation/quantum_yaml_engine.dart` is part of the integration surface and should be tested alongside this file.
- dependency `quantum_core_file_registry.dart` should be validated as a potential compatibility boundary.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_core_schema_registry.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
