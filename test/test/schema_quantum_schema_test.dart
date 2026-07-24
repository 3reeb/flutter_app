import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QLBlockPayload exposes map-style access and stable copies', () {
    const payload = QLBlockPayload(
      blockType: 'card',
      data: {'title': 'Hello', 'count': 3},
    );

    expect(payload['title'], 'Hello');
    expect(payload.containsKey('count'), isTrue);

    final map = payload.toMap();
    expect(map['blockType'], 'card');
    expect(map['data'], isA<Map<String, dynamic>>());
    expect((map['data'] as Map<String, dynamic>)['title'], 'Hello');
  });

  test('QLSchemaCompiler compiles, parses and serializes nested schemas', () {
    final blueprint =
        QLSchemaCompiler.compile('product', sampleSchemaDefinition());
    expect(blueprint.name, 'product');
    expect(blueprint.getIndex('id'), greaterThanOrEqualTo(0));
    expect(blueprint.field('name'), isNotNull);
    expect(blueprint.fieldPaths(), contains('profile.city'));

    final parsed = blueprint.parse({
      'id': 'p1',
      'name': 'Camera',
      'age': 12,
      'active': true,
      'status': 'live',
      'profile': {'city': 'Aden', 'zip': '1000'},
      'tags': ['new', 'sale'],
    });
    expect(parsed['id'], 'p1');
    expect(parsed['name'], 'Camera');
    expect(parsed['score'], 22.0);

    final serialized = blueprint.serialize(parsed);
    expect(serialized['id'], 'p1');
    expect(serialized['name'], 'Camera');
  });

  test('QLSchemaBlueprint validate reports required, enum and range issues',
      () {
    final blueprint =
        QLSchemaCompiler.compile('validation', sampleSchemaDefinition());
    final errors = blueprint.validate({
      'id': '',
      'name': 'A',
      'age': 200,
      'status': 'broken',
    });
    expect(errors, isNotEmpty);
    expect(errors.any((e) => e.contains('id: required')), isTrue);
    expect(errors.any((e) => e.contains('name: min length')), isTrue);
    expect(errors.any((e) => e.contains('age: max')), isTrue);
    expect(errors.any((e) => e.contains('status: invalid option')), isTrue);
  });

  test('QLSchemaRegistry compiles raw blueprints and resolves pending schemas',
      () {
    final registry = QLSchemaRegistry.instance;
    registry.registerRaw('product', sampleSchemaDefinition());
    registry.compileAllPending();

    expect(registry.hasSchema('product'), isTrue);
    final resolved = registry.getSchema('product');
    expect(resolved, isNotNull);
    expect(resolved!.field('status'), isNotNull);
  });

  test('QLSchemaCompiler resolves block schemas and array items', () {
    final blueprint = QLSchemaCompiler.compile('container', {
      'content': {
        'type': 'block',
        'hasMany': true,
        'allowedBlocks': ['textBlock'],
        'items': {
          'type': 'object',
          'fields': {
            'blockType': {'type': 'string'},
            'data': {
              'type': 'object',
              'fields': {
                'text': {'type': 'string', 'required': true},
              },
            },
          },
        },
      },
    });

    final validation = blueprint.validate({
      'content': [
        {
          'blockType': 'textBlock',
          'data': {'text': 'hello'},
        },
      ],
    });
    expect(validation, isEmpty);
  });

  test('QLSchemaCompiler compile cache returns the same blueprint instance',
      () {
    final first = QLSchemaCompiler.compile('cached', sampleSchemaDefinition());
    final second = QLSchemaCompiler.resolveSchema('cached');
    expect(identical(first, second), isTrue);
  });
}
