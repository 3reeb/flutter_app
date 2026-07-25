# Quantum Omega Studio

This package includes the full Quantum Flutter app plus a responsive SDUI studio in `main.dart`.

## What changed
- Added a **Paste JSON** button that reads from clipboard and inserts SDUI JSON into the editor.
- Added **Format**, **Copy JSON**, **Export JSON**, and **Export PNG** actions.
- Made the editor responsive for both desktop and mobile layouts.
- Added a self-contained `downloader.dart` helper so export works without the missing import.

## How the JSON workflow behaves
1. Paste JSON into the editor with the toolbar button.
2. The app sanitizes common clipboard wrappers like Markdown code fences.
3. The JSON is parsed and compiled by `QLCompiler`.
4. Valid content can be exported as a `.json` file or rendered to PNG.

## Notes
- On desktop/web the export helper triggers a file download.
- On iOS/Android it writes to a temporary export path and still returns a usable file path for the app to report.
