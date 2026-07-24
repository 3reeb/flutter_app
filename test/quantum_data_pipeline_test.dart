// ════════════════════════════════════════════════════════════════════════════
// QUANTUM DATA PIPELINE - OMEGA TEST SUITE (100% EXHAUSTIVE COVERAGE)
// test/quantum_data_pipeline_test.dart
// ════════════════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

// ── MOCK NETWORK DELEGATE ──
class MockPipelineDelegate implements QLPipelineDelegate {
  int fetchCount = 0;
  int partialFetchCount = 0;
  List<String> requestedPartialIds = [];
  QLProjection? lastProjection;

  @override
  Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state) async {
    fetchCount++;
    return [
      {'id': 'paged_1', 'name': 'Paged User'}
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPartial(
      List<String> ids, QLProjection projection) async {
    partialFetchCount++;
    requestedPartialIds = ids;
    lastProjection = projection;
    return [
      {'id': ids.first, 'age': 99}
    ];
  }
}

void main() {
  group('Quantum Data Pipeline | Comprehensive Omega Test Suite |', () {
    late QLSchemaBlueprint schema;
    late List<Map<String, dynamic>> mockData;

    setUpAll(() {
      // Compiled once to back all standard test pipelines
      QLSchemaRegistry.instance.clear();
      schema = QLSchemaCompiler.compile('users', {
        'id': {'type': 'string', 'required': true, 'unique': true},
        'name': {'type': 'string', 'indexed': true},
        'age': {'type': 'number'},
        'isActive': {'type': 'boolean'},
        'profile': {
          'type': 'object',
          'fields': {'role': 'string', 'score': 'number'}
        }
      });
    });

    setUp(() {
      QLPathUtils.clearCache();
      mockData = [
        {
          'id': 'u1',
          'name': 'Alice',
          'age': 25,
          'isActive': true,
          'profile': {'role': 'admin', 'score': 90.5}
        },
        {
          'id': 'u2',
          'name': 'Bob',
          'age': 30,
          'isActive': false,
          'profile': {'role': 'user', 'score': null}
        },
        {
          'id': 'u3',
          'name': 'Charlie',
          'age': 22,
          'isActive': true,
          'profile': {'role': 'editor', 'score': 80.0}
        },
        {
          'id': 'u4',
          'name': 'Diana',
          'age': null, // Null to test boundary sorting/aggregates
          'isActive': true,
          'profile': {'role': 'user', 'score': 95.0}
        },
        {
          'id': 'u5',
          'name': 'Eve',
          'age': 28,
          'isActive': false,
          'profile': {'role': 'admin', 'score': 88.0}
        },
      ];
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 1: REGISTRY & LIFECYCLE
    // ─────────────────────────────────────────────────────────────────────────
    test('1. Registry lifecycle, existence, and atomic destruction', () {
      final pipeline = QLDataPipeline(id: 'pl_lifecycle', schema: schema);
      QLPipelineRegistry.instance.register(pipeline);

      expect(QLPipelineRegistry.instance.exists('pl_lifecycle'), isTrue);
      expect(QLPipelineRegistry.instance.get('pl_lifecycle'), equals(pipeline));

      QLPipelineRegistry.instance.destroy('pl_lifecycle');
      expect(QLPipelineRegistry.instance.exists('pl_lifecycle'), isFalse);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 2: INGESTION, FLATTENING & UNFLATTENING (COLLECTION MODE)
    // ─────────────────────────────────────────────────────────────────────────
    test('2. Multi-Item Ingestion, Flattening, and UI Map Reconstruction',
        () async {
      final pipeline = QLDataPipeline(id: 'pl_ingest', schema: schema);
      pipeline.ingest(mockData);

      await Future.microtask(() {}); // Await scheduled _compute

      expect(pipeline.rawRecords.length, 5);
      expect(pipeline.visibleCount, 5);

      // Verify deep unflattening of Flat Array back into structured nested JSON Maps
      final mapU1 = pipeline.getAsMap(0); // Alice
      expect(mapU1['id'], 'u1');
      expect(mapU1['name'], 'Alice');
      expect(mapU1['profile']['role'], 'admin');
      expect(mapU1['profile']['score'], 90.5);

      // Deduplication: Ingesting existing ID updates flat array indexes, does not append
      pipeline.ingest([
        {
          'id': 'u1',
          'name': 'Alicia',
          'profile': {'role': 'super_admin'}
        }
      ]);
      await Future.microtask(() {});

      expect(pipeline.rawRecords.length, 5); // Remained at 5
      expect(pipeline.getAsMap(0)['name'], 'Alicia');
      expect(pipeline.getAsMap(0)['profile']['role'], 'super_admin');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 3: CUSTOM PRIMARY KEYS
    // ─────────────────────────────────────────────────────────────────────────
    test('3. Custom Primary Keys mapping and deduplication', () async {
      final customSchema = QLSchemaCompiler.compile('custom_pk_schema', {
        'userId': {'type': 'string', 'required': true, 'unique': true},
        'nickname': 'string'
      });

      final pipeline = QLDataPipeline(
        id: 'pl_custom_pk',
        schema: customSchema,
        primaryKey: 'userId', // Explicit override
      );

      pipeline.ingest([
        {'userId': 'usr_99', 'nickname': 'Quant'},
        {'userId': 'usr_99', 'nickname': 'Quantum_God'}, // Deduplicates
      ]);

      await Future.microtask(() {});
      expect(pipeline.rawRecords.length, 1);
      expect(pipeline.getAsMap(0)['nickname'], 'Quantum_God');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 4: SINGLE MODE PIPELINE
    // ─────────────────────────────────────────────────────────────────────────
    test('4. Single Mode overwrite constraints', () async {
      final pipeline = QLDataPipeline(
          id: 'pl_single', schema: schema, mode: QLPipelineMode.single);

      pipeline.ingest(mockData[0]); // Ingest Alice
      await Future.microtask(() {});
      expect(pipeline.rawRecords.length, 1);
      expect(pipeline.visibleCount, 1);

      pipeline.ingest(mockData[1]); // Ingest Bob
      await Future.microtask(() {});

      // In single mode, the array index stays locked at 0, data purely overwrites
      expect(pipeline.rawRecords.length, 1);
      expect(pipeline.getAsMap(0)['name'], 'Bob');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 5: SELECTIVE PROJECTIONS
    // ─────────────────────────────────────────────────────────────────────────
    test('5. Ingestion with selective projections and loaded mask validations',
        () async {
      final pipeline = QLDataPipeline(id: 'pl_proj', schema: schema);

      // Ingest only subset of fields
      pipeline.ingest(mockData, selectedFields: ['id', 'name']);
      await Future.microtask(() {});

      final u1 = pipeline.getAsMap(0);
      expect(u1['id'], 'u1');
      expect(u1['name'], 'Alice');
      expect(u1.containsKey('age'), isFalse); // Dropped by projection
      expect(u1.containsKey('profile'), isFalse); // Dropped by projection
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 6: SEARCH & FILTERING (ZERO-ALLOC O(1) / O(N) ENGINE)
    // ─────────────────────────────────────────────────────────────────────────
    test('6. Complex Text Search & Combination Filtering', () async {
      final pipeline = QLDataPipeline(id: 'pl_search', schema: schema);
      pipeline.ingest(mockData);
      await Future.microtask(() {});

      // 6A. Case-Insensitive String Search (Matches pre-lowercased cache)
      pipeline.searchQuery.value = 'EVE';
      await Future.microtask(() {});
      expect(pipeline.visibleCount, 1);
      expect(pipeline.getAsMap(pipeline.visibleIndices.value[0])['id'], 'u5');

      pipeline.searchQuery.value = ''; // Reset

      // 6B. Exact Filter (Non-Indexed O(N))
      pipeline.filters.value = {schema.getIndex('isActive'): 'true'};
      await Future.microtask(() {});
      expect(pipeline.visibleCount, 3); // Alice, Charlie, Diana
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 7: O(1) INDEXED LOOKUPS
    // ─────────────────────────────────────────────────────────────────────────
    test('7. O(1) Indexed & Unique Lookups', () async {
      final pipeline = QLDataPipeline(id: 'pl_indices', schema: schema);
      pipeline.ingest(mockData);
      await Future.microtask(() {});

      // O(1) Unique Index route (id is flagged as unique)
      pipeline.filters.value = {schema.getIndex('id'): 'u3'};
      await Future.microtask(() {});
      expect(pipeline.visibleCount, 1);
      expect(pipeline.getAsMap(pipeline.visibleIndices.value[0])['name'],
          'Charlie');

      // O(1) Multi-Bucket Standard Index route (name is flagged as indexed)
      pipeline.filters.value = {schema.getIndex('name'): 'Alice'};
      await Future.microtask(() {});
      expect(pipeline.visibleCount, 1);
      expect(pipeline.getAsMap(pipeline.visibleIndices.value[0])['id'], 'u1');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 8: QUICKSORT - NUMBERS & NULL BOUNDARIES
    // ─────────────────────────────────────────────────────────────────────────
    test('8. Quicksort: Numbers & Null Boundary Sorts', () async {
      final pipeline = QLDataPipeline(id: 'pl_sort_num', schema: schema);
      pipeline.ingest(mockData);

      // Sort by Age ASC
      pipeline.sortFieldIndex.value = schema.getIndex('age');
      pipeline.sortAsc.value = true;
      await Future.microtask(() {});

      // Expected order: Charlie(22), Alice(25), Eve(28), Bob(30), Diana(null)
      var p0 = pipeline.getAsMap(pipeline.visibleIndices.value[0]);
      var p4 = pipeline.getAsMap(pipeline.visibleIndices.value[4]);
      expect(p0['name'], 'Charlie');
      expect(p4['name'], 'Diana'); // Nulls always sorted last in ASC

      // Sort by Age DESC
      pipeline.sortAsc.value = false;
      await Future.microtask(() {});

      // Expected order: Diana(null), Bob(30), Eve(28), Alice(25), Charlie(22)
      p0 = pipeline.getAsMap(pipeline.visibleIndices.value[0]);
      p4 = pipeline.getAsMap(pipeline.visibleIndices.value[4]);
      expect(p0['name'], 'Diana'); // Nulls always sorted first in DESC
      expect(p4['name'], 'Charlie');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 9: QUICKSORT - BOOLEANS & STRINGS (CASE-INSENSITIVE)
    // ─────────────────────────────────────────────────────────────────────────
    test('9. Quicksort: Booleans & Case-Insensitive String sorting', () async {
      final pipeline = QLDataPipeline(id: 'pl_sort_types', schema: schema);
      pipeline.ingest(mockData);

      // 9A. Sort by IsActive (Booleans)
      pipeline.sortFieldIndex.value = schema.getIndex('isActive');
      pipeline.sortAsc.value = true;
      await Future.microtask(() {});

      // False, False, True, True, True
      var p0 = pipeline.getAsMap(pipeline.visibleIndices.value[0]);
      var p4 = pipeline.getAsMap(pipeline.visibleIndices.value[4]);
      expect(p0['isActive'], isFalse);
      expect(p4['isActive'], isTrue);

      // 9B. Sort by Name (String)
      pipeline.sortFieldIndex.value = schema.getIndex('name');
      pipeline.sortAsc.value = true;
      await Future.microtask(() {});

      p0 = pipeline.getAsMap(pipeline.visibleIndices.value[0]);
      expect(p0['name'], 'Alice');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 10: PAGINATION
    // ─────────────────────────────────────────────────────────────────────────
    test('10. Multi-Page Pagination Shifting', () async {
      final pipeline =
          QLDataPipeline(id: 'pl_page', schema: schema, pageSize: 2);
      pipeline.ingest(mockData); // 5 elements total

      await Future.microtask(() {});

      // Page 0 (Idx 0, 1)
      expect(pipeline.visibleCount, 2);
      expect(
          pipeline.getAsMap(pipeline.visibleIndices.value[0])['name'], 'Alice');

      // Page 1 (Idx 2, 3)
      pipeline.page.value = 1;
      await Future.microtask(() {});
      expect(pipeline.visibleCount, 2);
      expect(pipeline.getAsMap(pipeline.visibleIndices.value[0])['name'],
          'Charlie');

      // Page 2 (Idx 4)
      pipeline.page.value = 2;
      await Future.microtask(() {});
      expect(pipeline.visibleCount, 1);
      expect(
          pipeline.getAsMap(pipeline.visibleIndices.value[0])['name'], 'Eve');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 11: DEEP OBJECT PATCHING
    // ─────────────────────────────────────────────────────────────────────────
    test('11. Patching Deep Object paths and Auto-Ingestion of unknown IDs',
        () async {
      final pipeline = QLDataPipeline(id: 'pl_patch', schema: schema);
      pipeline.ingest(mockData);
      await Future.microtask(() {});

      // Patch deep object value directly
      pipeline.patch('u1', {'profile.role': 'CEO', 'profile.score': 100.0});
      await Future.microtask(() {});

      final u1 = pipeline.getAsMap(0);
      expect(u1['profile']['role'], 'CEO');
      expect(u1['profile']['score'], 100.0);

      // Ingest completely new ID via Patch (DOD Auto-Ingest safety valve)
      pipeline.patch('u999', {'name': 'New Guy', 'age': 40});
      await Future.microtask(() {});

      expect(pipeline.rawRecords.length, 6);
      expect(pipeline.getAsMap(5)['id'], 'u999');
      expect(pipeline.getAsMap(5)['name'], 'New Guy');
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 12: MATHEMATICAL AGGREGATIONS
    // ─────────────────────────────────────────────────────────────────────────
    test('12. Mathematical Aggregations (Sum, Avg, Min, Max, Count)', () async {
      final pipeline = QLDataPipeline(id: 'pl_agg', schema: schema);
      pipeline.ingest(mockData);

      pipeline.registerAggregates([
        const QLAggregateOp(alias: 'sum_age', field: 'age', type: 'sum'),
        const QLAggregateOp(
            alias: 'avg_score', field: 'profile.score', type: 'avg'),
        const QLAggregateOp(alias: 'max_age', field: 'age', type: 'max'),
        const QLAggregateOp(
            alias: 'min_score', field: 'profile.score', type: 'min'),
        const QLAggregateOp(alias: 'count_all', field: 'id', type: 'count'),
      ]);

      await Future.microtask(() {});

      final agg = pipeline.aggregates.value;
      // Ages: 25, 30, 22, null(0), 28 = 105
      expect(agg['sum_age'], 105.0);
      expect(agg['max_age'], 30.0);

      // Scores: 90.5, null(0), 80.0, 95.0, 88.0. Count is 5. Sum is 353.5. Avg = 70.7
      expect(agg['avg_score'], 70.7);
      expect(agg['min_score'], 0.0);
      expect(agg['count_all'], 5.0);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 13: SUBSET AGGREGATIONS
    // ─────────────────────────────────────────────────────────────────────────
    test('13. Subset Aggregations re-evaluation after filter mutations',
        () async {
      final pipeline = QLDataPipeline(id: 'pl_subset_agg', schema: schema);
      pipeline.ingest(mockData);

      pipeline.registerAggregates([
        const QLAggregateOp(alias: 'total_age', field: 'age', type: 'sum'),
        const QLAggregateOp(alias: 'active_count', field: 'id', type: 'count'),
      ]);

      // Filter: Only active users
      pipeline.filters.value = {schema.getIndex('isActive'): 'true'};
      await Future.microtask(() {});

      final agg = pipeline.aggregates.value;
      // Active Ages: Alice(25), Charlie(22), Diana(null->0) = 47
      expect(agg['total_age'], 47.0);
      expect(agg['active_count'], 3.0);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 14: INFINITE SCROLL PREFETCH TELEMETRY
    // ─────────────────────────────────────────────────────────────────────────
    test('14. Infinite Scroll Telemetry & Prefetch Locking', () async {
      final mockDelegate = MockPipelineDelegate();
      final pipeline = QLDataPipeline(
        id: 'pl_scroll',
        schema: schema,
        delegate: mockDelegate,
        prefetchConfig: const QLPrefetchConfig(triggerDistance: 3),
        pageSize: 10,
      );

      pipeline.visibleCount = 10;
      pipeline
          .notifyScrollIndex(8); // Distance: 10 - 8 = 2 < 3. Should trigger!

      expect(mockDelegate.fetchCount, 1);

      // Call again immediately. Fetch lock should prevent duplicate thrashing.
      pipeline.notifyScrollIndex(9);
      expect(mockDelegate.fetchCount, 1); // Remained at 1
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 15: HIGH-FREQUENCY STRESS TESTING
    // ─────────────────────────────────────────────────────────────────────────
    test('15. mutational stress testing (microtask coalescing)', () async {
      final pipeline = QLDataPipeline(id: 'pl_stress', schema: schema);
      pipeline.ingest(mockData);
      await Future.microtask(() {});

      int computeCount = 0;
      pipeline.visibleIndices.addListener(() {
        computeCount++;
      });

      // Synchronously fire 100 partial patch mutations
      for (int i = 0; i < 100; i++) {
        pipeline.patch('u1', {'age': 20.0 + i});
      }

      // Microtask loop has not finished yet, so computeCount should be 0
      expect(computeCount, 0);

      await Future.microtask(() {});

      // All 100 mutations were compiled in exactly ONE tick
      expect(computeCount, 1);
      expect(pipeline.getAsMap(0)['age'], 119.0); // 20 + 99
    });

    // ─────────────────────────────────────────────────────────────────────────
    // PHASE 16: PARSING FAILURE RECOVERY & SOLID RESILIENCE
    // ─────────────────────────────────────────────────────────────────────────
    test('16. Ingestion of corrupt/malformed payloads', () async {
      final pipeline = QLDataPipeline(id: 'pl_garbage', schema: schema);

      final List<Map<String, dynamic>> toxicWaste = [
        {'id': 'clean_1', 'name': 'Healthy Node', 'age': 30},
        {
          'id': 'toxic_2',
          'name': ['should', 'be', 'a', 'string'], // Incompatible array type
          'age': {'nested': 'object_not_a_num'}, // Incompatible map type
          'profile': 'corrupt_string_where_map_expected' // Incompatible object
        }
      ];

      expect(() => pipeline.ingest(toxicWaste), returnsNormally);
      await Future.microtask(() {});

      final cleanNode = pipeline.getAsMap(0);
      final corruptNode = pipeline.getAsMap(1);

      expect(cleanNode['name'], 'Healthy Node');
      expect(cleanNode['age'], 30.0);

      // Coercion / Recovery checks:
      // 'name' was coerced from List -> String "[should, be, a, string]"
      // 'age' was dropped because Map couldn't parse to number -> ignored
      // 'profile' was dropped because String couldn't parse to Object Map -> ignored
      expect(corruptNode['name'], '[should, be, a, string]');
      expect(corruptNode.containsKey('age'), isFalse);
      expect(corruptNode.containsKey('profile'), isFalse);
    });
  });
}
