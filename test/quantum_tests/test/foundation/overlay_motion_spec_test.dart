import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('QLMotionSpec', () {
    test('returns the default spec for null input', () {
      final spec = QLMotionSpec.fromValue(null);
      expect(spec.type, isNull);
      expect(spec.duration, isNull);
      expect(spec.fromScale, isNull);
      expect(spec.raw, isEmpty);
    });
    test('parses type, curve, and duration from a map', () {
      final spec = QLMotionSpec.fromValue({
        'type': 'fadeScale',
        'curve': 'linear',
        'durationMs': 240,
      });
      expect(spec.type, 'fadeScale');
      expect(spec.curveName, 'linear');
      expect(spec.duration, const Duration(milliseconds: 240));
    });
    test('parses offsets from fromTranslate and toTranslate maps', () {
      final spec = QLMotionSpec.fromValue({
        'fromTranslate': {'x': 12, 'y': 18},
        'toTranslate': {'x': -4, 'y': 5},
      });
      expect(spec.fromTranslate, const Offset(12, 18));
      expect(spec.toTranslate, const Offset(-4, 5));
    });
    test('falls back to fromX and fromY when translate maps are absent', () {
      final spec =
          QLMotionSpec.fromValue({'fromX': 8, 'fromY': 9, 'toX': 1, 'toY': 2});
      expect(spec.fromTranslate, const Offset(8, 9));
      expect(spec.toTranslate, const Offset(1, 2));
    });
    test('parses opacity, scale, blur, and zoom fields', () {
      final spec = QLMotionSpec.fromValue({
        'fromScale': 0.85,
        'toScale': 1.0,
        'fromOpacity': 0.0,
        'toOpacity': 1.0,
        'fromBlur': 18.0,
        'toBlur': 0.0,
        'zoomIn': true,
        'zoomScale': 0.92,
      });
      expect(spec.fromScale, 0.85);
      expect(spec.toScale, 1.0);
      expect(spec.fromOpacity, 0.0);
      expect(spec.toOpacity, 1.0);
      expect(spec.fromBlur, 18.0);
      expect(spec.toBlur, 0.0);
      expect(spec.zoomIn, isTrue);
      expect(spec.zoomScale, 0.92);
    });
    test('treats an invalid JSON string as a motion type fallback', () {
      final spec = QLMotionSpec.fromValue('fade');
      expect(spec.type, 'fade');
      expect(spec.raw['type'], 'fade');
    });
    test('builds a zoom preset from the resolved motion values', () {
      final spec = QLMotionSpec.fromValue({
        'zoomIn': true,
        'zoomScale': 0.86,
        'durationMs': 350,
        'curve': 'easeInOut'
      });
      final preset = spec.toPreset(QLTransitionPresets.dialog,
          screenSize: const Size(400, 800), pattern: QLSurfacePattern.centered);
      expect(preset.fromScale, 0.86);
      expect(preset.duration, const Duration(milliseconds: 350));
      expect(preset.curve, Curves.easeInOut);
    });
    test('builds a slide preset for edge-docked surfaces', () {
      final spec = QLMotionSpec.fromValue({'type': 'slide', 'durationMs': 320});
      final preset = spec.toPreset(QLTransitionPresets.drawer,
          screenSize: const Size(1200, 800),
          pattern: QLSurfacePattern.edgeDocked);
      expect(preset.fromTranslate, const Offset(-1, 0));
      expect(preset.duration, const Duration(milliseconds: 320));
    });
    test('builds a bottom-attached slide preset', () {
      final spec = QLMotionSpec.fromValue({'type': 'slideUp'});
      final preset = spec.toPreset(QLTransitionPresets.sheet,
          screenSize: const Size(400, 800),
          pattern: QLSurfacePattern.bottomAttached);
      expect(preset.fromTranslate, const Offset(0, 1));
    });
    test('keeps fallback values when no overrides are present', () {
      final fallback = QLTransitionPresets.dialog;
      final spec = QLMotionSpec.fromValue({});
      final preset = spec.toPreset(fallback,
          screenSize: const Size(320, 640), pattern: QLSurfacePattern.centered);
      expect(preset.fromScale, fallback.fromScale);
      expect(preset.fromOpacity, fallback.fromOpacity);
      expect(preset.fromTranslate, fallback.fromTranslate);
    });
    test('uses an explicit curve name instead of the fallback curve', () {
      final spec = QLMotionSpec.fromValue({'curve': 'bounceOut'});
      final preset = spec.toPreset(QLTransitionPresets.dialog,
          screenSize: const Size(320, 640), pattern: QLSurfacePattern.centered);
      expect(preset.curve, Curves.bounceOut);
    });
    test('keeps the current preset when the motion map is sparse', () {
      final spec = QLMotionSpec.fromValue({'type': 'fade'});
      final preset = spec.toPreset(QLTransitionPresets.dialog,
          screenSize: const Size(320, 640), pattern: QLSurfacePattern.centered);
      expect(preset.fromOpacity, 0.0);
      expect(preset.fromScale, QLTransitionPresets.dialog.fromScale);
    });
  });
}
