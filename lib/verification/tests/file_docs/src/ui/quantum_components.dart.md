# `src/ui/quantum_components.dart`

**Doc reference:** `docs/src/ui/quantum_components.dart.md`

## File profile
- Lines: 1517
- Classes: QLSensor, _QLSensorState, QLSpace, _QLRow, _QLColumn, _QLAdaptive, QLViewport, _QLViewportState
- Enums: none detected
- Notable functions: apply, initState, dispose, _onHoverMove, build, build, _buildLayout, initState, _scrollListener, dispose

## Existing docs snapshot
- `src/ui/quantum_components.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- layout collapse under tight constraints
- gesture/hit-test drift after rebuilds
- overdraw and repaint churn
- semantics regression and focus loss

## Selected scenarios
- `0adee761-5b0a-58eb-99d2-18dfe30ccff7` — Quantum Components: public contract remains stable under valid input (critical)
- `a6e3abbf-466c-599f-ba4b-c7a5638bee37` — Quantum Components: invalid or malformed input is rejected cleanly (critical)
- `13db782e-4448-5cf3-ba1d-dac0ed73b0ed` — Quantum Components: re-entrant calls do not corrupt internal state (high)
- `c44a81f8-38e7-5334-9e25-3f5ab92c5466` — Quantum Components: dispose/close/teardown releases resources deterministically (high)
- `606dfe35-ad8f-5d4d-8e6f-7050dab4e3ff` — Quantum Components: hot-path behavior stays within the runtime budget (high)
- `59ffb492-162d-50c5-a38f-a183c62dac16` — Quantum Components: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.