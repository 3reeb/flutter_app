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

Widget _vShell({
  required List<Widget> children,
}) {
  return QuantumLayoutScope(
    layoutType: 'col',
    child: QuantumFlex(
      direction: Axis.vertical,
      gap: 0,
      children: children,
    ),
  );
}

Widget _hShell({
  required List<Widget> children,
}) {
  return QuantumLayoutScope(
    layoutType: 'row',
    child: QuantumFlex(
      direction: Axis.horizontal,
      gap: 0,
      children: children,
    ),
  );
}

Widget _boundedPanel({
  required double width,
  required double height,
  required Widget child,
}) {
  return Center(
    child: SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(width: 1)),
        child: child,
      ),
    ),
  );
}

void main() {
  group('quantum_layout_production_regressions', () {
    testWidgets('oversized vertical page wraps into a scrollable shell',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('page-1', height: 72),
            _tile('page-2', height: 72),
            _tile('page-3', height: 72),
            _tile('page-4', height: 72),
            _tile('page-5', height: 72),
          ],
        ),
        size: const Size(360, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('page-5'), findsOneWidget);
    });

    testWidgets('short vertical page stays stable and does not throw',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('short-a', height: 44),
            _tile('short-b', height: 44),
          ],
        ),
        size: const Size(360, 560),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('short-a'), findsOneWidget);
    });

    testWidgets('oversized horizontal page wraps into a scrollable shell',
        (tester) async {
      await _pumpSurface(
        tester,
        _hShell(
          children: [
            _tile('wide-1', width: 140, height: 52),
            _tile('wide-2', width: 140, height: 52),
            _tile('wide-3', width: 140, height: 52),
            _tile('wide-4', width: 140, height: 52),
          ],
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('wide-4'), findsOneWidget);
    });

    testWidgets('short horizontal page stays stable and does not throw',
        (tester) async {
      await _pumpSurface(
        tester,
        _hShell(
          children: [
            _tile('row-a', width: 72, height: 44),
            _tile('row-b', width: 72, height: 44),
          ],
        ),
        size: const Size(360, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('row-a'), findsOneWidget);
    });

    testWidgets('fixed header and scroll body share the same page safely',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('fixed-header', height: 56),
            _boundedPanel(
              width: 320,
              height: 140,
              child: _vShell(
                children: [
                  _tile('body-a', height: 58),
                  _tile('body-b', height: 58),
                  _tile('body-c', height: 58),
                ],
              ),
            ),
          ],
        ),
        size: const Size(360, 240),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('fixed-header'), findsOneWidget);
      expect(find.text('body-c'), findsOneWidget);
    });

    testWidgets(
        'fixed sidebar and long content row do not overflow in a narrow window',
        (tester) async {
      await _pumpSurface(
        tester,
        _hShell(
          children: [
            _tile('sidebar', width: 96, height: 120),
            _boundedPanel(
              width: 160,
              height: 120,
              child: _hShell(
                children: [
                  _tile('content-1', width: 100, height: 88),
                  _tile('content-2', width: 100, height: 88),
                  _tile('content-3', width: 100, height: 88),
                ],
              ),
            ),
          ],
        ),
        size: const Size(300, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('sidebar'), findsOneWidget);
      expect(find.text('content-3'), findsOneWidget);
    });

    testWidgets(
        'child box scrolls independently inside a fixed-height parent box',
        (tester) async {
      await _pumpSurface(
        tester,
        _boundedPanel(
          width: 300,
          height: 180,
          child: _vShell(
            children: [
              _tile('box-top', height: 56),
              _tile('box-mid', height: 56),
              _tile('box-bottom', height: 56),
            ],
          ),
        ),
        size: const Size(360, 240),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('box-bottom'), findsOneWidget);
    });

    testWidgets(
        'nested scroll scope in a vertical panel keeps the content safe',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _boundedPanel(
            width: 320,
            height: 160,
            child: _vShell(
              children: [
                _tile('scope-v-1', height: 60),
                _tile('scope-v-2', height: 60),
                _tile('scope-v-3', height: 60),
              ],
            ),
          ),
        ),
        size: const Size(360, 240),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('scope-v-3'), findsOneWidget);
    });

    testWidgets(
        'nested scroll scope in a horizontal panel keeps the content safe',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.horizontal,
          child: _boundedPanel(
            width: 220,
            height: 140,
            child: _hShell(
              children: [
                _tile('scope-h-1', width: 100, height: 48),
                _tile('scope-h-2', width: 100, height: 48),
                _tile('scope-h-3', width: 100, height: 48),
              ],
            ),
          ),
        ),
        size: const Size(280, 200),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('scope-h-3'), findsOneWidget);
    });

    testWidgets('deeply nested boxes in a strict viewport remain stable',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _hShell(
              children: [
                _vShell(
                  children: [
                    _tile('deep-1', height: 52),
                    _tile('deep-2', height: 52),
                    _tile('deep-3', height: 52),
                  ],
                ),
                _vShell(
                  children: [
                    _tile('deep-4', height: 52),
                    _tile('deep-5', height: 52),
                    _tile('deep-6', height: 52),
                  ],
                ),
              ],
            ),
            _tile('deep-footer', height: 52),
          ],
        ),
        size: const Size(320, 200),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('deep-footer'), findsOneWidget);
    });

    testWidgets(
        'QuantumFlexible chain inside a column resolves without parent data conflict',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumLayoutScope(
          layoutType: 'col',
          child: QuantumFlex(
            direction: Axis.vertical,
            gap: 0,
            children: [
              QuantumFlexible(
                child: QuantumFlexible(
                  child: _tile('nested-col-flex', height: 64),
                ),
              ),
              _tile('nested-col-tail', height: 64),
            ],
          ),
        ),
        size: const Size(360, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('nested-col-flex'), findsOneWidget);
    });

    testWidgets(
        'QuantumFlexible chain inside a row resolves without parent data conflict',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumLayoutScope(
          layoutType: 'row',
          child: QuantumFlex(
            direction: Axis.horizontal,
            gap: 0,
            children: [
              QuantumFlexible(
                child: QuantumFlexible(
                  child: _tile('nested-row-flex', width: 120, height: 48),
                ),
              ),
              _tile('nested-row-tail', width: 120, height: 48),
            ],
          ),
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('nested-row-flex'), findsOneWidget);
    });

    testWidgets('flexible middle panel in a narrow toolbar row stays bounded',
        (tester) async {
      await _pumpSurface(
        tester,
        _hShell(
          children: [
            _tile('left-chip', width: 64, height: 40),
            QuantumFlexible(
                child: _tile('middle-chip', width: 120, height: 40)),
            _tile('right-chip', width: 64, height: 40),
          ],
        ),
        size: const Size(240, 120),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('middle-chip'), findsOneWidget);
    });

    testWidgets('flexible body in a short card column stays bounded',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('card-head', height: 48),
            QuantumFlexible(child: _tile('card-body', height: 120)),
            _tile('card-foot', height: 48),
          ],
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('card-body'), findsOneWidget);
    });

    testWidgets('scrollable form section keeps its action row reachable',
        (tester) async {
      await _pumpSurface(
        tester,
        _boundedPanel(
          width: 320,
          height: 200,
          child: _vShell(
            children: [
              _tile('form-title', height: 48),
              _tile('field-1', height: 56),
              _tile('field-2', height: 56),
              _tile('field-3', height: 56),
              _tile('form-submit', height: 48),
            ],
          ),
        ),
        size: const Size(360, 260),
      );

      expect(tester.takeException(), isNull);
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);
      await tester.drag(scrollView, const Offset(0, -120));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('form-submit'), findsOneWidget);
    });

    testWidgets('bottom-sheet-like panel keeps long content within bounds',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 340,
            height: 180,
            child: _vShell(
              children: [
                _tile('sheet-grabber', height: 20),
                _tile('sheet-line-1', height: 60),
                _tile('sheet-line-2', height: 60),
                _tile('sheet-line-3', height: 60),
              ],
            ),
          ),
        ),
        size: const Size(360, 300),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('sheet-line-3'), findsOneWidget);
    });

    testWidgets('split pane left side can hold a scrollable vertical stack',
        (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 360,
          height: 240,
          child: QuantumSplitPane(
            direction: Axis.horizontal,
            initialFractions: const [0.35, 0.65],
            children: [
              _vShell(
                children: [
                  _tile('split-left-1', height: 54),
                  _tile('split-left-2', height: 54),
                  _tile('split-left-3', height: 54),
                ],
              ),
              _vShell(
                children: [
                  _tile('split-right-1', height: 54),
                  _tile('split-right-2', height: 54),
                ],
              ),
            ],
          ),
        ),
        size: const Size(360, 260),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('split-left-3'), findsOneWidget);
    });

    testWidgets('split pane right side can hold a scrollable vertical stack',
        (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 360,
          height: 240,
          child: QuantumSplitPane(
            direction: Axis.horizontal,
            initialFractions: const [0.25, 0.75],
            children: [
              _vShell(
                children: [
                  _tile('left-1', height: 42),
                  _tile('left-2', height: 42),
                ],
              ),
              _vShell(
                children: [
                  _tile('right-1', height: 54),
                  _tile('right-2', height: 54),
                  _tile('right-3', height: 54),
                  _tile('right-4', height: 54),
                ],
              ),
            ],
          ),
        ),
        size: const Size(360, 260),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('right-4'), findsOneWidget);
    });

    testWidgets(
        'aspect-ratio wrapper stays stable when nested inside a scroll shell',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            SizedBox(
              height: 120,
              child: QuantumAspectRatio(
                ratio: 1.5,
                child: _tile('ratio-child', width: 180, height: 80),
              ),
            ),
            _tile('ratio-tail', height: 56),
          ],
        ),
        size: const Size(320, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('ratio-tail'), findsOneWidget);
    });

    testWidgets('morph surface content remains visible inside a bounded page',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            SizedBox(
              height: 180,
              child: QuantumMorphSurface(
                initialSize: const Size(180, 120),
                lockAspectRatio: false,
                snapGrid: 4,
                child: _tile('morph-child', width: 180, height: 120),
              ),
            ),
            _tile('morph-tail', height: 48),
          ],
        ),
        size: const Size(320, 260),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('morph-tail'), findsOneWidget);
    });

    testWidgets(
        'row of cards with one tall card stays safe in a tight viewport',
        (tester) async {
      await _pumpSurface(
        tester,
        _hShell(
          children: [
            _tile('card-a', width: 90, height: 140),
            _tile('card-b', width: 90, height: 180),
            _tile('card-c', width: 90, height: 140),
          ],
        ),
        size: const Size(260, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('card-b'), findsOneWidget);
    });

    testWidgets(
        'column of cards with one wide child stays safe in a tight viewport',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('stack-a', height: 48),
            _tile('stack-b', width: 220, height: 48),
            _tile('stack-c', height: 48),
          ],
        ),
        size: const Size(220, 170),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('stack-b'), findsOneWidget);
    });

    testWidgets('nested row inside column with a flexible center stays stable',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('header', height: 44),
            _hShell(
              children: [
                _tile('left-pane', width: 72, height: 72),
                QuantumFlexible(
                    child: _tile('center-pane', width: 120, height: 72)),
                _tile('right-pane', width: 72, height: 72),
              ],
            ),
            _tile('footer', height: 44),
          ],
        ),
        size: const Size(320, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('center-pane'), findsOneWidget);
    });

    testWidgets('row inside column with a flexible footer stays stable',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('top-banner', height: 52),
            _hShell(
              children: [
                _tile('nav-left', width: 84, height: 48),
                _tile('nav-right', width: 84, height: 48),
              ],
            ),
            QuantumFlexible(child: _tile('footer-flex', height: 120)),
          ],
        ),
        size: const Size(300, 180),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('footer-flex'), findsOneWidget);
    });

    testWidgets(
        'independent scroll panel inside a card stays interactive after drag',
        (tester) async {
      await _pumpSurface(
        tester,
        _boundedPanel(
          width: 320,
          height: 180,
          child: _vShell(
            children: [
              _tile('card-head', height: 42),
              _tile('card-row-1', height: 56),
              _tile('card-row-2', height: 56),
              _tile('card-row-3', height: 56),
            ],
          ),
        ),
        size: const Size(360, 240),
      );

      expect(tester.takeException(), isNull);
      final scrollView = find.byType(SingleChildScrollView);
      expect(scrollView, findsOneWidget);
      await tester.drag(scrollView, const Offset(0, -100));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('card-row-3'), findsOneWidget);
    });

    testWidgets(
        'nested scroll panel inside another scroll panel does not overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _vShell(
          children: [
            _tile('outer-head', height: 48),
            _boundedPanel(
              width: 300,
              height: 140,
              child: _vShell(
                children: [
                  _tile('inner-head', height: 48),
                  _tile('inner-body', height: 48),
                  _tile('inner-foot', height: 48),
                ],
              ),
            ),
          ],
        ),
        size: const Size(340, 220),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('inner-foot'), findsOneWidget);
    });
  });
}
