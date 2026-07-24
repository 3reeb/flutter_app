part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildSystem

Widget _buildSystem(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'scope');

  // 🚀 PRIMITIVE: system:timer (Vsync-Aligned Ticker)
  if (subType == 'timer') {
    return _QLVsyncTimerNode(
      intervalMs: ctx.integer('interval', fallback: 1000),
      autoStart: ctx.boolean('autoStart', fallback: true),
      onTick: ctx.action('onTick'),
      child: Q('col w-full h-full', children: ctx.children),
    );
  }

  // 🚀 PRIMITIVE: system:data_pipe (Native Memory Shaping)
  if (subType == 'data_pipe') {
    final String bindOutput = ctx.string('bindOutput');
    final String bindSource = ctx.string('bindSource');
    final int size = ctx.integer('size', fallback: 50);
    if (bindOutput.isNotEmpty && ctx.store.get(bindOutput) == null) {
      ctx.store.set(bindOutput, Float64List(size));
    }

    return _QLDataPipeNode(
      mode: ctx.string('mode', fallback: 'ring_buffer'),
      store: ctx.store,
      outputPath: bindOutput,
      sourceSig: ctx.store.signal(bindSource),
      size: size,
      child: Q('col w-full h-full', children: ctx.children),
    );
  }

  // 🚀 PRIMITIVE: system:kinetic_pipe (RK4 Physics Interpolation)
  if (subType == 'kinetic_pipe') {
    return _QLKineticPipeNode(
      sourceSig: ctx.store.signal(ctx.string('bindSource')),
      outputSig: ctx.store.signal(ctx.string('bindOutput')),
      stiffness: ctx.number('stiffness', fallback: 300.0),
      damping: ctx.number('damping', fallback: 24.0),
      child: Q('col w-full h-full', children: ctx.children),
    );
  }
  // 🚀 THE OMEGA MACRO: system:omega_macro / system:macro
  // A god-tier context builder that completely isolates re-renders.
  // Useful for creating standalone widgets like a "Field Wrapper", "Workflow Node", etc.
  if (subType == 'omega_macro' || subType == 'macro') {
    final Map<String, dynamic> templateJson = ctx.map('template');
    final Map<String, dynamic> localProps = ctx.map('props');
    final QLBlueprint templateAst = QLBlueprint.fromJson(templateJson);

    return QLDataScope(
      localData: {
        ...ctx.env,
        'props': localProps, // Pushed securely down
        'slots': ctx.node.slots, // Injects named slots automatically
      },
      child: Builder(
          builder: (macroCtx) =>
              QuantumVM.instance.renderWidget(macroCtx, templateAst)),
    );
  }

  // 🚀 ISOLATE TELEMETRY: system:worker
  // Headless threaded task dispatcher.
  if (subType == 'worker') {
    final String pipelineRef = ctx.string('pipeline');
    final QLSignal<dynamic> outputSig =
        ctx.store.signal(ctx.string('outputBind'));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final taskSig = QuantumVM.instance.workerPool.submit(
          QLZeroCopyPipelineTask([ctx.string('task')]),
          ctx.store.get(pipelineRef));
      taskSig.data.addListener(() => outputSig.value = taskSig.data.value);
    });
    return const SizedBox.shrink();
  }

  // 🚀 VIEWPORT TELEMETRY: system:sync_scroll
  if (subType == 'sync_scroll') {
    final String bindX = ctx.string('bindX');
    final String bindY = ctx.string('bindY');
    final Axis axis = ctx.string('axis') == 'horizontal' ||
            ctx.string('direction') == 'horizontal'
        ? Axis.horizontal
        : Axis.vertical;

    return _buildSmartScrollViewport(
      axis: axis,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (bindX.isNotEmpty) {
            final sig = ctx.store.signal(bindX);
            sig.setSilent(n.metrics.pixels);
            sig.forceNotify();
          }
          if (bindY.isNotEmpty) {
            final sig = ctx.store.signal(bindY);
            sig.setSilent(n.metrics.pixels);
            sig.forceNotify(); // 0-allocation scroll spy!
          }
          return false;
        },
        child: Q('col w-full h-full', children: ctx.children),
      ),
    );
  }

  // 🚀 HARDWARE KINEMATICS: system:ticker
  if (subType == 'ticker') {
    return _QLTickerNode(
      onTick: (dt) =>
          ctx.action('onTick', localPayload: {'deltaTime': dt})?.call(),
      child: Q('col w-full h-full', children: ctx.children),
    );
  }

  if (subType == 'repeater') {
    final dynamic bindData = ctx.env[ctx.node.props['bind']] ?? ctx.store.get(ctx.string('bind'));
    
    // Safely cast or default to empty list to avoid unexpected single-item rendering for objects
    List<dynamic> data = [];
    if (bindData is Iterable) {
      data = bindData.toList();
    } else if (bindData is String && bindData.isNotEmpty) {
      data = bindData.split('');
    } else if (bindData != null) {
      data = []; // Not iterable, render nothing
    } else {
      // Try resolving as a list using context if it was explicitly a list literal
      final resolved = ctx.list('bind');
      if (resolved.isNotEmpty) data = resolved;
    }

    final String asKey = ctx.string('as', fallback: 'item');
    final String indexKey = ctx.string('indexAs', fallback: 'index');
    final QLBlueprint? template =
        ctx.node.slots['item'] ?? ctx.node.children.firstOrNull;

    if (template == null)
      return const Center(
          child: Text('Repeater missing template',
              style: TextStyle(color: Colors.red)));

    return Q(
      'col w-full',
      children: List.generate(
          data.length,
          (i) => QLDataScope(
              localData: {asKey: data[i], indexKey: i},
              child: Builder(
                  builder: (c) =>
                      QuantumVM.instance.renderWidget(c, template)))),
    );
  }

  if (subType == 'store_provider') {
    final Map<String, dynamic> initialState = ctx.map('initialState');
    for (final entry in initialState.entries)
      ctx.store.set(entry.key, entry.value);
    return Q('col w-full', children: ctx.children);
  }

  // ── system:async — Async task runner with status/data/error slots ──────────
  if (subType == 'async') {
    final String action = ctx.string('action');
    final Map<String, dynamic> params = ctx.map('params');
    return _QLSystemAsyncNode(action: action, params: params, env: ctx.env, slots: ctx.node.slots, children: ctx.children);
  }

  // ── system:throttle / system:debounce — Event rate limiters ───────────────
  if (subType == 'throttle' || subType == 'debounce') {
    final int ms = ctx.integer('ms', fallback: 200);
    return _QLSystemRateLimitNode(mode: subType, ms: ms, child: ctx.children.isNotEmpty ? ctx.children.first : const SizedBox.shrink());
  }

  // ── system:geo — Hardware Geolocation provider ─────────────────────────────
  if (subType == 'geo') {
    final String asKey = ctx.string('as', fallback: 'geo');
    return QLDataScope(
      localData: {...ctx.env, asKey: const {'lat': 0.0, 'lng': 0.0, 'altitude': 0.0, 'heading': 0.0}},
      child: Q('col w-full', children: ctx.children),
    );
  }

  // ── system:haptic — Haptic Feedback trigger ───────────────────────────────
  if (subType == 'haptic') {
    final String feedbackType = ctx.string('type', fallback: 'selection');
    if (feedbackType == 'light') HapticFeedback.lightImpact();
    else if (feedbackType == 'medium') HapticFeedback.mediumImpact();
    else if (feedbackType == 'heavy') HapticFeedback.heavyImpact();
    else if (feedbackType == 'vibrate') HapticFeedback.vibrate();
    else HapticFeedback.selectionClick();
    return Q('col w-full', children: ctx.children);
  }

  // ── system:clipboard — System Clipboard access ────────────────────────────
  if (subType == 'clipboard') {
    final String textToCopy = ctx.string('copy');
    if (textToCopy.isNotEmpty) Clipboard.setData(ClipboardData(text: textToCopy));
    return QLDataScope(
      localData: {
        ...ctx.env,
        r'$copyToClipboard': (String t) => Clipboard.setData(ClipboardData(text: t)),
        r'$readClipboard': () async => (await Clipboard.getData('text/plain'))?.text ?? '',
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  // ── system:upload / download ────────────────────────────────────────────────
  if (subType == 'upload' || subType == 'download') {
    return QLDataScope(
      localData: {
        ...ctx.env,
        r'$progress': 0.0,
        r'$status': 'idle',
        r'$start': () => print('$subType started'), // Hook to actual plugin
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  // ── system:notification ─────────────────────────────────────────────────────
  if (subType == 'notification') {
    // Headless schedule, or plugin hook
    return const SizedBox.shrink();
  }

  // ── system:share ────────────────────────────────────────────────────────────
  if (subType == 'share') {
    return QLDataScope(
      localData: {
        ...ctx.env,
        r'$share': (String text, String url) => print('Share: $text, $url'), // Hook to share plugin
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  // ── system:sensor ───────────────────────────────────────────────────────────
  if (subType == 'sensor') {
    return QLDataScope(
      localData: {
        ...ctx.env,
        ctx.string('as', fallback: 'sensor'): const {'x': 0.0, 'y': 0.0, 'z': 0.0},
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  return Q('col w-full', children: ctx.children);
}

// ─────────────────────────────────────────────────────────────────────────────
// System Async Node
// ─────────────────────────────────────────────────────────────────────────────
class _QLSystemAsyncNode extends StatefulWidget {
  final String action;
  final Map<String, dynamic> params, env;
  final Map<String, QLBlueprint> slots;
  final List<Widget> children;
  const _QLSystemAsyncNode({required this.action, required this.params, required this.env, required this.slots, required this.children});
  @override State<_QLSystemAsyncNode> createState() => _QLSystemAsyncNodeState();
}
class _QLSystemAsyncNodeState extends State<_QLSystemAsyncNode> {
  bool _loading = true; dynamic _data; Object? _error;
  @override
  void initState() {
    super.initState();
    _run();
  }
  void _run() async {
    try {
      await QuantumVM.instance.triggerActions([{'action': widget.action, ...widget.params}], context, env: widget.env);
      if (mounted) setState(() { _loading = false; _data = true; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e; });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_loading && widget.slots['loading'] != null) {
      return QuantumVM.instance.renderWidget(context, widget.slots['loading']!);
    }
    if (_error != null && widget.slots['error'] != null) {
      return QLDataScope(localData: {...widget.env, r'$error': _error}, child: QuantumVM.instance.renderWidget(context, widget.slots['error']!));
    }
    if (_data != null && widget.slots['data'] != null) {
      return QLDataScope(localData: {...widget.env, r'$data': _data}, child: QuantumVM.instance.renderWidget(context, widget.slots['data']!));
    }
    return QLDataScope(
      localData: {...widget.env, r'$loading': _loading, r'$data': _data, r'$error': _error},
      child: Q('col w-full', children: widget.children),
    );
  }
}

// System Rate Limit Node (Throttle / Debounce)
class _QLSystemRateLimitNode extends StatefulWidget {
  final String mode; final int ms; final Widget child;
  const _QLSystemRateLimitNode({required this.mode, required this.ms, required this.child});
  @override State<_QLSystemRateLimitNode> createState() => _QLSystemRateLimitNodeState();
}
class _QLSystemRateLimitNodeState extends State<_QLSystemRateLimitNode> {
  Timer? _timer;
  @override void dispose() { _timer?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) => widget.child;
}

// ── 7. SYSTEM LIFECYCLE & VSYNC TIMERS ──
class _QLLifecycleNode extends StatefulWidget {
  // ignore: unused_element_parameter
  final VoidCallback? onMount, onUnmount;
  final Widget child;
  const _QLLifecycleNode({this.onMount, this.onUnmount, required this.child});
  @override
  State<_QLLifecycleNode> createState() => _QLLifecycleNodeState();
}

class _QLLifecycleNodeState extends State<_QLLifecycleNode> {
  @override
  void initState() {
    super.initState();
    if (widget.onMount != null)
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onMount!());
  }

  @override
  void dispose() {
    widget.onUnmount?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _QLVsyncTimerNode extends StatefulWidget {
  final int intervalMs;
  final bool autoStart;
  final VoidCallback? onTick;
  final Widget child;
  const _QLVsyncTimerNode(
      {required this.intervalMs,
      required this.autoStart,
      this.onTick,
      required this.child});
  @override
  State<_QLVsyncTimerNode> createState() => _QLVsyncTimerNodeState();
}

class _QLVsyncTimerNodeState extends State<_QLVsyncTimerNode>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _lastMs = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      if (d.inMilliseconds - _lastMs >= widget.intervalMs) {
        _lastMs = d.inMilliseconds;
        widget.onTick?.call();
      }
    });
    if (widget.autoStart && widget.intervalMs > 0) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── 8. NATIVE MEMORY SHAPING (DATA PIPE) ──
class _QLDataPipeNode extends StatefulWidget {
  final String mode;
  final QLDataStore store;
  final String outputPath;
  final QLSignal<dynamic> sourceSig;
  final int size;
  final Widget child;
  const _QLDataPipeNode({
    required this.mode,
    required this.store,
    required this.outputPath,
    required this.sourceSig,
    required this.size,
    required this.child,
  });
  @override
  State<_QLDataPipeNode> createState() => _QLDataPipeNodeState();
}

class _QLDataPipeNodeState extends State<_QLDataPipeNode> {
  late Float64List _buffer;

  @override
  void initState() {
    super.initState();
    _buffer = Float64List(widget.size);
    widget.sourceSig.addListener(_process);
    _process();
  }

  @override
  void didUpdateWidget(covariant _QLDataPipeNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sourceSig != widget.sourceSig) {
      oldWidget.sourceSig.removeListener(_process);
      widget.sourceSig.addListener(_process);
    }
    if (oldWidget.size != widget.size) {
      _buffer = Float64List(widget.size);
      _process();
    }
  }

  void _process() {
    if (widget.size <= 0) return;
    final double val = (widget.sourceSig.value as num?)?.toDouble() ?? 0.0;
    if (widget.mode == 'ring_buffer') {
      for (int i = 0; i < widget.size - 1; i++) {
        _buffer[i] = _buffer[i + 1];
      }
      _buffer[widget.size - 1] = val;
    } else if (widget.mode == 'accumulate') {
      _buffer[0] += val;
    }
    if (widget.outputPath.isNotEmpty) {
      widget.store.set(widget.outputPath, _buffer);
    }
  }

  @override
  void dispose() {
    widget.sourceSig.removeListener(_process);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// ── 9. KINETIC PHYSICS ENGINE (RK4) ──
class _QLKineticPipeNode extends StatefulWidget {
  final QLSignal<dynamic> sourceSig;
  final QLSignal<dynamic> outputSig;
  final double stiffness, damping;
  final Widget child;
  const _QLKineticPipeNode(
      {required this.sourceSig,
      required this.outputSig,
      required this.stiffness,
      required this.damping,
      required this.child});
  @override
  State<_QLKineticPipeNode> createState() => _QLKineticPipeNodeState();
}

class _QLKineticPipeNodeState extends State<_QLKineticPipeNode>
    with SingleTickerProviderStateMixin {
  late final QLIntegratorRK4 _rk4;
  late final Ticker _ticker;
  double _target = 0.0;
  int _lastTickMs = 0;

  @override
  void initState() {
    super.initState();
    _rk4 = QLIntegratorRK4(2);
    _ticker = createTicker(_tick);
    widget.sourceSig.addListener(_onSourceUpdate);
  }

  void _onSourceUpdate() {
    _target = (widget.sourceSig.value as num?)?.toDouble() ?? 0.0;
    _lastTickMs = 0;
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    final int newTick =
        QLPhysicsTicker.step(elapsed, _lastTickMs, _rk4, (state, derivs) {
      derivs[0] = state[1];
      derivs[1] =
          widget.stiffness * (_target - state[0]) - widget.damping * state[1];
    });
    if (newTick == -1) return;
    _lastTickMs = newTick;

    widget.outputSig.setSilent(_rk4.state[0]);
    widget.outputSig.forceNotify();

    if ((_rk4.state[0] - _target).abs() < 0.01 && _rk4.state[1].abs() < 0.1) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    widget.sourceSig.removeListener(_onSourceUpdate);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void _registerSystemAliases(QuantumVM vm) {
  vm.defineAlias('sync_scroll', 'system:sync_scroll', description: 'Sync scroll alias.', tags: const ['system', 'alias']);
  vm.defineAlias('worker', 'system:worker', description: 'Worker alias.', tags: const ['system', 'alias']);
  vm.defineAlias('ticker', 'system:ticker', description: 'Ticker alias.', tags: const ['system', 'alias']);
  vm.defineAlias('omega_macro', 'system:omega_macro', description: 'Omega macro alias.', tags: const ['system', 'alias']);
}
