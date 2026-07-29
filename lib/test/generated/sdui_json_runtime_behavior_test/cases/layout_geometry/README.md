# layout_geometry cases

These fixtures focus on live widget geometry rather than just blueprint shape.

The cases are split into four groups:

- `row_between/` — horizontal rows that must distribute free space
- `row_end/` — horizontal rows that must right-align their children
- `col_between/` — vertical columns that must distribute free space
- `col_end/` — vertical columns that must bottom-align their children

Each file uses the execution runner’s `expectGeometry` and `expectOrder` steps so spacing regressions are caught by real `WidgetTester` measurements.
