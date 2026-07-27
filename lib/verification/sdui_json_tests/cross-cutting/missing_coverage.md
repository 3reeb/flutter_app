# SDUI JSON audit notes

This audit identified a few places where the existing documentation was too narrow for the actual runtime.

## Gaps that needed explicit coverage

- The runtime operator list in `docs/overview/SDUI_RUNTIME_SPEC.md` only named a subset of the operators that `src/runtime/quantum_vm.dart` actually supports.
- The SDUI runtime snapshot had to be covered as a real contract, not as an implied implementation detail.
- Routing-only cores such as `animation`, `chart`, `connect`, `layout`, and `template` needed tests even though they do not expose `subType == '...'` branches.
- The large data and control families needed tests that extend from the simplest binding through repeatable, nested, and mixed compositions.
- The existing manifest suite needed stronger attention to recursive groups, mixed case shapes, and unique case IDs.
- The runtime behavior suite needed exact input/output fixtures rather than a handful of one-off assertions.

## How the new plan covers those gaps

- the YAML catalogue now includes separate families for schema, runtime shape, operators, omni cores, and large nested compositions
- the operator catalog now includes all compile-time operators exposed by the VM
- the omni-core manifest now includes every core file, including empty subtype families
- the nested-composition manifest uses progressive cases so the tree grows from a simple node into a realistic SDUI screen
- the runtime-contract manifest checks the exported type-engine surface and the normalization rules together
- the data-driven runtime suite now loads many JSON fixtures recursively and compares exact compiled snapshots

## Additional runtime behavior that now has explicit Dart tests

- minimal string nodes compile to `text` blueprints
- `box:row` and `box:split` preserve the box subtype semantics from `_normalizeNode`
- `$if` can prune a node to an empty compile result
- `$repeat`, `$switch`, `$async`, `$stream`, `$machine`, `$portal`, `$try`, `$layout`, `$throttle`, and `$debounce` all transform into the expected runtime wrappers
- `$scope` prefixes bound paths and wrapper nodes with `$apply` still propagate merged props and style
- macro expansion, state-store wrapping, and overflow-guard failures are all covered by real fixtures
- the exported type snapshot, JSON snapshot, and TypeScript bundle stay aligned on the same runtime metadata
