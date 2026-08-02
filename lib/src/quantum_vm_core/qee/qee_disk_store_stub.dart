/*
 * ============================================================================
 * File: qee_disk_store_stub.dart
 * 
 * Description:
 * Defines the abstract interface QDiskStore for all storage adapters, and 
 * provides a memory-only stub implementation (QStubDiskStore) for testing 
 * or environments lacking local storage.
 * 
 * Key Components:
 * - QDiskStore: The base abstract class dictating initialization and CRUD.
 * - QStubDiskStore: A fallback in-memory implementation mapping IDs to Uint8List.
 * 
 * Dependencies/Relationships:
 * Referenced universally as the baseline API for node persistence.
 * 
 * Notes:
 * Must remain entirely platform-agnostic (no dart:io or dart:html).
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE DISK STORE — STUB (qee_disk_store_stub.dart)
//
// Fallback implementation used when neither dart:io nor dart:html is
// available (pure Dart environments, tests without platform mocks).
//
// This file MUST be importable on every platform — no platform-specific
// imports allowed here. It defines the abstract QDiskStore interface and
// the in-memory-only QStubDiskStore.
//
// The conditional import in qee_disk_store.dart selects:
//   native → qee_disk_store_native.dart
//   web    → qee_disk_store_web.dart
//   other  → this file (qee_disk_store_stub.dart)
// ════════════════════════════════════════════════════════════════════════════

import 'dart:typed_data';

import 'qee_disk_store.dart' show QDiskIndex, QIndexEntry;

// ─────────────────────────────────────────────────────────────────────────────
// §1 — ABSTRACT INTERFACE
// ─────────────────────────────────────────────────────────────────────────────

/// Abstract disk store interface — implemented separately per platform.
///
/// All implementations share the same contract:
///   • [initialize] — open/create storage (files, DB, etc.)
///   • [write]      — store an encrypted blob; overwrites if exists
///   • [read]       — retrieve an encrypted blob; null if not found
///   • [delete]     — mark a slot as free
///   • [has]        — O(1) check via in-memory index
///   • [storedVersion] — O(1) version check via in-memory index
///   • [flush]      — sync pending writes to underlying storage
///   • [allNodeIds] — list all stored node IDs
///   • [close]      — release resources
abstract class QDiskStore {
  /// Initialize the store. Call once before any read/write operations.
  /// [namespace] is used to name the backing file(s) or DB store.
  Future<void> initialize(String namespace);

  /// Write an encrypted blob for [nodeId].
  /// If a slot for this nodeId already exists and is large enough,
  /// it is reused (no new allocation). Otherwise, a free slot is
  /// found from the free-list, or the blob is appended to the end.
  Future<void> write(int nodeId, Uint8List encryptedBlob, {int version = 1});

  /// Read the encrypted blob for [nodeId].
  /// Returns null if the node is not stored.
  /// This is the cold-path — the hot path checks the in-memory
  /// QMemoryCache first, so this is only called on cache miss.
  Future<Uint8List?> read(int nodeId);

  /// Delete a node from persistent storage.
  /// The blob slot is marked free for reuse by future writes.
  /// The in-memory index entry is removed immediately (O(1)).
  Future<void> delete(int nodeId);

  /// Returns true if [nodeId] exists in the persistent store.
  /// O(1) — reads the in-memory index, no I/O.
  bool has(int nodeId);

  /// Returns the stored version number for [nodeId], or 0 if not found.
  /// O(1) — reads the in-memory index, no I/O.
  int storedVersion(int nodeId);

  /// Flush all pending writes to the underlying storage medium.
  Future<void> flush();

  /// All node IDs currently stored on disk.
  List<int> get allNodeIds;

  /// Total number of nodes in the store.
  int get count;

  /// Approximate total bytes used by blobs (excludes free slots).
  int get totalBlobBytes;

  /// Release all open resources (file handles, DB connections, etc.).
  Future<void> close();

  /// Platform factory — returns the right implementation for the runtime.
  /// On native: returns [QNativeDiskStore].
  /// On web: returns [QWebDiskStore].
  /// On stub: returns [QStubDiskStore].
  static QDiskStore create() => QStubDiskStore();
}

// ─────────────────────────────────────────────────────────────────────────────
// §2 — STUB / IN-MEMORY IMPLEMENTATION
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory-only stub implementation.
/// Used in pure Dart environments (unit tests, non-platform contexts).
/// All writes go into a HashMap — nothing persists to disk.
class QStubDiskStore extends QDiskStore {
  final QDiskIndex _index = QDiskIndex();
  final Map<int, Uint8List> _blobs = {};
  bool _initialized = false;
  bool get isInitialized => _initialized;

  @override
  Future<void> initialize(String namespace) async {
    _initialized = true;
  }

  @override
  Future<void> write(int nodeId, Uint8List encryptedBlob, {int version = 1}) async {
    _blobs[nodeId] = Uint8List.fromList(encryptedBlob);
    _index.put(QIndexEntry(
      nodeId: nodeId,
      offset: 0,
      length: encryptedBlob.length,
      version: version,
    ));
  }

  @override
  Future<Uint8List?> read(int nodeId) async => _blobs[nodeId];

  @override
  Future<void> delete(int nodeId) async {
    _blobs.remove(nodeId);
    _index.markFree(nodeId);
  }

  @override
  bool has(int nodeId) => _index.has(nodeId);

  @override
  int storedVersion(int nodeId) => _index.version(nodeId);

  @override
  Future<void> flush() async {}

  @override
  List<int> get allNodeIds => _index.allIds;

  @override
  int get count => _index.count;

  @override
  int get totalBlobBytes => _index.totalAllocatedBytes;

  @override
  Future<void> close() async {
    _blobs.clear();
    _initialized = false;
  }
}
