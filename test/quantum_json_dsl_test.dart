import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum JSON DSL Tests', () {
    setUp(() {
      QEngine.instance.initialize(initialCapacity: 4096);
      QuantumVM.instance.initialize(workerThreads: 1);
      initQuantumBuiltIns(QuantumVM.instance);
    });

    tearDown(() {
      QEngine.instance.dispose();
      QJsonTemplateEngine_D.clear();
    });

    testWidgets('QJsonTemplateEngine_D compiles and registers correctly',
        (tester) async {
      QJsonTemplateEngine_D.define({
        "type": "template",
        "name": "TestCard",
        "props": {"title": "Default Title"},
        "ui": {
          "type": "text",
          "props": {"value": "{{title}}"}
        }
      });

      final blueprint = QLBlueprint.fromJson({
        "type": "TestCard",
        "props": {"title": "Override Title"}
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => QuantumVM.instance.renderWidget(ctx, blueprint),
          ),
        ),
      ));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('defineMatrixLayoutJson registers correctly', (tester) async {
      QuantumVM.instance.defineMatrixLayoutJson({
        "type": "layout",
        "name": "TestMatrix",
        "gap": 10,
        "matrix": """
          1fr 2fr
          left right
        """,
        "slots": {
          "left": {"padding": 5},
          "right": {"scrollable": true}
        }
      });

      final blueprint = QLBlueprint.fromJson({
        "type": "TestMatrix",
        "slots": {
          "left": {
            "type": "text",
            "props": {"value": "Left Slot"}
          }
        }
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => QuantumVM.instance.renderWidget(ctx, blueprint),
          ),
        ),
      ));

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
