# `src/ui/quantum_overlays.dart`

**Doc reference:** `docs/src/ui/quantum_overlays.dart.md`

## File profile
- Lines: 2472
- Classes: QLOverlayRuntimeSpec, QLMotionSpec, QLSpatialConfig, _QLSpatialNodeState, _QLSpatialRegistry, QuantumOverlay, _QLNodeWrapper, QLOverlayRoot
- Enums: QLTransitionMode, QLBackgroundEffect, QLSheetEdge, QLResizeEdge, QLInteractionMode, QLOverlayInsertMode
- Notable functions: readBool, readEdgeList, insert, updateBounds, remove, hitTest, ancestrySafeSet, getDismissibleIds, isEmpty, resetForTesting

## Existing docs snapshot
- `src/ui/quantum_overlays.dart`
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
- `afdbd2a4-e77f-5841-90a0-99a0e06ef0d4` — Quantum Overlays: public contract remains stable under valid input (critical)
- `ffc5a8c1-c811-5864-acc0-957d0ec4eec6` — Quantum Overlays: invalid or malformed input is rejected cleanly (critical)
- `5f50055b-4082-5762-87e7-2b1d09219c18` — Quantum Overlays: re-entrant calls do not corrupt internal state (high)
- `dcea3009-d716-525c-bd08-33d69be021df` — Quantum Overlays: dispose/close/teardown releases resources deterministically (high)
- `b291e1e1-cb8e-5e22-86e1-d9c5de13e021` — Quantum Overlays: hot-path behavior stays within the runtime budget (high)
- `04c89317-656e-565d-9eb3-bdf5613a1f87` — Quantum Overlays: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.