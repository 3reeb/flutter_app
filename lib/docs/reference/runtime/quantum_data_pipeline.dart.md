# `src/runtime/quantum_data_pipeline.dart`

## What this file is
This is the flat-cache data pipeline. It stores records in a compact row-oriented shape, supports partial hydration, maintains indices, and computes aggregates while keeping read paths cheap.

## What it depends on
- `quantum_data_state.dart` for shared runtime helpers and data-source integration
- `quantum_core.dart` for field flags, path utilities, and projections
- `quantum.dart` for the schema registry and framework glue

## Core pipeline model
The pipeline is built for large record sets and tries to avoid repeatedly materializing full object graphs. It keeps:
- a flattened record table
- an id-to-row index
- unique and non-unique indices
- loaded-mask tracking for partial records
- aggregate state
- visible-index state for filtered and paged views

## Why the schema changes matter here
The pipeline does not need a separate branch for the new field types as long as the schema can parse, serialize, and validate them correctly. Once the schema layer understands `media`, `bigInt`, `smallInt`, `decimal`, `char`, `flags`, and `hasMany`, the pipeline can ingest them as ordinary schema-shaped values.

That means:
- `media` records can be partial or fully hydrated without losing their shape
- multi-value scalar fields can remain list-valued in the pipeline cache
- typed values continue to participate in selection, indexing, and aggregation without extra ad hoc code

## Important behaviors
- `replaceAll()` clears cached rows and reloads the pipeline from fresh data.
- `ingest()` normalizes incoming data and updates the flat row store.
- Partial fetch paths can patch a single record without rebuilding the entire dataset.
- The pipeline keeps recomputation localized by using listeners on filters, search, sort, and page signals.

## Performance characteristics
The pipeline is optimized to be memory-friendly by:
- storing rows as lists instead of repeated nested maps
- keeping bit masks for hydration state
- only materializing maps when a caller explicitly asks for them
- using indices for repeated lookups instead of linear scans when possible

## Testing focus
- Confirm partial fetches patch only the targeted record.
- Confirm masked rows remain consistent after new field types are parsed by the schema.
- Confirm aggregates still recompute when selected field values change.
- Confirm record lookups and page transitions do not rebuild unnecessary objects.
