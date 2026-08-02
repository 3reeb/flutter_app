/*
 * ============================================================================
 * File: network.dart
 * 
 * Description:
 * Core networking components and API adaptors for OmniCloud, including offline 
 * queueing, SQLite caching, crypto policies, and domain logic interfaces.
 * 
 * Key Components:
 * - OmniCloud / ComputeCore: Main cloud singleton and isolate-based asynchronous helpers.
 * - IOmniAuth / IOmniDatabase / IOmniStorage: Interfaces for primary cloud services.
 * - SqliteOfflineManager: Handles queuing mutations to a local SQLite database for offline capability.
 * 
 * Dependencies/Relationships:
 * Used as the fundamental backend abstraction for the application. Dependent on sqflite, crypto.
 * 
 * Notes:
 * Avoid Firebase imports here; adapter-specific logic belongs in separate adapter files.
 * ============================================================================
 */
// network.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'dart:collection';
import 'dart:developer' as developer;

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:crypto/crypto.dart';

/// OmniCloud / second-code enhanced core.
///
/// No Firebase imports are used in this file.
/// Keep adapter-specific integrations in a separate file.

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  final idx = normalized.lastIndexOf('/');
  return idx >= 0 ? normalized.substring(idx + 1) : normalized;
}

bool _isJsonPrimitive(Object? value) =>
    value == null || value is String || value is num || value is bool;

class OmniLogger {
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
      name: 'OmniCloud',
    );
  }

  static void info(String message) {
    developer.log(message, level: 800, name: 'OmniCloud');
  }
}

/// ---------------------------------------------------------------------------
/// Crypto Helpers (Optimized with package:crypto)
/// ---------------------------------------------------------------------------

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

String _sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

String _hmacSha256Hex(String secret, String message) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  final digest = hmac.convert(utf8.encode(message));
  return digest.toString();
}

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return result == 0;
}

/// ---------------------------------------------------------------------------
/// Compute helper (Optimized Isolate Strategy)
/// ---------------------------------------------------------------------------

class ComputeCore {
  static Future<T> run<T>(FutureOr<T> Function() computation) async {
    return Isolate.run(computation);
  }

  static Future<dynamic> decodeJsonAsync(String source) {
    if (source.isEmpty) return Future.value(null);
    // 100KB threshold - Only spawn isolate for large payloads to prevent CPU choke
    if (source.length < 100000) return Future.value(jsonDecode(source));
    return run(() => jsonDecode(source));
  }

  static Future<String> encodeJsonAsync(dynamic object) {
    if (object == null) return Future.value('');
    if (_isJsonPrimitive(object)) return Future.value(jsonEncode(object));

    // Heuristic: If it's a massive list/map, run in isolate, else stay on main thread
    if (object is List && object.length > 5000) {
      return run(() => jsonEncode(object));
    }
    if (object is Map && object.length > 5000) {
      return run(() => jsonEncode(object));
    }
    return Future.value(jsonEncode(object));
  }
}

/// ---------------------------------------------------------------------------
/// Domain / adapters
/// ---------------------------------------------------------------------------

class OmniCloudException implements Exception {
  final String code;
  final String message;
  final dynamic originalError;
  OmniCloudException(this.code, this.message, [this.originalError]);
  @override
  String toString() => 'OmniCloudException($code): $message';
}

class OmniDocument {
  final String id;
  final Map<String, dynamic> data;
  OmniDocument(this.id, this.data);
}

abstract class IOmniAuth {
  Future<String?> getAccessToken();
  Future<String> getUserId();
  Future<void> signOut();
}

abstract class IOmniDatabase {
  Future<OmniDocument> get(String collection, String id);
  Future<List<OmniDocument>> query(String collection,
      {Map<String, dynamic>? filters});
  Future<void> set(String collection, String id, Map<String, dynamic> data);
  Future<void> update(String collection, String id, Map<String, dynamic> data);
  Future<void> delete(String collection, String id);
}

abstract class IOmniStorage {
  Future<String> upload(String path, File file,
      {void Function(StreamProgress)? onProgress});
  Future<File> download(String path, File localFile,
      {void Function(StreamProgress)? onProgress});
}

abstract class IOmniRTC {
  Future<void> startCall(String remoteUserId);
  Future<void> endCall();
  Stream<dynamic> get remoteTrack;
}

class OmniCloud {
  static final Map<Type, dynamic> _adapters = {};
  static late final AppSdk engine;

  static void register<T>(T adapter) => _adapters[T] = adapter;

  static T get<T>() {
    final adapter = _adapters[T];
    if (adapter == null) {
      throw StateError('Adapter $T not registered');
    }
    return adapter as T;
  }

  static void initialize(AppSdk customEngine) {
    engine = customEngine;
    if (_adapters.containsKey(IOmniAuth)) {
      engine.client.authProvider = _OmniCloudEngineAuthBridge(get<IOmniAuth>());
    }
  }
}

class _OmniCloudEngineAuthBridge implements AuthProvider {
  final IOmniAuth _cloudAuth;
  final StreamController<SessionContext?> _controller =
      StreamController<SessionContext?>.broadcast();

  _OmniCloudEngineAuthBridge(this._cloudAuth);

  @override
  Future<SessionContext?> getSession() async {
    final token = await _cloudAuth.getAccessToken();
    if (token == null) return null;
    // Map the old token string into the new robust SessionContext
    return SessionContext(accessToken: token);
  }

  @override
  Stream<SessionContext?> get onSessionChanged => _controller.stream;
}

/// ---------------------------------------------------------------------------
/// Core API types
/// ---------------------------------------------------------------------------

enum ApiTrustTier { privateSourceOfTruth, authenticatedPublic, public }

enum CachePolicy {
  networkOnly,
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
  cacheOnly,
}

enum RequestKind { rest, query, batch, stream, socket, duplex, media, udp, rpc }

enum TransferDirection { upload, download }

enum MediaTrackType { audio, video, image }

enum MediaSwitchMode { seamless, buffered, immediate }

enum SessionPolicyScope { requestOnly, sessionOnly, ttl, untilRevoked }

enum EncryptionMode { none, external, hardware }

class ApiClientConfig {
  final Uri baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Map<String, String> defaultHeaders;
  final bool enableLogging;
  final String? userAgent;
  final ApiTrustTier defaultTrustTier;
  final int maxRetries;
  final List<String>? allowedCertFingerprintsSha256;

  const ApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {},
    this.enableLogging = false,
    this.userAgent,
    this.defaultTrustTier = ApiTrustTier.privateSourceOfTruth,
    this.maxRetries = 3,
    this.allowedCertFingerprintsSha256,
  });
}

abstract class AuthProvider {
  Future<SessionContext?> getSession();
  Stream<SessionContext?> get onSessionChanged;
}

class SessionStore implements AuthProvider {
  SessionContext? _session;
  final StreamController<SessionContext?> _controller =
      StreamController<SessionContext?>.broadcast();

  SessionStore([this._session]);

  void setSession(SessionContext? session) {
    _session = session;
    // Broadcast the new session to the rest of the app
    if (!_controller.isClosed) {
      _controller.add(session);
    }
  }

  @override
  Future<SessionContext?> getSession() async => _session;

  @override
  Stream<SessionContext?> get onSessionChanged => _controller.stream;

  void dispose() {
    _controller.close();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;
  final dynamic body;
  final String? code;

  ApiException({
    required this.message,
    this.statusCode,
    this.uri,
    this.body,
    this.code,
  });

  @override
  String toString() =>
      'ApiException(${code ?? ''} ${statusCode ?? ''} $message ${uri ?? ''})';
}

class PolicyViolation implements Exception {
  final String message;
  final Uri? uri;
  PolicyViolation(this.message, {this.uri});
  @override
  String toString() =>
      'PolicyViolation($message${uri == null ? '' : ' uri=$uri'})';
}

class IntegrityViolation implements Exception {
  final String message;
  final Uri? uri;
  IntegrityViolation(this.message, {this.uri});
  @override
  String toString() =>
      'IntegrityViolation($message${uri == null ? '' : ' uri=$uri'})';
}

class RequestRetryException implements Exception {}

class StreamProgress {
  final int sentBytes;
  final int? totalBytes;
  const StreamProgress({required this.sentBytes, this.totalBytes});
  double? get ratio =>
      (totalBytes == null || totalBytes == 0) ? null : sentBytes / totalBytes!;
}

class UploadFile {
  final String fieldName;
  final String fileName;
  final String contentType;
  final Stream<List<int>> stream;
  final int? length;

  const UploadFile({
    required this.fieldName,
    required this.fileName,
    required this.contentType,
    required this.stream,
    this.length,
  });

  factory UploadFile.fromBytes({
    required String fieldName,
    required String fileName,
    required String contentType,
    required Uint8List bytes,
  }) {
    return UploadFile(
      fieldName: fieldName,
      fileName: fileName,
      contentType: contentType,
      stream: Stream<List<int>>.value(bytes),
      length: bytes.length,
    );
  }

  factory UploadFile.fromFile({
    required String fieldName,
    required File file,
    required String contentType,
    String? fileName,
  }) {
    return UploadFile(
      fieldName: fieldName,
      fileName: fileName ?? _basename(file.path),
      contentType: contentType,
      stream: file.openRead(),
      length: file.lengthSync(),
    );
  }
}

class MultipartPart {
  final String name;
  final String value;
  const MultipartPart(this.name, this.value);
}

class ApiResponse<T> {
  final int statusCode;
  final Map<String, String> headers;
  final T data;
  final Uri uri;

  const ApiResponse({
    required this.statusCode,
    required this.headers,
    required this.data,
    required this.uri,
  });
}

typedef JsonFactory<T> = T Function(dynamic json);
typedef JsonEncoderFn<T> = dynamic Function(T value);

/// ---------------------------------------------------------------------------
/// Native hooks / crypto policies
/// ---------------------------------------------------------------------------

abstract class NativeSystemDelegate {
  Future<void> handoffTransferToOS({
    required String taskId,
    required Uri uri,
    required TransferDirection direction,
    required String filePath,
    required Map<String, String> headers,
  });

  void registerBackgroundWakeup(
      Future<void> Function(Map<String, dynamic> payload) onWakeup);

  Future<Uint8List> hardwareEncrypt(Uint8List data, String keyId,
      {Map<String, dynamic> meta = const {}});

  Future<Uint8List> hardwareDecrypt(Uint8List data, String keyId,
      {Map<String, dynamic> meta = const {}});
}

abstract class CryptoPolicy {
  EncryptionMode get mode;
  Uint8List encryptBytes(Uint8List input,
      {Map<String, dynamic> meta = const {}});
  Uint8List decryptBytes(Uint8List input,
      {Map<String, dynamic> meta = const {}});
  Stream<List<int>> encryptStream(Stream<List<int>> input,
      {Map<String, dynamic> meta = const {}});
  Stream<List<int>> decryptStream(Stream<List<int>> input,
      {Map<String, dynamic> meta = const {}});
}

class PassThroughCryptoPolicy implements CryptoPolicy {
  @override
  EncryptionMode get mode => EncryptionMode.none;
  @override
  Uint8List encryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      input;
  @override
  Uint8List decryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      input;
  @override
  Stream<List<int>> encryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      input;
  @override
  Stream<List<int>> decryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      input;
}

class ExternalCryptoPolicy implements CryptoPolicy {
  final Uint8List Function(Uint8List input, Map<String, dynamic> meta)
      encryptFn;
  final Uint8List Function(Uint8List input, Map<String, dynamic> meta)
      decryptFn;
  final Stream<List<int>> Function(
      Stream<List<int>> input, Map<String, dynamic> meta) encryptStreamFn;
  final Stream<List<int>> Function(
      Stream<List<int>> input, Map<String, dynamic> meta) decryptStreamFn;

  ExternalCryptoPolicy({
    required this.encryptFn,
    required this.decryptFn,
    required this.encryptStreamFn,
    required this.decryptStreamFn,
  });

  @override
  EncryptionMode get mode => EncryptionMode.external;
  @override
  Uint8List encryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      encryptFn(input, meta);
  @override
  Uint8List decryptBytes(Uint8List input,
          {Map<String, dynamic> meta = const {}}) =>
      decryptFn(input, meta);
  @override
  Stream<List<int>> encryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      encryptStreamFn(input, meta);
  @override
  Stream<List<int>> decryptStream(Stream<List<int>> input,
          {Map<String, dynamic> meta = const {}}) =>
      decryptStreamFn(input, meta);
}

class RequestMerger {
  final Map<String, List<Completer<dynamic>>> _pending = {};
  final Duration window;
  RequestMerger({this.window = const Duration(milliseconds: 12)});

  Future<T> merge<T>(String key, Future<T> Function() action) async {
    final batch = _pending[key];
    if (batch != null) {
      final c = Completer<dynamic>();
      batch.add(c);
      return await c.future as T;
    }

    final batch2 = <Completer<dynamic>>[];
    _pending[key] = batch2;
    final main = Completer<dynamic>();
    batch2.add(main);

    () async {
      await Future.delayed(window);
      try {
        final result = await action();
        for (final c in _pending.remove(key) ?? const []) {
          if (!c.isCompleted) c.complete(result);
        }
      } catch (e, s) {
        for (final c in _pending.remove(key) ?? const []) {
          if (!c.isCompleted) c.completeError(e, s);
        }
      }
    }();

    return await main.future as T;
  }
}

/// ---------------------------------------------------------------------------
/// Cache
/// ---------------------------------------------------------------------------

class CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  final Duration? ttl;
  final Map<String, String> headers;

  CacheEntry({
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

abstract class CacheStore {
  Future<CacheEntry?> get(String key);
  Future<void> set(String key, CacheEntry entry);
  Future<void> remove(String key);
  Future<void> clear();
}

class MemoryCacheStore implements CacheStore {
  final int maxEntries;
  final Map<String, CacheEntry> _map = LinkedHashMap<String, CacheEntry>();

  MemoryCacheStore({this.maxEntries = 512});

  @override
  Future<CacheEntry?> get(String key) async {
    final entry = _map.remove(key);
    if (entry == null) return null;
    _map[key] = entry;
    return entry;
  }

  @override
  Future<void> set(String key, CacheEntry entry) async {
    _map.remove(key);
    _map[key] = entry;
    while (_map.length > maxEntries) {
      _map.remove(_map.keys.first);
    }
  }

  @override
  Future<void> remove(String key) async {
    _map.remove(key);
  }

  @override
  Future<void> clear() async {
    _map.clear();
  }
}

abstract class SecureStorageDelegate {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

class SecurePersistentCacheStore implements CacheStore {
  final SecureStorageDelegate secureStorage;
  SecurePersistentCacheStore(this.secureStorage);

  @override
  Future<CacheEntry?> get(String key) async {
    final raw = await secureStorage.read(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> set(String key, CacheEntry entry) async {
    await secureStorage.write(key, jsonEncode(entry.toJson()));
  }

  @override
  Future<void> remove(String key) async => secureStorage.delete(key);

  @override
  Future<void> clear() async => secureStorage.deleteAll();
}

/// ---------------------------------------------------------------------------
/// Offline queue
/// ---------------------------------------------------------------------------

class QueuedMutation {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
  final int timestamp;
  final int status;

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

class SqliteOfflineManager {
  static sqflite.Database? _db;
  final StreamController<int> _queueLengthController =
      StreamController<int>.broadcast();
  bool _isSyncing = false;

  Future<sqflite.Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<sqflite.Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath =
        '${docsDir.path}${Platform.pathSeparator}omni_offline_queue.db';
    return sqflite.openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE mutations (
            id TEXT PRIMARY KEY,
            method TEXT NOT NULL,
            path TEXT NOT NULL,
            body TEXT,
            headers TEXT,
            timestamp INTEGER NOT NULL,
            status INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  Stream<int> get queueLength async* {
    yield await getCount();
    yield* _queueLengthController.stream;
  }

  Future<int> getCount() async {
    final db = await database;
    final res =
        await db.rawQuery('SELECT COUNT(*) FROM mutations WHERE status = 0');
    return sqflite.Sqflite.firstIntValue(res) ?? 0;
  }

  Future<void> enqueue(RequestContext ctx) async {
    final db = await database;
    final rand = Random.secure();
    final mutation = QueuedMutation(
      id: '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(100000)}',
      method: ctx.method,
      path: ctx.uri.path,
      body: ctx.body is Map ? Map<String, dynamic>.from(ctx.body as Map) : {},
      headers: ctx.headers,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert(
      'mutations',
      mutation.toMap(),
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
    _queueLengthController.add(await getCount());
  }

  Future<void> processQueue(ApiClient client) async {
    if (_isSyncing) return;
    _isSyncing = true;
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.rawUpdate('UPDATE mutations SET status = 1 WHERE status = 0');
      });

      final syncingList = await db.query('mutations',
          where: 'status = 1', orderBy: 'timestamp ASC');
      final items = syncingList.map(QueuedMutation.fromMap).toList();

      for (final item in items) {
        try {
          await client.request(
            method: item.method,
            path: item.path,
            kind: RequestKind.rest,
            body: item.body,
            headers: item.headers,
            cachePolicy: CachePolicy.networkOnly,
            bypassOfflineQueue: true,
            maxRetries:
                0, // <-- CHANGE FROM 1 TO 0 (Offline queue manages retries across sync cycles)
          );
          await db.delete('mutations', where: 'id = ?', whereArgs: [item.id]);
        } catch (e) {
          if (e is ApiException &&
              e.statusCode != null &&
              e.statusCode! >= 400 &&
              e.statusCode! < 500) {
            await db.delete('mutations', where: 'id = ?', whereArgs: [item.id]);
          } else {
            await db.update('mutations', {'status': 0},
                where: 'id = ?', whereArgs: [item.id]);
          }
        }
      }
    } finally {
      _isSyncing = false;
      _queueLengthController.add(await getCount());
    }
  }

  Future<void> dispose() async {
    await _queueLengthController.close();
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
      _db = null;
    }
  }
}

class TransferCheckpointStore {
  Future<Map<String, dynamic>?> load(String id) async => null;
  Future<void> save(String id, Map<String, dynamic> checkpoint) async {}
  Future<void> clear(String id) async {}
}

class MemoryTransferCheckpointStore extends TransferCheckpointStore {
  final Map<String, Map<String, dynamic>> _store = LinkedHashMap();
  final int maxEntries;

  MemoryTransferCheckpointStore({this.maxEntries = 100});

  @override
  Future<Map<String, dynamic>?> load(String id) async {
    final entry = _store.remove(id);
    if (entry == null) return null;
    _store[id] = entry; // Refresh LRU position
    return entry;
  }

  @override
  Future<void> save(String id, Map<String, dynamic> checkpoint) async {
    _store.remove(id);
    _store[id] = checkpoint;
    while (_store.length > maxEntries) {
      _store.remove(_store.keys.first); // Evict oldest
    }
  }

  @override
  Future<void> clear(String id) async {
    _store.remove(id);
  }
}

/// ---------------------------------------------------------------------------
/// Routing / manifests
/// ---------------------------------------------------------------------------

class AllowedHostPolicy {
  final String host;
  final Set<String> schemes;
  final Set<String> methods;
  final Set<String> purposes;
  final Duration? ttl;

  AllowedHostPolicy({
    required this.host,
    this.schemes = const {'https', 'wss', 'udp', 'grpc', 'http', 'ws'},
    this.methods = const {
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
      'QUERY',
      'UDP',
      'RPC'
    },
    this.purposes = const {
      'private',
      'public',
      'media',
      'socket',
      'duplex',
      'udp',
      'rpc'
    },
    this.ttl,
  });

  bool allows(Uri uri, {required String method, required String purpose}) {
    return uri.host == host &&
        schemes.contains(uri.scheme) &&
        methods.contains(method) &&
        purposes.contains(purpose);
  }
}

class SessionPolicy {
  final SessionPolicyScope scope;
  final Duration? ttl;
  final bool allowPublicApis;
  final bool allowMedia;
  final bool allowSocket;
  final bool allowDuplex;
  final bool allowUdp;
  final bool allowRpc;
  final bool requireRevalidateOnHostChange;

  const SessionPolicy({
    required this.scope,
    this.ttl,
    this.allowPublicApis = false,
    this.allowMedia = false,
    this.allowSocket = false,
    this.allowDuplex = false,
    this.allowUdp = false,
    this.allowRpc = false,
    this.requireRevalidateOnHostChange = true,
  });
}

class RouteManifest {
  final Uri httpBase;
  final Uri? websocketBase;
  final Uri? duplexBase;
  final Uri? mediaBase;
  final Uri? udpBase;
  final Uri? rpcBase;
  final String? manifestId;
  final DateTime? expiresAt;
  final SessionPolicy sessionPolicy;
  final List<AllowedHostPolicy> allowedHosts;
  final Map<String, dynamic> hints;
  final String? signature;
  final String? serverDelegatedSignature;

  RouteManifest({
    required this.httpBase,
    this.websocketBase,
    this.duplexBase,
    this.mediaBase,
    this.udpBase,
    this.rpcBase,
    this.manifestId,
    this.expiresAt,
    this.sessionPolicy =
        const SessionPolicy(scope: SessionPolicyScope.sessionOnly),
    this.allowedHosts = const [],
    this.hints = const {},
    this.signature,
    this.serverDelegatedSignature,
  });

  bool isExpired() => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool allows(Uri uri, {required String method, required String purpose}) {
    return allowedHosts
        .any((p) => p.allows(uri, method: method, purpose: purpose));
  }
}

class RouteContext {
  final RequestContext request;
  final RouteManifest? manifest;
  final String purpose;
  RouteContext({required this.request, required this.purpose, this.manifest});
}

abstract class RouteProvider {
  Future<RouteManifest?> resolve(RouteContext context);
}

class StaticRouteProvider implements RouteProvider {
  final RouteManifest manifest;
  StaticRouteProvider(this.manifest);
  @override
  Future<RouteManifest?> resolve(RouteContext context) async => manifest;
}

/// ---------------------------------------------------------------------------
/// Transport
/// ---------------------------------------------------------------------------

abstract class TransportResponse {
  int get statusCode;
  Map<String, String> get headers;
  Stream<List<int>> get byteStream;
  Future<Uint8List> bytes();
  Future<String> text({Encoding encoding = utf8});
}

abstract class HttpTransport {
  Future<TransportResponse> send({
    required String method,
    required Uri uri,
    Map<String, String> headers,
    Object? body,
    Duration? timeout,
    void Function(StreamProgress progress)? onSendProgress,
  });

  void dispose();
}

class IoTransport implements HttpTransport {
  final HttpClient _client;

  IoTransport({HttpClient? client, List<String>? allowedCertFingerprintsSha256})
      : _client =
            client ?? _createSecureHttpClient(allowedCertFingerprintsSha256);

  static HttpClient _createSecureHttpClient(List<String>? fingerprints) {
    final context = SecurityContext(withTrustedRoots: true);
    final client = HttpClient(context: context);

    if (fingerprints != null && fingerprints.isNotEmpty) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        return fingerprints.contains(_sha256Hex(cert.der));
      };
    }
    return client;
  }

  @override
  Future<TransportResponse> send({
    required String method,
    required Uri uri,
    Map<String, String> headers = const {},
    Object? body,
    Duration? timeout,
    void Function(StreamProgress progress)? onSendProgress,
  }) async {
    final request = await _client.openUrl(method, uri);
    headers.forEach(request.headers.set);

    if (body is MultipartRequestBody) {
      request.headers.set(HttpHeaders.contentTypeHeader, body.contentType);
      await request.addStream(body.stream(onSendProgress: onSendProgress));
    } else if (body is Stream<List<int>>) {
      await request.addStream(body);
    } else if (body is List<int>) {
      request.add(body);
    } else if (body is String) {
      request.write(body);
    } else if (body != null) {
      request.headers.set(
          HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.write(await ComputeCore.encodeJsonAsync(body));
    }

    final response =
        await request.close().timeout(timeout ?? const Duration(seconds: 30));
    return _IoTransportResponse(response);
  }

  @override
  void dispose() {
    _client.close(force: true);
  }
}

class _IoTransportResponse implements TransportResponse {
  final HttpClientResponse _response;
  _IoTransportResponse(this._response);

  @override
  int get statusCode => _response.statusCode;

  @override
  Map<String, String> get headers {
    final map = <String, String>{};
    _response.headers.forEach((name, values) => map[name] = values.join(', '));
    return map;
  }

  @override
  Stream<List<int>> get byteStream => _response;

  @override
  Future<Uint8List> bytes() async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in _response) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<String> text({Encoding encoding = utf8}) async =>
      encoding.decode(await bytes());
}

class MultipartRequestBody {
  final List<MultipartPart> fields;
  final List<UploadFile> files;
  final String boundary;

  MultipartRequestBody({
    this.fields = const [],
    this.files = const [],
    String? boundary,
  }) : boundary =
            boundary ?? 'dart-sdk-${DateTime.now().microsecondsSinceEpoch}';

  String get contentType => 'multipart/form-data; boundary=$boundary';

  Stream<List<int>> stream(
      {void Function(StreamProgress progress)? onSendProgress}) async* {
    var sent = 0;
    for (final field in fields) {
      final chunk = utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="${_escape(field.name)}"\r\n\r\n${field.value}\r\n',
      );
      sent += chunk.length;
      onSendProgress?.call(StreamProgress(sentBytes: sent));
      yield chunk;
    }

    for (final file in files) {
      final header = utf8.encode(
        '--$boundary\r\nContent-Disposition: form-data; name="${_escape(file.fieldName)}"; filename="${_escape(file.fileName)}"\r\nContent-Type: ${file.contentType}\r\n\r\n',
      );
      sent += header.length;
      onSendProgress
          ?.call(StreamProgress(sentBytes: sent, totalBytes: file.length));
      yield header;

      await for (final chunk in file.stream) {
        sent += chunk.length;
        onSendProgress
            ?.call(StreamProgress(sentBytes: sent, totalBytes: file.length));
        yield chunk;
      }

      final tail = utf8.encode('\r\n');
      sent += tail.length;
      yield tail;
    }

    yield utf8.encode('--$boundary--\r\n');
  }

  String _escape(String value) => value.replaceAll('"', r'\"');
}

/// ---------------------------------------------------------------------------
/// Request pipeline
/// ---------------------------------------------------------------------------

class RequestContext {
  final String method;
  final Uri uri;
  final RequestKind kind;
  final ApiTrustTier trustTier;
  final Map<String, String> headers;
  final dynamic body;
  final CachePolicy cachePolicy;
  final Duration timeout;
  final String? idempotencyKey;
  final String? mergeKey;
  final bool requireIntegrityCheck;
  final RouteManifest? activeManifest;

  const RequestContext({
    required this.method,
    required this.uri,
    required this.kind,
    required this.trustTier,
    required this.headers,
    required this.body,
    required this.cachePolicy,
    required this.timeout,
    this.idempotencyKey,
    this.mergeKey,
    this.requireIntegrityCheck = false,
    this.activeManifest,
  });

  RequestContext copyWith({
    String? method,
    Uri? uri,
    RequestKind? kind,
    ApiTrustTier? trustTier,
    Map<String, String>? headers,
    dynamic body,
    CachePolicy? cachePolicy,
    Duration? timeout,
    String? idempotencyKey,
    String? mergeKey,
    bool? requireIntegrityCheck,
    RouteManifest? activeManifest,
  }) {
    return RequestContext(
      method: method ?? this.method,
      uri: uri ?? this.uri,
      kind: kind ?? this.kind,
      trustTier: trustTier ?? this.trustTier,
      headers: headers ?? this.headers,
      body: body ?? this.body,
      cachePolicy: cachePolicy ?? this.cachePolicy,
      timeout: timeout ?? this.timeout,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      mergeKey: mergeKey ?? this.mergeKey,
      requireIntegrityCheck:
          requireIntegrityCheck ?? this.requireIntegrityCheck,
      activeManifest: activeManifest ?? this.activeManifest,
    );
  }
}

abstract class RequestPolicy {
  FutureOr<RequestContext> onRequest(RequestContext context);
  FutureOr<ApiResponse<dynamic>> onResponse(
      RequestContext context, ApiResponse<dynamic> response);
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace);
}

abstract class AdvancedRequestPolicy extends RequestPolicy {
  Future<bool> shouldRetry(
      RequestContext context, ApiResponse<dynamic>? response, Object? error);
}

class HeaderPolicy extends RequestPolicy {
  final Map<String, String> headers;
  HeaderPolicy(this.headers);

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) =>
      context.copyWith(headers: {...context.headers, ...headers});

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}
}

class ServerApprovedDelegationPolicy extends RequestPolicy {
  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    final sig = context.activeManifest?.serverDelegatedSignature;
    if (context.trustTier == ApiTrustTier.authenticatedPublic && sig != null) {
      return context.copyWith(headers: {
        ...context.headers,
        'X-Server-Delegated-Signature': sig,
      });
    }
    return context;
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}
}

class OfflineMutationPolicy extends RequestPolicy {
  final SqliteOfflineManager syncManager;
  final bool bypass;
  OfflineMutationPolicy(this.syncManager, {this.bypass = false});

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) => context;

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) async {
    if (bypass) return;
    if (error is SocketException ||
        error is HttpException ||
        error is IOException) {
      if (const {'POST', 'PUT', 'PATCH', 'DELETE'}.contains(context.method)) {
        await syncManager.enqueue(context);
        throw ApiException(
          message: 'Offline. Mutation queued locally.',
          statusCode: 0,
          uri: context.uri,
        );
      }
    }
  }
}

class OAuthRefreshPolicy extends AdvancedRequestPolicy {
  final AuthProvider auth;
  final Future<void> Function() onRefreshRequired;
  bool _isRefreshing = false;
  Future<void>? _refreshFuture;

  OAuthRefreshPolicy({required this.auth, required this.onRefreshRequired});

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) async {
    if (_isRefreshing && _refreshFuture != null) {
      await _refreshFuture;
    }

    var session = await auth.getSession();

    // PROACTIVE REFRESH: If we know it's expired, refresh it before sending the request!
    if (session != null && session.isExpired) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshFuture = onRefreshRequired().whenComplete(() {
          _isRefreshing = false;
          _refreshFuture = null;
        });
      }
      await _refreshFuture;
      session = await auth.getSession(); // Get the newly refreshed session
    }

    if (session?.accessToken != null && session!.accessToken!.isNotEmpty) {
      final updatedHeaders = {
        ...context.headers,
        HttpHeaders.authorizationHeader: 'Bearer ${session.accessToken}',
      };

      // Inject deviceId if it exists
      if (session.deviceId != null) {
        updatedHeaders['X-Device-Id'] = session.deviceId!;
      }

      return context.copyWith(headers: updatedHeaders);
    }
    return context;
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
      RequestContext context, ApiResponse<dynamic> response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw RequestRetryException();
    }
    return response;
  }

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}

  @override
  Future<bool> shouldRetry(RequestContext context,
      ApiResponse<dynamic>? response, Object? error) async {
    if (response?.statusCode == 401 ||
        response?.statusCode == 403 ||
        error is RequestRetryException ||
        (error is ApiException &&
            (error.statusCode == 401 || error.statusCode == 403))) {
      if (!_isRefreshing) {
        _isRefreshing = true;
        _refreshFuture = onRefreshRequired().whenComplete(() {
          _isRefreshing = false;
          _refreshFuture = null;
        });
      }
      await _refreshFuture;
      return true;
    }
    return false;
  }
}

class HmacSigningPolicy extends RequestPolicy {
  final String secretKey;
  HmacSigningPolicy(this.secretKey);

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = DateTime.now().microsecondsSinceEpoch.toString();
    final bodyStr = context.body == null
        ? ''
        : context.body is String
            ? context.body as String
            : jsonEncode(context.body);
    final payload =
        '${context.method}:${context.uri.path}:$timestamp:$nonce:$bodyStr';
    final signature = _hmacSha256Hex(secretKey, payload);
    return context.copyWith(headers: {
      ...context.headers,
      'X-Signature-Timestamp': timestamp,
      'X-Signature-Nonce': nonce,
      'X-Signature': signature,
    });
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}
}

class RateLimiterPolicy extends RequestPolicy {
  final int maxTokens;
  final Duration refillInterval;
  int _tokens;
  DateTime _lastRefill;

  RateLimiterPolicy({
    this.maxTokens = 50,
    this.refillInterval = const Duration(seconds: 1),
  })  : _tokens = maxTokens,
        _lastRefill = DateTime.now();

  void _refill() {
    final now = DateTime.now();
    if (now.difference(_lastRefill) >= refillInterval) {
      _tokens = maxTokens;
      _lastRefill = now;
    }
  }

  @override
  FutureOr<RequestContext> onRequest(RequestContext context) async {
    _refill();
    if (_tokens <= 0) {
      await Future.delayed(refillInterval);
      _refill();
    }
    _tokens--;
    return context;
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}
}

class TraceparentPolicy extends RequestPolicy {
  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    final rand = Random.secure();
    final seed =
        '${DateTime.now().microsecondsSinceEpoch}_${rand.nextInt(1 << 32)}';
    final traceId = _sha256Hex(utf8.encode('$seed-trace')).substring(0, 32);
    final spanId = _sha256Hex(utf8.encode('$seed-span')).substring(0, 16);
    return context.copyWith(headers: {
      ...context.headers,
      'traceparent': '00-$traceId-$spanId-01',
    });
  }

  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;

  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}
}

class RequestPipeline {
  final List<RequestPolicy> policies;
  const RequestPipeline({this.policies = const []});

  Future<ApiResponse<dynamic>> execute(
    RequestContext initialContext,
    int maxRetries,
    Future<ApiResponse<dynamic>> Function(RequestContext c) action,
  ) async {
    var attempts = 0;
    while (true) {
      attempts++;
      var currentContext = initialContext;

      try {
        for (final policy in policies) {
          currentContext = await policy.onRequest(currentContext);
        }

        var response = await action(currentContext);

        for (final policy in policies.reversed) {
          response = await policy.onResponse(currentContext, response);
        }
        return response;
      } catch (e, s) {
        var willRetry = false;
        for (final policy in policies) {
          if (policy is AdvancedRequestPolicy) {
            if (await policy.shouldRetry(currentContext, null, e)) {
              willRetry = true;
            }
          }
        }

        if (!willRetry && _isTransientError(e)) {
          willRetry = true;
        }

        if (!willRetry || attempts > maxRetries) {
          for (final policy in policies.reversed) {
            await policy.onError(currentContext, e, s);
          }
          rethrow;
        }

        await Future.delayed(
            Duration(milliseconds: 200 * pow(2, attempts).toInt()));
      }
    }
  }

  bool _isTransientError(Object error) {
    if (error is SocketException ||
        error is HttpException ||
        error is IOException ||
        error is TimeoutException) {
      return true;
    }
    if (error is ApiException) {
      final code = error.statusCode;
      return code == null || code >= 500 || code == 429;
    }
    return false;
  }
}

class CoalescingPolicy {
  final Map<String, Completer<ApiResponse<dynamic>>> _inFlight = {};

  Future<ApiResponse<dynamic>> coalesce(
      String key, Future<ApiResponse<dynamic>> Function() action) {
    final existing = _inFlight[key];
    if (existing != null) return existing.future;

    final completer = Completer<ApiResponse<dynamic>>();
    _inFlight[key] = completer;

    () async {
      try {
        final result = await action();
        if (!completer.isCompleted) completer.complete(result);
      } catch (e, s) {
        if (!completer.isCompleted) completer.completeError(e, s);
      } finally {
        _inFlight.remove(key);
      }
    }();

    return completer.future;
  }
}

/// ---------------------------------------------------------------------------
/// API client
/// ---------------------------------------------------------------------------

class ApiClient {
  final ApiClientConfig config;
  final HttpTransport transport;
  AuthProvider? authProvider;
  final CacheStore cacheStore;
  final RequestPipeline pipeline;
  final CoalescingPolicy coalescingPolicy;
  final RequestMerger requestMerger;
  final SqliteOfflineManager offlineManager;
  final RouteProvider? routeProvider;
  final RouteProvider? socketRouteProvider;
  final RouteProvider? duplexRouteProvider;
  final RouteProvider? udpRouteProvider;
  final RouteProvider? rpcRouteProvider;
  final CryptoPolicy cryptoPolicy;
  final TransferCheckpointStore transferCheckpointStore;
  final NativeSystemDelegate? nativeDelegate;
  final RpcTransport? rpcTransport;
  final JsonEncoder? jsonEncoder;
  final Object? Function(Object? value)? jsonReviver;

  ApiClient({
    required this.config,
    HttpTransport? transport,
    this.authProvider,
    CacheStore? cacheStore,
    RequestPipeline? pipeline,
    this.routeProvider,
    this.socketRouteProvider,
    this.duplexRouteProvider,
    this.udpRouteProvider,
    this.rpcRouteProvider,
    CryptoPolicy? cryptoPolicy,
    TransferCheckpointStore? transferCheckpointStore,
    this.nativeDelegate,
    this.rpcTransport,
    this.jsonEncoder,
    this.jsonReviver,
  })  : transport = transport ??
            IoTransport(
                allowedCertFingerprintsSha256:
                    config.allowedCertFingerprintsSha256),
        cacheStore = cacheStore ?? MemoryCacheStore(),
        pipeline = pipeline ?? RequestPipeline(policies: [TraceparentPolicy()]),
        coalescingPolicy = CoalescingPolicy(),
        requestMerger = RequestMerger(),
        cryptoPolicy = cryptoPolicy ?? PassThroughCryptoPolicy(),
        transferCheckpointStore =
            transferCheckpointStore ?? MemoryTransferCheckpointStore(),
        offlineManager = SqliteOfflineManager() {
    this.pipeline.policies.add(OfflineMutationPolicy(offlineManager));
  }

  Future<Uri> buildUri(String path, Map<String, dynamic> query,
      {required RequestKind kind}) async {
    final base = await _resolveBase(kind);
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = base.resolve(normalized);
    if (query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    });
  }

  Future<Map<String, String>> buildHeaders(
    Map<String, String> headers, {
    String? idempotencyKey,
    required ApiTrustTier trustTier,
    required Uri uri,
    required RequestKind kind,
  }) async {
    final session = await authProvider?.getSession();
    final token = session?.accessToken;
    final deviceId = session?.deviceId;

    final merged = <String, String>{
      ...config.defaultHeaders,
      ...headers,
      if (config.userAgent != null)
        HttpHeaders.userAgentHeader: config.userAgent!,
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
      if (deviceId != null && deviceId.isNotEmpty)
        'X-Device-Id': deviceId, // Injected for server-side device tracking
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      'X-Api-Trust-Tier': trustTier.name,
      'X-Request-Kind': kind.name,
    };

    merged.putIfAbsent(
        HttpHeaders.acceptHeader, () => 'application/json, text/plain, */*');
    return merged;
  }

  Future<ApiResponse<T>> query<T>(
    String path, {
    required dynamic body,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    String contentType = 'application/json; charset=utf-8',
    String accept = 'application/json',
    JsonFactory<T>? decode,
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? mergeKey,
    CachePolicy cachePolicy = CachePolicy.networkOnly,
  }) {
    return request<T>(
      method: 'QUERY',
      path: path,
      kind: RequestKind.query,
      query: query,
      headers: {
        ...headers,
        HttpHeaders.contentTypeHeader: contentType,
        HttpHeaders.acceptHeader: accept,
      },
      body: body,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
      mergeKey: mergeKey,
      cachePolicy: cachePolicy,
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    JsonFactory<T>? decode,
    Duration? timeout,
    ApiTrustTier? trustTier,
    CachePolicy cachePolicy = CachePolicy.networkOnly,
    bool requireIntegrityCheck = false,
  }) {
    return request<T>(
      method: 'GET',
      path: path,
      kind: RequestKind.rest,
      query: query,
      headers: headers,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
      cachePolicy: cachePolicy,
      requireIntegrityCheck: requireIntegrityCheck,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? idempotencyKey,
    String? mergeKey,
  }) {
    return request<T>(
      method: 'POST',
      path: path,
      kind: RequestKind.rest,
      query: query,
      headers: headers,
      body: body,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
      idempotencyKey: idempotencyKey,
      mergeKey: mergeKey,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? idempotencyKey,
    String? mergeKey,
  }) {
    return request<T>(
      method: 'PUT',
      path: path,
      kind: RequestKind.rest,
      query: query,
      headers: headers,
      body: body,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
      idempotencyKey: idempotencyKey,
      mergeKey: mergeKey,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? idempotencyKey,
    String? mergeKey,
  }) {
    return request<T>(
      method: 'PATCH',
      path: path,
      kind: RequestKind.rest,
      query: query,
      headers: headers,
      body: body,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
      idempotencyKey: idempotencyKey,
      mergeKey: mergeKey,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
    ApiTrustTier? trustTier,
  }) {
    return request<T>(
      method: 'DELETE',
      path: path,
      kind: RequestKind.rest,
      query: query,
      headers: headers,
      body: body,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
    );
  }

  Future<TransportResponse> sendRaw({
    required String method,
    required String path,
    required RequestKind kind,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    Object? body,
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? idempotencyKey,
    bool requirePolicyCheck = true,
  }) async {
    final context = await _prepareContext(
      method: method,
      path: path,
      kind: kind,
      query: query,
      headers: headers,
      body: body,
      timeout: timeout,
      trustTier: trustTier,
      idempotencyKey: idempotencyKey,
    );
    if (requirePolicyCheck) {
      await _assertRequestAllowed(context);
    }
    return transport.send(
      method: context.method,
      uri: context.uri,
      headers: context.headers,
      body: context.body,
      timeout: context.timeout,
    );
  }

  Future<ApiResponse<T>> request<T>({
    required String method,
    required String path,
    required RequestKind kind,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
    CachePolicy cachePolicy = CachePolicy.networkOnly,
    ApiTrustTier? trustTier,
    String? idempotencyKey,
    String? mergeKey,
    bool requireIntegrityCheck = false,
    bool bypassOfflineQueue = false,
    int? maxRetries,
  }) async {
    final initialContext = await _prepareContext(
      method: method,
      path: path,
      kind: kind,
      query: query,
      headers: headers,
      body: body,
      timeout: timeout,
      trustTier: trustTier,
      idempotencyKey: idempotencyKey,
      mergeKey: mergeKey,
      cachePolicy: cachePolicy,
      requireIntegrityCheck: requireIntegrityCheck,
    );

    final cacheKey = _cacheKey(initialContext);

    if (cachePolicy == CachePolicy.cacheOnly) {
      final cached = await cacheStore.get(cacheKey);
      if (cached == null || cached.isExpired) {
        throw ApiException(
          message: 'Cache entry not found for cacheOnly policy',
          statusCode: 404,
          uri: initialContext.uri,
        );
      }
      final decodedCached = cached.value is String
          ? await ComputeCore.decodeJsonAsync(cached.value)
          : cached.value;
      return ApiResponse<T>(
        statusCode: 200,
        headers: cached.headers,
        data: _castOrDecode<T>(decodedCached, decode),
        uri: initialContext.uri,
      );
    }

    if (cachePolicy == CachePolicy.cacheFirst ||
        cachePolicy == CachePolicy.staleWhileRevalidate) {
      final cached = await cacheStore.get(cacheKey);
      if (cached != null && !cached.isExpired) {
        final decodedCached = cached.value is String
            ? await ComputeCore.decodeJsonAsync(cached.value)
            : cached.value;
        if (cachePolicy == CachePolicy.cacheFirst) {
          return ApiResponse<T>(
            statusCode: 200,
            headers: cached.headers,
            data: _castOrDecode<T>(decodedCached, decode),
            uri: initialContext.uri,
          );
        }
        unawaited(_refreshCacheLater<T>(
          initialContext,
          cacheKey,
          decode,
          bypassOfflineQueue: bypassOfflineQueue,
          maxRetries: maxRetries,
        ));
        return ApiResponse<T>(
          statusCode: 200,
          headers: cached.headers,
          data: _castOrDecode<T>(decodedCached, decode),
          uri: initialContext.uri,
        );
      }
    }

    final activePolicies = bypassOfflineQueue
        ? pipeline.policies.where((p) => p is! OfflineMutationPolicy).toList()
        : pipeline.policies;
    final activePipeline = RequestPipeline(policies: activePolicies);

    final response = await activePipeline.execute(
      initialContext,
      maxRetries ?? config.maxRetries,
      (ctx) async {
        Future<ApiResponse<dynamic>> perform() async {
          final raw = await transport.send(
            method: ctx.method,
            uri: ctx.uri,
            headers: ctx.headers,
            body: ctx.body,
            timeout: ctx.timeout,
          );

          final text = await raw.text();
          final decoded = await ComputeCore.decodeJsonAsync(text);

          if (raw.statusCode >= 400) {
            throw ApiException(
              message: decoded is Map && decoded['message'] != null
                  ? decoded['message'].toString()
                  : text,
              statusCode: raw.statusCode,
              uri: ctx.uri,
              body: decoded,
            );
          }

          final result = ApiResponse<dynamic>(
            statusCode: raw.statusCode,
            headers: raw.headers,
            data: decoded,
            uri: ctx.uri,
          );

          if (ctx.requireIntegrityCheck) {
            await _verifyIntegrity(ctx, result);
          }

          return result;
        }

        if (ctx.mergeKey != null) {
          return requestMerger.merge(ctx.mergeKey!, perform);
        }
        return coalescingPolicy.coalesce('${ctx.method}:${ctx.uri}', perform);
      },
    );

    if (cachePolicy != CachePolicy.networkOnly && method == 'GET') {
      await cacheStore.set(
        cacheKey,
        CacheEntry(
          value: response.data,
          createdAt: DateTime.now(),
          headers: response.headers,
        ),
      );
    }

    return ApiResponse<T>(
      statusCode: response.statusCode,
      headers: response.headers,
      data: _castOrDecode<T>(response.data, decode),
      uri: response.uri,
    );
  }

  Future<void> dispose() async {
    transport.dispose();
    await offlineManager.dispose();
  }

  Future<RequestContext> _prepareContext({
    required String method,
    required String path,
    required RequestKind kind,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? idempotencyKey,
    String? mergeKey,
    CachePolicy cachePolicy = CachePolicy.networkOnly,
    bool requireIntegrityCheck = false,
  }) async {
    final uri = await buildUri(path, query, kind: kind);
    final finalHeaders = await buildHeaders(
      headers,
      idempotencyKey: idempotencyKey,
      trustTier: trustTier ?? config.defaultTrustTier,
      uri: uri,
      kind: kind,
    );

    RouteManifest? manifest;
    if (routeProvider != null) {
      final dummyCtx = RequestContext(
        method: method,
        uri: uri,
        kind: kind,
        trustTier: trustTier ?? config.defaultTrustTier,
        headers: finalHeaders,
        body: null,
        cachePolicy: cachePolicy,
        timeout: timeout ?? config.receiveTimeout,
      );
      manifest = await routeProvider!.resolve(
        RouteContext(request: dummyCtx, purpose: kind.name, manifest: null),
      );
    }

    return RequestContext(
      method: method,
      uri: uri,
      kind: kind,
      trustTier: trustTier ?? config.defaultTrustTier,
      headers: finalHeaders,
      body: _normalizeBody(body, finalHeaders),
      cachePolicy: cachePolicy,
      timeout: timeout ?? config.receiveTimeout,
      idempotencyKey: idempotencyKey,
      mergeKey: mergeKey,
      requireIntegrityCheck: requireIntegrityCheck,
      activeManifest: manifest,
    );
  }

  Future<void> _assertRequestAllowed(RequestContext context) async {
    final provider = _resolveProviderForKind(context.kind);
    if (provider == null) return;
    final manifest = await provider.resolve(
      RouteContext(
          request: context, purpose: context.kind.name, manifest: null),
    );
    if (manifest != null &&
        !manifest.allows(context.uri,
            method: context.method, purpose: context.kind.name)) {
      throw PolicyViolation('Route not allowed by server policy',
          uri: context.uri);
    }
  }

  RouteProvider? _resolveProviderForKind(RequestKind kind) {
    return switch (kind) {
      RequestKind.socket => socketRouteProvider,
      RequestKind.duplex => duplexRouteProvider,
      RequestKind.media => routeProvider,
      RequestKind.udp => udpRouteProvider,
      RequestKind.rpc => rpcRouteProvider,
      _ => routeProvider,
    };
  }

  dynamic _normalizeBody(dynamic body, Map<String, String> headers) {
    if (body == null) return null;
    if (body is MultipartRequestBody) return body;
    if (body is Stream<List<int>> || body is List<int> || body is String)
      return body;
    headers.putIfAbsent(
        HttpHeaders.contentTypeHeader, () => 'application/json; charset=utf-8');
    return body;
  }

  String _cacheKey(RequestContext context) {
    final bodyKey = context.body == null
        ? 'null'
        : context.body is String
            ? context.body as String
            : _sha256Hex(utf8.encode(jsonEncode(context.body)));
    return '${context.method}:${context.uri}:${context.trustTier.name}:$bodyKey';
  }

  T _castOrDecode<T>(dynamic value, JsonFactory<T>? decode) {
    if (decode != null) return decode(value);
    return value as T;
  }

  Future<void> _refreshCacheLater<T>(
    RequestContext ctx,
    String cacheKey,
    JsonFactory<T>? decode, {
    required bool bypassOfflineQueue,
    int? maxRetries,
  }) async {
    try {
      final fresh = await request<T>(
        method: ctx.method,
        path: ctx.uri.path,
        kind: ctx.kind,
        query: ctx.uri.queryParameters.map((k, v) => MapEntry(k, v)),
        headers: ctx.headers,
        body: ctx.body,
        decode: decode,
        timeout: ctx.timeout,
        cachePolicy: CachePolicy.networkOnly,
        trustTier: ctx.trustTier,
        idempotencyKey: ctx.idempotencyKey,
        mergeKey: ctx.mergeKey,
        requireIntegrityCheck: ctx.requireIntegrityCheck,
        bypassOfflineQueue: bypassOfflineQueue,
        maxRetries: maxRetries,
      );
      await cacheStore.set(
        cacheKey,
        CacheEntry(
          value: fresh.data,
          createdAt: DateTime.now(),
          headers: fresh.headers,
          ttl: const Duration(minutes: 5),
        ),
      );
    } catch (e, s) {
      OmniLogger.error(
          'Failed to refresh stale cache entry for $cacheKey', e, s);
    }
  }

  Future<void> _verifyIntegrity(
      RequestContext context, ApiResponse<dynamic> response) async {
    final sig = response.headers['x-signature'] ??
        response.headers['x-content-signature'];
    if (sig == null) {
      throw IntegrityViolation('Missing integrity signature', uri: context.uri);
    }
  }

  Future<Uri> _resolveBase(RequestKind kind) async {
    final manifest = await _resolveManifest(kind);
    if (manifest != null) {
      switch (kind) {
        case RequestKind.socket:
          return manifest.websocketBase ?? manifest.httpBase;
        case RequestKind.duplex:
          return manifest.duplexBase ?? manifest.httpBase;
        case RequestKind.media:
          return manifest.mediaBase ?? manifest.httpBase;
        case RequestKind.udp:
          return manifest.udpBase ?? manifest.httpBase;
        case RequestKind.rpc:
          return manifest.rpcBase ?? manifest.httpBase;
        case RequestKind.rest:
        case RequestKind.query:
        case RequestKind.batch:
        case RequestKind.stream:
          return manifest.httpBase;
      }
    }
    return config.baseUrl;
  }

  Future<RouteManifest?> _resolveManifest(RequestKind kind) async {
    final provider = _resolveProviderForKind(kind);
    if (provider == null) return null;
    final dummyUri = await buildUri('/', const {}, kind: kind);
    final dummyCtx = RequestContext(
      method: 'GET',
      uri: dummyUri,
      kind: kind,
      trustTier: config.defaultTrustTier,
      headers: const {},
      body: null,
      cachePolicy: CachePolicy.networkOnly,
      timeout: config.receiveTimeout,
    );
    return provider.resolve(
        RouteContext(request: dummyCtx, purpose: kind.name, manifest: null));
  }
}

/// ---------------------------------------------------------------------------
/// Query / batch / RPC
/// ---------------------------------------------------------------------------

class QueryRequest<T> {
  final String name;
  final Map<String, dynamic> variables;
  final String contentType;
  final String accept;
  final JsonFactory<T>? decode;

  QueryRequest({
    required this.name,
    this.variables = const {},
    this.contentType = 'application/json; charset=utf-8',
    this.accept = 'application/json',
    this.decode,
  });
}

class QueryEngine {
  final ApiClient client;
  QueryEngine(this.client);

  Future<ApiResponse<T>> query<T>(
    String path, {
    required QueryRequest<T> request,
    Map<String, String> headers = const {},
    Map<String, dynamic> query = const {},
    Duration? timeout,
    ApiTrustTier? trustTier,
    String? mergeKey,
    CachePolicy cachePolicy = CachePolicy.networkOnly,
  }) {
    return client.query<T>(
      path,
      body: {'query': request.name, 'variables': request.variables},
      query: query,
      headers: {
        ...headers,
        HttpHeaders.contentTypeHeader: request.contentType,
        HttpHeaders.acceptHeader: request.accept,
      },
      decode: request.decode,
      timeout: timeout,
      trustTier: trustTier,
      mergeKey: mergeKey,
      cachePolicy: cachePolicy,
    );
  }
}

class BatchRequestItem {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> query;
  final dynamic body;
  final Map<String, String> headers;

  BatchRequestItem({
    required this.id,
    required this.method,
    required this.path,
    this.query = const {},
    this.body,
    this.headers = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'query': query,
        'body': body,
        'headers': headers,
      };
}

class BatchResultItem {
  final String id;
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;

  BatchResultItem({
    required this.id,
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  factory BatchResultItem.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    return BatchResultItem(
      id: map['id']?.toString() ?? '',
      statusCode: (map['statusCode'] as num?)?.toInt() ?? 200,
      body: map['body'],
      headers: Map<String, String>.from((map['headers'] ?? const {}) as Map),
    );
  }
}

class BatchResponse {
  final List<BatchResultItem> items;
  BatchResponse(this.items);

  factory BatchResponse.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    final items = (map['items'] as List? ?? const [])
        .map(BatchResultItem.fromJson)
        .toList();
    return BatchResponse(items);
  }
}

class BatchManager {
  final ApiClient client;
  final String batchPath;
  BatchManager({required this.client, this.batchPath = '/batch'});

  Future<BatchResponse> send(List<BatchRequestItem> items) async {
    final res = await client.post<BatchResponse>(
      batchPath,
      body: {'items': items.map((e) => e.toJson()).toList()},
      decode: (json) => BatchResponse.fromJson(json),
    );
    return res.data;
  }
}

abstract class RpcTransport {
  Future<Uint8List> call(String method, Uint8List payload);
}

class BinaryRpcClient {
  final RpcTransport transport;
  BinaryRpcClient(this.transport);

  Future<TResponse> invoke<TRequest, TResponse>(
    String method,
    TRequest request, {
    required Uint8List Function(TRequest) serialize,
    required TResponse Function(Uint8List) deserialize,
  }) async {
    final bytes = serialize(request);
    final responseBytes = await transport.call(method, bytes);
    return deserialize(responseBytes);
  }
}

/// ---------------------------------------------------------------------------
/// Realtime websocket
/// ---------------------------------------------------------------------------

abstract class SocketConnection {
  Stream<dynamic> get messages;
  Future<void> send(dynamic data);
  Future<void> close([int? code, String? reason]);
}

class IoSocketConnection implements SocketConnection {
  final WebSocket _ws;
  IoSocketConnection(this._ws);

  @override
  Stream<dynamic> get messages => _ws;

  @override
  Future<void> send(dynamic data) async {
    if (data is String || data is List<int>) {
      _ws.add(data);
    } else {
      _ws.add(await ComputeCore.encodeJsonAsync(data));
    }
  }

  @override
  Future<void> close([int? code, String? reason]) => _ws.close(code, reason);
}

class RealtimeEvent {
  final String type;
  final dynamic data;
  final Map<String, dynamic> meta;

  RealtimeEvent({required this.type, this.data, this.meta = const {}});

  factory RealtimeEvent.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    return RealtimeEvent(
      type: map['type']?.toString() ?? 'message',
      data: map['data'],
      meta: Map<String, dynamic>.from(map['meta'] ?? const {}),
    );
  }
}

class RealtimeClient {
  final Uri socketUrl;
  final AuthProvider? authProvider;
  final SocketConnection Function(Uri uri)? socketTransport;
  SocketConnection? _connection;
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  RealtimeClient({
    required this.socketUrl,
    this.authProvider,
    this.socketTransport,
  });

  Stream<RealtimeEvent> get events => _events.stream;

  Future<void> connect() async {
    final session = await authProvider?.getSession();
    final token = session?.accessToken;
    final deviceId = session?.deviceId;

    var uri = socketUrl;
    final queryParams = <String, String>{
      ...uri.queryParameters,
    };

    // Attach auth and device tracking to the socket URL
    if (token != null && token.isNotEmpty) {
      queryParams['token'] = token;
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      queryParams['deviceId'] = deviceId;
    }

    if (queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final connection = socketTransport != null
        ? socketTransport!(uri)
        : IoSocketConnection(await WebSocket.connect(uri.toString()));
    _connection = connection;

    _connection!.messages.listen(
      (msg) async {
        final decoded =
            msg is String ? await ComputeCore.decodeJsonAsync(msg) : msg;
        if (decoded is Map) {
          _events.add(RealtimeEvent.fromJson(decoded));
        } else {
          _events.add(RealtimeEvent(type: 'message', data: decoded));
        }
      },
      onDone: () => _events.add(RealtimeEvent(type: 'close')),
      onError: (Object e, StackTrace s) {
        OmniLogger.error('Realtime WebSocket Error', e, s);
        _events.add(
          RealtimeEvent(
              type: 'error', data: e.toString(), meta: {'stack': s.toString()}),
        );
      },
    );
  }

  Future<void> send(String type, dynamic data,
      {Map<String, dynamic> meta = const {}}) async {
    await _connection?.send({'type': type, 'data': data, 'meta': meta});
  }

  Future<void> close() async {
    await _connection?.close();
    await _events.close();
  }
}

/// ---------------------------------------------------------------------------
/// UDP media
/// ---------------------------------------------------------------------------

enum UdpPacketType { appData, audio, video, ping }

class UdpMediaPacket {
  final int sequence;
  final int timestamp;
  final UdpPacketType type;
  final Uint8List payload;

  const UdpMediaPacket({
    required this.sequence,
    required this.timestamp,
    required this.type,
    required this.payload,
  });

  Uint8List toBytes() {
    final bytes = Uint8List(7 + payload.length);
    final data = ByteData.sublistView(bytes);
    data.setUint16(0, sequence, Endian.big);
    data.setUint32(2, timestamp, Endian.big);
    data.setUint8(6, type.index);
    bytes.setAll(7, payload);
    return bytes;
  }

  factory UdpMediaPacket.fromBytes(Uint8List bytes) {
    if (bytes.length < 7) throw Exception('Packet undersized');
    final data = ByteData.sublistView(bytes);
    final typeIndex =
        data.getUint8(6).clamp(0, UdpPacketType.values.length - 1);
    return UdpMediaPacket(
      sequence: data.getUint16(0, Endian.big),
      timestamp: data.getUint32(2, Endian.big),
      type: UdpPacketType.values[typeIndex],
      payload: Uint8List.sublistView(bytes, 7),
    );
  }
}

abstract class UdpConnection {
  Stream<UdpMediaPacket> get frames;
  Future<void> send(UdpMediaPacket packet);
  Future<void> close();
}

class IoUdpTransport implements UdpConnection {
  final RawDatagramSocket _socket;
  final InternetAddress _targetAddress;
  final int _targetPort;
  final CryptoPolicy _crypto;
  final NativeSystemDelegate? _nativeDelegate;
  final String _encryptionKeyId;
  final StreamController<UdpMediaPacket> _frames =
      StreamController<UdpMediaPacket>.broadcast();
  bool _isClosed = false;

  IoUdpTransport._(
    this._socket,
    this._targetAddress,
    this._targetPort,
    this._crypto,
    this._nativeDelegate,
    this._encryptionKeyId,
  ) {
    _socket.listen(_onRawData, onDone: close);
  }

  static Future<IoUdpTransport> connect(
      Uri uri, CryptoPolicy crypto, NativeSystemDelegate? nativeDelegate,
      {String encryptionKeyId = 'default-udp-session-key'}) async {
    final addresses = await InternetAddress.lookup(uri.host);
    if (addresses.isEmpty)
      throw Exception('DNS resolution failed for ${uri.host}');
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    return IoUdpTransport._(socket, addresses.first, uri.port, crypto,
        nativeDelegate, encryptionKeyId);
  }

  @override
  Stream<UdpMediaPacket> get frames => _frames.stream;

  @override
  Future<void> send(UdpMediaPacket packet) async {
    if (_isClosed) return;
    var rawBytes = packet.toBytes();
    if (_crypto.mode == EncryptionMode.hardware && _nativeDelegate != null) {
      rawBytes = await _nativeDelegate!.hardwareEncrypt(
        rawBytes,
        _encryptionKeyId,
        meta: {'type': 'udp'},
      );
    } else if (_crypto.mode != EncryptionMode.none) {
      rawBytes = _crypto.encryptBytes(rawBytes, meta: {'type': 'udp'});
    }
    _socket.send(rawBytes, _targetAddress, _targetPort);
  }

  void _onRawData(RawSocketEvent event) async {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket.receive();
    if (datagram == null) return;
    if (datagram.address.address != _targetAddress.address ||
        datagram.port != _targetPort) {
      return;
    }

    try {
      var safeBytes = datagram.data;
      if (_crypto.mode == EncryptionMode.hardware && _nativeDelegate != null) {
        safeBytes = await _nativeDelegate!.hardwareDecrypt(
          safeBytes,
          _encryptionKeyId,
          meta: {'type': 'udp'},
        );
      } else if (_crypto.mode != EncryptionMode.none) {
        safeBytes = _crypto.decryptBytes(safeBytes, meta: {'type': 'udp'});
      }
      _frames.add(UdpMediaPacket.fromBytes(safeBytes));
    } catch (e, s) {
      OmniLogger.error('Failed to decrypt or parse incoming UDP packet', e, s);
    }
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    _socket.close();
    await _frames.close();
  }
}

class JitterBuffer {
  final Map<int, UdpMediaPacket> _buffer = {};

  // Production enhancement: Replaced LinkedHashSet with Queue + HashSet for O(1) eviction
  final Queue<int> _emittedQueue = ListQueue<int>();
  final HashSet<int> _emittedSet = HashSet<int>();

  final StreamController<UdpMediaPacket> _orderedStream =
      StreamController<UdpMediaPacket>.broadcast();
  final int maxDelayMs;
  int _expectedSequence = -1;
  Timer? _forceFlushTimer;
  bool _flushScheduled = false;

  JitterBuffer({this.maxDelayMs = 150});

  Stream<UdpMediaPacket> get orderedFrames => _orderedStream.stream;

  void insert(UdpMediaPacket packet) {
    if (_emittedSet.contains(packet.sequence) ||
        _buffer.containsKey(packet.sequence)) {
      return;
    }

    if (_expectedSequence == -1) {
      _expectedSequence = packet.sequence;
    } else {
      final dist = (packet.sequence - _expectedSequence) & 0xffff;
      if (dist > 32767) {
        _expectedSequence = packet.sequence;
      }
    }

    _buffer[packet.sequence] = packet;

    _forceFlushTimer?.cancel();
    _forceFlushTimer =
        Timer(Duration(milliseconds: maxDelayMs), () => _forceFlush(true));

    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    scheduleMicrotask(() {
      _flushScheduled = false;
      _forceFlush(false);
    });
  }

  void _forceFlush(bool forced) {
    while (_buffer.containsKey(_expectedSequence)) {
      final packet = _buffer.remove(_expectedSequence)!;

      _emittedQueue.add(packet.sequence);
      _emittedSet.add(packet.sequence);

      if (_emittedQueue.length > 10000) {
        final oldest = _emittedQueue.removeFirst();
        _emittedSet.remove(oldest);
      }

      if (!_orderedStream.isClosed) {
        _orderedStream.add(packet);
      }
      _expectedSequence = (_expectedSequence + 1) & 0xffff;
    }

    if (forced && _buffer.isNotEmpty) {
      final sortedKeys = _buffer.keys.toList()
        ..sort((a, b) {
          final d = (a - b) & 0xffff;
          return d > 32767 ? -1 : 1;
        });
      _expectedSequence = sortedKeys.first;
      _forceFlush(false);
    }
  }

  void dispose() {
    _forceFlushTimer?.cancel();
    _buffer.clear();
    _emittedQueue.clear();
    _emittedSet.clear();
    if (!_orderedStream.isClosed) _orderedStream.close();
  }
}

/// ---------------------------------------------------------------------------
/// Media
/// ---------------------------------------------------------------------------

class MediaTrack {
  final String id;
  final MediaTrackType type;
  final int bitrate;
  final int? width;
  final int? height;
  final Uri uri;
  final Map<String, dynamic> meta;

  MediaTrack({
    required this.id,
    required this.type,
    required this.bitrate,
    required this.uri,
    this.width,
    this.height,
    this.meta = const {},
  });

  factory MediaTrack.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    return MediaTrack(
      id: map['id']?.toString() ?? '',
      type: MediaTrackType.values.firstWhere(
        (e) => e.name == (map['type']?.toString() ?? 'video'),
        orElse: () => MediaTrackType.video,
      ),
      bitrate: (map['bitrate'] as num?)?.toInt() ?? 0,
      uri: Uri.parse(map['uri']?.toString() ?? ''),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      meta: Map<String, dynamic>.from(map['meta'] ?? const {}),
    );
  }
}

class MediaManifest {
  final String mediaId;
  final List<MediaTrack> tracks;
  final MediaTrack? defaultTrack;
  final Map<String, dynamic> meta;

  MediaManifest({
    required this.mediaId,
    required this.tracks,
    this.defaultTrack,
    this.meta = const {},
  });

  factory MediaManifest.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    final tracks =
        (map['tracks'] as List? ?? const []).map(MediaTrack.fromJson).toList();
    return MediaManifest(
      mediaId: map['mediaId']?.toString() ?? '',
      tracks: tracks,
      defaultTrack: map['defaultTrack'] == null
          ? null
          : MediaTrack.fromJson(map['defaultTrack']),
      meta: Map<String, dynamic>.from(map['meta'] ?? const {}),
    );
  }
}

class MediaSwitchEvent {
  final MediaTrack? oldTrack;
  final MediaTrack newTrack;
  final MediaSwitchMode mode;
  MediaSwitchEvent({
    required this.newTrack,
    this.oldTrack,
    this.mode = MediaSwitchMode.seamless,
  });
}

class AdaptiveMediaSession {
  final String sessionId;
  final StreamController<MediaSwitchEvent> _switches =
      StreamController<MediaSwitchEvent>.broadcast();
  final StreamController<double> _buffer = StreamController<double>.broadcast();
  MediaManifest manifest;
  MediaTrack activeTrack;

  AdaptiveMediaSession({
    required this.sessionId,
    required this.manifest,
    required this.activeTrack,
  });

  Stream<MediaSwitchEvent> get switches => _switches.stream;
  Stream<double> get buffer => _buffer.stream;

  void updateBuffer(double value) {
    if (!_buffer.isClosed) _buffer.add(value.clamp(0.0, 1.0));
  }

  void switchTrack(MediaTrack next,
      {MediaSwitchMode mode = MediaSwitchMode.seamless}) {
    final old = activeTrack;
    activeTrack = next;
    if (!_switches.isClosed) {
      _switches
          .add(MediaSwitchEvent(oldTrack: old, newTrack: next, mode: mode));
    }
  }

  Future<void> dispose() async {
    await _switches.close();
    await _buffer.close();
  }
}

class MediaPlaybackSession {
  final AdaptiveMediaSession media;
  final StreamController<Duration> _position =
      StreamController<Duration>.broadcast();
  final StreamController<bool> _playing = StreamController<bool>.broadcast();
  bool _isPlaying = false;
  Duration _positionValue = Duration.zero;

  MediaPlaybackSession(this.media);

  Stream<Duration> get position => _position.stream;
  Stream<bool> get playing => _playing.stream;

  bool get isPlaying => _isPlaying;
  Duration get positionValue => _positionValue;

  void play() {
    _isPlaying = true;
    if (!_playing.isClosed) _playing.add(true);
  }

  void pause() {
    _isPlaying = false;
    if (!_playing.isClosed) _playing.add(false);
  }

  void seek(Duration value) {
    _positionValue = value;
    if (!_position.isClosed) _position.add(value);
  }

  void switchQuality(MediaTrack next) => media.switchTrack(next);

  Future<void> dispose() async {
    await _position.close();
    await _playing.close();
    await media.dispose();
  }
}

/// ---------------------------------------------------------------------------
/// Local media proxy
/// ---------------------------------------------------------------------------

class EmbeddedMediaProxy {
  final ApiClient client;
  HttpServer? _server;
  Future<void>? _startFuture;

  EmbeddedMediaProxy(this.client);

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (_server != null) return;
    _startFuture ??= () async {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handleRequest);
    }();
    await _startFuture;
  }

  Future<String> getProxyUrl(String mediaPath) async {
    await start();
    return 'http://127.0.0.1:$port/stream?path=${Uri.encodeComponent(mediaPath)}';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.queryParameters['path'];
      if (path == null) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final reqHeaders = <String, String>{};
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null) reqHeaders[HttpHeaders.rangeHeader] = range;

      final apiResponse = await client.sendRaw(
        method: 'GET',
        path: path,
        kind: RequestKind.media,
        headers: reqHeaders,
        requirePolicyCheck: true,
      );

      request.response.statusCode = apiResponse.statusCode;
      apiResponse.headers.forEach((key, value) {
        if (key.toLowerCase() != 'transfer-encoding') {
          request.response.headers.set(key, value);
        }
      });

      await apiResponse.byteStream.pipe(request.response);
    } catch (e, s) {
      OmniLogger.error('EmbeddedMediaProxy request failed', e, s);
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(e.toString());
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _startFuture = null;
  }
}

/// ---------------------------------------------------------------------------
/// CRUD repository
/// ---------------------------------------------------------------------------

class ReactiveCrudRepository<T> {
  final ApiModule api;
  final String resourcePath;
  final JsonFactory<T> fromJson;
  final JsonEncoderFn<T> toJson;
  final StreamController<T> _docStream = StreamController<T>.broadcast();
  final StreamController<List<T>> _listStream =
      StreamController<List<T>>.broadcast();

  ReactiveCrudRepository({
    required this.api,
    required this.resourcePath,
    required this.fromJson,
    required this.toJson,
  });

  Stream<T> watch(String id) async* {
    final cacheKey = _cacheKeyForDoc(id);
    final cached = await api.client.cacheStore.get(cacheKey);
    if (cached != null && !cached.isExpired) {
      final decoded = cached.value is String
          ? await ComputeCore.decodeJsonAsync(cached.value)
          : cached.value;
      yield fromJson(decoded);
    }

    try {
      final res = await api.request<T>(
        method: 'GET',
        path: '$resourcePath/$id',
        kind: RequestKind.rest,
        decode: fromJson,
      );
      _docStream.add(res.data);
      yield res.data;
    } catch (e) {
      if (cached == null) rethrow;
    }

    yield* _docStream.stream;
  }

  Stream<List<T>> watchList({Map<String, dynamic> query = const {}}) async* {
    final uri =
        await api.client.buildUri(resourcePath, query, kind: RequestKind.rest);
    final cacheKey = 'GET:$uri:${api.client.config.defaultTrustTier.name}:null';
    final cached = await api.client.cacheStore.get(cacheKey);
    if (cached != null && !cached.isExpired) {
      final decoded = cached.value is String
          ? await ComputeCore.decodeJsonAsync(cached.value)
          : cached.value;
      yield ((decoded as List?) ?? []).map((e) => fromJson(e)).toList();
    }

    try {
      final res = await api.request<List<T>>(
        method: 'GET',
        path: resourcePath,
        kind: RequestKind.rest,
        query: query,
        decode: (json) =>
            ((json as List?) ?? const []).map((e) => fromJson(e)).toList(),
      );
      _listStream.add(res.data);
      yield res.data;
    } catch (e) {
      if (cached == null) rethrow;
    }

    yield* _listStream.stream;
  }

  Future<List<T>> list({Map<String, dynamic> query = const {}}) async {
    final res = await api.request<List<T>>(
      method: 'GET',
      path: resourcePath,
      kind: RequestKind.rest,
      query: query,
      decode: (json) =>
          ((json as List?) ?? const []).map((e) => fromJson(e)).toList(),
    );
    return res.data;
  }

  Future<T> read(String id) async {
    final res = await api.request<T>(
      method: 'GET',
      path: '$resourcePath/$id',
      kind: RequestKind.rest,
      decode: fromJson,
    );
    return res.data;
  }

  Future<T> create(T value) async {
    final res = await api.request<T>(
      method: 'POST',
      path: resourcePath,
      kind: RequestKind.rest,
      body: toJson(value),
      decode: fromJson,
    );
    return res.data;
  }

  Future<T> update(String id, T value) async {
    final res = await api.request<T>(
      method: 'PUT',
      path: '$resourcePath/$id',
      kind: RequestKind.rest,
      body: toJson(value),
      decode: fromJson,
    );
    _docStream.add(res.data);
    return res.data;
  }

  Future<void> remove(String id) async {
    await api.request<dynamic>(
        method: 'DELETE',
        path: '$resourcePath/$id',
        kind: RequestKind.rest,
        decode: (json) => json);
  }

  String _cacheKeyForDoc(String id) {
    final uri = api.client.config.baseUrl.resolve('$resourcePath/$id');
    return 'GET:$uri:${api.client.config.defaultTrustTier.name}:null';
  }

  void dispose() {
    _docStream.close();
    _listStream.close();
  }
}

/// ---------------------------------------------------------------------------
/// Lifecycle / SDK
/// ---------------------------------------------------------------------------

class AppLifecycleManager {
  final List<RealtimeClient> _realtimeClients = [];
  final List<UdpConnection> _udpConnections = [];

  void registerRealtimeClient(RealtimeClient client) =>
      _realtimeClients.add(client);
  void registerUdpConnection(UdpConnection udp) => _udpConnections.add(udp);

  Future<void> onAppPaused() async {
    for (final client in _realtimeClients) {
      await client.close();
    }
  }

  Future<void> onAppResumed() async {
    for (final client in _realtimeClients) {
      await client.connect();
    }
  }

  Future<void> dispose() async {
    for (final udp in _udpConnections) {
      await udp.close();
    }
    _udpConnections.clear();
    _realtimeClients.clear();
  }
}

class ApiModule {
  final ApiClient client;
  final String prefix;
  const ApiModule(this.client, {this.prefix = ''});

  String _joinPath(String path) {
    if (prefix.isEmpty) return path;
    if (path.startsWith('/')) return '$prefix$path';
    return '$prefix/$path';
  }

  Future<ApiResponse<T>> request<T>({
    required String method,
    required String path,
    required RequestKind kind,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    dynamic body,
    JsonFactory<T>? decode,
    Duration? timeout,
  }) {
    return client.request<T>(
      method: method,
      path: _joinPath(path),
      kind: kind,
      query: query,
      headers: headers,
      body: body,
      decode: decode,
      timeout: timeout,
    );
  }
}

class AppSdk {
  final ApiClient client;
  late final ApiModule root;
  late final QueryEngine queries;
  late final BinaryRpcClient? rpc;
  late final EmbeddedMediaProxy mediaProxy;
  late final AppLifecycleManager lifecycle;
  late final BatchManager batch;
  late final ResumableTransferManager transfers;

  AppSdk(this.client) {
    root = ApiModule(client);
    queries = QueryEngine(client);
    rpc = client.rpcTransport != null
        ? BinaryRpcClient(client.rpcTransport!)
        : null;
    mediaProxy = EmbeddedMediaProxy(client);
    lifecycle = AppLifecycleManager();
    batch = BatchManager(client: client);
    transfers = ResumableTransferManager(
      client: client,
      store: client.transferCheckpointStore,
      nativeDelegate: client.nativeDelegate,
    );
  }

  static Future<AppSdk> initialize(ApiClientConfig config) async {
    final client = ApiClient(config: config);
    final sdk = AppSdk(client);
    await sdk.mediaProxy.start();
    return sdk;
  }

  ReactiveCrudRepository<T> repository<T>({
    required String path,
    required JsonFactory<T> fromJson,
    required JsonEncoderFn<T> toJson,
  }) {
    return ReactiveCrudRepository<T>(
      api: root,
      resourcePath: path,
      fromJson: fromJson,
      toJson: toJson,
    );
  }

  RealtimeClient realtime({required String socketPath}) {
    final client = RealtimeClient(
      socketUrl: this.client.config.baseUrl.resolve(socketPath),
      authProvider: this.client.authProvider,
    );
    lifecycle.registerRealtimeClient(client);
    return client;
  }

  Future<Stream<UdpMediaPacket>> liveMediaStream(String path,
      {int jitterDelayMs = 150,
      String encryptionKeyId = 'default-udp-session-key'}) async {
    final uri = await client.buildUri(path, const {}, kind: RequestKind.udp);
    final connection = await IoUdpTransport.connect(
        uri, client.cryptoPolicy, client.nativeDelegate,
        encryptionKeyId: encryptionKeyId);
    lifecycle.registerUdpConnection(connection);
    final jitterBuffer = JitterBuffer(maxDelayMs: jitterDelayMs);
    connection.frames.listen((packet) => jitterBuffer.insert(packet),
        onDone: () => jitterBuffer.dispose());
    return jitterBuffer.orderedFrames;
  }

  Future<UdpConnection> createLiveMediaIngest(String path,
      {String encryptionKeyId = 'default-udp-session-key'}) async {
    final uri = await client.buildUri(path, const {}, kind: RequestKind.udp);
    final conn = await IoUdpTransport.connect(
        uri, client.cryptoPolicy, client.nativeDelegate,
        encryptionKeyId: encryptionKeyId);
    lifecycle.registerUdpConnection(conn);
    return conn;
  }

  void dispose() {
    unawaited(mediaProxy.stop());
    unawaited(lifecycle.dispose());
    unawaited(client.dispose());
  }
}

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

class ResumableTransferManager {
  final ApiClient client;
  final TransferCheckpointStore store;
  final NativeSystemDelegate? nativeDelegate;

  ResumableTransferManager({
    required this.client,
    required this.store,
    this.nativeDelegate,
  });

  Future<ResumableTransferController> startDownload({
    required String id,
    required String path,
    required File file,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    String? checkpointKey,
    ApiTrustTier? trustTier,
    bool allowOSBackground = false,
  }) async {
    final controller = ResumableTransferController(
      id: id,
      direction: TransferDirection.download,
    );
    final key = checkpointKey ?? id;
    final checkpoint = await store.load(key);
    final offset = (checkpoint?['offset'] as num?)?.toInt() ?? 0;
    final reqHeaders = <String, String>{
      ...headers,
      if (offset > 0) HttpHeaders.rangeHeader: 'bytes=$offset-',
    };

    if (allowOSBackground && nativeDelegate != null) {
      final uri = await client.buildUri(path, query, kind: RequestKind.media);
      final finalHeaders = await client.buildHeaders(
        reqHeaders,
        trustTier: trustTier ?? client.config.defaultTrustTier,
        uri: uri,
        kind: RequestKind.media,
      );
      await nativeDelegate!.handoffTransferToOS(
        taskId: id,
        uri: uri,
        direction: TransferDirection.download,
        filePath: file.path,
        headers: finalHeaders,
      );
      return controller;
    }

    final response = await client.sendRaw(
      method: 'GET',
      path: path,
      kind: RequestKind.media,
      query: query,
      headers: reqHeaders,
      trustTier: trustTier,
    );

    if (response.statusCode >= 400) {
      throw ApiException(
          message: 'Download failed', statusCode: response.statusCode);
    }

    final sink =
        file.openWrite(mode: offset > 0 ? FileMode.append : FileMode.writeOnly);
    () async {
      try {
        var received = offset;
        final contentLengthStr =
            response.headers[HttpHeaders.contentLengthHeader] ??
                response.headers['content-length'];
        final contentLength =
            contentLengthStr != null ? int.tryParse(contentLengthStr) : null;
        final totalBytes =
            contentLength != null ? offset + contentLength : null;

        await for (final chunk in response.byteStream) {
          if (controller.isCancelled) break;
          while (controller.isPaused) {
            await Future.delayed(const Duration(milliseconds: 25));
          }
          sink.add(chunk);
          received += chunk.length;
          await store.save(key, {'offset': received});
          if (totalBytes != null && totalBytes > 0) {
            controller.emitProgress(min(received / totalBytes, 0.99));
          }
        }
        await sink.flush();
        await sink.close();
        if (!controller.isCancelled) {
          await store.clear(key);
          controller.emitProgress(1.0);
        }
      } catch (e, s) {
        OmniLogger.error('Download stream failed for task: $id', e, s);
      } finally {
        try {
          await sink.close();
        } catch (e, s) {
          OmniLogger.error('Failed to cleanly close sink for $id', e, s);
        }
        await controller.dispose();
      }
    }();

    return controller;
  }
}

class SessionContext {
  final String? userId;
  final String? sessionId;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final Map<String, dynamic> claims;
  final String authProviderUsed;
  final String? deviceId;

  const SessionContext({
    this.userId,
    this.sessionId,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.claims = const {},
    this.authProviderUsed = 'none',
    this.deviceId,
  });

  bool get isAuthenticated => userId != null && accessToken != null;
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'sessionId': sessionId,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt?.toIso8601String(),
        'claims': claims,
        'authProviderUsed': authProviderUsed,
        'deviceId': deviceId,
      };

  factory SessionContext.fromJson(Map<String, dynamic> json) => SessionContext(
        userId: json['userId'] as String?,
        sessionId: json['sessionId'] as String?,
        accessToken: json['accessToken'] as String?,
        refreshToken: json['refreshToken'] as String?,
        expiresAt: json['expiresAt'] != null
            ? DateTime.parse(json['expiresAt'] as String)
            : null,
        claims: (json['claims'] as Map?)?.cast<String, dynamic>() ?? const {},
        authProviderUsed: json['authProviderUsed'] as String? ?? 'unknown',
        deviceId: json['deviceId'] as String?,
      );

  SessionContext copyWith({
    String? userId,
    String? sessionId,
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    Map<String, dynamic>? claims,
    String? authProviderUsed,
    String? deviceId,
  }) {
    return SessionContext(
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      claims: claims ?? this.claims,
      authProviderUsed: authProviderUsed ?? this.authProviderUsed,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  List<String> _strings(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is String) return <String>[raw];
    if (raw is Iterable) {
      return raw
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(growable: false);
    }
    return <String>[raw.toString()];
  }

  List<String> get roles => _strings(claims['roles'] ?? claims['role']);
  List<String> get permissions =>
      _strings(claims['permissions'] ?? claims['permission']);
  List<String> get features => _strings(
      claims['features'] ?? claims['featureFlags'] ?? claims['feature']);
  List<String> get subscriptions => _strings(
      claims['subscriptions'] ?? claims['subscription'] ?? claims['plan']);

  bool hasRole(String role) => roles.contains(role);
  bool hasPermission(String permission) => permissions.contains(permission);
  bool hasFeature(String feature) => features.contains(feature);
  bool hasSubscription(String subscription) =>
      subscriptions.contains(subscription);

  dynamic claim(String key) => claims[key];
}
