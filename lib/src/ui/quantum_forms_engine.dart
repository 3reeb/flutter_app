// ════════════════════════════════════════════════════════════════════════════
// QUANTUM FORMS ENGINE v3.0 - OMEGA PRODUCTION BUILD
// quantum_forms_engine.dart
// ════════════════════════════════════════════════════════════════════════════

library quantum_runtime;

import 'dart:async';
import 'dart:collection';
import '../foundation/quantum_core.dart';
import 'package:quantum_layout/quantum.dart';
typedef QLDataMiddleware<T> = T Function(T incoming, T current);

class QLChangeEvent<T> {
  final String path;
  final T previous;
  final T current;
  final QLGraphController graph;

  const QLChangeEvent({
    required this.path,
    required this.previous,
    required this.current,
    required this.graph,
  });

  Map<String, dynamic> doc({bool raw = false}) => graph.extractGraph(raw: raw);

  dynamic sibling(String relativePath) {
    final parent = QLPathUtils.parentOf(path);
    final siblingPath = parent.isEmpty ? relativePath : '$parent.$relativePath';
    return graph.getNode(siblingPath)?.serialize();
  }

  void setSibling(String relativePath, dynamic value) {
    final parent = QLPathUtils.parentOf(path);
    final siblingPath = parent.isEmpty ? relativePath : '$parent.$relativePath';
    graph.getNode(siblingPath)?.mutate(value);
  }
}

class _QLObserver {
  final RegExp pattern;
  final void Function(QLChangeEvent<dynamic>) callback;
  const _QLObserver(this.pattern, this.callback);
}

abstract class QLDataNode<T> implements QLDisposable {
  final String path;
  final QLGraphController graph;
  final T initialValue;
  final QLSleepPolicy sleepPolicy;

  late final QLSignal<T> data;
  late final QLSignal<int> stateFlags;
  late final QLSignal<Map<String, dynamic>> meta;
  late final QLSignal<List<QLNodeError>> errors;

  final List<QLValidator<T>> syncValidators;
  final List<QLAsyncValidator<T>> asyncValidators;
  final List<QLDataMiddleware<T>> middlewares;
  final List<QLFastMiddleware<T>> fastMiddlewares;
  final List<String> dependencies;

  int _asyncNonce = 0;
  bool _disposed = false;
  StreamSubscription<T>? _streamSub;

  QLDataNode({
    required this.path,
    required this.graph,
    required this.initialValue,
    this.sleepPolicy = QLSleepPolicy.manual,
    this.syncValidators = const [],
    this.asyncValidators = const [],
    this.middlewares = const [],
    this.fastMiddlewares = const [],
    this.dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
    int initialState = QLNodeState.idle,
  }) {
    data = QLSignal<T>(initialValue);
    stateFlags = QLSignal<int>(initialState);
    errors = QLSignal<List<QLNodeError>>(<QLNodeError>[]);
    meta =
        QLSignal<Map<String, dynamic>>(Map<String, dynamic>.from(initialMeta));

    graph.register(this);

    if (sleepPolicy == QLSleepPolicy.auto &&
        (syncValidators.isNotEmpty || asyncValidators.isNotEmpty) &&
        !hasState(QLNodeState.sleeping)) {
      scheduleMicrotask(validate);
    } else if (syncValidators.isNotEmpty && !hasState(QLNodeState.sleeping)) {
      // 🚀 FIX: Must notify the graph of initial validation errors so the form knows it is invalid!
      _runSyncValidation(initialValue, notifyGraph: true);
    }
  }

  bool get isDisposed => _disposed;
  bool get isDirty => hasState(QLNodeState.dirty);
  bool get isValid => !hasState(QLNodeState.hasError);
  bool get isValidating => hasState(QLNodeState.validating);
  bool get isDisabled =>
      hasState(QLNodeState.disabled) || hasState(QLNodeState.readOnly);
  bool get isSleeping => hasState(QLNodeState.sleeping);
  bool get isReadonly => hasState(QLNodeState.readOnly);
  bool get isHidden => meta.value['_ql_hidden'] == true;

  @pragma('vm:prefer-inline')
  void mutate(T newValue, {bool shouldValidate = true}) {
    if (_disposed) return;
    if (hasState(QLNodeState.hardwareLocked) ||
        hasState(QLNodeState.readOnly) ||
        hasState(QLNodeState.disabled)) {
      return;
    }

    var processed = newValue;
    if (!hasState(QLNodeState.sleeping) && middlewares.isNotEmpty) {
      for (final mw in middlewares) {
        processed = mw(processed, data.value);
      }
    }

    if (data.value == processed) return;

    final previous = data.value;
    data.setSilent(processed);

    var newFlags = stateFlags.value | QLNodeState.dirty;
    if (processed == initialValue) newFlags &= ~QLNodeState.dirty;
    stateFlags.setSilent(newFlags);

    data.forceNotify();
    stateFlags.forceNotify();

    graph._dispatchEvent(QLChangeEvent<T>(
      path: path,
      previous: previous,
      current: processed,
      graph: graph,
    ));

    if (hasState(QLNodeState.sleeping)) return;
    if (shouldValidate) validate();
    graph.notifyNodeMutated(path);
  }

  @pragma('vm:prefer-inline')
  void mutateFast(T newValue, {bool applyMiddleware = true}) {
    if (_disposed) return;
    if (hasState(QLNodeState.hardwareLocked) ||
        hasState(QLNodeState.readOnly) ||
        hasState(QLNodeState.disabled)) {
      return;
    }

    var processed = newValue;
    if (applyMiddleware && fastMiddlewares.isNotEmpty) {
      for (final mw in fastMiddlewares) {
        processed = mw(processed, data.value);
      }
    }

    if (data.value == processed) return;

    final previous = data.value;
    data.setSilent(processed);
    stateFlags.setSilent(stateFlags.value | QLNodeState.dirty);

    data.forceNotify();
    stateFlags.forceNotify();

    graph._dispatchEvent(QLChangeEvent<T>(
      path: path,
      previous: previous,
      current: processed,
      graph: graph,
    ));

    graph.notifyNodeMutated(path);
  }

  void setValue(T newValue, {bool shouldValidate = true}) =>
      mutate(newValue, shouldValidate: shouldValidate);

  void setSilently(T newValue, {bool keepDirty = true}) {
    if (_disposed) return;
    data.setSilent(newValue);
    if (keepDirty) {
      stateFlags.setSilent(stateFlags.value | QLNodeState.dirty);
    }
    data.forceNotify();
    stateFlags.forceNotify();
  }

  void bindStream(Stream<T> stream, {bool validateOnStream = false}) {
    if (_disposed) return;
    _streamSub?.cancel();
    addState(QLNodeState.streaming | QLNodeState.hardwareLocked);

    T? pending;
    var scheduled = false;

    _streamSub = stream.listen((incoming) {
      pending = incoming;
      if (scheduled) return;
      scheduled = true;

      scheduleMicrotask(() {
        scheduled = false;
        final value = pending;
        if (value == null || _disposed) return;

        removeState(QLNodeState.hardwareLocked);
        if (validateOnStream) {
          mutate(value as T);
        } else {
          mutateFast(value as T);
        }
        addState(QLNodeState.hardwareLocked);
      });
    }, onDone: () {
      removeState(QLNodeState.streaming | QLNodeState.hardwareLocked);
    });
  }

  void unbindStream() {
    _streamSub?.cancel();
    _streamSub = null;
    removeState(QLNodeState.streaming | QLNodeState.hardwareLocked);
  }

  void sleep() {
    if (_disposed || hasState(QLNodeState.sleeping)) return;
    addState(QLNodeState.sleeping);
    _asyncNonce++;
    removeState(QLNodeState.validating);
  }

  void wake() {
    if (_disposed || !hasState(QLNodeState.sleeping)) return;
    removeState(QLNodeState.sleeping);
    validate();
  }

  @pragma('vm:prefer-inline')
  void addState(int flag) {
    if ((stateFlags.value & flag) != flag) {
      stateFlags.setSilent(stateFlags.value | flag);
      stateFlags.forceNotify();
    }
  }

  @pragma('vm:prefer-inline')
  void removeState(int flag) {
    if ((stateFlags.value & flag) != 0) {
      stateFlags.setSilent(stateFlags.value & ~flag);
      stateFlags.forceNotify();
    }
  }

  @pragma('vm:prefer-inline')
  bool hasState(int flag) => (stateFlags.value & flag) == flag;

  void updateMeta(String key, dynamic value, {bool notify = true}) {
    if (_disposed) return;
    final next = Map<String, dynamic>.from(meta.value)..[key] = value;
    meta.setSilent(next);
    if (notify) meta.forceNotify();
  }

  void removeMeta(String key, {bool notify = true}) {
    if (_disposed) return;
    if (!meta.value.containsKey(key)) return;
    final next = Map<String, dynamic>.from(meta.value)..remove(key);
    meta.setSilent(next);
    if (notify) meta.forceNotify();
  }

  void hide({bool notify = true}) =>
      updateMeta('_ql_hidden', true, notify: notify);
  void show({bool notify = true}) => removeMeta('_ql_hidden', notify: notify);

  void disable({bool notify = true}) {
    addState(QLNodeState.disabled);
    if (notify) stateFlags.forceNotify();
  }

  void enable({bool notify = true}) {
    removeState(QLNodeState.disabled);
    if (notify) stateFlags.forceNotify();
  }

  void setReadOnly(bool value) => value
      ? addState(QLNodeState.readOnly)
      : removeState(QLNodeState.readOnly);

  Future<void> validate() async {
    if (_disposed || hasState(QLNodeState.sleeping)) return;
    if (syncValidators.isEmpty && asyncValidators.isEmpty) return;

    final currentVal = data.value;
    addState(QLNodeState.validating);
    try {
      final syncOk = _runSyncValidation(currentVal, notifyGraph: true);
      if (!syncOk || asyncValidators.isEmpty) return;

      final nonce = ++_asyncNonce;
      final asyncErrs = <QLNodeError>[];

      for (final validator in asyncValidators) {
        final err = await validator(currentVal, graph);
        if (_disposed || nonce != _asyncNonce) return;
        if (err != null) asyncErrs.add(err);
      }

      if (!_disposed && nonce == _asyncNonce) {
        _setErrors(asyncErrs, notifyGraph: true);
      }
    } finally {
      if (!_disposed) removeState(QLNodeState.validating);
    }
  }

  bool _runSyncValidation(T val, {required bool notifyGraph}) {
    final syncErrs = <QLNodeError>[];
    for (final validator in syncValidators) {
      final err = validator(val, graph);
      if (err != null) syncErrs.add(err);
    }
    _setErrors(syncErrs, notifyGraph: notifyGraph);
    return !hasState(QLNodeState.hasError);
  }

  void _setErrors(List<QLNodeError> newErrors, {bool notifyGraph = true}) {
    final hadError = hasState(QLNodeState.hasError);
    final hasErrorNow = newErrors.any((e) => e.severity >= 2);

    errors.setSilent(List<QLNodeError>.unmodifiable(newErrors));
    errors.forceNotify();

    if (hasErrorNow) {
      addState(QLNodeState.hasError);
    } else {
      removeState(QLNodeState.hasError);
    }

    if (notifyGraph && hadError != hasErrorNow) {
      graph.reportNodeValidity(path, !hasErrorNow);
    }
  }

  void clearErrors() => _setErrors(const [], notifyGraph: true);

  void refresh() {
    if (_disposed) return;
    data.forceNotify();
    stateFlags.forceNotify();
    errors.forceNotify();
    meta.forceNotify();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _streamSub?.cancel();
    _asyncNonce++;
    data.dispose();
    stateFlags.dispose();
    errors.dispose();
    meta.dispose();
  }

  void reset() {
    if (_disposed) return;
    data.setSilent(initialValue);
    stateFlags.setSilent(QLNodeState.idle);
    errors.setSilent(const []);
    data.forceNotify();
    stateFlags.forceNotify();
    errors.forceNotify();
    if (!hasState(QLNodeState.sleeping)) validate();
  }

  dynamic serialize() => data.value;
}

class QLGraphController {
  final Map<String, QLDataNode<dynamic>> _nodes = {};
  final Map<String, Set<String>> _dependents = {};
  final Set<String> _invalidNodes = {};
  final List<_QLObserver> _observers = [];
  late final QLSignal<int> globalState;
  bool _disposed = false;

  QLGraphController() {
    globalState = QLSignal<int>(QLNodeState.idle);
  }

  Map<String, QLDataNode<dynamic>> get registeredNodes =>
      Map.unmodifiable(_nodes);

  bool hasNode(String path) => _nodes.containsKey(path);
  QLDataNode<dynamic>? getNode(String path) => _nodes[path];

  Iterable<String> nodePathsWithPrefix(String prefix) sync* {
    for (final key in _nodes.keys) {
      if (key == prefix || key.startsWith('$prefix.')) yield key;
    }
  }

  Iterable<QLDataNode<dynamic>> nodesWithPrefix(String prefix) sync* {
    for (final key in nodePathsWithPrefix(prefix)) {
      final node = _nodes[key];
      if (node != null) yield node;
    }
  }

  Iterable<QLDataNode<dynamic>> nodesMatching(RegExp pattern) sync* {
    for (final entry in _nodes.entries) {
      if (pattern.hasMatch(entry.key)) yield entry.value;
    }
  }

  String _wildcardToRegex(String pattern) {
    final out = StringBuffer('^');
    for (int i = 0; i < pattern.length; i++) {
      final ch = pattern[i];
      if (ch == '*') {
        out.write('.*');
      } else if (ch == '[' &&
          i + 2 < pattern.length &&
          pattern[i + 1] == '*' &&
          pattern[i + 2] == ']') {
        out.write(r'\[\d+\]');
        i += 2;
      } else {
        out.write(RegExp.escape(ch));
      }
    }
    out.write(r'$');
    return out.toString();
  }

  void watch(String pattern, void Function(QLChangeEvent<dynamic>) callback) {
    _observers.add(_QLObserver(RegExp(_wildcardToRegex(pattern)), callback));
  }

  void _dispatchEvent(QLChangeEvent<dynamic> event) {
    if (_disposed) return;
    for (final observer in _observers) {
      if (observer.pattern.hasMatch(event.path)) {
        try {
          observer.callback(event);
        } catch (_) {}
      }
    }
  }

  void register(QLDataNode node) {
    if (_disposed) return;

    final existing = _nodes[node.path];
    if (existing != null && !identical(existing, node)) {
      unregister(node.path);
    }

    _nodes[node.path] = node;

    for (final dep in node.dependencies) {
      _dependents.putIfAbsent(dep, () => <String>{}).add(node.path);
    }

    if (node.hasState(QLNodeState.hasError)) {
      _invalidNodes.add(node.path);
      _syncGlobalValidity();
    }
  }

  void unregister(String path) {
    final node = _nodes.remove(path);
    if (node == null) return;

    _invalidNodes.remove(path);
    _syncGlobalValidity();

    for (final dep in node.dependencies) {
      final set = _dependents[dep];
      if (set == null) continue;
      set.remove(path);
      if (set.isEmpty) _dependents.remove(dep);
    }

    for (final set in _dependents.values) {
      set.remove(path);
    }

    node.dispose();
  }

  void notifyNodeMutated(String triggerPath) {
    if (_disposed) return;
    addGlobalState(QLNodeState.dirty);

    final queue = <String>[triggerPath];
    final visited = <String>{triggerPath};

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      final dependents = _dependents[current];
      if (dependents == null || dependents.isEmpty) continue;

      for (final depPath in dependents) {
        if (!visited.add(depPath)) continue;
        final target = _nodes[depPath];
        if (target != null && !target.hasState(QLNodeState.sleeping)) {
          target.validate();
        }
        queue.add(depPath);
      }
    }
  }

  void reportNodeValidity(String path, bool isValidNow) {
    if (isValidNow) {
      _invalidNodes.remove(path);
    } else {
      _invalidNodes.add(path);
    }
    _syncGlobalValidity();
  }

  void _syncGlobalValidity() {
    if (_invalidNodes.isEmpty) {
      removeGlobalState(QLNodeState.hasError);
    } else {
      addGlobalState(QLNodeState.hasError);
    }
  }

  void addGlobalState(int flag) {
    final next = globalState.value | flag;
    if (next != globalState.value) {
      globalState.setSilent(next);
      globalState.forceNotify();
    }
  }

  void removeGlobalState(int flag) {
    final next = globalState.value & ~flag;
    if (next != globalState.value) {
      globalState.setSilent(next);
      globalState.forceNotify();
    }
  }

  Future<bool> resolveGraph() async {
    if (_disposed) return false;
    addGlobalState(QLNodeState.validating);

    try {
      final futures = <Future<void>>[];
      for (final node in _nodes.values) {
        if (!node.hasState(QLNodeState.sleeping)) {
          futures.add(node.validate());
        }
      }
      await Future.wait(futures);
      return _invalidNodes.isEmpty;
    } finally {
      removeGlobalState(QLNodeState.validating);
    }
  }

  Map<String, dynamic> extractGraph({bool raw = false}) {
    final nested = <String, dynamic>{};
    for (final entry in _nodes.entries) {
      final value = raw ? entry.value.data.value : entry.value.serialize();
      if (value == null) continue;
      _bury(nested, QLPathUtils.resolve(entry.key), value);
    }
    return nested;
  }

  Map<String, dynamic> extractSubgraph(String prefix, {bool raw = false}) {
    if (prefix.isEmpty) return extractGraph(raw: raw);
    final nested = <String, dynamic>{};
    final prefixSegs = QLPathUtils.resolve(prefix).length;

    for (final entry in _nodes.entries) {
      if (!(entry.key == prefix || entry.key.startsWith('$prefix.'))) continue;
      final value = raw ? entry.value.data.value : entry.value.serialize();
      if (value == null) continue;
      final rel = QLPathUtils.resolve(entry.key)
          .skip(prefixSegs)
          .toList(growable: false);
      if (rel.isEmpty) continue;
      _bury(nested, rel, value);
    }
    return nested;
  }

  void _bury(Map<String, dynamic> root, List<dynamic> path, dynamic value) {
    if (path.isEmpty) return;
    dynamic current = root;

    for (int i = 0; i < path.length - 1; i++) {
      final segment = path[i];
      final nextSegment = path[i + 1];

      if (current is Map) {
        final key = segment.toString();
        current.putIfAbsent(
            key, () => nextSegment is int ? <dynamic>[] : <String, dynamic>{});
        current = current[key];
      } else if (current is List) {
        final idx =
            segment is int ? segment : int.tryParse(segment.toString()) ?? 0;
        while (current.length <= idx) {
          current.add(nextSegment is int ? <dynamic>[] : <String, dynamic>{});
        }
        current = current[idx];
      } else {
        return;
      }
    }

    final last = path.last;
    if (current is Map) {
      current[last.toString()] = value;
    } else if (current is List) {
      final idx = last is int ? last : int.tryParse(last.toString()) ?? 0;
      while (current.length <= idx) current.add(null);
      current[idx] = value;
    }
  }

  void sleepAll() {
    for (final n in _nodes.values) {
      n.sleep();
    }
  }

  void wakeAll() {
    for (final n in _nodes.values) {
      n.wake();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;

    globalState.dispose();
    for (final n in _nodes.values.toList(growable: false)) {
      n.dispose();
    }
    _nodes.clear();
    _dependents.clear();
    _invalidNodes.clear();
    _observers.clear();
  }
}

class QLFormController extends QLGraphController {
  int _virtualBuildDepth = 0;

  bool get isSubmitting => (globalState.value & QLNodeState.custom3) != 0;
  bool get isValid => (globalState.value & QLNodeState.hasError) == 0;
  bool get isVirtualBuildScope => _virtualBuildDepth > 0;

  void enterVirtualBuildScope() => _virtualBuildDepth++;
  void exitVirtualBuildScope() {
    if (_virtualBuildDepth > 0) _virtualBuildDepth--;
  }

  Iterable<QLDataNode<dynamic>> childrenOf(String path) =>
      nodesWithPrefix(path);

  Future<void> validateChildrenOf(String path) async {
    final futures = <Future<void>>[];
    for (final node in nodesWithPrefix(path)) {
      if (!node.hasState(QLNodeState.sleeping)) {
        futures.add(node.validate());
      }
    }
    await Future.wait(futures);
  }

  Future<bool> submit() async {
    addGlobalState(QLNodeState.custom3);
    try {
      for (final node in registeredNodes.values.toList(growable: false)) {
        if (node is QLFieldController) node.touch();
        node.wake();
      }
      return await resolveGraph();
    } finally {
      removeGlobalState(QLNodeState.custom3);
    }
  }

  Map<String, dynamic> get formData => extractGraph();

  void resetForm() {
    for (final node in registeredNodes.values.toList(growable: false)) {
      node.reset();
    }
  }
}

typedef QLFieldBuilder = void Function(String basePath, QLFormController form);
typedef QLFieldSchema = QLFieldBuilder;

abstract final class QLValidators {
  static QLValidator<dynamic> required([String msg = 'Required']) => (v, _) {
        if (v == null) return QLNodeError(msg);
        if (v is String && v.trim().isEmpty) return QLNodeError(msg);
        if (v is List && v.isEmpty) return QLNodeError(msg);
        if (v is Map && v.isEmpty) return QLNodeError(msg);
        return null;
      };

  static QLValidator<String> email([String msg = 'Invalid email']) => (v, _) {
        if (v.isEmpty) return null;
        final rx = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        return rx.hasMatch(v) ? null : QLNodeError(msg);
      };
}

abstract final class QLTransforms {
  static QLValueTransform<String> trim() => (v) => v.trim();
  static QLValueTransform<String> lowercase() => (v) => v.toLowerCase();
}

abstract class QLFieldController<T> extends QLDataNode<T> {
  final QLValueTransform<T>? transform;

  QLFormController get form => graph as QLFormController;

  QLFieldController({
    required String path,
    required QLFormController form,
    required T initialValue,
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    this.transform,
    List<QLValidator<T>> syncValidators = const [],
    List<QLAsyncValidator<T>> asyncValidators = const [],
    List<QLDataMiddleware<T>> middlewares = const [],
    List<QLFastMiddleware<T>> fastMiddlewares = const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
    int initialState = QLNodeState.idle,
  }) : super(
          path: path,
          graph: form,
          initialValue: initialValue,
          sleepPolicy: sleepPolicy,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          middlewares: middlewares,
          fastMiddlewares: fastMiddlewares,
          dependencies: dependencies,
          initialMeta: form.isVirtualBuildScope
              ? {...initialMeta, '_ql_hidden': true}
              : initialMeta,
          initialState: initialState,
        );

  String? get errorText =>
      errors.value.isNotEmpty ? errors.value.first.message : null;
  bool get isTouched => hasState(QLNodeState.custom1);
  bool get isFocused => hasState(QLNodeState.custom2);

  @override
  bool get isHidden => meta.value['_ql_hidden'] == true;

  @override
  void mutate(T newValue, {bool shouldValidate = true}) {
    final formatted = transform != null ? transform!(newValue) : newValue;
    super.mutate(formatted, shouldValidate: shouldValidate);
  }

  void touch() => addState(QLNodeState.custom1);
  void focus() => addState(QLNodeState.custom2);

  void blur() {
    removeState(QLNodeState.custom2);
    touch();
    if (!hasState(QLNodeState.sleeping)) validate();
  }

  QLFieldController<T> setMetaValue(String key, dynamic value) {
    updateMeta(key, value);
    return this;
  }

  QLFieldController<T> setHidden(bool value) {
    value ? hide() : show();
    return this;
  }

  QLFieldController<T> setDisabledValue(bool value) {
    value ? addState(QLNodeState.disabled) : removeState(QLNodeState.disabled);
    return this;
  }

  QLFieldController<T> lock() {
    addState(QLNodeState.hardwareLocked);
    return this;
  }

  QLFieldController<T> unlock() {
    removeState(QLNodeState.hardwareLocked);
    return this;
  }

  @override
  void reset() {
    super.reset();
    removeState(QLNodeState.custom1); // 🚀 Force strip Touched state
    removeState(QLNodeState.custom2); // 🚀 Force strip Focused state
  }

  @override
  dynamic serialize() => isHidden ? null : data.value;
}

class QLTextController extends QLFieldController<String> {
  QLTextController({
    required super.path,
    required super.form,
    super.initialValue = '',
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });

  void append(String text, {bool shouldValidate = true}) =>
      mutate('${data.value}$text', shouldValidate: shouldValidate);

  void prepend(String text, {bool shouldValidate = true}) =>
      mutate('$text${data.value}', shouldValidate: shouldValidate);

  void replaceRange(
    int start,
    int end,
    String replacement, {
    bool shouldValidate = true,
  }) {
    final current = data.value;
    final safeStart = start.clamp(0, current.length);
    final safeEnd = end.clamp(safeStart, current.length);
    mutate(
      current.replaceRange(safeStart, safeEnd, replacement),
      shouldValidate: shouldValidate,
    );
  }

  void insertAt(int index, String text, {bool shouldValidate = true}) {
    final current = data.value;
    final safeIndex = index.clamp(0, current.length);
    mutate(
      current.replaceRange(safeIndex, safeIndex, text),
      shouldValidate: shouldValidate,
    );
  }

  void clear({bool shouldValidate = true}) =>
      mutate('', shouldValidate: shouldValidate);
}

class QLTextAreaController extends QLTextController {
  final int minLines;
  final int maxLines;
  final bool expands;
  final int? maxLength;

  QLTextAreaController({
    required super.path,
    required super.form,
    String initialValue = '',
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
    this.minLines = 3,
    this.maxLines = 8,
    this.expands = false,
    this.maxLength,
  }) : super(initialValue: _trimInitial(initialValue, maxLength));

  static String _trimInitial(String value, int? maxLength) {
    if (maxLength != null && value.length > maxLength) {
      return value.substring(0, maxLength);
    }
    return value;
  }

  @override
  void mutate(String newValue, {bool shouldValidate = true}) {
    if (maxLength != null && newValue.length > maxLength!) {
      newValue = newValue.substring(0, maxLength!);
    }
    super.mutate(newValue, shouldValidate: shouldValidate);
  }
}

class QLNumberController extends QLFieldController<double> {
  QLNumberController({
    required super.path,
    required super.form,
    super.initialValue = 0.0,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

int _qlClampSmallInt(dynamic value) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null) return 0;
  return parsed.clamp(-32768, 32767);
}

BigInt _qlBigIntOf(dynamic value) {
  if (value is BigInt) return value;
  if (value is int) return BigInt.from(value);
  if (value is num) return BigInt.from(value.toInt());
  return BigInt.tryParse(value?.toString() ?? '') ?? BigInt.zero;
}

String _qlCharOf(dynamic value) {
  final text = value?.toString() ?? '';
  return text.isEmpty ? '' : text.substring(0, 1);
}

String _qlDecimalOf(dynamic value) => value?.toString().trim() ?? '';

double _qlNumberOf(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}

Map<String, dynamic> _qlMediaOf(dynamic value, {String? mediaType}) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String) {
    return <String, dynamic>{
      'src': value,
      'url': value,
      if (mediaType != null) 'mediaType': mediaType,
    };
  }
  return <String, dynamic>{
    'value': value,
    if (mediaType != null) 'mediaType': mediaType,
  };
}

class QLSmallIntController extends QLFieldController<int> {
  QLSmallIntController({
    required super.path,
    required super.form,
    int initialValue = 0,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialValue: _qlClampSmallInt(initialValue));
}

class QLBigIntController extends QLFieldController<BigInt> {
  QLBigIntController({
    required super.path,
    required super.form,
    BigInt? initialValue,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialValue: initialValue ?? BigInt.zero);
}

class QLDecimalController extends QLFieldController<String> {
  QLDecimalController({
    required super.path,
    required super.form,
    String initialValue = '',
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialValue: _qlDecimalOf(initialValue));
}

class QLCharController extends QLFieldController<String> {
  QLCharController({
    required super.path,
    required super.form,
    String initialValue = '',
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialValue: _qlCharOf(initialValue));
}

class QLFlagsController extends QLFieldController<int> {
  QLFlagsController({
    required super.path,
    required super.form,
    int initialValue = 0,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialValue: initialValue);

  void enableFlag(int flag) => mutate(data.value | flag);
  void disableFlag(int flag) => mutate(data.value & ~flag);
  void toggleFlag(int flag) => mutate(data.value ^ flag);
}

class QLMediaController extends QLFieldController<Map<String, dynamic>?> {
  QLMediaController({
    required super.path,
    required super.form,
    Map<String, dynamic>? initialValue,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialValue: initialValue == null ? null : _qlMediaOf(initialValue));

  void setMedia(Map<String, dynamic>? value) =>
      mutate(value == null ? null : _qlMediaOf(value));
  void setSource(String source, {String? mediaType}) =>
      mutate(_qlMediaOf(source, mediaType: mediaType));

  @override
  dynamic serialize() => isHidden ? null : (data.value == null ? null : Map<String, dynamic>.from(data.value!));
}

class QLSmallIntArrayController extends QLScalarArrayController<int> {
  QLSmallIntArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLBigIntArrayController extends QLScalarArrayController<BigInt> {
  QLBigIntArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLDecimalArrayController extends QLScalarArrayController<String> {
  QLDecimalArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLCharArrayController extends QLScalarArrayController<String> {
  QLCharArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLFlagsArrayController extends QLScalarArrayController<int> {
  QLFlagsArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLMediaArrayController extends QLScalarArrayController<Map<String, dynamic>> {
  QLMediaArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLBoolController extends QLFieldController<bool> {
  QLBoolController({
    required super.path,
    required super.form,
    super.initialValue = false,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });

  void toggle() => mutate(!data.value);
}

class QLDateController extends QLFieldController<DateTime?> {
  QLDateController({
    required super.path,
    required super.form,
    super.initialValue,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });

  @override
  dynamic serialize() => isHidden ? null : data.value?.toIso8601String();
}


T _normalizeEnumInitial<T>(T initialValue, List<T> allowedValues) {
  if (allowedValues.isEmpty) return initialValue;
  if (allowedValues.contains(initialValue)) return initialValue;
  return allowedValues.first;
}

List<T> _sanitizeEnumItems<T>(Iterable<T> items, List<T> allowedValues) {
  if (allowedValues.isEmpty) return List<T>.from(items, growable: false);
  return items.where(allowedValues.contains).toList(growable: false);
}

class QLEnumController<T> extends QLFieldController<T> {
  final List<T> allowedValues;

  QLEnumController({
    required String path,
    required QLFormController form,
    required T initialValue,
    required this.allowedValues,
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    QLValueTransform<T>? transform,
    List<QLValidator<T>> syncValidators = const [],
    List<QLAsyncValidator<T>> asyncValidators = const [],
    List<QLDataMiddleware<T>> middlewares = const [],
    List<QLFastMiddleware<T>> fastMiddlewares = const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
  }) : super(
          path: path,
          form: form,
          initialValue: _normalizeEnumInitial(initialValue, allowedValues),
          sleepPolicy: sleepPolicy,
          transform: transform,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          middlewares: middlewares,
          fastMiddlewares: fastMiddlewares,
          dependencies: dependencies,
          initialMeta: initialMeta,
        );

  @override
  void mutate(T newValue, {bool shouldValidate = true}) {
    if (!allowedValues.contains(newValue)) return;
    super.mutate(newValue, shouldValidate: shouldValidate);
  }
}

class QLSecureController extends QLFieldController<String> {
  late final QLSignal<bool> isObscured;

  QLSecureController({
    required super.path,
    required super.form,
    super.initialValue = '',
    bool initiallyObscured = true,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) {
    isObscured = QLSignal<bool>(initiallyObscured);
  }

  void toggleObscure() {
    isObscured.setSilent(!isObscured.value);
    isObscured.forceNotify();
  }

  void secureWipe({int wipeLength = 32}) {
    mutateFast(List.filled(wipeLength, '0').join(), applyMiddleware: false);
    mutateFast('', applyMiddleware: false);
  }

  @override
  void dispose() {
    isObscured.dispose();
    super.dispose();
  }
}

class QLLookupController extends QLFieldController<String?> {
  final Future<Map<String, dynamic>?> Function(String id) resolver;
  late final QLSignal<Map<String, dynamic>?> document;
  int _lookupNonce = 0;

  QLLookupController({
    required super.path,
    required super.form,
    required this.resolver,
    super.initialValue,
    super.sleepPolicy,
    super.syncValidators,
    super.asyncValidators,
    super.dependencies,
    super.initialMeta,
  }) {
    document = QLSignal<Map<String, dynamic>?>(null);
    if (initialValue != null) _resolveId(initialValue!);
  }

  @override
  void mutate(String? newValue, {bool shouldValidate = true}) {
    final before = data.value;
    super.mutate(newValue, shouldValidate: shouldValidate);
    if (before != newValue) _resolveId(newValue);
  }

  Future<void> _resolveId(String? id) async {
    final nonce = ++_lookupNonce;
    if (id == null) {
      document.setSilent(null);
      document.forceNotify();
      return;
    }

    addState(QLNodeState.syncing);
    try {
      final doc = await resolver(id);
      if (isDisposed || nonce != _lookupNonce) return;
      document.setSilent(doc);
      document.forceNotify();
    } finally {
      if (!isDisposed && nonce == _lookupNonce) {
        removeState(QLNodeState.syncing);
      }
    }
  }

  @override
  void dispose() {
    _lookupNonce++;
    document.dispose();
    super.dispose();
  }
}

class QLGroupController extends QLFieldController<Map<String, dynamic>> {
  final List<QLFieldBuilder> schema;

  QLGroupController({
    required String path,
    required QLFormController form,
    required this.schema,
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    List<QLValidator<Map<String, dynamic>>> syncValidators = const [],
    List<QLAsyncValidator<Map<String, dynamic>>> asyncValidators = const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
  }) : super(
          path: path,
          form: form,
          initialValue: const {},
          sleepPolicy: sleepPolicy,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          dependencies: dependencies,
          initialMeta: initialMeta,
        ) {
    for (final builder in schema) {
      builder(path, form);
    }
  }

  Iterable<QLDataNode<dynamic>> get childNodes => form.nodesWithPrefix(path);

  QLDataNode<dynamic>? childNode(String relativePath) =>
      form.getNode('$path.$relativePath');

  QLFieldController<T>? field<T>(String relativePath) =>
      form.getNode('$path.$relativePath') as QLFieldController<T>?;

  void setField(String relativePath, dynamic value) {
    final node = form.getNode('$path.$relativePath');
    if (node == null) return;
    if (node is QLFieldController<double> && value is int) {
      node.mutate(value.toDouble());
      return;
    }
    if (node is QLFieldController<double> && value is num) {
      node.mutate(value.toDouble());
      return;
    }
    node.mutate(value);
  }

  Future<void> validateChildren() => form.validateChildrenOf(path);

  @override
  dynamic serialize() => null;
}

class QLBlockInstance {
  final dynamic id;
  final String blockType;
  final String? key;

  const QLBlockInstance({required this.id, required this.blockType, this.key});
}

class QLBlockArrayController extends QLFieldController<List<QLBlockInstance>> {
  static int _globalBlockIdCounter = 0; // 🚀 FIX: Guaranteed Unique IDs
  final Map<String, List<QLFieldBuilder>> blockSchemas;
  final dynamic Function(int) idGenerator;
  final List<QLBlockInstance> _blocks;
  final List<QLBlockInstance> _initialBlocks;

  QLBlockArrayController({
    required String path,
    required QLFormController form,
    required this.blockSchemas,
    List<QLBlockInstance> initialBlocks = const [],
    dynamic Function(int)? idGenerator,
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    List<QLValidator<List<QLBlockInstance>>> syncValidators = const [],
    List<QLAsyncValidator<List<QLBlockInstance>>> asyncValidators = const [],
    List<QLDataMiddleware<List<QLBlockInstance>>> middlewares = const [],
    List<QLFastMiddleware<List<QLBlockInstance>>> fastMiddlewares = const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
  })  : _blocks = List<QLBlockInstance>.from(initialBlocks, growable: true),
        _initialBlocks =
            List<QLBlockInstance>.from(initialBlocks, growable: false),
        idGenerator = idGenerator ??
            ((i) =>
                'blk_${DateTime.now().microsecondsSinceEpoch}_${_globalBlockIdCounter++}'),
        super(
          path: path,
          form: form,
          initialValue: List<QLBlockInstance>.unmodifiable(initialBlocks),
          sleepPolicy: sleepPolicy,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          middlewares: middlewares,
          fastMiddlewares: fastMiddlewares,
          dependencies: dependencies,
          initialMeta: initialMeta,
        ) {
    data.setSilent(List<QLBlockInstance>.unmodifiable(_blocks));
    data.forceNotify();
  }

  String _keyFor(dynamic id) =>
      'b_${id.toString().replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')}';

  void _enterHiddenBuildScope() => form.enterVirtualBuildScope();
  void _exitHiddenBuildScope() => form.exitVirtualBuildScope();

  String blockPathFor(QLBlockInstance block) =>
      '$path.${block.key ?? _keyFor(block.id)}';

  Iterable<QLDataNode<dynamic>> blockNodes(QLBlockInstance block) =>
      form.nodesWithPrefix(blockPathFor(block));

  QLDataNode<dynamic>? blockNode(String blockKeyOrId, String relativePath) =>
      form.getNode('$path.$blockKeyOrId.$relativePath');

  void setBlockField(
          QLBlockInstance block, String relativePath, dynamic value) =>
      form.getNode('${blockPathFor(block)}.$relativePath')?.mutate(value);

  Future<void> validateBlock(QLBlockInstance block) =>
      form.validateChildrenOf(blockPathFor(block));

  void _notifyChanged({bool shouldValidate = true}) {
    final next = List<QLBlockInstance>.unmodifiable(_blocks);
    data.setSilent(next);
    stateFlags.setSilent(stateFlags.value | QLNodeState.dirty);
    stateFlags.forceNotify();
    data.forceNotify();
    if (!hasState(QLNodeState.sleeping) && shouldValidate) validate();
    form.notifyNodeMutated(path);
  }

  void _buildBlockSchema(String blockPath, String blockType) {
    final schema = blockSchemas[blockType];
    if (schema == null) return;
    _enterHiddenBuildScope();
    try {
      for (final builder in schema) {
        builder(blockPath, form);
      }
    } finally {
      _exitHiddenBuildScope();
    }
  }

  void addBlock(String blockType) {
    final schema = blockSchemas[blockType];
    if (schema == null) return;

    final newId = idGenerator(_blocks.length);
    final key = _keyFor(newId);
    final block = QLBlockInstance(id: newId, blockType: blockType, key: key);

    _blocks.add(block);
    _buildBlockSchema('$path.$key', blockType);
    _notifyChanged();
  }

  void insertBlockAt(int index, String blockType) {
    if (index < 0 || index > _blocks.length) return;
    final schema = blockSchemas[blockType];
    if (schema == null) return;

    final newId = idGenerator(index);
    final key = _keyFor(newId);
    final block = QLBlockInstance(id: newId, blockType: blockType, key: key);

    _blocks.insert(index, block);
    _buildBlockSchema('$path.$key', blockType);
    _notifyChanged();
  }

  void moveBlock(int from, int to) {
    if (from < 0 || to < 0 || from >= _blocks.length || to >= _blocks.length) {
      return;
    }
    if (from == to) return;
    final block = _blocks.removeAt(from);
    _blocks.insert(to, block);
    _notifyChanged();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _blocks.length) return;

    final block = _blocks.removeAt(index);
    final blockPath = blockPathFor(block);

    final keysToSweep = form.nodePathsWithPrefix(blockPath).toList();
    for (final k in keysToSweep) {
      form.unregister(k);
    }

    _notifyChanged();
  }

  Map<String, dynamic> _materializeBlock(QLBlockInstance block) {
    final blockKey = block.key ?? _keyFor(block.id);
    final prefix = '$path.$blockKey';

    return {
      'id': block.id,
      'blockType': block.blockType,
      'key': blockKey,
      'data': form.extractSubgraph(prefix, raw: true),
    };
  }

  @override
  dynamic serialize() => _blocks.map(_materializeBlock).toList(growable: false);

  @override
  void mutate(List<QLBlockInstance> newValue, {bool shouldValidate = true}) {
    _blocks
      ..clear()
      ..addAll(newValue);
    _notifyChanged(shouldValidate: shouldValidate);
  }

  @override
  void reset() {
    final currentBlocks = List<QLBlockInstance>.from(_blocks, growable: false);
    for (final block in currentBlocks) {
      final blockPath = blockPathFor(block);
      final keysToSweep = form.nodePathsWithPrefix(blockPath).toList();
      for (final k in keysToSweep) {
        form.unregister(k);
      }
    }

    _blocks
      ..clear()
      ..addAll(_initialBlocks);

    data.setSilent(List<QLBlockInstance>.unmodifiable(_blocks));
    data.forceNotify();

    stateFlags.setSilent(QLNodeState.idle);
    stateFlags.forceNotify();

    errors.setSilent(const []);
    errors.forceNotify();

    for (final block in _blocks) {
      _buildBlockSchema(blockPathFor(block), block.blockType);
    }

    if (!hasState(QLNodeState.sleeping)) validate();
  }
}

class QLScalarArrayController<T> extends QLFieldController<List<T>> {
  final List<T> _items;
  final List<T> _initialItems;
  late final UnmodifiableListView<T> _view;

  QLScalarArrayController({
    required String path,
    required QLFormController form,
    List<T> initialItems = const [],
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    QLValueTransform<List<T>>? transform,
    List<QLValidator<List<T>>> syncValidators = const [],
    List<QLAsyncValidator<List<T>>> asyncValidators = const [],
    List<QLDataMiddleware<List<T>>> middlewares = const [],
    List<QLFastMiddleware<List<T>>> fastMiddlewares = const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
  })  : _items = List<T>.from(initialItems, growable: true),
        _initialItems = List<T>.from(initialItems, growable: false),
        super(
          path: path,
          form: form,
          initialValue: UnmodifiableListView<T>(List<T>.from(initialItems)),
          sleepPolicy: sleepPolicy,
          transform: transform,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          middlewares: middlewares,
          fastMiddlewares: fastMiddlewares,
          dependencies: dependencies,
          initialMeta: initialMeta,
        ) {
    _view = UnmodifiableListView<T>(_items);
    data.setSilent(_view);
    data.forceNotify();
  }

  void _emit({bool shouldValidate = true}) {
    data.setSilent(_view);
    stateFlags.setSilent(stateFlags.value | QLNodeState.dirty);
    stateFlags.forceNotify();
    data.forceNotify();
    if (!hasState(QLNodeState.sleeping) && shouldValidate) validate();
    form.notifyNodeMutated(path);
  }

  @override
  void mutate(List<T> newValue, {bool shouldValidate = true}) {
    final processed = transform != null ? transform!(newValue) : newValue;
    _items
      ..clear()
      ..addAll(processed);
    _emit(shouldValidate: shouldValidate);
  }

  void setItems(Iterable<T> items, {bool shouldValidate = true}) {
    _items
      ..clear()
      ..addAll(items);
    _emit(shouldValidate: shouldValidate);
  }

  void push(T item) {
    _items.add(item);
    _emit();
  }

  void addAll(Iterable<T> items) {
    if (items.isEmpty) return;
    _items.addAll(items);
    _emit();
  }

  void insertAt(int index, T item) {
    if (index < 0 || index > _items.length) return;
    _items.insert(index, item);
    _emit();
  }

  void insertAllAt(int index, Iterable<T> items) {
    if (index < 0 || index > _items.length || items.isEmpty) return;
    _items.insertAll(index, items);
    _emit();
  }

  void updateAt(int index, T item) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = item;
    _emit();
  }

  void replaceRange(int start, int end, Iterable<T> replacement) {
    final safeStart = start.clamp(0, _items.length);
    final safeEnd = end.clamp(safeStart, _items.length);
    _items.replaceRange(safeStart, safeEnd, replacement);
    _emit();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    _emit();
  }

  void removeRange(int start, int end) {
    final safeStart = start.clamp(0, _items.length);
    final safeEnd = end.clamp(safeStart, _items.length);
    if (safeStart == safeEnd) return;
    _items.removeRange(safeStart, safeEnd);
    _emit();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _emit();
  }

  void swap(int a, int b) {
    if (a < 0 || b < 0 || a >= _items.length || b >= _items.length) return;
    final temp = _items[a];
    _items[a] = _items[b];
    _items[b] = temp;
    _emit();
  }

  @override
  void reset() {
    _items
      ..clear()
      ..addAll(_initialItems);
    data.setSilent(_view);
    data.forceNotify();
    stateFlags.setSilent(QLNodeState.idle);
    stateFlags.forceNotify();
    errors.setSilent(const []);
    errors.forceNotify();
    if (!hasState(QLNodeState.sleeping)) validate();
  }

  @override
  dynamic serialize() => _view;
}

class QLTextArrayController extends QLScalarArrayController<String> {
  QLTextArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });
}

class QLNumberArrayController extends QLScalarArrayController<double> {
  QLNumberArrayController({
    required super.path,
    required super.form,
    List<double> initialItems = const [],
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  }) : super(initialItems: initialItems.map(_qlNumberOf).toList(growable: false));
}

class QLDateArrayController extends QLScalarArrayController<DateTime> {
  QLDateArrayController({
    required super.path,
    required super.form,
    super.initialItems,
    super.sleepPolicy,
    super.transform,
    super.syncValidators,
    super.asyncValidators,
    super.middlewares,
    super.fastMiddlewares,
    super.dependencies,
    super.initialMeta,
  });

  @override
  dynamic serialize() =>
      _view.map((e) => e.toIso8601String()).toList(growable: false);
}

class QLEnumArrayController<T> extends QLScalarArrayController<T> {
  final List<T> allowedValues;

  QLEnumArrayController({
    required String path,
    required QLFormController form,
    required this.allowedValues,
    List<T> initialItems = const [],
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    QLValueTransform<List<T>>? transform,
    List<QLValidator<List<T>>> syncValidators = const [],
    List<QLAsyncValidator<List<T>>> asyncValidators = const [],
    List<QLDataMiddleware<List<T>>> middlewares = const [],
    List<QLFastMiddleware<List<T>>> fastMiddlewares = const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
  }) : super(
          path: path,
          form: form,
          initialItems: _sanitizeEnumItems(initialItems, allowedValues),
          sleepPolicy: sleepPolicy,
          transform: transform,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          middlewares: middlewares,
          fastMiddlewares: fastMiddlewares,
          dependencies: dependencies,
          initialMeta: initialMeta,
        );

  @override
  void mutate(List<T> newValue, {bool shouldValidate = true}) {
    if (newValue.any((e) => !allowedValues.contains(e))) return;
    super.mutate(newValue, shouldValidate: shouldValidate);
  }
}

class QLTreeNode<T> {
  final dynamic id;
  final dynamic parentId;
  final String nodeType;
  final T payload;

  const QLTreeNode({
    required this.id,
    required this.parentId,
    required this.payload,
    this.nodeType = 'default',
  });

  QLTreeNode<T> copyWith({
    dynamic parentId,
    String? nodeType,
    T? payload,
  }) =>
      QLTreeNode<T>(
        id: id,
        parentId: parentId ?? this.parentId,
        nodeType: nodeType ?? this.nodeType,
        payload: payload ?? this.payload,
      );
}

class QLTreeController<T>
    extends QLFieldController<Map<dynamic, QLTreeNode<T>>> {
  final Map<String, List<QLFieldBuilder>> nodeSchemas;
  final List<QLTreeNode<T>> _initialNodes;
  final Map<dynamic, QLTreeNode<T>> _nodes;
  final Map<dynamic, List<dynamic>> _children;
  late final UnmodifiableMapView<dynamic, QLTreeNode<T>> _view;
  late final UnmodifiableMapView<dynamic, List<dynamic>> _childrenView;
  late final QLSignal<Map<dynamic, List<dynamic>>> childrenGraph;

  QLTreeController({
    required String path,
    required QLFormController form,
    required this.nodeSchemas,
    List<QLTreeNode<T>> initialNodes = const [],
    QLSleepPolicy sleepPolicy = QLSleepPolicy.manual,
    List<QLValidator<Map<dynamic, QLTreeNode<T>>>> syncValidators = const [],
    List<QLAsyncValidator<Map<dynamic, QLTreeNode<T>>>> asyncValidators =
        const [],
    List<QLDataMiddleware<Map<dynamic, QLTreeNode<T>>>> middlewares = const [],
    List<QLFastMiddleware<Map<dynamic, QLTreeNode<T>>>> fastMiddlewares =
        const [],
    List<String> dependencies = const [],
    Map<String, dynamic> initialMeta = const {},
  })  : _nodes = <dynamic, QLTreeNode<T>>{
          for (final n in initialNodes) n.id: n
        },
        _children = <dynamic, List<dynamic>>{},
        _initialNodes = List<QLTreeNode<T>>.from(initialNodes, growable: false),
        super(
          path: path,
          form: form,
          initialValue: Map<dynamic, QLTreeNode<T>>.unmodifiable({
            for (final n in initialNodes) n.id: n,
          }),
          sleepPolicy: sleepPolicy,
          syncValidators: syncValidators,
          asyncValidators: asyncValidators,
          middlewares: middlewares,
          fastMiddlewares: fastMiddlewares,
          dependencies: dependencies,
          initialMeta: initialMeta,
        ) {
    for (final node in initialNodes) {
      _children.putIfAbsent(node.parentId, () => <dynamic>[]).add(node.id);
    }

    _view = UnmodifiableMapView<dynamic, QLTreeNode<T>>(_nodes);
    _childrenView = UnmodifiableMapView<dynamic, List<dynamic>>(_children);
    childrenGraph = QLSignal<Map<dynamic, List<dynamic>>>(_childrenView);
    data.setSilent(_view);
    data.forceNotify();
    childrenGraph.forceNotify();

    for (final node in initialNodes) {
      _buildNodeFields(node);
    }
  }

  String _nodeKey(dynamic id) =>
      'n_${id.toString().replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_')}';

  String nodePathFor(dynamic id) => '$path.${_nodeKey(id)}';

  Iterable<QLDataNode<dynamic>> nodeChildren(dynamic id) =>
      form.nodesWithPrefix(nodePathFor(id));

  QLDataNode<dynamic>? nodeField(dynamic id, String relativePath) =>
      form.getNode('${nodePathFor(id)}.$relativePath');

  void setNodeField(dynamic id, String relativePath, dynamic value) =>
      form.getNode('${nodePathFor(id)}.$relativePath')?.mutate(value);

  Future<void> validateNode(dynamic id) =>
      form.validateChildrenOf(nodePathFor(id));

  void _buildNodeFields(QLTreeNode<T> node) {
    final schema = nodeSchemas[node.nodeType] ?? const <QLFieldBuilder>[];
    final basePath = nodePathFor(node.id);

    form.enterVirtualBuildScope();
    try {
      for (final builder in schema) {
        builder(basePath, form);
      }
    } finally {
      form.exitVirtualBuildScope();
    }
  }

  void _sweepNodeFields(dynamic id) {
    final basePath = nodePathFor(id);
    final keys = form.nodePathsWithPrefix(basePath).toList();
    for (final key in keys) {
      form.unregister(key);
    }
  }

  void _attachChild(dynamic parentId, dynamic childId) {
    _children.putIfAbsent(parentId, () => <dynamic>[]).add(childId);
  }

  void _detachChild(dynamic parentId, dynamic childId) {
    final list = _children[parentId];
    if (list == null) return;
    list.remove(childId);
    if (list.isEmpty) _children.remove(parentId);
  }

  void _emit({bool shouldValidate = true}) {
    data.setSilent(_view);
    data.forceNotify();
    childrenGraph.forceNotify();
    stateFlags.setSilent(stateFlags.value | QLNodeState.dirty);
    stateFlags.forceNotify();
    if (!hasState(QLNodeState.sleeping) && shouldValidate) validate();
    form.notifyNodeMutated(path);
  }

  void addNode(QLTreeNode<T> node) {
    if (_nodes.containsKey(node.id)) return;
    _nodes[node.id] = node;
    _attachChild(node.parentId, node.id);
    _buildNodeFields(node);
    _emit();
    unawaited(validateNode(node.id));
  }

  void updateNodePayload(dynamic id, T newPayload) {
    final node = _nodes[id];
    if (node == null) return;
    _nodes[id] = node.copyWith(payload: newPayload);
    _emit();
  }

  void setNodeType(dynamic id, String nodeType) {
    final node = _nodes[id];
    if (node == null) return;
    if (node.nodeType == nodeType) return;

    _sweepNodeFields(id);
    _nodes[id] = node.copyWith(nodeType: nodeType);
    _buildNodeFields(_nodes[id]!);
    _emit();
    unawaited(validateNode(id));
  }

  void moveNode(dynamic id, dynamic newParentId) {
    final node = _nodes[id];
    if (node == null) return;
    if (node.parentId == newParentId) return;
    _detachChild(node.parentId, id);
    _nodes[id] = node.copyWith(parentId: newParentId);
    _attachChild(newParentId, id);
    _emit();
  }

  void removeNode(dynamic id) {
    final node = _nodes[id];
    if (node == null) return;

    final descendants = List<dynamic>.from(_children[id] ?? const []);
    for (final childId in descendants) {
      removeNode(childId);
    }

    _sweepNodeFields(id);
    _detachChild(node.parentId, id);
    _nodes.remove(id);
    _children.remove(id);
    _emit();
  }

  List<dynamic> childrenOf(dynamic parentId) =>
      List<dynamic>.unmodifiable(_children[parentId] ?? const []);

  @override
  dynamic serialize() => _nodes.values
      .map(
        (n) => {
          'id': n.id,
          'parentId': n.parentId,
          'nodeType': n.nodeType,
          'payload': n.payload,
          'fields': form.extractSubgraph(nodePathFor(n.id), raw: true),
        },
      )
      .toList(growable: false);

  @override
  void reset() {
    for (final id in _nodes.keys.toList(growable: false)) {
      _sweepNodeFields(id);
    }

    _nodes
      ..clear()
      ..addEntries(_initialNodes.map((n) => MapEntry(n.id, n)));
    _children.clear();
    for (final node in _initialNodes) {
      _children.putIfAbsent(node.parentId, () => <dynamic>[]).add(node.id);
    }

    for (final node in _initialNodes) {
      _buildNodeFields(node);
    }

    data.setSilent(_view);
    data.forceNotify();
    childrenGraph.forceNotify();
    stateFlags.setSilent(QLNodeState.idle);
    stateFlags.forceNotify();
    errors.setSilent(const []);
    errors.forceNotify();
    if (!hasState(QLNodeState.sleeping)) validate();
  }

  @override
  void dispose() {
    childrenGraph.dispose();
    super.dispose();
  }
}

class QLSchemaFormFactory {
  static void build(
    QLSchemaBlueprint blueprint,
    QLFormController form, {
    String basePath = '',
  }) {
    for (final spec in blueprint.rootFields) {
      _buildSpec(spec, form, basePath);
    }
  }

  static void _buildSpec(
    QLSchemaFieldSpec spec,
    QLFormController form,
    String basePath,
  ) {
    final path = basePath.isEmpty ? spec.path : '$basePath.${spec.name}';

    final customBuilder = spec.meta['builder'];
    if (customBuilder is QLFieldBuilder) {
      customBuilder(path, form);
      return;
    }

    switch (spec.type) {
      case QLFieldType.string:
        if (spec.hasMany) {
          QLTextArrayController(
            path: path,
            form: form,
            initialItems: List<String>.from(
              (spec.meta['initialValue'] as List?)?.map((e) => e.toString()) ??
                  const [],
            ),
          );
        } else {
          QLTextController(
            path: path,
            form: form,
            initialValue: spec.meta['initialValue']?.toString() ?? '',
            sleepPolicy: spec.meta['sleepPolicy'] as QLSleepPolicy? ??
                QLSleepPolicy.manual,
            syncValidators: const [],
            asyncValidators: const [],
          );
        }
        break;
      case QLFieldType.textarea:
        if (spec.hasMany) {
          QLTextArrayController(
            path: path,
            form: form,
            initialItems: List<String>.from(
              (spec.meta['initialValue'] as List?)?.map((e) => e.toString()) ??
                  const [],
            ),
          );
        } else {
          QLTextAreaController(
            path: path,
            form: form,
            initialValue: spec.meta['initialValue']?.toString() ?? '',
            maxLength: spec.meta['maxLength'] as int?,
          );
        }
        break;
      case QLFieldType.number:
        if (spec.hasMany) {
          QLNumberArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map(_qlNumberOf)
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLNumberController(
            path: path,
            form: form,
            initialValue: (spec.meta['initialValue'] as num?)?.toDouble() ?? 0.0,
          );
        }
        break;
      case QLFieldType.bigInt:
        if (spec.hasMany) {
          QLBigIntArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map(_qlBigIntOf)
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLBigIntController(
            path: path,
            form: form,
            initialValue: _qlBigIntOf(spec.meta['initialValue']),
          );
        }
        break;
      case QLFieldType.smallInt:
        if (spec.hasMany) {
          QLSmallIntArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map(_qlClampSmallInt)
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLSmallIntController(
            path: path,
            form: form,
            initialValue: _qlClampSmallInt(spec.meta['initialValue']),
          );
        }
        break;
      case QLFieldType.decimal:
        if (spec.hasMany) {
          QLDecimalArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map(_qlDecimalOf)
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLDecimalController(
            path: path,
            form: form,
            initialValue: _qlDecimalOf(spec.meta['initialValue']),
          );
        }
        break;
      case QLFieldType.char:
        if (spec.hasMany) {
          QLCharArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map(_qlCharOf)
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLCharController(
            path: path,
            form: form,
            initialValue: _qlCharOf(spec.meta['initialValue']),
          );
        }
        break;
      case QLFieldType.flags:
        if (spec.hasMany) {
          QLFlagsArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map((e) => _qlClampSmallInt(e))
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLFlagsController(
            path: path,
            form: form,
            initialValue: _qlClampSmallInt(spec.meta['initialValue']),
          );
        }
        break;
      case QLFieldType.media:
        if (spec.hasMany) {
          QLMediaArrayController(
            path: path,
            form: form,
            initialItems: (spec.meta['initialValue'] as List?)
                    ?.map((e) => _qlMediaOf(e, mediaType: spec.mediaType))
                    .toList(growable: false) ??
                const [],
          );
        } else {
          QLMediaController(
            path: path,
            form: form,
            initialValue: spec.meta['initialValue'] is Map
                ? _qlMediaOf(spec.meta['initialValue'], mediaType: spec.mediaType)
                : spec.meta['initialValue'] == null
                    ? null
                    : _qlMediaOf(spec.meta['initialValue'], mediaType: spec.mediaType),
          );
        }
        break;
      case QLFieldType.boolean:
        QLBoolController(
          path: path,
          form: form,
          initialValue: spec.meta['initialValue'] as bool? ?? false,
        );
        break;
      case QLFieldType.date:
        QLDateController(
          path: path,
          form: form,
          initialValue: spec.meta['initialValue'] is DateTime
              ? spec.meta['initialValue'] as DateTime
              : DateTime.tryParse(spec.meta['initialValue']?.toString() ?? ''),
        );
        break;
      case QLFieldType.enumeration:
        QLEnumController<dynamic>(
          path: path,
          form: form,
          initialValue: spec.meta['initialValue'],
          allowedValues: List<dynamic>.from(spec.options),
        );
        break;
      case QLFieldType.secure:
        QLSecureController(
          path: path,
          form: form,
          initialValue: spec.meta['initialValue']?.toString() ?? '',
          initiallyObscured: spec.meta['initiallyObscured'] as bool? ?? true,
        );
        break;
      case QLFieldType.lookup:
      case QLFieldType.relation:
      case QLFieldType.relationship:
        final resolver = spec.meta['resolver'];
        if (resolver is Future<Map<String, dynamic>?> Function(String id)) {
          QLLookupController(
            path: path,
            form: form,
            resolver: resolver,
            initialValue: spec.meta['initialValue']?.toString(),
          );
        } else {
          QLTextController(
            path: path,
            form: form,
            initialValue: spec.meta['initialValue']?.toString() ?? '',
          );
        }
        break;
      case QLFieldType.object:
        final builders = <QLFieldBuilder>[
          for (final child in spec.children)
            (childPath, childForm) => _buildSpec(
                  child,
                  childForm,
                  '',
                ),
        ];
        QLGroupController(
          path: path,
          form: form,
          schema: builders,
        );
        break;
      case QLFieldType.array:
        if (spec.itemSpec != null) {
          switch (spec.itemSpec!.type) {
            case QLFieldType.bigInt:
              QLBigIntArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map(_qlBigIntOf)
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.smallInt:
              QLSmallIntArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map(_qlClampSmallInt)
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.decimal:
              QLDecimalArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map(_qlDecimalOf)
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.char:
              QLCharArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map(_qlCharOf)
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.flags:
              QLFlagsArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map((e) => _qlClampSmallInt(e))
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.media:
              QLMediaArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map((e) => _qlMediaOf(e, mediaType: spec.mediaType))
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.number:
              QLNumberArrayController(
                path: path,
                form: form,
                initialItems: (spec.meta['initialValue'] as List?)
                        ?.map(_qlNumberOf)
                        .toList(growable: false) ??
                    const [],
              );
              break;
            case QLFieldType.date:
              QLDateArrayController(
                path: path,
                form: form,
                initialItems:
                    List<DateTime>.from(spec.meta['initialValue'] ?? const []),
              );
              break;
            case QLFieldType.enumeration:
              QLEnumArrayController<dynamic>(
                path: path,
                form: form,
                allowedValues: List<dynamic>.from(spec.itemSpec!.options),
                initialItems:
                    List<dynamic>.from(spec.meta['initialValue'] ?? const []),
              );
              break;
            default:
              QLTextArrayController(
                path: path,
                form: form,
                initialItems: List<String>.from(
                  (spec.meta['initialValue'] as List?)
                          ?.map((e) => e.toString()) ??
                      const [],
                ),
              );
          }
        } else {
          QLTextArrayController(
            path: path,
            form: form,
            initialItems: List<String>.from(
              (spec.meta['initialValue'] as List?)?.map((e) => e.toString()) ??
                  const [],
            ),
          );
        }
        break;
      case QLFieldType.block:
        final blockSchemas = <String, List<QLFieldBuilder>>{};
        final blocksMeta = spec.meta['blockSchemas'];
        if (blocksMeta is Map) {
          for (final entry in blocksMeta.entries) {
            final childBuilders = <QLFieldBuilder>[];
            final childSpec = entry.value;
            if (childSpec is Map) {
              final compiled = QLSchemaCompiler.compile(
                '__inline_${entry.key}',
                {'root': childSpec},
              );
              for (final f in compiled.rootFields.first.children) {
                childBuilders.add((p, frm) => _buildSpec(f, frm, ''));
              }
            }
            blockSchemas[entry.key] = childBuilders;
          }
        }
        QLBlockArrayController(
          path: path,
          form: form,
          blockSchemas: blockSchemas,
        );
        break;
      case QLFieldType.tree:
        final nodeSchemas = <String, List<QLFieldBuilder>>{};
        final metaSchemas = spec.meta['nodeSchemas'];
        if (metaSchemas is Map) {
          for (final entry in metaSchemas.entries) {
            final childBuilders = <QLFieldBuilder>[];
            final childSpec = entry.value;
            if (childSpec is Map) {
              final compiled = QLSchemaCompiler.compile(
                '__tree_${entry.key}',
                {'root': childSpec},
              );
              for (final f in compiled.rootFields.first.children) {
                childBuilders.add((p, frm) => _buildSpec(f, frm, ''));
              }
            }
            nodeSchemas[entry.key] = childBuilders;
          }
        }
        QLTreeController<dynamic>(
          path: path,
          form: form,
          nodeSchemas: nodeSchemas,
        );
        break;
      default:
        QLTextController(
          path: path,
          form: form,
          initialValue: spec.meta['initialValue']?.toString() ?? '',
        );
    }
  }
}
