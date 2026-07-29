import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/src/ui/quantum_overlays.dart';
import 'package:quantum_layout/src/ui/quantum_animation_engine.dart';
import 'package:flutter/services.dart';

Future<BuildContext> pumpOverlayHarness(
  WidgetTester tester, {
  required Widget child,
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      home: QLOverlayRoot(
        child: Builder(
          builder: (context) {
            captured = context;
            return child;
          },
        ),
      ),
    ),
  );
  await tester.pump();
  return captured;
}

Transform backgroundTransform(WidgetTester tester) {
  for (final transform
      in tester.widgetList<Transform>(find.byType(Transform))) {
    if (transform.alignment != null) return transform;
  }
  throw StateError('No background transform found.');
}

ClipRRect backgroundClipRRect(WidgetTester tester) {
  for (final clip in tester.widgetList<ClipRRect>(find.byType(ClipRRect))) {
    if (clip.borderRadius != BorderRadius.zero) return clip;
  }
  throw StateError('No background clip found.');
}

Container containerWithColor(WidgetTester tester, Color color) {
  for (final container
      in tester.widgetList<Container>(find.byType(Container))) {
    if (container.color == color) return container;
  }
  throw StateError('No container found with the expected color.');
}

Positioned firstPositioned(WidgetTester tester) {
  final positioned = tester.widgetList<Positioned>(find.byType(Positioned));
  if (positioned.isEmpty) {
    throw StateError('No Positioned widget found.');
  }
  return positioned.first;
}

Align alignWith(WidgetTester tester, Alignment alignment) {
  for (final align in tester.widgetList<Align>(find.byType(Align))) {
    if (align.alignment == alignment) return align;
  }
  throw StateError('No Align widget found for $alignment.');
}

Future<void> settleOverlay(WidgetTester tester,
    [Duration duration = const Duration(milliseconds: 500)]) async {
  await tester.pump(duration);
  await tester.pump();
}

void main() {
  setUp(QuantumOverlay.instance.resetForTesting);
  group('QLOverlayRuntimeSpec', () {
    test('returns defaults when the runtime value is null', () {
      const spec = QLOverlayRuntimeSpec();
      final parsed = QLOverlayRuntimeSpec.fromValue(null);

      expect(parsed.allowDrag, equals(spec.allowDrag));
      expect(parsed.allowResize, equals(spec.allowResize));
      expect(parsed.allowSwap, equals(spec.allowSwap));
      expect(parsed.closeOnEscape, equals(spec.closeOnEscape));
      expect(parsed.allowedEdges, isEmpty);
      expect(parsed.extra, isEmpty);
    });
    test('reads allowDrag and enableDrag as the same semantic flag', () {
      final parsed = QLOverlayRuntimeSpec.fromValue({
        'allowDrag': false,
        'enableDrag': true,
        'allowResize': true,
      });

      expect(parsed.allowDrag, isTrue);
      expect(parsed.allowResize, isTrue);
    });
    test('treats malformed JSON strings as raw payload instead of throwing',
        () {
      final parsed = QLOverlayRuntimeSpec.fromValue('{not-json');

      expect(parsed.extra['raw'], equals('{not-json'));
      expect(parsed.allowClose, isTrue);
      expect(parsed.closeOnOutsideTap, isTrue);
    });
    test('stringifies non-string map keys before parsing values', () {
      final parsed = QLOverlayRuntimeSpec.fromValue({
        1: true,
        2: 'top',
        3: ['left', 'right', 99],
      });

      expect(parsed.extra['1'], isTrue);
      expect(parsed.preferredEdge, isNull);
      expect(parsed.allowedEdges, isEmpty);
    });
    test(
        'copies hooks actions native and extra maps into an isolated runtime spec',
        () {
      final source = {
        'hooks': {'afterOpen': 1},
        'actions': {'close': 2},
        'native': {'channel': 'media'},
        'allowClose': false,
      };
      final parsed = QLOverlayRuntimeSpec.fromValue(source);
      source['hooks'] = {'mutated': true};
      source['actions'] = {'mutated': true};
      source['native'] = {'mutated': true};

      expect(parsed.hooks['afterOpen'], equals(1));
      expect(parsed.actions['close'], equals(2));
      expect(parsed.native['channel'], equals('media'));
      expect(parsed.allowClose, isFalse);
    });
    test('resolves the preferred edge from the preferredEdge alias', () {
      final parsed = QLOverlayRuntimeSpec.fromValue({'preferredEdge': 'TOP'});

      expect(parsed.preferredEdge, equals(QLSheetEdge.top));
    });
    test('resolves the preferred edge from the legacy edge alias', () {
      final parsed = QLOverlayRuntimeSpec.fromValue({'edge': 'right'});

      expect(parsed.preferredEdge, equals(QLSheetEdge.right));
    });
    test('filters allowed edges down to valid enum values only', () {
      final parsed = QLOverlayRuntimeSpec.fromValue({
        'allowedEdges': ['top', 'left', 'invalid', 9, 'bottom'],
      });

      expect(parsed.allowedEdges,
          equals([QLSheetEdge.top, QLSheetEdge.left, QLSheetEdge.bottom]));
    });
    test('maps insertMode bottom explicitly', () {
      final parsed = QLOverlayRuntimeSpec.fromValue({'insertMode': 'bottom'});

      expect(parsed.insertMode, equals(QLOverlayInsertMode.bottom));
    });
    test('maps insertMode above_older alias', () {
      final parsed =
          QLOverlayRuntimeSpec.fromValue({'insertMode': 'above_older'});

      expect(parsed.insertMode, equals(QLOverlayInsertMode.aboveOlder));
    });
    test('maps insertMode belowOlder alias', () {
      final parsed =
          QLOverlayRuntimeSpec.fromValue({'insertMode': 'belowOlder'});

      expect(parsed.insertMode, equals(QLOverlayInsertMode.belowOlder));
    });
    test('maps insertMode index alias to atIndex', () {
      final parsed = QLOverlayRuntimeSpec.fromValue(
          {'insertMode': 'index', 'insertIndex': 3});

      expect(parsed.insertMode, equals(QLOverlayInsertMode.atIndex));
      expect(parsed.insertIndex, equals(3));
    });
    test('falls back to top insert mode for unknown values', () {
      final parsed =
          QLOverlayRuntimeSpec.fromValue({'insertMode': 'something-else'});

      expect(parsed.insertMode, equals(QLOverlayInsertMode.top));
    });
    test('keeps the current edge when swapping is locked', () {
      const parsed = QLOverlayRuntimeSpec(lockSwap: true);

      expect(parsed.resolveEdge(QLSheetEdge.bottom, dx: 0, dy: -200),
          equals(QLSheetEdge.bottom));
    });
    test('keeps the current edge when swapping is disabled', () {
      const parsed = QLOverlayRuntimeSpec(allowSwap: false);

      expect(parsed.resolveEdge(QLSheetEdge.left, dx: 180, dy: 0),
          equals(QLSheetEdge.left));
    });
    test('forces the first allowed edge when the current edge is not allowed',
        () {
      const parsed = QLOverlayRuntimeSpec(
        allowedEdges: [QLSheetEdge.left, QLSheetEdge.right],
      );

      expect(parsed.resolveEdge(QLSheetEdge.bottom, dx: 0, dy: 0),
          equals(QLSheetEdge.left));
    });
    test('swaps bottom to top on a strong upward drag', () {
      const parsed = QLOverlayRuntimeSpec();

      expect(parsed.resolveEdge(QLSheetEdge.bottom, dx: 0, dy: -81),
          equals(QLSheetEdge.top));
    });
    test('swaps bottom to left on a strong leftward drag', () {
      const parsed = QLOverlayRuntimeSpec();

      expect(parsed.resolveEdge(QLSheetEdge.bottom, dx: -81, dy: 0),
          equals(QLSheetEdge.left));
    });
    test('swaps bottom to right on a strong rightward drag', () {
      const parsed = QLOverlayRuntimeSpec();

      expect(parsed.resolveEdge(QLSheetEdge.bottom, dx: 81, dy: 0),
          equals(QLSheetEdge.right));
    });
    test('swaps top to bottom on a strong downward drag', () {
      const parsed = QLOverlayRuntimeSpec();

      expect(parsed.resolveEdge(QLSheetEdge.top, dx: 0, dy: 81),
          equals(QLSheetEdge.bottom));
    });
    test('swaps left to right on a strong rightward drag', () {
      const parsed = QLOverlayRuntimeSpec();

      expect(parsed.resolveEdge(QLSheetEdge.left, dx: 81, dy: 0),
          equals(QLSheetEdge.right));
    });
    test('swaps right to left on a strong leftward drag', () {
      const parsed = QLOverlayRuntimeSpec();

      expect(parsed.resolveEdge(QLSheetEdge.right, dx: -81, dy: 0),
          equals(QLSheetEdge.left));
    });
    test('accepts mixed-case edge names when parsing from values', () {
      final parsed =
          QLOverlayRuntimeSpec.fromValue({'preferredEdge': '  Left  '});

      expect(parsed.preferredEdge, equals(QLSheetEdge.left));
    });
  });
  group('QLMotionSpec', () {
    test('returns the empty motion spec when the input is null', () {
      const spec = QLMotionSpec();

      final parsed = QLMotionSpec.fromValue(null);

      expect(parsed.type, isNull);
      expect(parsed.raw, isEmpty);
      expect(parsed.duration, isNull);
      expect(parsed.zoomIn, isNull);
      expect(parsed.fromTranslate, isNull);
    });
    test(
        'treats malformed strings as a type fallback instead of a parse failure',
        () {
      final parsed = QLMotionSpec.fromValue('fadeScale');

      expect(parsed.type, equals('fadeScale'));
      expect(parsed.raw['type'], equals('fadeScale'));
    });
    test('parses a complete motion map and keeps the raw payload intact', () {
      final parsed = QLMotionSpec.fromValue({
        'type': 'slide',
        'curve': 'easeInOut',
        'duration': 240,
        'fromScale': 0.72,
        'toScale': 1.0,
        'fromOpacity': 0.1,
        'toOpacity': 0.9,
        'fromBlur': 4,
        'toBlur': 0,
        'zoomIn': true,
        'zoomScale': 0.8,
      });

      expect(parsed.type, equals('slide'));
      expect(parsed.curveName, equals('easeInOut'));
      expect(parsed.duration, equals(const Duration(milliseconds: 240)));
      expect(parsed.fromScale, equals(0.72));
      expect(parsed.toScale, equals(1.0));
      expect(parsed.zoomIn, isTrue);
      expect(parsed.zoomScale, equals(0.8));
    });
    test('parses durationMs when duration is absent', () {
      final parsed = QLMotionSpec.fromValue({'durationMs': 375});

      expect(parsed.duration, equals(const Duration(milliseconds: 375)));
    });
    test('preserves Duration instances directly', () {
      final parsed =
          QLMotionSpec.fromValue({'duration': const Duration(seconds: 2)});

      expect(parsed.duration, equals(const Duration(seconds: 2)));
    });
    test('parses fromTranslate from an x/y map', () {
      final parsed = QLMotionSpec.fromValue({
        'fromTranslate': {'x': 12, 'y': -6},
      });

      expect(parsed.fromTranslate, equals(const Offset(12, -6)));
    });
    test('parses fromTranslate from a two-item list', () {
      final parsed = QLMotionSpec.fromValue({
        'fromTranslate': [3, 7],
      });

      expect(parsed.fromTranslate, equals(const Offset(3, 7)));
    });
    test('falls back to fromX and fromY when fromTranslate is missing', () {
      final parsed = QLMotionSpec.fromValue({
        'fromX': 2,
        'fromY': 9,
      });

      expect(parsed.fromTranslate, equals(const Offset(2, 9)));
    });
    test('parses toTranslate from an x/y map', () {
      final parsed = QLMotionSpec.fromValue({
        'toTranslate': {'x': -12, 'y': 6},
      });

      expect(parsed.toTranslate, equals(const Offset(-12, 6)));
    });
    test('falls back to toX and toY when toTranslate is missing', () {
      final parsed = QLMotionSpec.fromValue({
        'toX': -4,
        'toY': 10,
      });

      expect(parsed.toTranslate, equals(const Offset(-4, 10)));
    });
    test('maps linear curve names to Curves.linear', () {
      final parsed = QLMotionSpec.fromValue({'curve': 'linear'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.curve, equals(Curves.linear));
    });
    test('maps easeIn curve names to Curves.easeIn', () {
      final parsed = QLMotionSpec.fromValue({'curve': 'easeIn'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.curve, equals(Curves.easeIn));
    });
    test('maps spring curve names to Curves.elasticOut', () {
      final parsed = QLMotionSpec.fromValue({'curve': 'spring'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.easeOutCubic,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.curve, equals(Curves.elasticOut));
    });
    test('falls back to easeOutCubic for unknown curve names', () {
      final parsed = QLMotionSpec.fromValue({'curve': 'mystery'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.curve, equals(Curves.easeOutCubic));
    });
    test(
        'treats zoom types as a zooming entrance and applies the custom zoom scale',
        () {
      final parsed = QLMotionSpec.fromValue({
        'type': 'zoom',
        'zoomIn': true,
        'zoomScale': 0.81,
      });
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.fromScale, equals(0.81));
      expect(preset.fromOpacity, equals(0.0));
    });
    test('treats fade types as zero-opacity entrances', () {
      final parsed = QLMotionSpec.fromValue({'type': 'fade'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.fromOpacity, equals(0.0));
      expect(preset.fromScale, equals(0.5));
    });
    test('treats spring types as zero-opacity entrances', () {
      final parsed = QLMotionSpec.fromValue({'type': 'spring'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.fromOpacity, equals(0.0));
    });
    test('resolves slide motion for edge-docked overlays', () {
      final parsed = QLMotionSpec.fromValue({'type': 'slide'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
        pattern: QLSurfacePattern.edgeDocked,
      );

      expect(preset.fromTranslate, equals(const Offset(-1, 0)));
    });
    test('resolves slide motion for bottom-attached overlays', () {
      final parsed = QLMotionSpec.fromValue({'type': 'slide'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
        pattern: QLSurfacePattern.bottomAttached,
      );

      expect(preset.fromTranslate, equals(const Offset(0, 1)));
    });
    test('resolves slide motion for anchored floating overlays', () {
      final parsed = QLMotionSpec.fromValue({'type': 'slide'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
        pattern: QLSurfacePattern.anchoredFloating,
      );

      expect(preset.fromTranslate, equals(const Offset(0, 0.08)));
    });
    test('resolves slide motion for the default pattern', () {
      final parsed = QLMotionSpec.fromValue({'type': 'slide'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.5,
          fromOpacity: 0.4,
          fromTranslate: Offset.zero,
          fromBlur: 0.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
        pattern: QLSurfacePattern.modal,
      );

      expect(preset.fromTranslate, equals(const Offset(0, 0.14)));
    });
    test(
        'honors explicit scale opacity and blur overrides over fallback values',
        () {
      final parsed = QLMotionSpec.fromValue({
        'fromScale': 0.66,
        'fromOpacity': 0.22,
        'fromBlur': 8,
        'duration': 99,
      });
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.9,
          fromOpacity: 0.9,
          fromTranslate: const Offset(1, 1),
          fromBlur: 1.0,
          curve: Curves.linear,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.fromScale, equals(0.66));
      expect(preset.fromOpacity, equals(0.22));
      expect(preset.fromBlur, equals(8));
      expect(preset.duration, equals(const Duration(milliseconds: 99)));
    });
    test('prefers curveName over the fallback preset curve when both exist',
        () {
      final parsed = QLMotionSpec.fromValue({'curve': 'easeInCubic'});
      final preset = parsed.toPreset(
        QLTransitionPreset(
          fromScale: 0.9,
          fromOpacity: 0.9,
          fromTranslate: const Offset(1, 1),
          fromBlur: 1.0,
          curve: Curves.bounceOut,
          duration: const Duration(milliseconds: 300),
        ),
        screenSize: const Size(800, 600),
      );

      expect(preset.curve, equals(Curves.easeInCubic));
    });
  });
  group('QLSpatialConfig', () {
    test('builds a modal surface with barrier and dismissible flags', () {
      final config = QLSpatialConfig.surface(pattern: QLSurfacePattern.modal);

      expect(config.flags & QLNodeFlags.isModal, isNot(0));
      expect(config.flags & QLNodeFlags.hasBarrier, isNot(0));
      expect(config.flags & QLNodeFlags.dismissible, isNot(0));
      expect(config.closeOnOutsideTap, isTrue);
      expect(config.transition, equals(QLTransitionMode.fadeScale));
    });
    test('builds a non-modal surface without modal barrier flags', () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.nonModal);

      expect(config.flags & QLNodeFlags.isModal, equals(0));
      expect(config.flags & QLNodeFlags.hasBarrier, equals(0));
      expect(config.transition, equals(QLTransitionMode.fadeScale));
    });
    test('keeps the centered surface pattern on a centered overlay', () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.centered);

      expect(config.surfacePattern, equals(QLSurfacePattern.centered));
      expect(config.transition, equals(QLTransitionMode.fadeScale));
    });
    test('maps edge-docked left surfaces to slideRight transitions', () {
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.edgeDocked,
        edge: QLSheetEdge.left,
      );

      expect(config.surfacePattern, equals(QLSurfacePattern.edgeDocked));
      expect(config.transition, equals(QLTransitionMode.slideRight));
    });
    test('maps edge-docked right surfaces to slideLeft transitions', () {
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.edgeDocked,
        edge: QLSheetEdge.right,
      );

      expect(config.transition, equals(QLTransitionMode.slideLeft));
    });
    test('maps edge-docked top surfaces to slideDown transitions', () {
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.edgeDocked,
        edge: QLSheetEdge.top,
      );

      expect(config.transition, equals(QLTransitionMode.slideDown));
    });
    test('maps edge-docked bottom surfaces to slideUp transitions', () {
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.edgeDocked,
        edge: QLSheetEdge.bottom,
      );

      expect(config.transition, equals(QLTransitionMode.slideUp));
    });
    test(
        'normalizes bottom-attached surfaces with a non-bottom edge into edge-docked mode',
        () {
      final config = QLSpatialConfig.surface(
        pattern: QLSurfacePattern.bottomAttached,
        edge: QLSheetEdge.left,
      );

      expect(config.surfacePattern, equals(QLSurfacePattern.edgeDocked));
      expect(config.transition, equals(QLTransitionMode.slideUp));
      expect(config.sheetEdge, equals(QLSheetEdge.bottom));
    });
    test('marks temporary overlays as auto-closing popovers', () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.temporaryOverlay);

      expect(config.flags & QLNodeFlags.autoClose, isNot(0));
      expect(config.transition, equals(QLTransitionMode.popover));
    });
    test('marks anchored floating surfaces as menu-like popovers', () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.anchoredFloating);

      expect(config.flags & QLNodeFlags.isMenu, isNot(0));
      expect(config.transition, equals(QLTransitionMode.popover));
    });
    test('uses darken for fullscreen surfaces and leaves them safe-area aware',
        () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.fullScreen);

      expect(config.bgEffect, equals(QLBackgroundEffect.darken));
      expect(config.transition, equals(QLTransitionMode.fullscreen));
      expect(config.flags & QLNodeFlags.useSafeArea, isNot(0));
    });
    test('keeps persistent panels on a neutral background effect', () {
      final config =
          QLSpatialConfig.surface(pattern: QLSurfacePattern.persistentPanel);

      expect(config.bgEffect, equals(QLBackgroundEffect.none));
      expect(config.surfacePattern, equals(QLSurfacePattern.persistentPanel));
    });
    test('builds a dialog that disables outside dismissal when requested', () {
      final config = QLSpatialConfig.dialog(barrierDismissible: false);

      expect(config.flags & QLNodeFlags.dismissible, equals(0));
      expect(config.closeOnOutsideTap, isFalse);
      expect(config.flags & QLNodeFlags.hasBarrier, isNot(0));
    });
    test('builds a fullscreen dialog that can still honor safe-area mode', () {
      final config = QLSpatialConfig.fullscreenDialog(useSafeArea: true);

      expect(config.flags & QLNodeFlags.useSafeArea, isNot(0));
      expect(config.transition, equals(QLTransitionMode.fullscreen));
    });
    test('builds a bottom sheet with its default drag and alignment contract',
        () {
      final config = QLSpatialConfig.sheet();

      expect(config.transition, equals(QLTransitionMode.slideUp));
      expect(config.sheetEdge, equals(QLSheetEdge.bottom));
      expect(config.sheetAlignment, equals(Alignment.bottomCenter));
      expect(config.flags & QLNodeFlags.isDraggable, isNot(0));
    });
    test(
        'builds a top sheet with a top-centered alignment and slide-down transition',
        () {
      final config = QLSpatialConfig.sheet(edge: QLSheetEdge.top);

      expect(config.transition, equals(QLTransitionMode.slideDown));
      expect(config.sheetAlignment, equals(Alignment.topCenter));
    });
    test(
        'builds a left drawer with its initial width resolved from the constraint width',
        () {
      final config = QLSpatialConfig.drawer(
        edge: QLSheetEdge.left,
        constraints: const BoxConstraints(maxWidth: 512, maxHeight: 720),
      );

      expect(config.surfacePattern, equals(QLSurfacePattern.edgeDocked));
      expect(config.initialWidth, equals(512));
      expect(config.initialHeight, isNull);
    });
    test(
        'builds a top drawer with its initial height resolved from the constraint height',
        () {
      final config = QLSpatialConfig.drawer(
        edge: QLSheetEdge.top,
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 384),
      );

      expect(config.initialWidth, isNull);
      expect(config.initialHeight, equals(384));
    });
    test('builds an anchored menu that can match the anchor width', () {
      final config = QLSpatialConfig.menu(
        targetLeft: 12,
        targetTop: 18,
        targetRight: 92,
        targetBottom: 54,
        matchAnchorWidth: true,
      );

      expect(config.flags & QLNodeFlags.isMenu, isNot(0));
      expect(config.flags & QLNodeFlags.matchAnchorWidth, isNot(0));
      expect(config.transition, equals(QLTransitionMode.popover));
    });
    test('builds a notification overlay with timeout and draggable behavior',
        () {
      final config = QLSpatialConfig.notification(
        position: Alignment.bottomRight,
        duration: const Duration(milliseconds: 900),
      );

      expect(config.timeout, equals(const Duration(milliseconds: 900)));
      expect(config.flags & QLNodeFlags.autoClose, isNot(0));
      expect(config.flags & QLNodeFlags.isDraggable, isNot(0));
    });
    test('builds a toast overlay that keeps outside taps disabled', () {
      final config = QLSpatialConfig.toast();

      expect(config.closeOnOutsideTap, isFalse);
      expect(config.surfacePattern, equals(QLSurfacePattern.temporaryOverlay));
    });
    test('builds a window overlay with drag and resize semantics', () {
      final config = QLSpatialConfig.window(
        initialX: 44,
        initialY: 88,
        initialWidth: 500,
        initialHeight: 320,
        allowResize: false,
      );

      expect(config.flags & QLNodeFlags.isDraggable, isNot(0));
      expect(config.flags & QLNodeFlags.allowResize, equals(0));
      expect(config.flags & QLNodeFlags.extrude3D, isNot(0));
      expect(config.anchor, equals(Alignment.topLeft));
    });
  });
  group('QuantumOverlay lifecycle', () {
    test('resets the overlay engine back to an empty state', () {
      QuantumOverlay.instance.resetForTesting();
      expect(QuantumOverlay.instance.topNodeId, equals(0));
    });
    test('mounts a single overlay and exposes a non-zero top node id', () {
      final future = QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, isNonZero);
      expect(future, isA<Future<void>>()); // ✅ FIXED
    });
    testWidgets(
        'completes a mounted overlay future when the close callback is invoked',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(),
        (context, close) {
          return Center(
            child: TextButton(
              onPressed: close,
              child: const Text('close'),
            ),
          );
        },
      );

      await tester.pump();
      await tester.tap(find.text('close'));
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'closeTop closes the active overlay when the runtime allows closing',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('closeTop respects a runtime that forbids closing',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(runtime: QLOverlayRuntimeSpec(allowClose: false)),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.closeTop();
      await tester.pump();
      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    testWidgets('closeTop respects a locked-close runtime', (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(runtime: QLOverlayRuntimeSpec(lockClose: true)),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.closeTop();
      await tester.pump();
      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    test('top insertion makes the newest overlay the top node', () {
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(
          runtime: QLOverlayRuntimeSpec(insertMode: QLOverlayInsertMode.top),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, isNot(equals(before)));
    });
    test('bottom insertion keeps the earlier overlay at the top of the stack',
        () {
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(
          runtime: QLOverlayRuntimeSpec(insertMode: QLOverlayInsertMode.bottom),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    test('aboveOlder insertion appends a newer overlay above the previous one',
        () {
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(
          runtime:
              QLOverlayRuntimeSpec(insertMode: QLOverlayInsertMode.aboveOlder),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, isNot(equals(before)));
    });
    test('belowOlder insertion pushes a newer overlay underneath older entries',
        () {
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(
          runtime:
              QLOverlayRuntimeSpec(insertMode: QLOverlayInsertMode.belowOlder),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    test('atIndex insertion can place a newer overlay at the front', () {
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(
          runtime: QLOverlayRuntimeSpec(
            insertMode: QLOverlayInsertMode.atIndex,
            insertIndex: 0,
          ),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    test('atIndex insertion clamps to the end when the index is oversized', () {
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );
      final before = QuantumOverlay.instance.topNodeId;
      QuantumOverlay.instance.mount<void>(
        null,
        const QLSpatialConfig(
          runtime: QLOverlayRuntimeSpec(
            insertMode: QLOverlayInsertMode.atIndex,
            insertIndex: 999,
          ),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      expect(QuantumOverlay.instance.topNodeId, isNot(equals(before)));
    });
    testWidgets(
        'escape key closes the top overlay when the overlay allows escape dismissal',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('escape key leaves a non-closable overlay untouched',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(runtime: QLOverlayRuntimeSpec(allowClose: false)),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      final before = QuantumOverlay.instance.topNodeId;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    testWidgets('outside tap closes a dismissible dialog overlay',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = QuantumOverlay.instance.mount<void>(
        root,
        QLSpatialConfig.dialog(barrierDismissible: true),
        (_, __) => const SizedBox(width: 120, height: 120),
      );

      await tester.pump();
      await tester.tapAt(const Offset(4, 4));
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('outside tap does not close a non-dismissible overlay',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      QuantumOverlay.instance.mount<void>(
        root,
        QLSpatialConfig.dialog(barrierDismissible: false),
        (_, __) => const SizedBox(width: 120, height: 120),
      );

      await tester.pump();
      final before = QuantumOverlay.instance.topNodeId;
      await tester.tapAt(const Offset(4, 4));
      await tester.pump();
      expect(QuantumOverlay.instance.topNodeId, equals(before));
    });
    testWidgets('notification overlays auto-close after their timeout',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = QuantumOverlay.instance.mount<void>(
        root,
        QLSpatialConfig.notification(
          duration: const Duration(milliseconds: 60),
        ),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'resetForTesting clears mounted overlays after a live root has been used',
        (tester) async {
      final root =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      QuantumOverlay.instance.mount<void>(
        root,
        const QLSpatialConfig(),
        (_, __) => const SizedBox.shrink(),
      );

      await tester.pump();
      expect(find.byType(Positioned), findsOneWidget);
      QuantumOverlay.instance.resetForTesting();
      await tester.pump();
      expect(find.byType(Positioned), findsNothing);
      expect(QuantumOverlay.instance.topNodeId, equals(0));
    });
  });
  group('QuantumOverlay widgets and helpers', () {
    testWidgets(
        'showQLDialog inserts a SafeArea wrapper when safe area is enabled',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        useSafeArea: true,
        builder: (_, close) => const SizedBox(width: 120, height: 120),
      );

      await tester.pump();
      expect(find.byType(SafeArea), findsWidgets);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('showQLDialog skips SafeArea when safe area is disabled',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        useSafeArea: false,
        builder: (_, close) => const SizedBox(width: 120, height: 120),
      );

      await tester.pump();
      expect(find.byType(SafeArea), findsNothing);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('showQLSheet with a drag handle inserts the handle column',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSheet(
        showDragHandle: true,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(find.byType(Column), findsWidgets);
      expect(find.byType(ClipRRect), findsWidgets);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'showQLSheet without a drag handle keeps the extra column out of the tree',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSheet(
        showDragHandle: false,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(find.byType(Column), findsNothing);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'showQLSheet with padding inserts a Padding wrapper around the content',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSheet(
        sheetPadding: const EdgeInsets.all(14),
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(find.byType(Padding), findsWidgets);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'showQLSheet with border radius and clipping adds a ClipRRect wrapper',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSheet(
        sheetBorderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(find.byType(ClipRRect), findsWidgets);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'showQLFullScreenDialog fills the overlay stack with a Positioned.fill node',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLFullScreenDialog(
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      final positioned = firstPositioned(tester);
      expect(positioned.left, equals(0.0));
      expect(positioned.top, equals(0.0));
      expect(positioned.right, equals(0.0));
      expect(positioned.bottom, equals(0.0));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('showQLNotify respects a custom bottom-right anchor',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLNotify(
        position: Alignment.bottomRight,
        duration: const Duration(milliseconds: 70),
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(alignWith(tester, Alignment.bottomRight), isNotNull);
      await tester.pump(const Duration(milliseconds: 90));
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('showQLToast uses the top-center anchor by default',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLToast(
        duration: const Duration(milliseconds: 70),
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(alignWith(tester, Alignment.topCenter), isNotNull);
      await tester.pump(const Duration(milliseconds: 90));
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('showQLWindow positions the node using the supplied geometry',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLWindow(
        initialX: 32,
        initialY: 48,
        initialWidth: 440,
        initialHeight: 260,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      final positioned = firstPositioned(tester);
      expect(positioned.left, equals(32.0));
      expect(positioned.top, equals(48.0));
      expect(positioned.width, equals(440.0));
      expect(positioned.height, equals(260.0));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'showQLMenu uses the anchor box position and width when requested',
        (tester) async {
      final anchorKey = GlobalKey();
      final context = await pumpOverlayHarness(
        tester,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            key: anchorKey,
            width: 80,
            height: 40,
          ),
        ),
      );
      final future = context.showQLMenu(
        anchorKey: anchorKey,
        matchAnchorWidth: true,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      final positioned = firstPositioned(tester);
      expect(positioned.left, isNotNull);
      expect(positioned.top, isNotNull);
      expect(positioned.width, isNotNull);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('showQLMenu does not mount when the anchor context is missing',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final missingKey = GlobalKey();

      await context.showQLMenu(
        anchorKey: missingKey,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(find.byType(Positioned), findsNothing);
    });
    testWidgets(
        'showQLMenu does not mount when the anchor has no render box size',
        (tester) async {
      final anchorKey = GlobalKey();
      final context = await pumpOverlayHarness(
        tester,
        child: SizedBox(key: anchorKey),
      );

      await context.showQLMenu(
        anchorKey: anchorKey,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(find.byType(Positioned), findsNothing);
    });
    testWidgets('the overlay root paints the configured background color',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        rootBgColor: Colors.teal,
        effect: QLBackgroundEffect.none,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(containerWithColor(tester, Colors.teal), isNotNull);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('zoomBack effect scales the background transform',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        effect: QLBackgroundEffect.zoomBack,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      final transform = backgroundTransform(tester);
      expect(transform.transform.storage[0], lessThan(1.0));
      expect(transform.transform.storage[5], lessThan(1.0));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('blur effect expands the background clip radius',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        effect: QLBackgroundEffect.blur,
        bgBlurSigma: 18,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      final clip = backgroundClipRRect(tester);
      expect(clip.borderRadius, equals(BorderRadius.circular(18)));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets(
        'darken effect leaves the background transform at identity while scrimming the screen',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        effect: QLBackgroundEffect.darken,
        barrierOpacity: 0.3,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      final transform = backgroundTransform(tester);
      expect(transform.transform.storage[0], equals(1.0));
      expect(transform.transform.storage[5], equals(1.0));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('no background effect clears the scrim container entirely',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSurface(
        pattern: QLSurfacePattern.nonModal,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(containerWithColor(tester, const Color(0x00000000)), isNotNull);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('slide-left overlays anchor the background to center-right',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDrawer(
        edge: QLSheetEdge.left,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(
          backgroundTransform(tester).alignment, equals(Alignment.centerRight));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('slide-right overlays anchor the background to center-left',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDrawer(
        edge: QLSheetEdge.right,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(
          backgroundTransform(tester).alignment, equals(Alignment.centerLeft));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('slide-up overlays anchor the background to bottom-center',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSheet(
        edge: QLSheetEdge.bottom,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(backgroundTransform(tester).alignment,
          equals(Alignment.bottomCenter));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('slide-down overlays anchor the background to top-center',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLSheet(
        edge: QLSheetEdge.top,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(
          backgroundTransform(tester).alignment, equals(Alignment.topCenter));
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('close callbacks can be driven from the built widget tree',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        effect: QLBackgroundEffect.none,
        builder: (_, close) {
          return Center(
            child: TextButton(
              onPressed: close,
              child: const Text('dismiss'),
            ),
          );
        },
      );

      await tester.pump();
      await tester.tap(find.text('dismiss'));
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
    testWidgets('custom barrier colors are reflected in the scrim container',
        (tester) async {
      final context =
          await pumpOverlayHarness(tester, child: const SizedBox.shrink());
      final future = context.showQLDialog(
        effect: QLBackgroundEffect.none,
        barrierColor: Colors.red,
        barrierOpacity: 0.25,
        builder: (_, close) => const SizedBox(width: 160, height: 160),
      );

      await tester.pump();
      expect(containerWithColor(tester, Colors.red.withValues(alpha: 0.25)),
          isNotNull);
      QuantumOverlay.instance.closeTop();
      await settleOverlay(tester);
      await expectLater(future, completion(isNull));
    });
  });
}
