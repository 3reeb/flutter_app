---
file: lib/src/foundation/quantum_json_dsl.dart
layer: foundation
kind: test specification
role: json-dsl
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: ac109b53f696f462ebf0e7a6d3302e171e0c3f693e24107397b37d8f661449a2
source_line_count: 1125
public_surface_count: 10
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

# Test Specification: `src/foundation/quantum_json_dsl.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

JSON DSL parsing, transformation, compatibility, and round-trip stability.

## Source surface discovered

### Public surface

- `QJsonTemplateEngine_D`
- `_TemplateRecord`
- `_TemplateDrivenPlugin`
- `_QLayoutJsonRegistry`
- `QJsonDSL`
- `QuantumVMJsonDslExtension`
- `QuantumVMTemplateJsonExtension`
- `_extractName`
- `_extractDefaultProps`
- `_parseResizeHandle`

### Imports

- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `../../quantum.dart`
- `quantum_matrix_engine.dart`

## Testing priorities

- **smoke** — basic parse and emit behavior
- **edges** — invalid JSON DSL fragments and malformed nodes
- **serialization** — round-trip stability and shape preservation
- **compatibility** — legacy fields and default handling
- **integration** — schema and runtime consumers
- **performance** — large document handling
- **regression** — silent coercion and key loss

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
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- dependency `quantum_matrix_engine.dart` should be validated as a potential compatibility boundary.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/foundation/quantum_json_dsl.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
