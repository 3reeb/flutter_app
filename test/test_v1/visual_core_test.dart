import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  testWidgets('visual:box delegates to box primitives', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:box',
        props: <String, dynamic>{'boxType': 'safe'},
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'safe'}),
        ],
      ),
    );

    expect(find.byType(SafeArea), findsOneWidget);
    expect(find.text('safe'), findsOneWidget);
  });

  testWidgets('visual:chart renders the chart stack', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:chart',
        props: <String, dynamic>{
          'chartType': 'line',
          'data': <dynamic>[1, 2, 3, 2, 4],
          'animated': false,
        },
      ),
    );

    expect(find.byType(QLUniversalChart), findsOneWidget);
    expect(find.byType(QLBox), findsWidgets);
  });

  testWidgets('visual:animation delegates to animation core', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:animation',
        props: <String, dynamic>{'animationType': 'fade', 'from': 0.0, 'to': 1.0},
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'fade'}),
        ],
      ),
    );

    expect(find.byType(TweenAnimationBuilder), findsOneWidget);
    expect(find.text('fade'), findsOneWidget);
  });

  testWidgets('visual:scene builds an isolated scene layer', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:scene',
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'scene'}),
        ],
      ),
    );

    expect(find.byType(QLSceneLayerWidget), findsOneWidget);
    expect(find.byType(RepaintBoundary), findsWidgets);
  });

  testWidgets('visual:overlay composes base content and overlay slot', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:overlay',
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'base'}),
        ],
        slots: <String, QLBlueprint>{
          'overlay': blueprint('text:p', props: <String, dynamic>{'value': 'top'}),
        },
      ),
    );

    expect(find.text('base'), findsOneWidget);
    expect(find.text('top'), findsOneWidget);
  });

  testWidgets('visual:stack creates a full-bleed stack container', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:stack',
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'stacked'}),
        ],
      ),
    );

    expect(find.byType(Stack), findsOneWidget);
    expect(find.text('stacked'), findsOneWidget);
  });

  testWidgets('visual base plugin is registered', (tester) async {
    await bootstrapQuantumTestVm();
    expect(QuantumVM.instance.hasPlugin('visual'), isTrue);
    expect(QuantumVM.instance.hasAlias('visual'), isFalse);
  });
}
