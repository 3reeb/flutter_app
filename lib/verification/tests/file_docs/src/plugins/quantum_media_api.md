# `src/plugins/quantum_media_api.dart`

**Doc reference:** `docs/src/plugins/quantum_media_api.dart.md`

## File profile
- Lines: 941
- Classes: TransferProgress, ByteRange, RangeTracker, MediaCacheManager, BandwidthEstimator, MediaPrefetcher, ResumableUploader, LocalMediaProxyServer
- Enums: MediaType, Quality, HttpMethod
- Notable functions: contains, overlaps, addRange, _merge, getMissingRanges, hasRange, serialize, deserialize, init, _hash

## Existing docs snapshot
- `src/plugins/quantum_media_api.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- dense rendering jank
- hover/selection desynchronization
- numeric edge cases destabilizing paint
- buffer retention during export or snapshot

## Selected scenarios
- `c7aad091-9817-595b-af17-531fd6108ab6` — Quantum Media Api: public contract remains stable under valid input (critical)
- `9289ad6b-d04f-569e-9f64-c3b7fb2c5d8c` — Quantum Media Api: invalid or malformed input is rejected cleanly (critical)
- `7b84f816-2830-5743-a90f-d7cd106d1c5b` — Quantum Media Api: re-entrant calls do not corrupt internal state (high)
- `64b74511-6941-5d11-8237-13aa45516512` — Quantum Media Api: dispose/close/teardown releases resources deterministically (high)
- `6bea7418-c2a5-54ad-b244-0f5837a689e2` — Quantum Media Api: hot-path behavior stays within the runtime budget (high)
- `140e86ab-8145-58ab-83e2-44aa1d278c02` — Quantum Media Api: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.