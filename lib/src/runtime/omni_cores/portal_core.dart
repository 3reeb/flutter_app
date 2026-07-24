part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildPortal

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

  // 🚀 Z-SPACE PRIMITIVE: portal:overlay_entry / portal:overlay
  if (subType == 'overlay_entry' || subType == 'overlay') {
    final String triggerBind = ctx.string('triggerBind');
    final QLSignal<dynamic> triggerSig =
        triggerBind.isNotEmpty ? ctx.store.signal(triggerBind) : QLSignal(true);

    return _QLOverlayEntryNode(
      triggerSig: triggerSig,
      ctx: ctx,
    );
  }

  // STANDARD PORTAL LOGIC
  QLSpatialConfig buildConfig(BuildContext mountCtx) {
    final RenderBox? box = mountCtx.findRenderObject() as RenderBox?;
    final Offset origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size sz = box?.size ?? Size.zero;

    final effect = parseEffect(ctx.string('bgEffect',
        fallback:
            subType == 'sheet' || subType == 'drawer' ? 'zoomBack' : 'blur'));
    final edge = parseEdge(
        ctx.string('edge', fallback: subType == 'drawer' ? 'left' : 'bottom'));
    final barrier = ctx.boolean('barrierDismissible', fallback: true);
    final blurSigma = ctx.number('bgBlurSigma', fallback: 12.0);
    final zoomDepth = ctx.number('bgZoomDepth', fallback: 0.08);
    final barrierColor =
        ctx.color('barrierColor', fallback: Colors.black) ?? Colors.black;
    final rootBgColor =
        ctx.color('rootBgColor', fallback: Colors.black) ?? Colors.black;
    final barrierOpacity = ctx.number('barrierOpacity', fallback: 0.50);
    final bool showDragHandle = ctx.boolean('showDragHandle',
        fallback: subType == 'sheet' || subType == 'drawer');
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

    if (subType == 'drawer') {
      return QLSpatialConfig.drawer(
        dismissible: barrier,
        enableDrag: ctx.boolean('enableDrag', fallback: true),
        edge: edge,
        bgZoomDepth: zoomDepth,
        sheetAlignment: sheetAlignment,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
      );
    }
    if (subType == 'sheet') {
      return QLSpatialConfig.sheet(
        dismissible: barrier,
        enableDrag: ctx.boolean('enableDrag', fallback: true),
        effect: effect,
        edge: edge,
        sheetAlignment: sheetAlignment,
        sheetPadding: sheetPadding,
        sheetBorderRadius: sheetRadius,
        clipBehavior: clipBehavior,
        showDragHandle: showDragHandle,
        bgBlurSigma: blurSigma,
        bgZoomDepth: zoomDepth,
        initialWidth: ctx.number('w'),
        initialHeight: ctx.number('h'),
        barrierColor: barrierColor,
        barrierOpacity: barrierOpacity,
        rootBgColor: rootBgColor,
      );
    }
    if (subType == 'popover' ||
        subType == 'menu' ||
        subType == 'context_menu') {
      return QLSpatialConfig.menu(
        targetLeft: origin.dx,
        targetTop: origin.dy,
        targetRight: origin.dx + sz.width,
        targetBottom: origin.dy + sz.height,
        matchAnchorWidth: ctx.boolean('matchAnchorWidth'),
        isModal: ctx.boolean('isModal'),
      );
    }
    if (subType == 'toast') {
      return QLSpatialConfig.toast(
        duration: Duration(
            milliseconds: ctx.number('durationMs', fallback: 3000).toInt()),
      );
    }
    if (subType == 'window') {
      return QLSpatialConfig.window(
        initialX: ctx.number('x', fallback: 100),
        initialY: ctx.number('y', fallback: 100),
        initialWidth: ctx.number('w', fallback: 420),
        initialHeight: ctx.number('h', fallback: 300),
        allowResize: ctx.boolean('allowResize', fallback: true),
        resizeEdges:
            parseResizeEdge(ctx.string('resizeEdges', fallback: 'bottomRight')),
      );
    }
    return QLSpatialConfig.dialog(
      barrierDismissible: barrier,
      extrude3D: ctx.boolean('extrude3D', fallback: true),
      effect: effect,
    );
  }

  if (subType == 'toast') {
    return Builder(builder: (triggerCtx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (triggerCtx.mounted) {
          triggerCtx.mountOverlay(
            buildConfig(triggerCtx),
            (c, close) => ctx.slot('content') ?? const SizedBox.shrink(),
          );
        }
      });
      return const SizedBox.shrink();
    });
  }

  if (subType == 'menu' || subType == 'context_menu') {
    return Builder(builder: (triggerCtx) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerUp: (_) {
          if (triggerCtx.mounted) {
            triggerCtx.mountOverlay(
              buildConfig(triggerCtx),
              (c, close) => ctx.slot('content') ?? const SizedBox.shrink(),
            );
          }
        },
        child: ctx.slot('trigger') ?? const SizedBox.shrink(),
      );
    });
  }

  Offset? pointerDownPos;
  return Builder(builder: (triggerCtx) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => pointerDownPos = e.position,
      onPointerUp: (e) {
        if (pointerDownPos != null &&
            (e.position - pointerDownPos!).distance < 15) {
          if (triggerCtx.mounted) {
            triggerCtx.mountOverlay(buildConfig(triggerCtx),
                (c, close) => ctx.slot('content') ?? const SizedBox.shrink());
          }
        }
        pointerDownPos = null;
      },
      child: ctx.slot('trigger') ?? const SizedBox.shrink(),
    );
  });
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

  @override
  void initState() {
    super.initState();
    widget.triggerSig.addListener(_onTriggerChanged);
    _onTriggerChanged();
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

  void _onTriggerChanged() {
    if (widget.triggerSig.value == true && _closeOverlay == null) {
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

// ════════════════════════════════════════════════════════════════════════════
// CORE 8: CONTROL (Stateful Aggregation & Forms)
// ════════════════════════════════════════════════════════════════════════════

void _registerPortalAliases(QuantumVM vm) {
  vm.defineAlias('overlay_entry', 'portal:overlay_entry', description: 'Overlay entry alias.', tags: const ['portal', 'overlay', 'alias']);
  vm.defineAlias('overlay', 'portal:overlay', description: 'Overlay alias.', tags: const ['portal', 'overlay', 'alias']);
  vm.defineAlias('dialog', 'portal:dialog', description: 'Dialog portal alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('drawer', 'portal:sheet', description: 'Drawer alias routed through sheet.', tags: const ['portal', 'alias']);
  vm.defineAlias('sheet', 'portal:sheet', description: 'Sheet portal alias.', tags: const ['portal', 'alias']);
  vm.defineAlias('popover', 'portal:popover', description: 'Popover portal alias.', tags: const ['portal', 'alias']);
}
