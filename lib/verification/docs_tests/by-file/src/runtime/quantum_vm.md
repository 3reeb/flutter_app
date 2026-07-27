---
file: lib/src/runtime/quantum_vm.dart
layer: runtime
kind: test specification
role: vm-core
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 232c6d99fdebb6e2692cb347c2ac99c43250ccd44a99613968c407a4aa0a0028
source_line_count: 7157
public_surface_count: 62
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

# Test Specification: `src/runtime/quantum_vm.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

module registry behavior, macro expansion, policy gating, token parsing, cache invalidation, and lazy schema views.

## Source surface discovered

### Public surface

- `QuantumSecurityException`
- `QLSchemaSlice`
- `QLLazySchemaView`
- `QLModuleAccessPolicy`
- `QLModuleRecord`
- `QLModuleRegistry`
- `QLRegistryEntry`
- `QuantumExtensionBundle`
- `QLStableHasher`
- `QLPipes`
- `QLSignalBatch`
- `QLPluginStreamRegistry`
- `QLBlueprint`
- `QLCompiler`
- `ParsedToken`
- `_QLMacroSlots`
- `_QLMacroSlotList`
- `_QLMacroSlotEmpty`
- `QLAstInspector`
- `QLPathResolver`
- `QLDataBinder`
- `QLPlugin`
- `QLWidgetCapability`
- `QLSliverCapability`

### Imports

- `dart:async`
- `dart:convert`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `package:flutter/services.dart`
- `package:collection/collection.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — module setup and capability lookup sanity
- **edges** — invalid modules, empty tokens, and bad policy paths
- **registry** — registration, lookup, and removal behavior
- **macro-expansion** — macro slots, token injection, and expansion safety
- **security** — module access policy and denial handling
- **lazy-schema** — deferred schema view and cache invalidation
- **performance** — token parsing and repeated lookup overhead
- **regression** — silent permission bypass, stale caches, and token drift

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
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/services.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:collection/collection.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/runtime/quantum_vm.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
