# SDUI examples and health workflow

This studio now treats examples as first-class data.

## What the registry does
- Stores named SDUI examples inside the app session.
- Lets you load any example back into the editor.
- Lets you remove custom examples without affecting the rest of the suite.

## How health testing works
- Each example is parsed and compiled independently.
- Failures are stored per example, so one bad example does not stop the suite.
- The UI reports pass/fail counts and a summary message.
- The preview boundary is wrapped in `QLErrorBoundary` so render-time failures stay local to the selected preview.

## Copyable errors
- Parser and runtime errors are shown as selectable text.
- A copy action is available for the latest error and stack trace.
- This makes it easy to paste a failure directly back into chat for the next fix.

## Recommended workflow
1. Paste or load a JSON document.
2. Register it as an example when it is ready.
3. Run all health checks.
4. Fix only the example that failed.
5. Re-run the full suite to confirm the rest still passes.

## JSON test manifests

The health workflow is backed by JSON manifests in `test/sdui_json/`.
Those manifests pin the omni-core catalog, the SDUI runtime contract, and the JSON schema used by the test engine.
A manifest edit should normally be followed by a `flutter test` run so the new contract is validated end to end.

