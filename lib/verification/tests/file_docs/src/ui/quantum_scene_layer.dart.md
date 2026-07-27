# `src/ui/quantum_scene_layer.dart`

**Doc reference:** `docs/src/ui/quantum_scene_layer.dart.md`

## File profile
- Lines: 591
- Classes: _DirtyBitfield, _QLFragment, QLSceneLayer, QLScenePainter, QLSceneLayerWidget, _QLSceneLayerWidgetState, QLSoASceneBridge, QLSceneStack
- Enums: none detected
- Notable functions: mark, isSet, clear, clearAll, _ensureCapacity, update, invalidate, invalidateAll, remove, clear

## Existing docs snapshot
- `src/ui/quantum_scene_layer.dart`
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
- `222f5e57-45e7-5314-b62a-0eb5e4baa3ac` — Quantum Scene Layer: public contract remains stable under valid input (critical)
- `f92b078d-9f9c-5dd3-b616-e4900efa1ae2` — Quantum Scene Layer: invalid or malformed input is rejected cleanly (critical)
- `6494ff79-c70b-58ff-8051-91e5ac067b28` — Quantum Scene Layer: re-entrant calls do not corrupt internal state (high)
- `7b19652d-b876-59a7-be01-e9979818dd47` — Quantum Scene Layer: dispose/close/teardown releases resources deterministically (high)
- `e161e207-1f53-54dd-9bcd-7a7bf6f728e2` — Quantum Scene Layer: hot-path behavior stays within the runtime budget (high)
- `f65bb7c7-dc2c-52c6-9d46-127f147602a9` — Quantum Scene Layer: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.