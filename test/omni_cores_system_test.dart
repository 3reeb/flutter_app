// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY - HOSTILE SYSTEM CORES TESTS
// test/omni_cores_system_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Hostile Quantum Omni Registry | System Cores |', () {
    setUp(() {
      QLModuleRegistry.instance.clear();
      QLSchemaRegistry.instance.clear();
      QLPipelineRegistry.instance.destroy('default');
      QLStoreRegistry.instance.destroy('default');
      QuantumVM.instance.clearRuntimeCaches();

      QEngine.instance.initialize(initialCapacity: 1024);
      QuantumVM.instance.initialize(workerThreads: 1);
      registerOmniComponents(QuantumVM.instance);
    });

    Widget _buildTestWrapper(Map<String, dynamic> uiJson) {
      final ast = QLBlueprint.fromJson(uiJson);
      return MaterialApp(
        home: Scaffold(
          body: QLOverlayRoot(
            child: QLDataScope(
              moduleStore: QLStoreRegistry.instance.defaultStore,
              child: Builder(
                builder: (ctx) => QuantumVM.instance.renderWidget(ctx, ast),
              ),
            ),
          ),
        ),
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. COMPONENT CORE (Infinite Recursion)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Component Core: Infinite Recursion aborts cleanly', (WidgetTester tester) async {
      // We define a component that uses itself
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "component:define",
            "props": {
               "name": "recursive_comp"
            },
            "children": [
              {
                "type": "component:use",
                "props": {"name": "recursive_comp"}
              }
            ]
          },
          {
            "type": "component:use",
            "props": {"name": "recursive_comp"}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      // If it hit recursion limits and bailed instead of stack overflowing, we pass.
      expect(tester.takeException(), isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. TEMPLATE CORE (Malformed Syntax / Massive conditions)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Template Core: Broken bindings gracefully fail', (WidgetTester tester) async {
      final ui = {
        "type": "template:if",
        "props": {
          "condition": r"((((({{$store.malformed}} + 'broken' ||| && {"
        },
        "children": [
          {
            "type": "text",
            "props": {"text": "Visible Content"}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();
      
      expect(find.text('Visible Content'), findsNothing);
    });

    testWidgets('Template Core: List item basic sanity', (WidgetTester tester) async {
      final ui = {
        "type": "template:list_item",
        "props": {
          "item": {"label": "Hello"}
        }
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. DATA CORE (Negative Slice RangeError)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Data Core: Negative limit throws RangeError crash if unhandled', (WidgetTester tester) async {
      final ui = {
        "type": "data:slice",
        "props": {
          "bind": [1, 2, 3],
          "start": 1,
          "limit": -5
        },
        "children": [
          {"type": "text", "props": {"text": "Slice"}}
        ]
      };
      await tester.pumpWidget(_buildTestWrapper(ui));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. TEMPLATE CORE (Infinite Menu Recursion)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Template Core: Infinite menu items trigger StackOverflow', (WidgetTester tester) async {
      List<dynamic> deepItems(int depth) {
        if (depth == 0) return [{'label': 'end'}];
        return [{'label': 'L$depth', 'children': deepItems(depth - 1)}];
      }
      final ui = {
        "type": "template:rich_menu",
        "props": {
          "items": deepItems(100) // Stack overflow hazard
        }
      };
      await tester.pumpWidget(_buildTestWrapper(ui));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. SYSTEM CORE (Malformed Repeater object mapping)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('System Core: Repeater binding to Deep Recursive Object', (WidgetTester tester) async {
      final ui = {
        "type": "system:repeater",
        "props": {
          "bind": "deepObj",
          "as": "item"
        },
        "children": [
          {
            "type": "text",
            "props": {"text": r"Item: {{$env.item}}"}
          }
        ]
      };

      // Create a recursive data object
      final Map<String, dynamic> recursiveMap = {};
      recursiveMap['self'] = recursiveMap;

      final store = QLStoreRegistry.instance.defaultStore;
      store.set('deepObj', recursiveMap);

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();

      // The repeater should just yield 0 items or a safe iteration since it's not a list
      expect(find.text('Item: '), findsNothing);
    });
  });
}
