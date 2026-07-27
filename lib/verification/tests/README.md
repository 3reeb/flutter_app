# Comprehensive tests package

This package adds a new `tests/` tree without changing the existing source or docs layout.

Scope:
- Source files reviewed: 116
- Documentation files reviewed: 120
- Runtime test scenarios generated: 1144
- File-specific spec shards: 116

What is inside:
- `manifest.yaml` — source-to-test inventory and coverage summary.
- `docs_audit.yaml` — file-by-file audit of the existing `docs/` tree.
- `comprehensive_runtime_tests.yaml` — the full scenario catalog.
- `file_docs/` — per-source-file markdown docs with risk notes and selected scenarios.
- `specs/` — per-source-file YAML shards for direct consumption.

The catalog is intentionally heavy on failure paths, teardown, performance, memory pressure, and interaction edge cases.
