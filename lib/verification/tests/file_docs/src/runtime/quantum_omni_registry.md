# `src/runtime/quantum_omni_registry.dart`

**Doc reference:** `docs/src/runtime/quantum_omni_registry.dart.md`

## File profile
- Lines: 457
- Classes: _AliasContext
- Enums: none detected
- Notable functions: clearQuantumInputRegistry, Function, registerOmniComponents

## Existing docs snapshot
- `src/runtime/quantum_omni_registry.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- cache invalidation and stale snapshot leakage
- parallel mutation and event ordering
- observer/listener leaks
- bounded memory under repeated churn

## Selected scenarios
- `864e47d5-90ec-5b55-911d-e5b9ec3de8f3` — Quantum Omni Registry: public contract remains stable under valid input (critical)
- `8012770f-07bc-5d72-82cc-c07b2b7e43f6` — Quantum Omni Registry: invalid or malformed input is rejected cleanly (critical)
- `b97fb51f-bc27-5e5f-9ab6-da2eec38591a` — Quantum Omni Registry: re-entrant calls do not corrupt internal state (high)
- `c904775a-24ee-5275-b5e1-fbec5d1fe7d8` — Quantum Omni Registry: dispose/close/teardown releases resources deterministically (high)
- `21d92715-ffd6-5699-a740-f5b5b5e9a721` — Quantum Omni Registry: hot-path behavior stays within the runtime budget (high)
- `85acad82-632c-520f-af23-9e023af13bc9` — Quantum Omni Registry: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.