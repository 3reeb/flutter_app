import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Field Core Production Tests', () {
    testWidgets('field:text - basic input', (WidgetTester tester) async {
      final node = blueprint('field:text', props: {'placeholder': 'Enter name'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter name'), findsOneWidget); // Usually placeholder is found
    });

    testWidgets('field:number - numeric input', (WidgetTester tester) async {
      final node = blueprint('field:number', props: {'placeholder': 'Age'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('field:switch - boolean toggle', (WidgetTester tester) async {
      final node = blueprint('field:switch', props: {'bind': 'isActive'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('field:checkbox - boolean check', (WidgetTester tester) async {
      final node = blueprint('field:checkbox', props: {'bind': 'accepted'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(Checkbox), findsOneWidget);
    });

    testWidgets('field:slider - numeric slider', (WidgetTester tester) async {
      final node = blueprint('field:slider', props: {'min': 0.0, 'max': 100.0, 'bind': 'volume'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('field:dropdown - select from options', (WidgetTester tester) async {
      final node = blueprint('field:dropdown', props: {
        'options': [{'label': 'A', 'value': 'A'}, {'label': 'B', 'value': 'B'}],
        'bind': 'choice'
      });
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });
  });
}
