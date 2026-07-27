# Runtime execution test plan — runtime/omni_cores/portal_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/portal_core`
- Area: `portal_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `68bebe0e8712094884a5357af01f34e0f567447985c156793fddf113dd350894`
- Line count: `758`

## Executable surface
- `parseRuntime`
- `_buildPortal`
- `createState`
- `initState`
- `didUpdateWidget`
- `_registerPortalAliases`
- ... and 18 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation
- disposed context
- invalid constraints

## Symbol-specific runtime scenarios
### parseRuntime
- Drive `parseRuntime` with malformed input, truncated bytes, or a broken document shape; expect the executed transform to throw or reject the payload.
- Drive `parseRuntime` with deep nesting, recursive content, or a self-referential structure; expect cycle detection or bounded failure at runtime.
- Drive `parseRuntime` with wrong value types or mixed encodings; expect the live conversion path to fail where it actually runs.
- Drive `parseRuntime` with an oversized payload; expect the launched code to reject it or stop cleanly under resource pressure.

### _buildPortal
- Drive `_buildPortal` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildPortal` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildPortal` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildPortal` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

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
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
