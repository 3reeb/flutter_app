/*
 * ============================================================================
 * File: qte_interaction.dart
 * 
 * Description:
 * Provides the execution engine for all user interactions within the Quantum Test Engine.
 * It translates abstract interaction definitions (like tap, drag, type, scroll) into
 * concrete Flutter widget test commands, enabling end-to-end simulation of user behavior
 * against the rendered Server-Driven UI.
 * 
 * Key Components:
 * - QTEInteractionResult: Data model capturing the outcome and execution time of an interaction.
 * - QTEInteractionEngine: The primary dispatcher that resolves targets and executes the appropriate tester gestures.
 * 
 * Dependencies/Relationships:
 * Relies heavily on lutter_test (WidgetTester) and lutter/gestures.dart.
 * Interacts with qte_render_probe.dart to locate target widgets and qte_reactive.dart
 * to monitor resulting side effects (like action dispatches).
 * 
 * Notes:
 * For complex gestures like pinch or zoom, it simulates raw pointer events. Some interactions
 * also manipulate the underlying QLDataStore directly to simulate system-level events or
 * deep linking.
 * ============================================================================
 */
// ══════════════════════════════════════════════════════════════════════════════
// QTE INTERACTION ENGINE — qte_interaction.dart
// Executes every interaction type: tap, drag, type, resize, action dispatch, etc.
// ══════════════════════════════════════════════════════════════════════════════
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';
import 'qte_schema.dart';
import 'qte_render_probe.dart';
import 'qte_reactive.dart';

class QTEInteractionResult {
  final bool succeeded;
  final String stepId;
  final String? error;
  final Duration elapsed;
  final Map<String, dynamic> meta;

  const QTEInteractionResult({
    required this.succeeded,
    required this.stepId,
    this.error,
    required this.elapsed,
    this.meta = const {},
  });

  factory QTEInteractionResult.ok(String stepId, Duration elapsed, {Map<String, dynamic>? meta}) =>
      QTEInteractionResult(succeeded: true, stepId: stepId, elapsed: elapsed, meta: meta ?? const {});

  factory QTEInteractionResult.fail(String stepId, String error, Duration elapsed) =>
      QTEInteractionResult(succeeded: false, stepId: stepId, error: error, elapsed: elapsed);
}

// ─────────────────────────────────────────────────────────────────────────────

class QTEInteractionEngine {
  final WidgetTester tester;
  final QLDataStore store;
  final QTERenderProbe probe;
  final QTEReactiveWatcher watcher;

  QTEInteractionEngine({
    required this.tester,
    required this.store,
    required this.probe,
    required this.watcher,
  });

  Future<QTEInteractionResult> execute(QTEInteraction ix, String stepId) async {
    final sw = Stopwatch()..start();
    try {
      await _dispatch(ix, stepId);
      sw.stop();
      return QTEInteractionResult.ok(stepId, sw.elapsed);
    } catch (e, st) {
      print('INTERACTION ERROR: $e\n$st');
      sw.stop();
      return QTEInteractionResult.fail(stepId, '$e', sw.elapsed);
    }
  }

  // ── Dispatcher ────────────────────────────────────────────────────────────
  Future<void> _dispatch(QTEInteraction ix, String stepId) async {
    switch (ix.type) {
      case QTEInteractionType.tap:
        await _tap(ix);
      case QTEInteractionType.doubleTap:
        await _doubleTap(ix);
      case QTEInteractionType.longPress:
        await _longPress(ix);
      case QTEInteractionType.hover:
        await _hover(ix, entering: true);
      case QTEInteractionType.unhover:
        await _hover(ix, entering: false);
      case QTEInteractionType.drag:
        await _drag(ix);
      case QTEInteractionType.scroll:
        await _scroll(ix);
      case QTEInteractionType.type:
        await _typeText(ix);
      case QTEInteractionType.clearText:
        await _clearText(ix);
      case QTEInteractionType.focus:
        await _focus(ix);
      case QTEInteractionType.blur:
        await _blur(ix);
      case QTEInteractionType.resize:
        await _resize(ix);
      case QTEInteractionType.keyPress:
        await _keyPress(ix);
      case QTEInteractionType.rightClick:
        await _rightClick(ix);
      case QTEInteractionType.zoom:
        await _zoom(ix);
      case QTEInteractionType.pinch:
        await _pinch(ix);
      case QTEInteractionType.triggerAction:
        await _triggerAction(ix, stepId);
      case QTEInteractionType.setState:
        await _setState(ix);
      case QTEInteractionType.mergeState:
        await _mergeState(ix);
      case QTEInteractionType.toggleState:
        await _toggleState(ix);
      case QTEInteractionType.dispatchSignal:
        await _dispatchSignal(ix);
      case QTEInteractionType.wait:
        await _wait(ix);
      case QTEInteractionType.navigate:
        await _navigate(ix);
      case QTEInteractionType.waitForSignal:
        await _waitForSignal(ix);
    }
    try {
      await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 2));
    } catch (_) {}
  }

  // ── Target resolution ─────────────────────────────────────────────────────
  Future<Finder> _resolveTarget(QTEInteraction ix) async {
    if (ix.target == null) return find.byType(Widget).first;
    final f = probe.findByTarget(ix.target!);
    if (!tester.any(f)) {
      try {
        await tester.pumpAndSettle(
          const Duration(milliseconds: 50),
          EnginePhase.sendSemanticsUpdate,
          const Duration(seconds: 1),
        );
      } catch (_) {}
    }
    if (!tester.any(f)) {
      throw Exception('Target not found: ${ix.target!.by.name}="${ix.target!.value}"');
    }
    return f;
  }

  Offset _centerOf(Finder f) => tester.getCenter(f.first);
  Offset _applyOffset(Offset center, QTEVec2? offset) =>
      offset != null ? center + Offset(offset.dx, offset.dy) : center;

  // ── tap ───────────────────────────────────────────────────────────────────
  Future<void> _tap(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final pos = _applyOffset(_centerOf(f), ix.offset);
    await tester.tapAt(pos);
  }

  // ── double_tap ────────────────────────────────────────────────────────────
  Future<void> _doubleTap(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final pos = _applyOffset(_centerOf(f), ix.offset);
    await tester.tapAt(pos);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(pos);
  }

  // ── long_press ────────────────────────────────────────────────────────────
  Future<void> _longPress(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final pos = _applyOffset(_centerOf(f), ix.offset);
    final gesture = await tester.startGesture(pos);
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
  }

  // ── hover ─────────────────────────────────────────────────────────────────
  Future<void> _hover(QTEInteraction ix, {required bool entering}) async {
    final f = await _resolveTarget(ix);
    final pos = _applyOffset(_centerOf(f), ix.offset);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    if (entering) {
      await gesture.addPointer(location: pos);
    } else {
      await gesture.addPointer(location: pos + const Offset(1000, 1000));
    }
    await tester.pump();
    await gesture.removePointer();
  }

  // ── drag ──────────────────────────────────────────────────────────────────
  Future<void> _drag(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final center = _centerOf(f);
    final from = ix.from != null ? center + Offset(ix.from!.dx, ix.from!.dy) : center;
    final to = ix.to != null ? center + Offset(ix.to!.dx, ix.to!.dy) : center + const Offset(100, 0);
    await tester.dragFrom(from, to - from);
  }

  // ── scroll ────────────────────────────────────────────────────────────────
  Future<void> _scroll(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final delta = ix.delta;
    if (delta == null) return;
    await tester.drag(f.first, Offset(delta.dx, delta.dy));
  }

  // ── type ───────────────────────────────────────────────────────────────────
  Future<void> _typeText(QTEInteraction ix) async {
    if (ix.target != null) {
      final f = await _resolveTarget(ix);
      
      // --- DEBUG ---
      final element = f.first.evaluate().first;
      final box = element.renderObject as RenderBox;
      final size = box.size;
      final pos = box.localToGlobal(Offset.zero);
      print('DEBUG QTE_TAP TARGET: ${ix.target!.value} -> Size: $size, Pos: $pos');
      // -------------
      
      await tester.tap(f.first);
      await tester.pumpAndSettle();
      
      if (!tester.any(f)) {
        throw Exception('Target disappeared after tap: ${ix.target!.value}');
      }
      await tester.enterText(f.first, ix.text ?? '');
      await tester.pumpAndSettle();
    } else {
      final f = find.byType(EditableText);
      if (!tester.any(f)) {
        throw Exception('No EditableText found to type into');
      }
      await tester.enterText(f.first, ix.text ?? '');
    }
    await tester.pumpAndSettle();
  }

  // ── clear_text ──────────────────────────────────────────────────────────────
  Future<void> _clearText(QTEInteraction ix) async {
    if (ix.target != null) {
      final f = await _resolveTarget(ix);
      await tester.tap(f.first);
      await tester.pumpAndSettle();

      if (!tester.any(f)) {
        throw Exception('Target disappeared after tap: ${ix.target!.value}');
      }
      await tester.enterText(f.first, '');
    } else {
      final f = find.byType(EditableText);
      if (!tester.any(f)) {
        throw Exception('No EditableText found to clear');
      }
      await tester.enterText(f.first, '');
    }
    await tester.pumpAndSettle();
  }

  // ── focus ─────────────────────────────────────────────────────────────────
  Future<void> _focus(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    await tester.tap(f.first);
  }

  // ── blur ──────────────────────────────────────────────────────────────────
  Future<void> _blur(QTEInteraction ix) async {
    // Tap somewhere neutral to remove focus
    await tester.tapAt(const Offset(1, 1));
  }

  // ── resize ────────────────────────────────────────────────────────────────
  Future<void> _resize(QTEInteraction ix) async {
    // Find the resize handle by looking for the handle testId
    final handleKey = 'qte_resize_${ix.resizeHandle.name}';
    Finder handleFinder;
    try {
      handleFinder = find.byKey(ValueKey(handleKey));
      if (!tester.any(handleFinder)) throw Exception('fallback');
    } catch (_) {
      // Fallback: drag from bottom-right corner of target
      if (ix.target != null) {
        final f = await _resolveTarget(ix);
        final rect = tester.getRect(f.first);
        final handlePos = rect.bottomRight - const Offset(4, 4);
        final targetW = ix.newWidth ?? rect.width;
        final targetH = ix.newHeight ?? rect.height;
        final delta = Offset(targetW - rect.width, targetH - rect.height);
        await tester.dragFrom(handlePos, delta);
        return;
      }
      return;
    }
    final handlePos = tester.getCenter(handleFinder.first);
    if (ix.target != null) {
      final targetRect = tester.getRect((await _resolveTarget(ix)).first);
      final currentW = targetRect.width;
      final currentH = targetRect.height;
      final deltaX = (ix.newWidth ?? currentW) - currentW;
      final deltaY = (ix.newHeight ?? currentH) - currentH;
      await tester.dragFrom(handlePos, Offset(deltaX, deltaY));
    }
  }

  // ── key_press ─────────────────────────────────────────────────────────────
  Future<void> _keyPress(QTEInteraction ix) async {
    final key = ix.key ?? '';
    final logicalKey = _parseLogicalKey(key);
    if (logicalKey == null) return;
    final modifiers = ix.modifiers;
    if (modifiers.contains('shift')) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    if (modifiers.contains('ctrl') || modifiers.contains('control')) {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    }
    if (modifiers.contains('alt')) await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
    if (modifiers.contains('meta')) await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);

    await tester.sendKeyEvent(logicalKey);

    if (modifiers.contains('shift')) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    if (modifiers.contains('ctrl') || modifiers.contains('control')) {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    }
    if (modifiers.contains('alt')) await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    if (modifiers.contains('meta')) await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
  }

  LogicalKeyboardKey? _parseLogicalKey(String key) {
    const map = <String, LogicalKeyboardKey>{
      'Enter': LogicalKeyboardKey.enter,
      'Escape': LogicalKeyboardKey.escape,
      'Tab': LogicalKeyboardKey.tab,
      'Space': LogicalKeyboardKey.space,
      'Backspace': LogicalKeyboardKey.backspace,
      'Delete': LogicalKeyboardKey.delete,
      'ArrowUp': LogicalKeyboardKey.arrowUp,
      'ArrowDown': LogicalKeyboardKey.arrowDown,
      'ArrowLeft': LogicalKeyboardKey.arrowLeft,
      'ArrowRight': LogicalKeyboardKey.arrowRight,
      'Home': LogicalKeyboardKey.home,
      'End': LogicalKeyboardKey.end,
      'PageUp': LogicalKeyboardKey.pageUp,
      'PageDown': LogicalKeyboardKey.pageDown,
      'F1': LogicalKeyboardKey.f1, 'F2': LogicalKeyboardKey.f2,
      'F3': LogicalKeyboardKey.f3, 'F4': LogicalKeyboardKey.f4,
      'F5': LogicalKeyboardKey.f5,
    };
    if (map.containsKey(key)) return map[key];
    // if (key.length == 1) return LogicalKeyboardKey.fromCharacterCode(key.codeUnitAt(0));
    return null;
  }

  // ── right_click ───────────────────────────────────────────────────────────
  Future<void> _rightClick(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final pos = _applyOffset(_centerOf(f), ix.offset);
    final gesture = await tester.startGesture(pos, pointer: 2, buttons: kSecondaryMouseButton);
    await tester.pump();
    await gesture.up();
  }

  // ── zoom ──────────────────────────────────────────────────────────────────
  Future<void> _zoom(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final center = _centerOf(f);
    final scale = ix.scale ?? 2.0;
    // Simulate two-finger pinch-to-zoom
    final p1Start = center + const Offset(-50, 0);
    final p2Start = center + const Offset(50, 0);
    final p1End = center + Offset(-50 * scale, 0);
    final p2End = center + Offset(50 * scale, 0);
    final g1 = await tester.startGesture(p1Start, pointer: 1);
    final g2 = await tester.startGesture(p2Start, pointer: 2);
    await g1.moveTo(p1End);
    await g2.moveTo(p2End);
    await tester.pump();
    await g1.up();
    await g2.up();
  }

  // ── pinch ────────────────────────────────────────────────────────────────
  Future<void> _pinch(QTEInteraction ix) async {
    final f = await _resolveTarget(ix);
    final center = _centerOf(f);
    final scale = ix.scale ?? 0.5;
    final p1Start = center + const Offset(-100, 0);
    final p2Start = center + const Offset(100, 0);
    final p1End = center + Offset(-100 * scale, 0);
    final p2End = center + Offset(100 * scale, 0);
    final g1 = await tester.startGesture(p1Start, pointer: 1);
    final g2 = await tester.startGesture(p2Start, pointer: 2);
    await g1.moveTo(p1End);
    await g2.moveTo(p2End);
    await tester.pump();
    await g1.up();
    await g2.up();
  }

  // ── trigger_action ────────────────────────────────────────────────────────
  Future<void> _triggerAction(QTEInteraction ix, String stepId) async {
    if (ix.action == null) return;
    final actionDef = [{'action': ix.action!, ...ix.params}];
    try {
      await QuantumVM.instance.triggerActions(actionDef, null, env: Map<String, dynamic>.from(ix.params));
      watcher.recordAction(ix.action!, ix.params, succeeded: true);
    } catch (e) {
      watcher.recordAction(ix.action!, ix.params, result: e.toString(), succeeded: false);
      rethrow;
    }
  }

  // ── set_state ─────────────────────────────────────────────────────────────
  Future<void> _setState(QTEInteraction ix) async {
    ix.data.forEach((key, value) {
      store.set(key, value);
      watcher.watchKey(key);
    });
    await tester.pump();
  }

  // ── merge_state ───────────────────────────────────────────────────────────
  Future<void> _mergeState(QTEInteraction ix) async {
    store.merge(Map<String, dynamic>.from(ix.data));
    for (final key in ix.data.keys) {
      watcher.watchKey(key);
    }
    await tester.pump();
  }

  // ── toggle_state ──────────────────────────────────────────────────────────
  Future<void> _toggleState(QTEInteraction ix) async {
    final key = ix.stateKey ?? ix.key ?? '';
    if (key.isEmpty) return;
    final current = store.get(key);
    final next = !(current == true);
    store.set(key, next);
    watcher.watchKey(key);
    await tester.pump();
  }

  // ── dispatch_signal ───────────────────────────────────────────────────────
  Future<void> _dispatchSignal(QTEInteraction ix) async {
    // Dispatch via state.set action
    final key = ix.storeKey ?? ix.key ?? '';
    if (key.isEmpty) return;
    store.set(key, ix.expectedValue);
    watcher.watchKey(key);
    await tester.pump();
  }

  // ── wait ──────────────────────────────────────────────────────────────────
  Future<void> _wait(QTEInteraction ix) async {
    if (ix.waitMs > 0) {
      await tester.pump(Duration(milliseconds: ix.waitMs));
    }
  }

  // ── navigate ──────────────────────────────────────────────────────────────
  Future<void> _navigate(QTEInteraction ix) async {
    if (ix.route == null) return;
    final context = tester.element(find.byType(MaterialApp).first);
    Navigator.of(context).pushNamed(ix.route!, arguments: ix.queryParams);
    await tester.pumpAndSettle();
  }

  // ── wait_for_signal ───────────────────────────────────────────────────────
  Future<void> _waitForSignal(QTEInteraction ix) async {
    final key = ix.storeKey ?? '';
    if (key.isEmpty) return;
    watcher.watchKey(key);
    final ok = await watcher.waitForSignal(
      key,
      expectedValue: ix.expectedValue,
      timeoutMs: ix.timeoutMs,
    );
    if (!ok) {
      throw Exception(
          'waitForSignal timeout after ${ix.timeoutMs}ms: '
          'key="$key" expectedValue=${ix.expectedValue}, '
          'actualValue=${store.get(key)}');
    }
    await tester.pump();
  }
}
