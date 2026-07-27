# src/runtime/quantum_test_engine_shared.dart

## Overview

Shared manifest, row, result, issue, and report model used by generated tests and tooling.

## Runtime contract

- Manifest path: `docs_tests/yaml/by-file/src/runtime/quantum_test_engine_shared.yaml`
- Profile: `runtime-core`
- Declared symbols: QuantumTestSourceMetadata, QuantumTestRowSpec, QuantumTestGroupSpec, QuantumTestSupplementSpec, QuantumTestManifest, QuantumTestCaseSpec, QuantumTestIssue, QuantumTestResult, QuantumTestReport, QuantumTestContext, QuantumTestStatus, QuantumTestPhase (with the reserved-keyword-safe `_assert` phase) …

## Why it exists

This file is part of the central test-engine stack. It supports YAML-driven discovery, strict validation, and compact, human-readable reporting.

## Related files

- `test/support/quantum_generated_suite.dart`
- `tool/generate_quantum_tests.dart`
- `docs/test-engine/QUANTUM_TEST_ENGINE.md`
