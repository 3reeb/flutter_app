# `src/runtime/quantum_vm_components.dart`

**Doc reference:** `docs/src/runtime/quantum_vm_components.dart.md`

## File profile
- Lines: 2492
- Classes: _AliasContext, _QLBlueprintRuntimeRule, _QLComponentDefinition, _QLComponentComputedSpec, _QLComponentEffectSpec, _QLComponentHookBundle, _QLComponentRuntimeHost, _QLComponentRuntimeHostState
- Enums: none detected
- Notable functions: resolvedSubType, _buildComponent, _registerComponentAliases, _buildComponentDefine, _buildComponentUse, _buildComponentScoped, _buildComponentLink, _registerComponentDefinition, _componentSchemaForValue, _componentRawMap

## Existing docs snapshot
- `src/runtime/quantum_vm_components.dart`
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
- `de9ba29b-a4f3-5b8a-8746-3fd7e807e95a` — Quantum Vm Components: public contract remains stable under valid input (critical)
- `9e155a86-4be7-564d-a652-3ca9e09b4d66` — Quantum Vm Components: invalid or malformed input is rejected cleanly (critical)
- `6b6d08e6-67c9-54e9-a271-975d2422381e` — Quantum Vm Components: re-entrant calls do not corrupt internal state (high)
- `3ba498e7-45ad-57a2-ad3e-5fa1f8ffd3ce` — Quantum Vm Components: dispose/close/teardown releases resources deterministically (high)
- `4e3e56cf-c37c-5343-8125-8a7333ba76ec` — Quantum Vm Components: hot-path behavior stays within the runtime budget (high)
- `54ef61e5-e62f-5914-a2e2-7513d6c7461e` — Quantum Vm Components: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.