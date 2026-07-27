# `src/runtime/omni_cores/canvas_core.dart`

**Doc reference:** `docs/src/runtime/omni_cores/canvas_core.dart.md`

## File profile
- Lines: 283
- Classes: _QLVertexPlotPainter, _QLProceduralCanvasNode, _QLProceduralCanvasNodeState, _QLProceduralPainter
- Enums: none detected
- Notable functions: _buildCanvas, paint, shouldRepaint, initState, didUpdateWidget, _compile, _n, build, paint, shouldRepaint

## Existing docs snapshot
- `src/runtime/omni_cores/canvas_core.dart`
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
- `c08ae120-ec67-5e83-91fc-f114f78baf8c` — Canvas Core: public contract remains stable under valid input (critical)
- `62838b59-d242-5755-8bfa-22ee30c6e89e` — Canvas Core: invalid or malformed input is rejected cleanly (critical)
- `2f5190fe-0745-53c3-8074-8b75e6a0243d` — Canvas Core: re-entrant calls do not corrupt internal state (high)
- `cece1b4a-1b89-55eb-adc4-e86b4911fc32` — Canvas Core: dispose/close/teardown releases resources deterministically (high)
- `ad402147-7d46-5d98-ab69-e108d93a0c30` — Canvas Core: hot-path behavior stays within the runtime budget (high)
- `ec00b48c-bfe2-5323-86cf-d109fd41827f` — Canvas Core: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.