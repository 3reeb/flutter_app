// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

Future<void> _pumpSurface(
  WidgetTester tester,
  Widget child, {
  required Size size,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox.expand(child: child),
      ),
    ),
  );
  await tester.pump();
}

Widget _tile(
  String label, {
  double width = 88,
  double height = 56,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(border: Border.all(width: 1)),
      child: Center(child: Text(label, textDirection: TextDirection.ltr)),
    ),
  );
}

Widget _column({
  required List<Widget> children,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
}) {
  return QuantumLayoutScope(
    layoutType: 'col',
    child: QuantumFlex(
      direction: Axis.vertical,
      gap: 0,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    ),
  );
}

Widget _row({
  required List<Widget> children,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
}) {
  return QuantumLayoutScope(
    layoutType: 'row',
    child: QuantumFlex(
      direction: Axis.horizontal,
      gap: 0,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children,
    ),
  );
}

void main() {
  group('quantum_layout_scroll_regressions', () {
    testWidgets('vertical page shell scrolls a tall body safely',
        (tester) async {
      await _pumpSurface(
        tester,
        _column(
          children: [
            _tile('scroll-top', height: 72),
            _tile('scroll-mid-1', height: 72),
            _tile('scroll-mid-2', height: 72),
            _tile('scroll-mid-3', height: 72),
            _tile('scroll-bottom', height: 72),
          ],
        ),
        size: const Size(360, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('scroll-bottom'), findsOneWidget);
    });

    testWidgets('vertical page shell keeps a short body stable',
        (tester) async {
      await _pumpSurface(
        tester,
        _column(
          children: [
            _tile('fit-a', height: 40),
            _tile('fit-b', height: 40),
          ],
        ),
        size: const Size(360, 540),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('fit-a'), findsOneWidget);
      expect(find.text('fit-b'), findsOneWidget);
    });

    testWidgets(
        'nested QuantumFlexible chain inside a vertical scroll scope does not conflict',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _column(
            children: [
              QuantumFlexible(
                child: QuantumFlexible(
                  child: _tile('nested-scroll-flex', height: 64),
                ),
              ),
              _tile('tail', height: 64),
            ],
          ),
        ),
        size: const Size(360, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('nested-scroll-flex'), findsOneWidget);
    });

    testWidgets(
        'nested QuantumFlexible chain inside a horizontal scroll scope does not conflict',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.horizontal,
          child: _row(
            children: [
              QuantumFlexible(
                child: QuantumFlexible(
                  child: _tile('nested-row-flex', width: 120, height: 48),
                ),
              ),
              _tile('row-tail', width: 120, height: 48),
            ],
          ),
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('nested-row-flex'), findsOneWidget);
    });

    testWidgets(
        'top box stays fixed while the child column scrolls independently',
        (tester) async {
      await _pumpSurface(
        tester,
        _column(
          children: [
            _tile('fixed-header', height: 56),
            QuantumScrollScope(
              axis: Axis.vertical,
              child: SizedBox(
                height: 140,
                child: _column(
                  children: [
                    _tile('child-scroll-1', height: 58),
                    _tile('child-scroll-2', height: 58),
                    _tile('child-scroll-3', height: 58),
                  ],
                ),
              ),
            ),
          ],
        ),
        size: const Size(360, 240),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('fixed-header'), findsOneWidget);
      expect(find.text('child-scroll-3'), findsOneWidget);
    });

    testWidgets(
        'child scroll shell remains usable inside a non-scroll parent box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 300,
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(width: 1)),
              child: QuantumScrollScope(
                axis: Axis.vertical,
                child: _column(
                  children: [
                    _tile('box-child-1', height: 60),
                    _tile('box-child-2', height: 60),
                    _tile('box-child-3', height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
        size: const Size(360, 260),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('box-child-2'), findsOneWidget);
    });

    testWidgets(
        'row layout survives a narrow viewport with flexible descendants',
        (tester) async {
      await _pumpSurface(
        tester,
        _row(
          children: [
            _tile('row-left', width: 96, height: 48),
            QuantumFlexible(child: _tile('row-flex', width: 96, height: 48)),
            _tile('row-right', width: 96, height: 48),
          ],
        ),
        size: const Size(220, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('row-flex'), findsOneWidget);
    });

    testWidgets(
        'column layout survives a short viewport with flexible descendants',
        (tester) async {
      await _pumpSurface(
        tester,
        _column(
          children: [
            _tile('col-top', height: 64),
            QuantumFlexible(child: _tile('col-flex', height: 64)),
            _tile('col-bottom', height: 64),
          ],
        ),
        size: const Size(240, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('col-flex'), findsOneWidget);
    });

    testWidgets('same-axis scroll scope keeps a tall row from overflowing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.horizontal,
          child: _row(
            children: [
              _tile('wide-1', width: 140, height: 52),
              _tile('wide-2', width: 140, height: 52),
              _tile('wide-3', width: 140, height: 52),
            ],
          ),
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('wide-3'), findsOneWidget);
    });

    testWidgets('same-axis scroll scope keeps a tall column from overflowing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _column(
            children: [
              _tile('tall-a', height: 72),
              _tile('tall-b', height: 72),
              _tile('tall-c', height: 72),
            ],
          ),
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('tall-c'), findsOneWidget);
    });

    testWidgets('mixed nested boxes do not trigger parent data conflicts',
        (tester) async {
      await _pumpSurface(
        tester,
        _column(
          children: [
            _row(
              children: [
                _tile('mix-left', width: 72, height: 42),
                QuantumFlexible(
                  child: _column(
                    children: [
                      _tile('mix-inner-1', height: 42),
                      _tile('mix-inner-2', height: 42),
                    ],
                  ),
                ),
              ],
            ),
            _tile('mix-footer', height: 42),
          ],
        ),
        size: const Size(420, 240),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('mix-inner-2'), findsOneWidget);
    });

    testWidgets('deeply nested columns remain scroll-safe in a strict window',
        (tester) async {
      await _pumpSurface(
        tester,
        _column(
          children: [
            _column(
              children: [
                _tile('deep-a', height: 54),
                _tile('deep-b', height: 54),
                _tile('deep-c', height: 54),
              ],
            ),
            _tile('deep-tail', height: 54),
          ],
        ),
        size: const Size(320, 190),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('deep-tail'), findsOneWidget);
    });
  });
}
