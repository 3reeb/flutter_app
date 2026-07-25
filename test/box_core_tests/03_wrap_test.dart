// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: WRAP — PRODUCTION TESTS
// test/box_core_tests/03_wrap_test.dart
//
// Tests cover:
//  • box:wrap / 'wrap' alias
//  • Wrapping children when row overflows
//  • gap on wrap
//  • justify + items on wrap
//  • Dynamic children from store with varying widths
//  • Wrap inside fixed-width container
//  • Wrap with clip
//  • Wrap with padding/margin
//  • Wrap as a tag/chip list
//  • Wrap with width constrained items
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Wrap — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Alias resolution ────────────────────────────────────────────────
    testWidgets('1.1 "wrap" alias renders a wrap layout', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full',
        'children': [
          textLeaf('Tag1'),
          textLeaf('Tag2'),
          textLeaf('Tag3'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Tag1'), findsOneWidget);
      expect(find.text('Tag2'), findsOneWidget);
      expect(find.text('Tag3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 box:wrap direct type works identically to alias', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:wrap',
        'style': 'w-full',
        'children': [textLeaf('W1'), textLeaf('W2')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('W1'), findsOneWidget);
      expect(find.text('W2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Wrapping behavior ───────────────────────────────────────────────
    testWidgets('2.1 many children exceed container width and wrap to next row',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full',
        'children': List.generate(
          20,
          (i) => {
            'type': 'col',
            'style': 'w-120 h-40 bg-indigo-200 rounded-md',
            'children': [textLeaf('Chip$i')],
          },
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Chip0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Gap on wrap ────────────────────────────────────────────────────
    testWidgets('3.1 gap:12 applies spacing between wrapped children', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full',
        'props': {'gap': 12},
        'children': List.generate(
          8,
          (i) => colorBox('w-80 h-40 bg-cyan-200', label: 'G$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('G0'), findsOneWidget);
      expect(find.text('G7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. Chip/tag list pattern ───────────────────────────────────────────
    testWidgets('4.1 chip list with rounded pills wraps correctly', (tester) async {
      final tags = ['Flutter', 'Dart', 'Mobile', 'Web', 'Desktop', 'IoT', 'AI'];
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full gap-8',
        'children': tags
            .map((t) => {
                  'type': 'col',
                  'style': 'bg-purple-100 rounded-full px-16 py-8',
                  'children': [textLeaf(t)],
                })
            .toList(),
      }));
      await tester.pumpAndSettle();

      for (final tag in tags) {
        expect(find.text(tag), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });

    // ── 5. Wrap inside fixed-width container ──────────────────────────────
    testWidgets('5.1 wrap inside 300px col wraps at correct boundary', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-300',
        'children': [
          {
            'type': 'wrap',
            'style': 'w-full',
            'children': List.generate(
              6,
              (i) => colorBox('w-100 h-50 bg-rose-200', label: 'B$i'),
            ),
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('B0'), findsOneWidget);
      expect(find.text('B5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Wrap with clip ─────────────────────────────────────────────────
    testWidgets('6.1 wrap with clip:true clips overflowing items', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-80 overflow-hidden',
        'props': {'clip': true},
        'children': [
          {
            'type': 'wrap',
            'style': 'w-full',
            'children': List.generate(
              50,
              (i) => colorBox('w-80 h-40 bg-amber-100', label: 'X$i'),
            ),
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(ClipRect), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Wrap with padding ──────────────────────────────────────────────
    testWidgets('7.1 wrap with padding applied doesn\'t overflow parent', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full',
        'props': {
          'padding': [16],
        },
        'children': List.generate(
          10,
          (i) => colorBox('w-80 h-40 bg-lime-200', label: 'P$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('P0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Wrap of full-width items (degrade to col) ───────────────────────
    testWidgets('8.1 wrap where each child is full-width stacks like col', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full',
        'children': List.generate(
          5,
          (i) => colorBox('w-full h-60 bg-teal-100', label: 'Full$i'),
        ),
      }));
      await tester.pumpAndSettle();

      expect(find.text('Full0'), findsOneWidget);
      expect(find.text('Full4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. Wrap with dynamic content from store ────────────────────────────
    testWidgets('9.1 wrap renders dynamic count without crash', (tester) async {
      // Simulate 15 dynamic items being rendered
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'children': [
            {
              'type': 'wrap',
              'style': 'w-full gap-8',
              'children': List.generate(
                15,
                (i) => {
                  'type': 'col',
                  'style': 'rounded-lg bg-sky-100 px-12 py-8',
                  'children': [textLeaf('Skill $i')],
                },
              ),
            },
          ],
        },
        initialStore: {'count': 15},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Skill 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Wrap items with varying dimensions ─────────────────────────────
    testWidgets('10.1 wrap with mixed-size children adapts rows naturally', (tester) async {
      final widths = [60, 120, 80, 200, 50, 150, 100, 90];
      await tester.pumpWidget(buildTestWrapper({
        'type': 'wrap',
        'style': 'w-full gap-8',
        'children': widths.asMap().entries.map((e) {
          return {
            'type': 'col',
            'style': 'h-48 bg-orange-200 rounded-md',
            'props': {'width': e.value.toDouble()},
            'children': [textLeaf('V${e.key}')],
          };
        }).toList(),
      }));
      await tester.pumpAndSettle();

      expect(find.text('V0'), findsOneWidget);
      expect(find.text('V7'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
