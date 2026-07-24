import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

String _registerSyncThrowAction({String prefix = 'sync_throw'}) {
  final String name = _uniqueName(prefix);
  QuantumVM.instance.registerAction(
    name,
    LambdaActionPlugin((payload, store, ctx) {
      throw StateError('sync boom');
    }),
  );
  return name;
}

String _registerAsyncThrowAction({String prefix = 'async_throw'}) {
  final String name = _uniqueName(prefix);
  QuantumVM.instance.registerAction(
    name,
    LambdaActionPlugin((payload, store, ctx) async {
      throw StateError('async boom');
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

  final GlobalKey innerKey = GlobalKey();

  Widget tree = QLDataScope(
    localData: localData,
    localStore: resolvedStore,
    moduleStore: resolvedStore,
    child: Builder(
      builder: (context) {
        final Widget rendered = QuantumVM.instance.renderWidget(context, node);
        return KeyedSubtree(key: innerKey, child: rendered);
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

  if (onBuilt != null) {
    final Element? keyedElement = innerKey.currentContext as Element?;
    if (keyedElement != null) {
      Element? wrapperElement;
      keyedElement.visitChildren((e) => wrapperElement = e);
      Element? coreElement;
      wrapperElement?.visitChildren((e) => coreElement = e);
      onBuilt(coreElement?.widget ?? wrapperElement?.widget ?? const SizedBox());
    }
  }

  return resolvedStore;
}

void main() {
  setUpAll(() {
    registerOmniComponents(QuantumVM.instance);
  });

  setUp(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
  });

  group('action_core', () {
    testWidgets('tap action fires navigate before click and forwards href',
        (tester) async {
      final List<Map<String, dynamic>> events = <Map<String, dynamic>>[];
      final String navigateAction =
          _registerRecordingAction(events, prefix: 'navigate');
      final String clickAction =
          _registerRecordingAction(events, prefix: 'click');
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));

      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:tap',
          props: <String, dynamic>{
            'href': 'https://example.com',
            'text': 'Go',
            'onNavigate': <dynamic>[
              <dynamic>[navigateAction],
            ],
            'onClick': <dynamic>[
              <dynamic>[clickAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
        onBuilt: (w) => rendered = w,
      );

      expect(rendered, isA<QLSensor>());
      final QLSensor sensor = rendered as QLSensor;
      expect(sensor.onTap, isNotNull);
      expect(sensor.scaleOnTap, isTrue);
      expect(sensor.scaleOnHover, isTrue);

      sensor.onTap!.call();
      await tester.pump();

      expect(events, hasLength(2));
    });

    testWidgets('disabled tap becomes inert and disables scale affordances',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:press',
          props: <String, dynamic>{
            'text': 'Locked',
            'disabled': true,
            'onClick': <dynamic>[
              <dynamic>['never.fire'],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLSensor sensor = rendered as QLSensor;
      expect(sensor.onTap, isNull);
      expect(sensor.scaleOnTap, isFalse);
      expect(sensor.scaleOnHover, isFalse);
    });

    testWidgets('loading tap hides text and suppresses interaction',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:link',
          props: <String, dynamic>{
            'text': 'Loading',
            'loading': true,
            'href': 'https://example.com',
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLSensor sensor = rendered as QLSensor;
      expect(sensor.onTap, isNull);

      final Finder qFinder = find.descendant(
        of: find.byType(QLSensor),
        matching: find.byType(Q),
      );
      final Q qWidget = tester.widget<Q>(qFinder.first);
      expect(qWidget.text, isNull);
    });

    testWidgets('group signal and bind path update when a value is selected',
        (tester) async {
      final List<Map<String, dynamic>> clickCalls = <Map<String, dynamic>>[];
      final String clickAction =
          _registerRecordingAction(clickCalls, prefix: 'group_click');
      final QLSignal<String?> groupSignal = QLSignal<String?>('other');
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));
      store.set('selected', 'other');

      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:tap',
          props: <String, dynamic>{
            'text': 'Plan A',
            'value': 'plan-a',
            'onClick': <dynamic>[
              <dynamic>[clickAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
        localData: <String, dynamic>{
          'groupActiveSignal': groupSignal,
          'groupBindPath': 'selected',
        },
        onBuilt: (w) => rendered = w,
      );

      final QLSensor sensor = rendered as QLSensor;
      sensor.onTap!.call();
      await tester.pump();

      expect(groupSignal.value, 'plan-a');
      expect(store.get('selected'), 'plan-a');
      expect(clickCalls, hasLength(1));
    });

    testWidgets('raw pointer writes coordinates and pressure on every event',
        (tester) async {
      final List<Map<String, dynamic>> releaseCalls = <Map<String, dynamic>>[];
      final String releaseAction =
          _registerRecordingAction(releaseCalls, prefix: 'release');
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));

      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:raw_pointer',
          props: <String, dynamic>{
            'bindX': 'pointer.x',
            'bindY': 'pointer.y',
            'bindPressure': 'pointer.pressure',
            'onRelease': <dynamic>[
              <dynamic>[releaseAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
        onBuilt: (w) => rendered = w,
      );

      expect(rendered, isA<Listener>());
      final Listener listener = rendered as Listener;

      listener.onPointerDown?.call(
        const PointerDownEvent(
          position: Offset(10, 20),
          pressure: 0.42,
        ),
      );
      listener.onPointerMove?.call(
        const PointerMoveEvent(
          position: Offset(12, 24),
          pressure: 0.55,
        ),
      );
      listener.onPointerUp?.call(
        const PointerUpEvent(
          position: Offset(14, 26),
          pressure: 0.33,
        ),
      );
      await tester.pump();

      expect(store.signal('pointer.x').value, 14.0);
      expect(store.signal('pointer.y').value, 26.0);
      expect(store.signal('pointer.pressure').value, 0.33);
      expect(releaseCalls, hasLength(1));
    });

    testWidgets('focus writes state, emits enter, and forwards key labels',
        (tester) async {
      final List<Map<String, dynamic>> focusCalls = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> blurCalls = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> enterCalls = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> keyCalls = <Map<String, dynamic>>[];
      final String focusAction =
          _registerRecordingAction(focusCalls, prefix: 'focus');
      final String blurAction =
          _registerRecordingAction(blurCalls, prefix: 'blur');
      final String enterAction =
          _registerRecordingAction(enterCalls, prefix: 'enter');
      final String keyAction =
          _registerRecordingAction(keyCalls, prefix: 'key');
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));

      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:focus',
          props: <String, dynamic>{
            'bindState': 'focus.state',
            'onFocus': <dynamic>[
              <dynamic>[focusAction],
            ],
            'onBlur': <dynamic>[
              <dynamic>[blurAction],
            ],
            'onEnter': <dynamic>[
              <dynamic>[enterAction],
            ],
            'onKeyPress': <dynamic>[
              <dynamic>[keyAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
        onBuilt: (w) => rendered = w,
      );

      final Focus focusWidget = rendered as Focus;
      focusWidget.onFocusChange!.call(true);
      await tester.pump();
      expect(store.get('focus.state'), isTrue);
      expect(focusCalls, hasLength(1));

      final KeyEventResult result = focusWidget.onKeyEvent!(
        FocusNode(),
        const KeyDownEvent(
          logicalKey: LogicalKeyboardKey.enter,
          physicalKey: PhysicalKeyboardKey.enter,
          timeStamp: Duration.zero,
        ),
      );
      await tester.pump();
      expect(result, KeyEventResult.handled);
      expect(keyCalls, hasLength(1));
      expect(enterCalls, hasLength(1));

      focusWidget.onFocusChange!.call(false);
      await tester.pump();
      expect(store.get('focus.state'), isFalse);
      expect(blurCalls, hasLength(1));
    });

    testWidgets('hover, long press, and double tap wire to the right actions',
        (tester) async {
      final List<Map<String, dynamic>> hoverCalls = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> unhoverCalls = <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> longPressCalls =
          <Map<String, dynamic>>[];
      final List<Map<String, dynamic>> doubleTapCalls =
          <Map<String, dynamic>>[];
      final String hoverAction =
          _registerRecordingAction(hoverCalls, prefix: 'hover');
      final String unhoverAction =
          _registerRecordingAction(unhoverCalls, prefix: 'unhover');
      final String longPressAction =
          _registerRecordingAction(longPressCalls, prefix: 'long_press');
      final String doubleTapAction =
          _registerRecordingAction(doubleTapCalls, prefix: 'double_tap');

      late Widget hoverRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:hover',
          props: <String, dynamic>{
            'onHover': <dynamic>[
              <dynamic>[hoverAction],
            ],
            'onUnhover': <dynamic>[
              <dynamic>[unhoverAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => hoverRendered = w,
      );
      expect(hoverRendered, isA<MouseRegion>());
      final MouseRegion hoverWidget = hoverRendered as MouseRegion;
      hoverWidget.onEnter?.call(PointerEnterEvent(position: Offset.zero));
      hoverWidget.onExit?.call(PointerExitEvent(position: Offset.zero));
      await tester.pump();
      expect(hoverCalls, hasLength(1));
      expect(unhoverCalls, hasLength(1));

      late Widget longPressRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:long_press',
          props: <String, dynamic>{
            'onLongPress': <dynamic>[
              <dynamic>[longPressAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => longPressRendered = w,
      );
      final GestureDetector longPressWidget =
          tester.widget<GestureDetector>(find.descendant(of: find.byWidget(longPressRendered), matching: find.byType(GestureDetector)));
      longPressWidget.onLongPress?.call();
      await tester.pump();
      expect(longPressCalls, hasLength(1));

      late Widget doubleTapRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:double_tap',
          props: <String, dynamic>{
            'onDoubleTap': <dynamic>[
              <dynamic>[doubleTapAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => doubleTapRendered = w,
      );
      final GestureDetector doubleTapWidget =
          tester.widget<GestureDetector>(find.descendant(of: find.byWidget(doubleTapRendered), matching: find.byType(GestureDetector)));
      doubleTapWidget.onDoubleTap?.call();
      await tester.pump();
      expect(doubleTapCalls, hasLength(1));
    });

    testWidgets('gesture subtype builds the raw gesture node and child tree',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:gesture',
          props: <String, dynamic>{
            'onTap': <dynamic>[
              <dynamic>['noop.action'],
            ],
          },
          children: <QLBlueprint>[
            QLBlueprint(
              type: 'box:surface',
              props: <String, dynamic>{
                'fill': 'solid',
                'intent': 'blue-500',
              },
              children: const <QLBlueprint>[],
            ),
          ],
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString().contains('_QLRawGestureNode'),
        ),
        findsOneWidget,
      );
      expect(find.byType(Q), findsWidgets);
    });

    testWidgets('sync action exceptions are swallowed by the safe caller',
        (tester) async {
      final String throwingAction = _registerSyncThrowAction();
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:tap',
          props: <String, dynamic>{
            'text': 'Broken',
            'onClick': <dynamic>[
              <dynamic>[throwingAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLSensor sensor = rendered as QLSensor;
      expect(() => sensor.onTap!.call(), returnsNormally);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('async action exceptions are swallowed by the safe caller',
        (tester) async {
      final String throwingAction = _registerAsyncThrowAction();
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'action:tap',
          props: <String, dynamic>{
            'text': 'Broken async',
            'onClick': <dynamic>[
              <dynamic>[throwingAction],
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLSensor sensor = rendered as QLSensor;
      expect(() => sensor.onTap!.call(), returnsNormally);
      await tester.pump();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('animation_core', () {
    testWidgets('signal animation binds to a store signal and updates opacity',
        (tester) async {
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));
      store.signal('alpha').value = 0.25;

      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:signal',
          props: <String, dynamic>{
            'bind': 'alpha',
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
        onBuilt: (w) => rendered = w,
      );

      expect(rendered, isA<QLAnimatedWidget>());
      final QLAnimatedWidget<dynamic> animated =
          rendered as QLAnimatedWidget<dynamic>;
      expect(animated.signal.value, 0.25);

      final Finder opacityFinder = find.descendant(
        of: find.byType(QLAnimatedWidget),
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsOneWidget);
      expect(tester.widget<Opacity>(opacityFinder).opacity, 0.25);

      store.signal('alpha').value = 0.8;
      await tester.pump();
      expect(tester.widget<Opacity>(opacityFinder).opacity, 0.8);
    });

    testWidgets('signal animation falls back to child when bind is absent',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:signal',
          props: const <String, dynamic>{},
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      expect(rendered, isNot(isA<QLAnimatedWidget>()));
      expect(find.byType(QLAnimatedWidget), findsNothing);
    });

    testWidgets('numeric signal values outside range clamp to full opacity',
        (tester) async {
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));
      store.signal('alpha').value = 4.2;

      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:bind',
          props: <String, dynamic>{
            'bind': 'alpha',
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
      );

      final Finder opacityFinder = find.descendant(
        of: find.byType(QLAnimatedWidget),
        matching: find.byType(Opacity),
      );
      expect(tester.widget<Opacity>(opacityFinder).opacity, 1.0);
    });

    testWidgets('fade, scale, slide, and rotate configure transition widgets',
        (tester) async {
      late Widget fadeRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:fade',
          props: <String, dynamic>{
            'from': 0.2,
            'to': 0.9,
            'durationMs': 123,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => fadeRendered = w,
      );

      final TweenAnimationBuilder<double> fadeWidget =
          fadeRendered as TweenAnimationBuilder<double>;
      final Tween<double> fadeTween = fadeWidget.tween;
      expect(fadeTween.begin, 0.2);
      expect(fadeTween.end, 0.9);
      expect(fadeWidget.duration, const Duration(milliseconds: 123));

      late Widget scaleRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:scale',
          props: <String, dynamic>{
            'from': 0.75,
            'to': 1.0,
            'durationMs': 240,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => scaleRendered = w,
      );
      final TweenAnimationBuilder<double> scaleWidget =
          scaleRendered as TweenAnimationBuilder<double>;
      expect(scaleWidget.duration, const Duration(milliseconds: 240));
      expect((scaleWidget.tween).begin, 0.75);
      expect((scaleWidget.tween).end, 1.0);

      late Widget slideRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:slide',
          props: <String, dynamic>{
            'fromX': 0.1,
            'fromY': 0.3,
            'toX': 0.0,
            'toY': 0.0,
            'durationMs': 180,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => slideRendered = w,
      );
      final TweenAnimationBuilder<Offset> slideWidget =
          slideRendered as TweenAnimationBuilder<Offset>;
      expect(slideWidget.duration, const Duration(milliseconds: 180));
      expect(
          (slideWidget.tween).begin, const Offset(0.1, 0.3));
      expect((slideWidget.tween).end, Offset.zero);

      late Widget rotateRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:rotate',
          props: <String, dynamic>{
            'from': 0.25,
            'to': 1.0,
            'durationMs': 321,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rotateRendered = w,
      );
      final TweenAnimationBuilder<double> rotateWidget =
          rotateRendered as TweenAnimationBuilder<double>;
      expect(rotateWidget.duration, const Duration(milliseconds: 321));
      expect((rotateWidget.tween).begin, 0.25);
      expect((rotateWidget.tween).end, 1.0);
    });

    testWidgets('glass animation passes blur and tint through to QLGlassLayer',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:glass',
          props: <String, dynamic>{
            'blur': 18.0,
            'tint': '#112233',
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLGlassLayer glass = rendered as QLGlassLayer;
      expect(glass.config.blur, 18.0);
      expect(glass.config.tint, const Color(0xFF112233));
    });

    testWidgets('counter animation formats decimal places', (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:counter',
          props: <String, dynamic>{
            'from': 1.5,
            'to': 2.75,
            'decimals': 2,
            'durationMs': 1,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      expect(rendered, isA<TweenAnimationBuilder<double>>());
      final Finder textFinder = find.byType(Text);
      final Text text = tester.widget<Text>(textFinder.last);
      expect(text.data, '1.50');
    });

    testWidgets('cross animation respects slot selection and slot widgets',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'animation:cross',
          props: <String, dynamic>{
            'showFirst': false,
            'durationMs': 210,
          },
          slots: <String, QLBlueprint>{
            'first': QLBlueprint(
              type: 'box:surface',
              props: <String, dynamic>{
                'fill': 'solid',
                'intent': 'red-500',
              },
              children: const <QLBlueprint>[],
            ),
            'second': QLBlueprint(
              type: 'box:surface',
              props: <String, dynamic>{
                'fill': 'solid',
                'intent': 'blue-500',
              },
              children: const <QLBlueprint>[],
            ),
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final AnimatedCrossFade crossFade = rendered as AnimatedCrossFade;
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);
      expect(crossFade.duration, const Duration(milliseconds: 210));
      expect(crossFade.firstChild, isNot(same(crossFade.secondChild)));
    });
  });

  group('box_core', () {
    testWidgets('split returns a QLBox shell with full-size wrapper semantics',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:split',
          props: const <String, dynamic>{
            'direction': 'horizontal',
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLBox box = rendered as QLBox;
      expect(box.suppressParentData, isTrue);
      expect(box.style, contains('w-full h-full'));
      expect(box.child, isA<LayoutBuilder>());
    });

    testWidgets('expanded and flexible emit QuantumFlexible with expected fit',
        (tester) async {
      late Widget expandedRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:expanded',
          props: const <String, dynamic>{
            'flex': 3,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => expandedRendered = w,
      );
      final QuantumFlexible expanded = expandedRendered as QuantumFlexible;
      expect(expanded.flex, 3);
      expect(expanded.fit, FlexFit.tight);

      late Widget flexibleRendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:flexible',
          props: const <String, dynamic>{
            'flex': 2,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => flexibleRendered = w,
      );
      final QuantumFlexible flexible = flexibleRendered as QuantumFlexible;
      expect(flexible.flex, 2);
      expect(flexible.fit, FlexFit.loose);
    });

    testWidgets('matrix and layer bind matrix and opacity signals',
        (tester) async {
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));
      store.signal('matrix.bind').value = Matrix4.identity();
      store.signal('opacity.bind').value = 0.25;

      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:matrix',
          props: <String, dynamic>{
            'matrixBind': 'matrix.bind',
            'opacityBind': 'opacity.bind',
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
        onBuilt: (w) => rendered = w,
      );

      final QLBox box = rendered as QLBox;
      expect(box.transform3D, isNotNull);
      expect(box.opacity, isNotNull);
      expect(box.transform3D!.value.storage[0], 1.0);
      expect(box.opacity!.value, 0.25);

      store.signal('opacity.bind').value = 0.8;
      store.signal('matrix.bind').value =
          Matrix4.translationValues(7, 8, 9).storage;
      await tester.pump();

      expect(box.opacity!.value, 0.8);
      expect(box.transform3D!.value.storage[12], 7.0);
      expect(box.transform3D!.value.storage[13], 8.0);
      expect(box.transform3D!.value.storage[14], 9.0);
    });

    testWidgets('surface and shell resolve design-matrix styles',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:surface',
          props: const <String, dynamic>{
            'fill': 'solid',
            'intent': 'emerald-500',
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final Q q = rendered as Q;
      expect(q.style, contains('bg-emerald-500'));
      expect(q.style, contains('text-white'));
    });

    testWidgets('safe box forwards safe-area flags', (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:safe',
          props: const <String, dynamic>{
            'top': false,
            'bottom': true,
            'left': false,
            'right': true,
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final SafeArea safe = rendered as SafeArea;
      expect(safe.top, isFalse);
      expect(safe.bottom, isTrue);
      expect(safe.left, isFalse);
      expect(safe.right, isTrue);
    });

    testWidgets('responsive box injects viewport and breakpoint flags',
        (tester) async {
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:responsive',
          props: const <String, dynamic>{},
          children: const <QLBlueprint>[],
        ),
        mediaSize: const Size(500, 700),
      );

      final QLDataScope responsiveScope = tester
          .widgetList<QLDataScope>(find.byType(QLDataScope))
          .firstWhere((scope) => scope.localData.containsKey('isCompact'));

      expect(responsiveScope.localData['width'], 500);
      expect(responsiveScope.localData['height'], 700);
      expect(responsiveScope.localData['isCompact'], isTrue);
      expect(responsiveScope.localData['isMedium'], isFalse);
      expect(responsiveScope.localData['isLarge'], isFalse);
    });

    testWidgets('viewport box injects viewport dimensions', (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:viewport',
          props: const <String, dynamic>{},
          children: const <QLBlueprint>[],
        ),
        mediaSize: const Size(901, 733),
        onBuilt: (w) => rendered = w,
      );

      final QLDataScope scope = rendered as QLDataScope;
      expect(scope.localData['viewportWidth'], 901);
      expect(scope.localData['viewportHeight'], 733);
    });

    testWidgets('measure writes and updates the bound rectangle',
        (tester) async {
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));

      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:measure',
          props: const <String, dynamic>{
            'bind': 'measureRect',
          },
          children: <QLBlueprint>[
            QLBlueprint(
              type: 'box:surface',
              props: const <String, dynamic>{
                'fill': 'solid',
                'intent': 'blue-500',
              },
              children: const <QLBlueprint>[],
            ),
          ],
        ),
        store: store,
        wrap: (child) => Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 12, top: 18),
            child: SizedBox(width: 40, height: 30, child: child),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dynamic firstRect = store.signal('measureRect').value;
      expect(firstRect, isNotNull);

      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'box:measure',
          props: const <String, dynamic>{
            'bind': 'measureRect',
          },
          children: <QLBlueprint>[
            QLBlueprint(
              type: 'box:surface',
              props: const <String, dynamic>{
                'fill': 'solid',
                'intent': 'blue-500',
              },
              children: const <QLBlueprint>[],
            ),
          ],
        ),
        store: store,
        wrap: (child) => Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 44, top: 8),
            child: SizedBox(width: 72, height: 24, child: child),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dynamic secondRect = store.signal('measureRect').value;
      expect(secondRect, isNotNull);
    });
  });

  group('canvas_core', () {
    testWidgets(
        'draw compiles commands into a procedural canvas node and tolerates malformed entries',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'canvas:draw',
          props: const <String, dynamic>{
            'commands': <dynamic>[
              <dynamic>['rect', 1, 2, 3, 4, '#112233'],
              <dynamic>['circle', '10', '20', '5', '#445566'],
              <dynamic>['bad'],
              <dynamic>[],
              null,
            ],
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      expect(
        rendered.runtimeType.toString().contains('_QLProceduralCanvasNode'),
        isTrue,
      );
      final Finder paintFinder = find.byType(CustomPaint);
      expect(paintFinder, findsWidgets);
      final CustomPaint paintWidget = tester.widget<CustomPaint>(paintFinder.last);
      expect(
        paintWidget.painter.runtimeType
            .toString()
            .contains('_QLProceduralPainter'),
        isTrue,
      );
    });

    testWidgets('plot creates a vertex plot painter for Float64List data',
        (tester) async {
      final QLDataStore store = QLDataStore(namespace: _uniqueName('store'));
      store.signal('series').value =
          Float64List.fromList(<double>[1.0, 2.0, 3.5]);

      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'canvas:plot',
          props: const <String, dynamic>{
            'bind': 'series',
            'mode': 'line',
            'stepX': 8.0,
            'gapX': 2.0,
            'scaleY': 1.5,
            'baseline': 'center',
            'thickness': 3.0,
            'color': '#3366FF',
          },
          children: const <QLBlueprint>[],
        ),
        store: store,
      );

      expect(find.byType(RepaintBoundary), findsWidgets);
      final CustomPaint paintWidget =
          tester.widget<CustomPaint>(find.byType(CustomPaint).last);
      expect(
        paintWidget.painter.runtimeType
            .toString()
            .contains('_QLVertexPlotPainter'),
        isTrue,
      );
      expect(paintWidget.size, Size.infinite);
    });

    testWidgets('shape canvas returns a shape node with parsed color',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'canvas:shape',
          props: <String, dynamic>{
            'shapeDef': <String, dynamic>{
              'kind': 'rect',
              'radius': 8,
            },
            'fillColor': '#112233',
          },
          children: const <QLBlueprint>[],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLShapeNode shapeNode = rendered as QLShapeNode;
      expect(shapeNode.color, const Color(0xFF112233));
      expect(shapeNode.shapeDef, isNotNull);
    });

    testWidgets('default canvas branch keeps children in a scene layer stack',
        (tester) async {
      late Widget rendered;
      await _pumpRenderedNode(
        tester,
        QLBlueprint(
          type: 'canvas:scene',
          props: const <String, dynamic>{},
          children: <QLBlueprint>[
            QLBlueprint(
              type: 'text',
              props: const <String, dynamic>{'text': 'scene child'},
              children: const <QLBlueprint>[],
            ),
          ],
        ),
        onBuilt: (w) => rendered = w,
      );

      final QLSceneLayerWidget scene = rendered as QLSceneLayerWidget;
      expect(scene.isComplex, isTrue);
      expect(scene.willChange, isTrue);
      expect(find.byType(Stack), findsOneWidget);
      expect(find.text('scene child'), findsOneWidget);
    });
  });
}
