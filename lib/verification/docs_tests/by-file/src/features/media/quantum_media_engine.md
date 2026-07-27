---
file: lib/src/features/media/quantum_media_engine.dart
layer: features
kind: test specification
role: feature-media
test_status: draft
last_reviewed: "2026-07-26"
source_sha256: b19d6c7b143f8fe7c0c04e9d8b25e8e76461a79b5418972f946f098372b38851
source_line_count: 689
public_surface_count: 14
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

# Test Specification: `src/features/media/quantum_media_engine.dart`

This file is documented so a future generator can build strong tests from the spec instead of guessing at intent.

## Why this file matters

media transport, lazy resource handling, and metadata preservation.

## Source surface discovered

### Public surface

- `QLMediaPolicy`
- `QLMediaSource`
- `QLSubtitleTrack`
- `QLSubtitleParser`
- `QLMediaPlaybackController`
- `QuantumMediaOrchestrator`
- `QLVideoLifecycleWrapper`
- `_QLVideoLifecycleWrapperState`
- `QLVideoSurface`
- `QLSubtitleOverlay`
- `_QLFeedDisposer`
- `_QLFeedDisposerState`
- `QLStreamFormat`
- `registerQuantumMediaComponents`

### Imports

- `dart:async`
- `dart:typed_data`
- `dart:convert`
- `package:flutter/foundation.dart`
- `package:flutter/material.dart`
- `package:flutter/services.dart`
- `package:video_player/video_player.dart`
- `../../foundation/quantum_primitives.dart`
- `../../foundation/quantum_async.dart`
- `../../../quantum.dart`
- `../../plugins/quantum_media_api.dart`

## Testing priorities

- **smoke** — media engine bootstrap and source registration
- **edges** — missing sources, invalid mime types, and empty media payloads
- **metadata** — preserve mimeType, size, url, and source metadata
- **lazy-load** — defer heavy resources until first access
- **integration** — schema, state, and UI consumers
- **performance** — cache reuse and large payload handling
- **regression** — silent media metadata loss or eager fetch

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
- dependency `dart:convert` should be validated as a potential compatibility boundary.
- package dependency `package:flutter/foundation.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/material.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:flutter/services.dart` should be pinned or stubbed when behavior could change by platform.
- package dependency `package:video_player/video_player.dart` should be pinned or stubbed when behavior could change by platform.
- local dependency `../../foundation/quantum_primitives.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../foundation/quantum_async.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../../quantum.dart` is part of the integration surface and should be tested alongside this file.
- local dependency `../../plugins/quantum_media_api.dart` is part of the integration surface and should be tested alongside this file.

## YAML companion

- Base manifest: `docs_tests/yaml/by-file/src/features/media/quantum_media_engine.dart.yaml`
- Shared templates: `docs_tests/yaml/shared/case_template.yaml`
- Shared groups: `docs_tests/yaml/shared/group_catalog.yaml`
- Shared axes: `docs_tests/yaml/shared/axis_catalog.yaml`

## Regeneration rule

If this source file changes, this document and its YAML companion should be treated as stale until they are regenerated.

## Supplemental YAML files

This file is large enough to deserve extra YAML partitions. The main manifest points to those parts so a generator can expand them independently.
