import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import '../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await bootstrapQuantumTestVm();
  });

  testWidgets('hook:lifecycle executes mount and unmount actions', (tester) async {
    final events = <String>[];
    registerSpyAction('spy.mount', events, 'mount');
    registerSpyAction('spy.unmount', events, 'unmount');

    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'hook:lifecycle',
        props: <String, dynamic>{
          'onMount': <dynamic>[
            <dynamic>['spy.mount', <String, dynamic>{'value': '1'}],
          ],
          'onUnmount': <dynamic>[
            <dynamic>['spy.unmount', <String, dynamic>{'value': '2'}],
          ],
        },
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'child'}),
        ],
      ),
    );

    expect(events, contains('mount:1'));

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await tester.pump();

    expect(events, contains('unmount:2'));
  });

  testWidgets('hook:effect runs on mount and re-runs when dependencies change', (tester) async {
    final events = <String>[];
    registerSpyAction('spy.effect', events, 'effect');

    List<dynamic> deps = <dynamic>[1];
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return QLDataScope(
              child: Builder(
                builder: (context) {
                  final node = blueprint(
                    'hook:effect',
                    props: <String, dynamic>{
                      'deps': deps,
                      'onEffect': <dynamic>[
                        <dynamic>['spy.effect', <String, dynamic>{'value': 'run'}],
                      ],
                    },
                    children: <QLBlueprint>[
                      blueprint('text:p', props: <String, dynamic>{'value': 'x'}),
                    ],
                  );
                  return QuantumVM.instance.renderWidget(context, node);
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(events, equals(<String>['effect:run']));

    deps = <dynamic>[2];
    update(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(events, equals(<String>['effect:run', 'effect:run']));
  });

  testWidgets('hook:change skips mount and runs on dependency change only', (tester) async {
    final events = <String>[];
    registerSpyAction('spy.change', events, 'change');

    List<dynamic> deps = <dynamic>['alpha'];
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return QLDataScope(
              child: Builder(
                builder: (context) {
                  final node = blueprint(
                    'hook:change',
                    props: <String, dynamic>{
                      'deps': deps,
                      'onEffect': <dynamic>[
                        <dynamic>['spy.change', <String, dynamic>{'value': 'go'}],
                      ],
                    },
                    children: <QLBlueprint>[
                      blueprint('text:p', props: <String, dynamic>{'value': 'value'}),
                    ],
                  );
                  return QuantumVM.instance.renderWidget(context, node);
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.pump();
    expect(events, isEmpty);

    deps = <dynamic>['beta'];
    update(() {});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(events, equals(<String>['change:go']));
  });

  testWidgets('hook:guard suppresses content when disabled', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'hook:guard',
        props: <String, dynamic>{'enabled': false},
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'hidden'}),
        ],
      ),
    );

    expect(find.text('hidden'), findsNothing);
  });

  testWidgets('hook:memo stabilizes subtree identity by memoKey', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'hook:memo',
        props: <String, dynamic>{'memoKey': 'alpha'},
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': 'memo'}),
        ],
      ),
    );

    expect(find.byType(KeyedSubtree), findsOneWidget);
    expect(find.text('memo'), findsOneWidget);
  });

  testWidgets('hook:delegate can retarget into another core', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'hook:delegate',
        props: <String, dynamic>{
          'target': 'text',
          'delegateProps': <String, dynamic>{'value': 'delegated'},
        },
      ),
    );

    expect(find.text('delegated'), findsOneWidget);
  });

  testWidgets('hook:scope exposes scoped variables to tokenized content', (tester) async {
    await pumpBlueprintAndSettle(
      tester,
      blueprint(
        'hook:scope',
        props: <String, dynamic>{
          'scope': <String, dynamic>{'name': 'Ada', 'role': 'engineer'},
        },
        children: <QLBlueprint>[
          blueprint('text:p', props: <String, dynamic>{'value': '{{name}}'}),
          blueprint('text:p', props: <String, dynamic>{'value': '{{role}}'}),
        ],
      ),
    );

    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('engineer'), findsOneWidget);
  });

  test('hook base plugin is registered and not shadowed by an alias', () async {
    await bootstrapQuantumTestVm();
    expect(QuantumVM.instance.hasPlugin('hook'), isTrue);
    expect(QuantumVM.instance.hasAlias('hook'), isFalse);
  });
}
