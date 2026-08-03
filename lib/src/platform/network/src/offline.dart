// =============================================================================
// offline.dart — Offline queue, transfer checkpoints, resumable transfer controller.
// =============================================================================

import 'dart:async';
import 'dart:convert';

import 'types.dart';

// ---------------------------------------------------------------------------
// QueuedMutation
// ---------------------------------------------------------------------------

class QueuedMutation {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
  final int timestamp;
  int status; // 0=pending, 1=in-flight, 2=done

  QueuedMutation({
    required this.id,
    required this.method,
    required this.path,
    required this.body,
    required this.headers,
    required this.timestamp,
    this.status = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'method': method,
        'path': path,
        'body': jsonEncode(body),
        'headers': jsonEncode(headers),
        'timestamp': timestamp,
        'status': status,
      };

  factory QueuedMutation.fromMap(Map<String, dynamic> map) => QueuedMutation(
        id: map['id'].toString(),
        method: map['method'].toString(),
        path: map['path'].toString(),
        body: map['body'] != null
            ? Map<String, dynamic>.from(
                jsonDecode(map['body'].toString()) as Map)
            : {},
        headers: map['headers'] != null
            ? Map<String, String>.from(
                jsonDecode(map['headers'].toString()) as Map)
            : {},
        timestamp: (map['timestamp'] as num?)?.toInt() ?? 0,
        status: (map['status'] as num?)?.toInt() ?? 0,
      );
}

// ---------------------------------------------------------------------------
// OfflineQueueManager (abstract)
// ---------------------------------------------------------------------------

/// Platform-agnostic offline mutation queue.
/// - Native: SqliteOfflineManager (sqflite)
/// - Web:    SqliteOfflineManager (in-memory list, same class name for compat)
abstract class OfflineQueueManager {
  Future<int> getCount();
  Stream<int> get queueLength;
  Future<void> enqueue(dynamic ctx); // RequestContext (dynamic to avoid circular)
  Future<void> processQueue(dynamic client); // ApiClient
  Future<void> dispose();
}

// ---------------------------------------------------------------------------
// Transfer Checkpoint Store
// ---------------------------------------------------------------------------

class TransferCheckpointStore {
  Future<Map<String, dynamic>?> load(String id) async => null;
  Future<void> save(String id, Map<String, dynamic> checkpoint) async {}
  Future<void> clear(String id) async {}
}

/// LRU in-memory checkpoint store.
class MemoryTransferCheckpointStore extends TransferCheckpointStore {
  final Map<String, Map<String, dynamic>> _store = {};
  final int maxEntries;

  MemoryTransferCheckpointStore({this.maxEntries = 100});

  @override
  Future<Map<String, dynamic>?> load(String id) async {
    final e = _store.remove(id);
    if (e == null) return null;
    _store[id] = e;
    return e;
  }

  @override
  Future<void> save(String id, Map<String, dynamic> checkpoint) async {
    _store.remove(id);
    _store[id] = checkpoint;
    while (_store.length > maxEntries) {
      _store.remove(_store.keys.first);
    }
  }

  @override
  Future<void> clear(String id) async => _store.remove(id);
}

// ---------------------------------------------------------------------------
// ResumableTransferController
// ---------------------------------------------------------------------------

class ResumableTransferController {
  final String id;
  final TransferDirection direction;

  final StreamController<double> _progress =
      StreamController<double>.broadcast();
  final StreamController<void> _paused = StreamController<void>.broadcast();
  final StreamController<void> _resumed = StreamController<void>.broadcast();

  bool _isPaused = false;
  bool _isCancelled = false;

  ResumableTransferController({required this.id, required this.direction});

  Stream<double> get progress => _progress.stream;
  Stream<void> get paused => _paused.stream;
  Stream<void> get resumed => _resumed.stream;
  bool get isPaused => _isPaused;
  bool get isCancelled => _isCancelled;

  void emitProgress(double value) {
    if (!_progress.isClosed) _progress.add(value.clamp(0.0, 1.0));
  }

  void pause() {
    _isPaused = true;
    if (!_paused.isClosed) _paused.add(null);
  }

  void resume() {
    _isPaused = false;
    if (!_resumed.isClosed) _resumed.add(null);
  }

  void cancel() => _isCancelled = true;

  Future<void> dispose() async {
    await _progress.close();
    await _paused.close();
    await _resumed.close();
  }
}
