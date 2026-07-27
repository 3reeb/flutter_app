# `src/runtime/quantum_widget_image_exporter.dart`

**Doc reference:** `docs/src/runtime/quantum_widget_image_exporter.dart.md`

## File profile
- Lines: 414
- Classes: QuantumExportResult, QuantumExportConfig, _OffscreenCaptureHost, _OffscreenCaptureHostState
- Enums: none detected
- Notable functions: toString, initState, _capture, build

## Existing docs snapshot
- `src/runtime/quantum_widget_image_exporter.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- dense rendering jank
- hover/selection desynchronization
- numeric edge cases destabilizing paint
- buffer retention during export or snapshot

## Selected scenarios
- `77cd4793-8151-59b1-ae53-b1fbe24be62f` — Quantum Widget Image Exporter: public contract remains stable under valid input (critical)
- `bb8a0507-9a6a-59fb-a0e7-3a87f1ca123c` — Quantum Widget Image Exporter: invalid or malformed input is rejected cleanly (critical)
- `c44a4844-5dbf-5943-86c4-6036c2a649c8` — Quantum Widget Image Exporter: re-entrant calls do not corrupt internal state (high)
- `113b9e59-b2b5-50d1-b391-769feb2f55c9` — Quantum Widget Image Exporter: dispose/close/teardown releases resources deterministically (high)
- `8afd0cda-5d9a-5521-8d68-20acba693b19` — Quantum Widget Image Exporter: hot-path behavior stays within the runtime budget (high)
- `a2187165-dca1-5531-a67b-2a4fcea702da` — Quantum Widget Image Exporter: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.