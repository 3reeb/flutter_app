import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

// ════════════════════════════════════════════════════════════════════════════
// MASTER TEST PAYLOAD (Production IDE/Dashboard)
// ════════════════════════════════════════════════════════════════════════════

final Map<String, dynamic> productionDashboardPayload = {
  "type": "box:safe",
  "style": "w-full h-full bg-slate-900",
  "children": [
    {
      "type": "box:col",
      "style": "w-full h-full",
      "children": [
        {
          "type": "box:row",
          "style": "w-full h-64 bg-slate-800 border-b border-slate-700 p-16",
          "props": {"justify": "between", "items": "center"},
          "children": [
            {
              "type": "text:h3",
              "style": "text-white",
              "props": {"text": "Quantum IDE"}
            },
            {
              "type": "box:row",
              "props": {"gap": 8},
              "children": [
                {
                  "type": "action:button",
                  "props": {
                    "text": "Deploy",
                    "intent": "emerald",
                    "scale": "sm"
                  }
                },
                {
                  "type": "action:button",
                  "props": {"text": "Profile", "intent": "slate", "scale": "sm"}
                }
              ]
            }
          ]
        },
        {
          "type": "box:expanded",
          "children": [
            {
              "type": "box:split",
              "props": {
                "id": "main_splitter",
                "direction": "horizontal",
                "fractions": [0.2, 0.8],
                "dividerThickness": 4.0
              },
              "children": [
                {
                  "type": "box:responsive",
                  "props": {"id": "sidebar_resp"},
                  "style":
                      "w-full h-full bg-slate-800 border-r border-slate-700",
                  "children": [
                    {
                      "type": "box",
                      "props": {"\$if": "{{!isCompact}}"},
                      "style": "w-full h-full p-16",
                      "children": [
                        {
                          "type": "text:label",
                          "style": "text-slate-400",
                          "props": {"text": "EXPLORER"}
                        }
                      ]
                    }
                  ]
                },
                {
                  "type": "box:col",
                  "props": {"scrollable": true},
                  "style": "w-full h-full bg-slate-900",
                  "children": [
                    {
                      "type": "box:measure",
                      "props": {
                        "id": "content_measure",
                        "bind": "telemetry.main_content"
                      },
                      "style": "w-full p-24",
                      "children": [
                        {
                          "type": "box:aspect",
                          "props": {"ratio": 2.33},
                          "style":
                              "bg-slate-800 rounded-12 shadow-lg flex-center border border-slate-700",
                          "children": [
                            {
                              "type": "text:h2",
                              "style": "text-slate-300",
                              "props": {"text": "16:7 Cinematic View"}
                            }
                          ]
                        },
                        {
                          "type": "box:grid",
                          "props": {
                            "id": "stat_grid",
                            "gridCols": "repeat(auto-fit, minmax(200px, 1fr))",
                            "gap": 16
                          },
                          "style": "w-full mt-24",
                          "children": [
                            {
                              "type": "box:card",
                              "props": {"depth": "raised", "fill": "surface"},
                              "children": [
                                {
                                  "type": "text:p",
                                  "props": {"text": "CPU: 42%"}
                                }
                              ]
                            },
                            {
                              "type": "box:card",
                              "props": {"depth": "raised", "fill": "surface"},
                              "children": [
                                {
                                  "type": "text:p",
                                  "props": {"text": "RAM: 1.2GB"}
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
          ]
        }
      ]
    }
  ]
};

// ════════════════════════════════════════════════════════════════════════════
// TEST RUNNER
// ════════════════════════════════════════════════════════════════════════════

void main() {
  setUpAll(() {
    QEngine.instance.initialize(initialCapacity: 8192);
    QuantumVM.instance.initialize(workerThreads: 1);
    initQuantumBuiltIns(QuantumVM.instance);
  });

  tearDownAll(() {
    QuantumVM.instance.clearRuntimeCaches();
    QEngine.instance.dispose();
  });

  // 🚀 THE BYPASS: Directly build the AST, skipping QLSmartView & Local Telemetry
  Widget buildApp(Map<String, dynamic> uiPayload) {
    final ast = QLBlueprint.fromJson(uiPayload);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: QLDataScope(
          moduleStore: QLStoreRegistry.instance.defaultStore,
          localData: {"telemetry": {}, "click_target": "none"},
          child: Builder(
              builder: (ctx) => QuantumVM.instance.renderWidget(ctx, ast)),
        ),
      ),
    );
  }

  void setScreenSize(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder qKey(String id) => find.byKey(ValueKey('${id}_'));

  // ════════════════════════════════════════════════════════════════════════════
  // PHASE 1: STRUCTURAL MATHEMATICS & GEOMETRY
  // ════════════════════════════════════════════════════════════════════════════
  group('Phase 1: Mathematical Engine Integrity', () {
    testWidgets('Flex Math Resolution (Expanded vs Flexible)', (tester) async {
      final ui = {
        "type": "box:row",
        "style": "w-full h-100",
        "children": [
          {
            "type": "box",
            "props": {"id": "fixed"},
            "style": "w-200 h-full"
          },
          {
            "type": "box:expanded",
            "props": {"id": "exp3", "flex": 3},
            "children": [
              {"type": "box", "style": "w-full h-full"}
            ]
          },
          {
            "type": "box:expanded",
            "props": {"id": "exp1", "flex": 1},
            "children": [
              {"type": "box", "style": "w-full h-full"}
            ]
          }
        ]
      };

      setScreenSize(tester, const Size(1000, 800));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      expect(tester.getSize(qKey('fixed')).width, 200.0);
      expect(tester.getSize(qKey('exp3')).width, 600.0);
      expect(tester.getSize(qKey('exp1')).width, 200.0);
    });

    testWidgets('Grid Dense Packing & Out-of-Bounds Caching', (tester) async {
      final ui = {
        "type": "box:grid",
        "props": {"gridCols": "1fr 1fr 1fr", "gap": 10, "__subType": "grid"},
        "style": "w-900 h-900",
        "children": [
          {
            "type": "box:grid_item",
            "props": {"id": "i1", "colSpan": 2},
            "children": [
              {"type": "box", "style": "h-100"}
            ]
          },
          {
            "type": "box:grid_item",
            "props": {"id": "i2_oob", "colStart": 5},
            "children": [
              {"type": "box", "style": "h-100"}
            ]
          },
          {
            "type": "box:grid_item",
            "props": {"id": "i3_dense"},
            "children": [
              {"type": "box", "style": "h-100"}
            ]
          }
        ]
      };

      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final i1 = tester.getTopLeft(qKey('i1'));
      final i3 = tester.getTopLeft(qKey('i3_dense'));
      final i2 = tester.getTopLeft(qKey('i2_oob'));

      expect(i3.dy, i1.dy, reason: 'Dense packing failed to back-fill row 1.');
      expect(i2.dx, greaterThan(i3.dx),
          reason: 'Bitmask failed to expand out of bounds.');
    });

    testWidgets('Masonry Shortest-Column Fall Calculus', (tester) async {
      final ui = {
        "type": "box:masonry",
        "props": {"cols": "1fr 1fr 1fr", "gap": 0},
        "style": "w-300",
        "children": [
          {
            "type": "box",
            "props": {"id": "m1"},
            "style": "h-100"
          },
          {
            "type": "box",
            "props": {"id": "m2"},
            "style": "h-300"
          },
          {
            "type": "box",
            "props": {"id": "m3"},
            "style": "h-50"
          },
          {
            "type": "box",
            "props": {"id": "m4"},
            "style": "h-150"
          },
        ]
      };

      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(qKey('m4')).dx, 200.0,
          reason: 'Masonry failed shortest-column match.');
      expect(tester.getTopLeft(qKey('m4')).dy, 50.0,
          reason: 'Masonry failed Y-offset calculation.');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // PHASE 2: HOSTILITY & ARMOR
  // ════════════════════════════════════════════════════════════════════════════
  group('Phase 2: Crash Immunity & Constraint Armor', () {
    testWidgets('The Russian Doll Starvation (Double Infinity)',
        (tester) async {
      final ui = {
        "type": "box:col",
        "props": {"scrollable": true},
        "children": [
          {
            "type": "box:row",
            "props": {"scrollable": true},
            "children": [
              {
                "type": "box:wrap",
                "children": [
                  {
                    "type": "box:flexible",
                    "children": [
                      {
                        "type": "box:aspect",
                        "props": {"ratio": 1.5},
                        "children": [
                          {
                            "type": "text",
                            "props": {"text": "Armor Holds"}
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
      };

      setScreenSize(tester, const Size(500, 500));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull,
          reason: 'Layout failed to intercept infinity crash.');
      expect(find.text("Armor Holds"), findsOneWidget);
    });

    testWidgets('Negative Morpher Dragging (Collapse Prevention)',
        (tester) async {
      final ui = {
        "type": "box:morph",
        "props": {"id": "morpher", "width": 100, "height": 100},
        "children": [
          {
            "type": "text",
            "props": {"text": "Box"}
          }
        ]
      };

      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final boxFinder = qKey('morpher');
      final handles =
          find.descendant(of: boxFinder, matching: find.byType(Container));

      await tester.drag(handles.last, const Offset(-500.0, -500.0));
      await tester.pumpAndSettle();

      final newSize = tester.getSize(boxFinder);
      expect(newSize.width, 20.0,
          reason: 'Morpher failed to clamp negative width.');
      expect(newSize.height, 20.0,
          reason: 'Morpher failed to clamp negative height.');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // PHASE 3: HARDWARE KINEMATICS
  // ════════════════════════════════════════════════════════════════════════════
  group('Phase 3: Hardware Kinematics', () {
    testWidgets('Z-Space Pointer Interception', (tester) async {
      final ui = {
        "type": "box:grid",
        "props": {"gridCols": "1fr", "gridRows": "1fr"},
        "style": "w-500 h-500",
        "children": [
          {
            "type": "box:grid_item",
            "props": {"rowStart": 1, "colStart": 1, "zIndex": 10},
            "children": [
              {
                "type": "action:button",
                "props": {
                  "text": "Z_HIGH",
                  "onClick": [
                    {
                      "action": "state.set",
                      "key": "click_target",
                      "value": "HIGH"
                    }
                  ]
                }
              }
            ]
          },
          {
            "type": "box:grid_item",
            "props": {"rowStart": 1, "colStart": 1, "zIndex": 1},
            "children": [
              {
                "type": "action:button",
                "props": {
                  "text": "Z_LOW",
                  "onClick": [
                    {
                      "action": "state.set",
                      "key": "click_target",
                      "value": "LOW"
                    }
                  ]
                }
              }
            ]
          }
        ]
      };

      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(250, 250));
      await tester.pumpAndSettle();

      expect(QuantumVM.instance.store.get('click_target'), "HIGH",
          reason: 'Engine failed to hit-test based on zIndex paint order.');
    });

    testWidgets('Splitter Physics Gesture Simulation', (tester) async {
      final ui = {
        "type": "box:split",
        "props": {
          "direction": "horizontal",
          "fractions": [0.5, 0.5],
          "dividerThickness": 10
        },
        "style": "w-1000 h-500",
        "children": [
          {
            "type": "box",
            "props": {"id": "leftPane"},
            "style": "w-full h-full"
          },
          {
            "type": "box",
            "props": {"id": "rightPane"},
            "style": "w-full h-full"
          }
        ]
      };

      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final divider = find.byKey(const ValueKey('ql_divider_0'));
      final leftPane = qKey('leftPane');

      final initialSize = tester.getSize(leftPane);
      await tester.drag(divider, const Offset(200.0, 0.0));
      await tester.pumpAndSettle();

      expect(tester.getSize(leftPane).width,
          closeTo(initialSize.width + 200.0, 0.1),
          reason:
              'box:split failed to mathematically alter flex boundaries during drag gesture.');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // PHASE 4: PRODUCTION PAYLOAD
  // ════════════════════════════════════════════════════════════════════════════
  group('Phase 4: Production Dashboard Integration', () {
    testWidgets('Deep Render Tree & Infinity Crash Immunity', (tester) async {
      setScreenSize(tester, const Size(1920, 1080));
      await tester.pumpWidget(buildApp(productionDashboardPayload));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text("Quantum IDE"), findsOneWidget);
    });

    testWidgets('Responsive Engine (Desktop -> Mobile Unmount)',
        (tester) async {
      setScreenSize(tester, const Size(1920, 1080));
      await tester.pumpWidget(buildApp(productionDashboardPayload));
      await tester.pumpAndSettle();

      expect(find.text("EXPLORER"), findsOneWidget,
          reason: 'Sidebar failed to render on desktop.');

      setScreenSize(tester, const Size(375, 812));
      await tester.pumpAndSettle();

      expect(find.text("EXPLORER"), findsNothing,
          reason:
              'Responsive engine failed to unmount node on breakpoint threshold.');
    });

    testWidgets('Measure Telemetry Writeback', (tester) async {
      setScreenSize(tester, const Size(1280, 720));
      await tester.pumpWidget(buildApp(productionDashboardPayload));
      await tester.pumpAndSettle();

      final w = QuantumVM.instance.store.get('telemetry.main_content.w');
      final h = QuantumVM.instance.store.get('telemetry.main_content.h');

      expect(w, isNotNull,
          reason: 'Telemetry failed to jump threads to write width.');
      expect(h, isNotNull,
          reason: 'Telemetry failed to jump threads to write height.');
      expect(w, greaterThan(900.0));
    });
  });
}
