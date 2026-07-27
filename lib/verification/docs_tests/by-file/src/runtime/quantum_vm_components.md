---
file: lib/src/runtime/quantum_vm_components.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: ddc9475a0cc0cffa53f491a188a7c4a0c083bf89ecb0fd29d1447738522dc9da
source_line_count: 2492
public_surface_count: 57
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

# Test Specification: `src/runtime/quantum_vm_components.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `_AliasContext`
- `_QLBlueprintRuntimeRule`
- `_QLComponentDefinition`
- `_QLComponentComputedSpec`
- `_QLComponentEffectSpec`
- `_QLComponentHookBundle`
- `_QLComponentRuntimeHost`
- `_QLComponentRuntimeHostState`
- `_QLComponentSignalBinding`
- `QuantumComponentBuilder`
- `QLContextSubtype`
- `_nativeComponentDescribe`
- `_buildComponent`
- `_registerComponentAliases`
- `_buildComponentDefine`
- `_buildComponentUse`
- `_buildComponentScoped`
- `_buildComponentLink`
- `_registerComponentDefinition`
- `_resolveComponentDefinition`
- `_compileComponentDefinition`
- `_componentSchemaForValue`
- `_componentRawMap`
- `_compileDefinitionFromRaw`

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

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_vm_components.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
