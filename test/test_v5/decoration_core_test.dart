import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Decoration Core Sub-types (T2.3.5)', () {
    testWidgets('decoration:blur', (WidgetTester tester) async {
      final node = blueprint('decoration:blur', props: {'sigma': 5.0}, children: [
        blueprint('text', props: {'text': 'Blurred'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Blurred'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('decoration:gradient', (WidgetTester tester) async {
      final node = blueprint('decoration:gradient', props: {'beginColor': '#FF0000', 'endColor': '#00FF00'}, children: [
        blueprint('text', props: {'text': 'Grad'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Grad'), findsOneWidget);
      expect(find.byType(DecoratedBox), findsOneWidget);
    });

    testWidgets('decoration:border', (WidgetTester tester) async {
      final node = blueprint('decoration:border', props: {'width': 2.0}, children: [
        blueprint('text', props: {'text': 'Bordered'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Bordered'), findsOneWidget);
    });

    testWidgets('decoration:shadow', (WidgetTester tester) async {
      final node = blueprint('decoration:shadow', props: {'blur': 10.0}, children: [
        blueprint('text', props: {'text': 'Shadowed'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Shadowed'), findsOneWidget);
    });

    testWidgets('decoration:badge', (WidgetTester tester) async {
      final node = blueprint('decoration:badge', props: {'label': '99+'}, children: [
        blueprint('text', props: {'text': 'Icon'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('Icon'), findsOneWidget);
    });

    testWidgets('decoration:skeleton', (WidgetTester tester) async {
      final node = blueprint('decoration:skeleton', props: {'width': 100, 'height': 20});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(AnimatedBuilder), findsWidgets); // Skeleton uses AnimatedBuilder internally
    });

    testWidgets('decoration:ripple', (WidgetTester tester) async {
      final node = blueprint('decoration:ripple', children: [
        blueprint('text', props: {'text': 'Press Me'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(InkWell), findsOneWidget);
    });
  });
}
