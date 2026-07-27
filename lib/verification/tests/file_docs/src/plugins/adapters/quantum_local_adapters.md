# `src/plugins/adapters/quantum_local_adapters.dart`

**Doc reference:** `docs/src/plugins/adapters/quantum_local_adapters.dart.md`

## File profile
- Lines: 191
- Classes: SqfliteLocalStore, FlutterSecureVault
- Enums: none detected
- Notable functions: init, _ensureInitialized, read, write, delete, clear, size, close, init, read

## Existing docs snapshot
- `src/plugins/adapters/quantum_local_adapters.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- missing adapter fallback
- platform capability mismatch
- bridge detach/reattach ordering
- resource cleanup after failure

## Selected scenarios
- `e72f913d-d284-57ef-a18d-693810e14545` — Quantum Local Adapters: public contract remains stable under valid input (critical)
- `58073cb4-75ee-5ce4-9fb7-c64c11308df7` — Quantum Local Adapters: invalid or malformed input is rejected cleanly (critical)
- `fda90a2a-2f59-5b74-8121-67bcb32e0576` — Quantum Local Adapters: re-entrant calls do not corrupt internal state (high)
- `2e13572d-b142-5c06-bc5c-4d933ca848af` — Quantum Local Adapters: dispose/close/teardown releases resources deterministically (high)
- `5840c8c2-710f-5bd7-8f4a-b3fcbbd2652b` — Quantum Local Adapters: hot-path behavior stays within the runtime budget (high)
- `afedf3a4-8d27-5776-81e4-1db89ea4c446` — Quantum Local Adapters: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.