# 10 — Runtime Execution Tests

How to author, name, and organize SDUI JSON test cases that go beyond blueprint parsing to execute real UI rendering, verify reactive data states, and simulate runtime effects.

---

## 1. Why Execution Tests?

Historically, the SDUI JSON runner only evaluated the **compiler contract** (verifying that the compiled blueprint matched the expected snapshot). 

With Runtime Execution Tests, the JSON runner now mounts the fully compiled `QLBlueprint` using a real `WidgetTester` via `QuantumVMRoot`. This means you can:
- Verify that a blueprint actually mounts without throwing rendering exceptions (e.g., layout errors or missing providers).
- Interact with the mounted widget tree (tapping buttons, entering text).
- Assert against the real-time `QLDataStore` state after an action fires.
- Ensure API connections or `$async` operations behave correctly during render.

---

## 2. Test Case Anatomy (Enhanced)

The base anatomy described in `02_SKILLS_WRITING_TESTS.md` remains the same, but we introduce a new top-level field `executionSteps`:

```json
{
  "__meta": {
    "id": "action-button-click",
    "title": "Button click increments store",
    "description": "Verify that tapping the button dispatches an action to update the state.",
    "tags": ["action", "state", "execution"],
    "allowBlank": false
  },
  "env": {
    "theme": "dark"
  },
  "input": {
    "type": "action:button",
    "props": {
      "text": "Increment",
      "onTap": { "type": "action", "name": "store.increment", "args": { "path": "count", "amount": 1 } }
    }
  },
  "expected": {
    "type": "action:button",
    "props": {
      "text": "Increment",
      "onTap": { "type": "action", "name": "store.increment", "args": { "path": "count", "amount": 1 } }
    },
    "debugPath": "root"
  },
  "executionSteps": [
    { "action": "pumpAndSettle" },
    { "action": "tap", "finder": { "type": "text", "match": "Increment" } },
    { "action": "pumpAndSettle" },
    { "action": "expectState", "path": "count", "equals": 1 }
  ]
}
```

---

## 3. The `executionSteps` Array

This array allows you to script the Flutter `WidgetTester` straight from JSON. The runner will execute these steps sequentially *after* successfully mounting the `input` blueprint.

### Supported Actions:

All runtime execution steps are validated before the test runs, so malformed steps fail fast with a clear error. The runner supports both the legacy list-form action payloads and the single-object form used by newer SDUI fixtures, which means `onTap`, `onLongPress`, `onDoubleTap`, and similar handlers can be written as either one action map or a pipeline array. Interaction finders search the full mounted tree first, then collapse to one visible hit-testable target before tapping or typing. That keeps execution real while still handling offscreen scroll targets and nested interactive shells.


#### `pump` / `pumpAndSettle`
Pumps the widget tree to trigger frame rendering.
```json
{ "action": "pumpAndSettle" }
```
```json
{ "action": "pump", "durationMs": 100 }
```

#### `tap`
Taps a widget matching the `finder`.
```json
{ "action": "tap", "finder": { "type": "text", "match": "Submit" } }
```

#### `enterText`
Enters text into a matching input field.
```json
{ "action": "enterText", "finder": { "type": "key", "match": "email-input" }, "text": "user@example.com" }
```

#### `expectText`
Asserts that a specific text string exists in the widget tree.
```json
{ "action": "expectText", "text": "Success!", "findsOne": true }
```

#### `expectState`
Asserts against the actual data residing in the `QuantumVM.instance.store`. This is crucial for verifying that actions modify the reactive state correctly.
```json
{ "action": "expectState", "path": "user.profile.name", "equals": "Alice" }
```

#### `repeat` / `group`
`group` nests a sequence of steps, and `repeat` replays the same nested steps several times. This is useful for multi-tap and looped interaction flows.

```json
{
  "action": "repeat",
  "times": 2,
  "steps": [
    { "action": "tap", "finder": { "type": "text", "match": "Increment" } },
    { "action": "pumpAndSettle" }
  ]
}
```

---

## 4. How the Runner Executes It

When you run `flutter test lib/test/generated/sdui_json_runtime_behavior_test/sdui_json_runtime_behavior_test.dart`:
1. It validates the JSON against `expected` just like before.
2. It wraps the blueprint in `QuantumVMRoot` and passes it to `tester.pumpWidget()`.
3. It iterates over your `executionSteps`, executing the `WidgetTester` equivalents.
4. If a step fails, the test fails, and the runner reports the exact step that threw the exception.

This provides full End-to-End (E2E) certainty that the SDUI JSON you authored translates into a fully working UI.


## Live geometry verification

Runtime execution cases can now assert geometry directly after interactions. The supported steps include `expectGeometry` and `expectOrder`, which read the live `RenderBox` geometry from the mounted tree. That makes it practical to test spacing regressions such as `justify-between`, centering, vertical stacking, and scroll-driven placement.
