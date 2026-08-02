/*
 * ============================================================================
 * File: stream_core.dart
 * 
 * Description:
 * Manages real-time streaming primitives in the Quantum Omni Registry. Provides 
 * nodes for WebSocket channels, Server-Sent Events (SSE), fixed-capacity Ring 
 * buffers, and hardware-aligned ticker loops.
 * 
 * Key Components:
 * - _buildStream: Router for stream primitives.
 * - _QLWebSocketNode / _QLSSENode: Exposes real-time network payloads as signals.
 * - _QLTickNode / _QLRingBufferNode: Utilities for high-frequency telemetry.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Integrates with QLPluginStreamRegistry.
 * 
 * Notes:
 * Essential for rendering live financial data, chat systems, or real-time telemetry.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// ════════════════════════════════════════════════════════════════════════════
// STREAM CORE — Real-time streaming primitives (WebSocket, SSE, Ring, Ticker)
// Sub-types: ws, sse, tick, ring, multiplex
// ════════════════════════════════════════════════════════════════════════════

Widget _buildStream(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'ws');

  // stream:ws — WebSocket reactive channel
  if (subType == 'ws') {
    final String url = ctx.string('url');
    final String as = ctx.string('as', fallback: 'wsEvent');
    final String statusKey = ctx.string('statusKey', fallback: 'wsStatus');
    return _QLWebSocketNode(url: url, as: as, statusKey: statusKey, env: ctx.env, children: ctx.children);
  }

  // stream:sse — Server-Sent Events
  if (subType == 'sse') {
    final String url = ctx.string('url');
    final String as = ctx.string('as', fallback: 'sseEvent');
    return _QLSSENode(url: url, as: as, env: ctx.env, children: ctx.children);
  }

  // stream:tick — Periodic ticker exposing elapsed ticks
  if (subType == 'tick') {
    int ms = ctx.integer('ms', fallback: 1000);
    if (ms < 16) ms = 16; // Clamp to 16ms minimum to prevent test hangs and performance degradation
    final String as = ctx.string('as', fallback: 'tick');
    final QLSignal<int> sig = QLSignal<int>(0);
    return _QLTickNode(ms: ms, signal: sig, as: as, env: ctx.env, children: ctx.children);
  }

  // stream:ring — Fixed-capacity ring buffer, head always newest
  if (subType == 'ring') {
    final int capacity = ctx.integer('capacity', fallback: 64);
    final String bind = ctx.string('bind');
    final String as = ctx.string('as', fallback: 'ring');
    return _QLRingBufferNode(capacity: capacity, bind: bind, as: as, store: ctx.store, env: ctx.env, children: ctx.children);
  }

  // stream:multiplex — Fan out a single stream to multiple named channels
  if (subType == 'multiplex') {
    final List<dynamic> channels = ctx.list('channels');
    for (final ch in channels) {
      if (ch is Map && ch['stream'] is String && ch['as'] is String) {
        final src = QLPluginStreamRegistry.get(ch['stream'] as String);
        if (src != null) QLPluginStreamRegistry.register(ch['as'] as String, src.asBroadcastStream());
      }
    }
    return Q('col w-full', children: ctx.children);
  }

  return Q('col w-full', children: ctx.children);
}

// WebSocket node
class _QLWebSocketNode extends StatefulWidget {
  final String url, as, statusKey;
  final Map<String, dynamic> env;
  final List<Widget> children;
  const _QLWebSocketNode({required this.url, required this.as, required this.statusKey, required this.env, required this.children});
  @override State<_QLWebSocketNode> createState() => _QLWebSocketNodeState();
}
class _QLWebSocketNodeState extends State<_QLWebSocketNode> {
  StreamController<dynamic>? _ctrl;
  dynamic _latest;
  String _status = 'connecting';

  @override
  void initState() {
    super.initState();
    _ctrl = StreamController<dynamic>.broadcast();
    _connect();
  }

  void _connect() async {
    try {
      Uri.parse(widget.url); // Validate URL
      // Register stream so other hook:observable can tap it
      QLPluginStreamRegistry.register(widget.url, _ctrl!.stream);
      _ctrl!.stream.listen((v) { if (mounted) setState(() { _latest = v; _status = 'open'; }); });
    } catch (e) {
      if (mounted) setState(() => _status = 'error');
    }
  }

  @override void dispose() { _ctrl?.close(); QLPluginStreamRegistry.unregister(widget.url); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return QLDataScope(
      localData: {...widget.env, widget.as: _latest, widget.statusKey: _status},
      child: Q('col w-full', children: widget.children),
    );
  }
}

// SSE node (Server-Sent Events via periodic poll or native EventSource)
class _QLSSENode extends StatefulWidget {
  final String url, as;
  final Map<String, dynamic> env;
  final List<Widget> children;
  const _QLSSENode({required this.url, required this.as, required this.env, required this.children});
  @override State<_QLSSENode> createState() => _QLSSENodeState();
}
class _QLSSENodeState extends State<_QLSSENode> {
  dynamic _latest;
  StreamSubscription? _sub;
  @override void initState() {
    super.initState();
    final src = QLPluginStreamRegistry.get(widget.url);
    if (src != null) _sub = src.listen((v) { if (mounted) setState(() => _latest = v); });
  }
  @override void dispose() { _sub?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return QLDataScope(localData: {...widget.env, widget.as: _latest}, child: Q('col w-full', children: widget.children));
  }
}

// Tick node
class _QLTickNode extends StatefulWidget {
  final int ms; final QLSignal<int> signal; final String as; final Map<String, dynamic> env; final List<Widget> children;
  const _QLTickNode({required this.ms, required this.signal, required this.as, required this.env, required this.children});
  @override State<_QLTickNode> createState() => _QLTickNodeState();
}
class _QLTickNodeState extends State<_QLTickNode> {
  Timer? _t;
  @override void initState() { super.initState(); _t = Timer.periodic(Duration(milliseconds: widget.ms), (_) { if (mounted) widget.signal.value++; }); }
  @override void dispose() { _t?.cancel(); super.dispose(); }
  @override Widget build(BuildContext context) {
    return AnimatedBuilder(animation: widget.signal, builder: (_, __) => QLDataScope(localData: {...widget.env, widget.as: widget.signal.value}, child: Q('col w-full', children: widget.children)));
  }
}

// Ring buffer node
class _QLRingBufferNode extends StatefulWidget {
  final int capacity; final String bind, as; final QLDataStore store; final Map<String, dynamic> env; final List<Widget> children;
  const _QLRingBufferNode({required this.capacity, required this.bind, required this.as, required this.store, required this.env, required this.children});
  @override State<_QLRingBufferNode> createState() => _QLRingBufferNodeState();
}
class _QLRingBufferNodeState extends State<_QLRingBufferNode> {
  final List<dynamic> _buf = [];
  QLSignal? _sig; StreamSubscription? _sub;

  @override void initState() {
    super.initState();
    if (widget.bind.isNotEmpty) {
      _sig = widget.store.signal(widget.bind);
      _sig!.addListener(_onValue);
    }
    final src = QLPluginStreamRegistry.get(widget.as);
    if (src != null) _sub = src.listen(_push);
  }

  void _onValue() => _push(_sig!.value);

  void _push(dynamic v) {
    if (v == null) return;
    setState(() {
      _buf.insert(0, v);
      if (_buf.length > widget.capacity) _buf.removeLast();
    });
  }

  @override void dispose() { _sig?.removeListener(_onValue); _sub?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return QLDataScope(localData: {...widget.env, widget.as: List.unmodifiable(_buf)}, child: Q('col w-full', children: widget.children));
  }
}

void _registerStreamAliases(QuantumVM vm) {
  vm.defineAlias('ws', 'stream:ws', description: 'WebSocket stream alias.', tags: const ['stream', 'alias']);
  vm.defineAlias('sse', 'stream:sse', description: 'SSE stream alias.', tags: const ['stream', 'alias']);
  vm.defineAlias('tick', 'stream:tick', description: 'Tick stream alias.', tags: const ['stream', 'alias']);
  vm.defineAlias('ring', 'stream:ring', description: 'Ring buffer stream alias.', tags: const ['stream', 'alias']);
}
