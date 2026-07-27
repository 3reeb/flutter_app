---
file: lib/src/plugins/native/quantum_location.dart
layer: plugins
kind: test specification
role: plugin-native
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 5adfa06c0434e6ccc625c0a44829f478d7d172c3327420159be83e956ce10760
source_line_count: 71
public_surface_count: 5
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

# Test Specification: `src/plugins/native/quantum_location.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

plugin registration, adapter selection, fallback, and integration safety.

## Source surface discovered

### Public surface

- `LocationData`
- `_VoidLocationCodec`
- `_CurrentLocationBridge`
- `_LocationStreamBridge`
- `QuantumLocation`

### Imports

- `package:flutter/foundation.dart`
- `../../platform/quantum_native_bridge.dart`
- `../../foundation/quantum_async.dart`

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

- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../platform/quantum_native_bridge.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../foundation/quantum_async.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/plugins/native/quantum_location.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.
