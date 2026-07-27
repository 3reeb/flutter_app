---
file: lib/src/ui/quantum_forms_engine.dart
layer: ui
kind: test specification
role: forms-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: b046e7072ccb68102c1c0741d91b2c480769f70e1aba4bf6861c06dccdd8c48e
source_line_count: 2534
public_surface_count: 48
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

# Test Specification: `src/ui/quantum_forms_engine.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

controller binding, validation, array-aware field handling, graph synchronization, media payload handling, and the extended scalar/controller matrix.

## Source surface discovered

### Public surface

- `QLChangeEvent`
- `_QLObserver`
- `QLDataNode`
- `QLGraphController`
- `QLFormController`
- `QLValidators`
- `QLTransforms`
- `QLFieldController`
- `QLTextController`
- `QLTextAreaController`
- `QLNumberController`
- `QLSmallIntController`
- `QLBigIntController`
- `QLDecimalController`
- `QLCharController`
- `QLFlagsController`
- `QLMediaController`
- `QLSmallIntArrayController`
- `QLBigIntArrayController`
- `QLDecimalArrayController`
- `QLCharArrayController`
- `QLFlagsArrayController`
- `QLMediaArrayController`
- `QLBoolController`

### Imports

- `dart:async`
- `dart:collection`
- `../foundation/quantum_core.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — controller bootstrap and basic binding sanity
- **edges** — null, invalid schema, and malformed input handling
- **controller-matrix** — scalar and array controllers for bigInt, smallInt, decimal, char, flags, and media
- **validation** — synchronous and deferred validation behavior
- **graph-sync** — state propagation and observer consistency
- **integration** — schema and runtime integration
- **performance** — mutation churn and low-allocation updates
- **regression** — silent stale state, lost errors, and event-order drift

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
- dependency `dart:collection` should be validated as a potential compatibility boundary.
- local dependency `../foundation/quantum_core.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/ui/quantum_forms_engine.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
