# `src/foundation/quantum_primitives.dart`

**Doc reference:** `docs/src/foundation/quantum_primitives.dart.md`

## File profile
- Lines: 1034
- Classes: QLReactiveContext, QLSignalBase, QLSignal, QLComputed, QLIntegratorRK4, QLComponentArray, QLSoAEngine, QLNodeConfig
- Enums: none detected
- Notable functions: track, update, setSilent, forceNotify, Function, Function, dispose, track, _markDirty, _recompute

## Existing docs snapshot
- `src/foundation/quantum_primitives.dart`
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
- `624fa82d-9652-5ef0-8bf7-43a27c549a90` — Quantum Primitives: public contract remains stable under valid input (critical)
- `a0cd1313-a61d-513a-8084-152d1b0bb458` — Quantum Primitives: invalid or malformed input is rejected cleanly (critical)
- `3bc0d9b9-55aa-54ba-b2ac-09b3abb12e01` — Quantum Primitives: re-entrant calls do not corrupt internal state (high)
- `dbfd8d6a-cae0-523d-bea2-76bbc9ea4cb1` — Quantum Primitives: dispose/close/teardown releases resources deterministically (high)
- `caf3c322-d688-5ea2-b45b-cdae42fb009d` — Quantum Primitives: hot-path behavior stays within the runtime budget (high)
- `7c924cfc-5d8d-50fd-a5c8-b5408d42604a` — Quantum Primitives: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.