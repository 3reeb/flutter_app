# Runtime execution test plan — runtime/omni_cores/decoration_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/decoration_core`
- Area: `decoration_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `4f67e027c057765ceb160c6b58f41c35982d51e3ab8c0797ece2c0427ec88e38`
- Line count: `218`

## Executable surface
- `_buildDecoration`
- `_registerDecorationAliases`

## Launch-time failure targets
- null input
- malformed input
- boundary values
- resource pressure

## Symbol-specific runtime scenarios
### _buildDecoration
- Drive `_buildDecoration` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildDecoration` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildDecoration` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildDecoration` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerDecorationAliases
- Drive `_registerDecorationAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerDecorationAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerDecorationAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerDecorationAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
