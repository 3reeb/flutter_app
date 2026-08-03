// =============================================================================
// network_native.dart
// Native (dart:io) platform implementation of the network library.
//
// Exports all shared src/ types PLUS adds:
//   • ComputeCore   — Isolate.run for off-thread JSON
//   • QuantumFile   — io.File-backed
//   • IoTransport   — dart:io HttpClient with certificate pinning
//   • IoSocketConnection — dart:io WebSocket
//   • IoUdpTransport     — RawDatagramSocket + JitterBuffer
//   • SqliteOfflineManager — sqflite persistence
//   • EmbeddedMediaProxy   — local HttpServer
//   • ResumableTransferManager — resumable download/upload
//   • ApiClient     — full HTTP engine (default: IoTransport)
//   • AppSdk        — top-level SDK handle
// =============================================================================

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as io;
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

// Re-export all shared types so callers only need to import main.dart
export 'src/types.dart';
export 'src/exceptions.dart';
export 'src/session.dart';
export 'src/cache.dart';
export 'src/crypto.dart';
export 'src/upload.dart';
export 'src/transport.dart';
export 'src/routing.dart';
export 'src/pipeline.dart';
export 'src/offline.dart';
export 'src/realtime.dart';
export 'src/media.dart';
export 'src/rpc.dart';
export 'src/repository.dart';
export 'src/omni.dart';

// Also import them so we can use them in this file
import 'src/types.dart';
import 'src/exceptions.dart';
import 'src/session.dart';
import 'src/cache.dart';
import 'src/crypto.dart';
import 'src/upload.dart';
import 'src/transport.dart';
import 'src/routing.dart';
import 'src/pipeline.dart';
import 'src/offline.dart';
import 'src/realtime.dart';
import 'src/media.dart';
import 'src/rpc.dart';
import 'src/repository.dart';
import 'src/omni.dart';

// ===========================================================================
// ComputeCore — Off-thread JSON via Isolate.run
// ===========================================================================

class ComputeCore {
  /// Decode JSON on a background isolate when payload > 100 KB.
  static Future<dynamic> decodeJsonAsync(String src) async {
    if (src.length > 102400) {
      return Isolate.run(() => jsonDecode(src));
    }
    return jsonDecode(src);
  }

  /// Encode JSON on a background isolate when payload > 100 KB.
  static Future<String> encodeJsonAsync(dynamic value) async {
    final encoded = jsonEncode(value);
    if (encoded.length > 102400) {
      return Isolate.run(() => jsonEncode(value));
    }
    return encoded;
  }
}

// ===========================================================================
// QuantumFile — io.File backed
// ===========================================================================

class _IoFileSink implements QuantumFileSink {
  final IOSink _sink;
  _IoFileSink(this._sink);

  @override
  void add(List<int> data) => _sink.add(data);

  @override
  Future<void> flush() => _sink.flush(); // BUG FIX: was missing in abstract

  @override
  Future<void> close() => _sink.close();
}

class QuantumFileNative extends QuantumFile {
  final io.File _file;
  QuantumFileNative(String path) : _file = io.File(path);

  @override
  String get path => _file.path;

  @override
  Stream<List<int>> openRead() => _file.openRead();

  @override
  QuantumFileSink openWrite({QuantumFileMode mode = QuantumFileMode.writeOnly}) {
    final ioMode = mode == QuantumFileMode.append
        ? io.FileMode.append
        : io.FileMode.writeOnly;
    return _IoFileSink(_file.openWrite(mode: ioMode));
  }

  @override
  int lengthSync() => _file.lengthSync();
}

/// Factory function — creates a [QuantumFile] for the native platform.
QuantumFile createQuantumFile(String path) => QuantumFileNative(path);

// ===========================================================================
// IoTransport — dart:io HttpClient with optional certificate pinning
// ===========================================================================

class _IoTransportResponse implements TransportResponse {
  final io.HttpClientResponse _resp;
  _IoTransportResponse(this._resp);

  @override
  int get statusCode => _resp.statusCode;

  @override
  Map<String, String> get headers {
    final m = <String, String>{};
    _resp.headers.forEach((name, values) {
      m[name] = values.join(', ');
    });
    return m;
  }

  @override
  Stream<List<int>> get byteStream => _resp;

  @override
  Future<Uint8List> bytes() async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in _resp) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  @override
  Future<String> text({Encoding encoding = utf8}) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in _resp) {
      builder.add(chunk);
    }
    return encoding.decode(builder.takeBytes());
  }
}

class IoTransport implements HttpTransport {
  final io.HttpClient _client;
  final List<String>? _allowedFingerprints;

  IoTransport({List<String>? allowedCertFingerprintsSha256})
      : _allowedFingerprints = allowedCertFingerprintsSha256,
        _client = io.HttpClient() {
    if (allowedCertFingerprintsSha256 != null &&
        allowedCertFingerprintsSha256.isNotEmpty) {
      _client.badCertificateCallback =
          (io.X509Certificate cert, String host, int port) {
        final fingerprint = crypto.sha256
            .convert(cert.der)
            .toString()
            .toLowerCase()
            .replaceAll(':', '');
        return allowedCertFingerprintsSha256
            .map((f) => f.toLowerCase().replaceAll(':', ''))
            .contains(fingerprint);
      };
    }
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
    final request = await _client
        .openUrl(method, uri)
        .timeout(timeout ?? const Duration(seconds: 30));

    headers.forEach(request.headers.set);

    if (body is MultipartRequestBody) {
      request.headers.set(HttpHeaders.contentTypeHeader, body.contentType);
      await for (final chunk in body.stream(onSendProgress: onSendProgress)) {
        request.add(chunk);
      }
    } else if (body is Stream<List<int>>) {
      await body.pipe(request);
    } else if (body is List<int>) {
      request.add(body);
    } else if (body is String) {
      request.write(body);
    } else if (body != null) {
      request.headers.set(
          HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      request.write(await ComputeCore.encodeJsonAsync(body));
    }

    final response = await request.close();
    return _IoTransportResponse(response);
  }

  @override
  void dispose() => _client.close(force: true);
}

// ===========================================================================
// IoSocketConnection — dart:io WebSocket
// ===========================================================================

class IoSocketConnection implements SocketConnection {
  final io.WebSocket _ws;
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

// ===========================================================================
// IoUdpTransport — RawDatagramSocket with optional HW encryption
// ===========================================================================

class IoUdpTransport implements UdpConnection {
  final io.RawDatagramSocket _socket;
  final io.InternetAddress _targetAddr;
  final int _targetPort;
  final CryptoPolicy _crypto;
  final NativeSystemDelegate? _nativeDelegate;
  final String _encKeyId;
  final StreamController<UdpMediaPacket> _frames =
      StreamController<UdpMediaPacket>.broadcast();
  bool _closed = false;

  IoUdpTransport._(this._socket, this._targetAddr, this._targetPort,
      this._crypto, this._nativeDelegate, this._encKeyId) {
    _socket.listen(_onRaw, onDone: close);
  }

  static Future<IoUdpTransport> connect(
    Uri uri,
    CryptoPolicy crypto,
    NativeSystemDelegate? nativeDelegate, {
    String encryptionKeyId = 'default-udp-session-key',
  }) async {
    final addresses = await io.InternetAddress.lookup(uri.host);
    if (addresses.isEmpty) throw Exception('DNS failed for ${uri.host}');
    final socket =
        await io.RawDatagramSocket.bind(io.InternetAddress.anyIPv4, 0);
    return IoUdpTransport._(
        socket, addresses.first, uri.port, crypto, nativeDelegate, encryptionKeyId);
  }

  @override
  Stream<UdpMediaPacket> get frames => _frames.stream;

  @override
  Future<void> send(UdpMediaPacket packet) async {
    if (_closed) return;
    var raw = packet.toBytes();
    if (_crypto.mode == EncryptionMode.hardware && _nativeDelegate != null) {
      raw = await _nativeDelegate!
          .hardwareEncrypt(raw, _encKeyId, meta: {'type': 'udp'});
    } else if (_crypto.mode != EncryptionMode.none) {
      raw = _crypto.encryptBytes(raw, meta: {'type': 'udp'});
    }
    _socket.send(raw, _targetAddr, _targetPort);
  }

  void _onRaw(io.RawSocketEvent event) async {
    if (event != io.RawSocketEvent.read) return;
    final dg = _socket.receive();
    if (dg == null) return;
    if (dg.address.address != _targetAddr.address ||
        dg.port != _targetPort) return;
    try {
      var safe = dg.data;
      if (_crypto.mode == EncryptionMode.hardware && _nativeDelegate != null) {
        safe = await _nativeDelegate!
            .hardwareDecrypt(safe, _encKeyId, meta: {'type': 'udp'});
      } else if (_crypto.mode != EncryptionMode.none) {
        safe = _crypto.decryptBytes(safe, meta: {'type': 'udp'});
      }
      _frames.add(UdpMediaPacket.fromBytes(safe));
    } catch (e, s) {
      OmniLogger.error('UDP packet parse/decrypt failed', e, s);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _socket.close();
    await _frames.close();
  }
}

// ===========================================================================
// SqliteOfflineManager — sqflite-backed mutation queue
// ===========================================================================

class SqliteOfflineManager extends OfflineQueueManager {
  Database? _db;
  final StreamController<int> _queueLen =
      StreamController<int>.broadcast();
  bool _isSyncing = false;

  @override
  Stream<int> get queueLength => _queueLen.stream;

  Future<Database> _initDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'omni_offline_queue.db');
    _db = await openDatabase(dbPath, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS offline_queue (
          id TEXT PRIMARY KEY,
          method TEXT NOT NULL,
          path TEXT NOT NULL,
          body TEXT,
          headers TEXT,
          timestamp INTEGER,
          status INTEGER DEFAULT 0
        )
      ''');
    });
    return _db!;
  }

  @override
  Future<int> getCount() async {
    final db = await _initDb();
    final r =
        await db.rawQuery('SELECT COUNT(*) as c FROM offline_queue WHERE status=0');
    return (r.first['c'] as int?) ?? 0;
  }

  @override
  Future<void> enqueue(dynamic ctx) async {
    final context = ctx as RequestContext;
    final db = await _initDb();
    final mut = QueuedMutation(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      method: context.method,
      path: context.uri.path,
      body: context.body is Map<String, dynamic>
          ? context.body as Map<String, dynamic>
          : {},
      headers: context.headers,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await db.insert('offline_queue', mut.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    _queueLen.add(await getCount());
  }

  @override
  Future<void> processQueue(dynamic client) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final db = await _initDb();
      final rows = await db
          .query('offline_queue', where: 'status=0', orderBy: 'timestamp ASC');
      for (final row in rows) {
        final item = QueuedMutation.fromMap(row.cast<String, dynamic>());
        try {
          item.status = 1;
          await (client as dynamic).request<dynamic>(
            method: item.method,
            path: item.path,
            kind: RequestKind.rest,
            body: item.body,
            headers: item.headers,
            trustTier: ApiTrustTier.public,
            decode: (j) => j,
          );
          item.status = 2;
          await db.update(
              'offline_queue', {'status': 2},
              where: 'id=?', whereArgs: [item.id]);
        } catch (_) {
          item.status = 0;
          await db.update(
              'offline_queue', {'status': 0},
              where: 'id=?', whereArgs: [item.id]);
        }
      }
      _queueLen.add(await getCount());
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> dispose() async {
    await _db?.close();
    await _queueLen.close();
  }
}

// ===========================================================================
// EmbeddedMediaProxy — local HTTP proxy server for authenticated media
// ===========================================================================

class EmbeddedMediaProxy {
  final ApiClient client;
  io.HttpServer? _server;
  Future<void>? _startFuture;

  EmbeddedMediaProxy(this.client);

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (_server != null) return;
    _startFuture ??= () async {
      _server =
          await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handle);
    }();
    await _startFuture;
  }

  Future<String> getProxyUrl(String mediaPath) async {
    await start();
    return 'http://127.0.0.1:$port/stream?path=${Uri.encodeComponent(mediaPath)}';
  }

  Future<void> _handle(io.HttpRequest req) async {
    try {
      final path = req.uri.queryParameters['path'];
      if (path == null) {
        req.response.statusCode = io.HttpStatus.badRequest;
        await req.response.close();
        return;
      }
      final reqHeaders = <String, String>{};
      final range = req.headers.value(io.HttpHeaders.rangeHeader);
      if (range != null) reqHeaders[io.HttpHeaders.rangeHeader] = range;

      final apiResponse = await client.sendRaw(
        method: 'GET',
        path: path,
        kind: RequestKind.media,
        headers: reqHeaders,
        requirePolicyCheck: true,
      );
      req.response.statusCode = apiResponse.statusCode;
      apiResponse.headers.forEach((key, value) {
        if (key.toLowerCase() != 'transfer-encoding') {
          req.response.headers.set(key, value);
        }
      });
      await apiResponse.byteStream.pipe(req.response);
    } catch (e, s) {
      OmniLogger.error('EmbeddedMediaProxy request failed', e, s);
      req.response.statusCode = io.HttpStatus.internalServerError;
      req.response.write(e.toString());
      await req.response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _startFuture = null;
  }
}

// ===========================================================================
// ApiClient — full HTTP engine (native defaults)
// ===========================================================================

class ApiClient {
  final ApiClientConfig config;
  final HttpTransport transport;
  AuthProvider? authProvider;
  final CacheStore cacheStore;
  final RequestPipeline pipeline;
  final CoalescingPolicy coalescingPolicy;
  final RequestMerger requestMerger;
  final OfflineQueueManager offlineManager;
  final RouteProvider? routeProvider;
  final RouteProvider? socketRouteProvider;
  final RouteProvider? duplexRouteProvider;
  final RouteProvider? udpRouteProvider;
  final RouteProvider? rpcRouteProvider;
  final CryptoPolicy cryptoPolicy;
  final TransferCheckpointStore transferCheckpointStore;
  final NativeSystemDelegate? nativeDelegate;
  final RpcTransport? rpcTransport;

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
    OfflineQueueManager? offlineManager,
  })  : transport = transport ??
            IoTransport(
                allowedCertFingerprintsSha256:
                    config.allowedCertFingerprintsSha256),
        cacheStore = cacheStore ?? MemoryCacheStore(),
        cryptoPolicy = cryptoPolicy ?? const PassThroughCryptoPolicy(),
        transferCheckpointStore =
            transferCheckpointStore ?? MemoryTransferCheckpointStore(),
        pipeline = pipeline ?? RequestPipeline(policies: [TraceparentPolicy()]),
        coalescingPolicy = CoalescingPolicy(),
        requestMerger = RequestMerger(),
        offlineManager = offlineManager ?? SqliteOfflineManager() {
    // BUG FIX: was previously adding to a const [] — pipeline.policies is now mutable
    this.pipeline.policies
        .add(OfflineMutationPolicy(this.offlineManager, isNetworkError: (e) {
      return e is SocketException || e is HttpException || e is IOException;
    }));
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
      if (config.userAgent != null) 'user-agent': config.userAgent!,
      if (token != null && token.isNotEmpty) 'authorization': 'Bearer $token',
      if (deviceId != null && deviceId.isNotEmpty) 'X-Device-Id': deviceId,
      if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      'X-Api-Trust-Tier': trustTier.name,
      'X-Request-Kind': kind.name,
    };
    merged.putIfAbsent('accept', () => 'application/json, text/plain, */*');
    return merged;
  }

  Future<ApiResponse<T>> get<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      CachePolicy cachePolicy = CachePolicy.networkOnly,
      bool requireIntegrityCheck = false}) =>
      request<T>(
          method: 'GET',
          path: path,
          kind: RequestKind.rest,
          query: query,
          headers: headers,
          decode: decode,
          timeout: timeout,
          trustTier: trustTier,
          cachePolicy: cachePolicy,
          requireIntegrityCheck: requireIntegrityCheck);

  Future<ApiResponse<T>> post<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      dynamic body,
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      String? idempotencyKey,
      String? mergeKey}) =>
      request<T>(
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
          mergeKey: mergeKey);

  Future<ApiResponse<T>> put<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      dynamic body,
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      String? idempotencyKey,
      String? mergeKey}) =>
      request<T>(
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
          mergeKey: mergeKey);

  Future<ApiResponse<T>> patch<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      dynamic body,
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      String? idempotencyKey,
      String? mergeKey}) =>
      request<T>(
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
          mergeKey: mergeKey);

  Future<ApiResponse<T>> delete<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      dynamic body,
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier}) =>
      request<T>(
          method: 'DELETE',
          path: path,
          kind: RequestKind.rest,
          query: query,
          headers: headers,
          body: body,
          decode: decode,
          timeout: timeout,
          trustTier: trustTier);

  Future<ApiResponse<T>> query<T>(String path,
      {required dynamic body,
      Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      String contentType = 'application/json; charset=utf-8',
      String accept = 'application/json',
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      String? mergeKey,
      CachePolicy cachePolicy = CachePolicy.networkOnly}) =>
      request<T>(
          method: 'QUERY',
          path: path,
          kind: RequestKind.query,
          query: query,
          headers: {
            ...headers,
            'content-type': contentType,
            'accept': accept
          },
          body: body,
          decode: decode,
          timeout: timeout,
          trustTier: trustTier,
          mergeKey: mergeKey,
          cachePolicy: cachePolicy);

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
    final ctx = await _prepareContext(
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
    if (requirePolicyCheck) await _assertAllowed(ctx);
    return transport.send(
        method: ctx.method,
        uri: ctx.uri,
        headers: ctx.headers,
        body: ctx.body,
        timeout: ctx.timeout);
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
    final initialCtx = await _prepareContext(
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

    final cacheKey = _cacheKey(initialCtx);

    if (cachePolicy == CachePolicy.cacheOnly) {
      final cached = await cacheStore.get(cacheKey);
      if (cached == null || cached.isExpired) {
        throw ApiException(
            message: 'Cache miss for cacheOnly policy',
            statusCode: 404,
            uri: initialCtx.uri);
      }
      final decoded = cached.value is String
          ? await ComputeCore.decodeJsonAsync(cached.value)
          : cached.value;
      return ApiResponse<T>(
          statusCode: 200,
          headers: cached.headers,
          data: _castOrDecode<T>(decoded, decode),
          uri: initialCtx.uri);
    }

    if (cachePolicy == CachePolicy.cacheFirst ||
        cachePolicy == CachePolicy.staleWhileRevalidate) {
      final cached = await cacheStore.get(cacheKey);
      if (cached != null && !cached.isExpired) {
        final decoded = cached.value is String
            ? await ComputeCore.decodeJsonAsync(cached.value)
            : cached.value;
        if (cachePolicy == CachePolicy.cacheFirst) {
          return ApiResponse<T>(
              statusCode: 200,
              headers: cached.headers,
              data: _castOrDecode<T>(decoded, decode),
              uri: initialCtx.uri);
        }
        unawaited(_refreshCache<T>(initialCtx, cacheKey, decode,
            bypassOfflineQueue: bypassOfflineQueue, maxRetries: maxRetries));
        return ApiResponse<T>(
            statusCode: 200,
            headers: cached.headers,
            data: _castOrDecode<T>(decoded, decode),
            uri: initialCtx.uri);
      }
    }

    final activePolicies = bypassOfflineQueue
        ? pipeline.policies.where((p) => p is! OfflineMutationPolicy).toList()
        : pipeline.policies;
    final activePipeline = RequestPipeline(policies: activePolicies);

    final response = await activePipeline.execute(
      initialCtx,
      maxRetries ?? config.maxRetries,
      (ctx) async {
        Future<ApiResponse<dynamic>> perform() async {
          final raw = await transport.send(
              method: ctx.method,
              uri: ctx.uri,
              headers: ctx.headers,
              body: ctx.body,
              timeout: ctx.timeout);
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
              uri: ctx.uri);
          if (ctx.requireIntegrityCheck) await _verifyIntegrity(ctx, result);
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
              headers: response.headers));
    }

    return ApiResponse<T>(
        statusCode: response.statusCode,
        headers: response.headers,
        data: _castOrDecode<T>(response.data, decode),
        uri: response.uri);
  }

  Future<dynamic> decodeJson(String src) => ComputeCore.decodeJsonAsync(src);

  Future<void> dispose() async {
    transport.dispose();
    await offlineManager.dispose();
  }

  // --- Internals ---

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
    final finalHeaders = await buildHeaders(headers,
        idempotencyKey: idempotencyKey,
        trustTier: trustTier ?? config.defaultTrustTier,
        uri: uri,
        kind: kind);

    RouteManifest? manifest;
    if (routeProvider != null) {
      final dummy = RequestContext(
          method: method,
          uri: uri,
          kind: kind,
          trustTier: trustTier ?? config.defaultTrustTier,
          headers: finalHeaders,
          body: null,
          cachePolicy: cachePolicy,
          timeout: timeout ?? config.receiveTimeout);
      manifest = await routeProvider!
          .resolve(RouteContext(request: dummy, purpose: kind.name));
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
        activeManifest: manifest);
  }

  Future<void> _assertAllowed(RequestContext ctx) async {
    final provider = _providerFor(ctx.kind);
    if (provider == null) return;
    final m = await provider
        .resolve(RouteContext(request: ctx, purpose: ctx.kind.name));
    if (m != null &&
        !m.allows(ctx.uri, method: ctx.method, purpose: ctx.kind.name)) {
      throw PolicyViolation('Route not allowed by server policy', uri: ctx.uri);
    }
  }

  RouteProvider? _providerFor(RequestKind kind) => switch (kind) {
        RequestKind.socket => socketRouteProvider,
        RequestKind.duplex => duplexRouteProvider,
        RequestKind.udp => udpRouteProvider,
        RequestKind.rpc => rpcRouteProvider,
        _ => routeProvider,
      };

  dynamic _normalizeBody(dynamic body, Map<String, String> headers) {
    if (body == null) return null;
    if (body is MultipartRequestBody ||
        body is Stream<List<int>> ||
        body is List<int> ||
        body is String) return body;
    headers.putIfAbsent('content-type', () => 'application/json; charset=utf-8');
    return body;
  }

  String _cacheKey(RequestContext ctx) {
    final bodyKey = ctx.body == null
        ? 'null'
        : ctx.body is String
            ? ctx.body as String
            : _sha256Hex(utf8.encode(jsonEncode(ctx.body)));
    return '${ctx.method}:${ctx.uri}:${ctx.trustTier.name}:$bodyKey';
  }

  T _castOrDecode<T>(dynamic value, JsonFactory<T>? decode) {
    if (decode != null) return decode(value);
    return value as T;
  }

  Future<void> _refreshCache<T>(RequestContext ctx, String cacheKey,
      JsonFactory<T>? decode,
      {required bool bypassOfflineQueue, int? maxRetries}) async {
    try {
      final fresh = await request<T>(
        method: ctx.method,
        path: ctx.uri.path,
        kind: ctx.kind,
        query: ctx.uri.queryParameters.cast<String, dynamic>(),
        headers: ctx.headers,
        body: ctx.body,
        decode: decode,
        timeout: ctx.timeout,
        cachePolicy: CachePolicy.networkOnly,
        trustTier: ctx.trustTier,
        bypassOfflineQueue: bypassOfflineQueue,
        maxRetries: maxRetries,
      );
      await cacheStore.set(cacheKey,
          CacheEntry(value: fresh.data, createdAt: DateTime.now(), headers: fresh.headers, ttl: const Duration(minutes: 5)));
    } catch (e, s) {
      OmniLogger.error('Failed to refresh stale cache for $cacheKey', e, s);
    }
  }

  Future<void> _verifyIntegrity(
      RequestContext ctx, ApiResponse<dynamic> response) async {
    final sig = response.headers['x-signature'] ??
        response.headers['x-content-signature'];
    if (sig == null) {
      throw IntegrityViolation('Missing integrity signature', uri: ctx.uri);
    }
  }

  Future<Uri> _resolveBase(RequestKind kind) async {
    final manifest = await _resolveManifest(kind);
    if (manifest != null) {
      return switch (kind) {
        RequestKind.socket => manifest.websocketBase ?? manifest.httpBase,
        RequestKind.duplex => manifest.duplexBase ?? manifest.httpBase,
        RequestKind.media => manifest.mediaBase ?? manifest.httpBase,
        RequestKind.udp => manifest.udpBase ?? manifest.httpBase,
        RequestKind.rpc => manifest.rpcBase ?? manifest.httpBase,
        _ => manifest.httpBase,
      };
    }
    return config.baseUrl;
  }

  Future<RouteManifest?> _resolveManifest(RequestKind kind) async {
    final provider = _providerFor(kind);
    if (provider == null) return null;
    final dummyUri = await buildUri('/', const {}, kind: kind);
    final dummy = RequestContext(
        method: 'GET',
        uri: dummyUri,
        kind: kind,
        trustTier: config.defaultTrustTier,
        headers: const {},
        body: null,
        cachePolicy: CachePolicy.networkOnly,
        timeout: config.receiveTimeout);
    return provider.resolve(RouteContext(request: dummy, purpose: kind.name));
  }
}

// ===========================================================================
// ResumableTransferManager — download with pause/resume/cancel
// ===========================================================================

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
    required QuantumFile file,
    Map<String, dynamic> query = const {},
    Map<String, String> headers = const {},
    String? checkpointKey,
    ApiTrustTier? trustTier,
    bool allowOSBackground = false,
  }) async {
    final controller = ResumableTransferController(
        id: id, direction: TransferDirection.download);
    final key = checkpointKey ?? id;
    final checkpoint = await store.load(key);
    final offset = (checkpoint?['offset'] as num?)?.toInt() ?? 0;
    final reqHeaders = <String, String>{
      ...headers,
      if (offset > 0) 'range': 'bytes=$offset-',
    };

    if (allowOSBackground && nativeDelegate != null) {
      final uri =
          await client.buildUri(path, query, kind: RequestKind.media);
      final finalHeaders = await client.buildHeaders(reqHeaders,
          trustTier: trustTier ?? client.config.defaultTrustTier,
          uri: uri,
          kind: RequestKind.media);
      await nativeDelegate!.handoffTransferToOS(
          taskId: id,
          uri: uri,
          direction: TransferDirection.download,
          filePath: file.path,
          headers: finalHeaders);
      return controller;
    }

    final response = await client.sendRaw(
        method: 'GET',
        path: path,
        kind: RequestKind.media,
        query: query,
        headers: reqHeaders,
        trustTier: trustTier);

    if (response.statusCode >= 400) {
      throw ApiException(
          message: 'Download failed', statusCode: response.statusCode);
    }

    final sink = file.openWrite(
        mode: offset > 0 ? QuantumFileMode.append : QuantumFileMode.writeOnly);

    () async {
      try {
        var received = offset;
        final contentLengthStr = response.headers['content-length'];
        final contentLength =
            contentLengthStr != null ? int.tryParse(contentLengthStr) : null;
        final totalBytes =
            contentLength != null ? offset + contentLength : null;

        await for (final chunk in response.byteStream) {
          if (controller.isCancelled) break;
          while (controller.isPaused) {
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
          sink.add(chunk);
          received += chunk.length;
          await store.save(key, {'offset': received});
          if (totalBytes != null && totalBytes > 0) {
            controller.emitProgress(min(received / totalBytes, 0.99));
          }
        }
        await sink.flush(); // BUG FIX: flush before close
        await sink.close();
        if (!controller.isCancelled) {
          await store.clear(key);
          controller.emitProgress(1.0);
        }
      } catch (e, s) {
        OmniLogger.error('Download stream failed: $id', e, s);
      } finally {
        try {
          await sink.close();
        } catch (_) {}
        await controller.dispose();
      }
    }();

    return controller;
  }
}

// ===========================================================================
// AppSdk — top-level SDK handle
// ===========================================================================

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
        nativeDelegate: client.nativeDelegate);
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
  }) =>
      ReactiveCrudRepository<T>(
          api: root, resourcePath: path, fromJson: fromJson, toJson: toJson);

  RealtimeClient realtime({required String socketPath}) {
    final rt = RealtimeClient(
      socketUrl: client.config.baseUrl.resolve(socketPath),
      authProvider: client.authProvider,
      socketTransport: (uri) {
        // Connect synchronously — the actual WebSocket.connect is async,
        // so we wrap it in a lazy-connecting adapter.
        throw UnimplementedError(
            'Use AppSdk.realtimeAsync() for native WebSocket connections.');
      },
    );
    lifecycle.registerRealtimeClient(rt);
    return rt;
  }

  /// Creates and connects a [RealtimeClient] using the native dart:io WebSocket.
  Future<RealtimeClient> realtimeAsync({required String socketPath}) async {
    final session = await client.authProvider?.getSession();
    final token = session?.accessToken;
    final deviceId = session?.deviceId;

    var uri = client.config.baseUrl.resolve(socketPath);
    final params = <String, String>{...uri.queryParameters};
    if (token != null && token.isNotEmpty) params['token'] = token;
    if (deviceId != null && deviceId.isNotEmpty) params['deviceId'] = deviceId;
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final ws = await io.WebSocket.connect(uri.toString());
    final conn = IoSocketConnection(ws);
    final rt = RealtimeClient(
      socketUrl: uri,
      authProvider: client.authProvider,
      socketTransport: (_) => conn,
    );
    await rt.connect();
    lifecycle.registerRealtimeClient(rt);
    return rt;
  }

  Future<Stream<UdpMediaPacket>> liveMediaStream(String path,
      {int jitterDelayMs = 150,
      String encryptionKeyId = 'default-udp-session-key'}) async {
    final uri =
        await client.buildUri(path, const {}, kind: RequestKind.udp);
    final conn = await IoUdpTransport.connect(
        uri, client.cryptoPolicy, client.nativeDelegate,
        encryptionKeyId: encryptionKeyId);
    lifecycle.registerUdpConnection(conn);
    final jitter = JitterBuffer(maxDelayMs: jitterDelayMs);
    conn.frames.listen((p) => jitter.insert(p),
        onDone: () => jitter.dispose());
    return jitter.orderedFrames;
  }

  Future<UdpConnection> createLiveMediaIngest(String path,
      {String encryptionKeyId = 'default-udp-session-key'}) async {
    final uri =
        await client.buildUri(path, const {}, kind: RequestKind.udp);
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

// ===========================================================================
// Private helpers
// ===========================================================================

String _sha256Hex(List<int> input) =>
    crypto.sha256.convert(input).toString();
