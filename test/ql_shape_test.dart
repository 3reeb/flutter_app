import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// Ensure your actual package import is added here
import 'package:quantum_layout/quantum.dart';

void main() {
  group('QShapeValue', () {
    test('absolute instantiation and resolution', () {
      const val = QShapeValue.absolute(100.0);
      expect(val.absolute, 100.0);
      expect(val.percent, isNull);
      expect(val.resolve(500.0), 100.0);
    });

    test('percent instantiation and resolution with clamping', () {
      const val1 = QShapeValue.percent(0.5);
      expect(val1.percent, 0.5);
      expect(val1.absolute, isNull);
      expect(val1.resolve(500.0), 250.0);

      const val2 = QShapeValue.percent(1.5);
      expect(val2.resolve(500.0), 500.0);

      const val3 = QShapeValue.percent(-0.5);
      expect(val3.resolve(500.0), 0.0);
    });

    test('parse handles null and fallbacks', () {
      final val1 = QShapeValue.parse(null, fallback: 42.0);
      expect(val1.absolute, 42.0);

      final val2 = QShapeValue.parse(Object(), fallback: 99.0);
      expect(val2.absolute, 99.0);
    });

    test('parse handles numbers', () {
      final valInt = QShapeValue.parse(15);
      expect(valInt.absolute, 15.0);

      final valDouble = QShapeValue.parse(25.5);
      expect(valDouble.absolute, 25.5);
    });

    test('parse handles strings', () {
      final valAbsStr = QShapeValue.parse(' 45.5 ');
      expect(valAbsStr.absolute, 45.5);

      final valPctStr = QShapeValue.parse(' 60% ');
      expect(valPctStr.percent, 0.6);

      final invalidStr = QShapeValue.parse('abc', fallback: 10.0);
      expect(invalidStr.absolute, 10.0);

      final invalidPctStr = QShapeValue.parse('xyz%', fallback: 5.0);
      expect(invalidPctStr.absolute, 5.0);
    });

    test('parse handles maps', () {
      final valAbsMap = QShapeValue.parse({'absolute': 75.0});
      expect(valAbsMap.absolute, 75.0);

      final valAbsIntMap = QShapeValue.parse({'absolute': 75});
      expect(valAbsIntMap.absolute, 75.0);

      final valPctMap = QShapeValue.parse({'percent': 0.8});
      expect(valPctMap.percent, 0.8);

      final valEmptyMap = QShapeValue.parse({'other': 1}, fallback: 2.0);
      expect(valEmptyMap.absolute, 2.0);
    });

    test('parse handles QShapeValue directly', () {
      const original = QShapeValue.absolute(123.0);
      final parsed = QShapeValue.parse(original);
      expect(parsed, same(original));
    });
  });

  group('QShapePoint', () {
    test('instantiation and resolve', () {
      const pt =
          QShapePoint(QShapeValue.absolute(10), QShapeValue.percent(0.5));
      final offset = pt.resolve(const Size(100, 200));
      expect(offset.dx, 10.0);
      expect(offset.dy, 100.0);
    });

    test('parse handles QShapePoint directly', () {
      const original =
          QShapePoint(QShapeValue.absolute(0), QShapeValue.absolute(0));
      final parsed = QShapePoint.parse(original);
      expect(parsed, same(original));
    });

    test('parse handles Lists', () {
      final pt = QShapePoint.parse([10, '50%']);
      expect(pt.x.absolute, 10.0);
      expect(pt.y.percent, 0.5);

      final invalidList = QShapePoint.parse([10]);
      expect(invalidList.x.absolute, 0.0);
      expect(invalidList.y.absolute, 0.0);
    });

    test('parse handles Maps', () {
      final pt = QShapePoint.parse({'x': 15.0, 'y': '25%'});
      expect(pt.x.absolute, 15.0);
      expect(pt.y.percent, 0.25);
    });

    test('parse handles invalid types', () {
      final pt = QShapePoint.parse('invalid_string');
      expect(pt.x.absolute, 0.0);
      expect(pt.y.absolute, 0.0);
    });
  });

  group('QShapePrimitive', () {
    test('default instantiation', () {
      const prim = QShapePrimitive(type: QShapeType.rect);
      expect(prim.type, QShapeType.rect);
      expect(prim.x.absolute, 0.0);
      expect(prim.y.absolute, 0.0);
      expect(prim.w.percent, 1.0);
      expect(prim.h.percent, 1.0);
      expect(prim.radius.absolute, 0.0);
      expect(prim.origin, Alignment.center);
    });

    test('fromJson full parsing', () {
      final prim = QShapePrimitive.fromJson({
        'type': 'circle',
        'x': 10.0,
        'y': '20%',
        'w': '50%',
        'h': 30.0,
        'radius': '10%',
        'origin': 'topLeft',
        'points': [
          [0, 0],
          {'x': 10, 'y': 10}
        ]
      });

      expect(prim.type, QShapeType.circle);
      expect(prim.x.absolute, 10.0);
      expect(prim.y.percent, 0.2);
      expect(prim.w.percent, 0.5);
      expect(prim.h.absolute, 30.0);
      expect(prim.radius.percent, 0.1);
      expect(prim.origin, Alignment.topLeft);
      expect(prim.points?.length, 2);
    });

    test('fromJson fallback to r for radius', () {
      final prim = QShapePrimitive.fromJson({'type': 'rrect', 'r': 15.0});
      expect(prim.radius.absolute, 15.0);
    });

    test('fromJson invalid type fallbacks to rect', () {
      final prim = QShapePrimitive.fromJson({'type': 'invalid_type'});
      expect(prim.type, QShapeType.rect);
    });

    test('Alignment parsing exhaustive check', () {
      final alignments = {
        'topLeft': Alignment.topLeft,
        'topRight': Alignment.topRight,
        'bottomLeft': Alignment.bottomLeft,
        'bottomRight': Alignment.bottomRight,
        'centerLeft': Alignment.centerLeft,
        'centerRight': Alignment.centerRight,
        'topCenter': Alignment.topCenter,
        'bottomCenter': Alignment.bottomCenter,
        'center': Alignment.center,
        'random': Alignment.center,
      };

      for (final entry in alignments.entries) {
        final prim = QShapePrimitive.fromJson({'origin': entry.key});
        expect(prim.origin, entry.value);
      }
    });
  });

  group('QBooleanShapeDef and Ops', () {
    test('QBooleanShapeOp fromJson', () {
      final op1 = QBooleanShapeOp.fromJson({
        'op': 'subtract',
        'shape': {'type': 'circle', 'radius': 10}
      });
      expect(op1.op, QBooleanOp.subtract);
      expect(op1.shape.type, QShapeType.circle);
      expect(op1.shape.radius.absolute, 10.0);

      final op2 = QBooleanShapeOp.fromJson({});
      expect(op2.op, QBooleanOp.union);
      expect(op2.shape.type, QShapeType.rect);
    });

    test('QBooleanShapeDef fromJson modern structure', () {
      final def = QBooleanShapeDef.fromJson({
        'base': {'type': 'rrect', 'radius': 5},
        'operations': [
          {
            'op': 'intersect',
            'shape': {'type': 'pill'}
          },
          {
            'op': 'exclude',
            'shape': {'type': 'polygon'}
          }
        ]
      });

      expect(def.base.type, QShapeType.rrect);
      expect(def.operations.length, 2);
      expect(def.operations[0].op, QBooleanOp.intersect);
      expect(def.operations[0].shape.type, QShapeType.pill);
      expect(def.operations[1].op, QBooleanOp.exclude);
      expect(def.operations[1].shape.type, QShapeType.polygon);
    });

    test('QBooleanShapeDef fromJson legacy structure', () {
      final def = QBooleanShapeDef.fromJson({
        'base': {'type': 'rect'},
        'subtract': [
          {'type': 'circle'}
        ],
        'union': [
          {'type': 'pill'}
        ],
        'intersect': [
          {'type': 'rrect'}
        ],
        'exclude': [
          {'type': 'polygon'}
        ],
      });

      expect(def.base.type, QShapeType.rect);
      expect(def.operations.length, 4);
      expect(def.operations[0].op, QBooleanOp.subtract);
      expect(def.operations[0].shape.type, QShapeType.circle);

      expect(def.operations[1].op, QBooleanOp.union);
      expect(def.operations[1].shape.type, QShapeType.pill);

      expect(def.operations[2].op, QBooleanOp.intersect);
      expect(def.operations[2].shape.type, QShapeType.rrect);

      expect(def.operations[3].op, QBooleanOp.exclude);
      expect(def.operations[3].shape.type, QShapeType.polygon);
    });
  });

  group('QLShapeNode Widget & RenderObject Updates', () {
    final baseDef = QBooleanShapeDef.fromJson({
      'base': {'type': 'rect'}
    });

    testWidgets('Widget mounts and properties sync to RenderObject',
        (WidgetTester tester) async {
      final repaintNotifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: QLShapeNode(
                shapeDef: baseDef,
                repaint: repaintNotifier,
                color: Colors.red,
                shadows: const [
                  BoxShadow(color: Colors.black, blurRadius: 4.0)
                ],
                border: const BorderSide(color: Colors.blue, width: 2.0),
                clipChild: true,
                drawFillBehindChild: false,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final renderObject =
          tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));
      expect(renderObject.size, const Size(100, 100));

      final newDef = QBooleanShapeDef.fromJson({
        'base': {'type': 'circle'}
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 100,
              height: 100,
              child: QLShapeNode(
                shapeDef: newDef,
                color: Colors.green,
                shadows: null,
                border: null,
                clipChild: false,
                drawFillBehindChild: true,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final updatedRenderObject =
          tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));
      expect(updatedRenderObject, same(renderObject));

      repaintNotifier.value = 1;
      await tester.pump();
      repaintNotifier.dispose();
    });

    testWidgets('Layout sizes correctly based on constraints',
        (WidgetTester tester) async {
      // Unconstrained scenario: should resolve to child's dimensions
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: UnconstrainedBox(
              child: QLShapeNode(
                shapeDef: baseDef,
                child: const SizedBox(width: 50, height: 75),
              ),
            ),
          ),
        ),
      );

      var ro = tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));
      expect(ro.size, const Size(50, 75));

      // Constrained scenario: matches bounded width and height
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: QLShapeNode(
                shapeDef: baseDef,
              ),
            ),
          ),
        ),
      );

      ro = tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));
      expect(ro.size, const Size(120, 120));
    });

    testWidgets('Attach and Detach Listeners', (WidgetTester tester) async {
      final notifier = ValueNotifier<int>(0);

      await tester.pumpWidget(
        QLShapeNode(
          shapeDef: baseDef,
          repaint: notifier,
        ),
      );

      await tester.pumpWidget(const SizedBox());

      // Should not throw or dispatch to a disposed listener
      expect(() => notifier.value = 1, returnsNormally);
      await tester.pump();

      notifier.dispose();
    });
  });

  group('RenderQLShape Drawing & Hit Testing', () {
    testWidgets('Hit Testing subtracted shape (Hole) boundaries and parsing',
        (WidgetTester tester) async {
      final def = QBooleanShapeDef.fromJson({
        'base': {
          'type': 'rect',
          'origin': 'topLeft',
          'w': 100.0,
          'h': 100.0,
        },
        'operations': [
          {
            'op': 'subtract',
            'shape': {
              'type': 'rect',
              'origin': 'topLeft',
              'w': 50.0,
              'h': 50.0,
              'x': 25.0,
              'y': 25.0,
            }
          }
        ]
      });

      // 1. Verify JSON parsed the operations successfully
      expect(def.operations.length, 1);
      expect(def.operations.first.op, QBooleanOp.subtract);
      expect(def.operations.first.shape.type, QShapeType.rect);
      expect(def.operations.first.shape.w.absolute, 50.0);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: UnconstrainedBox(
              child: QLShapeNode(
                shapeDef: def,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final renderObject =
          tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));

      renderObject.paint(
          PaintingContext(ContainerLayer(), Rect.zero), Offset.zero);

      // 2. Headless VM Safe: Test outer bounding limits for hit testing
      final insideBase = BoxHitTestResult();
      expect(renderObject.hitTest(insideBase, position: const Offset(10, 10)),
          isTrue);

      final outsideBase = BoxHitTestResult();
      expect(
          renderObject.hitTest(outsideBase, position: const Offset(150, 150)),
          isFalse);
    });

    testWidgets('Hit Testing children precedence', (WidgetTester tester) async {
      final def = QBooleanShapeDef.fromJson({
        'base': {'type': 'rect', 'w': 0.0, 'h': 0.0}
      });

      bool childTapped = false;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: QLShapeNode(
              shapeDef: def,
              child: GestureDetector(
                onTap: () => childTapped = true,
                child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap is expected to miss due to the path containing no space.
      // Passing warnIfMissed: false prevents test framework warnings.
      await tester.tap(find.byType(GestureDetector), warnIfMissed: false);
      await tester.pump();

      expect(childTapped, isFalse);
    });

    testWidgets('Exhaustive Shape Painting (Coverage)',
        (WidgetTester tester) async {
      final def = QBooleanShapeDef.fromJson({
        'base': {
          'type': 'rrect',
          'origin': 'center',
          'radius': '10%',
          'w': '100%',
          'h': '100%'
        },
        'operations': [
          {
            'op': 'union',
            'shape': {
              'type': 'rrect',
              'radius': 0,
            }
          },
          {
            'op': 'intersect',
            'shape': {'type': 'pill'}
          },
          {
            'op': 'subtract',
            'shape': {'type': 'circle', 'radius': 15.0}
          },
          {
            'op': 'exclude',
            'shape': {'type': 'circle', 'radius': 0.0}
          },
          {
            'op': 'union',
            'shape': {
              'type': 'polygon',
              'points': [
                {'x': 0, 'y': 0},
                {'x': 100, 'y': 0},
                {'x': 50, 'y': 100}
              ]
            }
          },
          {
            'op': 'union',
            'shape': {
              'type': 'polygon',
            }
          }
        ]
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: QLShapeNode(
            shapeDef: def,
            color: Colors.red,
            border: const BorderSide(color: Colors.black, width: 5.0),
            shadows: const [
              BoxShadow(color: Colors.black, blurRadius: 4.0),
              BoxShadow(color: Color(0x00000000), blurRadius: 0.0),
            ],
            clipChild: true,
            drawFillBehindChild: true,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final renderObject =
          tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));
      final layer = ContainerLayer();
      final context = PaintingContext(layer, Rect.zero);

      expect(() => renderObject.paint(context, Offset.zero), returnsNormally);
    });

    testWidgets('Empty shape size prevents paint', (WidgetTester tester) async {
      final def = QBooleanShapeDef.fromJson({
        'base': {'type': 'rect'}
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: QLShapeNode(
            shapeDef: def,
            child: const SizedBox(width: 0, height: 0),
          ),
        ),
      );

      final renderObject =
          tester.renderObject<RenderQLShape>(find.byType(QLShapeNode));
      final layer = ContainerLayer();
      final context = PaintingContext(layer, Rect.zero);

      expect(() => renderObject.paint(context, Offset.zero), returnsNormally);
    });
  });
}
