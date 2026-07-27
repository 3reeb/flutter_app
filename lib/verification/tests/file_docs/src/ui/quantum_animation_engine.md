# `src/ui/quantum_animation_engine.dart`

**Doc reference:** `docs/src/ui/quantum_animation_engine.dart.md`

## File profile
- Lines: 1295
- Classes: QLSpringCurve, QLKeyframe, QLTimeline, QLAnimatedWidget, QLGlassConfig, QLGlassLayer, QLBehaviorAnimator, QLTransitionPreset
- Enums: QLPageTransition
- Notable functions: _evalLUT, transformInternal, _ensureCap, _alloc, _calcDuration, updateSpringTarget, setSpringPosition, parallel, sequence, stagger

## Existing docs snapshot
- `src/ui/quantum_animation_engine.dart`
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
- `3755e03b-b2cb-543d-8185-12b2e6a02d31` — Quantum Animation Engine: public contract remains stable under valid input (critical)
- `c1a1fd1e-1ddc-5ec4-8a55-1f44da8078b1` — Quantum Animation Engine: invalid or malformed input is rejected cleanly (critical)
- `0e682d83-7333-53e5-afb6-1d3bec289182` — Quantum Animation Engine: re-entrant calls do not corrupt internal state (high)
- `ba3f5026-a891-5d8a-b4cd-49c58a467741` — Quantum Animation Engine: dispose/close/teardown releases resources deterministically (high)
- `d2a3eda4-2a46-5e76-9667-96987215b85f` — Quantum Animation Engine: hot-path behavior stays within the runtime budget (high)
- `f9c8b578-35b7-5ffc-8bbf-d7c849eed1ba` — Quantum Animation Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.