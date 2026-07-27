# `src/runtime/quantum_sdui_engine.dart`

**Doc reference:** `docs/src/runtime/quantum_sdui_engine.dart.md`

## File profile
- Lines: 1222
- Classes: QuantumSduiException, SduiEncryptedPayload, SduiKeyStore, SduiReplayGuard, _AesEngine, QuantumSduiEngine, QLApiRequest, QLApiResponse
- Enums: none detected
- Notable functions: toString, toJson, toString, registerKey, deriveAndRegister, registerBase64, hasKey, removeKey, clear, claimNonce

## Existing docs snapshot
- `src/runtime/quantum_sdui_engine.dart`
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
- `155226ac-0b60-562e-ad4d-40e41ad58eea` — Quantum Sdui Engine: public contract remains stable under valid input (critical)
- `cae59240-96f0-522e-9a46-9da51775eb7e` — Quantum Sdui Engine: invalid or malformed input is rejected cleanly (critical)
- `e5cdba81-eee0-5ee9-8021-b585ab444157` — Quantum Sdui Engine: re-entrant calls do not corrupt internal state (high)
- `3390a660-80f6-539f-9052-39a088a037c4` — Quantum Sdui Engine: dispose/close/teardown releases resources deterministically (high)
- `30abfc93-dfd3-5587-adc1-de6f6976b60b` — Quantum Sdui Engine: hot-path behavior stays within the runtime budget (high)
- `8037ddf6-d9d7-5be9-b9c4-14f1b34386b6` — Quantum Sdui Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.