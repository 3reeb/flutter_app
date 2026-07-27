# `src/foundation/quantum_isolate_worker.dart`

**Doc reference:** `docs/src/foundation/quantum_isolate_worker.dart.md`

## File profile
- Lines: 613
- Classes: QLTransferableBuffer, _WorkerRequest, _WorkerResponse, _WorkerBootstrap, QLWorkerTask, QLIsolateWorker, QLWorkerPool, QLFloat64BatchTask
- Enums: none detected
- Notable functions: encode, compute, _ensureSpawned, dispose, dispose, encode, compute, encode, compute, decode

## Existing docs snapshot
- `src/foundation/quantum_isolate_worker.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- layout collapse under tight constraints
- gesture/hit-test drift after rebuilds
- overdraw and repaint churn
- semantics regression and focus loss

## Selected scenarios
- `52ae26b0-918e-5173-9f6a-b62eb8018ea4` — Quantum Isolate Worker: public contract remains stable under valid input (critical)
- `c41fe814-8e39-57ac-b5d4-0493456fd112` — Quantum Isolate Worker: invalid or malformed input is rejected cleanly (critical)
- `45b67b06-4e82-5f87-82eb-a965f734c302` — Quantum Isolate Worker: re-entrant calls do not corrupt internal state (high)
- `934e5da0-5dd5-5a9d-9b2a-8a5e48d1233e` — Quantum Isolate Worker: dispose/close/teardown releases resources deterministically (high)
- `8465a325-96d8-5ec5-bb92-79c5ec0e29cb` — Quantum Isolate Worker: hot-path behavior stays within the runtime budget (high)
- `281dad7c-b31e-5303-a985-084f5c9d7643` — Quantum Isolate Worker: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.