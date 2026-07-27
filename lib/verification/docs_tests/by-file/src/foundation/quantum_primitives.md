---
file: lib/src/foundation/quantum_primitives.dart
layer: foundation
kind: test specification
role: primitives
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: 859a49d34739f34723c3ba0e706710cbe0526cefb68880312536d80607a0fe03
source_line_count: 1034
public_surface_count: 24
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

# Test Specification: `src/foundation/quantum_primitives.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

low-level primitive helpers and compatibility behavior.

## Source surface discovered

### Public surface

- `QLSafe`
- `QLArena`
- `QLReactiveContext`
- `QLSignalBase`
- `QLSignal`
- `QLComputed`
- `QLPhysicsTicker`
- `QLIntegratorRK4`
- `QLComponentArray`
- `QLSoAEngine`
- `QLNodeConfig`
- `RenderQLNode`
- `QLPointerEvent`
- `QLOmniSensor`
- `_QLOmniSensorState`
- `QLNode`
- `QLTextPainterCache`
- `QLEntityBinding`
- `QLTableLayoutController`
- `_QLEqualityCheck`
- `QLMutable`
- `QLDerivativeFunc`
- `QLReactiveRenderMixin`
- `QLEcsBindingExt`

### Imports

- `dart:typed_data`
- `dart:collection`
- `dart:async`
- `dart:collection`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `package:flutter/rendering.dart`
- `package:flutter/scheduler.dart`
- `package:flutter/gestures.dart`
- `../../quantum.dart`

## Testing priorities

- **smoke** — primitive helper sanity
- **edges** — invalid values and boundary conditions
- **compatibility** — legacy helper behavior
- **performance** — tight-loop invocation
- **regression** — unexpected coercion or silent drift

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

- dependency `dart:typed_data` should be validated as a potential compatibility boundary.
- dependency `dart:collection` should be validated as a potential compatibility boundary.
- dependency `dart:async` should be validated as a potential compatibility boundary.
- dependency `dart:collection` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/rendering.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/scheduler.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/gestures.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/foundation/quantum_primitives.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
