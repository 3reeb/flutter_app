import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('System Core Sub-types (T2.3.4)', () {
    testWidgets('system:upload', (WidgetTester tester) async {
      final node = blueprint('system:upload', children: [
        blueprint('text', props: {'text': 'UploadNode'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('UploadNode'), findsOneWidget);
    });

    testWidgets('system:download', (WidgetTester tester) async {
      final node = blueprint('system:download', children: [
        blueprint('text', props: {'text': 'DownloadNode'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('DownloadNode'), findsOneWidget);
    });

    testWidgets('system:notification', (WidgetTester tester) async {
      final node = blueprint('system:notification');
      await pumpBlueprintAndSettle(tester, node);
      expect(find.byType(SizedBox), findsOneWidget); // Expecting SizedBox.shrink()
    });

    testWidgets('system:share', (WidgetTester tester) async {
      final node = blueprint('system:share', children: [
        blueprint('text', props: {'text': 'ShareBtn'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('ShareBtn'), findsOneWidget);
    });

    testWidgets('system:sensor', (WidgetTester tester) async {
      final node = blueprint('system:sensor', children: [
        blueprint('text', props: {'text': 'Accelerometer'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Accelerometer'), findsOneWidget);
    });
  });
}
