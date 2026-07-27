# SDUI JSON test matrix

## Coverage pillars

| Pillar | What it must prove | Primary evidence |
| --- | --- | --- |
| Schema grammar | The manifest shape, metadata keys, recursive groups, and supported assertion kinds stay stable. | `test/sdui_json/README.md`, `test/support/quantum_sdui_json_suite.dart`, `test/generated/sdui_json_contract_test.dart` |
| Runtime normalization | A node can be minimal, canonical, or colon-typed, and the VM still normalizes it correctly, including name/slot/debug-path preservation. | `src/runtime/quantum_vm.dart`, `docs/overview/SDUI_RUNTIME_SPEC.md`, `test/generated/sdui_json_runtime_behavior_test/` |
| State and pipeline | SDUI data binding has real backing stores, reads, writes, pagination, search, and aggregation. | `src/runtime/quantum_data_state.dart`, `src/runtime/quantum_data_pipeline.dart` |
| Omni-core routing | Every `type` / `props.__subType` branch remains explicit and covered. | `src/runtime/omni_cores/*.dart`, `src/runtime/quantum_vm.dart` |
| DSL operators | Every compile-time `$` operator listed by the VM has a test family. | `src/runtime/quantum_vm.dart`, `test/generated/sdui_json_runtime_behavior_test/cases/operators/` |
| Snapshot export | The SDUI type snapshot exposes registry, core schemas, core files, design systems, omni cores, DSL operators, alias registry, and orchestrator state. | `src/runtime/quantum_sdui_type_engine.dart` |
| Large composition | Deeply nested trees combine data, control, media, overlays, layout, and binding operators without losing semantics. | `src/runtime/quantum_vm.dart`, `src/runtime/quantum_template_engine.dart`, `test/generated/sdui_json_runtime_behavior_test/cases/nested/` |
| Negative guards | The suite must fail on dangerous depth and other invalid runtime forms instead of silently accepting them. | `test/generated/sdui_json_runtime_behavior_test/cases/failure/` |

## Required progression

The coverage plan should always move in this order:

1. minimal node shape
2. canonical node shape with props and style
3. box/layout subtypes
4. text/media/action/field basics
5. data repetition and reactive bindings
6. overlays, portals, and error boundaries
7. control-flow and compile-time operators
8. macro expansion and wrapper collapsing
9. state-store wrapping and compile-time environment behavior
10. large nested compositions that combine all of the above

## What counts as strong coverage

- every branch appears at least once with the real runtime type name
- empty subtype families are tested as deliberate routing-only files, not ignored
- nested manifests are tested as nested manifests, not flattened away
- the test suite exercises both the source text and the exported runtime shape
- the suite checks for drift in the helper docs as well as the code surface
- recursive discovery cases are stored as real JSON fixtures with exact expected outputs
- negative tests are explicit and reproducible

## Runnable behavior coverage

The Dart behavior suite now loads its own data fixtures from `test/generated/sdui_json_runtime_behavior_test/cases/` and checks the exact compiled blueprint snapshots.

That gives the suite production-oriented coverage for:
- minimal string nodes
- nested children and slot paths
- colon normalization and split guards
- compile-time interpolation and env scoping
- wrapper operators such as repeat, async, stream, machine, portal, and try/catch/finally
- layout expansion and macro expansion
- state-store wrapping
- overflow guard failures
