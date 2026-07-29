// test/engine/graph_topology_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('QLFieldController: Async Validators & Middleware', () {
    test(
        'Async Validators use Nonces to prevent race conditions on rapid mutation',
        () async {
      final form = QLFormController();
      var executionCount = 0;

      final node = QLTextController(
          path: 'username',
          form: form,
          initialValue: '',
          asyncValidators: [
            (v, g) async {
              executionCount++;
              // Simulate slow network request
              await Future.delayed(const Duration(milliseconds: 50));
              if (v == 'taken') return const QLNodeError('Username taken');
              return null;
            }
          ]);

      // Rapidly mutate 3 times in a row.
      // Only the FINAL async result should be applied.
      node.mutate('taken');
      node.mutate('valid');
      node.mutate('taken');

      expect(node.hasState(QLNodeState.validating), isTrue);

      // Wait for all async calls to finish
      await Future.delayed(const Duration(milliseconds: 100));

      // Execution count is 3, but the engine should only accept the last nonce
      expect(executionCount, 3);
      expect(node.hasState(QLNodeState.validating), isFalse);
      expect(node.hasState(QLNodeState.hasError),
          isTrue); // Last mutation was 'taken'
    });

    test('Middlewares intercept and format data synchronously', () {
      final form = QLFormController();
      final node = QLTextController(
          path: 'code',
          form: form,
          initialValue: '',
          middlewares: [
            (incoming, current) => incoming.toUpperCase(),
            (incoming, current) => incoming.replaceAll(' ', '-')
          ]);

      node.mutate('hello world');
      expect(node.data.value, 'HELLO-WORLD');
    });

    test('bindStream hardware-locks field and processes incoming events',
        () async {
      final form = QLFormController();
      final node = QLTextController(path: 'sensor', form: form);
      final streamCtrl = StreamController<String>();

      node.bindStream(streamCtrl.stream);
      expect(node.hasState(QLNodeState.streaming), isTrue);
      expect(node.hasState(QLNodeState.hardwareLocked), isTrue);

      // Manual mutation is rejected due to hardware lock
      node.mutate('manual');
      expect(node.data.value, '');

      // Stream mutation succeeds
      streamCtrl.add('sensor_data_1');
      await Future.delayed(Duration.zero);
      expect(node.data.value, 'sensor_data_1');

      node.unbindStream();
      expect(node.hasState(QLNodeState.streaming), isFalse);
      expect(node.hasState(QLNodeState.hardwareLocked), isFalse);
    });
  });
}
