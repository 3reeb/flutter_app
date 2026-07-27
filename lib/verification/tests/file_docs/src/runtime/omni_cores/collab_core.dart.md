# `src/runtime/omni_cores/collab_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/collab_core.dart.md`

## File profile
- Lines: 194
- Classes: _QLCursorOverlayNode, _QLCursorOverlayNodeState, _CursorDot, _QLCollabLockNode, _QLCollabLockNodeState
- Enums: none detected
- Notable functions: _buildCollab, tryLock, releaseLock, isLocked, updatePresence, updateCursor, updateAwareness, build, _registerCollabAliases

## Existing docs snapshot
- `src/runtime/omni_cores/collab_core.dart`
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
- `ee61e20a-bc06-5092-979e-cabbb13d981a` — Collab Core: public contract remains stable under valid input (critical)
- `2c94a62c-b94d-5197-8b85-52f44db4b64e` — Collab Core: invalid or malformed input is rejected cleanly (critical)
- `700fe2e2-753c-5639-b48a-96b0a3a430e0` — Collab Core: re-entrant calls do not corrupt internal state (high)
- `2fa2bf3b-8b22-595d-9f26-dab7b5b2c01d` — Collab Core: dispose/close/teardown releases resources deterministically (high)
- `e5f0d90a-d492-5e83-8a07-7ad0ee37bb80` — Collab Core: hot-path behavior stays within the runtime budget (high)
- `9672f153-b792-5dd7-8a45-50e261071701` — Collab Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.