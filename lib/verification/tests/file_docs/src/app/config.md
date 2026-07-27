# `src/app/config.dart`

**Doc reference:** `docs/src/app/config.dart.md`

## File profile
- Lines: 1326
- Classes: QuantumBuildDefines, QuantumBuildOverlay, QuantumConfigSourceResult, QuantumConfigSourceContext, QuantumConfigSource, QuantumInlineConfigSource, QuantumAssetConfigSource, QuantumFileConfigSource
- Enums: QuantumConfigSourceKind, QuantumConfigListMergeMode
- Notable functions: load, load, load, load, load, load, isLocked, isSensitive, toLegacyMap, toLegacyMap

## Existing docs snapshot
- `src/app/config.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- route assembly regressions
- startup ordering failures
- modal/export lifecycle leaks
- navigation state drift

## Selected scenarios
- `c6ce04fe-04dd-554f-a556-0478403b26b8` — Config: public contract remains stable under valid input (critical)
- `0f96ed2e-7963-59ed-8a6f-c8cd21db8933` — Config: invalid or malformed input is rejected cleanly (critical)
- `2bbaa619-3fa4-5d97-a81e-d03c624e788d` — Config: re-entrant calls do not corrupt internal state (high)
- `d7a001cf-c98c-51e2-bc67-d3917b3314e3` — Config: dispose/close/teardown releases resources deterministically (high)
- `556eba25-d63a-52c1-b6e0-00d193e0b3c1` — Config: hot-path behavior stays within the runtime budget (high)
- `d16218b6-0e9e-5220-a40a-226e34d0351a` — Config: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.