---
file: lib/src/plugins/quantum_domain.dart
layer: plugins
kind: test specification
role: plugin-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: f6deccd1edd2df6215230accd36869759e95842918520e2d8d93087c047b38dd
source_line_count: 475
public_surface_count: 17
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

# Test Specification: `src/plugins/quantum_domain.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

plugin registration, adapter selection, fallback, and integration safety.

## Source surface discovered

### Public surface

- `QuantumShellApiClient`
- `_QuantumShellAuthClient`
- `QuantumStreamRegistry`
- `_QuantumRunAction`
- `_QuantumDomainAction`
- `_QuantumStreamStartAction`
- `_QuantumStreamCancelAction`
- `_QuantumStreamCancelAllAction`
- `_QuantumStreamInAction`
- `_QuantumStreamOutAction`
- `QuantumPayloadBuilder`
- `quantumApiShellDomain`
- `_requestFromPayload`
- `_normalizeBinaryArgs`
- `_storeResult`
- `_unwrap`
- `_collectionWriteAction`

### Imports

- `dart:async`
- `dart:typed_data`
- `package:flutter/widgets.dart`
- `../app/quantum_app_shell.dart`
- `../../quantum.dart`
- `quantum_api_shell.dart`

## Testing priorities

- **smoke** — basic plugin registration and invocation sanity
- **edges** — null, empty, malformed, and permission-denied inputs
- **platform** — platform divergence and fallback selection
- **integration** — consumer and adapter handoff behavior
- **performance** — repeat dispatch and low-allocation handling
- **regression** — silent failure, stale adapters, and event-order drift

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
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/widgets.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../app/quantum_app_shell.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- dependency `quantum_api_shell.dart` should be validated as a potential compatibility boundary.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/plugins/quantum_domain.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
