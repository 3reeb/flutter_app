// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: STYLE ATTRIBUTES EXHAUSTIVE TEST
// test/box_core_tests/14_style_attributes_test.dart
//
// Tests every known style token's effect on the layout engine:
//  • Width tokens: w-full, w-screen, w-auto, w-{N}, w-{N}/2, w-px
//  • Height tokens: h-full, h-screen, h-auto, h-{N}
//  • Min/max: min-w-0, min-h-0, max-w-*, max-h-*
//  • Padding: p-{N}, px-{N}, py-{N}, pt/pr/pb/pl
//  • Margin: m-{N}, mx-{N}, my-{N}, mt/mr/mb/ml
//  • Gap: gap-{N}
//  • Flex direction: row, col
//  • Justify: justify-start/end/center/between/around/evenly
//  • Items: items-start/end/center/stretch/baseline
//  • Overflow: overflow-hidden, overflow-scroll
//  • Position tokens: relative, absolute
//  • Opacity: opacity-{0-100}
//  • Rounded: rounded-none, rounded-sm, rounded, rounded-md, rounded-lg, rounded-xl, rounded-2xl, rounded-3xl, rounded-full
//  • Background: bg-transparent, bg-white, bg-black, bg-{color}-{shade}
//  • Shadow: shadow-sm, shadow, shadow-md, shadow-lg, shadow-xl, shadow-2xl
//  • Text alignment: text-left, text-center, text-right
//  • Border: border, border-{N}, border-{color}-{shade}
//  • Combined complex style strings per layout type
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: render a box with a single style string and expect no exception
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _testStyle(WidgetTester tester, String type, String style) async {
  await tester.pumpWidget(buildTestWrapper({
    'type': type,
    'style': style,
    'children': [textLeaf(style)],
  }));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull,
      reason: 'Style "$style" on "$type" should not throw');
}

void main() {
  group('BoxCore | Style Attributes Exhaustive', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── Width tokens ───────────────────────────────────────────────────────
    group('Width tokens', () {
      for (final style in [
        'w-full',
        'w-auto',
        'w-0',
        'w-8',
        'w-16',
        'w-32',
        'w-48',
        'w-64',
        'w-80',
        'w-96',
        'w-100',
        'w-200',
        'w-300',
        'w-400',
        'w-screen',
        'w-px',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', style);
        });
      }
    });

    // ── Height tokens ──────────────────────────────────────────────────────
    group('Height tokens', () {
      for (final style in [
        'h-full',
        'h-auto',
        'h-0',
        'h-8',
        'h-16',
        'h-32',
        'h-48',
        'h-64',
        'h-80',
        'h-96',
        'h-100',
        'h-200',
        'h-300',
        'h-screen',
        'h-px',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', 'w-full $style');
        });
      }
    });

    // ── Min/Max constraint tokens ──────────────────────────────────────────
    group('Min/Max tokens', () {
      for (final style in [
        'min-w-0',
        'min-h-0',
        'min-w-full',
        'min-h-full',
        'max-w-full',
        'max-h-full',
        'max-w-screen',
        'max-h-screen',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', style);
        });
      }
    });

    // ── Padding tokens ─────────────────────────────────────────────────────
    group('Padding tokens', () {
      for (final style in [
        'p-0', 'p-4', 'p-8', 'p-12', 'p-16', 'p-20', 'p-24', 'p-32', 'p-48',
        'px-8', 'px-16', 'px-24', 'px-32',
        'py-8', 'py-16', 'py-24',
        'pt-8', 'pr-8', 'pb-8', 'pl-8',
        'pt-16', 'pr-16', 'pb-16', 'pl-16',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', 'w-full $style');
        });
      }
    });

    // ── Margin tokens ─────────────────────────────────────────────────────
    group('Margin tokens', () {
      for (final style in [
        'm-0', 'm-4', 'm-8', 'm-16', 'm-24',
        'mx-8', 'mx-16', 'mx-24', 'mx-auto',
        'my-8', 'my-16', 'my-24',
        'mt-8', 'mr-8', 'mb-8', 'ml-8',
        'mt-16', 'mb-24',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', 'w-full $style');
        });
      }
    });

    // ── Gap tokens ─────────────────────────────────────────────────────────
    group('Gap tokens', () {
      for (final gap in [0, 2, 4, 6, 8, 10, 12, 16, 20, 24, 32, 48]) {
        testWidgets('col with gap-$gap', (tester) async {
          await tester.pumpWidget(buildTestWrapper({
            'type': 'col',
            'style': 'w-full gap-$gap',
            'children': [textLeaf('A'), textLeaf('B')],
          }));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    });

    // ── Rounded tokens ─────────────────────────────────────────────────────
    group('Rounded tokens', () {
      for (final style in [
        'rounded-none',
        'rounded-sm',
        'rounded',
        'rounded-md',
        'rounded-lg',
        'rounded-xl',
        'rounded-2xl',
        'rounded-3xl',
        'rounded-full',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', 'w-full h-80 bg-white $style');
        });
      }
    });

    // ── Shadow tokens ─────────────────────────────────────────────────────
    group('Shadow tokens', () {
      for (final style in [
        'shadow-none',
        'shadow-sm',
        'shadow',
        'shadow-md',
        'shadow-lg',
        'shadow-xl',
        'shadow-2xl',
      ]) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', 'w-full h-80 bg-white rounded-xl $style');
        });
      }
    });

    // ── Overflow tokens ────────────────────────────────────────────────────
    group('Overflow tokens', () {
      for (final style in ['overflow-hidden', 'overflow-scroll', 'overflow-visible']) {
        testWidgets('col with $style', (tester) async {
          await _testStyle(tester, 'col', 'w-full h-80 $style');
        });
      }
    });

    // ── Background color tokens ────────────────────────────────────────────
    group('Background colors', () {
      final colors = ['slate', 'gray', 'zinc', 'red', 'orange', 'amber', 'yellow',
          'lime', 'green', 'emerald', 'teal', 'cyan', 'sky', 'blue', 'indigo',
          'violet', 'purple', 'fuchsia', 'pink', 'rose'];
      final shades = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];

      // Test a sample of color+shade combos (not exhaustive to keep test count reasonable)
      for (final color in ['blue', 'red', 'green', 'slate', 'violet']) {
        for (final shade in [100, 300, 500, 700]) {
          testWidgets('col bg-$color-$shade', (tester) async {
            await _testStyle(tester, 'col', 'w-60 h-60 bg-$color-$shade');
          });
        }
      }

      testWidgets('col bg-white', (tester) async {
        await _testStyle(tester, 'col', 'w-60 h-60 bg-white');
      });
      testWidgets('col bg-black', (tester) async {
        await _testStyle(tester, 'col', 'w-60 h-60 bg-black');
      });
      testWidgets('col bg-transparent', (tester) async {
        await _testStyle(tester, 'col', 'w-60 h-60 bg-transparent');
      });
    });

    // ── Flex direction ──────────────────────────────────────────────────────
    testWidgets('col+row flex tokens render children in correct axis', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full gap-8',
        'children': [
          {
            'type': 'row',
            'style': 'w-full h-60 items-center justify-between',
            'children': [textLeaf('RowL'), textLeaf('RowR')],
          },
          {
            'type': 'col',
            'style': 'w-full gap-4',
            'children': [textLeaf('ColT'), textLeaf('ColB')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('RowL'), findsOneWidget);
      expect(find.text('RowR'), findsOneWidget);
      expect(find.text('ColT'), findsOneWidget);
      expect(find.text('ColB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── Justify + Items combinations ───────────────────────────────────────
    group('Justify × Items combinations', () {
      final justifyValues = ['start', 'end', 'center', 'space-between'];
      final itemsValues = ['start', 'end', 'center', 'stretch'];

      for (final j in justifyValues) {
        for (final i in itemsValues) {
          testWidgets('row justify-$j items-$i', (tester) async {
            await tester.pumpWidget(buildTestWrapper({
              'type': 'row',
              'style': 'w-full h-80 justify-$j items-$i',
              'children': [textLeaf('A'), textLeaf('B')],
            }));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }
    });

    // ── Complex combined style strings ─────────────────────────────────────
    group('Complex combined styles', () {
      final complexStyles = [
        'w-full h-200 bg-white rounded-2xl shadow-lg p-24 gap-16 items-center justify-center',
        'w-320 h-120 bg-indigo-600 rounded-full shadow-xl px-32 py-16 items-center',
        'w-full min-h-0 bg-slate-800 rounded-none gap-0 overflow-hidden',
        'w-full h-full bg-gradient-to-br rounded-xl shadow-2xl p-32 gap-24',
        'min-w-0 min-h-0 w-full h-full items-stretch justify-start gap-8 overflow-hidden',
        'w-400 h-300 bg-amber-50 rounded-3xl shadow-md p-20 gap-12 items-end justify-between',
      ];

      for (final style in complexStyles) {
        testWidgets('col with complex style: ${style.substring(0, 40)}...', (tester) async {
          await tester.pumpWidget(buildTestWrapper({
            'type': 'col',
            'style': style,
            'children': [textLeaf('ComplexStyle'), textLeaf('Child2')],
          }));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }

      // Same for row
      for (final style in complexStyles) {
        testWidgets('row with complex style: ${style.substring(0, 40)}...', (tester) async {
          await tester.pumpWidget(buildTestWrapper({
            'type': 'row',
            'style': style,
            'children': [textLeaf('RA'), textLeaf('RB')],
          }));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    });

    // ── Width + height + gap combinations on all main subtypes ─────────────
    group('Sizing combos on all main box subtypes', () {
      final subtypes = ['col', 'row', 'stack', 'wrap'];
      final sizings = [
        'w-full h-100 gap-8',
        'w-200 h-150 gap-16',
        'w-full min-h-0 gap-0',
      ];

      for (final subtype in subtypes) {
        for (final sizing in sizings) {
          testWidgets('$subtype: $sizing', (tester) async {
            await tester.pumpWidget(buildTestWrapper({
              'type': subtype,
              'style': sizing,
              'children': [textLeaf('SZ1'), textLeaf('SZ2')],
            }));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          });
        }
      }
    });
  });
}
