# `src/runtime/quantum_sdui_test_engine_io.dart`

**Doc reference:** not found

## File profile
- Lines: 801
- Classes: _ProbeOutcome, _QuantumSduiRenderProbe, _QuantumSduiRenderProbeState
- Enums: none detected
- Notable functions: loadCase, runFolder, runCase, runAllRegistered, saveLastReport, _runRenderProbe, _defaultScreenshotPath, initState, _captureLater, _capture

## Existing docs snapshot
- No headings found in matching docs file.

## Runtime risk areas
- layout collapse under tight constraints
- gesture/hit-test drift after rebuilds
- overdraw and repaint churn
- semantics regression and focus loss

## Selected scenarios
- `a19ad0fb-7ca0-5757-881c-8ab3b4398557` — Quantum Sdui Test Engine Io: public contract remains stable under valid input (critical)
- `d83fffdd-e120-5429-83b4-443da2310364` — Quantum Sdui Test Engine Io: invalid or malformed input is rejected cleanly (critical)
- `119dcf21-aee9-5a33-89d0-de967a2010d6` — Quantum Sdui Test Engine Io: re-entrant calls do not corrupt internal state (high)
- `726d2417-04f7-57ab-af39-d4e77b4291ba` — Quantum Sdui Test Engine Io: dispose/close/teardown releases resources deterministically (high)
- `8b0b70ee-c3d8-5b68-b853-3f083cc0b37c` — Quantum Sdui Test Engine Io: hot-path behavior stays within the runtime budget (high)
- `80f77e5c-725c-5d6f-87fa-f5593ee34668` — Quantum Sdui Test Engine Io: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.