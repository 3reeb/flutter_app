# `src/app/quantum_app_entry.dart`

**Doc reference:** `docs/src/app/quantum_app_entry.dart.md`

## File profile
- Lines: 951
- Classes: QLYamlAppEnv, QuantumAppManifest, _QuantumBootLoader, _QuantumBootLoaderState, _QuantumYamlAppRoot, _QuantumYamlAppRootState, _QLFileRouteViewStatic, _QLFileRouteViewStaticState
- Enums: none detected
- Notable functions: Function, Function, Function, Function, Function, Function, Function, Function, bootQuantumManifestApp, bootQuantumYamlApp

## Existing docs snapshot
- `src/app/quantum_app_entry.dart`
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
- `a1596ef6-b891-5e74-ae88-b52ac974ea93` — Quantum App Entry: public contract remains stable under valid input (critical)
- `72ef578f-3467-537d-a400-b86a13ad0f07` — Quantum App Entry: invalid or malformed input is rejected cleanly (critical)
- `57268cf5-e2b7-54a1-9080-d545e86b3e1a` — Quantum App Entry: re-entrant calls do not corrupt internal state (high)
- `6022b28f-a840-593f-9dae-81d1d1e7435c` — Quantum App Entry: dispose/close/teardown releases resources deterministically (high)
- `c272bc6e-24f6-53ce-b7c9-ce8bd469f311` — Quantum App Entry: hot-path behavior stays within the runtime budget (high)
- `1ce39288-194c-590a-81e0-f1ec8084e504` — Quantum App Entry: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.