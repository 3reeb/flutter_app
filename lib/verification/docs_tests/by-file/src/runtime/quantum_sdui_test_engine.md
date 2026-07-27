---
file: lib/src/runtime/quantum_sdui_test_engine.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: a5a8224d55efa1b7e3f8f92ea384fdc0ca88fa35e9ddbbb6fee7d6323bc259a5
source_line_count: 13
public_surface_count: 0
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

# Test Specification: `src/runtime/quantum_sdui_test_engine.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `(none discovered)`

### Imports

- `(none)`

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

- This file has no imports, so the test focus stays on the file-local contract and any runtime side effects.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_sdui_test_engine.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## SDUI JSON contract integration

This file is the stable anchor for the JSON-driven SDUI test runner. The executable suite in `docs_tests/cross-cutting/sdui_json_contract.md` depends on the IO implementation and the shared model to turn JSON manifests into actual test cases.

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.
