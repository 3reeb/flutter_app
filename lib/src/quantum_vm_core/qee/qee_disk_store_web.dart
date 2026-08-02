/*
 * ============================================================================
 * File: qee_disk_store_web.dart
 * 
 * Description:
 * Web implementation of QDiskStore using the browser's IndexedDB via dart:html. 
 * Handles asynchronous IDB transactions while maintaining a hot in-memory index 
 * for immediate lookups.
 * 
 * Key Components:
 * - QWebDiskStore: IndexedDB-backed implementation of the storage interface.
 * 
 * Dependencies/Relationships:
 * Implements QDiskStore. Interacts with dart:indexed_db.
 * 
 * Notes:
 * Performs an initial warming phase on startup to retrieve all keys into memory, 
 * avoiding asynchronous bottlenecks during layout rendering.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE DISK STORE — WEB (qee_disk_store_web.dart)
//
// Concrete implementation for: Flutter Web.
//
// Uses the browser's IndexedDB API via dart:html.
// Selected automatically on web via the conditional import in
// qee_disk_store.dart.
//
// ── Storage layout ────────────────────────────────────────────────────────
// IndexedDB database: 'qee_<namespace>'
// Object store: 'nodes'
//   key   : nodeId (integer)
//   value : Uint8List with a 4-byte version prefix + encrypted blob
//           Format: [version: 4 bytes LE][encrypted_blob: N bytes]
//
// ── In-memory index ───────────────────────────────────────────────────────
// On startup, all keys are loaded from IDB into _index (QDiskIndex).
// This provides O(1) has() and storedVersion() without any IDB round-trips.
// The hot path in QNodeRegistry checks _index.has() before any async IDB read.
//
// ── Performance ───────────────────────────────────────────────────────────
// • has / storedVersion : O(1) in-memory index — zero IDB I/O
// • read                : one IDB get transaction (async, ~0.1–1 ms)
// • write               : one IDB put transaction (async, fire-and-forget)
// • delete              : one IDB delete transaction
// • startup warm        : one IDB getAllKeys() + getAllValues() on the
//                         store to populate in-memory index
// ════════════════════════════════════════════════════════════════════════════

// ignore_for_file: uri_does_not_exist, avoid_web_libraries_in_flutter, deprecated_member_use, undefined_class, undefined_identifier
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'dart:typed_data';
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'qee_disk_store.dart' show QDiskIndex, QIndexEntry;
import 'qee_disk_store_stub.dart' show QDiskStore;

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kStoreName = 'nodes';
const _kDbVersion = 1;
const _kVersionPrefixLen =
    4; // bytes prepended to each blob for version storage

// ─────────────────────────────────────────────────────────────────────────────
// §2 — WEB DISK STORE
// ─────────────────────────────────────────────────────────────────────────────

/// Web disk store backed by IndexedDB.
/// Selected automatically on Flutter Web via conditional import.
class QWebDiskStore extends QDiskStore {
  final QDiskIndex _index = QDiskIndex();

  idb.Database? _db;
  bool _initialized = false;
  String _dbName = 'qee_default';

  // ── Initialization ────────────────────────────────────────────────────────

  @override
  Future<void> initialize(String namespace) async {
    if (_initialized) return;
    _dbName = 'qee_$namespace';

    try {
      _db = await _openDatabase(_dbName);
      await _warmIndex();
      _initialized = true;

      if (kDebugMode) {
        debugPrint('[QEE Web] Initialized. Nodes: ${_index.count}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[QEE Web] IndexedDB init failed: $e');
      }
      // Degrade gracefully — in-memory only (QStubDiskStore behaviour)
      _initialized = true;
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> write(int nodeId, Uint8List encryptedBlob,
      {int version = 1}) async {
    _assertReady();

    // Build payload: [version: 4 bytes LE][blob]
    final payload = Uint8List(_kVersionPrefixLen + encryptedBlob.length);
    final bd = ByteData.sublistView(payload);
    bd.setUint32(0, version, Endian.little);
    payload.setAll(_kVersionPrefixLen, encryptedBlob);

    // Write to IDB
    await _idbPut(nodeId, payload);

    // Update in-memory index
    _index.put(QIndexEntry(
      nodeId: nodeId,
      offset: 0, // not used on web
      length: encryptedBlob.length,
      version: version,
    ));
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<Uint8List?> read(int nodeId) async {
    _assertReady();
    if (!_index.has(nodeId)) return null;

    final payload = await _idbGet(nodeId);
    if (payload == null || payload.length < _kVersionPrefixLen) return null;

    // Strip the version prefix and return the raw encrypted blob
    return Uint8List.sublistView(payload, _kVersionPrefixLen);
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> delete(int nodeId) async {
    _assertReady();
    if (!_index.has(nodeId)) return;

    await _idbDelete(nodeId);
    _index.markFree(nodeId);
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  bool has(int nodeId) => _index.has(nodeId);

  @override
  int storedVersion(int nodeId) => _index.version(nodeId);

  @override
  List<int> get allNodeIds => _index.allIds;

  @override
  int get count => _index.count;

  @override
  int get totalBlobBytes => _index.totalAllocatedBytes;

  @override
  Future<void> flush() async {
    // IDB transactions are auto-committed — no manual flush needed.
  }

  @override
  Future<void> close() async {
    _db?.close();
    _db = null;
    _initialized = false;
  }

  // ── Index warming ─────────────────────────────────────────────────────────

  /// Warm the in-memory index by reading all keys + their version prefixes.
  /// Called once during [initialize]. Uses a single IDB transaction for efficiency.
  Future<void> _warmIndex() async {
    final db = _db;
    if (db == null) return;

    final tx = db.transaction(_kStoreName, 'readonly');
    final store = tx.objectStore(_kStoreName);


    final ids = <int>[];
    final entries = <int, int>{}; // nodeId → version

    await cursor.forEach((idb.CursorWithValue c) {
      final key = c.key;
      final value = c.value;
      if (key is int && value is ByteBuffer) {
        final bytes = value.asUint8List();
        if (bytes.length >= _kVersionPrefixLen) {
          final version =
              ByteData.sublistView(bytes).getUint32(0, Endian.little);
          entries[key] = version;
          ids.add(key);
        }
      }
    }).catchError((_) {});

    for (final id in ids) {
      _index.put(QIndexEntry(
        nodeId: id,
        offset: 0,
        length: 0, // Not tracked on web (no blob file)
        version: entries[id] ?? 1,
      ));
    }
  }

  // ── IDB helpers ───────────────────────────────────────────────────────────

  Future<idb.Database> _openDatabase(String dbName) async {
    final factory = html.window.indexedDB;
    if (factory == null) {
      throw StateError('[QEE Web] IndexedDB not available in this browser.');
    }

    final db = await factory.open(
      dbName,
      version: _kDbVersion,
      onUpgradeNeeded: (idb.VersionChangeEvent event) {
        final db = event.target?.result as idb.Database?;
        if (db == null) return;
        if (!db.objectStoreNames!.contains(_kStoreName)) {
          db.createObjectStore(_kStoreName);
        }
      },
    );

    return db;
  }

  Future<void> _idbPut(int key, Uint8List value) async {
    final db = _db;
    if (db == null) return;

    final tx = db.transaction(_kStoreName, 'readwrite');
    final store = tx.objectStore(_kStoreName);
    await store.put(value.buffer, key);
    await tx.completed;
  }

  Future<Uint8List?> _idbGet(int key) async {
    final db = _db;
    if (db == null) return null;

    final tx = db.transaction(_kStoreName, 'readonly');
    final store = tx.objectStore(_kStoreName);

    try {
      final result = await store.getObject(key);
      if (result is ByteBuffer) {
        return result.asUint8List();
      }
      if (result is Uint8List) return result;
    } catch (e) {
      if (kDebugMode) debugPrint('[QEE Web] IDB get error for $key: $e');
    }
    return null;
  }

  Future<void> _idbDelete(int key) async {
    final db = _db;
    if (db == null) return;

    final tx = db.transaction(_kStoreName, 'readwrite');
    final store = tx.objectStore(_kStoreName);
    await store.delete(key);
    await tx.completed;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _assertReady() {
    if (!_initialized) {
      throw StateError('[QEE] QWebDiskStore not initialized. '
          'Call initialize() before use.');
    }
  }
}

// Needed for Completer in _warmIndex
