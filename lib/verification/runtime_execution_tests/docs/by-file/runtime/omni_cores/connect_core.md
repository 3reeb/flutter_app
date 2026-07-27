# Runtime execution test plan — runtime/omni_cores/connect_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/connect_core`
- Area: `connect_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `ccc4034f2ecaced80b990d9f51c10d012374912723ea44485bf3ec7df6f06a5b`
- Line count: `327`

## Executable surface
- `QLBehaviorBuilder`
- `QLBehaviorRegistry`
- `registerConnectOmniNodes`
- `QLBehaviorNode`
- `_buildConnect`
- `register`
- ... and 10 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation

## Symbol-specific runtime scenarios
### QLBehaviorBuilder
- Drive `QLBehaviorBuilder` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `QLBehaviorBuilder` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `QLBehaviorBuilder` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `QLBehaviorBuilder` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### QLBehaviorRegistry
- Drive `QLBehaviorRegistry` with a null or missing structured payload during app launch; expect the live parser/registry path to fail instead of defaulting silently.
- Drive `QLBehaviorRegistry` with a malformed document or wrong value type; expect runtime validation to stop the launch path at the point of execution.
- Drive `QLBehaviorRegistry` with duplicate keys, repeated registration, or a recursive reference; expect deterministic failure or cycle handling in the live code path.
- Drive `QLBehaviorRegistry` with an oversized or deeply nested payload; expect bounded failure under resource pressure, not a partial and stale runtime state.

### registerConnectOmniNodes
- Drive `registerConnectOmniNodes` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `registerConnectOmniNodes` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `registerConnectOmniNodes` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `registerConnectOmniNodes` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### QLBehaviorNode
- Drive `QLBehaviorNode` with a null or missing input and execute the live launch path; expect a runtime failure rather than a silent fallback.
- Drive `QLBehaviorNode` with a malformed or wrong-type input; expect the executed code to reject it during startup.
- Drive `QLBehaviorNode` with a boundary value such as empty, zero, or oversized data; expect deterministic edge-case behavior at runtime.
- Drive `QLBehaviorNode` after repeated initialization or disposal; expect stale-state handling to stay deterministic during execution.

## Cross-cutting launch stressors
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
