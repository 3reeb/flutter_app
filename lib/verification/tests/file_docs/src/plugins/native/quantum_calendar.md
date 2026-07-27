# `src/plugins/native/quantum_calendar.dart`

**Doc reference:** `docs/src/plugins/native/quantum_calendar.dart.md`

## File profile
- Lines: 109
- Classes: CalendarEvent, DateRange, _DateRangeEventListCodec, _GetEventsBridge, _AddEventCodec, _AddEventBridge, QuantumCalendar
- Enums: none detected
- Notable functions: toMap, toMap

## Existing docs snapshot
- `src/plugins/native/quantum_calendar.dart`
- What this file is
- Dependencies
- Top-level declarations
- Important members and helpers
- How it works

## Runtime risk areas
- missing adapter fallback
- platform capability mismatch
- bridge detach/reattach ordering
- resource cleanup after failure

## Selected scenarios
- `6b3d9281-8c5e-52b1-acc0-67edd1bc8005` — Quantum Calendar: public contract remains stable under valid input (critical)
- `11fe2294-07fc-5f80-b3aa-f6158592e9c9` — Quantum Calendar: invalid or malformed input is rejected cleanly (critical)
- `6a4924bc-dfd1-512a-8363-f09c3629cb2a` — Quantum Calendar: re-entrant calls do not corrupt internal state (high)
- `9e624b2c-2fe8-5973-936e-5651650cf7ed` — Quantum Calendar: dispose/close/teardown releases resources deterministically (high)
- `f71c4872-3a26-57b2-bdb6-ee878affb2bd` — Quantum Calendar: hot-path behavior stays within the runtime budget (high)
- `deeea01a-7d1f-5916-bf1f-98961df5044f` — Quantum Calendar: memory usage stays bounded under repeated operations (medium)

## Notes for executable test construction
- Convert the YAML entries into unit, widget, integration, and benchmark tests as appropriate.
- Preserve teardown assertions and failure-path checks; do not trim them to happy paths.
- Treat the performance and memory budgets as minimum acceptance constraints, not decorations.