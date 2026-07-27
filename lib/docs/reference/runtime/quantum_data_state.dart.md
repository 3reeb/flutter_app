# `src/runtime/quantum_data_state.dart`

## What this file is
This file owns the shared data-state and data-source runtime. It provides cache-aware handles, async registry integration, local-first behavior, stream routing, request construction, and data-source orchestration helpers.

## What changed in this update
The data-source layer now treats media-like source types consistently with the schema updates.

Source type aliases now route through the media path for:
- `media`
- `asset`
- `file`
- a few related streamable aliases

That keeps runtime request behavior aligned with schema field types and prevents media sources from falling back to generic API collection behavior.

## Key runtime pieces
### `QLRuntimeSupport`
Shared helpers used by the orchestrator, pipeline, and source layer:
- context resolution
- map normalization
- record list extraction
- last-result access
- path-affects checks
- path canonicalization
- safe string conversion

### `QLRuntimeCache` and `QLRuntimeCacheSizer`
A bounded, weight-aware cache implementation used to keep runtime lookups memory-friendly. The cache tracks hits, misses, evictions, and approximate weight so heavy data does not accumulate indefinitely.

### `QLDataSourceHandle`
Represents one live or virtual data source. It keeps a signal, a config map, pending writes, and optional stream subscription state.

Important behaviors:
- `isStreaming` now recognizes media-like source types through a shared matcher.
- request building chooses `media` / `adaptive_stream` for media-like source types.
- stream detection now accepts media and asset domains as well as realtime ones.

## Why this matters
The runtime data-source layer is the bridge between schema intent and actual requests. If a schema says something is media, or a source is configured as file/asset/media, the runtime should not treat it like a generic read-many collection.

## Caching behavior
This file is where the memory-friendly runtime policy lives:
- cache entries can expire by TTL
- the cache maintains a max-entry and max-weight budget
- a simple estimator is used to avoid storing large values indefinitely

That is the layer that makes lazy load and partial refresh practical without forcing every source to remain resident forever.

## Testing focus
- Confirm media-like source types are recognized as streaming-capable.
- Confirm request construction uses the media domain and media action path.
- Confirm the cache removes expired entries and keeps weight bounded.
- Confirm path-affects logic still catches nested field changes.
