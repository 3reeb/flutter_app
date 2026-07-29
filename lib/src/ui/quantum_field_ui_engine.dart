// ════════════════════════════════════════════════════════════════════════════
// QUANTUM FIELD UI ENGINE v2.0 - OMEGA HEADLESS PRIMITIVES
// quantum_field_ui_engine.dart
//
// ARCHITECTURE & CAPABILITIES:
// 1. Absolute Headless Purity: Zero forced padding, margins, colors, or layout.
//    These primitives wrap your builders and provide pure mathematical and
//    interaction state. They sit exactly where you put them.
// 2. Continuous Animation States: Toggles and Options provide an internal
//    AnimationController giving you a smooth `t` (0.0 -> 1.0) value to drive
//    custom transforms, color lerps, and sizing in your UI shells.
// 3. Hardware / A11y Ready: Every primitive includes `FocusNode` integration,
//    Keyboard event handlers (Arrows, Space, Enter), and MouseRegion hover states.
// 4. Dimensional Agnosticism: The Slider calculates math based on its exact
//    bounding box, meaning you can make horizontal, vertical, or thick 2D
//    bounding boxes and it will resolve the exact percentages perfectly.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:quantum_layout/quantum.dart';
import 'internal/quantum_focus_sync.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  CORE STATE OBJECTS
// ────────────────────────────────────────────────────────────────────────────

@immutable
class QLFieldUIState {
  final bool isFocused;
  final bool isHovered;
  final bool isDisabled;
  final bool isReadOnly;
  final bool hasError;
  final bool isEmpty;
  final String? errorText;

  const QLFieldUIState({
    required this.isFocused,
    required this.isHovered,
    required this.isDisabled,
    required this.isReadOnly,
    required this.hasError,
    required this.isEmpty,
    this.errorText,
  });
}

@immutable
class QLSliderUIState extends QLFieldUIState {
  final double value;
  final double percent; // 0.0 to 1.0
  final bool isDragging;

  const QLSliderUIState({
    required super.isFocused,
    required super.isHovered,
    required super.isDisabled,
    required super.isReadOnly,
    required super.hasError,
    required super.isEmpty,
    super.errorText,
    required this.value,
    required this.percent,
    required this.isDragging,
  });
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  THE TEXT BRIDGE (Headless Text Input)
// ────────────────────────────────────────────────────────────────────────────

class QLReactiveTextBridge extends TextEditingController {
  final QLTextController engineController;
  bool _isSyncingFromEngine = false;

  QLReactiveTextBridge({required this.engineController})
      : super(text: engineController.data.value) {
    engineController.data.addListener(_onEngineDataChanged);
    addListener(_onFlutterUiChanged);
  }

  void _onEngineDataChanged() {
    final newText = engineController.data.value;
    if (text == newText) return;

    _isSyncingFromEngine = true;
    final currentSelection = selection;
    int newOffset = newText.length;

    if (currentSelection.isValid) {
      newOffset = math.min(currentSelection.baseOffset, newText.length);
      final lengthDiff = newText.length - text.length;
      if (lengthDiff > 0 && currentSelection.baseOffset > 0) {
        newOffset =
            math.min(currentSelection.baseOffset + lengthDiff, newText.length);
      }
    }

    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    _isSyncingFromEngine = false;
  }

  void _onFlutterUiChanged() {
    if (_isSyncingFromEngine) return;
    engineController.mutateFast(text, applyMiddleware: true);
  }

  @override
  void dispose() {
    engineController.data.removeListener(_onEngineDataChanged);
    removeListener(_onFlutterUiChanged);
    super.dispose();
  }
}

class QLRawTextInput extends StatefulWidget {
  final QLTextController controller;
  final Widget Function(
          BuildContext context, QLFieldUIState state, Widget rawInputWidget)
      shellBuilder;

  final TextStyle textStyle;
  final Color cursorColor;
  final Color selectionColor;
  final Color backgroundCursorColor;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final int maxLines;
  final int minLines;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  const QLRawTextInput({
    super.key,
    required this.controller,
    required this.shellBuilder,
    required this.textStyle,
    required this.cursorColor,
    required this.selectionColor,
    required this.backgroundCursorColor,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.autofillHints,
    this.inputFormatters,
  });

  @override
  State<QLRawTextInput> createState() => _QLRawTextInputState();
}

class _QLRawTextInputState extends State<QLRawTextInput> {
  late final QLReactiveTextBridge _bridge;
  late final FocusNode _focusNode;
  final ScrollController _scrollController = ScrollController();

  // UI States
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);

  // 🚀 THE GOD-MODE FIX: Track ONLY empty state, not every keystroke
  late final ValueNotifier<bool> _isEmpty;

  @override
  void initState() {
    super.initState();
    _bridge = QLReactiveTextBridge(engineController: widget.controller);
    _focusNode = FocusNode();
    _isEmpty = ValueNotifier(_bridge.text.isEmpty);

    // 1. Sync Flutter Focus Node -> Quantum Engine
    _focusNode.addListener(() {
      if (_focusNode.hasFocus)
        widget.controller.focus();
      else
        widget.controller.blur();
    });

    // 2. Sync Quantum Engine -> Flutter Focus Node
    widget.controller.stateFlags.addListener(_onEngineStateFlagsChanged);

    // 3. 🚀 Only update `_isEmpty` when the boundary is crossed
    _bridge.addListener(_checkEmptyState);
  }

  void _checkEmptyState() {
    final currentlyEmpty = _bridge.text.isEmpty;
    if (_isEmpty.value != currentlyEmpty) {
      _isEmpty.value = currentlyEmpty;
    }
  }

  void _onEngineStateFlagsChanged() {
    final bool engineWantsFocus = widget.controller.isFocused;
    if (engineWantsFocus && !_focusNode.hasFocus) {
      _focusNode.requestFocus();
    } else if (!engineWantsFocus && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    widget.controller.stateFlags.removeListener(_onEngineStateFlagsChanged);
    _bridge.removeListener(_checkEmptyState);
    _bridge.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _isHovered.dispose();
    _isEmpty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ⬇️ REPLACED: Wrapped TextField in TextSelectionTheme and removed selectionColor from TextField properties
    final Widget rawInput = TextSelectionTheme(
      data: TextSelectionThemeData(
        selectionColor: widget.selectionColor,
      ),
      child: TextField(
        controller: _bridge,
        focusNode: _focusNode,
        style: widget.textStyle,
        cursorColor: widget.cursorColor,
        // selectionColor: widget.selectionColor, <--- REMOVED from here
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        obscureText: widget.obscureText,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        scrollController: _scrollController,
        autofillHints: widget.autofillHints,
        inputFormatters: widget.inputFormatters,
        readOnly: widget.controller.isReadonly,
        enableInteractiveSelection: true,
        mouseCursor: SystemMouseCursors.text,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isCollapsed: true,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (_) {},
        onSubmitted: (_) => widget.controller.blur(),
      ),
    );
    // ⬆️ END OF REPLACEMENT

    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      cursor: widget.controller.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.text,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!widget.controller.isDisabled && !widget.controller.isReadonly) {
            _focusNode.requestFocus();
          }
        },
        child: AnimatedBuilder(
          // 🚀 ZERO-REBUILD TYPING:
          // Notice `_bridge` is GONE. Typing characters will NEVER trigger this builder.
          // It only rebuilds if you Focus, Hover, trigger an Error, or delete the last character.
          animation: Listenable.merge([
            widget.controller.stateFlags,
            widget.controller.errors,
            _isEmpty,
            _isHovered,
          ]),
          builder: (context, _) {
            final state = QLFieldUIState(
              isFocused: widget.controller.isFocused,
              isHovered: _isHovered.value,
              isDisabled: widget.controller.isDisabled,
              isReadOnly: widget.controller.isReadonly,
              hasError: !widget.controller.isValid,
              isEmpty: _isEmpty.value,
              errorText: widget.controller.errorText,
            );

            return widget.shellBuilder(context, state, rawInput);
          },
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────── §3 ─
//  HEADLESS TOGGLE (Switch / Checkbox Primitive)
// ────────────────────────────────────────────────────────────────────────────

/// A purely mathematical toggle primitive. Exposes an `animationProgress` (0.0 to 1.0)
/// allowing you to build fluid sliding thumbs, color lerps, or scaling checkmarks.
class QLRawToggle extends StatefulWidget {
  final QLBoolController controller;
  final Duration animationDuration;
  final Curve curve;
  final Widget Function(BuildContext context, QLFieldUIState state, bool value,
      double animationProgress) builder;

  const QLRawToggle({
    super.key,
    required this.controller,
    required this.builder,
    this.animationDuration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<QLRawToggle> createState() => _QLRawToggleState();
}

class _QLRawToggleState extends State<QLRawToggle>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);
  late final FocusNode _focusNode;
  late final AnimationController _animCtrl;
  late final CurvedAnimation _curvedAnim;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_syncFocus);
    _animCtrl =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _curvedAnim = CurvedAnimation(parent: _animCtrl, curve: widget.curve);

    if (widget.controller.data.value) _animCtrl.value = 1.0;
    widget.controller.data.addListener(_onDataChanged);
    widget.controller.stateFlags.addListener(_onEngineFlagsChanged);
  }

  void _syncFocus() {
    qlMirrorFocusNodeToController(_focusNode, widget.controller);
  }

  void _onEngineFlagsChanged() {
    qlMirrorControllerToFocusNode(_focusNode, widget.controller);
  }

  void _onDataChanged() {
    if (widget.controller.data.value)
      _animCtrl.forward();
    else
      _animCtrl.reverse();
  }

  void _toggle() {
    if (widget.controller.isDisabled || widget.controller.isReadonly) return;
    _focusNode.requestFocus();
    widget.controller.toggle();
    widget.controller.validate();
  }

  @override
  void dispose() {
    widget.controller.data.removeListener(_onDataChanged);
    widget.controller.stateFlags.removeListener(_onEngineFlagsChanged);
    _focusNode.dispose();
    _isHovered.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      cursor: widget.controller.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              _toggle();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.controller.stateFlags,
              widget.controller.errors,
              _isHovered,
              _animCtrl,
            ]),
            builder: (context, _) {
              return widget.builder(
                context,
                QLFieldUIState(
                  isFocused: widget.controller.isFocused,
                  isHovered: _isHovered.value,
                  isDisabled: widget.controller.isDisabled,
                  isReadOnly: widget.controller.isReadonly,
                  hasError: !widget.controller.isValid,
                  isEmpty: !widget.controller.data.value,
                  errorText: widget.controller.errorText,
                ),
                widget.controller.data.value,
                _curvedAnim.value,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  HEADLESS OPTION (For Radio Buttons & Selectable Chips)
// ────────────────────────────────────────────────────────────────────────────

/// A primitive that represents a single choice in a multi-choice controller.
/// Binds to ANY controller type (Enum, String, Int) and checks equality.
class QLRawOption<T> extends StatefulWidget {
  final QLFieldController<T> controller;
  final T value;
  final Duration animationDuration;
  final Curve curve;
  final Widget Function(BuildContext context, QLFieldUIState state,
      bool isSelected, double animationProgress) builder;

  const QLRawOption({
    super.key,
    required this.controller,
    required this.value,
    required this.builder,
    this.animationDuration = const Duration(milliseconds: 200),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<QLRawOption<T>> createState() => _QLRawOptionState<T>();
}

class _QLRawOptionState<T> extends State<QLRawOption<T>>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);
  late final FocusNode _focusNode;
  late final AnimationController _animCtrl;
  late final CurvedAnimation _curvedAnim;

  bool get _isSelected => widget.controller.data.value == widget.value;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_syncFocus);
    _animCtrl =
        AnimationController(vsync: this, duration: widget.animationDuration);
    _curvedAnim = CurvedAnimation(parent: _animCtrl, curve: widget.curve);

    if (_isSelected) _animCtrl.value = 1.0;
    widget.controller.data.addListener(_onDataChanged);
    widget.controller.stateFlags.addListener(_onEngineFlagsChanged);
  }

  void _syncFocus() {
    qlMirrorFocusNodeToController(
      _focusNode,
      widget.controller,
      blurOnUnfocus: false,
    );
  }

  void _onEngineFlagsChanged() {
    if (widget.controller.isFocused && _isSelected && !_focusNode.hasFocus)
      _focusNode.requestFocus();
  }

  void _onDataChanged() {
    if (_isSelected)
      _animCtrl.forward();
    else
      _animCtrl.reverse();
  }

  void _select() {
    if (widget.controller.isDisabled || widget.controller.isReadonly) return;
    _focusNode.requestFocus();
    widget.controller.mutateFast(widget.value, applyMiddleware: true);
    widget.controller.validate();
  }

  @override
  void dispose() {
    widget.controller.data.removeListener(_onDataChanged);
    widget.controller.stateFlags.removeListener(_onEngineFlagsChanged);
    _focusNode.dispose();
    _isHovered.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      cursor: widget.controller.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _select,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              _select();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.controller.stateFlags,
              widget.controller.errors,
              _isHovered,
              _animCtrl,
            ]),
            builder: (context, _) {
              return widget.builder(
                context,
                QLFieldUIState(
                  isFocused: _focusNode.hasFocus,
                  isHovered: _isHovered.value,
                  isDisabled: widget.controller.isDisabled,
                  isReadOnly: widget.controller.isReadonly,
                  hasError: !widget.controller.isValid,
                  isEmpty: widget.controller.data.value == null,
                  errorText: widget.controller.errorText,
                ),
                _isSelected,
                _curvedAnim.value,
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  HEADLESS SLIDER (Layout-Agnostic Physics & Keyboard Control)
// ────────────────────────────────────────────────────────────────────────────

/// A purely mathematical layout-agnostic slider.
/// It wraps a `LayoutBuilder` simply to extract drag coordinates, but outputs EXACTLY
/// the UI you provide in the builder.
/// It calculates `percent` which you can use with Flutter's `FractionalTranslation`
/// or `Align` widgets to perfectly position a thumb visually.
class QLRawSlider extends StatefulWidget {
  final QLNumberController controller;
  final double min;
  final double max;
  final int? divisions;
  final Axis direction;
  final Widget Function(BuildContext context, QLSliderUIState state) builder;

  const QLRawSlider({
    super.key,
    required this.controller,
    required this.builder,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.direction = Axis.horizontal,
  });

  @override
  State<QLRawSlider> createState() => _QLRawSliderState();
}

class _QLRawSliderState extends State<QLRawSlider> {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  late final FocusNode _focusNode;

  double _trackExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_syncFocus);
    widget.controller.stateFlags.addListener(_onEngineFlagsChanged);
  }

  void _syncFocus() {
    qlMirrorFocusNodeToController(_focusNode, widget.controller);
  }

  void _onEngineFlagsChanged() {
    qlMirrorControllerToFocusNode(_focusNode, widget.controller);
  }

  void _handleInteraction(Offset localPosition) {
    if (widget.controller.isDisabled ||
        widget.controller.isReadonly ||
        _trackExtent == 0.0) return;

    // Support horizontal and vertical drag calculation
    final double rawPos = widget.direction == Axis.horizontal
        ? localPosition.dx
        : localPosition.dy;

    double percent = (rawPos / _trackExtent).clamp(0.0, 1.0);

    // If vertical, standard sliders fill from bottom to top, so invert the percentage
    if (widget.direction == Axis.vertical) percent = 1.0 - percent;

    double newValue = widget.min + (percent * (widget.max - widget.min));

    if (widget.divisions != null && widget.divisions! > 0) {
      final step = (widget.max - widget.min) / widget.divisions!;
      newValue = (newValue / step).round() * step;
    }

    widget.controller.mutateFast(newValue, applyMiddleware: true);
  }

  void _handleKeyboard(double deltaMultiplier) {
    if (widget.controller.isDisabled || widget.controller.isReadonly) return;

    final range = widget.max - widget.min;
    final step = widget.divisions != null && widget.divisions! > 0
        ? range / widget.divisions!
        : range * 0.05; // 5% default step

    final newValue = (widget.controller.data.value + (step * deltaMultiplier))
        .clamp(widget.min, widget.max);
    widget.controller.mutateFast(newValue, applyMiddleware: true);
    widget.controller.validate();
  }

  @override
  void dispose() {
    widget.controller.stateFlags.removeListener(_onEngineFlagsChanged);
    _focusNode.dispose();
    _isHovered.dispose();
    _isDragging.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      _trackExtent = widget.direction == Axis.horizontal
          ? constraints.maxWidth
          : constraints.maxHeight;

      return MouseRegion(
        onEnter: (_) => _isHovered.value = true,
        onExit: (_) => _isHovered.value = false,
        cursor: widget.controller.isDisabled
            ? SystemMouseCursors.forbidden
            : (widget.direction == Axis.horizontal
                ? SystemMouseCursors.resizeLeftRight
                : SystemMouseCursors.resizeUpDown),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (d) {
            if (widget.controller.isDisabled) return;
            _focusNode.requestFocus();
            _isDragging.value = true;
            _handleInteraction(d.localPosition);
          },
          onPanUpdate: (d) => _handleInteraction(d.localPosition),
          onPanEnd: (_) {
            _isDragging.value = false;
            widget.controller.validate();
          },
          onPanCancel: () => _isDragging.value = false,
          onTapDown: (d) {
            if (widget.controller.isDisabled) return;
            _focusNode.requestFocus();
            _handleInteraction(d.localPosition);
            widget.controller.validate();
          },
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                    event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  _handleKeyboard(1.0);
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  _handleKeyboard(-1.0);
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([
                widget.controller.data,
                widget.controller.stateFlags,
                widget.controller.errors,
                _isHovered,
                _isDragging,
              ]),
              builder: (context, _) {
                final double value =
                    widget.controller.data.value.clamp(widget.min, widget.max);
                final double percent =
                    ((value - widget.min) / (widget.max - widget.min))
                        .clamp(0.0, 1.0);

                final state = QLSliderUIState(
                  isFocused: widget.controller.isFocused,
                  isHovered: _isHovered.value,
                  isDisabled: widget.controller.isDisabled,
                  isReadOnly: widget.controller.isReadonly,
                  hasError: !widget.controller.isValid,
                  isEmpty: false,
                  errorText: widget.controller.errorText,
                  value: value,
                  percent: percent,
                  isDragging: _isDragging.value,
                );

                return widget.builder(context, state);
              },
            ),
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  HEADLESS TRIGGER (For Dropdowns, DatePickers, and Modals)
// ────────────────────────────────────────────────────────────────────────────

/// A primitive for things that need to be clicked to open a menu/dialog, but
/// act exactly like form fields (Focusable, Hoverable, Error states).
class QLRawTrigger extends StatefulWidget {
  final QLFieldController controller;
  final VoidCallback onTrigger;
  final Widget Function(
      BuildContext context, QLFieldUIState state, String displayValue) builder;

  const QLRawTrigger({
    super.key,
    required this.controller,
    required this.onTrigger,
    required this.builder,
  });

  @override
  State<QLRawTrigger> createState() => _QLRawTriggerState();
}

class _QLRawTriggerState extends State<QLRawTrigger> {
  final ValueNotifier<bool> _isHovered = ValueNotifier(false);
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_syncFocus);
    widget.controller.stateFlags.addListener(_onEngineFlagsChanged);
  }

  void _syncFocus() {
    qlMirrorFocusNodeToController(_focusNode, widget.controller);
  }

  void _onEngineFlagsChanged() {
    qlMirrorControllerToFocusNode(_focusNode, widget.controller);
  }

  void _trigger() {
    if (widget.controller.isDisabled || widget.controller.isReadonly) return;
    _focusNode.requestFocus();
    widget.onTrigger();
  }

  @override
  void dispose() {
    widget.controller.stateFlags.removeListener(_onEngineFlagsChanged);
    _focusNode.dispose();
    _isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _isHovered.value = true,
      onExit: (_) => _isHovered.value = false,
      cursor: widget.controller.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _trigger,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.enter)) {
              _trigger();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.controller.data,
              widget.controller.stateFlags,
              widget.controller.errors,
              _isHovered,
            ]),
            builder: (context, _) {
              final state = QLFieldUIState(
                isFocused: widget.controller.isFocused,
                isHovered: _isHovered.value,
                isDisabled: widget.controller.isDisabled,
                isReadOnly: widget.controller.isReadonly,
                hasError: !widget.controller.isValid,
                isEmpty: widget.controller.data.value == null ||
                    widget.controller.data.value.toString().isEmpty,
                errorText: widget.controller.errorText,
              );

              final displayValue =
                  widget.controller.data.value?.toString() ?? '';

              return widget.builder(context, state, displayValue);
            },
          ),
        ),
      ),
    );
  }
}
