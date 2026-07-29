// test/path_and_state_regression_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart' as ql;

ql.QLSliceExecutionContext _ctx([String sliceName = 'regression']) {
  return ql.QLSliceExecutionContext(
    namespace: 'test',
    sliceName: sliceName,
    schema: null,
    dataSource: null,
    metadata: const <String, dynamic>{},
    sliceDefinition: const <String, dynamic>{},
    slice: const ql.QLStoreSlice(namespace: 'test'),
  );
}

Future<void> _execMutation(
  String op,
  ql.QLDataStore store,
  Map<String, dynamic> payload, [
  String sliceName = 'regression',
]) async {
  await ql.QLSliceStrategyRegistry.instance.execute(
    op,
    store,
    payload,
    _ctx(sliceName),
    kind: 'mutation',
  );
}

void main() {
  group('QLPathUtils', () {
    test('splits dotted paths into nested strides', () {
      expect(
        ql.QLPathUtils.resolve('repeat.count.95'),
        equals(<dynamic>['repeat', 'count', 95]),
      );
    });

    test('splits bracket paths correctly', () {
      expect(
        ql.QLPathUtils.resolve('items[0].count'),
        equals(<dynamic>['items', 0, 'count']),
      );
    });

    test('canonicalize keeps numeric stride in brackets', () {
      expect(
        ql.QLPathUtils.canonicalize(<dynamic>['repeat', 'count', 95]),
        equals('repeat.count[95]'),
      );
    });

    test('parentOf and lastSegment are stable', () {
      expect(
          ql.QLPathUtils.parentOf('repeat.count.95'), equals('repeat.count'));
      expect(ql.QLPathUtils.lastSegment('repeat.count.95'), equals('95'));
    });
  });

  group('QLDataStore basic mutations', () {
    test('simple key round-trip works', () async {
      final store = ql.QLDataStore(namespace: 'test');
      store.set('count', 0);

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'count',
        'amount': 1,
      });

      expect(store.get('count'), equals(1.0));
      expect(store.snapshot['count'], equals(1.0));
    });

    test('nested path round-trip works', () async {
      final store = ql.QLDataStore(namespace: 'test');
      store.set('stats.count', 0);

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'stats.count',
        'amount': 1,
      });

      expect(store.get('stats.count'), equals(1.0));
      expect(store.snapshot['stats'], isA<Map>());
      expect((store.snapshot['stats'] as Map)['count'], equals(1.0));
    });

    test('array path round-trip works', () async {
      final store = ql.QLDataStore(namespace: 'test');
      store.set('items[0].count', 2);

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'items[0].count',
        'amount': 3,
      });

      expect(store.get('items[0].count'), equals(5.0));
    });
  });

  group('Regression: literal dotted keys', () {
    test('literal dotted key is not preserved as an exact root key', () {
      final store = ql.QLDataStore(namespace: 'test');

      store.set('repeat.count.95', 0);

      // This is the bug-revealing assertion.
      expect(store.snapshot.containsKey('repeat.count.95'), isTrue,
          reason:
              'If you want literal dotted keys to be supported, this must be true. '
              'Right now it fails because the path engine splits on dots.');

      expect(store.snapshot.containsKey('repeat'), isFalse,
          reason:
              'If literal dotted keys are supported, no nested repeat root should be created.');
    });

    test(
        'increment on a dotted key should not rewrite into a different nested tree',
        () async {
      final store = ql.QLDataStore(namespace: 'test');

      store.set('repeat.count.95', 0);

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'repeat.count.95',
        'amount': 1,
      });

      expect(store.snapshot.containsKey('repeat.count.95'), isTrue,
          reason: 'Exact key contract should survive increment.');
      expect(store.snapshot.containsKey('repeat'), isFalse,
          reason:
              'No synthetic repeat root should be created for an exact key.');
    });

    test('state.set on a dotted key should preserve exact key identity',
        () async {
      final store = ql.QLDataStore(namespace: 'test');

      await _execMutation('state.set', store, <String, dynamic>{
        'path': 'repeat.count.95',
        'value': 7,
      });

      expect(store.snapshot.containsKey('repeat.count.95'), isTrue,
          reason: 'Exact-key state.set should preserve the literal key.');
      expect(store.snapshot.containsKey('repeat'), isFalse,
          reason: 'Exact-key state.set should not create nested repeat root.');
    });
  });

  group('Runtime contract checks', () {
    test('increment uses amount/by/step consistently', () async {
      final store = ql.QLDataStore(namespace: 'test');
      store.set('score', 10);

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'score',
        'by': 2,
      });

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'score',
        'amount': 3,
      });

      await _execMutation('increment', store, <String, dynamic>{
        'path': 'score',
        'step': 5,
      });

      expect(store.get('score'), equals(20.0));
    });

    test('decrement mirrors increment behavior', () async {
      final store = ql.QLDataStore(namespace: 'test');
      store.set('score', 10);

      await _execMutation('decrement', store, <String, dynamic>{
        'path': 'score',
        'amount': 4,
      });

      expect(store.get('score'), equals(6.0));
    });

    test('state.merge merges maps without flattening', () async {
      final store = ql.QLDataStore(namespace: 'test');
      store.set('user', <String, dynamic>{
        'name': 'Alice',
        'profile': <String, dynamic>{'role': 'admin'},
      });

      await _execMutation('state.merge', store, <String, dynamic>{
        'path': 'user',
        'value': <String, dynamic>{
          'profile': <String, dynamic>{'team': 'core'},
          'active': true,
        },
      });

      final user = store.get('user') as Map;
      expect(user['name'], equals('Alice'));
      expect((user['profile'] as Map)['role'], equals('admin'));
      expect((user['profile'] as Map)['team'], equals('core'));
      expect(user['active'], equals(true));
    });
  });
}
