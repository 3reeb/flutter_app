/*
 * ============================================================================
 * File: qee_memory_cache.dart
 * 
 * Description:
 * A high-performance, two-tier in-process memory cache for deserialized QEE nodes. 
 * Combines an O(1) amortized L1 ring buffer for ultra-hot nodes and an O(1) 
 * LRU L2 cache for warm nodes, reacting dynamically to Flutter memory pressure.
 * 
 * Key Components:
 * - QL1Cache: A 256-slot ring buffer tracking most recently touched distinct IDs.
 * - QL2Cache: A doubly-linked list / HashMap hybrid for configurable LRU storage.
 * - QMemoryCache: Orchestrates hits, misses, and cross-tier promotion.
 * 
 * Dependencies/Relationships:
 * Interfaces with QBaseNode objects. Sits in front of QDiskStore within 
 * the QNodeRegistry access paths.
 * 
 * Notes:
 * All operations execute on the main isolate. Thread locking is not required.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE MEMORY CACHE — qee_memory_cache.dart
//
// Two-tier in-process cache for deserialized QBaseNode objects.
//
// L1 — Ring Buffer (256 slots, O(1) amortized):
//   Fixed-size ring buffer indexed by (nodeId & 0xFF).
//   Write: O(1) — slot = nodeId & mask → store.
//   Read:  O(1) — check slot.nodeId == requested.
//   Eviction: natural (circular overwrite — no tracking overhead).
//   Best for: ultra-hot recently accessed nodes (last 256 distinct nodeIds).
//
// L2 — LRU Map (configurable max, default 2048):
//   Doubly-linked list for O(1) LRU eviction + HashMap for O(1) lookup.
//   Read: O(1) → promotes to L1.
//   Write: O(1) → evicts LRU tail if full.
//   Best for: warm nodes that aren't accessed every frame.
//
// Memory pressure:
//   Flutter MemoryPressureListener → evict L2 first, then L1 if still needed.
//   Weighted eviction: nodes with higher [QBaseNode.weight] evicted first.
//
// Thread safety:
//   All operations run on the main Dart isolate — no locks needed.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'qee_node_types.dart';

// ─────────────────────────────────────────────────────────────────────────────
// §1 — L1: RING BUFFER CACHE
// ─────────────────────────────────────────────────────────────────────────────

/// Fixed-size ring buffer — 256 slots.
/// Hit rate is highest for the most recently touched 256 DISTINCT node IDs.
class QL1Cache {
  static const int _size = 256; // must be power of 2
  static const int _mask = _size - 1;

  // Two parallel arrays — avoids boxing overhead
  final List<int> _ids = List.filled(_size, 0);
  final List<QBaseNode?> _nodes = List.filled(_size, null);

  int _hits = 0;
  int _misses = 0;

  QBaseNode? get(int nodeId) {
    final slot = nodeId & _mask;
    if (_ids[slot] == nodeId && _nodes[slot] != null) {
      _hits++;
      return _nodes[slot];
    }
    _misses++;
    return null;
  }

  void put(int nodeId, QBaseNode node) {
    final slot = nodeId & _mask;
    _ids[slot] = nodeId;
    _nodes[slot] = node;
  }

  void evict(int nodeId) {
    final slot = nodeId & _mask;
    if (_ids[slot] == nodeId) {
      _ids[slot] = 0;
      _nodes[slot] = null;
    }
  }

  void evictAll() {
    for (int i = 0; i < _size; i++) {
      _ids[i] = 0;
      _nodes[i] = null;
    }
  }

  int get hits => _hits;
  int get misses => _misses;
  int get currentCount => _nodes.where((n) => n != null).length;
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — L2: LRU MAP CACHE
// ─────────────────────────────────────────────────────────────────────────────

/// Doubly-linked list node for O(1) LRU operations.
class _LRUNode {
  final int nodeId;
  final QBaseNode value;
  _LRUNode? prev;
  _LRUNode? next;

  _LRUNode(this.nodeId, this.value);
}

/// LRU cache backed by a HashMap + doubly-linked list.
/// All operations (get, put, evict) are O(1).
class QL2Cache {
  final int maxEntries;
  final int maxWeightBytes;

  final Map<int, _LRUNode> _map = {};
  _LRUNode? _head; // most recently used
  _LRUNode? _tail; // least recently used
  int _currentWeight = 0;

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  QL2Cache({
    this.maxEntries = 2048,
    this.maxWeightBytes = 16 * 1024 * 1024, // 16 MB default
  });

  QBaseNode? get(int nodeId) {
    final node = _map[nodeId];
    if (node == null) {
      _misses++;
      return null;
    }
    _hits++;
    _moveToHead(node);
    return node.value;
  }

  void put(int nodeId, QBaseNode value) {
    final existing = _map[nodeId];
    if (existing != null) {
      // Update in place
      _currentWeight -= existing.value.weight;
      _map[nodeId] = _LRUNode(nodeId, value);
      _removeFromList(existing);
      _addToHead(_map[nodeId]!);
      _currentWeight += value.weight;
      return;
    }

    final node = _LRUNode(nodeId, value);
    _map[nodeId] = node;
    _addToHead(node);
    _currentWeight += value.weight;

    // Evict until within limits
    while ((_map.length > maxEntries || _currentWeight > maxWeightBytes) && _tail != null) {
      _evictTail();
    }
  }

  void evict(int nodeId) {
    final node = _map.remove(nodeId);
    if (node != null) {
      _removeFromList(node);
      _currentWeight -= node.value.weight;
      _evictions++;
    }
  }

  void evictAll() {
    _map.clear();
    _head = null;
    _tail = null;
    _currentWeight = 0;
    _evictions++;
  }

  /// Evict a fraction of the cache to free memory.
  /// [fraction]: 0.0–1.0, portion to evict (0.5 = evict half).
  void evictFraction(double fraction) {
    final count = (_map.length * fraction).ceil();
    for (int i = 0; i < count && _tail != null; i++) {
      _evictTail();
    }
  }

  /// Evict nodes above a weight threshold (largest first).
  void evictHeavy({int weightThreshold = 4096}) {
    final heavy = _map.values
        .where((n) => n.value.weight > weightThreshold)
        .toList()
      ..sort((a, b) => b.value.weight.compareTo(a.value.weight));
    for (final node in heavy) {
      evict(node.nodeId);
    }
  }

  int get hits => _hits;
  int get misses => _misses;
  int get evictions => _evictions;
  int get currentCount => _map.length;
  int get currentWeightBytes => _currentWeight;

  // ── Doubly-linked list operations ─────────────────────────────────────────

  void _addToHead(_LRUNode node) {
    node.prev = null;
    node.next = _head;
    if (_head != null) _head!.prev = node;
    _head = node;
    _tail ??= node;
  }

  void _removeFromList(_LRUNode node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }
    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
    node.prev = null;
    node.next = null;
  }

  void _moveToHead(_LRUNode node) {
    if (node == _head) return;
    _removeFromList(node);
    _addToHead(node);
  }

  void _evictTail() {
    final tail = _tail;
    if (tail == null) return;
    _removeFromList(tail);
    _map.remove(tail.nodeId);
    _currentWeight -= tail.value.weight;
    _evictions++;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// §3 — COMBINED MEMORY CACHE
// ─────────────────────────────────────────────────────────────────────────────

/// Two-tier in-process cache: L1 (ring buffer) + L2 (LRU).
///
/// Read path:  L1 hit → return (fastest)
///             L1 miss → L2 hit → promote to L1 → return
///             L2 miss → caller loads from disk → put → return
///
/// Write path: put → L1 + L2 simultaneously
///
/// This cache is the hot path for every page render. Keep it fast.
class QMemoryCache {
  final QL1Cache _l1 = QL1Cache();
  final QL2Cache _l2;

  // Memory pressure listener handle
  MemoryPressureListener? _pressureListener;

  QMemoryCache({
    int maxL2Entries = 2048,
    int maxL2WeightBytes = 16 * 1024 * 1024,
  }) : _l2 = QL2Cache(maxEntries: maxL2Entries, maxWeightBytes: maxL2WeightBytes);

  /// Register the Flutter memory pressure listener.
  /// Call this once during app initialization.
  void attachMemoryPressureListener() {
    _pressureListener = MemoryPressureListener(
      onLowMemory: _onLowMemory,
    );
  }

  /// Detach the memory pressure listener.
  void detachMemoryPressureListener() {
    _pressureListener?.dispose();
    _pressureListener = null;
  }

  // ── Cache operations ──────────────────────────────────────────────────────

  /// Get a node from cache. Returns null if not cached (must load from disk).
  T? get<T extends QBaseNode>(int nodeId) {
    // L1 check first (fastest path)
    final l1 = _l1.get(nodeId);
    if (l1 != null) return l1 as T?;

    // L2 check
    final l2 = _l2.get(nodeId);
    if (l2 != null) {
      // Promote to L1
      _l1.put(nodeId, l2);
      return l2 as T?;
    }

    return null;
  }

  /// Store a node in both L1 and L2.
  void put(int nodeId, QBaseNode node) {
    _l1.put(nodeId, node);
    _l2.put(nodeId, node);
  }

  /// Check if a node is in cache (either tier).
  bool has(int nodeId) {
    return _l1.get(nodeId) != null || _l2.get(nodeId) != null;
  }

  /// Evict a node from both tiers.
  void evict(int nodeId) {
    _l1.evict(nodeId);
    _l2.evict(nodeId);
  }

  /// Evict all nodes from both tiers.
  void evictAll() {
    _l1.evictAll();
    _l2.evictAll();
  }

  /// Get cache statistics.
  QCacheStats stats() {
    return QCacheStats(
      l1Hits: _l1.hits,
      l1Misses: _l1.misses,
      l2Hits: _l2.hits,
      l2Misses: _l2.misses,
      diskHits: 0,   // tracked by registry
      diskMisses: 0,
      evictions: _l2.evictions,
      currentL1Count: _l1.currentCount,
      currentL2Count: _l2.currentCount,
      currentDiskCount: 0,
      totalWeightBytes: _l2.currentWeightBytes,
    );
  }

  // ── Memory pressure ───────────────────────────────────────────────────────

  void _onLowMemory() {
    // Phase 1: Evict half of L2 (cold nodes)
    _l2.evictFraction(0.5);
    // Phase 2: Evict heavy nodes (>4KB) from L2
    _l2.evictHeavy(weightThreshold: 4096);
    // Phase 3: Clear L1 ring buffer if still under pressure
    if (_l2.currentCount > _l2.maxEntries * 0.75) {
      _l1.evictAll();
    }
  }
}

/// Flutter memory pressure listener wrapper.
/// Calls [onLowMemory] when the system signals memory pressure.
class MemoryPressureListener with WidgetsBindingObserver {
  final VoidCallback onLowMemory;

  MemoryPressureListener({required this.onLowMemory}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didHaveMemoryPressure() {
    onLowMemory();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
