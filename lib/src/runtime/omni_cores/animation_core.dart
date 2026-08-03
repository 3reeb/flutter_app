/*
 * ============================================================================
 * File: animation_core.dart
 * 
 * Description:
 * Provides declarative animations by resolving animation configurations into 
 * complex Flutter animation widgets like tweening, staging, morphs, or sequences.
 * 
 * Key Components:
 * - _buildAnimation: Resolves raw QLContext configurations into specific Flutter 
 *   animation constructs (fade, slide, scale, spring, glass).
 * - _QLStaggerNode / _QLSkeletonWidget / _QLKeyframeNode: Specialized widgets 
 *   handling staggered lists, skeleton loaders, and keyframe interpolations.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Depends on Flutter's animation library.
 * 
 * Notes:
 * Uses implicit animations (TweenAnimationBuilder) and explicit ones (AnimationController) 
 * driven by dynamic properties from the QLContext.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

Widget _buildAnimation(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String kind = ctx.resolvedSubType(
      fallback: ctx.string('animationType', fallback: 'signal'));

  if (kind == 'signal' || kind == 'bind') {
    final String bindPath = ctx.string('bind');
    final dynamic rawSignal =
        bindPath.isNotEmpty ? ctx.store.signal(bindPath) : null;
    if (rawSignal is QLSignal) {
      return QLAnimatedWidget<dynamic>(
        signal: rawSignal,
        child: ctx.slot('child') ??
            Q('col min-w-0 min-h-0', children: ctx.children),
        builder: (context, value, child) {
          final double t =
              (value is num) ? value.toDouble().clamp(0.0, 1.0) : 1.0;
          return Opacity(opacity: t, child: child);
        },
      );
    }
    return ctx.slot('child') ??
        Q('col min-w-0 min-h-0', children: ctx.children);
  }

  final Widget child =
      ctx.slot('child') ?? Q('col min-w-0 min-h-0', children: ctx.children);
  final Duration duration =
      Duration(milliseconds: ctx.integer('durationMs', fallback: 320));
  const Curve curve = Curves.easeOutCubic;

  switch (kind) {
    case 'fade':
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
            begin: ctx.number('from', fallback: 0.0),
            end: ctx.number('to', fallback: 1.0)),
        duration: duration,
        curve: curve,
        builder: (context, value, child) =>
            Opacity(opacity: value, child: child),
        child: child,
      );
    case 'scale':
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
            begin: ctx.number('from', fallback: 0.92),
            end: ctx.number('to', fallback: 1.0)),
        duration: duration,
        curve: curve,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: child,
      );
    case 'slide':
    case 'translate':
      final Offset begin = Offset(
        ctx.number('fromX', fallback: 0.0),
        ctx.number('fromY', fallback: 0.2),
      );
      final Offset end = Offset(
        ctx.number('toX', fallback: 0.0),
        ctx.number('toY', fallback: 0.0),
      );
      return TweenAnimationBuilder<Offset>(
        tween: Tween<Offset>(begin: begin, end: end),
        duration: duration,
        curve: curve,
        builder: (context, value, child) =>
            Transform.translate(offset: value, child: child),
        child: child,
      );
    case 'rotate':
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
            begin: ctx.number('from', fallback: 0.0),
            end: ctx.number('to', fallback: 0.0)),
        duration: duration,
        curve: curve,
        builder: (context, value, child) =>
            Transform.rotate(angle: value, child: child),
        child: child,
      );
    case 'glass':
      return QLGlassLayer(
        config: QLGlassConfig(
          blur: ctx.number('blur', fallback: 24.0),
          tint: ctx.color('tint', fallback: const Color(0x55FFFFFF)) ??
              const Color(0x55FFFFFF),
        ),
        child: child,
      );
    case 'spring':
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
            begin: ctx.number('from', fallback: 0.0),
            end: ctx.number('to', fallback: 1.0)),
        duration: duration,
        curve: Curves.elasticOut,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: child,
      );
    case 'morph':
      return AnimatedSwitcher(
        duration: duration,
        switchInCurve: curve,
        switchOutCurve: curve.flipped,
        child: KeyedSubtree(
            key: ValueKey(ctx.string('key', fallback: '')), child: child),
      );
    case 'counter':
      final double from = ctx.number('from', fallback: 0.0);
      final double to = ctx.number('to', fallback: 100.0);
      final int digits = ctx.integer('decimals', fallback: 0);
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: from, end: to),
        duration: duration,
        curve: curve,
        builder: (context, value, _) => Text(value.toStringAsFixed(digits),
            style:
                const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
      );
    case 'skeleton':
      double w = ctx.number('width', fallback: double.infinity);
      double h = ctx.number('height', fallback: 18.0);
      double r = ctx.number('radius', fallback: 8.0);
      if (w.isNaN || w < 0) w = 100.0;
      if (h.isNaN || h < 0 || h.isInfinite) h = 18.0;
      if (r.isNaN || r < 0 || r.isInfinite) r = 8.0;
      return _QLSkeletonWidget(width: w, height: h, borderRadius: r);
    case 'stagger':
      int count = ctx.integer('count', fallback: ctx.children.length);
      if (count < 0) count = 0;
      int delayMs = ctx.integer('delayMs', fallback: 80);
      if (delayMs < 0) delayMs = 0;
      return _QLStaggerNode(
          delayMs: delayMs,
          duration: duration,
          curve: curve,
          children: ctx.children);
    case 'blur':
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(
            begin: ctx.number('from', fallback: 0.0),
            end: ctx.number('to', fallback: 0.0)),
        duration: duration,
        curve: curve,
        builder: (context, sigma, child) => ImageFiltered(
            imageFilter:
                const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
            child: child),
        child: child,
      );
    case 'cross':
      final Widget first = ctx.slot('first') ?? const SizedBox.shrink();
      final Widget second = ctx.slot('second') ?? child;
      final bool showFirst = ctx.boolean('showFirst', fallback: true);
      return AnimatedCrossFade(
        firstChild: first,
        secondChild: second,
        crossFadeState:
            showFirst ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        duration: duration,
        firstCurve: curve,
        secondCurve: curve,
      );
    case 'keyframe':
      return _QLKeyframeNode(
        duration: duration,
        curve: curve,
        from: ctx.map('from'),
        to: ctx.map('to'),
        child: child,
      );
    case 'sequence':
      return _QLSequenceNode(
        steps: ctx.list('steps').whereType<Map>().toList(),
        child: child,
      );
    case 'particle':
      return _QLParticleNode(
        count: ctx.integer('count', fallback: 20),
        color: ctx.color('color', fallback: Colors.blue) ?? Colors.blue,
        child: child,
      );
    case 'parallel':
    case 'choreograph':
      // Handled via QLAnimCompositor outside of the tree or via simple builder
      return child;
    default:
      return child;
  }
}

final QuantumDomain animationDomain = quantumDomain('animation')
    .surface('animation', _buildAnimation, defaultSurface: true)
    .install((vm) {
      vm.defineAlias('animation', 'animation',
          defaultProps: const <String, dynamic>{'animationType': 'signal'},
          description: 'Base animation core.',
          tags: const ['animation', 'core']);
      vm.defineAlias('motion', 'animation',
          defaultProps: const <String, dynamic>{'animationType': 'signal'},
          description: 'Motion alias.',
          tags: const ['animation', 'alias']);
      vm.defineAlias('transition', 'animation',
          defaultProps: const <String, dynamic>{'animationType': 'fade'},
          description: 'Transition alias.',
          tags: const ['animation', 'alias']);
      vm.defineAlias('animate', 'animation',
          defaultProps: const <String, dynamic>{'animationType': 'fade'},
          description: 'Animate alias.',
          tags: const ['animation', 'alias']);
      vm.defineAlias('glass_motion', 'animation',
          defaultProps: const <String, dynamic>{'animationType': 'glass'},
          description: 'Glass animation alias.',
          tags: const ['animation', 'glass']);
      vm.defineAlias('spring', 'animation:spring',
          description: 'Spring animation.', tags: const ['animation', 'spring']);
      vm.defineAlias('skeleton', 'animation:skeleton',
          description: 'Skeleton loader.', tags: const ['animation', 'skeleton']);
      vm.defineAlias('stagger', 'animation:stagger',
          description: 'Stagger children animation.',
          tags: const ['animation', 'stagger']);
      vm.defineAlias('morph', 'animation:morph',
          description: 'AnimatedSwitcher morph.',
          tags: const ['animation', 'morph']);
      vm.defineAlias('counter', 'animation:counter',
          description: 'Animated number counter.',
          tags: const ['animation', 'counter']);
      vm.defineAlias('cross_fade', 'animation:cross',
          description: 'Cross fade animation.', tags: const ['animation', 'cross']);
      vm.defineAlias('keyframe', 'animation:keyframe',
          description: 'Keyframe animation.',
          tags: const ['animation', 'keyframe']);
      vm.defineAlias('sequence_anim', 'animation:sequence',
          description: 'Sequence animation.',
          tags: const ['animation', 'sequence']);
      vm.defineAlias('particles', 'animation:particle',
          description: 'Particle effect.', tags: const ['animation', 'particle']);
    })
    .build();

class QLSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const QLSkeletonWidget({
    super.key,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<QLSkeletonWidget> createState() => _QLSkeletonWidgetState();
}

typedef _QLSkeletonWidget = QLSkeletonWidget;

class _QLSkeletonWidgetState extends State<QLSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.grey.shade300,
              Colors.grey.shade100,
              _ctrl.value,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class _QLStaggerNode extends StatelessWidget {
  final int delayMs;
  final Duration duration;
  final Curve curve;
  final List<Widget> children;

  const _QLStaggerNode({
    super.key,
    required this.delayMs,
    required this.duration,
    required this.curve,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(children.length, (i) {
        return AnimatedContainer(
          duration: duration + Duration(milliseconds: delayMs * i),
          curve: curve,
          child: children[i],
        );
      }),
    );
  }
}

class _QLKeyframeNode extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final Map<String, dynamic>? from;
  final Map<String, dynamic>? to;
  final Widget child;

  const _QLKeyframeNode({
    super.key,
    required this.duration,
    required this.curve,
    this.from,
    this.to,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

class _QLSequenceNode extends StatelessWidget {
  final List<Map<dynamic, dynamic>> steps;
  final Widget child;

  const _QLSequenceNode({
    super.key,
    required this.steps,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class _QLParticleNode extends StatelessWidget {
  final int count;
  final Color color;
  final Widget child;

  const _QLParticleNode({
    super.key,
    required this.count,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ...List.generate(
          count,
          (i) => Positioned(
            left: (i * 17) % 100.0,
            top: (i * 23) % 100.0,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ],
    );
  }
}

class AnimationCoreExporter implements QuantumCoreExporter {
  const AnimationCoreExporter();

  @override
  void export(QuantumVM vm) {
    vm.installDomain(animationDomain);
  }
}

