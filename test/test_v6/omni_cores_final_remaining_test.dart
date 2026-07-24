
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

QLBlueprint _bp(
  String type, {
  Map<String, dynamic> props = const <String, dynamic>{},
  List<QLBlueprint> children = const <QLBlueprint>[],
  Map<String, QLBlueprint> slots = const <String, QLBlueprint>{},
  String? style,
}) {
  return QLBlueprint(
    type: type,
    props: props,
    style: style,
    children: children,
    slots: slots,
  );
}

QLBlueprint _textNode(String text) {
  return _bp('text', props: <String, dynamic>{'text': text});
}

Future<QLDataStore> _pumpBlueprint(
  WidgetTester tester,
  QLBlueprint blueprint, {
  QLDataStore? store,
  Map<String, dynamic> localData = const <String, dynamic>{},
  Size mediaSize = const Size(1024, 768),
}) async {
  final QLDataStore resolvedStore = store ??
      QLStoreRegistry.instance
          .get('test_${DateTime.now().microsecondsSinceEpoch}');

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: mediaSize),
        child: QLDataScope(
          localData: localData,
          localStore: resolvedStore,
          moduleStore: resolvedStore,
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return QuantumVM.instance.renderWidget(context, blueprint);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return resolvedStore;
}

Text _textAt(WidgetTester tester, int index) {
  return tester.widget<Text>(find.byType(Text).at(index));
}

String _textDataAt(WidgetTester tester, int index) {
  return _textAt(tester, index).data ?? '';
}

Finder _descendantTextFinder() {
  return find.descendant(
    of: find.byType(QLDataScope),
    matching: find.byType(Text),
  );
}

String _textDataByIndex(WidgetTester tester, int index) {
  return tester.widget<Text>(_descendantTextFinder().at(index)).data ?? '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    QEngine.instance.initialize();
    registerOmniComponents(QuantumVM.instance);
    registerConnectOmniNodes(QuantumVM.instance);
    QLBehaviorRegistry.registerDefaults();
  });

  setUp(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
    QLChannelHub.instance.resetForTesting();
    QuantumOverlay.instance.resetForTesting();
  });

  tearDown(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
    QLChannelHub.instance.resetForTesting();
    QuantumOverlay.instance.resetForTesting();
  });

  group('collab_core', () {
    test('registers aliases for presence, cursor, awareness, and lock', () {
      final vm = QuantumVM.instance;

      expect(vm.getAlias('presence')?['type'], 'collab:presence');
      expect(vm.getAlias('cursor')?['type'], 'collab:cursor');
      expect(vm.getAlias('awareness')?['type'], 'collab:awareness');
      expect(vm.getAlias('lock')?['type'], 'collab:lock');
    });

    testWidgets('presence starts empty and exposes a stable count field',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'collab:presence',
          props: <String, dynamic>{
            'room': 'room-a',
            'as': 'present',
          },
          children: <QLBlueprint>[
            _textNode('{{presentCount}}'),
          ],
        ),
      );

      expect(_textDataByIndex(tester, 0), '0');
    });

    testWidgets('patch merges maps and ignores invalid patch payloads',
        (tester) async {
      final store = QLStoreRegistry.instance.get('collab_patch');
      store.set('doc', <String, dynamic>{
        'title': 'Draft',
        'keep': true,
      });

      await _pumpBlueprint(
        tester,
        _bp(
          'collab:patch',
          props: <String, dynamic>{
            'store': 'collab_patch',
            'key': 'doc',
            'patch': <String, dynamic>{
              'title': 'Published',
              'rev': 2,
            },
          },
        ),
        store: store,
      );

      expect(
        store.get('doc'),
        equals(<String, dynamic>{
          'title': 'Published',
          'keep': true,
          'rev': 2,
        }),
      );

      await _pumpBlueprint(
        tester,
        _bp(
          'collab:patch',
          props: <String, dynamic>{
            'store': 'collab_patch',
            'key': 'doc',
            'patch': 'not-a-map',
          },
        ),
        store: store,
      );

      expect(
        store.get('doc'),
        equals(<String, dynamic>{
          'title': 'Published',
          'keep': true,
          'rev': 2,
        }),
      );

      await _pumpBlueprint(
        tester,
        _bp(
          'collab:patch',
          props: <String, dynamic>{
            'store': 'collab_patch',
            'key': '',
            'patch': <String, dynamic>{'ignored': true},
          },
        ),
        store: store,
      );

      expect(
        store.get('doc'),
        equals(<String, dynamic>{
          'title': 'Published',
          'keep': true,
          'rev': 2,
        }),
      );
    });

    testWidgets(
        'lock is exclusive and is released when the first owner goes away',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'box',
          children: <QLBlueprint>[
            _bp(
              'collab:lock',
              props: <String, dynamic>{
                'resource': 'doc-1',
                'userId': 'alice',
              },
              children: <QLBlueprint>[
                _textNode('{{lockAcquired}}|{{lockHolder}}'),
              ],
            ),
            _bp(
              'collab:lock',
              props: <String, dynamic>{
                'resource': 'doc-1',
                'userId': 'bob',
              },
              children: <QLBlueprint>[
                _textNode('{{lockAcquired}}|{{lockHolder}}'),
              ],
            ),
          ],
        ),
      );

      expect(_textDataByIndex(tester, 0), 'true|alice');
      expect(_textDataByIndex(tester, 1), 'false|alice');

      await _pumpBlueprint(
        tester,
        _bp(
          'collab:lock',
          props: <String, dynamic>{
            'resource': 'doc-1',
            'userId': 'bob',
          },
          children: <QLBlueprint>[
            _textNode('{{lockAcquired}}|{{lockHolder}}'),
          ],
        ),
      );

      expect(_textDataByIndex(tester, 0), 'true|bob');
    });
  });

  group('connect_core', () {
    test('registers aliases and behavior contracts', () {
      final vm = QuantumVM.instance;
      expect(vm.getAlias('backButton')?['type'], 'connect:back');
      expect(vm.getAlias('pressGesture')?['type'], 'connect:pressGesture');
      expect(vm.getAlias('connectSlot')?['type'], 'connect:slot');
      expect(vm.getAlias('focusReveal')?['type'], 'connect:focusReveal');
      expect(vm.getAlias('channelText')?['type'], 'connect:channelText');
      expect(vm.getAlias('behavior')?['type'], 'connect:behavior');
      expect(vm.getAlias('socket')?['type'], 'connect:socket');
      expect(vm.getAlias('channel')?['type'], 'connect:channel');
      expect(vm.getAlias('broadcast')?['type'], 'connect:broadcast');
      expect(vm.getAlias('sync')?['type'], 'connect:sync');
      expect(vm.getAlias('rpc')?['type'], 'connect:rpc');

      expect(QLBehaviorRegistry.has('tooltip'), isTrue);
      expect(QLBehaviorRegistry.has('press_feedback'), isTrue);
      expect(QLBehaviorRegistry.has('hover_scale'), isTrue);
    });

    testWidgets('channelText reflects published values and updates live',
        (tester) async {
      QLChannelHub.instance.publish<String>('status-channel', 'ready');

      await _pumpBlueprint(
        tester,
        _bp(
          'connect:channelText',
          props: <String, dynamic>{
            'channel': 'status-channel',
            'fallback': 'idle',
          },
        ),
      );

      expect(_textDataByIndex(tester, 0), 'ready');

      QLChannelHub.instance.publish<String>('status-channel', 'steady');
      await tester.pump();

      expect(_textDataByIndex(tester, 0), 'steady');
    });

    testWidgets('smart back button taps back and reveals the prior title',
        (tester) async {
      QLChannelHub.instance.publish<String>('nav.previous.title', 'Settings');
      var backCount = 0;

      await _pumpBlueprint(
        tester,
        _bp(
          'connect:back',
          props: <String, dynamic>{
            'onBack': () => backCount++,
          },
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      await tester.tap(find.byType(QLSmartBackButton));
      await tester.pump();
      expect(backCount, 1);

      final Offset center = tester.getCenter(find.byType(QLSmartBackButton));
      final TestGesture gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Settings'), findsOneWidget);
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('pressGesture commits, cancels, and alt-commits on drag phase',
        (tester) async {
      var commits = 0;
      var cancels = 0;
      var alts = 0;

      await _pumpBlueprint(
        tester,
        _bp(
          'connect:pressGesture',
          props: <String, dynamic>{
            'cancelThreshold': 30,
            'altThreshold': 30,
            'onCommit': () => commits++,
            'onCancel': () => cancels++,
            'onAlt': () => alts++,
          },
          children: <QLBlueprint>[
            _textNode('hold'),
          ],
        ),
      );

      await tester.longPress(find.text('hold'));
      await tester.pump();
      expect(commits, 1);
      expect(cancels, 0);
      expect(alts, 0);

      commits = 0;
      cancels = 0;
      alts = 0;

      final Offset center = tester.getCenter(find.text('hold'));
      final TestGesture altGesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 700));
      await altGesture.moveBy(const Offset(0, 80));
      await tester.pump();
      await altGesture.up();
      await tester.pump();
      expect(alts, 1);
      expect(commits, 0);
      expect(cancels, 0);

      final TestGesture cancelGesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 700));
      await cancelGesture.moveBy(const Offset(0, -80));
      await tester.pump();
      await cancelGesture.up();
      await tester.pump();
      expect(cancels, 1);
      expect(alts, 1);
      expect(commits, 0);
    });

    testWidgets('behavior contracts fall back safely for unknown builders',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'connect:behavior',
          props: <String, dynamic>{'contract': 'does-not-exist'},
          children: <QLBlueprint>[
            _textNode('plain child'),
          ],
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
      expect(find.text('plain child'), findsOneWidget);
    });

    testWidgets('tooltip behavior resolves to a real Tooltip widget',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'connect:behavior',
          props: <String, dynamic>{
            'contract': 'tooltip',
            'text': 'Helpful context',
          },
          children: <QLBlueprint>[
            _textNode('hover target'),
          ],
        ),
      );

      expect(find.byType(Tooltip), findsOneWidget);
      expect(find.text('hover target'), findsOneWidget);
    });

    testWidgets('focus reveal shows and hides the close action by channel',
        (tester) async {
      final channel = 'focus.reveal';
      QLChannelHub.instance.publish<bool>(channel, true);
      var closeCount = 0;

      await _pumpBlueprint(
        tester,
        _bp(
          'connect:focusReveal',
          props: <String, dynamic>{
            'focusChannel': channel,
            'onClose': () => closeCount++,
          },
          children: <QLBlueprint>[
            _textNode('field body'),
          ],
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closeCount, 1);

      QLChannelHub.instance.publish<bool>(channel, false);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('portal_core', () {
    test('registers the portal aliases', () {
      final vm = QuantumVM.instance;
      expect(vm.getAlias('overlay_entry')?['type'], 'portal:overlay_entry');
      expect(vm.getAlias('overlay')?['type'], 'portal:overlay');
      expect(vm.getAlias('dialog')?['type'], 'portal:dialog');
      expect(vm.getAlias('drawer')?['type'], 'portal:sheet');
      expect(vm.getAlias('sheet')?['type'], 'portal:sheet');
      expect(vm.getAlias('popover')?['type'], 'portal:popover');
    });

    testWidgets('dialog portals mount on a real tap', (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'portal:dialog',
          slots: <String, QLBlueprint>{
            'trigger': _textNode('open dialog'),
            'content': _textNode('dialog body'),
          },
        ),
      );

      expect(find.text('dialog body'), findsNothing);
      await tester.tap(find.text('open dialog'));
      await tester.pump();
      expect(find.text('dialog body'), findsOneWidget);
    });

    testWidgets('dialog portals ignore drag gestures that move too far',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'portal:dialog',
          slots: <String, QLBlueprint>{
            'trigger': _textNode('move guarded trigger'),
            'content': _textNode('should not appear'),
          },
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('move guarded trigger')),
      );
      await gesture.moveBy(const Offset(20, 0));
      await gesture.up();
      await tester.pump();
      expect(find.text('should not appear'), findsNothing);
    });

    testWidgets('toast portals auto-mount after the first frame',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'portal:toast',
          slots: <String, QLBlueprint>{
            'content': _textNode('toast body'),
          },
        ),
      );

      await tester.pump();
      expect(find.text('toast body'), findsOneWidget);
    });

    testWidgets('overlay_entry tracks a bound trigger signal', (tester) async {
      final store = QLStoreRegistry.instance.get('portal_overlay');
      final QLSignal<dynamic> trigger = store.signal('show_entry');
      trigger.value = false;

      await _pumpBlueprint(
        tester,
        _bp(
          'portal:overlay_entry',
          props: <String, dynamic>{
            'triggerBind': 'show_entry',
            'x': 24,
            'y': 48,
          },
          slots: <String, QLBlueprint>{
            'content': _textNode('overlay body'),
          },
        ),
        store: store,
      );

      expect(find.text('overlay body'), findsNothing);

      trigger.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('overlay body'), findsOneWidget);

      trigger.value = false;
      await tester.pump();
      expect(find.text('overlay body'), findsNothing);
    });
  });

  group('visual_core', () {
    test('registers the visual aliases', () {
      final vm = QuantumVM.instance;
      expect(vm.getAlias('visual_surface')?['type'], 'visual:surface');
      expect(vm.getAlias('visual_shell')?['type'], 'visual:shell');
      expect(vm.getAlias('visual_scene')?['type'], 'visual:scene');
      expect(vm.getAlias('visual_overlay')?['type'], 'visual:overlay');
      expect(vm.getAlias('visual_delegate')?['type'], 'visual:delegate');
    });

    testWidgets('surface and overlay layouts preserve the slot tree',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'visual:surface',
          slots: <String, QLBlueprint>{
            'header': _textNode('header slot'),
            'body': _textNode('body slot'),
            'footer': _textNode('footer slot'),
            'chrome': _textNode('chrome slot'),
            'overlay': _textNode('overlay slot'),
          },
        ),
      );

      expect(find.text('header slot'), findsOneWidget);
      expect(find.text('body slot'), findsOneWidget);
      expect(find.text('footer slot'), findsOneWidget);
      expect(find.text('chrome slot'), findsOneWidget);
      expect(find.text('overlay slot'), findsOneWidget);

      await _pumpBlueprint(
        tester,
        _bp(
          'visual:overlay',
          children: <QLBlueprint>[
            _textNode('content panel'),
          ],
          slots: <String, QLBlueprint>{
            'overlay': _textNode('overlay panel'),
          },
        ),
      );

      expect(find.text('content panel'), findsOneWidget);
      expect(find.text('overlay panel'), findsOneWidget);
    });

    testWidgets('chart routing falls back to line for invalid chart types',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'visual:chart',
          props: <String, dynamic>{
            'chartType': 'definitely-not-valid',
            'data': <dynamic>[1, 2, 3],
          },
        ),
      );

      final QLUniversalChart chart = tester.widget<QLUniversalChart>(
        find.byType(QLUniversalChart),
      );
      expect(chart.type, QLChartType.line);
      expect(chart.rawData, equals(<dynamic>[1, 2, 3]));
    });

    testWidgets('visual routes connect subtrees through the connect core',
        (tester) async {
      QLChannelHub.instance.publish<String>('visual.connect.status', 'primed');

      await _pumpBlueprint(
        tester,
        _bp(
          'visual:connect',
          props: <String, dynamic>{
            'channel': 'visual.connect.status',
            'fallback': 'idle',
          },
        ),
      );

      expect(_textDataByIndex(tester, 0), 'primed');
      QLChannelHub.instance.publish<String>('visual.connect.status', 'hot');
      await tester.pump();
      expect(_textDataByIndex(tester, 0), 'hot');
    });

    testWidgets('visual routes portal subtrees through the portal core',
        (tester) async {
      await _pumpBlueprint(
        tester,
        _bp(
          'visual:portal',
          slots: <String, QLBlueprint>{
            'trigger': _textNode('open via visual'),
            'content': _textNode('visual portal body'),
          },
        ),
      );

      expect(find.text('visual portal body'), findsNothing);
      await tester.tap(find.text('open via visual'));
      await tester.pump();
      expect(find.text('visual portal body'), findsOneWidget);
    });
  });
}
