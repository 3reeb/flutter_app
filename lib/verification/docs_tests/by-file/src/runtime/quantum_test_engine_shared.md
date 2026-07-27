# lib/src/runtime/quantum_test_engine_shared.dart

This file is covered by the central YAML-driven test engine.

## Purpose

Shared manifest, row, result, issue, and report model used by generated tests and tooling.

## Test contract

The matching YAML manifest lives at `docs_tests/yaml/by-file/src/runtime/quantum_test_engine_shared.yaml` and expands into strict row-level cases with stable ids, inputs, expected outcomes, and compact reporting. The shared model also keeps the phase enum safe from the reserved `assert` keyword by using `_assert` in the source contract.

## What the suite checks

- manifest discovery and loading
- strict validation of group and row metadata
- source contract drift through declared imports and symbols
- compact result reporting and issue redaction
- resilience when a row executor throws

## Important rules

- Every row needs a stable `id`.
- Every group needs at least one row.
- Large debug payloads are truncated in reports.
- Failure must be explicit and local to the row that failed.

## How it is used

1. the test harness loads the YAML manifest
2. the harness checks the source file and declared surface
3. the engine expands rows into executable test cases
4. the report keeps only the important details

## Coverage intent

serialization, validation, redaction, identity, reporting, compatibility
