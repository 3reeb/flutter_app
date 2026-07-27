---
file: lib/src/foundation/quantum_isolate_worker.dart
layer: foundation
kind: test specification
role: isolate-worker
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: a04f01373f55a93aad48abef6dae14fc5c3656b18396c711b9e50fe5040b016e
source_line_count: 613
public_surface_count: 13
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

# Test Specification: `src/foundation/quantum_isolate_worker.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

worker lifecycle, command handling, and failure reporting.

## Source surface discovered

### Public surface

- `QLTransferableBuffer`
- `_WorkerRequest`
- `_WorkerResponse`
- `_WorkerBootstrap`
- `QLWorkerTask`
- `QLIsolateWorker`
- `QLWorkerPool`
- `QLFloat64BatchTask`
- `QLJsonDecodeTask`
- `QLZeroCopyPipelineTask`
- `QLEcsSyncTask`
- `QLSpatialProjectionTask`
- `QLAsyncWorkerExt`

### Imports

- `dart:async`
- `dart:isolate`
- `dart:typed_data`
- `dart:convert`
- `package:flutter/foundation.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — worker launch and command response
- **edges** — invalid command, early termination, and failure
- **lifecycle** — start, pause, resume, and stop
- **integration** — bridge and scheduler handoff
- **performance** — heavy queue processing
- **regression** — missed wake-ups and repeated execution

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
- dependency `dart:isolate` should be validated as a potential compatibility boundary.
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- dependency `dart:convert` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/foundation/quantum_isolate_worker.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
