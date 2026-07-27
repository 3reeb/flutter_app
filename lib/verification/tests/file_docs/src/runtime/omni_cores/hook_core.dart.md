# `src/runtime/omni_cores/hook_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/hook_core.dart.md`

## File profile
- Lines: 523
- Classes: _QLHookLifecycleNode, _QLHookLifecycleNodeState, _QLHookEffectNode, _QLHookEffectNodeState, _QLRefNode, _QLRefNodeState, _QLIntervalNode, _QLIntervalNodeState
- Enums: none detected
- Notable functions: _hookSignature, initState, dispose, build, initState, didUpdateWidget, _scheduleEffect, build, _buildHook, buildBody

## Existing docs snapshot
- `src/runtime/omni_cores/hook_core.dart`
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
- `2c8b9a31-04e4-50fb-9c0a-adc0babe8dd9` — Hook Core: public contract remains stable under valid input (critical)
- `3518cf92-5220-5b2a-a7ec-b2d83e071763` — Hook Core: invalid or malformed input is rejected cleanly (critical)
- `ff2f54a6-2a60-556b-aca8-198898b1d33f` — Hook Core: re-entrant calls do not corrupt internal state (high)
- `fabf92c3-99a0-5663-bc4e-bfb76e7f802d` — Hook Core: dispose/close/teardown releases resources deterministically (high)
- `df5667d7-afb4-5867-b847-85bc3b1bc373` — Hook Core: hot-path behavior stays within the runtime budget (high)
- `576c6600-dd0f-503c-9f29-b75299cf75c7` — Hook Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.