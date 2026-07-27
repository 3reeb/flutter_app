# `src/runtime/quantum_data_pipeline.dart`

**Doc reference:** `docs/src/runtime/quantum_data_pipeline.dart.md`

## File profile
- Lines: 1132
- Classes: QLPrefetchConfig, QLAggregateOp, QLPipelineDelegate, QLDataPipeline, QLPipelineRegistry, QLDataPipelineReadPlan
- Enums: QLPipelineMode, QLExecutionMode
- Notable functions: snapshot, dispose, setFilters, setSearchQuery, setSort, setPage, clearFilters, replaceAll, recordAsMap, _buildIndices

## Existing docs snapshot
- `src/runtime/quantum_data_pipeline.dart`
- What this file is
- What it depends on
- Core pipeline model
- Why the schema changes matter here
- Important behaviors

## Runtime risk areas
- cache invalidation and stale snapshot leakage
- parallel mutation and event ordering
- observer/listener leaks
- bounded memory under repeated churn

## Selected scenarios
- `049332fd-3c69-5325-9994-c6735160340d` — Quantum Data Pipeline: public contract remains stable under valid input (critical)
- `756ad43d-6f9f-5885-923f-7e64d8667b1f` — Quantum Data Pipeline: invalid or malformed input is rejected cleanly (critical)
- `b2dac894-669e-52c2-bc2a-7918064ed76f` — Quantum Data Pipeline: re-entrant calls do not corrupt internal state (high)
- `c79d20a0-50f4-568c-8559-c37da775e593` — Quantum Data Pipeline: dispose/close/teardown releases resources deterministically (high)
- `5c43236e-15e0-5acd-9fab-715251ac4f43` — Quantum Data Pipeline: hot-path behavior stays within the runtime budget (high)
- `1a544047-581b-5759-a728-fc80a32f2423` — Quantum Data Pipeline: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.