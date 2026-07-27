# `src/foundation/quantum_matrix_engine.dart`

**Doc reference:** `docs/src/foundation/quantum_matrix_engine.dart.md`

## File profile
- Lines: 2461
- Classes: QMatrixInteractionController, QMatrixSlotRuntimeOverride, QMatrixSlotDef, _CompiledSlot, _CompiledMatrixData, QMatrixLayoutDef, QMatrixBuilder, QuantumMatrixParentData
- Enums: QMatrixSemanticsOrder, QMatrixTextDirectionMode, QMatrixInteractionMode, QMatrixResizeHandle
- Notable functions: setVisualOrder, bringToFront, sendToBack, setGridPlacement, setPixelOffset, setPixelSize, setZIndex, setHidden, clearSlot, clearAll

## Existing docs snapshot
- `src/foundation/quantum_matrix_engine.dart`
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
- `0035ccc0-7afc-5547-9ba1-ddd7726a0bcc` — Quantum Matrix Engine: public contract remains stable under valid input (critical)
- `2c769873-df55-5a83-b269-aded20617530` — Quantum Matrix Engine: invalid or malformed input is rejected cleanly (critical)
- `ac2fd0c4-bf8f-5c44-8695-4126593f28ad` — Quantum Matrix Engine: re-entrant calls do not corrupt internal state (high)
- `919c8b38-12d4-5cff-9737-edcbe056408b` — Quantum Matrix Engine: dispose/close/teardown releases resources deterministically (high)
- `8190f274-9084-5c99-b6bc-4c356ae8df46` — Quantum Matrix Engine: hot-path behavior stays within the runtime budget (high)
- `4730459a-d045-55c5-949c-186bebc9a3c6` — Quantum Matrix Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.