import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;
import 'package:flutter/rendering.dart';

import 'package:quantum_layout/quantum.dart';

void main() {
  setUpAll(() {
    // Initialize the global Quantum Engine for tests that rely on QEngine singletons
    QEngine.instance.initialize(initialCapacity: 1024, ecsCapacity: 1024);
  });

  group('1. QLSafe (Math & Armor)', () {
    test('finite() protects against NaN and Infinity', () {
      expect(QLSafe.finite(10.5), 10.5);
      expect(QLSafe.finite(null, 5.0), 5.0);
      expect(QLSafe.finite(double.nan, 2.0), 2.0);
      expect(QLSafe.finite(double.infinity, 3.0), 3.0);
      expect(QLSafe.finite(double.negativeInfinity, 4.0), 4.0);
    });

    test('offset() protects against invalid coordinates', () {
      expect(QLSafe.offset(const Offset(10, 20)), const Offset(10, 20));
      expect(QLSafe.offset(null, const Offset(1, 1)), const Offset(1, 1));
      expect(QLSafe.offset(const Offset(double.nan, 10)), Offset.zero);
      expect(QLSafe.offset(const Offset(10, double.infinity)), Offset.zero);
    });

    test('isOffscreen2D() accurately calculates AABB visibility', () {
      // Viewport: x=0, y=0, w=100, h=100
      // Inside
      expect(QLSafe.isOffscreen2D(10, 10, 50, 50, 0, 0, 100, 100), isFalse);
      // Intersecting boundaries
      expect(QLSafe.isOffscreen2D(-10, -10, 20, 20, 0, 0, 100, 100), isFalse);
      expect(QLSafe.isOffscreen2D(90, 90, 50, 50, 0, 0, 100, 100), isFalse);
      // Completely outside
      expect(QLSafe.isOffscreen2D(-50, 10, 20, 20, 0, 0, 100, 100),
          isTrue); // Left
      expect(QLSafe.isOffscreen2D(110, 10, 20, 20, 0, 0, 100, 100),
          isTrue); // Right
      expect(
          QLSafe.isOffscreen2D(10, -50, 20, 20, 0, 0, 100, 100), isTrue); // Top
      expect(QLSafe.isOffscreen2D(10, 110, 20, 20, 0, 0, 100, 100),
          isTrue); // Bottom
      // Infinite viewport (always visible)
      expect(
          QLSafe.isOffscreen2D(1000, 1000, 50, 50, 0, 0, double.infinity, 100),
          isFalse);
    });
  });

  group('2. QLArena (Zero-Copy CPU Memory Pool)', () {
    test('obtainVector() provides sequential memory and wraps correctly', () {
      final v1 = QLArena.obtainVector(4);
      final v2 = QLArena.obtainVector(4);
      expect(v1.length, 4);
      expect(v2.length, 4);

      // Force wrap around by requesting max buffer size
      final wrap = QLArena.obtainVector(8192);
      expect(wrap.length, 8192);

      final v3 = QLArena.obtainVector(4); // Should be back at start
      expect(v3.length, 4);
    });

    test('multiplyMatrix() executes accurate 4x4 dot products', () {
      final a = Matrix4.identity()..scale(2.0, 3.0, 4.0);
      final b = Matrix4.identity()..translate(10.0, 20.0, 30.0);

      final out = Float64List(16);
      QLArena.multiplyMatrix(out, a.storage, b.storage);

      final expected = a * b;
      for (int i = 0; i < 16; i++) {
        expect(out[i], expected.storage[i],
            reason: 'Matrix element $i mismatch');
      }
    });
  });

  group('3. Reactivity (QLSignal & QLComputed)', () {
    test('QLSignal notifies listeners and batches updates', () {
      final sig = QLSignal<int>(0);
      int triggerCount = 0;
      sig.addListener(() => triggerCount++);

      sig.value = 1; // Notifies
      expect(triggerCount, 1);

      sig.value = 1; // Does not notify (same value)
      expect(triggerCount, 1);

      sig.update((state) {}); // Forced batch update
      expect(triggerCount, 2);

      sig.setSilent(5); // No notification
      expect(sig.value, 5);
      expect(triggerCount, 2);
    });

    test('QLComputed automatically tracks dependencies and caches output', () {
      final a = QLSignal<int>(10);
      final b = QLSignal<int>(20);
      int computeCount = 0;

      final sum = QLComputed<int>(() {
        computeCount++;
        return a.value + b.value;
      });

      // First read: evaluates
      expect(sum.value, 30);
      expect(computeCount, 1);

      // Second read: uses cache
      expect(sum.value, 30);
      expect(computeCount, 1);

      // Update dependency -> dirties cache
      a.value = 15;
      expect(computeCount, 1);

      // Third read: re-evaluates
      expect(sum.value, 35);
      expect(computeCount, 2);
    });
  });

  group('4. Physics Integrator (QLIntegratorRK4)', () {
    test('RK4 cleanly integrates ODEs (Linear velocity test)', () {
      final rk4 =
          QLIntegratorRK4(2, initialState: Float64List.fromList([0.0, 10.0]));

      void linearDerivative(Float64List state, Float64List derivs) {
        derivs[0] = state[1]; // Pos' = Vel
        derivs[1] = 0.0; // Vel' = Accel (Constant velocity)
      }

      // 1 second step
      rk4.step(1.0, linearDerivative);
      expect(rk4.state[0], closeTo(10.0, 0.001)); // Pos after 1s = 10
      expect(rk4.state[1], closeTo(10.0, 0.001)); // Vel remains 10
    });

    test('QLPhysicsTicker steps and caps delta time', () {
      final rk4 = QLIntegratorRK4(1);

      // Simulate a valid previous tick frame (lastTickMs = 10)
      final nextMs = QLPhysicsTicker.step(
          const Duration(milliseconds: 100), // elapsed
          10,
          rk4,
          (s, d) {});
      expect(nextMs, 100);

      // Step backwards/zero drops tick
      final dropMs = QLPhysicsTicker.step(
          const Duration(milliseconds: 100), 100, rk4, (s, d) {});
      expect(dropMs, -1);
    });
  });

  group('5. Entity Component System (QLSoAEngine)', () {
    late QLSoAEngine ecs;

    setUp(() {
      ecs = QLSoAEngine(100, cellSize: 50.0);
    });

    test('Spawns entities with parent-child relationships', () {
      final parent = ecs.spawn();
      final child1 = ecs.spawn(parentId: parent);
      final child2 = ecs.spawn(parentId: parent);

      expect(ecs.activeCount, 3);
      expect(ecs.parentIds[child1], parent);
      expect(ecs.firstChildIds[parent],
          child2); // Last spawned is first in linked list
      expect(ecs.nextSiblingIds[child2], child1);
    });

    test('Cascades world transforms properly', () {
      final parent = ecs.spawn();
      final child = ecs.spawn(parentId: parent);

      final t = ecs.comp('transform');
      // Set Parent Local Pos
      t.set(parent, 0, 10.0); // X
      t.set(parent, 1, 20.0); // Y
      // Set Child Local Pos
      t.set(child, 0, 5.0); // X
      t.set(child, 1, -5.0); // Y

      ecs.computeWorldTransforms();

      // Check Parent World
      expect(t.get(parent, 6), 10.0);
      expect(t.get(parent, 7), 20.0);

      // Check Child World (Cascaded)
      expect(t.get(child, 6), 15.0);
      expect(t.get(child, 7), 15.0);
    });

    test('Spatial Hashing and Hit Testing', () {
      final e1 = ecs.spawn();
      final e2 = ecs.spawn();

      final t = ecs.comp('transform');
      final b = ecs.comp('bounds');
      final v = ecs.comp('visual');

      // Entity 1 at (10, 10) 100x100 Z=1
      t.set(e1, 6, 10.0);
      t.set(e1, 7, 10.0);
      b.set(e1, 0, 100.0);
      b.set(e1, 1, 100.0);
      v.set(e1, 1, 1.0);

      // Entity 2 at (50, 50) 100x100 Z=2 (Overlaps E1)
      t.set(e2, 6, 50.0);
      t.set(e2, 7, 50.0);
      b.set(e2, 0, 100.0);
      b.set(e2, 1, 100.0);
      v.set(e2, 1, 2.0);

      ecs.updateSpatialHash(e1);
      ecs.updateSpatialHash(e2);

      // Hit at 60,60 should hit E2 due to higher Z-index
      final hit = ecs.hitTest(60, 60);
      expect(hit, e2);

      // Query Radius
      final hits = ecs.queryRadius(60, 60, 200);
      expect(hits.contains(e1), isTrue);
      expect(hits.contains(e2), isTrue);
    });

    test('Destroys entities and cleans up hierarchy', () {
      final parent = ecs.spawn();
      ecs.spawn(parentId: parent);

      ecs.destroy(parent);
      // Destroying parent destroys children. Array compacts.
      expect(ecs.activeCount, 0);
    });
  });

  group('6. Parsing Algorithms (QLParserUtils)', () {
    test('parseDecimal', () {
      expect(QLParserUtils.parseDecimal('123.45', 0, 6), 123.45);
      expect(QLParserUtils.parseDecimal('gap-42', 4, 6), 42.0);
      expect(QLParserUtils.parseDecimal('.5', 0, 2), 0.5);
      // Note: parser ignores signs by design in current optimized engine context.
      expect(QLParserUtils.parseDecimal('width: -99.9', 7, 12), 99.9);
    });

    test('parseColor & parseHexColor', () {
      // Raw hex
      expect(QLParserUtils.parseHexColor('FFF'), 0xFFFFFFFF);
      expect(QLParserUtils.parseHexColor('FF0000'), 0xFFFF0000);
      expect(QLParserUtils.parseHexColor('80FF0000'), 0x80FF0000);

      // Bracket format
      expect(QLParserUtils.parseColor('[#FF0000]', 0, 9), 0xFFFF0000);
      expect(QLParserUtils.parseColor('#FF0000', 0, 7), 0xFFFF0000);

      // Keywords
      expect(QLParserUtils.parseColor('red', 0, 3), 0xFFEF4444);
      expect(QLParserUtils.parseColor('transparent', 0, 11), 0x00000000);

      // Opacity modifiers
      expect(QLParserUtils.parseColor('black/50', 0, 8),
          0x7F000000); // 50% opacity
    });

    test('applyOpacity', () {
      expect(QLParserUtils.applyOpacity(0xFFFFFFFF, 0.5), 0x80FFFFFF);
      expect(QLParserUtils.applyOpacity(0x80FFFFFF, 0.5), 0x40FFFFFF);
    });
  });

  group('7. Caches & Controllers', () {
    test('QLTextPainterCache deduplicates successfully', () {
      const ts = TextStyle(fontSize: 14);
      final p1 = QLTextPainterCache.get('Hello', ts, 100.0);
      final p2 = QLTextPainterCache.get('Hello', ts, 100.0);

      expect(identical(p1, p2), isTrue); // Should be exact same instance
    });

    test('QLTableLayoutController handles state', () {
      final ctrl = QLTableLayoutController(5);
      expect(ctrl.activeOrder.length, 5);

      int sigTriggers = 0;
      ctrl.version.addListener(() => sigTriggers++);

      ctrl.updateColumn(0, 10, 100);
      expect(ctrl.offsetsX[0], 10);
      expect(ctrl.widths[0], 100);
      expect(sigTriggers, 1);

      ctrl.swapColumns(0, 1);
      expect(ctrl.activeOrder[0], 1);
      expect(ctrl.activeOrder[1], 0);
      expect(sigTriggers, 2);
    });
  });

  group('8. Widget & Render Layer (QLNode & OmniSensor)', () {
    testWidgets('QLNode respects layout boundaries and transforms',
        (WidgetTester tester) async {
      final widthSig = QLSignal<double>(100.0);
      final heightSig = QLSignal<double>(100.0);
      final opacitySig = QLSignal<double>(0.5);

      final config = QLNodeConfig(
        width: widthSig,
        height: heightSig,
        opacity: opacitySig,
        semanticsLabel: 'TestNode',
        hitTestBehavior: HitTestBehavior
            .opaque, // Required so the node itself absorbs hit tests without a child!
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: QLNode(
              config: config,
              child: const SizedBox(width: 500, height: 500), // Oversized child
            ),
          ),
        ),
      );

      final RenderQLNode renderObj = tester.renderObject(find.byType(QLNode));

      // Test constraints clamping child size
      expect(renderObj.size.width, 100.0);
      expect(renderObj.size.height, 100.0);

      // Test reactivity updating render object
      widthSig.value = 200.0;
      await tester.pump();
      expect(renderObj.size.width, 200.0);

      // Test hit testing behavior
      expect(
        renderObj.hitTest(BoxHitTestResult(), position: const Offset(50, 50)),
        isTrue,
      );
      expect(
        renderObj.hitTest(BoxHitTestResult(), position: const Offset(300, 300)),
        isFalse,
      );
    });

    testWidgets('QLOmniSensor fires pointer events',
        (WidgetTester tester) async {
      QLPointerEvent? capturedEvent;

      await tester.pumpWidget(
        MaterialApp(
          home: QLOmniSensor(
            onTouchUpdate: (e) => capturedEvent = e,
            child: Container(width: 200, height: 200, color: Colors.red),
          ),
        ),
      );

      final center = tester.getCenter(find.byType(Container));
      await tester.tapAt(center);

      expect(capturedEvent, isNotNull);
      expect(capturedEvent!.position.dx, closeTo(center.dx, 1.0));
      expect(capturedEvent!.position.dy, closeTo(center.dy, 1.0));
    });

    testWidgets('RenderQLNode Semantic injection', (WidgetTester tester) async {
      final config = QLNodeConfig(
        width: QLSignal<double>(100.0),
        semanticsLabel: 'Accessible Node',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: QLNode(config: config, child: const SizedBox()),
        ),
      );

      final semantics = tester.getSemantics(find.byType(QLNode));
      expect(semantics.label, 'Accessible Node');
    });
  });
}
