# Runtime execution test plan — runtime/omni_cores/text_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/text_core`
- Area: `text_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `b072c72ec8ba572ebc4657e12d7dba9d85e832e128487a85072c457fe248dda2`
- Line count: `189`

## Executable surface
- `_buildText`
- `_registerTextAliases`

## Launch-time failure targets
- null input
- malformed input
- boundary values
- resource pressure

## Symbol-specific runtime scenarios
### _buildText
- Drive `_buildText` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildText` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildText` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildText` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerTextAliases
- Drive `_registerTextAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerTextAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerTextAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerTextAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
