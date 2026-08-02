/*
 * ============================================================================
 * File: portal_core.dart
 * 
 * Description:
 * Manages floating, modal, and detached surfaces within the Quantum Omni Registry. 
 * A pattern-aware router for dialogs, sheets, drawers, popovers, and persistent 
 * panels with declarative spatial configurations.
 * 
 * Key Components:
 * - _buildPortal: Resolves and routes overlay types to proper QLSpatialConfigs.
 * - _QLInlineSurfaceHost: Hosts expandable inline surfaces or persistent panels.
 * - _QLTriggerBindPortal: Binds overlay behavior to underlying store signals.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart.
 * 
 * Notes:
 * Intercepts routing patterns to map them into the Q Overlay/Spatial layer natively.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// Pattern-aware portal router: dialogs, sheets, drawers, menus, anchored
// surfaces, persistent panels, and inline expandable surfaces.

Widget _buildPortal(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'dialog');

  QLBackgroundEffect parseEffect(String effect) {
    switch (effect) {
      case 'blur':
        return QLBackgroundEffect.blur;
      case 'zoomBack':
        return QLBackgroundEffect.zoomBack;
      case 'darken':
        return QLBackgroundEffect.darken;
      default:
        return QLBackgroundEffect.none;
    }
  }

  QLSurfacePattern parseSurfacePattern(String value) {
    switch (value) {
      case 'modal':
      case 'alert':
      case 'confirm':
      case 'form_modal':
        return QLSurfacePattern.modal;
      case 'nonModal':
      case 'non_modal':
      case 'inspector':
      case 'utility_panel':
        return QLSurfacePattern.nonModal;
      case 'centered':
      case 'centered_overlay':
      case 'dialog':
      case 'popup_modal':
      case 'lightbox':
        return QLSurfacePattern.centered;
      case 'edge_attached':
      case 'docked':
      case 'side_sheet':
      case 'left_panel':
      case 'right_panel':
      case 'drawer':
        return QLSurfacePattern.edgeDocked;
      case 'bottom_attached':
      case 'bottom_sheet':
      case 'action_sheet':
      case 'mobile_sheet':
      case 'sheet':
        return QLSurfacePattern.bottomAttached;
      case 'persistent_panel':
      case 'sidebar':
      case 'navigation_rail':
      case 'persistent_drawer':
        return QLSurfacePattern.persistentPanel;
      case 'temporary_overlay':
      case 'popover':
      case 'flyout':
      case 'context_panel':
      case 'menu':
      case 'context_menu':
      case 'dropdown':
        return QLSurfacePattern.temporaryOverlay;
      case 'full_screen':
      case 'full_screen_surface':
      case 'full_page_sheet':
      case 'immersive_editor':
        return QLSurfacePattern.fullScreen;
      case 'anchored_floating':
      case 'tooltip':
      case 'anchored_menu':
        return QLSurfacePattern.anchoredFloating;
      case 'expandable_inline':
      case 'inline_editor':
      case 'inline_details':
      case 'accordion':
        return QLSurfacePattern.inlineExpandable;
      default:
        return QLSurfacePattern.centered;
    }
  }

  QLSheetEdge parseEdge(String edge) {
    switch (edge) {
      case 'top':
        return QLSheetEdge.top;
      case 'left':
        return QLSheetEdge.left;
      case 'right':
        return QLSheetEdge.right;
      default:
        return QLSheetEdge.bottom;
    }
  }

  QLResizeEdge parseResizeEdge(String edge) {
    switch (edge) {
      case 'none':
        return QLResizeEdge.none;
      case 'left':
        return QLResizeEdge.left;
      case 'right':
        return QLResizeEdge.right;
      case 'top':
        return QLResizeEdge.top;
      case 'bottom':
        return QLResizeEdge.bottom;
      case 'topLeft':
        return QLResizeEdge.topLeft;
      case 'topRight':
        return QLResizeEdge.topRight;
      case 'bottomLeft':
        return QLResizeEdge.bottomLeft;
      default:
        return QLResizeEdge.bottomRight;
    }
  }

  QLMotionSpec parseMotion() {
    final dynamic motionValue = ctx.map('motion') ??
        ctx.map('animation') ??
        ctx.map('motionSpec') ??
        ctx.map('animationSpec');
    if (motionValue is Map || motionValue is String) {
      return QLMotionSpec.fromValue(motionValue);
    }
    final String jsonText = ctx.string('motionJson', fallback: '');
    if (jsonText.isNotEmpty) {
      return QLMotionSpec.fromValue(jsonText);
    }
    final String animationType = ctx.string('animationType', fallback: '');
    final int durationMs = ctx.integer('durationMs', fallback: -1);
    if (animationType.isNotEmpty || durationMs >= 0) {
      return QLMotionSpec.fromValue(<String, dynamic>{
        'type': animationType,
        if (durationMs >= 0) 'durationMs': durationMs,
        if (ctx.boolean('zoomIn', fallback: false)) 'zoomIn': true,
        if (ctx.number('zoomScale', fallback: double.nan).isFinite)
          'zoomScale': ctx.number('zoomScale'),
        if (ctx.number('fromScale', fallback: double.nan).isFinite)
          'fromScale': ctx.number('fromScale'),
        if (ctx.number('fromOpacity', fallback: double.nan).isFinite)
          'fromOpacity': ctx.number('fromOpacity'),
        if (ctx.number('fromBlur', fallback: double.nan).isFinite)
          'fromBlur': ctx.number('fromBlur'),
        if (ctx.number('fromX', fallback: double.nan).isFinite)
          'fromX': ctx.number('fromX'),
        if (ctx.number('fromY', fallback: double.nan).isFinite)
          'fromY': ctx.number('fromY'),
        if (ctx.number('toX', fallback: double.nan).isFinite)
          'toX': ctx.number('toX'),
        if (ctx.number('toY', fallback: double.nan).isFinite)
          'toY': ctx.number('toY'),
        if (ctx.string('curve', fallback: '').isNotEmpty)
          'curve': ctx.string('curve'),
      });
    }
    return const QLMotionSpec();
  }

  QLOverlayRuntimeSpec parseRuntime() {
    final dynamic runtimeValue = ctx.map('runtime') ??
        ctx.map('control') ??
        ctx.map('behavior') ??
        ctx.map('stack') ??
        ctx.map('hooks') ??
        ctx.map('actions') ??
        ctx.map('overlay');
    if (runtimeValue is Map || runtimeValue is String) {
      return QLOverlayRuntimeSpec.fromValue(runtimeValue);
    }
    final String runtimeJson = ctx.string('runtimeJson', fallback: '');
    if (runtimeJson.isNotEmpty) {
      return QLOverlayRuntimeSpec.fromValue(runtimeJson);
    }
    return const QLOverlayRuntimeSpec();
  }

  // FIX 3: Safe Size Parser to prevent NaN math layout crashes
  double? safeSize(String key) {
    final val = ctx.number(key, fallback: double.nan);
    return val.isFinite ? val : null;
  }

  Widget buildContent() {
    return ctx.slot('content') ??
        Q('col min-w-0 min-h-0', children: ctx.children);
  }

  Widget buildTrigger() {
    return ctx.slot('trigger') ??
        ctx.slot('content') ??
        const SizedBox.shrink();
  }

  // Detached overlay entry primitive.
  if (subType == 'overlay_entry' || subType == 'overlay') {
    final String triggerBind = ctx.string('triggerBind');
    final QLSignal<dynamic> triggerSig =
        triggerBind.isNotEmpty ? ctx.store.signal(triggerBind) : QLSignal(true);

    return _QLOverlayEntryNode(
      triggerSig: triggerSig,
      ctx: ctx,
    );
  }

  final QLSurfacePattern surfaceKind = parseSurfacePattern(
    ctx.string('surfaceKind',
        fallback: ctx.string('presentation', fallback: subType)),
  );
  final QLMotionSpec motion = parseMotion();
  final QLOverlayRuntimeSpec runtime = parseRuntime();
  final QLSheetEdge edge = parseEdge(
    ctx.string('edge', fallback: subType == 'drawer' ? 'left' : 'bottom'),
  );
  final bool barrier = ctx.boolean('barrierDismissible', fallback: true);
  final bool allowDrag = ctx.boolean('enableDrag', fallback: true);
  final bool allowResize = ctx.boolean('allowResize', fallback: true);
  final bool underlying =
      ctx.boolean('allowUnderlyingInteraction', fallback: false);
  final QLBackgroundEffect effect = parseEffect(ctx.string('bgEffect',
      fallback: surfaceKind == QLSurfacePattern.bottomAttached ||
              surfaceKind == QLSurfacePattern.edgeDocked
          ? 'zoomBack'
          : 'blur'));
  final bool showDragHandle = ctx.boolean('showDragHandle',
      fallback: surfaceKind == QLSurfacePattern.bottomAttached ||
          surfaceKind == QLSurfacePattern.edgeDocked);
  final double blurSigma = ctx.number('bgBlurSigma', fallback: 12.0);
  final double zoomDepth = ctx.number('bgZoomDepth', fallback: 0.08);
  final Color barrierColor =
      ctx.color('barrierColor', fallback: Colors.black) ?? Colors.black;
  final Color rootBgColor =
      ctx.color('rootBgColor', fallback: Colors.black) ?? Colors.black;
  final double barrierOpacity = ctx.number('barrierOpacity', fallback: 0.50);
  final Clip clipBehavior =
      ctx.boolean('clipSheet', fallback: true) ? Clip.antiAlias : Clip.none;
  final Alignment? sheetAlignment =
      switch (ctx.string('sheetAlignment', fallback: ctx.string('align'))) {
    'topLeft' => Alignment.topLeft,
    'topCenter' => Alignment.topCenter,
    'topRight' => Alignment.topRight,
    'centerLeft' => Alignment.centerLeft,
    'center' => Alignment.center,
    'centerRight' => Alignment.centerRight,
    'bottomLeft' => Alignment.bottomLeft,
    'bottomCenter' => Alignment.bottomCenter,
    'bottomRight' => Alignment.bottomRight,
    _ => null,
  };
  final EdgeInsetsGeometry sheetPadding = EdgeInsets.fromLTRB(
    ctx.number('sheetPaddingLeft',
        fallback: ctx.number('sheetPadding', fallback: 0.0)),
    ctx.number('sheetPaddingTop',
        fallback: ctx.number('sheetPadding', fallback: 0.0)),
    ctx.number('sheetPaddingRight',
        fallback: ctx.number('sheetPadding', fallback: 0.0)),
    ctx.number('sheetPaddingBottom',
        fallback: ctx.number('sheetPadding', fallback: 0.0)),
  );
  final BorderRadius sheetRadius = BorderRadius.circular(ctx.number(
      'sheetRadius',
      fallback: ctx.number('cornerRadius', fallback: 0.0)));
  final BoxConstraints constraints = BoxConstraints(
    maxWidth: ctx.number('maxWidth', fallback: double.nan).isFinite
        ? ctx.number('maxWidth')
        : (surfaceKind == QLSurfacePattern.inlineExpandable ? 800 : 800),
    maxHeight: ctx.number('maxHeight', fallback: double.nan).isFinite
        ? ctx.number('maxHeight')
        : (surfaceKind == QLSurfacePattern.inlineExpandable ? 99999 : 720),
  );

  QLSpatialConfig buildConfig(BuildContext mountCtx) {
    // FIX 5: Safe RenderObject retrieval
    RenderBox? box;
    if (mountCtx.mounted) {
      try {
        final renderObj = mountCtx.findRenderObject();
        if (renderObj is RenderBox && renderObj.hasSize) {
          box = renderObj;
        }
      } catch (_) {}
    }

    final Offset origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size sz = box?.size ?? Size.zero;

    if (subType == 'toast') {
      return QLSpatialConfig.toast(
        duration: Duration(
            milliseconds: ctx.number('durationMs', fallback: 3000).toInt()),
        runtime: runtime,
      );
    }
    if (subType == 'window') {
      return QLSpatialConfig.window(
        initialX: safeSize('x') ?? 100,
        initialY: safeSize('y') ?? 100,
        initialWidth: safeSize('w') ?? 420,
        initialHeight: safeSize('h') ?? 300,
        allowResize: ctx.boolean('allowResize', fallback: true),
        resizeEdges:
            parseResizeEdge(ctx.string('resizeEdges', fallback: 'bottomRight')),
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.inlineExpandable ||
        subType == 'expandable_inline') {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.inlineExpandable,
        dismissible: false,
        allowUnderlyingInteraction: true,
        anchor: sheetAlignment ?? Alignment.centerLeft,
        sheetAlignment: sheetAlignment ?? Alignment.centerLeft,
        constraints: constraints,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetRadius,
        clipBehavior: clipBehavior,
        bgZoomDepth: zoomDepth,
        bgBlurSigma: blurSigma,
        rootBgColor: rootBgColor,
        motion: motion,
        useSafeArea: ctx.boolean('useSafeArea', fallback: true),
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.persistentPanel) {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.persistentPanel,
        dismissible: false,
        allowUnderlyingInteraction: true,
        anchor: sheetAlignment ?? Alignment.centerLeft,
        sheetAlignment: sheetAlignment ?? Alignment.centerLeft,
        constraints: constraints,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        bgZoomDepth: zoomDepth,
        bgBlurSigma: blurSigma,
        rootBgColor: rootBgColor,
        motion: motion,
        useSafeArea: ctx.boolean('useSafeArea', fallback: true),
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.fullScreen) {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.fullScreen,
        dismissible: barrier,
        allowUnderlyingInteraction: false,
        anchor: Alignment.center,
        constraints: const BoxConstraints(),
        bgBlurSigma: blurSigma,
        bgZoomDepth: zoomDepth,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
        motion: motion,
        useSafeArea: ctx.boolean('useSafeArea', fallback: false),
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.edgeDocked || subType == 'drawer') {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.edgeDocked,
        dismissible: barrier,
        allowUnderlyingInteraction: underlying,
        enableDrag: allowDrag,
        edge: edge,
        anchor: sheetAlignment ?? Alignment.centerLeft,
        sheetAlignment: sheetAlignment ?? Alignment.centerLeft,
        constraints: constraints,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        bgZoomDepth: zoomDepth,
        bgBlurSigma: blurSigma,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
        initialWidth: safeSize('w'),
        initialHeight: safeSize('h'),
        motion: motion,
        useSafeArea: ctx.boolean('useSafeArea', fallback: true),
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.bottomAttached || subType == 'sheet') {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.bottomAttached,
        dismissible: barrier,
        allowUnderlyingInteraction: underlying,
        enableDrag: allowDrag,
        edge: edge,
        anchor: sheetAlignment ?? Alignment.bottomCenter,
        sheetAlignment: sheetAlignment ?? Alignment.bottomCenter,
        constraints: constraints,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        bgZoomDepth: zoomDepth,
        bgBlurSigma: blurSigma,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
        initialWidth: safeSize('w'),
        initialHeight: safeSize('h'),
        motion: motion,
        useSafeArea: ctx.boolean('useSafeArea', fallback: true),
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.temporaryOverlay ||
        subType == 'popover' ||
        subType == 'menu' ||
        subType == 'context_menu' ||
        subType == 'dropdown' ||
        subType == 'flyout' ||
        subType == 'context_panel') {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.anchoredFloating,
        dismissible: true,
        allowUnderlyingInteraction: underlying,
        anchor: Alignment.topLeft,
        sheetAlignment: Alignment.topLeft,
        targetLeft: origin.dx,
        targetTop: origin.dy,
        targetRight: origin.dx + sz.width,
        targetBottom: origin.dy + sz.height,
        matchAnchorWidth: ctx.boolean('matchAnchorWidth'),
        constraints: constraints,
        bgZoomDepth: zoomDepth,
        bgBlurSigma: blurSigma,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
        motion: motion,
        useSafeArea: false,
        runtime: runtime,
      );
    }

    if (surfaceKind == QLSurfacePattern.anchoredFloating) {
      return QLSpatialConfig.surface(
        pattern: QLSurfacePattern.anchoredFloating,
        dismissible: true,
        allowUnderlyingInteraction: underlying,
        anchor: Alignment.topLeft,
        sheetAlignment: Alignment.topLeft,
        targetLeft: origin.dx,
        targetTop: origin.dy,
        targetRight: origin.dx + sz.width,
        targetBottom: origin.dy + sz.height,
        matchAnchorWidth: ctx.boolean('matchAnchorWidth'),
        constraints: constraints,
        bgZoomDepth: zoomDepth,
        bgBlurSigma: blurSigma,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
        motion: motion,
        useSafeArea: false,
        runtime: runtime,
      );
    }

    return QLSpatialConfig.dialog(
      barrierDismissible: barrier,
      extrude3D: ctx.boolean('extrude3D', fallback: true),
      effect: effect,
      useSafeArea: ctx.boolean('useSafeArea', fallback: true),
      runtime: runtime,
    );
  }

  QLSpatialConfig buildInlineConfig() {
    return QLSpatialConfig.surface(
      pattern: surfaceKind == QLSurfacePattern.inlineExpandable
          ? QLSurfacePattern.inlineExpandable
          : QLSurfacePattern.persistentPanel,
      dismissible: false,
      allowUnderlyingInteraction: true,
      anchor: sheetAlignment ?? Alignment.centerLeft,
      sheetAlignment: sheetAlignment ?? Alignment.centerLeft,
      constraints: constraints,
      sheetPadding: sheetPadding,
      sheetBorderRadius: sheetRadius,
      clipBehavior: clipBehavior,
      bgZoomDepth: zoomDepth,
      bgBlurSigma: blurSigma,
      rootBgColor: rootBgColor,
      motion: motion,
      useSafeArea: ctx.boolean('useSafeArea', fallback: true),
      runtime: runtime,
    );
  }

  if (surfaceKind == QLSurfacePattern.inlineExpandable ||
      surfaceKind == QLSurfacePattern.persistentPanel) {
    return _QLInlineSurfaceHost(
      config: buildInlineConfig(),
      child: buildContent(),
    );
  }

  if (subType == 'toast') {
    return _QLToastAutoMounter(
      configBuilder: buildConfig,
      contentBuilder: buildContent,
    );
  }

  final String triggerBind = ctx.string('triggerBind');
  final bool pointerDriven = subType == 'menu' ||
      subType == 'context_menu' ||
      subType == 'popover' ||
      subType == 'dropdown' ||
      subType == 'flyout' ||
      subType == 'context_panel' ||
      subType == 'anchored_floating';

  return _QLTriggerBindPortal(
    triggerBind: triggerBind,
    store: ctx.store,
    openOnPointerUp: pointerDriven,
    configBuilder: buildConfig,
    contentBuilder: buildContent,
    triggerBuilder: buildTrigger,
  );
}

class _QLInlineSurfaceHost extends StatefulWidget {
  final QLSpatialConfig config;
  final Widget child;

  const _QLInlineSurfaceHost({required this.config, required this.child});

  @override
  State<_QLInlineSurfaceHost> createState() => _QLInlineSurfaceHostState();
}

class _QLInlineSurfaceHostState extends State<_QLInlineSurfaceHost>
    with TickerProviderStateMixin {
  late final QLTransitionComposer _composer;
  bool _initialized = false;

  QLTransitionPreset _mapPreset(QLTransitionMode mode) {
    switch (mode) {
      case QLTransitionMode.fadeScale:
        return QLTransitionPresets.dialog;
      case QLTransitionMode.slideUp:
        return QLTransitionPresets.sheet;
      case QLTransitionMode.slideDown:
        return QLTransitionPreset(
            fromScale: 1.0,
            fromOpacity: 0.0,
            fromTranslate: const Offset(0, -1),
            curve: QLSprings.sheet,
            duration: const Duration(milliseconds: 420));
      case QLTransitionMode.slideLeft:
        return QLTransitionPresets.drawer;
      case QLTransitionMode.slideRight:
        return QLTransitionPreset(
            fromScale: 1.0,
            fromOpacity: 0.0,
            fromTranslate: const Offset(1, 0),
            curve: QLSprings.sheet,
            duration: const Duration(milliseconds: 380));
      case QLTransitionMode.popover:
        return QLTransitionPresets.menu;
      case QLTransitionMode.windowDrop:
        return QLTransitionPresets.window;
      case QLTransitionMode.fullscreen:
        return QLTransitionPresets.full;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final basePreset = _mapPreset(widget.config.transition);
    final resolvedPreset = widget.config.motion.toPreset(
      basePreset,
      screenSize: MediaQuery.sizeOf(context),
      pattern: widget.config.surfacePattern,
    );
    _composer = QLTransitionComposer.entrance(
      vsync: this,
      preset: resolvedPreset,
      screenSize: MediaQuery.sizeOf(context),
    );

    // FIX 2: Ensure the internal animation plays, otherwise the surface will remain invisible!
    _composer.play();
  }

  @override
  void dispose() {
    _composer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final bool needsSafeArea =
        c.useSafeArea || (c.flags & QLNodeFlags.useSafeArea) != 0;

    Widget child = widget.child;
    child = AnimatedBuilder(
      animation: Listenable.merge([
        _composer.scaleSignal,
        _composer.translateSignal,
        _composer.opacitySignal,
      ]),
      builder: (ctx, child) {
        final Matrix4 m = Matrix4.identity();
        final double scale = _composer.scaleSignal.value;
        if (scale != 1.0) {
          m.storage[0] = scale;
          m.storage[5] = scale;
          m.storage[10] = scale;
        }
        final Offset trans = _composer.translateSignal.value;
        m.storage[12] = trans.dx;
        m.storage[13] = trans.dy;
        return Transform(
          transform: m,
          child: Opacity(
            opacity: _composer.opacitySignal.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );

    if (c.sheetPadding != EdgeInsets.zero) {
      child = Padding(padding: c.sheetPadding, child: child);
    }
    if (c.sheetBorderRadius != BorderRadius.zero ||
        c.clipBehavior != Clip.none) {
      child = ClipRRect(
        borderRadius: c.sheetBorderRadius,
        clipBehavior: c.clipBehavior,
        child: child,
      );
    }
    if (needsSafeArea) {
      child = SafeArea(child: child);
    }
    if (c.constraints.hasBoundedWidth || c.constraints.hasBoundedHeight) {
      child = ConstrainedBox(constraints: c.constraints, child: child);
    }
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      child: child,
    );
  }
}

class _QLOverlayEntryNode extends StatefulWidget {
  final QLSignal<dynamic> triggerSig;
  final _AliasContext ctx;

  const _QLOverlayEntryNode({required this.triggerSig, required this.ctx});

  @override
  State<_QLOverlayEntryNode> createState() => _QLOverlayEntryNodeState();
}

class _QLOverlayEntryNodeState extends State<_QLOverlayEntryNode> {
  VoidCallback? _closeOverlay;
  bool _pendingOpen = false;

  @override
  void initState() {
    super.initState();
    widget.triggerSig.addListener(_onTriggerChanged);
    if (widget.triggerSig.value == true) {
      _pendingOpen = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pendingOpen) {
      _pendingOpen = false;
      _openOverlay();
    }
  }

  @override
  void didUpdateWidget(covariant _QLOverlayEntryNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.triggerSig != widget.triggerSig) {
      oldWidget.triggerSig.removeListener(_onTriggerChanged);
      widget.triggerSig.addListener(_onTriggerChanged);
      _onTriggerChanged();
    }
  }

  void _openOverlay() {
    // FIX 1 & 4: Safe async mounting loop protection
    if (_closeOverlay != null) return;

    // Set a dummy closure to lock out subsequent calls while waiting for the next frame
    _closeOverlay = () {};

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.mountOverlay(
        QLSpatialConfig.window(
          initialX: widget.ctx.number('x', fallback: 0),
          initialY: widget.ctx.number('y', fallback: 0),
        ),
        (c, close) {
          _closeOverlay = close;
          return Q(widget.ctx.node.style ?? '', children: widget.ctx.children);
        },
      );
    });
  }

  void _onTriggerChanged() {
    if (widget.triggerSig.value == true && _closeOverlay == null) {
      _openOverlay();
    } else if (widget.triggerSig.value == false && _closeOverlay != null) {
      _closeOverlay?.call();
      _closeOverlay = null;
    }
  }

  @override
  void dispose() {
    widget.triggerSig.removeListener(_onTriggerChanged);
    _closeOverlay?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ─── _QLTriggerBindPortal ─────────────────────────────────────────────────────

class _QLTriggerBindPortal extends StatefulWidget {
  final QLSpatialConfig Function(BuildContext) configBuilder;
  final Widget Function() contentBuilder;
  final Widget Function() triggerBuilder;
  final String triggerBind;
  final QLDataStore store;
  final bool openOnPointerUp;

  const _QLTriggerBindPortal({
    required this.configBuilder,
    required this.contentBuilder,
    required this.triggerBuilder,
    required this.triggerBind,
    required this.store,
    required this.openOnPointerUp,
  });

  @override
  State<_QLTriggerBindPortal> createState() => _QLTriggerBindPortalState();
}

class _QLTriggerBindPortalState extends State<_QLTriggerBindPortal> {
  QLSignal<dynamic>? _signal;
  VoidCallback? _closeOverlay;
  bool _isOpening = false;

  @override
  void initState() {
    super.initState();
    if (widget.triggerBind.isNotEmpty) {
      _signal = widget.store.signal(widget.triggerBind);
      _signal!.addListener(_onSignalChanged);
    }
  }

  @override
  void dispose() {
    _signal?.removeListener(_onSignalChanged);
    _closeOverlay?.call();
    _closeOverlay = null;
    super.dispose();
  }

  void _onSignalChanged() {
    if (!mounted) return;
    final value = _signal?.value;
    if (value == true && _closeOverlay == null && !_isOpening) {
      _openOverlay();
    } else if (value == false && _closeOverlay != null) {
      _closeOverlay!.call();
      _closeOverlay = null;
    }
  }

  void _openOverlay() {
    // FIX 4: Prevent double-mounting ghost layers if signal fires rapidly
    if (!mounted || _closeOverlay != null || _isOpening) return;
    _isOpening = true;

    context.mountOverlay(
      widget.configBuilder(context),
      (c, close) {
        _closeOverlay = () {
          close();
          _closeOverlay = null;
          _syncStateToFalse();
        };
        return widget.contentBuilder();
      },
    ).then((_) {
      if (mounted) {
        _closeOverlay = null;
        _isOpening = false;
        _syncStateToFalse();
      }
    });
  }

  void _syncStateToFalse() {
    if (widget.triggerBind.isNotEmpty) {
      final current = widget.store.get(widget.triggerBind);
      if (current == true) widget.store.set(widget.triggerBind, false);
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (widget.triggerBind.isNotEmpty) {
      final current = widget.store.get(widget.triggerBind);
      widget.store.set(widget.triggerBind, current != true);
    } else {
      _openOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.triggerBuilder();
    if (widget.openOnPointerUp) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: _onPointerUp,
        child: trigger,
      );
    }
    return trigger;
  }
}

// ─── _QLToastAutoMounter ──────────────────────────────────────────────────────

class _QLToastAutoMounter extends StatefulWidget {
  final QLSpatialConfig Function(BuildContext) configBuilder;
  final Widget Function() contentBuilder;

  const _QLToastAutoMounter({
    required this.configBuilder,
    required this.contentBuilder,
  });

  @override
  State<_QLToastAutoMounter> createState() => _QLToastAutoMounterState();
}

class _QLToastAutoMounterState extends State<_QLToastAutoMounter> {
  bool _launched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // FIX 1: Delay mounting so it runs AFTER layout phase preventing build exceptions
    if (!_launched) {
      _launched = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.mountOverlay(
          widget.configBuilder(context),
          (c, close) => widget.contentBuilder(),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 8: CONTROL (Stateful Aggregation & Forms)
// ════════════════════════════════════════════════════════════════════════════

void _registerPortalAliases(QuantumVM vm) {
  vm.defineAlias('overlay_entry', 'portal:overlay_entry',
      description: 'Overlay entry alias.',
      tags: const ['portal', 'overlay', 'alias']);
  vm.defineAlias('overlay', 'portal:overlay',
      description: 'Overlay alias.',
      tags: const ['portal', 'overlay', 'alias']);
  vm.defineAlias('dialog', 'portal:dialog',
      description: 'Dialog portal alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('drawer', 'portal:sheet',
      description: 'Drawer alias routed through sheet.',
      tags: const ['portal', 'alias']);
  vm.defineAlias('sheet', 'portal:sheet',
      description: 'Sheet portal alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('popover', 'portal:popover',
      description: 'Popover portal alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('modal', 'portal:dialog',
      description: 'Modal alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('centered_overlay', 'portal:dialog',
      description: 'Centered overlay alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('persistent_panel', 'portal:overlay',
      description: 'Persistent panel alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('inline_expandable', 'portal:overlay',
      description: 'Inline expandable alias.', tags: const ['portal', 'alias']);
}

class PortalCoreExporter implements QuantumCoreExporter {
  const PortalCoreExporter();
  
  @override
  void export(QuantumVM vm) {
    vm.define('portal', _buildPortal, tags: const ['core', 'portal']);
    _registerPortalAliases(vm);
  }
}
