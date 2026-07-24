import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Connect Core Sub-types (T6.1)', () {
    testWidgets('connect:socket', (WidgetTester tester) async {
      final node = blueprint('connect:socket', children: [
        blueprint('text', props: {'text': 'SocketConnected'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('SocketConnected'), findsOneWidget);
    });

    testWidgets('connect:channel', (WidgetTester tester) async {
      final node = blueprint('connect:channel', children: [
        blueprint('text', props: {'text': 'ChannelSync'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('ChannelSync'), findsOneWidget);
    });

    testWidgets('connect:presence', (WidgetTester tester) async {
      final node = blueprint('connect:presence', children: [
        blueprint('text', props: {'text': 'Online'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Online'), findsOneWidget);
    });

    testWidgets('connect:behavior (tilt_3d)', (WidgetTester tester) async {
      final node = blueprint('connect:behavior', props: {'contract': 'tilt_3d'}, children: [
        blueprint('text', props: {'text': 'Tilt Me'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Tilt Me'), findsOneWidget);
    });

    testWidgets('connect:behavior (glassmorphism)', (WidgetTester tester) async {
      final node = blueprint('connect:behavior', props: {'contract': 'glassmorphism'}, children: [
        blueprint('text', props: {'text': 'Glass'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Glass'), findsOneWidget);
    });
  });
}
