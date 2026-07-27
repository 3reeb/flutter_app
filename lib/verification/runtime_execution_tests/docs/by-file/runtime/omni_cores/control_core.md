# Runtime execution test plan — runtime/omni_cores/control_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/control_core`
- Area: `control_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `fd19f1668268e3527dad009787b5fa6dc2494e77fc0c9d3752872b8ea26b5ea0`
- Line count: `486`

## Executable surface
- `_QLMachineController`
- `_buildControl`
- `createState`
- `initState`
- `_registerControlAliases`
- `register`
- ... and 19 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation

## Symbol-specific runtime scenarios
### _QLMachineController
- Drive `_QLMachineController` with a null or missing input and execute the live launch path; expect a runtime failure rather than a silent fallback.
- Drive `_QLMachineController` with a malformed or wrong-type input; expect the executed code to reject it during startup.
- Drive `_QLMachineController` with a boundary value such as empty, zero, or oversized data; expect deterministic edge-case behavior at runtime.
- Drive `_QLMachineController` after repeated initialization or disposal; expect stale-state handling to stay deterministic during execution.

### _buildControl
- Drive `_buildControl` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildControl` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildControl` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildControl` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### createState
- Drive `createState` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `createState` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `createState` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `createState` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### initState
- Drive `initState` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `initState` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `initState` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `initState` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
