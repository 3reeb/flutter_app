---
file: lib/src/app/quantum_app_shell.dart
layer: app
kind: test specification
role: app-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 89f59194860a8b03c5afe531418205fe3b806a3abfddc59ded4b5ef9a8c938be
source_line_count: 697
public_surface_count: 27
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

# Test Specification: `src/app/quantum_app_shell.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

bootstrap wiring, config loading, transport selection, and route dispatch.

## Source surface discovered

### Public surface

- `QuantumApiClient`
- `QuantumAuthClient`
- `QuantumRuntimeServices`
- `QuantumProductionRegistry`
- `_SetStateAction`
- `_MergeStateAction`
- `_ToggleStateAction`
- `_RemoveStateAction`
- `_ApiReadAction`
- `_ApiWriteAction`
- `_AuthAction`
- `_CacheAction`
- `QuantumAppEnvironment`
- `QuantumDomain`
- `QuantumTelemetryConfig`
- `QuantumRouterConfig`
- `QuantumVMConfig`
- `QuantumAppConfig`
- `_QuantumAppShell`
- `_QuantumAppShellState`
- `_AuthOp`
- `_CacheOp`
- `QuantumActionFactory`
- `QuantumDomainOrchestrator`

### Imports

- `dart:async`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — app bootstrap and routing sanity
- **edges** — bad config, missing transport, and empty route tables
- **bootstrap** — load order and initialization safety
- **routing** — file and HTTP route dispatch
- **integration** — foundation/runtime handoff
- **performance** — startup cost and repeated boot
- **regression** — silent transport fallback or stale config

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
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/app/quantum_app_shell.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
