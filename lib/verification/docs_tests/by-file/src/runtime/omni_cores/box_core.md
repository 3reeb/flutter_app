---
file: lib/src/runtime/omni_cores/box_core.dart
layer: runtime
kind: test specification
role: runtime-omni-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: cf9bfecea439451ed25257e137ce5f6f3350ed0404d9a5732577485d06954d1a
source_line_count: 719
public_surface_count: 6
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

# Test Specification: `src/runtime/omni_cores/box_core.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

omni-core capability declarations, shared behavior, and composition safety.

## Source surface discovered

### Public surface

- `_QLMeasureNode`
- `_RenderMeasureNode`
- `_buildBox`
- `_applyImplicitBehaviors`
- `_buildSmartScrollViewport`
- `_registerBoxAliases`

### Imports

- `(none)`

## Testing priorities

- **smoke** — capability declaration sanity
- **edges** — missing slots and malformed payloads
- **integration** — runtime and UI consumers
- **performance** — capability lookup churn
- **regression** — silent capability drift

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

- Base manifest: `docs_tests/yaml/by-file/src/runtime/omni_cores/box_core.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
