/*
 * ============================================================================
 * File: quantum_focus_sync.dart
 * 
 * Description:
 * Internal utility for synchronizing headless form field controller focus states with Flutter's native FocusNode.
 * 
 * Key Components:
 * - qlMirrorFocusNodeToController: Syncs native focus to headless state.
 * - qlMirrorControllerToFocusNode: Syncs headless state back to native focus.
 * 
 * Dependencies/Relationships:
 * Used internally by quantum_field_ui_engine.dart and quantum_forms_engine.dart.
 * 
 * Notes:
 * Keeps headless UI primitives seamlessly in sync with the Flutter focus tree.
 * ============================================================================
 */
import 'package:flutter/material.dart';
import 'package:quantum_layout/quantum.dart';
/// Shared focus synchronization helpers for the headless field primitives.
void qlMirrorFocusNodeToController(
  FocusNode focusNode,
  QLFieldController controller, {
  bool blurOnUnfocus = true,
}) {
  if (focusNode.hasFocus) {
    controller.focus();
  } else if (blurOnUnfocus) {
    controller.blur();
  }
}

void qlMirrorControllerToFocusNode(
  FocusNode focusNode,
  QLFieldController controller,
) {
  if (controller.isFocused && !focusNode.hasFocus) {
    focusNode.requestFocus();
  } else if (!controller.isFocused && focusNode.hasFocus) {
    focusNode.unfocus();
  }
}
