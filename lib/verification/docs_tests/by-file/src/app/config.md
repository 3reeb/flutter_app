---
file: lib/src/app/config.dart
layer: app
kind: test specification
role: app-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 57f3b1f34687d829a7ae250807b21d94272b1dbb7ab96a48949114b6bfd2a58b
source_line_count: 1326
public_surface_count: 39
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

# Test Specification: `src/app/config.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

bootstrap wiring, config loading, transport selection, and route dispatch.

## Source surface discovered

### Public surface

- `QuantumBuildDefines`
- `QuantumBuildOverlay`
- `QuantumConfigSourceResult`
- `QuantumConfigSourceContext`
- `QuantumConfigSource`
- `QuantumInlineConfigSource`
- `QuantumAssetConfigSource`
- `QuantumFileConfigSource`
- `QuantumHttpConfigSource`
- `QuantumCustomConfigSource`
- `QuantumConfigMergePolicy`
- `QuantumConfigSecurityPolicy`
- `QuantumConfigCachePolicy`
- `QuantumConfigThemeSection`
- `QuantumConfigRouterSection`
- `QuantumConfigVmSection`
- `QuantumConfigTelemetrySection`
- `QuantumConfigAppSection`
- `QuantumConfigApiSection`
- `QuantumConfigRemoteSourceSpec`
- `QuantumConfigLocalSourceSpec`
- `QuantumConfigSources`
- `QuantumConfigRoot`
- `QuantumConfigResolutionReport`

### Imports

- `dart:async`
- `dart:convert`
- `dart:io`
- `package:crypto/crypto.dart`
- `package:flutter/material.dart`
- `package:flutter/foundation.dart`
- `../foundation/quantum_yaml_engine.dart`
- `../ui/quantum_navigation_engine.dart`
- `../plugins/quantum_api_engine.dart`
- `../plugins/quantum_api_shell.dart`
- `quantum_app_entry.dart`
- `quantum_app_shell.dart`
- `quantum_boot_schema.dart`
- `quantum_http_transport.dart`
- `quantum_file_router.dart`

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
- dependency `dart:convert` should be validated as a potential compatibility boundary.
- dependency `dart:io` should be validated as a potential compatibility boundary.
- package dependency `package:crypto/crypto.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../foundation/quantum_yaml_engine.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../ui/quantum_navigation_engine.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../plugins/quantum_api_engine.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../plugins/quantum_api_shell.dart` is part of the integration surface and should be tested alongside this file.
- dependency `quantum_app_entry.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_app_shell.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_boot_schema.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_http_transport.dart` should be validated as a potential compatibility boundary.
- dependency `quantum_file_router.dart` should be validated as a potential compatibility boundary.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/app/config.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
