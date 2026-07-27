# Data and state tests

## What these tests cover
Compile-time contracts for store_provider wrapping, data_core subtypes (repeat, slice, stream, diff, paginated),
hook_core subtypes (atom, effect, interval), and system_core timer.

## Files

| File | ID | What it tests |
|------|-----|---------------|
| data_state_001_001.json | ds-001-state-wraps-to-store-provider | State field wraps to store_provider |
| data_state_002_002.json | ds-002-nested-state-structure | Nested initialState preserves structure |
| data_state_010_010.json | ds-010-data-repeat-minimal | Minimal data:repeat |
| data_state_011_011.json | ds-011-data-repeat-card-template | Repeat with nested card template |
| data_state_020_020.json | ds-020-data-slice-offset-limit | data:slice offset + limit |
| data_state_030_030.json | ds-030-data-stream-channel | data:stream with channel binding |
| data_state_040_040.json | ds-040-hook-atom-default-value | hook:atom key + defaultValue + persist |
| data_state_050_050.json | ds-050-hook-effect-deps | hook:effect deps array + run action |
| data_state_060_060.json | ds-060-system-timer-on-complete | system:timer durationMs + onComplete |
| data_state_090_090.json | ds-090-paginated-missing-page-size | paginated without pageSize must throw |
| data_state_091_091.json | ds-091-data-diff-missing-key-by | diff without keyBy must throw |
