import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('QuantumOverlay and QLOverlayRoot', () {
    testWidgets('renders the child content inside the overlay root',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      expect(find.text('app-shell'), findsOneWidget);
    });
    testWidgets('starts with a clean overlay state after the root is mounted',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      expect(QuantumOverlay.instance.topNodeId, 0);
    });
    testWidgets('resets the overlay engine when the root is disposed',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await tester.pumpWidget(const SizedBox.shrink());
      expect(QuantumOverlay.instance.topNodeId, 0);
    });
    testWidgets('mounts a dialog overlay and renders its widget',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Dialog body');
      expect(find.text('Dialog body'), findsOneWidget);
    });
    testWidgets('closeTop removes the active overlay', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Closable dialog');
      expect(QuantumOverlay.instance.topNodeId, isNonZero);
      QuantumOverlay.instance.closeTop();
      await tester.pumpAndSettle();
      expect(find.text('Closable dialog'), findsNothing);
      expect(QuantumOverlay.instance.topNodeId, 0);
    });
    testWidgets('escape closes a dismissible dialog overlay', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Escape dialog');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Escape dialog'), findsNothing);
    });
    testWidgets('outside tap closes a dismissible dialog overlay',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Tap dialog');
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Tap dialog'), findsNothing);
    });
    testWidgets('outside tap does not close a locked dialog', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(
        tester,
        config: QLSpatialConfig.dialog(barrierDismissible: false),
        label: 'Locked dialog',
      );
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Locked dialog'), findsOneWidget);
    });
    testWidgets('closeTop respects lockClose at the runtime level',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(
        tester,
        config: QLSpatialConfig.dialog(
            runtime: const QLOverlayRuntimeSpec(lockClose: true)),
        label: 'Runtime locked dialog',
      );
      QuantumOverlay.instance.closeTop();
      await tester.pumpAndSettle();
      expect(find.text('Runtime locked dialog'), findsOneWidget);
    });
    testWidgets('supports insertMode atIndex for stack ordering',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(
              runtime: const QLOverlayRuntimeSpec(
                  insertMode: QLOverlayInsertMode.top)),
          label: 'First');
      final firstTop = QuantumOverlay.instance.topNodeId;
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(
              runtime: const QLOverlayRuntimeSpec(
                  insertMode: QLOverlayInsertMode.atIndex, insertIndex: 0)),
          label: 'Second');
      expect(QuantumOverlay.instance.topNodeId, firstTop);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
    });
    testWidgets(
        'supports insertMode bottom by placing the new node behind older ones',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Top overlay');
      final topBefore = QuantumOverlay.instance.topNodeId;
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(
              runtime: const QLOverlayRuntimeSpec(
                  insertMode: QLOverlayInsertMode.bottom)),
          label: 'Bottom overlay');
      expect(QuantumOverlay.instance.topNodeId, topBefore);
    });
    testWidgets('renders a toast overlay and allows time-based dismissal',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.toast(
              duration: const Duration(milliseconds: 200)),
          label: 'Toast body');
      expect(find.text('Toast body'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Toast body'), findsNothing);
    });
    testWidgets('keeps a non-dismissible toast open until explicitly reset',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.toast(), label: 'Toast body 2');
      await tester.tapAt(const Offset(5, 5));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Toast body 2'), findsOneWidget);
    });
    testWidgets('applies a zoom-back background transform for sheets',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.sheet(), label: 'Sheet body');
      final transform = tester.widget<Transform>(find.byType(Transform).first);
      expect(transform.transform.storage[0], lessThan(1.0));
    });
    testWidgets('applies a zero-radius background for darken effects',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.fullscreenDialog(
              effect: QLBackgroundEffect.darken),
          label: 'Dark body');
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clip.borderRadius, BorderRadius.zero);
    });
    testWidgets(
        'shows the active barrier scrim while a modal overlay is mounted',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Barrier body');
      final ignorePointer =
          tester.widget<IgnorePointer>(find.byType(IgnorePointer).first);
      expect(ignorePointer.ignoring, isFalse);
    });
    testWidgets('clears overlay state after multiple opens and a final reset',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'One');
      await openOverlay(tester, config: QLSpatialConfig.dialog(), label: 'Two');
      QuantumOverlay.instance.resetForTesting();
      await tester.pump();
      expect(QuantumOverlay.instance.topNodeId, 0);
      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsNothing);
    });
    testWidgets('renders nested overlays without losing the parent overlay',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Parent');
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Child');
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
      QuantumOverlay.instance.closeTop();
      await tester.pumpAndSettle();
      expect(find.text('Parent'), findsOneWidget);
      expect(find.text('Child'), findsNothing);
    });
  });
}
