# `src/app/quantum_file_router.dart`

**Doc reference:** `docs/src/app/quantum_file_router.dart.md`

## File profile
- Lines: 875
- Classes: QLFileRouteEntry, QuantumFileRouter, _DirTree, _LazyPagePolicyMiddleware, _YamlMiddleware, _QLFileRouteView, _QLFileRouteViewState
- Enums: none detected
- Notable functions: addRoute, removeRoute, invalidateCache, _isSupportedFormat, _isSpecialFile, _buildDirTree, _compareEntries, _buildRoute, _loadPageConfigCached, _interpolateSeo

## Existing docs snapshot
- `src/app/quantum_file_router.dart`
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
- `cbd58733-acbe-519d-bdbc-65216481430c` — Quantum File Router: public contract remains stable under valid input (critical)
- `12edfdbc-d9e9-5975-99cf-3fddff4db8be` — Quantum File Router: invalid or malformed input is rejected cleanly (critical)
- `92d16554-0221-5dad-b237-2a4c1d2a0908` — Quantum File Router: re-entrant calls do not corrupt internal state (high)
- `1bf6f64a-0a0a-58b1-87b4-b744a88816e0` — Quantum File Router: dispose/close/teardown releases resources deterministically (high)
- `664a9e62-d68d-5e38-b51b-12df2d94e5b5` — Quantum File Router: hot-path behavior stays within the runtime budget (high)
- `f15dcf01-a4c0-541b-a85e-90b9510cd056` — Quantum File Router: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.