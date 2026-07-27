# `src/runtime/quantum_data_orchestrator.dart`

## What this file is
This file bootstraps manifests into live runtime state. It is the orchestration layer that connects schemas, data sources, slices, actions, and pipelines.

## Responsibilities
- Parse a raw manifest string or load a manifest asset.
- Register the module in the module registry.
- Register schemas into the schema registry.
- Register actions into the VM.
- Initialize data sources.
- Mount slices.
- Register slice pipelines.

## Boot flow
1. `bootstrapString()` parses the manifest safely through the isolate bridge.
2. `bootstrap()` resolves the namespace and registers the module.
3. Nested modules are recursively bootstrapped.
4. Schemas are registered both by local name and qualified namespace name.
5. Actions are wrapped and registered with the VM.
6. Data sources are initialized and bound to the store.
7. Slices are mounted and their pipelines are registered.

## Why this file matters for the new type system
The orchestrator is the place where schema declarations become runtime behavior. Once the schema compiler understands the expanded type system, the orchestrator automatically propagates that support to:
- slice pipelines
- local store bindings
- schema-driven actions
- partial fetches and projections

In other words, the orchestrator does not need to invent new field semantics; it only needs to make sure the schema blueprint reaches the right runtime consumers.

## Testing focus
- Confirm a manifest with nested modules bootstraps recursively.
- Confirm schema registration occurs under both local and qualified names.
- Confirm slice pipelines inherit the compiled schema and selected field lists.
- Confirm data sources bind into the store and refresh when configured to do so on mount.
