
# Quantum SDUI Power Test Engine

This engine is designed for **real render verification**, not just JSON parsing.

It does four things for every JSON file in a folder:

1. discovers the file automatically
2. compiles it through the SDUI compiler
3. renders it in a hidden probe surface
4. captures the pixels and flags blank or uniform frames

That means a case that renders to a white empty area is treated as a failure, even if no exception was thrown.

## Folder convention

Put your test cases in a folder like:

```text
sdui_tests/
  home.json
  auth/login.json
  dashboard/overview.json
```

The engine scans every `*.json` file recursively.

## How to write a test file

The file should be a normal SDUI JSON document. Optional test metadata can live at the top level using `__meta`, `__test`, `__expect`, `__viewport`, `__env`, or `__tags`.

Example:

```json
{
  "__meta": {
    "id": "home.desktop",
    "title": "Home Desktop",
    "tags": ["home", "desktop"],
    "viewport": { "width": 1440, "height": 1024, "pixelRatio": 1.0 },
    "background": "#0B1020",
    "allowSolidFill": false,
    "allowBlank": false,
    "timeoutMs": 8000
  },
  "type": "box:col",
  "style": "p-24 gap-16",
  "children": [
    {
      "type": "text:h1",
      "props": { "text": "Dashboard" }
    }
  ]
}
```

## Using the engine

```dart
final report = await QuantumSduiTestEngine.instance.runFolder(
  context,
  folderPath: 'sdui_tests',
  recursive: true,
  outputJsonPath: 'build/reports/sdui-report.json',
  outputImageDirectory: 'build/reports/screenshots',
);

debugPrint(report.toPrettyJson());
```

## What counts as a failure

A case fails when:

- JSON is invalid
- the compiler throws
- the render probe throws
- the frame is blank or uniform and blank frames are not allowed
- the render times out

## Why this catches the white-screen bug

A blank render can happen when the UI tree builds without throwing, but nothing meaningful paints.

This engine captures the rendered pixels and checks them directly. If the frame is just a uniform blank surface, the case fails with a render-health error.

## Report fields

The report includes:

- total cases
- passed / failed cases
- compile failures
- render failures
- blank-frame failures
- duration
- per-case error, stack trace, and optional screenshot path

## Recommended workflow

1. write JSON in `sdui_tests/`
2. run the folder test engine
3. inspect the report
4. fix the failing case
5. rerun until the whole folder is healthy

One broken screen does not stop the rest of the suite.
