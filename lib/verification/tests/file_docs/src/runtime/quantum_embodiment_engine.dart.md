# `src/runtime/quantum_embodiment_engine.dart`

**Doc reference:** `docs/src/runtime/quantum_embodiment_engine.dart.md`

## File profile
- Lines: 2365
- Classes: QEEConfig, QEEDataSnapshot, QEEUiNode, QEELayoutProbe, QEETelemetryProbe, QEEMemoryProbe, QEEErrorProbe, QEEProbeResult
- Enums: QEEStatus, QEEKind, PolicySeverity, PolicyTriggerEvent, QEEProbeKind
- Notable functions: liveRead, read, pathEquals, pathMatches, toMap, hasWidget, countWidgets, toMap, toMap, toMap

## Existing docs snapshot
- `src/runtime/quantum_embodiment_engine.dart`
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
- `c9875e54-21b1-5e56-9a13-8208c4063167` — Quantum Embodiment Engine: public contract remains stable under valid input (critical)
- `f6f9e705-2911-5806-aed1-000805da5cf7` — Quantum Embodiment Engine: invalid or malformed input is rejected cleanly (critical)
- `dfc80f50-00a9-55b6-b95f-ca338fa04c41` — Quantum Embodiment Engine: re-entrant calls do not corrupt internal state (high)
- `58d0d408-bf10-5993-990c-339ace53d558` — Quantum Embodiment Engine: dispose/close/teardown releases resources deterministically (high)
- `eb8f0c1f-8c06-58e5-80b4-d3c9925e2f3c` — Quantum Embodiment Engine: hot-path behavior stays within the runtime budget (high)
- `02ddea1d-5cd0-5fd0-8d16-8dc70514ee0d` — Quantum Embodiment Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.