# `src/features/charts/quantum_charts.dart`

**Doc reference:** `docs/src/features/charts/quantum_charts.dart.md`

## File profile
- Lines: 810
- Classes: QLChartDataBuffer, QLUniversalChart, _QLUniversalChartState, _QLGridPainter, _QLCrosshairPainter, _QLDataPainter
- Enums: QLChartType
- Notable functions: safeDouble, initState, didUpdateWidget, dispose, _handleHover, _handleExit, build, paint, shouldRepaint, paint

## Existing docs snapshot
- `src/features/charts/quantum_charts.dart`
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
- `723ff0ca-0a33-59bd-a4f3-2d290fd86042` — Quantum Charts: public contract remains stable under valid input (critical)
- `095281e9-0e7f-5942-8297-8d91dbc47675` — Quantum Charts: invalid or malformed input is rejected cleanly (critical)
- `3774bf6b-09a6-56d6-ada9-fa98a5c09ab0` — Quantum Charts: re-entrant calls do not corrupt internal state (high)
- `8fa0e1cf-7a0a-5445-ae5e-fd0d6c2ee7fd` — Quantum Charts: dispose/close/teardown releases resources deterministically (high)
- `9d726a0a-9d09-5af7-9717-cf6312f60ba7` — Quantum Charts: hot-path behavior stays within the runtime budget (high)
- `12193580-4851-5353-b2fa-51f98a2e760e` — Quantum Charts: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.