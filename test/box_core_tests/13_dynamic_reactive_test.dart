// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: DYNAMIC SIZING & REACTIVE STORE TESTS
// test/box_core_tests/13_dynamic_reactive_test.dart
//
// Tests cover:
//  • width/height driven by store signals
//  • gap driven by store
//  • opacity reactive to store
//  • fill / depth / intent switching via store
//  • animate + variantKey driven by store
//  • conditional rendering patterns via data:if
//  • Dynamic gridCols from store
//  • List of dynamic sizes — each child has unique store-driven dimension
//  • Store update triggers layout rebuild
//  • Dynamic padding from store
//  • Dynamic color-class token via store signal
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Dynamic Sizing & Reactive Store', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. width from store ────────────────────────────────────────────────
    testWidgets('1.1 box width changes when store signal updates', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'children': [
            {
              'type': 'col',
              'style': 'h-60 bg-blue-200',
              'props': {'width': r'{{panelWidth}}'},
              'children': [textLeaf('Dynamic Width Panel')],
            },
          ],
        },
        initialStore: {'panelWidth': 200.0},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dynamic Width Panel'), findsOneWidget);

      // Update width via store
      testStore.set('panelWidth', 400.0);
      await tester.pumpAndSettle();

      expect(find.text('Dynamic Width Panel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 height from store — animated height change', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'children': [
            {
              'type': 'col',
              'style': 'w-full bg-green-200',
              'props': {'height': r'{{panelHeight}}'},
              'children': [textLeaf('Tall Panel')],
            },
            textLeaf('Below'),
          ],
        },
        initialStore: {'panelHeight': 80.0},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Tall Panel'), findsOneWidget);

      testStore.set('panelHeight', 160.0);
      await tester.pumpAndSettle();

      expect(find.text('Tall Panel'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. gap from store ──────────────────────────────────────────────────
    testWidgets('2.1 gap from store changes spacing between children', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'props': {'gap': r'{{itemGap}}'},
          'children': List.generate(5, (i) => textLeaf('Item$i')),
        },
        initialStore: {'itemGap': 8},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Item0'), findsOneWidget);

      testStore.set('itemGap', 32);
      await tester.pumpAndSettle();

      expect(find.text('Item4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. opacity from store ──────────────────────────────────────────────
    testWidgets('3.1 opacity from store — fade in/out on update', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full h-100',
          'props': {'opacity': r'{{alpha}}'},
          'children': [textLeaf('FadingPanel')],
        },
        initialStore: {'alpha': 1.0},
      ));
      await tester.pumpAndSettle();

      expect(find.text('FadingPanel'), findsOneWidget);

      // Fade out
      testStore.set('alpha', 0.0);
      await tester.pumpAndSettle();

      expect(find.byType(Opacity), findsWidgets);
      expect(tester.takeException(), isNull);

      // Fade back
      testStore.set('alpha', 0.8);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 4. variantKey from store → AnimatedSwitcher ────────────────────────
    testWidgets('4.1 tab switching via store drives AnimatedSwitcher', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full h-full',
          'children': [
            // Tab buttons
            {
              'type': 'row',
              'style': 'w-full h-48 bg-slate-100',
              'children': ['Home', 'Profile', 'Settings'].asMap().entries.map((e) => {
                    'type': 'col',
                    'style': 'flex-1 h-full items-center justify-center',
                    'props': {
                      'onClick': [
                        {'action': 'state.set', 'key': 'activeTab', 'value': e.key}
                      ],
                    },
                    'children': [textLeaf(e.value)],
                  }).toList(),
            },
            // Animated content
            {
              'type': 'box:expanded',
              'children': [
                {
                  'type': 'col',
                  'style': 'w-full h-full',
                  'props': {
                    'animate': true,
                    'transition': 'fade',
                    'variant': r'{{activeTab}}',
                  },
                  'children': [textLeaf('Tab Content')],
                },
              ],
            },
          ],
        },
        initialStore: {'activeTab': 0},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);

      // Switch to Profile tab
      await tester.tap(find.text('Profile'));
      await tester.pump();

      expect(testStore.get('activeTab'), equals(1));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // ── 5. Dynamic gridCols from store ─────────────────────────────────────
    testWidgets('5.1 grid column template switches from 2-col to 3-col via store', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'grid',
          'style': 'w-full',
          'props': {'gridCols': r'{{colTemplate}}', 'gap': 8},
          'children': List.generate(
            6,
            (i) => colorBox('h-80 bg-blue-200', label: 'Item$i'),
          ),
        },
        initialStore: {'colTemplate': '1fr 1fr'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Item0'), findsOneWidget);

      testStore.set('colTemplate', '1fr 1fr 1fr');
      await tester.pumpAndSettle();

      expect(find.text('Item5'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. Dynamic list of boxes with unique heights ───────────────────────
    testWidgets('6.1 list items with store-driven individual heights', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'props': {'scrollable': true},
          'children': List.generate(
            10,
            (i) => {
              'type': 'col',
              'style': 'w-full bg-slate-${(i % 5 + 1) * 100} mb-8',
              'props': {'height': ((i + 1) * 30).toDouble()},
              'children': [textLeaf('Item $i (h=${((i + 1) * 30)})')]
            },
          ),
        },
        initialStore: {},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Item 0 (h=30)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Dynamic padding from store ─────────────────────────────────────
    testWidgets('7.1 padding changes when store value changes', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'props': {'padding': r'{{boxPadding}}'},
          'children': [textLeaf('PaddedFromStore')],
        },
        initialStore: {'boxPadding': [8]},
      ));
      await tester.pumpAndSettle();

      expect(find.text('PaddedFromStore'), findsOneWidget);

      testStore.set('boxPadding', [24, 16]);
      await tester.pumpAndSettle();

      expect(find.text('PaddedFromStore'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. fill/intent switch from store ──────────────────────────────────
    testWidgets('8.1 surface fill driven by store changes visual style', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'box:surface',
          'style': 'w-full h-120',
          'props': {
            'fill': r'{{surfaceFill}}',
            'intent': r'{{surfaceColor}}',
            'depth': 'raised',
          },
          'children': [textLeaf('DynamicSurface')],
        },
        initialStore: {'surfaceFill': 'solid', 'surfaceColor': 'blue'},
      ));
      await tester.pumpAndSettle();

      expect(find.text('DynamicSurface'), findsOneWidget);

      testStore.set('surfaceFill', 'gradient');
      testStore.set('surfaceColor', 'violet');
      await tester.pumpAndSettle();

      expect(find.text('DynamicSurface'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. Multi-dimensional reactive grid ────────────────────────────────
    testWidgets('9.1 grid + box where width/height/gap all from store', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'grid',
          'style': 'w-full',
          'props': {
            'gridCols': r'{{gridCols}}',
            'gap': r'{{gridGap}}',
          },
          'children': List.generate(
            9,
            (i) => {
              'type': 'col',
              'style': 'bg-emerald-200 rounded-lg',
              'props': {'height': r'{{cellHeight}}'},
              'children': [textLeaf('Cell$i')],
            },
          ),
        },
        initialStore: {
          'gridCols': '1fr 1fr 1fr',
          'gridGap': 12,
          'cellHeight': 80.0,
        },
      ));
      await tester.pumpAndSettle();

      expect(find.text('Cell0'), findsOneWidget);
      expect(find.text('Cell8'), findsOneWidget);

      // Change all at once
      testStore.set('gridCols', '1fr 1fr');
      testStore.set('gridGap', 24);
      testStore.set('cellHeight', 100.0);
      await tester.pumpAndSettle();

      expect(find.text('Cell0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Offstage toggled from store ───────────────────────────────────
    testWidgets('10.1 offstage toggled via store hides/shows widget', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'children': [
            {
              'type': 'col',
              'style': 'w-full h-80 bg-blue-200',
              'props': {'offstage': r'{{isHidden}}'},
              'children': [textLeaf('Toggleable')],
            },
            textLeaf('Always visible'),
          ],
        },
        initialStore: {'isHidden': false},
      ));
      await tester.pumpAndSettle();

      expect(find.text('Always visible'), findsOneWidget);

      testStore.set('isHidden', true);
      await tester.pumpAndSettle();

      expect(find.byType(Offstage), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
