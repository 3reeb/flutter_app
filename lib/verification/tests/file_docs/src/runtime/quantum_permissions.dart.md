# `src/runtime/quantum_permissions.dart`

**Doc reference:** `docs/src/runtime/quantum_permissions.dart.md`

## File profile
- Lines: 2766
- Classes: QuantumPermissionException, QuantumPermissionDecision, QuantumPermissionContext, QuantumPermissionRegistry, QuantumPermissionEngine, QuantumAppPermissionDescriptor, QuantumAppPermissionCenter, QuantumAppPermissionCatalog
- Enums: QuantumAppPermissionKind, QuantumPermissionState, QuantumPermissionKind
- Notable functions: toString, toJson, claim, hasRole, hasPermission, hasFeature, hasSubscription, opIs, scopeIs, register

## Existing docs snapshot
- `src/runtime/quantum_permissions.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- least-privilege enforcement regression
- grant/revoke snapshot mismatch
- audit leakage
- unexpected allow on edge inputs

## Selected scenarios
- `18da9c44-8333-5711-af43-728511e205b5` — Quantum Permissions: public contract remains stable under valid input (critical)
- `ea70fa1c-9b4e-50eb-bf81-a1dad96bb6c8` — Quantum Permissions: invalid or malformed input is rejected cleanly (critical)
- `0fe90d75-c8a5-5c63-b804-3a141c8e0330` — Quantum Permissions: re-entrant calls do not corrupt internal state (high)
- `cc181c64-48fb-5904-8490-1f7593c57198` — Quantum Permissions: dispose/close/teardown releases resources deterministically (high)
- `036dadca-5362-5674-abba-a1facdf77509` — Quantum Permissions: hot-path behavior stays within the runtime budget (high)
- `06477ab8-b878-5619-b933-f96f68884d97` — Quantum Permissions: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.