import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  setUpAll(() {
    QuantumVM.instance.initialize();
  });

  setUp(() {
    QLDataNode.globalNodes.clear();
    QLStoreRegistry.instance.clearAll();
    QLSchemaRegistry.instance.clear();
    QLDataSourceRegistry.instance.clear();
  });

  group('SSOT Proxy: High-Performance Type Coercion Matrix', () {
    test(
        'Automatically coerces bizarre API payloads into exact UI primitive types without crashing',
        () async {
      final form = QLFormController();
      final store = QLStoreRegistry.instance.get('coercion_test');

      final textNode = QLTextController(path: 'profile.name', form: form)
        ..bindStore(store, 'profile.name');
      final numNode = QLNumberController(path: 'profile.age', form: form)
        ..bindStore(store, 'profile.age');
      final boolNode = QLBoolController(path: 'profile.active', form: form)
        ..bindStore(store, 'profile.active');
      final intNode = QLSmallIntController(path: 'profile.level', form: form)
        ..bindStore(store, 'profile.level');

      final matrix = [
        [42, '42', 42.0, false, 42],
        ['42', '42', 42.0, false, 42],
        [3.14, '3.14', 3.14, false, 3],
        ['true', 'true', 0.0, true, 0],
        [1, '1', 1.0, true, 1],
      ];

      for (final row in matrix) {
        final raw = row[0];

        // 🚀 Fix: Use standard 'set' so the signals fire and update the UI!
        store.set('profile.name', raw);
        store.set('profile.age', raw);
        store.set('profile.active', raw);
        store.set('profile.level', raw);

        // Allow microtask queue to process the reactive listeners
        await Future.delayed(Duration.zero);

        expect(textNode.data.value, row[1]);
        expect(numNode.data.value, row[2]);
        expect(boolNode.data.value, row[3]);
        expect(intNode.data.value, row[4]);
      }
    });
  });

  group('Global Action Registry: Autonomous API & Form Routing', () {
    test(
        'form.load autonomously fetches from Global Store and deeply hydrates the UI',
        () async {
      final blueprint = QLSchemaCompiler.compile('User', {
        "profile": {
          "type": "object",
          "fields": {"first": "string", "last": "string"}
        },
        "tags": {"type": "array"}
      });
      final form = QLFormController();
      QLSchemaFormFactory.build(blueprint, form, basePath: 'user_form');

      final store = QLStoreRegistry.instance.get('ui_store');
      QLDataNode.globalNodes.forEach((k, v) => v.bindStore(store, k));

      // 🚀 Fix: Put the payload into the global store directly
      store.set('user_form', {
        'profile': {'first': 'Omega', 'last': 'Weapon'},
        'tags': ['admin', 'beta']
      });

      // 🚀 Fix: Use storePath instead of a fake dataSource
      await QuantumVM.instance.triggerActions([
        {"action": "form.load", "path": "user_form", "storePath": "user_form"}
      ], const _DummyContext());

      expect(
          (QLDataNode.globalNodes['user_form.profile.first']
                  as QLTextController)
              .data
              .value,
          'Omega');
      expect(
          (QLDataNode.globalNodes['user_form.tags'] as QLTextArrayController)
              .data
              .value,
          ['admin', 'beta']);
    });

    test(
        'form.submit aborts on validation failure, but returns validated JSON payload automatically on success',
        () async {
      final blueprint = QLSchemaCompiler.compile('Reg', {
        "email": {
          "type": "string",
          "required": true,
          "pattern": "^[^@]+@[^@]+\\.[^@]+\$"
        },
      });
      final form = QLFormController();
      QLSchemaFormFactory.build(blueprint, form, basePath: 'reg_form');
      final store = QLStoreRegistry.instance.get('reg_store');
      QLDataNode.globalNodes.forEach((k, v) => v.bindStore(store, k));

      // 1. Attempt Submit (Should Fail because email is empty)
      try {
        await QuantumVM.instance.triggerActions([
          {"action": "form.submit", "path": "reg_form"}
        ], const _DummyContext());
        fail('Should have thrown validation error');
      } catch (e) {
        expect(e, isA<QuantumSecurityException>());
      }

      // 2. Fix Form and Submit (Should Succeed)
      (QLDataNode.globalNodes['reg_form.email'] as QLTextController)
          .mutate('test@quantum.com');

      // 🚀 FIX: Allow the Dart event loop to process the SSOT transaction block!
      await Future.delayed(Duration.zero);

      final env = <String, dynamic>{};

      await QuantumVM.instance.triggerActions([
        {"action": "form.submit", "path": "reg_form"}
      ], const _DummyContext(), env: env);

      final payload = env[r'$lastResult'];

      expect(payload, isNotNull);
      expect(
          payload, isA<Map<String, dynamic>>()); // Guarantee it extracted a Map
      expect(payload['email'], 'test@quantum.com');
    });
  });
}

class _DummyContext implements BuildContext {
  const _DummyContext();
  @override
  bool get mounted => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
