// =============================================================================
// cache.dart — Response cache layer: entries, LRU store, secure store.
// No imports from other src/ files.
// =============================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

// ---------------------------------------------------------------------------
// CacheEntry
// ---------------------------------------------------------------------------

/// A single cached response value with optional TTL.
class CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  final Duration? ttl;
  final Map<String, String> headers;

  const CacheEntry({
    required this.value,
    required this.createdAt,
    this.ttl,
    this.headers = const {},
  });

  bool get isExpired =>
      ttl != null && DateTime.now().difference(createdAt) > ttl!;

  Map<String, dynamic> toJson() => {
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        'ttl': ttl?.inMilliseconds,
        'headers': headers,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        value: json['value'],
        createdAt: DateTime.parse(json['createdAt'] as String),
        ttl: json['ttl'] != null
            ? Duration(milliseconds: json['ttl'] as int)
            : null,
        headers: Map<String, String>.from(json['headers'] ?? {}),
      );
}

// ---------------------------------------------------------------------------
// CacheStore (abstract)
// ---------------------------------------------------------------------------

abstract class CacheStore {
  Future<CacheEntry?> get(String key);
  Future<void> set(String key, CacheEntry entry);
  Future<void> remove(String key);
  Future<void> clear();
}

// ---------------------------------------------------------------------------
// MemoryCacheStore — LRU in-memory store
// ---------------------------------------------------------------------------

/// LRU in-memory [CacheStore]. Evicts oldest entry when [maxEntries] exceeded.
class MemoryCacheStore implements CacheStore {
  final int maxEntries;
  // dart:collection LinkedHashMap preserves insertion order for LRU eviction.
  final LinkedHashMap<String, CacheEntry> _map = LinkedHashMap();

  MemoryCacheStore({this.maxEntries = 512});

  @override
  Future<CacheEntry?> get(String key) async {
    final entry = _map.remove(key);
    if (entry == null) return null;
    _map[key] = entry; // Re-insert at end = LRU refresh
    return entry;
  }

  @override
  Future<void> set(String key, CacheEntry entry) async {
    _map.remove(key);
    _map[key] = entry;
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first); // Evict oldest
    }
  }

  @override
  Future<void> remove(String key) async => _map.remove(key);

  @override
  Future<void> clear() async => _map.clear();
}

// ---------------------------------------------------------------------------
// SecurePersistentCacheStore — Delegate-backed encrypted store
// ---------------------------------------------------------------------------

/// Delegate for platform-provided secure storage (e.g. flutter_secure_storage).
abstract class SecureStorageDelegate {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// [CacheStore] backed by a [SecureStorageDelegate]. Use to cache sensitive
/// data such as auth tokens or encrypted payloads.
class SecurePersistentCacheStore implements CacheStore {
  final SecureStorageDelegate secureStorage;
  SecurePersistentCacheStore(this.secureStorage);

  @override
  Future<CacheEntry?> get(String key) async {
    final raw = await secureStorage.read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return CacheEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> set(String key, CacheEntry entry) async =>
      secureStorage.write(key, jsonEncode(entry.toJson()));

  @override
  Future<void> remove(String key) async => secureStorage.delete(key);

  @override
  Future<void> clear() async => secureStorage.deleteAll();
}
