# `src/app/quantum_app_shell.dart`

**Doc reference:** `docs/src/app/quantum_app_shell.dart.md`

## File profile
- Lines: 697
- Classes: QuantumApiClient, QuantumAuthClient, QuantumRuntimeServices, QuantumProductionRegistry, _SetStateAction, _MergeStateAction, _ToggleStateAction, _RemoveStateAction
- Enums: _AuthOp, _CacheOp
- Notable functions: init, executeRead, executeWrite, cacheGet, cacheSet, cacheRemove, login, register, logout, me

## Existing docs snapshot
- `src/app/quantum_app_shell.dart`
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
- `2715a35b-898f-54a3-9bce-115e011f5150` — Quantum App Shell: public contract remains stable under valid input (critical)
- `74f69a6b-c519-5b52-bc46-1fb006b595e2` — Quantum App Shell: invalid or malformed input is rejected cleanly (critical)
- `cdc4a76f-03ec-5b52-aa15-5a375682379d` — Quantum App Shell: re-entrant calls do not corrupt internal state (high)
- `fa50c10f-ab24-52ac-92cc-80a2aa33933f` — Quantum App Shell: dispose/close/teardown releases resources deterministically (high)
- `96132b20-1e4b-56fa-a163-2cef2bee771a` — Quantum App Shell: hot-path behavior stays within the runtime budget (high)
- `6865715e-0a0f-55c5-9de6-e26ce3da87f9` — Quantum App Shell: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.