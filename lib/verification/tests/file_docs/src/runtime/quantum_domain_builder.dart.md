# `src/runtime/quantum_domain_builder.dart`

**Doc reference:** `docs/src/runtime/quantum_domain_builder.dart.md`

## File profile
- Lines: 303
- Classes: QuantumDomainBuilder, _QuantumProxyActionPlugin
- Enums: none detected
- Notable functions: Function, Function, execute

## Existing docs snapshot
- `src/runtime/quantum_domain_builder.dart`
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
- `961325d2-4c5f-5010-87a7-dc0340ea52df` — Quantum Domain Builder: public contract remains stable under valid input (critical)
- `ac15beae-0f14-5506-85b8-0305a1f877ad` — Quantum Domain Builder: invalid or malformed input is rejected cleanly (critical)
- `f5ee700b-b3e7-580a-a63f-e4393fb8bc65` — Quantum Domain Builder: re-entrant calls do not corrupt internal state (high)
- `89c29dce-27cd-530b-b6a6-b0f4aeeb83fd` — Quantum Domain Builder: dispose/close/teardown releases resources deterministically (high)
- `28250890-073d-5f0e-b264-dad88fc96860` — Quantum Domain Builder: hot-path behavior stays within the runtime budget (high)
- `088d27bc-2619-5ccb-8fe7-74fb4ec1738b` — Quantum Domain Builder: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.