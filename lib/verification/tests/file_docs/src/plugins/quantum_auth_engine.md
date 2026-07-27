# `src/plugins/quantum_auth_engine.dart`

**Doc reference:** `docs/src/plugins/quantum_auth_engine.dart.md`

## File profile
- Lines: 1748
- Classes: AuthException, AuthResult, SessionContext, AuthRequest, AuthChallenge, AuthCapabilities, AuthPolicy, AuthSecretStore
- Enums: AuthProvider, OtpChannel, AuthChallengeType, AuthChallengeState, SecurityScope
- Notable functions: toString, toJson, _strings, hasRole, hasPermission, hasFeature, hasSubscription, claim, toJson, init

## Existing docs snapshot
- `src/plugins/quantum_auth_engine.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- least-privilege enforcement regression
- grant/revoke snapshot mismatch
- audit leakage
- unexpected allow on edge inputs

## Selected scenarios
- `57a95f52-8e8c-5b00-a716-08b4130389a7` — Quantum Auth Engine: public contract remains stable under valid input (critical)
- `c1faf58e-9007-5060-b079-846077a44a58` — Quantum Auth Engine: invalid or malformed input is rejected cleanly (critical)
- `fb3bd75c-87eb-56f4-8426-910b8e3d79aa` — Quantum Auth Engine: re-entrant calls do not corrupt internal state (high)
- `ca1e53d2-0c65-5e13-a255-6357b216b546` — Quantum Auth Engine: dispose/close/teardown releases resources deterministically (high)
- `eb0b9133-6762-5456-b1f0-b0d35eb1d7cc` — Quantum Auth Engine: hot-path behavior stays within the runtime budget (high)
- `c5e4946f-b986-512d-b956-df25a9cbf20f` — Quantum Auth Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.