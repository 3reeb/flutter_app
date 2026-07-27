# `src/runtime/omni_cores/layout_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/layout_core.dart.md`

## File profile
- Lines: 992
- Classes: none detected
- Enums: none detected
- Notable functions: _buildLayout, _registerRichSpatialLayouts, _buildDecorationRichText, _registerLayoutAliases

## Existing docs snapshot
- `src/runtime/omni_cores/layout_core.dart`
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
- `d144257d-02fd-5322-8a7f-6e5d2f665395` — Layout Core: public contract remains stable under valid input (critical)
- `7d0af555-44b1-5a6e-84ee-535a52b8753b` — Layout Core: invalid or malformed input is rejected cleanly (critical)
- `082f07c9-98be-514f-87d4-d1d482155cdf` — Layout Core: re-entrant calls do not corrupt internal state (high)
- `1b5269c0-02ec-57e5-8bb6-38ff7100a295` — Layout Core: dispose/close/teardown releases resources deterministically (high)
- `85f7b3ea-3e2c-5ea9-8da5-28a662919713` — Layout Core: hot-path behavior stays within the runtime budget (high)
- `3120ea5e-0142-54bc-89ec-16601a9da707` — Layout Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.