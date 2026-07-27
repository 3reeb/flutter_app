# `src/runtime/quantum_vm_init.dart`

**Doc reference:** `docs/src/runtime/quantum_vm_init.dart.md`

## File profile
- Lines: 501
- Classes: _BuiltInActionPlugin, LambdaActionPlugin
- Enums: none detected
- Notable functions: execute, initQuantumBuiltIns, execute

## Existing docs snapshot
- `src/runtime/quantum_vm_init.dart`
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
- `ff58ae49-a912-5ddd-8b1a-f4ae3f1d95b0` — Quantum Vm Init: public contract remains stable under valid input (critical)
- `929b35f6-ca5a-5702-a51a-44c0d3436947` — Quantum Vm Init: invalid or malformed input is rejected cleanly (critical)
- `14369788-76d6-55c3-a6d8-ac09ab14aa3c` — Quantum Vm Init: re-entrant calls do not corrupt internal state (high)
- `ce240c59-bd47-5f4d-b311-c00f4114a142` — Quantum Vm Init: dispose/close/teardown releases resources deterministically (high)
- `cf16ebf0-40ee-5d0d-ba3d-4ec70dd96be0` — Quantum Vm Init: hot-path behavior stays within the runtime budget (high)
- `a2077f69-1e20-518f-b638-dc8bee8a06c5` — Quantum Vm Init: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.