# `src/runtime/omni_cores/template_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/template_core.dart.md`

## File profile
- Lines: 3102
- Classes: _QTemplateInstanceNode, _QTemplateInstanceNodeState, _QLTickerNode, _QLTickerNodeState, _QLFlowControllerNode, _QLFlowControllerNodeState, _QLStickyDelegate
- Enums: none detected
- Notable functions: _registerRichDesignSystemTemplates, node, buildRecursiveMenuItems, buildRowsFromRecords, _buildTemplate, initState, dispose, build, initState, dispose

## Existing docs snapshot
- `src/runtime/omni_cores/template_core.dart`
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
- `06fe80cd-c200-5dea-9cfb-0b2900efe321` — Template Core: public contract remains stable under valid input (critical)
- `a96a19c3-c011-575d-a0cc-f582319dd55e` — Template Core: invalid or malformed input is rejected cleanly (critical)
- `773dd2fc-ad77-5f0a-9811-45f3ba2a7ddc` — Template Core: re-entrant calls do not corrupt internal state (high)
- `881a3475-4fb2-519b-b66d-0422f3c7a155` — Template Core: dispose/close/teardown releases resources deterministically (high)
- `ff555b4b-195d-5865-9b02-7b086b71486e` — Template Core: hot-path behavior stays within the runtime budget (high)
- `bb27367e-f572-5236-b2e6-adcb43936641` — Template Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.