# `src/foundation/quantum_core.dart`

**Doc reference:** `docs/src/foundation/quantum_core.dart.md`

## File profile
- Lines: 657
- Classes: QLNodeError, QLDisposable, QLProjection, QLChangeBatch, QLFieldPathView, QFixed, QFraction, QAuto
- Enums: QLSleepPolicy
- Notable functions: dispose, select, isSelected

## Existing docs snapshot
- `src/foundation/quantum_core.dart`
- What this file is
- Core responsibilities
- Key field types
- Field flags
- Path and projection behavior

## Runtime risk areas
- registry consistency under mixed workload
- orchestration cleanup gaps
- stress-induced latency spikes
- retained state after teardown

## Selected scenarios
- `1cf3d636-3ee5-5298-82f0-20fa191dae3d` — Quantum Core: public contract remains stable under valid input (critical)
- `c98b7631-2c05-5dd8-98fe-3c7dfbb18abc` — Quantum Core: invalid or malformed input is rejected cleanly (critical)
- `c812f740-28c1-5b8c-8298-600e1c868786` — Quantum Core: re-entrant calls do not corrupt internal state (high)
- `3924debb-9de5-5cd1-b1a2-5ab12547b29d` — Quantum Core: dispose/close/teardown releases resources deterministically (high)
- `270aa6c5-1396-5118-8f6e-b09f1c91e20e` — Quantum Core: hot-path behavior stays within the runtime budget (high)
- `12d0f5fd-894c-5af3-912f-856fc3fb7a77` — Quantum Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.