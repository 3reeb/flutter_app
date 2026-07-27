# `src/runtime/quantum_test_engine_shared.dart`

**Doc reference:** not found

## File profile
- Lines: 693
- Classes: QuantumTestSourceMetadata, QuantumTestRowSpec, QuantumTestGroupSpec, QuantumTestSupplementSpec, QuantumTestManifest, QuantumTestCaseSpec, QuantumTestIssue, QuantumTestResult
- Enums: QuantumTestStatus, QuantumTestPhase
- Notable functions: toJson, toJson, toJson, toJson, surfaceNames, toJson, validate, toJson, toJson, toJson

## Existing docs snapshot
- No headings found in matching docs file.

## Runtime risk areas
- registry consistency under mixed workload
- orchestration cleanup gaps
- stress-induced latency spikes
- retained state after teardown

## Selected scenarios
- `5cb88dbd-a284-5937-982c-1a667e804d7d` — Quantum Test Engine Shared: public contract remains stable under valid input (critical)
- `0cda5f83-0692-538f-ba46-7d8f7bfabb1d` — Quantum Test Engine Shared: invalid or malformed input is rejected cleanly (critical)
- `c0801cc0-7cf5-5721-886f-ae07a3c3d567` — Quantum Test Engine Shared: re-entrant calls do not corrupt internal state (high)
- `f2586a8e-d3aa-590d-bc2c-31798de9343f` — Quantum Test Engine Shared: dispose/close/teardown releases resources deterministically (high)
- `62ebe9cf-ce80-53f1-8845-8ecaf13c79ce` — Quantum Test Engine Shared: hot-path behavior stays within the runtime budget (high)
- `2c648b9c-64a0-5db8-b008-9f9a0b7596ef` — Quantum Test Engine Shared: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.