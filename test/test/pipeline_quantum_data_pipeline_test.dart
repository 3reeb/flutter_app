import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

class _FakePipelineDelegate implements QLPipelineDelegate {
  int fetchCalls = 0;
  int partialCalls = 0;
  Map<String, dynamic>? lastFetchState;
  List<String>? lastPartialIds;
  QLProjection? lastPartialProjection;

  @override
  Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state) async {
    fetchCalls += 1;
    lastFetchState = Map<String, dynamic>.from(state);
    return [
      {
        'id': 'p1',
        'name': 'Alpha',
        'age': 10,
        'status': 'draft',
        'active': true,
      },
      {
        'id': 'p2',
        'name': 'Beta',
        'age': 20,
        'status': 'live',
        'active': false,
      },
    ];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPartial(
      List<String> ids, QLProjection projection) async {
    partialCalls += 1;
    lastPartialIds = List<String>.from(ids);
    lastPartialProjection = projection;
    return [
      {
        'id': ids.first,
        'age': 42,
        'status': 'live',
      },
    ];
  }
}

void main() {
  setUp(resetQuantumRuntime);

  test('QLDataPipeline ingests records, filters, searches and sorts', () async {
    final schema =
        QLSchemaCompiler.compile('pipelineProduct', sampleSchemaDefinition());
    final pipeline = QLDataPipeline(id: 'products', schema: schema);

    pipeline.ingest([
      {'id': 'a', 'name': 'Gamma', 'age': 30, 'status': 'live', 'active': true},
      {
        'id': 'b',
        'name': 'Alpha',
        'age': 10,
        'status': 'draft',
        'active': false
      },
      {'id': 'c', 'name': 'Beta', 'age': 20, 'status': 'live', 'active': true},
    ]);

    await Future<void>.delayed(Duration.zero);
    expect(pipeline.visibleCount, 3);
    expect(pipeline.recordAsMap(0)['name'], isNotEmpty);

    pipeline.setFilters({schema.getIndex('status'): 'live'});
    await Future<void>.delayed(Duration.zero);
    expect(pipeline.visibleCount, 2);

    pipeline.setSearchQuery('beta');
    await Future<void>.delayed(Duration.zero);
    expect(pipeline.visibleCount, 1);

    pipeline.setSearchQuery('');
    pipeline.setSort(schema.getIndex('age'), ascending: false);
    await Future<void>.delayed(Duration.zero);
    expect(pipeline.visibleIndices.value[0], 0);
  });

  test('QLDataPipeline computes aggregates and updates them after mutations',
      () async {
    final schema =
        QLSchemaCompiler.compile('pipelineAgg', sampleSchemaDefinition());
    final pipeline = QLDataPipeline(id: 'agg', schema: schema);
    pipeline.registerAggregates([
      const QLAggregateOp(alias: 'sumAge', field: 'age', type: 'sum'),
      const QLAggregateOp(alias: 'avgAge', field: 'age', type: 'avg'),
      const QLAggregateOp(alias: 'count', field: 'id', type: 'count'),
    ]);

    pipeline.ingest([
      {'id': 'a', 'name': 'Gamma', 'age': 30, 'status': 'live'},
      {'id': 'b', 'name': 'Alpha', 'age': 10, 'status': 'draft'},
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(pipeline.aggregates.value['sumAge'], 40.0);
    expect(pipeline.aggregates.value['avgAge'], 20.0);
    expect(pipeline.aggregates.value['count'], 2.0);
  });

  test('QLDataPipeline delegates partial fetch requests for missing fields',
      () async {
    final schema =
        QLSchemaCompiler.compile('pipelinePartial', sampleSchemaDefinition());
    final delegate = _FakePipelineDelegate();
    final pipeline =
        QLDataPipeline(id: 'partial', schema: schema, delegate: delegate);

    pipeline.ingest([
      {'id': 'p1', 'name': 'Alpha'},
    ], selectedFields: [
      'id',
      'name'
    ]);
    await Future<void>.delayed(Duration.zero);

    pipeline.ensureFields('p1', ['id', 'age']);
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      if (pipeline.recordAsMap(0)['age'] != null) break;
    }

    expect(delegate.partialCalls, greaterThan(0));
    expect(delegate.lastPartialIds, ['p1']);
    expect(pipeline.recordAsMap(0)['age'], 42);
  });

  test(
      'QLDataPipeline requests next pages when scrolling crosses the threshold',
      () async {
    final schema =
        QLSchemaCompiler.compile('pipelineScroll', sampleSchemaDefinition());
    final delegate = _FakePipelineDelegate();
    final pipeline = QLDataPipeline(
      id: 'scroll',
      schema: schema,
      delegate: delegate,
      pageSize: 1,
      prefetchConfig:
          const QLPrefetchConfig(triggerDistance: 1, maxPagesToCache: 2),
    );

    pipeline.ingest([
      {'id': 'a', 'name': 'Alpha', 'age': 1, 'status': 'live'},
      {'id': 'b', 'name': 'Beta', 'age': 2, 'status': 'live'},
    ]);
    await Future<void>.delayed(Duration.zero);
    pipeline.notifyScrollIndex(1);
    await Future<void>.delayed(Duration.zero);
    expect(delegate.fetchCalls, greaterThan(0));
    expect(delegate.lastFetchState?['page'], 1);
  });

  test('QLDataPipeline patch updates indexed records in place', () async {
    final schema =
        QLSchemaCompiler.compile('pipelinePatch', sampleSchemaDefinition());
    final pipeline = QLDataPipeline(id: 'patch', schema: schema);
    pipeline.ingest([
      {'id': 'a', 'name': 'Alpha', 'age': 1, 'status': 'draft'},
    ]);
    await Future<void>.delayed(Duration.zero);

    pipeline.patch('a', {'name': 'Ava', 'age': 9});
    await Future<void>.delayed(Duration.zero);
    expect(pipeline.recordAsMap(0)['name'], 'Ava');
    expect(pipeline.recordAsMap(0)['age'], 9);
  });

  test('QLPipelineRegistry registers and clears pipelines deterministically',
      () {
    final schema =
        QLSchemaCompiler.compile('registrySchema', sampleSchemaDefinition());
    final pipeline = QLDataPipeline(id: 'registry', schema: schema);
    QLPipelineRegistry.instance.register(pipeline);
    expect(QLPipelineRegistry.instance.exists('registry'), isTrue);
    QLPipelineRegistry.instance.destroy('registry');
    expect(QLPipelineRegistry.instance.exists('registry'), isFalse);
  });
}
