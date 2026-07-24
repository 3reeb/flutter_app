import 'package:flutter/material.dart';
import 'quantum.dart';

// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SCHEMA-DRIVEN UI ENGINE DEMONSTRATOR
// Demonstrates all 10 Data-Driven Macro Components building complete views
// directly from JSON schemas with zero custom widgets.
// ════════════════════════════════════════════════════════════════════════════

void main() {
  final config = QuantumAppConfig(
    appName: 'Quantum SDUI Dashboard',
    themeMode: ThemeMode.light,
    telemetry: const QuantumTelemetryConfig(
      enabled: true,
      enableFrameMonitorInDebug: false,
    ),
    domains: [
      QuantumDomain(
        name: 'sdui_demo',
        routes: [
          QLRouteBuilder.localJson(
            path: '/',
            schemaBuilder: buildSduiDashboardSchema,
          ),
        ],
      )
    ],
  );

  bootQuantumApp(config);
}

/// Builds the SDUI Blueprint containing every Data-Driven Engine component.
Map<String, dynamic> buildSduiDashboardSchema(QLRouteInfo info) {
  return {
    "module": "sdui_demo",

    // ════════════════════════════════════════════════════════════════════════
    // 1. GLOBAL STATE (Mock Database)
    // ════════════════════════════════════════════════════════════════════════
    "state": {
      "currentTab": "table", // Controls which dashboard view is visible

      // ── DATA FOR: data_table, schema_list, schema_grid_view ──
      "users": [
        {
          "id": 1,
          "name": "Alice Chen",
          "email": "alice@quantum.dev",
          "role": "Admin",
          "status": "Active",
          "avatar": "https://i.pravatar.cc/150?u=1"
        },
        {
          "id": 2,
          "name": "Bob Smith",
          "email": "bob@quantum.dev",
          "role": "Editor",
          "status": "Pending",
          "avatar": "https://i.pravatar.cc/150?u=2"
        },
        {
          "id": 3,
          "name": "Charlie Day",
          "email": "charlie@quantum.dev",
          "role": "Viewer",
          "status": "Inactive",
          "avatar": "https://i.pravatar.cc/150?u=3"
        },
        {
          "id": 4,
          "name": "Diana Prince",
          "email": "diana@quantum.dev",
          "role": "Editor",
          "status": "Active",
          "avatar": "https://i.pravatar.cc/150?u=4"
        }
      ],

      // ── DATA FOR: kanban_schema ──
      "tasks": {
        "Todo": [
          {
            "id": 101,
            "title": "Design SDUI System",
            "status": "Todo",
            "color": "3B82F6",
            "badge": "High"
          },
          {
            "id": 102,
            "title": "Write Documentation",
            "status": "Todo",
            "color": "94A3B8"
          }
        ],
        "In Progress": [
          {
            "id": 103,
            "title": "Fix WebGL Crash",
            "status": "In Progress",
            "color": "F59E0B",
            "badge": "Urgent"
          }
        ],
        "Done": [
          {
            "id": 104,
            "title": "Setup Repository",
            "status": "Done",
            "color": "10B981"
          }
        ]
      },

      // ── DATA FOR: timeline_schema ──
      "events": [
        {
          "title": "System Deployed",
          "time": "10:00 AM",
          "body": "Version 8.0 shipped to production.",
          "icon": "🚀",
          "color": "10B981"
        },
        {
          "title": "Database Backup",
          "time": "11:30 AM",
          "body": "Automated snapshot completed.",
          "icon": "💾",
          "color": "3B82F6"
        },
        {
          "title": "Memory Spike",
          "time": "02:15 PM",
          "body": "RAM exceeded 90% threshold.",
          "icon": "⚠️",
          "color": "EF4444"
        }
      ],

      // ── DATA FOR: schema_report, schema_chart_view ──
      "metrics": [
        {"month": "Jan", "revenue": 15000, "users": 120, "region": "US"},
        {"month": "Feb", "revenue": 28000, "users": 250, "region": "EU"},
        {"month": "Mar", "revenue": 22000, "users": 180, "region": "US"},
        {"month": "Apr", "revenue": 35000, "users": 310, "region": "Asia"}
      ],

      // ── DATA FOR: schema_detail_view ──
      "selectedUser": {
        "name": "Alice Chen",
        "email": "alice@quantum.dev",
        "role": "Admin",
        "status": "Active",
        "notifications": true
      },

      // ── DATA FOR: schema_wizard ──
      "wizardData": {}
    },

    // ════════════════════════════════════════════════════════════════════════
    // 2. UI BLUEPRINT
    // ════════════════════════════════════════════════════════════════════════
    "ui": {
      "type": "page",
      "props": {"layout": "col", "fill": "slate-50", "scrollable": true},
      "children": [
        // ── HERO HEADER & NAVIGATION ──
        {
          "type": "col",
          "style": "p-24 bg-slate-900 shadow-md",
          "children": [
            {
              "type": "text",
              "style": "text-2xl font-bold text-white",
              "props": {"text": "Quantum SDUI Dashboard"}
            },
            {
              "type": "text",
              "style": "text-sm text-slate-400 mt-4 mb-24",
              "props": {
                "text":
                    "Entirely generated from a JSON Schema. Zero custom widgets."
              }
            },
            // Segmented Control to switch views
            {
              "type": "segmented_control",
              "props": {"bind": "currentTab", "initialValue": "table"},
              "children": [
                {
                  "type": "button",
                  "props": {
                    "value": "table",
                    "content": {
                      "type": "text",
                      "props": {"text": "Data Table"}
                    }
                  }
                },
                {
                  "type": "button",
                  "props": {
                    "value": "kanban",
                    "content": {
                      "type": "text",
                      "props": {"text": "Kanban & Timeline"}
                    }
                  }
                },
                {
                  "type": "button",
                  "props": {
                    "value": "reports",
                    "content": {
                      "type": "text",
                      "props": {"text": "Analytics"}
                    }
                  }
                },
                {
                  "type": "button",
                  "props": {
                    "value": "lists",
                    "content": {
                      "type": "text",
                      "props": {"text": "Lists & Grids"}
                    }
                  }
                },
                {
                  "type": "button",
                  "props": {
                    "value": "forms",
                    "content": {
                      "type": "text",
                      "props": {"text": "Detail & Wizard"}
                    }
                  }
                }
              ]
            }
          ]
        },

        // ── CONTENT CONTAINER ──
        {
          "type": "box",
          "style": "p-24",
          "children": [
            // =================================================================
            // VIEW 1: DATA TABLE & FILTER BAR
            // =================================================================
            {
              "\$if": "{{ currentTab | eq('table') }}",
              "type": "col",
              "style": "gap-24",
              "children": [
                {
                  "type": "text",
                  "style": "text-xl font-bold text-slate-800",
                  "props": {"text": "1. & 2. Filter Bar & Data Table"}
                },
                // 1. FILTER BAR
                {
                  "type": "card",
                  "style": "p-16",
                  "children": [
                    {
                      "type": "filter_bar",
                      "props": {
                        "bind": "userFilters",
                        "layout": "wrap",
                        "schema": {
                          "role": {
                            "type": "select",
                            "label": "Filter by Role",
                            "options": ["Admin", "Editor", "Viewer"]
                          },
                          "status": {
                            "type": "select",
                            "label": "Filter by Status",
                            "options": ["Active", "Pending", "Inactive"]
                          }
                        }
                      }
                    }
                  ]
                },
                // 2. DATA TABLE
                {
                  "type": "data_table",
                  "props": {
                    "bind": "users",
                    "selectable": true,
                    "selectBind": "selectedUsers",
                    "striped": true,
                    // Note: You can drag and drop these column headers horizontally!
                    "schema": {
                      "name": {
                        "type": "text",
                        "label": "Full Name",
                        "sortable": true,
                        "filterable": true,
                        "width": 200
                      },
                      "email": {
                        "type": "text",
                        "label": "Email Address",
                        "width": 250
                      },
                      "role": {
                        "type": "badge",
                        "label": "Access Role",
                        "sortable": true
                      },
                      "status": {
                        "type": "status",
                        "label": "Account Status",
                        "sortable": true
                      }
                    }
                  }
                }
              ]
            },

            // =================================================================
            // VIEW 2: KANBAN BOARD & TIMELINE
            // =================================================================
            {
              "\$if": "{{ currentTab | eq('kanban') }}",
              "type": "col",
              "style": "gap-24",
              "children": [
                {
                  "type": "text",
                  "style": "text-xl font-bold text-slate-800",
                  "props": {"text": "3. & 4. Kanban Schema & Timeline"}
                },
                {
                  "type": "row",
                  "style": "gap-24 items-start",
                  "children": [
                    // 3. KANBAN SCHEMA
                    {
                      "type": "box",
                      "style": "flex-2",
                      "children": [
                        {
                          "type": "kanban_schema",
                          "props": {
                            "bind": "tasks",
                            "columns": ["Todo", "In Progress", "Done"],
                            "statusField": "status",
                            "colorField": "color",
                            "schema": {
                              "title": {"type": "text", "label": "Task Name"},
                              "badge": {"type": "badge"}
                            }
                          }
                        }
                      ]
                    },
                    // 4. TIMELINE SCHEMA
                    {
                      "type": "card",
                      "style": "flex-1 p-20",
                      "children": [
                        {
                          "type": "timeline_schema",
                          "props": {
                            "bind": "events",
                            "timeField": "time",
                            "titleField": "title",
                            "bodyField": "body",
                            "iconField": "icon",
                            "colorField": "color"
                          }
                        }
                      ]
                    }
                  ]
                }
              ]
            },

            // =================================================================
            // VIEW 3: REPORTS & CHARTS
            // =================================================================
            {
              "\$if": "{{ currentTab | eq('reports') }}",
              "type": "col",
              "style": "gap-24",
              "children": [
                {
                  "type": "text",
                  "style": "text-xl font-bold text-slate-800",
                  "props": {"text": "5. & 6. Schema Report & Chart View"}
                },
                // 5. SCHEMA REPORT
                {
                  "type": "schema_report",
                  "props": {
                    "title": "Quarterly Financials",
                    "bind": "metrics",
                    "chartType": "line",
                    "chartField": "revenue",
                    "stats": [
                      {
                        "label": "Total Revenue",
                        "field": "revenue",
                        "agg": "sum",
                        "prefix": "\$"
                      },
                      {"label": "Avg Users", "field": "users", "agg": "avg"},
                      {
                        "label": "Peak Revenue",
                        "field": "revenue",
                        "agg": "max",
                        "prefix": "\$"
                      }
                    ],
                    "schema": {
                      "month": {"type": "text", "label": "Month"},
                      "revenue": {"type": "currency", "label": "Gross Revenue"},
                      "users": {"type": "number", "label": "Active Users"}
                    }
                  }
                },
                // 6. SCHEMA CHART VIEW (With integrated filter)
                {
                  "type": "schema_chart_view",
                  "props": {
                    "title": "User Growth by Region",
                    "bind": "metrics",
                    "chartType": "bar",
                    "xField": "month",
                    "yField": "users",
                    "filterBind": "chartFilters",
                    "filterSchema": {
                      "region": {
                        "type": "select",
                        "label": "Filter Region",
                        "options": ["US", "EU", "Asia"]
                      }
                    }
                  }
                }
              ]
            },

            // =================================================================
            // VIEW 4: LISTS & GRIDS
            // =================================================================
            {
              "\$if": "{{ currentTab | eq('lists') }}",
              "type": "col",
              "style": "gap-24",
              "children": [
                {
                  "type": "text",
                  "style": "text-xl font-bold text-slate-800",
                  "props": {"text": "7. & 8. Schema List & Grid View"}
                },
                {
                  "type": "row",
                  "style": "gap-24 items-start",
                  "children": [
                    // 7. SCHEMA LIST (v2 Ultra-Flexible)
                    {
                      "type": "card",
                      "style": "expand p-0 overflow-hidden",
                      "children": [
                        {
                          "type": "box",
                          "style":
                              "p-16 border-b-1 border-slate-200 bg-slate-50",
                          "children": [
                            {
                              "type": "text",
                              "style": "font-bold",
                              "props": {"text": "Draggable Row List"}
                            }
                          ]
                        },
                        {
                          "type": "schema_list",
                          "props": {
                            "bind": "users",
                            "draggable": true,
                            "selectable": true,
                            "selectBind": "selectedUsers",
                            "animateItems": true,
                            "animationType": "slideScale",
                            "magneto": true,
                            "schema": {
                              "name": {"type": "text"},
                              "email": {"type": "text"},
                              "status": {"type": "status"}
                            }
                          }
                        }
                      ]
                    },
                    // 8. SCHEMA GRID VIEW (Now powered by schema_list v2)
                    {
                      "type": "box",
                      "style": "expand",
                      "children": [
                        {
                          "type": "schema_list",
                          "props": {
                            "bind": "users",
                            "layout": "masonry",
                            "cols": "1fr 1fr",
                            "gap": 16,
                            "animateItems": true,
                            "animationType": "scale",
                            "schema": {
                              "avatar": {"type": "image"},
                              "name": {"type": "text"},
                              "role": {"type": "badge"}
                            }
                          }
                        }
                      ]
                    }
                  ]
                }
              ]
            },

            // =================================================================
            // VIEW 5: DETAIL VIEW & WIZARD
            // =================================================================
            {
              "\$if": "{{ currentTab | eq('forms') }}",
              "type": "col",
              "style": "gap-24",
              "children": [
                {
                  "type": "text",
                  "style": "text-xl font-bold text-slate-800",
                  "props": {"text": "9. & 10. Detail View & Wizard"}
                },
                {
                  "type": "row",
                  "style": "gap-24 items-start",
                  "children": [
                    // 9. SCHEMA DETAIL VIEW
                    {
                      "type": "card",
                      "style": "flex-1 p-24",
                      "children": [
                        {
                          "type": "schema_detail_view",
                          "props": {
                            "bind": "selectedUser",
                            "mode":
                                "auto", // Auto means it shows as text, but has an "Edit" button
                            "schema": {
                              "name": {"type": "text", "label": "Full Name"},
                              "email": {
                                "type": "email",
                                "label": "Email Address"
                              },
                              "role": {
                                "type": "select",
                                "label": "System Role",
                                "options": ["Admin", "Editor", "Viewer"]
                              },
                              "notifications": {
                                "type": "toggle",
                                "label": "Push Notifications"
                              }
                            }
                          }
                        }
                      ]
                    },
                    // 10. SCHEMA WIZARD
                    {
                      "type": "card",
                      "style": "flex-1 p-24",
                      "children": [
                        {
                          "type": "schema_wizard",
                          "props": {
                            "bind": "wizardData",
                            "steps": [
                              {
                                "title": "Step 1: Account Info",
                                "description": "Create a new user account.",
                                "schema": {
                                  "username": {
                                    "type": "text",
                                    "label": "Username",
                                    "required": true
                                  },
                                  "password": {
                                    "type": "password",
                                    "label": "Password",
                                    "required": true
                                  }
                                }
                              },
                              {
                                "title": "Step 2: Profile Details",
                                "schema": {
                                  "department": {
                                    "type": "select",
                                    "label": "Department",
                                    "options": ["Engineering", "Sales", "HR"]
                                  },
                                  "skills": {"type": "tags", "label": "Skills"}
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        }
      ]
    }
  };
}
