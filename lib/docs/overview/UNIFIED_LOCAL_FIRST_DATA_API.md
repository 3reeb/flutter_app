# Unified local-first data API

This project now exposes a single data-access shape across slice state, schema selection, datasource refreshes, pipeline hydration, and store-level helpers.

## Covered layers
- `src/runtime/quantum_data_state.dart`: datasource handles, optimistic refresh, stream merging, binding registration, store read/write helpers, and offline write queuing.
- `src/foundation/quantum_schema.dart`: schema-aware selection planning, projection, and partial-record merge helpers.
- `src/runtime/quantum_data_pipeline.dart`: partial hydration, projection-aware reads, page fetches, and aggregate handling.
- `src/runtime/quantum_data_orchestrator.dart`: manifest bootstrap, slice wiring, pipeline delegates, and datasource attachment.
- `src/runtime/quantum_vm.dart`: lazy schema views with selection planning and projection helpers.

## Unified operations
- create
- read
- query
- update
- upsert
- delete
- push
- pop
- move
- reorder
- set
- get
- increment
- decrement
- aggregate
- subscribe
- listen
- publish

## Behavior summary
- Local state stays authoritative for UI rendering.
- Cached fields are reused before remote hydration is requested.
- Missing fields can be requested selectively instead of reloading the full payload.
- Offline or intermittent network writes can be queued and replayed.
- Streaming and realtime paths merge incremental events into the current snapshot.
- Schema-aware selection keeps payloads narrow while preserving data correctness.

## Traceability notes
- Use the file-level docs above for per-module metadata and entry points.
- Use the source SHA-256 values in those docs to verify whether the runtime surface changed after this update.
