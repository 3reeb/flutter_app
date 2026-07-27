# sdui_json_tests

This tree is the SDUI JSON test-documentation mirror.

It is intentionally separated from the executable JSON manifests under `test/generated/sdui_json_runtime_behavior_test/cases/` so the coverage plan can grow without disturbing the live suite.

## What this tree is for

- pinning the SDUI JSON contract to the actual runtime surface
- covering small nodes, nested nodes, and large mixed compositions in one plan
- tracking the full omni-core subtype catalog and the compile-time DSL operators
- pairing manifest documentation with runnable Dart behavior tests for normalization, snapshots, operator transforms, and negative guards
- documenting what the JSON suite should protect when the runtime changes

## Folder layout

- `cross-cutting/` — shared coverage rules, audit notes, and the coverage ladder
- `yaml/` — machine-readable manifests that describe the SDUI JSON test families

## Test philosophy

This is not a happy-path checklist.

The plan deliberately covers:

- bare nodes before any helpers are applied
- colon-type normalization and `props.__subType` routing
- slot, env, style, name, and debug-path preservation
- every omni-core family and subtype branch
- compile-time operators such as `$define`, `$let`, `$if`, `$repeat`, `$call`, `$switch`, `$async`, `$stream`, `$machine`, `$portal`, `$watch`, `$try`, `$layout`, `$compose`, `$apply`, `$scope`, `$spread`, `$throttle`, `$debounce`, `$parallel`, `$reactive_map`, and `$classes`
- the state and pipeline layers that the bindings depend on
- large nested trees that combine data, layout, actions, overlays, control flow, and reactive bindings
- intentional edge cases like empty subtype catalogs, sparse templates, routing-only cores, wrapper nodes that collapse to children, and AST-overflow guards

## Runnable runtime behavior suite

The production runner now lives in `test/generated/sdui_json_runtime_behavior_test/` and discovers many JSON case files recursively.

Each case file supplies the input SDUI JSON plus the exact expected compiled blueprint snapshot. That keeps the suite real: the compiler output, not a hand-written assertion, becomes the source of truth.

## How to read it

1. start with the cross-cutting docs to see the coverage pillars
2. read the YAML index to see the manifest set at a glance
3. expand each YAML family into concrete Dart tests when you generate runnable coverage
4. keep the manifests in sync with `docs/overview/SDUI_RUNTIME_SPEC.md`, the runtime sources, and the recursive JSON fixtures
