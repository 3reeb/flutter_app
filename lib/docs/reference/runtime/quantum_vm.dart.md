# `src/runtime/quantum_vm.dart`

## What this file is
This is the framework VM and rendering runtime. It manages module registration, schema views, widget rendering, action dispatch, plugin metadata, caches, and a large amount of the framework’s compile-time-to-runtime translation work.

## What the VM does for schemas
The VM is not the schema compiler itself, but it is a major consumer of schema-shaped data. It exposes lazy schema views and cached schema slices so callers can read only the fields they need.

Important types:
- `QLSchemaSlice`
- `QLLazySchemaView`

`QLLazySchemaView` keeps schema field reads lazy and cached, which is useful when a large manifest or widget tree only needs a few fields at a time.

## Why this matters for the new field system
The VM frequently transports schema maps and schema metadata through its rendering and registry layers. That means the new schema field types matter here even when the VM is not parsing them directly:
- the VM can carry manifests that include `media`, `bigInt`, `smallInt`, `decimal`, `char`, `flags`, and `hasMany`
- lazy schema reads keep those manifests cheap to inspect
- cached schema slices reduce repeated allocations during rendering and introspection

## Core runtime features
- module registry and access policy handling
- plugin and manifest registration
- lazy schema lookup and cached field selection
- widget rendering and contextual prop access
- action dispatch and event wiring
- metadata snapshots for registry and core features

## Caching behavior
The VM keeps several caches to avoid repeated work:
- schema slices for field-level reads
- local manifest caches
- registry metadata snapshots
- various structure caches for feature and type resolution

This is what makes large manifest graphs and repeated render passes practical without repeatedly rebuilding the same structures.

## Practical reading order
If you need to understand how schema-driven rendering works, read in this order:
1. schema compiler / blueprint
2. VM lazy schema view and slice cache
3. orchestrator boot flow
4. data pipeline partial hydration
5. form controller mapping

## Testing focus
- Confirm lazy schema reads are cached across repeated field lookups.
- Confirm schema slices are stable under repeated access.
- Confirm manifests with new field types remain readable by the VM even when only a subset of fields is requested.
- Confirm cache invalidation still works when a manifest version hash changes.
