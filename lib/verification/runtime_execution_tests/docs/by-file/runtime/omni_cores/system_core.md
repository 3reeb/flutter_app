# Runtime execution test plan — runtime/omni_cores/system_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/system_core`
- Area: `system_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `137f8c0877b9c159f8789facf53a9131085d89b496bef11aaa38f9ed30694ec1`
- Line count: `600`

## Executable surface
- `_QLSystemAsyncNode`
- `_QLSystemAsyncNodeState`
- `_QLSystemRateLimitNodeState`
- `_buildSystem`
- `createState`
- `initState`
- ... and 18 more

## Launch-time failure targets
- cycle detection
- duplicate subscription
- stale state after dispose
- invalid update propagation
- late completion
- message corruption

## Symbol-specific runtime scenarios
### _QLSystemAsyncNode
- Drive `_QLSystemAsyncNode` with a null task, cancelled future, or missing worker input; expect a runtime failure on the actual execution path.
- Drive `_QLSystemAsyncNode` with a late completion after cancellation; expect the launch harness to observe correct failure propagation and cleanup.
- Drive `_QLSystemAsyncNode` with a message that cannot be decoded or deserialized; expect the live async path to reject it at runtime.
- Drive `_QLSystemAsyncNode` under repeated launches or allocation pressure; expect timeout/backpressure or out-of-memory handling rather than silent corruption.

### _QLSystemAsyncNodeState
- Drive `_QLSystemAsyncNodeState` with a null source value or missing listener; expect the live update path to surface the failure during execution.
- Drive `_QLSystemAsyncNodeState` with a cyclic/self-referential dependency chain; expect cycle detection or a controlled runtime error during launch.
- Drive `_QLSystemAsyncNodeState` with duplicate subscriptions or repeated emissions of the same value; expect the change-notification path to remain deterministic at runtime.
- Drive `_QLSystemAsyncNodeState` after disposal or teardown, then emit again; expect a stale-handle failure to surface instead of mutating dead state.

### _QLSystemRateLimitNodeState
- Drive `_QLSystemRateLimitNodeState` with a null source value or missing listener; expect the live update path to surface the failure during execution.
- Drive `_QLSystemRateLimitNodeState` with a cyclic/self-referential dependency chain; expect cycle detection or a controlled runtime error during launch.
- Drive `_QLSystemRateLimitNodeState` with duplicate subscriptions or repeated emissions of the same value; expect the change-notification path to remain deterministic at runtime.
- Drive `_QLSystemRateLimitNodeState` after disposal or teardown, then emit again; expect a stale-handle failure to surface instead of mutating dead state.

### _buildSystem
- Drive `_buildSystem` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildSystem` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildSystem` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildSystem` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.
- Make a future fail after cancellation or after the owning scope is gone so the executed async path must propagate the error cleanly.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
