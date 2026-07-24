import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

int _sequence = 0;

String _uniqueName(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';

String _registerRecordingAction(
  List<Map<String, dynamic>> calls, {
  String prefix = 'record',
}) {
  final String name = _uniqueName(prefix);
  QuantumVM.instance.registerAction(
    name,
    LambdaActionPlugin((payload, store, ctx) async {
      calls.add(Map<String, dynamic>.from(payload));
      return null;
    }),
  );
  return name;
}

Future<QLDataStore> _pumpRenderedNode(
  WidgetTester tester,
  QLBlueprint node, {
  Map<String, dynamic> localData = const <String, dynamic>{},
  Size mediaSize = const Size(1024, 768),
  QLDataStore? store,
  Widget Function(Widget child)? wrap,
  void Function(Widget rendered)? onBuilt,
}) async {
  final QLDataStore resolvedStore =
      store ?? QLDataStore(namespace: _uniqueName('test'));

  Widget tree = QLDataScope(
    localData: localData,
    localStore: resolvedStore,
    moduleStore: resolvedStore,
    child: Builder(
      builder: (context) {
        final Widget rendered = QuantumVM.instance.renderWidget(context, node);
        onBuilt?.call(rendered);
        return rendered;
      },
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

List<QLDataScope> _allDataScopes(WidgetTester tester) {
  return tester.widgetList<QLDataScope>(find.byType(QLDataScope)).toList();
}

Iterable<QLDataScope> _scopesWithKey(WidgetTester tester, String key) {
  return _allDataScopes(tester)
      .where((scope) => scope.localData.containsKey(key));
}

QLDataScope _singleScopeWithKey(WidgetTester tester, String key) {
  final matches = _scopesWithKey(tester, key).toList();
  expect(matches, isNotEmpty, reason: 'Expected a QLDataScope carrying "$key"');
  return matches.first;
}

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

Map<String, dynamic> _nodeJson(QLBlueprint node) => node.toJson();

class _MutableBlueprintHost extends StatefulWidget {
  final QLBlueprint initialBlueprint;
  final Map<String, dynamic> localData;
  final QLDataStore? store;

  const _MutableBlueprintHost({
    super.key,
    required this.initialBlueprint,
    this.store,
  }) : localData = const <String, dynamic>{};

  @override
  State<_MutableBlueprintHost> createState() => _MutableBlueprintHostState();
}

class _MutableBlueprintHostState extends State<_MutableBlueprintHost> {
  late QLBlueprint _blueprint = widget.initialBlueprint;
  late final QLDataStore _store =
      widget.store ?? QLDataStore(namespace: _uniqueName('mutable'));

  void updateBlueprint(QLBlueprint next) {
    setState(() {
      _blueprint = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return QLDataScope(
      localData: widget.localData,
      localStore: _store,
      moduleStore: _store,
      child: Builder(
        builder: (innerContext) =>
            QuantumVM.instance.renderWidget(innerContext, _blueprint),
      ),
    );
  }
}

void main() {
  setUpAll(() {
    registerOmniComponents(QuantumVM.instance);
  });

  setUp(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
  });

  group('data_core', () {
    test('registers the core and the sliver aliases', () {
      final registry = QuantumVM.instance;

      expect(registry.registryEntry('data'), isNotNull);
      expect(registry.registryEntry('sliver_plane', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('sliver', kind: 'alias'), isNotNull);
    });

    testWidgets('sliver_plane defaults to vertical and accepts sliver children',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{'__subType': 'sliver_plane'},
          children: <Map<String, dynamic>>[
            _nodeJson(_bp(
              'data',
              props: <String, dynamic>{'__subType': 'sliver'},
              children: <Map<String, dynamic>>[
                _textNode('inside sliver'),
              ],
            )),
          ],
        ),
        onBuilt: (widget) => rendered = widget,
      );

      expect(rendered, isA<CustomScrollView>());
      final CustomScrollView scrollView = rendered as CustomScrollView;
      expect(scrollView.scrollDirection, Axis.vertical);
      expect(scrollView.slivers, hasLength(1));
      expect(find.text('inside sliver'), findsOneWidget);
    });

    testWidgets(
        'sliver_plane honors horizontal direction and ignores invalid values',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'sliver_plane',
            'direction': 'horizontal',
          },
          children: <Map<String, dynamic>>[
            _nodeJson(_bp(
              'data',
              props: <String, dynamic>{'__subType': 'sliver'},
              children: <Map<String, dynamic>>[
                _textNode('horizontal child'),
              ],
            )),
          ],
        ),
        onBuilt: (widget) => rendered = widget,
      );

      final CustomScrollView horizontal = rendered as CustomScrollView;
      expect(horizontal.scrollDirection, Axis.horizontal);
      expect(find.text('horizontal child'), findsOneWidget);

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'sliver_plane',
            'direction': 'diagonal',
          },
          children: <Map<String, dynamic>>[
            _nodeJson(_bp(
              'data',
              props: <String, dynamic>{'__subType': 'sliver'},
              children: <Map<String, dynamic>>[
                _textNode('fallback child'),
              ],
            )),
          ],
        ),
      );

      final CustomScrollView fallback = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView).first,
      );
      expect(fallback.scrollDirection, Axis.vertical);
      expect(find.text('fallback child'), findsOneWidget);
    });

    testWidgets('sliver subtype is renderable inside a real sliver viewport',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{'__subType': 'sliver'},
          children: <Map<String, dynamic>>[
            _textNode('sliver body'),
          ],
        ),
        wrap: (child) => CustomScrollView(slivers: <Widget>[child]),
      );

      expect(find.text('sliver body'), findsOneWidget);
      expect(find.byType(SliverToBoxAdapter), findsOneWidget);
    });

    testWidgets('repeat binds each item, exposes index, and preserves order',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'repeat',
            'bind': <dynamic>['alpha', 'beta', 'gamma'],
            'as': 'value',
            'indexAs': 'position',
          },
          children: <Map<String, dynamic>>[
            _textNode('repeat template'),
          ],
        ),
      );

      final scopes = _scopesWithKey(tester, 'value').toList();
      expect(scopes, hasLength(3));
      expect(scopes.map((s) => s.localData['value']),
          <dynamic>['alpha', 'beta', 'gamma']);
      expect(scopes.map((s) => s.localData['position']), <dynamic>[0, 1, 2]);
    });

    testWidgets('repeat renders a hard error when the item template is missing',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'repeat',
            'bind': <dynamic>[1, 2, 3],
          },
        ),
      );

      expect(find.text('Repeat missing template'), findsOneWidget);
      final Text errorText =
          tester.widget<Text>(find.text('Repeat missing template'));
      expect(errorText.style?.color, Colors.red);
    });

    testWidgets(
        'stream reacts to signal changes and treats scalars as a single item',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('data_stream'));
      final signal = store.signal('feed');
      signal.value = <dynamic>['one'];

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'stream',
            'bind': 'feed',
            'as': 'item',
          },
          children: <Map<String, dynamic>>[
            _textNode('stream item'),
          ],
        ),
        store: store,
      );

      expect(_scopesWithKey(tester, 'item'), hasLength(1));
      expect(_singleScopeWithKey(tester, 'item').localData['item'], 'one');

      signal.value = <dynamic>['two', 'three'];
      await tester.pump();
      expect(_scopesWithKey(tester, 'item'), hasLength(2));
      expect(_scopesWithKey(tester, 'item').map((s) => s.localData['item']),
          <dynamic>['two', 'three']);

      signal.value = 'scalar-value';
      await tester.pump();
      expect(_scopesWithKey(tester, 'item'), hasLength(1));
      expect(_singleScopeWithKey(tester, 'item').localData['item'],
          'scalar-value');
    });

    testWidgets('stream uses the empty slot and falls back to child widgets',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('data_stream'));
      final signal = store.signal('feed');
      signal.value = <dynamic>[];

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'stream',
            'bind': 'feed',
            'as': 'item',
          },
          slots: <String, dynamic>{
            'empty': _nodeJson(_bp(
              'text',
              props: <String, dynamic>{'text': 'empty stream'},
            )),
          },
        ),
        store: store,
      );

      expect(find.text('empty stream'), findsOneWidget);

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'stream',
            'bind': 'feed',
            'as': 'item',
          },
          children: <Map<String, dynamic>>[
            _textNode('fallback child'),
          ],
        ),
        store: store,
      );

      expect(find.text('fallback child'), findsOneWidget);
    });

    testWidgets('diff uses explicit keys and keeps duplicate items distinct',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'diff',
            'bind': <dynamic>[
              <String, dynamic>{'id': 'a', 'label': 'Alpha'},
              <String, dynamic>{'id': 'b', 'label': 'Beta'},
            ],
            'as': 'entry',
            'key': 'id',
          },
          children: <Map<String, dynamic>>[
            _textNode('diff template'),
          ],
        ),
      );

      final keyed =
          tester.widgetList<KeyedSubtree>(find.byType(KeyedSubtree)).toList();
      expect(keyed, hasLength(2));
      expect(keyed.map((w) => w.key), <Key?>[
        const ValueKey<String>('a'),
        const ValueKey<String>('b'),
      ]);
    });

    testWidgets('slice clamps negative offsets and stops at the list boundary',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'slice',
            'bind': <dynamic>['zero', 'one', 'two'],
            'start': -99,
            'limit': 99,
            'as': 'item',
          },
          children: <Map<String, dynamic>>[
            _textNode('slice template'),
          ],
        ),
      );

      final scopes = _scopesWithKey(tester, 'item').toList();
      expect(scopes, hasLength(3));
      expect(scopes.map((s) => s.localData['index']), <dynamic>[0, 1, 2]);

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'slice',
            'bind': <dynamic>['zero', 'one', 'two'],
            'start': 100,
            'limit': 10,
            'as': 'item',
          },
          children: <Map<String, dynamic>>[
            _textNode('slice template'),
          ],
        ),
      );

      expect(_scopesWithKey(tester, 'item'), isEmpty);
    });

    testWidgets('cursor publishes hasMore and nextCursor from the store',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('cursor_store'));
      store.set('nextCursor', 'cursor-42');

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'cursor',
            'cursorKey': 'nextCursor',
          },
          children: <Map<String, dynamic>>[
            _textNode('cursor body'),
          ],
        ),
        store: store,
      );

      final scope = _singleScopeWithKey(tester, r'$nextCursor');
      expect(scope.localData[r'$hasMore'], isTrue);
      expect(scope.localData[r'$nextCursor'], 'cursor-42');
    });

    testWidgets('virtual_scroll respects the item height only when positive',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('scroll_store'));
      store.signal('rows').value = <dynamic>['a', 'b', 'c'];

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'virtual_scroll',
            'bind': 'rows',
            'itemHeight': 72,
            'as': 'row',
          },
          children: <Map<String, dynamic>>[
            _textNode('virtual row'),
          ],
        ),
        store: store,
      );

      final ListView listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.itemExtent, 72);
      expect(_scopesWithKey(tester, 'row'), hasLength(3));

      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            '__subType': 'virtual_scroll',
            'bind': 'rows',
            'itemHeight': -1,
            'as': 'row',
          },
          children: <Map<String, dynamic>>[
            _textNode('virtual row'),
          ],
        ),
        store: store,
      );

      final ListView unclamped = tester.widget<ListView>(find.byType(ListView));
      expect(unclamped.itemExtent, isNull);
    });

    testWidgets('missing pipelines surface an explicit not-found message',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'data',
          props: <String, dynamic>{
            'pipeline': 'does-not-exist',
          },
        ),
      );

      expect(find.text('Pipeline not found'), findsOneWidget);
    });
  });

  group('media_core', () {
    test('registers the core and the media aliases', () {
      final registry = QuantumVM.instance;

      expect(registry.registryEntry('media'), isNotNull);
      expect(registry.registryEntry('image', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('avatar', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('video', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('chart', kind: 'alias'), isNotNull);
    });

    testWidgets('icon subtype maps code point, font family, and color exactly',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'icon',
            'codePoint': 0xe87c,
            'fontFamily': 'MaterialIcons',
            'size': 28,
            'color': 0xff123456,
          },
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.size, 28);
      expect(icon.color, const Color(0xff123456));
      expect(icon.icon!.codePoint, 0xe87c);
      expect(icon.icon!.fontFamily, 'MaterialIcons');
    });

    testWidgets('svg_path creates a paintable surface with the requested size',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'svg_path',
            'path': 'M0 0 L10 10',
            'width': 42,
            'height': 24,
            'fill': 0x00000000,
            'stroke': 0xff00ff00,
            'strokeWidth': 2,
          },
        ),
      );

      final CustomPaint paint =
          tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(paint.size, const Size(42, 24));
      expect(paint.painter, isNotNull);
    });

    testWidgets('avatar wraps the image in a circular clip and fixed box',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'avatar',
            'src': 'https://example.com/avatar.png',
            'size': 64,
            'quality': 92,
          },
        ),
      );

      final ClipRRect clip = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(clip.borderRadius, BorderRadius.circular(32));

      final SizedBox box = tester.widget<SizedBox>(
        find
            .descendant(
                of: find.byType(ClipRRect), matching: find.byType(SizedBox))
            .first,
      );
      expect(box.width, 64);
      expect(box.height, 64);
    });

    testWidgets('audio subtype exposes play/pause controls through local data',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'audio',
            'src': 'https://example.com/audio.mp3',
            'autoPlay': false,
          },
          children: <Map<String, dynamic>>[
            _textNode('audio child'),
          ],
        ),
      );

      final scope = _singleScopeWithKey(tester, r'$playing');
      expect(scope.localData[r'$playing'], isFalse);
      expect(scope.localData[r'$position'], 0.0);
      expect(scope.localData[r'$duration'], 1.0);

      final play = scope.localData[r'$play'] as void Function();
      final pause = scope.localData[r'$pause'] as void Function();
      play();
      await tester.pump();
      expect(_singleScopeWithKey(tester, r'$playing').localData[r'$playing'],
          isTrue);
      pause();
      await tester.pump();
      expect(_singleScopeWithKey(tester, r'$playing').localData[r'$playing'],
          isFalse);
    });

    testWidgets('camera and stream primitives remain lightweight placeholders',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'camera',
            'width': 320,
            'height': 240,
          },
        ),
      );

      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      final containers =
          tester.widgetList<Container>(find.byType(Container)).toList();
      expect(containers.any((container) => container.color == Colors.black),
          isTrue);

      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'stream',
            'url': 'rtsp://example/live',
          },
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.textContaining('rtsp://example/live'), findsOneWidget);

      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'webrtc',
            'roomId': 'room-7',
          },
        ),
      );

      expect(find.byIcon(Icons.video_call), findsOneWidget);
      expect(find.textContaining('room-7'), findsOneWidget);
    });

    testWidgets(
        'audio_visualizer and canvas_video degrade safely when no signal exists',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'audio_visualizer',
            'bind': 'audio.waveform',
            'mode': 'bars',
            'count': 32,
          },
        ),
      );

      expect(find.byType(Placeholder), findsOneWidget);
      final SizedBox placeholderBox = tester.widget<SizedBox>(
        find
            .byWidgetPredicate(
                (widget) => widget is SizedBox && widget.height == 50)
            .first,
      );
      expect(placeholderBox.height, 50);

      await _pumpRenderedNode(
        tester,
        _bp(
          'media',
          props: <String, dynamic>{
            '__subType': 'canvas_video',
            'bind': 'video.frame',
            'fit': 'contain',
          },
        ),
      );

      final boxes = tester.widgetList<SizedBox>(find.byType(SizedBox)).toList();
      expect(boxes.any((box) => box.width == 0 && box.height == 0), isTrue);
    });
  });

  group('hook_core', () {
    test('registers the core and the hook aliases', () {
      final registry = QuantumVM.instance;

      expect(registry.registryEntry('hook'), isNotNull);
      expect(
          registry.registryEntry('hook_lifecycle', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('hook_effect', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('hook_scope', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('hook_bridge', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('hook_store', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('hook_atom', kind: 'alias'), isNotNull);
      expect(registry.registryEntry('hook_interval', kind: 'alias'), isNotNull);
      expect(
          registry.registryEntry('hook_observable', kind: 'alias'), isNotNull);
      expect(
          registry.registryEntry('error_boundary', kind: 'alias'), isNotNull);
    });

    testWidgets('lifecycle runs mount and unmount callbacks exactly once',
        (tester) async {
      final List<Map<String, dynamic>> mountCalls = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> unmountCalls = <Map<String, dynamic>>[];
      final String onMount =
          _registerRecordingAction(mountCalls, prefix: 'mount');
      final String onUnmount =
          _registerRecordingAction(unmountCalls, prefix: 'unmount');

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'lifecycle',
            'onMount': <dynamic>[
              <dynamic>[onMount],
            ],
            'onUnmount': <dynamic>[
              <dynamic>[onUnmount],
            ],
          },
          children: <Map<String, dynamic>>[
            _textNode('lifecycle child'),
          ],
        ),
      );
      await tester.pump();
      expect(mountCalls, hasLength(1));
      expect(find.text('lifecycle child'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(unmountCalls, hasLength(1));
    });

    testWidgets('guard blocks child rendering and prefers the fallback slot',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'guard',
            'enabled': false,
          },
          children: <Map<String, dynamic>>[
            _textNode('guarded child'),
          ],
          slots: <String, dynamic>{
            'fallback': _nodeJson(_bp(
              'text',
              props: <String, dynamic>{'text': 'guard fallback'},
            )),
          },
        ),
      );

      expect(find.text('guard fallback'), findsOneWidget);
      expect(find.text('guarded child'), findsNothing);
    });

    testWidgets(
        'memo wraps the child in a stable keyed subtree that changes with the memo key',
        (tester) async {
      final key = GlobalKey<_MutableBlueprintHostState>();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: _MutableBlueprintHost(
              key: key,
              initialBlueprint: _bp(
                'hook',
                props: <String, dynamic>{
                  '__subType': 'memo',
                  'memoKey': 'alpha',
                },
                children: <Map<String, dynamic>>[
                  _textNode('memo child'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final KeyedSubtree first =
          tester.widget<KeyedSubtree>(find.byType(KeyedSubtree));
      expect(first.key, isA<ValueKey<String>>());
      expect(find.text('memo child'), findsOneWidget);

      key.currentState!.updateBlueprint(
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'memo',
            'memoKey': 'beta',
          },
          children: <Map<String, dynamic>>[
            _textNode('memo child'),
          ],
        ),
      );
      await tester.pump();

      final KeyedSubtree second =
          tester.widget<KeyedSubtree>(find.byType(KeyedSubtree));
      expect(second.key, isA<ValueKey<String>>());
      expect(second.key, isNot(equals(first.key)));
    });

    testWidgets(
        'scope and bridge merge env, nested props, and locals without losing values',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'scope',
            'scope': <String, dynamic>{'feature': 'scope'},
            'locals': <String, dynamic>{'localOnly': 7},
          },
          children: <Map<String, dynamic>>[
            _textNode('scope child'),
          ],
        ),
        localData: <String, dynamic>{'envValue': 'present'},
      );

      final scope = _singleScopeWithKey(tester, 'localOnly');
      expect(scope.localData['envValue'], 'present');
      expect(scope.localData['feature'], 'scope');
      expect(scope.localData['localOnly'], 7);
      expect(find.text('scope child'), findsOneWidget);

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'bridge',
            'bridge': <String, dynamic>{'fromBridge': true},
            'payload': <String, dynamic>{'payloadOnly': 'yes'},
          },
          children: <Map<String, dynamic>>[
            _textNode('bridge child'),
          ],
        ),
        localData: <String, dynamic>{'envValue': 'present'},
      );

      final bridge = _singleScopeWithKey(tester, 'payloadOnly');
      expect(bridge.localData['envValue'], 'present');
      expect(bridge.localData['fromBridge'], isTrue);
      expect(bridge.localData['payloadOnly'], 'yes');
    });

    testWidgets(
        'store initializes once and preserves later mutations across rebuilds',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('hook_store'));
      final key = GlobalKey<_MutableBlueprintHostState>();
      final storeId = 'session-store';

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: _MutableBlueprintHost(
              key: key,
              store: store,
              initialBlueprint: _bp(
                'hook',
                props: <String, dynamic>{
                  '__subType': 'store',
                  'id': storeId,
                  'initialState': <String, dynamic>{
                    'count': 1,
                    'mode': 'alpha',
                  },
                },
                children: <Map<String, dynamic>>[
                  _textNode('store child'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(QLStoreRegistry.instance.get(storeId).get('count'), 1);
      expect(QLStoreRegistry.instance.get(storeId).get('mode'), 'alpha');

      QLStoreRegistry.instance.get(storeId).set('count', 9);
      key.currentState!.updateBlueprint(
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'store',
            'id': storeId,
            'initialState': <String, dynamic>{
              'count': 999,
              'mode': 'beta',
            },
          },
          children: <Map<String, dynamic>>[
            _textNode('store child'),
          ],
        ),
      );
      await tester.pump();

      final scopedStore = QLStoreRegistry.instance.get(storeId);
      expect(scopedStore.get('count'), 9);
      expect(scopedStore.get('mode'), 'alpha');
      final scope = _singleScopeWithKey(tester, '@$storeId');
      expect(scope.localData['@$storeId'], storeId);
    });

    testWidgets('atom seeds an empty signal and preserves an existing value',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('atom_store'));
      final existing = store.signal('ui.atom');
      existing.value = 'keep-me';

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'atom',
            'key': 'ui.atom',
            'value': 'seed-me',
            'as': 'atomSignal',
          },
          children: <Map<String, dynamic>>[
            _textNode('atom child'),
          ],
        ),
        store: store,
      );

      final scope = _singleScopeWithKey(tester, 'atomSignal');
      final signal = scope.localData['atomSignal'] as QLSignal<dynamic>;
      expect(signal.value, 'keep-me');
      signal.value = 'updated';
      await tester.pump();
      expect(store.signal('ui.atom').value, 'updated');
    });

    testWidgets('slice reflects live updates from a target store signal',
        (tester) async {
      final targetStore = QLDataStore(namespace: _uniqueName('slice_target'));
      targetStore.signal('profile.tags').value = <dynamic>['one', 'two'];

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'slice',
            'store': targetStore.namespace,
            'path': 'profile.tags',
            'as': 'sliceValue',
          },
          children: <Map<String, dynamic>>[
            _textNode('slice child'),
          ],
        ),
      );

      final first = _singleScopeWithKey(tester, 'sliceValue');
      expect(first.localData['sliceValue'], <dynamic>['one', 'two']);

      targetStore.signal('profile.tags').value = <dynamic>['three'];
      await tester.pump();
      final second = _singleScopeWithKey(tester, 'sliceValue');
      expect(second.localData['sliceValue'], <dynamic>['three']);
    });

    testWidgets('ref exposes a mutable read/write handle through local data',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'ref',
            'id': 'sessionRef',
            'initial': 12,
          },
          children: <Map<String, dynamic>>[
            _textNode('ref child'),
          ],
        ),
      );

      final scope = _singleScopeWithKey(tester, 'sessionRef');
      final dynamic refNode = scope.localData['sessionRef'];
      expect(refNode.read(), 12);
      refNode.write(21);
      expect(refNode.read(), 21);
    });

    testWidgets(
        'interval ticks increment the bind key, trigger actions, and stop after disposal',
        (tester) async {
      final store = QLDataStore(namespace: _uniqueName('interval_store'));
      final calls = <Map<String, dynamic>>[];
      final action = _registerRecordingAction(calls, prefix: 'interval');

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'interval',
            'ms': 20,
            'bind': 'ticks',
            'action': <dynamic>[
              <dynamic>[action],
            ],
          },
          children: <Map<String, dynamic>>[
            _textNode('interval child'),
          ],
        ),
        store: store,
      );

      await tester.pump(const Duration(milliseconds: 25));
      await tester.pump(const Duration(milliseconds: 25));
      expect(store.get('ticks'), 2);
      expect(calls, hasLength(2));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
      expect(store.get('ticks'), 2);
      expect(calls, hasLength(2));
    });

    testWidgets('observable streams update the scoped value and cancel cleanly',
        (tester) async {
      final controller = StreamController<String>.broadcast();
      addTearDown(controller.close);

      QLPluginStreamRegistry.register('live-feed', controller.stream);
      addTearDown(() => QLPluginStreamRegistry.unregister('live-feed'));

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'observable',
            'stream': 'live-feed',
            'as': 'latest',
          },
          children: <Map<String, dynamic>>[
            _textNode('observable child'),
          ],
        ),
      );

      expect(_singleScopeWithKey(tester, 'latest').localData['latest'], isNull);
      controller.add('first');
      await tester.pump();
      expect(
          _singleScopeWithKey(tester, 'latest').localData['latest'], 'first');
      controller.add('second');
      await tester.pump();
      expect(
          _singleScopeWithKey(tester, 'latest').localData['latest'], 'second');
    });

    testWidgets('effect fires on mount and again only when dependencies change',
        (tester) async {
      final calls = <Map<String, dynamic>>[];
      final effectAction = _registerRecordingAction(calls, prefix: 'effect');
      final key = GlobalKey<_MutableBlueprintHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: _MutableBlueprintHost(
              key: key,
              initialBlueprint: _bp(
                'hook',
                props: <String, dynamic>{
                  '__subType': 'effect',
                  'deps': <dynamic>[1],
                  'onEffect': <dynamic>[
                    <dynamic>[effectAction],
                  ],
                },
                children: <Map<String, dynamic>>[
                  _textNode('effect child'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(calls, hasLength(1));

      key.currentState!.updateBlueprint(
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'effect',
            'deps': <dynamic>[2],
            'onEffect': <dynamic>[
              <dynamic>[effectAction],
            ],
          },
          children: <Map<String, dynamic>>[
            _textNode('effect child'),
          ],
        ),
      );
      await tester.pump();
      expect(calls, hasLength(2));

      key.currentState!.updateBlueprint(
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'effect',
            'deps': <dynamic>[2],
            'onEffect': <dynamic>[
              <dynamic>[effectAction],
            ],
          },
          children: <Map<String, dynamic>>[
            _textNode('effect child'),
          ],
        ),
      );
      await tester.pump();
      expect(calls, hasLength(2));
    });

    testWidgets(
        'change skips the mount pass but still reacts to dependency changes',
        (tester) async {
      final calls = <Map<String, dynamic>>[];
      final changeAction = _registerRecordingAction(calls, prefix: 'change');
      final key = GlobalKey<_MutableBlueprintHostState>();

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1024, 768)),
            child: _MutableBlueprintHost(
              key: key,
              initialBlueprint: _bp(
                'hook',
                props: <String, dynamic>{
                  '__subType': 'change',
                  'deps': <dynamic>['a'],
                  'onEffect': <dynamic>[
                    <dynamic>[changeAction],
                  ],
                },
                children: <Map<String, dynamic>>[
                  _textNode('change child'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(calls, isEmpty);

      key.currentState!.updateBlueprint(
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'change',
            'deps': <dynamic>['b'],
            'onEffect': <dynamic>[
              <dynamic>[changeAction],
            ],
          },
          children: <Map<String, dynamic>>[
            _textNode('change child'),
          ],
        ),
      );
      await tester.pump();
      expect(calls, hasLength(1));
    });

    testWidgets(
        'error boundary swaps in the catch child and keeps the finally child visible',
        (tester) async {
      final oldHandler = FlutterError.onError;
      addTearDown(() => FlutterError.onError = oldHandler);
      FlutterError.onError = (FlutterErrorDetails details) {};

      await _pumpRenderedNode(
        tester,
        _bp(
          'hook',
          props: <String, dynamic>{
            '__subType': 'error_boundary',
          },
          children: <Map<String, dynamic>>[
            _textNode('this should not stay visible'),
          ],
          slots: <String, dynamic>{
            'try': _nodeJson(_bp(
              'data',
              props: <String, dynamic>{'__subType': 'sliver_plane'},
              children: <Map<String, dynamic>>[
                _textNode('boom child'),
              ],
            )),
            'catch': _nodeJson(
                _bp('text', props: <String, dynamic>{'text': 'caught'})),
            'finally': _nodeJson(
                _bp('text', props: <String, dynamic>{'text': 'finally'})),
          },
        ),
      );

      await tester.pump();
      await tester.pump();
      expect(find.text('caught'), findsOneWidget);
      expect(find.text('finally'), findsOneWidget);
    });
  });
}
