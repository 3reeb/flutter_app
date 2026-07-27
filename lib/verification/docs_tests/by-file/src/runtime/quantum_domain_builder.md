---
file: lib/src/runtime/quantum_domain_builder.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: cce8a7a669ef08505359a3c2e21c5c0e2e5f9391e8da43f1fdfd9d15d13c6b19
source_line_count: 303
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

# Test Specification: `src/runtime/quantum_domain_builder.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `QuantumDomainBuilder`
- `_QuantumProxyActionPlugin`
- `quantumDomain`

### Imports

- `package:flutter/widgets.dart`
- `../../quantum.dart`
- `../plugins/quantum_api_shell.dart`

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

- package dependency `package:flutter/widgets.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../plugins/quantum_api_shell.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_domain_builder.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.
