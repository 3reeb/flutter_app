# `src/foundation/quantum_schema.dart`

## What this file is
This is the schema compiler, runtime schema registry, validation engine, parse/serialize bridge, and smart-select planner for the framework. It turns a declarative field description into a flattened, indexed blueprint that other layers can validate, hydrate, cache, and partially fetch.

## What changed in this update
The schema layer now understands the expanded type system and treats `hasMany` as a true multi-value contract.

Newly supported field types:
- `media`
- `bigInt`
- `smallInt`
- `decimal`
- `char`
- `flags`

New alias support in the compiler accepts common synonyms such as `int64`, `long`, `smallint`, `numeric`, `money`, `character`, `bitmask`, `asset`, and `file`.

`hasMany` now applies to these scalar/media types as well, so a field can be modeled as a repeated list of media objects, repeated decimals, repeated flags, and so on.

## Public model types
### `QLBlockPayload`
A normalized block record with a `blockType` and a `data` payload map. It is used when block fields are parsed, validated, or serialized.

### `QLSchemaFieldSpec`
Holds the compiled metadata for one field path, including:
- `name` and `path`
- `type` and `flags`
- relation target / options / min / max
- child field specs and array item spec
- media policy fields such as MIME constraints, size limits, thumbnails, and streaming/cache settings
- computed function hooks

Important derived getters:
- `isVirtual`
- `isComputed`
- `isRequired`
- `hasMany`
- `isReadOnly`
- `isMedia`
- `supportsAdaptiveQuality`
- `supportsRangeCaching`
- `supportsLazyLoad`

`supportsLazyLoad` is intentionally broad: it becomes true for media fields, multi-value fields, or explicit lazy policies. That lets downstream code decide whether a field should be paged, deferred, or streamed without needing to re-derive the policy itself.

### `QLSchemaBlueprint`
The compiled, flattened schema graph. It holds:
- `rootFields`
- flattened `fields`
- a `byPath` index map

This is the object used by runtime data pipelines and the VM when they need fast field lookup.

## Runtime behavior
### Parse
`parse()` reads raw JSON-like maps, resolves field paths, drops invalid garbage values, and writes schema-shaped output. The parser now:
- handles list values for `hasMany`
- handles array specs with typed item specs
- handles block values through schema-aware block parsing
- handles media normalization
- handles the new scalar types with type-specific conversion rules

### Serialize
`serialize()` performs the inverse conversion and keeps the same type semantics in reverse:
- `bigInt` is normalized to a string representation
- `smallInt` is kept as an integer
- `decimal` is preserved as a trimmed string form
- `char` is constrained to a single-character string
- `flags` becomes a normalized bitmask integer
- `media` becomes a normalized media map

### Validate
`validate()` now enforces more specific rules for the expanded types:
- `char` must be a single character
- `smallInt` must stay inside the 16-bit signed range
- `bigInt` must parse as a valid big integer
- `decimal` must parse cleanly as a numeric decimal string
- `flags` must normalize to a valid integer mask
- `media` can be constrained by MIME type and size bounds
- arrays and `hasMany` values validate each item separately
- nested object children validate recursively
- blocks validate against nested block schemas when available

## New helper behavior
The blueprint now uses dedicated helpers for field parsing, serialization, and validation rather than routing everything through one generic conversion path. That makes the type system easier to extend and keeps the special cases explicit.

Important helpers include:
- `_parseFieldValue`
- `_serializeFieldValue`
- `_validateFieldValue`
- `_parseItem`
- `_serializeItem`
- `_parseValue`
- `_serializeValue`
- `_normalizeMediaValue`
- `_serializeMediaValue`
- `_normalizeFlagsValue`

## Compiler logic
`QLSchemaCompiler` now normalizes type labels before matching them, so spacing, underscores, and hyphens do not matter. It also treats `many` and `multiple` flags as `hasMany`.

The compiler’s role is to turn a raw schema map into a flattened runtime blueprint with stable field indices, which is what enables:
- bitset projection
- partial hydration
- indexed record storage
- fast validation
- selective serialization

## Smart-select and partial hydration
The blueprint exposes projection helpers that compare requested paths to available fields and build a compact read plan. That is what the data pipeline uses when it wants to fetch only the fields that are actually needed.

## Notes for implementation and testing
- A field declared as `media[]` or `hasMany: true` on a media field should round-trip as a list of normalized media payloads.
- A `char` field should reject strings longer than one character.
- A `flags` field should accept integers, option names, lists, and flag maps when normalization can derive a mask.
- A `decimal` field should preserve the textual decimal form instead of silently forcing binary floating-point behavior.
- When testing schema flattening, confirm that object fields with `hasMany` are still preserved as list-valued paths rather than being skipped during parse/serialize.
