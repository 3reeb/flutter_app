# Runtime execution test plan — ui/quantum_overlays

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/ui/quantum_overlays`
- Area: `quantum_overlays`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `820669128870b916842897f82ce19a16a6a9efac7ac6236b32bb58c1c70ed1d4`
- Line count: `2469`
- Imports:
  - `dart:async`
  - `dart:convert`
  - `dart:math`
  - `package:flutter/material.dart`
  - `package:flutter/scheduler.dart`
  - `package:flutter/services.dart`
  - `package:quantum_layout/quantum.dart`

## Executable surface
- `QLOverlayBuilder`
- `QLOverlayRuntimeSpec`
- `QuantumOverlay`
- `QLOverlayRoot`
- `QLOverlayInsertMode`
- `QuantumOverlayContextExt`
- ... and 57 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation
- late completion
- message corruption

## Symbol-specific runtime scenarios
### QLOverlayBuilder
- Drive `QLOverlayBuilder` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `QLOverlayBuilder` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `QLOverlayBuilder` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `QLOverlayBuilder` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### QLOverlayRuntimeSpec
- Drive `QLOverlayRuntimeSpec` with a null task, cancelled future, or missing worker input; expect a runtime failure on the actual execution path.
- Drive `QLOverlayRuntimeSpec` with a late completion after cancellation; expect the launch harness to observe correct failure propagation and cleanup.
- Drive `QLOverlayRuntimeSpec` with a message that cannot be decoded or deserialized; expect the live async path to reject it at runtime.
- Drive `QLOverlayRuntimeSpec` under repeated launches or allocation pressure; expect timeout/backpressure or out-of-memory handling rather than silent corruption.

### QuantumOverlay
- Drive `QuantumOverlay` with a null child, missing context, or disposed widget tree; expect the build/layout path to fail at runtime.
- Drive `QuantumOverlay` with invalid constraints, zero size, or an impossible geometry; expect launch-time layout/paint rejection.
- Drive `QuantumOverlay` with duplicate keys or repeated attachment in the same frame; expect the live widget tree to report a runtime failure.
- Drive `QuantumOverlay` with a large, dense, or rapidly changing UI payload; expect frame pressure to surface during execution instead of leaving stale visuals.

### QLOverlayRoot
- Drive `QLOverlayRoot` with a null child, missing context, or disposed widget tree; expect the build/layout path to fail at runtime.
- Drive `QLOverlayRoot` with invalid constraints, zero size, or an impossible geometry; expect launch-time layout/paint rejection.
- Drive `QLOverlayRoot` with duplicate keys or repeated attachment in the same frame; expect the live widget tree to report a runtime failure.
- Drive `QLOverlayRoot` with a large, dense, or rapidly changing UI payload; expect frame pressure to surface during execution instead of leaving stale visuals.

## Cross-cutting launch stressors
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.
- Make a future fail after cancellation or after the owning scope is gone so the executed async path must propagate the error cleanly.
- Run boundary numeric cases such as `0`, `-1`, `double.nan`, and large magnitudes through the live math path to check runtime rejection.
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.
- Use malformed UTF-8 or truncated encoded payloads so the live decode path throws where the code actually runs.
- Starve the frame scheduler or enqueue repeated callbacks so the launch path proves it can fail or back off under pressure.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
