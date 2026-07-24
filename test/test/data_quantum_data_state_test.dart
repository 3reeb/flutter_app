import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_layout/quantum.dart';

import 'support/test_helpers.dart';

void main() {
  setUp(resetQuantumRuntime);

  test('QLDataStore stores nested paths and computed values', () async {
    final store = QLDataStore(namespace: 'unit');
    store.set('user.name', 'Ada');
    store.set('cart.items[0].title', 'Notebook');
    expect(store.get('user.name'), 'Ada');
    expect(store.get('cart.items[0].title'), 'Notebook');

    store.set('a', 2);
    store.set('b', 3);
    store.registerComputed(
        'sum', ['a', 'b'], (values) => (values[0] as num) + (values[1] as num));
    await Future<void>.delayed(Duration.zero);
    expect(store.get('sum'), 5);

    store.transaction(() {
      store.set('a', 10);
      store.set('b', 5);
    });
    await Future<void>.delayed(Duration.zero);
    expect(store.get('sum'), 15);
  });

  test('QLDataStore recalculates chained computed paths', () async {
    final store = QLDataStore(namespace: 'chain');
    store.set('base', 4);
    store.registerComputed(
        'doubleBase', ['base'], (values) => (values[0] as num) * 2);
    store.registerComputed(
        'tripleBase', ['doubleBase'], (values) => (values[0] as num) + 4);
    await Future<void>.delayed(Duration.zero);
    expect(store.get('doubleBase'), 8);
    expect(store.get('tripleBase'), 12);

    store.set('base', 5);
    await Future<void>.delayed(Duration.zero);
    expect(store.get('doubleBase'), 10);
    expect(store.get('tripleBase'), 14);
  });

  test('QLDataStore rollback restores a saved snapshot', () async {
    final store = QLDataStore(namespace: 'history');
    store.set('counter', 1);
    store.saveSnapshot();
    store.set('counter', 99);
    store.rollback();
    await Future<void>.delayed(Duration.zero);
    expect(store.get('counter'), 1);
  });

  test('QLDataStore transaction applies nested mutations atomically', () async {
    final store = QLDataStore(namespace: 'txn');
    store.transaction(() {
      store.set('meta.title', 'Alpha');
      store.set('meta.flags[0]', true);
      store.set('meta.flags[1]', false);
    });
    await Future<void>.delayed(Duration.zero);
    expect(store.get('meta.title'), 'Alpha');
    expect(store.get('meta.flags[0]'), isTrue);
    expect(store.get('meta.flags[1]'), isFalse);
  });

  test('QLStoreRegistry manages named stores', () {
    final registry = QLStoreRegistry.instance;
    final alpha = registry.get('alpha');
    alpha.set('value', 10);
    expect(registry.exists('alpha'), isTrue);
    expect(registry.get('alpha').get('value'), 10);

    registry.destroy('alpha');
    expect(registry.exists('alpha'), isFalse);
  });

  test('QLRuntimeSupport pathAffects detects parent and child edits', () {
    expect(QLRuntimeSupport.pathAffects('profile', 'profile.name'), isTrue);
    expect(QLRuntimeSupport.pathAffects('profile.name', 'profile'), isTrue);
    expect(QLRuntimeSupport.pathAffects('profile.name', 'cart.items'), isFalse);
  });

  test('QLSignalProxy synchronizes both directions', () async {
    final source = QLSignal<dynamic>('one');
    final proxy = QLSignalProxy<String>(
      source,
      (value) => value?.toString() ?? '',
      (value) => value,
    );

    expect(proxy.value, 'one');

    proxy.value = 'two';
    await Future<void>.delayed(Duration.zero);
    expect(source.value, 'two');

    source.value = 'three';
    await Future<void>.delayed(Duration.zero);
    expect(proxy.value, 'three');

    proxy.dispose();
    source.dispose();
  });

  testWidgets('QLSliceRegistry mounts state and actions into a store',
      (tester) async {
    final actions = <String, QLActionPlugin>{};
    QLSliceRegistry.actionRegistrar = (name, plugin) => actions[name] = plugin;

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 1, height: 1),
      ),
    );

    final context = tester.element(find.byType(SizedBox));

    QLSliceRegistry.instance.mount(
      QLStoreSlice(
        namespace: 'shop',
        state: const {'count': 1},
        mutations: {
          'inc': (store, payload) async {
            final next = (store.get('count') as int? ?? 0) +
                (payload['by'] as int? ?? 1);
            store.set('count', next);
            return next;
          },
        },
        queries: {
          'read': (store, payload) async => store.get('count'),
        },
      ),
    );

    expect(QLStoreRegistry.instance.get('shop').get('count'), 1);
    expect(actions.containsKey('shop.inc'), isTrue);
    expect(actions.containsKey('shop.read'), isTrue);

    final mutation = actions['shop.inc']!;
    final result = await mutation
        .execute({'by': 2}, QLStoreRegistry.instance.get('shop'), context);
    expect(result, 3);
    expect(QLStoreRegistry.instance.get('shop').get('count'), 3);

    QLSliceRegistry.instance.clear();
  });
}
