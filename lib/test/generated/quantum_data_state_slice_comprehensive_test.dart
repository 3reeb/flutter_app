// Comprehensive manual test suite for the Quantum data-state engine and slice system.
// This file contains 1000 explicit test cases grouped by feature family.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

Future<void> _flush() async {
  await Future<void>.delayed(Duration.zero);
}

void _resetRuntime() {
  QLStoreRegistry.instance.clearAll();
  QLSliceRegistry.instance.clear();
  QLDataSourceRegistry.instance.clear();
}

void main() {
  late Map<String, QLActionPlugin> capturedActions;

  setUp(() {
    _resetRuntime();
    capturedActions = <String, QLActionPlugin>{};
    QLSliceRegistry.actionRegistrar = (name, plugin) {
      capturedActions[name] = plugin;
    };
  });

  tearDown(() {
    QLSliceRegistry.actionRegistrar = null;
    _resetRuntime();
  });

  group('runtime support', () {
    test('runtime support #0001', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 1});
      expect(map['value'], 1);
    });
    test('runtime support #0002', () {
      final fallback = <String, dynamic>{'fallback': 2};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0003', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 3},
        {'id': 4}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 3);
    });
    test('runtime support #0004', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 4}
        ]
      });
      expect(records.single['id'], 4);
    });
    test('runtime support #0005', () {
      final env = <String, dynamic>{r'$lastResult': 5};
      expect(QLRuntimeSupport.lastResult(env), 5);
    });
    test('runtime support #0006', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.6', 'user'), isTrue);
    });
    test('runtime support #0007', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.7'), isTrue);
    });
    test('runtime support #0008', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 3]),
          'root.items[3]');
    });
    test('runtime support #0009', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0010', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0011', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 11});
      expect(map['value'], 11);
    });
    test('runtime support #0012', () {
      final fallback = <String, dynamic>{'fallback': 12};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0013', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 13},
        {'id': 14}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 13);
    });
    test('runtime support #0014', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 14}
        ]
      });
      expect(records.single['id'], 14);
    });
    test('runtime support #0015', () {
      final env = <String, dynamic>{r'$lastResult': 15};
      expect(QLRuntimeSupport.lastResult(env), 15);
    });
    test('runtime support #0016', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.16', 'user'), isTrue);
    });
    test('runtime support #0017', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.17'), isTrue);
    });
    test('runtime support #0018', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 1]),
          'root.items[1]');
    });
    test('runtime support #0019', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0020', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0021', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 21});
      expect(map['value'], 21);
    });
    test('runtime support #0022', () {
      final fallback = <String, dynamic>{'fallback': 22};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0023', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 23},
        {'id': 24}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 23);
    });
    test('runtime support #0024', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 24}
        ]
      });
      expect(records.single['id'], 24);
    });
    test('runtime support #0025', () {
      final env = <String, dynamic>{r'$lastResult': 25};
      expect(QLRuntimeSupport.lastResult(env), 25);
    });
    test('runtime support #0026', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.26', 'user'), isTrue);
    });
    test('runtime support #0027', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.27'), isTrue);
    });
    test('runtime support #0028', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 3]),
          'root.items[3]');
    });
    test('runtime support #0029', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0030', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0031', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 31});
      expect(map['value'], 31);
    });
    test('runtime support #0032', () {
      final fallback = <String, dynamic>{'fallback': 32};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0033', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 33},
        {'id': 34}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 33);
    });
    test('runtime support #0034', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 34}
        ]
      });
      expect(records.single['id'], 34);
    });
    test('runtime support #0035', () {
      final env = <String, dynamic>{r'$lastResult': 35};
      expect(QLRuntimeSupport.lastResult(env), 35);
    });
    test('runtime support #0036', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.36', 'user'), isTrue);
    });
    test('runtime support #0037', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.37'), isTrue);
    });
    test('runtime support #0038', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 1]),
          'root.items[1]');
    });
    test('runtime support #0039', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0040', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0041', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 41});
      expect(map['value'], 41);
    });
    test('runtime support #0042', () {
      final fallback = <String, dynamic>{'fallback': 42};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0043', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 43},
        {'id': 44}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 43);
    });
    test('runtime support #0044', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 44}
        ]
      });
      expect(records.single['id'], 44);
    });
    test('runtime support #0045', () {
      final env = <String, dynamic>{r'$lastResult': 45};
      expect(QLRuntimeSupport.lastResult(env), 45);
    });
    test('runtime support #0046', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.46', 'user'), isTrue);
    });
    test('runtime support #0047', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.47'), isTrue);
    });
    test('runtime support #0048', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 3]),
          'root.items[3]');
    });
    test('runtime support #0049', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0050', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0051', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 51});
      expect(map['value'], 51);
    });
    test('runtime support #0052', () {
      final fallback = <String, dynamic>{'fallback': 52};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0053', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 53},
        {'id': 54}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 53);
    });
    test('runtime support #0054', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 54}
        ]
      });
      expect(records.single['id'], 54);
    });
    test('runtime support #0055', () {
      final env = <String, dynamic>{r'$lastResult': 55};
      expect(QLRuntimeSupport.lastResult(env), 55);
    });
    test('runtime support #0056', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.56', 'user'), isTrue);
    });
    test('runtime support #0057', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.57'), isTrue);
    });
    test('runtime support #0058', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 1]),
          'root.items[1]');
    });
    test('runtime support #0059', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0060', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0061', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 61});
      expect(map['value'], 61);
    });
    test('runtime support #0062', () {
      final fallback = <String, dynamic>{'fallback': 62};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0063', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 63},
        {'id': 64}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 63);
    });
    test('runtime support #0064', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 64}
        ]
      });
      expect(records.single['id'], 64);
    });
    test('runtime support #0065', () {
      final env = <String, dynamic>{r'$lastResult': 65};
      expect(QLRuntimeSupport.lastResult(env), 65);
    });
    test('runtime support #0066', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.66', 'user'), isTrue);
    });
    test('runtime support #0067', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.67'), isTrue);
    });
    test('runtime support #0068', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 3]),
          'root.items[3]');
    });
    test('runtime support #0069', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0070', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0071', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 71});
      expect(map['value'], 71);
    });
    test('runtime support #0072', () {
      final fallback = <String, dynamic>{'fallback': 72};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0073', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 73},
        {'id': 74}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 73);
    });
    test('runtime support #0074', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 74}
        ]
      });
      expect(records.single['id'], 74);
    });
    test('runtime support #0075', () {
      final env = <String, dynamic>{r'$lastResult': 75};
      expect(QLRuntimeSupport.lastResult(env), 75);
    });
    test('runtime support #0076', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.76', 'user'), isTrue);
    });
    test('runtime support #0077', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.77'), isTrue);
    });
    test('runtime support #0078', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 1]),
          'root.items[1]');
    });
    test('runtime support #0079', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0080', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0081', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 81});
      expect(map['value'], 81);
    });
    test('runtime support #0082', () {
      final fallback = <String, dynamic>{'fallback': 82};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0083', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 83},
        {'id': 84}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 83);
    });
    test('runtime support #0084', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 84}
        ]
      });
      expect(records.single['id'], 84);
    });
    test('runtime support #0085', () {
      final env = <String, dynamic>{r'$lastResult': 85};
      expect(QLRuntimeSupport.lastResult(env), 85);
    });
    test('runtime support #0086', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.86', 'user'), isTrue);
    });
    test('runtime support #0087', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.87'), isTrue);
    });
    test('runtime support #0088', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 3]),
          'root.items[3]');
    });
    test('runtime support #0089', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0090', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('runtime support #0091', () {
      final map = QLRuntimeSupport.mapOf(<String, dynamic>{'value': 91});
      expect(map['value'], 91);
    });
    test('runtime support #0092', () {
      final fallback = <String, dynamic>{'fallback': 92};
      expect(
          QLRuntimeSupport.mapOf('nope', fallback: fallback), same(fallback));
    });
    test('runtime support #0093', () {
      final records = QLRuntimeSupport.recordsOf([
        {'id': 93},
        {'id': 94}
      ]);
      expect(records.length, 2);
      expect(records.first['id'], 93);
    });
    test('runtime support #0094', () {
      final records = QLRuntimeSupport.recordsOf(<String, dynamic>{
        'data': [
          {'id': 94}
        ]
      });
      expect(records.single['id'], 94);
    });
    test('runtime support #0095', () {
      final env = <String, dynamic>{r'$lastResult': 95};
      expect(QLRuntimeSupport.lastResult(env), 95);
    });
    test('runtime support #0096', () {
      expect(QLRuntimeSupport.pathAffects('user.profile.96', 'user'), isTrue);
    });
    test('runtime support #0097', () {
      expect(QLRuntimeSupport.pathAffects('user', 'user.profile.97'), isTrue);
    });
    test('runtime support #0098', () {
      expect(QLRuntimeSupport.canonicalPath(['root', 'items', 1]),
          'root.items[1]');
    });
    test('runtime support #0099', () {
      expect(QLRuntimeSupport.safeString(null), '');
    });
    test('runtime support #0100', () {
      var notified = 0;
      final signal = QLSignal<int>(0);
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        expect(QLSignalBatch.isActive, isTrue);
        QLSignalBatch.enqueue(signal);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
  });

  group('cache engine', () {
    test('cache engine #0001', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k100', 100, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k100'), isFalse);
    });
    test('cache engine #0002', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k101', 101);
      cache.put('k101', 102);
      expect(cache.get('k101'), 102);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0003', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x102', 102);
      cache.put('y102', 103);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x102'), isFalse);
      expect(cache.contains('y102'), isTrue);
    });
    test('cache engine #0004', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k103', 103);
      cache.put('k103b', 104);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0005', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k104', 104);
      expect(cache.get('k104'), 104);
    });
    test('cache engine #0006', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k105', () {
        loads++;
        return 105;
      });
      expect(value, 105);
      expect(loads, 1);
      expect(cache.get('k105'), 105);
    });
    test('cache engine #0007', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k106', 106);
      expect(cache.contains('k106'), isTrue);
      cache.remove('k106');
      expect(cache.contains('k106'), isFalse);
    });
    test('cache engine #0008', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a107', 107);
      cache.put('b107', 108);
      cache.put('c107', 109);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0009', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k108', 108, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k108'), isFalse);
    });
    test('cache engine #0010', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k109', 109);
      cache.put('k109', 110);
      expect(cache.get('k109'), 110);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0011', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x110', 110);
      cache.put('y110', 111);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x110'), isFalse);
      expect(cache.contains('y110'), isTrue);
    });
    test('cache engine #0012', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k111', 111);
      cache.put('k111b', 112);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0013', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k112', 112);
      expect(cache.get('k112'), 112);
    });
    test('cache engine #0014', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k113', () {
        loads++;
        return 113;
      });
      expect(value, 113);
      expect(loads, 1);
      expect(cache.get('k113'), 113);
    });
    test('cache engine #0015', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k114', 114);
      expect(cache.contains('k114'), isTrue);
      cache.remove('k114');
      expect(cache.contains('k114'), isFalse);
    });
    test('cache engine #0016', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a115', 115);
      cache.put('b115', 116);
      cache.put('c115', 117);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0017', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k116', 116, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k116'), isFalse);
    });
    test('cache engine #0018', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k117', 117);
      cache.put('k117', 118);
      expect(cache.get('k117'), 118);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0019', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x118', 118);
      cache.put('y118', 119);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x118'), isFalse);
      expect(cache.contains('y118'), isTrue);
    });
    test('cache engine #0020', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k119', 119);
      cache.put('k119b', 120);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0021', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k120', 120);
      expect(cache.get('k120'), 120);
    });
    test('cache engine #0022', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k121', () {
        loads++;
        return 121;
      });
      expect(value, 121);
      expect(loads, 1);
      expect(cache.get('k121'), 121);
    });
    test('cache engine #0023', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k122', 122);
      expect(cache.contains('k122'), isTrue);
      cache.remove('k122');
      expect(cache.contains('k122'), isFalse);
    });
    test('cache engine #0024', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a123', 123);
      cache.put('b123', 124);
      cache.put('c123', 125);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0025', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k124', 124, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k124'), isFalse);
    });
    test('cache engine #0026', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k125', 125);
      cache.put('k125', 126);
      expect(cache.get('k125'), 126);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0027', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x126', 126);
      cache.put('y126', 127);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x126'), isFalse);
      expect(cache.contains('y126'), isTrue);
    });
    test('cache engine #0028', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k127', 127);
      cache.put('k127b', 128);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0029', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k128', 128);
      expect(cache.get('k128'), 128);
    });
    test('cache engine #0030', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k129', () {
        loads++;
        return 129;
      });
      expect(value, 129);
      expect(loads, 1);
      expect(cache.get('k129'), 129);
    });
    test('cache engine #0031', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k130', 130);
      expect(cache.contains('k130'), isTrue);
      cache.remove('k130');
      expect(cache.contains('k130'), isFalse);
    });
    test('cache engine #0032', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a131', 131);
      cache.put('b131', 132);
      cache.put('c131', 133);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0033', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k132', 132, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k132'), isFalse);
    });
    test('cache engine #0034', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k133', 133);
      cache.put('k133', 134);
      expect(cache.get('k133'), 134);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0035', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x134', 134);
      cache.put('y134', 135);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x134'), isFalse);
      expect(cache.contains('y134'), isTrue);
    });
    test('cache engine #0036', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k135', 135);
      cache.put('k135b', 136);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0037', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k136', 136);
      expect(cache.get('k136'), 136);
    });
    test('cache engine #0038', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k137', () {
        loads++;
        return 137;
      });
      expect(value, 137);
      expect(loads, 1);
      expect(cache.get('k137'), 137);
    });
    test('cache engine #0039', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k138', 138);
      expect(cache.contains('k138'), isTrue);
      cache.remove('k138');
      expect(cache.contains('k138'), isFalse);
    });
    test('cache engine #0040', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a139', 139);
      cache.put('b139', 140);
      cache.put('c139', 141);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0041', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k140', 140, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k140'), isFalse);
    });
    test('cache engine #0042', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k141', 141);
      cache.put('k141', 142);
      expect(cache.get('k141'), 142);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0043', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x142', 142);
      cache.put('y142', 143);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x142'), isFalse);
      expect(cache.contains('y142'), isTrue);
    });
    test('cache engine #0044', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k143', 143);
      cache.put('k143b', 144);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0045', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k144', 144);
      expect(cache.get('k144'), 144);
    });
    test('cache engine #0046', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k145', () {
        loads++;
        return 145;
      });
      expect(value, 145);
      expect(loads, 1);
      expect(cache.get('k145'), 145);
    });
    test('cache engine #0047', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k146', 146);
      expect(cache.contains('k146'), isTrue);
      cache.remove('k146');
      expect(cache.contains('k146'), isFalse);
    });
    test('cache engine #0048', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a147', 147);
      cache.put('b147', 148);
      cache.put('c147', 149);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0049', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k148', 148, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k148'), isFalse);
    });
    test('cache engine #0050', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k149', 149);
      cache.put('k149', 150);
      expect(cache.get('k149'), 150);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0051', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x150', 150);
      cache.put('y150', 151);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x150'), isFalse);
      expect(cache.contains('y150'), isTrue);
    });
    test('cache engine #0052', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k151', 151);
      cache.put('k151b', 152);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0053', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k152', 152);
      expect(cache.get('k152'), 152);
    });
    test('cache engine #0054', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k153', () {
        loads++;
        return 153;
      });
      expect(value, 153);
      expect(loads, 1);
      expect(cache.get('k153'), 153);
    });
    test('cache engine #0055', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k154', 154);
      expect(cache.contains('k154'), isTrue);
      cache.remove('k154');
      expect(cache.contains('k154'), isFalse);
    });
    test('cache engine #0056', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a155', 155);
      cache.put('b155', 156);
      cache.put('c155', 157);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0057', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k156', 156, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k156'), isFalse);
    });
    test('cache engine #0058', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k157', 157);
      cache.put('k157', 158);
      expect(cache.get('k157'), 158);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0059', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x158', 158);
      cache.put('y158', 159);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x158'), isFalse);
      expect(cache.contains('y158'), isTrue);
    });
    test('cache engine #0060', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k159', 159);
      cache.put('k159b', 160);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0061', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k160', 160);
      expect(cache.get('k160'), 160);
    });
    test('cache engine #0062', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k161', () {
        loads++;
        return 161;
      });
      expect(value, 161);
      expect(loads, 1);
      expect(cache.get('k161'), 161);
    });
    test('cache engine #0063', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k162', 162);
      expect(cache.contains('k162'), isTrue);
      cache.remove('k162');
      expect(cache.contains('k162'), isFalse);
    });
    test('cache engine #0064', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a163', 163);
      cache.put('b163', 164);
      cache.put('c163', 165);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0065', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k164', 164, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k164'), isFalse);
    });
    test('cache engine #0066', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k165', 165);
      cache.put('k165', 166);
      expect(cache.get('k165'), 166);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0067', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x166', 166);
      cache.put('y166', 167);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x166'), isFalse);
      expect(cache.contains('y166'), isTrue);
    });
    test('cache engine #0068', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k167', 167);
      cache.put('k167b', 168);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0069', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k168', 168);
      expect(cache.get('k168'), 168);
    });
    test('cache engine #0070', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k169', () {
        loads++;
        return 169;
      });
      expect(value, 169);
      expect(loads, 1);
      expect(cache.get('k169'), 169);
    });
    test('cache engine #0071', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k170', 170);
      expect(cache.contains('k170'), isTrue);
      cache.remove('k170');
      expect(cache.contains('k170'), isFalse);
    });
    test('cache engine #0072', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a171', 171);
      cache.put('b171', 172);
      cache.put('c171', 173);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0073', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k172', 172, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k172'), isFalse);
    });
    test('cache engine #0074', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k173', 173);
      cache.put('k173', 174);
      expect(cache.get('k173'), 174);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0075', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x174', 174);
      cache.put('y174', 175);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x174'), isFalse);
      expect(cache.contains('y174'), isTrue);
    });
    test('cache engine #0076', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k175', 175);
      cache.put('k175b', 176);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0077', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k176', 176);
      expect(cache.get('k176'), 176);
    });
    test('cache engine #0078', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k177', () {
        loads++;
        return 177;
      });
      expect(value, 177);
      expect(loads, 1);
      expect(cache.get('k177'), 177);
    });
    test('cache engine #0079', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k178', 178);
      expect(cache.contains('k178'), isTrue);
      cache.remove('k178');
      expect(cache.contains('k178'), isFalse);
    });
    test('cache engine #0080', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a179', 179);
      cache.put('b179', 180);
      cache.put('c179', 181);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0081', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k180', 180, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k180'), isFalse);
    });
    test('cache engine #0082', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k181', 181);
      cache.put('k181', 182);
      expect(cache.get('k181'), 182);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0083', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x182', 182);
      cache.put('y182', 183);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x182'), isFalse);
      expect(cache.contains('y182'), isTrue);
    });
    test('cache engine #0084', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k183', 183);
      cache.put('k183b', 184);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0085', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k184', 184);
      expect(cache.get('k184'), 184);
    });
    test('cache engine #0086', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k185', () {
        loads++;
        return 185;
      });
      expect(value, 185);
      expect(loads, 1);
      expect(cache.get('k185'), 185);
    });
    test('cache engine #0087', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k186', 186);
      expect(cache.contains('k186'), isTrue);
      cache.remove('k186');
      expect(cache.contains('k186'), isFalse);
    });
    test('cache engine #0088', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a187', 187);
      cache.put('b187', 188);
      cache.put('c187', 189);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0089', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k188', 188, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k188'), isFalse);
    });
    test('cache engine #0090', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k189', 189);
      cache.put('k189', 190);
      expect(cache.get('k189'), 190);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0091', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x190', 190);
      cache.put('y190', 191);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x190'), isFalse);
      expect(cache.contains('y190'), isTrue);
    });
    test('cache engine #0092', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k191', 191);
      cache.put('k191b', 192);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0093', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k192', 192);
      expect(cache.get('k192'), 192);
    });
    test('cache engine #0094', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k193', () {
        loads++;
        return 193;
      });
      expect(value, 193);
      expect(loads, 1);
      expect(cache.get('k193'), 193);
    });
    test('cache engine #0095', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k194', 194);
      expect(cache.contains('k194'), isTrue);
      cache.remove('k194');
      expect(cache.contains('k194'), isFalse);
    });
    test('cache engine #0096', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a195', 195);
      cache.put('b195', 196);
      cache.put('c195', 197);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0097', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k196', 196, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k196'), isFalse);
    });
    test('cache engine #0098', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k197', 197);
      cache.put('k197', 198);
      expect(cache.get('k197'), 198);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0099', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x198', 198);
      cache.put('y198', 199);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x198'), isFalse);
      expect(cache.contains('y198'), isTrue);
    });
    test('cache engine #0100', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k199', 199);
      cache.put('k199b', 200);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0101', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k200', 200);
      expect(cache.get('k200'), 200);
    });
    test('cache engine #0102', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k201', () {
        loads++;
        return 201;
      });
      expect(value, 201);
      expect(loads, 1);
      expect(cache.get('k201'), 201);
    });
    test('cache engine #0103', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k202', 202);
      expect(cache.contains('k202'), isTrue);
      cache.remove('k202');
      expect(cache.contains('k202'), isFalse);
    });
    test('cache engine #0104', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a203', 203);
      cache.put('b203', 204);
      cache.put('c203', 205);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0105', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k204', 204, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k204'), isFalse);
    });
    test('cache engine #0106', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k205', 205);
      cache.put('k205', 206);
      expect(cache.get('k205'), 206);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0107', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x206', 206);
      cache.put('y206', 207);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x206'), isFalse);
      expect(cache.contains('y206'), isTrue);
    });
    test('cache engine #0108', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k207', 207);
      cache.put('k207b', 208);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0109', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k208', 208);
      expect(cache.get('k208'), 208);
    });
    test('cache engine #0110', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k209', () {
        loads++;
        return 209;
      });
      expect(value, 209);
      expect(loads, 1);
      expect(cache.get('k209'), 209);
    });
    test('cache engine #0111', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k210', 210);
      expect(cache.contains('k210'), isTrue);
      cache.remove('k210');
      expect(cache.contains('k210'), isFalse);
    });
    test('cache engine #0112', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a211', 211);
      cache.put('b211', 212);
      cache.put('c211', 213);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0113', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k212', 212, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k212'), isFalse);
    });
    test('cache engine #0114', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k213', 213);
      cache.put('k213', 214);
      expect(cache.get('k213'), 214);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0115', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x214', 214);
      cache.put('y214', 215);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x214'), isFalse);
      expect(cache.contains('y214'), isTrue);
    });
    test('cache engine #0116', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k215', 215);
      cache.put('k215b', 216);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0117', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k216', 216);
      expect(cache.get('k216'), 216);
    });
    test('cache engine #0118', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k217', () {
        loads++;
        return 217;
      });
      expect(value, 217);
      expect(loads, 1);
      expect(cache.get('k217'), 217);
    });
    test('cache engine #0119', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k218', 218);
      expect(cache.contains('k218'), isTrue);
      cache.remove('k218');
      expect(cache.contains('k218'), isFalse);
    });
    test('cache engine #0120', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a219', 219);
      cache.put('b219', 220);
      cache.put('c219', 221);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0121', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k220', 220, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k220'), isFalse);
    });
    test('cache engine #0122', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k221', 221);
      cache.put('k221', 222);
      expect(cache.get('k221'), 222);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0123', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x222', 222);
      cache.put('y222', 223);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x222'), isFalse);
      expect(cache.contains('y222'), isTrue);
    });
    test('cache engine #0124', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k223', 223);
      cache.put('k223b', 224);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0125', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k224', 224);
      expect(cache.get('k224'), 224);
    });
    test('cache engine #0126', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k225', () {
        loads++;
        return 225;
      });
      expect(value, 225);
      expect(loads, 1);
      expect(cache.get('k225'), 225);
    });
    test('cache engine #0127', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k226', 226);
      expect(cache.contains('k226'), isTrue);
      cache.remove('k226');
      expect(cache.contains('k226'), isFalse);
    });
    test('cache engine #0128', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a227', 227);
      cache.put('b227', 228);
      cache.put('c227', 229);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0129', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k228', 228, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k228'), isFalse);
    });
    test('cache engine #0130', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k229', 229);
      cache.put('k229', 230);
      expect(cache.get('k229'), 230);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0131', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x230', 230);
      cache.put('y230', 231);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x230'), isFalse);
      expect(cache.contains('y230'), isTrue);
    });
    test('cache engine #0132', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k231', 231);
      cache.put('k231b', 232);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0133', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k232', 232);
      expect(cache.get('k232'), 232);
    });
    test('cache engine #0134', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k233', () {
        loads++;
        return 233;
      });
      expect(value, 233);
      expect(loads, 1);
      expect(cache.get('k233'), 233);
    });
    test('cache engine #0135', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k234', 234);
      expect(cache.contains('k234'), isTrue);
      cache.remove('k234');
      expect(cache.contains('k234'), isFalse);
    });
    test('cache engine #0136', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a235', 235);
      cache.put('b235', 236);
      cache.put('c235', 237);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0137', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k236', 236, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k236'), isFalse);
    });
    test('cache engine #0138', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k237', 237);
      cache.put('k237', 238);
      expect(cache.get('k237'), 238);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0139', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x238', 238);
      cache.put('y238', 239);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x238'), isFalse);
      expect(cache.contains('y238'), isTrue);
    });
    test('cache engine #0140', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k239', 239);
      cache.put('k239b', 240);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0141', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k240', 240);
      expect(cache.get('k240'), 240);
    });
    test('cache engine #0142', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k241', () {
        loads++;
        return 241;
      });
      expect(value, 241);
      expect(loads, 1);
      expect(cache.get('k241'), 241);
    });
    test('cache engine #0143', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k242', 242);
      expect(cache.contains('k242'), isTrue);
      cache.remove('k242');
      expect(cache.contains('k242'), isFalse);
    });
    test('cache engine #0144', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a243', 243);
      cache.put('b243', 244);
      cache.put('c243', 245);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0145', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k244', 244, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k244'), isFalse);
    });
    test('cache engine #0146', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k245', 245);
      cache.put('k245', 246);
      expect(cache.get('k245'), 246);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0147', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x246', 246);
      cache.put('y246', 247);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x246'), isFalse);
      expect(cache.contains('y246'), isTrue);
    });
    test('cache engine #0148', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k247', 247);
      cache.put('k247b', 248);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0149', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k248', 248);
      expect(cache.get('k248'), 248);
    });
    test('cache engine #0150', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k249', () {
        loads++;
        return 249;
      });
      expect(value, 249);
      expect(loads, 1);
      expect(cache.get('k249'), 249);
    });
    test('cache engine #0151', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k250', 250);
      expect(cache.contains('k250'), isTrue);
      cache.remove('k250');
      expect(cache.contains('k250'), isFalse);
    });
    test('cache engine #0152', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a251', 251);
      cache.put('b251', 252);
      cache.put('c251', 253);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0153', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k252', 252, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k252'), isFalse);
    });
    test('cache engine #0154', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k253', 253);
      cache.put('k253', 254);
      expect(cache.get('k253'), 254);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0155', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x254', 254);
      cache.put('y254', 255);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x254'), isFalse);
      expect(cache.contains('y254'), isTrue);
    });
    test('cache engine #0156', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k255', 255);
      cache.put('k255b', 256);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0157', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k256', 256);
      expect(cache.get('k256'), 256);
    });
    test('cache engine #0158', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k257', () {
        loads++;
        return 257;
      });
      expect(value, 257);
      expect(loads, 1);
      expect(cache.get('k257'), 257);
    });
    test('cache engine #0159', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k258', 258);
      expect(cache.contains('k258'), isTrue);
      cache.remove('k258');
      expect(cache.contains('k258'), isFalse);
    });
    test('cache engine #0160', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a259', 259);
      cache.put('b259', 260);
      cache.put('c259', 261);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0161', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k260', 260, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k260'), isFalse);
    });
    test('cache engine #0162', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k261', 261);
      cache.put('k261', 262);
      expect(cache.get('k261'), 262);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0163', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x262', 262);
      cache.put('y262', 263);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x262'), isFalse);
      expect(cache.contains('y262'), isTrue);
    });
    test('cache engine #0164', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k263', 263);
      cache.put('k263b', 264);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0165', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k264', 264);
      expect(cache.get('k264'), 264);
    });
    test('cache engine #0166', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k265', () {
        loads++;
        return 265;
      });
      expect(value, 265);
      expect(loads, 1);
      expect(cache.get('k265'), 265);
    });
    test('cache engine #0167', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k266', 266);
      expect(cache.contains('k266'), isTrue);
      cache.remove('k266');
      expect(cache.contains('k266'), isFalse);
    });
    test('cache engine #0168', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a267', 267);
      cache.put('b267', 268);
      cache.put('c267', 269);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0169', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k268', 268, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k268'), isFalse);
    });
    test('cache engine #0170', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k269', 269);
      cache.put('k269', 270);
      expect(cache.get('k269'), 270);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0171', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x270', 270);
      cache.put('y270', 271);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x270'), isFalse);
      expect(cache.contains('y270'), isTrue);
    });
    test('cache engine #0172', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k271', 271);
      cache.put('k271b', 272);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0173', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k272', 272);
      expect(cache.get('k272'), 272);
    });
    test('cache engine #0174', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k273', () {
        loads++;
        return 273;
      });
      expect(value, 273);
      expect(loads, 1);
      expect(cache.get('k273'), 273);
    });
    test('cache engine #0175', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k274', 274);
      expect(cache.contains('k274'), isTrue);
      cache.remove('k274');
      expect(cache.contains('k274'), isFalse);
    });
    test('cache engine #0176', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a275', 275);
      cache.put('b275', 276);
      cache.put('c275', 277);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0177', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k276', 276, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k276'), isFalse);
    });
    test('cache engine #0178', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k277', 277);
      cache.put('k277', 278);
      expect(cache.get('k277'), 278);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0179', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x278', 278);
      cache.put('y278', 279);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x278'), isFalse);
      expect(cache.contains('y278'), isTrue);
    });
    test('cache engine #0180', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k279', 279);
      cache.put('k279b', 280);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0181', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k280', 280);
      expect(cache.get('k280'), 280);
    });
    test('cache engine #0182', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k281', () {
        loads++;
        return 281;
      });
      expect(value, 281);
      expect(loads, 1);
      expect(cache.get('k281'), 281);
    });
    test('cache engine #0183', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k282', 282);
      expect(cache.contains('k282'), isTrue);
      cache.remove('k282');
      expect(cache.contains('k282'), isFalse);
    });
    test('cache engine #0184', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a283', 283);
      cache.put('b283', 284);
      cache.put('c283', 285);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0185', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k284', 284, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k284'), isFalse);
    });
    test('cache engine #0186', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k285', 285);
      cache.put('k285', 286);
      expect(cache.get('k285'), 286);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0187', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x286', 286);
      cache.put('y286', 287);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x286'), isFalse);
      expect(cache.contains('y286'), isTrue);
    });
    test('cache engine #0188', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k287', 287);
      cache.put('k287b', 288);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0189', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k288', 288);
      expect(cache.get('k288'), 288);
    });
    test('cache engine #0190', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k289', () {
        loads++;
        return 289;
      });
      expect(value, 289);
      expect(loads, 1);
      expect(cache.get('k289'), 289);
    });
    test('cache engine #0191', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k290', 290);
      expect(cache.contains('k290'), isTrue);
      cache.remove('k290');
      expect(cache.contains('k290'), isFalse);
    });
    test('cache engine #0192', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a291', 291);
      cache.put('b291', 292);
      cache.put('c291', 293);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
    test('cache engine #0193', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k292', 292, ttl: Duration.zero);
      cache.sweepExpired();
      expect(cache.contains('k292'), isFalse);
    });
    test('cache engine #0194', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k293', 293);
      cache.put('k293', 294);
      expect(cache.get('k293'), 294);
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0195', () {
      final cache = QLRuntimeCache<int>();
      cache.put('x294', 294);
      cache.put('y294', 295);
      cache.removeWhere((key, entry) => key.toString().startsWith('x'));
      expect(cache.contains('x294'), isFalse);
      expect(cache.contains('y294'), isTrue);
    });
    test('cache engine #0196', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 1, maxWeight: 16));
      cache.put('k295', 295);
      cache.put('k295b', 296);
      cache.compact();
      expect(cache.stats.entries, 1);
    });
    test('cache engine #0197', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k296', 296);
      expect(cache.get('k296'), 296);
    });
    test('cache engine #0198', () {
      final cache = QLRuntimeCache<int>();
      var loads = 0;
      final value = cache.getOrPut('k297', () {
        loads++;
        return 297;
      });
      expect(value, 297);
      expect(loads, 1);
      expect(cache.get('k297'), 297);
    });
    test('cache engine #0199', () {
      final cache = QLRuntimeCache<int>();
      cache.put('k298', 298);
      expect(cache.contains('k298'), isTrue);
      cache.remove('k298');
      expect(cache.contains('k298'), isFalse);
    });
    test('cache engine #0200', () {
      final cache = QLRuntimeCache<int>(
          config: const QLRuntimeCacheConfig(maxEntries: 2, maxWeight: 256));
      cache.put('a299', 299);
      cache.put('b299', 300);
      cache.put('c299', 301);
      expect(cache.stats.evictions, greaterThanOrEqualTo(1));
    });
  });

  group('data store core', () {
    test('data store core #0001', () {
      final store = QLStoreRegistry.instance.get('ns_300');
      store.set('count', 300);
      expect(store.get('count'), 300);
    });
    test('data store core #0002', () {
      final store = QLStoreRegistry.instance.get('ns_301');
      store.set('user.profile.name', 'u301');
      expect(store.get('user.profile.name'), 'u301');
    });
    test('data store core #0003', () {
      final store = QLStoreRegistry.instance.get('ns_302');
      store.set('items[0].id', 302);
      expect(store.get('items[0].id'), 302);
    });
    test('data store core #0004', () {
      final store = QLStoreRegistry.instance.get('ns_303');
      store.merge(<String, dynamic>{'a': 303, 'b': 304});
      expect(store.get('a'), 303);
      expect(store.get('b'), 304);
    });
    test('data store core #0005', () {
      final store = QLStoreRegistry.instance.get('ns_304');
      store.merge(<String, dynamic>{'a': 304, 'b': 305});
      store.saveSnapshot();
      store.set('a', 314);
      store.rollback();
      expect(store.get('a'), 304);
    });
    test('data store core #0006', () {
      final store = QLStoreRegistry.instance.get('ns_305');
      store.set('root.child.value', 305);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0007', () {
      final store = QLStoreRegistry.instance.get('ns_306');
      store.set('a.b.c', 306);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0008', () {
      final store = QLStoreRegistry.instance.get('ns_307');
      store.set('x', 307);
      store.clearCache();
      expect(store.get('x'), 307);
    });
    test('data store core #0009', () {
      final store = QLStoreRegistry.instance.get('ns_308');
      store.set('a', 308);
      store.set('b', 309);
      expect(store.snapshot['a'], 308);
      expect(store.snapshot['b'], 309);
    });
    test('data store core #0010', () {
      final store = QLStoreRegistry.instance.get('ns_309');
      store.transaction(() {
        store.set('n', 309);
        store.set('m', 310);
      });
      expect(store.get('n'), 309);
      expect(store.get('m'), 310);
    });
    test('data store core #0011', () {
      final store = QLStoreRegistry.instance.get('ns_310');
      store.set('count', 310);
      expect(store.get('count'), 310);
    });
    test('data store core #0012', () {
      final store = QLStoreRegistry.instance.get('ns_311');
      store.set('user.profile.name', 'u311');
      expect(store.get('user.profile.name'), 'u311');
    });
    test('data store core #0013', () {
      final store = QLStoreRegistry.instance.get('ns_312');
      store.set('items[0].id', 312);
      expect(store.get('items[0].id'), 312);
    });
    test('data store core #0014', () {
      final store = QLStoreRegistry.instance.get('ns_313');
      store.merge(<String, dynamic>{'a': 313, 'b': 314});
      expect(store.get('a'), 313);
      expect(store.get('b'), 314);
    });
    test('data store core #0015', () {
      final store = QLStoreRegistry.instance.get('ns_314');
      store.merge(<String, dynamic>{'a': 314, 'b': 315});
      store.saveSnapshot();
      store.set('a', 324);
      store.rollback();
      expect(store.get('a'), 314);
    });
    test('data store core #0016', () {
      final store = QLStoreRegistry.instance.get('ns_315');
      store.set('root.child.value', 315);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0017', () {
      final store = QLStoreRegistry.instance.get('ns_316');
      store.set('a.b.c', 316);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0018', () {
      final store = QLStoreRegistry.instance.get('ns_317');
      store.set('x', 317);
      store.clearCache();
      expect(store.get('x'), 317);
    });
    test('data store core #0019', () {
      final store = QLStoreRegistry.instance.get('ns_318');
      store.set('a', 318);
      store.set('b', 319);
      expect(store.snapshot['a'], 318);
      expect(store.snapshot['b'], 319);
    });
    test('data store core #0020', () {
      final store = QLStoreRegistry.instance.get('ns_319');
      store.transaction(() {
        store.set('n', 319);
        store.set('m', 320);
      });
      expect(store.get('n'), 319);
      expect(store.get('m'), 320);
    });
    test('data store core #0021', () {
      final store = QLStoreRegistry.instance.get('ns_320');
      store.set('count', 320);
      expect(store.get('count'), 320);
    });
    test('data store core #0022', () {
      final store = QLStoreRegistry.instance.get('ns_321');
      store.set('user.profile.name', 'u321');
      expect(store.get('user.profile.name'), 'u321');
    });
    test('data store core #0023', () {
      final store = QLStoreRegistry.instance.get('ns_322');
      store.set('items[0].id', 322);
      expect(store.get('items[0].id'), 322);
    });
    test('data store core #0024', () {
      final store = QLStoreRegistry.instance.get('ns_323');
      store.merge(<String, dynamic>{'a': 323, 'b': 324});
      expect(store.get('a'), 323);
      expect(store.get('b'), 324);
    });
    test('data store core #0025', () {
      final store = QLStoreRegistry.instance.get('ns_324');
      store.merge(<String, dynamic>{'a': 324, 'b': 325});
      store.saveSnapshot();
      store.set('a', 334);
      store.rollback();
      expect(store.get('a'), 324);
    });
    test('data store core #0026', () {
      final store = QLStoreRegistry.instance.get('ns_325');
      store.set('root.child.value', 325);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0027', () {
      final store = QLStoreRegistry.instance.get('ns_326');
      store.set('a.b.c', 326);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0028', () {
      final store = QLStoreRegistry.instance.get('ns_327');
      store.set('x', 327);
      store.clearCache();
      expect(store.get('x'), 327);
    });
    test('data store core #0029', () {
      final store = QLStoreRegistry.instance.get('ns_328');
      store.set('a', 328);
      store.set('b', 329);
      expect(store.snapshot['a'], 328);
      expect(store.snapshot['b'], 329);
    });
    test('data store core #0030', () {
      final store = QLStoreRegistry.instance.get('ns_329');
      store.transaction(() {
        store.set('n', 329);
        store.set('m', 330);
      });
      expect(store.get('n'), 329);
      expect(store.get('m'), 330);
    });
    test('data store core #0031', () {
      final store = QLStoreRegistry.instance.get('ns_330');
      store.set('count', 330);
      expect(store.get('count'), 330);
    });
    test('data store core #0032', () {
      final store = QLStoreRegistry.instance.get('ns_331');
      store.set('user.profile.name', 'u331');
      expect(store.get('user.profile.name'), 'u331');
    });
    test('data store core #0033', () {
      final store = QLStoreRegistry.instance.get('ns_332');
      store.set('items[0].id', 332);
      expect(store.get('items[0].id'), 332);
    });
    test('data store core #0034', () {
      final store = QLStoreRegistry.instance.get('ns_333');
      store.merge(<String, dynamic>{'a': 333, 'b': 334});
      expect(store.get('a'), 333);
      expect(store.get('b'), 334);
    });
    test('data store core #0035', () {
      final store = QLStoreRegistry.instance.get('ns_334');
      store.merge(<String, dynamic>{'a': 334, 'b': 335});
      store.saveSnapshot();
      store.set('a', 344);
      store.rollback();
      expect(store.get('a'), 334);
    });
    test('data store core #0036', () {
      final store = QLStoreRegistry.instance.get('ns_335');
      store.set('root.child.value', 335);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0037', () {
      final store = QLStoreRegistry.instance.get('ns_336');
      store.set('a.b.c', 336);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0038', () {
      final store = QLStoreRegistry.instance.get('ns_337');
      store.set('x', 337);
      store.clearCache();
      expect(store.get('x'), 337);
    });
    test('data store core #0039', () {
      final store = QLStoreRegistry.instance.get('ns_338');
      store.set('a', 338);
      store.set('b', 339);
      expect(store.snapshot['a'], 338);
      expect(store.snapshot['b'], 339);
    });
    test('data store core #0040', () {
      final store = QLStoreRegistry.instance.get('ns_339');
      store.transaction(() {
        store.set('n', 339);
        store.set('m', 340);
      });
      expect(store.get('n'), 339);
      expect(store.get('m'), 340);
    });
    test('data store core #0041', () {
      final store = QLStoreRegistry.instance.get('ns_340');
      store.set('count', 340);
      expect(store.get('count'), 340);
    });
    test('data store core #0042', () {
      final store = QLStoreRegistry.instance.get('ns_341');
      store.set('user.profile.name', 'u341');
      expect(store.get('user.profile.name'), 'u341');
    });
    test('data store core #0043', () {
      final store = QLStoreRegistry.instance.get('ns_342');
      store.set('items[0].id', 342);
      expect(store.get('items[0].id'), 342);
    });
    test('data store core #0044', () {
      final store = QLStoreRegistry.instance.get('ns_343');
      store.merge(<String, dynamic>{'a': 343, 'b': 344});
      expect(store.get('a'), 343);
      expect(store.get('b'), 344);
    });
    test('data store core #0045', () {
      final store = QLStoreRegistry.instance.get('ns_344');
      store.merge(<String, dynamic>{'a': 344, 'b': 345});
      store.saveSnapshot();
      store.set('a', 354);
      store.rollback();
      expect(store.get('a'), 344);
    });
    test('data store core #0046', () {
      final store = QLStoreRegistry.instance.get('ns_345');
      store.set('root.child.value', 345);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0047', () {
      final store = QLStoreRegistry.instance.get('ns_346');
      store.set('a.b.c', 346);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0048', () {
      final store = QLStoreRegistry.instance.get('ns_347');
      store.set('x', 347);
      store.clearCache();
      expect(store.get('x'), 347);
    });
    test('data store core #0049', () {
      final store = QLStoreRegistry.instance.get('ns_348');
      store.set('a', 348);
      store.set('b', 349);
      expect(store.snapshot['a'], 348);
      expect(store.snapshot['b'], 349);
    });
    test('data store core #0050', () {
      final store = QLStoreRegistry.instance.get('ns_349');
      store.transaction(() {
        store.set('n', 349);
        store.set('m', 350);
      });
      expect(store.get('n'), 349);
      expect(store.get('m'), 350);
    });
    test('data store core #0051', () {
      final store = QLStoreRegistry.instance.get('ns_350');
      store.set('count', 350);
      expect(store.get('count'), 350);
    });
    test('data store core #0052', () {
      final store = QLStoreRegistry.instance.get('ns_351');
      store.set('user.profile.name', 'u351');
      expect(store.get('user.profile.name'), 'u351');
    });
    test('data store core #0053', () {
      final store = QLStoreRegistry.instance.get('ns_352');
      store.set('items[0].id', 352);
      expect(store.get('items[0].id'), 352);
    });
    test('data store core #0054', () {
      final store = QLStoreRegistry.instance.get('ns_353');
      store.merge(<String, dynamic>{'a': 353, 'b': 354});
      expect(store.get('a'), 353);
      expect(store.get('b'), 354);
    });
    test('data store core #0055', () {
      final store = QLStoreRegistry.instance.get('ns_354');
      store.merge(<String, dynamic>{'a': 354, 'b': 355});
      store.saveSnapshot();
      store.set('a', 364);
      store.rollback();
      expect(store.get('a'), 354);
    });
    test('data store core #0056', () {
      final store = QLStoreRegistry.instance.get('ns_355');
      store.set('root.child.value', 355);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0057', () {
      final store = QLStoreRegistry.instance.get('ns_356');
      store.set('a.b.c', 356);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0058', () {
      final store = QLStoreRegistry.instance.get('ns_357');
      store.set('x', 357);
      store.clearCache();
      expect(store.get('x'), 357);
    });
    test('data store core #0059', () {
      final store = QLStoreRegistry.instance.get('ns_358');
      store.set('a', 358);
      store.set('b', 359);
      expect(store.snapshot['a'], 358);
      expect(store.snapshot['b'], 359);
    });
    test('data store core #0060', () {
      final store = QLStoreRegistry.instance.get('ns_359');
      store.transaction(() {
        store.set('n', 359);
        store.set('m', 360);
      });
      expect(store.get('n'), 359);
      expect(store.get('m'), 360);
    });
    test('data store core #0061', () {
      final store = QLStoreRegistry.instance.get('ns_360');
      store.set('count', 360);
      expect(store.get('count'), 360);
    });
    test('data store core #0062', () {
      final store = QLStoreRegistry.instance.get('ns_361');
      store.set('user.profile.name', 'u361');
      expect(store.get('user.profile.name'), 'u361');
    });
    test('data store core #0063', () {
      final store = QLStoreRegistry.instance.get('ns_362');
      store.set('items[0].id', 362);
      expect(store.get('items[0].id'), 362);
    });
    test('data store core #0064', () {
      final store = QLStoreRegistry.instance.get('ns_363');
      store.merge(<String, dynamic>{'a': 363, 'b': 364});
      expect(store.get('a'), 363);
      expect(store.get('b'), 364);
    });
    test('data store core #0065', () {
      final store = QLStoreRegistry.instance.get('ns_364');
      store.merge(<String, dynamic>{'a': 364, 'b': 365});
      store.saveSnapshot();
      store.set('a', 374);
      store.rollback();
      expect(store.get('a'), 364);
    });
    test('data store core #0066', () {
      final store = QLStoreRegistry.instance.get('ns_365');
      store.set('root.child.value', 365);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0067', () {
      final store = QLStoreRegistry.instance.get('ns_366');
      store.set('a.b.c', 366);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0068', () {
      final store = QLStoreRegistry.instance.get('ns_367');
      store.set('x', 367);
      store.clearCache();
      expect(store.get('x'), 367);
    });
    test('data store core #0069', () {
      final store = QLStoreRegistry.instance.get('ns_368');
      store.set('a', 368);
      store.set('b', 369);
      expect(store.snapshot['a'], 368);
      expect(store.snapshot['b'], 369);
    });
    test('data store core #0070', () {
      final store = QLStoreRegistry.instance.get('ns_369');
      store.transaction(() {
        store.set('n', 369);
        store.set('m', 370);
      });
      expect(store.get('n'), 369);
      expect(store.get('m'), 370);
    });
    test('data store core #0071', () {
      final store = QLStoreRegistry.instance.get('ns_370');
      store.set('count', 370);
      expect(store.get('count'), 370);
    });
    test('data store core #0072', () {
      final store = QLStoreRegistry.instance.get('ns_371');
      store.set('user.profile.name', 'u371');
      expect(store.get('user.profile.name'), 'u371');
    });
    test('data store core #0073', () {
      final store = QLStoreRegistry.instance.get('ns_372');
      store.set('items[0].id', 372);
      expect(store.get('items[0].id'), 372);
    });
    test('data store core #0074', () {
      final store = QLStoreRegistry.instance.get('ns_373');
      store.merge(<String, dynamic>{'a': 373, 'b': 374});
      expect(store.get('a'), 373);
      expect(store.get('b'), 374);
    });
    test('data store core #0075', () {
      final store = QLStoreRegistry.instance.get('ns_374');
      store.merge(<String, dynamic>{'a': 374, 'b': 375});
      store.saveSnapshot();
      store.set('a', 384);
      store.rollback();
      expect(store.get('a'), 374);
    });
    test('data store core #0076', () {
      final store = QLStoreRegistry.instance.get('ns_375');
      store.set('root.child.value', 375);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0077', () {
      final store = QLStoreRegistry.instance.get('ns_376');
      store.set('a.b.c', 376);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0078', () {
      final store = QLStoreRegistry.instance.get('ns_377');
      store.set('x', 377);
      store.clearCache();
      expect(store.get('x'), 377);
    });
    test('data store core #0079', () {
      final store = QLStoreRegistry.instance.get('ns_378');
      store.set('a', 378);
      store.set('b', 379);
      expect(store.snapshot['a'], 378);
      expect(store.snapshot['b'], 379);
    });
    test('data store core #0080', () {
      final store = QLStoreRegistry.instance.get('ns_379');
      store.transaction(() {
        store.set('n', 379);
        store.set('m', 380);
      });
      expect(store.get('n'), 379);
      expect(store.get('m'), 380);
    });
    test('data store core #0081', () {
      final store = QLStoreRegistry.instance.get('ns_380');
      store.set('count', 380);
      expect(store.get('count'), 380);
    });
    test('data store core #0082', () {
      final store = QLStoreRegistry.instance.get('ns_381');
      store.set('user.profile.name', 'u381');
      expect(store.get('user.profile.name'), 'u381');
    });
    test('data store core #0083', () {
      final store = QLStoreRegistry.instance.get('ns_382');
      store.set('items[0].id', 382);
      expect(store.get('items[0].id'), 382);
    });
    test('data store core #0084', () {
      final store = QLStoreRegistry.instance.get('ns_383');
      store.merge(<String, dynamic>{'a': 383, 'b': 384});
      expect(store.get('a'), 383);
      expect(store.get('b'), 384);
    });
    test('data store core #0085', () {
      final store = QLStoreRegistry.instance.get('ns_384');
      store.merge(<String, dynamic>{'a': 384, 'b': 385});
      store.saveSnapshot();
      store.set('a', 394);
      store.rollback();
      expect(store.get('a'), 384);
    });
    test('data store core #0086', () {
      final store = QLStoreRegistry.instance.get('ns_385');
      store.set('root.child.value', 385);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0087', () {
      final store = QLStoreRegistry.instance.get('ns_386');
      store.set('a.b.c', 386);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0088', () {
      final store = QLStoreRegistry.instance.get('ns_387');
      store.set('x', 387);
      store.clearCache();
      expect(store.get('x'), 387);
    });
    test('data store core #0089', () {
      final store = QLStoreRegistry.instance.get('ns_388');
      store.set('a', 388);
      store.set('b', 389);
      expect(store.snapshot['a'], 388);
      expect(store.snapshot['b'], 389);
    });
    test('data store core #0090', () {
      final store = QLStoreRegistry.instance.get('ns_389');
      store.transaction(() {
        store.set('n', 389);
        store.set('m', 390);
      });
      expect(store.get('n'), 389);
      expect(store.get('m'), 390);
    });
    test('data store core #0091', () {
      final store = QLStoreRegistry.instance.get('ns_390');
      store.set('count', 390);
      expect(store.get('count'), 390);
    });
    test('data store core #0092', () {
      final store = QLStoreRegistry.instance.get('ns_391');
      store.set('user.profile.name', 'u391');
      expect(store.get('user.profile.name'), 'u391');
    });
    test('data store core #0093', () {
      final store = QLStoreRegistry.instance.get('ns_392');
      store.set('items[0].id', 392);
      expect(store.get('items[0].id'), 392);
    });
    test('data store core #0094', () {
      final store = QLStoreRegistry.instance.get('ns_393');
      store.merge(<String, dynamic>{'a': 393, 'b': 394});
      expect(store.get('a'), 393);
      expect(store.get('b'), 394);
    });
    test('data store core #0095', () {
      final store = QLStoreRegistry.instance.get('ns_394');
      store.merge(<String, dynamic>{'a': 394, 'b': 395});
      store.saveSnapshot();
      store.set('a', 404);
      store.rollback();
      expect(store.get('a'), 394);
    });
    test('data store core #0096', () {
      final store = QLStoreRegistry.instance.get('ns_395');
      store.set('root.child.value', 395);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0097', () {
      final store = QLStoreRegistry.instance.get('ns_396');
      store.set('a.b.c', 396);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0098', () {
      final store = QLStoreRegistry.instance.get('ns_397');
      store.set('x', 397);
      store.clearCache();
      expect(store.get('x'), 397);
    });
    test('data store core #0099', () {
      final store = QLStoreRegistry.instance.get('ns_398');
      store.set('a', 398);
      store.set('b', 399);
      expect(store.snapshot['a'], 398);
      expect(store.snapshot['b'], 399);
    });
    test('data store core #0100', () {
      final store = QLStoreRegistry.instance.get('ns_399');
      store.transaction(() {
        store.set('n', 399);
        store.set('m', 400);
      });
      expect(store.get('n'), 399);
      expect(store.get('m'), 400);
    });
    test('data store core #0101', () {
      final store = QLStoreRegistry.instance.get('ns_400');
      store.set('count', 400);
      expect(store.get('count'), 400);
    });
    test('data store core #0102', () {
      final store = QLStoreRegistry.instance.get('ns_401');
      store.set('user.profile.name', 'u401');
      expect(store.get('user.profile.name'), 'u401');
    });
    test('data store core #0103', () {
      final store = QLStoreRegistry.instance.get('ns_402');
      store.set('items[0].id', 402);
      expect(store.get('items[0].id'), 402);
    });
    test('data store core #0104', () {
      final store = QLStoreRegistry.instance.get('ns_403');
      store.merge(<String, dynamic>{'a': 403, 'b': 404});
      expect(store.get('a'), 403);
      expect(store.get('b'), 404);
    });
    test('data store core #0105', () {
      final store = QLStoreRegistry.instance.get('ns_404');
      store.merge(<String, dynamic>{'a': 404, 'b': 405});
      store.saveSnapshot();
      store.set('a', 414);
      store.rollback();
      expect(store.get('a'), 404);
    });
    test('data store core #0106', () {
      final store = QLStoreRegistry.instance.get('ns_405');
      store.set('root.child.value', 405);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0107', () {
      final store = QLStoreRegistry.instance.get('ns_406');
      store.set('a.b.c', 406);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0108', () {
      final store = QLStoreRegistry.instance.get('ns_407');
      store.set('x', 407);
      store.clearCache();
      expect(store.get('x'), 407);
    });
    test('data store core #0109', () {
      final store = QLStoreRegistry.instance.get('ns_408');
      store.set('a', 408);
      store.set('b', 409);
      expect(store.snapshot['a'], 408);
      expect(store.snapshot['b'], 409);
    });
    test('data store core #0110', () {
      final store = QLStoreRegistry.instance.get('ns_409');
      store.transaction(() {
        store.set('n', 409);
        store.set('m', 410);
      });
      expect(store.get('n'), 409);
      expect(store.get('m'), 410);
    });
    test('data store core #0111', () {
      final store = QLStoreRegistry.instance.get('ns_410');
      store.set('count', 410);
      expect(store.get('count'), 410);
    });
    test('data store core #0112', () {
      final store = QLStoreRegistry.instance.get('ns_411');
      store.set('user.profile.name', 'u411');
      expect(store.get('user.profile.name'), 'u411');
    });
    test('data store core #0113', () {
      final store = QLStoreRegistry.instance.get('ns_412');
      store.set('items[0].id', 412);
      expect(store.get('items[0].id'), 412);
    });
    test('data store core #0114', () {
      final store = QLStoreRegistry.instance.get('ns_413');
      store.merge(<String, dynamic>{'a': 413, 'b': 414});
      expect(store.get('a'), 413);
      expect(store.get('b'), 414);
    });
    test('data store core #0115', () {
      final store = QLStoreRegistry.instance.get('ns_414');
      store.merge(<String, dynamic>{'a': 414, 'b': 415});
      store.saveSnapshot();
      store.set('a', 424);
      store.rollback();
      expect(store.get('a'), 414);
    });
    test('data store core #0116', () {
      final store = QLStoreRegistry.instance.get('ns_415');
      store.set('root.child.value', 415);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0117', () {
      final store = QLStoreRegistry.instance.get('ns_416');
      store.set('a.b.c', 416);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0118', () {
      final store = QLStoreRegistry.instance.get('ns_417');
      store.set('x', 417);
      store.clearCache();
      expect(store.get('x'), 417);
    });
    test('data store core #0119', () {
      final store = QLStoreRegistry.instance.get('ns_418');
      store.set('a', 418);
      store.set('b', 419);
      expect(store.snapshot['a'], 418);
      expect(store.snapshot['b'], 419);
    });
    test('data store core #0120', () {
      final store = QLStoreRegistry.instance.get('ns_419');
      store.transaction(() {
        store.set('n', 419);
        store.set('m', 420);
      });
      expect(store.get('n'), 419);
      expect(store.get('m'), 420);
    });
    test('data store core #0121', () {
      final store = QLStoreRegistry.instance.get('ns_420');
      store.set('count', 420);
      expect(store.get('count'), 420);
    });
    test('data store core #0122', () {
      final store = QLStoreRegistry.instance.get('ns_421');
      store.set('user.profile.name', 'u421');
      expect(store.get('user.profile.name'), 'u421');
    });
    test('data store core #0123', () {
      final store = QLStoreRegistry.instance.get('ns_422');
      store.set('items[0].id', 422);
      expect(store.get('items[0].id'), 422);
    });
    test('data store core #0124', () {
      final store = QLStoreRegistry.instance.get('ns_423');
      store.merge(<String, dynamic>{'a': 423, 'b': 424});
      expect(store.get('a'), 423);
      expect(store.get('b'), 424);
    });
    test('data store core #0125', () {
      final store = QLStoreRegistry.instance.get('ns_424');
      store.merge(<String, dynamic>{'a': 424, 'b': 425});
      store.saveSnapshot();
      store.set('a', 434);
      store.rollback();
      expect(store.get('a'), 424);
    });
    test('data store core #0126', () {
      final store = QLStoreRegistry.instance.get('ns_425');
      store.set('root.child.value', 425);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0127', () {
      final store = QLStoreRegistry.instance.get('ns_426');
      store.set('a.b.c', 426);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0128', () {
      final store = QLStoreRegistry.instance.get('ns_427');
      store.set('x', 427);
      store.clearCache();
      expect(store.get('x'), 427);
    });
    test('data store core #0129', () {
      final store = QLStoreRegistry.instance.get('ns_428');
      store.set('a', 428);
      store.set('b', 429);
      expect(store.snapshot['a'], 428);
      expect(store.snapshot['b'], 429);
    });
    test('data store core #0130', () {
      final store = QLStoreRegistry.instance.get('ns_429');
      store.transaction(() {
        store.set('n', 429);
        store.set('m', 430);
      });
      expect(store.get('n'), 429);
      expect(store.get('m'), 430);
    });
    test('data store core #0131', () {
      final store = QLStoreRegistry.instance.get('ns_430');
      store.set('count', 430);
      expect(store.get('count'), 430);
    });
    test('data store core #0132', () {
      final store = QLStoreRegistry.instance.get('ns_431');
      store.set('user.profile.name', 'u431');
      expect(store.get('user.profile.name'), 'u431');
    });
    test('data store core #0133', () {
      final store = QLStoreRegistry.instance.get('ns_432');
      store.set('items[0].id', 432);
      expect(store.get('items[0].id'), 432);
    });
    test('data store core #0134', () {
      final store = QLStoreRegistry.instance.get('ns_433');
      store.merge(<String, dynamic>{'a': 433, 'b': 434});
      expect(store.get('a'), 433);
      expect(store.get('b'), 434);
    });
    test('data store core #0135', () {
      final store = QLStoreRegistry.instance.get('ns_434');
      store.merge(<String, dynamic>{'a': 434, 'b': 435});
      store.saveSnapshot();
      store.set('a', 444);
      store.rollback();
      expect(store.get('a'), 434);
    });
    test('data store core #0136', () {
      final store = QLStoreRegistry.instance.get('ns_435');
      store.set('root.child.value', 435);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0137', () {
      final store = QLStoreRegistry.instance.get('ns_436');
      store.set('a.b.c', 436);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0138', () {
      final store = QLStoreRegistry.instance.get('ns_437');
      store.set('x', 437);
      store.clearCache();
      expect(store.get('x'), 437);
    });
    test('data store core #0139', () {
      final store = QLStoreRegistry.instance.get('ns_438');
      store.set('a', 438);
      store.set('b', 439);
      expect(store.snapshot['a'], 438);
      expect(store.snapshot['b'], 439);
    });
    test('data store core #0140', () {
      final store = QLStoreRegistry.instance.get('ns_439');
      store.transaction(() {
        store.set('n', 439);
        store.set('m', 440);
      });
      expect(store.get('n'), 439);
      expect(store.get('m'), 440);
    });
    test('data store core #0141', () {
      final store = QLStoreRegistry.instance.get('ns_440');
      store.set('count', 440);
      expect(store.get('count'), 440);
    });
    test('data store core #0142', () {
      final store = QLStoreRegistry.instance.get('ns_441');
      store.set('user.profile.name', 'u441');
      expect(store.get('user.profile.name'), 'u441');
    });
    test('data store core #0143', () {
      final store = QLStoreRegistry.instance.get('ns_442');
      store.set('items[0].id', 442);
      expect(store.get('items[0].id'), 442);
    });
    test('data store core #0144', () {
      final store = QLStoreRegistry.instance.get('ns_443');
      store.merge(<String, dynamic>{'a': 443, 'b': 444});
      expect(store.get('a'), 443);
      expect(store.get('b'), 444);
    });
    test('data store core #0145', () {
      final store = QLStoreRegistry.instance.get('ns_444');
      store.merge(<String, dynamic>{'a': 444, 'b': 445});
      store.saveSnapshot();
      store.set('a', 454);
      store.rollback();
      expect(store.get('a'), 444);
    });
    test('data store core #0146', () {
      final store = QLStoreRegistry.instance.get('ns_445');
      store.set('root.child.value', 445);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0147', () {
      final store = QLStoreRegistry.instance.get('ns_446');
      store.set('a.b.c', 446);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0148', () {
      final store = QLStoreRegistry.instance.get('ns_447');
      store.set('x', 447);
      store.clearCache();
      expect(store.get('x'), 447);
    });
    test('data store core #0149', () {
      final store = QLStoreRegistry.instance.get('ns_448');
      store.set('a', 448);
      store.set('b', 449);
      expect(store.snapshot['a'], 448);
      expect(store.snapshot['b'], 449);
    });
    test('data store core #0150', () {
      final store = QLStoreRegistry.instance.get('ns_449');
      store.transaction(() {
        store.set('n', 449);
        store.set('m', 450);
      });
      expect(store.get('n'), 449);
      expect(store.get('m'), 450);
    });
    test('data store core #0151', () {
      final store = QLStoreRegistry.instance.get('ns_450');
      store.set('count', 450);
      expect(store.get('count'), 450);
    });
    test('data store core #0152', () {
      final store = QLStoreRegistry.instance.get('ns_451');
      store.set('user.profile.name', 'u451');
      expect(store.get('user.profile.name'), 'u451');
    });
    test('data store core #0153', () {
      final store = QLStoreRegistry.instance.get('ns_452');
      store.set('items[0].id', 452);
      expect(store.get('items[0].id'), 452);
    });
    test('data store core #0154', () {
      final store = QLStoreRegistry.instance.get('ns_453');
      store.merge(<String, dynamic>{'a': 453, 'b': 454});
      expect(store.get('a'), 453);
      expect(store.get('b'), 454);
    });
    test('data store core #0155', () {
      final store = QLStoreRegistry.instance.get('ns_454');
      store.merge(<String, dynamic>{'a': 454, 'b': 455});
      store.saveSnapshot();
      store.set('a', 464);
      store.rollback();
      expect(store.get('a'), 454);
    });
    test('data store core #0156', () {
      final store = QLStoreRegistry.instance.get('ns_455');
      store.set('root.child.value', 455);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0157', () {
      final store = QLStoreRegistry.instance.get('ns_456');
      store.set('a.b.c', 456);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0158', () {
      final store = QLStoreRegistry.instance.get('ns_457');
      store.set('x', 457);
      store.clearCache();
      expect(store.get('x'), 457);
    });
    test('data store core #0159', () {
      final store = QLStoreRegistry.instance.get('ns_458');
      store.set('a', 458);
      store.set('b', 459);
      expect(store.snapshot['a'], 458);
      expect(store.snapshot['b'], 459);
    });
    test('data store core #0160', () {
      final store = QLStoreRegistry.instance.get('ns_459');
      store.transaction(() {
        store.set('n', 459);
        store.set('m', 460);
      });
      expect(store.get('n'), 459);
      expect(store.get('m'), 460);
    });
    test('data store core #0161', () {
      final store = QLStoreRegistry.instance.get('ns_460');
      store.set('count', 460);
      expect(store.get('count'), 460);
    });
    test('data store core #0162', () {
      final store = QLStoreRegistry.instance.get('ns_461');
      store.set('user.profile.name', 'u461');
      expect(store.get('user.profile.name'), 'u461');
    });
    test('data store core #0163', () {
      final store = QLStoreRegistry.instance.get('ns_462');
      store.set('items[0].id', 462);
      expect(store.get('items[0].id'), 462);
    });
    test('data store core #0164', () {
      final store = QLStoreRegistry.instance.get('ns_463');
      store.merge(<String, dynamic>{'a': 463, 'b': 464});
      expect(store.get('a'), 463);
      expect(store.get('b'), 464);
    });
    test('data store core #0165', () {
      final store = QLStoreRegistry.instance.get('ns_464');
      store.merge(<String, dynamic>{'a': 464, 'b': 465});
      store.saveSnapshot();
      store.set('a', 474);
      store.rollback();
      expect(store.get('a'), 464);
    });
    test('data store core #0166', () {
      final store = QLStoreRegistry.instance.get('ns_465');
      store.set('root.child.value', 465);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0167', () {
      final store = QLStoreRegistry.instance.get('ns_466');
      store.set('a.b.c', 466);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0168', () {
      final store = QLStoreRegistry.instance.get('ns_467');
      store.set('x', 467);
      store.clearCache();
      expect(store.get('x'), 467);
    });
    test('data store core #0169', () {
      final store = QLStoreRegistry.instance.get('ns_468');
      store.set('a', 468);
      store.set('b', 469);
      expect(store.snapshot['a'], 468);
      expect(store.snapshot['b'], 469);
    });
    test('data store core #0170', () {
      final store = QLStoreRegistry.instance.get('ns_469');
      store.transaction(() {
        store.set('n', 469);
        store.set('m', 470);
      });
      expect(store.get('n'), 469);
      expect(store.get('m'), 470);
    });
    test('data store core #0171', () {
      final store = QLStoreRegistry.instance.get('ns_470');
      store.set('count', 470);
      expect(store.get('count'), 470);
    });
    test('data store core #0172', () {
      final store = QLStoreRegistry.instance.get('ns_471');
      store.set('user.profile.name', 'u471');
      expect(store.get('user.profile.name'), 'u471');
    });
    test('data store core #0173', () {
      final store = QLStoreRegistry.instance.get('ns_472');
      store.set('items[0].id', 472);
      expect(store.get('items[0].id'), 472);
    });
    test('data store core #0174', () {
      final store = QLStoreRegistry.instance.get('ns_473');
      store.merge(<String, dynamic>{'a': 473, 'b': 474});
      expect(store.get('a'), 473);
      expect(store.get('b'), 474);
    });
    test('data store core #0175', () {
      final store = QLStoreRegistry.instance.get('ns_474');
      store.merge(<String, dynamic>{'a': 474, 'b': 475});
      store.saveSnapshot();
      store.set('a', 484);
      store.rollback();
      expect(store.get('a'), 474);
    });
    test('data store core #0176', () {
      final store = QLStoreRegistry.instance.get('ns_475');
      store.set('root.child.value', 475);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0177', () {
      final store = QLStoreRegistry.instance.get('ns_476');
      store.set('a.b.c', 476);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0178', () {
      final store = QLStoreRegistry.instance.get('ns_477');
      store.set('x', 477);
      store.clearCache();
      expect(store.get('x'), 477);
    });
    test('data store core #0179', () {
      final store = QLStoreRegistry.instance.get('ns_478');
      store.set('a', 478);
      store.set('b', 479);
      expect(store.snapshot['a'], 478);
      expect(store.snapshot['b'], 479);
    });
    test('data store core #0180', () {
      final store = QLStoreRegistry.instance.get('ns_479');
      store.transaction(() {
        store.set('n', 479);
        store.set('m', 480);
      });
      expect(store.get('n'), 479);
      expect(store.get('m'), 480);
    });
    test('data store core #0181', () {
      final store = QLStoreRegistry.instance.get('ns_480');
      store.set('count', 480);
      expect(store.get('count'), 480);
    });
    test('data store core #0182', () {
      final store = QLStoreRegistry.instance.get('ns_481');
      store.set('user.profile.name', 'u481');
      expect(store.get('user.profile.name'), 'u481');
    });
    test('data store core #0183', () {
      final store = QLStoreRegistry.instance.get('ns_482');
      store.set('items[0].id', 482);
      expect(store.get('items[0].id'), 482);
    });
    test('data store core #0184', () {
      final store = QLStoreRegistry.instance.get('ns_483');
      store.merge(<String, dynamic>{'a': 483, 'b': 484});
      expect(store.get('a'), 483);
      expect(store.get('b'), 484);
    });
    test('data store core #0185', () {
      final store = QLStoreRegistry.instance.get('ns_484');
      store.merge(<String, dynamic>{'a': 484, 'b': 485});
      store.saveSnapshot();
      store.set('a', 494);
      store.rollback();
      expect(store.get('a'), 484);
    });
    test('data store core #0186', () {
      final store = QLStoreRegistry.instance.get('ns_485');
      store.set('root.child.value', 485);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0187', () {
      final store = QLStoreRegistry.instance.get('ns_486');
      store.set('a.b.c', 486);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0188', () {
      final store = QLStoreRegistry.instance.get('ns_487');
      store.set('x', 487);
      store.clearCache();
      expect(store.get('x'), 487);
    });
    test('data store core #0189', () {
      final store = QLStoreRegistry.instance.get('ns_488');
      store.set('a', 488);
      store.set('b', 489);
      expect(store.snapshot['a'], 488);
      expect(store.snapshot['b'], 489);
    });
    test('data store core #0190', () {
      final store = QLStoreRegistry.instance.get('ns_489');
      store.transaction(() {
        store.set('n', 489);
        store.set('m', 490);
      });
      expect(store.get('n'), 489);
      expect(store.get('m'), 490);
    });
    test('data store core #0191', () {
      final store = QLStoreRegistry.instance.get('ns_490');
      store.set('count', 490);
      expect(store.get('count'), 490);
    });
    test('data store core #0192', () {
      final store = QLStoreRegistry.instance.get('ns_491');
      store.set('user.profile.name', 'u491');
      expect(store.get('user.profile.name'), 'u491');
    });
    test('data store core #0193', () {
      final store = QLStoreRegistry.instance.get('ns_492');
      store.set('items[0].id', 492);
      expect(store.get('items[0].id'), 492);
    });
    test('data store core #0194', () {
      final store = QLStoreRegistry.instance.get('ns_493');
      store.merge(<String, dynamic>{'a': 493, 'b': 494});
      expect(store.get('a'), 493);
      expect(store.get('b'), 494);
    });
    test('data store core #0195', () {
      final store = QLStoreRegistry.instance.get('ns_494');
      store.merge(<String, dynamic>{'a': 494, 'b': 495});
      store.saveSnapshot();
      store.set('a', 504);
      store.rollback();
      expect(store.get('a'), 494);
    });
    test('data store core #0196', () {
      final store = QLStoreRegistry.instance.get('ns_495');
      store.set('root.child.value', 495);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0197', () {
      final store = QLStoreRegistry.instance.get('ns_496');
      store.set('a.b.c', 496);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0198', () {
      final store = QLStoreRegistry.instance.get('ns_497');
      store.set('x', 497);
      store.clearCache();
      expect(store.get('x'), 497);
    });
    test('data store core #0199', () {
      final store = QLStoreRegistry.instance.get('ns_498');
      store.set('a', 498);
      store.set('b', 499);
      expect(store.snapshot['a'], 498);
      expect(store.snapshot['b'], 499);
    });
    test('data store core #0200', () {
      final store = QLStoreRegistry.instance.get('ns_499');
      store.transaction(() {
        store.set('n', 499);
        store.set('m', 500);
      });
      expect(store.get('n'), 499);
      expect(store.get('m'), 500);
    });
    test('data store core #0201', () {
      final store = QLStoreRegistry.instance.get('ns_500');
      store.set('count', 500);
      expect(store.get('count'), 500);
    });
    test('data store core #0202', () {
      final store = QLStoreRegistry.instance.get('ns_501');
      store.set('user.profile.name', 'u501');
      expect(store.get('user.profile.name'), 'u501');
    });
    test('data store core #0203', () {
      final store = QLStoreRegistry.instance.get('ns_502');
      store.set('items[0].id', 502);
      expect(store.get('items[0].id'), 502);
    });
    test('data store core #0204', () {
      final store = QLStoreRegistry.instance.get('ns_503');
      store.merge(<String, dynamic>{'a': 503, 'b': 504});
      expect(store.get('a'), 503);
      expect(store.get('b'), 504);
    });
    test('data store core #0205', () {
      final store = QLStoreRegistry.instance.get('ns_504');
      store.merge(<String, dynamic>{'a': 504, 'b': 505});
      store.saveSnapshot();
      store.set('a', 514);
      store.rollback();
      expect(store.get('a'), 504);
    });
    test('data store core #0206', () {
      final store = QLStoreRegistry.instance.get('ns_505');
      store.set('root.child.value', 505);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0207', () {
      final store = QLStoreRegistry.instance.get('ns_506');
      store.set('a.b.c', 506);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0208', () {
      final store = QLStoreRegistry.instance.get('ns_507');
      store.set('x', 507);
      store.clearCache();
      expect(store.get('x'), 507);
    });
    test('data store core #0209', () {
      final store = QLStoreRegistry.instance.get('ns_508');
      store.set('a', 508);
      store.set('b', 509);
      expect(store.snapshot['a'], 508);
      expect(store.snapshot['b'], 509);
    });
    test('data store core #0210', () {
      final store = QLStoreRegistry.instance.get('ns_509');
      store.transaction(() {
        store.set('n', 509);
        store.set('m', 510);
      });
      expect(store.get('n'), 509);
      expect(store.get('m'), 510);
    });
    test('data store core #0211', () {
      final store = QLStoreRegistry.instance.get('ns_510');
      store.set('count', 510);
      expect(store.get('count'), 510);
    });
    test('data store core #0212', () {
      final store = QLStoreRegistry.instance.get('ns_511');
      store.set('user.profile.name', 'u511');
      expect(store.get('user.profile.name'), 'u511');
    });
    test('data store core #0213', () {
      final store = QLStoreRegistry.instance.get('ns_512');
      store.set('items[0].id', 512);
      expect(store.get('items[0].id'), 512);
    });
    test('data store core #0214', () {
      final store = QLStoreRegistry.instance.get('ns_513');
      store.merge(<String, dynamic>{'a': 513, 'b': 514});
      expect(store.get('a'), 513);
      expect(store.get('b'), 514);
    });
    test('data store core #0215', () {
      final store = QLStoreRegistry.instance.get('ns_514');
      store.merge(<String, dynamic>{'a': 514, 'b': 515});
      store.saveSnapshot();
      store.set('a', 524);
      store.rollback();
      expect(store.get('a'), 514);
    });
    test('data store core #0216', () {
      final store = QLStoreRegistry.instance.get('ns_515');
      store.set('root.child.value', 515);
      expect(store.has('root.child.value'), isTrue);
      expect(store.has('root.child.missing'), isFalse);
    });
    test('data store core #0217', () {
      final store = QLStoreRegistry.instance.get('ns_516');
      store.set('a.b.c', 516);
      store.sweep('a.b');
      expect(store.has('a.b.c'), isFalse);
    });
    test('data store core #0218', () {
      final store = QLStoreRegistry.instance.get('ns_517');
      store.set('x', 517);
      store.clearCache();
      expect(store.get('x'), 517);
    });
    test('data store core #0219', () {
      final store = QLStoreRegistry.instance.get('ns_518');
      store.set('a', 518);
      store.set('b', 519);
      expect(store.snapshot['a'], 518);
      expect(store.snapshot['b'], 519);
    });
    test('data store core #0220', () {
      final store = QLStoreRegistry.instance.get('ns_519');
      store.transaction(() {
        store.set('n', 519);
        store.set('m', 520);
      });
      expect(store.get('n'), 519);
      expect(store.get('m'), 520);
    });
  });

  group('computed and async binding', () {
    test('computed and async binding #0001', () async {
      final store = QLStoreRegistry.instance.get('cmp_520');
      store.set('x', 520);
      store.set('y', 522);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 523);
      await _flush();
      expect(store.get('sum'), 1045);
    });
    test('computed and async binding #0002', () async {
      final store = QLStoreRegistry.instance.get('cmp_521');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0003', () async {
      final store = QLStoreRegistry.instance.get('cmp_522');
      store.set('base', 522);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1044);
    });
    test('computed and async binding #0004', () async {
      final store = QLStoreRegistry.instance.get('cmp_523');
      store.set('a', 523);
      store.set('b', 524);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1047);
    });
    test('computed and async binding #0005', () async {
      final store = QLStoreRegistry.instance.get('cmp_524');
      store.set('items', [524, 525]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 524);
    });
    test('computed and async binding #0006', () async {
      final store = QLStoreRegistry.instance.get('cmp_525');
      store.set('count', 525);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 526);
      });
      await _flush();
      expect(store.get('triple'), 1578);
    });
    test('computed and async binding #0007', () async {
      final store = QLStoreRegistry.instance.get('cmp_526');
      store.set('x', 526);
      store.set('y', 528);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 529);
      await _flush();
      expect(store.get('sum'), 1057);
    });
    test('computed and async binding #0008', () async {
      final store = QLStoreRegistry.instance.get('cmp_527');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0009', () async {
      final store = QLStoreRegistry.instance.get('cmp_528');
      store.set('base', 528);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1056);
    });
    test('computed and async binding #0010', () async {
      final store = QLStoreRegistry.instance.get('cmp_529');
      store.set('a', 529);
      store.set('b', 530);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1059);
    });
    test('computed and async binding #0011', () async {
      final store = QLStoreRegistry.instance.get('cmp_530');
      store.set('items', [530, 531]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 530);
    });
    test('computed and async binding #0012', () async {
      final store = QLStoreRegistry.instance.get('cmp_531');
      store.set('count', 531);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 532);
      });
      await _flush();
      expect(store.get('triple'), 1596);
    });
    test('computed and async binding #0013', () async {
      final store = QLStoreRegistry.instance.get('cmp_532');
      store.set('x', 532);
      store.set('y', 534);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 535);
      await _flush();
      expect(store.get('sum'), 1069);
    });
    test('computed and async binding #0014', () async {
      final store = QLStoreRegistry.instance.get('cmp_533');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0015', () async {
      final store = QLStoreRegistry.instance.get('cmp_534');
      store.set('base', 534);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1068);
    });
    test('computed and async binding #0016', () async {
      final store = QLStoreRegistry.instance.get('cmp_535');
      store.set('a', 535);
      store.set('b', 536);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1071);
    });
    test('computed and async binding #0017', () async {
      final store = QLStoreRegistry.instance.get('cmp_536');
      store.set('items', [536, 537]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 536);
    });
    test('computed and async binding #0018', () async {
      final store = QLStoreRegistry.instance.get('cmp_537');
      store.set('count', 537);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 538);
      });
      await _flush();
      expect(store.get('triple'), 1614);
    });
    test('computed and async binding #0019', () async {
      final store = QLStoreRegistry.instance.get('cmp_538');
      store.set('x', 538);
      store.set('y', 540);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 541);
      await _flush();
      expect(store.get('sum'), 1081);
    });
    test('computed and async binding #0020', () async {
      final store = QLStoreRegistry.instance.get('cmp_539');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0021', () async {
      final store = QLStoreRegistry.instance.get('cmp_540');
      store.set('base', 540);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1080);
    });
    test('computed and async binding #0022', () async {
      final store = QLStoreRegistry.instance.get('cmp_541');
      store.set('a', 541);
      store.set('b', 542);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1083);
    });
    test('computed and async binding #0023', () async {
      final store = QLStoreRegistry.instance.get('cmp_542');
      store.set('items', [542, 543]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 542);
    });
    test('computed and async binding #0024', () async {
      final store = QLStoreRegistry.instance.get('cmp_543');
      store.set('count', 543);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 544);
      });
      await _flush();
      expect(store.get('triple'), 1632);
    });
    test('computed and async binding #0025', () async {
      final store = QLStoreRegistry.instance.get('cmp_544');
      store.set('x', 544);
      store.set('y', 546);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 547);
      await _flush();
      expect(store.get('sum'), 1093);
    });
    test('computed and async binding #0026', () async {
      final store = QLStoreRegistry.instance.get('cmp_545');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0027', () async {
      final store = QLStoreRegistry.instance.get('cmp_546');
      store.set('base', 546);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1092);
    });
    test('computed and async binding #0028', () async {
      final store = QLStoreRegistry.instance.get('cmp_547');
      store.set('a', 547);
      store.set('b', 548);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1095);
    });
    test('computed and async binding #0029', () async {
      final store = QLStoreRegistry.instance.get('cmp_548');
      store.set('items', [548, 549]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 548);
    });
    test('computed and async binding #0030', () async {
      final store = QLStoreRegistry.instance.get('cmp_549');
      store.set('count', 549);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 550);
      });
      await _flush();
      expect(store.get('triple'), 1650);
    });
    test('computed and async binding #0031', () async {
      final store = QLStoreRegistry.instance.get('cmp_550');
      store.set('x', 550);
      store.set('y', 552);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 553);
      await _flush();
      expect(store.get('sum'), 1105);
    });
    test('computed and async binding #0032', () async {
      final store = QLStoreRegistry.instance.get('cmp_551');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0033', () async {
      final store = QLStoreRegistry.instance.get('cmp_552');
      store.set('base', 552);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1104);
    });
    test('computed and async binding #0034', () async {
      final store = QLStoreRegistry.instance.get('cmp_553');
      store.set('a', 553);
      store.set('b', 554);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1107);
    });
    test('computed and async binding #0035', () async {
      final store = QLStoreRegistry.instance.get('cmp_554');
      store.set('items', [554, 555]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 554);
    });
    test('computed and async binding #0036', () async {
      final store = QLStoreRegistry.instance.get('cmp_555');
      store.set('count', 555);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 556);
      });
      await _flush();
      expect(store.get('triple'), 1668);
    });
    test('computed and async binding #0037', () async {
      final store = QLStoreRegistry.instance.get('cmp_556');
      store.set('x', 556);
      store.set('y', 558);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 559);
      await _flush();
      expect(store.get('sum'), 1117);
    });
    test('computed and async binding #0038', () async {
      final store = QLStoreRegistry.instance.get('cmp_557');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0039', () async {
      final store = QLStoreRegistry.instance.get('cmp_558');
      store.set('base', 558);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1116);
    });
    test('computed and async binding #0040', () async {
      final store = QLStoreRegistry.instance.get('cmp_559');
      store.set('a', 559);
      store.set('b', 560);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1119);
    });
    test('computed and async binding #0041', () async {
      final store = QLStoreRegistry.instance.get('cmp_560');
      store.set('items', [560, 561]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 560);
    });
    test('computed and async binding #0042', () async {
      final store = QLStoreRegistry.instance.get('cmp_561');
      store.set('count', 561);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 562);
      });
      await _flush();
      expect(store.get('triple'), 1686);
    });
    test('computed and async binding #0043', () async {
      final store = QLStoreRegistry.instance.get('cmp_562');
      store.set('x', 562);
      store.set('y', 564);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 565);
      await _flush();
      expect(store.get('sum'), 1129);
    });
    test('computed and async binding #0044', () async {
      final store = QLStoreRegistry.instance.get('cmp_563');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0045', () async {
      final store = QLStoreRegistry.instance.get('cmp_564');
      store.set('base', 564);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1128);
    });
    test('computed and async binding #0046', () async {
      final store = QLStoreRegistry.instance.get('cmp_565');
      store.set('a', 565);
      store.set('b', 566);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1131);
    });
    test('computed and async binding #0047', () async {
      final store = QLStoreRegistry.instance.get('cmp_566');
      store.set('items', [566, 567]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 566);
    });
    test('computed and async binding #0048', () async {
      final store = QLStoreRegistry.instance.get('cmp_567');
      store.set('count', 567);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 568);
      });
      await _flush();
      expect(store.get('triple'), 1704);
    });
    test('computed and async binding #0049', () async {
      final store = QLStoreRegistry.instance.get('cmp_568');
      store.set('x', 568);
      store.set('y', 570);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 571);
      await _flush();
      expect(store.get('sum'), 1141);
    });
    test('computed and async binding #0050', () async {
      final store = QLStoreRegistry.instance.get('cmp_569');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0051', () async {
      final store = QLStoreRegistry.instance.get('cmp_570');
      store.set('base', 570);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1140);
    });
    test('computed and async binding #0052', () async {
      final store = QLStoreRegistry.instance.get('cmp_571');
      store.set('a', 571);
      store.set('b', 572);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1143);
    });
    test('computed and async binding #0053', () async {
      final store = QLStoreRegistry.instance.get('cmp_572');
      store.set('items', [572, 573]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 572);
    });
    test('computed and async binding #0054', () async {
      final store = QLStoreRegistry.instance.get('cmp_573');
      store.set('count', 573);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 574);
      });
      await _flush();
      expect(store.get('triple'), 1722);
    });
    test('computed and async binding #0055', () async {
      final store = QLStoreRegistry.instance.get('cmp_574');
      store.set('x', 574);
      store.set('y', 576);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 577);
      await _flush();
      expect(store.get('sum'), 1153);
    });
    test('computed and async binding #0056', () async {
      final store = QLStoreRegistry.instance.get('cmp_575');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0057', () async {
      final store = QLStoreRegistry.instance.get('cmp_576');
      store.set('base', 576);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1152);
    });
    test('computed and async binding #0058', () async {
      final store = QLStoreRegistry.instance.get('cmp_577');
      store.set('a', 577);
      store.set('b', 578);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1155);
    });
    test('computed and async binding #0059', () async {
      final store = QLStoreRegistry.instance.get('cmp_578');
      store.set('items', [578, 579]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 578);
    });
    test('computed and async binding #0060', () async {
      final store = QLStoreRegistry.instance.get('cmp_579');
      store.set('count', 579);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 580);
      });
      await _flush();
      expect(store.get('triple'), 1740);
    });
    test('computed and async binding #0061', () async {
      final store = QLStoreRegistry.instance.get('cmp_580');
      store.set('x', 580);
      store.set('y', 582);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 583);
      await _flush();
      expect(store.get('sum'), 1165);
    });
    test('computed and async binding #0062', () async {
      final store = QLStoreRegistry.instance.get('cmp_581');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0063', () async {
      final store = QLStoreRegistry.instance.get('cmp_582');
      store.set('base', 582);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1164);
    });
    test('computed and async binding #0064', () async {
      final store = QLStoreRegistry.instance.get('cmp_583');
      store.set('a', 583);
      store.set('b', 584);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1167);
    });
    test('computed and async binding #0065', () async {
      final store = QLStoreRegistry.instance.get('cmp_584');
      store.set('items', [584, 585]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 584);
    });
    test('computed and async binding #0066', () async {
      final store = QLStoreRegistry.instance.get('cmp_585');
      store.set('count', 585);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 586);
      });
      await _flush();
      expect(store.get('triple'), 1758);
    });
    test('computed and async binding #0067', () async {
      final store = QLStoreRegistry.instance.get('cmp_586');
      store.set('x', 586);
      store.set('y', 588);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 589);
      await _flush();
      expect(store.get('sum'), 1177);
    });
    test('computed and async binding #0068', () async {
      final store = QLStoreRegistry.instance.get('cmp_587');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0069', () async {
      final store = QLStoreRegistry.instance.get('cmp_588');
      store.set('base', 588);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1176);
    });
    test('computed and async binding #0070', () async {
      final store = QLStoreRegistry.instance.get('cmp_589');
      store.set('a', 589);
      store.set('b', 590);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1179);
    });
    test('computed and async binding #0071', () async {
      final store = QLStoreRegistry.instance.get('cmp_590');
      store.set('items', [590, 591]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 590);
    });
    test('computed and async binding #0072', () async {
      final store = QLStoreRegistry.instance.get('cmp_591');
      store.set('count', 591);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 592);
      });
      await _flush();
      expect(store.get('triple'), 1776);
    });
    test('computed and async binding #0073', () async {
      final store = QLStoreRegistry.instance.get('cmp_592');
      store.set('x', 592);
      store.set('y', 594);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 595);
      await _flush();
      expect(store.get('sum'), 1189);
    });
    test('computed and async binding #0074', () async {
      final store = QLStoreRegistry.instance.get('cmp_593');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0075', () async {
      final store = QLStoreRegistry.instance.get('cmp_594');
      store.set('base', 594);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1188);
    });
    test('computed and async binding #0076', () async {
      final store = QLStoreRegistry.instance.get('cmp_595');
      store.set('a', 595);
      store.set('b', 596);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1191);
    });
    test('computed and async binding #0077', () async {
      final store = QLStoreRegistry.instance.get('cmp_596');
      store.set('items', [596, 597]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 596);
    });
    test('computed and async binding #0078', () async {
      final store = QLStoreRegistry.instance.get('cmp_597');
      store.set('count', 597);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 598);
      });
      await _flush();
      expect(store.get('triple'), 1794);
    });
    test('computed and async binding #0079', () async {
      final store = QLStoreRegistry.instance.get('cmp_598');
      store.set('x', 598);
      store.set('y', 600);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 601);
      await _flush();
      expect(store.get('sum'), 1201);
    });
    test('computed and async binding #0080', () async {
      final store = QLStoreRegistry.instance.get('cmp_599');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0081', () async {
      final store = QLStoreRegistry.instance.get('cmp_600');
      store.set('base', 600);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1200);
    });
    test('computed and async binding #0082', () async {
      final store = QLStoreRegistry.instance.get('cmp_601');
      store.set('a', 601);
      store.set('b', 602);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1203);
    });
    test('computed and async binding #0083', () async {
      final store = QLStoreRegistry.instance.get('cmp_602');
      store.set('items', [602, 603]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 602);
    });
    test('computed and async binding #0084', () async {
      final store = QLStoreRegistry.instance.get('cmp_603');
      store.set('count', 603);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 604);
      });
      await _flush();
      expect(store.get('triple'), 1812);
    });
    test('computed and async binding #0085', () async {
      final store = QLStoreRegistry.instance.get('cmp_604');
      store.set('x', 604);
      store.set('y', 606);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 607);
      await _flush();
      expect(store.get('sum'), 1213);
    });
    test('computed and async binding #0086', () async {
      final store = QLStoreRegistry.instance.get('cmp_605');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0087', () async {
      final store = QLStoreRegistry.instance.get('cmp_606');
      store.set('base', 606);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1212);
    });
    test('computed and async binding #0088', () async {
      final store = QLStoreRegistry.instance.get('cmp_607');
      store.set('a', 607);
      store.set('b', 608);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1215);
    });
    test('computed and async binding #0089', () async {
      final store = QLStoreRegistry.instance.get('cmp_608');
      store.set('items', [608, 609]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 608);
    });
    test('computed and async binding #0090', () async {
      final store = QLStoreRegistry.instance.get('cmp_609');
      store.set('count', 609);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 610);
      });
      await _flush();
      expect(store.get('triple'), 1830);
    });
    test('computed and async binding #0091', () async {
      final store = QLStoreRegistry.instance.get('cmp_610');
      store.set('x', 610);
      store.set('y', 612);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 613);
      await _flush();
      expect(store.get('sum'), 1225);
    });
    test('computed and async binding #0092', () async {
      final store = QLStoreRegistry.instance.get('cmp_611');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0093', () async {
      final store = QLStoreRegistry.instance.get('cmp_612');
      store.set('base', 612);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1224);
    });
    test('computed and async binding #0094', () async {
      final store = QLStoreRegistry.instance.get('cmp_613');
      store.set('a', 613);
      store.set('b', 614);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1227);
    });
    test('computed and async binding #0095', () async {
      final store = QLStoreRegistry.instance.get('cmp_614');
      store.set('items', [614, 615]);
      store.registerComputed('first', ['items'], (values) {
        final items = values.first as List;
        return items.first;
      });
      await _flush();
      expect(store.get('first'), 614);
    });
    test('computed and async binding #0096', () async {
      final store = QLStoreRegistry.instance.get('cmp_615');
      store.set('count', 615);
      store.registerComputed(
          'triple', ['count'], (values) => (values.first as num) * 3);
      store.transaction(() {
        store.set('count', 616);
      });
      await _flush();
      expect(store.get('triple'), 1848);
    });
    test('computed and async binding #0097', () async {
      final store = QLStoreRegistry.instance.get('cmp_616');
      store.set('x', 616);
      store.set('y', 618);
      store.registerComputed('sum', ['x', 'y'],
          (values) => (values[0] as num) + (values[1] as num));
      store.set('x', 619);
      await _flush();
      expect(store.get('sum'), 1237);
    });
    test('computed and async binding #0098', () async {
      final store = QLStoreRegistry.instance.get('cmp_617');
      store.set('flag', true);
      store.registerComputed('mirror', ['flag'], (values) => values.first);
      await _flush();
      expect(store.get('mirror'), isTrue);
    });
    test('computed and async binding #0099', () async {
      final store = QLStoreRegistry.instance.get('cmp_618');
      store.set('base', 618);
      store.registerComputed(
          'double', ['base'], (values) => (values.first as num) * 2);
      await _flush();
      expect(store.get('double'), 1236);
    });
    test('computed and async binding #0100', () async {
      final store = QLStoreRegistry.instance.get('cmp_619');
      store.set('a', 619);
      store.set('b', 620);
      store.registerComputed('sum', ['a', 'b'],
          (values) => (values[0] as num) + (values[1] as num));
      await _flush();
      expect(store.get('sum'), 1239);
    });
  });

  group('slice model and context', () {
    test('slice model and context #0001', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_620',
          schema: 'schema.620',
          dataSource: 'source.620',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_620');
      expect(map['schema'], 'schema.620');
      expect(map['dataSource'], 'source.620');
    });
    test('slice model and context #0002', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_621',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_621',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0003', () {
      final slice = QLStoreSlice(namespace: 'slice_model_622', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0004', () {
      final slice = QLStoreSlice(namespace: 'slice_model_623', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0005', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_624',
        sliceName: 'slice_624',
        schema: 'schema.624',
        dataSource: 'source.624',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_624', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_624');
      expect(map['sliceName'], 'slice_624');
      expect(map['schema'], 'schema.624');
      expect(map['dataSource'], 'source.624');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0006', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_625',
          schema: 'schema.625',
          dataSource: 'source.625',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_625');
      expect(map['schema'], 'schema.625');
      expect(map['dataSource'], 'source.625');
    });
    test('slice model and context #0007', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_626',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_626',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0008', () {
      final slice = QLStoreSlice(namespace: 'slice_model_627', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0009', () {
      final slice = QLStoreSlice(namespace: 'slice_model_628', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0010', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_629',
        sliceName: 'slice_629',
        schema: 'schema.629',
        dataSource: 'source.629',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_629', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_629');
      expect(map['sliceName'], 'slice_629');
      expect(map['schema'], 'schema.629');
      expect(map['dataSource'], 'source.629');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0011', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_630',
          schema: 'schema.630',
          dataSource: 'source.630',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_630');
      expect(map['schema'], 'schema.630');
      expect(map['dataSource'], 'source.630');
    });
    test('slice model and context #0012', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_631',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_631',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0013', () {
      final slice = QLStoreSlice(namespace: 'slice_model_632', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0014', () {
      final slice = QLStoreSlice(namespace: 'slice_model_633', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0015', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_634',
        sliceName: 'slice_634',
        schema: 'schema.634',
        dataSource: 'source.634',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_634', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_634');
      expect(map['sliceName'], 'slice_634');
      expect(map['schema'], 'schema.634');
      expect(map['dataSource'], 'source.634');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0016', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_635',
          schema: 'schema.635',
          dataSource: 'source.635',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_635');
      expect(map['schema'], 'schema.635');
      expect(map['dataSource'], 'source.635');
    });
    test('slice model and context #0017', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_636',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_636',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0018', () {
      final slice = QLStoreSlice(namespace: 'slice_model_637', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0019', () {
      final slice = QLStoreSlice(namespace: 'slice_model_638', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0020', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_639',
        sliceName: 'slice_639',
        schema: 'schema.639',
        dataSource: 'source.639',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_639', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_639');
      expect(map['sliceName'], 'slice_639');
      expect(map['schema'], 'schema.639');
      expect(map['dataSource'], 'source.639');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0021', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_640',
          schema: 'schema.640',
          dataSource: 'source.640',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_640');
      expect(map['schema'], 'schema.640');
      expect(map['dataSource'], 'source.640');
    });
    test('slice model and context #0022', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_641',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_641',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0023', () {
      final slice = QLStoreSlice(namespace: 'slice_model_642', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0024', () {
      final slice = QLStoreSlice(namespace: 'slice_model_643', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0025', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_644',
        sliceName: 'slice_644',
        schema: 'schema.644',
        dataSource: 'source.644',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_644', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_644');
      expect(map['sliceName'], 'slice_644');
      expect(map['schema'], 'schema.644');
      expect(map['dataSource'], 'source.644');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0026', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_645',
          schema: 'schema.645',
          dataSource: 'source.645',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_645');
      expect(map['schema'], 'schema.645');
      expect(map['dataSource'], 'source.645');
    });
    test('slice model and context #0027', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_646',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_646',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0028', () {
      final slice = QLStoreSlice(namespace: 'slice_model_647', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0029', () {
      final slice = QLStoreSlice(namespace: 'slice_model_648', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0030', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_649',
        sliceName: 'slice_649',
        schema: 'schema.649',
        dataSource: 'source.649',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_649', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_649');
      expect(map['sliceName'], 'slice_649');
      expect(map['schema'], 'schema.649');
      expect(map['dataSource'], 'source.649');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0031', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_650',
          schema: 'schema.650',
          dataSource: 'source.650',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_650');
      expect(map['schema'], 'schema.650');
      expect(map['dataSource'], 'source.650');
    });
    test('slice model and context #0032', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_651',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_651',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0033', () {
      final slice = QLStoreSlice(namespace: 'slice_model_652', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0034', () {
      final slice = QLStoreSlice(namespace: 'slice_model_653', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0035', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_654',
        sliceName: 'slice_654',
        schema: 'schema.654',
        dataSource: 'source.654',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_654', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_654');
      expect(map['sliceName'], 'slice_654');
      expect(map['schema'], 'schema.654');
      expect(map['dataSource'], 'source.654');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0036', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_655',
          schema: 'schema.655',
          dataSource: 'source.655',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_655');
      expect(map['schema'], 'schema.655');
      expect(map['dataSource'], 'source.655');
    });
    test('slice model and context #0037', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_656',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_656',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0038', () {
      final slice = QLStoreSlice(namespace: 'slice_model_657', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0039', () {
      final slice = QLStoreSlice(namespace: 'slice_model_658', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0040', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_659',
        sliceName: 'slice_659',
        schema: 'schema.659',
        dataSource: 'source.659',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_659', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_659');
      expect(map['sliceName'], 'slice_659');
      expect(map['schema'], 'schema.659');
      expect(map['dataSource'], 'source.659');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0041', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_660',
          schema: 'schema.660',
          dataSource: 'source.660',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_660');
      expect(map['schema'], 'schema.660');
      expect(map['dataSource'], 'source.660');
    });
    test('slice model and context #0042', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_661',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_661',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0043', () {
      final slice = QLStoreSlice(namespace: 'slice_model_662', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0044', () {
      final slice = QLStoreSlice(namespace: 'slice_model_663', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0045', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_664',
        sliceName: 'slice_664',
        schema: 'schema.664',
        dataSource: 'source.664',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_664', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_664');
      expect(map['sliceName'], 'slice_664');
      expect(map['schema'], 'schema.664');
      expect(map['dataSource'], 'source.664');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0046', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_665',
          schema: 'schema.665',
          dataSource: 'source.665',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_665');
      expect(map['schema'], 'schema.665');
      expect(map['dataSource'], 'source.665');
    });
    test('slice model and context #0047', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_666',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_666',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0048', () {
      final slice = QLStoreSlice(namespace: 'slice_model_667', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0049', () {
      final slice = QLStoreSlice(namespace: 'slice_model_668', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0050', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_669',
        sliceName: 'slice_669',
        schema: 'schema.669',
        dataSource: 'source.669',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_669', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_669');
      expect(map['sliceName'], 'slice_669');
      expect(map['schema'], 'schema.669');
      expect(map['dataSource'], 'source.669');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0051', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_670',
          schema: 'schema.670',
          dataSource: 'source.670',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_670');
      expect(map['schema'], 'schema.670');
      expect(map['dataSource'], 'source.670');
    });
    test('slice model and context #0052', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_671',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_671',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0053', () {
      final slice = QLStoreSlice(namespace: 'slice_model_672', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0054', () {
      final slice = QLStoreSlice(namespace: 'slice_model_673', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0055', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_674',
        sliceName: 'slice_674',
        schema: 'schema.674',
        dataSource: 'source.674',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_674', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_674');
      expect(map['sliceName'], 'slice_674');
      expect(map['schema'], 'schema.674');
      expect(map['dataSource'], 'source.674');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0056', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_675',
          schema: 'schema.675',
          dataSource: 'source.675',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_675');
      expect(map['schema'], 'schema.675');
      expect(map['dataSource'], 'source.675');
    });
    test('slice model and context #0057', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_676',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_676',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0058', () {
      final slice = QLStoreSlice(namespace: 'slice_model_677', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0059', () {
      final slice = QLStoreSlice(namespace: 'slice_model_678', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0060', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_679',
        sliceName: 'slice_679',
        schema: 'schema.679',
        dataSource: 'source.679',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_679', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_679');
      expect(map['sliceName'], 'slice_679');
      expect(map['schema'], 'schema.679');
      expect(map['dataSource'], 'source.679');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0061', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_680',
          schema: 'schema.680',
          dataSource: 'source.680',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_680');
      expect(map['schema'], 'schema.680');
      expect(map['dataSource'], 'source.680');
    });
    test('slice model and context #0062', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_681',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_681',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0063', () {
      final slice = QLStoreSlice(namespace: 'slice_model_682', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0064', () {
      final slice = QLStoreSlice(namespace: 'slice_model_683', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0065', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_684',
        sliceName: 'slice_684',
        schema: 'schema.684',
        dataSource: 'source.684',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_684', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_684');
      expect(map['sliceName'], 'slice_684');
      expect(map['schema'], 'schema.684');
      expect(map['dataSource'], 'source.684');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0066', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_685',
          schema: 'schema.685',
          dataSource: 'source.685',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_685');
      expect(map['schema'], 'schema.685');
      expect(map['dataSource'], 'source.685');
    });
    test('slice model and context #0067', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_686',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_686',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0068', () {
      final slice = QLStoreSlice(namespace: 'slice_model_687', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0069', () {
      final slice = QLStoreSlice(namespace: 'slice_model_688', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0070', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_689',
        sliceName: 'slice_689',
        schema: 'schema.689',
        dataSource: 'source.689',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_689', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_689');
      expect(map['sliceName'], 'slice_689');
      expect(map['schema'], 'schema.689');
      expect(map['dataSource'], 'source.689');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0071', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_690',
          schema: 'schema.690',
          dataSource: 'source.690',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_690');
      expect(map['schema'], 'schema.690');
      expect(map['dataSource'], 'source.690');
    });
    test('slice model and context #0072', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_691',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_691',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0073', () {
      final slice = QLStoreSlice(namespace: 'slice_model_692', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0074', () {
      final slice = QLStoreSlice(namespace: 'slice_model_693', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0075', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_694',
        sliceName: 'slice_694',
        schema: 'schema.694',
        dataSource: 'source.694',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_694', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_694');
      expect(map['sliceName'], 'slice_694');
      expect(map['schema'], 'schema.694');
      expect(map['dataSource'], 'source.694');
      expect(map['metadata']['secure'], true);
    });
    test('slice model and context #0076', () {
      final slice = QLStoreSlice(
          namespace: 'slice_model_695',
          schema: 'schema.695',
          dataSource: 'source.695',
          state: const {'a': 1},
          metadata: const {'m': 1});
      final map = slice.toMap();
      expect(map['namespace'], 'slice_model_695');
      expect(map['schema'], 'schema.695');
      expect(map['dataSource'], 'source.695');
    });
    test('slice model and context #0077', () {
      final left = QLStoreSlice(
          namespace: 'slice_model_696',
          state: const {'a': 1},
          metadata: const {'left': true});
      final right = QLStoreSlice(
          namespace: 'slice_model_696',
          state: const {'b': 2},
          metadata: const {'right': true});
      final merged = left.merge(right);
      expect(merged.state['a'], 1);
      expect(merged.state['b'], 2);
      expect(merged.metadata['left'], true);
      expect(merged.metadata['right'], true);
    });
    test('slice model and context #0078', () {
      final slice = QLStoreSlice(namespace: 'slice_model_697', computed: const {
        'sum': ['a', 'b']
      }, mutations: const {
        'save': 'set'
      }, queries: const {
        'read': 'get'
      }, pipelines: const {
        'refresh': 'refresh'
      });
      expect(slice.computed.keys, contains('sum'));
      expect(slice.mutations.keys, contains('save'));
      expect(slice.queries.keys, contains('read'));
      expect(slice.pipelines.keys, contains('refresh'));
    });
    test('slice model and context #0079', () {
      final slice = QLStoreSlice(namespace: 'slice_model_698', state: const {
        'flag': true
      }, strategies: const {
        'identity': {'op': 'identity'}
      });
      expect(slice.strategies['identity'], isA<Map>());
      expect(slice.state['flag'], isTrue);
    });
    test('slice model and context #0080', () {
      final ctx = QLSliceExecutionContext(
        namespace: 'slice_model_699',
        sliceName: 'slice_699',
        schema: 'schema.699',
        dataSource: 'source.699',
        metadata: const {'secure': true},
        sliceDefinition: const {
          'state': {'a': 1}
        },
        slice: const QLStoreSlice(
            namespace: 'slice_model_699', state: const {'a': 1}),
      );
      final map = ctx.toMap();
      expect(map['namespace'], 'slice_model_699');
      expect(map['sliceName'], 'slice_699');
      expect(map['schema'], 'schema.699');
      expect(map['dataSource'], 'source.699');
      expect(map['metadata']['secure'], true);
    });
  });

  group('slice registry and plugins', () {
    test('slice registry and plugins #0001', () {
      final slice =
          QLStoreSlice(namespace: 'slice_700', state: const {'count': 700});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_700']?.state['count'], 700);
    });
    test('slice registry and plugins #0002', () {
      final slice =
          QLStoreSlice(namespace: 'slice_701', state: const {'title': 't701'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_701').get('title'), 't701');
    });
    test('slice registry and plugins #0003', () async {
      final slice = QLStoreSlice(namespace: 'slice_702', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_702');
      store.set('value', 702);
      await _flush();
      expect(store.get('mirror'), 702);
    });
    test('slice registry and plugins #0004', () async {
      final slice = QLStoreSlice(namespace: 'slice_703', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_703.bump']!;
      final store = QLStoreRegistry.instance.get('slice_703');
      store.set('count', 703);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 704);
    });
    test('slice registry and plugins #0005', () async {
      final slice = QLStoreSlice(namespace: 'slice_704', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_704.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_704');
      store.set('count', 704);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 704);
    });
    test('slice registry and plugins #0006', () async {
      final slice = QLStoreSlice(namespace: 'slice_705', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_705.setName']!;
      final store = QLStoreRegistry.instance.get('slice_705');
      await plugin
          .execute(const {'value': 'name-705'}, store, const QLNullContext());
      expect(store.get('name'), 'name-705');
    });
    test('slice registry and plugins #0007', () async {
      final slice = QLStoreSlice(namespace: 'slice_706', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_706.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_706');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0008', () async {
      final slice = QLStoreSlice(namespace: 'slice_707', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_707.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_707');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0009', () async {
      final slice = QLStoreSlice(namespace: 'slice_708', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_708.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_708');
      store.set('a', 708);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 708);
    });
    test('slice registry and plugins #0010', () {
      final slice =
          QLStoreSlice(namespace: 'slice_709', state: const {'v': 709});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_709');
      expect(QLSliceRegistry.instance['slice_709'], isNull);
    });
    test('slice registry and plugins #0011', () {
      final slice =
          QLStoreSlice(namespace: 'slice_710', state: const {'count': 710});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_710']?.state['count'], 710);
    });
    test('slice registry and plugins #0012', () {
      final slice =
          QLStoreSlice(namespace: 'slice_711', state: const {'title': 't711'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_711').get('title'), 't711');
    });
    test('slice registry and plugins #0013', () async {
      final slice = QLStoreSlice(namespace: 'slice_712', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_712');
      store.set('value', 712);
      await _flush();
      expect(store.get('mirror'), 712);
    });
    test('slice registry and plugins #0014', () async {
      final slice = QLStoreSlice(namespace: 'slice_713', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_713.bump']!;
      final store = QLStoreRegistry.instance.get('slice_713');
      store.set('count', 713);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 714);
    });
    test('slice registry and plugins #0015', () async {
      final slice = QLStoreSlice(namespace: 'slice_714', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_714.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_714');
      store.set('count', 714);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 714);
    });
    test('slice registry and plugins #0016', () async {
      final slice = QLStoreSlice(namespace: 'slice_715', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_715.setName']!;
      final store = QLStoreRegistry.instance.get('slice_715');
      await plugin
          .execute(const {'value': 'name-715'}, store, const QLNullContext());
      expect(store.get('name'), 'name-715');
    });
    test('slice registry and plugins #0017', () async {
      final slice = QLStoreSlice(namespace: 'slice_716', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_716.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_716');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0018', () async {
      final slice = QLStoreSlice(namespace: 'slice_717', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_717.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_717');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0019', () async {
      final slice = QLStoreSlice(namespace: 'slice_718', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_718.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_718');
      store.set('a', 718);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 718);
    });
    test('slice registry and plugins #0020', () {
      final slice =
          QLStoreSlice(namespace: 'slice_719', state: const {'v': 719});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_719');
      expect(QLSliceRegistry.instance['slice_719'], isNull);
    });
    test('slice registry and plugins #0021', () {
      final slice =
          QLStoreSlice(namespace: 'slice_720', state: const {'count': 720});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_720']?.state['count'], 720);
    });
    test('slice registry and plugins #0022', () {
      final slice =
          QLStoreSlice(namespace: 'slice_721', state: const {'title': 't721'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_721').get('title'), 't721');
    });
    test('slice registry and plugins #0023', () async {
      final slice = QLStoreSlice(namespace: 'slice_722', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_722');
      store.set('value', 722);
      await _flush();
      expect(store.get('mirror'), 722);
    });
    test('slice registry and plugins #0024', () async {
      final slice = QLStoreSlice(namespace: 'slice_723', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_723.bump']!;
      final store = QLStoreRegistry.instance.get('slice_723');
      store.set('count', 723);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 724);
    });
    test('slice registry and plugins #0025', () async {
      final slice = QLStoreSlice(namespace: 'slice_724', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_724.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_724');
      store.set('count', 724);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 724);
    });
    test('slice registry and plugins #0026', () async {
      final slice = QLStoreSlice(namespace: 'slice_725', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_725.setName']!;
      final store = QLStoreRegistry.instance.get('slice_725');
      await plugin
          .execute(const {'value': 'name-725'}, store, const QLNullContext());
      expect(store.get('name'), 'name-725');
    });
    test('slice registry and plugins #0027', () async {
      final slice = QLStoreSlice(namespace: 'slice_726', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_726.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_726');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0028', () async {
      final slice = QLStoreSlice(namespace: 'slice_727', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_727.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_727');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0029', () async {
      final slice = QLStoreSlice(namespace: 'slice_728', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_728.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_728');
      store.set('a', 728);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 728);
    });
    test('slice registry and plugins #0030', () {
      final slice =
          QLStoreSlice(namespace: 'slice_729', state: const {'v': 729});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_729');
      expect(QLSliceRegistry.instance['slice_729'], isNull);
    });
    test('slice registry and plugins #0031', () {
      final slice =
          QLStoreSlice(namespace: 'slice_730', state: const {'count': 730});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_730']?.state['count'], 730);
    });
    test('slice registry and plugins #0032', () {
      final slice =
          QLStoreSlice(namespace: 'slice_731', state: const {'title': 't731'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_731').get('title'), 't731');
    });
    test('slice registry and plugins #0033', () async {
      final slice = QLStoreSlice(namespace: 'slice_732', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_732');
      store.set('value', 732);
      await _flush();
      expect(store.get('mirror'), 732);
    });
    test('slice registry and plugins #0034', () async {
      final slice = QLStoreSlice(namespace: 'slice_733', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_733.bump']!;
      final store = QLStoreRegistry.instance.get('slice_733');
      store.set('count', 733);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 734);
    });
    test('slice registry and plugins #0035', () async {
      final slice = QLStoreSlice(namespace: 'slice_734', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_734.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_734');
      store.set('count', 734);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 734);
    });
    test('slice registry and plugins #0036', () async {
      final slice = QLStoreSlice(namespace: 'slice_735', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_735.setName']!;
      final store = QLStoreRegistry.instance.get('slice_735');
      await plugin
          .execute(const {'value': 'name-735'}, store, const QLNullContext());
      expect(store.get('name'), 'name-735');
    });
    test('slice registry and plugins #0037', () async {
      final slice = QLStoreSlice(namespace: 'slice_736', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_736.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_736');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0038', () async {
      final slice = QLStoreSlice(namespace: 'slice_737', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_737.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_737');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0039', () async {
      final slice = QLStoreSlice(namespace: 'slice_738', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_738.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_738');
      store.set('a', 738);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 738);
    });
    test('slice registry and plugins #0040', () {
      final slice =
          QLStoreSlice(namespace: 'slice_739', state: const {'v': 739});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_739');
      expect(QLSliceRegistry.instance['slice_739'], isNull);
    });
    test('slice registry and plugins #0041', () {
      final slice =
          QLStoreSlice(namespace: 'slice_740', state: const {'count': 740});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_740']?.state['count'], 740);
    });
    test('slice registry and plugins #0042', () {
      final slice =
          QLStoreSlice(namespace: 'slice_741', state: const {'title': 't741'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_741').get('title'), 't741');
    });
    test('slice registry and plugins #0043', () async {
      final slice = QLStoreSlice(namespace: 'slice_742', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_742');
      store.set('value', 742);
      await _flush();
      expect(store.get('mirror'), 742);
    });
    test('slice registry and plugins #0044', () async {
      final slice = QLStoreSlice(namespace: 'slice_743', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_743.bump']!;
      final store = QLStoreRegistry.instance.get('slice_743');
      store.set('count', 743);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 744);
    });
    test('slice registry and plugins #0045', () async {
      final slice = QLStoreSlice(namespace: 'slice_744', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_744.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_744');
      store.set('count', 744);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 744);
    });
    test('slice registry and plugins #0046', () async {
      final slice = QLStoreSlice(namespace: 'slice_745', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_745.setName']!;
      final store = QLStoreRegistry.instance.get('slice_745');
      await plugin
          .execute(const {'value': 'name-745'}, store, const QLNullContext());
      expect(store.get('name'), 'name-745');
    });
    test('slice registry and plugins #0047', () async {
      final slice = QLStoreSlice(namespace: 'slice_746', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_746.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_746');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0048', () async {
      final slice = QLStoreSlice(namespace: 'slice_747', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_747.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_747');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0049', () async {
      final slice = QLStoreSlice(namespace: 'slice_748', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_748.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_748');
      store.set('a', 748);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 748);
    });
    test('slice registry and plugins #0050', () {
      final slice =
          QLStoreSlice(namespace: 'slice_749', state: const {'v': 749});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_749');
      expect(QLSliceRegistry.instance['slice_749'], isNull);
    });
    test('slice registry and plugins #0051', () {
      final slice =
          QLStoreSlice(namespace: 'slice_750', state: const {'count': 750});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_750']?.state['count'], 750);
    });
    test('slice registry and plugins #0052', () {
      final slice =
          QLStoreSlice(namespace: 'slice_751', state: const {'title': 't751'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_751').get('title'), 't751');
    });
    test('slice registry and plugins #0053', () async {
      final slice = QLStoreSlice(namespace: 'slice_752', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_752');
      store.set('value', 752);
      await _flush();
      expect(store.get('mirror'), 752);
    });
    test('slice registry and plugins #0054', () async {
      final slice = QLStoreSlice(namespace: 'slice_753', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_753.bump']!;
      final store = QLStoreRegistry.instance.get('slice_753');
      store.set('count', 753);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 754);
    });
    test('slice registry and plugins #0055', () async {
      final slice = QLStoreSlice(namespace: 'slice_754', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_754.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_754');
      store.set('count', 754);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 754);
    });
    test('slice registry and plugins #0056', () async {
      final slice = QLStoreSlice(namespace: 'slice_755', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_755.setName']!;
      final store = QLStoreRegistry.instance.get('slice_755');
      await plugin
          .execute(const {'value': 'name-755'}, store, const QLNullContext());
      expect(store.get('name'), 'name-755');
    });
    test('slice registry and plugins #0057', () async {
      final slice = QLStoreSlice(namespace: 'slice_756', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_756.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_756');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0058', () async {
      final slice = QLStoreSlice(namespace: 'slice_757', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_757.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_757');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0059', () async {
      final slice = QLStoreSlice(namespace: 'slice_758', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_758.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_758');
      store.set('a', 758);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 758);
    });
    test('slice registry and plugins #0060', () {
      final slice =
          QLStoreSlice(namespace: 'slice_759', state: const {'v': 759});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_759');
      expect(QLSliceRegistry.instance['slice_759'], isNull);
    });
    test('slice registry and plugins #0061', () {
      final slice =
          QLStoreSlice(namespace: 'slice_760', state: const {'count': 760});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_760']?.state['count'], 760);
    });
    test('slice registry and plugins #0062', () {
      final slice =
          QLStoreSlice(namespace: 'slice_761', state: const {'title': 't761'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_761').get('title'), 't761');
    });
    test('slice registry and plugins #0063', () async {
      final slice = QLStoreSlice(namespace: 'slice_762', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_762');
      store.set('value', 762);
      await _flush();
      expect(store.get('mirror'), 762);
    });
    test('slice registry and plugins #0064', () async {
      final slice = QLStoreSlice(namespace: 'slice_763', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_763.bump']!;
      final store = QLStoreRegistry.instance.get('slice_763');
      store.set('count', 763);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 764);
    });
    test('slice registry and plugins #0065', () async {
      final slice = QLStoreSlice(namespace: 'slice_764', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_764.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_764');
      store.set('count', 764);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 764);
    });
    test('slice registry and plugins #0066', () async {
      final slice = QLStoreSlice(namespace: 'slice_765', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_765.setName']!;
      final store = QLStoreRegistry.instance.get('slice_765');
      await plugin
          .execute(const {'value': 'name-765'}, store, const QLNullContext());
      expect(store.get('name'), 'name-765');
    });
    test('slice registry and plugins #0067', () async {
      final slice = QLStoreSlice(namespace: 'slice_766', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_766.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_766');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0068', () async {
      final slice = QLStoreSlice(namespace: 'slice_767', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_767.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_767');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0069', () async {
      final slice = QLStoreSlice(namespace: 'slice_768', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_768.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_768');
      store.set('a', 768);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 768);
    });
    test('slice registry and plugins #0070', () {
      final slice =
          QLStoreSlice(namespace: 'slice_769', state: const {'v': 769});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_769');
      expect(QLSliceRegistry.instance['slice_769'], isNull);
    });
    test('slice registry and plugins #0071', () {
      final slice =
          QLStoreSlice(namespace: 'slice_770', state: const {'count': 770});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_770']?.state['count'], 770);
    });
    test('slice registry and plugins #0072', () {
      final slice =
          QLStoreSlice(namespace: 'slice_771', state: const {'title': 't771'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_771').get('title'), 't771');
    });
    test('slice registry and plugins #0073', () async {
      final slice = QLStoreSlice(namespace: 'slice_772', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_772');
      store.set('value', 772);
      await _flush();
      expect(store.get('mirror'), 772);
    });
    test('slice registry and plugins #0074', () async {
      final slice = QLStoreSlice(namespace: 'slice_773', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_773.bump']!;
      final store = QLStoreRegistry.instance.get('slice_773');
      store.set('count', 773);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 774);
    });
    test('slice registry and plugins #0075', () async {
      final slice = QLStoreSlice(namespace: 'slice_774', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_774.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_774');
      store.set('count', 774);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 774);
    });
    test('slice registry and plugins #0076', () async {
      final slice = QLStoreSlice(namespace: 'slice_775', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_775.setName']!;
      final store = QLStoreRegistry.instance.get('slice_775');
      await plugin
          .execute(const {'value': 'name-775'}, store, const QLNullContext());
      expect(store.get('name'), 'name-775');
    });
    test('slice registry and plugins #0077', () async {
      final slice = QLStoreSlice(namespace: 'slice_776', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_776.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_776');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0078', () async {
      final slice = QLStoreSlice(namespace: 'slice_777', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_777.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_777');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0079', () async {
      final slice = QLStoreSlice(namespace: 'slice_778', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_778.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_778');
      store.set('a', 778);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 778);
    });
    test('slice registry and plugins #0080', () {
      final slice =
          QLStoreSlice(namespace: 'slice_779', state: const {'v': 779});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_779');
      expect(QLSliceRegistry.instance['slice_779'], isNull);
    });
    test('slice registry and plugins #0081', () {
      final slice =
          QLStoreSlice(namespace: 'slice_780', state: const {'count': 780});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_780']?.state['count'], 780);
    });
    test('slice registry and plugins #0082', () {
      final slice =
          QLStoreSlice(namespace: 'slice_781', state: const {'title': 't781'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_781').get('title'), 't781');
    });
    test('slice registry and plugins #0083', () async {
      final slice = QLStoreSlice(namespace: 'slice_782', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_782');
      store.set('value', 782);
      await _flush();
      expect(store.get('mirror'), 782);
    });
    test('slice registry and plugins #0084', () async {
      final slice = QLStoreSlice(namespace: 'slice_783', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_783.bump']!;
      final store = QLStoreRegistry.instance.get('slice_783');
      store.set('count', 783);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 784);
    });
    test('slice registry and plugins #0085', () async {
      final slice = QLStoreSlice(namespace: 'slice_784', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_784.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_784');
      store.set('count', 784);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 784);
    });
    test('slice registry and plugins #0086', () async {
      final slice = QLStoreSlice(namespace: 'slice_785', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_785.setName']!;
      final store = QLStoreRegistry.instance.get('slice_785');
      await plugin
          .execute(const {'value': 'name-785'}, store, const QLNullContext());
      expect(store.get('name'), 'name-785');
    });
    test('slice registry and plugins #0087', () async {
      final slice = QLStoreSlice(namespace: 'slice_786', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_786.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_786');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0088', () async {
      final slice = QLStoreSlice(namespace: 'slice_787', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_787.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_787');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0089', () async {
      final slice = QLStoreSlice(namespace: 'slice_788', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_788.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_788');
      store.set('a', 788);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 788);
    });
    test('slice registry and plugins #0090', () {
      final slice =
          QLStoreSlice(namespace: 'slice_789', state: const {'v': 789});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_789');
      expect(QLSliceRegistry.instance['slice_789'], isNull);
    });
    test('slice registry and plugins #0091', () {
      final slice =
          QLStoreSlice(namespace: 'slice_790', state: const {'count': 790});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_790']?.state['count'], 790);
    });
    test('slice registry and plugins #0092', () {
      final slice =
          QLStoreSlice(namespace: 'slice_791', state: const {'title': 't791'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_791').get('title'), 't791');
    });
    test('slice registry and plugins #0093', () async {
      final slice = QLStoreSlice(namespace: 'slice_792', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_792');
      store.set('value', 792);
      await _flush();
      expect(store.get('mirror'), 792);
    });
    test('slice registry and plugins #0094', () async {
      final slice = QLStoreSlice(namespace: 'slice_793', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_793.bump']!;
      final store = QLStoreRegistry.instance.get('slice_793');
      store.set('count', 793);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 794);
    });
    test('slice registry and plugins #0095', () async {
      final slice = QLStoreSlice(namespace: 'slice_794', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_794.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_794');
      store.set('count', 794);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 794);
    });
    test('slice registry and plugins #0096', () async {
      final slice = QLStoreSlice(namespace: 'slice_795', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_795.setName']!;
      final store = QLStoreRegistry.instance.get('slice_795');
      await plugin
          .execute(const {'value': 'name-795'}, store, const QLNullContext());
      expect(store.get('name'), 'name-795');
    });
    test('slice registry and plugins #0097', () async {
      final slice = QLStoreSlice(namespace: 'slice_796', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_796.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_796');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0098', () async {
      final slice = QLStoreSlice(namespace: 'slice_797', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_797.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_797');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0099', () async {
      final slice = QLStoreSlice(namespace: 'slice_798', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_798.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_798');
      store.set('a', 798);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 798);
    });
    test('slice registry and plugins #0100', () {
      final slice =
          QLStoreSlice(namespace: 'slice_799', state: const {'v': 799});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_799');
      expect(QLSliceRegistry.instance['slice_799'], isNull);
    });
    test('slice registry and plugins #0101', () {
      final slice =
          QLStoreSlice(namespace: 'slice_800', state: const {'count': 800});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_800']?.state['count'], 800);
    });
    test('slice registry and plugins #0102', () {
      final slice =
          QLStoreSlice(namespace: 'slice_801', state: const {'title': 't801'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_801').get('title'), 't801');
    });
    test('slice registry and plugins #0103', () async {
      final slice = QLStoreSlice(namespace: 'slice_802', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_802');
      store.set('value', 802);
      await _flush();
      expect(store.get('mirror'), 802);
    });
    test('slice registry and plugins #0104', () async {
      final slice = QLStoreSlice(namespace: 'slice_803', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_803.bump']!;
      final store = QLStoreRegistry.instance.get('slice_803');
      store.set('count', 803);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 804);
    });
    test('slice registry and plugins #0105', () async {
      final slice = QLStoreSlice(namespace: 'slice_804', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_804.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_804');
      store.set('count', 804);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 804);
    });
    test('slice registry and plugins #0106', () async {
      final slice = QLStoreSlice(namespace: 'slice_805', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_805.setName']!;
      final store = QLStoreRegistry.instance.get('slice_805');
      await plugin
          .execute(const {'value': 'name-805'}, store, const QLNullContext());
      expect(store.get('name'), 'name-805');
    });
    test('slice registry and plugins #0107', () async {
      final slice = QLStoreSlice(namespace: 'slice_806', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_806.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_806');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0108', () async {
      final slice = QLStoreSlice(namespace: 'slice_807', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_807.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_807');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0109', () async {
      final slice = QLStoreSlice(namespace: 'slice_808', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_808.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_808');
      store.set('a', 808);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 808);
    });
    test('slice registry and plugins #0110', () {
      final slice =
          QLStoreSlice(namespace: 'slice_809', state: const {'v': 809});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_809');
      expect(QLSliceRegistry.instance['slice_809'], isNull);
    });
    test('slice registry and plugins #0111', () {
      final slice =
          QLStoreSlice(namespace: 'slice_810', state: const {'count': 810});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_810']?.state['count'], 810);
    });
    test('slice registry and plugins #0112', () {
      final slice =
          QLStoreSlice(namespace: 'slice_811', state: const {'title': 't811'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_811').get('title'), 't811');
    });
    test('slice registry and plugins #0113', () async {
      final slice = QLStoreSlice(namespace: 'slice_812', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_812');
      store.set('value', 812);
      await _flush();
      expect(store.get('mirror'), 812);
    });
    test('slice registry and plugins #0114', () async {
      final slice = QLStoreSlice(namespace: 'slice_813', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_813.bump']!;
      final store = QLStoreRegistry.instance.get('slice_813');
      store.set('count', 813);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 814);
    });
    test('slice registry and plugins #0115', () async {
      final slice = QLStoreSlice(namespace: 'slice_814', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_814.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_814');
      store.set('count', 814);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 814);
    });
    test('slice registry and plugins #0116', () async {
      final slice = QLStoreSlice(namespace: 'slice_815', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_815.setName']!;
      final store = QLStoreRegistry.instance.get('slice_815');
      await plugin
          .execute(const {'value': 'name-815'}, store, const QLNullContext());
      expect(store.get('name'), 'name-815');
    });
    test('slice registry and plugins #0117', () async {
      final slice = QLStoreSlice(namespace: 'slice_816', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_816.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_816');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0118', () async {
      final slice = QLStoreSlice(namespace: 'slice_817', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_817.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_817');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0119', () async {
      final slice = QLStoreSlice(namespace: 'slice_818', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_818.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_818');
      store.set('a', 818);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 818);
    });
    test('slice registry and plugins #0120', () {
      final slice =
          QLStoreSlice(namespace: 'slice_819', state: const {'v': 819});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_819');
      expect(QLSliceRegistry.instance['slice_819'], isNull);
    });
    test('slice registry and plugins #0121', () {
      final slice =
          QLStoreSlice(namespace: 'slice_820', state: const {'count': 820});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_820']?.state['count'], 820);
    });
    test('slice registry and plugins #0122', () {
      final slice =
          QLStoreSlice(namespace: 'slice_821', state: const {'title': 't821'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_821').get('title'), 't821');
    });
    test('slice registry and plugins #0123', () async {
      final slice = QLStoreSlice(namespace: 'slice_822', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_822');
      store.set('value', 822);
      await _flush();
      expect(store.get('mirror'), 822);
    });
    test('slice registry and plugins #0124', () async {
      final slice = QLStoreSlice(namespace: 'slice_823', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_823.bump']!;
      final store = QLStoreRegistry.instance.get('slice_823');
      store.set('count', 823);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 824);
    });
    test('slice registry and plugins #0125', () async {
      final slice = QLStoreSlice(namespace: 'slice_824', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_824.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_824');
      store.set('count', 824);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 824);
    });
    test('slice registry and plugins #0126', () async {
      final slice = QLStoreSlice(namespace: 'slice_825', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_825.setName']!;
      final store = QLStoreRegistry.instance.get('slice_825');
      await plugin
          .execute(const {'value': 'name-825'}, store, const QLNullContext());
      expect(store.get('name'), 'name-825');
    });
    test('slice registry and plugins #0127', () async {
      final slice = QLStoreSlice(namespace: 'slice_826', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_826.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_826');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0128', () async {
      final slice = QLStoreSlice(namespace: 'slice_827', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_827.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_827');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0129', () async {
      final slice = QLStoreSlice(namespace: 'slice_828', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_828.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_828');
      store.set('a', 828);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 828);
    });
    test('slice registry and plugins #0130', () {
      final slice =
          QLStoreSlice(namespace: 'slice_829', state: const {'v': 829});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_829');
      expect(QLSliceRegistry.instance['slice_829'], isNull);
    });
    test('slice registry and plugins #0131', () {
      final slice =
          QLStoreSlice(namespace: 'slice_830', state: const {'count': 830});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_830']?.state['count'], 830);
    });
    test('slice registry and plugins #0132', () {
      final slice =
          QLStoreSlice(namespace: 'slice_831', state: const {'title': 't831'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_831').get('title'), 't831');
    });
    test('slice registry and plugins #0133', () async {
      final slice = QLStoreSlice(namespace: 'slice_832', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_832');
      store.set('value', 832);
      await _flush();
      expect(store.get('mirror'), 832);
    });
    test('slice registry and plugins #0134', () async {
      final slice = QLStoreSlice(namespace: 'slice_833', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_833.bump']!;
      final store = QLStoreRegistry.instance.get('slice_833');
      store.set('count', 833);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 834);
    });
    test('slice registry and plugins #0135', () async {
      final slice = QLStoreSlice(namespace: 'slice_834', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_834.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_834');
      store.set('count', 834);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 834);
    });
    test('slice registry and plugins #0136', () async {
      final slice = QLStoreSlice(namespace: 'slice_835', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_835.setName']!;
      final store = QLStoreRegistry.instance.get('slice_835');
      await plugin
          .execute(const {'value': 'name-835'}, store, const QLNullContext());
      expect(store.get('name'), 'name-835');
    });
    test('slice registry and plugins #0137', () async {
      final slice = QLStoreSlice(namespace: 'slice_836', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_836.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_836');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0138', () async {
      final slice = QLStoreSlice(namespace: 'slice_837', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_837.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_837');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0139', () async {
      final slice = QLStoreSlice(namespace: 'slice_838', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_838.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_838');
      store.set('a', 838);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 838);
    });
    test('slice registry and plugins #0140', () {
      final slice =
          QLStoreSlice(namespace: 'slice_839', state: const {'v': 839});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_839');
      expect(QLSliceRegistry.instance['slice_839'], isNull);
    });
    test('slice registry and plugins #0141', () {
      final slice =
          QLStoreSlice(namespace: 'slice_840', state: const {'count': 840});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance['slice_840']?.state['count'], 840);
    });
    test('slice registry and plugins #0142', () {
      final slice =
          QLStoreSlice(namespace: 'slice_841', state: const {'title': 't841'});
      QLSliceRegistry.instance.mount(slice);
      expect(QLStoreRegistry.instance.get('slice_841').get('title'), 't841');
    });
    test('slice registry and plugins #0143', () async {
      final slice = QLStoreSlice(namespace: 'slice_842', computed: const {
        'mirror': ['value']
      });
      QLSliceRegistry.instance.mount(slice);
      final store = QLStoreRegistry.instance.get('slice_842');
      store.set('value', 842);
      await _flush();
      expect(store.get('mirror'), 842);
    });
    test('slice registry and plugins #0144', () async {
      final slice = QLStoreSlice(namespace: 'slice_843', mutations: const {
        'bump': {'op': 'increment', 'key': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_843.bump']!;
      final store = QLStoreRegistry.instance.get('slice_843');
      store.set('count', 843);
      await plugin.execute(
          const {'path': 'count', 'by': 1}, store, const QLNullContext());
      expect(store.get('count'), 844);
    });
    test('slice registry and plugins #0145', () async {
      final slice = QLStoreSlice(namespace: 'slice_844', queries: const {
        'readCount': {'op': 'get', 'path': 'count'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_844.readCount']!;
      final store = QLStoreRegistry.instance.get('slice_844');
      store.set('count', 844);
      final result = await plugin
          .execute(const {'path': 'count'}, store, const QLNullContext());
      expect(result, 844);
    });
    test('slice registry and plugins #0146', () async {
      final slice = QLStoreSlice(namespace: 'slice_845', mutations: const {
        'setName': {'op': 'set', 'path': 'name'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_845.setName']!;
      final store = QLStoreRegistry.instance.get('slice_845');
      await plugin
          .execute(const {'value': 'name-845'}, store, const QLNullContext());
      expect(store.get('name'), 'name-845');
    });
    test('slice registry and plugins #0147', () async {
      final slice = QLStoreSlice(namespace: 'slice_846', mutations: const {
        'appendItem': {'op': 'append', 'path': 'items'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_846.appendItem']!;
      final store = QLStoreRegistry.instance.get('slice_846');
      store.set('items', [1, 2]);
      await plugin.execute(const {'value': 3}, store, const QLNullContext());
      expect(store.get('items'), [1, 2, 3]);
    });
    test('slice registry and plugins #0148', () async {
      final slice = QLStoreSlice(namespace: 'slice_847', mutations: const {
        'toggleFlag': {'op': 'toggle', 'path': 'flag'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_847.toggleFlag']!;
      final store = QLStoreRegistry.instance.get('slice_847');
      store.set('flag', false);
      await plugin.execute(const {}, store, const QLNullContext());
      expect(store.get('flag'), isTrue);
    });
    test('slice registry and plugins #0149', () async {
      final slice = QLStoreSlice(namespace: 'slice_848', queries: const {
        'snapshot': {'op': 'snapshot'}
      });
      QLSliceRegistry.instance.mount(slice);
      final plugin = capturedActions['slice_848.snapshot']!;
      final store = QLStoreRegistry.instance.get('slice_848');
      store.set('a', 848);
      final result =
          await plugin.execute(const {}, store, const QLNullContext());
      expect(result['a'], 848);
    });
    test('slice registry and plugins #0150', () {
      final slice =
          QLStoreSlice(namespace: 'slice_849', state: const {'v': 849});
      QLSliceRegistry.instance.mount(slice);
      expect(QLSliceRegistry.instance.snapshot()['namespaces'], isNotEmpty);
      QLSliceRegistry.instance.unmount('slice_849');
      expect(QLSliceRegistry.instance['slice_849'], isNull);
    });
  });

  group('data-source registry', () {
    test('data-source registry #0001', () async {
      final store = QLStoreRegistry.instance.get('ds_850');
      QLDataSourceRegistry.instance.register('source_850', const {
        'type': 'api',
        'initial': {'v': 850}
      });
      final handle = QLDataSourceRegistry.instance.get('source_850')!;
      handle.signal.data.setSilent({'v': 850});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_850',
        store: store,
        sourceName: 'source_850',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 850);
      cancel();
    });
    test('data-source registry #0002', () {
      final store = QLStoreRegistry.instance.get('ds_851');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_851',
        store: store,
        sourceName: 'missing_851',
        statePath: 'fallback',
        defaultValue: 'fallback-851',
      );
      expect(store.get('fallback'), 'fallback-851');
      cancel();
    });
    test('data-source registry #0003', () async {
      final store = QLStoreRegistry.instance.get('ds_852');
      QLDataSourceRegistry.instance
          .register('source_852', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_852')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u852'},
        'meta': 852
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_852',
        store: store,
        sourceName: 'source_852',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u852');
    });
    test('data-source registry #0004', () async {
      final store = QLStoreRegistry.instance.get('ds_853');
      QLDataSourceRegistry.instance
          .register('source_853', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_853')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 853]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_853',
        store: store,
        sourceName: 'source_853',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 853]);
    });
    test('data-source registry #0005', () async {
      final store = QLStoreRegistry.instance.get('ds_854');
      QLDataSourceRegistry.instance
          .register('source_854', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_854')!;
      handle.signal.data.setSilent({'path': 'p854', 'label': 'l854'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_854',
        store: store,
        sourceName: 'source_854',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p854');
    });
    test('data-source registry #0006', () async {
      final store = QLStoreRegistry.instance.get('ds_855');
      QLDataSourceRegistry.instance.register('source_855', const {
        'type': 'api',
        'initial': {'v': 855}
      });
      final handle = QLDataSourceRegistry.instance.get('source_855')!;
      handle.signal.data.setSilent({'v': 855});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_855',
        store: store,
        sourceName: 'source_855',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 855);
      cancel();
    });
    test('data-source registry #0007', () {
      final store = QLStoreRegistry.instance.get('ds_856');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_856',
        store: store,
        sourceName: 'missing_856',
        statePath: 'fallback',
        defaultValue: 'fallback-856',
      );
      expect(store.get('fallback'), 'fallback-856');
      cancel();
    });
    test('data-source registry #0008', () async {
      final store = QLStoreRegistry.instance.get('ds_857');
      QLDataSourceRegistry.instance
          .register('source_857', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_857')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u857'},
        'meta': 857
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_857',
        store: store,
        sourceName: 'source_857',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u857');
    });
    test('data-source registry #0009', () async {
      final store = QLStoreRegistry.instance.get('ds_858');
      QLDataSourceRegistry.instance
          .register('source_858', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_858')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 858]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_858',
        store: store,
        sourceName: 'source_858',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 858]);
    });
    test('data-source registry #0010', () async {
      final store = QLStoreRegistry.instance.get('ds_859');
      QLDataSourceRegistry.instance
          .register('source_859', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_859')!;
      handle.signal.data.setSilent({'path': 'p859', 'label': 'l859'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_859',
        store: store,
        sourceName: 'source_859',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p859');
    });
    test('data-source registry #0011', () async {
      final store = QLStoreRegistry.instance.get('ds_860');
      QLDataSourceRegistry.instance.register('source_860', const {
        'type': 'api',
        'initial': {'v': 860}
      });
      final handle = QLDataSourceRegistry.instance.get('source_860')!;
      handle.signal.data.setSilent({'v': 860});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_860',
        store: store,
        sourceName: 'source_860',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 860);
      cancel();
    });
    test('data-source registry #0012', () {
      final store = QLStoreRegistry.instance.get('ds_861');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_861',
        store: store,
        sourceName: 'missing_861',
        statePath: 'fallback',
        defaultValue: 'fallback-861',
      );
      expect(store.get('fallback'), 'fallback-861');
      cancel();
    });
    test('data-source registry #0013', () async {
      final store = QLStoreRegistry.instance.get('ds_862');
      QLDataSourceRegistry.instance
          .register('source_862', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_862')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u862'},
        'meta': 862
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_862',
        store: store,
        sourceName: 'source_862',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u862');
    });
    test('data-source registry #0014', () async {
      final store = QLStoreRegistry.instance.get('ds_863');
      QLDataSourceRegistry.instance
          .register('source_863', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_863')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 863]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_863',
        store: store,
        sourceName: 'source_863',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 863]);
    });
    test('data-source registry #0015', () async {
      final store = QLStoreRegistry.instance.get('ds_864');
      QLDataSourceRegistry.instance
          .register('source_864', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_864')!;
      handle.signal.data.setSilent({'path': 'p864', 'label': 'l864'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_864',
        store: store,
        sourceName: 'source_864',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p864');
    });
    test('data-source registry #0016', () async {
      final store = QLStoreRegistry.instance.get('ds_865');
      QLDataSourceRegistry.instance.register('source_865', const {
        'type': 'api',
        'initial': {'v': 865}
      });
      final handle = QLDataSourceRegistry.instance.get('source_865')!;
      handle.signal.data.setSilent({'v': 865});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_865',
        store: store,
        sourceName: 'source_865',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 865);
      cancel();
    });
    test('data-source registry #0017', () {
      final store = QLStoreRegistry.instance.get('ds_866');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_866',
        store: store,
        sourceName: 'missing_866',
        statePath: 'fallback',
        defaultValue: 'fallback-866',
      );
      expect(store.get('fallback'), 'fallback-866');
      cancel();
    });
    test('data-source registry #0018', () async {
      final store = QLStoreRegistry.instance.get('ds_867');
      QLDataSourceRegistry.instance
          .register('source_867', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_867')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u867'},
        'meta': 867
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_867',
        store: store,
        sourceName: 'source_867',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u867');
    });
    test('data-source registry #0019', () async {
      final store = QLStoreRegistry.instance.get('ds_868');
      QLDataSourceRegistry.instance
          .register('source_868', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_868')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 868]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_868',
        store: store,
        sourceName: 'source_868',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 868]);
    });
    test('data-source registry #0020', () async {
      final store = QLStoreRegistry.instance.get('ds_869');
      QLDataSourceRegistry.instance
          .register('source_869', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_869')!;
      handle.signal.data.setSilent({'path': 'p869', 'label': 'l869'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_869',
        store: store,
        sourceName: 'source_869',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p869');
    });
    test('data-source registry #0021', () async {
      final store = QLStoreRegistry.instance.get('ds_870');
      QLDataSourceRegistry.instance.register('source_870', const {
        'type': 'api',
        'initial': {'v': 870}
      });
      final handle = QLDataSourceRegistry.instance.get('source_870')!;
      handle.signal.data.setSilent({'v': 870});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_870',
        store: store,
        sourceName: 'source_870',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 870);
      cancel();
    });
    test('data-source registry #0022', () {
      final store = QLStoreRegistry.instance.get('ds_871');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_871',
        store: store,
        sourceName: 'missing_871',
        statePath: 'fallback',
        defaultValue: 'fallback-871',
      );
      expect(store.get('fallback'), 'fallback-871');
      cancel();
    });
    test('data-source registry #0023', () async {
      final store = QLStoreRegistry.instance.get('ds_872');
      QLDataSourceRegistry.instance
          .register('source_872', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_872')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u872'},
        'meta': 872
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_872',
        store: store,
        sourceName: 'source_872',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u872');
    });
    test('data-source registry #0024', () async {
      final store = QLStoreRegistry.instance.get('ds_873');
      QLDataSourceRegistry.instance
          .register('source_873', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_873')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 873]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_873',
        store: store,
        sourceName: 'source_873',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 873]);
    });
    test('data-source registry #0025', () async {
      final store = QLStoreRegistry.instance.get('ds_874');
      QLDataSourceRegistry.instance
          .register('source_874', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_874')!;
      handle.signal.data.setSilent({'path': 'p874', 'label': 'l874'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_874',
        store: store,
        sourceName: 'source_874',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p874');
    });
    test('data-source registry #0026', () async {
      final store = QLStoreRegistry.instance.get('ds_875');
      QLDataSourceRegistry.instance.register('source_875', const {
        'type': 'api',
        'initial': {'v': 875}
      });
      final handle = QLDataSourceRegistry.instance.get('source_875')!;
      handle.signal.data.setSilent({'v': 875});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_875',
        store: store,
        sourceName: 'source_875',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 875);
      cancel();
    });
    test('data-source registry #0027', () {
      final store = QLStoreRegistry.instance.get('ds_876');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_876',
        store: store,
        sourceName: 'missing_876',
        statePath: 'fallback',
        defaultValue: 'fallback-876',
      );
      expect(store.get('fallback'), 'fallback-876');
      cancel();
    });
    test('data-source registry #0028', () async {
      final store = QLStoreRegistry.instance.get('ds_877');
      QLDataSourceRegistry.instance
          .register('source_877', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_877')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u877'},
        'meta': 877
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_877',
        store: store,
        sourceName: 'source_877',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u877');
    });
    test('data-source registry #0029', () async {
      final store = QLStoreRegistry.instance.get('ds_878');
      QLDataSourceRegistry.instance
          .register('source_878', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_878')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 878]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_878',
        store: store,
        sourceName: 'source_878',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 878]);
    });
    test('data-source registry #0030', () async {
      final store = QLStoreRegistry.instance.get('ds_879');
      QLDataSourceRegistry.instance
          .register('source_879', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_879')!;
      handle.signal.data.setSilent({'path': 'p879', 'label': 'l879'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_879',
        store: store,
        sourceName: 'source_879',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p879');
    });
    test('data-source registry #0031', () async {
      final store = QLStoreRegistry.instance.get('ds_880');
      QLDataSourceRegistry.instance.register('source_880', const {
        'type': 'api',
        'initial': {'v': 880}
      });
      final handle = QLDataSourceRegistry.instance.get('source_880')!;
      handle.signal.data.setSilent({'v': 880});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_880',
        store: store,
        sourceName: 'source_880',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 880);
      cancel();
    });
    test('data-source registry #0032', () {
      final store = QLStoreRegistry.instance.get('ds_881');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_881',
        store: store,
        sourceName: 'missing_881',
        statePath: 'fallback',
        defaultValue: 'fallback-881',
      );
      expect(store.get('fallback'), 'fallback-881');
      cancel();
    });
    test('data-source registry #0033', () async {
      final store = QLStoreRegistry.instance.get('ds_882');
      QLDataSourceRegistry.instance
          .register('source_882', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_882')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u882'},
        'meta': 882
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_882',
        store: store,
        sourceName: 'source_882',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u882');
    });
    test('data-source registry #0034', () async {
      final store = QLStoreRegistry.instance.get('ds_883');
      QLDataSourceRegistry.instance
          .register('source_883', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_883')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 883]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_883',
        store: store,
        sourceName: 'source_883',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 883]);
    });
    test('data-source registry #0035', () async {
      final store = QLStoreRegistry.instance.get('ds_884');
      QLDataSourceRegistry.instance
          .register('source_884', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_884')!;
      handle.signal.data.setSilent({'path': 'p884', 'label': 'l884'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_884',
        store: store,
        sourceName: 'source_884',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p884');
    });
    test('data-source registry #0036', () async {
      final store = QLStoreRegistry.instance.get('ds_885');
      QLDataSourceRegistry.instance.register('source_885', const {
        'type': 'api',
        'initial': {'v': 885}
      });
      final handle = QLDataSourceRegistry.instance.get('source_885')!;
      handle.signal.data.setSilent({'v': 885});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_885',
        store: store,
        sourceName: 'source_885',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 885);
      cancel();
    });
    test('data-source registry #0037', () {
      final store = QLStoreRegistry.instance.get('ds_886');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_886',
        store: store,
        sourceName: 'missing_886',
        statePath: 'fallback',
        defaultValue: 'fallback-886',
      );
      expect(store.get('fallback'), 'fallback-886');
      cancel();
    });
    test('data-source registry #0038', () async {
      final store = QLStoreRegistry.instance.get('ds_887');
      QLDataSourceRegistry.instance
          .register('source_887', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_887')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u887'},
        'meta': 887
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_887',
        store: store,
        sourceName: 'source_887',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u887');
    });
    test('data-source registry #0039', () async {
      final store = QLStoreRegistry.instance.get('ds_888');
      QLDataSourceRegistry.instance
          .register('source_888', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_888')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 888]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_888',
        store: store,
        sourceName: 'source_888',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 888]);
    });
    test('data-source registry #0040', () async {
      final store = QLStoreRegistry.instance.get('ds_889');
      QLDataSourceRegistry.instance
          .register('source_889', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_889')!;
      handle.signal.data.setSilent({'path': 'p889', 'label': 'l889'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_889',
        store: store,
        sourceName: 'source_889',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p889');
    });
    test('data-source registry #0041', () async {
      final store = QLStoreRegistry.instance.get('ds_890');
      QLDataSourceRegistry.instance.register('source_890', const {
        'type': 'api',
        'initial': {'v': 890}
      });
      final handle = QLDataSourceRegistry.instance.get('source_890')!;
      handle.signal.data.setSilent({'v': 890});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_890',
        store: store,
        sourceName: 'source_890',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 890);
      cancel();
    });
    test('data-source registry #0042', () {
      final store = QLStoreRegistry.instance.get('ds_891');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_891',
        store: store,
        sourceName: 'missing_891',
        statePath: 'fallback',
        defaultValue: 'fallback-891',
      );
      expect(store.get('fallback'), 'fallback-891');
      cancel();
    });
    test('data-source registry #0043', () async {
      final store = QLStoreRegistry.instance.get('ds_892');
      QLDataSourceRegistry.instance
          .register('source_892', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_892')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u892'},
        'meta': 892
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_892',
        store: store,
        sourceName: 'source_892',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u892');
    });
    test('data-source registry #0044', () async {
      final store = QLStoreRegistry.instance.get('ds_893');
      QLDataSourceRegistry.instance
          .register('source_893', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_893')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 893]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_893',
        store: store,
        sourceName: 'source_893',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 893]);
    });
    test('data-source registry #0045', () async {
      final store = QLStoreRegistry.instance.get('ds_894');
      QLDataSourceRegistry.instance
          .register('source_894', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_894')!;
      handle.signal.data.setSilent({'path': 'p894', 'label': 'l894'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_894',
        store: store,
        sourceName: 'source_894',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p894');
    });
    test('data-source registry #0046', () async {
      final store = QLStoreRegistry.instance.get('ds_895');
      QLDataSourceRegistry.instance.register('source_895', const {
        'type': 'api',
        'initial': {'v': 895}
      });
      final handle = QLDataSourceRegistry.instance.get('source_895')!;
      handle.signal.data.setSilent({'v': 895});
      handle.signal.data.forceNotify();
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_895',
        store: store,
        sourceName: 'source_895',
        sourcePath: 'v',
        statePath: 'v',
      );
      await _flush();
      expect(store.get('v'), 895);
      cancel();
    });
    test('data-source registry #0047', () {
      final store = QLStoreRegistry.instance.get('ds_896');
      final cancel = QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_896',
        store: store,
        sourceName: 'missing_896',
        statePath: 'fallback',
        defaultValue: 'fallback-896',
      );
      expect(store.get('fallback'), 'fallback-896');
      cancel();
    });
    test('data-source registry #0048', () async {
      final store = QLStoreRegistry.instance.get('ds_897');
      QLDataSourceRegistry.instance
          .register('source_897', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_897')!;
      handle.signal.data.setSilent({
        'user': {'name': 'u897'},
        'meta': 897
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_897',
        store: store,
        sourceName: 'source_897',
        sourcePath: 'user',
        statePath: 'profile',
        merge: 'mergeMap',
      );
      await _flush();
      expect(store.get('profile.name'), 'u897');
    });
    test('data-source registry #0049', () async {
      final store = QLStoreRegistry.instance.get('ds_898');
      QLDataSourceRegistry.instance
          .register('source_898', const {'type': 'api'});
      final handle = QLDataSourceRegistry.instance.get('source_898')!;
      handle.signal.data.setSilent({
        'items': [1, 2, 898]
      });
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_898',
        store: store,
        sourceName: 'source_898',
        sourcePath: 'items',
        statePath: 'items',
        merge: 'replace',
      );
      await _flush();
      expect(store.get('items'), [1, 2, 898]);
    });
    test('data-source registry #0050', () async {
      final store = QLStoreRegistry.instance.get('ds_899');
      QLDataSourceRegistry.instance
          .register('source_899', const {'type': 'file', 'smartSelect': true});
      final handle = QLDataSourceRegistry.instance.get('source_899')!;
      handle.signal.data.setSilent({'path': 'p899', 'label': 'l899'});
      handle.signal.data.forceNotify();
      QLDataSourceRegistry.instance.attachStateBinding(
        namespace: 'ds_899',
        store: store,
        sourceName: 'source_899',
        statePath: 'current',
        transform: 'identity',
        select: const ['path', 'label'],
      );
      await _flush();
      expect(store.get('current.path'), 'p899');
    });
  });

  group('module policy and lazy schema', () {
    test('module policy and lazy schema #0001', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0002', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0003', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user902'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user902'),
          isTrue);
    });
    test('module policy and lazy schema #0004', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0005', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0006', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0007', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0008', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user907'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user907'),
          isTrue);
    });
    test('module policy and lazy schema #0009', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0010', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0011', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0012', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0013', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user912'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user912'),
          isTrue);
    });
    test('module policy and lazy schema #0014', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0015', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0016', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0017', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0018', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user917'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user917'),
          isTrue);
    });
    test('module policy and lazy schema #0019', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0020', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0021', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0022', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0023', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user922'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user922'),
          isTrue);
    });
    test('module policy and lazy schema #0024', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0025', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0026', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0027', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0028', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user927'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user927'),
          isTrue);
    });
    test('module policy and lazy schema #0029', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0030', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0031', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0032', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0033', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user932'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user932'),
          isTrue);
    });
    test('module policy and lazy schema #0034', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0035', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
    test('module policy and lazy schema #0036', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'public'});
      expect(policy.allows(requester: 'a', target: 'b'), isTrue);
    });
    test('module policy and lazy schema #0037', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'local'});
      expect(policy.allows(requester: 'team.one', target: 'team.two'), isTrue);
    });
    test('module policy and lazy schema #0038', () {
      final policy = QLModuleAccessPolicy.from(
          const {'visibility': 'owner', 'owner': 'user937'});
      expect(policy.allows(requester: 'a', target: 'b', ownerId: 'user937'),
          isTrue);
    });
    test('module policy and lazy schema #0039', () {
      final policy = QLModuleAccessPolicy.from(const {'visibility': 'secure'});
      expect(policy.allows(requester: 'a', target: 'b'), isFalse);
    });
    test('module policy and lazy schema #0040', () {
      final policy = QLModuleAccessPolicy.from(const {
        'allow': ['*']
      });
      expect(policy.allows(requester: 'any', target: 'other'), isTrue);
    });
  });

  group('signal proxy and batch', () {
    test('signal proxy and batch #0001', () {
      final source = QLSignal<int>(940);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      expect(proxy.value, 'v940');
    });
    test('signal proxy and batch #0002', () {
      final source = QLSignal<int>(941);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      proxy.value = 'v942';
      expect(source.value, 942);
    });
    test('signal proxy and batch #0003', () {
      final signal = QLSignal<int>(0);
      var notified = 0;
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        signal.setSilent(942);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('signal proxy and batch #0004', () {
      final signal = QLSignal<int>(943);
      expect(signal.value, 943);
    });
    test('signal proxy and batch #0005', () {
      final source = QLSignal<int>(944);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      expect(proxy.value, 'v944');
    });
    test('signal proxy and batch #0006', () {
      final source = QLSignal<int>(945);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      proxy.value = 'v946';
      expect(source.value, 946);
    });
    test('signal proxy and batch #0007', () {
      final signal = QLSignal<int>(0);
      var notified = 0;
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        signal.setSilent(946);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('signal proxy and batch #0008', () {
      final signal = QLSignal<int>(947);
      expect(signal.value, 947);
    });
    test('signal proxy and batch #0009', () {
      final source = QLSignal<int>(948);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      expect(proxy.value, 'v948');
    });
    test('signal proxy and batch #0010', () {
      final source = QLSignal<int>(949);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      proxy.value = 'v950';
      expect(source.value, 950);
    });
    test('signal proxy and batch #0011', () {
      final signal = QLSignal<int>(0);
      var notified = 0;
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        signal.setSilent(950);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('signal proxy and batch #0012', () {
      final signal = QLSignal<int>(951);
      expect(signal.value, 951);
    });
    test('signal proxy and batch #0013', () {
      final source = QLSignal<int>(952);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      expect(proxy.value, 'v952');
    });
    test('signal proxy and batch #0014', () {
      final source = QLSignal<int>(953);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      proxy.value = 'v954';
      expect(source.value, 954);
    });
    test('signal proxy and batch #0015', () {
      final signal = QLSignal<int>(0);
      var notified = 0;
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        signal.setSilent(954);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('signal proxy and batch #0016', () {
      final signal = QLSignal<int>(955);
      expect(signal.value, 955);
    });
    test('signal proxy and batch #0017', () {
      final source = QLSignal<int>(956);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      expect(proxy.value, 'v956');
    });
    test('signal proxy and batch #0018', () {
      final source = QLSignal<int>(957);
      final proxy = QLSignalProxy<String>(source, (value) => 'v$value',
          (value) => int.parse(value.substring(1)));
      proxy.value = 'v958';
      expect(source.value, 958);
    });
    test('signal proxy and batch #0019', () {
      final signal = QLSignal<int>(0);
      var notified = 0;
      signal.addListener(() => notified++);
      QLSignalBatch.run(() {
        signal.setSilent(958);
        QLSignalBatch.enqueue(signal);
      });
      expect(notified, 1);
    });
    test('signal proxy and batch #0020', () {
      final signal = QLSignal<int>(959);
      expect(signal.value, 959);
    });
  });

  group('regressions', () {
    test('regressions #0001', () {
      final store = QLStoreRegistry.instance.get('reg_960');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0002', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0003', () {
      final store = QLStoreRegistry.instance.get('reg_962');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0004', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
    test('regressions #0005', () {
      final store = QLStoreRegistry.instance.get('reg_964');
      store.sweep('unknown');
      expect(store.signalCount, 0);
    });
    test('regressions #0006', () {
      final store = QLStoreRegistry.instance.get('reg_965');
      store.set('a', 965);
      store.set('a', 965);
      expect(store.get('a'), 965);
    });
    test('regressions #0007', () {
      final store = QLStoreRegistry.instance.get('reg_966');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0008', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0009', () {
      final store = QLStoreRegistry.instance.get('reg_968');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0010', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
    test('regressions #0011', () {
      final store = QLStoreRegistry.instance.get('reg_970');
      store.sweep('unknown');
      expect(store.signalCount, 0);
    });
    test('regressions #0012', () {
      final store = QLStoreRegistry.instance.get('reg_971');
      store.set('a', 971);
      store.set('a', 971);
      expect(store.get('a'), 971);
    });
    test('regressions #0013', () {
      final store = QLStoreRegistry.instance.get('reg_972');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0014', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0015', () {
      final store = QLStoreRegistry.instance.get('reg_974');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0016', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
    test('regressions #0017', () {
      final store = QLStoreRegistry.instance.get('reg_976');
      store.sweep('unknown');
      expect(store.signalCount, 0);
    });
    test('regressions #0018', () {
      final store = QLStoreRegistry.instance.get('reg_977');
      store.set('a', 977);
      store.set('a', 977);
      expect(store.get('a'), 977);
    });
    test('regressions #0019', () {
      final store = QLStoreRegistry.instance.get('reg_978');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0020', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0021', () {
      final store = QLStoreRegistry.instance.get('reg_980');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0022', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
    test('regressions #0023', () {
      final store = QLStoreRegistry.instance.get('reg_982');
      store.sweep('unknown');
      expect(store.signalCount, 0);
    });
    test('regressions #0024', () {
      final store = QLStoreRegistry.instance.get('reg_983');
      store.set('a', 983);
      store.set('a', 983);
      expect(store.get('a'), 983);
    });
    test('regressions #0025', () {
      final store = QLStoreRegistry.instance.get('reg_984');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0026', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0027', () {
      final store = QLStoreRegistry.instance.get('reg_986');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0028', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
    test('regressions #0029', () {
      final store = QLStoreRegistry.instance.get('reg_988');
      store.sweep('unknown');
      expect(store.signalCount, 0);
    });
    test('regressions #0030', () {
      final store = QLStoreRegistry.instance.get('reg_989');
      store.set('a', 989);
      store.set('a', 989);
      expect(store.get('a'), 989);
    });
    test('regressions #0031', () {
      final store = QLStoreRegistry.instance.get('reg_990');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0032', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0033', () {
      final store = QLStoreRegistry.instance.get('reg_992');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0034', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
    test('regressions #0035', () {
      final store = QLStoreRegistry.instance.get('reg_994');
      store.sweep('unknown');
      expect(store.signalCount, 0);
    });
    test('regressions #0036', () {
      final store = QLStoreRegistry.instance.get('reg_995');
      store.set('a', 995);
      store.set('a', 995);
      expect(store.get('a'), 995);
    });
    test('regressions #0037', () {
      final store = QLStoreRegistry.instance.get('reg_996');
      expect(store.get('missing'), isNull);
    });
    test('regressions #0038', () {
      final cache = QLRuntimeCache<int>();
      expect(cache.get('nope'), isNull);
    });
    test('regressions #0039', () {
      final store = QLStoreRegistry.instance.get('reg_998');
      store.rollback();
      expect(store.snapshot.isEmpty, isTrue);
    });
    test('regressions #0040', () {
      expect(QLRuntimeSupport.safeString(1234), '1234');
    });
  });
}
