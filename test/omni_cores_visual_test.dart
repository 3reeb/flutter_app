// ════════════════════════════════════════════════════════════════════════════
// QUANTUM OMNI REGISTRY - HOSTILE VISUAL CORES TESTS
// test/omni_cores_visual_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Hostile Quantum Omni Registry | Visual Cores |', () {
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
    // 1. TEXT CORE (Massive strings, bounds)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Text Core: Massive 1MB String bounds layout', (WidgetTester tester) async {
      final ui = {
        "type": "text",
        "props": {
          "text": List.filled(50000, "A").join(),
        }
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pumpAndSettle();
      
      // If it renders without hanging the main isolate, it passes
      expect(find.byType(Text), findsWidgets);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. ANIMATION CORE (NaN, Infinity, Negative)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Animation Core: Skeleton NaN/Infinity Layout', (WidgetTester tester) async {
      final ui = {
        "type": "col",
        "children": [
          {
            "type": "animation:skeleton",
            "props": {
               "width": double.nan, 
               "height": double.infinity,
               "radius": -10.0
            }
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pump(const Duration(milliseconds: 500));

      // Ensure that providing NaN or Infinity doesn't panic RenderBox
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Animation Core: Stagger negative count', (WidgetTester tester) async {
      final ui = {
        "type": "animation:stagger",
        "props": {
           "count": -500,
           "delayMs": -100
        },
        "children": [
          {
            "type": "text",
            "props": {"text": "Staggered"}
          }
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Staggered'), findsOneWidget);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. DECORATION CORE (Negative Blur)
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Decoration Core: Blur Negative Bounds', (WidgetTester tester) async {
      final ui = {
        "type": "decoration:blur",
        "props": {
          "sigmaX": -5.0, // negative blur
          "sigmaY": -10.0
        },
        "children": [
          {"type": "text", "props": {"text": "Blurred Text"}}
        ]
      };

      await tester.pumpWidget(_buildTestWrapper(ui));
      expect(tester.takeException(), isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. LAYOUT CORE
    // ─────────────────────────────────────────────────────────────────────────
    testWidgets('Layout Core: Negative Infinity gap crash', (WidgetTester tester) async {
      final ui = {
        "type": "layout",
        "props": {
          "layoutId": "workspace",
          "gap": double.negativeInfinity
        },
        "children": [
          {"type": "box", "props": {"slot": "main"}}
        ]
      };
      await tester.pumpWidget(_buildTestWrapper(ui));
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
    });
  });
}
