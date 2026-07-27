# Cross-cutting test matrix

This document defines the shared matrix that file-specific tests should inherit.

## Required groups

- smoke
- edges
- integration
- regression
- performance
- lazy-load
- cache
- compatibility
- serialization
- platform
- input
- hydration
- layout
- security
- registry
- routing

## Shared axes

- input shape: null, empty, single-item, multi-item, mixed-type, duplicate, legacy-shape, malformed, large-batch
- execution phase: cold, warm, cached, invalidated, replayed, deferred, eager
- observed outcome: accept, reject, normalize, reuse, evict, defer, round-trip, fallback
- measurement axis: latency, allocation count, cache hit rate, event order, recompute count
- platform axis: io, web, stub, native, shared

## Shared case row schema

```yaml
- id: <stable-test-id>
  purpose: <why this exists>
  target_symbols: [<symbols>]
  setup: <fixtures and mocks>
  input: <the fixture shape>
  body: <the action>
  expected: <observable result>
  assertions: [<observable assertions>]
  metrics: [<performance or memory metrics>]
  risks: [<regression traps>]
  cleanup: <cleanup step>
```

## Expansion rule

Generators should expand each row across the local axes only when the file spec says the branch is safe to multiply.

## SDUI JSON matrix

| Fixture | Structure | Notes |
| --- | --- | --- |
| `omni_cores_catalog.json` | flat cases | source-derived core catalog |
| `omni_cores_nested_catalog.json` | nested groups + cases | mirrors architecture, includes recursive groups |
| `sdui_runtime_contract.json` | flat cases | runtime engine and registry checks |
| `sdui_runtime_nested_contract.json` | nested groups + cases | adds compositional assertions and path checks |
| `sdui_json_schema_contract.json` | flat cases | validates the manifest format itself |
