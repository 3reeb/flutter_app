# `src/runtime/omni_cores/data_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/data_core.dart.md`

## File profile
- Lines: 311
- Classes: none detected
- Enums: none detected
- Notable functions: _buildData, _getMapData, _registerDataAliases

## Existing docs snapshot
- `src/runtime/omni_cores/data_core.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- cache invalidation and stale snapshot leakage
- parallel mutation and event ordering
- observer/listener leaks
- bounded memory under repeated churn

## Selected scenarios
- `df3302cc-d162-558d-8439-4d9e825c1d70` — Data Core: public contract remains stable under valid input (critical)
- `10b2e60a-d064-5ece-80fc-1dc3e00f14ca` — Data Core: invalid or malformed input is rejected cleanly (critical)
- `6f099bbb-63ea-577d-8864-9204b545886d` — Data Core: re-entrant calls do not corrupt internal state (high)
- `1abc632c-d152-5eee-b7ff-86ded461ff31` — Data Core: dispose/close/teardown releases resources deterministically (high)
- `43c733be-3ea7-5dea-bae1-63c6bbf54e0b` — Data Core: hot-path behavior stays within the runtime budget (high)
- `4e875b49-7e32-53a8-8ff6-dab033782d7b` — Data Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.