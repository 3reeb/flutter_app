# `src/runtime/quantum_vm.dart`

**Doc reference:** `docs/src/runtime/quantum_vm.dart.md`

## File profile
- Lines: 7157
- Classes: QuantumSecurityException, QLSchemaSlice, QLLazySchemaView, QLModuleAccessPolicy, QLModuleRecord, QLModuleRegistry, QLRegistryEntry, QuantumExtensionBundle
- Enums: QLModuleVisibility
- Notable functions: toString, pick, allows, exists, canUse, importsFor, section, macrosFor, clear, snapshot

## Existing docs snapshot
- `src/runtime/quantum_vm.dart`
- What this file is
- What the VM does for schemas
- Why this matters for the new field system
- Core runtime features
- Caching behavior

## Runtime risk areas
- layout collapse under tight constraints
- gesture/hit-test drift after rebuilds
- overdraw and repaint churn
- semantics regression and focus loss

## Selected scenarios
- `0a36bef0-54a6-5237-a179-74c81e69710a` — Quantum Vm: public contract remains stable under valid input (critical)
- `edffc82b-17d0-51cf-b2d4-d7d4bdaaedc1` — Quantum Vm: invalid or malformed input is rejected cleanly (critical)
- `95840b78-0442-5300-8d44-c3f629388df0` — Quantum Vm: re-entrant calls do not corrupt internal state (high)
- `385ce48e-c3b9-58db-9fb3-5cc6f1364c1c` — Quantum Vm: dispose/close/teardown releases resources deterministically (high)
- `a1d20802-3bc3-52af-8f47-bbd619a246a6` — Quantum Vm: hot-path behavior stays within the runtime budget (high)
- `6a793dfc-230e-5e9f-95fd-d8a0b7628de5` — Quantum Vm: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.