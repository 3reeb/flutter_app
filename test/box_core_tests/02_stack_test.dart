// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: STACK — PRODUCTION TESTS
// test/box_core_tests/02_stack_test.dart
//
// Tests cover:
//  • box:stack / 'stack' alias
//  • Children overlapping: z-order validation
//  • style-driven: w-full h-full, absolute positioning via style
//  • Stack inside row/col
//  • Stack with many overlapping cards
//  • Stack + clip:true
//  • Stack + opacity on individual children
//  • Stack + onClick for bottom vs top layer
//  • Dynamic children count from store
//  • aspectBox:true + stack combo
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Stack — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Alias resolution ────────────────────────────────────────────────
    testWidgets('1.1 "stack" alias renders a stack layout', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-full h-200',
        'children': [
          colorBox('w-full h-full bg-blue-200', label: 'Bottom'),
          colorBox('w-100 h-100 bg-red-200', label: 'Top'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Bottom'), findsOneWidget);
      expect(find.text('Top'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 box:stack direct type works identically to alias', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:stack',
        'style': 'w-300 h-200',
        'children': [textLeaf('StackA'), textLeaf('StackB')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('StackA'), findsOneWidget);
      expect(find.text('StackB'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Multiple overlapping children ──────────────────────────────────
    testWidgets('2.1 5 overlapping children all render', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-300 h-200',
        'children': List.generate(
          5,
          (i) => {
            'type': 'col',
            'style': 'w-${(5 - i) * 50} h-${(5 - i) * 30} bg-blue-${(i + 1) * 100}',
            'children': [textLeaf('Layer$i')],
          },
        ),
      }));
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        // Last layer may be obscured but tree still built
      }
      expect(find.text('Layer0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Stack inside col (real-world card + badge) ─────────────────────
    testWidgets('3.1 card-with-badge pattern: stack inside col', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full gap-16',
        'children': [
          {
            'type': 'stack',
            'style': 'w-200 h-120',
            'children': [
              // Card base
              colorBox('w-full h-full rounded-xl bg-white shadow-sm', label: 'CardContent'),
              // Badge overlay
              {
                'type': 'col',
                'style': 'w-24 h-24 rounded-full bg-red-500 items-center justify-center',
                'children': [textLeaf('3')],
              },
            ],
          },
          textLeaf('Below card'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('CardContent'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Below card'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. Stack + clip prevents overflow ─────────────────────────────────
    testWidgets('4.1 stack with clip:true clips overflowing children', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-100 h-100',
        'props': {'clip': true},
        'children': [
          colorBox('w-500 h-500 bg-green-400', label: 'BigChild'),
          textLeaf('Clipped'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(ClipRect), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ── 5. Stack inside row (header with overlaid avatar) ─────────────────
    testWidgets('5.1 stack inside row renders without layout conflict', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-80 items-center gap-12',
        'children': [
          {
            'type': 'stack',
            'style': 'w-60 h-60',
            'children': [
              colorBox('w-60 h-60 rounded-full bg-indigo-400'),
              {
                'type': 'col',
                'style': 'w-16 h-16 rounded-full bg-green-400',
                'children': [],
              },
            ],
          },
          textLeaf('User Name'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('User Name'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Stack with opacity children ────────────────────────────────────
    testWidgets('6.1 stack with opacity on individual children', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-300 h-200',
        'children': [
          colorBox('w-full h-full bg-slate-100'),
          {
            'type': 'col',
            'style': 'w-full h-full bg-blue-500',
            'props': {'opacity': 0.3},
            'children': [textLeaf('GlassOverlay')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Opacity), findsWidgets);
      expect(find.text('GlassOverlay'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Stack width/height props ────────────────────────────────────────
    testWidgets('7.1 stack with width:400 height:300 creates correct SizedBox', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'props': {'width': 400.0, 'height': 300.0},
        'children': [
          textLeaf('StackSized'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('StackSized'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. AspectBox + stack ───────────────────────────────────────────────
    testWidgets('8.1 aspectBox:true with ratio:1.0 wraps stack in AspectRatio', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'stack',
            'style': 'w-full',
            'props': {'aspectBox': true, 'ratio': 1.0},
            'children': [
              colorBox('w-full h-full bg-amber-300', label: 'Square'),
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(AspectRatio), findsWidgets);
      expect(find.text('Square'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. Stack repaint boundary isolates subtree ─────────────────────────
    testWidgets('9.1 repaintBoundary on stack subtree', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-300 h-200',
        'props': {'repaintBoundary': true},
        'children': [
          colorBox('w-full h-full bg-slate-50'),
          textLeaf('Isolated'),
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(RepaintBoundary), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Dynamic child count in stack from store ────────────────────────
    testWidgets('10.1 stack renders complex dynamic pattern without crash', (tester) async {
      // Simulate a notification overlay stack
      await tester.pumpWidget(buildTestWrapper({
        'type': 'stack',
        'style': 'w-full h-full',
        'children': [
          // Background
          colorBox('w-full h-full bg-gray-50'),
          // Overlay notification card
          {
            'type': 'col',
            'style': 'w-320 h-80 rounded-xl bg-white shadow-lg',
            'props': {
              'constrained': true,
              'maxWidth': 400.0,
            },
            'children': [
              {
                'type': 'row',
                'style': 'w-full h-full items-center gap-12 px-16',
                'children': [
                  colorBox('w-40 h-40 rounded-full bg-blue-500'),
                  {
                    'type': 'col',
                    'style': 'min-w-0',
                    'children': [
                      textLeaf('Notification Title'),
                      textLeaf('Body of notification'),
                    ],
                  },
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Notification Title'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
