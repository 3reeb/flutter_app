# Action tests

## What these tests cover
Compile-time contracts for action_core subtypes: button, icon_button, chip, gesture,
hover, focus, long_press, double_tap, and raw pointer nodes.
Verifies that __subType is injected correctly and all handler/prop values survive compilation.

## Files

| File | ID | What it tests |
|------|-----|---------------|
| action_001_001.json | action-001-button-intent | button __subType + intent + onTap |
| action_002_002.json | action-002-button-disabled-binding | disabled state binding |
| action_003_003.json | action-003-icon-button | icon_button __subType + icon prop |
| action_010_010.json | action-010-gesture-on-tap | gesture + onTap action ref |
| action_011_011.json | action-011-gesture-multi-event | gesture with onTap + onLongPress + onDoubleTap |
| action_020_020.json | action-020-long-press-delay | long_press durationMs prop |
| action_021_021.json | action-021-double-tap | double_tap onDoubleTap handler |
| action_030_030.json | action-030-hover-enter-leave | hover onEnter + onLeave |
| action_040_040.json | action-040-focus-blur | focus onFocus + onBlur |
| action_050_050.json | action-050-chip-selected | chip selected binding + onToggle |
| action_090_090.json | action-090-bare-action-type | bare action type with no __subType |
