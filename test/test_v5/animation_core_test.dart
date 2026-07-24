import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_v1/test_support.dart';

void main() {
  setUp(() async {
    await bootstrapQuantumTestVm();
  });

  group('Animation Core Sub-types (T3.1)', () {
    testWidgets('animation:fade (fallback for morph alias)', (WidgetTester tester) async {
      final node = blueprint('animation:morph', children: [
        blueprint('text', props: {'text': 'Hello'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('animation:cross_fade', (WidgetTester tester) async {
      final node = blueprint('animation:cross', 
        slots: {
          'first': blueprint('text', props: {'text': 'First'}),
          'second': blueprint('text', props: {'text': 'Second'}),
        },
        props: {'showFirst': true}
      );
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('First'), findsOneWidget);
    });

    testWidgets('animation:keyframe', (WidgetTester tester) async {
      final node = blueprint('animation:keyframe', props: {
        'from': {'x': 0, 'opacity': 0.0},
        'to': {'x': 100, 'opacity': 1.0},
      }, children: [blueprint('text', props: {'text': 'KF'})]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('KF'), findsOneWidget);
    });

    testWidgets('animation:stagger', (WidgetTester tester) async {
      final node = blueprint('animation:stagger', children: [
        blueprint('text', props: {'text': '1'}),
        blueprint('text', props: {'text': '2'}),
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('animation:sequence', (WidgetTester tester) async {
      final node = blueprint('animation:sequence', props: {
        'steps': [{'from': 0.0, 'to': 1.0, 'weight': 1.0}]
      }, children: [blueprint('text', props: {'text': 'Seq'})]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Seq'), findsOneWidget);
    });

    testWidgets('animation:particle', (WidgetTester tester) async {
      final node = blueprint('animation:particle', props: {'count': 10}, children: [
        blueprint('text', props: {'text': 'Sparkle'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Sparkle'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('animation:counter', (WidgetTester tester) async {
      final node = blueprint('animation:counter', props: {'from': 0.0, 'to': 100.0, 'decimals': 0});
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('100'), findsOneWidget); // End value
    });

    testWidgets('animation:spring', (WidgetTester tester) async {
      final node = blueprint('animation:spring', props: {'from': 0.5, 'to': 1.0}, children: [
        blueprint('text', props: {'text': 'Boring'})
      ]);
      await pumpBlueprintAndSettle(tester, node);
      expect(find.text('Boring'), findsOneWidget);
    });
  });
}
