# `src/runtime/omni_cores/decoration_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/decoration_core.dart.md`

## File profile
- Lines: 219
- Classes: none detected
- Enums: none detected
- Notable functions: _buildDecoration, _registerDecorationAliases

## Existing docs snapshot
- `src/runtime/omni_cores/decoration_core.dart`
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
- `b52ff0f1-176b-5f01-a79b-b696913fedd8` — Decoration Core: public contract remains stable under valid input (critical)
- `1cfa1910-a6da-5508-9871-2215316d5471` — Decoration Core: invalid or malformed input is rejected cleanly (critical)
- `faa2a914-e5e1-58e3-b8ec-e775bc33565b` — Decoration Core: re-entrant calls do not corrupt internal state (high)
- `ca1df5c0-5ec4-5517-8cf4-9264ccf393b9` — Decoration Core: dispose/close/teardown releases resources deterministically (high)
- `32ea9c85-6a54-5479-bef8-f55d2c1ff8f6` — Decoration Core: hot-path behavior stays within the runtime budget (high)
- `80b9c882-6202-53be-a7b5-7f34f8fa58be` — Decoration Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.