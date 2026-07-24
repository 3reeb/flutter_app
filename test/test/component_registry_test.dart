import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  setUp(() {
    QuantumComponentRegistry.instance.clear();
  });

  test('QuantumComponentRegistry stores and retrieves builders', () {
    QuantumComponentRegistry.instance
        .register('text', (context, node, store) => const SizedBox.shrink());
    expect(QuantumComponentRegistry.instance.contains('text'), isTrue);
    expect(QuantumComponentRegistry.instance.get('text'), isNotNull);
  });

  test('QuantumComponentRegistry snapshot is isolated from mutation', () {
    QuantumComponentRegistry.instance
        .register('text', (context, node, store) => const SizedBox.shrink());
    final snap = QuantumComponentRegistry.instance.snapshot();
    expect(snap.containsKey('text'), isTrue);
    QuantumComponentRegistry.instance.remove('text');
    expect(snap.containsKey('text'), isTrue);
    expect(QuantumComponentRegistry.instance.contains('text'), isFalse);
  });
}
