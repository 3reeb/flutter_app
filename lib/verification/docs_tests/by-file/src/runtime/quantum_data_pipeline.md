---
file: lib/src/runtime/quantum_data_pipeline.dart
layer: runtime
kind: test specification
role: data-pipeline-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 8ab30404e7cddd3d0275516558c0f8b93bf107dde721c41c059996b7b779c432
source_line_count: 1132
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

# Test Specification: `src/runtime/quantum_data_pipeline.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

pipeline assembly, staged execution, routing, transform chains, retry behavior, cache-aware reads, and regression safety.

## Source surface discovered

### Public surface

- `QLPrefetchConfig`
- `QLAggregateOp`
- `QLPipelineDelegate`
- `QLDataPipeline`
- `QLPipelineRegistry`
- `QLDataPipelineReadPlan`
- `QLPipelineMode`
- `QLExecutionMode`
- `QLDataPipelineSmartAccess`

### Imports

- `dart:async`
- `dart:collection`
- `dart:typed_data`
- `package:flutter/foundation.dart`
- `quantum_data_state.dart`
- `../foundation/quantum_primitives.dart`
- `../foundation/quantum_core.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — pipeline assembly and basic execution
- **edges** — empty stage list, bad input, and exception handling
- **routing** — source selection and branch dispatch
- **streaming** — batched and streamed execution behavior
- **cache** — cache-aware pipeline paths and reuse
- **integration** — state/orchestrator handoff
- **performance** — throughput and backpressure on large workloads
- **regression** — ordering bugs, retry drift, and silent drops

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
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `quantum_data_state.dart` should be validated as a potential compatibility boundary.
- local dependency `../foundation/quantum_primitives.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../foundation/quantum_core.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_data_pipeline.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
