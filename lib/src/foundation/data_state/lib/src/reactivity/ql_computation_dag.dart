import 'ql_signal.dart';
import 'ql_data_store.dart';

class QLComputationNode {
  final String targetKey;
  final QLSignal<dynamic> targetSignal;
  final List<String> dependencies;
  final dynamic Function(List<dynamic> values) calculator;
  final QLDataStore store;

  int evaluateCount = 0;
  bool _evaluating = false;

  QLComputationNode(
    this.targetKey,
    this.targetSignal,
    this.dependencies,
    this.calculator,
    this.store,
  );

  void evaluateSilent() {
    if (_evaluating) {
      throw StateError(
          'Circular dependency detected in computation node: $targetKey');
    }
    _evaluating = true;
    try {
      final values =
          dependencies.map((k) => store.get(k)).toList(growable: false);
      final result = calculator(values);
      evaluateCount++;

      if (EqualityComparer.equals(targetSignal.value, result)) return;

      targetSignal.setSilent(result);
      store.registerDirtySignal(targetSignal);
      store.registerTxDirtyKey(targetKey);
    } finally {
      _evaluating = false;
    }
  }
}
