# `src/runtime/omni_cores/box_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/box_core.dart.md`

## File profile
- Lines: 719
- Classes: _QLMeasureNode, _RenderMeasureNode
- Enums: none detected
- Notable functions: _buildBox, createRenderObject, updateRenderObject, performLayout, _applyImplicitBehaviors, _buildSmartScrollViewport, _registerBoxAliases

## Existing docs snapshot
- `src/runtime/omni_cores/box_core.dart`
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
- `2312adcc-0728-5e8c-a164-aec0d77f8081` — Box Core: public contract remains stable under valid input (critical)
- `3d3ef8d9-1c8f-5e63-9e9c-75cc8678a425` — Box Core: invalid or malformed input is rejected cleanly (critical)
- `399449f5-a728-5824-ab60-66a859b8fd71` — Box Core: re-entrant calls do not corrupt internal state (high)
- `fe92351b-34a4-5f57-ace4-bc00cdc33529` — Box Core: dispose/close/teardown releases resources deterministically (high)
- `667fc2f6-ef6a-5f9a-a720-518ab40faf8b` — Box Core: hot-path behavior stays within the runtime budget (high)
- `83ad1e6a-efc7-53bd-97f6-a370b8fc5436` — Box Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.