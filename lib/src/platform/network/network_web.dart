// File: network_web.dart (network\network_web.dart)

// =============================================================================
// network_web.dart
// Web platform implementation of the network library using modern web JS Interop.
//
// Exports all shared src/ types PLUS adds:
//   • ComputeCore   — synchronous JSON (no isolates on web)
//   • QuantumFile   — in-memory Uint8List-backed
//   • IoTransport   — package:http BrowserClient
//   • IoSocketConnection — package:web & dart:js_interop WebSocket
//   • SqliteOfflineManager — in-memory mutation queue (same name for compat)
//   • StubMediaProxy — returns direct URLs (no embedded HttpServer on web)
//   • ApiClient     — full HTTP engine (default: BrowserClient)
//   • AppSdk        — top-level SDK handle
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart';
import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:crypto/crypto.dart' as crypto;

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
// ComputeCore — synchronous JSON (web has no Isolate.run)
// ===========================================================================

class ComputeCore {
  static Future<dynamic> decodeJsonAsync(String src) async => jsonDecode(src);

  static Future<String> encodeJsonAsync(dynamic value) async =>
      jsonEncode(value);
}

// ===========================================================================
// QuantumFile — in-memory Uint8List backed
// ===========================================================================

class _MemSink implements QuantumFileSink {
  final _MemQuantumFile _file;
  final bool _append;
  _MemSink(this._file, this._append) {
    if (!_append) _file._bytes = null;
  }

  @override
  void add(List<int> data) {
    final existing = _file._bytes;
    if (existing == null) {
      _file._bytes = Uint8List.fromList(data);
    } else {
      final combined = Uint8List(existing.length + data.length);
      combined.setAll(0, existing);
      combined.setAll(existing.length, data);
      _file._bytes = combined;
    }
  }

  @override
  Future<void> flush() async {} // No-op for in-memory

  @override
  Future<void> close() async {}
}

class _MemQuantumFile extends QuantumFile {
  final String _path;
  Uint8List? _bytes;

  _MemQuantumFile(this._path, [Uint8List? initial]) : _bytes = initial;

  @override
  String get path => _path;

  @override
  Stream<List<int>> openRead() async* {
    final b = _bytes ?? Uint8List(0);
    yield b;
  }

  @override
  QuantumFileSink openWrite(
          {QuantumFileMode mode = QuantumFileMode.writeOnly}) =>
      _MemSink(this, mode == QuantumFileMode.append);

  @override
  int lengthSync() => _bytes?.length ?? 0;
}

QuantumFile createQuantumFile(String path) => _MemQuantumFile(path);

// ===========================================================================
// IoTransport — package:http BrowserClient
// ===========================================================================

class _BrowserTransportResponse implements TransportResponse {
  final http.StreamedResponse _resp;
  _BrowserTransportResponse(this._resp);

  @override
  int get statusCode => _resp.statusCode;

  @override
  Map<String, String> get headers => _resp.headers;

  @override
  Stream<List<int>> get byteStream => _resp.stream;

  @override
  Future<Uint8List> bytes() async {
    final chunks = <int>[];
    await for (final chunk in _resp.stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  @override
  Future<String> text({Encoding encoding = utf8}) async {
    final b = await bytes();
    return encoding.decode(b);
  }
}

class IoTransport implements HttpTransport {
  final BrowserClient _client = BrowserClient();

  IoTransport({List<String>? allowedCertFingerprintsSha256}) {
    // Certificate pinning not possible in browsers; silently ignored.
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
    http.BaseRequest request;

    if (body is MultipartRequestBody) {
      final multipart = http.MultipartRequest(method, uri);
      multipart.headers.addAll(headers);
      for (final field in body.fields) {
        multipart.fields[field.name] = field.value;
      }
      for (final file in body.files) {
        final bytes = await _collectStream(file.stream);
        multipart.files.add(http.MultipartFile.fromBytes(
          file.fieldName,
          bytes,
          filename: file.fileName,
          contentType: _parseMediaType(file.contentType),
        ));
      }
      request = multipart;
    } else {
      final req = http.Request(method, uri);
      req.headers.addAll(headers);
      if (body is String) {
        req.body = body;
      } else if (body is List<int>) {
        req.bodyBytes = Uint8List.fromList(body);
      } else if (body != null && body is! Stream) {
        req.headers.putIfAbsent(
            'content-type', () => 'application/json; charset=utf-8');
        req.body = jsonEncode(body);
      }
      request = req;
    }

    final future = _client.send(request);
    final response =
        timeout != null ? await future.timeout(timeout) : await future;
    return _BrowserTransportResponse(response);
  }

  @override
  void dispose() => _client.close();

  Future<Uint8List> _collectStream(Stream<List<int>> stream) async {
    final buffer = <int>[];
    await for (final chunk in stream) {
      buffer.addAll(chunk);
    }
    return Uint8List.fromList(buffer);
  }

  http_parser.MediaType? _parseMediaType(String ct) {
    try {
      return http_parser.MediaType.parse(ct);
    } catch (_) {
      return null;
    }
  }
}

// ===========================================================================
// IoSocketConnection — package:web & dart:js_interop WebSocket
// ===========================================================================

class IoSocketConnection implements SocketConnection {
  final web.WebSocket _ws;
  final StreamController<dynamic> _messages =
      StreamController<dynamic>.broadcast();

  IoSocketConnection(this._ws) {
    _ws.onmessage = ((web.MessageEvent e) {
      final data = e.data;
      if (data != null && data.isA<JSString>()) {
        _messages.add((data as JSString).toDart);
      } else {
        _messages.add(data);
      }
    }).toJS;

    _ws.onclose = ((web.CloseEvent e) {
      if (!_messages.isClosed) _messages.close();
    }).toJS;

    _ws.onerror = ((web.Event e) {
      if (!_messages.isClosed) _messages.addError('WebSocket connection error');
    }).toJS;
  }

  @override
  Stream<dynamic> get messages => _messages.stream;

  @override
  Future<void> send(dynamic data) async {
    if (data is String) {
      _ws.send(data.toJS);
    } else if (data is Uint8List) {
      _ws.send(data.toJS);
    } else if (data is List<int>) {
      _ws.send(Uint8List.fromList(data).toJS);
    } else {
      final jsonStr = await ComputeCore.encodeJsonAsync(data);
      _ws.send(jsonStr.toJS);
    }
  }

  @override
  Future<void> close([int? code, String? reason]) async {
    if (code != null && reason != null) {
      _ws.close(code, reason);
    } else if (code != null) {
      _ws.close(code);
    } else {
      _ws.close();
    }
  }
}

// ===========================================================================
// SqliteOfflineManager — in-memory implementation (web has no SQLite)
// ===========================================================================

class SqliteOfflineManager extends OfflineQueueManager {
  final List<QueuedMutation> _queue = [];
  final StreamController<int> _queueLen = StreamController<int>.broadcast();
  bool _isSyncing = false;

  @override
  Stream<int> get queueLength => _queueLen.stream;

  @override
  Future<int> getCount() async => _queue.where((m) => m.status == 0).length;

  @override
  Future<void> enqueue(dynamic ctx) async {
    final context = ctx as RequestContext;
    _queue.add(QueuedMutation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      method: context.method,
      path: context.uri.path,
      body: context.body is Map<String, dynamic>
          ? context.body as Map<String, dynamic>
          : {},
      headers: context.headers,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    if (!_queueLen.isClosed) _queueLen.add(await getCount());
  }

  @override
  Future<void> processQueue(dynamic client) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      for (final item in _queue.where((m) => m.status == 0).toList()) {
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
        } catch (_) {
          item.status = 0;
        }
      }
      if (!_queueLen.isClosed) _queueLen.add(await getCount());
    } finally {
      _isSyncing = false;
    }
  }

  @override
  Future<void> dispose() async {
    await _queueLen.close();
  }
}

// ===========================================================================
// StubMediaProxy — returns direct authenticated URLs (no HttpServer on web)
// ===========================================================================

class StubMediaProxy {
  final ApiClient client;
  StubMediaProxy(this.client);

  int get port => 0;
  Future<void> start() async {}
  Future<void> stop() async {}

  Future<String> getProxyUrl(String mediaPath) async {
    final uri =
        await client.buildUri(mediaPath, const {}, kind: RequestKind.media);
    final headers = await client.buildHeaders(const {},
        trustTier: client.config.defaultTrustTier,
        uri: uri,
        kind: RequestKind.media);
    final token = headers['authorization'];
    if (token != null && token.isNotEmpty) {
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        'token': token.replaceFirst('Bearer ', ''),
      }).toString();
    }
    return uri.toString();
  }
}

// Alias for API compat with native (AppSdk uses mediaProxy.start/stop/getProxyUrl)
typedef EmbeddedMediaProxy = StubMediaProxy;

// ===========================================================================
// ApiClient — full HTTP engine (web defaults: BrowserClient)
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
  })  : transport = transport ?? IoTransport(),
        cacheStore = cacheStore ?? MemoryCacheStore(),
        cryptoPolicy = cryptoPolicy ?? const PassThroughCryptoPolicy(),
        transferCheckpointStore =
            transferCheckpointStore ?? MemoryTransferCheckpointStore(),
        pipeline = pipeline ?? RequestPipeline(policies: [TraceparentPolicy()]),
        coalescingPolicy = CoalescingPolicy(),
        requestMerger = RequestMerger(),
        offlineManager = offlineManager ?? SqliteOfflineManager() {
    this.pipeline.policies.add(
          OfflineMutationPolicy(this.offlineManager, isNetworkError: (e) {
            return e is http.ClientException ||
                e.toString().toLowerCase().contains('network') ||
                e.toString().toLowerCase().contains('connection');
          }),
        );
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
          headers: {...headers, 'content-type': contentType, 'accept': accept},
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
            message: 'Cache miss (cacheOnly)',
            statusCode: 404,
            uri: initialCtx.uri);
      }
      final decoded = await ComputeCore.decodeJsonAsync(
          cached.value is String ? cached.value : jsonEncode(cached.value));
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
        final decoded = await ComputeCore.decodeJsonAsync(
            cached.value is String ? cached.value : jsonEncode(cached.value));
        if (cachePolicy == CachePolicy.cacheFirst) {
          return ApiResponse<T>(
              statusCode: 200,
              headers: cached.headers,
              data: _castOrDecode<T>(decoded, decode),
              uri: initialCtx.uri);
        }
        unawaited(_refreshCache<T>(initialCtx, cacheKey, decode,
            bypassOfflineQueue: bypassOfflineQueue));
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
          return ApiResponse<dynamic>(
              statusCode: raw.statusCode,
              headers: raw.headers,
              data: decoded,
              uri: ctx.uri);
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
        body: body,
        cachePolicy: cachePolicy,
        timeout: timeout ?? config.receiveTimeout,
        idempotencyKey: idempotencyKey,
        mergeKey: mergeKey,
        requireIntegrityCheck: requireIntegrityCheck,
        activeManifest: manifest);
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

  Future<void> _refreshCache<T>(
      RequestContext ctx, String cacheKey, JsonFactory<T>? decode,
      {required bool bypassOfflineQueue}) async {
    try {
      final fresh = await request<T>(
        method: ctx.method,
        path: ctx.uri.path,
        kind: ctx.kind,
        query: ctx.uri.queryParameters.cast<String, dynamic>(),
        headers: ctx.headers,
        body: ctx.body,
        decode: decode,
        cachePolicy: CachePolicy.networkOnly,
        trustTier: ctx.trustTier,
        bypassOfflineQueue: bypassOfflineQueue,
      );
      await cacheStore.set(
          cacheKey,
          CacheEntry(
              value: fresh.data,
              createdAt: DateTime.now(),
              headers: fresh.headers,
              ttl: const Duration(minutes: 5)));
    } catch (_) {}
  }

  Future<Uri> _resolveBase(RequestKind kind) async {
    final provider = _providerFor(kind);
    if (provider == null) return config.baseUrl;
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
    final manifest = await provider
        .resolve(RouteContext(request: dummy, purpose: kind.name));
    if (manifest == null) return config.baseUrl;
    return switch (kind) {
      RequestKind.socket => manifest.websocketBase ?? manifest.httpBase,
      RequestKind.duplex => manifest.duplexBase ?? manifest.httpBase,
      RequestKind.media => manifest.mediaBase ?? manifest.httpBase,
      RequestKind.rpc => manifest.rpcBase ?? manifest.httpBase,
      _ => manifest.httpBase,
    };
  }

  RouteProvider? _providerFor(RequestKind kind) => switch (kind) {
        RequestKind.socket => socketRouteProvider,
        RequestKind.duplex => duplexRouteProvider,
        RequestKind.rpc => rpcRouteProvider,
        _ => routeProvider,
      };
}

// ===========================================================================
// AppSdk — web flavour
// ===========================================================================

class AppSdk {
  final ApiClient client;
  late final ApiModule root;
  late final QueryEngine queries;
  late final BinaryRpcClient? rpc;
  late final EmbeddedMediaProxy mediaProxy; // = StubMediaProxy on web
  late final AppLifecycleManager lifecycle;
  late final BatchManager batch;

  AppSdk(this.client) {
    root = ApiModule(client);
    queries = QueryEngine(client);
    rpc = client.rpcTransport != null
        ? BinaryRpcClient(client.rpcTransport!)
        : null;
    mediaProxy = StubMediaProxy(client);
    lifecycle = AppLifecycleManager();
    batch = BatchManager(client: client);
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

  Future<RealtimeClient> realtimeAsync({required String socketPath}) async {
    final session = await client.authProvider?.getSession();
    final token = session?.accessToken;
    final deviceId = session?.deviceId;

    var uri = client.config.baseUrl.resolve(socketPath);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    uri = uri.replace(scheme: wsScheme);

    final params = <String, String>{...uri.queryParameters};
    if (token != null && token.isNotEmpty) params['token'] = token;
    if (deviceId != null && deviceId.isNotEmpty) params['deviceId'] = deviceId;
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);

    final ws = web.WebSocket(uri.toString());

    final openCompleter = Completer<void>();
    ws.onopen = ((web.Event e) {
      if (!openCompleter.isCompleted) openCompleter.complete();
    }).toJS;

    ws.onerror = ((web.Event e) {
      if (!openCompleter.isCompleted) {
        openCompleter.completeError(
            ApiException(message: 'WebSocket connection failed', uri: uri));
      }
    }).toJS;

    await openCompleter.future.timeout(const Duration(seconds: 15));

    final conn = IoSocketConnection(ws);
    final rt = RealtimeClient(
        socketUrl: uri,
        authProvider: client.authProvider,
        socketTransport: (_) => conn);
    await rt.connect();
    lifecycle.registerRealtimeClient(rt);
    return rt;
  }

  void dispose() {
    unawaited(mediaProxy.stop());
    unawaited(lifecycle.dispose());
    unawaited(client.dispose());
  }
}

// ===========================================================================
// Helpers
// ===========================================================================

String _sha256Hex(List<int> input) => crypto.sha256.convert(input).toString();
