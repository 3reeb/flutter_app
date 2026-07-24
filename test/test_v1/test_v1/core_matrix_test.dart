import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  test('all top-level core plugins are registered', () {
    for (final core in <String>[
      'box',
      'action',
      'field',
      'text',
      'media',
      'visual',
      'hook',
      'data',
      'portal',
      'control',
      'canvas',
      'system',
      'template',
      'layout',
      'decoration',
      'chart',
      'animation',
    ]) {
      expect(QuantumVM.instance.hasPlugin(core), isTrue,
          reason: 'missing $core');
    }
  });

  test('core aliases resolve to their canonical targets', () {
    expect(QuantumVM.instance.getAlias('image')?['type'], 'media:image');
    expect(QuantumVM.instance.getAlias('avatar')?['type'], 'media:avatar');
    expect(QuantumVM.instance.getAlias('chart')?['type'], 'media:chart');
    expect(QuantumVM.instance.getAlias('row')?['type'], 'box:row');
    expect(QuantumVM.instance.getAlias('col')?['type'], 'box:col');
    expect(QuantumVM.instance.getAlias('overlay')?['type'], 'portal:overlay');
  });

  testWidgets(
      'representative visual and system cores still render in smoke paths',
      (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:chart',
        props: <String, dynamic>{
          'chartType': 'line',
          'data': <dynamic>[1, 2, 3]
        },
      ),
    );
    expect(find.byType(QLUniversalChart), findsOneWidget);

    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'visual:animation',
        props: <String, dynamic>{
          'animationType': 'fade',
          'from': 0.0,
          'to': 1.0
        },
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'x'})
        ],
      ),
    );
    expect(find.byType(TweenAnimationBuilder), findsOneWidget);

    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'system:timer',
        props: <String, dynamic>{'interval': 1, 'autoStart': false},
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'tick'})
        ],
      ),
    );
    expect(find.text('tick'), findsOneWidget);
  });
}
