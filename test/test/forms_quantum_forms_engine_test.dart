import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('Text controllers mutate, slice and serialize correctly', () {
    final form = QLFormController();
    final text = QLTextController(path: 'title', form: form, initialValue: 'a');

    text.append('b');
    expect(text.data.value, 'ab');

    text.prepend('z');
    expect(text.data.value, 'zab');

    text.replaceRange(1, 2, 'X');
    expect(text.data.value, 'zXb');

    text.insertAt(1, 'Y');
    expect(text.data.value, 'zYXb');

    text.clear();
    expect(text.data.value, '');
    expect(text.serialize(), '');
  });

  test('Number, bool and date controllers expose expected helpers', () {
    final form = QLFormController();
    final number =
        QLNumberController(path: 'age', form: form, initialValue: 3.5);
    final boolCtrl = QLBoolController(path: 'active', form: form);
    final date = QLDateController(
        path: 'publishedAt',
        form: form,
        initialValue: DateTime.utc(2024, 1, 2));

    expect(number.data.value, 3.5);
    boolCtrl.toggle();
    expect(boolCtrl.data.value, isTrue);
    expect(date.serialize(), '2024-01-02T00:00:00.000Z');
  });

  test(
      'Enum controllers normalize invalid initial values and reject invalid mutations',
      () {
    final form = QLFormController();
    final enumCtrl = QLEnumController<String>(
      path: 'status',
      form: form,
      initialValue: 'invalid',
      allowedValues: ['draft', 'live'],
    );

    expect(enumCtrl.data.value, 'draft');
    enumCtrl.mutate('live');
    expect(enumCtrl.data.value, 'live');
    enumCtrl.mutate('broken');
    expect(enumCtrl.data.value, 'live');
  });

  test('Secure controllers toggle obscuring and wipe secrets', () {
    final form = QLFormController();
    final secure =
        QLSecureController(path: 'secret', form: form, initialValue: 'hello');
    expect(secure.isObscured.value, isTrue);
    secure.toggleObscure();
    expect(secure.isObscured.value, isFalse);
    secure.secureWipe(wipeLength: 6);
    expect(secure.data.value, '');
  });

  test('Lookup controller resolves documents asynchronously and resets on null',
      () async {
    final form = QLFormController();
    final lookup = QLLookupController(
      path: 'customerId',
      form: form,
      resolver: (id) async => {'id': id, 'name': 'Ada'},
      initialValue: 'u1',
    );

    await Future<void>.delayed(Duration.zero);
    expect(lookup.document.value?['name'], 'Ada');

    lookup.mutate(null);
    await Future<void>.delayed(Duration.zero);
    expect(lookup.document.value, isNull);
  });

  test('Group controller exposes nested child nodes and serializes as null',
      () {
    final form = QLFormController();
    final group = QLGroupController(
      path: 'profile',
      form: form,
      schema: [
        (basePath, form) => QLTextController(
            path: '$basePath.name', form: form, initialValue: 'Ada'),
        (basePath, form) => QLNumberController(
            path: '$basePath.age', form: form, initialValue: 7),
      ],
    );

    expect(group.childNode('name'), isNotNull);
    expect(group.field<String>('name')!.data.value, 'Ada');
    group.setField('age', 12.5);
    expect(group.field<num>('age')!.data.value, 12.5);
    expect(group.serialize(), isNull);
  });

  test('Form controller validates and resets children deterministically',
      () async {
    final form = QLFormController();
    final requiredText = QLTextController(
      path: 'name',
      form: form,
      initialValue: '',
      syncValidators: [QLValidators.required()],
    );

    requiredText.mutate('Ada');
    await form.resolveGraph();
    expect(form.isValid, isTrue);
    form.resetForm();
    expect(requiredText.data.value, '');
  });

  test('Schema form factory builds nodes from compiled schema', () {
    final blueprint =
        QLSchemaCompiler.compile('formProduct', sampleSchemaDefinition());
    final form = QLFormController();
    QLSchemaFormFactory.build(blueprint, form);

    expect(form.getNode('id'), isNotNull);
    expect(form.getNode('name'), isNotNull);
    expect(form.getNode('status'), isNotNull);
    expect(form.getNode('profile.city'), isNotNull);
  });

  test('Text area initial values are trimmed to maxLength eagerly', () {
    final form = QLFormController();
    final area = QLTextAreaController(
      path: 'notes',
      form: form,
      initialValue: 'abcdef',
      maxLength: 5,
    );

    expect(area.data.value, 'abcde');
    area.mutate('123456');
    expect(area.data.value, '12345');
  });

  test('Schema form factory can build controllers from arrays and lookups', () {
    final blueprint = QLSchemaCompiler.compile('formAdvanced', {
      'kind': {
        'type': 'enum',
        'options': ['a', 'b'],
        'initialValue': 'b'
      },
      'notes': {'type': 'textarea', 'maxLength': 5, 'initialValue': 'abcdef'},
      'owner': {
        'type': 'lookup',
        'initialValue': 'u1',
        'resolver': (String id) async => {'id': id}
      },
    });
    final form = QLFormController();
    QLSchemaFormFactory.build(blueprint, form);

    expect((form.getNode('kind') as QLEnumController).data.value, 'b');
    expect(
        (form.getNode('notes') as QLTextAreaController).data.value.length, 5);
    expect(form.getNode('owner'), isA<QLLookupController>());
    expect(form.getNode('kind'), isNotNull);
    expect(form.getNode('notes'), isNotNull);
    expect(form.getNode('owner'), isNotNull);
  });
}
