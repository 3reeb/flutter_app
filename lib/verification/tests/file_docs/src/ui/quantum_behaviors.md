# `src/ui/quantum_behaviors.dart`

**Doc reference:** `docs/src/ui/quantum_behaviors.dart.md`

## File profile
- Lines: 758
- Classes: QLDragConfig, QLMultiSplit, _QLMultiSplitState, _QLMultiSplitDelegate, QLMorphSurface, _QLMorphSurfaceState, QLSpatialCanvas, _QLSpatialCanvasState
- Enums: none detected
- Notable functions: initState, _onDragUpdate, dispose, build, performLayout, shouldRelayout, initState, _applyDelta, _handle, dispose

## Existing docs snapshot
- `src/ui/quantum_behaviors.dart`
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
- `deddba1c-b6d4-5a90-9223-9bea49c5d33b` — Quantum Behaviors: public contract remains stable under valid input (critical)
- `393363b0-6d7e-5807-8340-435ce0879300` — Quantum Behaviors: invalid or malformed input is rejected cleanly (critical)
- `f6f080d1-358a-56ee-88cb-9cb0fb74f0a9` — Quantum Behaviors: re-entrant calls do not corrupt internal state (high)
- `d07fe3c2-5c99-5a30-a07a-a8acd8fa4448` — Quantum Behaviors: dispose/close/teardown releases resources deterministically (high)
- `b535d251-1fb9-5396-8211-a56cb89679b1` — Quantum Behaviors: hot-path behavior stays within the runtime budget (high)
- `8987f3c6-fe07-53fe-b484-642bc43040d6` — Quantum Behaviors: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.