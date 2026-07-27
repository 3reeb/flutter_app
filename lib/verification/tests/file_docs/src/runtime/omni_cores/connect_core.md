# `src/runtime/omni_cores/connect_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/connect_core.dart.md`

## File profile
- Lines: 328
- Classes: QLBehaviorRegistry, _QLHoverScaleBehavior, _QLHoverScaleBehaviorState, _QLPressFeedbackBehavior, _QLPressFeedbackBehaviorState, QLBehaviorNode
- Enums: none detected
- Notable functions: build, build, build, _firstChildOr, _buildConnect, registerConnectOmniNodes

## Existing docs snapshot
- `src/runtime/omni_cores/connect_core.dart`
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
- `b13fe0a3-1aa5-5afc-b403-45e7ac8d8908` — Connect Core: public contract remains stable under valid input (critical)
- `2f090fc5-c677-5dc8-b45d-f2846f721478` — Connect Core: invalid or malformed input is rejected cleanly (critical)
- `62075ebd-eb89-54d6-9c09-1d845fb6884d` — Connect Core: re-entrant calls do not corrupt internal state (high)
- `69ce3d37-6206-5f1c-a314-527bd0f3fe34` — Connect Core: dispose/close/teardown releases resources deterministically (high)
- `538fc97f-8875-56db-ab8b-313d7206dc51` — Connect Core: hot-path behavior stays within the runtime budget (high)
- `84ce3223-fb03-5209-84d3-5c5a919af74a` — Connect Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.