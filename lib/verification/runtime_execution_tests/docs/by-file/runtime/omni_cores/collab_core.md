# Runtime execution test plan — runtime/omni_cores/collab_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/collab_core`
- Area: `collab_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `cdf8b7cb189476dd52b2260094c75a8760ec3191040f497ee20a83c34c41f326`
- Line count: `193`

## Executable surface
- `_QLCollabRegistry`
- `_QLCollabLockNodeState`
- `_buildCollab`
- `_registerCollabAliases`
- `_QLCollabLockNode`
- `getPresence`
- ... and 12 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation

## Symbol-specific runtime scenarios
### _QLCollabRegistry
- Drive `_QLCollabRegistry` with a null or missing structured payload during app launch; expect the live parser/registry path to fail instead of defaulting silently.
- Drive `_QLCollabRegistry` with a malformed document or wrong value type; expect runtime validation to stop the launch path at the point of execution.
- Drive `_QLCollabRegistry` with duplicate keys, repeated registration, or a recursive reference; expect deterministic failure or cycle handling in the live code path.
- Drive `_QLCollabRegistry` with an oversized or deeply nested payload; expect bounded failure under resource pressure, not a partial and stale runtime state.

### _QLCollabLockNodeState
- Drive `_QLCollabLockNodeState` with a null source value or missing listener; expect the live update path to surface the failure during execution.
- Drive `_QLCollabLockNodeState` with a cyclic/self-referential dependency chain; expect cycle detection or a controlled runtime error during launch.
- Drive `_QLCollabLockNodeState` with duplicate subscriptions or repeated emissions of the same value; expect the change-notification path to remain deterministic at runtime.
- Drive `_QLCollabLockNodeState` after disposal or teardown, then emit again; expect a stale-handle failure to surface instead of mutating dead state.

### _buildCollab
- Drive `_buildCollab` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildCollab` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildCollab` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildCollab` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerCollabAliases
- Drive `_registerCollabAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerCollabAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerCollabAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerCollabAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
