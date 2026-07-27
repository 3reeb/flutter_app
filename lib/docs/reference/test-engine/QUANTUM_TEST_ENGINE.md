# Quantum Test Engine

The Quantum test engine is the central, YAML-driven test layer for the codebase.
It is designed to do three jobs at the same time:

1. discover and validate test manifests
2. expand each manifest row into a strict, stable case
3. keep the final report compact so only important details are visible

## What it reads

The engine loads manifests from `docs_tests/yaml/by-file/`.
Each manifest records:

- source file path
- source hash and line count
- declared imports and exported surface names
- groups and rows of test intent
- coverage targets, presets, and regeneration triggers
- supplements for larger or more complex runtime files

## What it runs

Each row records:

- a stable id
- a purpose statement
- setup and input notes
- the body of the intended test action
- the expected outcome
- assertions, metrics, risks, and cleanup notes

The engine uses those rows to build a full test matrix. A row can be skipped, passed, failed, or errored, and each result keeps the same id so humans and automation can trace it back to the manifest and the source file.

## Important reporting rule

The report intentionally removes noise.
Long strings and very large maps are truncated so the output shows the important details only:

- the row id
- the file and group
- the pass/fail state
- the error summary, if any
- the duration
- compact details that help diagnose the issue

## Test generation flow

1. `tool/generate_quantum_tests.dart` walks the YAML catalog.
2. It writes one generated Dart test shell per source file.
3. Each shell imports the shared test suite helper.
4. The helper validates the manifest and source contract.
5. The central engine can later be extended with file-specific executors.

## Why this is strict

The suite is meant to catch hidden drift:

- missing source symbols
- duplicate ids
- missing groups or rows
- unsupported platform behavior
- noisy or overly large diagnostics
- executor crashes that should not stop the full run

That makes it useful both as a test generator input and as a quality gate for the manifest layer itself.
