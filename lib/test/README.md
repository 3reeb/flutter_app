# test

This folder contains the generated, YAML-driven test shells for the Quantum codebase, plus a JSON-driven SDUI contract suite.

## Layout

- `support/` — shared helpers, manifest validation, source fingerprinting, SDUI JSON contract execution, and compact result formatting.
- `generated/` — one Dart test shell per source file, plus dedicated JSON contract runners.
- `sdui_json/` — executable JSON test manifests for SDUI and omni-core contract checks.
- `generated/<path>_test.dart` — imports the barrel export, validates the matching YAML manifest, fingerprints the source file, and runs file-specific smoke checks.

## How the generated tests work

Each generated file now does three things:

1. imports `quantum.dart` so the full source barrel is compiled
2. loads the matching YAML manifest under `docs_tests/yaml/by-file/`
3. validates the manifest, source fingerprint, supplement manifests, and the declared surface

The shared suite also checks row completeness, surface coverage, JSON round-trips, and source/manifest drift, while the key generated test files add real controller and model behavior checks.

The SDUI JSON suite adds a second execution path: write a JSON manifest under `test/sdui_json/`, and the runner turns each case into a concrete Flutter test with built-in assertions for source contracts, subtype catalogs, and live SDUI snapshot checks.

## Why this structure matters

The generated tests are still thin in spirit, but they now verify the actual source fingerprint and supplement manifests, not just the manifest shape. That keeps the suite aligned with the code while preserving the one-file-per-source layout.

## Nested SDUI JSON manifests

The JSON runner now supports nested `groups`, `sections`, `cases`, `tests`, and `rows` blocks. This means you can mirror the runtime architecture in the manifest itself:

- suite-level metadata in `__meta` or `meta`
- nested groups for feature families, modules, and submodules
- case rows inside `cases`, `tests`, or `rows`
- recursive assertion blocks using `all`, `any`, and `not`
- path checks such as `json_path_exists`, `json_path_keys_contains`, and `json_path_length_at_least`

The runner recursively discovers any `.json` file under `test/sdui_json/`.
