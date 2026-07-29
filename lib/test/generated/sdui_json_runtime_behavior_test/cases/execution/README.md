# execution

Real WidgetTester-backed runtime execution fixtures.

These cases are intentionally small but they drive live rendering, real taps, text entry, and store mutations. They are discovered recursively by the runner together with the compile-time fixtures. State assertions read the live scoped store from the mounted widget tree, not just the global default store.
