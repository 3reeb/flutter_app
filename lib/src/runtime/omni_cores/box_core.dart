part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildBox

Widget _buildBox(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'col');

  Widget _q(Widget child) => Q('col min-w-0 min-h-0', children: [child]);

  Matrix4 _matrix4FromDynamic(dynamic v) {
    if (v is Matrix4) return v;
    if (v is Float64List && v.length >= 16) return Matrix4.fromFloat64List(v);
    if (v is List) {
      final values = v
          .where((e) => e is num)
          .map((e) => (e as num).toDouble())
          .toList(growable: false);
      if (values.length >= 16) {
        return Matrix4.fromFloat64List(
            Float64List.fromList(values.take(16).toList()));
      }
    }
    return Matrix4.identity();
  }

  Curve _curveFromName(String name) {
    switch (name.toLowerCase()) {
      case 'linear':
        return Curves.linear;
      case 'easein':
        return Curves.easeIn;
      case 'easeout':
        return Curves.easeOut;
      case 'easeinout':
        return Curves.easeInOut;
      case 'easeoutcubic':
        return Curves.easeOutCubic;
      case 'easeincubic':
        return Curves.easeInCubic;
      case 'bounceout':
        return Curves.bounceOut;
      case 'bouncein':
        return Curves.bounceIn;
      case 'elasticout':
        return Curves.elasticOut;
      case 'elasticin':
        return Curves.elasticIn;
      default:
        return Curves.easeOutCubic;
    }
  }

  Widget _wrapIf(bool enabled, Widget Function(Widget) wrap, Widget child) {
    return enabled ? wrap(child) : child;
  }

  Widget _wrapIfNotEmpty(
      String value, Widget Function(Widget) wrap, Widget child) {
    return value.isNotEmpty ? wrap(child) : child;
  }

  if (subType == 'split') {
    Widget splitWidget = LayoutBuilder(
      builder: (context, constraints) {
        final bool unboundedW = constraints.maxWidth.isInfinite;
        final bool unboundedH = constraints.maxHeight.isInfinite;

        Widget body = QuantumLayout(
          layoutType: QLayoutType.split,
          direction: ctx.string('direction') == 'vertical'
              ? Axis.vertical
              : Axis.horizontal,
          fractions: ctx.list('fractions').isNotEmpty
              ? ctx
                  .list('fractions')
                  .map((e) => (e as num).toDouble())
                  .toList(growable: false)
              : null,
          children: ctx.children,
        );

        if (unboundedW || unboundedH) {
          body = SizedBox(
            width: unboundedW
                ? MediaQuery.sizeOf(context).width
                : constraints.maxWidth,
            height: unboundedH
                ? MediaQuery.sizeOf(context).height
                : constraints.maxHeight,
            child: body,
          );
        }
        return body;
      },
    );

    return QLBox(
      style: 'min-w-0 min-h-0 ${ctx.node.style ?? ''}',
      suppressParentData: true,
      child: splitWidget,
    );
  }

  if (subType == 'expanded' || subType == 'flexible') {
    // 🚀 FIX: Swap to QFlexible so it checks the active QLayoutScope correctly
    return QuantumFlexible(
      flex: ctx.integer('flex', fallback: 1),
      fit: subType == 'expanded' ? FlexFit.tight : FlexFit.loose,
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  if (subType == 'morph') {
    return QuantumLayout(
      layoutType: QLayoutType.morph,
      initialMorphSize: Size(
        ctx.number('width', fallback: 200),
        ctx.number('height', fallback: 200),
      ),
      lockAspect: ctx.boolean('lockAspect'),
      snapGrid: ctx.number('snapGrid', fallback: 0.0),
      children: ctx.children,
    );
  }

  if (subType == 'safe') {
    return SafeArea(
      top: ctx.boolean('top', fallback: true),
      bottom: ctx.boolean('bottom', fallback: true),
      left: ctx.boolean('left', fallback: true),
      right: ctx.boolean('right', fallback: true),
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  if (subType == 'aspect') {
    return QuantumAspectRatio(
      ratio: ctx.number('ratio', fallback: 1.0),
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  if (subType == 'sticky') {
    return SliverPersistentHeader(
      pinned: ctx.boolean('pinned', fallback: true),
      floating: ctx.boolean('floating', fallback: false),
      delegate: QuantumStickyDelegate(
        minHeight: ctx.number('minHeight', fallback: 60),
        maxHeight: ctx.number('maxHeight', fallback: 200),
        child: Q('col min-w-0 min-h-0', children: ctx.children),
      ),
    );
  }

  if (subType == 'virtual_grid') {
    return QuantumVirtualGridView(
      itemCount: ctx.children.length,
      columns: QParser.parse(ctx.string('cols', fallback: '1fr 1fr')),
      rows: QParser.parse(ctx.string('rows', fallback: 'auto')),
      columnGap: ctx.number('gap', fallback: 8.0),
      rowGap: ctx.number('gap', fallback: 8.0),
      itemBuilder: (context, index) => ctx.children[index],
    );
  }

  if (subType == 'measure') {
    final String bindTarget = ctx.string('bind');
    final String style = ctx.string('style');
    return _QLMeasureNode(
      bindTarget: bindTarget,
      store: ctx.store,
      child: Q('col min-w-0 min-h-0 $style', children: ctx.children),
    );
  }

  if (subType == 'builder') {
    return LayoutBuilder(builder: (c, constraints) {
      return QLDataScope(
        localData: {
          ...ctx.env,
          'maxWidth': constraints.maxWidth,
          'maxHeight': constraints.maxHeight,
        },
        child: Q('col min-w-0 min-h-0', children: ctx.children),
      );
    });
  }

  if (subType == 'matrix' || subType == 'layer') {
    final String matrixBind = ctx.string('matrixBind');
    final QLSignal<dynamic>? rawSig =
        matrixBind.isNotEmpty ? ctx.store.signal(matrixBind) : null;

    final QLSignal<Matrix4>? transformSig = rawSig != null
        ? QLSignalProxy<Matrix4>(
            rawSig,
            (v) => _matrix4FromDynamic(v),
            (v) => v.storage,
          )
        : null;

    final String opacityBind = ctx.string('opacityBind');
    final QLSignal<double>? opacitySig = opacityBind.isNotEmpty
        ? QLSignalProxy<double>(
            ctx.store.signal(opacityBind),
            (v) => (v as num?)?.toDouble() ?? 1.0,
            (v) => v,
          )
        : null;

    return QLBox(
      transform3D: transformSig,
      opacity: opacitySig,
      child: Q('col w-full h-full ${ctx.node.style ?? ''}',
          children: ctx.children),
    );
  }

  if (subType == 'surface' || subType == 'shell') {
    final String shellStyle = QDesignMatrix.resolve(
      family: 'surface',
      intent: ctx.intent,
      fill: ctx.string('fill', fallback: 'surface'),
      depth: ctx.depth,
      edge: ctx.edge,
      shape: ctx.shape,
      scale: ctx.scale,
      disabled: ctx.boolean('disabled'),
    );
    return Q(
      '$shellStyle col min-w-0 min-h-0 ${ctx.node.style ?? ''}',
      padding: ctx.list('padding'),
      margin: ctx.list('margin'),
      gap: ctx.number('gap') > 0 ? ctx.number('gap') : null,
      children: ctx.children,
    );
  }

  if (subType == 'responsive') {
    return LayoutBuilder(builder: (c, constraints) {
      final size = MediaQuery.sizeOf(ctx.flutterContext);
      return QLDataScope(
        localData: {
          ...ctx.env,
          'width': size.width,
          'height': size.height,
          'isCompact': size.width < 640,
          'isMedium': size.width >= 640 && size.width < 1024,
          'isLarge': size.width >= 1024,
          'maxWidth': constraints.maxWidth,
          'maxHeight': constraints.maxHeight,
        },
        child: Builder(
          builder: (innerCtx) {
            final rebuiltChildren = ctx.node.children
                .map((childNode) =>
                    QuantumVM.instance.renderWidget(innerCtx, childNode))
                .toList(growable: false);
            return Q('col min-w-0 min-h-0', children: rebuiltChildren);
          },
        ),
      );
    });
  }

  if (subType == 'viewport') {
    final size = MediaQuery.sizeOf(ctx.flutterContext);
    return QLDataScope(
      localData: {
        ...ctx.env,
        'viewportWidth': size.width,
        'viewportHeight': size.height,
      },
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

// ───────────────────────────────────────────────────────────────────────────
// GENERAL BOX / FLEX / GRID / WRAPPER PIPELINE
// ───────────────────────────────────────────────────────────────────────────

  final String matrixStyle = QDesignMatrix.resolve(
    family: 'surface',
    intent: ctx.intent,
    fill: ctx.string('fill', fallback: 'bare'),
    depth: ctx.depth,
    edge: ctx.edge,
    shape: ctx.shape,
    scale: ctx.string('scale', fallback: 'bare'),
    disabled: false,
  );

  final List<String> styles = [matrixStyle];

  if (subType == 'row') {
    styles.add('row');
  } else if (subType == 'col') {
    styles.add('col');
  } else if (subType == 'stack') {
    styles.add('stack');
  } else if (subType == 'wrap') {
    styles.add('wrap');
  } else if (subType == 'grid' || subType == 'masonry') {
    styles.add('col');
    styles.add('w-full');
    styles.add('h-full');
  }

  if (ctx.string('justify').isNotEmpty) {
    styles.add('justify-${ctx.string('justify')}');
  }
  if (ctx.string('items').isNotEmpty) {
    styles.add('items-${ctx.string('items')}');
  }
  if (ctx.boolean('clip')) {
    styles.add('overflow-hidden');
  }
  if (ctx.number('gap') > 0) {
    styles.add('gap-${ctx.number('gap').toInt()}');
  }
  if (ctx.node.style != null && ctx.node.style!.isNotEmpty) {
    styles.add(ctx.node.style!);
  }

  Widget node;

  if (subType == 'grid' || subType == 'masonry') {
    node = QuantumLayout(
      layoutType: subType == 'masonry' ? QLayoutType.masonry : QLayoutType.grid,
      columns: ctx.string('gridCols',
          fallback: ctx.string('cols', fallback: '1fr 1fr')),
      rows: ctx.string('gridRows',
          fallback: ctx.string('rows', fallback: 'auto')),
      columnGap: ctx.number('gap', fallback: 8.0),
      rowGap: ctx.number('gap', fallback: 8.0),
      dense: ctx.boolean('dense', fallback: true),
      children: ctx.children,
    );

    node = Q(
      styles.join(' '),
      padding: ctx.list('padding'),
      margin: ctx.list('margin'),
      onTap: ctx.action('onClick'),
      suppressParentData: true,
      children: [node],
    );
  } else {
    node = Q(
      styles.join(' '),
      padding: ctx.list('padding'),
      margin: ctx.list('margin'),
      gap: ctx.number('gap') > 0 ? ctx.number('gap') : null,
      onTap: ctx.action('onClick'),
      children: ctx.children,
      suppressParentData: true,
    );
  }

// ───────────────────────────────────────────────────────────────────────────
// OPTIONAL HIGH-POWER WRAPPERS
// Zero overhead unless the prop is actually used.
// ───────────────────────────────────────────────────────────────────────────

  final bool offstage = ctx.boolean('offstage');
  if (offstage) {
    node = Offstage(offstage: true, child: node);
  }

  if (ctx.boolean('ignorePointer')) {
    node = IgnorePointer(
      ignoring: true,
      child: node,
    );
  }

  if (ctx.boolean('absorbPointer')) {
    node = AbsorbPointer(
      absorbing: true,
      child: node,
    );
  }

  if (ctx.boolean('repaintBoundary')) {
    node = RepaintBoundary(child: node);
  }

  final String semanticLabel = ctx.string('semanticLabel');
  if (semanticLabel.isNotEmpty || ctx.boolean('semantics')) {
    node = Semantics(
      label: semanticLabel.isNotEmpty ? semanticLabel : null,
      enabled: !ctx.boolean('disabled'),
      child: node,
    );
  }

  if (ctx.boolean('constrained')) {
    node = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: ctx.number('minWidth', fallback: 0.0),
        minHeight: ctx.number('minHeight', fallback: 0.0),
        maxWidth: ctx.number('maxWidth', fallback: double.infinity),
        maxHeight: ctx.number('maxHeight', fallback: double.infinity),
      ),
      child: node,
    );
  }

  if (ctx.boolean('expand')) {
    node = SizedBox.expand(child: node);
  } else {
    final double w = ctx.number('width', fallback: double.nan);
    final double h = ctx.number('height', fallback: double.nan);
    if (w.isFinite || h.isFinite) {
      node = SizedBox(
        width: w.isFinite ? w : null,
        height: h.isFinite ? h : null,
        child: node,
      );
    }
  }

  if (ctx.boolean('fractional')) {
    node = FractionallySizedBox(
      widthFactor: ctx.number('widthFactor', fallback: 1.0),
      heightFactor: ctx.number('heightFactor', fallback: 1.0),
      child: node,
    );
  }

  if (ctx.boolean('aspectBox')) {
    node = AspectRatio(
      aspectRatio: ctx.number('ratio', fallback: 1.0),
      child: node,
    );
  }

  final String clipKind = ctx.string('clipKind', fallback: '');
  if (ctx.boolean('clip') || clipKind.isNotEmpty) {
    node = ClipRect(
      child: node,
    );
  }

  final double opacity = ctx.number('opacity', fallback: 1.0);
  if (opacity < 1.0) {
    node = Opacity(opacity: opacity.clamp(0.0, 1.0), child: node);
  }

  final String heroTag = ctx.string('heroTag', fallback: '');
  if (heroTag.isNotEmpty) {
    node = Hero(
      tag: heroTag,
      flightShuttleBuilder: ctx.boolean('heroFlight')
          ? (flightContext, animation, flightDirection, fromHeroContext,
              toHeroContext) {
              return FadeTransition(
                opacity: animation.drive(Tween<double>(begin: 0.0, end: 1.0)),
                child: toHeroContext.widget,
              );
            }
          : null,
      child: node,
    );
  }

  final String variantKey = ctx.string('variant', fallback: '');
  final bool animate = ctx.boolean('animate') || variantKey.isNotEmpty;
  if (animate) {
    final int durationMs = ctx.integer('durationMs', fallback: 180);
    final String transitionKind = ctx.string('transition', fallback: 'fade');
    final Curve curve =
        _curveFromName(ctx.string('curve', fallback: 'easeOutCubic'));

    node = AnimatedSwitcher(
      duration: Duration(milliseconds: durationMs.clamp(0, 10000)),
      switchInCurve: curve,
      switchOutCurve: curve,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        switch (transitionKind.toLowerCase()) {
          case 'scale':
            return ScaleTransition(scale: animation, child: child);
          case 'slide':
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          case 'size':
            return SizeTransition(sizeFactor: animation, child: child);
          case 'fade':
          default:
            return FadeTransition(opacity: animation, child: child);
        }
      },
      child: KeyedSubtree(
        key: ValueKey<String>(variantKey.isNotEmpty
            ? variantKey
            : '${subType}_${ctx.node.props['id'] ?? ctx.node.hashCode}'),
        child: node,
      ),
    );
  }

  final bool draggable = ctx.boolean('draggable');
  if (draggable) {
    node = Draggable<Object>(
      data: ctx.string('dragData', fallback: subType),
      axis: ctx.string('dragAxis') == 'horizontal'
          ? Axis.horizontal
          : ctx.string('dragAxis') == 'vertical'
              ? Axis.vertical
              : null,
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(
          opacity: ctx.number('dragOpacity', fallback: 0.85).clamp(0.0, 1.0),
          child: node,
        ),
      ),
      childWhenDragging: ctx.boolean('hideOnDrag', fallback: false)
          ? const SizedBox.shrink()
          : node,
      child: node,
    );
  }

  final bool longPressDrag = ctx.boolean('longPressDraggable');
  if (longPressDrag) {
    node = LongPressDraggable<Object>(
      data: ctx.string('dragData', fallback: subType),
      feedback: Material(
        type: MaterialType.transparency,
        child: Opacity(
          opacity: ctx.number('dragOpacity', fallback: 0.85).clamp(0.0, 1.0),
          child: node,
        ),
      ),
      childWhenDragging: ctx.boolean('hideOnDrag', fallback: false)
          ? const SizedBox.shrink()
          : node,
      child: node,
    );
  }

  final bool rotate = ctx.boolean('rotate');
  final double rotateTurns = ctx.number('rotateTurns', fallback: 0.0);
  if (rotate || rotateTurns != 0.0) {
    node = Transform.rotate(
      angle: rotateTurns * 3.1415926535897932 * 2.0,
      alignment: Alignment.center,
      child: node,
    );
  }

  final bool transformEnabled = ctx.boolean('transform');
  final String transformBind = ctx.string('transformBind', fallback: '');
  if (transformEnabled || transformBind.isNotEmpty) {
    final QLSignal<dynamic>? rawSig =
        transformBind.isNotEmpty ? ctx.store.signal(transformBind) : null;

    final QLSignal<Matrix4>? transformSig = rawSig != null
        ? QLSignalProxy<Matrix4>(
            rawSig,
            (v) => _matrix4FromDynamic(v),
            (v) => v.storage,
          )
        : null;

    if (transformSig != null) {
      node = QLBox(
        transform3D: transformSig,
        child: node,
      );
    } else {
      final String matrix = ctx.string('matrix', fallback: '');
      if (matrix.isNotEmpty) {
        final values = matrix
            .split(',')
            .map((e) => double.tryParse(e.trim()) ?? 0.0)
            .toList(growable: false);
        if (values.length >= 16) {
          node = Transform(
            transform: Matrix4.fromFloat64List(
                Float64List.fromList(values.take(16).toList())),
            alignment: Alignment.center,
            child: node,
          );
        }
      }
    }
  }

  if (ctx.boolean('resize')) {
    node = QuantumMorphSurface(
      initialSize: Size(
        ctx.number('width', fallback: 200.0),
        ctx.number('height', fallback: 200.0),
      ),
      lockAspectRatio: ctx.boolean('lockAspect'),
      snapGrid: ctx.number('snapGrid', fallback: 0.0),
      child: node,
    );
  }

  final bool wrapInScroll = ctx.boolean('scrollable') || subType == 'scroll';
  if (wrapInScroll) {
    final bool isRow = subType == 'row';
    final Axis scrollAxis = isRow ? Axis.horizontal : Axis.vertical;
    node = _buildSmartScrollViewport(axis: scrollAxis, child: node);
  }

  return _applyImplicitBehaviors(ctx, node);
}

// ─────────────────────────────────────────────────────────────────────────────
// SPATIAL MEASUREMENT HELPER (Required for box:measure)
// ─────────────────────────────────────────────────────────────────────────────
class _QLMeasureNode extends SingleChildRenderObjectWidget {
  final String bindTarget;
  final QLDataStore store;

  const _QLMeasureNode({
    required this.bindTarget,
    required this.store,
    required Widget child,
  }) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureNode(bindTarget, store);

  @override
  void updateRenderObject(
      BuildContext context, covariant _RenderMeasureNode renderObject) {
    renderObject
      ..bindTarget = bindTarget
      ..store = store;
  }
}

class _RenderMeasureNode extends RenderProxyBox {
  String bindTarget;
  QLDataStore store;
  Rect _lastRect = Rect.zero;

  _RenderMeasureNode(this.bindTarget, this.store);

  @override
  void performLayout() {
    super.performLayout();
    // Defer writing to the signal to avoid mutating state during layout phase.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!attached || bindTarget.isEmpty) return;
      final pos = localToGlobal(Offset.zero);
      final r = Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height);
      if (r != _lastRect) {
        _lastRect = r;
        // Broadcasts to the store so attached signals (like popovers/menus) instantly reposition.
        store.set(
            bindTarget, {'x': r.left, 'y': r.top, 'w': r.width, 'h': r.height});
      }
    });
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 2: ACTION (Interactive & Hardware Hardware Kinematics)
// ════════════════════════════════════════════════════════════════════════════

void _registerBoxAliases(QuantumVM vm) {
  vm.defineAlias('row', 'box:row',
      description: 'Row layout alias.', tags: const ['box', 'layout', 'alias']);
  vm.defineAlias('col', 'box:col',
      description: 'Column layout alias.',
      tags: const ['box', 'layout', 'alias']);
  vm.defineAlias('stack', 'box:stack',
      description: 'Stack layout alias.',
      tags: const ['box', 'layout', 'alias']);
  vm.defineAlias('wrap', 'box:wrap',
      description: 'Wrap layout alias.',
      tags: const ['box', 'layout', 'alias']);
  vm.defineAlias('grid', 'box:grid',
      description: 'Grid layout alias.',
      tags: const ['box', 'layout', 'alias']);
  vm.defineAlias('masonry', 'box:masonry',
      description: 'Masonry layout alias.',
      tags: const ['box', 'layout', 'alias']);
  vm.defineAlias(
    'card',
    'box:card',
    defaultProps: const <String, dynamic>{
      'fill': 'surface',
      'depth': 'raised',
      'padding': [24],
    },
    description: 'Card surface alias.',
    tags: const ['box', 'surface', 'alias'],
  );
  vm.defineAlias(
    'split',
    'box:split',
    defaultProps: const <String, dynamic>{'style': 'min-w-0 min-h-0'},
    description: 'Split layout alias.',
    tags: const ['box', 'layout', 'alias'],
  );
  vm.defineAlias('morph', 'box:morph',
      description: 'Morphing container alias.', tags: const ['box', 'alias']);
  vm.defineAlias('surface', 'box:surface',
      description: 'Surface container alias.',
      tags: const ['box', 'surface', 'alias']);
  vm.defineAlias('shell', 'box:shell',
      description: 'Shell container alias.',
      tags: const ['box', 'shell', 'alias']);
  vm.defineAlias('viewport', 'box:viewport',
      description: 'Viewport container alias.',
      tags: const ['box', 'viewport', 'alias']);
  vm.defineAlias('responsive', 'box:responsive',
      description: 'Responsive container alias.',
      tags: const ['box', 'responsive', 'alias']);
  vm.defineAlias('measure', 'box:measure',
      description: 'Layout measure alias.',
      tags: const ['box', 'measure', 'alias']);
  vm.defineAlias('builder', 'box:builder',
      description: 'Builder container alias.',
      tags: const ['box', 'builder', 'alias']);
  vm.defineAlias('layer', 'box:layer',
      description: 'Layer container alias.',
      tags: const ['box', 'layer', 'alias']);
  vm.defineAlias('matrix', 'box:matrix',
      description: 'Matrix layout alias.',
      tags: const ['box', 'matrix', 'alias']);
}
