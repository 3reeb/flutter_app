# `src/runtime/omni_cores/animation_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/animation_core.dart.md`

## File profile
- Lines: 514
- Classes: _QLStaggerNode, _QLStaggerNodeState, _QLSkeletonWidget, _QLSkeletonWidgetState, _QLKeyframeNode, _QLKeyframeNodeState, _QLSequenceNode, _QLSequenceNodeState
- Enums: none detected
- Notable functions: _buildAnimation, _registerAnimationAliases, initState, dispose, build, initState, dispose, build, initState, dispose

## Existing docs snapshot
- `src/runtime/omni_cores/animation_core.dart`
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
- `8ad114ab-2ed2-5b3c-8b37-f76da8b48d86` — Animation Core: public contract remains stable under valid input (critical)
- `6f5e9781-bb40-525e-949d-30eae276d6eb` — Animation Core: invalid or malformed input is rejected cleanly (critical)
- `9809c7a7-edfb-5225-ba9a-81de486011ff` — Animation Core: re-entrant calls do not corrupt internal state (high)
- `25f3c426-949c-50d5-8e1a-6ba0104889be` — Animation Core: dispose/close/teardown releases resources deterministically (high)
- `c5973301-fb5b-53ab-b6bb-845d6753ff40` — Animation Core: hot-path behavior stays within the runtime budget (high)
- `5df8d99a-9608-54b3-a342-d7ffc8b88942` — Animation Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.