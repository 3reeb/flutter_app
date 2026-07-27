# `src/runtime/omni_cores/stream_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/stream_core.dart.md`

## File profile
- Lines: 181
- Classes: _QLWebSocketNode, _QLWebSocketNodeState, _QLSSENode, _QLSSENodeState, _QLTickNode, _QLTickNodeState, _QLRingBufferNode, _QLRingBufferNodeState
- Enums: none detected
- Notable functions: _buildStream, initState, _connect, build, _onValue, _push, _registerStreamAliases

## Existing docs snapshot
- `src/runtime/omni_cores/stream_core.dart`
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
- `3cd9e574-08ef-5e4b-87d3-9dff4e6c348a` — Stream Core: public contract remains stable under valid input (critical)
- `421a2441-226d-5c84-b850-d72fba1efb63` — Stream Core: invalid or malformed input is rejected cleanly (critical)
- `db1b6488-09b6-537f-9f24-736575aaa6f0` — Stream Core: re-entrant calls do not corrupt internal state (high)
- `70458503-f73e-59fe-a1a6-8d539d5a61bd` — Stream Core: dispose/close/teardown releases resources deterministically (high)
- `e893726b-4084-5f90-9213-69f647560fe3` — Stream Core: hot-path behavior stays within the runtime budget (high)
- `9318c5ae-c267-5d15-96fb-a13f7b732303` — Stream Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.