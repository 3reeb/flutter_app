# Widget tests

## What these tests cover
Compile-time contracts for sizing (width/height), drag props, resize handles, split ratios,
field range constraints, and virtual grid cell sizing.
These tests verify that the VM does not strip, mutate, or coerce props that drive widget behavior.

## Files

| File | ID | What it tests |
|------|----|---------------|
| widget_001_001.json | widget-001-fixed-size | Fixed width/height props round-trip |
| widget_002_002.json | widget-002-string-sizing | String width/height values |
| widget_003_003.json | widget-003-aspect-ratio | box:aspect ratio prop |
| widget_010_010.json | widget-010-draggable-prop | draggable + dragAxis + dragHandleSelector |
| widget_011_011.json | widget-011-drag-axis-constrained | dragAxis:'x' constrains horizontal only |
| widget_012_012.json | widget-012-drag-snap-grid | snapToGrid + gridSize |
| widget_020_020.json | widget-020-resizable-handles | All 8 resize handles + min/max |
| widget_021_021.json | widget-021-resize-horizontal-only | East/west only resize |
| widget_030_030.json | widget-030-split-ratio-axis | box:split ratio + axis |
| widget_040_040.json | widget-040-slider-min-max-step | field:slider range props |
| widget_041_041.json | widget-041-slider-out-of-range | defaultValue > max must fail |
| widget_050_050.json | widget-050-virtual-grid-cell-size | virtual_grid cellWidth/cellHeight |
