# Runtime execution test plan — runtime/omni_cores/chart_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/chart_core`
- Area: `chart_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `d943caeeaf5b9e8400102abf33ca65b6c115d64c621edb9200637b902040a60c`
- Line count: `47`

## Executable surface
- `_buildChart`
- `_registerChartAliases`

## Launch-time failure targets
- null input
- malformed input
- boundary values
- resource pressure

## Symbol-specific runtime scenarios
### _buildChart
- Drive `_buildChart` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildChart` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildChart` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildChart` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerChartAliases
- Drive `_registerChartAliases` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerChartAliases` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerChartAliases` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerChartAliases` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
