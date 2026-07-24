import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quantum_layout/quantum.dart';

class _StaticPipelineDelegate implements QLPipelineDelegate {
  final List<Map<String, dynamic>> data;
  final List<Map<String, dynamic>> partial;

  const _StaticPipelineDelegate({
    required this.data,
    this.partial = const <Map<String, dynamic>>[],
  });

  @override
  Future<List<Map<String, dynamic>>> fetch(Map<String, dynamic> state) async {
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPartial(
      List<String> ids, QLProjection projection) async {
    return List<Map<String, dynamic>>.from(partial);
  }
}

void _resetRuntime() {
  QuantumVM.instance.dispose();
  QLSliceRegistry.instance.clear();
  QLPipelineRegistry.instance.clear();
  QLDataSourceRegistry.instance.clear();
  QLStoreRegistry.instance.clearAll();
  QLSchemaRegistry.instance.clear();
  QLSliceRegistry.actionRegistrar = null;
}

QLSchemaBlueprint _schemaForRecord(String name) {
  return QLSchemaRegistry.instance.compile(name, <String, dynamic>{
    'id': <String, dynamic>{'type': 'string', 'required': true},
    'name': <String, dynamic>{
      'type': 'string',
      'required': true,
      'min': 2,
      'max': 64
    },
    'score': <String, dynamic>{'type': 'number', 'min': 0, 'max': 100},
    'flag': <String, dynamic>{'type': 'boolean'},
    'tags': <String, dynamic>{
      'type': 'array',
      'items': <String, dynamic>{'type': 'string'},
    },
    'profile': <String, dynamic>{
      'type': 'object',
      'fields': <String, dynamic>{
        'avatar': <String, dynamic>{
          'type': 'string',
          'required': false,
        },
        'bio': <String, dynamic>{
          'type': 'string',
        },
      },
    },
  });
}

Map<String, dynamic> _designSystemManifest({
  required String id,
  required String componentName,
  required int seed,
}) {
  return <String, dynamic>{
    'id': id,
    'metadata': <String, dynamic>{
      'description': 'Design system $id',
      'seed': seed,
    },
    'components': <String, dynamic>{
      componentName: <String, dynamic>{
        'name': componentName,
        'description': 'Native component $componentName',
        'props': <String, dynamic>{
          'label': 'Label $seed',
          'count': seed,
        },
        'state': <String, dynamic>{
          'enabled': seed.isEven,
        },
        'computed': <String, dynamic>{
          'labelCount': <String, dynamic>{
            'deps': <String>['props.label', 'state.enabled'],
            'op': 'identity',
          },
        },
        'hooks': <String, dynamic>{
          'mount': <dynamic>[],
          'unmount': <dynamic>[],
          'effects': <dynamic>[],
        },
        'runtime': <String, dynamic>{
          'schema': 'ButtonSchema',
          'feature': 'nativeComponent',
        },
        'policy': <String, dynamic>{
          'permission': 'ui.render',
        },
        'slots': <String, dynamic>{
          'leading': <String, dynamic>{
            'type': 'text',
            'props': <String, dynamic>{'text': 'L$seed'},
          },
        },
      },
    },
  };
}

QLStoreSlice _sliceWithBinding({
  required String namespace,
  required String dataSource,
  required int seed,
}) {
  return QLStoreSlice(
    namespace: namespace,
    schema: 'Post',
    dataSource: dataSource,
    state: <String, dynamic>{
      'items': <String, dynamic>{
        'mode': 'hybrid',
        'from': 'dataSource.items',
        'merge': 'appendById',
        'subscribe': true,
        'default': <dynamic>[],
      },
      'cursor': <String, dynamic>{
        'mode': 'remote',
        'from': 'dataSource.cursor',
        'default': null,
      },
      'draft': <String, dynamic>{
        'mode': 'local',
        'default': 'draft-$seed',
      },
      'count': <String, dynamic>{
        'mode': 'local',
        'default': 0,
      },
    },
    computed: <String, dynamic>{
      'itemCount': <String, dynamic>{
        'deps': <String>['items'],
        'op': 'count',
      },
      'hasCursor': <String, dynamic>{
        'deps': <String>['cursor'],
        'op': 'notNull',
      },
    },
    mutations: <String, dynamic>{
      'appendItem': <String, dynamic>{
        'strategy': 'append',
        'path': 'items',
      },
      'setDraft': <String, dynamic>{
        'strategy': 'state.set',
        'path': 'draft',
      },
      'bumpCount': <String, dynamic>{
        'strategy': 'increment',
        'path': 'count',
        'payload': <String, dynamic>{'by': 1},
      },
    },
    queries: <String, dynamic>{
      'snapshotQuery': <String, dynamic>{
        'strategy': 'snapshot',
      },
      'keysQuery': <String, dynamic>{
        'strategy': 'keys',
      },
    },
    pipelines: <String, dynamic>{
      'feed': <String, dynamic>{
        'strategy': 'appendById',
        'subscribe': true,
        'realtime': true,
      },
    },
    strategies: <String, dynamic>{
      'toggleEnabled': <String, dynamic>{
        'kind': 'mutation',
        'op': 'toggle',
        'path': 'draftEnabled',
      },
    },
    metadata: <String, dynamic>{
      'seed': seed,
      'group': 'slice',
    },
  );
}

QLDataPipeline _makePipeline({
  required String id,
  required int seed,
}) {
  final schema = _schemaForRecord('PipeSchema_$seed');
  final delegateData = List<Map<String, dynamic>>.generate(6, (index) {
    return <String, dynamic>{
      'id': '$seed-$index',
      'name': 'Item $seed/$index',
      'score': (seed + index) % 101,
      'flag': index.isEven,
      'tags': <String>['tag${seed % 5}', 'tag$index'],
      'profile': <String, dynamic>{
        'avatar': 'a$index.png',
        'bio': 'bio-$seed-$index',
      },
    };
  });
  return QLDataPipeline(
    id: id,
    schema: schema,
    mode: QLPipelineMode.collection,
    executionMode: QLExecutionMode.client,
    pageSize: 2,
    delegate: _StaticPipelineDelegate(
      data: delegateData,
      partial: delegateData.take(2).toList(growable: false),
    ),
  );
}

void main() {
  setUp(_resetRuntime);

  group('runtime cache', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('lru ttl eviction and compaction $i', () {
        final cache = QLRuntimeCache<String>(
          config: QLRuntimeCacheConfig(
            maxEntries: 3,
            maxWeight: 0,
            defaultTtl: i % 5 == 0 ? Duration.zero : null,
          ),
        );

        switch (i % 5) {
          case 0:
            cache.put('a$i', 'A$i', ttl: Duration.zero);
            cache.put('b$i', 'B$i', ttl: Duration.zero);
            cache.sweepExpired();
            expect(cache.get('a$i'), isNull);
            expect(cache.get('b$i'), isNull);
            break;
          case 1:
            cache.put('a$i', 'A$i');
            cache.put('b$i', 'B$i');
            cache.put('c$i', 'C$i');
            cache.put('d$i', 'D$i');
            expect(cache.stats.evictions, 1);
            expect(cache.contains('d$i'), isTrue);
            expect(cache.stats.entries, 3);
            break;
          case 2:
            cache.put('a$i', 'A$i');
            cache.put('b$i', 'B$i');
            cache.put('c$i', 'C$i');
            cache.removeWhere((key, entry) => key.toString().contains('b'));
            expect(cache.contains('b$i'), isFalse);
            expect(cache.stats.entries, 2);
            break;
          case 3:
            cache.put('a$i', 'A$i');
            cache.put('b$i', 'B$i');
            cache.clear();
            expect(cache.stats.entries, 0);
            expect(cache.get('a$i'), isNull);
            break;
          default:
            final value = cache.getOrPut('x$i', () => 'V$i');
            final valueAgain = cache.getOrPut('x$i', () => 'W$i');
            expect(value, 'V$i');
            expect(valueAgain, 'V$i');
            expect(cache.stats.hits, greaterThanOrEqualTo(1));
            break;
        }
      });
    }
  });

  group('module access and lazy schema views', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('module policy and lookup $i', () {
        final moduleId = 'team$i:module';
        final targetId = 'team$i:target';
        final policy = QLModuleAccessPolicy.from(<String, dynamic>{
          'visibility': switch (i % 4) {
            0 => 'public',
            1 => 'local',
            2 => 'owner',
            _ => 'secure',
          },
          'allow': i % 6 == 0 ? <String>['*'] : <String>[],
          'owner': 'owner-$i',
        });

        final record = QLModuleRegistry.instance.register(
          <String, dynamic>{
            'id': targetId,
            'access': <String, dynamic>{
              'visibility': switch (i % 4) {
                0 => 'public',
                1 => 'local',
                2 => 'owner',
                _ => 'secure',
              },
              'allow': i % 6 == 0 ? <String>['*'] : <String>[],
              'owner': 'owner-$i',
            },
            'macros': <String, dynamic>{
              'macro$i': <String, dynamic>{'value': i},
            },
            'modules': <String, dynamic>{
              'child': <String, dynamic>{
                'value': i,
              },
            },
          },
        );

        expect(record.id, targetId);
        expect(QLModuleRegistry.instance.exists(targetId), isTrue);
        expect(QLModuleRegistry.instance.importsFor(targetId), isEmpty);

        final allowed = policy.allows(
          requester: moduleId,
          target: targetId,
          ownerId: 'owner-$i',
        );
        if (i % 4 == 0) {
          expect(allowed, isTrue);
        } else if (i % 4 == 1) {
          expect(allowed, isTrue);
        } else if (i % 4 == 2) {
          expect(allowed, isTrue);
        } else {
          expect(allowed, i % 6 == 0);
        }

        final manifest = <String, dynamic>{
          'first': <String, dynamic>{'a': i},
          'second': <String, dynamic>{'b': i + 1},
          'plain': i,
        };
        final view = QLLazySchemaView('lazy-$i', manifest);
        expect(view.field('first')?.definition['a'], i);
        expect(view.field('second')?.definition['b'], i + 1);
        expect(view.field('plain'), isNull);
        expect(view.pick(<String>['first', 'second']).length, 2);
      });
    }
  });

  group('schema compiler and validation', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('schema parse serialize validate $i', () {
        final schemaName = 'Schema$i';
        final schema = _schemaForRecord(schemaName);
        expect(schema.fieldCount, greaterThanOrEqualTo(5));
        expect(schema.fieldPaths(), contains('id'));

        final validRecord = <String, dynamic>{
          'id': 'id-$i',
          'name': 'Name $i',
          'score': i % 100,
          'flag': i.isEven,
          'tags': <String>['x', 'y'],
          'profile': <String, dynamic>{
            'avatar': 'avatar$i.png',
            'bio': 'bio-$i',
          },
        };

        final invalidRecord = <String, dynamic>{
          'id': '',
          'name': i % 2 == 0 ? 'A' : 'Name$i' * 5,
          'score': i % 2 == 0 ? -1 : 999,
          'tags': <dynamic>['x', 2],
          'profile': <String, dynamic>{
            'avatar': 1,
          },
        };

        final parsed = schema.parse(validRecord);
        final serialized = schema.serialize(parsed);
        final errsValid = schema.validate(validRecord);
        final errsInvalid = schema.validate(invalidRecord);

        expect(parsed['id'], 'id-$i');
        expect(serialized['name'], startsWith('Name'));
        expect(errsValid, isEmpty);
        expect(errsInvalid, isNotEmpty);

        final projection = schema.createProjection(<String>['profile']);
        expect(
            projection.isSelected(schema.getIndex('profile.avatar')), isTrue);
        final expanded = schema.expandSelection(<String>['profile']);
        expect(expanded, contains('profile.avatar'));
      });
    }
  });

  group('data store state semantics', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('set get merge transaction rollback $i', () {
        final store = QLDataStore(namespace: 'store$i');

        store.set('profile.name', 'User$i');
        store.set('profile.age', i);
        store.set('flags.active', i.isEven);
        store.set('items', <dynamic>[i, i + 1]);
        store.registerComputed(
          'profile.summary',
          <String>['profile.name', 'profile.age'],
          (values) => '${values[0]}:${values[1]}',
        );

        expect(store.get('profile.name'), 'User$i');
        expect(store.get('profile.age'), i);
        expect(store.get('profile.summary'), 'User$i:$i');

        store.saveSnapshot();
        store.transaction(() {
          store.set('profile.age', i + 100);
          store.set('flags.active', false);
        });
        store.rollback();

        expect(store.get('profile.age'), i);
        expect(store.get('flags.active'), i.isEven);

        if (i % 3 == 0) {
          store.merge(
            <String, dynamic>{
              'profile': <String, dynamic>{'name': 'Merged$i'},
              'extra': <String, dynamic>{'v': i},
            },
            clearMissing: true,
          );
          expect(store.get('profile.name'), 'Merged$i');
          expect(store.get('extra.v'), i);
        } else {
          store.sweep('extra');
          expect(store.get('extra.v'), isNull);
        }

        store.clearCache();
        expect(store.has('profile.name'), isTrue);
      });
    }
  });

  group('data source transport and hybrid bindings', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('source classification binding and snapshot $i', () {
        final sourceName = 'source$i';
        final config = <String, dynamic>{
          'type': switch (i % 4) {
            0 => 'realtime',
            1 => 'media',
            2 => 'stream',
            _ => 'api',
          },
          'subscribe': i % 2 == 0,
          'realtime': i % 3 == 0,
          'stream': i % 5 == 0
              ? <String, dynamic>{'mode': 'duplex', 'kind': 'data'}
              : null,
          'seed': <String, dynamic>{
            'items': <dynamic>[
              <String, dynamic>{'id': 'seed-$i', 'value': i},
            ],
            'cursor': 'cursor-$i',
          },
        };

        final handle =
            QLDataSourceRegistry.instance.register(sourceName, config);
        expect(handle.name, sourceName);
        expect(handle.signal.data.value, isNotNull);
        expect(handle.isStreaming, isTrue);

        final store = QLStoreRegistry.instance.get('slice$i');
        final cancel = QLDataSourceRegistry.instance.attachStateBinding(
          namespace: 'slice$i',
          store: store,
          sourceName: sourceName,
          statePath: 'feed.items',
          sourcePath: 'items',
          merge: 'replace',
          defaultValue: <dynamic>[],
          transform: i % 2 == 0 ? 'count' : 'identity',
          subscribe: true,
          metadata: <String, dynamic>{'seed': i},
          ctx: QLSliceExecutionContext(
            namespace: 'slice$i',
            sliceName: 'slice$i',
            schema: 'Feed',
            dataSource: sourceName,
            metadata: <String, dynamic>{'seed': i},
            sliceDefinition: const <String, dynamic>{},
            slice: QLStoreSlice(namespace: 'slice$i'),
          ),
        );

        handle.signal.data.value = <String, dynamic>{
          'items': <dynamic>[
            <String, dynamic>{'id': 'live-$i', 'value': i + 1},
          ],
          'cursor': 'next-$i',
        };
        handle.signal.data.forceNotify();

        final bound = store.get('feed.items');
        if (i % 2 == 0) {
          expect(bound, 1);
        } else {
          expect(bound, isNotNull);
        }

        final snapshot = QLDataSourceRegistry.instance.snapshot();
        expect(snapshot['count'], greaterThanOrEqualTo(1));
        expect((snapshot['sources'] as List).isNotEmpty, isTrue);

        cancel();
      });
    }
  });

  group('slice registry, strategies, mutation plugins, and query plugins', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('slice mount strategy execution $i', () {
        final captured = <String, QLActionPlugin>{};
        QLSliceRegistry.actionRegistrar = (String name, QLActionPlugin plugin) {
          captured[name] = plugin;
        };

        final sourceName = 'sliceSource$i';
        QLDataSourceRegistry.instance.register(
          sourceName,
          <String, dynamic>{
            'type': 'realtime',
            'subscribe': true,
            'seed': <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{'id': 'a$i', 'value': i},
              ],
              'cursor': 'c$i',
            },
          },
        );

        final slice = _sliceWithBinding(
          namespace: 'feed$i',
          dataSource: sourceName,
          seed: i,
        );
        QLSliceRegistry.instance.mount(slice);

        final store = QLStoreRegistry.instance.get('feed$i');
        expect(store.get('draft'), 'draft-$i');
        expect(store.get('items'), isNotNull);
        expect(store.get('itemCount'), isNotNull);
        expect(QLSliceRegistry.instance.snapshot()['count'],
            greaterThanOrEqualTo(1));
        expect(QLSliceRegistry.instance['feed$i']?.schema, 'Post');

        final mutation = captured['feed$i.appendItem'];
        final query = captured['feed$i.snapshotQuery'];
        final keysQuery = captured['feed$i.keysQuery'];
        expect(mutation, isNotNull);
        expect(query, isNotNull);
        expect(keysQuery, isNotNull);

        final mutationResult = mutation!.execute(<String, dynamic>{
          'path': 'items',
          'value': <dynamic>[
            <String, dynamic>{'id': 'm$i', 'value': i + 10},
          ],
        }, store, QLNullContext());
        expect(mutationResult, completes);

        final snapshotResult = query!.execute(
          <String, dynamic>{},
          store,
          QLNullContext(),
        );
        expect(snapshotResult, completes);

        final keysResult = keysQuery!.execute(
          <String, dynamic>{},
          store,
          QLNullContext(),
        );
        expect(keysResult, completes);

        final builtIn = QLSliceStrategyRegistry.instance.execute(
          'state.set',
          store,
          <String, dynamic>{'path': 'draft', 'value': 'updated-$i'},
          QLSliceExecutionContext(
            namespace: 'feed$i',
            sliceName: 'feed$i',
            schema: 'Post',
            dataSource: sourceName,
            metadata: const <String, dynamic>{},
            sliceDefinition: slice.toMap(),
            slice: slice,
          ),
        );
        expect(builtIn, 'updated-$i');

        final localStrategy = QLSliceStrategyRegistry.instance.execute(
          'toggleEnabled',
          store,
          <String, dynamic>{},
          QLSliceExecutionContext(
            namespace: 'feed$i',
            sliceName: 'feed$i',
            schema: 'Post',
            dataSource: sourceName,
            metadata: const <String, dynamic>{},
            sliceDefinition: slice.toMap(),
            slice: slice,
          ),
        );
        expect(localStrategy, isA<bool>());

        QLSliceRegistry.instance.unmount('feed$i');
        expect(QLSliceRegistry.instance['feed$i'], isNull);
      });
    }
  });

  group('pipeline ingest filter search sort patch and snapshot', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('pipeline lifecycle $i', () {
        final pipeline = _makePipeline(id: 'pipe$i', seed: i);
        QLPipelineRegistry.instance.register(pipeline);

        expect(QLPipelineRegistry.instance.exists('pipe$i'), isTrue);
        expect(QLPipelineRegistry.instance.get('pipe$i').id, 'pipe$i');

        pipeline.replaceAll(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'r$i-1',
            'name': 'Alpha$i',
            'score': i % 100,
            'flag': true,
            'tags': <String>['a']
          },
          <String, dynamic>{
            'id': 'r$i-2',
            'name': 'Beta$i',
            'score': (i + 10) % 100,
            'flag': false,
            'tags': <String>['b']
          },
          <String, dynamic>{
            'id': 'r$i-3',
            'name': 'Gamma$i',
            'score': (i + 20) % 100,
            'flag': true,
            'tags': <String>['c']
          },
        ]);

        pipeline.setFilters(<int, String>{0: 'r$i-2'});
        pipeline.setSearchQuery('Beta$i');
        pipeline.setSort(2, ascending: i.isEven);

        // FIX: Replaced `pipeline.setPage(i % 2);` with `0`.
        // The search query strictly filters to exactly 1 matching item.
        // Setting it to page index 1 (the 2nd page) would yield 0 items on that page,
        // causing `visibleCount` to fail the expectation of >= 1 below.
        pipeline.setPage(0);

        pipeline.notifyScrollIndex(0);
        pipeline.patch(
            'r$i-2', <String, dynamic>{'score': 99, 'name': 'Beta$i-updated'});

        final snapshot = pipeline.snapshot();
        expect(snapshot['id'], 'pipe$i');
        expect(snapshot['recordCount'], 3);
        expect(snapshot['schema'], 'PipeSchema_$i');
        expect(snapshot['visibleCount'], greaterThanOrEqualTo(1));

        final map = pipeline.getAsMap(0);
        expect(map, isA<Map<String, dynamic>>());
        expect(map['name'], isNotNull);

        pipeline.clearFilters();
        pipeline.setSearchQuery('');
        pipeline.setSort(-1, ascending: true);
        expect(pipeline.visibleCount, greaterThanOrEqualTo(0));

        final regSnapshot = QLPipelineRegistry.instance.snapshot();
        expect(regSnapshot['count'], greaterThanOrEqualTo(1));

        QLPipelineRegistry.instance.destroy('pipe$i');
        expect(QLPipelineRegistry.instance.exists('pipe$i'), isFalse);
      });
    }
  });

  group('blueprint compiler and node normalization', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('blueprint compile roundtrip $i', () {
        final raw = <String, dynamic>{
          'type': 'box:col',
          'props': <String, dynamic>{
            'padding': i,
            'title': 'Title $i',
            if (i % 2 == 0) r'$if': true,
          },
          'children': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'Hello $i'},
            },
            <String, dynamic>{
              'type': 'button',
              'props': <String, dynamic>{'text': 'Tap $i'},
            },
          ],
          'slots': <String, dynamic>{
            'footer': <String, dynamic>{
              'type': 'text',
              'props': <String, dynamic>{'text': 'Footer $i'},
            },
          },
        };

        final blueprint = QLBlueprint.fromJson(raw, path: 'root.$i');
        expect(blueprint.type, 'box:col');
        expect(blueprint.children.length, 2);
        expect(blueprint.slots.keys, contains('footer'));
        expect(blueprint.debugPath, 'root.$i');

        final compiled = QLCompiler.compile(raw, const <String, dynamic>{});
        expect(compiled.type, 'box:col');
        expect(compiled.toJson()['debugPath'], isNotNull);

        final asString =
            QLCompiler.compile('hello-$i', const <String, dynamic>{});
        expect(asString.type, 'text');
        expect(asString.props['text'], 'hello-$i');

        final listForm = QLCompiler.compile(<dynamic>[
          'box.row',
          <String, dynamic>{
            'props': <String, dynamic>{'x': i}
          }
        ], const <String, dynamic>{});
        expect(listForm.type, 'box');
      });
    }
  });

  group('native component manifest installation and registry descriptions', () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('native component registry item $i', () {
        final componentName = 'NativeButton$i';
        final bundle = QuantumVM.instance.installDesignSystemManifest(
          _designSystemManifest(
            id: 'ds_$i',
            componentName: componentName,
            seed: i,
          ),
          manifestId: 'ds_$i',
          overwrite: true,
        );

        expect(bundle.id, 'ds_$i');
        expect(bundle.components.containsKey(componentName), isTrue);
        expect(QuantumVM.instance.getDesignSystemManifest('ds_$i'), isNotNull);

        final snapshot = QuantumVM.instance.designSystemSnapshot();
        expect(snapshot.containsKey('ds_$i'), isTrue);

        final item = QuantumVM.instance.describeRegistryItem(
          componentName,
          kind: 'native_component',
        );
        expect(item, isNotNull);
        expect(item!['kind'], 'native_component');
        expect(item['name'], componentName);

        final registryItems = QuantumVM.instance.registryEntries(
          kind: 'native_component',
          query: componentName,
        );
        expect(registryItems.isNotEmpty, isTrue);
        expect(registryItems.first.kind, 'native_component');
        expect(registryItems.first.name, componentName);

        final snapshotData = QuantumVM.instance.registrySnapshot(
          kind: 'native_component',
          query: componentName,
        );
        expect((snapshotData['counts'] as Map)['components'],
            greaterThanOrEqualTo(1));
        expect((snapshotData['items'] as List).isNotEmpty, isTrue);
      });
    }
  });

  group(
      'integration stress across slice data pipeline and native component registry',
      () {
    final cases = List<int>.generate(100, (i) => i);

    for (final i in cases) {
      test('full integration path $i', () {
        final sourceName = 'integratedSource$i';
        final sliceName = 'integrated.$i';
        final componentName = 'IntegratedComponent$i';
        final pipelineId = 'integratedPipe$i';

        QuantumVM.instance.installDesignSystemManifest(
          _designSystemManifest(
            id: 'integrated_ds_$i',
            componentName: componentName,
            seed: i,
          ),
          manifestId: 'integrated_ds_$i',
          overwrite: true,
        );

        final source = QLDataSourceRegistry.instance.register(
          sourceName,
          <String, dynamic>{
            'type': i % 2 == 0 ? 'realtime' : 'media',
            'subscribe': true,
            'realtime': true,
            'seed': <String, dynamic>{
              'items': <dynamic>[
                <String, dynamic>{'id': 'x$i', 'value': i},
              ],
              'cursor': 'cursor-$i',
            },
          },
        );

        final store = QLStoreRegistry.instance.get(sliceName);
        final cancel = QLDataSourceRegistry.instance.attachStateBinding(
          namespace: sliceName,
          store: store,
          sourceName: sourceName,
          statePath: 'items',
          sourcePath: 'items',
          merge: 'appendById',
          defaultValue: <dynamic>[],
          transform: 'identity',
          subscribe: true,
          metadata: <String, dynamic>{'integration': i},
          ctx: QLSliceExecutionContext(
            namespace: sliceName,
            sliceName: sliceName,
            schema: 'Integrated',
            dataSource: sourceName,
            metadata: <String, dynamic>{'integration': i},
            sliceDefinition: const <String, dynamic>{},
            slice: QLStoreSlice(namespace: sliceName),
          ),
        );

        final slice = QLStoreSlice(
          namespace: sliceName,
          schema: 'Integrated',
          dataSource: sourceName,
          state: <String, dynamic>{
            'items': <String, dynamic>{
              'mode': 'hybrid',
              'from': 'dataSource.items',
              'merge': 'appendById',
              'subscribe': true,
              'default': <dynamic>[],
            },
            'cursor': <String, dynamic>{
              'mode': 'remote',
              'from': 'dataSource.cursor',
              'default': null,
            },
          },
          computed: const <String, dynamic>{
            'count': <String, dynamic>{
              'deps': <String>['items'],
              'op': 'count',
            },
          },
          mutations: const <String, dynamic>{
            'pushItem': <String, dynamic>{
              'strategy': 'append',
              'path': 'items',
            },
          },
          queries: const <String, dynamic>{
            'readSnapshot': <String, dynamic>{
              'strategy': 'snapshot',
            },
          },
          pipelines: <String, dynamic>{
            'main': <String, dynamic>{
              'strategy': 'refresh',
              'pipelineId': pipelineId,
            },
          },
          metadata: <String, dynamic>{'seed': i},
        );

        final plugins = <String, QLActionPlugin>{};
        QLSliceRegistry.actionRegistrar = (String name, QLActionPlugin plugin) {
          plugins[name] = plugin;
        };

        QLSliceRegistry.instance.mount(slice);
        expect(QLSliceRegistry.instance[sliceName], isNotNull);
        expect(plugins.containsKey('$sliceName.pushItem'), isTrue);
        expect(plugins.containsKey('$sliceName.readSnapshot'), isTrue);

        final pipeline = _makePipeline(id: pipelineId, seed: i);
        QLPipelineRegistry.instance.register(pipeline);
        pipeline.replaceAll(<Map<String, dynamic>>[
          <String, dynamic>{'id': 'id-$i', 'name': 'Name $i', 'score': i},
          <String, dynamic>{
            'id': 'id-${i + 1}',
            'name': 'Name ${i + 1}',
            'score': i + 1
          },
        ]);

        final mutationResult = plugins['$sliceName.pushItem']!.execute(
          <String, dynamic>{
            'path': 'items',
            'value': <dynamic>[
              <String, dynamic>{'id': 'new-$i', 'value': i + 100},
            ],
          },
          store,
          QLNullContext(),
        );
        expect(mutationResult, completes);

        final queryResult = plugins['$sliceName.readSnapshot']!.execute(
          <String, dynamic>{},
          store,
          QLNullContext(),
        );
        expect(queryResult, completes);

        source.signal.data.value = <String, dynamic>{
          'items': <dynamic>[
            <String, dynamic>{'id': 'live-$i', 'value': i + 200},
          ],
          'cursor': 'c-$i',
        };
        source.signal.data.forceNotify();

        expect(store.get('items'), isNotNull);
        expect(store.get('cursor'), isNotNull);
        expect(
            QuantumVM.instance
                .describeRegistryItem(componentName, kind: 'native_component'),
            isNotNull);
        expect(
            QuantumVM.instance
                .registryEntries(kind: 'native_component', query: componentName)
                .isNotEmpty,
            isTrue);

        QLSliceRegistry.instance.unmount(sliceName);
        QLPipelineRegistry.instance.destroy(pipelineId);
        cancel();
      });
    }
  });
}
