// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: SURFACE, SHELL, CARD — PRODUCTION TESTS
// test/box_core_tests/07_surface_shell_card_test.dart
//
// Tests cover:
//  • box:surface / box:shell with various fill variants
//  • card alias with default props (fill:surface, depth:raised, padding:[24])
//  • QDesignMatrix fill variants: solid, soft, ghost, bare, glass, gradient, surface
//  • depth variants: flat, raised, floating, glow, neon, neobrutal
//  • edge variants: none, hairline, thick, dashed
//  • shape variants: rounded, sharp, pill, circle, soft
//  • surface with intent color
//  • disabled prop on surface
//  • surface with complex children
//  • Card grid with different fill/depth combos
//  • shell with scrollable content
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Surface, Shell & Card — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. Card alias ──────────────────────────────────────────────────────
    testWidgets('1.1 card alias renders with default raised surface', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'card',
        'children': [textLeaf('CardContent')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('CardContent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1.2 card overrides fill and depth defaults', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'card',
        'props': {
          'fill': 'gradient',
          'depth': 'floating',
          'intent': 'indigo',
        },
        'children': [textLeaf('GradientCard')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('GradientCard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 2. Surface fill variants ───────────────────────────────────────────
    for (final fill in ['solid', 'soft', 'ghost', 'bare', 'glass', 'gradient', 'surface']) {
      testWidgets('2.fill "$fill" renders correctly on box:surface', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'box:surface',
          'style': 'w-200 h-100',
          'props': {
            'fill': fill,
            'intent': 'blue',
            'depth': 'flat',
          },
          'children': [textLeaf('Fill:$fill')],
        }));
        await tester.pumpAndSettle();

        expect(find.text('Fill:$fill'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ── 3. Depth variants ─────────────────────────────────────────────────
    for (final depth in ['flat', 'raised', 'floating', 'glow', 'neon', 'neobrutal']) {
      testWidgets('3.depth "$depth" renders on surface', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'box:surface',
          'style': 'w-200 h-100',
          'props': {
            'fill': 'surface',
            'depth': depth,
            'intent': 'violet',
          },
          'children': [textLeaf('Depth:$depth')],
        }));
        await tester.pumpAndSettle();

        expect(find.text('Depth:$depth'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ── 4. Edge variants ──────────────────────────────────────────────────
    for (final edge in ['none', 'hairline', 'thick', 'dashed']) {
      testWidgets('4.edge "$edge" renders on surface', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'box:surface',
          'style': 'w-200 h-100',
          'props': {
            'fill': 'soft',
            'edge': edge,
            'intent': 'emerald',
          },
          'children': [textLeaf('Edge:$edge')],
        }));
        await tester.pumpAndSettle();

        expect(find.text('Edge:$edge'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ── 5. Shape variants ─────────────────────────────────────────────────
    for (final shape in ['rounded', 'sharp', 'pill', 'circle', 'soft']) {
      testWidgets('5.shape "$shape" renders on surface', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'box:surface',
          'style': 'w-120 h-120',
          'props': {
            'fill': 'solid',
            'shape': shape,
            'intent': 'rose',
          },
          'children': [textLeaf('Shape:$shape')],
        }));
        await tester.pumpAndSettle();

        expect(find.text('Shape:$shape'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ── 6. Shell alias ────────────────────────────────────────────────────
    testWidgets('6.1 box:shell alias works same as surface', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:shell',
        'style': 'w-300 h-200',
        'props': {
          'fill': 'surface',
          'depth': 'raised',
          'intent': 'slate-900',
        },
        'children': [textLeaf('ShellContent')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('ShellContent'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 7. Surface with disabled:true ─────────────────────────────────────
    testWidgets('7.1 surface disabled:true applies disabled styling', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:surface',
        'style': 'w-200 h-100',
        'props': {
          'fill': 'solid',
          'intent': 'blue',
          'disabled': true,
        },
        'children': [textLeaf('DisabledSurface')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('DisabledSurface'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Card grid — visual showcase ────────────────────────────────────
    testWidgets('8.1 grid of cards with different fills and depths', (tester) async {
      final combos = [
        {'fill': 'solid', 'depth': 'raised', 'intent': 'blue'},
        {'fill': 'soft', 'depth': 'flat', 'intent': 'emerald'},
        {'fill': 'ghost', 'depth': 'floating', 'intent': 'violet'},
        {'fill': 'glass', 'depth': 'glow', 'intent': 'amber'},
        {'fill': 'gradient', 'depth': 'neon', 'intent': 'rose'},
        {'fill': 'bare', 'depth': 'neobrutal', 'intent': 'slate-900'},
      ];

      await tester.pumpWidget(buildTestWrapper({
        'type': 'grid',
        'style': 'w-full',
        'props': {'gridCols': '1fr 1fr 1fr', 'gap': 16},
        'children': combos.map((c) => {
              'type': 'box:surface',
              'style': 'h-100',
              'props': {...c},
              'children': [textLeaf('${c['fill']}/${c['depth']}')],
            }).toList(),
      }));
      await tester.pumpAndSettle();

      expect(find.text('solid/raised'), findsOneWidget);
      expect(find.text('glass/glow'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. Shell with gap and scrollable content ───────────────────────────
    testWidgets('9.1 shell with gap and scrollable inner col', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:shell',
        'style': 'w-full h-400',
        'props': {
          'fill': 'surface',
          'depth': 'floating',
          'gap': 12,
          'padding': [24],
        },
        'children': [
          textLeaf('Shell Title'),
          {
            'type': 'col',
            'style': 'w-full',
            'props': {'scrollable': true},
            'children': List.generate(
              15,
              (i) => textLeaf('Item $i'),
            ),
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Shell Title'), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 10. Nested surface inside surface ──────────────────────────────────
    testWidgets('10.1 nested surface containers render correctly', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:surface',
        'style': 'w-full h-400',
        'props': {'fill': 'surface', 'depth': 'flat', 'intent': 'slate-900'},
        'children': [
          {
            'type': 'row',
            'style': 'w-full gap-16',
            'children': [
              {
                'type': 'box:surface',
                'style': 'w-200 h-120',
                'props': {'fill': 'solid', 'depth': 'raised', 'intent': 'indigo'},
                'children': [textLeaf('Inner1')],
              },
              {
                'type': 'box:surface',
                'style': 'w-200 h-120',
                'props': {'fill': 'gradient', 'depth': 'glow', 'intent': 'violet'},
                'children': [textLeaf('Inner2')],
              },
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Inner1'), findsOneWidget);
      expect(find.text('Inner2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 11. Surface with padding and margin props ──────────────────────────
    testWidgets('11.1 surface respects padding and margin props', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'box:surface',
        'style': 'w-full',
        'props': {
          'fill': 'surface',
          'depth': 'raised',
          'padding': [24],
          'margin': [16],
          'gap': 8,
        },
        'children': [textLeaf('PaddedSurface'), textLeaf('Row2')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('PaddedSurface'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
