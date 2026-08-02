/*
 * ============================================================================
 * File: action_core.dart
 * 
 * Description:
 * Handles declarative resolution for UI action components within the Quantum 
 * framework, implementing handlers for interactive behaviors like focus, gestures, 
 * pointers, and viewport scaling.
 * 
 * Key Components:
 * - _buildAction: Main factory turning QLContext into functional, interactive widgets.
 * - _QLViewportNode / _QLRawGestureNode: Custom gesture recognizers to bypass 
 *   or intercept the Flutter gesture arena for advanced interaction.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Integrates deeply with QLDataScope and Q Engine.
 * 
 * Notes:
 * Implements primitive pointer logic mapped to application signals for state management.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildAction

// Moved from quantum_omni_registry.dart: _buildAction
Widget _buildAction(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'button');

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

  void safeCall(Function? fn) {
    if (fn == null) return;
    try {
      final res = fn();
      if (res is Future) {
        res.catchError((e) {
          debugPrint('Async Action Error: $e');
        });
      }
    } catch (e) {
      debugPrint('Action Error: $e');
    }
  }

  // 🚀 PRIMITIVE: action:gesture (Raw Multi-Touch)
  if (subType == 'gesture') {
    return _QLRawGestureNode(
      onPan: ctx.action('onPan') == null
          ? null
          : () => safeCall(ctx.action('onPan')),
      onScale: ctx.action('onScale') == null
          ? null
          : () => safeCall(ctx.action('onScale')),
      onTap: ctx.action('onTap') == null
          ? null
          : () => safeCall(ctx.action('onTap')),
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 PRIMITIVE: action:viewport
  if (subType == 'viewport') {
    final String bind = ctx.string('matrixBind');
    final QLSignal<dynamic> matrixSig = ctx.store.signal(bind);
    return _QLViewportNode(
      matrixSignal: matrixSig,
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 HARDWARE KINEMATICS: action:raw_pointer / action:pointer
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
        safeCall(ctx.action('onRelease'));
      },
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // 🚀 HARDWARE KINEMATICS: action:focus
  if (subType == 'focus') {
    final String bindState = ctx.string('bindState');
    return Focus(
      onFocusChange: (focused) {
        if (bindState.isNotEmpty) ctx.store.set(bindState, focused);
        if (focused) {
          safeCall(ctx.action('onFocus'));
        } else {
          safeCall(ctx.action('onBlur'));
        }
      },
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          safeCall(ctx.action('onKeyPress',
              localPayload: {'key': event.logicalKey.keyLabel}));
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            safeCall(ctx.action('onEnter'));
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Q('col min-w-0 min-h-0', children: ctx.children),
    );
  }

  // Check for both 'onClick' and 'onTap' keys from JSON
  final Function? clickAction =
      ctx.action('onClick') ?? ctx.action('onTap') ?? ctx.action('action');

  final VoidCallback? tapHandler = disabled
      ? null
      : () {
          final String url = ctx.string('href');
          if (url.isNotEmpty) {
            safeCall(ctx.action('onNavigate', localPayload: {'href': url}));
          }
          if (groupSignal != null && ctx.string('value').isNotEmpty) {
            groupSignal.value = ctx.string('value');
            final String bindPath = QLDataScope.readNode(ctx.flutterContext)
                    ?.localData['groupBindPath']
                    ?.toString() ??
                '';
            if (bindPath.isNotEmpty) {
              ctx.store.set(bindPath, ctx.string('value'));
            }
          }
          safeCall(clickAction);
        };

  // 🚀 FLATTENED BUTTON/HOVER LOGIC: Delegate entirely to Q Engine.
  String interactionStyles = '';
  if (!disabled &&
      (subType == 'button' || subType == 'icon_button' || subType == 'chip')) {
    interactionStyles =
        'interactive'; // Tells Q to inject scaling & pointer natively
  } else if (!disabled &&
      (subType == 'long_press' ||
          subType == 'double_tap' ||
          subType == 'hover')) {
    interactionStyles = 'hover'; // Basic hover, no scaling
  }

  Widget node = Q(
    'flex-center $matrixStyle $interactionStyles ${ctx.node.style ?? ''}',
    padding: ctx.list('padding'),
    margin: ctx.list('margin'),
    text: ctx.boolean('loading') ? null : ctx.string('text'),
    onTap: tapHandler, // 🚀 TAP PASSED DIRECTLY TO Q! No Gesture conflicts.
    suppressParentData: true,
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
  );

  return _applyImplicitBehaviors(ctx, node);
}

void _injectRawPointer(QLContext ctx, PointerEvent e, String bindX,
    String bindY, String bindPressure) {
  if (bindX.isNotEmpty) {
    ctx.store.signal(bindX)
      ..setSilent(e.localPosition.dx)
      ..forceNotify();
  }
  if (bindY.isNotEmpty) {
    ctx.store.signal(bindY)
      ..setSilent(e.localPosition.dy)
      ..forceNotify();
  }
  if (bindPressure.isNotEmpty) {
    ctx.store.signal(bindPressure)
      ..setSilent(e.pressure)
      ..forceNotify();
  }
}

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
                if (d.scale == 1.0) {
                  onPan?.call();
                } else {
                  onScale?.call();
                }
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
            if (widget.matrixSignal.value is! Matrix4) {
              widget.matrixSignal.setSilent(Matrix4.identity());
            }
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

class ActionCoreExporter implements QuantumCoreExporter {
  const ActionCoreExporter();
  
  @override
  void export(QuantumVM vm) {
    vm.define('action', _buildAction, tags: const ['core', 'action']);
    _registerActionAliases(vm);
  }
}
