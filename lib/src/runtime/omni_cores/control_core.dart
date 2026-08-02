/*
 * ============================================================================
 * File: control_core.dart
 * 
 * Description:
 * Implements logical control structures within the Quantum Omni Registry, including 
 * topological form scopes, tab/stepper indexing, optimistic updates, Redux-like 
 * reducers, state machines, and side-effect sagas.
 * 
 * Key Components:
 * - _buildControl: Resolves logical control subtypes (e.g., form_scope, flow).
 * - _QLMachineNode: Orchestrates XState-inspired finite state machines.
 * - _QLOptimisticNode: Manages optimistic UI updates with automatic rollback.
 * 
 * Dependencies/Relationships:
 * Part of quantum_omni_registry.dart. Hooks deeply into Quantum VM and DataStore.
 * 
 * Notes:
 * Handles complex asynchronous flows and state synchronization natively.
 * ============================================================================
 */
part of '../quantum_omni_registry.dart';

// Moved from quantum_omni_registry.dart: _buildControl

Widget _buildControl(QLContext rawCtx) {
  final ctx = _AliasContext(rawCtx);
  final String subType = ctx.resolvedSubType(fallback: 'tabs');
  final String ctrlId = ctx.string('id', fallback: 'ctrl_${ctx.node.hashCode}');

  // 🚀 MATH CONTEXT: control:form_scope
  // Reducer for children fields. Exposes .isValid and .formData automatically.
  // 🚀 MATH CONTEXT: control:form_scope
  // Hooks into the TRUE QLFormController (Topological Graph Engine)
  if (subType == 'form_scope') {
    final formCtrl = QLFormController();

    // We create derived signals so the UI can react instantly to Graph changes
    final isValidSignal = QLDerivedSignal<bool>(() => formCtrl.isValid)
      ..track(formCtrl.globalState);
    final formDataSignal =
        QLDerivedSignal<Map<String, dynamic>>(() => formCtrl.extractGraph())
          ..track(formCtrl.globalState);

    return QLDataScope(
      localData: {
        ...ctx.env,
        '__formController': formCtrl, // Expose the God-Mode Graph to children
        '$ctrlId.isValid': isValidSignal,
        '$ctrlId.formData': formDataSignal,
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  if (subType == 'tabs' || subType == 'stepper' || subType == 'accordion') {
    final int index = ctx.integer('initialIndex', fallback: 0);
    return QLDataScope(
      localData: {
        ...ctx.env,
        '$ctrlId.index': QLSignal<int>(index),
      },
      child: Q('col w-full', children: ctx.children),
    );
  }

  // 🚀 FLOW / TCA PRIMITIVE: control:flow / control:tca / control:architecture
  if (subType == 'flow' || subType == 'tca' || subType == 'architecture') {
    final String namespace = ctx.string('namespace', fallback: ctrlId);
    final String stateKey =
        ctx.string('stateKey', fallback: '$namespace.state');
    final String routeKey =
        ctx.string('routeKey', fallback: '$namespace.route');
    final String selectionKey =
        ctx.string('selectionKey', fallback: '$namespace.selection');
    final String heroKey = ctx.string('heroKey', fallback: '$namespace.hero');
    final QLDataStore flowStore = QLStoreRegistry.instance.get(namespace);

    final Map<String, dynamic> initialState = ctx.map('initialState');
    if (flowStore.get(stateKey) == null) {
      flowStore.set(
          stateKey, initialState.isEmpty ? <String, dynamic>{} : initialState);
    }
    if (flowStore.get(routeKey) == null) {
      final dynamic initialRoute =
          ctx.prop('initialRoute') ?? ctx.prop('route');
      if (initialRoute != null) flowStore.set(routeKey, initialRoute);
    }
    if (flowStore.get(selectionKey) == null) {
      final dynamic initialSelection =
          ctx.prop('initialSelection') ?? ctx.prop('selected');
      if (initialSelection != null) {
        flowStore.set(selectionKey, initialSelection);
      }
    }
    if (flowStore.get(heroKey) == null) {
      final dynamic initialHero =
          ctx.prop('initialHero') ?? ctx.prop('heroTag');
      if (initialHero != null) flowStore.set(heroKey, initialHero);
    }

    final stateSig = flowStore.signal(stateKey);
    final routeSig = flowStore.signal(routeKey);
    final selectionSig = flowStore.signal(selectionKey);
    final heroSig = flowStore.signal(heroKey);

    return _QLFlowControllerNode(
      namespace: namespace,
      disposeFlowState: ctx.boolean('disposeFlowState', fallback: false),
      stateKey: stateKey,
      routeKey: routeKey,
      selectionKey: selectionKey,
      heroKey: heroKey,
      child: AnimatedBuilder(
        animation:
            Listenable.merge([stateSig, routeSig, selectionSig, heroSig]),
        builder: (_, __) => QLDataScope(
          localStore: flowStore,
          moduleStore: flowStore,
          localData: {
            ...ctx.env,
            '$ctrlId.namespace': namespace,
            '$ctrlId.state': stateSig,
            '$ctrlId.route': routeSig,
            '$ctrlId.selection': selectionSig,
            '$ctrlId.hero': heroSig,
            '$ctrlId.heroTag': heroSig,
            '$ctrlId.stateValue': stateSig.value,
            '$ctrlId.routeValue': routeSig.value,
            '$ctrlId.selectionValue': selectionSig.value,
            '$ctrlId.heroValue': heroSig.value,
            'namespace': namespace,
            'state': stateSig.value,
            'route': routeSig.value,
            'selection': selectionSig.value,
            'hero': heroSig.value,
            'heroTag': heroSig.value,
            'stateSignal': stateSig,
            'routeSignal': routeSig,
            'selectionSignal': selectionSig,
            'heroSignal': heroSig,
            'flowState': stateSig.value,
            'flowRoute': routeSig.value,
            'flowSelection': selectionSig.value,
            'flowHeroTag': heroSig.value,
            'flowStateSignal': stateSig,
            'flowRouteSignal': routeSig,
            'flowSelectionSignal': selectionSig,
            'flowHeroSignal': heroSig,
          },
          child: Builder(
            builder: (_) => Q('col min-w-0 min-h-0', children: ctx.children),
          ),
        ),
      ),
    );
  }

  // ── control:machine — XState-inspired finite state machine ─────────────────
  if (subType == 'machine') {
    return _QLMachineNode(
      id: ctrlId,
      initial: ctx.string('initial'),
      states: ctx.map('states'),
      machineContext: ctx.map('context'),
      env: ctx.env,
      children: ctx.children,
    );
  }

  // ── control:reducer — Redux-style local reducer ────────────────────────────
  if (subType == 'reducer') {
    final Map<String, dynamic> initialState = ctx.map('initialState');
    final Map<String, dynamic> actions = ctx.map('actions');
    return _QLLocalReducerNode(
      reducerId: ctrlId,
      initialState: initialState,
      actions: actions,
      env: ctx.env,
      children: ctx.children,
    );
  }

  // ── control:optimistic — Optimistic UI with auto-rollback ─────────────────
  if (subType == 'optimistic') {
    return _QLOptimisticNode(
      action: ctx.string('action'),
      optimisticData: ctx.map('optimisticData'),
      rollbackOn: ctx.string('rollbackOn', fallback: 'error'),
      env: ctx.env,
      store: ctx.store,
      child: ctx.children.isNotEmpty
          ? ctx.children.first
          : const SizedBox.shrink(),
    );
  }

  // ── control:saga — Sequential side-effect runner ──────────────────────────
  if (subType == 'saga') {
    final List<dynamic> steps = ctx.list('steps');
    QuantumVM.instance.registerAction(
      'saga.$ctrlId.run',
      LambdaActionPlugin((p, s, c) async {
        for (final step in steps) {
          if (step is! Map) continue;
          final delay = (step['delay'] as num?)?.toInt() ?? 0;
          if (delay > 0) await Future.delayed(Duration(milliseconds: delay));
          final actionList = step['action'] != null
              ? [step]
              : (step['actions'] as List? ?? []);
          await QuantumVM.instance
              .triggerActions(actionList, null, env: {...ctx.env, ...p});
        }
        return null;
      }),
    );
    return QLDataScope(
      localData: {...ctx.env, 'saga.$ctrlId.run': 'saga.$ctrlId.run'},
      child: Q('col w-full', children: ctx.children),
    );
  }

  // STANDARD CONTROL LOGIC
  return QLDataScope(
    moduleStore: ctx.store,
    localData: {
      '$ctrlId.index': QLSignal<int>(ctx.integer('initialIndex', fallback: 0)),
      '$ctrlId.data': QLSignal<Map<String, dynamic>>({}),
    },
    child:
        Builder(builder: (innerCtx) => Q('col w-full', children: ctx.children)),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// MACHINE CONTROLLER — XState-inspired finite state machine
// ════════════════════════════════════════════════════════════════════════════

final class _QLMachineRegistry {
  static final _QLMachineRegistry instance = _QLMachineRegistry._();
  _QLMachineRegistry._();
  final Map<String, _QLMachineController> _machines = {};
  void register(String id, _QLMachineController ctrl) => _machines[id] = ctrl;
  _QLMachineController? get(String id) => _machines[id];
  void remove(String id) => _machines.remove(id);
}

class _QLMachineController {
  final String id;
  final Map<String, dynamic> states;
  final QLSignal<String> stateSignal;
  Map<String, dynamic> context;

  _QLMachineController(
      {required this.id,
      required String initial,
      required this.states,
      Map<String, dynamic>? context})
      : stateSignal = QLSignal<String>(initial),
        context = context ?? {};

  String get current => stateSignal.value;

  bool can(String event) {
    final on = _on(current);
    return on != null && on.containsKey(event);
  }

  Map? _on(String state) {
    final node = states[state];
    return node is Map ? node['on'] as Map? : null;
  }

  void send(String event, {Map<String, dynamic>? payload}) {
    final on = _on(current);
    if (on == null || !on.containsKey(event)) return;
    final t = on[event];
    final next = t is Map ? t['target']?.toString() : t?.toString();
    if (next == null || !states.containsKey(next)) return;
    if (payload != null) context.addAll(payload);
    stateSignal.value = next;
    _invokeEntry(next);
  }

  void _invokeEntry(String state) {
    final node = states[state];
    if (node is! Map) return;
    final inv = node['invoke'];
    if (inv is! Map) return;
    final act = inv['action']?.toString() ?? '';
    final params = inv['params'] is Map
        ? Map<String, dynamic>.from(inv['params'] as Map)
        : <String, dynamic>{};
    params.addAll({r'$machineId': id, r'$state': state});
    QuantumVM.instance.triggerActions([
      {'action': act, ...params}
    ], null).then((_) {
      final done = inv['onDone']?.toString();
      if (done != null && states.containsKey(done)) stateSignal.value = done;
    }).catchError((_) {
      final err = inv['onError']?.toString();
      if (err != null && states.containsKey(err)) stateSignal.value = err;
    });
  }

  bool matches(String s) => current == s;
  bool matchesAny(List<String> list) => list.contains(current);
}

class _QLMachineNode extends StatefulWidget {
  final String id, initial;
  final Map<String, dynamic> states, machineContext, env;
  final List<Widget> children;
  const _QLMachineNode(
      {required this.id,
      required this.initial,
      required this.states,
      required this.machineContext,
      required this.env,
      required this.children});
  @override
  State<_QLMachineNode> createState() => _QLMachineNodeState();
}

class _QLMachineNodeState extends State<_QLMachineNode> {
  late _QLMachineController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = _QLMachineController(
        id: widget.id,
        initial: widget.initial,
        states: widget.states,
        context: Map.from(widget.machineContext));
    _QLMachineRegistry.instance.register(widget.id, _ctrl);
    QuantumVM.instance.registerAction('machine.${widget.id}.send',
        LambdaActionPlugin((p, s, c) async {
      final event = p['event']?.toString() ?? '';
      final payload = Map<String, dynamic>.from(p)
        ..remove('event')
        ..remove('action');
      _ctrl.send(event, payload: payload);
      return null;
    }));
  }

  @override
  void dispose() {
    _QLMachineRegistry.instance.remove(widget.id);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl.stateSignal,
      builder: (_, __) {
        final cur = _ctrl.current;
        final stateNode = widget.states[cur];
        final renderDef = stateNode is Map ? stateNode['render'] : null;
        Widget content = widget.children.isNotEmpty
            ? widget.children.first
            : const SizedBox.shrink();
        if (renderDef is Map) {
          content = QuantumVM.instance.renderWidget(
              context,
              QLBlueprint.fromJson(Map<String, dynamic>.from(renderDef),
                  path: 'machine.${widget.id}.$cur'));
        }
        return QLDataScope(
          localData: {
            ...widget.env,
            r'$machineState': cur,
            r'$machineId': widget.id,
            r'$machineContext': _ctrl.context,
            r'$send': 'machine.${widget.id}.send',
            r'$can': (String e) => _ctrl.can(e)
          },
          child: content,
        );
      },
    );
  }
}

class _QLOptimisticNode extends StatefulWidget {
  final String action, rollbackOn;
  final Map<String, dynamic> optimisticData, env;
  final QLDataStore store;
  final Widget child;
  const _QLOptimisticNode(
      {required this.action,
      required this.optimisticData,
      required this.rollbackOn,
      required this.env,
      required this.store,
      required this.child});
  @override
  State<_QLOptimisticNode> createState() => _QLOptimisticNodeState();
}

class _QLOptimisticNodeState extends State<_QLOptimisticNode> {
  Map<String, dynamic>? _snapshot;
  void _apply() {
    _snapshot = {
      for (final k in widget.optimisticData.keys) k: widget.store.get(k)
    };
    widget.optimisticData.forEach((k, v) => widget.store.set(k, v));
  }

  void _rollback() {
    _snapshot?.forEach((k, v) => widget.store.set(k, v));
    _snapshot = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        _apply();
        try {
          await QuantumVM.instance.triggerActions([
            {'action': widget.action}
          ], context, env: widget.env);
        } catch (_) {
          if (widget.rollbackOn == 'error') _rollback();
        }
      },
      child: widget.child,
    );
  }
}

class _QLLocalReducerNode extends StatefulWidget {
  final String reducerId;
  final Map<String, dynamic> initialState, actions, env;
  final List<Widget> children;
  const _QLLocalReducerNode(
      {required this.reducerId,
      required this.initialState,
      required this.actions,
      required this.env,
      required this.children});
  @override
  State<_QLLocalReducerNode> createState() => _QLLocalReducerNodeState();
}

class _QLLocalReducerNodeState extends State<_QLLocalReducerNode> {
  late QLSignal<Map<String, dynamic>> _state;
  @override
  void initState() {
    super.initState();
    _state = QLSignal<Map<String, dynamic>>(Map.from(widget.initialState));
  }

  Future<void> dispatch(String type, Map<String, dynamic> payload) async {
    final acts = widget.actions[type] as List<dynamic>?;
    if (acts == null) return;
    await QuantumVM.instance.triggerActions(acts, context,
        env: {...widget.env, r'$state': _state.value, r'$payload': payload});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _state,
      builder: (_, __) => QLDataScope(
        localData: {
          ...widget.env,
          r'$state': _state.value,
          r'$dispatch': dispatch
        },
        child: Q('col w-full', children: widget.children),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CORE 9: CANVAS (GPU Fragment Pipelines & Custom Paint)
// ════════════════════════════════════════════════════════════════════════════

void _registerControlAliases(QuantumVM vm) {
  vm.defineAlias('flow', 'control:flow',
      description: 'Flow control alias.', tags: const ['control', 'alias']);
  vm.defineAlias('workflow', 'control:flow',
      description: 'Workflow alias for flow control.',
      tags: const ['control', 'alias']);
  vm.defineAlias('form_scope', 'control:form_scope',
      description: 'Form scope alias.', tags: const ['control', 'alias']);
  vm.defineAlias('tabs', 'control:tabs',
      description: 'Tabs control alias.', tags: const ['control', 'alias']);
  vm.defineAlias('segment', 'control:tabs',
      description: 'Segment alias for tabs control.',
      tags: const ['control', 'alias']);
  vm.defineAlias('stepper', 'control:stepper',
      description: 'Stepper control alias.', tags: const ['control', 'alias']);
  vm.defineAlias('accordion', 'control:accordion',
      description: 'Accordion control alias.',
      tags: const ['control', 'alias']);
  vm.defineAlias('machine', 'control:machine',
      description: 'State machine control alias.',
      tags: const ['control', 'alias']);
  vm.defineAlias('reducer', 'control:reducer',
      description: 'Reducer control alias.', tags: const ['control', 'alias']);
  vm.defineAlias('optimistic', 'control:optimistic',
      description: 'Optimistic control alias.',
      tags: const ['control', 'alias']);
}

class ControlCoreExporter implements QuantumCoreExporter {
  const ControlCoreExporter();
  
  @override
  void export(QuantumVM vm) {
    vm.define('control', _buildControl, tags: const ['core', 'control']);
    _registerControlAliases(vm);
  }
}
