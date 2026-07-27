# sdui_json_runtime_behavior_test

This folder is the runnable SDUI runtime behavior suite.

Each JSON file under `cases/` is a real test case with:

- `__meta` — stable case identity and description
- `input` — the SDUI JSON sent into `QuantumVM.compile`
- `env` — optional compile-time environment values
- `macros` — optional macro catalog passed into the compiler
- `expected` — the exact blueprint snapshot expected from `toJson()`
- `expectError` — optional error contract for negative cases

The Dart runner discovers every JSON file recursively and compares the compiled blueprint to the stored snapshot. That keeps the suite real: small nodes, nested nodes, wrappers, data bindings, grid layout, macro expansion, and failure guards are all expressed as data, not hand-written one-off tests.

The checked-in fixture set now spans 100 JSON cases in each major folder so the suite covers a broad production-shaped surface, not just a handful of toy examples.
