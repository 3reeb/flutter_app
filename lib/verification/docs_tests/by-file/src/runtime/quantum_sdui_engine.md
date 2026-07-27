---
file: lib/src/runtime/quantum_sdui_engine.dart
layer: runtime
kind: test specification
role: runtime-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 2276ee4570dc90680c648fb0d9ec6dcb4cc8bf1c31d6115a12ff3eba04ca1119
source_line_count: 1222
public_surface_count: 15
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

# Test Specification: `src/runtime/quantum_sdui_engine.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

runtime orchestration, registries, state distribution, and integration safety.

## Source surface discovered

### Public surface

- `QuantumSduiException`
- `SduiEncryptedPayload`
- `SduiKeyStore`
- `SduiReplayGuard`
- `_AesGcm`
- `_AesEngine`
- `QuantumSduiEngine`
- `QLApiRequest`
- `QLApiResponse`
- `QuantumApiEngine`
- `_SduiFetchAction`
- `_ApiReadAction`
- `_ApiWriteAction`
- `QLSduiWidget`
- `_QLSduiWidgetState`

### Imports

- `dart:async`
- `dart:collection`
- `dart:convert`
- `dart:math`
- `dart:typed_data`
- `package:crypto/crypto.dart`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `quantum_permissions.dart`
- `../../quantum.dart`
- `../foundation/quantum_yaml_engine.dart`

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

- dependency `dart:async` should be validated as a potential compatibility boundary.
- dependency `dart:collection` should be validated as a potential compatibility boundary.
- dependency `dart:convert` should be validated as a potential compatibility boundary.
- dependency `dart:math` should be validated as a potential compatibility boundary.
- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- package dependency `package:crypto/crypto.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- dependency `quantum_permissions.dart` should be validated as a potential compatibility boundary.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../foundation/quantum_yaml_engine.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_sdui_engine.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## SDUI JSON contract integration

This runtime file is exercised by the executable JSON contract suite documented in `docs_tests/cross-cutting/sdui_json_contract.md`. The suite pins the encrypted payload surface, the key store, the replay guard, and the runtime orchestration symbols so source drift is caught early.

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
