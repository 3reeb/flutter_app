# `src/plugins/native/quantum_camera.dart`

**Doc reference:** `docs/src/plugins/native/quantum_camera.dart.md`

## File profile
- Lines: 156
- Classes: CameraConfig, MediaResult, _InitCodec, _MediaCodec, _InitBridge, _VoidBoolCodec, _DisposeBridgeImpl, _TakePhotoBridge
- Enums: CameraLens, FlashMode
- Notable functions: toMap, encode, decode, encode, encode, decode

## Existing docs snapshot
- `src/plugins/native/quantum_camera.dart`
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
- `36dd2d30-c20e-53ae-be23-05915f6915d2` — Quantum Camera: public contract remains stable under valid input (critical)
- `9cc6f7f3-04a5-5a7f-8fa6-dbd51c3e0b1f` — Quantum Camera: invalid or malformed input is rejected cleanly (critical)
- `eb6bde47-12e3-5a46-9344-a1d4d5a156aa` — Quantum Camera: re-entrant calls do not corrupt internal state (high)
- `f1a85905-181e-51e2-b87b-6ab9b9197ff8` — Quantum Camera: dispose/close/teardown releases resources deterministically (high)
- `41a7f0a1-74ca-51f3-8355-cf934913a73e` — Quantum Camera: hot-path behavior stays within the runtime budget (high)
- `21ce177a-60e9-562c-81ba-caab360eaf4a` — Quantum Camera: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.