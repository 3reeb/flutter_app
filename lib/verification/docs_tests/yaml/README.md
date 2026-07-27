# docs_tests/yaml

This folder contains machine-readable YAML test specifications generated from the Markdown test docs.

## How to use it

1. read the base file spec under `by-file/`
2. read any supplement specs for large files
3. use the shared template and group catalog when expanding the YAML into Dart test code
4. regenerate the matching YAML whenever a source file's public surface or contract changes

## Why this exists

The Markdown layer explains the contract in human-readable form.
The YAML layer turns that contract into a reusable test matrix with stable identifiers, observable inputs, expected outcomes, and update-detection metadata.

## Structure

- `by-file/` — one manifest YAML per source file, plus optional supplements for large files.
- `shared/` — reusable templates, group definitions, axis catalogs, and SDUI JSON test templates.
- `INDEX.yaml` — machine-readable catalog of every generated YAML spec.
- `shared/sdui_case_template.yaml` — template for executable SDUI JSON contract cases.
