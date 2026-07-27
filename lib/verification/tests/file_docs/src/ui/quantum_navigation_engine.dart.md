# `src/ui/quantum_navigation_engine.dart`

**Doc reference:** `docs/src/ui/quantum_navigation_engine.dart.md`

## File profile
- Lines: 1039
- Classes: QLSeoConfig, QLMiddleware, QLRouteInfo, QLRoute, _RadixMatch, _RadixNode, _QLRadixTrie, QLNavController
- Enums: QLTransitionType
- Notable functions: generateHtmlTags, param, intParam, query, insert, _zeroAllocSplit, _registerRoutes, switchBranch, replaceRoot, push

## Existing docs snapshot
- `src/ui/quantum_navigation_engine.dart`
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
- `d40515ac-5675-55fe-b4e5-4db22ff6dcea` — Quantum Navigation Engine: public contract remains stable under valid input (critical)
- `086b3c64-2634-5ac5-a0fa-68acfd62ea91` — Quantum Navigation Engine: invalid or malformed input is rejected cleanly (critical)
- `c49fd59c-abbf-598c-9261-1b9593619fe4` — Quantum Navigation Engine: re-entrant calls do not corrupt internal state (high)
- `d0ec55e3-1df9-5be9-a6ac-7f16dce80f32` — Quantum Navigation Engine: dispose/close/teardown releases resources deterministically (high)
- `91e8a4e4-48df-5b8d-8ea0-ab1ea1840391` — Quantum Navigation Engine: hot-path behavior stays within the runtime budget (high)
- `042f9e48-d86a-5c3f-b403-1f841c62e689` — Quantum Navigation Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.