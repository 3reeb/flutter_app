# 09 — Folder Structure

Canonical test folder layout, naming rules, and how to add new categories.

---

## Full folder tree

```
lib/test/generated/sdui_json_runtime_behavior_test/
├── sdui_json_runtime_behavior_test.dart   ← test runner (do not modify)
├── README.md                              ← high-level guide
└── cases/
    ├── README.md                          ← category map (keep updated)
    │
    ├── basic/                             ← L0–L2: bare strings, single nodes
    │   ├── README.md
    │   └── basic_NNN_NNN.json
    │
    ├── compile_time/                      ← $let, $apply, $if, $classes, $switch
    │   ├── README.md
    │   └── compile_time_NNN_NNN.json
    │
    ├── operators/                         ← all other authoring operators
    │   ├── README.md
    │   └── operators_NNN_NNN.json
    │
    ├── state_and_pipeline/                ← state wrapping, pipeline, store
    │   ├── README.md
    │   └── state_and_pipeline_NNN_NNN.json
    │
    ├── nested/                            ← complex multi-layer compositions
    │   ├── README.md
    │   └── nested_NNN_NNN.json
    │
    ├── failure/                           ← expected compile failures
    │   ├── README.md
    │   └── failure_NNN_NNN.json
    │
    ├── widget/                            ← NEW: sizing, drag, resize, split, field
    │   ├── README.md
    │   └── widget_NNN_NNN.json
    │
    ├── action/                            ← NEW: button, gesture, hover, focus
    │   ├── README.md
    │   └── action_NNN_NNN.json
    │
    ├── data_state/                        ← NEW: repeat, slice, stream, atom, effect
    │   ├── README.md
    │   └── data_state_NNN_NNN.json
    │
    ├── performance/                       ← NEW: wide/deep trees, macro expansion
    │   ├── README.md
    │   └── perf_NNN_NNN.json
    │
    ├── memory/                            ← NEW: scope isolation, macro leak, ref sharing
    │   ├── README.md
    │   └── memory_NNN_NNN.json
    │
    └── issue/                             ← NEW: regressions pinned to issue IDs
        ├── README.md
        └── issue_NNN_NNN.json
```

---

## Naming rules

### File naming

```
<category>_<NNN>_<NNN>.json
```

- `NNN` is zero-padded to 3 digits: `001`, `002`, ..., `099`, `100`, `101`
- The double number is conventional (matches existing files); both parts are the same by default
- Exception: if a file is a variant of another, use different second number: `widget_005_006.json`

### ID naming (inside `__meta.id`)

```
<category>-<NNN>-<kebab-description>
```

Examples:
- `widget-001-fixed-size`
- `action-010-gesture-on-tap`
- `ds-040-hook-atom-default-value`
- `perf-wide-50-children`
- `memory-003-store-no-double-wrap`
- `issue-007-repeat-missing-bind`

IDs must be globally unique across all files in all folders.

---

## README.md per folder

Each folder must have a `README.md` with this format:

```markdown
# <Category> tests

## What these tests cover
<one paragraph>

## Files

| File | ID | What it tests |
|------|-----|---------------|
| widget_001_001.json | widget-001-fixed-size | Fixed width/height props round-trip |
| widget_002_002.json | widget-002-string-sizing | String width/height values |
...
```

Update this table every time you add a file.

---

## Adding a new category

1. Create the folder: `cases/<new_category>/`
2. Create `cases/<new_category>/README.md` using the template above
3. Add the category to `cases/README.md`
4. Add test files named `<new_category>_001_001.json`
5. Run `flutter test` to confirm the runner discovers them

---

## Test runner discovery

The runner in `sdui_json_runtime_behavior_test.dart` calls `_discoverCases()`:
- Recursively walks `cases/` searching for `*.json` files
- Sorts by path (alphabetical = category order, then numeric order within category)
- Every JSON file is loaded as a test case

**Do not** put non-test JSON files in `cases/` subfolders. The runner will attempt to load them.

---

## Tag taxonomy

Use consistent tags to enable filtering with `flutter test --name`:

| Tag | Use for |
|-----|---------|
| `basic` | Bare primitives |
| `normalization` | Colon syntax, type resolution |
| `operator` | Any `$` operator |
| `let` | `$let` specifically |
| `apply` | `$apply` specifically |
| `classes` | `$classes` specifically |
| `state` | State wrapping |
| `store` | Store provider |
| `data` | data_core subtypes |
| `repeat` | data:repeat |
| `stream` | data:stream |
| `hook` | hook_core subtypes |
| `action` | action_core subtypes |
| `button` | action:button |
| `gesture` | action:gesture |
| `hover` | action:hover |
| `focus` | action:focus |
| `widget` | Sizing, layout constraint tests |
| `sizing` | Width/height props |
| `drag` | Draggable behavior |
| `resize` | Resizable behavior |
| `split` | box:split ratio/axis |
| `portal` | portal_core subtypes |
| `control` | control_core subtypes |
| `performance` | Large/deep/wide tree tests |
| `memory` | Scope isolation, leak tests |
| `issue` | Regression tests |
| `guard` | Error guard trips |
| `failure` | Expected compile failures |
| `nested` | Multi-level compositions |

---

## Complexity ladder (quick reference)

| Level | Folder | Key characteristic |
|-------|--------|--------------------|
| L0 | `basic` | Bare string/number |
| L1 | `basic` | Single node + 1 prop |
| L2 | `basic` | Single node + style |
| L3 | `basic` | 2–3 level children |
| L4 | `compile_time` | One operator |
| L5 | `state_and_pipeline` | State wrapping |
| L6 | `data_state` | data:repeat |
| L7 | `action` | Action + onTap descriptor |
| L8 | `nested` | Portal + data + action combined |
| L9 | `nested` | Full page with hooks + repeat + portal |
| L10 | `issue`/`failure` | Edge case / error guard |

---

## CI command reference

```bash
# Run all tests
flutter test lib/test/generated/sdui_json_runtime_behavior_test/

# Run only a category
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "widget"

# Run only critical issue regressions
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "issue"

# Run only performance contracts
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "perf"

# Run only memory contracts
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "memory"
```
