# `src/runtime/quantum_core_schema_registry.dart`

**Doc reference:** `docs/src/runtime/quantum_core_schema_registry.dart.md`

## File profile
- Lines: 2112
- Classes: QLCorePropSpec, QLCoreSlotSpec, QLCoreSchemaDescriptor
- Enums: none detected
- Notable functions: toMap, toMap, _mergeMaps, toMap, clear, installDefaults, registerCore, registerAlias, registerFileSource, hasName

## Existing docs snapshot
- `src/runtime/quantum_core_schema_registry.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- malformed document acceptance
- deep nesting or alias blowups
- encoding and BOM handling
- duplicate declaration ambiguity

## Selected scenarios
- `e4142ab1-2319-5493-822f-25267eb341a9` — Quantum Core Schema Registry: public contract remains stable under valid input (critical)
- `d7fba3ea-b62e-560b-980f-dbcf78928952` — Quantum Core Schema Registry: invalid or malformed input is rejected cleanly (critical)
- `4045c764-962e-5ac3-ab05-7105e99b4aba` — Quantum Core Schema Registry: re-entrant calls do not corrupt internal state (high)
- `79bcfaef-a820-5ff2-b58f-38436638e6d0` — Quantum Core Schema Registry: dispose/close/teardown releases resources deterministically (high)
- `e9a6f3bb-a9b5-54e9-9a37-ee2e0f685f9e` — Quantum Core Schema Registry: hot-path behavior stays within the runtime budget (high)
- `1e89ed91-c315-5918-a108-a53b4a7a2874` — Quantum Core Schema Registry: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.