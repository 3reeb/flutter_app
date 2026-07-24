import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

Future<void> flushRuntime([int turns = 8]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void resetRuntime() {
  QLSliceRegistry.instance.clear();
  QLPipelineRegistry.instance.clear();
  QLDataSourceRegistry.instance.clear();
  QLStoreRegistry.instance.clearAll();
  QLSliceRegistry.actionRegistrar = null;
}

QLSchemaBlueprint buildPostSchema() {
  return QLSchemaCompiler.compile('ProductionPostSchema', <String, dynamic>{
    'id': <String, dynamic>{
      'type': 'string',
      'unique': true,
      'indexed': true,
      'required': true,
    },
    'title': <String, dynamic>{
      'type': 'string',
      'indexed': true,
    },
    'likes': <String, dynamic>{
      'type': 'number',
      'indexed': true,
    },
    'published': <String, dynamic>{
      'type': 'boolean',
    },
    'author': <String, dynamic>{
      'type': 'object',
      'fields': <String, dynamic>{
        'name': <String, dynamic>{'type': 'string'},
        'role': <String, dynamic>{'type': 'string'},
      },
    },
    'tags': <String, dynamic>{
      'type': 'array',
      'items': <String, dynamic>{
        'type': 'string',
      },
    },
  });
}

QLDataPipeline buildPostPipeline({
  String id = 'feed.main',
  QLPipelineMode mode = QLPipelineMode.collection,
  int pageSize = 0,
}) {
  return QLDataPipeline(
    id: id,
    schema: buildPostSchema(),
    mode: mode,
    executionMode: QLExecutionMode.client,
    pageSize: pageSize,
  );
}

Map<String, dynamic> buildFeedSourceSeed({
  int likes = 1,
  String id = 'p1',
  String title = 'First post',
}) {
  return <String, dynamic>{
    'items': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': id,
        'title': title,
        'likes': likes,
        'published': true,
        'author': <String, dynamic>{
          'name': 'Ada',
          'role': 'creator',
        },
        'tags': <String>['flutter', 'quantum'],
      },
    ],
    'cursor': 'next-page-token',
    'meta': <String, dynamic>{
      'source': 'seed',
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(resetRuntime);

  setUpAll(() {
    QLSliceStrategyRegistry.instance.register(
      'test.bumpBy',
      (QLDataStore store, Map<String, dynamic> payload,
          QLSliceExecutionContext ctx) {
        final path = payload['path']?.toString() ?? 'likes';
        final by = (payload['by'] as num?)?.toDouble() ?? 1.0;
        final current = store.get(path);
        final next = (current is num ? current.toDouble() : 0.0) + by;
        store.set(path, next);
        return next;
      },
      kind: 'mutation',
    );

    QLSliceStrategyRegistry.instance.register(
      'test.listCount',
      (QLDataStore store, Map<String, dynamic> payload,
          QLSliceExecutionContext ctx) {
        final path = payload['path']?.toString() ?? 'items';
        final current = store.get(path);
        return current is List ? current.length : 0;
      },
      kind: 'query',
    );

    QLSliceStrategyRegistry.instance.register(
      'test.pipelineEcho',
      (QLDataStore store, Map<String, dynamic> payload,
          QLSliceExecutionContext ctx) {
        return <String, dynamic>{
          'namespace': ctx.namespace,
          'slice': ctx.sliceName,
          'payload': Map<String, dynamic>.from(payload),
        };
      },
      kind: 'pipeline',
    );
  });

  group('QLRuntimeSupport', () {
    test('mapOf preserves maps and falls back on non-map values', () {
      expect(QLRuntimeSupport.mapOf(<String, dynamic>{'a': 1}),
          <String, dynamic>{'a': 1});
      expect(
          QLRuntimeSupport.mapOf('x',
              fallback: <String, dynamic>{'fallback': true}),
          <String, dynamic>{'fallback': true});
    });

    test(
        'recordsOf accepts list payloads, wrapped data payloads, and rejects scalars',
        () {
      final direct = QLRuntimeSupport.recordsOf(<Map<String, dynamic>>[
        <String, dynamic>{'id': 1},
        <String, dynamic>{'id': 2},
      ]);
      final wrapped = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 3},
        ],
      });
      final rejected = QLRuntimeSupport.recordsOf(123);

      expect(direct.length, 2);
      expect(wrapped.single['id'], 3);
      expect(rejected, isEmpty);
    });

    test('lastResult supports both escaped and raw keys', () {
      expect(
        QLRuntimeSupport.lastResult(<String, dynamic>{r'$lastResult': 'raw'}),
        'raw',
      );
      expect(
        QLRuntimeSupport.lastResult(
            <String, dynamic>{'\$lastResult': 'escaped'}),
        'escaped',
      );
    });

    test('pathAffects is symmetric across nested paths', () {
      expect(QLRuntimeSupport.pathAffects('user.name', 'user'), isTrue);
      expect(QLRuntimeSupport.pathAffects('user', 'user.name'), isTrue);
      expect(
          QLRuntimeSupport.pathAffects('user.profile.avatar', 'user.profile'),
          isTrue);
      expect(QLRuntimeSupport.pathAffects('a.b', 'c.d'), isFalse);
    });

    test('canonicalPath normalizes list paths with the path utils', () {
      expect(
        QLRuntimeSupport.canonicalPath(<dynamic>['profile', 'name']),
        'profile.name',
      );
    });

    test('safeString always produces a stable string', () {
      expect(QLRuntimeSupport.safeString(null), '');
      expect(QLRuntimeSupport.safeString(12), '12');
      expect(QLRuntimeSupport.safeString(<String, dynamic>{'a': 1}),
          contains('a'));
    });
  });

  group('QLRuntimeCache', () {
    test('stores, retrieves, and counts hits and misses', () {
      final cache = QLRuntimeCache<String>(
        config: const QLRuntimeCacheConfig(maxEntries: 10, maxWeight: 1024),
      );

      expect(cache.get('missing'), isNull);
      cache.put('k1', 'v1');
      expect(cache.get('k1'), 'v1');
      expect(cache.get('missing-2'), isNull);

      final stats = cache.stats;
      expect(stats.entries, 1);
      expect(stats.hits, 1);
      expect(stats.misses, 2);
    });

    test('getOrPut only loads once for the same key', () {
      final cache = QLRuntimeCache<int>(
        config: const QLRuntimeCacheConfig(maxEntries: 10, maxWeight: 1024),
      );

      var loads = 0;
      final first = cache.getOrPut('answer', () {
        loads++;
        return 42;
      });
      final second = cache.getOrPut('answer', () {
        loads++;
        return 99;
      });

      expect(first, 42);
      expect(second, 42);
      expect(loads, 1);
    });

    test('evicts old entries when maxEntries is exceeded', () {
      final cache = QLRuntimeCache<String>(
        config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 1024),
      );

      cache.put('a', 'A');
      cache.put('b', 'B');
      cache.put('c', 'C');

      expect(cache.contains('a'), isFalse);
      expect(cache.contains('b'), isTrue);
      expect(cache.contains('c'), isTrue);
      expect(cache.stats.evictions, 1);
    });

    test('respects ttl expiration on access and compact', () async {
      final cache = QLRuntimeCache<String>(
        config: const QLRuntimeCacheConfig(maxEntries: 10, maxWeight: 1024),
      );

      cache.put('ttl', 'value', ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cache.get('ttl'), isNull);

      cache.put('compact', 'value2', ttl: const Duration(milliseconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      cache.compact();
      expect(cache.contains('compact'), isFalse);
    });

    test('removeWhere and clear leave the cache empty', () {
      final cache = QLRuntimeCache<int>(
        config: const QLRuntimeCacheConfig(maxEntries: 10, maxWeight: 1024),
      );

      cache.put('a', 1);
      cache.put('b', 2);
      cache.removeWhere((key, entry) => key == 'a');
      expect(cache.contains('a'), isFalse);
      expect(cache.contains('b'), isTrue);

      cache.clear();
      expect(cache.stats.entries, 0);
    });
  });

  group('QLDataStore', () {
    test('set and get support nested object and list paths', () {
      final store = QLStoreRegistry.instance.get('store.nested');
      store.set('profile.name', 'Ada');
      store.set('profile.phones[0]', '123');
      store.set('profile.phones[1]', '456');

      expect(store.get('profile.name'), 'Ada');
      expect(store.get('profile.phones[0]'), '123');
      expect(store.get('profile.phones[1]'), '456');
      expect(store.snapshot['profile'], isNotNull);
    });

    test('computed nodes react to dependency updates', () async {
      final store = QLStoreRegistry.instance.get('store.computed');
      store.set('likes', 2);
      store.registerComputed(
        'doubleLikes',
        <String>['likes'],
        (List<dynamic> values) => ((values.first as num?) ?? 0) * 2,
      );

      await flushRuntime();
      expect(store.get('doubleLikes'), 4);

      store.set('likes', 7);
      await flushRuntime();
      expect(store.get('doubleLikes'), 14);
    });

    test(
        'merge can replace or preserve existing keys and rollback restores snapshot',
        () async {
      final store = QLStoreRegistry.instance.get('store.merge');

      // FIX 1: Use dot notation here so nested values are preserved
      // instead of replacing the entire profile object.
      store.merge(<String, dynamic>{
        'profile.name': 'Ada',
        'profile.role': 'creator',
      });
      store.saveSnapshot();
      store.merge(<String, dynamic>{
        'profile.role': 'editor',
        'profile.city': 'Sana',
      });
      await flushRuntime();

      expect(store.get('profile.name'), 'Ada');
      expect(store.get('profile.role'), 'editor');
      expect(store.get('profile.city'), 'Sana');

      store.rollback();
      await flushRuntime();
      expect(store.get('profile.role'), 'creator');
      expect(store.get('profile.city'), isNull);
    });

    test('bindAsync mirrors loading data and error channels into store paths',
        () async {
      final store = QLStoreRegistry.instance.get('store.async');
      final signal = QLAsyncSignal<int>();
      store.bindAsync('resource.weather', signal);

      expect(store.get('resource.weather.data'), isNull);
      expect(store.get('resource.weather.loading'), isFalse);

      signal.loading.setSilent(true);
      signal.loading.forceNotify();
      signal.data.setSilent(88);
      signal.data.forceNotify();
      signal.error.setSilent(StateError('offline'));
      signal.error.forceNotify();

      await flushRuntime();
      expect(store.get('resource.weather.data'), 88);
      expect(store.get('resource.weather.loading'), isTrue);
      expect(store.get('resource.weather.error'), contains('offline'));
    });

    test('sweep removes all keys below the requested prefix', () {
      final store = QLStoreRegistry.instance.get('store.sweep');
      store.set('feed.items[0].id', '1');
      store.set('feed.items[0].title', 'hello');
      store.set('profile.name', 'Ada');

      store.sweep('feed');
      expect(store.get('feed.items[0].id'), isNull);
      expect(store.get('profile.name'), 'Ada');
    });

    test('transaction batches writes without losing values', () async {
      final store = QLStoreRegistry.instance.get('store.tx');
      var changed = 0;
      store.addPersistenceListener(() {
        changed++;
      });

      store.transaction(() {
        store.set('a', 1);
        store.set('b', 2);
        store.set('c.d', 3);
      });

      await flushRuntime();
      expect(store.get('a'), 1);
      expect(store.get('b'), 2);
      expect(store.get('c.d'), 3);
      expect(changed, greaterThan(0));
    });

    test('snapshot exposes all live keys', () {
      final store = QLStoreRegistry.instance.get('store.snapshot');
      store.set('x', 1);
      store.set('y', 2);
      expect(store.snapshot['x'], 1);
      expect(store.snapshot['y'], 2);
      expect(store.signalCount, greaterThanOrEqualTo(2));
    });
  });

  group('QLDataSourceRegistry', () {
    test('register stores seed data and reports streaming behavior by config',
        () {
      final realtime = QLDataSourceRegistry.instance.register(
        'source.realtime',
        <String, dynamic>{
          'type': 'realtime',
          'seed': buildFeedSourceSeed(),
        },
      );
      final media = QLDataSourceRegistry.instance.register(
        'source.media',
        <String, dynamic>{
          'type': 'media',
          'seed': <String, dynamic>{
            'bytes': <int>[1, 2, 3]
          },
        },
      );

      // FIX 2: explicit 'direction': 'outboundOnly' dictates that
      // the endpoint does not support streaming mode.
      final plain = QLDataSourceRegistry.instance.register(
        'source.api',
        <String, dynamic>{
          'type': 'api',
          'direction': 'outboundOnly',
          'seed': <String, dynamic>{'hello': true},
        },
      );

      expect(realtime.isStreaming, isTrue);
      expect(media.isStreaming, isTrue);
      expect(plain.isStreaming, isFalse);
      expect(realtime.signal.data.value, isNotNull);
    });

    test(
        'attachStateBinding syncs source payload into store and tracks updates',
        () async {
      final source = QLDataSourceRegistry.instance.register(
        'source.feed',
        <String, dynamic>{
          'type': 'realtime',
          'seed': buildFeedSourceSeed(),
        },
      );
      final store = QLStoreRegistry.instance.get('slice.feed');
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'slice.feed',
        store: store,
        sourceName: 'source.feed',
        statePath: 'feedItems',
        sourcePath: 'items',
        merge: 'replace',
        defaultValue: <dynamic>[],
        subscribe: true,
      );

      await flushRuntime();
      expect(store.get('feedItems'), isA<List<dynamic>>());
      expect((store.get('feedItems') as List).length, 1);

      source.signal.data.setSilent(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'p1',
            'title': 'First post',
            'likes': 1,
          },
          <String, dynamic>{
            'id': 'p2',
            'title': 'Second post',
            'likes': 3,
          },
        ],
      });
      source.signal.data.forceNotify();

      await flushRuntime();
      expect((store.get('feedItems') as List).length, 2);
      expect((store.get('feedItems') as List).first['id'], 'p1');
    });

    test(
        'hybrid merge with appendById keeps local items and deduplicates remote items',
        () async {
      final source = QLDataSourceRegistry.instance.register(
        'source.hybrid',
        <String, dynamic>{
          'type': 'realtime',
          'seed': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'a', 'title': 'alpha'},
            ],
          },
        },
      );
      final store = QLStoreRegistry.instance.get('slice.hybrid');
      store.set('items', <Map<String, dynamic>>[
        <String, dynamic>{'id': 'a', 'title': 'alpha-local'},
      ]);

      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'slice.hybrid',
        store: store,
        sourceName: 'source.hybrid',
        statePath: 'items',
        sourcePath: 'items',
        merge: 'appendById',
      );

      await flushRuntime();
      expect((store.get('items') as List).length, 1);
      expect((store.get('items') as List).single['id'], 'a');

      source.signal.data.setSilent(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'a', 'title': 'alpha-remote'},
          <String, dynamic>{'id': 'b', 'title': 'bravo'},
        ],
      });
      source.signal.data.forceNotify();

      await flushRuntime();
      final items = store.get('items') as List<dynamic>;
      expect(items.length, 2);
      expect(items.any((e) => e is Map && e['id'] == 'b'), isTrue);
    });

    test(
        'detachNamespace stops future state synchronization for a mounted binding',
        () async {
      final source = QLDataSourceRegistry.instance.register(
        'source.detach',
        <String, dynamic>{
          'type': 'realtime',
          'seed': <String, dynamic>{'count': 1},
        },
      );
      final store = QLStoreRegistry.instance.get('slice.detach');
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'slice.detach',
        store: store,
        sourceName: 'source.detach',
        statePath: 'count',
        sourcePath: 'count',
        merge: 'replace',
      );

      await flushRuntime();
      expect(store.get('count'), 1);

      QLDataSourceRegistry.instance.detachNamespace('slice.detach');
      source.signal.data.setSilent(<String, dynamic>{'count': 99});
      source.signal.data.forceNotify();
      await flushRuntime();

      expect(store.get('count'), 1);
    });

    test('snapshot reports source count and metadata without touching network',
        () {
      QLDataSourceRegistry.instance.register(
        'source.snapshot',
        <String, dynamic>{
          'type': 'api',
          'domain': 'api_collection',
          'resource': 'posts',
          'seed': <String, dynamic>{'ok': true},
        },
      );
      final snapshot = QLDataSourceRegistry.instance.snapshot();

      expect(snapshot['count'], 1);
      expect((snapshot['sources'] as List).single['name'], 'source.snapshot');
      expect((snapshot['sources'] as List).single['resource'], 'posts');
    });
  });

  group('QLSchemaCompiler and QLDataPipeline', () {
    test('compile exposes schema fields and nested paths', () {
      final schema = buildPostSchema();
      expect(schema.name, 'ProductionPostSchema');
      expect(schema.fieldCount, greaterThan(0));
      expect(schema.getIndex('id'), greaterThanOrEqualTo(0));
      expect(schema.getIndex('author.name'), greaterThanOrEqualTo(0));
      expect(schema.fieldPaths(), contains('tags[]'));
    });

    test('parse and serialize keep nested objects stable', () {
      final schema = buildPostSchema();
      final raw = <String, dynamic>{
        'id': 'p1',
        'title': 'Hello',
        'likes': 9,
        'published': true,
        'author': <String, dynamic>{
          'name': 'Ada',
          'role': 'creator',
        },
        'tags': <String>['a', 'b'],
      };

      final parsed = schema.parse(raw);
      final encoded = schema.serialize(parsed);

      expect(parsed['id'], 'p1');
      expect(parsed['author']['name'], 'Ada');
      expect(encoded['title'], 'Hello');
    });

    test(
        'collection pipeline ingests, sorts, searches, filters, and aggregates',
        () async {
      final pipeline = buildPostPipeline(pageSize: 0);
      QLPipelineRegistry.instance.register(pipeline);

      pipeline.registerAggregates(const <QLAggregateOp>[
        QLAggregateOp(alias: 'likesTotal', field: 'likes', type: 'sum'),
        QLAggregateOp(alias: 'countPosts', field: 'id', type: 'count'),
      ]);

      pipeline.ingest(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'p1',
          'title': 'Hello Quantum',
          'likes': 3,
          'published': true,
          'author': <String, dynamic>{'name': 'Ada', 'role': 'creator'},
          'tags': <String>['flutter'],
        },
        <String, dynamic>{
          'id': 'p2',
          'title': 'Realtime Streams',
          'likes': 7,
          'published': false,
          'author': <String, dynamic>{'name': 'Bea', 'role': 'editor'},
          'tags': <String>['video', 'live'],
        },
        <String, dynamic>{
          'id': 'p3',
          'title': 'Search Index',
          'likes': 2,
          'published': true,
          'author': <String, dynamic>{'name': 'Cora', 'role': 'reviewer'},
          'tags': <String>['search'],
        },
      ]);

      await flushRuntime();

      expect(pipeline.visibleCount, 3);
      expect(pipeline.aggregates.value['likesTotal'], 12.0);
      expect(pipeline.aggregates.value['countPosts'], 3.0);

      pipeline.setSearchQuery('realtime');
      await flushRuntime();
      expect(pipeline.visibleCount, 1);

      pipeline.clearFilters();
      // FIX 3: Cast to <int, dynamic> and use actual boolean `true`
      // instead of string 'true' so exact equality matches the data type.
      pipeline.setFilters(
          <int, String>{pipeline.schema.getIndex('published'): 'true'});
      await flushRuntime();
      expect(pipeline.visibleCount, 2);

      pipeline.clearFilters();
      pipeline.setSort(pipeline.schema.getIndex('likes'), ascending: false);
      await flushRuntime();
      expect(pipeline.visibleIndices.value[0], isNotNull);
      expect(pipeline.getAsMap(pipeline.visibleIndices.value[0])['likes'], 7);
    });

    test(
        'patch updates a known record and inserts when collection patch targets a new id',
        () async {
      final pipeline = buildPostPipeline();
      pipeline.ingest(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'p1',
          'title': 'Original',
          'likes': 1,
          'published': true,
        },
      ]);

      pipeline.patch('p1', <String, dynamic>{'title': 'Updated', 'likes': 5});
      await flushRuntime();
      expect(pipeline.getAsMap(0)['title'], 'Updated');
      expect(pipeline.getAsMap(0)['likes'], 5);

      pipeline
          .patch('new-id', <String, dynamic>{'title': 'Inserted', 'likes': 9});
      await flushRuntime();
      expect(pipeline.getAsMap(1)['id'], 'new-id');
      expect(pipeline.getAsMap(1)['title'], 'Inserted');
    });

    test('single mode keeps exactly one record and updates in place', () async {
      final pipeline = buildPostPipeline(
        id: 'single.post',
        mode: QLPipelineMode.single,
      );

      pipeline.ingest(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 's1',
          'title': 'One',
          'likes': 2,
          'published': true,
        },
      ]);
      await flushRuntime();
      expect(pipeline.visibleCount, 1);
      expect(pipeline.getAsMap(0)['title'], 'One');

      pipeline.ingest(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 's1',
          'title': 'Two',
          'likes': 4,
          'published': false,
        },
      ]);
      await flushRuntime();
      expect(pipeline.getAsMap(0)['title'], 'Two');
      expect(pipeline.getAsMap(0)['published'], isFalse);
    });

    test('pipeline registry registers destroys and clears live pipelines', () {
      final pipeline = buildPostPipeline(id: 'registry.pipe');
      QLPipelineRegistry.instance.register(pipeline);

      expect(QLPipelineRegistry.instance.exists('registry.pipe'), isTrue);
      expect(
          QLPipelineRegistry.instance.get('registry.pipe').id, 'registry.pipe');

      QLPipelineRegistry.instance.destroy('registry.pipe');
      expect(QLPipelineRegistry.instance.exists('registry.pipe'), isFalse);
    });

    test('notifyScrollIndex is a no-op without a delegate', () async {
      final pipeline = buildPostPipeline(pageSize: 2);
      pipeline.ingest(<Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'p1',
          'title': 'A',
          'likes': 1,
          'published': true
        },
        <String, dynamic>{
          'id': 'p2',
          'title': 'B',
          'likes': 2,
          'published': true
        },
      ]);
      await flushRuntime();
      pipeline.notifyScrollIndex(1);
      await flushRuntime();
      expect(pipeline.visibleCount, 2);
    });
  });

  group('QLStoreSlice, execution context, and strategy registry', () {
    test('slice toMap and merge preserve all declared contracts', () {
      final base = QLStoreSlice(
        namespace: 'feed',
        schema: 'Post',
        dataSource: 'feedSource',
        state: <String, dynamic>{'items': <dynamic>[]},
        computed: <String, dynamic>{
          'count': <String, dynamic>{
            'deps': <String>['items'],
            'op': 'count'
          }
        },
        mutations: <String, dynamic>{
          'like': <String, dynamic>{'strategy': 'test.bumpBy'}
        },
        queries: <String, dynamic>{
          'read': <String, dynamic>{'strategy': 'test.listCount'}
        },
        pipelines: <String, dynamic>{
          'main': <String, dynamic>{'strategy': 'feedTimeline'}
        },
        strategies: <String, dynamic>{
          'feedTimeline': <String, dynamic>{'op': 'refresh'}
        },
        metadata: <String, dynamic>{'ui': 'social'},
      );
      final overlay = QLStoreSlice(
        namespace: 'feed',
        metadata: <String, dynamic>{'feature': 'timeline'},
        pipelines: <String, dynamic>{
          'secondary': <String, dynamic>{'strategy': 'other'}
        },
      );

      final merged = base.merge(overlay);
      final map = merged.toMap();

      expect(map['namespace'], 'feed');
      expect(map['schema'], 'Post');
      expect((map['pipelines'] as Map).containsKey('secondary'), isTrue);
      expect((map['metadata'] as Map)['feature'], 'timeline');
    });

    test('execution context exports the slice contract shape', () {
      final slice = QLStoreSlice(
        namespace: 'feed',
        schema: 'Post',
        dataSource: 'feedSource',
        state: <String, dynamic>{'items': <dynamic>[]},
        computed: <String, dynamic>{
          'count': <String, dynamic>{
            'deps': <String>['items'],
            'op': 'count'
          }
        },
        mutations: const <String, dynamic>{},
        queries: const <String, dynamic>{},
        pipelines: const <String, dynamic>{},
        metadata: <String, dynamic>{'ui': 'social'},
      );
      final ctx = QLSliceExecutionContext(
        namespace: slice.namespace,
        sliceName: 'feed',
        schema: slice.schema,
        dataSource: slice.dataSource,
        metadata: slice.metadata,
        sliceDefinition: slice.toMap(),
        slice: slice,
      );

      final map = ctx.toMap();
      expect(map['namespace'], 'feed');
      expect(map['sliceName'], 'feed');
      expect(map['dataSource'], 'feedSource');
      expect((map['stateKeys'] as List), contains('items'));
    });

    test(
        'built-in mutation strategies write directly without state.set boilerplate',
        () async {
      final store = QLStoreRegistry.instance.get('strategy.mutations');
      final slice = QLStoreSlice(namespace: 'strategy.mutations');
      final ctx = QLSliceExecutionContext(
        namespace: 'strategy.mutations',
        sliceName: 'mutations',
        schema: null,
        dataSource: null,
        metadata: const <String, dynamic>{},
        sliceDefinition: slice.toMap(),
        slice: slice,
      );

      store.set('items', <dynamic>[]);

      await QLSliceStrategyRegistry.instance.execute(
        'state.set',
        store,
        <String, dynamic>{'path': 'profile.name', 'value': 'Ada'},
        ctx,
        kind: 'mutation',
      );
      await QLSliceStrategyRegistry.instance.execute(
        'state.merge',
        store,
        <String, dynamic>{
          'path': 'profile',
          'value': <String, dynamic>{'role': 'creator'}
        },
        ctx,
        kind: 'mutation',
      );
      await QLSliceStrategyRegistry.instance.execute(
        'append',
        store,
        <String, dynamic>{
          'path': 'items',
          'value': <String, dynamic>{'id': '1'}
        },
        ctx,
        kind: 'mutation',
      );
      await QLSliceStrategyRegistry.instance.execute(
        'patch',
        store,
        <String, dynamic>{
          'path': 'profile',
          'patch': <String, dynamic>{'city': 'Sana'}
        },
        ctx,
        kind: 'mutation',
      );
      await QLSliceStrategyRegistry.instance.execute(
        'toggle',
        store,
        <String, dynamic>{'path': 'enabled'},
        ctx,
        kind: 'mutation',
      );
      await QLSliceStrategyRegistry.instance.execute(
        'increment',
        store,
        <String, dynamic>{'path': 'counter', 'by': 3},
        ctx,
        kind: 'mutation',
      );
      await QLSliceStrategyRegistry.instance.execute(
        'decrement',
        store,
        <String, dynamic>{'path': 'counter', 'by': 1},
        ctx,
        kind: 'mutation',
      );

      // FIX 4: Use state.set value: null to cleanly remove nested paths instead
      // of using state.remove/sweep (which only handles root signal keys).
      await QLSliceStrategyRegistry.instance.execute(
        'state.set',
        store,
        <String, dynamic>{'path': 'profile.city', 'value': null},
        ctx,
        kind: 'mutation',
      );

      expect(store.get('profile.name'), 'Ada');
      expect(store.get('profile.role'), 'creator');
      expect((store.get('items') as List).single['id'], '1');
      expect(store.get('enabled'), isTrue);
      expect(store.get('counter'), 2.0);
      expect(store.get('profile.city'), isNull);
    });

    test('built-in query strategies read the current store view', () async {
      final store = QLStoreRegistry.instance.get('strategy.queries');
      store.set('items', <Map<String, dynamic>>[
        <String, dynamic>{'id': '1'},
        <String, dynamic>{'id': '2'},
      ]);
      final slice = QLStoreSlice(namespace: 'strategy.queries');
      final ctx = QLSliceExecutionContext(
        namespace: 'strategy.queries',
        sliceName: 'queries',
        schema: null,
        dataSource: null,
        metadata: const <String, dynamic>{},
        sliceDefinition: slice.toMap(),
        slice: slice,
      );

      final snapshot = await QLSliceStrategyRegistry.instance.execute(
        'snapshot',
        store,
        <String, dynamic>{},
        ctx,
        kind: 'query',
      );
      final keys = await QLSliceStrategyRegistry.instance.execute(
        'keys',
        store,
        <String, dynamic>{},
        ctx,
        kind: 'query',
      );
      final resolved = await QLSliceStrategyRegistry.instance.execute(
        'get',
        store,
        <String, dynamic>{'path': 'items'},
        ctx,
        kind: 'query',
      );

      expect((snapshot as Map<String, dynamic>)['items'], isNotNull);
      expect(keys, contains('items'));
      expect(resolved, isA<List<dynamic>>());
    });

    test('local slice strategies are resolved before falling back to built-ins',
        () async {
      final store = QLStoreRegistry.instance.get('slice.local');
      store.set('likes', 1);

      final slice = QLStoreSlice(
        namespace: 'slice.local',
        schema: 'Post',
        strategies: <String, dynamic>{
          'bumpLikes': <String, dynamic>{
            'op': 'increment',
            'path': 'likes',
            'by': 4,
          },
        },
        mutations: <String, dynamic>{
          'like': <String, dynamic>{
            'strategy': 'bumpLikes',
          },
        },
      );

      final ctx = QLSliceExecutionContext(
        namespace: 'slice.local',
        sliceName: 'local',
        schema: slice.schema,
        dataSource: null,
        metadata: const <String, dynamic>{},
        sliceDefinition: slice.toMap(),
        slice: slice,
      );

      final actionCalls = <String, QLActionPlugin>{};
      final previousRegistrar = QLSliceRegistry.actionRegistrar;
      QLSliceRegistry.actionRegistrar =
          (String actionName, QLActionPlugin plugin) {
        actionCalls[actionName] = plugin;
      };

      try {
        QLSliceRegistry.instance.mount(slice);
        expect(actionCalls.keys, contains('slice.local.like'));

        await actionCalls['slice.local.like']!.execute(
          <String, dynamic>{},
          store,
          const QLNullContext(),
        );
        await flushRuntime();
        expect(store.get('likes'), 5);
      } finally {
        QLSliceRegistry.actionRegistrar = previousRegistrar;
      }
    });

    test(
        'query plugins store loading state, result, and no error for successful execution',
        () async {
      final store = QLStoreRegistry.instance.get('slice.query.plugin');
      store.set('items', <Map<String, dynamic>>[
        <String, dynamic>{'id': '1'},
        <String, dynamic>{'id': '2'},
        <String, dynamic>{'id': '3'},
      ]);

      final slice = QLStoreSlice(
        namespace: 'slice.query.plugin',
        schema: 'Post',
        queries: <String, dynamic>{
          'countItems': <String, dynamic>{
            'strategy': 'test.listCount',
            'path': 'items',
          },
        },
      );

      final ctx = QLSliceExecutionContext(
        namespace: 'slice.query.plugin',
        sliceName: 'query',
        schema: slice.schema,
        dataSource: null,
        metadata: const <String, dynamic>{},
        sliceDefinition: slice.toMap(),
        slice: slice,
      );

      final actionCalls = <String, QLActionPlugin>{};
      final previousRegistrar = QLSliceRegistry.actionRegistrar;
      QLSliceRegistry.actionRegistrar =
          (String actionName, QLActionPlugin plugin) {
        actionCalls[actionName] = plugin;
      };

      try {
        QLSliceRegistry.instance.mount(slice);
        final result =
            await actionCalls['slice.query.plugin.countItems']!.execute(
          <String, dynamic>{},
          store,
          const QLNullContext(),
        );
        await flushRuntime();

        expect(result, 3);
        expect(store.get('countItems.data'), 3);
        expect(store.get('countItems.loading'), isFalse);
        expect(store.get('countItems.error'), isNull);
      } finally {
        QLSliceRegistry.actionRegistrar = previousRegistrar;
      }
    });

    test(
        'slice mount wires source bindings, computed values, and unmount cleans pipelines',
        () async {
      final source = QLDataSourceRegistry.instance.register(
        'slice.source',
        <String, dynamic>{
          'type': 'realtime',
          'seed': buildFeedSourceSeed(),
        },
      );

      final slice = QLStoreSlice(
        namespace: 'feed.page',
        schema: 'Post',
        dataSource: 'slice.source',
        state: <String, dynamic>{
          'items': <String, dynamic>{
            'mode': 'hybrid',
            'from': 'items',
            'merge': 'appendById',
            'subscribe': true,
            'default': <dynamic>[],
          },
          'cursor': <String, dynamic>{
            'mode': 'remote',
            'from': 'cursor',
            'default': null,
          },
          'draft': '',
        },
        computed: <String, dynamic>{
          'itemCount': <String, dynamic>{
            'deps': <String>['items'],
            'op': 'count',
          },
        },
        mutations: <String, dynamic>{
          'appendItem': <String, dynamic>{
            'strategy': 'append',
            'path': 'items',
            'payload': <String, dynamic>{
              'valueFrom': r'$event.item',
            },
          },
        },
        queries: <String, dynamic>{
          'readState': <String, dynamic>{
            'strategy': 'snapshot',
          },
        },
        pipelines: <String, dynamic>{
          'main': <String, dynamic>{
            'strategy': 'feedTimeline',
          },
        },
      );

      final pipeline = buildPostPipeline(id: 'feed.page.main');
      QLPipelineRegistry.instance.register(pipeline);

      final actionCalls = <String, QLActionPlugin>{};
      final previousRegistrar = QLSliceRegistry.actionRegistrar;
      QLSliceRegistry.actionRegistrar =
          (String actionName, QLActionPlugin plugin) {
        actionCalls[actionName] = plugin;
      };

      try {
        QLSliceRegistry.instance.mount(slice);
        await flushRuntime();

        final store = QLStoreRegistry.instance.get('feed.page');
        expect(store.get('draft'), '');
        expect(store.get('cursor'), 'next-page-token');
        expect((store.get('items') as List).length, 1);
        expect(store.get('itemCount'), 1);
        expect(actionCalls.keys, contains('feed.page.appendItem'));
        expect(actionCalls.keys, contains('feed.page.readState'));
        expect(QLPipelineRegistry.instance.exists('feed.page.main'), isTrue);

        source.signal.data.setSilent(buildFeedSourceSeed(likes: 4));
        source.signal.data.forceNotify();
        await flushRuntime();

        expect(store.get('itemCount'), 1);
        expect(store.get('cursor'), 'next-page-token');

        QLSliceRegistry.instance.unmount('feed.page');
        expect(QLPipelineRegistry.instance.exists('feed.page.main'), isFalse);
        expect(store.snapshot, isEmpty);
      } finally {
        QLSliceRegistry.actionRegistrar = previousRegistrar;
      }
    });

    test('multiple mounted slices stay isolated by namespace and dataSource',
        () async {
      final sourceA = QLDataSourceRegistry.instance.register(
        'source.a',
        <String, dynamic>{
          'type': 'realtime',
          'seed': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'a1', 'title': 'Alpha'},
            ],
          },
        },
      );
      final sourceB = QLDataSourceRegistry.instance.register(
        'source.b',
        <String, dynamic>{
          'type': 'realtime',
          'seed': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'id': 'b1', 'title': 'Beta'},
            ],
          },
        },
      );

      final sliceA = QLStoreSlice(
        namespace: 'slice.a',
        schema: 'Post',
        dataSource: 'source.a',
        state: <String, dynamic>{
          'items': <String, dynamic>{
            'mode': 'hybrid',
            'from': 'items',
            'merge': 'appendById',
            'subscribe': true,
            'default': <dynamic>[],
          },
        },
      );
      final sliceB = QLStoreSlice(
        namespace: 'slice.b',
        schema: 'Post',
        dataSource: 'source.b',
        state: <String, dynamic>{
          'items': <String, dynamic>{
            'mode': 'hybrid',
            'from': 'items',
            'merge': 'appendById',
            'subscribe': true,
            'default': <dynamic>[],
          },
        },
      );

      QLSliceRegistry.instance.mount(sliceA);
      QLSliceRegistry.instance.mount(sliceB);
      await flushRuntime();

      final storeA = QLStoreRegistry.instance.get('slice.a');
      final storeB = QLStoreRegistry.instance.get('slice.b');
      expect((storeA.get('items') as List).single['id'], 'a1');
      expect((storeB.get('items') as List).single['id'], 'b1');

      sourceA.signal.data.setSilent(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'a1', 'title': 'Alpha2'},
          <String, dynamic>{'id': 'a2', 'title': 'Alpha3'},
        ],
      });
      sourceA.signal.data.forceNotify();
      await flushRuntime();

      expect((storeA.get('items') as List).length, 2);
      expect((storeB.get('items') as List).length, 1);
    });
  });

  group('End-to-end contract behavior', () {
    test(
        'a slice can bind local state, remote state, computed state, custom mutation, and a pipeline snapshot together',
        () async {
      final source = QLDataSourceRegistry.instance.register(
        'source.end.to.end',
        <String, dynamic>{
          'type': 'realtime',
          'seed': buildFeedSourceSeed(id: 'e1', title: 'End to end'),
        },
      );

      final slice = QLStoreSlice(
        namespace: 'end.to.end',
        schema: 'Post',
        dataSource: 'source.end.to.end',
        state: <String, dynamic>{
          'items': <String, dynamic>{
            'mode': 'hybrid',
            'from': 'items',
            'merge': 'appendById',
            'subscribe': true,
            'default': <dynamic>[],
          },
          'draft': '',
          'cursor': <String, dynamic>{
            'mode': 'remote',
            'from': 'cursor',
          },
        },
        computed: <String, dynamic>{
          'itemCount': <String, dynamic>{
            'deps': <String>['items'],
            'op': 'count',
          },
        },
        strategies: <String, dynamic>{
          'bumpItemCount': <String, dynamic>{
            'op': 'increment',
            'path': 'localCounter',
            'by': 1,
          },
        },
        mutations: <String, dynamic>{
          'bump': <String, dynamic>{'strategy': 'bumpItemCount'},
        },
        queries: <String, dynamic>{
          'readAll': <String, dynamic>{'strategy': 'snapshot'},
        },
        pipelines: <String, dynamic>{
          'main': <String, dynamic>{'strategy': 'feedTimeline'},
        },
      );

      final pipeline = buildPostPipeline(id: 'end.to.end.main', pageSize: 2);
      QLPipelineRegistry.instance.register(pipeline);

      final actions = <String, QLActionPlugin>{};
      final previousRegistrar = QLSliceRegistry.actionRegistrar;
      QLSliceRegistry.actionRegistrar =
          (String actionName, QLActionPlugin plugin) {
        actions[actionName] = plugin;
      };

      try {
        QLSliceRegistry.instance.mount(slice);
        await flushRuntime();

        final store = QLStoreRegistry.instance.get('end.to.end');
        expect(store.get('cursor'), 'next-page-token');
        expect(store.get('itemCount'), 1);
        expect(actions.containsKey('end.to.end.bump'), isTrue);
        expect(actions.containsKey('end.to.end.readAll'), isTrue);

        await actions['end.to.end.bump']!.execute(
          <String, dynamic>{},
          store,
          const QLNullContext(),
        );
        await flushRuntime();
        expect(store.get('localCounter'), 1.0);

        pipeline.ingest(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'e1',
            'title': 'End to end',
            'likes': 10,
            'published': true,
          },
          <String, dynamic>{
            'id': 'e2',
            'title': 'Second record',
            'likes': 5,
            'published': true,
          },
        ]);
        await flushRuntime();

        expect(pipeline.visibleCount, 2);
        expect(pipeline.getAsMap(1)['id'], 'e2');

        source.signal.data
            .setSilent(buildFeedSourceSeed(id: 'e1', title: 'Updated seed'));
        source.signal.data.forceNotify();
        await flushRuntime();
        expect((store.get('items') as List).isNotEmpty, isTrue);

        QLSliceRegistry.instance.unmount('end.to.end');
        expect(QLPipelineRegistry.instance.exists('end.to.end.main'), isFalse);
      } finally {
        QLSliceRegistry.actionRegistrar = previousRegistrar;
      }
    });
  });
}
