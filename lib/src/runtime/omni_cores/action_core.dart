part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildAction

Widget _buildAction(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'button');

  // FIX: Declare 'disabled' early so all action variants can access it
  final bool disabled = ctx.boolean('disabled') || ctx.boolean('loading');

  // STANDARD ACTION LOGIC
  final groupSignal = QLDataScope.readNode(ctx.flutterContext)
      ?.localData['groupActiveSignal'] as QLSignal?;
  final bool isActive = groupSignal != null &&
      groupSignal.value?.toString() == ctx.string('value');
  final String resolvedFill = isActive ? 'solid' : ctx.fill;

  final String matrixStyle = QDesignMatrix.resolve(
    family: 'action',
    intent: ctx.intent,
    fill: resolvedFill,
    depth: ctx.depth,
    edge: ctx.edge,
    shape: ctx.shape,
    scale: ctx.scale,
    disabled: disabled,
  );

  void _safeCall(Function? fn) {
    if (fn == null) return;
    try {
      final res = fn();
      if (res is Future)
        res.catchError((e) {
          print('Async Action Error: $e');
        });
    } catch (e) {
      print('Action Error: $e');
    }
  }

  // 🚀 PRIMITIVE: action:gesture (Raw Multi-Touch without Widget Arena overhead)
  if (subType == 'gesture') {
    return _QLRawGestureNode(
      onPan: ctx.action('onPan') == null
          ? null
          : () => _safeCall(ctx.action('onPan')),
      onScale: ctx.action('onScale') == null
          ? null
          : () => _safeCall(ctx.action('onScale')),
      onTap: ctx.action('onTap') == null
          ? null
          : () => _safeCall(ctx.action('onTap')),
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 PRIMITIVE: action:viewport (Direct Matrix4.storage mutation)
  if (subType == 'viewport') {
    final String bind = ctx.string('matrixBind');
    final QLSignal<dynamic> matrixSig = ctx.store.signal(bind);

    return _QLViewportNode(
      matrixSignal: matrixSig,
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 HARDWARE KINEMATICS: action:raw_pointer / action:pointer
  // Native Listener bypasses Flutter's Gesture Arena completely. 120Hz O(1) Signal injection.
  if (subType == 'raw_pointer' || subType == 'pointer') {
    final String bindX = ctx.string('bindX');
    final String bindY = ctx.string('bindY');
    final String bindPressure = ctx.string('bindPressure');

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) =>
          _injectRawPointer(ctx, e, bindX, bindY, bindPressure),
      onPointerMove: (e) =>
          _injectRawPointer(ctx, e, bindX, bindY, bindPressure),
      onPointerUp: (e) {
        _injectRawPointer(ctx, e, bindX, bindY, bindPressure);
        _safeCall(ctx.action('onRelease'));
      },
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 HARDWARE KINEMATICS: action:focus
  // Captures raw keystrokes (Enter, Escape, D-Pad) and tracks exact hardware focus state natively.
  if (subType == 'focus') {
    final String bindState = ctx.string('bindState');
    return Focus(
      onFocusChange: (focused) {
        if (bindState.isNotEmpty) ctx.store.set(bindState, focused);
        if (focused)
          _safeCall(ctx.action('onFocus'));
        else
          _safeCall(ctx.action('onBlur'));
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          _safeCall(ctx.action('onKeyPress',
              localPayload: {'key': event.logicalKey.keyLabel}));
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _safeCall(ctx.action('onEnter'));
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  if (subType == 'long_press' ||
      subType == 'double_tap' ||
      subType == 'hover') {
    return MouseRegion(
      onEnter:
          subType == 'hover' ? (_) => _safeCall(ctx.action('onHover')) : null,
      onExit:
          subType == 'hover' ? (_) => _safeCall(ctx.action('onUnhover')) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: subType == 'long_press' && !disabled
            ? () => _safeCall(ctx.action('onLongPress'))
            : null,
        onDoubleTap: subType == 'double_tap' && !disabled
            ? () => _safeCall(ctx.action('onDoubleTap'))
            : null,
        child: Q(
          'flex-center $matrixStyle ${ctx.node.style ?? ''}',
          padding: ctx.list('padding'),
          margin: ctx.list('margin'),
          text: ctx.boolean('loading') ? null : ctx.string('text'),
          children: ctx.children,
        ),
      ),
    );
  }

  Widget node = QLSensor(
    onTap: disabled
        ? null
        : () {
            final String url = ctx.string('href');
            if (url.isNotEmpty) {
              _safeCall(ctx.action('onNavigate', localPayload: {'href': url}));
            }
            if (groupSignal != null && ctx.string('value').isNotEmpty) {
              groupSignal.value = ctx.string('value');
              final String bindPath = QLDataScope.readNode(ctx.flutterContext)
                      ?.localData['groupBindPath']
                      ?.toString() ??
                  '';
              if (bindPath.isNotEmpty)
                ctx.store.set(bindPath, ctx.string('value'));
            }
            _safeCall(ctx.action('onClick'));
          },
    scaleOnTap: !disabled,
    scaleOnHover: !disabled && subType != 'badge',
    child: Q(
      'flex-center $matrixStyle ${ctx.node.style ?? ''}',
      padding: ctx.list('padding'),
      margin: ctx.list('margin'),
      text: ctx.boolean('loading') ? null : ctx.string('text'),
      children: ctx.boolean('loading')
          ? [
              const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
            ]
          : [
              if (ctx.slot('icon') != null) ...[
                ctx.slot('icon')!,
                if (ctx.string('text').isNotEmpty) const SizedBox(width: 8)
              ],
              ...ctx.children
            ],
    ),
  );

  return _applyImplicitBehaviors(ctx, node);
}

void _injectRawPointer(QLContext ctx, PointerEvent e, String bindX,
    String bindY, String bindPressure) {
  if (bindX.isNotEmpty)
    ctx.store.signal(bindX)
      ..setSilent(e.localPosition.dx)
      ..forceNotify();
  if (bindY.isNotEmpty)
    ctx.store.signal(bindY)
      ..setSilent(e.localPosition.dy)
      ..forceNotify();
  if (bindPressure.isNotEmpty)
    ctx.store.signal(bindPressure)
      ..setSilent(e.pressure)
      ..forceNotify();
}

Widget _buildSmartScrollViewport({
  required Axis axis,
  required Widget child,
}) {
  return QuantumFlexible(
    fit: FlexFit.loose,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final bool boundedMain = axis == Axis.vertical
            ? constraints.maxHeight.isFinite
            : constraints.maxWidth.isFinite;
        final Size screen = MediaQuery.sizeOf(context);
        final double fallbackExtent =
            axis == Axis.vertical ? screen.height : screen.width;
        final BoxConstraints viewportConstraints = axis == Axis.vertical
            ? BoxConstraints(
                minHeight: boundedMain ? constraints.maxHeight : 0.0,
                maxHeight: boundedMain ? constraints.maxHeight : fallbackExtent,
              )
            : BoxConstraints(
                minWidth: boundedMain ? constraints.maxWidth : 0.0,
                maxWidth: boundedMain ? constraints.maxWidth : fallbackExtent,
              );

        return QuantumScrollScope(
          axis: axis,
          child: ClipRect(
            child: SingleChildScrollView(
              scrollDirection: axis,
              primary: false,
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: viewportConstraints,
                child: child,
              ),
            ),
          ),
        );
      },
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 3: FIELD (Headless UI Shells & Form Primitives)
// ════════════════════════════════════════════════════════════════════════════

// ── 3. RAW GESTURE NODE ──
class _QLRawGestureNode extends StatelessWidget {
  final VoidCallback? onPan, onScale, onTap;
  final Widget child;
  const _QLRawGestureNode(
      {this.onPan, this.onScale, this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      // 🚀 FIX: Translucent allows parent ScrollViews to receive the event simultaneously
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        if (onPan != null || onScale != null)
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(),
            (ScaleGestureRecognizer instance) {
              // 🚀 FIX: Only accept the gesture if it passes a threshold, allowing scroll to win otherwise
              instance.dragStartBehavior = DragStartBehavior.start;
              instance.onUpdate = (ScaleUpdateDetails d) {
                if (d.scale == 1.0)
                  onPan?.call();
                else
                  onScale?.call();
              };
            },
          ),
        if (onTap != null)
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
            () => TapGestureRecognizer(),
            (TapGestureRecognizer instance) => instance.onTap = onTap,
          ),
      },
      child: child,
    );
  }
}

// ── 2. ZERO-GC MATRIX VIEWPORT ENGINE ──
class _QLViewportNode extends StatefulWidget {
  final QLSignal<dynamic> matrixSignal;
  final Widget child;
  const _QLViewportNode({required this.matrixSignal, required this.child});
  @override
  State<_QLViewportNode> createState() => _QLViewportNodeState();
}

class _QLViewportNodeState extends State<_QLViewportNode> {
  late final Map<Type, GestureRecognizerFactory> _gestures;

  @override
  void initState() {
    super.initState();
    // RawGestureDetector bypasses the heavy Flutter Gesture Arena
    _gestures = {
      ScaleGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
        () => ScaleGestureRecognizer(),
        (instance) {
          instance.onUpdate = (details) {
            if (widget.matrixSignal.value is! Matrix4)
              widget.matrixSignal.setSilent(Matrix4.identity());
            final Matrix4 m = widget.matrixSignal.value;
            final s = m.storage;

            // Direct memory manipulation. Zero object allocations.
            s[12] += details.focalPointDelta.dx;
            s[13] += details.focalPointDelta.dy;

            if (details.scale != 1.0 || details.rotation != 0.0) {
              m.translate(
                  details.localFocalPoint.dx, details.localFocalPoint.dy);
              m.scale(details.scale, details.scale, 1.0);
              m.rotateZ(details.rotation);
              m.translate(
                  -details.localFocalPoint.dx, -details.localFocalPoint.dy);
            }
            widget.matrixSignal.forceNotify();
          };
        },
      )
    };
  }

  @override
  Widget build(BuildContext context) => RawGestureDetector(
      behavior: HitTestBehavior.opaque,
      gestures: _gestures,
      child: widget.child);
}

void _registerActionAliases(QuantumVM vm) {
  vm.defineAlias('raw_pointer', 'action:raw_pointer',
      description: 'Raw pointer action alias.',
      tags: const ['action', 'input', 'alias']);
  vm.defineAlias('pointer', 'action:pointer',
      description: 'Pointer action alias.',
      tags: const ['action', 'input', 'alias']);
  vm.defineAlias('focus', 'action:focus',
      description: 'Focus action alias.',
      tags: const ['action', 'input', 'alias']);
  vm.defineAlias('button', 'action:button',
      description: 'Button action alias.', tags: const ['action', 'alias']);
  vm.defineAlias('tap', 'action:button',
      description: 'Tap alias for button action.',
      tags: const ['action', 'alias']);
  vm.defineAlias('press', 'action:button',
      description: 'Press alias for button action.',
      tags: const ['action', 'alias']);
  vm.defineAlias('hover_action', 'action:hover',
      description: 'Hover action alias.', tags: const ['action', 'alias']);
  vm.defineAlias(
    'icon_button',
    'action:button',
    defaultProps: const <String, dynamic>{'shape': 'circle', 'fill': 'ghost'},
    description: 'Icon button alias.',
    tags: const ['action', 'alias'],
  );
  vm.defineAlias(
    'chip',
    'action:chip',
    defaultProps: const <String, dynamic>{
      'shape': 'pill',
      'scale': 'sm',
      'edge': 'hairline'
    },
    description: 'Chip action alias.',
    tags: const ['action', 'alias'],
  );
  vm.defineAlias(
    'badge',
    'action:badge',
    defaultProps: const <String, dynamic>{
      'shape': 'pill',
      'scale': 'xs',
      'disabled': true
    },
    description: 'Badge action alias.',
    tags: const ['action', 'alias'],
  );
}
