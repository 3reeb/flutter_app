# Runtime execution test plan — foundation/quantum_isolate_worker

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/foundation/quantum_isolate_worker`
- Area: `quantum_isolate_worker`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `2daa71b7a78bede9f465af6069f1b48980e9204f89144f5d3d3d5f08f1b8faf0`
- Line count: `610`
- Imports:
  - `dart:async`
  - `dart:isolate`
  - `dart:typed_data`
  - `dart:convert`
  - `package:flutter/foundation.dart`
  - `../../quantum.dart`

## Executable surface
- `QLWorkerTask`
- `QLIsolateWorker`
- `QLWorkerPool`
- `QLJsonDecodeTask`
- `QLZeroCopyPipelineTask`
- `_WorkerRequest`
- ... and 16 more

## Launch-time failure targets
- malformed structured payload
- duplicate or recursive definitions
- empty/zero-value edge case
- oversized nested document
- late completion
- message corruption

## Symbol-specific runtime scenarios
### QLWorkerTask
- Drive `QLWorkerTask` with a null task, cancelled future, or missing worker input; expect a runtime failure on the actual execution path.
- Drive `QLWorkerTask` with a late completion after cancellation; expect the launch harness to observe correct failure propagation and cleanup.
- Drive `QLWorkerTask` with a message that cannot be decoded or deserialized; expect the live async path to reject it at runtime.
- Drive `QLWorkerTask` under repeated launches or allocation pressure; expect timeout/backpressure or out-of-memory handling rather than silent corruption.

### QLIsolateWorker
- Drive `QLIsolateWorker` with a null task, cancelled future, or missing worker input; expect a runtime failure on the actual execution path.
- Drive `QLIsolateWorker` with a late completion after cancellation; expect the launch harness to observe correct failure propagation and cleanup.
- Drive `QLIsolateWorker` with a message that cannot be decoded or deserialized; expect the live async path to reject it at runtime.
- Drive `QLIsolateWorker` under repeated launches or allocation pressure; expect timeout/backpressure or out-of-memory handling rather than silent corruption.

### QLWorkerPool
- Drive `QLWorkerPool` with a null task, cancelled future, or missing worker input; expect a runtime failure on the actual execution path.
- Drive `QLWorkerPool` with a late completion after cancellation; expect the launch harness to observe correct failure propagation and cleanup.
- Drive `QLWorkerPool` with a message that cannot be decoded or deserialized; expect the live async path to reject it at runtime.
- Drive `QLWorkerPool` under repeated launches or allocation pressure; expect timeout/backpressure or out-of-memory handling rather than silent corruption.

### QLJsonDecodeTask
- Drive `QLJsonDecodeTask` with malformed input, truncated bytes, or a broken document shape; expect the executed transform to throw or reject the payload.
- Drive `QLJsonDecodeTask` with deep nesting, recursive content, or a self-referential structure; expect cycle detection or bounded failure at runtime.
- Drive `QLJsonDecodeTask` with wrong value types or mixed encodings; expect the live conversion path to fail where it actually runs.
- Drive `QLJsonDecodeTask` with an oversized payload; expect the launched code to reject it or stop cleanly under resource pressure.

## Cross-cutting launch stressors
- Feed the live path an empty `Uint8List`, then an oversized buffer, to verify byte-oriented code fails deterministically at runtime.
- Force the isolate-backed path to spawn, fail, and fall back; verify the runtime sees the spawn failure and does not leave a hanging worker.
- Make a future fail after cancellation or after the owning scope is gone so the executed async path must propagate the error cleanly.
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.
- Use malformed UTF-8 or truncated encoded payloads so the live decode path throws where the code actually runs.
- Run the same failing input under repeated startup and teardown cycles to ensure no stale debug/runtime state persists.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
