import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('Overlay mounting scenarios', () {
    testWidgets('mounts a sheet overlay and keeps it visible after a pump',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.sheet(), label: 'Sheet A');
      expect(find.text('Sheet A'), findsOneWidget);
    });
    testWidgets('mounts a drawer overlay from the left edge', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.drawer(edge: QLSheetEdge.left),
          label: 'Drawer Left');
      expect(find.text('Drawer Left'), findsOneWidget);
    });
    testWidgets('mounts a drawer overlay from the right edge', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.drawer(edge: QLSheetEdge.right),
          label: 'Drawer Right');
      expect(find.text('Drawer Right'), findsOneWidget);
    });
    testWidgets('mounts a window overlay with a resize edge', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.window(resizeEdges: QLResizeEdge.topLeft),
          label: 'Window A');
      expect(find.text('Window A'), findsOneWidget);
    });
    testWidgets('mounts a fullscreen overlay without a safe area',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.fullscreenDialog(useSafeArea: false),
          label: 'Fullscreen A');
      expect(find.text('Fullscreen A'), findsOneWidget);
    });
    testWidgets('mounts an anchored menu overlay', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.menu(
              targetLeft: 10, targetTop: 20, targetRight: 30, targetBottom: 40),
          label: 'Menu A');
      expect(find.text('Menu A'), findsOneWidget);
    });
    testWidgets('mounts a non-modal surface without a barrier', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.nonModal);
      await openOverlay(tester, config: config, label: 'NonModal A');
      expect(find.text('NonModal A'), findsOneWidget);
    });
    testWidgets('honors runtime insertBelowOlder when mounting with top mode',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(
              runtime: const QLOverlayRuntimeSpec(insertBelowOlder: true)),
          label: 'Older-first');
      final topBefore = QuantumOverlay.instance.topNodeId;
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(
              runtime: const QLOverlayRuntimeSpec(insertBelowOlder: true)),
          label: 'Older-second');
      expect(QuantumOverlay.instance.topNodeId, topBefore);
    });
    testWidgets('reopens cleanly after a manual reset', (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Before reset');
      QuantumOverlay.instance.resetForTesting();
      await tester.pump();
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'After reset');
      expect(find.text('After reset'), findsOneWidget);
    });
    testWidgets('keeps the app shell visible under overlay content',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Overlay shell');
      expect(find.text('app-shell'), findsOneWidget);
      expect(find.text('Overlay shell'), findsOneWidget);
    });
    testWidgets(
        'supports rapid mount and close cycles without leaking visible content',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      for (var i = 0; i < 3; i += 1) {
        await openOverlay(tester,
            config: QLSpatialConfig.dialog(), label: 'Cycle $i');
        QuantumOverlay.instance.closeTop();
        await tester.pumpAndSettle();
      }
      expect(find.text('Cycle 0'), findsNothing);
      expect(find.text('Cycle 1'), findsNothing);
      expect(find.text('Cycle 2'), findsNothing);
    });
    testWidgets('uses runtime closeOnEscape=false to keep overlays open',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(
        tester,
        config: QLSpatialConfig.dialog(
            runtime: const QLOverlayRuntimeSpec(closeOnEscape: false)),
        label: 'No escape close',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('No escape close'), findsOneWidget);
    });
    testWidgets('uses runtime closeOnOutsideTap=false to keep overlays open',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(
        tester,
        config: QLSpatialConfig.dialog(
            runtime: const QLOverlayRuntimeSpec(closeOnOutsideTap: false)),
        label: 'No outside close',
      );
      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.text('No outside close'), findsOneWidget);
    });
    testWidgets('shows a custom builder that calls close directly',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      // ignore: unawaited_futures
      QuantumOverlay.instance.mount(
        null,
        QLSpatialConfig.dialog(),
        (context, close) => Material(
          child:
              TextButton(onPressed: close, child: const Text('Direct close')),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Direct close'));
      await tester.pumpAndSettle();
      expect(find.text('Direct close'), findsNothing);
    });
    testWidgets('preserves the top node id when a lower insertion is used',
        (tester) async {
      await pumpOverlayHarness(tester, child: const Text('app-shell'));
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(), label: 'Alpha');
      final topId = QuantumOverlay.instance.topNodeId;
      await openOverlay(tester,
          config: QLSpatialConfig.dialog(
              runtime: const QLOverlayRuntimeSpec(
                  insertMode: QLOverlayInsertMode.bottom)),
          label: 'Beta');
      expect(QuantumOverlay.instance.topNodeId, topId);
    });
  });
}
