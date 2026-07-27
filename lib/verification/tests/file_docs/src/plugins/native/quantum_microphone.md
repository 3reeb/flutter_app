# `src/plugins/native/quantum_microphone.dart`

**Doc reference:** `docs/src/plugins/native/quantum_microphone.dart.md`

## File profile
- Lines: 95
- Classes: AudioRecordingResult, _VoidBoolCodec, _ResultCodec, _StartBridge, _StopBridge, _AmplitudeStreamBridge, _VoidDoubleCodec, QuantumMicrophone
- Enums: none detected
- Notable functions: none detected

## Existing docs snapshot
- `src/plugins/native/quantum_microphone.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- missing adapter fallback
- platform capability mismatch
- bridge detach/reattach ordering
- resource cleanup after failure

## Selected scenarios
- `3e0f5dd7-e7e7-5e91-8c1c-57fc688b73b9` — Quantum Microphone: public contract remains stable under valid input (critical)
- `ac06bb1d-fca0-5d3b-9bf6-dd9e6a84af69` — Quantum Microphone: invalid or malformed input is rejected cleanly (critical)
- `8f9da010-3356-5a2c-a054-855e64c74cf6` — Quantum Microphone: re-entrant calls do not corrupt internal state (high)
- `7286ba1a-9c96-58ae-92f0-1d1aeadc3aae` — Quantum Microphone: dispose/close/teardown releases resources deterministically (high)
- `9712a650-9cdd-5fa8-b9d3-01a0bff078e8` — Quantum Microphone: hot-path behavior stays within the runtime budget (high)
- `387f14cb-5b8e-5f6e-a2ca-ecc13a256512` — Quantum Microphone: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.