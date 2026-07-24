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

Widget _panel(
  String label, {
  double width = 64,
  double height = 64,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(width: 1),
      ),
      child: Center(
        child: Text(label, textDirection: TextDirection.ltr),
      ),
    ),
  );
}

Widget _rowHarness({
  required List<Widget> children,
  double gap = 0,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.max,
}) {
  return QuantumLayoutScope(
    layoutType: 'row',
    child: QuantumFlex(
      direction: Axis.horizontal,
      gap: gap,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    ),
  );
}

Widget _columnHarness({
  required List<Widget> children,
  double gap = 0,
  MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.max,
}) {
  return QuantumLayoutScope(
    layoutType: 'col',
    child: QuantumFlex(
      direction: Axis.vertical,
      gap: gap,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    ),
  );
}

void main() {
  group('Group 001 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G001-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G001-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G001-deep', width: 88, height: 44),
              ),
            ),
            _panel('G001-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G001-deep'), findsOneWidget);
    });

    testWidgets('G001-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G001-alpha', width: 56, height: 40),
            _panel('G001-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G001-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G001-gamma'), findsOneWidget);
    });

    testWidgets('G001-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G001-one')),
            QuantumFlexible(child: _panel('G001-two')),
            _panel('G001-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G001-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G001-narrow-1', width: 90, height: 28),
            _panel('G001-narrow-2', width: 90, height: 28),
            _panel('G001-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G001-narrow-3'), findsOneWidget);
    });

    testWidgets('G001-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G001-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G001-loose'), findsOneWidget);
    });
  });

  group('Group 002 - column-scroll-fit @ 375x667', () {
    testWidgets('G002-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G002-top', width: 180, height: 42),
              _panel('G002-mid-a', width: 180, height: 42),
              _panel('G002-mid-b', width: 180, height: 42),
              _panel('G002-mid-c', width: 180, height: 42),
              _panel('G002-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G002-bottom'), findsOneWidget);
    });

    testWidgets('G002-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G002-one', width: 200, height: 48),
              _panel('G002-two', width: 200, height: 48),
              _panel('G002-three', width: 200, height: 48),
              _panel('G002-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G002-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G002-stretched-1', height: 36),
            _panel('G002-stretched-2', height: 36),
            _panel('G002-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G002-stretched-2'), findsOneWidget);
    });

    testWidgets('G002-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G002-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G002-inner-1'),
                _panel('G002-inner-2'),
              ],
            ),
            _panel('G002-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G002-inner-2'), findsOneWidget);
    });

    testWidgets('G002-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G002-a', height: 30),
            _panel('G002-b', height: 30),
            _panel('G002-c', height: 30),
            _panel('G002-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 003 - split-pane-horizontal @ 390x844', () {
    testWidgets('G003-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G003-left', width: 120, height: 180),
            _panel('G003-center', width: 120, height: 180),
            _panel('G003-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G003-center'), findsOneWidget);
    });

    testWidgets('G003-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G003-a', width: 96, height: 160),
            _panel('G003-b', width: 96, height: 160),
            _panel('G003-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G003-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G003-p1'),
            _panel('G003-p2'),
            _panel('G003-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G003-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G003-slot-1')),
            SizedBox.expand(child: _panel('G003-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G003-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G003-x'),
            _panel('G003-y'),
            _panel('G003-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G003-z'), findsOneWidget);
    });
  });

  group('Group 004 - split-pane-vertical @ 414x896', () {
    testWidgets('G004-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G004-top', width: 180, height: 60),
            _panel('G004-mid', width: 180, height: 60),
            _panel('G004-bottom', width: 180, height: 60),
            _panel('G004-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G004-tail'), findsOneWidget);
    });

    testWidgets('G004-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G004-a', width: 160, height: 50),
            _panel('G004-b', width: 160, height: 50),
            _panel('G004-c', width: 160, height: 50),
            _panel('G004-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G004-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G004-one'),
            _panel('G004-two'),
            _panel('G004-three'),
            _panel('G004-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G004-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G004-header'),
            _panel('G004-content'),
            _panel('G004-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G004-content'), findsOneWidget);
    });

    testWidgets('G004-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G004-inner-1'), _panel('G004-inner-2')]),
            _panel('G004-middle'),
            _rowHarness(children: [_panel('G004-row-1'), _panel('G004-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 005 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G005-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G005-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G005-ratio'), findsOneWidget);
    });

    testWidgets('G005-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G005-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G005-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G005-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G005-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G005-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G005-sq-3'), findsOneWidget);
    });

    testWidgets('G005-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G005-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G005-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G005-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G005-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 006 - morph-surface-handle @ 768x1024', () {
    testWidgets('G006-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G006-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G006-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G006-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G006-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G006-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G006-centered'), findsOneWidget);
    });

    testWidgets(
        'G006-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G006-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G006-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G006-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 007 - hydration-claim-path @ 820x1180', () {
    testWidgets('G007-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/7',
        'props': {'title': 'G007', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/7');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G007');
    });

    testWidgets('G007-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/7/once',
        'props': {'variant': 'once', 'index': 6},
      });
      expect(QLHydration.claimProps('/layout/7/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/7/once'), isNull);
    });

    testWidgets('G007-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/7/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/7/other'), isNull);
      expect(QLHydration.claimProps('/layout/7/match'), isNotNull);
    });

    testWidgets('G007-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/7/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G007',
        },
      });
      final claimed = QLHydration.claimProps('/layout/7/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G007-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G007-hydration-root'),
            _panel('G007-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 008 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G008-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G008-wrap-1', width: 58, height: 28),
                _panel('G008-wrap-2', width: 64, height: 28),
                _panel('G008-wrap-3', width: 72, height: 28),
                _panel('G008-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G008-wrap-4'), findsOneWidget);
    });

    testWidgets('G008-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G008-gap-1'),
            _panel('G008-gap-2'),
            _panel('G008-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G008-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G008-mix-1'),
                _panel('G008-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G008-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G008-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G008-compact-1', width: 100, height: 26),
                _panel('G008-compact-2', width: 100, height: 26),
                _panel('G008-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G008-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G008-recalc-1'),
            _panel('G008-recalc-2'),
            _panel('G008-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 009 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G009-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G009-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G009-stack-a', width: 88, height: 30),
                _panel('G009-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G009-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G009-stack-b'), findsOneWidget);
    });

    testWidgets('G009-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G009-row-inner-1'),
                _panel('G009-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G009-col-inner-1'),
                _panel('G009-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G009-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G009-outer-text'),
            _columnHarness(children: [
              _panel('G009-inner-text-a'),
              _panel('G009-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G009-inner-text-b'), findsOneWidget);
    });

    testWidgets('G009-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G009-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G009-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G009-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G009-pass-1'), _panel('G009-pass-2')]),
            _panel('G009-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 010 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G010-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G010-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G010-orphan'), findsOneWidget);
    });

    testWidgets('G010-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G010-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G010-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G010-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G010-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G010-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G010-discoverable'), findsOneWidget);
    });

    testWidgets('G010-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G010-normal'),
            QuantumFlexible(child: _panel('G010-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 011 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G011-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G011-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G011-deep', width: 88, height: 44),
              ),
            ),
            _panel('G011-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G011-deep'), findsOneWidget);
    });

    testWidgets('G011-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G011-alpha', width: 56, height: 40),
            _panel('G011-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G011-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G011-gamma'), findsOneWidget);
    });

    testWidgets('G011-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G011-one')),
            QuantumFlexible(child: _panel('G011-two')),
            _panel('G011-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G011-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G011-narrow-1', width: 90, height: 28),
            _panel('G011-narrow-2', width: 90, height: 28),
            _panel('G011-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G011-narrow-3'), findsOneWidget);
    });

    testWidgets('G011-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G011-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G011-loose'), findsOneWidget);
    });
  });

  group('Group 012 - column-scroll-fit @ 375x667', () {
    testWidgets('G012-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G012-top', width: 180, height: 42),
              _panel('G012-mid-a', width: 180, height: 42),
              _panel('G012-mid-b', width: 180, height: 42),
              _panel('G012-mid-c', width: 180, height: 42),
              _panel('G012-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G012-bottom'), findsOneWidget);
    });

    testWidgets('G012-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G012-one', width: 200, height: 48),
              _panel('G012-two', width: 200, height: 48),
              _panel('G012-three', width: 200, height: 48),
              _panel('G012-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G012-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G012-stretched-1', height: 36),
            _panel('G012-stretched-2', height: 36),
            _panel('G012-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G012-stretched-2'), findsOneWidget);
    });

    testWidgets('G012-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G012-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G012-inner-1'),
                _panel('G012-inner-2'),
              ],
            ),
            _panel('G012-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G012-inner-2'), findsOneWidget);
    });

    testWidgets('G012-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G012-a', height: 30),
            _panel('G012-b', height: 30),
            _panel('G012-c', height: 30),
            _panel('G012-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 013 - split-pane-horizontal @ 390x844', () {
    testWidgets('G013-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G013-left', width: 120, height: 180),
            _panel('G013-center', width: 120, height: 180),
            _panel('G013-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G013-center'), findsOneWidget);
    });

    testWidgets('G013-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G013-a', width: 96, height: 160),
            _panel('G013-b', width: 96, height: 160),
            _panel('G013-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G013-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G013-p1'),
            _panel('G013-p2'),
            _panel('G013-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G013-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G013-slot-1')),
            SizedBox.expand(child: _panel('G013-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G013-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G013-x'),
            _panel('G013-y'),
            _panel('G013-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G013-z'), findsOneWidget);
    });
  });

  group('Group 014 - split-pane-vertical @ 414x896', () {
    testWidgets('G014-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G014-top', width: 180, height: 60),
            _panel('G014-mid', width: 180, height: 60),
            _panel('G014-bottom', width: 180, height: 60),
            _panel('G014-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G014-tail'), findsOneWidget);
    });

    testWidgets('G014-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G014-a', width: 160, height: 50),
            _panel('G014-b', width: 160, height: 50),
            _panel('G014-c', width: 160, height: 50),
            _panel('G014-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G014-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G014-one'),
            _panel('G014-two'),
            _panel('G014-three'),
            _panel('G014-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G014-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G014-header'),
            _panel('G014-content'),
            _panel('G014-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G014-content'), findsOneWidget);
    });

    testWidgets('G014-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G014-inner-1'), _panel('G014-inner-2')]),
            _panel('G014-middle'),
            _rowHarness(children: [_panel('G014-row-1'), _panel('G014-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 015 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G015-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G015-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G015-ratio'), findsOneWidget);
    });

    testWidgets('G015-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G015-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G015-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G015-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G015-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G015-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G015-sq-3'), findsOneWidget);
    });

    testWidgets('G015-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G015-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G015-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G015-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G015-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 016 - morph-surface-handle @ 768x1024', () {
    testWidgets('G016-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G016-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G016-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G016-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G016-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G016-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G016-centered'), findsOneWidget);
    });

    testWidgets(
        'G016-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G016-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G016-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G016-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 017 - hydration-claim-path @ 820x1180', () {
    testWidgets('G017-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/17',
        'props': {'title': 'G017', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/17');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G017');
    });

    testWidgets('G017-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/17/once',
        'props': {'variant': 'once', 'index': 16},
      });
      expect(QLHydration.claimProps('/layout/17/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/17/once'), isNull);
    });

    testWidgets('G017-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/17/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/17/other'), isNull);
      expect(QLHydration.claimProps('/layout/17/match'), isNotNull);
    });

    testWidgets('G017-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/17/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G017',
        },
      });
      final claimed = QLHydration.claimProps('/layout/17/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G017-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G017-hydration-root'),
            _panel('G017-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 018 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G018-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G018-wrap-1', width: 58, height: 28),
                _panel('G018-wrap-2', width: 64, height: 28),
                _panel('G018-wrap-3', width: 72, height: 28),
                _panel('G018-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G018-wrap-4'), findsOneWidget);
    });

    testWidgets('G018-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G018-gap-1'),
            _panel('G018-gap-2'),
            _panel('G018-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G018-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G018-mix-1'),
                _panel('G018-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G018-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G018-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G018-compact-1', width: 100, height: 26),
                _panel('G018-compact-2', width: 100, height: 26),
                _panel('G018-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G018-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G018-recalc-1'),
            _panel('G018-recalc-2'),
            _panel('G018-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 019 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G019-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G019-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G019-stack-a', width: 88, height: 30),
                _panel('G019-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G019-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G019-stack-b'), findsOneWidget);
    });

    testWidgets('G019-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G019-row-inner-1'),
                _panel('G019-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G019-col-inner-1'),
                _panel('G019-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G019-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G019-outer-text'),
            _columnHarness(children: [
              _panel('G019-inner-text-a'),
              _panel('G019-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G019-inner-text-b'), findsOneWidget);
    });

    testWidgets('G019-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G019-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G019-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G019-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G019-pass-1'), _panel('G019-pass-2')]),
            _panel('G019-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 020 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G020-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G020-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G020-orphan'), findsOneWidget);
    });

    testWidgets('G020-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G020-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G020-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G020-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G020-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G020-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G020-discoverable'), findsOneWidget);
    });

    testWidgets('G020-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G020-normal'),
            QuantumFlexible(child: _panel('G020-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 021 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G021-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G021-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G021-deep', width: 88, height: 44),
              ),
            ),
            _panel('G021-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G021-deep'), findsOneWidget);
    });

    testWidgets('G021-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G021-alpha', width: 56, height: 40),
            _panel('G021-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G021-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G021-gamma'), findsOneWidget);
    });

    testWidgets('G021-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G021-one')),
            QuantumFlexible(child: _panel('G021-two')),
            _panel('G021-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G021-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G021-narrow-1', width: 90, height: 28),
            _panel('G021-narrow-2', width: 90, height: 28),
            _panel('G021-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G021-narrow-3'), findsOneWidget);
    });

    testWidgets('G021-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G021-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G021-loose'), findsOneWidget);
    });
  });

  group('Group 022 - column-scroll-fit @ 375x667', () {
    testWidgets('G022-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G022-top', width: 180, height: 42),
              _panel('G022-mid-a', width: 180, height: 42),
              _panel('G022-mid-b', width: 180, height: 42),
              _panel('G022-mid-c', width: 180, height: 42),
              _panel('G022-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G022-bottom'), findsOneWidget);
    });

    testWidgets('G022-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G022-one', width: 200, height: 48),
              _panel('G022-two', width: 200, height: 48),
              _panel('G022-three', width: 200, height: 48),
              _panel('G022-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G022-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G022-stretched-1', height: 36),
            _panel('G022-stretched-2', height: 36),
            _panel('G022-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G022-stretched-2'), findsOneWidget);
    });

    testWidgets('G022-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G022-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G022-inner-1'),
                _panel('G022-inner-2'),
              ],
            ),
            _panel('G022-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G022-inner-2'), findsOneWidget);
    });

    testWidgets('G022-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G022-a', height: 30),
            _panel('G022-b', height: 30),
            _panel('G022-c', height: 30),
            _panel('G022-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 023 - split-pane-horizontal @ 390x844', () {
    testWidgets('G023-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G023-left', width: 120, height: 180),
            _panel('G023-center', width: 120, height: 180),
            _panel('G023-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G023-center'), findsOneWidget);
    });

    testWidgets('G023-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G023-a', width: 96, height: 160),
            _panel('G023-b', width: 96, height: 160),
            _panel('G023-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G023-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G023-p1'),
            _panel('G023-p2'),
            _panel('G023-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G023-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G023-slot-1')),
            SizedBox.expand(child: _panel('G023-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G023-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G023-x'),
            _panel('G023-y'),
            _panel('G023-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G023-z'), findsOneWidget);
    });
  });

  group('Group 024 - split-pane-vertical @ 414x896', () {
    testWidgets('G024-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G024-top', width: 180, height: 60),
            _panel('G024-mid', width: 180, height: 60),
            _panel('G024-bottom', width: 180, height: 60),
            _panel('G024-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G024-tail'), findsOneWidget);
    });

    testWidgets('G024-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G024-a', width: 160, height: 50),
            _panel('G024-b', width: 160, height: 50),
            _panel('G024-c', width: 160, height: 50),
            _panel('G024-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G024-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G024-one'),
            _panel('G024-two'),
            _panel('G024-three'),
            _panel('G024-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G024-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G024-header'),
            _panel('G024-content'),
            _panel('G024-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G024-content'), findsOneWidget);
    });

    testWidgets('G024-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G024-inner-1'), _panel('G024-inner-2')]),
            _panel('G024-middle'),
            _rowHarness(children: [_panel('G024-row-1'), _panel('G024-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 025 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G025-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G025-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G025-ratio'), findsOneWidget);
    });

    testWidgets('G025-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G025-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G025-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G025-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G025-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G025-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G025-sq-3'), findsOneWidget);
    });

    testWidgets('G025-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G025-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G025-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G025-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G025-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 026 - morph-surface-handle @ 768x1024', () {
    testWidgets('G026-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G026-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G026-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G026-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G026-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G026-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G026-centered'), findsOneWidget);
    });

    testWidgets(
        'G026-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G026-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G026-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G026-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 027 - hydration-claim-path @ 820x1180', () {
    testWidgets('G027-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/27',
        'props': {'title': 'G027', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/27');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G027');
    });

    testWidgets('G027-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/27/once',
        'props': {'variant': 'once', 'index': 26},
      });
      expect(QLHydration.claimProps('/layout/27/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/27/once'), isNull);
    });

    testWidgets('G027-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/27/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/27/other'), isNull);
      expect(QLHydration.claimProps('/layout/27/match'), isNotNull);
    });

    testWidgets('G027-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/27/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G027',
        },
      });
      final claimed = QLHydration.claimProps('/layout/27/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G027-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G027-hydration-root'),
            _panel('G027-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 028 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G028-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G028-wrap-1', width: 58, height: 28),
                _panel('G028-wrap-2', width: 64, height: 28),
                _panel('G028-wrap-3', width: 72, height: 28),
                _panel('G028-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G028-wrap-4'), findsOneWidget);
    });

    testWidgets('G028-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G028-gap-1'),
            _panel('G028-gap-2'),
            _panel('G028-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G028-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G028-mix-1'),
                _panel('G028-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G028-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G028-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G028-compact-1', width: 100, height: 26),
                _panel('G028-compact-2', width: 100, height: 26),
                _panel('G028-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G028-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G028-recalc-1'),
            _panel('G028-recalc-2'),
            _panel('G028-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 029 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G029-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G029-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G029-stack-a', width: 88, height: 30),
                _panel('G029-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G029-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G029-stack-b'), findsOneWidget);
    });

    testWidgets('G029-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G029-row-inner-1'),
                _panel('G029-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G029-col-inner-1'),
                _panel('G029-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G029-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G029-outer-text'),
            _columnHarness(children: [
              _panel('G029-inner-text-a'),
              _panel('G029-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G029-inner-text-b'), findsOneWidget);
    });

    testWidgets('G029-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G029-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G029-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G029-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G029-pass-1'), _panel('G029-pass-2')]),
            _panel('G029-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 030 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G030-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G030-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G030-orphan'), findsOneWidget);
    });

    testWidgets('G030-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G030-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G030-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G030-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G030-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G030-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G030-discoverable'), findsOneWidget);
    });

    testWidgets('G030-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G030-normal'),
            QuantumFlexible(child: _panel('G030-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 031 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G031-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G031-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G031-deep', width: 88, height: 44),
              ),
            ),
            _panel('G031-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G031-deep'), findsOneWidget);
    });

    testWidgets('G031-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G031-alpha', width: 56, height: 40),
            _panel('G031-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G031-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G031-gamma'), findsOneWidget);
    });

    testWidgets('G031-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G031-one')),
            QuantumFlexible(child: _panel('G031-two')),
            _panel('G031-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G031-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G031-narrow-1', width: 90, height: 28),
            _panel('G031-narrow-2', width: 90, height: 28),
            _panel('G031-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G031-narrow-3'), findsOneWidget);
    });

    testWidgets('G031-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G031-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G031-loose'), findsOneWidget);
    });
  });

  group('Group 032 - column-scroll-fit @ 375x667', () {
    testWidgets('G032-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G032-top', width: 180, height: 42),
              _panel('G032-mid-a', width: 180, height: 42),
              _panel('G032-mid-b', width: 180, height: 42),
              _panel('G032-mid-c', width: 180, height: 42),
              _panel('G032-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G032-bottom'), findsOneWidget);
    });

    testWidgets('G032-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G032-one', width: 200, height: 48),
              _panel('G032-two', width: 200, height: 48),
              _panel('G032-three', width: 200, height: 48),
              _panel('G032-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G032-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G032-stretched-1', height: 36),
            _panel('G032-stretched-2', height: 36),
            _panel('G032-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G032-stretched-2'), findsOneWidget);
    });

    testWidgets('G032-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G032-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G032-inner-1'),
                _panel('G032-inner-2'),
              ],
            ),
            _panel('G032-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G032-inner-2'), findsOneWidget);
    });

    testWidgets('G032-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G032-a', height: 30),
            _panel('G032-b', height: 30),
            _panel('G032-c', height: 30),
            _panel('G032-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 033 - split-pane-horizontal @ 390x844', () {
    testWidgets('G033-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G033-left', width: 120, height: 180),
            _panel('G033-center', width: 120, height: 180),
            _panel('G033-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G033-center'), findsOneWidget);
    });

    testWidgets('G033-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G033-a', width: 96, height: 160),
            _panel('G033-b', width: 96, height: 160),
            _panel('G033-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G033-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G033-p1'),
            _panel('G033-p2'),
            _panel('G033-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G033-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G033-slot-1')),
            SizedBox.expand(child: _panel('G033-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G033-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G033-x'),
            _panel('G033-y'),
            _panel('G033-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G033-z'), findsOneWidget);
    });
  });

  group('Group 034 - split-pane-vertical @ 414x896', () {
    testWidgets('G034-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G034-top', width: 180, height: 60),
            _panel('G034-mid', width: 180, height: 60),
            _panel('G034-bottom', width: 180, height: 60),
            _panel('G034-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G034-tail'), findsOneWidget);
    });

    testWidgets('G034-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G034-a', width: 160, height: 50),
            _panel('G034-b', width: 160, height: 50),
            _panel('G034-c', width: 160, height: 50),
            _panel('G034-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G034-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G034-one'),
            _panel('G034-two'),
            _panel('G034-three'),
            _panel('G034-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G034-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G034-header'),
            _panel('G034-content'),
            _panel('G034-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G034-content'), findsOneWidget);
    });

    testWidgets('G034-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G034-inner-1'), _panel('G034-inner-2')]),
            _panel('G034-middle'),
            _rowHarness(children: [_panel('G034-row-1'), _panel('G034-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 035 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G035-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G035-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G035-ratio'), findsOneWidget);
    });

    testWidgets('G035-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G035-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G035-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G035-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G035-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G035-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G035-sq-3'), findsOneWidget);
    });

    testWidgets('G035-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G035-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G035-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G035-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G035-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 036 - morph-surface-handle @ 768x1024', () {
    testWidgets('G036-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G036-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G036-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G036-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G036-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G036-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G036-centered'), findsOneWidget);
    });

    testWidgets(
        'G036-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G036-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G036-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G036-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 037 - hydration-claim-path @ 820x1180', () {
    testWidgets('G037-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/37',
        'props': {'title': 'G037', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/37');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G037');
    });

    testWidgets('G037-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/37/once',
        'props': {'variant': 'once', 'index': 36},
      });
      expect(QLHydration.claimProps('/layout/37/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/37/once'), isNull);
    });

    testWidgets('G037-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/37/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/37/other'), isNull);
      expect(QLHydration.claimProps('/layout/37/match'), isNotNull);
    });

    testWidgets('G037-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/37/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G037',
        },
      });
      final claimed = QLHydration.claimProps('/layout/37/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G037-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G037-hydration-root'),
            _panel('G037-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 038 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G038-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G038-wrap-1', width: 58, height: 28),
                _panel('G038-wrap-2', width: 64, height: 28),
                _panel('G038-wrap-3', width: 72, height: 28),
                _panel('G038-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G038-wrap-4'), findsOneWidget);
    });

    testWidgets('G038-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G038-gap-1'),
            _panel('G038-gap-2'),
            _panel('G038-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G038-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G038-mix-1'),
                _panel('G038-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G038-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G038-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G038-compact-1', width: 100, height: 26),
                _panel('G038-compact-2', width: 100, height: 26),
                _panel('G038-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G038-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G038-recalc-1'),
            _panel('G038-recalc-2'),
            _panel('G038-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 039 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G039-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G039-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G039-stack-a', width: 88, height: 30),
                _panel('G039-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G039-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G039-stack-b'), findsOneWidget);
    });

    testWidgets('G039-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G039-row-inner-1'),
                _panel('G039-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G039-col-inner-1'),
                _panel('G039-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G039-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G039-outer-text'),
            _columnHarness(children: [
              _panel('G039-inner-text-a'),
              _panel('G039-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G039-inner-text-b'), findsOneWidget);
    });

    testWidgets('G039-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G039-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G039-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G039-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G039-pass-1'), _panel('G039-pass-2')]),
            _panel('G039-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 040 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G040-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G040-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G040-orphan'), findsOneWidget);
    });

    testWidgets('G040-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G040-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G040-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G040-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G040-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G040-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G040-discoverable'), findsOneWidget);
    });

    testWidgets('G040-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G040-normal'),
            QuantumFlexible(child: _panel('G040-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 041 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G041-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G041-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G041-deep', width: 88, height: 44),
              ),
            ),
            _panel('G041-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G041-deep'), findsOneWidget);
    });

    testWidgets('G041-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G041-alpha', width: 56, height: 40),
            _panel('G041-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G041-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G041-gamma'), findsOneWidget);
    });

    testWidgets('G041-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G041-one')),
            QuantumFlexible(child: _panel('G041-two')),
            _panel('G041-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G041-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G041-narrow-1', width: 90, height: 28),
            _panel('G041-narrow-2', width: 90, height: 28),
            _panel('G041-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G041-narrow-3'), findsOneWidget);
    });

    testWidgets('G041-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G041-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G041-loose'), findsOneWidget);
    });
  });

  group('Group 042 - column-scroll-fit @ 375x667', () {
    testWidgets('G042-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G042-top', width: 180, height: 42),
              _panel('G042-mid-a', width: 180, height: 42),
              _panel('G042-mid-b', width: 180, height: 42),
              _panel('G042-mid-c', width: 180, height: 42),
              _panel('G042-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G042-bottom'), findsOneWidget);
    });

    testWidgets('G042-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G042-one', width: 200, height: 48),
              _panel('G042-two', width: 200, height: 48),
              _panel('G042-three', width: 200, height: 48),
              _panel('G042-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G042-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G042-stretched-1', height: 36),
            _panel('G042-stretched-2', height: 36),
            _panel('G042-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G042-stretched-2'), findsOneWidget);
    });

    testWidgets('G042-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G042-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G042-inner-1'),
                _panel('G042-inner-2'),
              ],
            ),
            _panel('G042-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G042-inner-2'), findsOneWidget);
    });

    testWidgets('G042-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G042-a', height: 30),
            _panel('G042-b', height: 30),
            _panel('G042-c', height: 30),
            _panel('G042-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 043 - split-pane-horizontal @ 390x844', () {
    testWidgets('G043-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G043-left', width: 120, height: 180),
            _panel('G043-center', width: 120, height: 180),
            _panel('G043-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G043-center'), findsOneWidget);
    });

    testWidgets('G043-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G043-a', width: 96, height: 160),
            _panel('G043-b', width: 96, height: 160),
            _panel('G043-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G043-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G043-p1'),
            _panel('G043-p2'),
            _panel('G043-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G043-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G043-slot-1')),
            SizedBox.expand(child: _panel('G043-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G043-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G043-x'),
            _panel('G043-y'),
            _panel('G043-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G043-z'), findsOneWidget);
    });
  });

  group('Group 044 - split-pane-vertical @ 414x896', () {
    testWidgets('G044-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G044-top', width: 180, height: 60),
            _panel('G044-mid', width: 180, height: 60),
            _panel('G044-bottom', width: 180, height: 60),
            _panel('G044-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G044-tail'), findsOneWidget);
    });

    testWidgets('G044-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G044-a', width: 160, height: 50),
            _panel('G044-b', width: 160, height: 50),
            _panel('G044-c', width: 160, height: 50),
            _panel('G044-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G044-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G044-one'),
            _panel('G044-two'),
            _panel('G044-three'),
            _panel('G044-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G044-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G044-header'),
            _panel('G044-content'),
            _panel('G044-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G044-content'), findsOneWidget);
    });

    testWidgets('G044-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G044-inner-1'), _panel('G044-inner-2')]),
            _panel('G044-middle'),
            _rowHarness(children: [_panel('G044-row-1'), _panel('G044-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 045 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G045-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G045-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G045-ratio'), findsOneWidget);
    });

    testWidgets('G045-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G045-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G045-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G045-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G045-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G045-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G045-sq-3'), findsOneWidget);
    });

    testWidgets('G045-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G045-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G045-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G045-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G045-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 046 - morph-surface-handle @ 768x1024', () {
    testWidgets('G046-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G046-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G046-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G046-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G046-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G046-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G046-centered'), findsOneWidget);
    });

    testWidgets(
        'G046-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G046-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G046-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G046-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 047 - hydration-claim-path @ 820x1180', () {
    testWidgets('G047-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/47',
        'props': {'title': 'G047', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/47');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G047');
    });

    testWidgets('G047-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/47/once',
        'props': {'variant': 'once', 'index': 46},
      });
      expect(QLHydration.claimProps('/layout/47/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/47/once'), isNull);
    });

    testWidgets('G047-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/47/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/47/other'), isNull);
      expect(QLHydration.claimProps('/layout/47/match'), isNotNull);
    });

    testWidgets('G047-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/47/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G047',
        },
      });
      final claimed = QLHydration.claimProps('/layout/47/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G047-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G047-hydration-root'),
            _panel('G047-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 048 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G048-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G048-wrap-1', width: 58, height: 28),
                _panel('G048-wrap-2', width: 64, height: 28),
                _panel('G048-wrap-3', width: 72, height: 28),
                _panel('G048-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G048-wrap-4'), findsOneWidget);
    });

    testWidgets('G048-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G048-gap-1'),
            _panel('G048-gap-2'),
            _panel('G048-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G048-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G048-mix-1'),
                _panel('G048-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G048-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G048-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G048-compact-1', width: 100, height: 26),
                _panel('G048-compact-2', width: 100, height: 26),
                _panel('G048-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G048-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G048-recalc-1'),
            _panel('G048-recalc-2'),
            _panel('G048-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 049 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G049-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G049-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G049-stack-a', width: 88, height: 30),
                _panel('G049-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G049-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G049-stack-b'), findsOneWidget);
    });

    testWidgets('G049-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G049-row-inner-1'),
                _panel('G049-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G049-col-inner-1'),
                _panel('G049-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G049-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G049-outer-text'),
            _columnHarness(children: [
              _panel('G049-inner-text-a'),
              _panel('G049-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G049-inner-text-b'), findsOneWidget);
    });

    testWidgets('G049-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G049-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G049-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G049-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G049-pass-1'), _panel('G049-pass-2')]),
            _panel('G049-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 050 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G050-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G050-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G050-orphan'), findsOneWidget);
    });

    testWidgets('G050-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G050-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G050-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G050-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G050-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G050-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G050-discoverable'), findsOneWidget);
    });

    testWidgets('G050-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G050-normal'),
            QuantumFlexible(child: _panel('G050-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 051 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G051-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G051-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G051-deep', width: 88, height: 44),
              ),
            ),
            _panel('G051-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G051-deep'), findsOneWidget);
    });

    testWidgets('G051-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G051-alpha', width: 56, height: 40),
            _panel('G051-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G051-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G051-gamma'), findsOneWidget);
    });

    testWidgets('G051-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G051-one')),
            QuantumFlexible(child: _panel('G051-two')),
            _panel('G051-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G051-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G051-narrow-1', width: 90, height: 28),
            _panel('G051-narrow-2', width: 90, height: 28),
            _panel('G051-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G051-narrow-3'), findsOneWidget);
    });

    testWidgets('G051-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G051-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G051-loose'), findsOneWidget);
    });
  });

  group('Group 052 - column-scroll-fit @ 375x667', () {
    testWidgets('G052-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G052-top', width: 180, height: 42),
              _panel('G052-mid-a', width: 180, height: 42),
              _panel('G052-mid-b', width: 180, height: 42),
              _panel('G052-mid-c', width: 180, height: 42),
              _panel('G052-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G052-bottom'), findsOneWidget);
    });

    testWidgets('G052-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G052-one', width: 200, height: 48),
              _panel('G052-two', width: 200, height: 48),
              _panel('G052-three', width: 200, height: 48),
              _panel('G052-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G052-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G052-stretched-1', height: 36),
            _panel('G052-stretched-2', height: 36),
            _panel('G052-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G052-stretched-2'), findsOneWidget);
    });

    testWidgets('G052-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G052-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G052-inner-1'),
                _panel('G052-inner-2'),
              ],
            ),
            _panel('G052-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G052-inner-2'), findsOneWidget);
    });

    testWidgets('G052-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G052-a', height: 30),
            _panel('G052-b', height: 30),
            _panel('G052-c', height: 30),
            _panel('G052-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 053 - split-pane-horizontal @ 390x844', () {
    testWidgets('G053-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G053-left', width: 120, height: 180),
            _panel('G053-center', width: 120, height: 180),
            _panel('G053-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G053-center'), findsOneWidget);
    });

    testWidgets('G053-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G053-a', width: 96, height: 160),
            _panel('G053-b', width: 96, height: 160),
            _panel('G053-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G053-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G053-p1'),
            _panel('G053-p2'),
            _panel('G053-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G053-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G053-slot-1')),
            SizedBox.expand(child: _panel('G053-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G053-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G053-x'),
            _panel('G053-y'),
            _panel('G053-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G053-z'), findsOneWidget);
    });
  });

  group('Group 054 - split-pane-vertical @ 414x896', () {
    testWidgets('G054-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G054-top', width: 180, height: 60),
            _panel('G054-mid', width: 180, height: 60),
            _panel('G054-bottom', width: 180, height: 60),
            _panel('G054-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G054-tail'), findsOneWidget);
    });

    testWidgets('G054-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G054-a', width: 160, height: 50),
            _panel('G054-b', width: 160, height: 50),
            _panel('G054-c', width: 160, height: 50),
            _panel('G054-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G054-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G054-one'),
            _panel('G054-two'),
            _panel('G054-three'),
            _panel('G054-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G054-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G054-header'),
            _panel('G054-content'),
            _panel('G054-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G054-content'), findsOneWidget);
    });

    testWidgets('G054-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G054-inner-1'), _panel('G054-inner-2')]),
            _panel('G054-middle'),
            _rowHarness(children: [_panel('G054-row-1'), _panel('G054-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 055 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G055-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G055-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G055-ratio'), findsOneWidget);
    });

    testWidgets('G055-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G055-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G055-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G055-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G055-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G055-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G055-sq-3'), findsOneWidget);
    });

    testWidgets('G055-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G055-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G055-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G055-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G055-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 056 - morph-surface-handle @ 768x1024', () {
    testWidgets('G056-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G056-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G056-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G056-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G056-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G056-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G056-centered'), findsOneWidget);
    });

    testWidgets(
        'G056-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G056-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G056-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G056-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 057 - hydration-claim-path @ 820x1180', () {
    testWidgets('G057-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/57',
        'props': {'title': 'G057', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/57');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G057');
    });

    testWidgets('G057-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/57/once',
        'props': {'variant': 'once', 'index': 56},
      });
      expect(QLHydration.claimProps('/layout/57/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/57/once'), isNull);
    });

    testWidgets('G057-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/57/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/57/other'), isNull);
      expect(QLHydration.claimProps('/layout/57/match'), isNotNull);
    });

    testWidgets('G057-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/57/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G057',
        },
      });
      final claimed = QLHydration.claimProps('/layout/57/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G057-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G057-hydration-root'),
            _panel('G057-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 058 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G058-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G058-wrap-1', width: 58, height: 28),
                _panel('G058-wrap-2', width: 64, height: 28),
                _panel('G058-wrap-3', width: 72, height: 28),
                _panel('G058-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G058-wrap-4'), findsOneWidget);
    });

    testWidgets('G058-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G058-gap-1'),
            _panel('G058-gap-2'),
            _panel('G058-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G058-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G058-mix-1'),
                _panel('G058-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G058-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G058-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G058-compact-1', width: 100, height: 26),
                _panel('G058-compact-2', width: 100, height: 26),
                _panel('G058-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G058-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G058-recalc-1'),
            _panel('G058-recalc-2'),
            _panel('G058-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 059 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G059-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G059-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G059-stack-a', width: 88, height: 30),
                _panel('G059-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G059-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G059-stack-b'), findsOneWidget);
    });

    testWidgets('G059-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G059-row-inner-1'),
                _panel('G059-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G059-col-inner-1'),
                _panel('G059-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G059-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G059-outer-text'),
            _columnHarness(children: [
              _panel('G059-inner-text-a'),
              _panel('G059-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G059-inner-text-b'), findsOneWidget);
    });

    testWidgets('G059-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G059-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G059-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G059-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G059-pass-1'), _panel('G059-pass-2')]),
            _panel('G059-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 060 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G060-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G060-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G060-orphan'), findsOneWidget);
    });

    testWidgets('G060-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G060-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G060-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G060-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G060-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G060-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G060-discoverable'), findsOneWidget);
    });

    testWidgets('G060-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G060-normal'),
            QuantumFlexible(child: _panel('G060-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 061 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G061-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G061-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G061-deep', width: 88, height: 44),
              ),
            ),
            _panel('G061-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G061-deep'), findsOneWidget);
    });

    testWidgets('G061-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G061-alpha', width: 56, height: 40),
            _panel('G061-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G061-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G061-gamma'), findsOneWidget);
    });

    testWidgets('G061-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G061-one')),
            QuantumFlexible(child: _panel('G061-two')),
            _panel('G061-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G061-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G061-narrow-1', width: 90, height: 28),
            _panel('G061-narrow-2', width: 90, height: 28),
            _panel('G061-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G061-narrow-3'), findsOneWidget);
    });

    testWidgets('G061-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G061-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G061-loose'), findsOneWidget);
    });
  });

  group('Group 062 - column-scroll-fit @ 375x667', () {
    testWidgets('G062-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G062-top', width: 180, height: 42),
              _panel('G062-mid-a', width: 180, height: 42),
              _panel('G062-mid-b', width: 180, height: 42),
              _panel('G062-mid-c', width: 180, height: 42),
              _panel('G062-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G062-bottom'), findsOneWidget);
    });

    testWidgets('G062-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G062-one', width: 200, height: 48),
              _panel('G062-two', width: 200, height: 48),
              _panel('G062-three', width: 200, height: 48),
              _panel('G062-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G062-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G062-stretched-1', height: 36),
            _panel('G062-stretched-2', height: 36),
            _panel('G062-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G062-stretched-2'), findsOneWidget);
    });

    testWidgets('G062-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G062-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G062-inner-1'),
                _panel('G062-inner-2'),
              ],
            ),
            _panel('G062-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G062-inner-2'), findsOneWidget);
    });

    testWidgets('G062-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G062-a', height: 30),
            _panel('G062-b', height: 30),
            _panel('G062-c', height: 30),
            _panel('G062-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 063 - split-pane-horizontal @ 390x844', () {
    testWidgets('G063-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G063-left', width: 120, height: 180),
            _panel('G063-center', width: 120, height: 180),
            _panel('G063-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G063-center'), findsOneWidget);
    });

    testWidgets('G063-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G063-a', width: 96, height: 160),
            _panel('G063-b', width: 96, height: 160),
            _panel('G063-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G063-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G063-p1'),
            _panel('G063-p2'),
            _panel('G063-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G063-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G063-slot-1')),
            SizedBox.expand(child: _panel('G063-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G063-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G063-x'),
            _panel('G063-y'),
            _panel('G063-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G063-z'), findsOneWidget);
    });
  });

  group('Group 064 - split-pane-vertical @ 414x896', () {
    testWidgets('G064-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G064-top', width: 180, height: 60),
            _panel('G064-mid', width: 180, height: 60),
            _panel('G064-bottom', width: 180, height: 60),
            _panel('G064-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G064-tail'), findsOneWidget);
    });

    testWidgets('G064-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G064-a', width: 160, height: 50),
            _panel('G064-b', width: 160, height: 50),
            _panel('G064-c', width: 160, height: 50),
            _panel('G064-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G064-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G064-one'),
            _panel('G064-two'),
            _panel('G064-three'),
            _panel('G064-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G064-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G064-header'),
            _panel('G064-content'),
            _panel('G064-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G064-content'), findsOneWidget);
    });

    testWidgets('G064-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G064-inner-1'), _panel('G064-inner-2')]),
            _panel('G064-middle'),
            _rowHarness(children: [_panel('G064-row-1'), _panel('G064-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 065 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G065-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G065-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G065-ratio'), findsOneWidget);
    });

    testWidgets('G065-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G065-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G065-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G065-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G065-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G065-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G065-sq-3'), findsOneWidget);
    });

    testWidgets('G065-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G065-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G065-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G065-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G065-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 066 - morph-surface-handle @ 768x1024', () {
    testWidgets('G066-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G066-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G066-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G066-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G066-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G066-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G066-centered'), findsOneWidget);
    });

    testWidgets(
        'G066-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G066-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G066-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G066-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 067 - hydration-claim-path @ 820x1180', () {
    testWidgets('G067-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/67',
        'props': {'title': 'G067', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/67');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G067');
    });

    testWidgets('G067-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/67/once',
        'props': {'variant': 'once', 'index': 66},
      });
      expect(QLHydration.claimProps('/layout/67/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/67/once'), isNull);
    });

    testWidgets('G067-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/67/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/67/other'), isNull);
      expect(QLHydration.claimProps('/layout/67/match'), isNotNull);
    });

    testWidgets('G067-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/67/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G067',
        },
      });
      final claimed = QLHydration.claimProps('/layout/67/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G067-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G067-hydration-root'),
            _panel('G067-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 068 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G068-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G068-wrap-1', width: 58, height: 28),
                _panel('G068-wrap-2', width: 64, height: 28),
                _panel('G068-wrap-3', width: 72, height: 28),
                _panel('G068-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G068-wrap-4'), findsOneWidget);
    });

    testWidgets('G068-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G068-gap-1'),
            _panel('G068-gap-2'),
            _panel('G068-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G068-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G068-mix-1'),
                _panel('G068-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G068-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G068-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G068-compact-1', width: 100, height: 26),
                _panel('G068-compact-2', width: 100, height: 26),
                _panel('G068-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G068-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G068-recalc-1'),
            _panel('G068-recalc-2'),
            _panel('G068-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 069 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G069-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G069-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G069-stack-a', width: 88, height: 30),
                _panel('G069-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G069-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G069-stack-b'), findsOneWidget);
    });

    testWidgets('G069-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G069-row-inner-1'),
                _panel('G069-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G069-col-inner-1'),
                _panel('G069-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G069-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G069-outer-text'),
            _columnHarness(children: [
              _panel('G069-inner-text-a'),
              _panel('G069-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G069-inner-text-b'), findsOneWidget);
    });

    testWidgets('G069-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G069-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G069-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G069-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G069-pass-1'), _panel('G069-pass-2')]),
            _panel('G069-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 070 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G070-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G070-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G070-orphan'), findsOneWidget);
    });

    testWidgets('G070-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G070-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G070-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G070-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G070-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G070-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G070-discoverable'), findsOneWidget);
    });

    testWidgets('G070-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G070-normal'),
            QuantumFlexible(child: _panel('G070-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 071 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G071-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G071-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G071-deep', width: 88, height: 44),
              ),
            ),
            _panel('G071-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G071-deep'), findsOneWidget);
    });

    testWidgets('G071-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G071-alpha', width: 56, height: 40),
            _panel('G071-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G071-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G071-gamma'), findsOneWidget);
    });

    testWidgets('G071-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G071-one')),
            QuantumFlexible(child: _panel('G071-two')),
            _panel('G071-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G071-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G071-narrow-1', width: 90, height: 28),
            _panel('G071-narrow-2', width: 90, height: 28),
            _panel('G071-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G071-narrow-3'), findsOneWidget);
    });

    testWidgets('G071-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G071-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G071-loose'), findsOneWidget);
    });
  });

  group('Group 072 - column-scroll-fit @ 375x667', () {
    testWidgets('G072-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G072-top', width: 180, height: 42),
              _panel('G072-mid-a', width: 180, height: 42),
              _panel('G072-mid-b', width: 180, height: 42),
              _panel('G072-mid-c', width: 180, height: 42),
              _panel('G072-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G072-bottom'), findsOneWidget);
    });

    testWidgets('G072-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G072-one', width: 200, height: 48),
              _panel('G072-two', width: 200, height: 48),
              _panel('G072-three', width: 200, height: 48),
              _panel('G072-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G072-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G072-stretched-1', height: 36),
            _panel('G072-stretched-2', height: 36),
            _panel('G072-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G072-stretched-2'), findsOneWidget);
    });

    testWidgets('G072-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G072-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G072-inner-1'),
                _panel('G072-inner-2'),
              ],
            ),
            _panel('G072-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G072-inner-2'), findsOneWidget);
    });

    testWidgets('G072-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G072-a', height: 30),
            _panel('G072-b', height: 30),
            _panel('G072-c', height: 30),
            _panel('G072-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 073 - split-pane-horizontal @ 390x844', () {
    testWidgets('G073-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G073-left', width: 120, height: 180),
            _panel('G073-center', width: 120, height: 180),
            _panel('G073-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G073-center'), findsOneWidget);
    });

    testWidgets('G073-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G073-a', width: 96, height: 160),
            _panel('G073-b', width: 96, height: 160),
            _panel('G073-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G073-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G073-p1'),
            _panel('G073-p2'),
            _panel('G073-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G073-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G073-slot-1')),
            SizedBox.expand(child: _panel('G073-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G073-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G073-x'),
            _panel('G073-y'),
            _panel('G073-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G073-z'), findsOneWidget);
    });
  });

  group('Group 074 - split-pane-vertical @ 414x896', () {
    testWidgets('G074-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G074-top', width: 180, height: 60),
            _panel('G074-mid', width: 180, height: 60),
            _panel('G074-bottom', width: 180, height: 60),
            _panel('G074-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G074-tail'), findsOneWidget);
    });

    testWidgets('G074-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G074-a', width: 160, height: 50),
            _panel('G074-b', width: 160, height: 50),
            _panel('G074-c', width: 160, height: 50),
            _panel('G074-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G074-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G074-one'),
            _panel('G074-two'),
            _panel('G074-three'),
            _panel('G074-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G074-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G074-header'),
            _panel('G074-content'),
            _panel('G074-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G074-content'), findsOneWidget);
    });

    testWidgets('G074-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G074-inner-1'), _panel('G074-inner-2')]),
            _panel('G074-middle'),
            _rowHarness(children: [_panel('G074-row-1'), _panel('G074-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 075 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G075-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G075-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G075-ratio'), findsOneWidget);
    });

    testWidgets('G075-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G075-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G075-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G075-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G075-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G075-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G075-sq-3'), findsOneWidget);
    });

    testWidgets('G075-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G075-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G075-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G075-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G075-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 076 - morph-surface-handle @ 768x1024', () {
    testWidgets('G076-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G076-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G076-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G076-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G076-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G076-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G076-centered'), findsOneWidget);
    });

    testWidgets(
        'G076-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G076-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G076-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G076-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 077 - hydration-claim-path @ 820x1180', () {
    testWidgets('G077-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/77',
        'props': {'title': 'G077', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/77');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G077');
    });

    testWidgets('G077-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/77/once',
        'props': {'variant': 'once', 'index': 76},
      });
      expect(QLHydration.claimProps('/layout/77/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/77/once'), isNull);
    });

    testWidgets('G077-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/77/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/77/other'), isNull);
      expect(QLHydration.claimProps('/layout/77/match'), isNotNull);
    });

    testWidgets('G077-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/77/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G077',
        },
      });
      final claimed = QLHydration.claimProps('/layout/77/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G077-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G077-hydration-root'),
            _panel('G077-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 078 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G078-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G078-wrap-1', width: 58, height: 28),
                _panel('G078-wrap-2', width: 64, height: 28),
                _panel('G078-wrap-3', width: 72, height: 28),
                _panel('G078-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G078-wrap-4'), findsOneWidget);
    });

    testWidgets('G078-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G078-gap-1'),
            _panel('G078-gap-2'),
            _panel('G078-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G078-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G078-mix-1'),
                _panel('G078-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G078-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G078-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G078-compact-1', width: 100, height: 26),
                _panel('G078-compact-2', width: 100, height: 26),
                _panel('G078-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G078-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G078-recalc-1'),
            _panel('G078-recalc-2'),
            _panel('G078-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 079 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G079-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G079-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G079-stack-a', width: 88, height: 30),
                _panel('G079-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G079-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G079-stack-b'), findsOneWidget);
    });

    testWidgets('G079-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G079-row-inner-1'),
                _panel('G079-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G079-col-inner-1'),
                _panel('G079-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G079-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G079-outer-text'),
            _columnHarness(children: [
              _panel('G079-inner-text-a'),
              _panel('G079-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G079-inner-text-b'), findsOneWidget);
    });

    testWidgets('G079-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G079-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G079-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G079-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G079-pass-1'), _panel('G079-pass-2')]),
            _panel('G079-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 080 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G080-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G080-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G080-orphan'), findsOneWidget);
    });

    testWidgets('G080-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G080-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G080-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G080-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G080-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G080-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G080-discoverable'), findsOneWidget);
    });

    testWidgets('G080-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G080-normal'),
            QuantumFlexible(child: _panel('G080-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 081 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G081-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G081-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G081-deep', width: 88, height: 44),
              ),
            ),
            _panel('G081-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G081-deep'), findsOneWidget);
    });

    testWidgets('G081-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G081-alpha', width: 56, height: 40),
            _panel('G081-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G081-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G081-gamma'), findsOneWidget);
    });

    testWidgets('G081-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G081-one')),
            QuantumFlexible(child: _panel('G081-two')),
            _panel('G081-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G081-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G081-narrow-1', width: 90, height: 28),
            _panel('G081-narrow-2', width: 90, height: 28),
            _panel('G081-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G081-narrow-3'), findsOneWidget);
    });

    testWidgets('G081-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G081-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G081-loose'), findsOneWidget);
    });
  });

  group('Group 082 - column-scroll-fit @ 375x667', () {
    testWidgets('G082-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G082-top', width: 180, height: 42),
              _panel('G082-mid-a', width: 180, height: 42),
              _panel('G082-mid-b', width: 180, height: 42),
              _panel('G082-mid-c', width: 180, height: 42),
              _panel('G082-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G082-bottom'), findsOneWidget);
    });

    testWidgets('G082-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G082-one', width: 200, height: 48),
              _panel('G082-two', width: 200, height: 48),
              _panel('G082-three', width: 200, height: 48),
              _panel('G082-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G082-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G082-stretched-1', height: 36),
            _panel('G082-stretched-2', height: 36),
            _panel('G082-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G082-stretched-2'), findsOneWidget);
    });

    testWidgets('G082-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G082-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G082-inner-1'),
                _panel('G082-inner-2'),
              ],
            ),
            _panel('G082-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G082-inner-2'), findsOneWidget);
    });

    testWidgets('G082-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G082-a', height: 30),
            _panel('G082-b', height: 30),
            _panel('G082-c', height: 30),
            _panel('G082-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 083 - split-pane-horizontal @ 390x844', () {
    testWidgets('G083-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G083-left', width: 120, height: 180),
            _panel('G083-center', width: 120, height: 180),
            _panel('G083-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G083-center'), findsOneWidget);
    });

    testWidgets('G083-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G083-a', width: 96, height: 160),
            _panel('G083-b', width: 96, height: 160),
            _panel('G083-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G083-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G083-p1'),
            _panel('G083-p2'),
            _panel('G083-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G083-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G083-slot-1')),
            SizedBox.expand(child: _panel('G083-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G083-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G083-x'),
            _panel('G083-y'),
            _panel('G083-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G083-z'), findsOneWidget);
    });
  });

  group('Group 084 - split-pane-vertical @ 414x896', () {
    testWidgets('G084-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G084-top', width: 180, height: 60),
            _panel('G084-mid', width: 180, height: 60),
            _panel('G084-bottom', width: 180, height: 60),
            _panel('G084-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G084-tail'), findsOneWidget);
    });

    testWidgets('G084-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G084-a', width: 160, height: 50),
            _panel('G084-b', width: 160, height: 50),
            _panel('G084-c', width: 160, height: 50),
            _panel('G084-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G084-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G084-one'),
            _panel('G084-two'),
            _panel('G084-three'),
            _panel('G084-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G084-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G084-header'),
            _panel('G084-content'),
            _panel('G084-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G084-content'), findsOneWidget);
    });

    testWidgets('G084-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G084-inner-1'), _panel('G084-inner-2')]),
            _panel('G084-middle'),
            _rowHarness(children: [_panel('G084-row-1'), _panel('G084-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 085 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G085-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G085-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G085-ratio'), findsOneWidget);
    });

    testWidgets('G085-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G085-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G085-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G085-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G085-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G085-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G085-sq-3'), findsOneWidget);
    });

    testWidgets('G085-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G085-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G085-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G085-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G085-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 086 - morph-surface-handle @ 768x1024', () {
    testWidgets('G086-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G086-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G086-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G086-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G086-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G086-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G086-centered'), findsOneWidget);
    });

    testWidgets(
        'G086-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G086-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G086-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G086-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 087 - hydration-claim-path @ 820x1180', () {
    testWidgets('G087-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/87',
        'props': {'title': 'G087', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/87');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G087');
    });

    testWidgets('G087-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/87/once',
        'props': {'variant': 'once', 'index': 86},
      });
      expect(QLHydration.claimProps('/layout/87/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/87/once'), isNull);
    });

    testWidgets('G087-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/87/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/87/other'), isNull);
      expect(QLHydration.claimProps('/layout/87/match'), isNotNull);
    });

    testWidgets('G087-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/87/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G087',
        },
      });
      final claimed = QLHydration.claimProps('/layout/87/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G087-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G087-hydration-root'),
            _panel('G087-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 088 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G088-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G088-wrap-1', width: 58, height: 28),
                _panel('G088-wrap-2', width: 64, height: 28),
                _panel('G088-wrap-3', width: 72, height: 28),
                _panel('G088-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G088-wrap-4'), findsOneWidget);
    });

    testWidgets('G088-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G088-gap-1'),
            _panel('G088-gap-2'),
            _panel('G088-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G088-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G088-mix-1'),
                _panel('G088-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G088-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G088-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G088-compact-1', width: 100, height: 26),
                _panel('G088-compact-2', width: 100, height: 26),
                _panel('G088-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G088-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G088-recalc-1'),
            _panel('G088-recalc-2'),
            _panel('G088-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 089 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G089-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G089-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G089-stack-a', width: 88, height: 30),
                _panel('G089-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G089-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G089-stack-b'), findsOneWidget);
    });

    testWidgets('G089-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G089-row-inner-1'),
                _panel('G089-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G089-col-inner-1'),
                _panel('G089-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G089-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G089-outer-text'),
            _columnHarness(children: [
              _panel('G089-inner-text-a'),
              _panel('G089-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G089-inner-text-b'), findsOneWidget);
    });

    testWidgets('G089-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G089-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G089-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G089-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G089-pass-1'), _panel('G089-pass-2')]),
            _panel('G089-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 090 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G090-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G090-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G090-orphan'), findsOneWidget);
    });

    testWidgets('G090-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G090-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G090-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G090-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G090-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G090-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G090-discoverable'), findsOneWidget);
    });

    testWidgets('G090-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G090-normal'),
            QuantumFlexible(child: _panel('G090-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 091 - row-flex-flatten @ 320x240', () {
    testWidgets(
        'G091-A renders a nested flexible row without parent-data exceptions',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 8,
          children: [
            _panel('G091-left', width: 72, height: 44),
            QuantumFlexible(
              child: QuantumFlexible(
                child: _panel('G091-deep', width: 88, height: 44),
              ),
            ),
            _panel('G091-right', width: 72, height: 44),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G091-deep'), findsOneWidget);
    });

    testWidgets('G091-B stays stable in a wider viewport', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 12,
          children: [
            _panel('G091-alpha', width: 56, height: 40),
            _panel('G091-beta', width: 80, height: 40),
            QuantumFlexible(
                child: _panel('G091-gamma', width: 120, height: 40)),
          ],
        ),
        size: const Size(520.0, 320.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G091-gamma'), findsOneWidget);
    });

    testWidgets('G091-C keeps a flex wrapper visible only once',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(child: _panel('G091-one')),
            QuantumFlexible(child: _panel('G091-two')),
            _panel('G091-three'),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumFlex), findsOneWidget);
    });

    testWidgets('G091-D handles compressed width without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 4,
          children: [
            _panel('G091-narrow-1', width: 90, height: 28),
            _panel('G091-narrow-2', width: 90, height: 28),
            _panel('G091-narrow-3', width: 90, height: 28),
          ],
        ),
        size: const Size(280, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G091-narrow-3'), findsOneWidget);
    });

    testWidgets('G091-E remains usable with loose fit nesting', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(
              fit: FlexFit.loose,
              child: QuantumFlexible(
                fit: FlexFit.loose,
                child: _panel('G091-loose', width: 110, height: 32),
              ),
            ),
          ],
        ),
        size: const Size(320.0, 240.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G091-loose'), findsOneWidget);
    });
  });

  group('Group 092 - column-scroll-fit @ 375x667', () {
    testWidgets('G092-A builds a tall scrollable column cleanly',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            gap: 10,
            children: [
              _panel('G092-top', width: 180, height: 42),
              _panel('G092-mid-a', width: 180, height: 42),
              _panel('G092-mid-b', width: 180, height: 42),
              _panel('G092-mid-c', width: 180, height: 42),
              _panel('G092-bottom', width: 180, height: 42),
            ],
          ),
        ),
        size: const Size(375.0, 667.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G092-bottom'), findsOneWidget);
    });

    testWidgets('G092-B keeps the scroll shell bounded on a shorter screen',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              _panel('G092-one', width: 200, height: 48),
              _panel('G092-two', width: 200, height: 48),
              _panel('G092-three', width: 200, height: 48),
              _panel('G092-four', width: 200, height: 48),
            ],
          ),
        ),
        size: const Size(360, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumScrollScope), findsOneWidget);
    });

    testWidgets('G092-C preserves all labels through vertical stacking',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panel('G092-stretched-1', height: 36),
            _panel('G092-stretched-2', height: 36),
            _panel('G092-stretched-3', height: 36),
          ],
        ),
        size: const Size(420, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G092-stretched-2'), findsOneWidget);
    });

    testWidgets('G092-D tolerates nested column content at the same axis',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G092-outer'),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G092-inner-1'),
                _panel('G092-inner-2'),
              ],
            ),
            _panel('G092-tail'),
          ],
        ),
        size: const Size(480, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G092-inner-2'), findsOneWidget);
    });

    testWidgets('G092-E stays calm with minimal height and wide width',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G092-a', height: 30),
            _panel('G092-b', height: 30),
            _panel('G092-c', height: 30),
            _panel('G092-d', height: 30),
          ],
        ),
        size: const Size(800, 200),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 093 - split-pane-horizontal @ 390x844', () {
    testWidgets('G093-A renders a horizontal split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G093-left', width: 120, height: 180),
            _panel('G093-center', width: 120, height: 180),
            _panel('G093-right', width: 120, height: 180),
          ],
        ),
        size: const Size(390.0, 844.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G093-center'), findsOneWidget);
    });

    testWidgets('G093-B survives a narrow horizontal canvas', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G093-a', width: 96, height: 160),
            _panel('G093-b', width: 96, height: 160),
            _panel('G093-c', width: 96, height: 160),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(QuantumSplitPane), findsOneWidget);
    });

    testWidgets('G093-C keeps divider affordances mounted', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          dividerThickness: 8,
          children: [
            _panel('G093-p1'),
            _panel('G093-p2'),
            _panel('G093-p3'),
          ],
        ),
        size: const Size(640, 360),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G093-D accepts stretched children at each slot',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            SizedBox.expand(child: _panel('G093-slot-1')),
            SizedBox.expand(child: _panel('G093-slot-2')),
          ],
        ),
        size: const Size(720, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G093-E leaves all panes discoverable after a settle pass',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.horizontal,
          children: [
            _panel('G093-x'),
            _panel('G093-y'),
            _panel('G093-z'),
          ],
        ),
        size: const Size(900, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G093-z'), findsOneWidget);
    });
  });

  group('Group 094 - split-pane-vertical @ 414x896', () {
    testWidgets('G094-A renders a vertical split pane', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G094-top', width: 180, height: 60),
            _panel('G094-mid', width: 180, height: 60),
            _panel('G094-bottom', width: 180, height: 60),
            _panel('G094-tail', width: 180, height: 60),
          ],
        ),
        size: const Size(414.0, 896.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G094-tail'), findsOneWidget);
    });

    testWidgets('G094-B stays usable when the height is tight', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G094-a', width: 160, height: 50),
            _panel('G094-b', width: 160, height: 50),
            _panel('G094-c', width: 160, height: 50),
            _panel('G094-d', width: 160, height: 50),
          ],
        ),
        size: const Size(360, 240),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G094-C exposes all four vertical panes', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          dividerThickness: 10,
          children: [
            _panel('G094-one'),
            _panel('G094-two'),
            _panel('G094-three'),
            _panel('G094-four'),
          ],
        ),
        size: const Size(540, 480),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('G094-D remains readable on a tall viewport', (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _panel('G094-header'),
            _panel('G094-content'),
            _panel('G094-footer'),
          ],
        ),
        size: const Size(480, 900),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G094-content'), findsOneWidget);
    });

    testWidgets('G094-E tolerates nested split content within the panes',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumSplitPane(
          direction: Axis.vertical,
          children: [
            _columnHarness(
                children: [_panel('G094-inner-1'), _panel('G094-inner-2')]),
            _panel('G094-middle'),
            _rowHarness(children: [_panel('G094-row-1'), _panel('G094-row-2')]),
          ],
        ),
        size: const Size(760, 540),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 095 - aspect-ratio-tight-box @ 600x400', () {
    testWidgets('G095-A keeps an aspect-ratio box stable', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 280,
          height: 180,
          child: QuantumAspectRatio(
            ratio: 16 / 9,
            child: _panel('G095-ratio', width: 280, height: 180),
          ),
        ),
        size: const Size(600.0, 400.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G095-ratio'), findsOneWidget);
    });

    testWidgets('G095-B remains safe inside a small constrained box',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: SizedBox(
            width: 160,
            height: 120,
            child: QuantumAspectRatio(
              ratio: 4 / 3,
              child: _panel('G095-small', width: 160, height: 120),
            ),
          ),
        ),
        size: const Size(320, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G095-C works when placed next to other ratio boxes',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 6,
          children: [
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1, child: _panel('G095-sq-1'))),
            SizedBox(
                width: 120,
                height: 120,
                child:
                    QuantumAspectRatio(ratio: 1.5, child: _panel('G095-sq-2'))),
            SizedBox(
                width: 120,
                height: 120,
                child: QuantumAspectRatio(
                    ratio: 0.75, child: _panel('G095-sq-3'))),
          ],
        ),
        size: const Size(720, 280),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G095-sq-3'), findsOneWidget);
    });

    testWidgets('G095-D stays bounded in a scroll-aware column',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumScrollScope(
          axis: Axis.vertical,
          child: _columnHarness(
            children: [
              SizedBox(
                  height: 150,
                  child:
                      QuantumAspectRatio(ratio: 2, child: _panel('G095-top'))),
              SizedBox(
                  height: 150,
                  child: QuantumAspectRatio(
                      ratio: 1.2, child: _panel('G095-mid'))),
            ],
          ),
        ),
        size: const Size(540, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G095-E still renders after a second pump', (tester) async {
      await _pumpSurface(
        tester,
        SizedBox(
          width: 220,
          height: 220,
          child: QuantumAspectRatio(ratio: 1.25, child: _panel('G095-repeat')),
        ),
        size: const Size(640, 640),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 096 - morph-surface-handle @ 768x1024', () {
    testWidgets('G096-A mounts the morph surface and drag handle',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(180, 140),
          lockAspectRatio: false,
          snapGrid: 8,
          child: _panel('G096-surface', width: 180, height: 140),
        ),
        size: const Size(768.0, 1024.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    });

    testWidgets('G096-B remains stable with locked aspect resizing',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(200, 150),
          lockAspectRatio: true,
          snapGrid: 4,
          child: _panel('G096-locked', width: 200, height: 150),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'G096-C shows the child content centered inside the resizable surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(220, 180),
          lockAspectRatio: false,
          snapGrid: 0,
          child: _panel('G096-centered', width: 220, height: 180),
        ),
        size: const Size(700, 500),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G096-centered'), findsOneWidget);
    });

    testWidgets(
        'G096-D keeps the resize affordance visible after a second frame',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(160, 160),
          lockAspectRatio: false,
          snapGrid: 2,
          child: _panel('G096-second-frame'),
        ),
        size: const Size(360, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('G096-E tolerates a child that already fills the surface',
        (tester) async {
      await _pumpSurface(
        tester,
        QuantumMorphSurface(
          initialSize: const Size(240, 160),
          lockAspectRatio: true,
          snapGrid: 10,
          child: SizedBox.expand(child: _panel('G096-fill')),
        ),
        size: const Size(800, 600),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 097 - hydration-claim-path @ 820x1180', () {
    testWidgets('G097-A injects and claims hydration payloads cleanly',
        (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/97',
        'props': {'title': 'G097', 'width': 820, 'height': 1180},
      });
      final claimed = QLHydration.claimProps('/layout/97');
      expect(claimed, isNotNull);
      expect(claimed!['title'], 'G097');
    });

    testWidgets('G097-B consumes hydration only once', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/97/once',
        'props': {'variant': 'once', 'index': 96},
      });
      expect(QLHydration.claimProps('/layout/97/once'), isNotNull);
      expect(QLHydration.claimProps('/layout/97/once'), isNull);
    });

    testWidgets('G097-C leaves non-matching paths untouched', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/97/match',
        'props': {'kind': 'path-check'},
      });
      expect(QLHydration.claimProps('/layout/97/other'), isNull);
      expect(QLHydration.claimProps('/layout/97/match'), isNotNull);
    });

    testWidgets('G097-D can store structured metadata', (tester) async {
      QLHydration.injectProps({
        '__path__': '/layout/97/meta',
        'props': {
          'nest': {'left': 1, 'right': 2},
          'label': 'G097',
        },
      });
      final claimed = QLHydration.claimProps('/layout/97/meta');
      expect(claimed, isNotNull);
      expect((claimed!['nest'] as Map)['right'], 2);
    });

    testWidgets('G097-E still works after a layout pump around it',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _panel('G097-hydration-root'),
            _panel('G097-hydration-tail'),
          ],
        ),
        size: const Size(480, 280),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 098 - wrap-and-gap-grid @ 1024x768', () {
    testWidgets('G098-A lays out a wrapped flow without overflow',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _panel('G098-wrap-1', width: 58, height: 28),
                _panel('G098-wrap-2', width: 64, height: 28),
                _panel('G098-wrap-3', width: 72, height: 28),
                _panel('G098-wrap-4', width: 80, height: 28),
              ],
            ),
          ],
        ),
        size: const Size(1024.0, 768.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G098-wrap-4'), findsOneWidget);
    });

    testWidgets('G098-B keeps custom gaps visible between wrapped elements',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          gap: 14,
          children: [
            _panel('G098-gap-1'),
            _panel('G098-gap-2'),
            _panel('G098-gap-3'),
          ],
        ),
        size: const Size(420, 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G098-C mixes wrap and flex content safely', (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            Wrap(
              spacing: 8,
              children: [
                _panel('G098-mix-1'),
                _panel('G098-mix-2'),
              ],
            ),
            QuantumFlexible(child: _panel('G098-mix-3')),
          ],
        ),
        size: const Size(620, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G098-D remains readable when the available width shrinks',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _panel('G098-compact-1', width: 100, height: 26),
                _panel('G098-compact-2', width: 100, height: 26),
                _panel('G098-compact-3', width: 100, height: 26),
              ],
            ),
          ],
        ),
        size: const Size(300, 220),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G098-E still pumps after layout recalculation',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G098-recalc-1'),
            _panel('G098-recalc-2'),
            _panel('G098-recalc-3'),
          ],
        ),
        size: const Size(760, 260),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 099 - nested-row-column-stack @ 1280x720', () {
    testWidgets('G099-A composes a nested row-column stack', (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          gap: 10,
          children: [
            _panel('G099-left', width: 60, height: 60),
            _columnHarness(
              mainAxisSize: MainAxisSize.min,
              children: [
                _panel('G099-stack-a', width: 88, height: 30),
                _panel('G099-stack-b', width: 88, height: 30),
              ],
            ),
            _panel('G099-right', width: 60, height: 60),
          ],
        ),
        size: const Size(1280.0, 720.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G099-stack-b'), findsOneWidget);
    });

    testWidgets('G099-B survives a column inside a row inside a column',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
              children: [
                _panel('G099-row-inner-1'),
                _panel('G099-row-inner-2'),
              ],
            ),
            _columnHarness(
              children: [
                _panel('G099-col-inner-1'),
                _panel('G099-col-inner-2'),
              ],
            ),
          ],
        ),
        size: const Size(500, 420),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G099-C keeps outer and inner text discoverable',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G099-outer-text'),
            _columnHarness(children: [
              _panel('G099-inner-text-a'),
              _panel('G099-inner-text-b')
            ]),
          ],
        ),
        size: const Size(820, 320),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G099-inner-text-b'), findsOneWidget);
    });

    testWidgets('G099-D does not explode with mixed fit semantics',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            QuantumFlexible(fit: FlexFit.loose, child: _panel('G099-loose-a')),
            QuantumFlexible(fit: FlexFit.tight, child: _panel('G099-tight-b')),
          ],
        ),
        size: const Size(640, 280),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G099-E remains healthy after a second pump pass',
        (tester) async {
      await _pumpSurface(
        tester,
        _columnHarness(
          children: [
            _rowHarness(
                children: [_panel('G099-pass-1'), _panel('G099-pass-2')]),
            _panel('G099-pass-3'),
          ],
        ),
        size: const Size(960, 420),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('Group 100 - loose-flex-outside-scope @ 1440x900', () {
    testWidgets('G100-A degrades safely outside a flex scope', (tester) async {
      await _pumpSurface(
        tester,
        QuantumFlexible(
          child: _panel('G100-orphan'),
        ),
        size: const Size(1440.0, 900.0),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('G100-orphan'), findsOneWidget);
    });

    testWidgets('G100-B remains visible when nested under a plain container',
        (tester) async {
      await _pumpSurface(
        tester,
        Container(
          padding: const EdgeInsets.all(12),
          child: QuantumFlexible(
            fit: FlexFit.loose,
            child: _panel('G100-container-child'),
          ),
        ),
        size: const Size(420, 320),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G100-C tolerates a strict window with no flex ancestor',
        (tester) async {
      await _pumpSurface(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: QuantumFlexible(
            child: _panel('G100-strict'),
          ),
        ),
        size: const Size(280, 180),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('G100-D keeps child labels discoverable after repump',
        (tester) async {
      await _pumpSurface(
        tester,
        Center(
          child: QuantumFlexible(child: _panel('G100-discoverable')),
        ),
        size: const Size(500, 360),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('G100-discoverable'), findsOneWidget);
    });

    testWidgets('G100-E stays calm when paired with a normal box',
        (tester) async {
      await _pumpSurface(
        tester,
        _rowHarness(
          children: [
            _panel('G100-normal'),
            QuantumFlexible(child: _panel('G100-flexed')),
          ],
        ),
        size: const Size(560, 240),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
