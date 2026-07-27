# `src/foundation/quantum_json_dsl.dart`

**Doc reference:** `docs/src/foundation/quantum_json_dsl.dart.md`

## File profile
- Lines: 1125
- Classes: QJsonTemplateEngine_D, _TemplateRecord, _TemplateDrivenPlugin
- Enums: none detected
- Notable functions: toMap, buildWidget, defineMatrixLayoutJson, _extractName, _extractDefaultProps, defineTemplate, defineAllJson, defineAliasJson, defineAliasesJson, defineOmniRegistryJson

## Existing docs snapshot
- `src/foundation/quantum_json_dsl.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- malformed document acceptance
- deep nesting or alias blowups
- encoding and BOM handling
- duplicate declaration ambiguity

## Selected scenarios
- `8b7f6102-f668-5b52-8bc4-2d8ffbc562d0` — Quantum Json Dsl: public contract remains stable under valid input (critical)
- `6939ce91-e1c2-560b-b218-bd239d7f4730` — Quantum Json Dsl: invalid or malformed input is rejected cleanly (critical)
- `c7ce1c54-f45e-577a-9ccd-3cdb12a99866` — Quantum Json Dsl: re-entrant calls do not corrupt internal state (high)
- `27336a56-04b6-5ab3-886f-92e526aadbc6` — Quantum Json Dsl: dispose/close/teardown releases resources deterministically (high)
- `08988e92-ae11-55d0-b641-fdcab22194ff` — Quantum Json Dsl: hot-path behavior stays within the runtime budget (high)
- `82467fa6-a70b-5a9c-bb90-e2ee8dfc03ee` — Quantum Json Dsl: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.