import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

int _sequence = 0;

String _uniqueName(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';

QLBlueprint _bp(
  String type, {
  Map<String, dynamic> props = const <String, dynamic>{},
  List<Map<String, dynamic>> children = const <Map<String, dynamic>>[],
  Map<String, dynamic> slots = const <String, dynamic>{},
}) {
  return QLBlueprint.fromJson(<String, dynamic>{
    'type': type,
    if (props.isNotEmpty) 'props': props,
    if (children.isNotEmpty) 'children': children,
    if (slots.isNotEmpty) 'slots': slots,
  });
}

Map<String, dynamic> _textNode(String text) => <String, dynamic>{
      'type': 'text',
      'props': <String, dynamic>{'text': text},
    };

String _registerRecordingAction(
  List<Map<String, dynamic>> calls, {
  String prefix = 'record',
  FutureOr<dynamic> Function(Map<String, dynamic> payload)? onCall,
}) {
  final String name = _uniqueName(prefix);
  QuantumVM.instance.registerAction(
    name,
    LambdaActionPlugin((payload, store, ctx) async {
      calls.add(Map<String, dynamic>.from(payload));
      if (onCall != null) return onCall(payload);
      return null;
    }),
  );
  return name;
}

Future<QLDataStore> _pumpRenderedNode(
  WidgetTester tester,
  QLBlueprint node, {
  Map<String, dynamic> localData = const <String, dynamic>{},
  Size mediaSize = const Size(1280, 900),
  QLDataStore? store,
  Widget Function(Widget child)? wrap,
}) async {
  final QLDataStore resolvedStore =
      store ?? QLDataStore(namespace: _uniqueName('test_store'));

  Widget tree = QLDataScope(
    localData: localData,
    localStore: resolvedStore,
    moduleStore: resolvedStore,
    child: Builder(
      builder: (context) => QuantumVM.instance.renderWidget(context, node),
    ),
  );

  if (wrap != null) {
    tree = wrap(tree);
  }

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: mediaSize),
        child: tree,
      ),
    ),
  );
  await tester.pump();
  return resolvedStore;
}

Iterable<QLDataScope> _allScopes(WidgetTester tester) {
  return tester.widgetList<QLDataScope>(find.byType(QLDataScope));
}

QLDataScope _scopeWhere(
  WidgetTester tester,
  bool Function(QLDataScope scope) predicate, {
  String reason = 'Expected a matching QLDataScope',
}) {
  final matches = _allScopes(tester).where(predicate).toList(growable: false);
  expect(matches, isNotEmpty, reason: reason);
  return matches.first;
}

QLDataScope _scopeWithKey(WidgetTester tester, String key) {
  return _scopeWhere(
    tester,
    (scope) => scope.localData.containsKey(key),
    reason: 'Expected a QLDataScope carrying "$key"',
  );
}

QLDataScope _scopeWithAnyKeyPrefix(WidgetTester tester, String prefix) {
  return _scopeWhere(
    tester,
    (scope) => scope.localData.keys.any((key) => key.startsWith(prefix)),
    reason: 'Expected a QLDataScope carrying a key starting with "$prefix"',
  );
}

void main() {
  group('control_core.dart', () {
    testWidgets(
        'standard fallback exposes index/data signals using the control id',
        (tester) async {
      final String id = _uniqueName('control_fallback');
      final QLBlueprint node = _bp(
        'control:noop',
        props: <String, dynamic>{
          'id': id,
          'initialIndex': 7,
        },
        children: <Map<String, dynamic>>[
          _textNode('fallback child'),
        ],
      );

      await _pumpRenderedNode(tester, node);

      expect(find.text('fallback child'), findsOneWidget);
      final QLDataScope scope = _scopeWithKey(tester, '$id.index');
      expect(scope.localData['$id.index'], isA<QLSignal<int>>());
      expect((scope.localData['$id.index'] as QLSignal<int>).value, 7);
      expect(
          scope.localData['$id.data'], isA<QLSignal<Map<String, dynamic>>>());
      expect(
          (scope.localData['$id.data'] as QLSignal<Map<String, dynamic>>).value,
          isEmpty);
    });

    testWidgets('tabs, stepper, and accordion all seed an index signal',
        (tester) async {
      for (final String subtype in <String>['tabs', 'stepper', 'accordion']) {
        final String id = _uniqueName(subtype);
        final QLBlueprint node = _bp(
          'control:$subtype',
          props: <String, dynamic>{
            'id': id,
            'initialIndex': 3,
          },
          children: <Map<String, dynamic>>[
            _textNode('$subtype child'),
          ],
        );

        await _pumpRenderedNode(tester, node);

        expect(find.text('$subtype child'), findsOneWidget);
        final QLDataScope scope = _scopeWithKey(tester, '$id.index');
        expect((scope.localData['$id.index'] as QLSignal<int>).value, 3);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    });

    testWidgets('form_scope exposes controller and derived signals',
        (tester) async {
      final String id = _uniqueName('form_scope');
      final QLBlueprint node = _bp(
        'control:form_scope',
        props: <String, dynamic>{'id': id},
        children: <Map<String, dynamic>>[
          _textNode('form body'),
        ],
      );

      await _pumpRenderedNode(tester, node);

      expect(find.text('form body'), findsOneWidget);
      final QLDataScope scope = _scopeWithKey(tester, '__formController');
      final QLFormController controller =
          scope.localData['__formController'] as QLFormController;
      expect(scope.localData['$id.isValid'], isA<QLDerivedSignal<bool>>());
      expect(scope.localData['$id.formData'],
          isA<QLDerivedSignal<Map<String, dynamic>>>());
      expect(controller.isValid, isTrue);
      expect(controller.formData, isA<Map<String, dynamic>>());
      expect(await controller.submit(), isTrue);
      controller.resetForm();
    });

    testWidgets(
        'flow branch initializes the store once and preserves existing values',
        (tester) async {
      final String id = _uniqueName('flow');
      final String namespace = 'ns_$id';
      final QLDataStore store = QLStoreRegistry.instance.get(namespace);
      addTearDown(() => QLStoreRegistry.instance.destroy(namespace));

      store.set('$namespace.state', <String, dynamic>{'existing': true});
      store.set('$namespace.route', '/preloaded');
      store.set('$namespace.selection', 'saved');
      store.set('$namespace.hero', 'hero-1');

      final QLBlueprint node = _bp(
        'control:flow',
        props: <String, dynamic>{
          'id': id,
          'namespace': namespace,
          'initialState': <String, dynamic>{'fresh': false},
          'initialRoute': '/ignored',
          'initialSelection': 'ignored',
          'initialHero': 'ignored',
        },
        children: <Map<String, dynamic>>[
          _textNode('flow child'),
        ],
      );

      await _pumpRenderedNode(tester, node, store: store);

      final QLDataScope scope = _scopeWithAnyKeyPrefix(tester, '$id.');
      expect((scope.localData['namespace'] as String), namespace);
      expect(
          store.get('$namespace.state'), <String, dynamic>{'existing': true});
      expect(store.get('$namespace.route'), '/preloaded');
      expect(store.get('$namespace.selection'), 'saved');
      expect(store.get('$namespace.hero'), 'hero-1');
      expect(scope.localData['$id.stateSignal'], isA<QLSignal<dynamic>>());
      expect(scope.localData['$id.routeSignal'], isA<QLSignal<dynamic>>());
    });

    testWidgets(
        'flow branch reflects store updates through the derived signals',
        (tester) async {
      final String id = _uniqueName('flow_reactive');
      final String namespace = 'ns_$id';
      final QLDataStore store = QLStoreRegistry.instance.get(namespace);
      addTearDown(() => QLStoreRegistry.instance.destroy(namespace));

      final QLBlueprint node = _bp(
        'control:architecture',
        props: <String, dynamic>{
          'id': id,
          'namespace': namespace,
          'initialState': <String, dynamic>{'count': 1},
        },
        children: <Map<String, dynamic>>[
          _textNode('flow body'),
        ],
      );

      await _pumpRenderedNode(tester, node, store: store);
      final QLDataScope initialScope = _scopeWithAnyKeyPrefix(tester, '$id.');
      expect(initialScope.localData['$id.stateValue'],
          <String, dynamic>{'count': 1});

      store.set('$namespace.state', <String, dynamic>{'count': 9});
      await tester.pump();

      final QLDataScope updatedScope = _scopeWithAnyKeyPrefix(tester, '$id.');
      expect(updatedScope.localData['$id.stateValue'],
          <String, dynamic>{'count': 9});
    });

    testWidgets(
        'machine transitions to done on successful invoke and ignores unknown events',
        (tester) async {
      final List<Map<String, dynamic>> calls = <Map<String, dynamic>>[];
      final String invokeAction =
          _registerRecordingAction(calls, prefix: 'machine_ok');
      final String id = _uniqueName('machine');
      final String sendAction = 'machine.$id.send';
      final QLBlueprint node = _bp(
        'control:machine',
        props: <String, dynamic>{
          'id': id,
          'initial': 'idle',
          'states': <String, dynamic>{
            'idle': <String, dynamic>{
              'on': <String, dynamic>{
                'start': <String, dynamic>{'target': 'loading'},
              },
              'render': _textNode('idle state'),
            },
            'loading': <String, dynamic>{
              'invoke': <String, dynamic>{
                'action': invokeAction,
                'onDone': 'done',
                'onError': 'failed',
              },
              'on': <String, dynamic>{
                'noop': <String, dynamic>{'target': 'loading'},
              },
              'render': _textNode('loading state'),
            },
            'done': <String, dynamic>{'render': _textNode('done state')},
            'failed': <String, dynamic>{'render': _textNode('failed state')},
          },
        },
        children: <Map<String, dynamic>>[
          _textNode('machine child'),
        ],
      );

      await _pumpRenderedNode(tester, node);
      expect(find.text('idle state'), findsOneWidget);

      await QuantumVM.instance.triggerActions(
        <dynamic>[
          <String, dynamic>{'action': sendAction, 'event': 'start'},
        ],
        tester.element(find.text('idle state')),
      );
      await tester.pump();

      expect(find.text('done state'), findsOneWidget);
      expect(calls, hasLength(1));
      expect(calls.single['action'], invokeAction);

      await QuantumVM.instance.triggerActions(
        <dynamic>[
          <String, dynamic>{'action': sendAction, 'event': 'unknown'},
        ],
        tester.element(find.text('done state')),
      );
      await tester.pump();
      expect(find.text('done state'), findsOneWidget);
    });

    testWidgets('machine invokes the error target when the invoke action fails',
        (tester) async {
      final String invokeAction = _uniqueName('machine_fail');
      QuantumVM.instance.registerAction(
        invokeAction,
        LambdaActionPlugin((payload, store, ctx) async {
          throw StateError('boom');
        }),
      );

      final String id = _uniqueName('machine_error');
      final String sendAction = 'machine.$id.send';
      final QLBlueprint node = _bp(
        'control:machine',
        props: <String, dynamic>{
          'id': id,
          'initial': 'idle',
          'states': <String, dynamic>{
            'idle': <String, dynamic>{
              'on': <String, dynamic>{
                'start': <String, dynamic>{'target': 'loading'},
              },
              'render': _textNode('idle state'),
            },
            'loading': <String, dynamic>{
              'invoke': <String, dynamic>{
                'action': invokeAction,
                'onDone': 'done',
                'onError': 'failed',
              },
              'render': _textNode('loading state'),
            },
            'done': <String, dynamic>{'render': _textNode('done state')},
            'failed': <String, dynamic>{'render': _textNode('failed state')},
          },
        },
      );

      await _pumpRenderedNode(tester, node);
      expect(find.text('idle state'), findsOneWidget);

      await QuantumVM.instance.triggerActions(
        <dynamic>[
          <String, dynamic>{'action': sendAction, 'event': 'start'},
        ],
        tester.element(find.text('idle state')),
      );
      await tester.pump();

      expect(find.text('failed state'), findsOneWidget);
      expect(find.text('done state'), findsNothing);
    });

    testWidgets('optimistic updates roll back on error and persist on success',
        (tester) async {
      final String key = _uniqueName('optimistic_value');
      final String failingAction = _uniqueName('optimistic_fail');
      final String successAction = _uniqueName('optimistic_ok');
      final QLDataStore store =
          QLDataStore(namespace: _uniqueName('optimistic_store'));

      QuantumVM.instance.registerAction(
        failingAction,
        LambdaActionPlugin((payload, store, ctx) async {
          throw StateError('deny');
        }),
      );
      QuantumVM.instance.registerAction(
        successAction,
        LambdaActionPlugin((payload, store, ctx) async {
          return null;
        }),
      );

      store.set(key, 'original');
      final QLBlueprint failingNode = _bp(
        'control:optimistic',
        props: <String, dynamic>{
          'action': failingAction,
          'rollbackOn': 'error',
          'optimisticData': <String, dynamic>{key: 'optimistic'},
        },
        children: <Map<String, dynamic>>[
          _textNode('tap fail'),
        ],
      );
      final QLBlueprint successNode = _bp(
        'control:optimistic',
        props: <String, dynamic>{
          'action': successAction,
          'rollbackOn': 'error',
          'optimisticData': <String, dynamic>{key: 'persisted'},
        },
        children: <Map<String, dynamic>>[
          _textNode('tap ok'),
        ],
      );

      addTearDown(() => QLStoreRegistry.instance.destroy(store.namespace));
      await _pumpRenderedNode(tester, failingNode, store: store);
      await tester.tap(find.text('tap fail'));
      await tester.pump();
      expect(store.get(key), 'original');

      await _pumpRenderedNode(tester, successNode, store: store);
      await tester.tap(find.text('tap ok'));
      await tester.pump();
      expect(store.get(key), 'persisted');
    });

    testWidgets('saga action executes steps in order with delayed steps',
        (tester) async {
      final List<Map<String, dynamic>> calls = <Map<String, dynamic>>[];
      final String first =
          _registerRecordingAction(calls, prefix: 'saga_first');
      final String second =
          _registerRecordingAction(calls, prefix: 'saga_second');
      final String id = _uniqueName('saga');
      final String runAction = 'saga.$id.run';
      final QLBlueprint node = _bp(
        'control:saga',
        props: <String, dynamic>{
          'id': id,
          'steps': <Map<String, dynamic>>[
            <String, dynamic>{'action': first},
            <String, dynamic>{'delay': 20, 'action': second},
          ],
        },
        children: <Map<String, dynamic>>[
          _textNode('saga body'),
        ],
      );

      await _pumpRenderedNode(tester, node);
      final QLDataScope scope = _scopeWithKey(tester, runAction);
      expect(scope.localData[runAction], runAction);

      await QuantumVM.instance.triggerActions(
        <dynamic>[
          <String, dynamic>{'action': runAction},
        ],
        tester.element(find.text('saga body')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pump();

      expect(calls.map((c) => c['action']).toList(), <String>[first, second]);
    });

    testWidgets(
        'reducer exposes a dispatch callback that can execute configured actions',
        (tester) async {
      final List<Map<String, dynamic>> calls = <Map<String, dynamic>>[];
      final String recordAction =
          _registerRecordingAction(calls, prefix: 'reducer');
      final String id = _uniqueName('reducer');
      final QLBlueprint node = _bp(
        'control:reducer',
        props: <String, dynamic>{
          'id': id,
          'initialState': <String, dynamic>{'count': 0},
          'actions': <String, dynamic>{
            'save': <Map<String, dynamic>>[
              <String, dynamic>{'action': recordAction, 'kind': 'save'},
            ],
          },
        },
        children: <Map<String, dynamic>>[
          _textNode('reducer body'),
        ],
      );

      await _pumpRenderedNode(tester, node);
      final QLDataScope scope = _scopeWithKey(tester, r'$dispatch');
      final dispatch = scope.localData[r'$dispatch'];
      expect(
          dispatch, isA<Future<void> Function(String, Map<String, dynamic>)>());
      await (dispatch as Future<void> Function(String, Map<String, dynamic>))(
        'save',
        <String, dynamic>{'count': 5},
      );
      await tester.pump();
      expect(calls, hasLength(1));
      expect(calls.single['kind'], 'save');
    });
  });

  group('system_core.dart', () {
    testWidgets('async shows loading, then data, then error slot on failure',
        (tester) async {
      final Completer<void> gate = Completer<void>();
      final List<Map<String, dynamic>> calls = <Map<String, dynamic>>[];
      final String waitAction = _registerRecordingAction(
        calls,
        prefix: 'async_wait',
        onCall: (_) async {
          await gate.future;
        },
      );
      final String failAction = _uniqueName('async_fail');
      QuantumVM.instance.registerAction(
        failAction,
        LambdaActionPlugin((payload, store, ctx) async {
          throw StateError('network down');
        }),
      );

      final QLBlueprint loadingNode = _bp(
        'system:async',
        props: <String, dynamic>{'action': waitAction},
        slots: <String, dynamic>{
          'loading': _textNode('loading slot'),
          'data': _textNode('data slot'),
          'error': _textNode('error slot'),
        },
      );

      await _pumpRenderedNode(tester, loadingNode);
      expect(find.text('loading slot'), findsOneWidget);
      expect(calls, hasLength(1));

      gate.complete();
      await tester.pump();
      await tester.pump();
      expect(find.text('data slot'), findsOneWidget);
      expect(find.text('loading slot'), findsNothing);

      final QLBlueprint errorNode = _bp(
        'system:async',
        props: <String, dynamic>{'action': failAction},
        slots: <String, dynamic>{
          'loading': _textNode('loading slot'),
          'data': _textNode('data slot'),
          'error': _textNode('error slot'),
        },
      );

      await _pumpRenderedNode(tester, errorNode);
      await tester.pump();
      await tester.pump();
      expect(find.text('error slot'), findsOneWidget);
    });

    testWidgets(
        'repeater renders list and string sources and exposes per-item scopes',
        (tester) async {
      final QLBlueprint listNode = _bp(
        'system:repeater',
        props: <String, dynamic>{
          'bind': 'items',
          'as': 'itemValue',
          'indexAs': 'itemIndex',
        },
        slots: <String, dynamic>{
          'item': _bp('text', props: <String, dynamic>{'text': 'row'}),
        },
      );

      await _pumpRenderedNode(
        tester,
        listNode,
        localData: <String, dynamic>{
          'items': <int>[10, 20, 30]
        },
      );
      expect(find.text('row'), findsNWidgets(3));
      final List<QLDataScope> itemScopes = _allScopes(tester)
          .where((scope) => scope.localData.containsKey('itemValue'))
          .toList(growable: false);
      expect(itemScopes, hasLength(3));
      expect(itemScopes.map((s) => s.localData['itemIndex']).toList(),
          <int>[0, 1, 2]);
      expect(itemScopes.map((s) => s.localData['itemValue']).toList(),
          <int>[10, 20, 30]);

      final QLBlueprint stringNode = _bp(
        'system:repeater',
        props: <String, dynamic>{
          'bind': 'letters',
          'as': 'letter',
          'indexAs': 'letterIndex',
        },
        slots: <String, dynamic>{
          'item': _bp('text', props: <String, dynamic>{'text': 'char'}),
        },
      );

      await _pumpRenderedNode(
        tester,
        stringNode,
        localData: <String, dynamic>{'letters': 'abc'},
      );
      expect(find.text('char'), findsNWidgets(3));
      final List<QLDataScope> letterScopes = _allScopes(tester)
          .where((scope) => scope.localData.containsKey('letter'))
          .toList(growable: false);
      expect(letterScopes.map((s) => s.localData['letter']).toList(),
          <String>['a', 'b', 'c']);
      expect(letterScopes.map((s) => s.localData['letterIndex']).toList(),
          <int>[0, 1, 2]);
    });

    testWidgets('repeater shows a visible error when no template exists',
        (tester) async {
      final QLBlueprint node = _bp(
        'system:repeater',
        props: <String, dynamic>{'bind': 'items'},
      );

      await _pumpRenderedNode(
        tester,
        node,
        localData: <String, dynamic>{
          'items': <int>[1, 2, 3]
        },
      );

      expect(find.text('Repeater missing template'), findsOneWidget);
      final Text errorText =
          tester.widget<Text>(find.text('Repeater missing template'));
      expect(errorText.style?.color, Colors.red);
    });

    testWidgets('store_provider seeds the store before rendering children',
        (tester) async {
      final String namespace = _uniqueName('store_provider');
      final QLDataStore store = QLDataStore(namespace: namespace);
      addTearDown(() => QLStoreRegistry.instance.destroy(namespace));

      final QLBlueprint node = _bp(
        'system:store_provider',
        props: <String, dynamic>{
          'initialState': <String, dynamic>{
            'flag': true,
            'count': 4,
            'nested': <String, dynamic>{'ok': 'yes'},
          },
        },
        children: <Map<String, dynamic>>[
          _textNode('store child'),
        ],
      );

      await _pumpRenderedNode(tester, node, store: store);
      expect(find.text('store child'), findsOneWidget);
      expect(store.get('flag'), isTrue);
      expect(store.get('count'), 4);
      expect(store.get('nested.ok'), 'yes');
    });

    testWidgets('timer respects interval boundaries and autoStart',
        (tester) async {
      final List<Map<String, dynamic>> calls = <Map<String, dynamic>>[];
      final String tickAction =
          _registerRecordingAction(calls, prefix: 'timer_tick');
      final QLBlueprint autoNode = _bp(
        'system:timer',
        props: <String, dynamic>{
          'interval': 20,
          'autoStart': true,
          'onTick': tickAction,
        },
        children: <Map<String, dynamic>>[
          _textNode('timer child'),
        ],
      );

      await _pumpRenderedNode(tester, autoNode);
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 10));
      expect(calls, isEmpty);
      await tester.pump(const Duration(milliseconds: 15));
      expect(calls, hasLength(1));
      await tester.pump(const Duration(milliseconds: 25));
      expect(calls, hasLength(2));

      calls.clear();
      final QLBlueprint pausedNode = _bp(
        'system:timer',
        props: <String, dynamic>{
          'interval': 20,
          'autoStart': false,
          'onTick': tickAction,
        },
        children: <Map<String, dynamic>>[
          _textNode('paused timer'),
        ],
      );

      await _pumpRenderedNode(tester, pausedNode);
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, isEmpty);
    });

    testWidgets('data_pipe writes a rolling buffer and an accumulate buffer',
        (tester) async {
      final String namespace = _uniqueName('data_pipe');
      final QLDataStore store = QLStoreRegistry.instance.get(namespace);
      addTearDown(() => QLStoreRegistry.instance.destroy(namespace));

      store.set('$namespace.source', 1.0);
      final QLBlueprint ringNode = _bp(
        'system:data_pipe',
        props: <String, dynamic>{
          'mode': 'ring_buffer',
          'bindSource': '$namespace.source',
          'bindOutput': '$namespace.ring',
          'size': 3,
        },
        children: <Map<String, dynamic>>[
          _textNode('pipe child'),
        ],
      );

      await _pumpRenderedNode(tester, ringNode, store: store);
      expect(find.text('pipe child'), findsOneWidget);
      expect(store.get('$namespace.ring'), isA<Float64List>());
      expect((store.get('$namespace.ring') as Float64List).toList(),
          <double>[0.0, 0.0, 1.0]);

      store.signal('$namespace.source').value = 2.0;
      await tester.pump();
      expect((store.get('$namespace.ring') as Float64List).toList(),
          <double>[0.0, 1.0, 2.0]);

      final QLBlueprint accumulateNode = _bp(
        'system:data_pipe',
        props: <String, dynamic>{
          'mode': 'accumulate',
          'bindSource': '$namespace.source',
          'bindOutput': '$namespace.acc',
          'size': 4,
        },
        children: <Map<String, dynamic>>[
          _textNode('pipe child 2'),
        ],
      );

      await _pumpRenderedNode(tester, accumulateNode, store: store);
      expect((store.get('$namespace.acc') as Float64List).toList(),
          <double>[2.0, 0.0, 0.0, 0.0]);
      store.signal('$namespace.source').value = 3.5;
      await tester.pump();
      expect((store.get('$namespace.acc') as Float64List).toList(),
          <double>[5.5, 0.0, 0.0, 0.0]);
    });

    testWidgets('geo and sensor expose stable default payloads',
        (tester) async {
      final QLBlueprint geoNode = _bp(
        'system:geo',
        props: <String, dynamic>{'as': 'position'},
        children: <Map<String, dynamic>>[
          _textNode('geo child'),
        ],
      );
      await _pumpRenderedNode(tester, geoNode);
      final QLDataScope geoScope = _scopeWithKey(tester, 'position');
      expect(geoScope.localData['position'], <String, dynamic>{
        'lat': 0.0,
        'lng': 0.0,
        'altitude': 0.0,
        'heading': 0.0,
      });

      final QLBlueprint sensorNode = _bp(
        'system:sensor',
        props: <String, dynamic>{'as': 'sensorState'},
        children: <Map<String, dynamic>>[
          _textNode('sensor child'),
        ],
      );
      await _pumpRenderedNode(tester, sensorNode);
      final QLDataScope sensorScope = _scopeWithKey(tester, 'sensorState');
      expect(sensorScope.localData['sensorState'], <String, dynamic>{
        'x': 0.0,
        'y': 0.0,
        'z': 0.0,
      });
    });
  });
}
