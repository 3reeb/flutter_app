# `src/runtime/omni_cores/visual_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/visual_core.dart.md`

## File profile
- Lines: 309
- Classes: none detected
- Enums: none detected
- Notable functions: _buildVisual, _registerVisualAliases

## Existing docs snapshot
- `src/runtime/omni_cores/visual_core.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- registry consistency under mixed workload
- orchestration cleanup gaps
- stress-induced latency spikes
- retained state after teardown

## Selected scenarios
- `64adf577-16b1-5502-a014-4ab41986287a` — Visual Core: public contract remains stable under valid input (critical)
- `0bc75436-81bb-507d-afe8-f29e7166c157` — Visual Core: invalid or malformed input is rejected cleanly (critical)
- `df66378a-458c-52f6-a22f-a688690821ce` — Visual Core: re-entrant calls do not corrupt internal state (high)
- `799e8b67-e4c7-536b-a101-1b7b9d6ecf5e` — Visual Core: dispose/close/teardown releases resources deterministically (high)
- `6b08f138-26f4-5748-81fa-466e40f6ed7b` — Visual Core: hot-path behavior stays within the runtime budget (high)
- `08b933b4-46d9-53b8-b8e0-e623e0e447ef` — Visual Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.