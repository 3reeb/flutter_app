import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QLRuntimeSupport normalizes maps, records and strings', () {
    expect(QLRuntimeSupport.mapOf({'a': 1})['a'], 1);
    expect(
        QLRuntimeSupport.mapOf({'a': 1}.map((k, v) => MapEntry(k, v)))['a'], 1);
    expect(QLRuntimeSupport.mapOf(null), isEmpty);

    expect(
      QLRuntimeSupport.recordsOf([
        {'id': 1},
        null,
        {'id': 2},
      ]),
      equals([
        {'id': 1},
        {'id': 2},
      ]),
    );

    expect(QLRuntimeSupport.safeString(null), '');
    expect(QLRuntimeSupport.safeString(42), '42');
    expect(QLRuntimeSupport.canonicalPath(['a', 'b', 1]), 'a.b[1]');
    expect(QLRuntimeSupport.lastResult({'\$lastResult': 'x'}), 'x');
    expect(QLRuntimeSupport.pathAffects('user.items[0].name', 'user.items'),
        isTrue);
    expect(QLRuntimeSupport.pathAffects('user.profile', 'cart.items'), isFalse);
  });

  test('QLRuntimeCache stores, retrieves and evicts by capacity', () {
    final cache =
        QLRuntimeCache<int>(config: const QLRuntimeCacheConfig(maxEntries: 2));
    cache.put('a', 1);
    cache.put('b', 2);
    expect(cache.get('a'), 1);
    cache.put('c', 3);
    expect(cache.stats.entries, 2);
    expect(cache.contains('c'), isTrue);
  });

  test('QLRuntimeCache getOrPut reuses loaded values', () {
    final cache = QLRuntimeCache<String>();
    var loads = 0;
    final value1 = cache.getOrPut('k', () {
      loads += 1;
      return 'value';
    });
    final value2 = cache.getOrPut('k', () {
      loads += 1;
      return 'other';
    });
    expect(value1, 'value');
    expect(value2, 'value');
    expect(loads, 1);
  });

  test('QLRuntimeCache honors TTL expiration', () async {
    final cache = QLRuntimeCache<String>(
      config: const QLRuntimeCacheConfig(defaultTtl: Duration(milliseconds: 1)),
    );
    cache.put('temp', 'ok');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(cache.get('temp'), isNull);
    expect(cache.stats.misses, greaterThan(0));
  });

  test('QLRuntimeCache removeWhere and clear empty the cache', () {
    final cache = QLRuntimeCache<int>();
    cache.put('a', 1);
    cache.put('b', 2);
    cache.removeWhere((key, entry) => key == 'a');
    expect(cache.contains('a'), isFalse);
    expect(cache.contains('b'), isTrue);
    cache.clear();
    expect(cache.stats.entries, 0);
  });

  test('QLRuntimeCacheSizer estimates nested values without crashing', () {
    final size = QLRuntimeCacheSizer.estimate({
      'a': [
        1,
        2,
        {'b': true}
      ],
      'c': 'hello',
    });
    expect(size, greaterThan(0));
  });
}
