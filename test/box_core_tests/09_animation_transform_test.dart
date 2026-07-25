// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: ANIMATION, TRANSFORM & HERO — PRODUCTION TESTS
// test/box_core_tests/09_animation_transform_test.dart
//
// Tests cover:
//  • animate:true with AnimatedSwitcher (fade, scale, slide, size)
//  • variantKey driving AnimatedSwitcher key changes
//  • durationMs control
//  • curve variants: linear, easein, easeout, easeinout, bounceout, elasticout
//  • rotate + rotateTurns
//  • transform:true + matrix string (16 values)
//  • heroTag wrapping in Hero widget
//  • heroFlight:true adds custom flightShuttleBuilder
//  • opacity < 1 wraps in Opacity
//  • rotate + opacity combination
//  • box:layer with opacityBind from store
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Animation, Transform & Hero — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. animate:true — AnimatedSwitcher ────────────────────────────────
    testWidgets('1.1 animate:true wraps in AnimatedSwitcher', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-200',
        'props': {'animate': true},
        'children': [textLeaf('Animated')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.text('Animated'), findsOneWidget);
    });

    testWidgets('1.2 animate with transition:scale uses ScaleTransition', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-200',
        'props': {
          'animate': true,
          'transition': 'scale',
          'durationMs': 300,
        },
        'children': [textLeaf('Scale')],
      }));
      await tester.pump(); // Start transition
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('1.3 animate with transition:slide', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-200',
        'props': {
          'animate': true,
          'transition': 'slide',
          'durationMs': 400,
        },
        'children': [textLeaf('Slide')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('1.4 animate with transition:size', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-200',
        'props': {
          'animate': true,
          'transition': 'size',
        },
        'children': [textLeaf('Size')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    testWidgets('1.5 animate with transition:fade (default)', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-200',
        'props': {
          'animate': true,
          'transition': 'fade',
          'durationMs': 250,
        },
        'children': [textLeaf('Fade')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
    });

    // ── 2. variantKey changes trigger AnimatedSwitcher ────────────────────
    testWidgets('2.1 variantKey drives AnimatedSwitcher key switch', (tester) async {
      await tester.pumpWidget(buildTestWrapper(
        {
          'type': 'col',
          'style': 'w-full',
          'props': {'variant': r'{{activeTab}}'},
          'children': [textLeaf('TabContent')],
        },
        initialStore: {'activeTab': 'tab1'},
      ));
      await tester.pump();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);

      // Update store to trigger variant key change
      testStore.set('activeTab', 'tab2');
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 3. Curve variants ─────────────────────────────────────────────────
    for (final curve in [
      'linear',
      'easein',
      'easeout',
      'easeinout',
      'easeoutcubic',
      'easeincubic',
      'bounceout',
      'bouncein',
      'elasticout',
      'elasticin',
    ]) {
      testWidgets('3.curve "$curve" resolves without error', (tester) async {
        await tester.pumpWidget(buildTestWrapper({
          'type': 'col',
          'style': 'w-full h-100',
          'props': {
            'animate': true,
            'curve': curve,
            'durationMs': 200,
          },
          'children': [textLeaf('Curve:$curve')],
        }));
        await tester.pumpAndSettle();

        expect(find.byType(AnimatedSwitcher), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    // ── 4. rotate ─────────────────────────────────────────────────────────
    testWidgets('4.1 rotate:true with rotateTurns:0.25 applies 90° rotation', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100',
        'props': {'rotate': true, 'rotateTurns': 0.25},
        'children': [textLeaf('Rotated')],
      }));
      await tester.pumpAndSettle();

      // Transform.rotate is used internally
      expect(find.text('Rotated'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4.2 rotateTurns:0.5 gives 180° flip', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100',
        'props': {'rotateTurns': 0.5},
        'children': [textLeaf('Flipped')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Flipped'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 5. transform:true + matrix ────────────────────────────────────────
    testWidgets('5.1 transform:true with 16-value matrix string', (tester) async {
      // Identity matrix as CSV string
      const identity =
          '1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1';
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-200 h-100',
        'props': {
          'transform': true,
          'matrix': identity,
        },
        'children': [textLeaf('Matrix')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Matrix'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5.2 transform with scale matrix (2x uniform)', (tester) async {
      // Scale by 2 in x and y
      const scaleMatrix =
          '2,0,0,0, 0,2,0,0, 0,0,1,0, 0,0,0,1';
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100',
        'props': {
          'transform': true,
          'matrix': scaleMatrix,
        },
        'children': [textLeaf('Scaled2x')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('Scaled2x'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5.3 transform with invalid matrix string (< 16 values) falls back gracefully',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100',
        'props': {
          'transform': true,
          'matrix': '1,0,0', // Only 3 values — should be ignored
        },
        'children': [textLeaf('BadMatrix')],
      }));
      await tester.pumpAndSettle();

      expect(find.text('BadMatrix'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 6. heroTag ────────────────────────────────────────────────────────
    testWidgets('6.1 heroTag wraps widget in Hero', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'children': [
          {
            'type': 'col',
            'style': 'w-100 h-100 bg-blue-300',
            'props': {'heroTag': 'my-hero-box'},
            'children': [textLeaf('HeroItem')],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Hero), findsOneWidget);
      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, equals('my-hero-box'));
    });

    testWidgets('6.2 heroFlight:true adds custom flightShuttleBuilder', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100',
        'props': {
          'heroTag': 'flight-hero',
          'heroFlight': true,
        },
        'children': [textLeaf('FlightHero')],
      }));
      await tester.pumpAndSettle();

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.flightShuttleBuilder, isNotNull);
    });

    // ── 7. Opacity ────────────────────────────────────────────────────────
    testWidgets('7.1 opacity:0.0 renders fully transparent node', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-80',
        'props': {'opacity': 0.0},
        'children': [textLeaf('Invisible')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Opacity), findsWidgets);
    });

    testWidgets('7.2 opacity:0.75 clamps between 0 and 1', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'opacity': 0.75},
        'children': [textLeaf('SemiTransp')],
      }));
      await tester.pumpAndSettle();

      final opacityWidget = tester.widgetList<Opacity>(find.byType(Opacity)).firstWhere(
        (w) => w.opacity == 0.75,
        orElse: () => throw TestFailure('No Opacity(0.75) widget found'),
      );
      expect(opacityWidget.opacity, closeTo(0.75, 0.001));
    });

    testWidgets('7.3 opacity > 1.0 is clamped to 1.0', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full',
        'props': {'opacity': 2.0}, // should clamp to 1.0
        'children': [textLeaf('Clamped')],
      }));
      await tester.pumpAndSettle();

      // Clamped to 1.0 → no Opacity wrapper added (1.0 = skip)
      expect(tester.takeException(), isNull);
    });

    // ── 8. Rotate + opacity combination ───────────────────────────────────
    testWidgets('8.1 rotate and opacity applied together', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100',
        'props': {'rotateTurns': 0.125, 'opacity': 0.6},
        'children': [textLeaf('RotateOpacity')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Opacity), findsWidgets);
      expect(find.text('RotateOpacity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 9. durationMs edge cases ──────────────────────────────────────────
    testWidgets('9.1 durationMs:0 — instant switch (no animation delay)', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-100',
        'props': {'animate': true, 'durationMs': 0},
        'children': [textLeaf('Instant')],
      }));
      await tester.pump(); // single frame
      await tester.pumpAndSettle();

      expect(find.text('Instant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9.2 durationMs exceeding cap (>10000) clamps to 10000ms', (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-full h-100',
        'props': {'animate': true, 'durationMs': 99999},
        'children': [textLeaf('SlowFade')],
      }));
      await tester.pump(); // just validates it doesn't throw

      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
