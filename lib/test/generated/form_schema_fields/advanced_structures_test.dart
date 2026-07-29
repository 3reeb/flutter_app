// test/engine/advanced_structures_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Advanced Memory Structures: Boundary & Graph Safety', () {
    test('QLBlockArrayController moveBlock safely clamps out-of-bound indices',
        () {
      final form = QLFormController();
      final blocks = QLBlockArrayController(
          path: 'content',
          form: form,
          blockSchemas: {
            'A': [(p, f) {}]
          },
          idGenerator: (i) => 'b$i');

      blocks.addBlock('A'); // index 0
      blocks.addBlock('A'); // index 1
      blocks.addBlock('A'); // index 2

      // Invalid moves should fail silently, not crash
      blocks.moveBlock(-1, 5);
      expect(blocks.data.value[0].id, 'b0');

      blocks.moveBlock(0, 2); // Valid move
      expect(blocks.data.value[2].id, 'b0');
    });

    test(
        'QLTreeController setNodeType triggers dynamic re-build of schema paths',
        () {
      final form = QLFormController();
      final tree =
          QLTreeController<String>(path: 'tree', form: form, nodeSchemas: {
        'TypeA': [(p, f) => QLTextController(path: '$p.field_a', form: f)],
        'TypeB': [(p, f) => QLTextController(path: '$p.field_b', form: f)],
      });

      tree.addNode(const QLTreeNode(
          id: 'node1', parentId: null, payload: '', nodeType: 'TypeA'));

      expect(form.hasNode('tree.n_node1.field_a'), isTrue);
      expect(form.hasNode('tree.n_node1.field_b'), isFalse);

      // Swap Type Mid-Flight (Graph must purge field_a and build field_b)
      tree.setNodeType('node1', 'TypeB');

      expect(form.hasNode('tree.n_node1.field_a'), isFalse);
      expect(form.hasNode('tree.n_node1.field_b'), isTrue);
    });

    test('QLScalarArrayController replaceRange and swap constraints', () {
      final form = QLFormController();
      final array = QLSmallIntArrayController(
          path: 'nums', form: form, initialItems: [1, 2, 3, 4, 5]);

      array.replaceRange(1, 4, [9, 9]); // Replaces indices 1, 2, 3
      expect(array.data.value, [1, 9, 9, 5]);

      array.replaceRange(-5, 100, [0]); // Out of bounds clamped safely
      expect(array.data.value, [0]);
    });
  });
}
