# 20 — CI Commands & Regression Reference

The exact commands used to run and enforce these tests in CI.

---

## 1. Local Development Checks

### Run only tests matching a category
```bash
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "compile_time"
```

### Run specific critical tests
```bash
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "critical"
```

### Run all execution/E2E tests (longest running)
```bash
flutter test lib/test/generated/sdui_json_runtime_behavior_test/ --name "execution"
```

---

## 2. CI Pipeline Enforcement

The CI server MUST run the full suite.

```bash
flutter test lib/test/generated/sdui_json_runtime_behavior_test/
```

If any structural contract changes, `expected` snapshots will fail.
If any runtime behavior changes, `executionSteps` will fail.

---

## 3. Dealing with regressions

When a new bug is found:
1. Write a minimal JSON reproduction matching the issue.
2. Tag it with the issue number in `__meta.issue` (e.g. `ISS-105`).
3. If it causes a crash, use `expectError`.
4. Run the test to watch it fail.
5. Fix the VM/engine.
6. Run the test to watch it pass.
