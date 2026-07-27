# test/sdui_json

This folder contains data-driven SDUI contract specs.

A JSON file here is not a widget fixture. It is a test manifest that the shared SDUI JSON suite turns into concrete Flutter tests at runtime.

## Folder layout

- `omni_cores_catalog.json` — source-derived catalog for every file in `src/runtime/omni_cores/`
- `omni_cores_nested_catalog.json` — nested core catalog that mirrors the multi-level documentation plan
- `sdui_runtime_contract.json` — runtime contract checks for the SDUI engine, registry, and test engine
- `sdui_runtime_nested_contract.json` — nested runtime contract checks for recursive manifest shapes
- `sdui_json_schema_contract.json` — manifest-shape tests for the JSON test format itself
- `operators_and_bindings.json` — compile-time operator and binding audits
- `state_and_pipeline.json` — data-store and pipeline contract audits
- `nested_composition.json` — progressive node, wrapper, and large-screen composition audits
- any additional `.json` file under this folder or its subfolders is discovered automatically

## Supported case format

Each file can define:

- `__meta` or `meta` — suite metadata (for example `id`, `title`, `description`, `tags`, and `allowBlank`)
- `cases`, `tests`, or `rows` — an array of executable cases
- `sourcePath` — the Dart or JSON source file to validate
- `snapshotPath` — optional snapshot path for runtime export checks
- `sourceSha256` — optional source fingerprint
- `lineCountAtLeast` — optional minimum source length
- `assertions` — a list of built-in assertion objects

## Supported assertion kinds

- `source_contains_all`
- `source_contains_any`
- `source_not_contains`
- `subtypes_exact`
- `subtypes_contains`
- `builder_contains`
- `line_count_at_least`
- `source_sha256_matches`
- `snapshot_path_not_empty`
- `json_round_trip`
- `json_round_trip_strict`
- `json_root_keys_contains`
- `json_root_keys_exact`
- `json_meta_keys_contains`
- `json_meta_keys_exact`
- `json_case_count_at_least`
- `json_case_count_exact`
- `json_case_keys_contains`
- `json_case_keys_exact`
- `json_case_ids_unique`
- `json_case_assertions_nonempty`
- `json_assertion_kinds_allowed`

## JSON authoring rules

1. Keep `__meta.id` stable so the suite title stays readable.
2. Make every case `id` unique.
3. Pin source files with `sourceSha256` when you want exact regression protection.
4. Use `subtypes_exact` for omni-core catalogs so the subtype list cannot drift silently.
5. Use `snapshot_path_not_empty` against `QuantumSduiTypeEngine.exportSnapshot()` to prove the runtime registry exports the same core.
6. Use `json_round_trip_strict` on manifest files to catch schema drift or invalid JSON normalization.

## Example

```json
{
  "__meta": {
    "id": "example-contract",
    "title": "Example contract",
    "description": "A small JSON-driven test manifest.",
    "tags": ["sdui", "example"]
  },
  "cases": [
    {
      "id": "example-case",
      "title": "Example case",
      "sourcePath": "src/runtime/omni_cores/box_core.dart",
      "assertions": [
        {
          "kind": "subtypes_exact",
          "expected": ["row", "col"]
        },
        {
          "kind": "snapshot_path_not_empty",
          "path": "omniCores.box.subtypeCount"
        }
      ]
    }
  ]
}
```

The suite automatically discovers every JSON file in this folder recursively.

## Nested manifest grammar

A manifest can be flat, nested, or mixed.

```json
{
  "__meta": {
    "id": "nested-example",
    "title": "Nested example",
    "description": "A manifest that mirrors the runtime tree.",
    "tags": ["sdui", "nested", "json"],
    "allowBlank": true
  },
  "cases": [
    {
      "id": "root-shape",
      "title": "Root shape",
      "sourcePath": "test/sdui_json/example.json",
      "assertions": [
        { "kind": "json_root_keys_contains", "expected": ["__meta", "groups"] },
        { "kind": "json_path_type_is", "path": "groups", "expected": ["list"] }
      ]
    }
  ],
  "groups": [
    {
      "id": "feature-family",
      "title": "Feature family",
      "description": "A nested family of test rows.",
      "groups": [
        {
          "id": "leaf-module",
          "title": "Leaf module",
          "rows": [
            {
              "id": "leaf-case",
              "title": "Leaf case",
              "sourcePath": "src/runtime/example.dart",
              "assertions": [
                {
                  "kind": "all",
                  "assertions": [
                    { "kind": "source_contains_all", "values": ["ExampleSymbol"] },
                    { "kind": "source_not_contains", "values": ["TODO"] }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

## Advanced assertion blocks

- `all` runs every nested assertion.
- `any` passes when at least one nested assertion passes.
- `not` passes only when the nested block fails.
- `json_path_*` assertions let you inspect deeply nested arrays and objects.
- `json_assertion_kinds_allowed` should list every assertion kind you intend to permit in the manifest.

## Recommended production pattern

Use nested groups to match product architecture, and keep leaf rows small enough that each case validates one contract family at a time. That makes failures easier to interpret and makes the JSON itself act like executable documentation.


## Runnable behavior tests

The JSON manifests are paired with direct Dart behavior tests in `test/generated/sdui_json_runtime_behavior_test/`. Those tests compile real SDUI nodes and verify exact runtime snapshots from recursive JSON fixtures.
