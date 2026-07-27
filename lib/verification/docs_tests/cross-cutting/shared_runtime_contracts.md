# Shared runtime contracts

These contracts apply to schema, state, pipeline, orchestrator, VM, UI, and plugin layers.

## Contract themes

- **Cache discipline:** cache hits must remain repeatable and invalidation must be explicit.
- **Lazy-load discipline:** deferred work must stay deferred until a first-access boundary is crossed.
- **Serialization discipline:** round-trips must preserve shape, metadata, and compatibility semantics.
- **List discipline:** hasMany/list paths must preserve list boundaries and item identity.
- **Media discipline:** media values must preserve type hints, mime/content metadata, source fields, and lazy-load policy.
- **Scalar discipline:** bigInt, smallInt, decimal, char, and flags must remain distinct runtime types, not generic strings.
- **Error discipline:** failures must be explicit, localized, and observable.
- **Performance discipline:** repeated work should be bounded and predictable.

## Silent-failure traps

- stale snapshots that still look valid
- eager loads hidden inside getter calls
- accidental list flattening
- coercing incompatible scalars into strings
- duplicate listener registration
- incorrect platform fallback selection
- losing metadata while round-tripping through serialization

## SDUI JSON contract layer

The SDUI JSON suite now supports a nested manifest model in addition to the original flat case list.

### Manifest structure

- `__meta` / `meta`: suite metadata (`id`, `title`, `description`, `tags`, `allowBlank`)
- `cases` / `tests` / `rows`: root-level executable cases
- `groups` / `sections`: nested group nodes that can contain more groups and more cases
- nested groups may use `cases`, `tests`, or `rows` for their leaves

### Nested assertion grammar

Use `all`, `any`, and `not` to compose assertion blocks.

Use `json_path_*` assertions when the manifest needs to inspect its own nested shape or validate a JSON source contract at a deep path.

The supported path assertions are:

- `json_path_exists`
- `json_path_not_empty`
- `json_path_equals`
- `json_path_contains_all`
- `json_path_contains_any`
- `json_path_keys_contains`
- `json_path_keys_exact`
- `json_path_length_at_least`
- `json_path_length_exact`
- `json_path_type_is`

### Why this matters

A deeply nested manifest can now mirror the runtime SDUI tree directly: feature family -> module -> submodule -> leaf contract. That gives you one JSON file that documents the contract and executes the test for it.
