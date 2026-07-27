// ════════════════════════════════════════════════════════════════════════════
// QUANTUM CONNECT ENGINE
// quantum_connect_engine.dart
//
// STATUS: newly written, additive, NOT yet run through `flutter analyze` or
// `flutter test` — there is no Dart/Flutter SDK in the environment that wrote
// this file. Every type and method it calls on the rest of the framework
// (QLSignal, QLHero, QLNavController, QLRouteInfo, QLFieldController,
// QLSignal-backed stateFlags) was verified by reading the actual source in
// this repo, not assumed from the docs — see CONNECT_PATTERN_GUIDE.md for the
// exact line references. Still: read this like a careful PR from someone new
// to the codebase, not a finished/verified release. Run the analyzer first.
//
// WHAT PROBLEM THIS SOLVES
// -------------------------
// Nothing in this codebase is missing "more power" — quantum_behaviors.dart,
// quantum_animation_engine.dart, quantum_navigation_engine.dart and
// quantum_field_ui_engine.dart already do real, specific jobs well. What's
// missing is the thing you actually asked for: a way for one JSON node to
// say "I depend on / affect THAT node over there" without you wiring a
// controller reference between them by hand, and without every screen
// needing its own bespoke plumbing.
//
// This file adds exactly one primitive — a named, typed, lazy connection —
// and four small widgets built on top of it. It does not reimplement Hero,
// signals, or gestures; it reuses QLHero, QLSignal-style ChangeNotifier
// patterns, and GestureDetector, because those already exist and work.
//
// THE PIECES
// 1. QLChannel<T> / QLChannelHub  — a named pub/sub cell. Publish once from
//    anywhere, read from anywhere, by string name. A channel that's never
//    published or watched costs one map slot that's never even created —
//    the hub only allocates a QLChannel the first time its name is touched.
// 2. QLNavBridge                  — one call, at the point where you already
//    create your QLNavController, publishes nav.current.title /
//    nav.previous.title / nav.canPop onto the hub every time the stack
//    changes. This is what makes a back button "know" the previous page's
//    title without you passing that title down through every route.
// 3. QLPressGesture                — a small state machine for
//    press-and-hold-with-directional-escape: active → cancelling (swipe up)
//    / altPending (swipe down) / committed. This is the gesture behind
//    "hold to record, swipe up to cancel, swipe down to do something else."
//    It does not render anything itself — it only reports phase changes —
//    so it costs nothing when you don't use it and doesn't force any
//    particular visual design on you.
// 4. QLMorphSlot                   — swaps between named "roles" in the same
//    tree position with a cross-fade, and optionally hero-links that swap
//    to a matching tag elsewhere in the app (another route, another widget)
//    via the existing QLHero. This is the "record button becomes the full
//    rich-text field" pattern and the "shared element across pages" pattern
//    — same primitive, because they're the same problem: two different
//    widgets, one continuous piece of UI.
//
// Plus two ready-to-use compositions of the above:
//   QLSmartBackButton   — back button that reveals the previous page's
//                          title on long-press. Every hook is overridable.
//   QLFocusRevealField  — wraps any field + its QLFieldController and shows
//                          a close button only while focused.
//
// SECURITY NOTE: a channel name is a plain string key into a closed,
// in-memory Dart map. Nothing here parses or evaluates JSON as code — the
// values that flow through a channel are whatever typed Dart object your
// app already put there. This module adds no new expression language.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quantum_layout/quantum.dart';
// ─────────────────────────────────────────────────────────────────────── §1 ─
//  CHANNELS — named, typed, lazy connections
// ────────────────────────────────────────────────────────────────────────────

/// A single named, typed value cell with subscribers. You will not normally
/// construct this directly — get one from [QLChannelHub.instance.channel].
class QLChannel<T> {
  T? _value;
  bool _hasValue = false;
  final List<void Function(T)> _listeners = [];

  bool get hasValue => _hasValue;
  T? get value => _value;

  /// Current value, or [fallback] if nothing has published to this channel
  /// yet. Prefer this over [value] when you need a non-null default.
  T valueOr(T fallback) => _hasValue ? (_value as T) : fallback;

  void publish(T value) {
    _value = value;
    _hasValue = true;
    // Snapshot before iterating: a listener may unsubscribe itself (e.g. a
    // widget disposing mid-callback) without corrupting this loop.
    for (final listener in List<void Function(T)>.of(_listeners)) {
      listener(value);
    }
  }

  /// Returns an unsubscribe function. Call it in dispose().
  VoidCallback subscribe(void Function(T value) onChange) {
    _listeners.add(onChange);
    return () => _listeners.remove(onChange);
  }

  /// Two-way bind this channel to a signal. The channel publishes the current
  /// signal value immediately, then follows future updates until the returned
  /// unsubscribe callback is called.
  VoidCallback bindSignal(QLSignalBase<T> signal, {bool publishInitial = true}) {
    void sync() => publish(signal.value);
    if (publishInitial) sync();
    signal.addListener(sync);
    return () => signal.removeListener(sync);
  }

  @visibleForTesting
  int get listenerCount => _listeners.length;
}

/// Global registry of [QLChannel]s by name. A channel is created lazily the
/// first time its name is touched (by publish OR by subscribe) and never
/// before — a screen that declares no connections allocates nothing here.
class QLChannelHub {
  QLChannelHub._();
  static final QLChannelHub instance = QLChannelHub._();

  final Map<String, QLChannel<dynamic>> _channels = {};

  QLChannel<T> channel<T>(String name) {
    final existing = _channels[name];
    if (existing != null) {
      assert(
        existing is QLChannel<T>,
        'QLChannelHub: channel "$name" already exists as '
        '${existing.runtimeType}, but was requested as QLChannel<$T>. '
        'Use one consistent type per channel name (treat the name like a '
        'typed key, the same discipline you already use for env/store keys).',
      );
      return existing as QLChannel<T>;
    }
    final created = QLChannel<T>();
    _channels[name] = created;
    return created;
  }

  void publish<T>(String name, T value) => channel<T>(name).publish(value);

  T valueOr<T>(String name, T fallback) {
    final existing = _channels[name];
    if (existing == null) return fallback;
    return (existing as QLChannel<T>).valueOr(fallback);
  }

  bool exists(String name) => _channels.containsKey(name);

  /// Clears every channel. Tests only — never call this from app code.
  @visibleForTesting
  void resetForTesting() => _channels.clear();
}

/// Rebuilds [builder] whenever the named channel changes. Reads the current
/// value (or [fallback]) immediately on first build, so there's no flash of
/// empty state if something already published before this widget mounted.
class QLChannelBuilder<T> extends StatefulWidget {
  final String name;
  final T fallback;
  final Widget Function(BuildContext context, T value) builder;

  const QLChannelBuilder({
    super.key,
    required this.name,
    required this.fallback,
    required this.builder,
  });

  @override
  State<QLChannelBuilder<T>> createState() => _QLChannelBuilderState<T>();
}

class _QLChannelBuilderState<T> extends State<QLChannelBuilder<T>> {
  late QLChannel<T> _channel;
  VoidCallback? _unsubscribe;
  late T _value;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() {
    _channel = QLChannelHub.instance.channel<T>(widget.name);
    _value = _channel.valueOr(widget.fallback);
    _unsubscribe = _channel.subscribe((v) {
      if (mounted) setState(() => _value = v);
    });
  }

  @override
  void didUpdateWidget(covariant QLChannelBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _unsubscribe?.call();
      _bind();
    }
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  NAV BRIDGE — routes publish their own context onto the hub
// ────────────────────────────────────────────────────────────────────────────

typedef QLRouteTitleResolver = String Function(QLRouteInfo info);

String _defaultRouteTitle(QLRouteInfo info) {
  final dynamic propTitle = info.props['title'];
  if (propTitle is String && propTitle.isNotEmpty) return propTitle;
  final segments = info.path.split('/').where((s) => s.isNotEmpty).toList();
  return segments.isNotEmpty ? segments.last : info.path;
}

/// Publishes `nav.current.title`, `nav.previous.title`, `nav.canPop`,
/// `nav.current.route` and `nav.previous.route` onto [QLChannelHub] every
/// time [controller]'s stack changes.
///
/// Call this once, right where you already construct your QLNavController:
///
/// ```dart
/// final nav = QLNavController(routes: myRoutes);
/// QLNavBridge.attach(nav);
/// ```
///
/// After that, any widget anywhere — including one with no reference to
/// `nav` at all — can read `nav.previous.title` via [QLChannelBuilder] or
/// [QLChannelHub.instance.valueOr]. That's what lets a back button placed
/// deep in a shared app-bar component know the previous page's title
/// without threading it through every route's props by hand.
///
/// If a route doesn't set an explicit `title` in its props, the last path
/// segment is used as a readable fallback. Pass [titleOf] to change that.
class QLNavBridge {
  QLNavBridge._();

  static VoidCallback attach(
    QLNavController controller, {
    QLRouteTitleResolver titleOf = _defaultRouteTitle,
  }) {
    void publish() {
      final stack = controller.stack;
      if (stack.isEmpty) return;
      final current = stack.last;
      final previous = stack.length > 1 ? stack[stack.length - 2] : null;

      QLChannelHub.instance.publish<QLRouteInfo>('nav.current.route', current);
      QLChannelHub.instance.publish<String>('nav.current.title', titleOf(current));
      QLChannelHub.instance.publish<bool>('nav.canPop', controller.canPop);

      if (previous != null) {
        QLChannelHub.instance.publish<QLRouteInfo>('nav.previous.route', previous);
        QLChannelHub.instance.publish<String>('nav.previous.title', titleOf(previous));
      } else {
        QLChannelHub.instance.publish<String>('nav.previous.title', '');
      }
    }

    publish();
    controller.addListener(publish);
    return () => controller.removeListener(publish);
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  PRESS GESTURE — hold, then escape up/down, exactly like a voice-message
//  record button. Reports phase changes; renders nothing on its own.
// ────────────────────────────────────────────────────────────────────────────

enum QLPressPhase {
  idle,
  active, // held, no escape yet
  cancelling, // dragged past cancelThreshold upward
  altPending, // dragged past altThreshold downward
  committed, // released while active
  cancelled, // released while cancelling
  altCommitted, // released while altPending
}

typedef QLPressPhaseCallback = void Function(QLPressPhase phase, double dragDy);

/// Wraps [child] with a press-and-hold gesture that can be escaped by
/// dragging while still held — up to cancel, down for an alternate action —
/// the interaction behind "hold the mic to record, swipe up to cancel,
/// swipe down to do something else."
///
/// This widget draws nothing extra and never rebuilds itself; it only calls
/// your callbacks. Drive whatever visual you want (a [QLMorphSlot], an
/// opacity, a channel publish for other widgets to read) from
/// [onPhaseChanged]. That keeps the gesture logic reusable across totally
/// different visual treatments, and means it costs nothing if you don't
/// wire a visual to it at all.
class QLPressGesture extends StatefulWidget {
  final Widget child;
  final VoidCallback? onCommit;
  final VoidCallback? onCancel;
  final VoidCallback? onAlt;
  final QLPressPhaseCallback? onPhaseChanged;
  final double cancelThreshold;
  final double altThreshold;

  const QLPressGesture({
    super.key,
    required this.child,
    this.onCommit,
    this.onCancel,
    this.onAlt,
    this.onPhaseChanged,
    this.cancelThreshold = 60,
    this.altThreshold = 60,
  });

  @override
  State<QLPressGesture> createState() => _QLPressGestureState();
}

class _QLPressGestureState extends State<QLPressGesture> {
  QLPressPhase _phase = QLPressPhase.idle;
  double _dragDy = 0;

  void _emit(QLPressPhase phase) {
    _phase = phase;
    widget.onPhaseChanged?.call(_phase, _dragDy);
  }

  void _onStart(LongPressStartDetails details) {
    _dragDy = 0;
    _emit(QLPressPhase.active);
  }

  void _onMove(LongPressMoveUpdateDetails details) {
    _dragDy = details.offsetFromOrigin.dy;
    if (_dragDy <= -widget.cancelThreshold) {
      _emit(QLPressPhase.cancelling);
    } else if (_dragDy >= widget.altThreshold) {
      _emit(QLPressPhase.altPending);
    } else {
      _emit(QLPressPhase.active);
    }
  }

  void _onEnd(LongPressEndDetails details) {
    switch (_phase) {
      case QLPressPhase.cancelling:
        widget.onCancel?.call();
        _emit(QLPressPhase.cancelled);
        break;
      case QLPressPhase.altPending:
        widget.onAlt?.call();
        _emit(QLPressPhase.altCommitted);
        break;
      case QLPressPhase.active:
        widget.onCommit?.call();
        _emit(QLPressPhase.committed);
        break;
      default:
        break;
    }
    // Settle back to idle after the commit/cancel/alt phase has had a chance
    // to be observed by whatever's driving the visual off onPhaseChanged.
    Future.microtask(() {
      if (mounted) _emit(QLPressPhase.idle);
    });
  }

  void _onCancelGesture() {
    if (_phase != QLPressPhase.idle) {
      widget.onCancel?.call();
      _emit(QLPressPhase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: _onStart,
      onLongPressMoveUpdate: _onMove,
      onLongPressEnd: _onEnd,
      onLongPressCancel: _onCancelGesture,
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  MORPH SLOT — swap named roles in place, optionally hero-linked
// ────────────────────────────────────────────────────────────────────────────

/// Cross-fades between named "roles" occupying the same tree position — the
/// pattern behind "the mic button becomes the recording UI in the same
/// spot the text field was." If [heroTag] is set, the active role is also
/// wrapped in [QLHero], so it can additionally morph into (or out of) a
/// matching tag on a different route, using the spring-curved Hero the
/// framework already ships (quantum_animation_engine.dart).
///
/// [roles] maps a role name to a builder for that role's content; only the
/// active role's builder is invoked, so inactive roles cost nothing.
class QLMorphSlot extends StatelessWidget {
  final String activeRole;
  final Map<String, WidgetBuilder> roles;
  final Duration duration;
  final String? heroTag;

  const QLMorphSlot({
    super.key,
    required this.activeRole,
    required this.roles,
    this.duration = const Duration(milliseconds: 220),
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    assert(roles.isNotEmpty, 'QLMorphSlot: roles must not be empty.');
    final builder = roles[activeRole] ?? roles.values.first;
    Widget content = builder(context);
    final tag = heroTag;
    if (tag != null) {
      content = QLHero(tag: tag, child: content);
    }
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(sizeFactor: anim, axisAlignment: -1, child: child),
      ),
      child: KeyedSubtree(key: ValueKey(activeRole), child: content),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  READY-MADE COMPOSITIONS
// ────────────────────────────────────────────────────────────────────────────

enum QLBackRevealMode { none, longPress }

/// A back button that already knows the previous page's title — it reads
/// `nav.previous.title` off [QLChannelHub], published by [QLNavBridge]. On
/// long-press it swaps its icon for a tag showing that title, then swaps
/// back on release. Every hook is overridable:
///
/// - [onBack] replaces the default `Navigator.maybePop`.
/// - [iconBuilder] / [tagBuilder] replace the default visuals.
/// - [revealMode] = QLBackRevealMode.none disables the long-press reveal
///   entirely (the button still knows the title; it just never shows it).
class QLSmartBackButton extends StatefulWidget {
  final VoidCallback? onBack;
  final QLBackRevealMode revealMode;
  final WidgetBuilder? iconBuilder;
  final Widget Function(BuildContext context, String title)? tagBuilder;

  const QLSmartBackButton({
    super.key,
    this.onBack,
    this.revealMode = QLBackRevealMode.longPress,
    this.iconBuilder,
    this.tagBuilder,
  });

  @override
  State<QLSmartBackButton> createState() => _QLSmartBackButtonState();
}

class _QLSmartBackButtonState extends State<QLSmartBackButton> {
  bool _revealed = false;

  void _handleBack() {
    final override = widget.onBack;
    if (override != null) {
      override();
      return;
    }
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return QLChannelBuilder<String>(
      name: 'nav.previous.title',
      fallback: '',
      builder: (context, title) {
        final canReveal =
            widget.revealMode == QLBackRevealMode.longPress && title.isNotEmpty;
        return GestureDetector(
          onTap: _handleBack,
          onLongPressStart: canReveal ? (_) => setState(() => _revealed = true) : null,
          onLongPressEnd: canReveal ? (_) => setState(() => _revealed = false) : null,
          onLongPressCancel: canReveal ? () => setState(() => _revealed = false) : null,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: (_revealed && canReveal)
                ? KeyedSubtree(
                    key: const ValueKey('ql-back-tag'),
                    child: widget.tagBuilder?.call(context, title) ??
                        _DefaultBackTag(title: title),
                  )
                : KeyedSubtree(
                    key: const ValueKey('ql-back-icon'),
                    child: widget.iconBuilder?.call(context) ??
                        const Icon(Icons.arrow_back),
                  ),
          ),
        );
      },
    );
  }
}

class _DefaultBackTag extends StatelessWidget {
  final String title;
  const _DefaultBackTag({required this.title});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    );
  }
}

/// Wraps any field widget together with its [QLFieldController] and shows a
/// close button only while the field is focused — "focus an input, a close
/// button appears next to it; tap it to blur/clear/whatever you wire it to."
/// Listens to the same `stateFlags` signal the framework's own
/// QLRawTrigger already listens to, so it stays correctly in sync with
/// framework-driven focus changes (not just user taps).
class QLFocusRevealField<T> extends StatefulWidget {
  final Widget field;
  final QLFieldController<T> controller;
  final Widget Function(BuildContext context, VoidCallback close)? closeButtonBuilder;

  const QLFocusRevealField({
    super.key,
    required this.field,
    required this.controller,
    this.closeButtonBuilder,
  });

  @override
  State<QLFocusRevealField<T>> createState() => _QLFocusRevealFieldState<T>();
}

class _QLFocusRevealFieldState<T> extends State<QLFocusRevealField<T>> {
  @override
  void initState() {
    super.initState();
    widget.controller.stateFlags.addListener(_onFlagsChanged);
  }

  void _onFlagsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.stateFlags.removeListener(_onFlagsChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.controller.isFocused;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: widget.field),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: focused
              ? (widget.closeButtonBuilder?.call(context, widget.controller.blur) ??
                  IconButton(
                    key: const ValueKey('ql-focus-close'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: widget.controller.blur,
                  ))
              : const SizedBox.shrink(key: ValueKey('ql-focus-empty')),
        ),
      ],
    );
  }
}


/// Bridges any signal-like atom into a [QLChannel] without introducing a new
/// reactive graph. Useful when you want the connect layer to mirror a local
/// atom or store-backed signal.
extension QLSignalChannelBridgeExt<T> on QLSignalBase<T> {
  VoidCallback publishToChannel(
    String name, {
    bool publishInitial = true,
  }) {
    void push() => QLChannelHub.instance.publish<T>(name, value);
    if (publishInitial) push();
    addListener(push);
    return () => removeListener(push);
  }
}
