# `src/runtime/omni_cores/field_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/field_core.dart.md`

## File profile
- Lines: 521
- Classes: _QLInlineCellNode, _QLInlineCellNodeState, _QLRichTextNode, _QLRichTextNodeState
- Enums: none detected
- Notable functions: _buildField, initState, build, _registerFieldAliases

## Existing docs snapshot
- `src/runtime/omni_cores/field_core.dart`
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
- `3affb641-1381-5780-b5a2-7df777e19a02` — Field Core: public contract remains stable under valid input (critical)
- `cb86c5d3-66e8-55d2-b9c6-293cf394adcb` — Field Core: invalid or malformed input is rejected cleanly (critical)
- `dd4b3cc5-fb80-5034-b793-ff0c1ea47510` — Field Core: re-entrant calls do not corrupt internal state (high)
- `ed129f12-8262-566b-bc39-b7d091efbb67` — Field Core: dispose/close/teardown releases resources deterministically (high)
- `0f630a1b-0eca-5627-91e0-ae4f89bd6e07` — Field Core: hot-path behavior stays within the runtime budget (high)
- `59954b8c-6d8e-59fb-9417-a8b4d8628d7d` — Field Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.