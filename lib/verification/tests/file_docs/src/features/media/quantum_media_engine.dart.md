# `src/features/media/quantum_media_engine.dart`

**Doc reference:** `docs/src/features/media/quantum_media_engine.dart.md`

## File profile
- Lines: 690
- Classes: QLMediaPolicy, QLMediaSource, QLSubtitleTrack, QLMediaPlaybackController, QuantumMediaOrchestrator, QLVideoLifecycleWrapper, _QLVideoLifecycleWrapperState, QLVideoSurface
- Enums: QLStreamFormat
- Notable functions: initialize, _onHardwareUpdate, _startSyncWatchdog, play, pause, seek, setVolume, dispose, onIndexChanged, _runGarbageCollectionAndPrefetch

## Existing docs snapshot
- `src/features/media/quantum_media_engine.dart`
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
- `9133bc0a-0711-5bca-bdb6-1998fe65990c` — Quantum Media Engine: public contract remains stable under valid input (critical)
- `41f273d1-3478-52b3-9e87-f25975126250` — Quantum Media Engine: invalid or malformed input is rejected cleanly (critical)
- `1dd71ba8-ac8e-53e7-a361-929ab0d7cf9a` — Quantum Media Engine: re-entrant calls do not corrupt internal state (high)
- `b1f25376-3412-5787-8956-500891d03f8b` — Quantum Media Engine: dispose/close/teardown releases resources deterministically (high)
- `388449e9-a46a-5eb5-a079-eed104712651` — Quantum Media Engine: hot-path behavior stays within the runtime budget (high)
- `1ba1238f-cdea-5d10-adde-bacdf61acb16` — Quantum Media Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.