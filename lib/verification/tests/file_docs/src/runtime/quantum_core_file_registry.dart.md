# `src/runtime/quantum_core_file_registry.dart`

**Doc reference:** `docs/src/runtime/quantum_core_file_registry.dart.md`

## File profile
- Lines: 331
- Classes: QLCoreFileDescriptor
- Enums: none detected
- Notable functions: toMap, _resolveCoreFromFolder, _resolveTypeName, _key, registerFolder, registerBuiltIn, registerOverride, register, _register, descriptors

## Existing docs snapshot
- `src/runtime/quantum_core_file_registry.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- cache invalidation and stale snapshot leakage
- parallel mutation and event ordering
- observer/listener leaks
- bounded memory under repeated churn

## Selected scenarios
- `383bb58c-73c1-5d56-b023-14b9aa7a9b42` — Quantum Core File Registry: public contract remains stable under valid input (critical)
- `fc07a7a3-6609-50b7-b5a3-52447be0cb6d` — Quantum Core File Registry: invalid or malformed input is rejected cleanly (critical)
- `50fcb548-0ebf-5444-a814-f676af3653bc` — Quantum Core File Registry: re-entrant calls do not corrupt internal state (high)
- `5d1e80f0-2114-559c-bc04-cb55d64e272c` — Quantum Core File Registry: dispose/close/teardown releases resources deterministically (high)
- `afa47d4c-bf08-5858-bba5-228649a03f5b` — Quantum Core File Registry: hot-path behavior stays within the runtime budget (high)
- `1d582de8-6aea-51b0-9c23-90eeae79562a` — Quantum Core File Registry: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.