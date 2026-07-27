# Runtime execution test plan — runtime/omni_cores/canvas_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/canvas_core`
- Area: `canvas_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `7c7402f3038e65990f9cdde1a19aadbd20ad77dc59e9b66ec67d8bbc6c8743a8`
- Line count: `282`

## Executable surface
- `_QLProceduralCanvasNodeState`
- `_buildCanvas`
- `createState`
- `initState`
- `didUpdateWidget`
- `_registerCanvasAliases`
- ... and 8 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation
- disposed context
- invalid constraints

## Symbol-specific runtime scenarios
### _QLProceduralCanvasNodeState
- Drive `_QLProceduralCanvasNodeState` with a null source value or missing listener; expect the live update path to surface the failure during execution.
- Drive `_QLProceduralCanvasNodeState` with a cyclic/self-referential dependency chain; expect cycle detection or a controlled runtime error during launch.
- Drive `_QLProceduralCanvasNodeState` with duplicate subscriptions or repeated emissions of the same value; expect the change-notification path to remain deterministic at runtime.
- Drive `_QLProceduralCanvasNodeState` after disposal or teardown, then emit again; expect a stale-handle failure to surface instead of mutating dead state.

### _buildCanvas
- Drive `_buildCanvas` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildCanvas` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildCanvas` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildCanvas` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

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
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
