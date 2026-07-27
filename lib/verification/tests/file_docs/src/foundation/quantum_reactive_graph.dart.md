# `src/foundation/quantum_reactive_graph.dart`

**Doc reference:** `docs/src/foundation/quantum_reactive_graph.dart.md`

## File profile
- Lines: 651
- Classes: QLSelector, QLDerivedSignal, QLReactiveBinding, QLAnimGraph, QLReactiveTween, _QLReactiveTweenState, QLAnimCompositor
- Enums: none detected
- Notable functions: _onSourceChange, dispose, track, _markDirty, _flush, _recompute, dispose, attach, detach, _onSourceChange

## Existing docs snapshot
- `src/foundation/quantum_reactive_graph.dart`
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
- `8ca6b844-e596-5886-b219-a2e73060219a` — Quantum Reactive Graph: public contract remains stable under valid input (critical)
- `80f458d3-8223-5dc4-8b90-2d860d109497` — Quantum Reactive Graph: invalid or malformed input is rejected cleanly (critical)
- `fa1a2db8-f1de-5016-8db1-bc3effe6e37b` — Quantum Reactive Graph: re-entrant calls do not corrupt internal state (high)
- `4f635391-4ac7-5409-a000-e3f2ba55529a` — Quantum Reactive Graph: dispose/close/teardown releases resources deterministically (high)
- `b7b33e43-ab99-5695-b950-e6739ef51c21` — Quantum Reactive Graph: hot-path behavior stays within the runtime budget (high)
- `2bf26b2f-7642-5679-a111-923555376df9` — Quantum Reactive Graph: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.