import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('Nested overlay scenarios', () {
    testWidgets('keeps a parent overlay alive when a child overlay closes',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Parent');
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Child');
      QuantumOverlay.instance.closeTop();
      await tester.pumpAndSettle();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsNothing);
    });
    testWidgets(
        'supports three nested overlays without losing the underlying stack',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Layer 1');
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Layer 2');
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Layer 3');
      expect(find.text('Layer 1'), findsOneWidget);
      expect(find.text('Layer 2'), findsOneWidget);
      expect(find.text('Layer 3'), findsOneWidget);
    });
    testWidgets('dismisses only the top nested overlay on escape',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Bottom');
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'Top');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Bottom'), findsOneWidget);
      expect(find.text('Top'), findsNothing);
    });
    testWidgets('dismisses only the top nested overlay on outside tap',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Bottom');
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'Top');
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(find.text('Bottom'), findsOneWidget);
      expect(find.text('Top'), findsNothing);
    });
    testWidgets('retains nested non-modal overlays when a modal child closes',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.surface(pattern: QLSurfacePattern.nonModal),
          label: 'Non modal parent');
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Modal child');
      QuantumOverlay.instance.closeTop();
      await tester.pumpAndSettle();
      expect(find.text('Non modal parent'), findsOneWidget);
      expect(find.text('Modal child'), findsNothing);
    });
    testWidgets('handles nested overlays with mixed patterns', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.drawer(edge: QLSheetEdge.left),
          label: 'Drawer');
      await openOverlay(tester,
          config: QLSpatialConfig.toast(), label: 'Toast');
      await openOverlay(tester,
          config: QLSpatialConfig.menu(
              targetLeft: 1, targetTop: 2, targetRight: 3, targetBottom: 4),
          label: 'Menu');
      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Toast'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
    });
    testWidgets('keeps nested overlays aligned with the current top node id',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'A');
      final first = QuantumOverlay.instance.topNodeId;
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'B');
      final second = QuantumOverlay.instance.topNodeId;
      expect(second, isNot(first));
    });
    testWidgets('clears nested overlays when the root is disposed',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'A');
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'B');
      await tester.pumpWidget(const SizedBox.shrink());
      expect(QuantumOverlay.instance.topNodeId, 0);
    });
    testWidgets('survives repeated nested open and close cycles',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      for (var i = 0; i < 4; i += 1) {
        await openOverlay(tester,
            config: QLSpatialConfig.dialog(), label: 'Level $i');
      }
      expect(find.text('Level 0'), findsOneWidget);
      expect(find.text('Level 3'), findsOneWidget);
      QuantumOverlay.instance.resetForTesting();
      await tester.pump();
      expect(find.text('Level 0'), findsNothing);
      expect(find.text('Level 3'), findsNothing);
    });
    testWidgets('retains app shell content when overlays stack deeply',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'X');
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'Y');
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'Z');
      expect(find.text('app-shell'), findsOneWidget);
    });
  });
}
