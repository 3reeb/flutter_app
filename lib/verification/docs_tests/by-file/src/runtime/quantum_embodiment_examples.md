---
file: lib/src/runtime/quantum_embodiment_examples.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 352f382e78fec8bd08e5624f0c7d1ed5060686826f087bf71ba36e1b697e7800
source_line_count: 781
public_surface_count: 21
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

# Test Specification: `src/runtime/quantum_embodiment_examples.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `QEEExamples`
- `_dataBasicSetAndRead`
- `_dataMergeAndSnapshot`
- `_dataRollbackOnFailure`
- `_jsonCompileProductCard`
- `_jsonInjectWithMacros`
- `_jsonCompileAndProfile`
- `_actionStateSet`
- `_actionPipeline`
- `_ensureTestSchemas`
- `_schemaValidateUser`
- `_schemaParseAndSerialize`
- `_vmCacheStats`
- `_vmRegisteredActions`
- `_scriptCustomLambda`
- `_policyNoNegativeTotal`
- `_policyFatalViolation`
- `_scenarioCartCheckout`
- `_scenarioRollback`
- `_perf1000Reads`
- `_perf500Compiles`

### Imports

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

- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_embodiment_examples.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
