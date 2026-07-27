# `src/runtime/omni_cores/portal_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/portal_core.dart.md`

## File profile
- Lines: 759
- Classes: _QLInlineSurfaceHost, _QLInlineSurfaceHostState, _QLOverlayEntryNode, _QLOverlayEntryNodeState
- Enums: none detected
- Notable functions: _buildPortal, buildContent, buildTrigger, didChangeDependencies, dispose, build, initState, didUpdateWidget, _onTriggerChanged, dispose

## Existing docs snapshot
- `src/runtime/omni_cores/portal_core.dart`
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
- `4033ed39-45d9-5048-885b-b23fd337a7e5` — Portal Core: public contract remains stable under valid input (critical)
- `7f752770-3c14-5d92-9c12-24421035a4b0` — Portal Core: invalid or malformed input is rejected cleanly (critical)
- `fbf7af1c-dee3-5217-86a0-7fdf5c5c203d` — Portal Core: re-entrant calls do not corrupt internal state (high)
- `eb9c93de-8772-5365-b676-7f2b4189d334` — Portal Core: dispose/close/teardown releases resources deterministically (high)
- `476ad550-9f2d-513c-a64a-b17a09b39be6` — Portal Core: hot-path behavior stays within the runtime budget (high)
- `27cd04be-a366-54c9-9f08-6de644b4f7b3` — Portal Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.