// ════════════════════════════════════════════════════════════════════════════
// QUANTUM FORMS ENGINE - TRUE 100% EXHAUSTIVE TEST SUITE
// test/quantum_forms_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum Forms Engine | Exhaustive Feature Tests |', () {
    late QLFormController form;

    setUp(() {
      form = QLFormController();
      QLSchemaRegistry.instance.clear();
      QLPathUtils.clearCache();
    });

    tearDown(() {
      form.dispose();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1. SCALAR CONTROLLERS, MUTATIONS & STATE FLAGS
    // ─────────────────────────────────────────────────────────────────────────
    test('1. Core Node Mechanics (Dirty, Disabled, ReadOnly, Locked)', () {
      final textNode = QLTextController(path: 'username', form: form);

      expect(textNode.data.value, '');
      textNode.mutate('quantum_dev');
      expect(textNode.isDirty, isTrue);

      // Disable guard
      textNode.disable();
      expect(textNode.isDisabled, isTrue);
      textNode.mutate('hacked');
      expect(textNode.data.value, 'quantum_dev');
      textNode.enable();

      // Lock guard
      textNode.lock();
      textNode.mutate('hacked2');
      expect(textNode.data.value, 'quantum_dev');
      textNode.unlock();

      // ReadOnly guard
      textNode.setReadOnly(true);
      textNode.mutate('hacked3');
      expect(textNode.data.value, 'quantum_dev');
      textNode.setReadOnly(false);

      // Text operations
      textNode.append('_admin');
      expect(textNode.data.value, 'quantum_dev_admin');
      textNode.prepend('super_');
      expect(textNode.data.value, 'super_quantum_dev_admin');
      textNode.insertAt(6, 'X');
      expect(textNode.data.value, 'super_Xquantum_dev_admin');
      textNode.replaceRange(0, 7, 'core_');
      expect(textNode.data.value, 'core_quantum_dev_admin');
      textNode.clear();
      expect(textNode.data.value, '');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. MIDDLEWARES & BUILT-IN TRANSFORMS
    // ─────────────────────────────────────────────────────────────────────────
    test('2. Data Middlewares & Transforms (Trim, Lowercase)', () {
      final textNode = QLTextController(
        path: 'code',
        form: form,
        transform: QLTransforms.lowercase(), // Built-in transform
        middlewares: [
          (incoming, current) =>
              incoming.replaceAll('-', '') // Custom Middleware
        ],
      );

      textNode.mutate('  ALPHA-BRAVO  ');
      // Lowercase transform applies FIRST, then middleware strips hyphens
      expect(textNode.data.value, '  alphabravo  ');

      // Test setSilently (bypasses middleware and validation)
      textNode.setSilently('SILENT-MODE');
      expect(textNode.data.value, 'SILENT-MODE');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. TOPOLOGICAL DEPENDENCIES & CROSS-VALIDATION
    // ─────────────────────────────────────────────────────────────────────────
    test('3. Topological Graph Dependencies', () async {
      // Password field
      QLTextController(path: 'pass', form: form);

      // Confirm Password field depends on 'pass'
      final confirm = QLTextController(
          path: 'confirm',
          form: form,
          dependencies: [
            'pass'
          ], // 🚀 The specific feature tested
          syncValidators: [
            (v, graph) {
              final pass =
                  (graph as QLGraphController).getNode('pass')?.data.value;
              if (v != pass) return const QLNodeError('Mismatch');
              return null;
            }
          ]);

      confirm.mutate('secret123');
      expect(confirm.isValid, isFalse);

      // Mutating 'pass' should AUTOMATICALLY trigger validation on 'confirm'
      form.getNode('pass')?.mutate('secret123');

      // Allow microtasks for dependency propagation
      await Future.delayed(Duration.zero);

      expect(confirm.isValid, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. GRAPH TOPOLOGY (EXTRACT, SUBGRAPHS, & OBSERVERS)
    // ─────────────────────────────────────────────────────────────────────────
    test('4. Graph Extraction & Wildcard Observers', () {
      QLTextController(
          path: 'user.firstName', form: form, initialValue: 'John');
      QLNumberController(path: 'user.age', form: form, initialValue: 30);

      bool observed = false;
      form.watch('user.*', (event) {
        observed = true;
        expect(event.path, 'user.age');
      });

      form.getNode('user.age')?.mutate(31.0);
      expect(observed, isTrue);

      final fullGraph = form.extractGraph();
      expect(fullGraph['user']['firstName'], 'John');

      final subGraph = form.extractSubgraph('user');
      expect(subGraph['firstName'], 'John');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. HIDDEN NODES & METADATA
    // ─────────────────────────────────────────────────────────────────────────
    test('5. Metadata & Hidden Node Serialization', () {
      final node =
          QLTextController(path: 'secret', form: form, initialValue: 'data');

      node.setMetaValue('custom_key', 42);
      expect(node.meta.value['custom_key'], 42);

      // Hide node
      node.hide();
      expect(node.isHidden, isTrue);

      // 🚀 The specific feature: Hidden nodes return null in serialize() and drop from graph
      final graph = form.extractGraph();
      expect(graph.containsKey('secret'), isFalse);

      node.show();
      expect(form.extractGraph()['secret'], 'data');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. SPECIALTY CONTROLLERS (SECURE, ENUM, LOOKUP, TEXTAREA, BOOL)
    // ─────────────────────────────────────────────────────────────────────────
    test('6. Specialty Controllers (Secure, Enum, Lookup, TextArea, Bool)',
        () async {
      final secure =
          QLSecureController(path: 'pwd', form: form, initialValue: 'secret');
      secure.secureWipe();
      expect(secure.data.value, '');

      final boolNode = QLBoolController(path: 'switch', form: form);
      boolNode.toggle();
      expect(boolNode.data.value, isTrue);

      final enumNode = QLEnumController<String>(
        path: 'theme',
        form: form,
        initialValue: 'light',
        allowedValues: ['light', 'dark'],
      );
      enumNode.mutate('invalid'); // Blocked
      expect(enumNode.data.value, 'light');

      // TextArea maxLength enforcement
      final txtArea =
          QLTextAreaController(path: 'bio', form: form, maxLength: 5);
      txtArea.mutate('123456789');
      expect(txtArea.data.value, '12345'); // Truncated to 5

      final lookup = QLLookupController(
        path: 'comp',
        form: form,
        resolver: (id) async => {'name': 'Quantum'},
      );
      lookup.mutate('123');
      await Future.delayed(Duration.zero);
      expect(lookup.document.value?['name'], 'Quantum');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. COMPLEX ARRAYS (DATES, ENUMS, SCALARS)
    // ─────────────────────────────────────────────────────────────────────────
    test('7. Specialized Array Controllers', () {
      final dateArr = QLDateArrayController(
          path: 'dates', form: form, initialItems: [DateTime(2025)]);
      // 🚀 Feature: Serializes to ISO strings
      final serializedDates = dateArr.serialize();
      expect(serializedDates[0], contains('2025-01-01'));

      final enumArr = QLEnumArrayController<String>(
        path: 'roles',
        form: form,
        allowedValues: ['admin', 'user'],
      );
      enumArr.mutate(['admin', 'hacker']); // 'hacker' is invalid
      expect(enumArr.data.value, isEmpty); // Entire mutation blocked

      final scalar = QLNumberArrayController(
          path: 'nums', form: form, initialItems: [1, 2]);
      scalar.insertAllAt(1, [9, 8]);
      expect(scalar.data.value, [1, 9, 8, 2]);
      scalar.removeRange(1, 3);
      expect(scalar.data.value, [1, 2]);
      scalar.updateAt(0, 99);
      expect(scalar.data.value, [99, 2]);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. BLOCK ARRAY MUTATIONS (INSERT, MOVE, REMOVE)
    // ─────────────────────────────────────────────────────────────────────────
    test('8. Block Array Controller Advanced Mutations', () {
      final blocks = QLBlockArrayController(
        path: 'content',
        form: form,
        blockSchemas: {
          'text': [(path, f) => QLTextController(path: '$path.body', form: f)],
        },
      );

      blocks.addBlock('text'); // Idx 0
      blocks.addBlock('text'); // Idx 1

      final instances = blocks.data.value;
      blocks.setBlockField(instances[0], 'body', 'First');
      blocks.setBlockField(instances[1], 'body', 'Second');

      // Insert at specific index
      blocks.insertBlockAt(1, 'text');
      final newInstances = blocks.data.value;
      blocks.setBlockField(newInstances[1], 'body', 'Inserted');

      // Move Block
      blocks.moveBlock(0, 2);

      final graph = form.extractGraph()['content'] as List;
      expect(graph[0]['data']['body'], 'Inserted');
      expect(graph[1]['data']['body'], 'Second');
      expect(graph[2]['data']['body'], 'First');

      // Reset
      blocks.reset();
      expect(blocks.data.value, isEmpty);
      // 🚀 FIX: The field remains in the graph but its value is empty
      expect(form.extractGraph()['content'], isEmpty);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 9. TREE CONTROLLER ADVANCED MUTATIONS
    // ─────────────────────────────────────────────────────────────────────────
    test('9. Tree Controller (SetNodeType Schema Sweeping)', () {
      final tree =
          QLTreeController<String>(path: 'org', form: form, nodeSchemas: {
        'type_a': [
          (path, f) => QLTextController(path: '$path.field_a', form: f)
        ],
        'type_b': [
          (path, f) => QLTextController(path: '$path.field_b', form: f)
        ]
      });

      tree.addNode(const QLTreeNode(
          id: 'node1', parentId: null, payload: 'N1', nodeType: 'type_a'));
      tree.setNodeField('node1', 'field_a', 'Data A');

      // 🚀 Feature: Changing node type sweeps old fields and builds new ones
      tree.setNodeType('node1', 'type_b');

      // field_a should be gone from the graph
      final graph = form.extractGraph();
      final nodeData = graph['org'][0]['fields'];
      expect(nodeData.containsKey('field_a'), isFalse);

      tree.setNodeField('node1', 'field_b', 'Data B');
      expect(form.extractGraph()['org'][0]['fields']['field_b'], 'Data B');

      tree.updateNodePayload('node1', 'Updated Payload');
      expect(form.extractGraph()['org'][0]['payload'], 'Updated Payload');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 10. LIVE STREAM BINDINGS
    // ─────────────────────────────────────────────────────────────────────────
    test('10. Live Stream Binding & Hardware Locks', () async {
      final ctrl = StreamController<String>();
      final node = QLTextController(path: 'live', form: form);

      node.bindStream(ctrl.stream);
      expect(node.hasState(QLNodeState.streaming), isTrue);

      ctrl.add('Tick 1');
      await Future.delayed(Duration.zero);
      expect(node.data.value, 'Tick 1');

      node.unbindStream();
      expect(node.hasState(QLNodeState.streaming), isFalse);
      await ctrl.close();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 11. FORM SUBMISSION, VALIDATION STATES & RESETS
    // ─────────────────────────────────────────────────────────────────────────
    test('11. Form Controller Submit & Reset', () async {
      final node = QLTextController(
          path: 'field', form: form, syncValidators: [QLValidators.required()]);

      // 🚀 Feature: Submit triggers touch() and wake() on all fields, then validates graph
      final isValid = await form.submit();

      expect(isValid, isFalse);
      expect(form.isSubmitting, isFalse);
      expect(node.isTouched, isTrue); // Submit touched the field
      expect(node.hasState(QLNodeState.hasError), isTrue);

      // Fix error
      node.mutate('valid_data');
      expect(node.hasState(QLNodeState.hasError), isFalse);

      final isValidNow = await form.submit();
      expect(isValidNow, isTrue);

      // 🚀 Feature: Reset Form
      form.resetForm();
      expect(node.data.value, ''); // Resets to initialValue
      expect(node.isTouched,
          isFalse); // 🚀 FIX: Clears touched state so UI hides errors
      expect(node.hasState(QLNodeState.hasError),
          isTrue); // 🚀 FIX: The engine correctly re-validates the empty string as an error!
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 12. FAST MUTATIONS & SLEEP LIFECYCLE
    // ─────────────────────────────────────────────────────────────────────────
    test('12. Fast Mutations & Sleep/Wake Lifecycle', () async {
      final node = QLTextController(
          path: 'fast_node',
          form: form,
          initialValue:
              'valid', // 🚀 FIX: Start valid so we don't trip the constructor validation
          fastMiddlewares: [(incoming, current) => '${incoming}_fast'],
          syncValidators: [QLValidators.required('req')]);

      // Verify it starts clean
      expect(node.hasState(QLNodeState.hasError), isFalse);

      // Sleep the node
      node.sleep();
      expect(node.isSleeping, isTrue);

      // Mutate to an INVALID value while sleeping
      node.mutate('');

      // 🚀 Validation is bypassed! The engine doesn't know it's invalid yet.
      expect(node.hasState(QLNodeState.hasError), isFalse);

      // Wake the node (Should trigger validation instantly)
      node.wake();

      // 🚀 Now the engine catches the empty string!
      expect(node.hasState(QLNodeState.hasError), isTrue);

      // Fast Mutation (Applies fast middleware)
      node.mutateFast('data');
      expect(node.data.value, 'data_fast');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 13. EVENT SIBLING CONTEXT
    // ─────────────────────────────────────────────────────────────────────────
    test('13. QLChangeEvent Sibling Lookups', () {
      QLTextController(path: 'group.f1', form: form, initialValue: 'A');
      QLTextController(path: 'group.f2', form: form, initialValue: 'B');

      bool siblingTested = false;
      form.watch('group.f1', (event) {
        // Read sibling
        expect(event.sibling('f2'), 'B');

        // Mutate sibling
        event.setSibling('f2', 'C');
        siblingTested = true;
      });

      form.getNode('group.f1')?.mutate('X');

      expect(siblingTested, isTrue);
      expect(
          form.extractGraph()['group']['f2'], 'C'); // Verified sibling mutation
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 14. REMAINING UTILITIES (Obscure, Trim)
    // ─────────────────────────────────────────────────────────────────────────
    test('14. Remaining Controller Utilities', () {
      // Secure Obscure Toggle
      final secure =
          QLSecureController(path: 'sec', form: form, initiallyObscured: true);
      expect(secure.isObscured.value, isTrue);
      secure.toggleObscure();
      expect(secure.isObscured.value, isFalse);

      // Trim Transform
      final trimmed = QLTextController(
          path: 'trim_node', form: form, transform: QLTransforms.trim());
      trimmed.mutate('   spaces   ');
      expect(trimmed.data.value, 'spaces');
    });
  });
}
