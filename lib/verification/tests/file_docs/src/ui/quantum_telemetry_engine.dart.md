# `src/ui/quantum_telemetry_engine.dart`

**Doc reference:** `docs/src/ui/quantum_telemetry_engine.dart.md`

## File profile
- Lines: 2553
- Classes: TelemetryConfig, SymbolCache, TelemetryRecord, TelemetryFilter, TelemetrySnapshot, TelemetryStore, _OpenSpan, _ImageSpan
- Enums: TelemetryKind, QLType
- Notable functions: intern, clear, snapshot, toJson, matches, toJson, countByKind, countByTargetLabel, durationByTargetLabel, reset

## Existing docs snapshot
- `src/ui/quantum_telemetry_engine.dart`
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
- `61cf3727-9e7d-5faf-bfa5-30960d495168` — Quantum Telemetry Engine: public contract remains stable under valid input (critical)
- `d31821ac-9cea-5e27-a650-13bb856cb7bc` — Quantum Telemetry Engine: invalid or malformed input is rejected cleanly (critical)
- `e04ec6a1-f7a7-58ca-a7e8-08221c32960a` — Quantum Telemetry Engine: re-entrant calls do not corrupt internal state (high)
- `77914cdb-c8cf-56b8-8402-ebe8b7662f54` — Quantum Telemetry Engine: dispose/close/teardown releases resources deterministically (high)
- `11e5a322-b8f8-5e09-9adc-e89e6db555fa` — Quantum Telemetry Engine: hot-path behavior stays within the runtime budget (high)
- `763710a9-3e69-53d9-ade7-0a581f39ae0c` — Quantum Telemetry Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.