import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('QLSpatialConfig', () {
    test('dialog config sets the expected modal flags and defaults', () {
      final config = QLSpatialConfig.dialog();
      expect((config.flags & QLNodeFlags.isModal) != 0, isTrue);
      expect((config.flags & QLNodeFlags.hasBarrier) != 0, isTrue);
      expect((config.flags & QLNodeFlags.dismissible) != 0, isTrue);
      expect(config.transition, QLTransitionMode.fadeScale);
      expect(config.bgEffect, QLBackgroundEffect.blur);
      expect(config.useSafeArea, isTrue);
      expect(config.surfacePattern, QLSurfacePattern.centered);
    });
    test('fullscreen dialogs are modal without outside-tap dismissal', () {
      final config =
          QLSpatialConfig.fullscreenDialog(barrierDismissible: false);
      expect((config.flags & QLNodeFlags.isModal) != 0, isTrue);
      expect((config.flags & QLNodeFlags.hasBarrier) != 0, isTrue);
      expect((config.flags & QLNodeFlags.dismissible) != 0, isFalse);
      expect(config.transition, QLTransitionMode.fullscreen);
      expect(config.useSafeArea, isFalse);
      expect(config.surfacePattern, QLSurfacePattern.fullScreen);
    });
    test('bottom sheets use a slide-up transition and drag handle', () {
      final config = QLSpatialConfig.sheet();
      expect(config.transition, QLTransitionMode.slideUp);
      expect(config.bgEffect, QLBackgroundEffect.zoomBack);
      expect(config.showDragHandle, isTrue);
      expect(config.sheetEdge, QLSheetEdge.bottom);
      expect(config.sheetAlignment, Alignment.bottomCenter);
    });
    test('top sheets resolve to slide-down and top alignment', () {
      final config = QLSpatialConfig.sheet(edge: QLSheetEdge.top);
      expect(config.transition, QLTransitionMode.slideDown);
      expect(config.sheetEdge, QLSheetEdge.top);
      expect(config.sheetAlignment, Alignment.topCenter);
    });
    test('drawer factory maps left edge to a slide-right transition', () {
      final config = QLSpatialConfig.drawer(edge: QLSheetEdge.left);
      expect(config.transition, QLTransitionMode.slideRight);
      expect(config.surfacePattern, QLSurfacePattern.edgeDocked);
      expect(config.allowDragging, isTrue);
      expect(config.allowResizing, isFalse);
      expect(config.showDragHandle, isTrue);
    });
    test('drawer factory maps right edge to a slide-left transition', () {
      final config = QLSpatialConfig.drawer(edge: QLSheetEdge.right);
      expect(config.transition, QLTransitionMode.slideLeft);
      expect(config.sheetEdge, QLSheetEdge.right);
    });
    test('menu surfaces are anchored floating overlays with menu flags', () {
      final config = QLSpatialConfig.menu(
          targetLeft: 1, targetTop: 2, targetRight: 3, targetBottom: 4);
      expect((config.flags & QLNodeFlags.isMenu) != 0, isTrue);
      expect((config.flags & QLNodeFlags.dismissible) != 0, isTrue);
      expect(config.transition, QLTransitionMode.popover);
      expect(config.surfacePattern, QLSurfacePattern.anchoredFloating);
      expect(config.allowDragging, isFalse);
      expect(config.allowResizing, isFalse);
    });
    test('menu surfaces can be made modal', () {
      final config = QLSpatialConfig.menu(
          targetLeft: 1,
          targetTop: 2,
          targetRight: 3,
          targetBottom: 4,
          isModal: true);
      expect((config.flags & QLNodeFlags.isModal) != 0, isTrue);
      expect((config.flags & QLNodeFlags.hasBarrier) != 0, isTrue);
    });
    test('toast surfaces are auto-closing temporary overlays', () {
      final config =
          QLSpatialConfig.toast(duration: const Duration(seconds: 7));
      expect((config.flags & QLNodeFlags.autoClose) != 0, isTrue);
      expect((config.flags & QLNodeFlags.isDraggable) != 0, isTrue);
      expect(config.timeout, const Duration(seconds: 7));
      expect(config.closeOnOutsideTap, isFalse);
      expect(config.surfacePattern, QLSurfacePattern.temporaryOverlay);
    });
    test('notification surfaces preserve the requested position', () {
      final config = QLSpatialConfig.notification(
          position: Alignment.topRight,
          duration: const Duration(milliseconds: 900));
      expect(config.anchor, Alignment.topRight);
      expect(config.timeout, const Duration(milliseconds: 900));
      expect(config.allowDragging, isTrue);
    });
    test('window surfaces preserve resize and geometry fields', () {
      final config = QLSpatialConfig.window(
          initialX: 25, initialY: 40, initialWidth: 640, initialHeight: 360);
      expect(config.anchor, Alignment.topLeft);
      expect(config.offsetX, 25);
      expect(config.offsetY, 40);
      expect(config.initialWidth, 640);
      expect(config.initialHeight, 360);
      expect(config.allowResizing, isTrue);
      expect(config.transition, QLTransitionMode.windowDrop);
    });
    test('surface factory carries custom runtime and root colors', () {
      final runtime =
          const QLOverlayRuntimeSpec(allowDrag: true, lockClose: true);
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.bottomAttached,
        edge: QLSheetEdge.left,
        rootBgColor: const Color(0xFF112233),
        barrierColor: const Color(0xFF445566),
        runtime: runtime,
      );
      expect(config.rootBgColor, const Color(0xFF112233));
      expect(config.barrierColor, const Color(0xFF445566));
      expect(config.runtime.allowDrag, isTrue);
      expect(config.runtime.lockClose, isTrue);
    });
    test('surface factory respects sheet padding, radius, and clipping', () {
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.bottomAttached,
        sheetPadding: const EdgeInsets.fromLTRB(1, 2, 3, 4),
        sheetBorderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
      );
      expect(config.sheetPadding, const EdgeInsets.fromLTRB(1, 2, 3, 4));
      expect(config.sheetBorderRadius, BorderRadius.circular(18));
      expect(config.clipBehavior, Clip.antiAlias);
    });
    test('surface factory keeps non-modal patterns non-modal', () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.nonModal);
      expect((config.flags & QLNodeFlags.isModal) != 0, isFalse);
      expect((config.flags & QLNodeFlags.hasBarrier) != 0, isFalse);
      expect(config.surfacePattern, QLSurfacePattern.nonModal);
    });
    test(
        'surface factory turns bottom-attached shapes into edge-docked when the edge is not bottom',
        () {
      final config = QLSpatialConfig.surface(
          pattern: QLSurfacePattern.bottomAttached, edge: QLSheetEdge.left);
      expect(config.surfacePattern, QLSurfacePattern.edgeDocked);
      expect(config.sheetEdge, QLSheetEdge.left);
    });
    test('surface factory forwards initial dimensions and constraints', () {
      final config = QLSpatialConfig.surface(
          pattern: QLSurfacePattern.centered,
          initialWidth: 321,
          initialHeight: 654,
          constraints: const BoxConstraints(maxWidth: 777, maxHeight: 888));
      expect(config.initialWidth, 321);
      expect(config.initialHeight, 654);
      expect(config.constraints.maxWidth, 777);
      expect(config.constraints.maxHeight, 888);
    });
  });
}
