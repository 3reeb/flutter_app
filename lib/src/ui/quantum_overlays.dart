import 'dart:async';
import 'dart:math' as math;


import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

// Quantum ecosystem — only the barrel import is needed after decoupling.
import '../../quantum.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Quantum Overlay Engine
// A hardened, production-oriented overlay manager for dialogs, sheets, drawers,
// menus, popovers, toasts, floating windows, and anchored inline editors.
//
// Notes:
// - This file assumes your project already provides QLSignal, QLBox, QLDataScope,
//   QEngine, and the rest of the Quantum ecosystem.
// - The implementation prefers explicit state, typed node lookups, and predictable
//   lifecycles over "magical" traversal.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Flags
// ─────────────────────────────────────────────────────────────────────────────

abstract final class QLNodeFlags {
  static const int none = 0;
  static const int isModal = 1 << 0;
  static const int hasBarrier = 1 << 1;
  static const int dismissible = 1 << 2;
  static const int isDraggable = 1 << 3;
  static const int isMenu = 1 << 4;
  static const int extrude3D = 1 << 5;
  static const int autoClose = 1 << 6;
  static const int allowResize = 1 << 7;
  static const int matchAnchorWidth = 1 << 8;
  static const int matchAnchorHeight = 1 << 9;
  static const int closeOnEscape = 1 << 10;
  static const int closeOnOutsideTap = 1 << 11;
  static const int useSafeArea = 1 << 12;
}

enum QLTransitionMode {
  fadeScale,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
  popover,
  windowDrop,
  fullscreen,
}

enum QLBackgroundEffect { none, blur, zoomBack, darken }

enum QLSheetEdge { top, bottom, left, right }

enum QLResizeEdge {
  none,
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

enum QLInteractionMode { none, drag, resize }

typedef QLOverlayBuilder = Widget Function(
  BuildContext context,
  VoidCallback close,
);

@immutable
class QLSpatialConfig {
  final int flags;
  final Alignment anchor;
  final double offsetX;
  final double offsetY;
  final double? targetLeft;
  final double? targetTop;
  final double? targetRight;
  final double? targetBottom;
  final List<double> snapPoints;
  final BoxConstraints constraints;
  final QLTransitionMode transition;
  final QLBackgroundEffect bgEffect;
  final Duration? timeout;
  // NOTE: Style is intentionally absent. The overlay engine handles spatial
  // logic only. Callers must style their own builder widget using Q() or QLBox().
  final int? ecsImposterId;
  final QLSheetEdge sheetEdge;
  final Alignment? sheetAlignment;
  final EdgeInsetsGeometry sheetPadding;
  final BorderRadius sheetBorderRadius;
  final Clip clipBehavior;
  final bool showDragHandle;
  final double dragHandleWidth;
  final double dragHandleHeight;
  final double dragHandleOpacity;
  final QLResizeEdge resizeEdges;
  final double bgZoomDepth;
  final double bgBlurSigma;
  final Color barrierColor;
  final double barrierOpacity;
  final Color rootBgColor; // 🚀 ADD THIS

  final bool allowDragging;
  final bool allowResizing;
  final bool closeOnOutsideTap;
  final bool closeOnEscape;
  final bool useSafeArea;
  final bool matchAnchorWidth;
  final bool matchAnchorHeight;
  final double? initialWidth;
  final double? initialHeight;
  final double minWidth;
  final double minHeight;
  final double maxDragExtent;

  const QLSpatialConfig({
    this.flags = QLNodeFlags.none,
    this.anchor = Alignment.center,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.targetLeft,
    this.targetTop,
    this.targetRight,
    this.targetBottom,
    this.snapPoints = const [],
    this.constraints = const BoxConstraints(),
    this.transition = QLTransitionMode.fadeScale,
    this.bgEffect = QLBackgroundEffect.none,
    this.timeout,
    this.ecsImposterId,
    this.sheetEdge = QLSheetEdge.bottom,
    this.sheetAlignment,
    this.sheetPadding = EdgeInsets.zero,
    this.sheetBorderRadius = BorderRadius.zero,
    this.clipBehavior = Clip.none,
    this.showDragHandle = false,
    this.dragHandleWidth = 36.0,
    this.dragHandleHeight = 4.0,
    this.dragHandleOpacity = 0.35,
    this.resizeEdges = QLResizeEdge.none,
    this.bgZoomDepth = 0.08,
    this.bgBlurSigma = 0.0,
    this.barrierColor = const Color(0xFF000000),
    this.rootBgColor = const Color(0xFF000000), // 🚀 ADD THIS

    this.barrierOpacity = 0.50,
    this.allowDragging = false,
    this.allowResizing = false,
    this.closeOnOutsideTap = true,
    this.closeOnEscape = true,
    this.useSafeArea = true,
    this.matchAnchorWidth = false,
    this.matchAnchorHeight = false,
    this.initialWidth,
    this.initialHeight,
    this.minWidth = 160.0,
    this.minHeight = 120.0,
    this.maxDragExtent = 1200.0,
  });

  factory QLSpatialConfig.dialog({
    bool barrierDismissible = true,
    bool extrude3D = true,
    QLBackgroundEffect effect = QLBackgroundEffect.blur,
    BoxConstraints constraints =
        const BoxConstraints(maxWidth: 480, maxHeight: 800),
    bool useSafeArea = true,
  }) {
    return QLSpatialConfig(
      flags: QLNodeFlags.isModal |
          QLNodeFlags.hasBarrier |
          (barrierDismissible ? QLNodeFlags.dismissible : 0) |
          (extrude3D ? QLNodeFlags.extrude3D : 0) |
          QLNodeFlags.closeOnEscape |
          QLNodeFlags.closeOnOutsideTap |
          (useSafeArea ? QLNodeFlags.useSafeArea : 0),
      anchor: Alignment.center,
      constraints: constraints,
      transition: QLTransitionMode.fadeScale,
      bgEffect: effect,
      allowDragging: false,
      allowResizing: false,
      closeOnOutsideTap: barrierDismissible,
      useSafeArea: useSafeArea,
    );
  }

  factory QLSpatialConfig.fullscreenDialog({
    bool barrierDismissible = true,
    QLBackgroundEffect effect = QLBackgroundEffect.darken,
    bool useSafeArea = false,
  }) {
    return QLSpatialConfig(
      flags: QLNodeFlags.isModal |
          QLNodeFlags.hasBarrier |
          (barrierDismissible ? QLNodeFlags.dismissible : 0) |
          QLNodeFlags.closeOnEscape |
          (useSafeArea ? QLNodeFlags.useSafeArea : 0),
      anchor: Alignment.center,
      // BoxConstraints() without expand() prevents unbounded infinity crashes.
      constraints: const BoxConstraints(),
      transition: QLTransitionMode.fullscreen,
      bgEffect: effect,
      useSafeArea: useSafeArea,
    );
  }

  factory QLSpatialConfig.sheet({
    bool dismissible = true,
    bool enableDrag = true,
    List<double> snapPoints = const [0.5, 1.0],
    QLBackgroundEffect effect = QLBackgroundEffect.zoomBack,
    BoxConstraints constraints = const BoxConstraints(maxWidth: 800, maxHeight: 720),
    QLSheetEdge edge = QLSheetEdge.bottom,
    Alignment? sheetAlignment,
    EdgeInsetsGeometry sheetPadding = EdgeInsets.zero,
    BorderRadius sheetBorderRadius = BorderRadius.zero,
    Clip clipBehavior = Clip.antiAlias,
    bool showDragHandle = true,
    double dragHandleWidth = 36.0,
    double dragHandleHeight = 4.0,
    double dragHandleOpacity = 0.35,
    double bgZoomDepth = 0.08,
    double bgBlurSigma = 0.0,
    double? initialWidth,
    double? initialHeight,
    bool useSafeArea = true,
    Color barrierColor = const Color(0xFF000000),
    double barrierOpacity = 0.50,
    Color rootBgColor = const Color(0xFF000000),
  }) {
    final transition = switch (edge) {
      QLSheetEdge.bottom => QLTransitionMode.slideUp,
      QLSheetEdge.top => QLTransitionMode.slideDown,
      QLSheetEdge.left => QLTransitionMode.slideRight,
      QLSheetEdge.right => QLTransitionMode.slideLeft
    };
    final Alignment resolvedAlignment = sheetAlignment ??
        switch (edge) {
          QLSheetEdge.bottom => Alignment.bottomCenter,
          QLSheetEdge.top => Alignment.topCenter,
          QLSheetEdge.left => Alignment.centerLeft,
          QLSheetEdge.right => Alignment.centerRight
        };

    return QLSpatialConfig(
      flags: QLNodeFlags.isModal |
          QLNodeFlags.hasBarrier |
          (dismissible ? QLNodeFlags.dismissible : 0) |
          (enableDrag ? QLNodeFlags.isDraggable : 0) |
          QLNodeFlags.closeOnEscape |
          QLNodeFlags.closeOnOutsideTap |
          (useSafeArea ? QLNodeFlags.useSafeArea : 0),
      anchor: resolvedAlignment,
      snapPoints: snapPoints,
      constraints: constraints,
      transition: transition,
      bgEffect: effect,
      sheetEdge: edge,
      sheetAlignment: resolvedAlignment,
      sheetPadding: sheetPadding,
      sheetBorderRadius: sheetBorderRadius,
      clipBehavior: clipBehavior,
      showDragHandle: showDragHandle,
      dragHandleWidth: dragHandleWidth,
      dragHandleHeight: dragHandleHeight,
      dragHandleOpacity: dragHandleOpacity,
      bgZoomDepth: bgZoomDepth,
      bgBlurSigma: bgBlurSigma,
      barrierColor: barrierColor,
      barrierOpacity: barrierOpacity,
      allowDragging: enableDrag,
      closeOnOutsideTap: dismissible,
      useSafeArea: useSafeArea,
      initialWidth: initialWidth,
      initialHeight: initialHeight,
      rootBgColor: rootBgColor,
    );
  }
  factory QLSpatialConfig.drawer({
    bool dismissible = true,
    bool enableDrag = true,
    QLSheetEdge edge = QLSheetEdge.left,
    BoxConstraints constraints = const BoxConstraints(maxWidth: 420, maxHeight: 720),
    bool useSafeArea = true,
    double bgZoomDepth = 0.06,
    Alignment? sheetAlignment,
    EdgeInsetsGeometry sheetPadding = EdgeInsets.zero,
    BorderRadius sheetBorderRadius = BorderRadius.zero,
    Clip clipBehavior = Clip.antiAlias,
    bool showDragHandle = true,
    Color barrierColor = const Color(0xFF000000),
    double barrierOpacity = 0.50,
    Color rootBgColor = const Color(0xFF000000),
  }) {
    return QLSpatialConfig.sheet(
      dismissible: dismissible,
      enableDrag: enableDrag,
      effect: QLBackgroundEffect.zoomBack,
      constraints: constraints,
      edge: edge,
      sheetAlignment: sheetAlignment,
      sheetPadding: sheetPadding,
      sheetBorderRadius: sheetBorderRadius,
      clipBehavior: clipBehavior,
      showDragHandle: showDragHandle,
      bgZoomDepth: bgZoomDepth,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      barrierOpacity: barrierOpacity,
      rootBgColor: rootBgColor,
      initialWidth: edge == QLSheetEdge.left || edge == QLSheetEdge.right
          ? constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : 360
          : null,
      initialHeight: edge == QLSheetEdge.top || edge == QLSheetEdge.bottom
          ? constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 400
          : null,
    );
  }
  factory QLSpatialConfig.menu({
    required double targetLeft,
    required double targetTop,
    required double targetRight,
    required double targetBottom,
    bool isModal = false,
    BoxConstraints constraints =
        const BoxConstraints(maxWidth: 280, maxHeight: 400),
    bool matchAnchorWidth = false,
  }) {
    return QLSpatialConfig(
      flags: QLNodeFlags.isMenu |
          QLNodeFlags.dismissible |
          QLNodeFlags.closeOnOutsideTap |
          QLNodeFlags.closeOnEscape |
          (matchAnchorWidth ? QLNodeFlags.matchAnchorWidth : 0) |
          (isModal ? (QLNodeFlags.isModal | QLNodeFlags.hasBarrier) : 0),
      targetLeft: targetLeft,
      targetTop: targetTop,
      targetRight: targetRight,
      targetBottom: targetBottom,
      constraints: constraints,
      transition: QLTransitionMode.popover,
      matchAnchorWidth: matchAnchorWidth,
      allowDragging: false,
      allowResizing: false,
    );
  }

  factory QLSpatialConfig.notification({
    Alignment position = Alignment.topCenter,
    Duration duration = const Duration(seconds: 4),
    BoxConstraints constraints = const BoxConstraints(maxWidth: 420, maxHeight: 720),
    bool closeOnOutsideTap = false,
  }) {
    return QLSpatialConfig(
      flags: QLNodeFlags.autoClose | QLNodeFlags.isDraggable,
      anchor: position,
      timeout: duration,
      constraints: constraints,
      transition: QLTransitionMode.fadeScale,
      allowDragging: true,
      closeOnOutsideTap: closeOnOutsideTap,
    );
  }

  factory QLSpatialConfig.toast({
    Alignment position = Alignment.topCenter,
    Duration duration = const Duration(seconds: 3),
    BoxConstraints constraints = const BoxConstraints(maxWidth: 420, maxHeight: 720),
  }) {
    return QLSpatialConfig.notification(
      position: position,
      duration: duration,
      constraints: constraints,
      closeOnOutsideTap: false,
    );
  }

  factory QLSpatialConfig.window({
    double initialX = 100.0,
    double initialY = 100.0,
    double initialWidth = 420.0,
    double initialHeight = 300.0,
    BoxConstraints constraints =
        const BoxConstraints(maxWidth: 800, maxHeight: 600),
    bool allowResize = true,
    QLResizeEdge resizeEdges = QLResizeEdge.bottomRight,
  }) {
    return QLSpatialConfig(
      flags: QLNodeFlags.isDraggable |
          QLNodeFlags.extrude3D |
          (allowResize ? QLNodeFlags.allowResize : 0) |
          QLNodeFlags.closeOnEscape |
          QLNodeFlags.closeOnOutsideTap,
      anchor: Alignment.topLeft,
      offsetX: initialX,
      offsetY: initialY,
      initialWidth: initialWidth,
      initialHeight: initialHeight,
      constraints: constraints,
      transition: QLTransitionMode.windowDrop,
      allowDragging: true,
      allowResizing: allowResize,
      resizeEdges: resizeEdges,
      useSafeArea: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Registry
// ─────────────────────────────────────────────────────────────────────────────

class _QLSpatialNodeState {
  _QLSpatialNodeState({
    required this.id,
    required this.parentId,
    required this.zIndex,
    required this.flags,
  });

  final int id;
  final int parentId;
  final int zIndex;
  final int flags;
  double left = 0.0;
  double top = 0.0;
  double right = 0.0;
  double bottom = 0.0;
  int parentLookup = 0;
}

class _QLSpatialRegistry {
  final Map<int, _QLSpatialNodeState> _nodes = <int, _QLSpatialNodeState>{};
  final List<int> _zOrder = <int>[];

  int insert(int id, int parentId, int zIndex, int flags) {
    final node = _QLSpatialNodeState(
      id: id,
      parentId: parentId,
      zIndex: zIndex,
      flags: flags,
    );
    _nodes[id] = node;
    _zOrder.add(id);
    return id;
  }

  void updateBounds(
      int id, double left, double top, double right, double bottom) {
    final node = _nodes[id];
    if (node == null) return;
    node.left = left;
    node.top = top;
    node.right = right;
    node.bottom = bottom;
  }

  void remove(int id) {
    _nodes.remove(id);
    _zOrder.remove(id);
  }

  _QLSpatialNodeState? byId(int id) => _nodes[id];

  int hitTest(double x, double y) {
    int hitId = 0;
    int highestZ = -0x7fffffff;
    for (int i = _zOrder.length - 1; i >= 0; i--) {
      final node = _nodes[_zOrder[i]];
      if (node == null) continue;
      if (x >= node.left &&
          x <= node.right &&
          y >= node.top &&
          y <= node.bottom) {
        if (node.zIndex >= highestZ) {
          highestZ = node.zIndex;
          hitId = node.id;
        }
      }
    }
    return hitId;
  }

  Set<int> ancestrySafeSet(int hitId) {
    final safe = <int>{};
    var currentId = hitId;
    int guard = 0;
    while (currentId > 0 && guard++ < 128) {
      final node = _nodes[currentId];
      if (node == null) break;
      safe.add(currentId);
      final nextParent = node.parentId;
      if (nextParent <= 0 || nextParent == currentId) break;
      currentId = nextParent;
    }
    return safe;
  }

  List<int> getDismissibleIds(double x, double y) {
    final hitId = hitTest(x, y);
    final safeIds = ancestrySafeSet(hitId);
    final toClose = <int>[];
    bool hitModalBarrier = false;

    for (int i = _zOrder.length - 1; i >= 0; i--) {
      final node = _nodes[_zOrder[i]];
      if (node == null) continue;

      final isSafe = safeIds.contains(node.id);
      if (isSafe) {
        if ((node.flags & QLNodeFlags.isModal) != 0) {
          hitModalBarrier = true;
        }
        continue;
      }

      if (hitModalBarrier) {
        continue;
      }

      final dismissible = (node.flags & QLNodeFlags.dismissible) != 0;
      final closeOnOutsideTap =
          (node.flags & QLNodeFlags.closeOnOutsideTap) != 0;
      if (dismissible && closeOnOutsideTap) {
        toClose.add(node.id);
      }
    }

    return toClose;
  }

  bool isEmpty() => _nodes.isEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// Engine
// ─────────────────────────────────────────────────────────────────────────────

class QuantumOverlay {
  static final QuantumOverlay instance = QuantumOverlay._();
  QuantumOverlay._();

  final _QLSpatialRegistry _registry = _QLSpatialRegistry();
  final QLSignal<List<_QLNodeWrapper>> _activeNodes =
      QLSignal(<_QLNodeWrapper>[]);

  int get topNodeId =>
      _activeNodes.value.isNotEmpty ? _activeNodes.value.last.id : 0;

  int _idCounter = 1000 + math.Random().nextInt(9000);
  int _zCounter = 1;

  final QLSignal<Matrix4> _bgTransform = QLSignal(Matrix4.identity());
  final QLSignal<Alignment> _bgAlignment = QLSignal(Alignment.center);
  final QLSignal<double> _bgRadius = QLSignal(0.0);
  final QLSignal<Color> _scrimColor = QLSignal(const Color(0x00000000));
  final QLSignal<Color> _rootBgColor =
      QLSignal(const Color(0xFF000000)); // 🚀 ADD THIS
  final QLSignal<bool> _hasActiveBarrier = QLSignal(false);

  @visibleForTesting
  void resetForTesting() {
    _activeNodes.value = <_QLNodeWrapper>[];
    _registry._nodes.clear();
    _registry._zOrder.clear();
    _bgTransform.update((m) => m.setIdentity());
    _bgRadius.value = 0.0;
    _scrimColor.value = const Color(0x00000000);
    _hasActiveBarrier.value = false;
  }

  void _handleGlobalPointerDown(Offset pos) {
    if (_activeNodes.value.isEmpty) return;
    final toClose = _registry.getDismissibleIds(pos.dx, pos.dy);
    for (final id in toClose) {
      _closeNode(id);
    }
  }

  void _handleEscape() {
    if (_activeNodes.value.isEmpty) return;
    final top = _activeNodes.value.last;
    if ((top.config.flags & QLNodeFlags.closeOnEscape) != 0 ||
        top.config.closeOnEscape) {
      _closeNode(top.id);
    }
  }

  void _closeNode(int id) {
    final nodes = _activeNodes.value;
    final idx = nodes.indexWhere((n) => n.id == id);
    if (idx != -1) {
      nodes[idx].closeTrigger();
    }
  }

  void closeTop() {
    if (_activeNodes.value.isNotEmpty) {
      _activeNodes.value.last.closeTrigger();
    }
  }

  void _cleanupNode(int id) {
    _registry.remove(id);
    final nodes = List<_QLNodeWrapper>.from(_activeNodes.value)
      ..removeWhere((n) => n.id == id);
    _activeNodes.value = nodes;
    _recalculateBackgroundEffects();
  }

  void _recalculateBackgroundEffects() {
    if (_activeNodes.value.isEmpty) {
      _bgTransform.update((m) => m.setIdentity());
      _bgRadius.value = 0.0;
      _scrimColor.value = const Color(0x00000000);
      _hasActiveBarrier.value = false;
      _bgAlignment.value = Alignment.center;
      return;
    }

    bool requiresBarrier = false;
    QLBackgroundEffect activeEffect = QLBackgroundEffect.none;
    double bgZoomDepth = 0.08, blurSigma = 0.0, barrierOpacity = 0.50;
    Color barrierColor = const Color(0xFF000000);
    Color rootBgColor = const Color(0xFF000000); // 🚀 Track root color
    Alignment bgAlign = Alignment.center;

    for (int i = _activeNodes.value.length - 1; i >= 0; i--) {
      final conf = _activeNodes.value[i].config;
      if ((conf.flags & QLNodeFlags.hasBarrier) != 0) requiresBarrier = true;
      if (activeEffect == QLBackgroundEffect.none &&
          conf.bgEffect != QLBackgroundEffect.none) {
        activeEffect = conf.bgEffect;
        bgZoomDepth = conf.bgZoomDepth;
        blurSigma = conf.bgBlurSigma;
        barrierColor = conf.barrierColor;
        barrierOpacity = conf.barrierOpacity;
        rootBgColor = conf.rootBgColor; // 🚀 Capture custom background color

        // 🚀 DYNAMIC ZOOM ANCHOR FIX
        // To leave space on the OPPOSITE side of the overlay, the background must anchor to the SAME side as the overlay.
        if (conf.transition == QLTransitionMode.slideLeft)
          bgAlign = Alignment
              .centerRight; // Overlay on Right -> Anchor Right -> Space on Left
        else if (conf.transition == QLTransitionMode.slideRight)
          bgAlign = Alignment
              .centerLeft; // Overlay on Left -> Anchor Left -> Space on Right
        else if (conf.transition == QLTransitionMode.slideUp)
          bgAlign = Alignment
              .bottomCenter; // Overlay on Bottom -> Anchor Bottom -> Space on Top
        else if (conf.transition == QLTransitionMode.slideDown)
          bgAlign = Alignment
              .topCenter; // Overlay on Top -> Anchor Top -> Space on Bottom
      }
    }
    _hasActiveBarrier.value = requiresBarrier;
    _bgAlignment.value = bgAlign;
    _rootBgColor.value = rootBgColor; // 🚀 Apply custom background color

    final double clampedOpacity = barrierOpacity.clamp(0.0, 1.0);
    if (activeEffect == QLBackgroundEffect.zoomBack) {
      final scale = (1.0 - bgZoomDepth).clamp(0.82, 1.0).toDouble();
      _bgTransform.update((m) {
        m.setIdentity();
        m.storage[0] = scale;
        m.storage[5] = scale;
        m.storage[10] = scale;
      });
      _bgRadius.value = blurSigma > 0.0 ? blurSigma : 16.0;
      _scrimColor.value = barrierColor.withValues(alpha: clampedOpacity);
    } else if (activeEffect == QLBackgroundEffect.blur) {
      _bgTransform.update((m) => m.setIdentity());
      _bgRadius.value = blurSigma > 0.0 ? blurSigma : 0.0;
      _scrimColor.value = barrierColor.withValues(alpha: clampedOpacity);
    } else if (activeEffect == QLBackgroundEffect.darken) {
      _bgTransform.update((m) => m.setIdentity());
      _bgRadius.value = 0.0;
      _scrimColor.value = barrierColor.withValues(alpha: clampedOpacity);
    } else {
      _bgTransform.update((m) => m.setIdentity());
      _bgRadius.value = 0.0;
      _scrimColor.value = const Color(0x00000000);
    }
  }

  Future<T?> mount<T>(
    BuildContext? context,
    QLSpatialConfig config,
    QLOverlayBuilder builder, {
    int parentId = 0,
  }) {
    final completer = Completer<T?>();
    final int id = _idCounter++;
    final int zIndex = _zCounter++;

    _registry.insert(id, parentId, zIndex, config.flags);

    void completeNull() {
      if (!completer.isCompleted) completer.complete(null);
    }

    final wrapper = _QLNodeWrapper(
      id: id,
      config: config,
      builder: builder,
      parentScope: context != null ? QLDataScope.ofNode(context) : null,
      onCleanedUp: () => _cleanupNode(id),
    );

    wrapper.closeTrigger = () {
      wrapper.nodeKey.currentState?.beginExit(completeNull);
    };

    final nodes = List<_QLNodeWrapper>.from(_activeNodes.value)..add(wrapper);
    _activeNodes.value = nodes;
    _recalculateBackgroundEffects();
    return completer.future;
  }

  Widget buildMasterStack() {
    return AnimatedBuilder(
      animation: _activeNodes,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: _activeNodes.value
              .map(
                (node) => _QLUniversalNode(
                  key: node.nodeKey,
                  wrapper: node,
                  onBoundsCalculated: (left, top, right, bottom) {
                    _registry.updateBounds(node.id, left, top, right, bottom);
                  },
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _QLNodeWrapper {
  final int id;
  final QLSpatialConfig config;
  final QLOverlayBuilder builder;
  final QLDataScope? parentScope;
  final VoidCallback onCleanedUp;
  late VoidCallback closeTrigger;
  final GlobalKey<_QLUniversalNodeState> nodeKey =
      GlobalKey<_QLUniversalNodeState>();

  _QLNodeWrapper({
    required this.id,
    required this.config,
    required this.builder,
    required this.parentScope,
    required this.onCleanedUp,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Root host
// ─────────────────────────────────────────────────────────────────────────────

class QLOverlayRoot extends StatefulWidget {
  final Widget child;
  const QLOverlayRoot({super.key, required this.child});

  @override
  State<QLOverlayRoot> createState() => _QLOverlayRootState();
}

class _QLOverlayRootState extends State<QLOverlayRoot> {
  @override
  void dispose() {
    QuantumOverlay.instance.resetForTesting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent()
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (_) {
            QuantumOverlay.instance._handleEscape();
            return null;
          })
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) =>
              QuantumOverlay.instance._handleGlobalPointerDown(e.position),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 🚀 FOREVER FIX: Reactive Background Color Layer
              AnimatedBuilder(
                animation: QuantumOverlay.instance._rootBgColor,
                builder: (ctx, child) => Container(
                  color: QuantumOverlay.instance._rootBgColor.value,
                  child: child,
                ),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    QuantumOverlay.instance._bgTransform,
                    QuantumOverlay.instance._bgAlignment
                  ]),
                  builder: (ctx, child) => Transform(
                    alignment: QuantumOverlay.instance._bgAlignment
                        .value, // 🚀 Anchors the zoom properly
                    transform: QuantumOverlay.instance._bgTransform.value,
                    child: child,
                  ),
                  // AnimatedBuilder + ClipRRect for animated corner radius.
                  // Pure Flutter — no QLBox or theme engine dependency.
                  child: AnimatedBuilder(
                    animation: QuantumOverlay.instance._bgRadius,
                    builder: (ctx, child) => ClipRRect(
                      borderRadius: BorderRadius.circular(
                          QuantumOverlay.instance._bgRadius.value),
                      child: child,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: QuantumOverlay.instance._hasActiveBarrier,
                builder: (context, _) => IgnorePointer(
                  ignoring: !QuantumOverlay.instance._hasActiveBarrier.value,
                  child: AnimatedBuilder(
                      animation: QuantumOverlay.instance._scrimColor,
                      builder: (ctx, _) => Container(
                          color: QuantumOverlay.instance._scrimColor.value)),
                ),
              ),
              QuantumOverlay.instance.buildMasterStack(),
            ],
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Universal node
// ─────────────────────────────────────────────────────────────────────────────

class _QLUniversalNode extends StatefulWidget {
  final _QLNodeWrapper wrapper;
  final void Function(double left, double top, double right, double bottom)
      onBoundsCalculated;

  const _QLUniversalNode(
      {super.key, required this.wrapper, required this.onBoundsCalculated});

  @override
  State<_QLUniversalNode> createState() => _QLUniversalNodeState();
}

class _QLUniversalNodeState extends State<_QLUniversalNode>
    with TickerProviderStateMixin {
  late final QLTransitionComposer _composer;
  bool _initialized = false;
  final GlobalKey _contentKey = GlobalKey();
  Timer? _timeout;

  double _x = 0.0;
  double _y = 0.0;
  double _w = 0.0;
  double _h = 0.0;
  double _dragDx = 0.0;
  double _dragDy = 0.0;
  bool _hasExplicitBox = false;
  bool _gestureActive = false;
  int? _activePointer;

  QLInteractionMode _mode = QLInteractionMode.none;
  QLResizeEdge _resizeEdge = QLResizeEdge.none;
  double _startX = 0.0;
  double _startY = 0.0;
  double _startW = 0.0;
  double _startH = 0.0;
  double _sheetOvershoot = 0.0;

  @override
  void initState() {
    super.initState();
    _applyInitialLayout();
    WidgetsBinding.instance.addPostFrameCallback((_) => _calcBounds());
    final timeout = widget.wrapper.config.timeout;
    if (timeout != null) {
      _timeout = Timer(timeout, () => beginExit(() {}));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _composer = QLTransitionComposer.entrance(
        vsync: this,
        preset: _mapPreset(widget.wrapper.config.transition),
        screenSize: MediaQuery.sizeOf(context),
      );
    }
  }

  QLTransitionPreset _mapPreset(QLTransitionMode mode) {
    switch (mode) {
      case QLTransitionMode.fadeScale:
        return QLTransitionPresets.dialog;
      case QLTransitionMode.slideUp:
        return QLTransitionPresets.sheet;
      case QLTransitionMode.slideDown:
        return QLTransitionPreset(fromScale: 1.0, fromOpacity: 0.0, fromTranslate: const Offset(0, -1), curve: QLSprings.sheet, duration: const Duration(milliseconds: 420));
      case QLTransitionMode.slideLeft:
        return QLTransitionPresets.drawer;
      case QLTransitionMode.slideRight:
        return QLTransitionPreset(fromScale: 1.0, fromOpacity: 0.0, fromTranslate: const Offset(1, 0), curve: QLSprings.sheet, duration: const Duration(milliseconds: 380));
      case QLTransitionMode.popover:
        return QLTransitionPresets.menu;
      case QLTransitionMode.windowDrop:
        return QLTransitionPresets.window;
      case QLTransitionMode.fullscreen:
        return QLTransitionPresets.full;
    }
  }

  void _applyInitialLayout() {
    final conf = widget.wrapper.config;
    _x = conf.offsetX;
    _y = conf.offsetY;
    _w = conf.initialWidth ??
        (conf.constraints.maxWidth.isFinite
            ? math.max(
                conf.minWidth, math.min(conf.constraints.maxWidth, 420.0))
            : 420.0);
    _h = conf.initialHeight ??
        (conf.constraints.maxHeight.isFinite
            ? math.max(
                conf.minHeight, math.min(conf.constraints.maxHeight, 300.0))
            : 300.0);

    _hasExplicitBox =
        conf.transition == QLTransitionMode.windowDrop || conf.allowResizing;

    if (conf.targetLeft != null && conf.targetTop != null) {
      _x = conf.targetLeft!;
      _y = conf.targetBottom != null
          ? conf.targetBottom! + 8.0
          : conf.targetTop!;
    }

    if (conf.matchAnchorWidth &&
        conf.targetLeft != null &&
        conf.targetRight != null) {
      _w = math.max(conf.minWidth, conf.targetRight! - conf.targetLeft!);
    }
    if (conf.matchAnchorHeight &&
        conf.targetTop != null &&
        conf.targetBottom != null) {
      _h = math.max(conf.minHeight, conf.targetBottom! - conf.targetTop!);
    }
  }

  BoxConstraints _effectiveConstraints(QLSpatialConfig c, Size screenSize) {
    final bool needsSafeArea =
        c.useSafeArea || (c.flags & QLNodeFlags.useSafeArea) != 0;

    final EdgeInsets safePadding =
        needsSafeArea ? MediaQuery.of(context).viewPadding : EdgeInsets.zero;
    final double availableWidth =
        math.max(0.0, screenSize.width - safePadding.horizontal - 24.0);
    final double availableHeight =
        math.max(0.0, screenSize.height - safePadding.vertical - 24.0);

    final bool verticalSheet = c.transition == QLTransitionMode.slideUp ||
        c.transition == QLTransitionMode.slideDown;
    final bool horizontalSheet = c.transition == QLTransitionMode.slideLeft ||
        c.transition == QLTransitionMode.slideRight;

    final double maxWidth = c.constraints.maxWidth.isFinite
        ? math.min(c.constraints.maxWidth, availableWidth)
        : availableWidth;
    final double maxHeight = c.constraints.maxHeight.isFinite
        ? math.min(c.constraints.maxHeight, availableHeight)
        : availableHeight;

    final double effectiveMaxWidth = horizontalSheet
        ? math.min(maxWidth, screenSize.width * 0.92)
        : maxWidth;
    final double effectiveMaxHeight = verticalSheet
        ? math.min(maxHeight, screenSize.height * 0.92)
        : maxHeight;

    final double minWidth = math.min(
      math.max(0.0, c.constraints.minWidth),
      effectiveMaxWidth,
    );
    final double minHeight = math.min(
      math.max(0.0, c.constraints.minHeight),
      effectiveMaxHeight,
    );

    if (c.transition == QLTransitionMode.fullscreen) {
      return BoxConstraints.tight(screenSize);
    }

    return BoxConstraints(
      minWidth: minWidth,
      maxWidth: effectiveMaxWidth,
      minHeight: minHeight,
      maxHeight: effectiveMaxHeight,
    );
  }

  void beginExit(VoidCallback onComplete) {
    _timeout?.cancel();
    if (mounted) {
      _composer.exit(onComplete: () {
        onComplete();
        widget.wrapper.onCleanedUp();
      });
    }
  }

  void _calcBounds() {
    if (!mounted) return;

    final imposterId = widget.wrapper.config.ecsImposterId;
    if (imposterId != null && imposterId != -1) {
      final t = QEngine.instance.ecs.comp('transform');
      final b = QEngine.instance.ecs.comp('bounds');

      final double worldX = t.get(imposterId, 6);
      final double worldY = t.get(imposterId, 1);
      final double w = b.get(imposterId, 0);
      final double h = b.get(imposterId, 1);

      final scrollState =
          Scrollable.maybeOf(_contentKey.currentContext ?? context);
      final double scrollOffset = scrollState?.position.pixels ?? 0.0;

      _x = worldX;
      _y = worldY - scrollOffset;
      _w = w;
      _h = h;
      widget.onBoundsCalculated(_x, _y, _x + _w, _y + _h);
      SchedulerBinding.instance.addPostFrameCallback((_) => _calcBounds());
      return;
    }

    final ctx = _contentKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final pos = box.localToGlobal(Offset.zero);
      final right = pos.dx + box.size.width;
      final bottom = pos.dy + box.size.height;
      widget.onBoundsCalculated(pos.dx, pos.dy, right, bottom);

      if (!_hasExplicitBox) {
        _x = pos.dx;
        _y = pos.dy;
        _w = box.size.width;
        _h = box.size.height;
      }
    }
  }

  QLResizeEdge _detectResizeEdge(
      Offset local, Size size, QLResizeEdge allowed) {
    const zone = 12.0;
    final x = local.dx;
    final y = local.dy;
    final w = size.width;
    final h = size.height;

    final left = x <= zone;
    final right = x >= w - zone;
    final top = y <= zone;
    final bottom = y >= h - zone;

    bool ok(QLResizeEdge e) {
      if (allowed == QLResizeEdge.none) return false;
      if (allowed == QLResizeEdge.topLeft ||
          allowed == QLResizeEdge.topRight ||
          allowed == QLResizeEdge.bottomLeft ||
          allowed == QLResizeEdge.bottomRight) {
        return allowed == e;
      }
      return allowed == QLResizeEdge.left ||
              allowed == QLResizeEdge.right ||
              allowed == QLResizeEdge.top ||
              allowed == QLResizeEdge.bottom ||
              allowed == QLResizeEdge.none
          ? allowed == e
          : true;
    }

    if (left && top && ok(QLResizeEdge.topLeft)) return QLResizeEdge.topLeft;
    if (right && top && ok(QLResizeEdge.topRight)) return QLResizeEdge.topRight;
    if (left && bottom && ok(QLResizeEdge.bottomLeft))
      return QLResizeEdge.bottomLeft;
    if (right && bottom && ok(QLResizeEdge.bottomRight))
      return QLResizeEdge.bottomRight;
    if (left && ok(QLResizeEdge.left)) return QLResizeEdge.left;
    if (right && ok(QLResizeEdge.right)) return QLResizeEdge.right;
    if (top && ok(QLResizeEdge.top)) return QLResizeEdge.top;
    if (bottom && ok(QLResizeEdge.bottom)) return QLResizeEdge.bottom;
    return QLResizeEdge.none;
  }

  void _beginInteraction(PointerDownEvent e) {
    if (_activePointer != null) return;
    final conf = widget.wrapper.config;
    _activePointer = e.pointer;
    _gestureActive = true;

    final size = _contentKey.currentContext?.findRenderObject() is RenderBox
        ? (_contentKey.currentContext!.findRenderObject() as RenderBox).size
        : Size(_w, _h);
    final resizeEdge = conf.allowResizing
        ? _detectResizeEdge(e.localPosition, size, conf.resizeEdges)
        : QLResizeEdge.none;
    if (resizeEdge != QLResizeEdge.none) {
      _mode = QLInteractionMode.resize;
      _resizeEdge = resizeEdge;
    } else if (conf.allowDragging ||
        (conf.flags & QLNodeFlags.isDraggable) != 0) {
      _mode = QLInteractionMode.drag;
    } else {
      _mode = QLInteractionMode.none;
    }

    _startX = _x;
    _startY = _y;
    _startW = _w;
    _startH = _h;
    _sheetOvershoot = 0.0;
  }

  void _moveInteraction(PointerMoveEvent e) {
    if (_activePointer != e.pointer || !_gestureActive) return;
    final conf = widget.wrapper.config;
    final dx = e.delta.dx;
    final dy = e.delta.dy;

    if (_mode == QLInteractionMode.resize) {
      _applyResize(dx, dy);
      if (mounted) setState((){});
      _calcBounds();
      return;
    }

    if (_mode != QLInteractionMode.drag) return;

    switch (conf.transition) {
      case QLTransitionMode.slideUp:
      case QLTransitionMode.slideDown:
        _sheetOvershoot = math.min(conf.maxDragExtent,
            math.max(-conf.maxDragExtent, _sheetOvershoot + dy));
        break;
      case QLTransitionMode.slideLeft:
      case QLTransitionMode.slideRight:
        _sheetOvershoot = math.min(conf.maxDragExtent,
            math.max(-conf.maxDragExtent, _sheetOvershoot + dx));
        break;
      default:
        _dragDx += dx;
        _dragDy += dy;
        break;
    }

    if (mounted) setState((){});
    _calcBounds();
  }

  void _applyResize(double dx, double dy) {
    final conf = widget.wrapper.config;
    double x = _startX;
    double y = _startY;
    double w = _startW;
    double h = _startH;

    switch (_resizeEdge) {
      case QLResizeEdge.left:
        x += dx;
        w -= dx;
        break;
      case QLResizeEdge.right:
        w += dx;
        break;
      case QLResizeEdge.top:
        y += dy;
        h -= dy;
        break;
      case QLResizeEdge.bottom:
        h += dy;
        break;
      case QLResizeEdge.topLeft:
        x += dx;
        w -= dx;
        y += dy;
        h -= dy;
        break;
      case QLResizeEdge.topRight:
        w += dx;
        y += dy;
        h -= dy;
        break;
      case QLResizeEdge.bottomLeft:
        x += dx;
        w -= dx;
        h += dy;
        break;
      case QLResizeEdge.bottomRight:
        w += dx;
        h += dy;
        break;
      case QLResizeEdge.none:
        break;
    }

    w = math.max(conf.minWidth, w);
    h = math.max(conf.minHeight, h);

    final maxW = conf.constraints.maxWidth;
    final maxH = conf.constraints.maxHeight;
    if (maxW.isFinite) w = math.min(maxW, w);
    if (maxH.isFinite) h = math.min(maxH, h);

    _x = x;
    _y = y;
    _w = w;
    _h = h;
  }

  void _endInteraction(PointerUpEvent e) {
    if (_activePointer != e.pointer) return;
    final conf = widget.wrapper.config;
    _gestureActive = false;
    _activePointer = null;

    switch (conf.transition) {
      case QLTransitionMode.slideUp:
        if (_sheetOvershoot > 150) {
          beginExit(() {});
          return;
        }
        _sheetOvershoot = 0.0;
        break;
      case QLTransitionMode.slideDown:
        if (_sheetOvershoot < -150) {
          beginExit(() {});
          return;
        }
        _sheetOvershoot = 0.0;
        break;
      case QLTransitionMode.slideLeft:
        if (_sheetOvershoot < -150) {
          beginExit(() {});
          return;
        }
        _sheetOvershoot = 0.0;
        break;
      case QLTransitionMode.slideRight:
        if (_sheetOvershoot > 150) {
          beginExit(() {});
          return;
        }
        _sheetOvershoot = 0.0;
        break;
      default:
        break;
    }

    if (_mode == QLInteractionMode.drag) {
      if (conf.transition == QLTransitionMode.slideUp ||
          conf.transition == QLTransitionMode.slideDown ||
          conf.transition == QLTransitionMode.slideLeft ||
          conf.transition == QLTransitionMode.slideRight) {
        _dragDx = 0.0;
        _dragDy = 0.0;
      }
      _composer.play();
      _calcBounds();
    }

    _mode = QLInteractionMode.none;
    _resizeEdge = QLResizeEdge.none;
    if (mounted) setState((){});
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.wrapper.config;
    final builder = Builder(
        builder: (ctx) => widget.wrapper.builder(ctx, () => beginExit(() {})));
    final injected = widget.wrapper.parentScope != null
        ? QLDataScope(
            localData: widget.wrapper.parentScope!.localData,
            localStore: widget.wrapper.parentScope!.localStore,
            moduleStore: widget.wrapper.parentScope!.moduleStore,
            child: builder)
        : builder;

    Widget content = AnimatedBuilder(
      animation: Listenable.merge([
        _composer.scaleSignal,
        _composer.translateSignal,
        _composer.opacitySignal,
      ]),
      builder: (ctx, child) {
        final m = Matrix4.identity();
        final scale = _composer.scaleSignal.value;
        if (scale != 1.0) {
          m.storage[0] = scale;
          m.storage[5] = scale;
          m.storage[10] = scale;
        }

        final trans = _composer.translateSignal.value;
        m.storage[12] = trans.dx + _dragDx;
        m.storage[13] = trans.dy + _dragDy;

        if (_sheetOvershoot != 0.0) {
          switch (c.sheetEdge) {
            case QLSheetEdge.bottom: m.storage[13] += _sheetOvershoot; break;
            case QLSheetEdge.top: m.storage[13] -= _sheetOvershoot; break;
            case QLSheetEdge.left: m.storage[12] -= _sheetOvershoot; break;
            case QLSheetEdge.right: m.storage[12] += _sheetOvershoot; break;
          }
        }

        if ((c.flags & QLNodeFlags.extrude3D) != 0) {
          m.setEntry(3, 2, 0.001);
          m.storage[14] -= 150.0 * (1.0 - _composer.opacitySignal.value);
        }

        return Transform(transform: m, child: child);
      },
      child: Listener(
        behavior: HitTestBehavior.deferToChild,
        onPointerDown: _beginInteraction,
        onPointerMove: _moveInteraction,
        onPointerUp: _endInteraction,
        onPointerCancel: (_) {
          _gestureActive = false;
          _activePointer = null;
          _mode = QLInteractionMode.none;
          _resizeEdge = QLResizeEdge.none;
        },
        child: LayoutBuilder(
          builder: (ctx, viewportConstraints) {
            final Size screenSize = MediaQuery.sizeOf(ctx);
            final BoxConstraints effectiveConstraints =
                _effectiveConstraints(c, screenSize).enforce(viewportConstraints);

            return ConstrainedBox(
              constraints: effectiveConstraints,
              child: Material(
                type: MaterialType.transparency,
                child: AnimatedBuilder(
                  animation: _composer.opacitySignal,
                  builder: (ctx, child) => Opacity(
                    opacity: _composer.opacitySignal.value.clamp(0.0, 1.0),
                    child: child,
                  ),
                  child: injected,
                ),
              ),
            );
          },
        ),
      ),
    );

    if (c.bgEffect == QLBackgroundEffect.blur) {
      content = QLGlassLayer(
        config: QLGlassConfig(
          blur: c.bgBlurSigma > 0.0 ? c.bgBlurSigma : 12.0,
          tint: Colors.transparent,
          borderOpacity: 0.0,
          shadows: const [],
          radius: BorderRadius.zero,
        ),
        child: content,
      );
    }

    final bool needsSafeArea =
        c.useSafeArea || (c.flags & QLNodeFlags.useSafeArea) != 0;

    Widget innerChild = KeyedSubtree(key: _contentKey, child: content);

    if (c.showDragHandle) {
      final handleColor =
          Colors.white.withValues(alpha: c.dragHandleOpacity.clamp(0.0, 1.0).toDouble());
      innerChild = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: c.dragHandleHeight.clamp(0.0, 24.0).toDouble()),
          Center(
            child: Container(
              width: c.dragHandleWidth.clamp(16.0, 80.0).toDouble(),
              height: c.dragHandleHeight.clamp(2.0, 12.0).toDouble(),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius:
                    BorderRadius.circular(c.dragHandleHeight.clamp(2.0, 12.0).toDouble()),
              ),
            ),
          ),
          SizedBox(height: c.dragHandleHeight.clamp(0.0, 16.0).toDouble()),
          innerChild,
        ],
      );
    }

    if (c.sheetPadding != EdgeInsets.zero) {
      innerChild = Padding(padding: c.sheetPadding, child: innerChild);
    }

    if (c.sheetBorderRadius != BorderRadius.zero || c.clipBehavior != Clip.none) {
      innerChild = ClipRRect(
        borderRadius: c.sheetBorderRadius,
        clipBehavior: c.clipBehavior,
        child: innerChild,
      );
    }

    if (needsSafeArea) {
      innerChild = SafeArea(child: innerChild);
    }

    final bool sheetIsVertical = c.sheetEdge == QLSheetEdge.top ||
        c.sheetEdge == QLSheetEdge.bottom ||
        c.transition == QLTransitionMode.slideUp ||
        c.transition == QLTransitionMode.slideDown;
    final bool sheetIsHorizontal = c.sheetEdge == QLSheetEdge.left ||
        c.sheetEdge == QLSheetEdge.right ||
        c.transition == QLTransitionMode.slideLeft ||
        c.transition == QLTransitionMode.slideRight;
    if (sheetIsVertical || sheetIsHorizontal) {
      final Axis scrollAxis = sheetIsHorizontal ? Axis.horizontal : Axis.vertical;
      innerChild = QuantumScrollScope(
        axis: scrollAxis,
        child: ClipRect(
          child: SingleChildScrollView(
            scrollDirection: scrollAxis,
            primary: false,
            physics: const ClampingScrollPhysics(),
            child: innerChild,
          ),
        ),
      );
    }

    final menuLike = (c.flags & QLNodeFlags.isMenu) != 0 ||
        c.transition == QLTransitionMode.popover;

    if (menuLike && c.targetLeft != null && c.targetTop != null) {
      final anchorWidth = c.targetRight != null && c.targetLeft != null
          ? (c.targetRight! - c.targetLeft!)
          : null;
      if (c.matchAnchorWidth || (c.flags & QLNodeFlags.matchAnchorWidth) != 0) {
        return Positioned(
          left: c.targetLeft,
          top: (c.targetBottom ?? c.targetTop!) + 8.0,
          width: anchorWidth,
          child: innerChild,
        );
      } else {
        return Positioned(
          left: c.targetLeft,
          top: (c.targetBottom ?? c.targetTop!) + 8.0,
          child: innerChild,
        );
      }
    }

    if (c.transition == QLTransitionMode.fullscreen) {
      return Positioned.fill(child: innerChild);
    }

    if (_hasExplicitBox) {
      return Positioned(
          left: _x, top: _y, width: _w, height: _h, child: innerChild);
    } else {
      return Positioned.fill(
          child: Align(alignment: c.sheetAlignment ?? c.anchor, child: innerChild));
    }
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Context helpers
// ─────────────────────────────────────────────────────────────────────────────

extension QuantumOverlayContextExt on BuildContext {
  Future<T?> mountOverlay<T>(QLSpatialConfig config, QLOverlayBuilder builder,
      {int parentId = 0}) {
    return QuantumOverlay.instance
        .mount<T>(this, config, builder, parentId: parentId);
  }

  Future<T?> showQLDialog<T>({
    bool barrierDismissible = true,
    bool extrude3D = true,
    QLBackgroundEffect effect = QLBackgroundEffect.blur,
    BoxConstraints constraints =
        const BoxConstraints(maxWidth: 480, maxHeight: 800),
    bool useSafeArea = true,
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<T>(
      QLSpatialConfig.dialog(
        barrierDismissible: barrierDismissible,
        extrude3D: extrude3D,
        effect: effect,
        constraints: constraints,
        useSafeArea: useSafeArea,
      ),
      builder,
    );
  }

  Future<T?> showQLFullScreenDialog<T>({
    bool barrierDismissible = true,
    QLBackgroundEffect effect = QLBackgroundEffect.darken,
    bool useSafeArea = false,
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<T>(
      QLSpatialConfig.fullscreenDialog(
        barrierDismissible: barrierDismissible,
        effect: effect,
        useSafeArea: useSafeArea,
      ),
      builder,
    );
  }

  Future<T?> showQLSheet<T>({
    bool dismissible = true,
    bool enableDrag = true,
    List<double> snapPoints = const [0.5, 1.0],
    QLBackgroundEffect effect = QLBackgroundEffect.zoomBack,
    BoxConstraints constraints = const BoxConstraints(maxWidth: 800, maxHeight: 720),
    QLSheetEdge edge = QLSheetEdge.bottom,
    Alignment? sheetAlignment,
    EdgeInsetsGeometry sheetPadding = EdgeInsets.zero,
    BorderRadius sheetBorderRadius = BorderRadius.zero,
    Clip clipBehavior = Clip.antiAlias,
    bool showDragHandle = true,
    double dragHandleWidth = 36.0,
    double dragHandleHeight = 4.0,
    double dragHandleOpacity = 0.35,
    double bgZoomDepth = 0.08,
    double bgBlurSigma = 0.0,
    Color barrierColor = const Color(0xFF000000),
    double barrierOpacity = 0.50,
    Color rootBgColor = const Color(0xFF000000),
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<T>(
      QLSpatialConfig.sheet(
        dismissible: dismissible,
        enableDrag: enableDrag,
        snapPoints: snapPoints,
        effect: effect,
        constraints: constraints,
        edge: edge,
        sheetAlignment: sheetAlignment,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetBorderRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        dragHandleWidth: dragHandleWidth,
        dragHandleHeight: dragHandleHeight,
        dragHandleOpacity: dragHandleOpacity,
        bgZoomDepth: bgZoomDepth,
        bgBlurSigma: bgBlurSigma,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
      ),
      builder,
    );
  }

  Future<T?> showQLDrawer<T>({
    bool dismissible = true,
    bool enableDrag = true,
    QLSheetEdge edge = QLSheetEdge.left,
    BoxConstraints constraints = const BoxConstraints(maxWidth: 420, maxHeight: 720),
    Alignment? sheetAlignment,
    EdgeInsetsGeometry sheetPadding = EdgeInsets.zero,
    BorderRadius sheetBorderRadius = BorderRadius.zero,
    Clip clipBehavior = Clip.antiAlias,
    bool showDragHandle = true,
    double bgZoomDepth = 0.06,
    Color barrierColor = const Color(0xFF000000),
    double barrierOpacity = 0.50,
    Color rootBgColor = const Color(0xFF000000),
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<T>(
      QLSpatialConfig.drawer(
        dismissible: dismissible,
        enableDrag: enableDrag,
        edge: edge,
        constraints: constraints,
        sheetAlignment: sheetAlignment,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetBorderRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        bgZoomDepth: bgZoomDepth,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
      ),
      builder,
    );
  }

  Future<void> showQLWindow({
    double initialX = 100.0,
    double initialY = 100.0,
    double initialWidth = 420.0,
    double initialHeight = 300.0,
    BoxConstraints constraints =
        const BoxConstraints(maxWidth: 800, maxHeight: 600),
    bool allowResize = true,
    QLResizeEdge resizeEdges = QLResizeEdge.bottomRight,
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<void>(
      QLSpatialConfig.window(
        initialX: initialX,
        initialY: initialY,
        initialWidth: initialWidth,
        initialHeight: initialHeight,
        constraints: constraints,
        allowResize: allowResize,
        resizeEdges: resizeEdges,
      ),
      builder,
    );
  }

  Future<void> showQLMenu({
    required GlobalKey anchorKey,
    int parentId = 0,
    bool isModal = false,
    BoxConstraints constraints =
        const BoxConstraints(maxWidth: 280, maxHeight: 400),
    bool matchAnchorWidth = false,
    required QLOverlayBuilder builder,
  }) async {
    final ctx = anchorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final pos = box.localToGlobal(Offset.zero);
    await mountOverlay<void>(
      QLSpatialConfig.menu(
        targetLeft: pos.dx,
        targetTop: pos.dy,
        targetRight: pos.dx + box.size.width,
        targetBottom: pos.dy + box.size.height,
        isModal: isModal,
        constraints: constraints,
        matchAnchorWidth: matchAnchorWidth,
      ),
      builder,
      parentId: parentId,
    );
  }

  Future<void> showQLNotify({
    Alignment position = Alignment.topCenter,
    Duration duration = const Duration(seconds: 4),
    BoxConstraints constraints = const BoxConstraints(maxWidth: 420),
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<void>(
      QLSpatialConfig.notification(
        position: position,
        duration: duration,
        constraints: constraints,
      ),
      builder,
    );
  }

  Future<void> showQLToast({
    Alignment position = Alignment.topCenter,
    Duration duration = const Duration(seconds: 3),
    BoxConstraints constraints = const BoxConstraints(maxWidth: 420),
    required QLOverlayBuilder builder,
  }) {
    return mountOverlay<void>(
      QLSpatialConfig.toast(
        position: position,
        duration: duration,
        constraints: constraints,
      ),
      builder,
    );
  }
}
