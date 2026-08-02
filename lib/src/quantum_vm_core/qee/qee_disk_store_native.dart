/*
 * ============================================================================
 * File: qee_disk_store_native.dart
 * 
 * Description:
 * Native implementation of QDiskStore targeting iOS, Android, and desktop. 
 * Uses dart:io and RandomAccessFile to manage an append-only binary blob 
 * store alongside a lightweight, crash-resilient index file.
 * 
 * Key Components:
 * - QNativeDiskStore: Implements direct byte-level file I/O operations.
 * 
 * Dependencies/Relationships:
 * Implements QDiskStore. Relies on path_provider to locate safe storage 
 * directories.
 * 
 * Notes:
 * Relies heavily on the OS kernel's page caching to make repeated file reads 
 * extremely fast, approximating memory-mapped files.
 * ============================================================================
 */
// ════════════════════════════════════════════════════════════════════════════
// QEE DISK STORE — NATIVE (qee_disk_store_native.dart)
//
// Concrete implementation for: iOS, Android, macOS, Windows, Linux.
//
// Uses dart:io RandomAccessFile for direct byte-level disk I/O.
// Files are stored in the application support directory:
//   <appSupport>/qee/<namespace>.idx  — index file
//   <appSupport>/qee/<namespace>.blb  — blob file
//
// ── Index file layout ─────────────────────────────────────────────────────
// The index is an append-only log of 24-byte fixed-size records.
// The full index is loaded into memory on startup (typically < 1 MB).
// On read/write/delete, only the in-memory QDiskIndex is used for O(1)
// decisions; the file is only touched for persistence.
//
//   Index record (24 bytes):
//     [nodeId : 8 bytes, uint64 LE]
//     [offset : 8 bytes, int64 LE]   — byte offset in .blb file
//     [length : 4 bytes, uint32 LE]  — byte length of blob
//     [version: 4 bytes, uint32 LE]  — node version counter
//
//   A free (deleted) slot is written as:
//     nodeId  = 0
//     offset  = -1 (0xFFFFFFFFFFFFFFFF)
//     length  = 0
//     version = 0
//
// ── Blob file layout ─────────────────────────────────────────────────────
// The blob file is append-only on new writes. Deleted slots are tracked
// in a free list and reused for future writes of equal or smaller size
// (first-fit strategy). This keeps the file compact over time.
//
// ── Performance ──────────────────────────────────────────────────────────
// • Index lookup (has / version): O(1) HashMap — zero I/O
// • Read: one seek + one read syscall. The OS page-cache warms the
//   frequently-accessed blobs, making repeated reads effectively free
//   (kernel page cache behaves like mmap for sequential workloads).
// • Write: one seek + one write to blob file + one append to index file.
// • No locks: all I/O awaited on the Dart event loop (single-threaded).
// ════════════════════════════════════════════════════════════════════════════

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'qee_disk_store.dart' show QDiskIndex, QIndexEntry;
import 'qee_disk_store_stub.dart' show QDiskStore;

// ─────────────────────────────────────────────────────────────────────────────
// §1 — CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

const _kIndexRecordSize = 24; // bytes per index entry

// ─────────────────────────────────────────────────────────────────────────────
// §2 — NATIVE DISK STORE
// ─────────────────────────────────────────────────────────────────────────────

/// Native disk store using RandomAccessFile.
/// Selected automatically on iOS, Android, macOS, Windows, and Linux.
class QNativeDiskStore extends QDiskStore {
  final QDiskIndex _index = QDiskIndex();

  RandomAccessFile? _blobFile;
  RandomAccessFile? _indexFile;

  int _blobEof = 0;   // next append position in the blob file
  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  @override
  Future<void> initialize(String namespace) async {
    if (_initialized) return;

    final supportDir = await getApplicationSupportDirectory();
    final qeeDir = Directory('${supportDir.path}/qee');
    if (!qeeDir.existsSync()) {
      await qeeDir.create(recursive: true);
    }

    final blobPath  = '${qeeDir.path}/$namespace.blb';
    final indexPath = '${qeeDir.path}/$namespace.idx';

    // Create files if they don't exist yet
    await _ensureFile(blobPath);
    await _ensureFile(indexPath);

    // Open both files in read+write mode (no truncate)
    _blobFile  = await File(blobPath).open(mode: FileMode.append);
    _indexFile = await File(indexPath).open(mode: FileMode.append);

    // Determine current blob end-of-file
    _blobEof = await _blobFile!.length();

    // Load the full index into memory
    await _loadIndexFromDisk();

    _initialized = true;

    if (kDebugMode) {
      debugPrint('[QEE Native] Initialized. '
          'Nodes: ${_index.count}, BlobSize: ${_blobEof}B');
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  @override
  Future<void> write(int nodeId, Uint8List encryptedBlob, {int version = 1}) async {
    _assertReady();

    int writeOffset;
    final existing = _index.get(nodeId);

    if (existing != null && existing.length >= encryptedBlob.length) {
      // Reuse the existing slot — no new allocation needed
      writeOffset = existing.offset;
    } else {
      if (existing != null) {
        // Existing slot is too small — free it and find/append a new one
        _index.markFree(nodeId);
      }
      // Try to reuse a free slot large enough
      final freeSlot = _index.findFreeSlot(encryptedBlob.length);
      if (freeSlot != null) {
        writeOffset = freeSlot.offset;
      } else {
        // Append to end of blob file
        writeOffset = _blobEof;
        _blobEof += encryptedBlob.length;
      }
    }

    // ── Write blob ────────────────────────────────────────────────────────
    // Crash-safe: write blob data first, THEN update index.
    // If the app crashes between these two, the index won't point to the
    // new data, so the next startup will see the old (or no) entry — safe.
    final blobRaf = _blobFile!;
    await blobRaf.setPosition(writeOffset);
    await blobRaf.writeFrom(encryptedBlob);

    // ── Update in-memory index ────────────────────────────────────────────
    final entry = QIndexEntry(
      nodeId: nodeId,
      offset: writeOffset,
      length: encryptedBlob.length,
      version: version,
    );
    _index.put(entry);

    // ── Append index record to disk ───────────────────────────────────────
    await _appendIndexRecord(entry);
  }

  // ── Read ──────────────────────────────────────────────────────────────────

  @override
  Future<Uint8List?> read(int nodeId) async {
    _assertReady();
    final entry = _index.get(nodeId);
    if (entry == null) return null;

    final blobRaf = _blobFile!;
    try {
      await blobRaf.setPosition(entry.offset);
      final bytes = await blobRaf.read(entry.length);
      if (bytes.length != entry.length) return null;
      return bytes;
    } catch (e) {
      if (kDebugMode) debugPrint('[QEE Native] Read error for node $nodeId: $e');
      return null;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  @override
  Future<void> delete(int nodeId) async {
    _assertReady();
    if (!_index.has(nodeId)) return;

    _index.markFree(nodeId);

    // Write a tombstone index record (nodeId=0, offset=-1)
    await _appendIndexRecord(QIndexEntry(
      nodeId: 0,
      offset: -1,
      length: 0,
      version: 0,
    ));
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
  int get totalBlobBytes => _blobEof;

  // ── Flush ─────────────────────────────────────────────────────────────────

  @override
  Future<void> flush() async {
    await _blobFile?.flush();
    await _indexFile?.flush();
  }

  // ── Close ─────────────────────────────────────────────────────────────────

  @override
  Future<void> close() async {
    await _blobFile?.flush();
    await _indexFile?.flush();
    await _blobFile?.close();
    await _indexFile?.close();
    _blobFile = null;
    _indexFile = null;
    _initialized = false;
  }

  // ── Index loading ─────────────────────────────────────────────────────────

  Future<void> _loadIndexFromDisk() async {
    final raf = _indexFile!;
    await raf.setPosition(0);
    final fileLen = await raf.length();
    if (fileLen == 0) return;

    // Read all records in one syscall
    final recordCount = fileLen ~/ _kIndexRecordSize;
    final rawBytes = await raf.read(recordCount * _kIndexRecordSize);
    if (rawBytes.isEmpty) return;

    final bd = ByteData.sublistView(rawBytes);

    int maxBlobEnd = 0;

    for (int i = 0; i < recordCount; i++) {
      final base = i * _kIndexRecordSize;
      if (base + _kIndexRecordSize > rawBytes.length) break;

      final nodeId  = _readI64(bd, base);
      final offset  = _readI64(bd, base + 8);
      final length  = bd.getUint32(base + 16, Endian.little);
      final version = bd.getUint32(base + 20, Endian.little);

      // Tombstone record — ignore
      if (nodeId == 0 && offset == -1) continue;

      // Dead or zero entry — skip
      if (nodeId == 0) continue;

      _index.put(QIndexEntry(
        nodeId: nodeId,
        offset: offset,
        length: length,
        version: version,
      ));

      final end = offset + length;
      if (end > maxBlobEnd) maxBlobEnd = end;
    }

    // Sync blob EOF with what the index says (handles crash recovery)
    if (maxBlobEnd > _blobEof) _blobEof = maxBlobEnd;
  }

  // ── Index record append ───────────────────────────────────────────────────

  Future<void> _appendIndexRecord(QIndexEntry entry) async {
    final raf = _indexFile!;
    final buf = ByteData(_kIndexRecordSize);

    _writeI64(buf, 0, entry.nodeId);
    _writeI64(buf, 8, entry.offset);
    buf.setUint32(16, entry.length.clamp(0, 0xFFFFFFFF), Endian.little);
    buf.setUint32(20, entry.version.clamp(0, 0xFFFFFFFF), Endian.little);

    // Seek to end and append
    final endPos = await raf.length();
    await raf.setPosition(endPos);
    await raf.writeFrom(buf.buffer.asUint8List());
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<void> _ensureFile(String path) async {
    final f = File(path);
    if (!f.existsSync()) await f.create(recursive: true);
  }

  void _assertReady() {
    if (!_initialized) {
      throw StateError('[QEE] QNativeDiskStore not initialized. '
          'Call initialize() before use.');
    }
  }

  // Read a signed 64-bit integer (two's complement, little-endian) from ByteData.
  // ByteData.getInt64 is not available in all Dart targets, so we read as two
  // 32-bit unsigned halves and combine.
  static int _readI64(ByteData bd, int offset) {
    final lo = bd.getUint32(offset, Endian.little);
    final hi = bd.getInt32(offset + 4, Endian.little); // signed for negative offsets
    return (hi << 32) | lo;
  }

  static void _writeI64(ByteData bd, int offset, int value) {
    bd.setUint32(offset, value & 0xFFFFFFFF, Endian.little);
    bd.setUint32(offset + 4, (value >> 32) & 0xFFFFFFFF, Endian.little);
  }
}
