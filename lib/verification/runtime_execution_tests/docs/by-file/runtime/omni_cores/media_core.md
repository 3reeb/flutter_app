# Runtime execution test plan — runtime/omni_cores/media_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/media_core`
- Area: `media_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `7919b46373fac7897dfec1c25b943ca419122e6e0ac790a83cfdbbf1e27b1a7d`
- Line count: `396`

## Executable surface
- `_buildMedia`
- `createState`
- `initState`
- `didUpdateWidget`
- `_registerMediaAliases`
- `build`
- ... and 10 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation
- disposed context
- invalid constraints

## Symbol-specific runtime scenarios
### _buildMedia
- Drive `_buildMedia` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildMedia` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildMedia` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildMedia` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

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

### didUpdateWidget
- Drive `didUpdateWidget` with a missing key, unknown route, or absent identifier; expect a live lookup failure rather than an implicit default.
- Drive `didUpdateWidget` with a null query or empty selector; expect the runtime to reject the request on execution, not at static analysis time.
- Drive `didUpdateWidget` with duplicate matches or conflicting candidates; expect deterministic resolution or a controlled error path.
- Drive `didUpdateWidget` after the source backing store has been cleared or disposed; expect stale lookup access to fail at runtime.

## Cross-cutting launch stressors
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
