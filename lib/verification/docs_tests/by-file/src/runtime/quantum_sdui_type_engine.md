---
file: lib/src/runtime/quantum_sdui_type_engine.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: d5a0cc0258632fc24927f5688566fb572ed7cb386fbf66e7f89a7386405f50c2
source_line_count: 246
public_surface_count: 2
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

# Test Specification: `src/runtime/quantum_sdui_type_engine.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `QuantumSduiTypeBundle`
- `QuantumSduiTypeEngine`

### Imports

- `dart:convert`
- `package:flutter/foundation.dart`
- `quantum_core_schema_registry.dart`
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

- dependency `dart:convert` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `quantum_core_schema_registry.dart` should be validated as a potential compatibility boundary.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_sdui_type_engine.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## SDUI JSON contract integration

This type-export file is exercised by the executable JSON contract suite documented in `docs_tests/cross-cutting/sdui_json_contract.md`. The suite checks that the live snapshot export still exposes `registry`, `coreSchemas`, `coreFiles`, `designSystems`, `themeConfig`, `omniCores`, `dslOperators`, `aliasRegistry`, and `orchestrator`.

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.
