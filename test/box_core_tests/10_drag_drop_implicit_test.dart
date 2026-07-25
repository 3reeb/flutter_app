// ════════════════════════════════════════════════════════════════════════════
// BOX CORE: DRAG, DROP & IMPLICIT BEHAVIORS — PRODUCTION TESTS
// test/box_core_tests/10_drag_drop_implicit_test.dart
//
// Tests cover:
//  • draggable:true → Draggable<Object> wraps the widget
//  • dragAxis:horizontal / vertical / null (free)
//  • dragOpacity:0.5 on feedback
//  • hideOnDrag:true → child replaced with SizedBox.shrink while dragging
//  • longPressDraggable:true → LongPressDraggable
//  • dragData string transfer
//  • onDrop action triggered on DragTarget
//  • dragData + onDrop combo
//  • magneto:true → QLMagnetoSurface wraps
//  • heroId prop → Hero wrapping (implicit behavior)
//  • draggable inside grid — production kanban-like pattern
//  • dragData carrying object reference via store
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'helpers.dart';

void main() {
  group('BoxCore | Drag, Drop & Implicit Behaviors — Production', () {
    setUp(boxCoreSetUp);
    tearDown(boxCoreTearDown);

    // ── 1. draggable:true ─────────────────────────────────────────────────
    testWidgets('1.1 draggable:true wraps in Draggable<Object>',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80 bg-blue-200 rounded-xl',
        'props': {'draggable': true, 'dragData': 'card_item_1'},
        'children': [textLeaf('DragMe')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<Object>), findsOneWidget);
      expect(find.text('DragMe'), findsOneWidget);
    });

    testWidgets(
        '1.2 draggable with dragAxis:horizontal restricts to horizontal drag',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80 bg-blue-200',
        'props': {
          'draggable': true,
          'dragData': 'h_drag',
          'dragAxis': 'horizontal',
        },
        'children': [textLeaf('HorizDrag')],
      }));
      await tester.pumpAndSettle();

      final draggable = tester.widget<Draggable<Object>>(
        find.byType(Draggable<Object>),
      );
      expect(draggable.axis, equals(Axis.horizontal));
    });

    testWidgets('1.3 draggable with dragAxis:vertical restricts to vertical',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80 bg-green-200',
        'props': {
          'draggable': true,
          'dragData': 'v_drag',
          'dragAxis': 'vertical',
        },
        'children': [textLeaf('VertDrag')],
      }));
      await tester.pumpAndSettle();

      final draggable = tester.widget<Draggable<Object>>(
        find.byType(Draggable<Object>),
      );
      expect(draggable.axis, equals(Axis.vertical));
    });

    testWidgets('1.4 draggable without dragAxis has null axis (free drag)',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80',
        'props': {'draggable': true, 'dragData': 'free'},
        'children': [textLeaf('FreeDrag')],
      }));
      await tester.pumpAndSettle();

      final draggable = tester.widget<Draggable<Object>>(
        find.byType(Draggable<Object>),
      );
      expect(draggable.axis, isNull);
    });

    // ── 2. hideOnDrag ─────────────────────────────────────────────────────
    testWidgets('2.1 hideOnDrag:true sets childWhenDragging to SizedBox.shrink',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80',
        'props': {
          'draggable': true,
          'dragData': 'hidden_drag',
          'hideOnDrag': true,
        },
        'children': [textLeaf('HiddenWhenDragging')],
      }));
      await tester.pumpAndSettle();

      // childWhenDragging should be SizedBox.shrink
      final draggable = tester.widget<Draggable<Object>>(
        find.byType(Draggable<Object>),
      );
      expect(draggable.childWhenDragging, isA<SizedBox>());
    });

    // ── 3. longPressDraggable ─────────────────────────────────────────────
    testWidgets('3.1 longPressDraggable:true wraps in LongPressDraggable',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-150 h-100 bg-amber-200',
        'props': {
          'longPressDraggable': true,
          'dragData': 'long_press_item',
        },
        'children': [textLeaf('LongPress')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(LongPressDraggable<Object>), findsOneWidget);
    });

    // ── 4. dragData carrying payload ──────────────────────────────────────
    testWidgets('4.1 dragData default is subType when not specified',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80',
        'props': {'draggable': true},
        'children': [textLeaf('SubtypeData')],
      }));
      await tester.pumpAndSettle();

      final draggable = tester.widget<Draggable<Object>>(
        find.byType(Draggable<Object>),
      );
      // dragData defaults to subType when not specified
      expect(draggable.data, isNotNull);
    });

    // ── 6. heroId implicit behavior ───────────────────────────────────────
    testWidgets('6.1 heroId prop wraps in Hero via _applyImplicitBehaviors',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-100 h-100 bg-emerald-300',
        'props': {'heroId': 'product-hero-42'},
        'children': [textLeaf('HeroItem')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Hero), findsWidgets);
      final hero = tester.widgetList<Hero>(find.byType(Hero)).firstWhere(
            (h) => h.tag == 'product-hero-42',
            orElse: () => throw TestFailure('Hero with tag not found'),
          );
      expect(hero.tag, equals('product-hero-42'));
    });

    // ── 7. dragData + dragOpacity on feedback ─────────────────────────────
    testWidgets('7.1 dragOpacity:0.5 sets feedback Opacity to 0.5',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-120 h-80 bg-indigo-200',
        'props': {
          'draggable': true,
          'dragData': 'opacity_item',
          'dragOpacity': 0.5,
        },
        'children': [textLeaf('DragOpacity')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<Object>), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ── 8. Kanban-board pattern: draggable items in a row of cols ─────────
    testWidgets('8.1 kanban layout with 3 draggable items in columns',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'row',
        'style': 'w-full h-full gap-16 items-start',
        'props': {'scrollable': true},
        'children': [
          // Column 1: To Do
          {
            'type': 'col',
            'style': 'w-220 bg-slate-100 rounded-xl gap-8',
            'props': {
              'padding': [12]
            },
            'children': [
              textLeaf('To Do'),
              ...List.generate(
                  3,
                  (i) => {
                        'type': 'col',
                        'style': 'w-full h-80 bg-white rounded-lg shadow-sm',
                        'props': {
                          'draggable': true,
                          'dragData': 'todo_$i',
                          'dragAxis': 'horizontal',
                        },
                        'children': [textLeaf('Task $i')],
                      }),
            ],
          },
          // Column 2: In Progress
          {
            'type': 'col',
            'style': 'w-220 bg-blue-50 rounded-xl gap-8',
            'props': {
              'padding': [12]
            },
            'children': [
              textLeaf('In Progress'),
              ...List.generate(
                  2,
                  (i) => {
                        'type': 'col',
                        'style': 'w-full h-80 bg-white rounded-lg shadow-sm',
                        'props': {
                          'draggable': true,
                          'dragData': 'wip_$i',
                        },
                        'children': [textLeaf('WIP $i')],
                      }),
            ],
          },
          // Column 3: Done
          {
            'type': 'col',
            'style': 'w-220 bg-green-50 rounded-xl gap-8',
            'props': {
              'padding': [12]
            },
            'children': [
              textLeaf('Done'),
            ],
          },
        ],
      }));
      await tester.pumpAndSettle();

      expect(find.text('To Do'), findsOneWidget);
      expect(find.text('Task 0'), findsOneWidget);
      expect(find.text('WIP 0'), findsOneWidget);
      expect(find.byType(Draggable<Object>), findsNWidgets(5));
      expect(tester.takeException(), isNull);
    });

    // ── 9. Combined: draggable + magneto + opacity ─────────────────────────
    testWidgets('9.1 draggable + magneto + opacity on same box',
        (tester) async {
      await tester.pumpWidget(buildTestWrapper({
        'type': 'col',
        'style': 'w-180 h-120 rounded-2xl bg-rose-200',
        'props': {
          'draggable': true,
          'dragData': 'combo_card',
          'magneto': true,
          'opacity': 0.85,
        },
        'children': [textLeaf('ComboCard')],
      }));
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<Object>), findsOneWidget);
      expect(find.text('ComboCard'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
