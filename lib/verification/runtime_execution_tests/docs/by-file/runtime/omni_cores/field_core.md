# Runtime execution test plan — runtime/omni_cores/field_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/field_core`
- Area: `field_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `5818df08d95de185a4a20883e9cac175d0da1bc640fd383d5f5da548052ea9cc`
- Line count: `520`

## Executable surface
- `_buildField`
- `initState`
- `setState`
- `_registerFieldAliases`
- `build`
- `_QLInlineCellNodeState`
- ... and 3 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation

## Symbol-specific runtime scenarios
### _buildField
- Drive `_buildField` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildField` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildField` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildField` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### initState
- Drive `initState` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `initState` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `initState` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `initState` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### setState
- Drive `setState` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `setState` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `setState` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `setState` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerFieldAliases
- Drive `_registerFieldAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerFieldAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerFieldAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerFieldAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
