# `src/runtime/omni_cores/media_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/media_core.dart.md`

## File profile
- Lines: 397
- Classes: _QLAudioPlayerNode, _QLAudioPlayerNodeState, _QLAudioVisualizerNode, _QLAudioVisualizerNodeState, _QLCompiledPathNode, _QLCompiledPathNodeState, _RawPathPainter
- Enums: none detected
- Notable functions: _buildMedia, build, build, initState, didUpdateWidget, build, paint, shouldRepaint, _registerMediaAliases

## Existing docs snapshot
- `src/runtime/omni_cores/media_core.dart`
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
- `996855da-ddf7-55fe-bcc2-c3bb93fc74bd` — Media Core: public contract remains stable under valid input (critical)
- `44bc614a-1bf4-590f-b8b4-224faa4e74f7` — Media Core: invalid or malformed input is rejected cleanly (critical)
- `68a1195a-cfd3-5d7a-9337-f6fd9a513e83` — Media Core: re-entrant calls do not corrupt internal state (high)
- `62cb18bb-2cfc-5eaa-9b1d-30d3bce2401c` — Media Core: dispose/close/teardown releases resources deterministically (high)
- `be204363-c4a3-53a3-946d-a0ec79b703f2` — Media Core: hot-path behavior stays within the runtime budget (high)
- `b0f5b54e-4986-564f-a24c-33819adac371` — Media Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.