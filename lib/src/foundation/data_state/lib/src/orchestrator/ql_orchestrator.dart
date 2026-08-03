import 'dart:async';
import '../storage/ql_storage_adapter.dart';
import '../reactivity/ql_data_store.dart';

abstract final class QLOrchestrator {
  static Future<QLDataStore> bootstrap(
    Map<String, dynamic> manifest, {
    QLStorageAdapter? storageAdapter,
  }) async {
    final String namespace = manifest['module']?.toString() ?? 'default';
    final store =
        QLDataStore(namespace: namespace, storageAdapter: storageAdapter);

    if (manifest['state'] is Map) {
      store.transaction(() {
        (manifest['state'] as Map).forEach((key, value) {
          store.set(key.toString(), value);
        });
      });
    }

    if (manifest['computed'] is Map) {
      (manifest['computed'] as Map).forEach((targetKey, spec) {
        if (spec is Map) {
          final deps = (spec['deps'] as List? ?? const [])
              .map((e) => e.toString())
              .toList();
          final expr = spec['expr']?.toString() ?? '';
          store.registerComputed(targetKey.toString(), deps, (values) {
            return values.isNotEmpty ? values.first : expr;
          });
        }
      });
    }

    return store;
  }
}
