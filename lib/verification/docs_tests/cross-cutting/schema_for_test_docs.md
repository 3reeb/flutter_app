# Schema for test docs

Every file-level test doc is expected to mirror the source tree and carry enough metadata for a generator to produce production-grade tests.

## Markdown front matter

Required fields:

- `file`
- `layer`
- `kind`
- `role`
- `test_status`
- `last_reviewed`
- `source_sha256`
- `source_line_count`
- `public_surface_count`
- `regeneration_triggers`
- `coverage_targets`

## YAML manifest shape

Required top-level keys:

- `schema_version`
- `doc_kind`
- `file`
- `layer`
- `profile`
- `test_doc_status`
- `last_reviewed`
- `source_metadata`
- `surface_summary`
- `focus`
- `coverage_targets`
- `test_dimensions`
- `reusable_presets`
- `groups`
- `regeneration_triggers`
- `supplements`

## Supplemental YAML files

Large files may split their test matrix into multiple YAML files. Use a root manifest plus supplements when the file has distinct branches such as:

- core contract coverage
- integration coverage
- performance/memory coverage
- compatibility or fallback coverage

## Reusable rows

Each row should carry these details so a future generator can scale the spec into many concrete tests:

- `id`
- `purpose`
- `target_symbols`
- `setup`
- `input`
- `body`
- `expected`
- `assertions`
- `metrics`
- `risks`
- `cleanup`

## Expansion guidance

- keep rows specific enough to avoid fake coverage
- keep them broad enough to generate multiple concrete cases
- attach performance and regression notes to every high-value branch
- treat silent success as a failure unless the contract explicitly allows it
