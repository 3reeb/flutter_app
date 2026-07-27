# Runtime execution test plan — runtime/quantum_sdui_engine

This plan validates the file by running the code at runtime during app launch or launch-like harness execution.
It focuses only on execution-based failure behavior produced by real code paths in this file.

## Scope
- File: `lib/runtime/quantum_sdui_engine`
- Area: `quantum_sdui_engine`
- Mode: runtime execution only
- Static existence checks: excluded

## Source snapshot
- SHA-256: `b0783ba23b754cc4937d7fce6e6bc6b25156257118945acd84d859476de5bbe2`
- Line count: `1218`
- Imports:
  - `dart:async`
  - `dart:collection`
  - `dart:convert`
  - `dart:math`
  - `dart:typed_data`
  - `package:crypto/crypto.dart`
  - `package:flutter/foundation.dart`
  - `package:flutter/material.dart`
  - `package:http/http.dart`
  - `quantum_permissions.dart`
  - `package:quantum_layout/quantum.dart`
  - `../foundation/quantum_yaml_engine.dart`

## Executable surface
- `QLSduiWidget`
- `QuantumSduiEngine`
- `QuantumApiEngine`
- `QuantumSduiException`
- `SduiKeyStore`
- `SduiEncryptedPayload`
- ... and 44 more

## Launch-time failure targets
- malformed structured payload
- duplicate or recursive definitions
- empty/zero-value edge case
- oversized nested document
- cycle detection
- duplicate subscription

## Symbol-specific runtime scenarios
### QLSduiWidget
- Drive `QLSduiWidget` with a missing key, unknown route, or absent identifier; expect a live lookup failure rather than an implicit default.
- Drive `QLSduiWidget` with a null query or empty selector; expect the runtime to reject the request on execution, not at static analysis time.
- Drive `QLSduiWidget` with duplicate matches or conflicting candidates; expect deterministic resolution or a controlled error path.
- Drive `QLSduiWidget` after the source backing store has been cleared or disposed; expect stale lookup access to fail at runtime.

### QuantumSduiEngine
- Drive `QuantumSduiEngine` with a null or missing input and execute the live launch path; expect a runtime failure rather than a silent fallback.
- Drive `QuantumSduiEngine` with a malformed or wrong-type input; expect the executed code to reject it during startup.
- Drive `QuantumSduiEngine` with a boundary value such as empty, zero, or oversized data; expect deterministic edge-case behavior at runtime.
- Drive `QuantumSduiEngine` after repeated initialization or disposal; expect stale-state handling to stay deterministic during execution.

### QuantumApiEngine
- Drive `QuantumApiEngine` with a null request, malformed URL, or unsupported scheme; expect the transport layer to reject it at runtime.
- Drive `QuantumApiEngine` through a simulated timeout, connection drop, or refused socket; expect the launch path to surface the live network failure.
- Drive `QuantumApiEngine` with a malformed response body or invalid header set; expect decode or protocol validation to fail during execution.
- Drive `QuantumApiEngine` with a retry storm or repeated cancellation; expect bounded failure handling rather than a hanging startup path.

### QuantumSduiException
- Drive `QuantumSduiException` with a dependency that throws immediately; expect the failure boundary to capture the runtime exception on the live path.
- Drive `QuantumSduiException` with a null fallback or missing retry handler; expect the launch harness to observe failure propagation, not silent recovery.
- Drive `QuantumSduiException` with repeated error emissions from the same source; expect deterministic reporting and no recursive crash loop.
- Drive `QuantumSduiException` after the surrounding scope has been torn down; expect stale-error-boundary access to fail during execution.

## Cross-cutting launch stressors
- Feed the live path an empty `Uint8List`, then an oversized buffer, to verify byte-oriented code fails deterministically at runtime.
- Start the app with a disposed `BuildContext`, invalid constraints, or a duplicate-key subtree to exercise launch-time widget failure handling.
- Make a future fail after cancellation or after the owning scope is gone so the executed async path must propagate the error cleanly.
- Run boundary numeric cases such as `0`, `-1`, `double.nan`, and large magnitudes through the live math path to check runtime rejection.
- Exercise missing-file, permission-denied, and truncated-stream execution paths to ensure I/O failures are surfaced during startup.
- Use malformed UTF-8 or truncated encoded payloads so the live decode path throws where the code actually runs.

## Harness assertions
- The test must execute the real code path during launch or launch-like initialization.
- The test must use invalid, empty, malformed, duplicated, or resource-heavy inputs that the file can actually encounter.
- The test must observe runtime failure, rejection, or cleanup behavior instead of checking for symbols statically.
- The test must leave the launched state clean enough for the next execution attempt.
