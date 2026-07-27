# SDUI Studio Guide

## Purpose
This screen is a JSON-first SDUI authoring surface for Quantum. It is designed to:
- paste native SDUI JSON quickly,
- validate it immediately,
- render it with the Quantum VM,
- export the same JSON back out,
- and export a PNG preview for fast visual sharing.

## Primary actions
- **Paste JSON**: reads clipboard text and inserts it into the editor.
- **Format**: prettifies valid JSON so it is easier to review.
- **Copy JSON**: copies the current editor content.
- **Export JSON**: saves the current valid JSON to a `.json` file.
- **Export PNG**: renders the current JSON to an image and downloads it.
- **Render**: forces a recompile/render pass.

## Responsiveness
- Desktop: editor and preview are shown side by side.
- Mobile: editor stacks above preview so the screen stays usable on narrower widths.

## Safety behavior
- Markdown fences are stripped from pasted JSON.
- Invalid JSON blocks export and render, so only valid content is emitted.
- The editor keeps the raw JSON text intact while the VM compiles a parsed copy.

## JSON-driven contract tests

The `test/sdui_json/` folder now holds executable JSON manifests. Each manifest can validate:
- source file shape,
- runtime snapshot export paths,
- subtype catalogs,
- and the JSON schema of the manifest itself.

Add a new JSON file under `test/sdui_json/` and the dynamic runner will pick it up automatically.

