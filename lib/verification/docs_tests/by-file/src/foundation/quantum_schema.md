---
file: lib/src/foundation/quantum_schema.dart
layer: foundation
kind: test specification
role: schema-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 8c331d3f6ba80ced9a9564e22cece44a2405a3426b6e6830d55a2b0bafe056c5
source_line_count: 1433
public_surface_count: 9
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

# Test Specification: `src/foundation/quantum_schema.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

field typing, projection, read-plan compilation, compatibility, serialization, hasMany handling, and the extended scalar/media type matrix.

## Source surface discovered

### Public surface

- `QLBlockPayload`
- `QLSchemaFieldSpec`
- `QLSchemaBlueprint`
- `QLSchemaCompiler`
- `QLSchemaRegistry`
- `QLSchemaReadPlan`
- `QLSchemaRegistryInspector`
- `QLSchemaBlueprintSmartSelect`
- `_qlDeepMergeSchemaMaps`

### Imports

- `dart:collection`
- `dart:typed_data`
- `../../quantum.dart`

## Testing priorities

- **smoke** — basic compile and round-trip sanity
- **edges** — invalid, empty, mixed, and duplicate input paths
- **type-matrix** — bigInt, smallInt, decimal, char, flags, media, and hasMany combinations
- **projection** — field selection and path narrowing behavior
- **serialization** — parse/serialize compatibility and legacy shapes
- **integration** — registry and dependent file integration
- **performance** — hot-path compilation, linear selection, and low-copy behavior
- **regression** — silent data loss, stale field maps, and normalization drift

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
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/foundation/quantum_schema.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
