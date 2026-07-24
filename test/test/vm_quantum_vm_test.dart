import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QuantumVM stores aliases and slot metadata', () {
    QuantumVM.instance.defineAlias('card', 'box:col', defaultProps: {'gap': 8});
    QuantumVM.instance.registerDefaultSlotNodes('card', {
      'header': {'type': 'text'}
    });
    QuantumVM.instance.registerSlotTypes('card', {'header': 'text'});

    expect(QuantumVM.instance.getAlias('card')!['type'], 'box:col');
    expect(QuantumVM.instance.getDefaultSlotNodes('card'), isNotNull);
    expect(QuantumVM.instance.getSlotTypes('card')!['header'], 'text');
  });

  test('QuantumVM compileStyle survives a cold engine reset and caches output',
      () {
    QEngine.instance.dispose();
    final first = QuantumVM.instance.compileStyle('text-center font-bold');
    final second = QuantumVM.instance.compileStyle('text-center font-bold');
    expect(first.id, second.id);
  });

  test('QLBlueprint.fromJson preserves nested children and props', () {
    final blueprint = QLBlueprint.fromJson(sampleBlueprintJson());
    expect(blueprint.props['gap'], 8);
    expect(blueprint.children, hasLength(2));
    expect(blueprint.children[0].props['text'], 'one');
  });

  test(
      'QuantumVM caches and clears runtime data without breaking future compiles',
      () {
    QuantumVM.instance.clearRuntimeCaches();
    final style = QuantumVM.instance.compileStyle('rounded-lg bg-[#ffffff]');
    expect(style, isNotNull);

    QuantumVM.instance.dispose();
    expect(QuantumVM.instance.compileStyle('text-sm'), isNotNull);
  });
}
