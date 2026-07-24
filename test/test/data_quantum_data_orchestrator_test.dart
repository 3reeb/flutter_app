import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('bootstrapString registers modules, state, and nested slices', () async {
    final manifest = {
      'module': 'orch',
      'state': {'title': 'boot'},
      'modules': {
        'child': {
          'module': 'orch.child',
          'state': {'count': 3},
        },
      },
      'slices': {
        'profile': {
          'state': {'name': 'Ada'},
        },
      },
    };

    await QuantumDataOrchestrator.bootstrapString(jsonEncode(manifest), null);

    expect(QLModuleRegistry.instance.exists('orch'), isTrue);
    expect(QLModuleRegistry.instance.exists('orch.child'), isTrue);
    expect(QLStoreRegistry.instance.get('orch').get('title'), 'boot');
    expect(QLStoreRegistry.instance.get('orch.child').get('count'), 3);
    expect(QLStoreRegistry.instance.get('orch.profile').get('name'), 'Ada');
  });
}
