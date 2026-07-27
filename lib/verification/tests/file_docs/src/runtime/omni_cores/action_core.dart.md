# `src/runtime/omni_cores/action_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/action_core.dart.md`

## File profile
- Lines: 337
- Classes: _QLRawGestureNode, _QLViewportNode, _QLViewportNodeState
- Enums: none detected
- Notable functions: _buildAction, _safeCall, _injectRawPointer, build, initState, build, _registerActionAliases

## Existing docs snapshot
- `src/runtime/omni_cores/action_core.dart`
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
- `c4220d88-6f58-58cd-bf99-ece010000893` — Action Core: public contract remains stable under valid input (critical)
- `46d7eaea-e23b-559f-acac-e64b22df149c` — Action Core: invalid or malformed input is rejected cleanly (critical)
- `49e64334-e62b-5e7e-8307-697fc98cce33` — Action Core: re-entrant calls do not corrupt internal state (high)
- `d6d93ddc-aa7a-582f-bdef-09b36106f531` — Action Core: dispose/close/teardown releases resources deterministically (high)
- `da43bffd-23b4-57bc-9094-ce559a8f5f60` — Action Core: hot-path behavior stays within the runtime budget (high)
- `c3c69a29-63ae-5ced-804e-aa55e5ea83e7` — Action Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.