/*
 * ============================================================================
 * File: qee_disk_store.dart
 * 
 * Description:
 * Platform-routing layer for persistent blob storage. It conditionally imports 
 * the correct QDiskStore implementation (native, web, or stub) based on the 
 * compilation target, hiding platform intricacies from the core engine.
 * 
 * Key Components:
 * - QIndexEntry: Defines a memory-resident reference to a stored node.
 * - QDiskIndex: An in-memory hash index guaranteeing O(1) lookup times.
 * 
 * Dependencies/Relationships:
 * Conditionally exports qee_disk_store_stub.dart, qee_disk_store_native.dart, 
 * or qee_disk_store_web.dart.
 * 
 * Notes:
 * The hot-path index logic is defined here so that all platform implementations 
 * share the exact same rapid lookup semantics.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE DISK STORE — qee_disk_store.dart
//
// Platform-routing layer: abstract interface + conditional import factory.
//
// The concrete implementations are in separate platform-specific files:
//   qee_disk_store_native.dart  — dart:io, RandomAccessFile, real files
//   qee_disk_store_web.dart     — dart:indexed_db, IndexedDB
//
// Conditional import selects the right implementation at compile time.
// The abstract class + QDiskStore.create() is the only public surface.
//
// Index entry layout (24 bytes per node, native only):
//   [nodeId:8 uint64 LE][offset:8 int64 LE][length:4 uint32 LE][version:4 uint32 LE]
// ════════════════════════════════════════════════════════════════════════════

// Conditional export — selects the correct implementation at compile time.
// dart.library.io is available on native; dart.library.html on web.
export 'qee_disk_store_stub.dart'
    if (dart.library.io) 'qee_disk_store_native.dart'
    if (dart.library.html) 'qee_disk_store_web.dart'
    show QDiskStore;

// ─────────────────────────────────────────────────────────────────────────────
// §1 — IN-MEMORY INDEX (shared between all implementations)
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory index entry for a stored node.
class QIndexEntry {
  final int nodeId;
  int offset;        // byte offset in blob file (native) / unused on web
  int length;        // byte length of encrypted blob
  int version;       // node version number
  bool isFree;       // true if this slot is available for reuse

  QIndexEntry({
    required this.nodeId,
    required this.offset,
    required this.length,
    required this.version,
    this.isFree = false,
  });
}

/// In-memory hash-map index: nodeId → QIndexEntry.
/// Kept ALWAYS HOT in memory so has(nodeId) and version(nodeId) are O(1)
/// with zero I/O — critical for the registry's single-instance guarantee.
class QDiskIndex {
  final Map<int, QIndexEntry> _entries = {};
  final List<QIndexEntry> _freeList = [];

  /// O(1) existence check.
  bool has(int nodeId) => _entries.containsKey(nodeId);

  /// O(1) version read.
  int version(int nodeId) => _entries[nodeId]?.version ?? 0;

  /// O(1) entry access.
  QIndexEntry? get(int nodeId) => _entries[nodeId];

  /// Register or update an entry.
  void put(QIndexEntry entry) {
    _entries[entry.nodeId] = entry;
  }

  /// Mark a slot as free and remove from active index.
  /// The slot remains in the free list for potential reuse.
  void markFree(int nodeId) {
    final entry = _entries.remove(nodeId);
    if (entry != null) {
      entry.isFree = true;
      _freeList.add(entry);
      // Keep free list sorted by length ascending (first-fit allocation)
      _freeList.sort((a, b) => a.length.compareTo(b.length));
    }
  }

  /// Find a free slot of at least [minLength] bytes (first-fit strategy).
  /// Returns null if no suitable free slot exists.
  QIndexEntry? findFreeSlot(int minLength) {
    for (int i = 0; i < _freeList.length; i++) {
      if (_freeList[i].length >= minLength) {
        return _freeList.removeAt(i);
      }
    }
    return null;
  }

  List<int> get allIds => List.unmodifiable(_entries.keys);
  int get count => _entries.length;
  int get freeSlotCount => _freeList.length;

  int get totalAllocatedBytes {
    int total = 0;
    for (final e in _entries.values) {
      total += e.length;
    }
    return total;
  }
}
