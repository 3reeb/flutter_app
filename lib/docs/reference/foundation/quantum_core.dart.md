# `src/foundation/quantum_core.dart`

## What this file is
This file defines the shared low-level primitives that the rest of the framework depends on: state flags, sleep policy, node errors, field type constants, field flags, projection helpers, path utilities, and a few compact math / parsing helpers. It is the first place to look when a higher layer needs to know what a field type or runtime bit flag means.

## Core responsibilities
- Stores the canonical field type ids used by schema parsing, form construction, runtime validation, and serialization.
- Stores bit flags for node state and field metadata.
- Provides path helpers that normalize dotted and indexed paths into cached strides.
- Provides compact value objects like `QLProjection`, `QLChangeBatch`, and `QLFieldPathView`.
- Provides lightweight parsing utilities used by JSON DSL, schema, and runtime layers.

## Key field types
`QLFieldType` now includes the original scalar and structural types plus the expanded set used by the schema/forms updates:
- `string`
- `number`
- `boolean`
- `date`
- `json`
- `object`
- `relation`
- `relationship`
- `block`
- `enumeration`
- `array`
- `tree`
- `secure`
- `lookup`
- `textarea`
- `media`
- `bigInt`
- `smallInt`
- `decimal`
- `char`
- `flags`

These ids are used as the stable type contract across the parser, form engine, pipeline, and orchestration layers.

## Field flags
`QLFieldFlags` exposes the bitmask contract used by compiled schema fields:
- virtual / computed / required
- hasMany
- unique / indexed
- hidden / readOnly

`hasMany` is important because the newer schema logic treats it as a first-class multi-value contract rather than a loose convention.

## Path and projection behavior
`QLPathUtils` caches resolved paths in a bounded `LinkedHashMap`, so repeated lookups of the same field path stay cheap even when large records or many slices are being processed. The utility also canonicalizes paths, extracts prefixes, and joins / splits paths in a consistent way.

`QLProjection` is the compact bitset used to include or exclude field indices during parse and serialization.

## Practical implications
- If you add a new schema field type, the constant should be introduced here first so the rest of the stack can talk about it consistently.
- If you add a new field flag, this file is the shared bitmask contract.
- If you are debugging path resolution, this is the place to inspect for cache invalidation or canonicalization behavior.

## Testing focus
- Confirm path resolution returns stable strides for dotted, bracketed, and mixed paths.
- Confirm projection bits align with field indices after compilation.
- Confirm new field ids remain unique and are used consistently by schema and form layers.
