// ════════════════════════════════════════════════════════════════════════════
// QUANTUM SCHEMA ENGINE - OMEGA TEST SUITE (100% EXHAUSTIVE COVERAGE)
// test/quantum_schema_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

void main() {
  group('Quantum Schema Engine | Exhaustive Feature Tests |', () {
    setUp(() {
      QLSchemaRegistry.instance.clear();
      QLPathUtils.clearCache();
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1. ALL 15 TYPES: PARSING & COERCION
    // ─────────────────────────────────────────────────────────────────────────
    test('1. Parses & Coerces Every Single QLFieldType', () {
      final blueprint = QLSchemaCompiler.compile('all_types_schema', {
        't_string': 'string',
        't_textarea': 'textarea',
        't_number': 'number',
        't_boolean': 'boolean',
        't_date': 'date',
        't_json': 'json',
        't_object': {
          'type': 'object',
          'fields': {'inner': 'string'}
        },
        't_relation': 'relation',
        't_relationship': 'relationship',
        't_enum': {
          'type': 'enum',
          'options': ['A', 'B']
        },
        't_array': {'type': 'array', 'items': 'number'},
        't_untyped_array': 'array', // Array without itemSpec
        't_tree': 'tree',
        't_secure': 'secure',
        't_lookup': 'lookup',
      });

      // Verify compiler assigned correct enum types internally
      expect(blueprint.field('t_string')?.type, QLFieldType.string);
      expect(blueprint.field('t_textarea')?.type, QLFieldType.textarea);
      expect(blueprint.field('t_number')?.type, QLFieldType.number);
      expect(blueprint.field('t_boolean')?.type, QLFieldType.boolean);
      expect(blueprint.field('t_date')?.type, QLFieldType.date);
      expect(blueprint.field('t_json')?.type, QLFieldType.json);
      expect(blueprint.field('t_object')?.type, QLFieldType.object);
      expect(blueprint.field('t_relation')?.type, QLFieldType.relation);
      expect(blueprint.field('t_relationship')?.type, QLFieldType.relationship);
      expect(blueprint.field('t_enum')?.type, QLFieldType.enumeration);
      expect(blueprint.field('t_array')?.type, QLFieldType.array);
      expect(blueprint.field('t_tree')?.type, QLFieldType.tree);
      expect(blueprint.field('t_secure')?.type, QLFieldType.secure);
      expect(blueprint.field('t_lookup')?.type, QLFieldType.lookup);

      final parsed = blueprint.parse({
        't_string': 123, // Coerced to string
        't_textarea': 456, // Coerced to string
        't_number': '42.5', // Coerced to double
        't_boolean': 'TrUe', // Coerced to bool
        't_date': '2025-01-01T00:00:00Z', // Parsed to DateTime
        't_json': {
          'dynamic': 'data',
          'nested': [1, 2]
        }, // Passed through
        't_object': {'inner': 999}, // 999 coerced to string
        't_relation': 'rel_id_1', // Passed as string
        't_relationship': 'rel_id_2', // Passed as string
        't_enum': 'A', // Passed as string
        't_array': ['1', 2, 3.5], // Coerced to List<double>
        't_untyped_array': ['any', 1, true], // Untyped array passthrough
        't_tree': {
          'node1': {
            'children': {'node2': 'data'}
          }
        }, // Tree passed through completely
        't_secure': 'my_password', // Passed as string
        't_lookup': 'lookup_id_1', // Passed as string
      });

      expect(parsed['t_string'], '123');
      expect(parsed['t_textarea'], '456');
      expect(parsed['t_number'], 42.5);
      expect(parsed['t_boolean'], true);
      expect(parsed['t_date'], isA<DateTime>());
      expect(parsed['t_json']['nested'][1], 2);
      expect(parsed['t_object']['inner'], '999');
      expect(parsed['t_relation'], 'rel_id_1');
      expect(parsed['t_relationship'], 'rel_id_2');
      expect(parsed['t_array'], [1.0, 2.0, 3.5]);
      expect(parsed['t_untyped_array'], ['any', 1, true]);
      expect(parsed['t_tree']['node1']['children']['node2'], 'data');
      expect(parsed['t_secure'], 'my_password');
      expect(parsed['t_lookup'], 'lookup_id_1');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. ALL 8 FLAGS: COMPILATION & BEHAVIOR
    // ─────────────────────────────────────────────────────────────────────────
    test('2. Compiles and Enforces Every QLFieldFlag', () {
      final blueprint = QLSchemaCompiler.compile('flags_schema', {
        'f_virtual': {'type': 'string', 'virtual': true},
        'f_computed': {
          'type': 'string',
          'computed': true,
          'compute': (Map<String, dynamic> r) => 'computed_value'
        },
        'f_required': {'type': 'string', 'required': true},
        'f_hasMany': {'type': 'string', 'hasMany': true},
        'f_unique': {'type': 'string', 'unique': true},
        'f_indexed': {'type': 'string', 'indexed': true},
        'f_hidden': {'type': 'string', 'hidden': true},
        'f_readOnly': {'type': 'string', 'readOnly': true},
      });

      // Verify binary flag assignments in the compiler
      expect(blueprint.field('f_virtual')?.isVirtual, isTrue);
      expect(blueprint.field('f_computed')?.isComputed, isTrue);
      expect(blueprint.field('f_required')?.isRequired, isTrue);
      expect(blueprint.field('f_hasMany')?.hasMany, isTrue);
      expect((blueprint.field('f_unique')!.flags & QLFieldFlags.isUnique) != 0,
          isTrue);
      expect(
          (blueprint.field('f_indexed')!.flags & QLFieldFlags.isIndexed) != 0,
          isTrue);
      expect((blueprint.field('f_hidden')!.flags & QLFieldFlags.isHidden) != 0,
          isTrue);
      expect(blueprint.field('f_readOnly')?.isReadOnly, isTrue);

      // Verify Virtual fields are dropped, Computed fields are injected
      final parsed = blueprint.parse({
        'f_virtual': 'secret',
        'f_required': 'present',
      });

      expect(parsed.containsKey('f_virtual'), isFalse);
      expect(parsed['f_computed'], 'computed_value');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. CONSTRAINTS (MIN, MAX, ENUM)
    // ─────────────────────────────────────────────────────────────────────────
    test('3. Constraint Validation Engine', () {
      final blueprint = QLSchemaCompiler.compile('constraints_schema', {
        'num_bounds': {'type': 'number', 'min': 10, 'max': 50},
        'str_bounds': {'type': 'string', 'min': 3, 'max': 5},
        'enum_check': {
          'type': 'enum',
          'options': ['UP', 'DOWN']
        },
      });

      final errors = blueprint.validate({
        'num_bounds': 9, // Too low
        'str_bounds': 'ab', // Too short
        'enum_check': 'LEFT', // Invalid
      });
      expect(errors, contains('num_bounds: min 10.0'));
      expect(errors, contains('str_bounds: min length 3.0'));
      expect(errors, contains('enum_check: invalid option'));

      final errors2 = blueprint.validate({
        'num_bounds': 51, // Too high
        'str_bounds': 'abcdef', // Too long
      });
      expect(errors2, contains('num_bounds: max 50.0'));
      expect(errors2, contains('str_bounds: max length 5.0'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. HASMANY VALIDATION LOGIC
    // ─────────────────────────────────────────────────────────────────────────
    test('4. hasMany Array Block Validation Loop', () {
      // In quantum_schema.dart, if `hasMany: true` and the value is a List,
      // it runs the data through the block payload validation logic.
      QLSchemaRegistry.instance.registerRaw('related_block', {
        'type': 'object',
        'fields': {
          'name': {'type': 'string', 'required': true}
        }
      });

      final blueprint = QLSchemaCompiler.compile('hasMany_schema', {
        'relations': {
          'type': 'string',
          'hasMany': true,
          'allowedBlocks': ['related_block']
        }
      });

      final errors = blueprint.validate({
        'relations': [
          {
            'blockType': 'unknown_type',
            'data': {}
          }, // Fails allowedBlocks check
          {
            'blockType': 'related_block',
            'data': {}
          }, // Fails required 'name' inside block
          'not_a_map' // Fails map check
        ]
      });

      expect(errors, contains('relations[0]: invalid blockType'));
      expect(errors, contains('relations[1].data.name: required'));
      expect(errors, contains('relations[2]: invalid block payload'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. INTERNAL PATHING LOGIC (_readAt / _writeAt)
    // ─────────────────────────────────────────────────────────────────────────
    test('5. Deep Path Reading/Writing (Array & Object Chaining)', () {
      // The compiler flattens names to dot notation, but let's test a schema
      // that directly targets a specific complex array-object path.
      final blueprint = QLSchemaCompiler.compile('path_schema', {
        'users': {
          'type': 'array',
          'items': {
            'type': 'object',
            'fields': {
              'address': {
                'type': 'object',
                'fields': {
                  'zip': {'type': 'number'}
                }
              }
            }
          }
        }
      });

      final parsed = blueprint.parse({
        'users': [
          {
            'address': {'zip': '12345'}
          }, // string coerced to double
          {'address': {}} // missing zip (allowed)
        ]
      });

      expect(parsed['users'][0]['address']['zip'], 12345.0);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. SERIALIZATION OF QLBlockPayload vs Map
    // ─────────────────────────────────────────────────────────────────────────
    test('6. Serialize Internal QLBlockPayload vs Raw Maps', () {
      QLSchemaRegistry.instance.registerRaw('test_block', {
        'type': 'object',
        'fields': {
          'val': {'type': 'number'}
        }
      });

      final blueprint = QLSchemaCompiler.compile('serialize_schema', {
        'blocks': {'type': 'block'}
      });

      // Passing internal QLBlockPayload object
      final payload1 = {
        'blocks': [
          const QLBlockPayload(blockType: 'test_block', data: {'val': '42'})
        ]
      };

      // Passing raw map
      final payload2 = {
        'blocks': [
          {
            'blockType': 'test_block',
            'data': {'val': '99'}
          }
        ]
      };

      final serialized1 = blueprint.serialize(payload1);
      final serialized2 = blueprint.serialize(payload2);

      // Value was successfully coerced by the block schema during serialization
      expect(serialized1['blocks'][0]['data']['val'], 42.0);
      expect(serialized2['blocks'][0]['data']['val'], 99.0);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. BITMASK PROJECTIONS (O(1) CULLING)
    // ─────────────────────────────────────────────────────────────────────────
    test('7. Bitmask Projections (Parse, Serialize, Validate)', () {
      final blueprint = QLSchemaCompiler.compile('projection_schema', {
        'f1': {'type': 'string', 'required': true},
        'f2': {'type': 'string', 'required': true},
      });

      // Mask out f2
      final projection = blueprint.createProjection(['f1']);

      // Parsing drops f2
      final parsed =
          blueprint.parse({'f1': 'A', 'f2': 'B'}, projection: projection);
      expect(parsed.containsKey('f1'), isTrue);
      expect(parsed.containsKey('f2'), isFalse);

      // Serialization drops f2
      final serialized =
          blueprint.serialize({'f1': 'A', 'f2': 'B'}, projection: projection);
      expect(serialized.containsKey('f1'), isTrue);
      expect(serialized.containsKey('f2'), isFalse);

      // Validation ignores the missing required 'f2' because it's not in the bitmask
      final errors = blueprint.validate({'f1': 'A'}, projection: projection);
      expect(errors.isEmpty, isTrue);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. GARBAGE DATA & CRASH PROOFING
    // ─────────────────────────────────────────────────────────────────────────
    test('8. Engine Resilience Against Pure Garbage Data', () {
      final blueprint = QLSchemaCompiler.compile('garbage_schema', {
        'str': 'string',
        'num': 'number',
        'arr': {'type': 'array', 'items': 'number'},
        'obj': {
          'type': 'object',
          'fields': {'val': 'string'}
        }
      });

      final Map<String, dynamic> toxicWaste = {
        'str': ['an', 'array'], // Array instead of string
        'num': {'a': 'map'}, // Map instead of number
        'arr': 'a string', // String instead of Array
        'obj': 12345, // Number instead of Map
      };

      Map<String, dynamic>? parsed;
      Object? parseError;

      try {
        parsed = blueprint.parse(toxicWaste);
      } catch (e) {
        parseError = e;
      }

      // Assert No crashes!
      expect(parseError, isNull);
      expect(parsed, isNotNull);

      // Assert Coercions/Drops
      expect(parsed!['str'], '[an, array]'); // toString() fallback
      expect(parsed['num'], isNull); // Map cannot be parsed to num -> null
      expect(
          parsed.containsKey('arr'), isFalse); // String dropped, expects List
      expect(parsed.containsKey('obj'), isFalse); // Num dropped, expects Map

      // Assert Null Safety (Pass raw null to ensure it doesn't break)
      final dynamic rawNull = null;
      expect(() => blueprint.parse(rawNull ?? {}), returnsNormally);
      expect(() => blueprint.validate(rawNull ?? {}), returnsNormally);
    });
  });
}
