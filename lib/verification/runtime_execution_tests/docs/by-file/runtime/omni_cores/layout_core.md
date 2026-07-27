# Runtime execution test plan — runtime/omni_cores/layout_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/layout_core`
- Area: `layout_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `e185ccde0604b99cacaa1433fe408bcf709eedfd52a33c3c380f5e1e30d2d2e1`
- Line count: `991`

## Executable surface
- `_buildLayout`
- `_registerRichSpatialLayouts`
- `_registerLayoutAliases`
- `_buildDecorationRichText`

## Launch-time failure targets
- disposed context
- invalid constraints
- duplicate keys
- frame pressure

## Symbol-specific runtime scenarios
### _buildLayout
- Drive `_buildLayout` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildLayout` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildLayout` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildLayout` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerRichSpatialLayouts
- Drive `_registerRichSpatialLayouts` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerRichSpatialLayouts` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerRichSpatialLayouts` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerRichSpatialLayouts` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerLayoutAliases
- Drive `_registerLayoutAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerLayoutAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerLayoutAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerLayoutAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _buildDecorationRichText
- Drive `_buildDecorationRichText` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildDecorationRichText` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildDecorationRichText` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildDecorationRichText` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
