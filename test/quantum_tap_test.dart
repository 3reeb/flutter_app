import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// import your quantum.dart
import 'package:quantum_layout/quantum.dart';

void main() {
  setUp(() => QuantumVM.instance.initialize());
  tearDown(() => QuantumVM.instance.dispose());

  testWidgets('DIAGNOSTIC: AST Parsing & Action Extraction', (tester) async {
    bool actionFired = false;

    QuantumVM.instance.registerAction(
      'test.action',
      LambdaActionPlugin((payload, store, ctx) async {
        actionFired = true;
        return null;
      }),
    );

    final jsonPayload = {
      'type': 'box',
      'style': 'w-100 h-100 bg-blue-500',
      'props': {
        'text': 'AST Tap Test',
        'onClick': [
          {'action': 'test.action'}
        ]
      }
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QLSmartView(manifest: {'id': 'test', 'ui': jsonPayload}),
        ),
      ),
    );

    // 🚀 THE FIX: Wait for QLSmartView to compile the AST!
    await tester.pumpAndSettle();

    expect(find.text('AST Tap Test'), findsOneWidget); // Will now succeed
    await tester.tap(find.text('AST Tap Test'));
    await tester.pumpAndSettle();

    expect(actionFired, isTrue); // Will now succeed
  });
}
