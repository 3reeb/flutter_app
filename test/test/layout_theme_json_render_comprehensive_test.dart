import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  testWidgets('QThemeDictionary parses aliases as aliases and resolves them',
      (tester) async {
    final dictionary = QThemeDictionary.fromJson({
      'colors': {
        'primary': '#3366ff',
      },
      'labels': {
        'title': 'Dashboard',
      },
      'spacing': {
        'sm': 4,
      },
      'aliases': {
        'brand': '#112233',
      },
    });

    final graph = QThemeGraph()..load(dictionary);
    expect(dictionary.aliases.containsKey('aliases.brand'), isTrue);
    expect(dictionary.aliases['aliases.brand'], '#112233');
    expect(graph.color('colors.primary'), isNotNull);
    expect(graph.number('spacing.sm'), closeTo(4.0, 0.001));
    expect(graph.text('labels.title'), 'Dashboard');
    expect(graph.color('aliases.brand'), isNotNull);
  });

  testWidgets(
      'Q flex-1 tokens expand inside row layouts and react to resize constraints',
      (tester) async {
    Widget build(double width) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: width,
              height: 160,
              child: Q(
                'row gap-8',
                children: [
                  Q('flex-1', children: const [
                    SizedBox(height: 24, child: Text('grow'))
                  ]),
                  const SizedBox(width: 48, child: Text('fixed')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(360));
    expect(tester.takeException(), isNull);
    expect(find.text('grow'), findsOneWidget);
    expect(find.text('fixed'), findsOneWidget);
    final wideFixedDx = tester.getTopLeft(find.text('fixed')).dx;
    expect(wideFixedDx, greaterThan(tester.getTopLeft(find.text('grow')).dx));

    await tester.pumpWidget(build(240));
    expect(tester.takeException(), isNull);
    final narrowFixedDx = tester.getTopLeft(find.text('fixed')).dx;
    expect(narrowFixedDx, lessThan(wideFixedDx));
  });

  testWidgets('Q row layouts render children side by side instead of stacking',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 320,
              height: 160,
              child: Q(
                'row gap-12 items-center',
                children: const [Text('left'), Text('right')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Flex), findsOneWidget);
    final left = tester.getTopLeft(find.text('left'));
    final right = tester.getTopLeft(find.text('right'));
    expect(right.dx, greaterThan(left.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Q col layouts render children vertically with spacing',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Q(
                'col gap-10 items-center',
                children: const [Text('top'), Text('bottom')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Flex), findsOneWidget);
    final top = tester.getTopLeft(find.text('top'));
    final bottom = tester.getTopLeft(find.text('bottom'));
    expect(bottom.dy, greaterThan(top.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Q wrap layouts keep many children on screen without overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 260,
              height: 220,
              child: Q(
                'wrap gap-6',
                children: List<Widget>.generate(
                  12,
                  (i) => Container(
                    width: 72,
                    height: 24,
                    alignment: Alignment.center,
                    child: Text('tag-$i'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Q stack layouts remain overlays when explicitly requested',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 180,
              height: 180,
              child: Q(
                'stack',
                children: const [Text('base'), Text('overlay')],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Stack), findsOneWidget);
    expect(find.text('base'), findsOneWidget);
    expect(find.text('overlay'), findsOneWidget);
  });

  testWidgets('QuantumLayout responds to row, column and split modes',
      (tester) async {
    Widget build(QLayoutType type) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: QuantumLayout(
            layoutType: type,
            columnGap: 8,
            rowGap: 8,
            children: const [Text('one'), Text('two')],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(QLayoutType.row));
    expect(find.byType(Flex), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.col));
    expect(find.byType(Flex), findsOneWidget);

    await tester.pumpWidget(build(QLayoutType.split));
    expect(find.byType(QuantumSplitPane), findsOneWidget);
  });

  testWidgets('QuantumFlex inserts gap spacers only when the gap is positive',
      (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: QuantumFlex(
          direction: Axis.horizontal,
          gap: 12,
          children: [Text('a'), Text('b')],
        ),
      ),
    );

    expect(find.byType(SizedBox), findsWidgets);
    final flex = tester.widget<Flex>(find.byType(Flex));
    expect(flex.children.length, 3);
  });

  testWidgets('QuantumSplitPane can be resized interactively', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 500,
            height: 240,
            child: QuantumSplitPane(
              direction: Axis.horizontal,
              children: const [
                ColoredBox(color: Colors.red),
                ColoredBox(color: Colors.blue)
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('QuantumMorphSurface resize handle changes the surface size',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: QuantumMorphSurface(
            initialSize: const Size(120, 80),
            lockAspectRatio: false,
            snapGrid: 0,
            child: const ColoredBox(color: Colors.green),
          ),
        ),
      ),
    );

    final before = tester.getSize(find.byType(QuantumMorphSurface));
    await tester.drag(find.byIcon(Icons.drag_indicator), const Offset(30, 20));
    await tester.pump();
    final after = tester.getSize(find.byType(QuantumMorphSurface));
    expect(after.width, greaterThanOrEqualTo(before.width));
    expect(after.height, greaterThanOrEqualTo(before.height));
  });

  testWidgets('QuantumVirtualGridView scrolls to late items without overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 360,
            height: 300,
            child: QuantumVirtualGridView(
              itemCount: 180,
              itemBuilder: (context, index) => SizedBox(
                height: 32,
                child: Text('item-$index'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('item-0'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.dragUntilVisible(
      find.text('item-179'),
      find.byType(CustomScrollView),
      const Offset(0, -800),
      maxIteration: 60,
    );
    await tester.pumpAndSettle();
    expect(find.text('item-179'), findsOneWidget);
  });

  testWidgets('QuantumSduiEngine processes plain payload maps and JSON strings',
      (tester) async {
    final plain = await QuantumSduiEngine.instance.processRaw({
      'ui': {
        'type': 'box:col',
        'props': {'gap': 8},
        'children': [
          {
            'type': 'text',
            'props': {'text': 'hello'}
          },
        ],
      },
    });

    final fromJson = await QuantumSduiEngine.instance.processRaw('''
      {
        "view": {
          "type": "box:col",
          "props": {"gap": 8},
          "children": [
            {"type": "text", "props": {"text": "hello"}}
          ]
        }
      }
    ''');

    expect(plain.type, 'box:col');
    expect(fromJson.type, 'box:col');
    expect(plain.children, isNotEmpty);
    expect(fromJson.children, isNotEmpty);
  });

  testWidgets('QuantumSduiEngine compiles template and raw map payloads',
      (tester) async {
    final template = await QuantumSduiEngine.instance.processRaw({
      'template': {
        'type': 'box:row',
        'props': {'gap': 4},
        'children': [
          {
            'type': 'text',
            'props': {'text': 'a'}
          },
          {
            'type': 'text',
            'props': {'text': 'b'}
          },
        ],
      },
    });

    final raw = await QuantumSduiEngine.instance.processRaw({
      'type': 'box:row',
      'props': {'gap': 4},
      'children': [
        {
          'type': 'text',
          'props': {'text': 'x'}
        },
        {
          'type': 'text',
          'props': {'text': 'y'}
        },
      ],
    });

    expect(template.type, 'box:row');
    expect(raw.type, 'box:row');
  });

  testWidgets('QuantumLayout and Q cooperate on nested layout hierarchies',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 420,
            height: 320,
            child: QuantumLayout(
              layoutType: QLayoutType.col,
              rowGap: 12,
              children: [
                Q('row gap-8',
                    children: const [Text('left-1'), Text('right-1')]),
                Q('row gap-8',
                    children: const [Text('left-2'), Text('right-2')]),
                Q('col gap-4', children: const [Text('top'), Text('bottom')]),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('left-1'), findsOneWidget);
    expect(find.text('right-2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
