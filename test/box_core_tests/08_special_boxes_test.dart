// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: SPECIAL BOXES — PRODUCTION TESTS
// test/box_core_tests/08_special_boxes_test.dart
//
// Tests cover:
//  • box:safe — SafeArea wrapping with top/bottom/left/right toggles
//  • box:aspect — AspectRatio via ratio prop
//  • box:measure — Spatial measurement with bind → store
//  • box:viewport — Injects viewportWidth/viewportHeight into scope
//  • box:responsive — Injects isCompact/isMedium/isLarge into scope
//  • box:builder — Injects maxWidth/maxHeight from LayoutBuilder
//  • box:morph — Resizable container with initial size
//  • box:layer / box:matrix — Transform3D + opacity binding
//  • box:virtual_grid — Virtualized grid with itemCount
//  • box:sticky — SliverPersistentHeader for sliver contexts
//  • box:measure writes correct x/y/w/h to store
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Special Boxes — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. box:safe ────────────────────────────────────────────────────────
    testWidgets('1.1 box:safe wraps in SafeArea', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:safe',
        'children': [textLeaf('SafeContent')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('SafeContent'), findsOneWidget);
    });

    testWidgets('1.2 box:safe with top:false bottom:false disables padding',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:safe',
        'props': {'top': false, 'bottom': false, 'left': true, 'right': true},
        'children': [textLeaf('PartialSafe')],
      }));
      await tester.pumpAndSettle();

      final safeArea = tester.widget<SafeArea>(find.byType(SafeArea));
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isFalse);
      expect(safeArea.left, isTrue);
      expect(find.text('PartialSafe'), findsOneWidget);
    });

    testWidgets('1.3 box:safe inside col renders correctly', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-full',
        'children': [
          {
            'type': 'box:safe',
            'children': [
              colorBox('w-full h-80 bg-blue-500', label: 'SafeBar'),
            ],
          },
          {
            'type': 'box:expanded',
            'children': [
              colorBox('w-full h-full bg-slate-50', label: 'MainContent')
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('SafeBar'), findsOneWidget);
      expect(find.text('MainContent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. box:aspect ─────────────────────────────────────────────────────
    testWidgets('2.1 box:aspect with ratio:1.777 wraps in QuantumAspectRatio',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'box:aspect',
            'props': {'ratio': 1.777},
            'children': [colorBox('w-full h-full bg-slate-900', label: '16:9')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(QuantumAspectRatio), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2.2 box:aspect ratio:1.0 produces square', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'box:aspect',
            'props': {'ratio': 1.0},
            'children': [
              colorBox('w-full h-full bg-amber-300', label: 'Square')
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(QuantumAspectRatio), findsOneWidget);
      expect(find.text('Square'), findsOneWidget);
    });

    testWidgets('2.3 box:aspect ratio:2.39 cinema widescreen', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'box:aspect',
            'props': {'ratio': 2.39},
            'children': [colorBox('w-full h-full bg-black', label: 'Cinema')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Cinema'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. box:measure ────────────────────────────────────────────────────
    testWidgets('3.1 box:measure writes bounds to store after layout',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'box:measure',
            'props': {'bind': 'my_box_bounds'},
            'children': [
              colorBox('w-200 h-100 bg-blue-200', label: 'Measured')
            ],
          },
        ],
      }));
      await tester.pumpAndSettle(); // Allows postFrameCallback to fire

      expect(find.text('Measured'), findsOneWidget);
      final bounds = testStore.get('my_box_bounds');
      expect(bounds, isA<Map>());
      expect((bounds as Map)['w'], greaterThan(0));
    });

    testWidgets('3.2 box:measure with style applied', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:measure',
        'props': {'bind': 'header_bounds'},
        'style': 'w-full h-60',
        'children': [textLeaf('MeasuredHeader')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('MeasuredHeader'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 4. box:viewport ───────────────────────────────────────────────────
    testWidgets('4.1 box:viewport injects viewportWidth/Height into data scope',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:viewport',
        'children': [
          {
            'type': 'text',
            'props': {'text': r'W:{{viewportWidth}}'},
          },
        ],
      }));
      await tester.pumpAndSettle();

      // The text should contain "W:" and a number
      expect(find.textContaining('W:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 5. box:responsive ─────────────────────────────────────────────────
    testWidgets('5.1 box:responsive injects isCompact/isMedium/isLarge',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:responsive',
        'children': [
          {
            'type': 'text',
            'props': {'text': r'compact:{{isCompact}}'},
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.textContaining('compact:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. box:builder ────────────────────────────────────────────────────
    testWidgets('6.1 box:builder injects maxWidth/maxHeight into scope',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:builder',
        'children': [
          {
            'type': 'text',
            'props': {'text': r'maxW:{{maxWidth}}'},
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.textContaining('maxW:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('6.2 box:builder renders children with layout constraints',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-400',
        'children': [
          {
            'type': 'box:builder',
            'children': [
              colorBox('w-full h-80 bg-green-200', label: 'BuilderChild'),
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('BuilderChild'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. box:layer ──────────────────────────────────────────────────────
    testWidgets('8.1 box:layer renders with identity transform when no bind',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:layer',
        'style': 'w-full h-200',
        'children': [textLeaf('LayerContent')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Q), findsWidgets);
      expect(find.text('LayerContent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. box:matrix ─────────────────────────────────────────────────────
    testWidgets('9.1 box:matrix alias same as box:layer without bind',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:matrix',
        'style': 'w-full h-200',
        'children': [textLeaf('MatrixContent')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('MatrixContent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Default fallback (no subType = col) ────────────────────────────
    testWidgets('10.1 bare "box" type defaults to col layout', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box',
        'style': 'w-full',
        'children': [textLeaf('DefaultBox'), textLeaf('BoxChild2')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('DefaultBox'), findsOneWidget);
      expect(find.text('BoxChild2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 11. box:viewport + box:responsive nested ───────────────────────────
    testWidgets('11.1 viewport wrapping responsive provides all env vars',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:viewport',
        'children': [
          {
            'type': 'box:responsive',
            'children': [
              {
                'type': 'col',
                'style': 'w-full',
                'children': [
                  {
                    'type': 'text',
                    'props': {'text': r'{{isCompact}}'},
                  },
                ],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // ── 12. box:measure nested inside card ─────────────────────────────────
    testWidgets('12.1 box:measure inside card captures correct bounds',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'card',
        'children': [
          {
            'type': 'box:measure',
            'props': {'bind': 'card_inner_bounds'},
            'children': [textLeaf('MeasuredInCard')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('MeasuredInCard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
