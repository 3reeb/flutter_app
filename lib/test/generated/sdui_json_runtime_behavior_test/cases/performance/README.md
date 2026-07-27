# Performance tests

## What these tests cover
Compile-time contracts for trees that are wide (many siblings), deep (approaching the AST overflow guard),
have large repeat templates, or use nested macro expansion.
These tests verify correctness under load — not wall-clock timing.

## Files

| File | ID | What it tests |
|------|-----|---------------|
| perf_001_001.json | perf-wide-20-siblings | 20 sibling text nodes in one row |
| perf_002_002.json | perf-repeat-template-normalized | Repeat template normalizes correctly at compile time |
| perf_003_003.json | perf-macro-3-levels-deep | Macro expanded 3 levels deep |
| perf_004_004.json | perf-mixed-100-node-page | Page with 100 nodes in mixed layout |
| perf_005_005.json | perf-deep-8-levels | 8-level deep nesting compiles without error |
