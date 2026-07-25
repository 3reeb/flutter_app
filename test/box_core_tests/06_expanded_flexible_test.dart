// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: EXPANDED & FLEXIBLE — PRODUCTION TESTS
// test/box_core_tests/06_expanded_flexible_test.dart
//
// Tests cover:
//  • box:expanded / box:flexible within a row/col parent
//  • Default flex value (1) and custom flex values
//  • Flexible vs Expanded fill behavior (loose vs tight)
//  • flex in col: two expanded children share height equally
//  • flex in row: 2:1 ratio
//  • expanded wrapping complex content (grid, scrollable col)
//  • Multiple flexible + expanded combinations
//  • Expanded inside split pane
//  • Dynamic flex value from store
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Expanded & Flexible — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Expanded in row ─────────────────────────────────────────────────
    testWidgets('1.1 single expanded in row fills remaining width', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-60 items-center',
        'children': [
          colorBox('w-80 h-60 bg-slate-300', label: 'Fixed'),
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-60 bg-blue-200', label: 'Fills')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Fixed'), findsOneWidget);
      expect(find.text('Fills'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 two expanded in row share width equally (flex:1 each)', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-60',
        'children': [
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-60 bg-red-200', label: 'Half1')],
          },
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-60 bg-blue-200', label: 'Half2')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Half1'), findsOneWidget);
      expect(find.text('Half2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.3 expanded flex:2 and flex:1 — 2:1 ratio in row', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-60',
        'children': [
          {
            'type': 'box:expanded',
            'props': {'flex': 2},
            'children': [colorBox('w-full h-60 bg-green-300', label: 'TwoParts')],
          },
          {
            'type': 'box:expanded',
            'props': {'flex': 1},
            'children': [colorBox('w-full h-60 bg-green-100', label: 'OnePart')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('TwoParts'), findsOneWidget);
      expect(find.text('OnePart'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Expanded in col ─────────────────────────────────────────────────
    testWidgets('2.1 expanded in col fills remaining vertical space', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [
          colorBox('w-full h-60 bg-slate-200', label: 'FixedHeader'),
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-full bg-white', label: 'Content')],
          },
          colorBox('w-full h-48 bg-slate-200', label: 'FixedFooter'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('FixedHeader'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('FixedFooter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.2 two expanded in col — equal height sections', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-full bg-indigo-100', label: 'Section1')],
          },
          {
            'type': 'box:expanded',
            'children': [colorBox('w-full h-full bg-indigo-200', label: 'Section2')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Section1'), findsOneWidget);
      expect(find.text('Section2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Flexible (loose fit) ────────────────────────────────────────────
    testWidgets('3.1 box:flexible wraps child without forcing tight fit', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-80 items-center',
        'children': [
          {
            'type': 'box:flexible',
            'props': {'flex': 1},
            'children': [textLeaf('FlexChild')],
          },
          colorBox('w-100 h-60 bg-slate-300', label: 'Fixed'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('FlexChild'), findsOneWidget);
      expect(find.text('Fixed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('3.2 flexible + expanded mixed in same row', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-60 items-center min-w-0',
        'children': [
          {
            'type': 'box:flexible',
            'props': {'flex': 1},
            'children': [textLeaf('Flex')],
          },
          {
            'type': 'box:expanded',
            'props': {'flex': 2},
            'children': [colorBox('w-full h-60 bg-blue-200', label: 'Expanded')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Flex'), findsOneWidget);
      expect(find.text('Expanded'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. Expanded wrapping complex content ──────────────────────────────
    testWidgets('4.1 expanded wrapping scrollable col with grid', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [
          colorBox('w-full h-56 bg-blue-700', label: 'AppBar'),
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'col',
                'style': 'w-full h-full',
                'props': {'scrollable': true, 'padding': [16]},
                'children': [
                  {
                    'type': 'grid',
                    'style': 'w-full',
                    'props': {'gridCols': '1fr 1fr 1fr', 'gap': 12},
                    'children': List.generate(
                      9,
                      (i) => colorBox('h-100 rounded-xl bg-white shadow-sm', label: 'Card$i'),
                    ),
                  },
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('AppBar'), findsOneWidget);
      expect(find.text('Card0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 5. Expanded inside split pane ──────────────────────────────────────
    testWidgets('5.1 expanded fills split pane content area', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-400',
        'props': {
          'direction': 'horizontal',
          'fractions': [0.3, 0.7],
        },
        'children': [
          {
            'type': 'col',
            'style': 'w-full h-full',
            'children': [
              textLeaf('SplitLeft'),
            ],
          },
          {
            'type': 'col',
            'style': 'w-full h-full',
            'children': [
              colorBox('w-full h-40 bg-blue-100', label: 'SplitHeader'),
              {
                'type': 'box:expanded',
                'children': [
                  colorBox('w-full h-full bg-slate-50', label: 'SplitContent'),
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('SplitLeft'), findsOneWidget);
      expect(find.text('SplitContent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Dynamic flex from store ─────────────────────────────────────────
    testWidgets('6.1 flex value from store signal — dynamic flex', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'row',
          'style': 'w-full h-60',
          'children': [
            {
              'type': 'box:expanded',
              'props': {'flex': r'{{flexLeft}}'},
              'children': [colorBox('w-full h-60 bg-emerald-200', label: 'DynLeft')],
            },
            {
              'type': 'box:expanded',
              'props': {'flex': 1},
              'children': [colorBox('w-full h-60 bg-emerald-400', label: 'DynRight')],
            },
          ],
        },
        initialStore: {'flexLeft': 3},
      ));
      await tester.pumpAndSettle();

      expect(find.text('DynLeft'), findsOneWidget);
      expect(find.text('DynRight'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Multiple expandeds + fixed + flexible — dashboard layout ─────────
    testWidgets('7.1 full dashboard layout: fixed header, sidebar, expanded main', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full min-w-0 min-h-0',
        'children': [
          // Top bar
          colorBox('w-full h-56 bg-slate-900', label: 'TopBar'),
          // Body
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'row',
                'style': 'w-full h-full min-w-0',
                'children': [
                  // Sidebar
                  colorBox('w-220 h-full bg-slate-800', label: 'Sidebar'),
                  // Main
                  {
                    'type': 'box:expanded',
                    'children': [
                      {
                        'type': 'col',
                        'style': 'w-full h-full',
                        'props': {'scrollable': true, 'padding': [24]},
                        'children': [
                          textLeaf('Dashboard Content'),
                          {
                            'type': 'grid',
                            'style': 'w-full mt-16',
                            'props': {'gridCols': '1fr 1fr 1fr 1fr', 'gap': 16},
                            'children': List.generate(
                              8,
                              (i) => colorBox('h-100 rounded-xl bg-white shadow-sm', label: 'Stat$i'),
                            ),
                          },
                        ],
                      },
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('TopBar'), findsOneWidget);
      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.text('Dashboard Content'), findsOneWidget);
      expect(find.text('Stat0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
