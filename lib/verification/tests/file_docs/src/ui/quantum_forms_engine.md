# `src/ui/quantum_forms_engine.dart`

**Doc reference:** `docs/src/ui/quantum_forms_engine.dart.md`

## File profile
- Lines: 2535
- Classes: QLChangeEvent, _QLObserver, QLDataNode, QLGraphController, QLFormController, QLFieldController, QLTextController, QLTextAreaController
- Enums: none detected
- Notable functions: doc, sibling, setSibling, mutate, mutateFast, setValue, setSilently, bindStream, unbindStream, sleep

## Existing docs snapshot
- `src/ui/quantum_forms_engine.dart`
- What this file is
- What changed in this update
- Core controller responsibilities
- Scalar controllers
- Array controllers

## Runtime risk areas
- layout collapse under tight constraints
- gesture/hit-test drift after rebuilds
- overdraw and repaint churn
- semantics regression and focus loss

## Selected scenarios
- `6098428d-45d1-5313-95c7-bfe1c2a2956f` — Quantum Forms Engine: public contract remains stable under valid input (critical)
- `9c41cba9-cb7d-5950-a58c-ab06f4ab83ae` — Quantum Forms Engine: invalid or malformed input is rejected cleanly (critical)
- `2aec7d2e-dd70-532d-b949-ee9cf879d58d` — Quantum Forms Engine: re-entrant calls do not corrupt internal state (high)
- `ccaf3a91-3fe4-5ce9-a2da-daf643d94188` — Quantum Forms Engine: dispose/close/teardown releases resources deterministically (high)
- `9f4ab547-636a-5203-8399-3bbecd5a521e` — Quantum Forms Engine: hot-path behavior stays within the runtime budget (high)
- `fc4eb1a7-9a2b-5399-b1b7-8537aec355b4` — Quantum Forms Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.