# `src/ui/quantum_field_ui_engine.dart`

**Doc reference:** `docs/src/ui/quantum_field_ui_engine.dart.md`

## File profile
- Lines: 855
- Classes: QLFieldUIState, QLSliderUIState, QLReactiveTextBridge, QLRawTextInput, _QLRawTextInputState, QLRawToggle, _QLRawToggleState, QLRawOption
- Enums: none detected
- Notable functions: _onEngineDataChanged, _onFlutterUiChanged, dispose, initState, _checkEmptyState, _onEngineStateFlagsChanged, dispose, build, initState, _syncFocus

## Existing docs snapshot
- `src/ui/quantum_field_ui_engine.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- layout collapse under tight constraints
- gesture/hit-test drift after rebuilds
- overdraw and repaint churn
- semantics regression and focus loss

## Selected scenarios
- `71249b4c-0e46-537c-86b2-357ee9884dc6` — Quantum Field Ui Engine: public contract remains stable under valid input (critical)
- `7b1e6b6c-ecd0-58e5-9b86-28433185b8b8` — Quantum Field Ui Engine: invalid or malformed input is rejected cleanly (critical)
- `4153ee76-baa7-5167-9114-c6b031de01e8` — Quantum Field Ui Engine: re-entrant calls do not corrupt internal state (high)
- `b2e814c8-ca15-55e9-848e-e557804bdf2d` — Quantum Field Ui Engine: dispose/close/teardown releases resources deterministically (high)
- `18513c1f-75fe-5092-8ec5-ac39e690fcc3` — Quantum Field Ui Engine: hot-path behavior stays within the runtime budget (high)
- `81249466-1d17-531d-9b7d-5b82cd0ebbf2` — Quantum Field Ui Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.