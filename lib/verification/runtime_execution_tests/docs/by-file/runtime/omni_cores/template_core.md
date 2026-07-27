# Runtime execution test plan — runtime/omni_cores/template_core

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/omni_cores/template_core`
- Area: `template_core`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `70c2785c566b09169529ec88485f68730df1c58091197880b80d9f9dc14f1021`
- Line count: `3101`

## Executable surface
- `_registerRichDesignSystemTemplates`
- `_buildTemplate`
- `_registerPowerFieldTemplates`
- `_registerBuiltInTemplates`
- `_registerGeneralBuiltInTemplates`
- `_registerTemplateAliases`
- ... and 16 more

## Launch-time failure targets
- malformed structured payload
- duplicate or recursive definitions
- empty/zero-value edge case
- oversized nested document
- cycle detection
- duplicate subscription

## Symbol-specific runtime scenarios
### _registerRichDesignSystemTemplates
- Drive `_registerRichDesignSystemTemplates` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerRichDesignSystemTemplates` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerRichDesignSystemTemplates` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerRichDesignSystemTemplates` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _buildTemplate
- Drive `_buildTemplate` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_buildTemplate` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_buildTemplate` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_buildTemplate` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerPowerFieldTemplates
- Drive `_registerPowerFieldTemplates` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerPowerFieldTemplates` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerPowerFieldTemplates` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerPowerFieldTemplates` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

### _registerBuiltInTemplates
- Drive `_registerBuiltInTemplates` with a null dependency or missing required input; expect the live launch path to fail at the exact point the object is created or registered.
- Drive `_registerBuiltInTemplates` with a malformed payload or wrong value type; expect runtime validation to reject it instead of silently constructing stale state.
- Drive `_registerBuiltInTemplates` with a duplicate identifier or repeated setup call; expect deterministic collision handling during execution.
- Drive `_registerBuiltInTemplates` with a boundary-value payload such as empty, zero, or oversized data; expect bounded failure or explicit handling under launch pressure.

## Cross-cutting launch stressors
- Re-run the file's main launch path with a null dependency and a malformed edge-case payload to keep the runtime-only contract covered.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
