# 10 — Table Rendering Test Plan

Testing `data:table` configurations, complex column definitions, cell rendering slots, and large dataset handling.

---

## data:table configuration

### TBL-001 — Table with custom cell slots

```json
{
  "__meta": {
    "id": "tbl-001-custom-cell-slots",
    "title": "data:table using custom slots for cell rendering",
    "description": "If a column defines a slot name, the table uses that slot to render the cell, passing the row data as context.",
    "tags": ["table", "slots", "render", "high"],
    "allowBlank": false,
    "priority": "high"
  },
  "input": {
    "state": { "users": [{ "id": 1, "status": "active" }] },
    "type": "data:table",
    "props": {
      "bind": "${state.users}",
      "columns": [
        { "key": "id", "label": "ID" },
        { "key": "status", "label": "Status", "slot": "statusCell" }
      ]
    },
    "slots": {
      "statusCell": { "type": "action:chip", "props": { "label": "${row.status}" } }
    }
  },
  "expected": {
    "type": "system",
    "props": { "__subType": "store_provider", "initialState": { "users": [{ "id": 1, "status": "active" }] } },
    "debugPath": "root.store_provider",
    "children": [{
      "type": "data",
      "props": {
        "__subType": "table",
        "bind": "${state.users}",
        "columns": [
          { "key": "id", "label": "ID" },
          { "key": "status", "label": "Status", "slot": "statusCell" }
        ]
      },
      "slots": {
        "statusCell": { "type": "action", "props": { "__subType": "chip", "label": "${row.status}" } }
      },
      "debugPath": "root"
    }]
  },
  "runtimeAssertions": [
    { "path": "children[0].slots.statusCell.props.__subType", "equals": "chip" }
  ]
}
```

---

## Complete Table Test ID Table

| ID | What it covers | Priority |
|----|---------------|----------|
| tbl-001 | Table with custom cell slots | high |
| tbl-002 | Table empty data state | high |
| tbl-003 | Table loading state | high |
| tbl-004 | Table sortable column headers | critical |
| tbl-005 | Table row selection | medium |
| tbl-006 | Table sticky headers | low |
