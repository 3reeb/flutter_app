import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Data Core Sub-types (T5.1)', () {
    testWidgets('data:realtime', (WidgetTester tester) async {
      final node = blueprint('data:realtime', props: {'channel': 'chat'}, children: [
        blueprint('text', props: {'text': 'Realtime Node'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Realtime Node'), findsOneWidget);
    });

    testWidgets('data:paginated', (WidgetTester tester) async {
      final node = blueprint('data:paginated', props: {'action': 'loadMore'}, children: [
        blueprint('text', props: {'text': 'Page1'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Page1'), findsOneWidget);
    });

    testWidgets('data:virtual_scroll', (WidgetTester tester) async {
      // Must put some data into the store signal
      QuantumVM.instance.store.signal('myList').value = [1, 2, 3];
      
      final node = blueprint('data:virtual_scroll', 
        props: {'bind': 'myList', 'itemHeight': 50.0},
        slots: {
          'item': blueprint('text', props: {'text': 'Item'})
        }
      );
      
      await pumpBlueprint(tester, node); // ListView doesn't settle immediately sometimes, but pump is enough here.
      expect(find.text('Item'), findsWidgets);
    });

    testWidgets('data:aggregate', (WidgetTester tester) async {
      final node = blueprint('data:aggregate', props: {'sources': ['a', 'b']}, children: [
        blueprint('text', props: {'text': 'Agg'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Agg'), findsOneWidget);
    });

    testWidgets('data:timeline', (WidgetTester tester) async {
      final node = blueprint('data:timeline', children: [
        blueprint('text', props: {'text': 'Time'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Time'), findsOneWidget);
    });

    testWidgets('data:infinite', (WidgetTester tester) async {
      final node = blueprint('data:infinite', children: [
        blueprint('text', props: {'text': 'Inf'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Inf'), findsOneWidget);
    });
  });
}
