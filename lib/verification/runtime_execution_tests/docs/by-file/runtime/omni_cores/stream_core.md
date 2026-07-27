# Runtime execution test plan — runtime/omni_cores/stream_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/stream_core`
- Area: `stream_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `4622cc082c3e832acfda1fe2dfec6dff693cdbd3f8beb2df2352986e808cbd37`
- Line count: `180`

## Executable surface
- `_buildStream`
- `initState`
- `setState`
- `_registerStreamAliases`
- `build`
- `_QLWebSocketNode`
- ... and 10 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation
- timeout
- connection refusal

## Symbol-specific runtime scenarios
### _buildStream
- Drive `_buildStream` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildStream` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildStream` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildStream` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

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

### _registerStreamAliases
- Drive `_registerStreamAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerStreamAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerStreamAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerStreamAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
