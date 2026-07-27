# `src/runtime/omni_cores/text_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/text_core.dart.md`

## File profile
- Lines: 190
- Classes: none detected
- Enums: none detected
- Notable functions: _buildText, _registerTextAliases

## Existing docs snapshot
- `src/runtime/omni_cores/text_core.dart`
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
- `72f79798-615b-512d-b1e4-f36238b0194b` — Text Core: public contract remains stable under valid input (critical)
- `66ff900e-2526-5641-a341-24e4e302ffe8` — Text Core: invalid or malformed input is rejected cleanly (critical)
- `79201add-bf6c-52c6-931a-ad7fe423defd` — Text Core: re-entrant calls do not corrupt internal state (high)
- `0229f757-45f9-51a2-91b4-ad44bb8c4e3b` — Text Core: dispose/close/teardown releases resources deterministically (high)
- `e62c2d73-6a6e-59ea-a7cf-b7daf3837370` — Text Core: hot-path behavior stays within the runtime budget (high)
- `c4e88163-f5b7-541b-842c-918b11654894` — Text Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.