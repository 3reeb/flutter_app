# `src/runtime/downloader_io.dart`

**Doc reference:** not found

## File profile
- Lines: 27
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
- `03bc6727-af81-5362-9142-83fa73b57da9` — Downloader Io: public contract remains stable under valid input (critical)
- `413198d9-16ad-5049-9a2b-b1cb44ae3ca6` — Downloader Io: invalid or malformed input is rejected cleanly (critical)
- `c1409150-086c-5633-a52a-7ae0c8537375` — Downloader Io: re-entrant calls do not corrupt internal state (high)
- `7e726071-2184-5504-82a1-e6a433700404` — Downloader Io: dispose/close/teardown releases resources deterministically (high)
- `1109e75f-75e7-5690-8aff-bb17b5e39e08` — Downloader Io: hot-path behavior stays within the runtime budget (high)
- `d9a03cf5-1b0c-524b-be85-1f5750e9981b` — Downloader Io: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.