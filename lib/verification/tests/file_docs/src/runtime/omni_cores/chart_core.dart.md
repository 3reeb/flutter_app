# `src/runtime/omni_cores/chart_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/chart_core.dart.md`

## File profile
- Lines: 48
- Classes: none detected
- Enums: none detected
- Notable functions: _buildChart, _registerChartAliases

## Existing docs snapshot
- `src/runtime/omni_cores/chart_core.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- dense rendering jank
- hover/selection desynchronization
- numeric edge cases destabilizing paint
- buffer retention during export or snapshot

## Selected scenarios
- `5b3d377a-eaed-56a4-9817-608cae82861b` — Chart Core: public contract remains stable under valid input (critical)
- `b6fae65f-8183-5e8d-805d-cf75b5e20ec5` — Chart Core: invalid or malformed input is rejected cleanly (critical)
- `55d8730b-0dc3-5d00-bc05-b407661cf9ef` — Chart Core: re-entrant calls do not corrupt internal state (high)
- `e73e7e9c-640c-51be-8a21-f3e4ba38227d` — Chart Core: dispose/close/teardown releases resources deterministically (high)
- `b3d6032b-6473-59d9-8d96-1bab200f127d` — Chart Core: hot-path behavior stays within the runtime budget (high)
- `b97e7351-dd06-528b-bcef-3b7e9ee48934` — Chart Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.