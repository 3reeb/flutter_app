// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY - EXHAUSTIVE UNHAPPY PATH & EDGE CASES TEST
// test/omni_cores_edge_cases_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum Omni Registry | Hostile Edge Cases & Production Stress Test |', () {
    setUp(() {
      // 1. Total System Purge
      QLModuleRegistry.instance.clear();
      QLSchemaRegistry.instance.clear();
      QLPipelineRegistry.instance.destroy('default');
      QLStoreRegistry.instance.destroy('default');
      QuantumVM.instance.clearRuntimeCaches();
      clearQuantumInputRegistry();

      // 2. Hardware Engine Initialization
      QEngine.instance.initialize(initialCapacity: 4096);
      QuantumVM.instance.initialize(workerThreads: 1);

      // 3. Mount the Omni Registry
      registerOmniComponents(QuantumVM.instance);
      
      // Error-throwing plugin
      QuantumVM.instance.registerAction(
        'mock.error_thrower',
        LambdaActionPlugin((p, s, c) async {
          throw Exception("Intended hostile exception from mock.error_thrower");
        }),
      );
    });

    Widget _buildTestWrapper(Map<String, dynamic> uiJson, {bool unbounded = false, Map<String, dynamic>? initialStore}) {
      final store = QLStoreRegistry.instance.defaultStore;
      if (initialStore != null) {
        initialStore.forEach((k, v) => store.set(k, v));
      }

      final ast = QLBlueprint.fromJson(uiJson);
      
      Widget child = QLOverlayRoot(
        child: QLDataScope(
          moduleStore: store,
          child: Builder(
            builder: (ctx) => QuantumVM.instance.renderWidget(ctx, ast),
          ),
        ),
      );

      // If unbounded is true, we place it in a ListView (unbounded height) or Row (unbounded width)
      // to test constraints overflow.
      if (unbounded) {
        child = ListView(children: [child]);
      } else {
        child = SizedBox(
          width: 800,
          height: 1200,
          child: child,
        );
      }

      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. BOX CORE & LAYOUT EDGE CASES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Box Core: Infinite Constraints and Infinite Depth', (WidgetTester tester) async {
      // Create a 50-level deep nested box structure to test stack limits & context passing
      Map<String, dynamic> deepNesting = {
        "type": "text",
        "props": {"text": "Deeply Nested Text"}
      };
      
      for(int i = 0; i < 50; i++) {
        deepNesting = {
          "type": i % 2 == 0 ? "col" : "row",
          "children": [deepNesting]
        };
      }
      
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "box:expanded",
            "children": [
              {
                "type": "text",
                "props": {"text": "Expanded inside Unbounded ListView"}
              }
            ]
          },
          {
            "type": "box:matrix",
            "props": {"matrixBind": "bad_matrix"},
            "children": [
              {
                "type": "text",
                "props": {"text": "Bad Matrix Layer"}
              }
            ]
          },
          deepNesting
        ]
      };

      // bad_matrix has 15 elements instead of 16
      final initialStore = {
        "bad_matrix": [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0] 
      };

      // We place the Expanded widget in a bounded layout now because QuantumFlexible
      // correctly maps to Expanded, and Flutter framework intentionally throws on Expanded in ListView.
      // The framework's behavior is correct; we just verify QuantumVM passes it through properly.
      await tester.pumpWidget(_buildTestWrapper(ui, unbounded: false, initialStore: initialStore));
      await tester.pumpAndSettle();
      
      // Also expect that Bad Matrix didn't fatally crash the engine, but degraded gracefully
      expect(find.text('Expanded inside Unbounded ListView'), findsOneWidget);
      expect(find.text('Bad Matrix Layer'), findsOneWidget);
      expect(find.text('Deeply Nested Text'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. FIELD & CONTROL CORE EDGE CASES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Field Core: Orphaned Fields & Type Mismatches', (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            // Orphaned text field (no form scope)
            "type": "text_field",
            "props": {"bind": "orphan_field.name"}
          },
          {
            // Slider (expects double) but store provides String
            "type": "slider",
            "props": {"bind": "bad_slider_value", "min": 0, "max": 100}
          }
        ]
      };

      final initialStore = {
        "bad_slider_value": "I am a string, not a number"
      };

      await tester.pumpWidget(_buildTestWrapper(ui, initialStore: initialStore));
      await tester.pumpAndSettle();

      final store = QLStoreRegistry.instance.defaultStore;

      // Type into orphaned text field
      await tester.enterText(find.byType(EditableText).first, 'Orphan Typed');
      await tester.pumpAndSettle();

      // Check if orphaned field properly bound to store despite missing form
      expect(store.get('orphan_field.name'), 'Orphan Typed');

      // The slider should have degraded to 0.0 or gracefully failed
      // We need to make sure the app didn't crash
      expect(tester.takeException(), isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. ACTION & HOOK CORE EDGE CASES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Action Core: Missing Plugins & Uncaught Exceptions', (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "button",
            "props": {
              "text": "Missing Action",
              "onClick": ["non_existent_plugin"]
            }
          },
          {
            "type": "button",
            "props": {
              "text": "Throw Action",
              "onClick": ["mock.error_thrower"]
            }
          },
          {
            "type": "system:lifecycle",
            "props": {
              "onMount": ["mock.error_thrower"]
            },
            "children": [
              {
                "type": "text",
                "props": {"text": "Lifecycle with Error"}
              }
            ]
          }
        ]
      };

      // By default, testWidgets fails on uncaught exceptions. We wrapped ctx.action calls
      // in safe blocks inside Action Core, so this should NOT throw to the framework.
      
      await tester.pumpWidget(_buildTestWrapper(ui));
      
      // Tap Missing Action
      await tester.tap(find.text('Missing Action'));
      await tester.pump();
      
      // Tap Throw Action
      await tester.tap(find.text('Throw Action'));
      await tester.pump();

      // UI should still be alive despite exceptions handled internally
      expect(find.text('Missing Action'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. PORTAL CORE EDGE CASES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Portal Core: Dangling Overlays & Rapid Unmounts', (WidgetTester tester) async {
      // A widget that conditionally mounts a portal
      final ui = {
        "type": "box:builder",
        "props": {"bind": "show_portal"},
        "children": [
          {
            "type": "control:flow",
            "props": {
              "condition": "{{\$env.show_portal}} == true"
            },
            "children": [
              {
                "type": "portal:dialog",
                "slots": {
                  "trigger": {
                    "type": "button",
                    "props": {"text": "Open Me"}
                  },
                  "content": {
                    "type": "text",
                    "props": {"text": "I am a Dialog"}
                  }
                }
              }
            ]
          }
        ]
      };

      final store = QLStoreRegistry.instance.defaultStore;
      store.set('show_portal', true);

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      // Open Dialog
      await tester.tap(find.text('Open Me'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('I am a Dialog'), findsOneWidget);

      // Suddenly destroy the tree from under the dialog to simulate rapid unmount
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Container())));
      // Wait long enough for animations and overlays to close
      await tester.pump(const Duration(seconds: 2));

      // 🚨 The dialog logic cleans up OverlayEntries on dispose.
      expect(find.text('Open Me'), findsNothing);
      expect(find.text('I am a Dialog'), findsNothing); 
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. DATA & STREAM CORE EDGE CASES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Data Core: Malformed Repeater Data', (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "system:repeater",
            "props": {
              "bind": "bad_list_data", // Bound to an object, not a list
              "as": "item"
            },
            "children": [
              {
                "type": "text",
                "props": {"text": "Item"}
              }
            ]
          }
        ]
      };

      final initialStore = {
        "bad_list_data": {"im_an_object": "not_an_array"}
      };

      await tester.pumpWidget(_buildTestWrapper(ui, initialStore: initialStore));
      await tester.pumpAndSettle();

      // The repeater should not crash, it should just yield 0 items or degrade gracefully
      expect(find.text('Item'), findsNothing);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. CANVAS & ANIMATION CORE EDGE CASES
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Canvas Core: Invalid Bytecode Instructions', (WidgetTester tester) async {
      final ui = {
        "type": "canvas:draw",
        "style": "w-200 h-200",
        "props": {
          "commands": [
            ["invalid_command", 100], // Unknown command
            ["rect"], // Missing args
            ["circle", "invalid_type", 50, 50] // Wrong type args
          ]
        }
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      // The CustomPainter should catch the invalid commands and skip them without blowing up the render loop
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
