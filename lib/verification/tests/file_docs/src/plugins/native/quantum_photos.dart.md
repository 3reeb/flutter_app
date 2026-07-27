# `src/plugins/native/quantum_photos.dart`

**Doc reference:** `docs/src/plugins/native/quantum_photos.dart.md`

## File profile
- Lines: 80
- Classes: MediaFile, PickerConfig, _PickerCodec, _PickMediaBridge, QuantumPhotos
- Enums: none detected
- Notable functions: toMap

## Existing docs snapshot
- `src/plugins/native/quantum_photos.dart`
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
- `8dab749c-cd2f-563a-a7c3-e536207e9db8` — Quantum Photos: public contract remains stable under valid input (critical)
- `bd3b1420-4101-59a7-9900-18e113df627f` — Quantum Photos: invalid or malformed input is rejected cleanly (critical)
- `ae8357e1-4179-5c5d-89bc-f4dd1b17fc77` — Quantum Photos: re-entrant calls do not corrupt internal state (high)
- `a87e5c13-1d0e-5f62-b0d7-7e466bf3f099` — Quantum Photos: dispose/close/teardown releases resources deterministically (high)
- `8865ff49-553c-59b3-84a1-5d1c026641d8` — Quantum Photos: hot-path behavior stays within the runtime budget (high)
- `6612304f-3db8-5e01-8094-99af435d0753` — Quantum Photos: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.