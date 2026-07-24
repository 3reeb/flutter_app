import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Layout Core Production Tests', () {
    testWidgets('layout:grid - grid view', (WidgetTester tester) async {
      final node = blueprint('layout:grid', props: {'columns': 2}, children: [
        blueprint('text', props: {'text': 'Grid1'}),
        blueprint('text', props: {'text': 'Grid2'}),
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('Grid1'), findsOneWidget);
    });

    testWidgets('layout:wrap - wrapping flow', (WidgetTester tester) async {
      final node = blueprint('layout:wrap', children: [
        blueprint('text', props: {'text': 'Wrap1'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.text('Wrap1'), findsOneWidget);
    });

    testWidgets('layout:scroll - simple scroll view', (WidgetTester tester) async {
      final node = blueprint('layout:scroll', children: [
        blueprint('text', props: {'text': 'Scroll1'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
