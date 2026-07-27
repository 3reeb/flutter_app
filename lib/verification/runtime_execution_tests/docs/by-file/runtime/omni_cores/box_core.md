# Runtime execution test plan — runtime/omni_cores/box_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/box_core`
- Area: `box_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `cf9bfecea439451ed25257e137ce5f6f3350ed0404d9a5732577485d06954d1a`
- Line count: `718`

## Executable surface
- `_buildBox`
- `createRenderObject`
- `_registerBoxAliases`
- `performLayout`
- `_RenderMeasureNode`
- `_buildSmartScrollViewport`
- ... and 4 more

## Launch-time failure targets
- disposed context
- invalid constraints
- duplicate keys
- frame pressure

## Symbol-specific runtime scenarios
### _buildBox
- Drive `_buildBox` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildBox` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildBox` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildBox` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### createRenderObject
- Drive `createRenderObject` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `createRenderObject` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `createRenderObject` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `createRenderObject` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerBoxAliases
- Drive `_registerBoxAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerBoxAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerBoxAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerBoxAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### performLayout
- Drive `performLayout` with a null child, missing context, or disposed widget tree; expect the build/layout path to fail at runtime.
- Drive `performLayout` with invalid constraints, zero size, or an impossible geometry; expect launch-time layout/paint rejection.
- Drive `performLayout` with duplicate keys or repeated attachment in the same frame; expect the live widget tree to report a runtime failure.
- Drive `performLayout` with a large, dense, or rapidly changing UI payload; expect frame pressure to surface during execution instead of leaving stale visuals.

## Cross-cutting launch stressors
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
