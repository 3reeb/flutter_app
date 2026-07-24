import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Text Core Production Tests', () {
    testWidgets('text - basic rendering', (WidgetTester tester) async {
      final node = blueprint('text', props: {'text': 'Hello World'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('text:rich - inline spans', (WidgetTester tester) async {
      final node = blueprint('text:rich', props: {'text': 'Rich Text'}, children: [
        blueprint('text:span', props: {'text': ' Bold'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('text:markdown - markdown parsing', (WidgetTester tester) async {
      final node = blueprint('text:markdown', props: {'text': '# Title'});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('# Title'), findsOneWidget); // Assuming basic text fallback if no markdown plugin
    });
  });
}
