# YAML manifests

These YAML files describe the SDUI JSON test families in a machine-readable way.

They are written so a future generator can turn them into Dart tests without guessing the coverage intent.

## Manifest design

- `__meta` carries the stable suite identity, title, description, and tags.
- `groups` lets the manifest mirror real product structure.
- `cases` or `rows` hold the executable test cases.
- `sourcePath` points to the real file under audit.
- `assertions` uses the same assertion vocabulary as `test/support/quantum_sdui_json_suite.dart`.
- runtime fixtures may also be described by `input`, `env`, `macros`, `expected`, and `expectError` fields when the manifest represents runnable SDUI behavior.

## Required assertion style

Every family should use a mix of:

- exact catalog assertions for subtype lists
- source text assertions for operator and router presence
- JSON-path assertions for manifest grammar
- recursive nested assertions for complex cases
- negative assertions to make sure accidental branches do not appear
- exact runtime snapshots for the data-driven behavior suite

## Expansion rule

Read the manifests from smallest to largest:

1. schema contract
2. runtime contract
3. operators and bindings
4. omni-core catalog
5. nested composition
6. data-driven runtime behavior fixtures

## Runnable families mirrored by the Dart suite

- schema contract
- runtime contract
- operators and bindings
- omni-core catalog
- nested composition
- state and pipeline
- data-driven runtime behavior fixtures

Each family should map cleanly to either source-text audits or direct Dart behavior checks.
