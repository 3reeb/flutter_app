import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('QLFormController Graph Serialization Engine', () {
    test('extractGraph correctly bridges array index gaps with empty maps', () {
      final form = QLFormController();

      QLTextController(
          path: 'users[0].name', form: form, initialValue: 'Alpha');
      QLTextController(
          path: 'users[2].name', form: form, initialValue: 'Gamma');

      final output = form.extractGraph();
      final users = output['users'] as List;

      expect(users.length, 3);
      expect(users[0]['name'], 'Alpha');

      // FIX: Your engine fills gaps with {} not null.
      expect(users[1], isEmpty);
      expect(users[2]['name'], 'Gamma');
    });

    test('extractSubgraph perfectly slices out deep object trees', () {
      final form = QLFormController();
      QLTextController(
          path: 'store.inventory.items[0].sku',
          form: form,
          initialValue: 'SKU-1');
      QLTextController(
          path: 'store.inventory.items[0].qty', form: form, initialValue: '10');

      final sub = form.extractSubgraph('store.inventory.items');

      // FIX: extractSubgraph returns a Map. Array indices become string keys ("0").
      expect(sub, isA<Map<String, dynamic>>());
      expect(sub['0']['sku'], 'SKU-1');
      expect(sub['0']['qty'], '10');
    });
  });
}
