# `src/runtime/downloader_web.dart`

**Doc reference:** not found

## File profile
- Lines: 35
- Classes: none detected
- Enums: none detected
- Notable functions: downloadText, downloadImage

## Existing docs snapshot
- No headings found in matching docs file.

## Runtime risk areas
- registry consistency under mixed workload
- orchestration cleanup gaps
- stress-induced latency spikes
- retained state after teardown

## Selected scenarios
- `ef378275-c87b-5400-b5ed-775a21947d9a` — Downloader Web: public contract remains stable under valid input (critical)
- `d97cdef7-0d0f-5c36-8b37-9524f91e5d77` — Downloader Web: invalid or malformed input is rejected cleanly (critical)
- `1a210507-f527-5314-85d6-9f7161881386` — Downloader Web: re-entrant calls do not corrupt internal state (high)
- `c836b5b4-e7d4-59a6-848e-29c8328aded4` — Downloader Web: dispose/close/teardown releases resources deterministically (high)
- `4cf30738-653b-579e-b691-29edac6f33e8` — Downloader Web: hot-path behavior stays within the runtime budget (high)
- `5eff8b4d-ceb8-56ed-ab61-e468829cde5c` — Downloader Web: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.