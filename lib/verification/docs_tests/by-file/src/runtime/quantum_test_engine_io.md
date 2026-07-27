# lib/src/runtime/quantum_test_engine_io.dart

This file is covered by the central YAML-driven test engine.

## Purpose

File-system backed YAML discovery, manifest loading, and execution against injected runners.

## Test contract

The matching YAML manifest lives at `docs_tests/yaml/by-file/src/runtime/quantum_test_engine_io.yaml` and expands into strict row-level cases with stable ids, inputs, expected outcomes, and compact reporting.

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

file discovery, yaml parsing, executor routing, failure isolation, compatibility, performance
