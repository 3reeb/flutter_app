import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';
import '../test_support.dart';

void main() {
  setUp(resetQuantumState);
  tearDown(resetQuantumState);

  group('QLOverlayRuntimeSpec.fromValue', () {
    test('returns the default spec for null input', () {
      final spec = QLOverlayRuntimeSpec.fromValue(null);
      expect(spec.allowDrag, isFalse);
      expect(spec.allowResize, isFalse);
      expect(spec.allowSwap, isTrue);
      expect(spec.allowClose, isTrue);
      expect(spec.closeOnOutsideTap, isTrue);
      expect(spec.closeOnEscape, isTrue);
      expect(spec.useSafeArea, isTrue);
      expect(spec.newestOnTop, isTrue);
      expect(spec.insertMode, QLOverlayInsertMode.top);
      expect(spec.allowedEdges, isEmpty);
      expect(spec.extra, isEmpty);
    });
    test('parses flags and insertion fields from a map', () {
      final spec = QLOverlayRuntimeSpec.fromValue({
        'allowDrag': true,
        'allowResize': true,
        'allowSwap': false,
        'lockSwap': true,
        'allowClose': false,
        'lockClose': true,
        'allowUnderlyingInteraction': true,
        'closeOnOutsideTap': false,
        'closeOnEscape': false,
        'useSafeArea': false,
        'newestOnTop': false,
        'insertAboveOlder': false,
        'insertBelowOlder': true,
      });
      expect(spec.allowDrag, isTrue);
      expect(spec.allowResize, isTrue);
      expect(spec.allowSwap, isFalse);
      expect(spec.lockSwap, isTrue);
      expect(spec.allowClose, isFalse);
      expect(spec.lockClose, isTrue);
      expect(spec.allowUnderlyingInteraction, isTrue);
      expect(spec.closeOnOutsideTap, isFalse);
      expect(spec.closeOnEscape, isFalse);
      expect(spec.useSafeArea, isFalse);
      expect(spec.newestOnTop, isFalse);
      expect(spec.insertAboveOlder, isFalse);
      expect(spec.insertBelowOlder, isTrue);
    });
    test('accepts JSON text and resolves the preferred edge', () {
      final spec = QLOverlayRuntimeSpec.fromValue(
          '{"preferredEdge":"left","insertMode":"atIndex","insertIndex":3}');
      expect(spec.preferredEdge, QLSheetEdge.left);
      expect(spec.insertMode, QLOverlayInsertMode.atIndex);
      expect(spec.insertIndex, 3);
    });
    test('preserves raw input when string JSON fails to decode', () {
      final spec = QLOverlayRuntimeSpec.fromValue('not-json');
      expect(spec.extra['raw'], 'not-json');
      expect(spec.allowClose, isTrue);
      expect(spec.closeOnOutsideTap, isTrue);
    });
    test('parses allowed edges and nested maps', () {
      final spec = QLOverlayRuntimeSpec.fromValue({
        'allowedEdges': ['top', 'left', 'bad', 'right'],
        'hooks': {'onOpen': 'openHook'},
        'actions': {'close': 'closeAction'},
        'native': {'channel': 'bridge'},
        'extraKey': 42,
      });
      expect(spec.allowedEdges,
          [QLSheetEdge.top, QLSheetEdge.left, QLSheetEdge.right]);
      expect(spec.hooks['onOpen'], 'openHook');
      expect(spec.actions['close'], 'closeAction');
      expect(spec.native['channel'], 'bridge');
      expect(spec.extra['extraKey'], 42);
    });
    test('recognizes enableDrag as an alias', () {
      final spec = QLOverlayRuntimeSpec.fromValue({'enableDrag': true});
      expect(spec.allowDrag, isTrue);
    });
    test('resolves insertMode synonyms', () {
      final bottom = QLOverlayRuntimeSpec.fromValue({'insertMode': 'bottom'});
      final above =
          QLOverlayRuntimeSpec.fromValue({'insertMode': 'above_older'});
      final below =
          QLOverlayRuntimeSpec.fromValue({'insertMode': 'belowOlder'});
      expect(bottom.insertMode, QLOverlayInsertMode.bottom);
      expect(above.insertMode, QLOverlayInsertMode.aboveOlder);
      expect(below.insertMode, QLOverlayInsertMode.belowOlder);
    });
    test('returns the first allowed edge when the current one is disallowed',
        () {
      final spec = const QLOverlayRuntimeSpec(
          allowSwap: true, allowedEdges: <QLSheetEdge>[QLSheetEdge.top]);
      expect(spec.resolveEdge(QLSheetEdge.bottom, dx: 120, dy: 0),
          QLSheetEdge.top);
    });
    test('keeps the current edge when swapping is locked', () {
      final spec = const QLOverlayRuntimeSpec(
          allowSwap: true,
          lockSwap: true,
          allowedEdges: <QLSheetEdge>[QLSheetEdge.top, QLSheetEdge.left]);
      expect(spec.resolveEdge(QLSheetEdge.bottom, dx: -999, dy: -999),
          QLSheetEdge.bottom);
    });
    test('swaps bottom to right on a strong horizontal drag', () {
      final spec = const QLOverlayRuntimeSpec(allowSwap: true);
      expect(spec.resolveEdge(QLSheetEdge.bottom, dx: 120, dy: 0),
          QLSheetEdge.right);
    });
    test('swaps right to top on a strong upward drag', () {
      final spec = const QLOverlayRuntimeSpec(allowSwap: true);
      expect(spec.resolveEdge(QLSheetEdge.right, dx: 0, dy: -120),
          QLSheetEdge.top);
    });
    test('swaps left to bottom on a strong downward drag', () {
      final spec = const QLOverlayRuntimeSpec(allowSwap: true);
      expect(spec.resolveEdge(QLSheetEdge.left, dx: 0, dy: 120),
          QLSheetEdge.bottom);
    });
    test('keeps the same edge for small drags', () {
      final spec = const QLOverlayRuntimeSpec(allowSwap: true);
      expect(
          spec.resolveEdge(QLSheetEdge.top, dx: 10, dy: 10), QLSheetEdge.top);
    });
    test('shows the current string-bool coercion gap as a regression test', () {
      final spec = QLOverlayRuntimeSpec.fromValue(
          '{"allowDrag":"true","allowResize":"true","closeOnOutsideTap":"false"}');
      expect(spec.allowDrag, isTrue,
          reason: 'String booleans should be coerced for production JSON');
      expect(spec.allowResize, isTrue,
          reason: 'String booleans should be coerced for production JSON');
      expect(spec.closeOnOutsideTap, isFalse,
          reason: 'String booleans should be coerced for production JSON');
    });
  });
}
