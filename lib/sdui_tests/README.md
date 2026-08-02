# Quantum Test Engine (QTE)

A powerful, self-contained SDUI test harness driven entirely by JSON.
Each `.test.json` file is a complete, standalone test case.

## Quick Start

```dart
// In your flutter_test file:
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'engine/qte.dart';

void main() {
  testWidgets('button basic', (tester) async {
    final jsonStr = await rootBundle.loadString('lib/sdui_tests/tests/button_basic.test.json');
    final result = await qteRunJsonString(jsonStr, tester, config: QTERunnerConfig(verbose: true));
    expect(result.passed, isTrue, reason: result.steps
      .expand((s) => s.assertions)
      .where((a) => !a.passed)
      .map((a) => a.toString())
      .join('\n'));
  });
}
```

## JSON Test File Structure

```
{
  "$schema": "quantum://test-engine/v1",
  "id":          "dot.namespaced.id",
  "title":       "Human readable title",
  "viewport":    { "width": 390, "height": 844 },
  "sdui":        { ... QLBlueprint JSON ... },
  "initialState":{ "key": "value" },
  "env":         { "envKey": "value" },
  "performance": { "maxFirstFrameMs": 16, "trackFrames": true },
  "steps":       [ ... StepDef[] ... ],
  "teardown":    { "clearState": true }
}
```

## Interaction Types

| Type | Description |
|---|---|
| `tap` | Single tap at widget center (or offset) |
| `double_tap` | Double tap |
| `long_press` | 500ms long press |
| `hover` / `unhover` | Mouse hover enter/leave |
| `drag` | Drag from→to offset relative to widget center |
| `scroll` | Scroll by delta {dx, dy} |
| `type` | Enter text into field |
| `clear_text` | Clear field content |
| `resize` | Drag resize handle to newWidth/newHeight |
| `key_press` | Keyboard key with optional modifiers |
| `right_click` | Secondary mouse button |
| `zoom` / `pinch` | Two-finger scale gesture |
| `trigger_action` | Call a QuantumVM action by name |
| `set_state` | Set QLDataStore keys directly |
| `merge_state` | Merge map into QLDataStore |
| `toggle_state` | Toggle boolean key |
| `wait` | Wait N milliseconds |
| `navigate` | Push named route |
| `wait_for_signal` | Wait until store key = expected value |

## Assertion Types

### UI Geometry
`widget_exists`, `widget_not_exists`, `widget_width`, `widget_height`,
`widget_size`, `widget_offset`, `widget_visible`, `widget_not_visible`,
`widget_color`, `widget_background_color`, `widget_border_radius`,
`widget_opacity`, `widget_text`, `widget_text_contains`, `widget_text_style`,
`widget_count`, `widget_enabled`, `widget_disabled`, `widget_focused`,
`widget_scrollable`, `widget_scroll_offset`

### State
`state_equals`, `state_not_equals`, `state_contains`, `state_type`,
`state_null`, `state_not_null`, `state_list_length`,
`state_greater_than`, `state_less_than`, `state_matches_regex`

### Reactive / Signals
`signal_emitted`, `signal_value`, `reactive_rebuilt`,
`store_key_changed`, `action_called`, `action_result`

### Performance
`first_frame_under_ms`, `rerender_under_ms`, `no_frame_drops`,
`memory_under_mb`, `memory_delta_under_mb`, `rasterize_under_ms`, `no_jank`

### Interaction Behaviors
`hover_triggered`, `drag_completed`, `scroll_reached_end`,
`animation_completed`, `portal_opened`, `portal_closed`

## Matchers
`equals`, `not_equals`, `gt`, `gte`, `lt`, `lte`,
`between` (needs `min`+`max`), `contains`, `starts_with`, `ends_with`,
`matches_regex`, `is_null`, `is_not_null`, `is_true`, `is_false`

## Target Selectors
| `by` value | Description |
|---|---|
| `key` | Flutter `ValueKey` |
| `text` | Widget text content |
| `type` | Widget runtime type name |
| `semanticLabel` | Semantics label |
| `testId` | `ValueKey('__qte_testId_...')` |
| `path` | Dot-separated key path |

## Engine Files

| File | Role |
|---|---|
| `qte_schema.dart` | All strongly-typed DTOs — no `dynamic` |
| `qte_validator.dart` | Pre-run JSON validation with rich errors |
| `qte_render_probe.dart` | Reads real RenderObject geometry, color, text |
| `qte_reactive.dart` | QLDataStore listener, signal event recording |
| `qte_performance.dart` | Frame timing, memory snapshots, jank detection |
| `qte_interaction.dart` | Executes every interaction type |
| `qte_assertion.dart` | Evaluates every assertion type |
| `qte_report.dart` | Structured pass/fail, JSON, JUnit XML reports |
| `qte_host_widget.dart` | Test host: fixed viewport + seeded QLDataStore |
| `qte_runner.dart` | Master orchestrator — runs the full test lifecycle |
| `qte.dart` | Barrel export |

## Example Tests

| File | What it covers |
|---|---|
| `button_basic.test.json` | Render, geometry, tap, state update, performance |
| `form_journey.test.json` | Full user journey, field input, validation, success |
| `layout_resize.test.json` | Drag, resize, scroll, hover, geometry constraints |
| `reactive_data.test.json` | Data binding, computed values, signals, conditional rendering |
