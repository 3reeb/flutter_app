import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

// ════════════════════════════════════════════════════════════════════════════
// REUSABLE STRESS PAYLOADS (The Core Test Data)
// ════════════════════════════════════════════════════════════════════════════
class TestPayloads {
  // Payload A: Infinity Bait
  static Map<String, dynamic> infinityBait() => {
        "type": "box:col",
        "props": {"scrollable": true},
        "children": [
          {
            "type": "box:row",
            "props": {"scrollable": true},
            "children": [
              {
                "type": "box:expanded",
                "children": [
                  {
                    "type": "text",
                    "props": {"text": "Infinity Armor Holds"}
                  }
                ]
              }
            ]
          }
        ]
      };

  // Payload B: Dynamic Fracture
  static Map<String, dynamic> dynamicFracture() => {
        "type": "box:split",
        "props": {
          "direction": "horizontal",
          "fractions": [0.5, 0.5]
        },
        "children": [
          {
            "type": "box:morph",
            "props": {"id": "morph_in_split", "width": 100, "height": 100},
            "children": [
              {
                "type": "text",
                "props": {"text": "M"}
              }
            ]
          },
          {"type": "box:col", "style": "w-full h-full"}
        ]
      };

  // Payload C: Z-Space Collision
  static Map<String, dynamic> zSpaceCollision() => {
        "type": "box:grid",
        "props": {"gridCols": "1fr", "gridRows": "1fr"},
        "children": List.generate(
            10,
            (i) => {
                  "type": "box:grid_item",
                  "props": {"rowStart": 1, "colStart": 1, "zIndex": i},
                  "children": [
                    {
                      "type": "action:button",
                      "props": {
                        "text": "BTN_$i",
                        "onClick": [
                          {"action": "state.set", "key": "hit", "value": i}
                        ]
                      }
                    }
                  ]
                })
      };

  // Payload D: Fluid Media
  static Map<String, dynamic> fluidMedia() => {
        "type": "box:aspect",
        "props": {"ratio": 1.777}, // 16:9
        "children": [
          {
            "type": "text",
            "style": "text-2xl",
            "props": {"text": "Fluid Text"}
          }
        ]
      };

  // Payload E: The Matryoshka
  static Map<String, dynamic> matryoshka() => {
        "type": "box:morph",
        "props": {"width": 500, "height": 500},
        "children": [
          {
            "type": "box:masonry",
            "props": {"cols": "2"},
            "children": [
              {
                "type": "box:row",
                "children": [
                  {
                    "type": "box:col",
                    "children": [
                      {
                        "type": "box:grid",
                        "props": {"gridCols": "1fr 1fr"},
                        "children": [
                          {"type": "box", "style": "w-full h-10"}
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
}

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

  Widget buildApp(Map<String, dynamic> uiPayload) {
    final ast = QLBlueprint.fromJson(uiPayload);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: QLDataScope(
          moduleStore: QLStoreRegistry.instance.defaultStore,
          localData: {"telemetry": {}, "hit": -1, "visible": true},
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
  // 1. Grid Engine Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('1. Grid Engine Suite', () {
    testWidgets('1.1 Dense Packing Algorithm (Holes backfilling)',
        (tester) async {
      final ui = {
        "type": "box:grid",
        "props": {"gridCols": "1fr 1fr 1fr", "gap": 0},
        "style": "w-300 h-300",
        "children": [
          {
            "type": "box:grid_item",
            "props": {"id": "item1", "colStart": 3, "colSpan": 1},
            "children": [
              {"type": "box", "style": "h-100"}
            ]
          },
          {
            "type": "box:grid_item",
            "props": {"id": "item2", "colSpan": 2},
            "children": [
              {"type": "box", "style": "h-100"}
            ]
          },
          {
            "type": "box:grid_item",
            "props": {"id": "item3", "colSpan": 1},
            "children": [
              {"type": "box", "style": "h-100"}
            ]
          },
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final i1 = tester.getTopLeft(qKey('item1'));
      final i2 = tester.getTopLeft(qKey('item2'));
      final i3 = tester.getTopLeft(qKey('item3'));
      // item1 is forced to col 3 (x=200).
      // item2 is dense, needs 2 span, fits at col 1 (x=0, y=0).
      // item3 needs 1 span, where does it go? dense packing should put it in the next available.
      expect(i2.dx, 0.0);
      expect(i2.dy, 0.0);
      expect(i1.dx, 200.0);
      expect(i1.dy, 0.0);
      // Ensure layout completed without crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 Out-Of-Bounds (OOB) Matrix Memory Expansion',
        (tester) async {
      final ui = {
        "type": "box:grid",
        "props": {"gridCols": "1fr", "gridRows": "1fr"},
        "children": [
          {
            "type": "box:grid_item",
            "props": {"id": "oob", "colStart": 100, "rowStart": 100},
            "children": [
              {
                "type": "text",
                "props": {"text": "Far"}
              }
            ]
          }
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();
      expect(tester.takeException(),
          isNull); // Ensures no RangeError or OutOfBounds exception
    });

    testWidgets('1.3 Track Resolution Auto-Fit Starvation', (tester) async {
      final ui = {
        "type": "box:grid",
        "props": {
          "id": "g",
          "gridCols": "repeat(auto-fit, minmax(200px, 1fr))",
          "gap": 10
        },
        "children": [
          {
            "type": "box",
            "props": {"id": "c1"},
            "style": "h-10"
          },
          {
            "type": "box",
            "props": {"id": "c2"},
            "style": "h-10"
          },
        ]
      };
      // Starve it with 50px width
      setScreenSize(tester, const Size(50, 500));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final c1 = tester.getTopLeft(qKey('c1'));
      final c2 = tester.getTopLeft(qKey('c2'));
      expect(c2.dy, greaterThan(c1.dy)); // Fallback to 1 column

      // Expand to 500px width
      setScreenSize(tester, const Size(500, 500));
      await tester.pumpAndSettle();
      final c2Expanded = tester.getTopLeft(qKey('c2'));
      expect(c2Expanded.dy, c1.dy); // Packed into same row
    });

    testWidgets('1.4 The Matryoshka Grid (Nested scaling)', (tester) async {
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(TestPayloads.matryoshka()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. Masonry Engine Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('2. Masonry Engine Suite', () {
    testWidgets('2.1 Shortest-Column Integrity & 2.2 Reflow', (tester) async {
      final ui = {
        "type": "box:masonry",
        "props": {"cols": "2", "gap": 0},
        "style": "w-200",
        "children": [
          {
            "type": "box",
            "props": {"id": "m1"},
            "style": "h-100"
          },
          {
            "type": "box",
            "props": {"id": "m2"},
            "style": "h-150"
          },
          {
            "type": "box",
            "props": {"id": "m3"},
            "style": "h-80"
          },
          {
            "type": "box",
            "props": {"id": "m4"},
            "style": "h-20"
          },
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final m1 = tester.getTopLeft(qKey('m1')); // Col 1, y=0
      final m2 = tester.getTopLeft(qKey('m2')); // Col 2, y=0
      final m3 = tester.getTopLeft(qKey('m3')); // Col 1, y=100 (100 < 150)
      final m4 = tester.getTopLeft(
          qKey('m4')); // Col 2? Col 1 height=180, Col 2 height=150. So Col 2.

      expect(m1.dy, 0);
      expect(m2.dy, 0);
      expect(m3.dx, 0);
      expect(m3.dy, 100);
      expect(m4.dx, 100); // 200/2 = 100
      expect(m4.dy, 150);
    });

    testWidgets('2.3 Column Starvation & Overflow', (tester) async {
      final ui = {
        "type": "box:masonry",
        "props": {"cols": "5", "gap": 10},
        "style": "w-10", // Extreme starvation
        "children": [
          {"type": "box", "style": "h-100"},
          {"type": "box", "style": "h-100"},
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. Flex Engine Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('3. Flex Engine Suite', () {
    testWidgets('3.1 Extreme Flexibility & Rounding', (tester) async {
      final ui = {
        "type": "box:row",
        "style": "w-1000 h-100",
        "children": [
          {
            "type": "box:expanded",
            "props": {"id": "f1", "flex": 1},
            "children": [
              {"type": "box"}
            ]
          },
          {
            "type": "box:expanded",
            "props": {"id": "f7", "flex": 7},
            "children": [
              {"type": "box"}
            ]
          },
          {
            "type": "box:expanded",
            "props": {"id": "f10k", "flex": 10000},
            "children": [
              {"type": "box"}
            ]
          },
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final w1 = tester.getSize(qKey('f1')).width;
      final w7 = tester.getSize(qKey('f7')).width;
      final w10k = tester.getSize(qKey('f10k')).width;

      expect(w1 + w7 + w10k, closeTo(1000.0, 0.001));
    });

    testWidgets('3.3 Gap Starvation Logic', (tester) async {
      final ui = {
        "type": "box:row",
        "props": {"gap": 50},
        "style": "w-100", // Gaps alone are 4*50=200 > 100
        "children": List.generate(
            5,
            (_) => {
                  "type": "box:expanded",
                  "children": [
                    {"type": "box"}
                  ]
                })
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();
      expect(tester.takeException(),
          isNull); // Should not throw negative dimension constraints
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. Wrap Engine Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('4. Wrap Engine Suite', () {
    testWidgets('4.1 Main & Cross-Axis Spacing Matrix Thresholds',
        (tester) async {
      final ui = {
        "type": "box:wrap",
        "props": {"gap": 10},
        "style": "w-310 h-300",
        "children": [
          {
            "type": "box",
            "props": {"id": "w1"},
            "style": "w-100 h-50"
          },
          {
            "type": "box",
            "props": {"id": "w2"},
            "style": "w-100 h-50"
          },
          {
            "type": "box",
            "props": {"id": "w3"},
            "style": "w-100 h-50"
          },
          {
            "type": "box",
            "props": {"id": "w4"},
            "style": "w-100 h-50"
          },
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final w3 = tester.getTopLeft(qKey('w3'));
      final w4 = tester.getTopLeft(qKey('w4'));

      // w: 310. w1(100)+g(10)+w2(100)+g(10)+w3(100) = 320.
      // Actually 310 < 320, so w3 should wrap!
      expect(w3.dy, greaterThan(0.0));
      expect(w4.dy, w3.dy);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 5. Stack & Layering Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('5. Stack & Layering Suite', () {
    testWidgets('5.3 Z-Index Context Mutation & Collision', (tester) async {
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(TestPayloads.zSpaceCollision()));
      await tester.pumpAndSettle();

      // Tap exactly at the overlapping center
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // The button with zIndex: 9 should intercept the hit
      expect(QuantumVM.instance.store.get('hit'), 9);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 6. Split Pane Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('6. Split Pane Suite', () {
    testWidgets('6.1 Multi-Divider Extreme Kinematics & Bounds',
        (tester) async {
      final ui = {
        "type": "box:split",
        "props": {
          "direction": "horizontal",
          "fractions": [0.2, 0.2, 0.2, 0.2, 0.2],
          "dividerThickness": 10
        },
        "style": "w-1000 h-500",
        "children":
            List.generate(5, (i) => {"type": "box", "style": "w-full h-full"})
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      final divider = find.byKey(const ValueKey('ql_divider_0'));
      await tester.drag(
          divider, const Offset(800.0, 0.0)); // Drag extreme right
      await tester.pumpAndSettle();

      expect(
          tester.takeException(), isNull); // Must not throw or invert dividers
    });

    testWidgets('6.3 Pane Collapsing', (tester) async {
      final ui = {
        "type": "box:split",
        "props": {
          "direction": "horizontal",
          "fractions": [0.5, 0.5]
        },
        "style": "w-1000 h-500",
        "children": [
          {
            "type": "box",
            "props": {"\$if": "{{visible}}"},
            "style": "w-full h-full"
          },
          {
            "type": "box",
            "props": {"id": "p2"},
            "style": "w-full h-full"
          }
        ]
      };
      setScreenSize(tester, const Size(1000, 1000));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();

      // Trigger hide
      QuantumVM.instance.store.set('visible', false);
      await tester.pumpAndSettle();

      // Pane 2 should take full width (1000px)
      final p2Size = tester.getSize(qKey('p2'));
      expect(p2Size.width, 1000.0);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 7. Morph Surface Suite
  // ════════════════════════════════════════════════════════════════════════════
  group('7. Morph Surface Suite', () {
    testWidgets('7.2 Negative Dimensional Drag & Bounding limits',
        (tester) async {
      final ui = {
        "type": "box:morph",
        "props": {"id": "morph", "width": 100, "height": 100},
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

      final boxFinder = qKey('morph');
      final handles =
          find.descendant(of: boxFinder, matching: find.byType(Container));

      // Drag bottom-right handle far top-left into negative size
      await tester.drag(handles.last, const Offset(-500.0, -500.0));
      await tester.pumpAndSettle();

      final newSize = tester.getSize(boxFinder);
      expect(newSize.width, greaterThan(0.0)); // Clamped
      expect(newSize.height, greaterThan(0.0)); // Clamped
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 8. Global Responsiveness & Engine Armor
  // ════════════════════════════════════════════════════════════════════════════
  group('8. Global Responsiveness & Engine Armor', () {
    testWidgets('8.1 Rapid Breakpoint Thrashing', (tester) async {
      final ui = {
        "type": "box:col",
        "children": [
          {
            "type": "box",
            "props": {"\$if": "{{!isCompact}}"},
            "children": [
              {
                "type": "text",
                "props": {"text": "Desktop"}
              }
            ]
          },
          {
            "type": "box",
            "props": {"\$if": "{{isCompact}}"},
            "children": [
              {
                "type": "text",
                "props": {"text": "Mobile"}
              }
            ]
          },
        ]
      };
      setScreenSize(tester, const Size(1920, 1080));
      await tester.pumpWidget(buildApp(ui));
      await tester.pumpAndSettle();
      expect(find.text("Desktop"), findsOneWidget);

      for (int i = 0; i < 10; i++) {
        setScreenSize(tester, const Size(375, 812));
        await tester.pumpAndSettle();
        expect(find.text("Mobile"), findsOneWidget);

        setScreenSize(tester, const Size(1920, 1080));
        await tester.pumpAndSettle();
        expect(find.text("Desktop"), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('8.3 Double Infinity Russian Doll', (tester) async {
      setScreenSize(tester, const Size(500, 500));
      await tester.pumpWidget(buildApp(TestPayloads.infinityBait()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text("Infinity Armor Holds"), findsOneWidget);
    });
  });
}
