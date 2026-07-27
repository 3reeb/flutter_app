# sdui_json_tests index

## Cross-cutting docs

- [`README.md`](README.md)
- [`cross-cutting/test_matrix.md`](cross-cutting/test_matrix.md)
- [`cross-cutting/missing_coverage.md`](cross-cutting/missing_coverage.md)

## YAML manifests

- [`yaml/README.md`](yaml/README.md)
- [`yaml/INDEX.yaml`](yaml/INDEX.yaml)
- [`yaml/shared/case_template.yaml`](yaml/shared/case_template.yaml)
- [`yaml/shared/group_catalog.yaml`](yaml/shared/group_catalog.yaml)
- [`yaml/shared/operator_catalog.yaml`](yaml/shared/operator_catalog.yaml)
- [`yaml/by-file/schema_contract.yaml`](yaml/by-file/schema_contract.yaml)
- [`yaml/by-file/runtime_contract.yaml`](yaml/by-file/runtime_contract.yaml)
- [`yaml/by-file/sdui_runtime_nested_contract.yaml`](yaml/by-file/sdui_runtime_nested_contract.yaml)
- [`yaml/by-file/operators_and_bindings.yaml`](yaml/by-file/operators_and_bindings.yaml)
- [`yaml/by-file/omni_cores_catalog.yaml`](yaml/by-file/omni_cores_catalog.yaml)
- [`yaml/by-file/nested_composition.yaml`](yaml/by-file/nested_composition.yaml)
- [`yaml/by-file/state_and_pipeline.yaml`](yaml/by-file/state_and_pipeline.yaml)
- [`yaml/by-file/runtime_behavior_data_driven.yaml`](yaml/by-file/runtime_behavior_data_driven.yaml)

## Runnable Dart suite

- [`test/generated/sdui_json_runtime_behavior_test/`](../../test/generated/sdui_json_runtime_behavior_test/)

The runnable suite is intentionally data-driven. It discovers the JSON files recursively and compares each compiled blueprint snapshot against the file’s expected output.
