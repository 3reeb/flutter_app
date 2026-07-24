import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

Widget _shell(
  Widget child, {
  Size size = const Size(420, 320),
  TextDirection textDirection = TextDirection.ltr,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: textDirection,
      child: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

Future<void> _pumpShell(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(420, 320),
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    _shell(child, size: size, textDirection: textDirection),
  );
}

Finder _byKey(String value) => find.byKey(Key(value));

Offset _topLeft(WidgetTester tester, String key) =>
    tester.getTopLeft(_byKey(key));

Size _size(WidgetTester tester, String key) => tester.getSize(_byKey(key));

Widget _fixedBox({required String key, double width = 20, double height = 20}) {
  return Container(
    key: Key(key),
    width: width,
    height: height,
    color: Colors.blue,
  );
}

Widget _scopedAxisProbe({required String key}) {
  return Builder(
    builder: (context) {
      final QuantumScrollScope? scope = QuantumScrollScope.of(context);
      return Text(
        scope == null ? 'none' : scope.axis.name,
        key: Key(key),
      );
    },
  );
}

void main() {
  group('layout_core', () {
    testWidgets('QuantumLayout routes each layout type to the expected engine',
        (tester) async {
      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.grid,
          children: <Widget>[_fixedBox(key: 'g')],
        ),
      );
      expect(find.byType(QuantumGrid), findsOneWidget);
      expect(find.byType(QuantumLayoutScope), findsOneWidget);
      expect(find.text('g'), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.masonry,
          children: <Widget>[_fixedBox(key: 'm')],
        ),
      );
      expect(find.byType(QuantumGrid), findsOneWidget);
      expect(find.text('m'), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.row,
          columnGap: 12,
          rowGap: 24,
          children: <Widget>[
            _fixedBox(key: 'r1', width: 20, height: 20),
            _fixedBox(key: 'r2', width: 20, height: 20),
          ],
        ),
      );
      expect(find.byType(QuantumFlex), findsOneWidget);
      expect(find.byType(Flex), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.col,
          columnGap: 12,
          rowGap: 24,
          children: <Widget>[
            _fixedBox(key: 'c1', width: 20, height: 20),
            _fixedBox(key: 'c2', width: 20, height: 20),
          ],
        ),
      );
      expect(find.byType(QuantumFlex), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.wrap,
          children: <Widget>[_fixedBox(key: 'w')],
        ),
      );
      expect(find.byType(Wrap), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.stack,
          children: <Widget>[_fixedBox(key: 's')],
        ),
      );
      expect(find.byType(Stack), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.split,
          children: <Widget>[_fixedBox(key: 'p1'), _fixedBox(key: 'p2')],
        ),
      );
      expect(find.byType(QuantumSplitPane), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.morph,
          initialMorphSize: const Size(240, 180),
          children: <Widget>[_fixedBox(key: 'mf')],
        ),
      );
      expect(find.byType(QuantumMorphSurface), findsOneWidget);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.none,
          children: <Widget>[
            _fixedBox(key: 'first'),
            _fixedBox(key: 'second'),
          ],
        ),
      );
      expect(find.byKey(const Key('first')), findsOneWidget);
      expect(find.byKey(const Key('second')), findsNothing);

      await _pumpShell(tester, 
        QuantumLayout(layoutType: QLayoutType.none, children: const <Widget>[]),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 0 && widget.height == 0,
        ),
        findsOneWidget,
      );
      expect(find.text('first'), findsNothing);
    });

    testWidgets('QuantumLayoutScope updates when the layout type changes',
        (tester) async {
      final seen = <String>[];
      QLayoutType current = QLayoutType.grid;

      await _pumpShell(tester, 
        StatefulBuilder(
          builder: (context, setState) {
            return QuantumLayout(
              layoutType: current,
              children: <Widget>[
                Builder(
                  builder: (context) {
                    seen.add(QuantumLayoutScope.of(context)!.layoutType);
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        ),
      );

      expect(seen, isNotEmpty);
      expect(seen.last, 'grid');

      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              return QuantumLayout(
                layoutType: current,
                children: <Widget>[
                  Builder(
                    builder: (context) {
                      seen.add(QuantumLayoutScope.of(context)!.layoutType);
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      current = QLayoutType.col;
      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              return QuantumLayout(
                layoutType: current,
                children: <Widget>[
                  Builder(
                    builder: (context) {
                      seen.add(QuantumLayoutScope.of(context)!.layoutType);
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(seen.last, 'col');
    });

    testWidgets('QuantumLayout row uses columnGap and col uses rowGap',
        (tester) async {
      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.row,
          columnGap: 14,
          rowGap: 60,
          children: <Widget>[
            _fixedBox(key: 'row-a', width: 30, height: 20),
            _fixedBox(key: 'row-b', width: 40, height: 20),
          ],
        ),
        size: const Size(240, 120),
      );
      expect(_topLeft(tester, 'row-a').dx, 0);
      expect(_topLeft(tester, 'row-b').dx, 44);

      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.col,
          columnGap: 60,
          rowGap: 18,
          children: <Widget>[
            _fixedBox(key: 'col-a', width: 30, height: 20),
            _fixedBox(key: 'col-b', width: 40, height: 20),
          ],
        ),
        size: const Size(240, 120),
      );
      expect(_topLeft(tester, 'col-a').dy, 0);
      expect(_topLeft(tester, 'col-b').dy, 38);
    });

    testWidgets('QuantumLayout split exposes an interactive splitter',
        (tester) async {
      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.split,
          direction: Axis.horizontal,
          children: <Widget>[
            Container(key: const Key('left'), height: 80, color: Colors.red),
            Container(key: const Key('right'), height: 80, color: Colors.green),
          ],
        ),
        size: const Size(360, 120),
      );

      final double leftBefore = _size(tester, 'left').width;
      final double rightBefore = _size(tester, 'right').width;
      expect(leftBefore, closeTo(rightBefore, 8));

      final divider = find.byType(GestureDetector).first;
      await tester.drag(divider, const Offset(60, 0));
      await tester.pumpAndSettle();

      final double leftAfter = _size(tester, 'left').width;
      final double rightAfter = _size(tester, 'right').width;
      expect(leftAfter, greaterThan(leftBefore));
      expect(rightAfter, lessThan(rightBefore));
    });

    testWidgets('QuantumLayout split keeps single-child mode as passthrough',
        (tester) async {
      await _pumpShell(tester, 
        QuantumLayout(
          layoutType: QLayoutType.split,
          children: <Widget>[_fixedBox(key: 'solo')],
        ),
      );
      expect(find.byType(QuantumSplitPane), findsOneWidget);
      expect(find.byKey(const Key('solo')), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('QuantumFlex inserts gaps exactly between children',
        (tester) async {
      await _pumpShell(tester, 
        QuantumFlex(
          direction: Axis.horizontal,
          gap: 12,
          children: <Widget>[
            _fixedBox(key: 'a', width: 20, height: 20),
            _fixedBox(key: 'b', width: 30, height: 20),
          ],
        ),
        size: const Size(220, 80),
      );

      expect(_topLeft(tester, 'a').dx, 0);
      expect(_topLeft(tester, 'b').dx, 32);

      await _pumpShell(tester, 
        QuantumFlex(
          direction: Axis.vertical,
          gap: 14,
          children: <Widget>[
            _fixedBox(key: 'c', width: 20, height: 20),
            _fixedBox(key: 'd', width: 20, height: 30),
          ],
        ),
        size: const Size(120, 220),
      );

      expect(_topLeft(tester, 'c').dy, 0);
      expect(_topLeft(tester, 'd').dy, 34);
    });

    testWidgets(
        'QuantumFlex creates a scroll shell when the main axis is bounded',
        (tester) async {
      await _pumpShell(tester, 
        QuantumFlex(
          direction: Axis.vertical,
          gap: 0,
          children: <Widget>[
            _fixedBox(key: 'big-1', width: 60, height: 180),
            _fixedBox(key: 'big-2', width: 60, height: 180),
            _scopedAxisProbe(key: 'scope'),
          ],
        ),
        size: const Size(160, 120),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
      expect(find.text('vertical'), findsOneWidget);
      expect(find.byKey(const Key('scope')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuantumFlex respects allowAutoScroll=false', (tester) async {
      await _pumpShell(tester, 
        QuantumFlex(
          direction: Axis.horizontal,
          allowAutoScroll: false,
          gap: 0,
          children: <Widget>[
            _fixedBox(key: 'x', width: 220, height: 40),
            _scopedAxisProbe(key: 'scope'),
          ],
        ),
        size: const Size(120, 80),
      );

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byType(QuantumScrollScope), findsNothing);
      expect(find.text('none'), findsOneWidget);
      expect(find.byKey(const Key('scope')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuantumSplitPane handles empty and single-child edge cases',
        (tester) async {
      await _pumpShell(tester, 
        const QuantumSplitPane(
            direction: Axis.horizontal, children: <Widget>[]),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox && widget.width == 0 && widget.height == 0,
        ),
        findsOneWidget,
      );

      await _pumpShell(tester, 
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: <Widget>[_fixedBox(key: 'only')],
        ),
      );
      expect(find.byKey(const Key('only')), findsOneWidget);
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('QuantumSplitPane normalizes initial fractions',
        (tester) async {
      await _pumpShell(tester, 
        QuantumSplitPane(
          direction: Axis.horizontal,
          initialFractions: const <double>[2, 1],
          children: <Widget>[
            Container(key: const Key('left'), height: 80, color: Colors.red),
            Container(key: const Key('right'), height: 80, color: Colors.green),
          ],
        ),
        size: const Size(300, 120),
      );

      final double leftWidth = _size(tester, 'left').width;
      final double rightWidth = _size(tester, 'right').width;
      expect(leftWidth, closeTo(196, 10));
      expect(rightWidth, closeTo(98, 10));
      expect(leftWidth / rightWidth, closeTo(2.0, 0.2));
    });

    testWidgets('QuantumSplitPane drag updates the pane ratio', (tester) async {
      await _pumpShell(tester, 
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: <Widget>[
            Container(key: const Key('left'), height: 80, color: Colors.red),
            Container(key: const Key('right'), height: 80, color: Colors.green),
          ],
        ),
        size: const Size(360, 120),
      );

      final double leftBefore = _size(tester, 'left').width;
      final double rightBefore = _size(tester, 'right').width;

      await tester.drag(
          find.byType(GestureDetector).first, const Offset(60, 0));
      await tester.pumpAndSettle();

      final double leftAfter = _size(tester, 'left').width;
      final double rightAfter = _size(tester, 'right').width;

      expect(leftAfter, greaterThan(leftBefore));
      expect(rightAfter, lessThan(rightBefore));
      expect((leftAfter + rightAfter), closeTo((leftBefore + rightBefore), 16));
    });

    testWidgets('QuantumSplitPane keeps a minimum fraction under extreme drags',
        (tester) async {
      await _pumpShell(tester, 
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: <Widget>[
            Container(key: const Key('left'), height: 80, color: Colors.red),
            Container(key: const Key('right'), height: 80, color: Colors.green),
          ],
        ),
        size: const Size(360, 120),
      );

      await tester.drag(
          find.byType(GestureDetector).first, const Offset(500, 0));
      await tester.pumpAndSettle();

      final double total =
          _size(tester, 'left').width + _size(tester, 'right').width;
      expect(_size(tester, 'left').width, greaterThan(total * 0.04));
      expect(_size(tester, 'right').width, greaterThan(total * 0.04));
    });

    testWidgets('QuantumGrid honors explicit placement and spans',
        (tester) async {
      await _pumpShell(tester, 
        QuantumGrid(
          columns: 'repeat(2, 100px)',
          rows: '40px 60px',
          columnGap: 10,
          rowGap: 8,
          children: <Widget>[
            QuantumItem(
              colStart: 1,
              rowStart: 1,
              child: _fixedBox(key: 'a'),
            ),
            QuantumItem(
              colStart: 2,
              rowStart: 1,
              child: _fixedBox(key: 'b'),
            ),
            QuantumItem(
              colStart: 1,
              rowStart: 2,
              child: _fixedBox(key: 'c'),
            ),
            QuantumItem(
              colStart: 1,
              rowStart: 1,
              colSpan: 2,
              rowSpan: 2,
              child: _fixedBox(key: 'span', width: 10, height: 10),
            ),
          ],
        ),
        size: const Size(280, 220),
      );

      expect(_topLeft(tester, 'a'), const Offset(0, 0));
      expect(_topLeft(tester, 'b'), const Offset(110, 0));
      expect(_topLeft(tester, 'c'), const Offset(0, 48));
      expect(_size(tester, 'span').width, 210);
      expect(_size(tester, 'span').height, 100);
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuantumGrid auto placement fills rows before wrapping',
        (tester) async {
      await _pumpShell(tester, 
        QuantumGrid(
          columns: '50px 50px 50px',
          rows: '20px 20px',
          columnGap: 10,
          rowGap: 5,
          flow: QFlowDirection.row,
          children: <Widget>[
            QuantumItem(
              colSpan: 2,
              child: _fixedBox(key: 'one', width: 10, height: 10),
            ),
            QuantumItem(
              child: _fixedBox(key: 'two', width: 10, height: 10),
            ),
            QuantumItem(
              child: _fixedBox(key: 'three', width: 10, height: 10),
            ),
          ],
        ),
        size: const Size(260, 200),
      );

      expect(_topLeft(tester, 'one'), const Offset(0, 0));
      expect(_topLeft(tester, 'two'), const Offset(110, 0));
      expect(_topLeft(tester, 'three'), const Offset(0, 25));
    });

    testWidgets('QuantumGrid stretch fills the cell while center/end align',
        (tester) async {
      await _pumpShell(tester, 
        QuantumGrid(
          columns: '100px',
          rows: '80px',
          alignItems: QAlign.center,
          justifyItems: QAlign.end,
          children: <Widget>[
            QuantumItem(
              child: _fixedBox(key: 'center-end', width: 20, height: 20),
            ),
          ],
        ),
        size: const Size(180, 140),
      );

      expect(_topLeft(tester, 'center-end'), const Offset(80, 30));
      expect(_size(tester, 'center-end'), const Size(20, 20));

      await _pumpShell(tester, 
        QuantumGrid(
          columns: '100px',
          rows: '80px',
          children: <Widget>[
            QuantumItem(
              child: _fixedBox(key: 'stretch', width: 20, height: 20),
            ),
          ],
        ),
        size: const Size(180, 140),
      );

      expect(_size(tester, 'stretch'), const Size(100, 80));
      expect(_topLeft(tester, 'stretch'), const Offset(0, 0));
    });

    testWidgets('QuantumGrid honors item-level alignment overrides',
        (tester) async {
      await _pumpShell(tester, 
        QuantumGrid(
          columns: '100px',
          rows: '80px',
          alignItems: QAlign.stretch,
          justifyItems: QAlign.stretch,
          children: <Widget>[
            QuantumItem(
              alignSelf: QAlign.center,
              justifySelf: QAlign.end,
              child: _fixedBox(key: 'override', width: 20, height: 20),
            ),
          ],
        ),
        size: const Size(180, 140),
      );

      expect(_topLeft(tester, 'override'), const Offset(80, 30));
      expect(_size(tester, 'override'), const Size(20, 20));
    });

    testWidgets('QuantumGrid mirrors horizontal placement in RTL',
        (tester) async {
      await _pumpShell(tester, 
        QuantumGrid(
          columns: '100px 50px',
          rows: '60px',
          columnGap: 10,
          children: <Widget>[
            QuantumItem(child: _fixedBox(key: 'rtl-a', width: 20, height: 20)),
            QuantumItem(child: _fixedBox(key: 'rtl-b', width: 20, height: 20)),
          ],
        ),
        size: const Size(220, 120),
        textDirection: TextDirection.rtl,
      );

      expect(_topLeft(tester, 'rtl-a').dx,
          greaterThan(_topLeft(tester, 'rtl-b').dx));
      expect(_topLeft(tester, 'rtl-b').dx, 0);
    });

    testWidgets('QuantumGrid hit testing follows zIndex and updates on rebuild',
        (tester) async {
      final hits = <String>[];
      bool topOnFront = true;

      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              return QuantumGrid(
                columns: '120px',
                rows: '120px',
                children: <Widget>[
                  QuantumItem(
                    ignoreOccupancy: true,
                    zIndex: topOnFront ? 10 : 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => hits.add('top'),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  QuantumItem(
                    ignoreOccupancy: true,
                    zIndex: topOnFront ? 0 : 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => hits.add('bottom'),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            },
          ),
          size: const Size(180, 180),
        ),
      );

      await tester.tapAt(const Offset(40, 40));
      await tester.pump();
      expect(hits, ['top']);

      hits.clear();
      topOnFront = false;
      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              return QuantumGrid(
                columns: '120px',
                rows: '120px',
                children: <Widget>[
                  QuantumItem(
                    ignoreOccupancy: true,
                    zIndex: topOnFront ? 10 : 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => hits.add('top'),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  QuantumItem(
                    ignoreOccupancy: true,
                    zIndex: topOnFront ? 0 : 10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => hits.add('bottom'),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              );
            },
          ),
          size: const Size(180, 180),
        ),
      );

      await tester.tapAt(const Offset(40, 40));
      await tester.pump();
      expect(hits, ['bottom']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('QuantumGrid reacts to updated track definitions on rebuild',
        (tester) async {
      String columns = '100px 100px';
      double gap = 0;

      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              return QuantumGrid(
                columns: columns,
                rows: '80px',
                columnGap: gap,
                children: <Widget>[
                  QuantumItem(
                    colStart: 2,
                    child: _fixedBox(key: 'moved', width: 20, height: 20),
                  ),
                ],
              );
            },
          ),
          size: const Size(260, 140),
        ),
      );

      final double initialDx = _topLeft(tester, 'moved').dx;
      expect(initialDx, 100);

      columns = '40px 100px';
      gap = 12;
      await tester.pumpWidget(
        _shell(
          StatefulBuilder(
            builder: (context, setState) {
              return QuantumGrid(
                columns: columns,
                rows: '80px',
                columnGap: gap,
                children: <Widget>[
                  QuantumItem(
                    colStart: 2,
                    child: _fixedBox(key: 'moved', width: 20, height: 20),
                  ),
                ],
              );
            },
          ),
          size: const Size(260, 140),
        ),
      );

      final double updatedDx = _topLeft(tester, 'moved').dx;
      expect(updatedDx, 52);
      expect(updatedDx, isNot(equals(initialDx)));
    });

    testWidgets('QuantumGrid empty state stays stable and compact',
        (tester) async {
      await _pumpShell(tester, 
        QuantumGrid(
          columns: 'repeat(4, 50px)',
          rows: 'repeat(3, 40px)',
          columnGap: 10,
          rowGap: 8,
          children: const <Widget>[],
        ),
        size: const Size(320, 240),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(QuantumGrid)), const Size(0, 0));
    });
  });
}
