# Case fixtures

Each JSON file in this tree is one runnable SDUI runtime behavior case.

Keep these cases small enough to read, but strong enough to prove real runtime output. The progression should stay visible:

1. minimal string nodes
2. canonical node shapes and subtype routing
3. compile-time interpolation and scoping
4. wrapper operators
5. layout expansion and macro expansion
6. large mixed nested compositions
7. explicit failure guards
8. geometry and spatial assertions


The `execution/` folder holds WidgetTester-backed runtime execution cases. These cases may include `runtimeAssertions`, `runtimeBehavior`, and `executionSteps` so the suite can verify live rendering and interaction flows. The runner also supports geometry checks such as `expectGeometry` and `expectOrder` so layout spacing, alignment, and bounds can be tested directly.


The `layout_geometry/` folder adds spatial checks for rows, columns, alignment, and sibling ordering. Those cases use the new `expectGeometry` and `expectOrder` execution steps to catch spacing regressions like `justify-between` not distributing free space.

Overlay fixtures live under `cases/overlay/` and cover portal-driven overlays, floating surfaces, inline panels, and fullscreen presentations with live execution checks.

The `overlay/` folder adds portal and overlay runtime cases. These tests exercise trigger bindings, fixed placement, window movement, barrier dismissal, anchored floating surfaces, inline panels, toasts, and fullscreen surfaces with WidgetTester execution steps.
