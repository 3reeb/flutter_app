/*
 * ============================================================================
 * File: hook_core.dart
 * 
 * Description:
 * Implements React-style lifecycle and state management hooks for the Quantum 
 * Omni Registry, enabling logic embedding directly within JSON blueprints.
 * 
 * Key Components:
 * - _buildHook: Routes various hooks (effect, memo, scope, atom, slice, error_boundary).
 * - _QLHookEffectNode / _QLHookLifecycleNode: Handle component mounting and side effects.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart.
 * 
 * Notes:
 * Dependency signatures are deeply evaluated to prevent unnecessary effect triggers.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

String _hookSignature(dynamic value) {
  if (value == null) return 'null';
  if (value is String || value is num || value is bool) return value.toString();
  if (value is DateTime) return value.millisecondsSinceEpoch.toString();
  if (value is List) {
    final StringBuffer b = StringBuffer('[');
    for (final item in value) {
      b
        ..write(_hookSignature(item))
        ..write(',');
    }
    b.write(']');
    return b.toString();
  }
  if (value is Map) {
    final keys = value.keys.map((e) => e.toString()).toList(growable: false)
      ..sort();
    final StringBuffer b = StringBuffer('{');
    for (final key in keys) {
      b
        ..write(key)
        ..write(':')
        ..write(_hookSignature(value[key]))
        ..write(',');
    }
    b.write('}');
    return b.toString();
  }
  return value.toString();
}

QLBlueprint _cloneBlueprintAs(
  QLBlueprint source,
  String type, {
  Map<String, dynamic>? props,
  String? path,
}) {
  final Map<String, dynamic> json = source.toJson();
  json['type'] = type;
  final Map<String, dynamic> merged =
      Map<String, dynamic>.from(json['props'] as Map? ?? const {});
  if (props != null && props.isNotEmpty) merged.addAll(props);
  if (props == null || !props.containsKey('__subType')) {
    merged.remove('__subType');
  }
  json['props'] = merged;
  if (path != null) json['debugPath'] = path;
  return QLBlueprint.fromJson(json, path: path ?? source.debugPath);
}

class _QLHookLifecycleNode extends StatefulWidget {
  final VoidCallback? onMount;
  final VoidCallback? onUnmount;
  final Widget child;

  const _QLHookLifecycleNode({
    required this.child,
    this.onMount,
    this.onUnmount,
  });

  @override
  State<_QLHookLifecycleNode> createState() => _QLHookLifecycleNodeState();
}

class _QLHookLifecycleNodeState extends State<_QLHookLifecycleNode> {
  @override
  void initState() {
    super.initState();
    final onMount = widget.onMount;
    if (onMount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        onMount();
      });
    }
  }

  @override
  void dispose() {
    widget.onUnmount?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _QLHookEffectNode extends StatefulWidget {
  final VoidCallback? onEffect;
  final Widget child;
  final String depsSignature;
  final bool runOnMount;

  const _QLHookEffectNode({
    required this.child,
    required this.depsSignature,
    this.onEffect,
    this.runOnMount = true,
  });

  @override
  State<_QLHookEffectNode> createState() => _QLHookEffectNodeState();
}

class _QLHookEffectNodeState extends State<_QLHookEffectNode> {
  String? _lastSignature;

  @override
  void initState() {
    super.initState();
    if (widget.runOnMount) {
      _scheduleEffect(force: true);
    } else {
      _lastSignature = widget.depsSignature;
    }
  }

  @override
  void didUpdateWidget(covariant _QLHookEffectNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.depsSignature != widget.depsSignature) {
      _scheduleEffect(force: false);
    }
  }

  void _scheduleEffect({required bool force}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!force && _lastSignature == widget.depsSignature) return;
      _lastSignature = widget.depsSignature;
      widget.onEffect?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _buildHook(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'lifecycle');

  Widget buildBody(BuildContext buildContext) {
    final Map<String, dynamic> env =
        QLDataScope.readNode(buildContext)?.localData ?? ctx.env;
    final effective =
        _AliasContext(QLContext(buildContext, ctx.node, env, ctx.store));

    final Widget child = effective.slot('child') ??
        (effective.children.isEmpty
            ? const SizedBox.shrink()
            : Q('col min-w-0 min-h-0', children: effective.children));
    return child;
  }

  final Widget child = buildBody(ctx.flutterContext);

  if (subType == 'guard') {
    if (!ctx.boolean('enabled', fallback: true)) {
      return ctx.slot('fallback') ?? const SizedBox.shrink();
    }
    return child;
  }

  if (subType == 'memo') {
    final dynamic memoKey = ctx.node.props['memoKey'] ??
        ctx.node.props['key'] ??
        ctx.node.props['memo'];
    return KeyedSubtree(
      key: ValueKey<String>(_hookSignature(memoKey)),
      child: child,
    );
  }

  if (subType == 'scope') {
    final Map<String, dynamic> scope = <String, dynamic>{
      ...ctx.env,
      ...ctx.map('scope'),
      if (ctx.node.props['locals'] is Map)
        ...Map<String, dynamic>.from(ctx.node.props['locals'] as Map),
    };
    return QLDataScope(
      localData: scope,
      child: Builder(builder: buildBody),
    );
  }

  if (subType == 'delegate') {
    final String target = ctx.string('target');
    if (target.isEmpty) return child;
    final Map<String, dynamic> delegateProps =
        Map<String, dynamic>.from(ctx.map('delegateProps'));
    final QLBlueprint delegated =
        _cloneBlueprintAs(ctx.node, target, props: delegateProps);
    return QuantumVM.instance.renderWidget(ctx.flutterContext, delegated);
  }

  final VoidCallback? onMount = ctx.action('onMount');
  final VoidCallback? onUnmount = ctx.action('onUnmount');
  final VoidCallback? onEffect = ctx.action('onEffect');
  final bool runOnMount = ctx.boolean('runOnMount', fallback: true);
  final String depsSignature = _hookSignature(
    ctx.node.props['deps'] ?? ctx.list('deps'),
  );

  if (subType == 'effect') {
    return _QLHookEffectNode(
      onEffect: onEffect,
      runOnMount: runOnMount,
      depsSignature: depsSignature,
      child: child,
    );
  }

  if (subType == 'change') {
    return _QLHookEffectNode(
      onEffect: onEffect,
      runOnMount: false,
      depsSignature: depsSignature,
      child: child,
    );
  }

  if (subType == 'lifecycle' || subType == 'mount') {
    return _QLHookLifecycleNode(
      onMount: onMount,
      onUnmount: onUnmount,
      child: child,
    );
  }

  if (subType == 'bridge') {
    final Map<String, dynamic> bridgeData = <String, dynamic>{
      ...ctx.env,
      ...ctx.map('bridge'),
      if (ctx.node.props['payload'] is Map)
        ...Map<String, dynamic>.from(ctx.node.props['payload'] as Map),
    };
    return QLDataScope(
      localData: bridgeData,
      child: Builder(builder: buildBody),
    );
  }

  // hook:store
  if (subType == 'store') {
    final String storeId =
        ctx.string('id', fallback: 'store_${ctx.node.hashCode}');
    final Map<String, dynamic> initial = ctx.map('initialState');
    final QLDataStore scopedStore = QLStoreRegistry.instance.get(storeId);
    if (scopedStore.get('__init') == null) {
      initial.forEach((k, v) => scopedStore.set(k, v));
      scopedStore.set('__init', true);
    }
    return QLDataScope(
        moduleStore: scopedStore,
        localData: {...ctx.env, '@$storeId': storeId},
        child: Q('col w-full', children: ctx.children));
  }

  // hook:atom
  if (subType == 'atom') {
    final String key = ctx.string('key', fallback: 'atom_${ctx.node.hashCode}');
    final String as = ctx.string('as', fallback: key);
    final sig = ctx.store.signal(key);
    if (sig.value == null) sig.value = ctx.node.props['value'];
    return QLDataScope(
        localData: {...ctx.env, as: sig},
        child: Q('col w-full', children: ctx.children));
  }

  // hook:slice
  if (subType == 'slice') {
    final String storeId = ctx.string('store');
    final String path = ctx.string('path');
    final String as = ctx.string('as', fallback: 'sliceValue');
    final QLDataStore target = QLStoreRegistry.instance.get(storeId);
    final sig = target.signal(path);
    return AnimatedBuilder(
      animation: sig,
      builder: (context, _) => QLDataScope(
          localData: {...ctx.env, as: sig.value},
          child: Q('col w-full', children: ctx.children)),
    );
  }

  // hook:ref
  if (subType == 'ref') {
    final String refId = ctx.string('id', fallback: 'ref_${ctx.node.hashCode}');
    return _QLRefNode(
        refId: refId,
        initial: ctx.node.props['initial'],
        env: ctx.env,
        children: ctx.children);
  }

  // hook:interval
  if (subType == 'interval') {
    final int ms = ctx.integer('ms', fallback: 1000);
    final String? bindKey =
        ctx.string('bind').isNotEmpty ? ctx.string('bind') : null;
    return _QLIntervalNode(
      ms: ms,
      bindKey: bindKey,
      actions: ctx.node.props['action'] as List<dynamic>?,
      store: ctx.store,
      env: ctx.env,
      child: ctx.children.isNotEmpty
          ? ctx.children.first
          : const SizedBox.shrink(),
    );
  }

  // hook:observable
  if (subType == 'observable') {
    final String streamKey = ctx.string('stream');
    final String as = ctx.string('as', fallback: 'value');
    final stream = QLPluginStreamRegistry.get(streamKey);
    if (stream == null) return Q('col w-full', children: ctx.children);
    return _QLObservableNode(
        stream: stream, as: as, env: ctx.env, children: ctx.children);
  }

  // hook:error_boundary
  if (subType == 'error_boundary') {
    final Widget? tryW = ctx.slot('try') ??
        (ctx.children.isNotEmpty ? ctx.children.first : null);
    return _QLErrorBoundaryNode(
      tryChild: tryW ?? const SizedBox.shrink(),
      catchChild: ctx.slot('catch'),
      finallyChild: ctx.slot('finally'),
    );
  }

  return child;
}

void _registerHookAliases(QuantumVM vm) {
  vm.defineAlias('hook_lifecycle', 'hook:lifecycle',
      description: 'Lifecycle hook wrapper alias.',
      tags: const ['hook', 'alias']);
  vm.defineAlias('hook_effect', 'hook:effect',
      description: 'Effect hook wrapper alias.', tags: const ['hook', 'alias']);
  vm.defineAlias('hook_scope', 'hook:scope',
      description: 'Scoped local data hook alias.',
      tags: const ['hook', 'alias']);
  vm.defineAlias('hook_bridge', 'hook:bridge',
      description: 'Bridge / data injection hook alias.',
      tags: const ['hook', 'alias']);
  vm.defineAlias('hook_store', 'hook:store',
      description: 'Scoped store hook.', tags: const ['hook', 'alias']);
  vm.defineAlias('hook_atom', 'hook:atom',
      description: 'Signal atom hook.', tags: const ['hook', 'alias']);
  vm.defineAlias('hook_interval', 'hook:interval',
      description: 'Interval hook.', tags: const ['hook', 'alias']);
  vm.defineAlias('hook_observable', 'hook:observable',
      description: 'Stream observable hook.', tags: const ['hook', 'alias']);
  vm.defineAlias('error_boundary', 'hook:error_boundary',
      description: 'Error boundary.', tags: const ['hook', 'alias']);
}

// Ref node
class _QLRefNode extends StatefulWidget {
  final String refId;
  final dynamic initial;
  final Map<String, dynamic> env;
  final List<Widget> children;
  const _QLRefNode(
      {required this.refId,
      this.initial,
      required this.env,
      required this.children});
  @override
  State<_QLRefNode> createState() => _QLRefNodeState();
}

class _QLRefNodeState extends State<_QLRefNode> {
  late dynamic _value;
  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  dynamic read() => _value;
  void write(dynamic v) {
    _value = v;
  }

  @override
  Widget build(BuildContext context) => QLDataScope(
      localData: {...widget.env, widget.refId: this},
      child: Q('col w-full', children: widget.children));
}

// Interval node
class _QLIntervalNode extends StatefulWidget {
  final int ms;
  final String? bindKey;
  final List<dynamic>? actions;
  final QLDataStore store;
  final Map<String, dynamic> env;
  final Widget child;
  const _QLIntervalNode(
      {required this.ms,
      this.bindKey,
      this.actions,
      required this.store,
      required this.env,
      required this.child});
  @override
  State<_QLIntervalNode> createState() => _QLIntervalNodeState();
}

class _QLIntervalNodeState extends State<_QLIntervalNode> {
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(milliseconds: widget.ms), (_) {
      if (!mounted) return;
      if (widget.bindKey != null) {
        final cur = widget.store.get(widget.bindKey!) as int? ?? 0;
        widget.store.set(widget.bindKey!, cur + 1);
      }
      if (widget.actions != null)
        QuantumVM.instance
            .triggerActions(widget.actions!, context, env: widget.env);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

// Observable (Stream) node
class _QLObservableNode extends StatefulWidget {
  final Stream<dynamic> stream;
  final String as;
  final Map<String, dynamic> env;
  final List<Widget> children;
  const _QLObservableNode(
      {required this.stream,
      required this.as,
      required this.env,
      required this.children});
  @override
  State<_QLObservableNode> createState() => _QLObservableNodeState();
}

class _QLObservableNodeState extends State<_QLObservableNode> {
  StreamSubscription? _sub;
  dynamic _latest;
  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((v) {
      if (mounted) setState(() => _latest = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => QLDataScope(
      localData: {...widget.env, widget.as: _latest},
      child: Q('col w-full', children: widget.children));
}

// Error Boundary node
class _QLErrorBoundaryNode extends StatefulWidget {
  final Widget tryChild;
  final Widget? catchChild, finallyChild;
  const _QLErrorBoundaryNode(
      {required this.tryChild, this.catchChild, this.finallyChild});
  @override
  State<_QLErrorBoundaryNode> createState() => _QLErrorBoundaryNodeState();
}

class _QLErrorBoundaryNodeState extends State<_QLErrorBoundaryNode> {
  Object? _error;
  @override
  Widget build(BuildContext context) {
    Widget body = _error != null && widget.catchChild != null
        ? widget.catchChild!
        : _QLErrorCatcher(
            onError: (e) {
              if (mounted) setState(() => _error = e);
            },
            child: widget.tryChild);
    if (widget.finallyChild == null) return body;
    return Column(
        mainAxisSize: MainAxisSize.min, children: [body, widget.finallyChild!]);
  }
}

class _QLErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object) onError;
  const _QLErrorCatcher({required this.child, required this.onError});
  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (d) {
      onError(d.exception);
      return const SizedBox.shrink();
    };
    return child;
  }
}
