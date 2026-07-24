import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Action Core Production Tests', () {
    testWidgets('action:raw_pointer - catches pointer events', (WidgetTester tester) async {
      final node = blueprint('action:raw_pointer', children: [
        blueprint('text', props: {'text': 'Touch Target'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Touch Target'), findsOneWidget);
      expect(find.byType(Listener), findsOneWidget);
    });

    testWidgets('action:focus - manages focus states', (WidgetTester tester) async {
      final node = blueprint('action:focus', children: [
        blueprint('text', props: {'text': 'Focusable'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Focusable'), findsOneWidget);
      expect(find.byType(Focus), findsOneWidget);
    });

    testWidgets('action:shortcut - binds keyboard shortcuts', (WidgetTester tester) async {
      final node = blueprint('action:shortcut', props: {'bind': 'ctrl+s', 'action': 'save'}, children: [
        blueprint('text', props: {'text': 'ShortcutTarget'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('ShortcutTarget'), findsOneWidget);
      expect(find.byType(Focus), findsOneWidget); // Usually wrapped in Focus to capture keys
    });
  });
}
