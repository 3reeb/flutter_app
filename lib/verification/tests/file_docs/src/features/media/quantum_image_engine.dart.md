# `src/features/media/quantum_image_engine.dart`

**Doc reference:** `docs/src/features/media/quantum_image_engine.dart.md`

## File profile
- Lines: 424
- Classes: QLImageResolver, QLDefaultCdnResolver, QuantumImagePipeline, QLImage, _QLImageState, _QLHardwareImagePainter
- Enums: none detected
- Notable functions: rewrite, rewrite, _fetchResolverBytes, _fetchBytes, _zeroCopyDecode, _cacheImage, _markUsed, _evictIfNeeded, initState, _decodePlaceholder

## Existing docs snapshot
- `src/features/media/quantum_image_engine.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- dense rendering jank
- hover/selection desynchronization
- numeric edge cases destabilizing paint
- buffer retention during export or snapshot

## Selected scenarios
- `4029576d-c0ce-5700-9387-ed9ceb950999` — Quantum Image Engine: public contract remains stable under valid input (critical)
- `6b1298e1-bf6b-5b00-a59b-d303e50c0113` — Quantum Image Engine: invalid or malformed input is rejected cleanly (critical)
- `d62011aa-79fb-5946-9fee-074f52c744af` — Quantum Image Engine: re-entrant calls do not corrupt internal state (high)
- `5cd12116-bb39-5cd9-83a0-09bc7d2e6fa0` — Quantum Image Engine: dispose/close/teardown releases resources deterministically (high)
- `87f4ed0c-b7e0-5e9e-8e10-0b17ed12b8b1` — Quantum Image Engine: hot-path behavior stays within the runtime budget (high)
- `670eb16a-02dd-53ef-87b5-4a5db25484c6` — Quantum Image Engine: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.