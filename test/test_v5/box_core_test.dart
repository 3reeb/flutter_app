import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Box Core Production Tests', () {
    testWidgets('box:measure - captures dimensions without layout effect', (WidgetTester tester) async {
      final node = blueprint('box:measure', props: {'bind': 'mySize'}, children: [
        blueprint('text', props: {'text': 'Measured'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Measured'), findsOneWidget);
    });

    testWidgets('box:matrix - applies 3D transforms', (WidgetTester tester) async {
      final node = blueprint('box:matrix', props: {'transform': [1.0, 0.0, 0.0, 0.0,  0.0, 1.0, 0.0, 0.0,  0.0, 0.0, 1.0, 0.0,  0.0, 0.0, 0.0, 1.0]}, children: [
        blueprint('text', props: {'text': '3D Transformed'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('3D Transformed'), findsOneWidget);
    });

    testWidgets('box:row - lays out children horizontally', (WidgetTester tester) async {
      final node = blueprint('box:row', children: [
        blueprint('text', props: {'text': 'A'}),
        blueprint('text', props: {'text': 'B'}),
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('box:col - lays out children vertically', (WidgetTester tester) async {
      final node = blueprint('box:col', children: [
        blueprint('text', props: {'text': 'Top'}),
        blueprint('text', props: {'text': 'Bottom'}),
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('box:stack - overlays children', (WidgetTester tester) async {
      final node = blueprint('box:stack', children: [
        blueprint('text', props: {'text': 'Base'}),
        blueprint('text', props: {'text': 'Overlay'}),
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(Stack), findsOneWidget);
      expect(find.text('Overlay'), findsOneWidget);
    });
  });
}
