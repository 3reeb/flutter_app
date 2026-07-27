---
file: lib/src/foundation/quantum_atoms.dart
layer: foundation
kind: test specification
role: atoms
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 85c2a9bae5d910c27dfa6761dcbb99d31ef06abbaacd265ded7a3767605d366b
source_line_count: 302
public_surface_count: 10
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

# Test Specification: `src/foundation/quantum_atoms.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

atom creation, mutation, signals, and stable identity behavior.

## Source surface discovered

### Public surface

- `QLStateAtom`
- `QLComputedAtom`
- `QLStoreAtom`
- `QLAtomFamily`
- `QLAtomBuilder`
- `QLAtomEquals`
- `QLAtomDecoder`
- `QLAtomEncoder`
- `QLDataStoreAtomExt`
- `QuantumVMAtomExt`

### Imports

- `dart:collection`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `../../quantum.dart`
- `quantum_reactive_graph.dart`

## Testing priorities

- **smoke** — atom create and mutate
- **edges** — invalid state and empty metadata
- **signals** — subscription and propagation
- **integration** — graph and store consumers
- **performance** — hot mutation paths
- **regression** — stale identity or missing notification

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
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- dependency `quantum_reactive_graph.dart` should be validated as a potential compatibility boundary.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/foundation/quantum_atoms.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.
