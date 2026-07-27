# `src/runtime/quantum_export_web_bridge.dart`

**Doc reference:** `docs/src/runtime/quantum_export_web_bridge.dart.md`

## File profile
- Lines: 286
- Classes: _ExportPayload, QuantumExportBridgePage, _QuantumExportBridgePageState
- Enums: _Status
- Notable functions: initState, _run, _fail, _setMsg, build

## Existing docs snapshot
- `src/runtime/quantum_export_web_bridge.dart`
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
- `cefc397a-cdb4-5200-80d2-94c61d6ce66e` — Quantum Export Web Bridge: public contract remains stable under valid input (critical)
- `3d0036aa-8c92-5ff5-a35c-0f2321a88fad` — Quantum Export Web Bridge: invalid or malformed input is rejected cleanly (critical)
- `e1a5aa47-0e37-5c55-8c60-b99836413db4` — Quantum Export Web Bridge: re-entrant calls do not corrupt internal state (high)
- `f63eb9f9-d34a-5f93-a55f-ba0799fdfa99` — Quantum Export Web Bridge: dispose/close/teardown releases resources deterministically (high)
- `708a2238-ce59-501e-840b-d1b5cc357cf5` — Quantum Export Web Bridge: hot-path behavior stays within the runtime budget (high)
- `bf7447ab-d276-565d-804c-35e74589080c` — Quantum Export Web Bridge: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.