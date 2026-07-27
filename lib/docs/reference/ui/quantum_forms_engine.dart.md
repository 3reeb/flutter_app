# `src/ui/quantum_forms_engine.dart`

## What this file is
This file is the runtime form engine. It translates schema field specs into controllers, validators, array controllers, group controls, and field widgets while keeping changes fast and memory-conscious.

## What changed in this update
The form layer now understands the expanded type set and supports multi-value forms for the new scalar/media field families.

New controller families were added for:
- `bigInt`
- `smallInt`
- `decimal`
- `char`
- `flags`
- `media`

The latest maintenance pass also tightened the controller defaults and shape handling:
- `QLBigIntController` now falls back to `BigInt.zero` in the initializer instead of relying on a non-const default parameter.
- `QLFlagsController` exposes dedicated flag mutation methods so it no longer collides with the base node enable/disable lifecycle methods.
- `QLMediaController.setMedia()` clones normalized media maps before storing them, which prevents caller-side map mutations from leaking into controller state.

Each of those types also has array counterparts so `hasMany` fields can be edited and serialized as repeated values without flattening them into a lossy string list.

## Core controller responsibilities
### Scalar controllers
- `QLSmallIntController`
- `QLBigIntController`
- `QLDecimalController`
- `QLCharController`
- `QLFlagsController`
- `QLMediaController`

These controllers normalize initial values and keep the runtime type stable while a field is edited.

### Array controllers
- `QLSmallIntArrayController`
- `QLBigIntArrayController`
- `QLDecimalArrayController`
- `QLCharArrayController`
- `QLFlagsArrayController`
- `QLMediaArrayController`

These support `hasMany` by keeping the list shape native to the field type.

## Normalization helpers
The file now includes focused helpers that make controller setup safer and cheaper:
- `_qlClampSmallInt()` keeps values inside the 16-bit signed integer range.
- `_qlBigIntOf()` converts mixed inputs into `BigInt`.
- `_qlCharOf()` extracts the first character safely.
- `_qlDecimalOf()` normalizes a decimal string.
- `_qlMediaOf()` converts strings, maps, byte payloads, and loose inputs into a normalized media map.

These helpers are important because form controls often receive partial or mixed values while the user is typing, selecting files, or editing arrays.

## Field-to-controller mapping
The `_buildSpec()` switch now routes the new field types directly to the matching controller family. For arrays, the nested item spec is used so typed arrays preserve the correct item shape.

That means the form engine can now represent:
- a single media object or many media items
- a single `BigInt` or many `BigInt` values
- a decimal list without coercing everything into doubles
- a flags bitmask or a repeated set of masks
- single-character fields and character arrays

## Performance notes
The form engine stays fast by:
- avoiding unnecessary re-parsing of already-normalized values
- using narrow conversion helpers instead of generic object cloning where possible
- preserving the controller type that matches the schema type, so downstream state changes do less work
- keeping arrays as arrays rather than flattening them into mixed string representations

## Testing focus
- Confirm `hasMany` fields create array controllers instead of scalar controllers.
- Confirm `media` fields preserve map shape, metadata, and source location.
- Confirm `smallInt` values clamp correctly.
- Confirm `char` fields never serialize multi-character strings.
- Confirm `flags` fields keep their integer mask semantics through edit/serialize cycles.
