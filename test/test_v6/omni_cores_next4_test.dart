import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

int _sequence = 0;

String _uniqueName(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';

Future<QLDataStore> _pumpBlueprint(
  WidgetTester tester,
  QLBlueprint blueprint, {
  Map<String, dynamic> localData = const <String, dynamic>{},
  QLDataStore? store,
  Size mediaSize = const Size(1024, 768),
  void Function(Widget rendered)? onBuilt,
}) async {
  final QLDataStore resolvedStore =
      store ?? QLDataStore(namespace: _uniqueName('store'));

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: mediaSize),
        child: QLDataScope(
          localData: localData,
          localStore: resolvedStore,
          moduleStore: resolvedStore,
          child: Builder(
            builder: (context) {
              final Widget rendered = QuantumVM.instance.renderWidget(
                context,
                blueprint,
              );
              onBuilt?.call(rendered);
              return rendered;
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return resolvedStore;
}

Finder _textFinder() =>
    find.descendant(of: find.byType(QLDataScope), matching: find.byType(Text));

Text _firstTextWidget(WidgetTester tester) =>
    tester.widget<Text>(_textFinder().first);

SelectableText _firstSelectableText(WidgetTester tester) =>
    tester.widget<SelectableText>(find.byType(SelectableText).first);

void _clearStreamRegistry() {
  for (final key in QLPluginStreamRegistry.keys.toList()) {
    QLPluginStreamRegistry.unregister(key);
  }
}

void main() {
  setUpAll(() {
    QEngine.instance.initialize();
    registerOmniComponents(QuantumVM.instance);
  });

  setUp(() {
    clearQuantumInputRegistry();
    QLStoreRegistry.instance.clearAll();
    _clearStreamRegistry();
  });

  tearDown(() async {
    await Future<void>.delayed(Duration.zero);
    _clearStreamRegistry();
  });

  group('chart_core', () {
    test('registers the chart component and representative aliases', () {
      final registry = QuantumVM.instance;

      expect(registry.registryEntry('chart'), isNotNull);
      expect(registry.registryEntry('line', kind: 'alias'), isNotNull);

      final aliasNames = registry
          .registryEntries(kind: 'alias', query: 'line')
          .map((e) => e.name)
          .toSet();

      expect(aliasNames, contains('line'));
      expect(aliasNames, contains('chart_line'));
      expect(aliasNames, contains('line_chart'));
      expect(aliasNames, contains('media_line_chart'));
    });

    testWidgets('falls back to line for missing or invalid chartType',
        (tester) async {
      late Widget rendered;
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'chart',
          'props': <String, dynamic>{
            'chartType': 'definitely-not-a-chart-type',
            'data': <dynamic>[1, 2, 3],
          },
        }),
        onBuilt: (widget) => rendered = widget,
      );

      final QLUniversalChart chart =
          tester.widget<QLUniversalChart>(find.byType(QLUniversalChart));
      expect(chart.type, QLChartType.line);
      expect(chart.rawData, equals(<dynamic>[1, 2, 3]));
      expect(find.byType(QLBox), findsWidgets);
    });

    testWidgets('respects explicit chart props on the universal chart widget',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'chart:bar',
          'props': <String, dynamic>{
            'chartType': 'bar',
            'color': '#112233',
            'showGrid': false,
            'showAxes': false,
            'animated': false,
            'lineWidth': 7.5,
            'data': <dynamic>[
              <String, dynamic>{'x': 0, 'y': 10},
              <String, dynamic>{'x': 1, 'y': 14},
            ],
          },
        }),
      );

      final QLUniversalChart chart =
          tester.widget<QLUniversalChart>(find.byType(QLUniversalChart));
      expect(chart.type, QLChartType.bar);
      expect(chart.showGrid, isFalse);
      expect(chart.showAxes, isFalse);
      expect(chart.animate, isFalse);
      expect(chart.lineWidth, 7.5);
      expect(chart.color.toARGB32(), 0xFF112233);
    });

    testWidgets('tooltips expose hover metadata through a scoped slot',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'chart',
          'props': <String, dynamic>{
            'data': <dynamic>[1, 2, 3],
          },
          'slots': <String, dynamic>{
            'tooltip': <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'hover slot'},
            },
          },
        }),
      );

      final BuildContext chartContext =
          tester.element(find.byType(QLUniversalChart));
      final QLUniversalChart chart =
          tester.widget<QLUniversalChart>(find.byType(QLUniversalChart));
      final Widget tooltip = chart.tooltipBuilder!(
        chartContext,
        2,
        const Offset(40, 50),
        <String, dynamic>{'y': 99},
      );

      await tester
          .pumpWidget(MaterialApp(home: Stack(children: <Widget>[tooltip])));
      await tester.pump();

      final QLDataScope scope =
          tester.widget<QLDataScope>(find.byType(QLDataScope).first);
      expect(scope.localData['hoverIndex'], 2);
      expect(scope.localData['hoverData'], <String, dynamic>{'y': 99});
      expect(find.text('hover slot'), findsOneWidget);
    });
  });

  group('text_core', () {
    testWidgets('h1 text renders as a bold heading', (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'text:h1',
          'props': <String, dynamic>{'text': 'Headline'},
        }),
      );

      final Text text = _firstTextWidget(tester);
      expect(text.data, 'Headline');
      expect(text.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('selectable text with children uses rich selectable rendering',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'text:rich',
          'props': <String, dynamic>{
            'selectable': true,
            'text': 'ignored leaf value',
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'child piece'},
            },
          ],
        }),
      );

      expect(find.byType(SelectableText), findsOneWidget);
      final SelectableText selectable = _firstSelectableText(tester);
      expect(selectable.textSpan, isNotNull);
      expect(selectable.textSpan!.children, hasLength(1));
    });

    testWidgets('explicit overflow settings are passed through unchanged',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'text',
          'props': <String, dynamic>{
            'text': 'Overflow',
            'overflow': 'ellipsis',
            'softWrap': false,
            'maxLines': 1,
          },
        }),
      );

      final Text text = _firstTextWidget(tester);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(text.softWrap, isFalse);
      expect(text.maxLines, 1);
    });

    testWidgets('unrecognized subtypes still render the supplied content',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'text:__unknown__',
          'props': <String, dynamic>{'value': 'Fallback content'},
        }),
      );

      final Text text = _firstTextWidget(tester);
      expect(text.data, 'Fallback content');
      expect(text.softWrap, isTrue);
    });
  });

  group('decoration_core', () {
    testWidgets('gradient decoration uses the provided endpoints',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'decoration:gradient',
          'props': <String, dynamic>{
            'beginColor': 0xFF010203,
            'endColor': 0xFF040506,
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'Gradient body'},
            },
          ],
        }),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(QLDataScope),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final LinearGradient gradient = decoration.gradient as LinearGradient;
      expect(gradient.colors,
          <Color>[const Color(0xFF010203), const Color(0xFF040506)]);
    });

    testWidgets('border decoration clamps invalid width and radius values',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'decoration:border',
          'props': <String, dynamic>{
            'width': -9,
            'radius': -4,
            'color': 0xFFABCDEF,
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'Border body'},
            },
          ],
        }),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(QLDataScope),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final Border border = decoration.border as Border;
      expect(border.top.width, 0);
      expect(border.top.color, const Color(0xFFABCDEF));
      expect((decoration.borderRadius as BorderRadius).topLeft.x, 0);
    });

    testWidgets(
        'badge decoration wraps the body only when the label is non-empty',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'decoration:badge',
          'props': <String, dynamic>{'label': '7'},
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'Inbox'},
            },
          ],
        }),
      );

      expect(
        find.descendant(
          of: find.byType(QLDataScope),
          matching: find.byType(Stack),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(QLDataScope),
          matching: find.byType(Positioned),
        ),
        findsOneWidget,
      );
      expect(find.text('Inbox'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('merge-style decoration can apply clip and pointer wrappers',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'decoration',
          'props': <String, dynamic>{
            'mergeStyle': 'px-2',
            'clip': true,
            'ignorePointer': true,
            'absorbPointer': true,
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'Wrapped body'},
            },
          ],
        }),
      );

      expect(
        find.descendant(
          of: find.byType(QLDataScope),
          matching: find.byType(ClipRect),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(QLDataScope),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(QLDataScope),
          matching: find.byType(AbsorbPointer),
        ),
        findsOneWidget,
      );
      expect(find.text('Wrapped body'), findsOneWidget);
    });
  });

  group('stream_core', () {
    testWidgets('ws nodes register and unregister their stream key',
        (tester) async {
      const String url = 'wss://example.com/socket';

      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'stream:ws',
          'props': <String, dynamic>{'url': url},
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'WS child'},
            },
          ],
        }),
      );

      expect(QLPluginStreamRegistry.has(url), isTrue);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      expect(QLPluginStreamRegistry.has(url), isFalse);
    });

    testWidgets('sse nodes mirror a registered source stream into their scope',
        (tester) async {
      final StreamController<String> source =
          StreamController<String>.broadcast(sync: true);
      const String url = 'stream://events';
      QLPluginStreamRegistry.register(url, source.stream);

      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'stream:sse',
          'props': <String, dynamic>{'url': url, 'as': 'event'},
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': '{{event}}'},
            },
          ],
        }),
      );

      source.add('alpha');
      await tester.pump();

      expect(_firstTextWidget(tester).data, contains('alpha'));
      await source.close();
    });

    testWidgets('tick nodes clamp to 16ms and update the exposed counter',
        (tester) async {
      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'stream:tick',
          'props': <String, dynamic>{'ms': 1, 'as': 'tick'},
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': '{{tick}}'},
            },
          ],
        }),
      );

      expect(_firstTextWidget(tester).data, '0');

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();

      final int value = int.parse(_firstTextWidget(tester).data!);
      expect(value, greaterThanOrEqualTo(1));
    });

    testWidgets('ring buffers keep newest items first and enforce capacity',
        (tester) async {
      final QLDataStore store = QLDataStore(namespace: _uniqueName('ring'));
      final QLSignal<dynamic> signal = store.signal('source');

      await _pumpBlueprint(
        tester,
        QLBlueprint.fromJson(<String, dynamic>{
          'type': 'stream:ring',
          'props': <String, dynamic>{
            'capacity': 2,
            'bind': 'source',
            'as': 'ring',
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': '{{ring}}'},
            },
          ],
        }),
        store: store,
      );

      signal.value = 'one';
      await tester.pump();
      expect(_firstTextWidget(tester).data, contains('one'));

      signal.value = 'two';
      await tester.pump();
      expect(_firstTextWidget(tester).data, contains('[two, one]'));

      signal.value = 'three';
      await tester.pump();
      final String rendered = _firstTextWidget(tester).data ?? '';
      expect(rendered, contains('three'));
      expect(rendered, contains('two'));
      expect(rendered, isNot(contains('one')));
    });
  });
}
