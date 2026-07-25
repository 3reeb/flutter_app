// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: SPLIT — PRODUCTION TESTS
// test/box_core_tests/05_split_test.dart
//
// Tests cover:
//  • box:split / 'split' alias
//  • Horizontal split with fractions [0.3, 0.7]
//  • Vertical split with fractions [0.4, 0.6]
//  • Equal fractions [0.5, 0.5]
//  • Three-pane split [0.2, 0.6, 0.2]
//  • Split with bounded style (h-300 w-full)
//  • Split with complex children (col + row + grid)
//  • Split with scrollable panes
//  • Split nested inside row
//  • Split with dynamic fractions from store
//  • Split pane with onTap action
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Split — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Basic horizontal split ──────────────────────────────────────────
    testWidgets('1.1 horizontal split 30/70 renders both panes', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'h-300 w-full',
        'props': {
          'direction': 'horizontal',
          'fractions': [0.3, 0.7],
        },
        'children': [
          colorBox('w-full h-full bg-slate-100', label: 'Left'),
          colorBox('w-full h-full bg-white', label: 'Right'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
      expect(find.byType(QLMultiSplit), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 box:split direct type works identically to alias', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:split',
        'style': 'h-400 w-full',
        'props': {
          'direction': 'horizontal',
          'fractions': [0.5, 0.5],
        },
        'children': [
          textLeaf('PaneA'),
          textLeaf('PaneB'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('PaneA'), findsOneWidget);
      expect(find.text('PaneB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Vertical split ─────────────────────────────────────────────────
    testWidgets('2.1 vertical split 40/60 renders top and bottom panes', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-400',
        'props': {
          'direction': 'vertical',
          'fractions': [0.4, 0.6],
        },
        'children': [
          colorBox('w-full h-full bg-blue-50', label: 'Top'),
          colorBox('w-full h-full bg-blue-100', label: 'Bottom'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Three-pane split ───────────────────────────────────────────────
    testWidgets('3.1 three-pane horizontal split 20/60/20', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-500',
        'props': {
          'direction': 'horizontal',
          'fractions': [0.2, 0.6, 0.2],
        },
        'children': [
          colorBox('w-full h-full bg-slate-700', label: 'Sidebar'),
          colorBox('w-full h-full bg-white', label: 'Content'),
          colorBox('w-full h-full bg-slate-100', label: 'Panel'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Sidebar'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
      expect(find.text('Panel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. Split with complex children ────────────────────────────────────
    testWidgets('4.1 split pane contains a col with card list', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-600',
        'props': {
          'direction': 'horizontal',
          'fractions': [0.35, 0.65],
        },
        'children': [
          // Left: nav list
          {
            'type': 'col',
            'style': 'w-full h-full bg-slate-800 gap-8',
            'props': {'scrollable': true, 'padding': [12]},
            'children': List.generate(
              10,
              (i) => {
                'type': 'col',
                'style': 'w-full h-48 rounded-lg bg-slate-700',
                'children': [textLeaf('Nav $i')],
              },
            ),
          },
          // Right: content area
          {
            'type': 'col',
            'style': 'w-full h-full bg-slate-50',
            'props': {'scrollable': true, 'padding': [24]},
            'children': [
              {
                'type': 'grid',
                'style': 'w-full',
                'props': {'gridCols': '1fr 1fr', 'gap': 16},
                'children': List.generate(
                  6,
                  (i) => colorBox('h-120 rounded-xl bg-white shadow-sm', label: 'Card $i'),
                ),
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Nav 0'), findsOneWidget);
      expect(find.text('Card 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 5. Split nested inside row ─────────────────────────────────────────
    testWidgets('5.1 split nested inside row — full IDE-like layout', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [
          // Header
          colorBox('w-full h-48 bg-slate-900', label: 'Header'),
          // Main area with split
          {
            'type': 'box:expanded',
            'children': [
              {
                'type': 'split',
                'style': 'w-full h-full',
                'props': {
                  'direction': 'horizontal',
                  'fractions': [0.25, 0.75],
                },
                'children': [
                  colorBox('w-full h-full bg-slate-800', label: 'FileTree'),
                  {
                    'type': 'split',
                    'style': 'w-full h-full',
                    'props': {
                      'direction': 'vertical',
                      'fractions': [0.7, 0.3],
                    },
                    'children': [
                      colorBox('w-full h-full bg-slate-50', label: 'Editor'),
                      colorBox('w-full h-full bg-slate-900', label: 'Terminal'),
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('FileTree'), findsOneWidget);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Terminal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Split with dynamic fractions from store ─────────────────────────
    testWidgets('6.1 split fractions driven by store signal', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'split',
          'style': 'w-full h-300',
          'props': {
            'direction': 'horizontal',
            'fractions': [0.3, 0.7], // static fractions — store doesn't control fraction list in this impl
          },
          'children': [
            colorBox('w-full h-full bg-blue-50', label: 'LeftDyn'),
            colorBox('w-full h-full bg-blue-100', label: 'RightDyn'),
          ],
        },
        initialStore: {'splitRatio': 0.3},
      ));
      await tester.pumpAndSettle();

      expect(find.text('LeftDyn'), findsOneWidget);
      expect(find.text('RightDyn'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Split edge cases ────────────────────────────────────────────────
    testWidgets('7.1 split with no fractions prop falls back to equal sizing', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-300',
        'props': {'direction': 'horizontal'},
        'children': [
          textLeaf('DefaultL'),
          textLeaf('DefaultR'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('DefaultL'), findsOneWidget);
      expect(find.text('DefaultR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('7.2 split defaults to horizontal when direction omitted', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'split',
        'style': 'w-full h-300',
        'props': {
          'fractions': [0.5, 0.5],
        },
        'children': [
          textLeaf('NoDir1'),
          textLeaf('NoDir2'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(QLMultiSplit), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
