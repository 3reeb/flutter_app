import 'package:flutter/material.dart';

import '../../../quantum.dart';

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
