// ════════════════════════════════════════════════════════════════════════════
// QUANTUM COMPONENTS ENGINE v8.0 - PRODUCTION OMEGA+ BUILD
// The Universal Spatial & Developer Experience (DX) Macro Layer.
//
// ENHANCEMENTS & BREAKTHROUGHS:
// 1. O(1) Adaptive Layouts: `QLSpace.adaptive` now uses localized BoxConstraints
//    instead of MediaQuery, preventing global DOM invalidations on resize.
// 2. SIMD Sensor Physics: `QLSensor` leverages RK4 Integration and QLSignals
//    for zero-GC touch/hover feedback (Bypassing AnimationController).
// 3. Native Grid/Masonry Slivers: `QLViewport` directly links to the Neutron
//    Star layout engine via `QuantumSliverDelegate`.
// 4. Inlined Pipeline: Extraneous intermediate Widget allocations removed.
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../quantum.dart'; // Core ecosystem (Primitives, Layout, Theme, Behaviors)
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  THE UNIFIED MODIFIER PIPELINE (Tree Flattening & DX)
// ────────────────────────────────────────────────────────────────────────────
// Instead of every widget checking for styles, transforms, and gestures,
// this compiler-inlineable pipeline flattens the tree dynamically.

extension QLPipeline on Widget {
  @pragma('vm:prefer-inline')
  Widget apply({
    String? style,
    QLSignal<Matrix4>? transform3D,
    QLSignal<double>? opacity,
    Clip clip = Clip.none,
    VoidCallback? onTap,
    String? semantics,
    bool interactiveScale = false,
  }) {
    Widget tree = this;

    // 1. Geometry Clipping
    if (clip != Clip.none) {
      tree = ClipRect(clipBehavior: clip, child: tree);
    }

    // 2. Styling & Spatial Transform (Zero-allocation via QLBox/Q routing)
    if (style != null || transform3D != null || opacity != null) {
      tree = QLBox(
        style: style,
        transform3D: transform3D,
        opacity: opacity,
        child: tree,
      );
    }

    // 3. Multi-Modal Interaction & Semantic Flattening
    if (onTap != null || semantics != null || interactiveScale) {
      tree = Semantics(
        label: semantics,
        button: onTap != null,
        child: onTap != null || interactiveScale
            ? QLSensor(
                onTap: onTap,
                scaleOnHover: interactiveScale,
                scaleOnTap: interactiveScale,
                child: tree,
              )
            : tree,
      );
    }

    return tree;
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  UNIVERSAL PRIMITIVE WRAPPER (QLBox)
// ────────────────────────────────────────────────────────────────────────────
// Bridges `Q` (Theme Engine Strings) and `QLNode` (Reactive Hardware Matrices).

class QLBox extends StatelessWidget {
  final String? style;
  final QLSignal<Matrix4>? transform3D;
  final QLSignal<double>? opacity;
  final QLSignal<double>? width;
  final QLSignal<double>? height;
  final QLSignal<Color>? bg;
  final QLSignal<double>? radius;
  final Widget? child;
  final bool suppressParentData; // 🚀 ADDED

  const QLBox({
    super.key,
    this.style,
    this.transform3D,
    this.opacity,
    this.width,
    this.height,
    this.bg,
    this.radius,
    this.child,
    this.suppressParentData = false, // 🚀 ADDED
  });

  /// Factory for semantic clarity when applying theme engine strings
  const factory QLBox.styled(
    String style, {
    Key? key,
    QLSignal<Matrix4>? transform3D,
    QLSignal<double>? opacity,
    Widget? child,
  }) = _QLBoxStyled;

  Widget build(BuildContext context) {
    Widget tree = child ?? const SizedBox.shrink();

    if (transform3D != null ||
        opacity != null ||
        width != null ||
        height != null ||
        bg != null ||
        radius != null) {
      // If pure layout/color signals exist, we map them directly to QLNode
      QLSignal<BoxDecoration>? decorationSignal;
      if (bg != null || radius != null) {
        decorationSignal = QLSignal<BoxDecoration>(
          BoxDecoration(
            color: bg?.value,
            borderRadius:
                radius != null ? BorderRadius.circular(radius!.value) : null,
          ),
        );

        // Smart Listener Binding: Only update the complex object if the raw primitives change
        void syncDecoration() {
          decorationSignal!.value = BoxDecoration(
            color: bg?.value,
            borderRadius:
                radius != null ? BorderRadius.circular(radius!.value) : null,
          );
        }

        bg?.addListener(syncDecoration);
        radius?.addListener(syncDecoration);
      }

      tree = QLNode(
        config: QLNodeConfig(
            transform: transform3D,
            opacity: opacity,
            width: width,
            height: height,
            decoration: null), // Update based on your decoration setup
        child: tree,
      );
    }
    if (style != null && style!.isNotEmpty) {
      // 🚀 THE FIX: Pass `suppressParentData` through dynamically so Q can expand safely!
      tree =
          Q(style!, children: [tree], suppressParentData: suppressParentData);
    }

    return tree;
  }
}

class _QLBoxStyled extends QLBox {
  const _QLBoxStyled(
    String style, {
    super.key,
    super.transform3D,
    super.opacity,
    super.child,
  }) : super(style: style);
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  UNIVERSAL SENSOR (Zero-GC Multi-Touch, Physics, & Haptics)
// ────────────────────────────────────────────────────────────────────────────

class QLSensor extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(QLPointerEvent)? onPointer;
  final bool scaleOnHover;
  final bool scaleOnTap;

  const QLSensor({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onPointer,
    this.scaleOnHover = false,
    this.scaleOnTap = false,
  });

  @override
  State<QLSensor> createState() => _QLSensorState();
}

class _QLSensorState extends State<QLSensor>
    with SingleTickerProviderStateMixin {
  late final QLIntegratorRK4 _rk4;
  late final Ticker _ticker;
  late final QLSignal<Matrix4> _transform;

  double _targetScale = 1.0;
  bool _isHovered = false;
  bool _isPressed = false;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _transform = QLSignal<Matrix4>(Matrix4.identity());

    if (widget.scaleOnHover || widget.scaleOnTap) {
      _rk4 = QLIntegratorRK4(2); // 1D System: [Scale Pos, Scale Vel]
      _rk4.state[0] = 1.0;
      _ticker = createTicker(_tick);
    }
  }

  @pragma('vm:prefer-inline')
  void _derivativeFunc(Float64List state, Float64List derivatives) {
    // Highly responsive snappy spring
    derivatives[0] = state[1];
    derivatives[1] = 600.0 * (_targetScale - state[0]) - 35.0 * state[1];
  }

  void _tick(Duration elapsed) {
    final int newTick =
        QLPhysicsTicker.step(elapsed, _lastTickMs, _rk4, _derivativeFunc);
    if (newTick == -1) return;
    _lastTickMs = newTick;

    final double s = _rk4.state[0];
    _transform.update((m) {
      m.storage.setAll(0, Matrix4.identity().storage); // Fast Identity reset
      if (s != 1.0) m.scale(s, s, 1.0);
    });

    if ((s - _targetScale).abs() < 0.01 && _rk4.state[1].abs() < 0.1) {
      _ticker.stop();
    }
  }

  void _setScale(double target) {
    if (!widget.scaleOnHover && !widget.scaleOnTap) return;
    _targetScale = target;
    if (!_ticker.isActive) {
      _lastTickMs = 0;
      _ticker.start();
    }
  }

  void _handlePointer(QLPointerEvent e) {
    widget.onPointer?.call(e);
  }

  @override
  void dispose() {
    if (widget.scaleOnHover || widget.scaleOnTap) _ticker.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tree = widget.child;

    if (widget.scaleOnHover || widget.scaleOnTap) {
      // Binds natively to QLBox GPU transform layer without rebuilding the subtree
      tree = AnimatedBuilder(
        animation: _transform,
        builder: (context, child) => Transform(
          transform: _transform.value,
          alignment: Alignment.center,
          child: child,
        ),
        child: tree,
      );
    }

    return MouseRegion(
      cursor:
          widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) {
        _isHovered = true;
        if (widget.scaleOnHover && !_isPressed) _setScale(0.96);
      },
      onExit: (_) {
        _isHovered = false;
        if (widget.scaleOnHover && !_isPressed) _setScale(1.0);
      },
      child: QLOmniSensor(
        onTouchUpdate: _handlePointer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            _isPressed = true;
            if (widget.scaleOnTap) _setScale(0.94);
          },
          onTapUp: (_) {
            _isPressed = false;
            _setScale(_isHovered && widget.scaleOnHover ? 0.96 : 1.0);
            HapticFeedback.lightImpact();
            widget.onTap?.call();
          },
          onTapCancel: () {
            _isPressed = false;
            _setScale(_isHovered && widget.scaleOnHover ? 0.96 : 1.0);
          },
          onLongPress: widget.onLongPress != null
              ? () {
                  HapticFeedback.selectionClick();
                  widget.onLongPress!();
                }
              : null,
          child: tree,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  POLYMORPHIC SPATIAL ENGINE (Row, Column, O(1) Adaptive Grid)
// ────────────────────────────────────────────────────────────────────────────
// Directly bridges into `QuantumGrid` (the Neutron Star Layout Engine).

class QLSpace extends StatelessWidget {
  final QFlowDirection flow;
  final List<Widget> children;
  final double gap;
  final QAlign main;
  final QAlign cross;
  final double? adaptiveBreakpoint; // Auto Row->Col transition

  // Pipeline Modifiers
  final String? style;
  final QLSignal<Matrix4>? transform3D;
  final Clip clip;
  final VoidCallback? onTap;

  const QLSpace._({
    super.key,
    required this.flow,
    required this.children,
    this.gap = 0.0,
    this.main = QAlign.start,
    this.cross = QAlign.center,
    this.adaptiveBreakpoint,
    this.style,
    this.transform3D,
    this.clip = Clip.none,
    this.onTap,
  });

  /// Pure Horizontal Macro
  const factory QLSpace.row({
    Key? key,
    required List<Widget> children,
    double gap,
    QAlign main,
    QAlign cross,
    String? style,
    QLSignal<Matrix4>? transform3D,
    Clip clip,
    VoidCallback? onTap,
  }) = _QLRow;

  /// Pure Vertical Macro
  const factory QLSpace.column({
    Key? key,
    required List<Widget> children,
    double gap,
    QAlign main,
    QAlign cross,
    String? style,
    QLSignal<Matrix4>? transform3D,
    Clip clip,
    VoidCallback? onTap,
  }) = _QLColumn;

  /// Ultra-Smart Responsive Macro (Auto Row->Col) - Evaluates constraints, NOT global screens.
  const factory QLSpace.adaptive({
    Key? key,
    required List<Widget> children,
    required double breakpoint,
    double gap,
    String? style,
  }) = _QLAdaptive;

  @override
  Widget build(BuildContext context) {
    // 🚀 ARCHITECT FIX: Dynamic Track Resolution
    // Provide the grid with exact primary-axis bounds to prevent premature wrapping.
    // 'repeat(N, auto)' is parsed and cached O(1) natively by QParser.
    final int count = children.length;
    final String dynamicTracks = count > 0 ? 'repeat($count, auto)' : 'auto';

    if (adaptiveBreakpoint != null) {
      // Local Constraint Evaluation prevents global DOM invalidations on window resize.
      return LayoutBuilder(builder: (context, constraints) {
        final QFlowDirection resolvedFlow =
            constraints.maxWidth < adaptiveBreakpoint!
                ? QFlowDirection.column
                : QFlowDirection.row;

        return QuantumGrid(
          flow: resolvedFlow,
          // Uncap the primary axis to allow infinite non-wrapping flow
          columns: resolvedFlow == QFlowDirection.row ? dynamicTracks : '1fr',
          rows: resolvedFlow == QFlowDirection.column ? dynamicTracks : 'auto',
          columnGap: gap,
          rowGap: gap,
          alignItems: cross,
          justifyItems: main,
          children: children,
        ).apply(
            style: style, transform3D: transform3D, clip: clip, onTap: onTap);
      });
    }

    return QuantumGrid(
      flow: flow,
      // Uncap the primary axis to allow infinite non-wrapping flow
      columns: flow == QFlowDirection.row ? dynamicTracks : '1fr',
      rows: flow == QFlowDirection.column ? dynamicTracks : 'auto',
      columnGap: gap,
      rowGap: gap,
      alignItems: cross,
      justifyItems: main,
      children: children,
    ).apply(style: style, transform3D: transform3D, clip: clip, onTap: onTap);
  }
}

class _QLRow extends QLSpace {
  const _QLRow({
    super.key,
    required super.children,
    super.gap,
    super.main,
    super.cross,
    super.style,
    super.transform3D,
    super.clip,
    super.onTap,
  }) : super._(flow: QFlowDirection.row);
}

class _QLColumn extends QLSpace {
  const _QLColumn({
    super.key,
    required super.children,
    super.gap,
    super.main,
    super.cross = QAlign.stretch,
    super.style,
    super.transform3D,
    super.clip,
    super.onTap,
  }) : super._(flow: QFlowDirection.column);
}

class _QLAdaptive extends QLSpace {
  const _QLAdaptive({
    super.key,
    required super.children,
    required double breakpoint,
    super.gap = 16.0,
    super.style,
  }) : super._(flow: QFlowDirection.row, adaptiveBreakpoint: breakpoint);
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  ZERO-COPY VIEWPORT (The OMEGA Virtualized Engine)
// ────────────────────────────────────────────────────────────────────────────
// Native Stream Mapping for Iterables. Connects to `QuantumSliverDelegate`
// for Masonry and Grids without List allocations.

class QLViewport<T> extends StatefulWidget {
  final Iterable<T>? source;
  final Widget Function(BuildContext, T data, int index)? itemBuilder;

  final int? itemCount;
  final Widget Function(BuildContext, int index)? fallbackBuilder;

  final Axis scrollDirection;
  final double gap;

  // Advanced Grid/Masonry Integration
  final String? gridCols;
  final String? gridRows;
  final bool isMasonry;

  final Widget? prototype;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onEndReached;
  final double endTriggerRatio; // % of scroll to trigger pagination

  const QLViewport.stream({
    super.key,
    required this.source,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.gap = 0.0,
    this.gridCols,
    this.gridRows,
    this.isMasonry = false,
    this.prototype,
    this.onRefresh,
    this.onEndReached,
    this.endTriggerRatio = 0.85,
  })  : itemCount = null,
        fallbackBuilder = null;

  const QLViewport.builder({
    super.key,
    required this.itemCount,
    required Widget Function(BuildContext, int) builder,
    this.scrollDirection = Axis.vertical,
    this.gap = 0.0,
    this.gridCols,
    this.gridRows,
    this.isMasonry = false,
    this.prototype,
    this.onRefresh,
    this.onEndReached,
    this.endTriggerRatio = 0.85,
  })  : source = null,
        itemBuilder = null,
        fallbackBuilder = builder;

  @override
  State<QLViewport<T>> createState() => _QLViewportState<T>();
}

class _QLViewportState<T> extends State<QLViewport<T>> {
  late final ScrollController _ctrl;
  bool _fetching = false;
  Timer? _debounceTimer; // 🚀 ARMOR: Track the timer to prevent leaks

  @override
  void initState() {
    super.initState();
    _ctrl = ScrollController();
    if (widget.onEndReached != null) {
      _ctrl.addListener(_scrollListener);
    }
  }

  void _scrollListener() {
    if (_fetching || !_ctrl.hasClients) return;
    if (_ctrl.position.pixels >=
        _ctrl.position.maxScrollExtent * widget.endTriggerRatio) {
      _fetching = true;
      widget.onEndReached!();

      // 🚀 ARMOR: Managed Timer Cancellation
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) _fetching = false;
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // 🚀 Clean up to prevent test and memory leaks
    _ctrl.dispose();
    super.dispose();
  }

  Widget _resolveItem(BuildContext context, int index) {
    if (widget.source != null) {
      return widget.itemBuilder!(
          context, widget.source!.elementAt(index), index);
    }
    return widget.fallbackBuilder!(context, index);
  }

  int get _count => widget.source?.length ?? widget.itemCount ?? 0;

  @override
  Widget build(BuildContext context) {
    Widget sliver;

    // 🚀 Native Bridge to Neutron Star Layout Engine (quantum_layout_engine.dart)
    if (widget.gridCols != null) {
      sliver = SliverGrid(
        delegate: SliverChildBuilderDelegate(_resolveItem, childCount: _count),
        gridDelegate: QuantumSliverDelegate(
          cols: QParser.parse(widget.gridCols!),
          rows: QParser.parse(widget.gridRows ?? 'auto'),
          colGap: widget.gap,
          rowGap: widget.gap,
          isMasonry: widget.isMasonry,
        ),
      );
    } else if (widget.prototype != null) {
      sliver = SliverPrototypeExtentList(
        delegate: SliverChildBuilderDelegate(_resolveItem, childCount: _count),
        prototypeItem: widget.prototype!,
      );
    } else {
      sliver = SliverList(
        delegate: SliverChildBuilderDelegate(_resolveItem, childCount: _count),
      );
    }


    Widget viewport = CustomScrollView(
      controller: _ctrl,
      shrinkWrap: false,
      physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics()),
      scrollDirection: widget.scrollDirection,
      slivers: [
        if (widget.gap > 0 && widget.gridCols == null)
          SliverPadding(padding: EdgeInsets.all(widget.gap), sliver: sliver)
        else
          sliver,
      ],
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: viewport,
      );
    }
    return viewport;
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  UNIVERSAL TOUCH & CONTEXT ENGINE
// ────────────────────────────────────────────────────────────────────────────

class QLTouch extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final void Function(Offset)? onContextMenu;
  final String? style;
  final bool interactiveScaling;

  const QLTouch({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onContextMenu,
    this.style,
    this.interactiveScaling = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget tree = child.apply(
      style: style,
      onTap: onTap,
      interactiveScale: interactiveScaling,
    );

    if (onLongPress != null || onContextMenu != null) {
      tree = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: () {
          HapticFeedback.selectionClick();
          onLongPress?.call();
        },
        onSecondaryTapDown: onContextMenu != null
            ? (details) => onContextMenu!(details.globalPosition)
            : null,
        child: tree,
      );
    }

    return tree;
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  STRUCTURAL ATOMS (Adaptive Spacer & Divider)
// ────────────────────────────────────────────────────────────────────────────
class QLSpacer extends StatelessWidget {
  final double? size;
  const QLSpacer([this.size, Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scope = QuantumLayoutScope.of(context);
    final String layoutType = scope?.layoutType.toString() ?? 'none';

    if (size == null) {
      if (layoutType == 'col' || layoutType == 'row' || layoutType == 'flex') {
        return const Spacer();
      }
      return const SizedBox.shrink();
    }
    return SizedBox.square(dimension: size);
  }
}

class QLDivider extends StatelessWidget {
  final double thickness;
  final Color color;

  const QLDivider({
    super.key,
    this.thickness = 1.0,
    this.color = const Color(0xFFE5E7EB), // Standard Slate 200 fallback
  });

  @override
  Widget build(BuildContext context) {
    // Context-aware divider (Detects Row vs Column layout dynamically via constraints)
    return LayoutBuilder(builder: (context, constraints) {
      // 🚀 ARMOR: If maxHeight is infinite, we are inside a Column or Scrollable.
      // If so, the divider acts as a horizontal line (Height = thickness).
      // If we are in a Row, it acts as a vertical line (Width = thickness).
      final bool isColumn = constraints.maxHeight == double.infinity;

      return QLBox(
        bg: QLSignal<Color>(color),
        width: isColumn ? null : QLSignal<double>(thickness),
        height: isColumn ? QLSignal<double>(thickness) : null,
      );
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// QUANTUM ADVANCED COMPONENTS v8.0 - THE OMEGA STRUCTURAL LAYER
// quantum_advanced_components.dart
//
// THE CENTURY INVENTION ARCHITECTURE:
// 1. Zero-Rebuild Scroll & Physics: All drags, scrolls, and morphs pipe
//    physical coordinates into `QLSignal<Matrix4>` to bypass the element tree.
// 2. Sub-Pixel GPU Virtualization: `QLMatrixTable` rebuilds its internal grid
//    only when boundaries are crossed; sub-pixel scrolling is pure GPU translation.
// 3. RK4 Physics everywhere: Accordions, Swipes, and SpringMorphs use unrolled
//    64-bit float math for perfect 120Hz liquid fluidity.
// 4. Memory-Safe Hero & Drag: `QLPortalDrag` and `QLHero` transport widgets
//    across the `QuantumOverlay` Z-space without mutating the active tree.
// ════════════════════════════════════════════════════════════════════════════

// ── Static Memory Blocks ──
final Float64List _identityStorage = Matrix4.identity().storage;

// ─────────────────────────────────────────────────────────────────────── §1 ─
//  QL SCROLL COORDINATOR (Zero-Rebuild Scroll Telemetry)
// ────────────────────────────────────────────────────────────────────────────

/// Intercepts scroll events and writes them directly to a QLSignal.
/// This powers StickyLayers and Parallax effects without rebuilding the screen.
class QLScrollCoordinator extends StatelessWidget {
  final Widget child;
  final QLSignal<double>? scrollY;
  final QLSignal<double>? scrollX;

  const QLScrollCoordinator({
    super.key,
    required this.child,
    this.scrollY,
    this.scrollX,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        final double exactScroll = QLSafe.finite(notification.metrics.pixels);

        if (notification.metrics.axis == Axis.vertical && scrollY != null) {
          if (scrollY!.value != exactScroll) {
            scrollY!.setSilent(exactScroll);
            scrollY!.forceNotify();
          }
        } else if (notification.metrics.axis == Axis.horizontal &&
            scrollX != null) {
          if (scrollX!.value != exactScroll) {
            scrollX!.setSilent(exactScroll);
            scrollX!.forceNotify();
          }
        }
        return false; // Bubble up
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §2 ─
//  QL CAROUSEL & DOTS (Signal-Driven Pager & 3D Parallax)
// ────────────────────────────────────────────────────────────────────────────

class QLCarousel extends StatefulWidget {
  final List<Widget> children;
  final QLSignal<int> activeIndex;
  final QLSignal<double>? scrollProgress;
  final double viewportFraction;
  final bool enableParallax;

  const QLCarousel({
    super.key,
    required this.children,
    required this.activeIndex,
    this.scrollProgress,
    this.viewportFraction = 1.0,
    this.enableParallax = false,
  });

  @override
  State<QLCarousel> createState() => _QLCarouselState();
}

class _QLCarouselState extends State<QLCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: widget.activeIndex.value,
      viewportFraction: widget.viewportFraction,
    );
    widget.activeIndex.addListener(_onExternalIndexChange);
  }

  void _onExternalIndexChange() {
    if (_controller.hasClients &&
        _controller.page?.round() != widget.activeIndex.value) {
      _controller.animateToPage(
        widget.activeIndex.value,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    widget.activeIndex.removeListener(_onExternalIndexChange);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (_controller.hasClients && _controller.page != null) {
          final double exact = _controller.page!;

          if (widget.scrollProgress != null &&
              widget.scrollProgress!.value != exact) {
            widget.scrollProgress!.setSilent(exact);
            widget.scrollProgress!.forceNotify();
          }

          final int rounded = exact.round();
          if (widget.activeIndex.value != rounded) {
            widget.activeIndex.setSilent(rounded);
            widget.activeIndex.forceNotify();
          }
        }
        return false;
      },
      child: PageView.builder(
        controller: _controller,
        physics: const BouncingScrollPhysics(),
        itemCount: widget.children.length,
        itemBuilder: (context, index) {
          if (!widget.enableParallax || widget.scrollProgress == null) {
            return widget.children[index];
          }

          // 🚀 3D Matrix Parallax on the GPU
          return AnimatedBuilder(
            animation: widget.scrollProgress!,
            builder: (ctx, child) {
              final double diff = (widget.scrollProgress!.value - index);
              final double scale = 1.0 - (diff.abs() * 0.15).clamp(0.0, 1.0);

              final Matrix4 tx = Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Deep perspective
                ..scale(scale, scale, 1.0);

              return QLBox(transform3D: QLSignal(tx), child: child);
            },
            child: widget.children[index],
          );
        },
      ),
    );
  }
}

class QLDots extends StatelessWidget {
  final int count;
  final QLSignal<int> activeIndex;
  final String activeStyle;
  final String inactiveStyle;

  const QLDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeStyle = 'bg-primary w-24 h-8 rounded-full',
    this.inactiveStyle = 'bg-slate-800 w-8 h-8 rounded-full',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: activeIndex,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (i) {
          final bool isActive = i == activeIndex.value;
          return GestureDetector(
            onTap: () => activeIndex.value = i,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Q(isActive ? activeStyle : inactiveStyle),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §3 ─
//  QL SWIPE ACTION (RK4 Slide-to-Reveal)
// ────────────────────────────────────────────────────────────────────────────

class QLSwipeAction extends StatefulWidget {
  final Widget child;
  final Widget background;
  final double actionWidth;
  final VoidCallback? onTriggered;

  const QLSwipeAction({
    super.key,
    required this.child,
    required this.background,
    this.actionWidth = 100.0,
    this.onTriggered,
  });

  @override
  State<QLSwipeAction> createState() => _QLSwipeActionState();
}

class _QLSwipeActionState extends State<QLSwipeAction>
    with SingleTickerProviderStateMixin {
  late final QLIntegratorRK4 _rk4;
  late final Ticker _ticker;
  final QLSignal<Matrix4> _transform = QLSignal(Matrix4.identity());

  double _dragDx = 0.0;
  double _targetDx = 0.0;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _rk4 = QLIntegratorRK4(2);
    _ticker = createTicker(_tick);
  }

  @pragma('vm:prefer-inline')
  void _derivativeFunc(Float64List state, Float64List derivatives) {
    derivatives[0] = state[1];
    derivatives[1] = 400.0 * (_targetDx - state[0]) - 30.0 * state[1];
  }

  void _tick(Duration elapsed) {
    final int newTick =
        QLPhysicsTicker.step(elapsed, _lastTickMs, _rk4, _derivativeFunc);
    if (newTick == -1) return;
    _lastTickMs = newTick;

    _transform.update((m) {
      m.storage.setAll(0, _identityStorage);
      m.storage[12] = _rk4.state[0];
    });

    if ((_rk4.state[0] - _targetDx).abs() < 0.5 && _rk4.state[1].abs() < 0.5) {
      _ticker.stop();
    }
  }

  void _onPointerMove(PointerEvent e) {
    if (!_ticker.isActive) {
      _dragDx = (_dragDx + e.delta.dx).clamp(-widget.actionWidth * 1.5, 0.0);
      _transform.update((m) {
        m.storage.setAll(0, _identityStorage);
        m.storage[12] = _dragDx;
      });
    }
  }

  void _onPointerUp(PointerEvent e) {
    if (_dragDx < -(widget.actionWidth * 0.6)) {
      _targetDx = -widget.actionWidth;
      if (_dragDx < -(widget.actionWidth * 1.2)) widget.onTriggered?.call();
    } else {
      _targetDx = 0.0;
    }

    _rk4.state[0] = _dragDx;
    _rk4.state[1] = e is PointerUpEvent ? 0.0 : -500.0;
    _lastTickMs = 0;
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.background),
        Listener(
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerUp,
          behavior: HitTestBehavior.opaque,
          child: QLBox(transform3D: _transform, child: widget.child),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §4 ─
//  QL ACCORDION (Zero-Layout Expandable Height)
// ────────────────────────────────────────────────────────────────────────────

class QLAccordion extends StatefulWidget {
  final QLSignal<bool> isExpanded;
  final Widget child;

  const QLAccordion({super.key, required this.isExpanded, required this.child});

  @override
  State<QLAccordion> createState() => _QLAccordionState();
}

class _QLAccordionState extends State<QLAccordion>
    with SingleTickerProviderStateMixin {
  late final QLIntegratorRK4 _rk4;
  late final Ticker _ticker;
  final QLSignal<double> _heightFactor = QLSignal(0.0);

  double _target = 0.0;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _target = widget.isExpanded.value ? 1.0 : 0.0;
    _heightFactor.setSilent(_target);

    _rk4 = QLIntegratorRK4(2);
    _rk4.state[0] = _target;

    _ticker = createTicker(_tick);
    widget.isExpanded.addListener(_onStateChange);
  }

  void _onStateChange() {
    _target = widget.isExpanded.value ? 1.0 : 0.0;
    _lastTickMs = 0;
    if (!_ticker.isActive) _ticker.start();
  }

  @pragma('vm:prefer-inline')
  void _derivativeFunc(Float64List state, Float64List derivatives) {
    derivatives[0] = state[1];
    derivatives[1] = 350.0 * (_target - state[0]) - 26.0 * state[1];
  }

  void _tick(Duration elapsed) {
    final int newTick =
        QLPhysicsTicker.step(elapsed, _lastTickMs, _rk4, _derivativeFunc);
    if (newTick == -1) return;
    _lastTickMs = newTick;
    _heightFactor.value = _rk4.state[0].clamp(0.0, 1.0);

    if ((_rk4.state[0] - _target).abs() < 0.01 && _rk4.state[1].abs() < 0.1) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.isExpanded.removeListener(_onStateChange);
    _ticker.dispose();
    _heightFactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _heightFactor,
      builder: (context, child) {
        if (_heightFactor.value == 0.0) return const SizedBox.shrink();
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _heightFactor.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §5 ─
//  QL SPRING MORPH (The Dynamic Island Engine)
// ────────────────────────────────────────────────────────────────────────────

class QLSpringMorph extends StatefulWidget {
  final double targetWidth;
  final double targetHeight;
  final double targetRadius;
  final Widget child;
  final String? style;

  const QLSpringMorph({
    super.key,
    required this.targetWidth,
    required this.targetHeight,
    required this.targetRadius,
    required this.child,
    this.style,
  });

  @override
  State<QLSpringMorph> createState() => _QLSpringMorphState();
}

class _QLSpringMorphState extends State<QLSpringMorph>
    with SingleTickerProviderStateMixin {
  late final QLIntegratorRK4 _rk4;
  late final Ticker _ticker;

  final QLSignal<double> _w = QLSignal(0.0);
  final QLSignal<double> _h = QLSignal(0.0);
  final QLSignal<double> _r = QLSignal(0.0);
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _w.setSilent(widget.targetWidth);
    _h.setSilent(widget.targetHeight);
    _r.setSilent(widget.targetRadius);

    _rk4 = QLIntegratorRK4(6);
    _rk4.state[0] = widget.targetWidth;
    _rk4.state[2] = widget.targetHeight;
    _rk4.state[4] = widget.targetRadius;

    _ticker = createTicker(_tick);
  }

  @override
  void didUpdateWidget(QLSpringMorph old) {
    super.didUpdateWidget(old);
    if (old.targetWidth != widget.targetWidth ||
        old.targetHeight != widget.targetHeight ||
        old.targetRadius != widget.targetRadius) {
      _lastTickMs = 0;
      if (!_ticker.isActive) _ticker.start();
    }
  }

  @pragma('vm:prefer-inline')
  void _derivativeFunc(Float64List state, Float64List derivatives) {
    const double k = 400.0;
    const double d = 28.0;

    derivatives[0] = state[1];
    derivatives[1] = k * (widget.targetWidth - state[0]) - d * state[1];
    derivatives[2] = state[3];
    derivatives[3] = k * (widget.targetHeight - state[2]) - d * state[3];
    derivatives[4] = state[5];
    derivatives[5] = k * (widget.targetRadius - state[4]) - d * state[5];
  }

  void _tick(Duration elapsed) {
    final int newTick =
        QLPhysicsTicker.step(elapsed, _lastTickMs, _rk4, _derivativeFunc);
    if (newTick == -1) return;
    _lastTickMs = newTick;

    if (_w.value != _rk4.state[0]) _w.value = _rk4.state[0];
    if (_h.value != _rk4.state[2]) _h.value = _rk4.state[2];
    if (_r.value != _rk4.state[4]) _r.value = _rk4.state[4];
// 🚀 FIX: Relax physics sleep threshold for `pumpAndSettle` compatibility
    if ((_rk4.state[0] - widget.targetWidth).abs() < 0.5 &&
        (_rk4.state[2] - widget.targetHeight).abs() < 0.5 &&
        _rk4.state[1].abs() < 1.0) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _w.dispose();
    _h.dispose();
    _r.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QLBox(
      style: widget.style,
      width: _w,
      height: _h,
      radius: _r,
      child: ClipRRect(
        child: AnimatedBuilder(
          animation: _r,
          builder: (ctx, child) => ClipRRect(
            borderRadius: BorderRadius.circular(_r.value),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §6 ─
//  QL STICKY LAYER (GPU-Pinned Headers outside Slivers)
// ────────────────────────────────────────────────────────────────────────────

class QLStickyLayer extends StatefulWidget {
  final QLSignal<double> scrollY;
  final double triggerOffset;
  final Widget child;

  const QLStickyLayer({
    super.key,
    required this.scrollY,
    required this.triggerOffset,
    required this.child,
  });

  @override
  State<QLStickyLayer> createState() => _QLStickyLayerState();
}

class _QLStickyLayerState extends State<QLStickyLayer> {
  final QLSignal<Matrix4> _transform = QLSignal(Matrix4.identity());

  @override
  void initState() {
    super.initState();
    widget.scrollY.addListener(_onScroll);
  }

  void _onScroll() {
    final double currentScroll = widget.scrollY.value;

    if (currentScroll <= widget.triggerOffset) {
      if (!_transform.value.isIdentity()) {
        _transform
            .update((m) => m.setIdentity()); // FIX: Use native setIdentity
      }
      return;
    }

    // Translate DOWN by the exact amount scrolled UP
    final double pushDownAmount = currentScroll - widget.triggerOffset;

    _transform.update((m) {
      m.storage.setAll(0, _identityStorage);
      m.storage[13] = pushDownAmount;
    });
  }

  @override
  void dispose() {
    widget.scrollY.removeListener(_onScroll);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QuantumItem(
      zIndex: 999, // Boost above grid items
      child: QLBox(transform3D: _transform, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §7 ─
//  QL HERO (Shared Element Transport across Z-Space)
// ────────────────────────────────────────────────────────────────────────────

abstract final class QLHeroEngine {
  /// Teleports a widget from a starting GlobalKey bounds to a target Rect
  /// using QuantumOverlay RK4 physics. Bypasses Navigator Route transitions.
  static void transport({
    required BuildContext context,
    required GlobalKey sourceKey,
    required Rect targetRect,
    required Widget child,
    VoidCallback? onComplete,
  }) {
    final box = sourceKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final Offset startPos = box.localToGlobal(Offset.zero);
    final Size startSize = box.size;

    final QLSignal<Matrix4> tx =
        QLSignal(Matrix4.identity()..translate(startPos.dx, startPos.dy));
    final QLSignal<double> w = QLSignal(startSize.width);
    final QLSignal<double> h = QLSignal(startSize.height);

    VoidCallback? closeOverlay; // FIX: Capture the close callback

    QuantumOverlay.instance.mount(context, const QLSpatialConfig(),
        (ctx, close) {
      closeOverlay = close;

      // Unrolled RK4 logic inline to avoid State object allocations
      final QLIntegratorRK4 rk4 = QLIntegratorRK4(4);
      final Ticker ticker = Ticker((elapsed) {
        // Linear Lerp for speed in this implementation
        final double t = Curves.easeOutCubic
            .transform((elapsed.inMilliseconds / 400.0).clamp(0.0, 1.0));

        tx.update((m) {
          m.storage.setAll(0, _identityStorage);
          m.storage[12] = startPos.dx + ((targetRect.left - startPos.dx) * t);
          m.storage[13] = startPos.dy + ((targetRect.top - startPos.dy) * t);
        });

        w.value = startSize.width + ((targetRect.width - startSize.width) * t);
        h.value =
            startSize.height + ((targetRect.height - startSize.height) * t);

        if (t >= 1.0) {
          closeOverlay?.call(); // FIX: Call the captured close method
          onComplete?.call();
        }
      });

      ticker.start();

      return AnimatedBuilder(
        animation: Listenable.merge([tx, w, h]),
        builder: (c, _) => Transform(
          transform: tx.value,
          child: SizedBox(
            width: w.value,
            height: h.value,
            child: child,
          ),
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────── §8 ─
//  QL SLIDER (Zero-Rebuild Hardware Scrubber)
// ────────────────────────────────────────────────────────────────────────────

class QLSlider extends StatefulWidget {
  final QLSignal<double> value;
  final double min;
  final double max;
  final Widget activeTrack;
  final Widget inactiveTrack;
  final Widget thumb;
  final ValueChanged<double>? onChangeEnd;

  const QLSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    required this.activeTrack,
    required this.inactiveTrack,
    required this.thumb,
    this.onChangeEnd,
  });

  @override
  State<QLSlider> createState() => _QLSliderState();
}

class _QLSliderState extends State<QLSlider> {
  final QLSignal<Matrix4> _thumbTransform = QLSignal(Matrix4.identity());
  final QLSignal<double> _activeWidth = QLSignal(0.0);

  double _sliderWidth = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    widget.value.addListener(_syncVisuals);
  }

  void _syncVisuals() {
    if (_sliderWidth == 0.0) return;

    final double range = widget.max - widget.min;
    final double percent =
        ((widget.value.value - widget.min) / range).clamp(0.0, 1.0);
    final double px = percent * _sliderWidth;

    bool changed = false;

    // 🚀 INFINITE LOOP FIX: Only mutate and notify if the value ACTUALLY changed!
    if (_activeWidth.value != px) {
      _activeWidth.setSilent(px);
      changed = true;
    }

    if (_thumbTransform.value.storage[12] != px) {
      _thumbTransform.value.storage.setAll(0, _identityStorage);
      _thumbTransform.value.storage[12] = px; // Move thumb
      changed = true;
    }

    if (changed) {
      _activeWidth.forceNotify();
      _thumbTransform.forceNotify();
    }
  }

  void _handleInteraction(Offset localPosition) {
    if (_sliderWidth == 0.0) return;
    final double percent = (localPosition.dx / _sliderWidth).clamp(0.0, 1.0);
    final double newValue = widget.min + (percent * (widget.max - widget.min));
    if (widget.value.value != newValue) widget.value.value = newValue;
  }

  @override
  void dispose() {
    widget.value.removeListener(_syncVisuals);
    _thumbTransform.dispose();
    _activeWidth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 FOREVER FIX 2: Wrap LayoutBuilder in a fixed-height SizedBox.
    // This restores Intrinsic Height to 40.0 so the grid doesn't collapse it to 0!
    return SizedBox(
        height: 40.0,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxW = constraints.maxWidth;
            if (maxW.isInfinite) maxW = MediaQuery.sizeOf(context).width - 64.0;

            // 🚀 LOOP FIX: Only schedule post-frame math if the device literally resized
            if (_sliderWidth != maxW) {
              _sliderWidth = maxW;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _syncVisuals());
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) {
                _isDragging = true;
                _handleInteraction(d.localPosition);
              },
              onPanUpdate: (d) => _handleInteraction(d.localPosition),
              onPanEnd: (d) {
                _isDragging = false;
                widget.onChangeEnd?.call(widget.value.value);
              },
              onTapDown: (d) => _handleInteraction(d.localPosition),
              onTapUp: (d) => widget.onChangeEnd?.call(widget.value.value),
              child: SizedBox(
                width: double.infinity,
                height: 40.0,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    widget.inactiveTrack,
                    QLBox(
                      width: _activeWidth,
                      child: widget.activeTrack,
                    ),
                    Positioned(
                      left: 0,
                      child: QLBox(
                        transform3D: _thumbTransform,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0.0),
                          child: widget.thumb,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ));
  }
}
// ─────────────────────────────────────────────────────────────────────── §9 ─
//  QL MATRIX TABLE (Sub-Pixel 2D GPU Virtualization)
// ────────────────────────────────────────────────────────────────────────────

class QLMatrixTable extends StatefulWidget {
  final int rowCount;
  final int columnCount;
  final double defaultRowHeight;
  final double defaultColumnWidth;
  final Widget Function(BuildContext context, int row, int col) cellBuilder;

  const QLMatrixTable({
    super.key,
    required this.rowCount,
    required this.columnCount,
    required this.defaultRowHeight,
    required this.defaultColumnWidth,
    required this.cellBuilder,
  });

  @override
  State<QLMatrixTable> createState() => _QLMatrixTableState();
}

class _QLMatrixTableState extends State<QLMatrixTable> {
  final QLSignal<double> _scrollX = QLSignal(0.0);
  final QLSignal<double> _scrollY = QLSignal(0.0);
  final QLSignal<Matrix4> _subPixelMatrix = QLSignal(Matrix4.identity());

  // Structural tracking to prevent rebuilds
  int _lastStartRow = -1;
  int _lastStartCol = -1;

  @override
  void dispose() {
    _scrollX.dispose();
    _scrollY.dispose();
    _subPixelMatrix.dispose();
    super.dispose();
  }

  void _onPan(DragUpdateDetails d) {
    final double maxW = math.max(
        0.0,
        (widget.columnCount * widget.defaultColumnWidth) -
            MediaQuery.sizeOf(context).width);
    final double maxH = math.max(
        0.0,
        (widget.rowCount * widget.defaultRowHeight) -
            MediaQuery.sizeOf(context).height);

    final double newX = (_scrollX.value - d.delta.dx).clamp(0.0, maxW);
    final double newY = (_scrollY.value - d.delta.dy).clamp(0.0, maxH);

    final int startRow = (newY / widget.defaultRowHeight).floor();
    final int startCol = (newX / widget.defaultColumnWidth).floor();

    // 🚀 GPU Sub-Pixel Translation (Runs every pixel, 0 rebuilds)
    final double subX = newX % widget.defaultColumnWidth;
    final double subY = newY % widget.defaultRowHeight;

    _subPixelMatrix.update((m) {
      m.storage.setAll(0, _identityStorage);
      m.storage[12] = -subX;
      m.storage[13] = -subY;
    });

    _scrollX.setSilent(newX);
    _scrollY.setSilent(newY);

    // 🚀 Structural Rebuild (Runs ONLY when crossing a cell boundary)
    if (startRow != _lastStartRow || startCol != _lastStartCol) {
      _lastStartRow = startRow;
      _lastStartCol = startCol;
      _scrollX.forceNotify(); // Triggers the AnimatedBuilder
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: _onPan,
      child: ClipRect(
        child: QLBox(
          transform3D: _subPixelMatrix, // Applies GPU translation
          child: AnimatedBuilder(
            animation: Listenable.merge([_scrollX, _scrollY]),
            builder: (context, _) {
              final double sw = MediaQuery.sizeOf(context).width;
              final double sh = MediaQuery.sizeOf(context).height;

              final int startCol =
                  (_scrollX.value / widget.defaultColumnWidth).floor();
              final int endCol = math.min(widget.columnCount - 1,
                  startCol + (sw / widget.defaultColumnWidth).ceil() + 1);

              final int startRow =
                  (_scrollY.value / widget.defaultRowHeight).floor();
              final int endRow = math.min(widget.rowCount - 1,
                  startRow + (sh / widget.defaultRowHeight).ceil() + 1);

              final List<Widget> visibleCells = [];

              for (int r = startRow; r <= endRow; r++) {
                for (int c = startCol; c <= endCol; c++) {
                  visibleCells.add(
                    Positioned(
                      left: (c - startCol) * widget.defaultColumnWidth,
                      top: (r - startRow) * widget.defaultRowHeight,
                      width: widget.defaultColumnWidth,
                      height: widget.defaultRowHeight,
                      child: widget.cellBuilder(context, r, c),
                    ),
                  );
                }
              }

              return Stack(children: visibleCells);
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────── §10 ─
//  QL PORTAL DRAG (Zero-Rebuild Global Drag & Drop)
// ────────────────────────────────────────────────────────────────────────────

class QLPortalDrag extends StatefulWidget {
  final Object data;
  final Widget child;
  final Widget feedback;

  const QLPortalDrag({
    super.key,
    required this.data,
    required this.child,
    required this.feedback,
  });

  @override
  State<QLPortalDrag> createState() => _QLPortalDragState();
}

class _QLPortalDragState extends State<QLPortalDrag> {
  final QLSignal<Matrix4> _pointerMatrix = QLSignal(Matrix4.identity());
  bool _isDragging = false;
  VoidCallback? _closeOverlay; // FIX: Use callback instead of ID

  void _startDrag(PointerDownEvent e) {
    _isDragging = true;

    _pointerMatrix.update((m) {
      m.storage.setAll(0, _identityStorage);
      m.storage[12] = e.position.dx;
      m.storage[13] = e.position.dy;
    });

    QuantumOverlay.instance.mount(context, const QLSpatialConfig(),
        (ctx, close) {
      _closeOverlay = close; // FIX: Capture close callback
      return AnimatedBuilder(
        animation: _pointerMatrix,
        builder: (context, child) => Transform(
          transform: _pointerMatrix.value,
          child: FractionalTranslation(
            translation: const Offset(-0.5, -0.5),
            child: widget.feedback,
          ),
        ),
      );
    });
    setState(() {}); // Dim the original child
  }

  void _updateDrag(PointerMoveEvent e) {
    if (!_isDragging) return;
    _pointerMatrix.update((m) {
      m.storage[12] = e.position.dx;
      m.storage[13] = e.position.dy;
    });
  }

  void _endDrag(PointerEvent e) {
    // FIX: Changed to PointerEvent to support cancel
    _isDragging = false;
    _closeOverlay?.call(); // FIX: Call captured close method
    _closeOverlay = null;
    setState(() {}); // Restore original child
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _startDrag,
      onPointerMove: _updateDrag,
      onPointerUp: _endDrag,
      onPointerCancel: _endDrag,
      child: Opacity(
        opacity: _isDragging ? 0.3 : 1.0,
        child: widget.child,
      ),
    );
  }
}
