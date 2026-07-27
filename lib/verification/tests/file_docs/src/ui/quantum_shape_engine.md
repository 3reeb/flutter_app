# `src/ui/quantum_shape_engine.dart`

**Doc reference:** `docs/src/ui/quantum_shape_engine.dart.md`

## File profile
- Lines: 604
- Classes: QShapeValue, QShapePoint, QShapePrimitive, QBooleanShapeOp, QBooleanShapeDef, QLShapeNode, RenderQLShape
- Enums: QShapeType, QBooleanOp
- Notable functions: resolve, addLegacy, updateRenderObject, attach, detach, _onRepaintTick, _resolve, _buildPrimitive, _compilePath, performLayout

## Existing docs snapshot
- `src/ui/quantum_shape_engine.dart`
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
- `857a5563-8f2f-5d81-a85a-a92fc4d84b06` — Quantum Shape Engine: public contract remains stable under valid input (critical)
- `1c554854-7e3c-5ca4-a557-84f70e9ab8da` — Quantum Shape Engine: invalid or malformed input is rejected cleanly (critical)
- `bdcb181d-c3e4-5fce-bac7-a91dc6e329af` — Quantum Shape Engine: re-entrant calls do not corrupt internal state (high)
- `36eb2b7a-faeb-579f-ac89-eb7549ad408c` — Quantum Shape Engine: dispose/close/teardown releases resources deterministically (high)
- `59b53057-4ec8-568c-96e1-1e93a5755d6f` — Quantum Shape Engine: hot-path behavior stays within the runtime budget (high)
- `d92274e3-8e37-5b8d-85d2-92860e5660fb` — Quantum Shape Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.