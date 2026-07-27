# Update detection rules

Mark the matching test-doc as stale when any of the following changes:

- public type, function, or method signature changes
- new branch added to cache, registry, or data routing logic
- serialization shape changes
- platform branch changes
- new plugin, adapter, or datasource registration path
- order-sensitive code is modified
- lazy loading, memoization, or eviction logic changes
- any new field type, controller type, or media policy behavior appears
- any hasMany/list semantics change

When in doubt, refresh the file-specific Markdown and YAML together so the generator does not inherit stale assumptions.
