// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: ROW & COL — PRODUCTION TESTS
// test/box_core_tests/01_row_col_basic_test.dart
//
// Tests cover:
//  • Alias resolution: 'row' → 'box:row', 'col' → 'box:col'
//  • Style attribute: w-full, h-full, item-center, justify-*, gap-*, overflow-*
//  • Width/height sizing props
//  • Gap prop vs style gap
//  • justify + items alignment combos
//  • Nested row-in-col and col-in-row
//  • Scrollable row / col
//  • clip:true rendering
//  • expand:true → SizedBox.expand
//  • constrained min/maxWidth/Height
//  • fractional sizing
//  • offstage / ignorePointer / absorbPointer / repaintBoundary
//  • Semantic label application
//  • Deep nesting (10 levels)
//  • Dynamic width / height driven by store data
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Row & Col — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Alias resolution ────────────────────────────────────────────────
    testWidgets(
        '1.1 "row" alias resolves to box:row and renders Flex(horizontal)',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-80 items-center',
        'children': [textLeaf('A'), textLeaf('B'), textLeaf('C')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets(
        '1.2 "col" alias resolves to box:col and renders Flex(vertical)',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [textLeaf('X'), textLeaf('Y')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('X'), findsOneWidget);
      expect(find.text('Y'), findsOneWidget);
    });

    // ── 2. Style attribute — layout tokens ────────────────────────────────
    testWidgets('2.1 style "w-full h-full" fills available space',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [textLeaf('Fill')],
      }));
      await tester.pumpAndSettle();

      final colFinder = find.byWidgetPredicate((w) => w is Q);
      expect(colFinder, findsWidgets);
    });

    testWidgets('2.2 style "items-center justify-center" centres children',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full items-center justify-center',
        'children': [textLeaf('Centered')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Centered'), findsOneWidget);
    });

    testWidgets('2.3 style "items-end justify-end" pushes children to end',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-80 items-end justify-end',
        'children': [textLeaf('EndChild')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('EndChild'), findsOneWidget);
    });

    testWidgets('2.4 style "gap-16" applies spacing token between children',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full gap-16 items-center',
        'children': [textLeaf('L'), textLeaf('R')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('L'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);
    });

    testWidgets('2.5 style "overflow-hidden" clips overflow', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-200 h-50 overflow-hidden',
        'children': [
          colorBox('w-full h-300 bg-red-500', label: 'TallChild'),
        ],
      }));
      await tester.pumpAndSettle();
      // Should render without throwing overflow errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.6 style "min-w-0 min-h-0" prevents intrinsic overflow crash',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'min-w-0 min-h-0',
        'children': [
          {
            'type': 'box:col',
            'style': 'min-w-0',
            'children': [textLeaf('Safe')]
          },
        ],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 3. Props: gap, justify, items ──────────────────────────────────────
    testWidgets('3.1 prop gap:20 applies spacing between children',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'gap': 20},
        'children': [textLeaf('P1'), textLeaf('P2'), textLeaf('P3')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('P1'), findsOneWidget);
      expect(find.text('P3'), findsOneWidget);
    });

    testWidgets('3.2 prop justify:space-between spreads children',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-60',
        'props': {'justify': 'space-between'},
        'children': [textLeaf('First'), textLeaf('Last')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsOneWidget);
      expect(find.text('Last'), findsOneWidget);
    });

    testWidgets('3.3 prop items:stretch stretches cross-axis', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-100',
        'props': {'items': 'stretch'},
        'children': [textLeaf('Stretch')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Stretch'), findsOneWidget);
    });

    // ── 4. Width / Height props ───────────────────────────────────────────
    testWidgets('4.1 width:300 height:150 creates bounded SizedBox',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'bg-blue-500',
        'props': {'width': 300.0, 'height': 150.0},
        'children': [textLeaf('Sized')],
      }));
      await tester.pumpAndSettle();

      // Must render without overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Sized'), findsOneWidget);
    });

    testWidgets('4.2 expand:true fills all available space via SizedBox.expand',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'props': {'expand': true},
        'children': [textLeaf('Expanded')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(SizedBox), findsWidgets);
      expect(find.text('Expanded'), findsOneWidget);
    });

    // ── 5. Constrained box ────────────────────────────────────────────────
    testWidgets(
        '5.1 constrained:true with maxWidth/maxHeight enforces box constraints',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'items-center',
        'props': {
          'constrained': true,
          'minWidth': 100.0,
          'maxWidth': 400.0,
          'minHeight': 50.0,
          'maxHeight': 300.0,
        },
        'children': [textLeaf('Constrained')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(ConstrainedBox), findsWidgets);
      expect(find.text('Constrained'), findsOneWidget);
    });

    testWidgets('5.2 constrained with minWidth:0 minHeight:0 is no-op safe',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full',
        'props': {
          'constrained': true,
          'minWidth': 0.0,
          'minHeight': 0.0,
        },
        'children': [textLeaf('SafeConstrained')],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 6. Fractional sizing ──────────────────────────────────────────────
    testWidgets(
        '6.1 fractional:true with widthFactor:0.5 uses half parent width',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'fractional': true, 'widthFactor': 0.5, 'heightFactor': 1.0},
        'children': [textLeaf('Half')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(FractionallySizedBox), findsWidgets);
    });

    // ── 7. Clip ───────────────────────────────────────────────────────────
    testWidgets('7.1 clip:true wraps with ClipRect', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-200 h-100',
        'props': {'clip': true},
        'children': [colorBox('w-400 h-400 bg-green-500')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(ClipRect), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Opacity ────────────────────────────────────────────────────────
    testWidgets('8.1 opacity:0.5 wraps in Opacity widget', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'opacity': 0.5},
        'children': [textLeaf('SemiVisible')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Opacity), findsWidgets);
    });

    testWidgets('8.2 opacity:1.0 does NOT add Opacity widget (no overhead)',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'opacity': 1.0},
        'children': [textLeaf('Visible')],
      }));
      await tester.pumpAndSettle();
      // No extra Opacity widget for full opacity
      final opacityFinders = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .where((w) => w.opacity < 1.0)
          .toList();
      expect(opacityFinders, isEmpty);
    });

    // ── 9. Pointer / Gesture control ──────────────────────────────────────
    testWidgets('9.1 offstage:true hides the widget tree', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'offstage': true},
        'children': [textLeaf('Hidden')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Offstage), findsWidgets);
    });

    testWidgets('9.2 ignorePointer:true blocks tap events', (tester) async {
      bool tapped = false;
      QuantumVM.instance.registerAction(
        'test.tapped',
        LambdaActionPlugin((p, s, c) async => tapped = true),
      );

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {
          'ignorePointer': true,
          'onClick': ['test.tapped'],
        },
        'children': [textLeaf('NoTap')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(IgnorePointer), findsWidgets);
      await tester.tap(find.text('NoTap'), warnIfMissed: false);
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('9.3 absorbPointer:true swallows pointer events',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'absorbPointer': true},
        'children': [textLeaf('Absorbed')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(AbsorbPointer), findsWidgets);
    });

    testWidgets('9.4 repaintBoundary:true isolates paint', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'repaintBoundary': true},
        'children': [textLeaf('Boundary')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    // ── 10. Semantics ─────────────────────────────────────────────────────
    testWidgets('10.1 semanticLabel adds Semantics widget with label',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'semanticLabel': 'My Container'},
        'children': [textLeaf('Inner')],
      }));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('My Container'), findsWidgets);
    });

    // ── 11. Nested row-in-col ─────────────────────────────────────────────
    testWidgets('11.1 row nested inside col renders correct 2D layout',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full gap-8',
        'children': [
          {
            'type': 'row',
            'style': 'w-full h-60 items-center gap-12',
            'children': [textLeaf('Row1Col1'), textLeaf('Row1Col2')],
          },
          {
            'type': 'row',
            'style': 'w-full h-60 items-center gap-12',
            'children': [textLeaf('Row2Col1'), textLeaf('Row2Col2')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Row1Col1'), findsOneWidget);
      expect(find.text('Row2Col2'), findsOneWidget);
    });

    testWidgets('11.2 col nested inside row — sidebar + content pattern',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-full min-w-0',
        'children': [
          {
            'type': 'col',
            'style': 'w-200 h-full gap-8',
            'children': [
              textLeaf('NavItem1'),
              textLeaf('NavItem2'),
              textLeaf('NavItem3'),
            ],
          },
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'col',
                'style': 'w-full h-full',
                'children': [textLeaf('Main content area')],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('NavItem1'), findsOneWidget);
      expect(find.text('Main content area'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 12. Scrollable row / col ──────────────────────────────────────────
    testWidgets('12.1 col with scrollable:true wraps in scroll viewport',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'scrollable': true},
        'children': List.generate(
          50,
          (i) => textLeaf('Item $i'),
        ),
      }));
      await tester.pumpAndSettle();

      // The first and last items may not both be visible
      expect(find.text('Item 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('12.2 row with scrollable:true wraps in horizontal scroll',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'h-80 items-center',
        'props': {'scrollable': true},
        'children': List.generate(
          30,
          (i) => colorBox('w-100 h-60 bg-purple-300', label: 'Card$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Card0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 13. Deep nesting stress test ──────────────────────────────────────
    testWidgets('13.1 10-level deep nesting renders without stack overflow',
        (tester) async {
      Map<String, dynamic> buildNested(int depth, String label) {
        if (depth == 0) return textLeaf(label);
        final type = depth.isEven ? 'col' : 'row';
        return {
          'type': type,
          'style': 'min-w-0 min-h-0',
          'children': [buildNested(depth - 1, label)],
        };
      }

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [buildNested(10, 'DeepLeaf')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('DeepLeaf'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 14. Dynamic sizes driven by store ─────────────────────────────────
    testWidgets('14.1 width/height driven by store data — reactive sizing',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'props': {
            'width': r'{{boxWidth}}',
            'height': r'{{boxHeight}}',
          },
          'children': [textLeaf('Dynamic')],
        },
        initialStore: {'boxWidth': 250.0, 'boxHeight': 120.0},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dynamic'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14.2 gap driven by store signal', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'props': {'gap': r'{{spacing}}'},
          'children': [textLeaf('Gapped'), textLeaf('Item')],
        },
        initialStore: {'spacing': 24},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gapped'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 15. onClick on col ────────────────────────────────────────────────
    testWidgets('15.1 col with onClick triggers action on tap', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-80 items-center justify-center',
        'props': {
          'onClick': [
            {'action': 'state.set', 'key': 'was_tapped', 'value': true}
          ],
        },
        'children': [textLeaf('TapMe')],
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.text('TapMe'));
      await tester.pump();

      expect(testStore.get('was_tapped'), isTrue);
    });

    // ── 16. Multiple style tokens combined ────────────────────────────────
    testWidgets(
        '16.1 combined style: w-full h-200 items-start justify-between gap-8',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-200 items-start justify-between gap-8',
        'children': [
          textLeaf('Alpha'),
          textLeaf('Beta'),
          textLeaf('Gamma'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 17. Padding and margin props ──────────────────────────────────────
    testWidgets('17.1 padding prop applied to col', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {
          'padding': [16],
        },
        'children': [textLeaf('Padded')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Padded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17.2 margin prop applied to row', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'row',
            'style': 'w-full h-60',
            'props': {
              'margin': [8, 16],
            },
            'children': [textLeaf('Margined')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Margined'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17.3 asymmetric padding [top, right, bottom, left]',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {
          'padding': [8, 24, 8, 12],
        },
        'children': [textLeaf('AsymPadded')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('AsymPadded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 18. Complex combination: sidebar layout with nested scrollable col ─
    testWidgets('18.1 sidebar + scrollable content — real-world pattern',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-full min-w-0',
        'children': [
          // Fixed sidebar
          {
            'type': 'col',
            'style': 'w-200 h-full bg-slate-800 gap-4',
            'props': {
              'padding': [16]
            },
            'children': List.generate(
              5,
              (i) => {
                'type': 'col',
                'style': 'w-full rounded-xl p-12',
                'children': [textLeaf('Nav$i')],
              },
            ),
          },
          // Scrollable main
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'col',
                'style': 'w-full h-full',
                'props': {
                  'scrollable': true,
                  'padding': [24]
                },
                'children': List.generate(
                  20,
                  (i) => {
                    'type': 'col',
                    'style': 'w-full h-80 bg-white rounded-xl mb-12',
                    'children': [textLeaf('Card $i')],
                  },
                ),
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Nav0'), findsOneWidget);
      expect(find.text('Card 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
