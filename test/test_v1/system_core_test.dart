import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  testWidgets('system:data_pipe allocates and updates a Float64List in the store', (tester) async {
    QuantumVM.instance.store.set('pipeline.input', 0.0);

    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'system:data_pipe',
        props: <String, dynamic>{
          'bindSource': 'pipeline.input',
          'bindOutput': 'pipeline.output',
          'size': 8,
        },
      ),
    );

    final value = QuantumVM.instance.store.get('pipeline.output');
    expect(value, isA<Float64List>());
    expect((value as Float64List).length, 8);

    QuantumVM.instance.store.set('pipeline.input', 3.5);
    await tester.pump();
    await tester.pump();

    final updated = QuantumVM.instance.store.get('pipeline.output');
    expect(updated, isA<Float64List>());
    expect((updated as Float64List)[7], closeTo(3.5, 1e-9));
  });

  testWidgets('system:store_provider seeds initial state into the store', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'system:store_provider',
        props: <String, dynamic>{
          'initialState': <String, dynamic>{
            'theme.mode': 'dark',
            'layout.density': 'compact',
            'feature.flags.beta': true,
          },
        },
      ),
    );

    expect(QuantumVM.instance.store.get('theme.mode'), 'dark');
    expect(QuantumVM.instance.store.get('layout.density'), 'compact');
    expect(QuantumVM.instance.store.get('feature.flags.beta'), true);
  });

  testWidgets('system:lifecycle no longer performs lifecycle hooks', (tester) async {
    final events = <String>[];
    registerSpyAction('spy.mount', events, 'mount');

    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'system:lifecycle',
        props: <String, dynamic>{
          'onMount': <dynamic>[
            <dynamic>['spy.mount', <String, dynamic>{'value': 'x'}],
          ],
        },
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'system'}),
        ],
      ),
    );

    expect(events, isEmpty);
    expect(find.text('system'), findsOneWidget);
  });

  testWidgets('system:timer renders its child and remains mountable', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'system:timer',
        props: <String, dynamic>{
          'interval': 1,
          'autoStart': false,
        },
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'timer'}),
        ],
      ),
    );

    expect(find.text('timer'), findsOneWidget);
  });

  testWidgets('system base plugin is registered', (tester) async {
    await bootstrapQuantumTestVm();
    expect(QuantumVM.instance.hasPlugin('system'), isTrue);
  });
}
