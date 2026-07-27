# `src/runtime/omni_cores/control_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/control_core.dart.md`

## File profile
- Lines: 487
- Classes: _QLMachineController, _QLMachineNode, _QLMachineNodeState, _QLOptimisticNode, _QLOptimisticNodeState, _QLLocalReducerNode, _QLLocalReducerNodeState
- Enums: none detected
- Notable functions: _buildControl, register, remove, can, send, _invokeEntry, matches, matchesAny, initState, dispose

## Existing docs snapshot
- `src/runtime/omni_cores/control_core.dart`
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
- `56fb32eb-075d-5e98-9667-2265836fb8c9` — Control Core: public contract remains stable under valid input (critical)
- `3904c330-6f31-567f-881b-b572a7a6e607` — Control Core: invalid or malformed input is rejected cleanly (critical)
- `7c1b0b55-ce2d-5692-8515-f09ad17c13f1` — Control Core: re-entrant calls do not corrupt internal state (high)
- `26680c9c-1a94-5150-aa42-12ef8d9be203` — Control Core: dispose/close/teardown releases resources deterministically (high)
- `93171140-33b6-594a-98e4-7ad7daddb602` — Control Core: hot-path behavior stays within the runtime budget (high)
- `541d5414-acb9-5201-9d79-ad697b20634b` — Control Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.