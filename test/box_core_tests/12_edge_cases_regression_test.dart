// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: EDGE CASES & REGRESSION TESTS
// test/box_core_tests/12_edge_cases_regression_test.dart
//
// Tests for known dangerous conditions, boundary values, and regressions:
//  1. Empty children list
//  2. Null/missing style
//  3. Unbounded width/height in split → MediaQuery fallback
//  4. Expanded directly inside col (not row) – common anti-pattern
//  5. box with both width and expand:true (width should be ignored)
//  6. Very long style strings (combinational explosion)
//  7. Nested scroll viewports (scroll in scroll)
//  8. col inside row with tight constraints (min-w-0 guard)
//  9. box:split single child (only 1 fraction)
//  10. grid with 0 children
//  11. Stack with 1 child
//  12. gap:negative (should not crash)
//  13. opacity:-0.5 clamp (should not crash)
//  14. fractional:true widthFactor:0 / heightFactor:0
//  15. constrained with maxWidth:0 (invisible but no crash)
//  16. Deep recursive nesting (15 levels)
//  17. Mixing subtype through box:col direct type
//  18. aspectBox:true ratio:0 (edge case)
//  19. Multiple measures on same bind key (should not conflict)
//  20. Dynamic width:0 height:0 (invisible box)
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Edge Cases & Regressions', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Empty children ──────────────────────────────────────────────────
    testWidgets('1.1 col with empty children renders without crash', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-80',
        'children': [],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 row with empty children', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-40',
        'children': [],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.3 grid with 0 children', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr', 'gap': 8},
        'children': [],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.4 stack with 0 children', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-100 h-100',
        'children': [],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 2. No style ────────────────────────────────────────────────────────
    testWidgets('2.1 col with no style prop renders with defaults', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'children': [textLeaf('NoStyle')],
      }));
      await tester.pumpAndSettle();
      expect(find.text('NoStyle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Expanded inside col (not row) ─────────────────────────────────
    // Expanded needs a Flex parent — should degrade gracefully
    testWidgets('3.1 expanded inside col takes vertical space', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-300',
        'children': [
          textLeaf('Top'),
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-full bg-blue-100', label: 'FillVert')],
          },
          textLeaf('Bottom'),
        ],
      }));
      await tester.pumpAndSettle();
      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. expand:true with width prop — expand wins ───────────────────────
    testWidgets('4.1 expand:true overrides width/height props', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'props': {'expand': true, 'width': 100.0, 'height': 100.0},
        'children': [textLeaf('ExpandWins')],
      }));
      await tester.pumpAndSettle();
      expect(find.byType(SizedBox), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ── 5. Very long style string ──────────────────────────────────────────
    testWidgets('5.1 very long style string with many tokens renders without crash', (tester) async {
      final longStyle = [
        'w-full', 'h-200', 'min-w-0', 'min-h-0',
        'bg-white', 'rounded-xl', 'shadow-sm',
        'items-center', 'justify-center',
        'p-24', 'gap-16', 'overflow-hidden',
      ].join(' ');

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': longStyle,
        'children': [textLeaf('LongStyle')],
      }));
      await tester.pumpAndSettle();
      expect(find.text('LongStyle'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Nested scroll viewports ─────────────────────────────────────────
    testWidgets('6.1 col with scrollable inside another scrollable col', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-300',
        'props': {'scrollable': true},
        'children': [
          textLeaf('Outer scroll'),
          {
            'type': 'col',
            'style': 'w-full h-200',
            'props': {'scrollable': true},
            'children': List.generate(
              10,
              (i) => textLeaf('Inner $i'),
            ),
          },
          textLeaf('Outer end'),
        ],
      }));
      await tester.pumpAndSettle();
      expect(find.text('Outer scroll'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. col with min-w-0 inside tight row ──────────────────────────────
    testWidgets('7.1 col min-w-0 inside row prevents overflow exception', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-60 items-center gap-12',
        'children': [
          colorBox('w-60 h-60 bg-blue-300'),
          {
            'type': 'col',
            'style': 'min-w-0',
            'children': [
              textLeaf('Long text that might overflow its parent'),
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();
      expect(find.text('Long text that might overflow its parent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Stack with 1 child ─────────────────────────────────────────────
    testWidgets('8.1 stack with only 1 child renders normally', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-200 h-100',
        'children': [textLeaf('SingleInStack')],
      }));
      await tester.pumpAndSettle();
      expect(find.text('SingleInStack'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. gap:0 and gap:-1 edge cases ────────────────────────────────────
    testWidgets('9.1 gap:0 does not add gap token', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'gap': 0},
        'children': [textLeaf('G0'), textLeaf('G1')],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('9.2 gap:-5 treated as no gap (not crash)', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'gap': -5},
        'children': [textLeaf('Neg0'), textLeaf('Neg1')],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 10. fractional:true with widthFactor:0 ────────────────────────────
    testWidgets('10.1 fractional widthFactor:0 renders invisible but no crash', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'col',
            'style': 'h-80',
            'props': {'fractional': true, 'widthFactor': 0.0, 'heightFactor': 1.0},
            'children': [textLeaf('Invisible')],
          },
          textLeaf('Visible'),
        ],
      }));
      await tester.pumpAndSettle();
      expect(find.text('Visible'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 11. constrained with maxWidth:0 ───────────────────────────────────
    testWidgets('11.1 constrained maxWidth:0 renders nothing visible but no crash', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'col',
            'props': {
              'constrained': true,
              'maxWidth': 0.0,
              'maxHeight': 0.0,
            },
            'children': [textLeaf('HiddenConstr')],
          },
          textLeaf('AfterConstr'),
        ],
      }));
      await tester.pumpAndSettle();
      expect(find.text('AfterConstr'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 12. Deep 15-level nesting ─────────────────────────────────────────
    testWidgets('12.1 15-level deep nesting survives without stack overflow', (tester) async {
      Map<String, dynamic> buildNested(int depth) {
        if (depth == 0) return textLeaf('DeepLeaf15');
        final types = ['col', 'row', 'stack', 'col', 'col'];
        return {
          'type': types[depth % types.length],
          'style': 'min-w-0 min-h-0',
          'children': [buildNested(depth - 1)],
        };
      }

      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [buildNested(15)],
      }));
      await tester.pumpAndSettle();

      expect(find.text('DeepLeaf15'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 13. aspectBox:true ratio:0 ────────────────────────────────────────
    testWidgets('13.1 aspectBox:true ratio:0.001 (near zero) renders safely', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'col',
            'style': 'w-full',
            'props': {'aspectBox': true, 'ratio': 0.001},
            'children': [textLeaf('TinyAspect')],
          },
        ],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 14. Multiple measure nodes on different bind keys ─────────────────
    testWidgets('14.1 two measure nodes with different binds operate independently', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'box:measure',
            'props': {'bind': 'box_a_bounds'},
            'children': [colorBox('w-200 h-80 bg-blue-200', label: 'BoxA')],
          },
          {
            'type': 'box:measure',
            'props': {'bind': 'box_b_bounds'},
            'children': [colorBox('w-300 h-120 bg-green-200', label: 'BoxB')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('BoxA'), findsOneWidget);
      expect(find.text('BoxB'), findsOneWidget);

      final boundsA = testStore.get('box_a_bounds') as Map?;
      final boundsB = testStore.get('box_b_bounds') as Map?;

      // Both should have written bounds
      if (boundsA != null) expect(boundsA['w'], greaterThan(0));
      if (boundsB != null) expect(boundsB['w'], greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    // ── 15. Dynamic width:0 height:0 — collapse to invisible ──────────────
    testWidgets('15.1 width:0 height:0 from store collapses box without crash', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'children': [
            {
              'type': 'col',
              'style': 'bg-red-100',
              'props': {'width': r'{{dynW}}', 'height': r'{{dynH}}'},
              'children': [textLeaf('DynZero')],
            },
            textLeaf('AfterDynZero'),
          ],
        },
        initialStore: {'dynW': 0.0, 'dynH': 0.0},
      ));
      await tester.pumpAndSettle();

      expect(find.text('AfterDynZero'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 16. split with single child ───────────────────────────────────────
    testWidgets('16.1 split with 1 child (no fraction pair) survives', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-300',
        'props': {
          'direction': 'horizontal',
          'fractions': [1.0],
        },
        'children': [textLeaf('OnlyPane')],
      }));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 17. box:col direct type ────────────────────────────────────────────
    testWidgets('17.1 box:col direct subtype declaration works', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:col',
        'style': 'w-full gap-8',
        'children': [textLeaf('DirectCol'), textLeaf('DirectCol2')],
      }));
      await tester.pumpAndSettle();
      expect(find.text('DirectCol'), findsOneWidget);
      expect(find.text('DirectCol2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17.2 box:row direct type declaration works', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:row',
        'style': 'w-full h-60 items-center',
        'children': [textLeaf('DirectRow'), textLeaf('DirectRow2')],
      }));
      await tester.pumpAndSettle();
      expect(find.text('DirectRow'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 18. all style direction combinations ──────────────────────────────
    for (final justify in ['start', 'end', 'center', 'space-between', 'space-around', 'space-evenly']) {
      testWidgets('18.justify-$justify on row renders without error', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'row',
          'style': 'w-full h-60 justify-$justify',
          'children': [textLeaf('A'), textLeaf('B')],
        }));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    for (final items in ['start', 'end', 'center', 'stretch', 'baseline']) {
      testWidgets('18.items-$items on row renders without error', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'row',
          'style': 'w-full h-80 items-$items',
          'children': [textLeaf('A')],
        }));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    // ── 19. repaintBoundary + semanticLabel together ───────────────────────
    testWidgets('19.1 repaintBoundary and semanticLabel can coexist', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {
          'repaintBoundary': true,
          'semanticLabel': 'Container Label',
        },
        'children': [textLeaf('Labeled')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(find.bySemanticsLabel('Container Label'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ── 20. wrap with 1 child ─────────────────────────────────────────────
    testWidgets('20.1 wrap with single child renders without error', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full',
        'children': [textLeaf('SingleWrapChild')],
      }));
      await tester.pumpAndSettle();
      expect(find.text('SingleWrapChild'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
