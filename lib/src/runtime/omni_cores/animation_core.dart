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

void _registerAnimationAliases(QuantumVM vm) {
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
}

// Stagger node — staggers each child's entrance animation
class _QLStaggerNode extends StatefulWidget {
  final List<Widget> children;
  final int delayMs;
  final Duration duration;
  final Curve curve;
  const _QLStaggerNode(
      {required this.children,
      required this.delayMs,
      required this.duration,
      required this.curve});
  @override
  State<_QLStaggerNode> createState() => _QLStaggerNodeState();
}

class _QLStaggerNodeState extends State<_QLStaggerNode>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctrls;
  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(widget.children.length,
        (i) => AnimationController(duration: widget.duration, vsync: this));
    for (var i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: widget.delayMs * i), () {
        if (mounted) _ctrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(widget.children.length, (i) {
          final anim = CurvedAnimation(parent: _ctrls[i], curve: widget.curve);
          return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.12), end: Offset.zero)
                      .animate(anim),
                  child: widget.children[i]));
        }));
  }
}

// Skeleton bar widget
class _QLSkeletonWidget extends StatefulWidget {
  final double width, height, borderRadius;
  const _QLSkeletonWidget(
      {required this.width, required this.height, required this.borderRadius});
  @override
  State<_QLSkeletonWidget> createState() => _QLSkeletonWidgetState();
}

class _QLSkeletonWidgetState extends State<_QLSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this)
      ..repeat();
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
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: const [
              Color(0xFFE0E0E0),
              Color(0xFFF5F5F5),
              Color(0xFFE0E0E0)
            ],
            stops: [0.0, (_ctrl.value * 1.5).clamp(0.0, 1.0), 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
      ),
    );
  }
}

class _QLKeyframeNode extends StatefulWidget {
  final Map from, to;
  final Duration duration;
  final Curve curve;
  final Widget child;
  const _QLKeyframeNode(
      {required this.from,
      required this.to,
      required this.duration,
      required this.curve,
      required this.child});
  @override
  State<_QLKeyframeNode> createState() => _QLKeyframeNodeState();
}

class _QLKeyframeNodeState extends State<_QLKeyframeNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: widget.duration, vsync: this)..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final double t = widget.curve.transform(_c.value);
        final double dx = (widget.from['x'] ?? 0.0) +
            ((widget.to['x'] ?? 0.0) - (widget.from['x'] ?? 0.0)) * t;
        final double dy = (widget.from['y'] ?? 0.0) +
            ((widget.to['y'] ?? 0.0) - (widget.from['y'] ?? 0.0)) * t;
        final double s = (widget.from['scale'] ?? 1.0) +
            ((widget.to['scale'] ?? 1.0) - (widget.from['scale'] ?? 1.0)) * t;
        final double o = (widget.from['opacity'] ?? 1.0) +
            ((widget.to['opacity'] ?? 1.0) - (widget.from['opacity'] ?? 1.0)) *
                t;
        return Opacity(
            opacity: o.clamp(0.0, 1.0),
            child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(scale: s, child: child)));
      },
      child: widget.child,
    );
  }
}

class _QLSequenceNode extends StatefulWidget {
  final List<Map> steps;
  final Widget child;
  const _QLSequenceNode({required this.steps, required this.child});
  @override
  State<_QLSequenceNode> createState() => _QLSequenceNodeState();
}

class _QLSequenceNodeState extends State<_QLSequenceNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..forward();
    if (widget.steps.isEmpty) {
      _anim = Tween<double>(begin: 1, end: 1).animate(_c);
    } else {
      final List<TweenSequenceItem<double>> items = [];
      for (final s in widget.steps) {
        items.add(TweenSequenceItem(
            tween: Tween<double>(
                begin: (s['from'] ?? 0.0).toDouble(),
                end: (s['to'] ?? 1.0).toDouble()),
            weight: (s['weight'] ?? 1.0).toDouble()));
      }
      _anim = TweenSequence<double>(items).animate(_c);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _anim, child: widget.child);
}

class _QLParticleNode extends StatefulWidget {
  final int count;
  final Color color;
  final Widget child;
  const _QLParticleNode(
      {required this.count, required this.color, required this.child});
  @override
  State<_QLParticleNode> createState() => _QLParticleNodeState();
}

class _QLParticleNodeState extends State<_QLParticleNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  final List<Offset> _p = [];
  @override
  void initState() {
    super.initState();
    _c = AnimationController(duration: const Duration(seconds: 2), vsync: this)
      ..repeat();
    for (int i = 0; i < widget.count; i++) {
      _p.add(Offset((math.Random().nextDouble() - 0.5) * 200,
          (math.Random().nextDouble() - 0.5) * 200));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
            child: AnimatedBuilder(
                animation: _c,
                builder: (_, __) => CustomPaint(
                    painter: _ParticlePainter(_p, _c.value, widget.color)))),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double progress;
  final Color color;
  _ParticlePainter(this.particles, this.progress, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0, 1));
    for (final p in particles) {
      canvas.drawCircle(
          Offset(size.width / 2 + p.dx * progress,
              size.height / 2 + p.dy * progress),
          3.0,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

class AnimationCoreExporter implements QuantumCoreExporter {
  const AnimationCoreExporter();
  
  @override
  void export(QuantumVM vm) {
    vm.define('animation', _buildAnimation, tags: const ['core', 'animation']);
    _registerAnimationAliases(vm);
  }
}
