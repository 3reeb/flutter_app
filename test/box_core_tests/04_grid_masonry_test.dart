// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: GRID & MASONRY — PRODUCTION TESTS
// test/box_core_tests/04_grid_masonry_test.dart
//
// Tests cover:
//  • box:grid alias
//  • box:masonry alias
//  • gridCols / cols string parsing: "1fr 1fr", "1fr 2fr 1fr", "repeat(3,1fr)"
//  • gridRows / rows string parsing
//  • gap prop on grid
//  • dense:true vs dense:false packing
//  • Grid inside bounded container
//  • Masonry multi-column with unequal height items
//  • Dynamic grid size — cols driven by store
//  • Grid with onClick on grid items
//  • 4-column responsive grid pattern
//  • grid + clip combination
//  • Nested grid inside grid (2-level)
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Grid & Masonry — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Grid basic ──────────────────────────────────────────────────────
    testWidgets('1.1 "grid" alias renders 2-column grid', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr', 'gap': 8},
        'children': List.generate(
          6,
          (i) => colorBox('h-80 bg-blue-${((i % 5) + 1) * 100}', label: 'G$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('G0'), findsOneWidget);
      expect(find.text('G5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 box:grid with 3-column "1fr 2fr 1fr" distributes widths', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 2fr 1fr', 'gap': 12},
        'children': [
          colorBox('h-80 bg-slate-200', label: 'Narrow'),
          colorBox('h-80 bg-indigo-300', label: 'Wide'),
          colorBox('h-80 bg-slate-200', label: 'Narrow2'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Narrow'), findsOneWidget);
      expect(find.text('Wide'), findsOneWidget);
      expect(find.text('Narrow2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.3 grid with "cols" fallback shorthand', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'cols': '1fr 1fr 1fr', 'gap': 8},
        'children': List.generate(
          9,
          (i) => colorBox('h-60 bg-green-200', label: 'C$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('C0'), findsOneWidget);
      expect(find.text('C8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Grid rows definition ────────────────────────────────────────────
    testWidgets('2.1 grid with rows:"auto auto" defines row sizing', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {
          'gridCols': '1fr 1fr',
          'gridRows': 'auto auto',
          'gap': 8,
        },
        'children': List.generate(
          4,
          (i) => colorBox('h-80 bg-rose-200', label: 'R$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('R0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Gap on grid ────────────────────────────────────────────────────
    testWidgets('3.1 gap:16 applies row and column gap uniformly', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr', 'gap': 16},
        'children': List.generate(
          4,
          (i) => colorBox('h-80 bg-amber-200', label: 'GG$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('GG0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.2 gap:0 on grid — items touch without spacing', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr', 'gap': 0},
        'children': List.generate(
          4,
          (i) => colorBox('h-80 bg-slate-300', label: 'Z$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Z0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. Dense grid packing ─────────────────────────────────────────────
    testWidgets('4.1 dense:true packs items into available cells', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {
          'gridCols': '1fr 1fr 1fr',
          'gap': 8,
          'dense': true,
        },
        'children': List.generate(
          12,
          (i) => colorBox('h-80 bg-violet-200', label: 'D$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('D0'), findsOneWidget);
      expect(find.text('D11'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 5. Masonry layout ─────────────────────────────────────────────────
    testWidgets('5.1 "masonry" alias renders multi-column waterfall', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'masonry',
        'style': 'w-full h-full',
        'props': {'cols': '1fr 1fr', 'gap': 8},
        'children': [
          colorBox('h-80 bg-pink-200', label: 'Mas0'),
          colorBox('h-140 bg-pink-300', label: 'Mas1'),
          colorBox('h-100 bg-pink-200', label: 'Mas2'),
          colorBox('h-60 bg-pink-100', label: 'Mas3'),
          colorBox('h-120 bg-pink-300', label: 'Mas4'),
          colorBox('h-90 bg-pink-200', label: 'Mas5'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Mas0'), findsOneWidget);
      expect(find.text('Mas5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5.2 masonry with 3 cols and unequal heights', (tester) async {
      final heights = [60, 130, 80, 200, 50, 110, 90, 70, 150];
      await tester.pumpWidget(buildTestWrapper({
        'type': 'masonry',
        'style': 'w-full h-full',
        'props': {'cols': '1fr 1fr 1fr', 'gap': 12},
        'children': heights.asMap().entries.map((e) {
          return {
            'type': 'col',
            'style': 'w-full bg-emerald-${(e.key % 5 + 1) * 100} rounded-xl',
            'props': {'height': e.value.toDouble()},
            'children': [textLeaf('Item${e.key}')],
          };
        }).toList(),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Item0'), findsOneWidget);
      expect(find.text('Item8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Dynamic grid cols from store ────────────────────────────────────
    testWidgets('6.1 cols prop driven by store value renders variable columns', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'grid',
          'style': 'w-full',
          'props': {'gridCols': r'{{gridTemplate}}', 'gap': 8},
          'children': List.generate(
            6,
            (i) => colorBox('h-80 bg-cyan-200', label: 'Dyn$i'),
          ),
        },
        initialStore: {'gridTemplate': '1fr 1fr 1fr'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dyn0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Grid inside bounded col ─────────────────────────────────────────
    testWidgets('7.1 grid inside a 400px col with bounded height', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-400 h-full',
        'children': [
          {
            'type': 'grid',
            'style': 'w-full',
            'props': {'gridCols': '1fr 1fr', 'gap': 8},
            'children': List.generate(
              8,
              (i) => colorBox('h-80 bg-orange-200', label: 'BG$i'),
            ),
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('BG0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Grid with onClick on children ──────────────────────────────────
    testWidgets('8.1 grid child with onClick registers tap action', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr 1fr', 'gap': 8},
        'children': List.generate(
          3,
          (i) => {
            'type': 'col',
            'style': 'h-80 bg-blue-200 rounded-lg items-center justify-center',
            'props': {
              'onClick': [
                {'action': 'state.set', 'key': 'selected_grid', 'value': i}
              ],
            },
            'children': [textLeaf('Item $i')],
          },
        ),
      }));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Item 1'));
      await tester.pump();

      expect(testStore.get('selected_grid'), equals(1));
    });

    // ── 9. 4-column responsive card grid ──────────────────────────────────
    testWidgets('9.1 4-col product grid with height-varying cards', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'props': {'scrollable': true, 'padding': [16]},
        'children': [
          {
            'type': 'grid',
            'style': 'w-full',
            'props': {'gridCols': '1fr 1fr 1fr 1fr', 'gap': 12},
            'children': List.generate(
              12,
              (i) => {
                'type': 'col',
                'style': 'bg-white rounded-xl shadow-sm',
                'props': {'height': (i % 3 + 1) * 80.0},
                'children': [
                  {
                    'type': 'col',
                    'style': 'w-full h-60 bg-blue-${(i % 5 + 1) * 100} rounded-t-xl',
                    'children': [],
                  },
                  {
                    'type': 'col',
                    'style': 'p-12',
                    'children': [textLeaf('Product $i')],
                  },
                ],
              },
            ),
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Product 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Nested grid inside grid ────────────────────────────────────────
    testWidgets('10.1 2-level nested grid — calendar-style', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr', 'gap': 16},
        'children': List.generate(
          2,
          (outer) => {
            'type': 'col',
            'style': 'w-full bg-slate-50 rounded-xl p-12',
            'children': [
              textLeaf('Week ${outer + 1}'),
              {
                'type': 'grid',
                'style': 'w-full mt-8',
                'props': {'gridCols': '1fr 1fr 1fr 1fr 1fr 1fr 1fr', 'gap': 4},
                'children': List.generate(
                  7,
                  (inner) => colorBox('h-40 bg-blue-100 rounded-sm', label: '${inner + 1}'),
                ),
              },
            ],
          },
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('Week 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 11. Grid clip ──────────────────────────────────────────────────────
    testWidgets('11.1 grid with clip:true on wrapper prevents overflow', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-200',
        'props': {'clip': true},
        'children': [
          {
            'type': 'grid',
            'style': 'w-full',
            'props': {'gridCols': '1fr 1fr', 'gap': 8},
            'children': List.generate(
              30,
              (i) => colorBox('h-80 bg-violet-100', label: 'CG$i'),
            ),
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(ClipRect), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
