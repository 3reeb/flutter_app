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

The checked-in fixture set now spans 200 JSON execution cases in the layout and runtime folders so the suite covers a broad production-shaped surface, not just a handful of toy examples.


Execution fixtures live under `cases/execution/` and may include `runtimeAssertions`, `runtimeBehavior`, and `executionSteps` for real WidgetTester flows.


Runtime execution assertions resolve the live `QLDataScope` store from the mounted widget tree before checking `expectState` paths. Geometry steps now also verify widget size, bounds, and relative position from the same live tree.
