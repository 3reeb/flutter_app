# `src/runtime/quantum_template_engine.dart`

**Doc reference:** `docs/src/runtime/quantum_template_engine.dart.md`

## File profile
- Lines: 796
- Classes: _PendingTemplateDef, _LayoutCompileResult, _GridRect, TemplateDef, QTemplateContext
- Enums: none detected
- Notable functions: string, boolean, integer, number, list, eval, stateKey, checkGuard, _mergeAst, buildSlot

## Existing docs snapshot
- `src/runtime/quantum_template_engine.dart`
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
- `3889cfa0-6d6d-5e89-9f64-4cfcc8284128` — Quantum Template Engine: public contract remains stable under valid input (critical)
- `ba727836-c0b3-5185-815a-acf2aa0ae1bb` — Quantum Template Engine: invalid or malformed input is rejected cleanly (critical)
- `ceb3fe24-86bc-5ceb-9aee-9943d50c8881` — Quantum Template Engine: re-entrant calls do not corrupt internal state (high)
- `66a23b6f-0259-5334-a455-29c966199ca5` — Quantum Template Engine: dispose/close/teardown releases resources deterministically (high)
- `b647d699-ca64-539f-9e61-0ed14d034dae` — Quantum Template Engine: hot-path behavior stays within the runtime budget (high)
- `d7c28436-b572-5e40-915f-7544d48e7039` — Quantum Template Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.