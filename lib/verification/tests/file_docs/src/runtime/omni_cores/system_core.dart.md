# `src/runtime/omni_cores/system_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/system_core.dart.md`

## File profile
- Lines: 601
- Classes: _QLSystemAsyncNode, _QLSystemAsyncNodeState, _QLSystemRateLimitNode, _QLSystemRateLimitNodeState, _QLLifecycleNode, _QLLifecycleNodeState, _QLVsyncTimerNode, _QLVsyncTimerNodeState
- Enums: none detected
- Notable functions: _buildSystem, initState, _run, build, dispose, build, initState, dispose, build, initState

## Existing docs snapshot
- `src/runtime/omni_cores/system_core.dart`
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
- `5ba4ee05-3d57-5b21-ad0a-287644eb9bfc` — System Core: public contract remains stable under valid input (critical)
- `56632773-e365-55b6-a338-6adab02578d3` — System Core: invalid or malformed input is rejected cleanly (critical)
- `33b894fe-34c8-5c30-8165-bbbd42250e57` — System Core: re-entrant calls do not corrupt internal state (high)
- `b87f2bec-c2e7-56ef-8aae-ace9d38058b9` — System Core: dispose/close/teardown releases resources deterministically (high)
- `edee5f0d-7656-5a6f-89f6-c8794ff48768` — System Core: hot-path behavior stays within the runtime budget (high)
- `e0d4bf2c-bd37-52a5-b3ba-3f5c796127b0` — System Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.