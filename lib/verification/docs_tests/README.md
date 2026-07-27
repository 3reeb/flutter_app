# docs_tests

This folder is the test-documentation mirror for the codebase.

It is designed so a future test generator can create strong test code from the Markdown and YAML alone.

## Folder layout

- `by-file/` — one Markdown test specification per Dart source file, mirrored by path.
- `cross-cutting/` — shared rules that apply across schema, state, pipeline, orchestrator, VM, UI, plugin, and SDUI JSON contract layers.
- `yaml/` — machine-readable YAML test specs, supplement specs, and reusable templates.

## How to use it

1. read the file-specific spec under `by-file/`
2. read the cross-cutting docs for shared behavior
3. expand the YAML manifests into concrete cases using the shared templates and group catalog
4. use the SDUI JSON contract docs when authoring executable JSON suites
4. regenerate the matching YAML whenever a file signature or runtime contract changes

## Test philosophy

This is not a happy-path checklist.

A strong suite must cover:

- invalid input
- repeated mutation
- cache reuse
- eviction and refresh
- lazy-load boundaries
- cross-file integration
- platform-specific divergence
- memory pressure and large collections
- compatibility with older serialized shapes
- hidden eager loads and silent data loss
- controller normalization, validation, and bitmask behavior
- source/manifest fingerprint drift
- reserved-keyword-safe model names

## Regeneration rule

If a source file changes, its matching Markdown spec and YAML manifest should be treated as stale until they are reviewed and regenerated.
