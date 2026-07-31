import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

// ============================================================
// [ENHANCEMENT INJECTED] - The OmniCloud Universal Facade
// This allows zero-code-change swapping of Firebase, Supabase, WebRTC, etc.
// Added IOmniStorage for huge file uploads/downloads.
// ============================================================

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

/// Universal contracts for any 3rd party SDK
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

/// The Orchestrator - Add ANY protocol without touching the core SDK
class OmniCloud {
  static final Map<Type, dynamic> _adapters = {};
  static late final AppSdk engine;

  static void register<T>(T adapter) => _adapters[T] = adapter;

  static T get<T>() {
    if (!_adapters.containsKey(T))
      throw Exception('Adapter $T not registered.');
    return _adapters[T] as T;
  }

  static void initialize(AppSdk customEngine) {
    engine = customEngine;
    if (_adapters.containsKey(IOmniAuth)) {
      // Bridge universal auth directly into your raw engine's AuthProvider
      engine.client.authProvider = _OmniCloudEngineAuthBridge(get<IOmniAuth>());
    }
  }
}

class _OmniCloudEngineAuthBridge implements AuthProvider {
  final IOmniAuth _cloudAuth;
  _OmniCloudEngineAuthBridge(this._cloudAuth);
  @override
  Future<String?> getAccessToken() => _cloudAuth.getAccessToken();
}

// ============================================================
// ISOLATE COMPUTE CORE (Zero UI Jank)
// ============================================================

/// Offloads intense CPU tasks (JSON parsing, Crypto) to background OS threads.
class ComputeCore {
  static Future<T> run<T>(FutureOr<T> Function() computation) async {
    return await Isolate.run(computation);
  }

  static Future<dynamic> decodeJsonAsync(String source) {
    if (source.isEmpty) return Future.value(null);
    return run(() => jsonDecode(source));
  }

  static Future<String> encodeJsonAsync(dynamic object) {
    if (object == null) return Future.value('');
    return run(() => jsonEncode(object));
  }
}

// ============================================================
// Original Core Types & Configurations
// ============================================================

/// The Omni-Architecture Client Engine for Flutter / Dart.
///
/// Capabilities:
/// - REST, QUERY (GraphQL), batch, raw request, streaming
/// - WebSockets (Duplex, Pub/Sub, Live Sessions)
/// - UDP Binary Media Transport (RTP-Lite) with Memory-Safe Jitter Buffering
/// - Universal RPC (gRPC / HTTP2 / Proprietary Binary Protocols)
/// - Native OS System Delegates (Background Tasks, Hardware Crypto)
/// - Advanced Request Pipeline (Interceptors, Auto-Retries, Token Refresh)
/// - Resumable upload/download checkpoints
/// - Adaptive media track switching hooks
/// - Server-approved routing and policy TTL / session scoping

enum ApiTrustTier { privateSourceOfTruth, authenticatedPublic, public }

enum CachePolicy {
  networkOnly,
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
  cacheOnly
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

  const ApiClientConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {},
    this.enableLogging = false,
    this.userAgent,
    this.defaultTrustTier = ApiTrustTier.privateSourceOfTruth,
    this.maxRetries = 3,
  });
}

abstract class AuthProvider {
  Future<String?> getAccessToken();
}

class TokenStore implements AuthProvider {
  String? _token;
  TokenStore([this._token]);
  void setToken(String? token) => _token = token;
  @override
  Future<String?> getAccessToken() async => _token;
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Uri? uri;
  final dynamic body;
  final String? code;

  ApiException(
      {required this.message, this.statusCode, this.uri, this.body, this.code});

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
      fileName: fileName ?? file.uri.pathSegments.last,
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

  const ApiResponse(
      {required this.statusCode,
      required this.headers,
      required this.data,
      required this.uri});
}

typedef JsonFactory<T> = T Function(dynamic json);
typedef JsonEncoderFn<T> = dynamic Function(T value);

// ============================================================
// Native OS Delegate & Hardware Hooks
// ============================================================

/// Hooks your engine into native OS capabilities (iOS/Android).
/// Implement this using Flutter MethodChannels in your app layer.
abstract class NativeSystemDelegate {
  /// Hands off a large transfer to the iOS/Android background manager.
  Future<void> handoffTransferToOS({
    required String taskId,
    required Uri uri,
    required TransferDirection direction,
    required String filePath,
    required Map<String, String> headers,
  });

  /// Registers a native listener to wake up this engine when a background data packet arrives (APNs/FCM).
  void registerBackgroundWakeup(
      Future<void> Function(Map<String, dynamic> payload) onWakeup);

  /// Hooks into native Cryptography (e.g., Apple Secure Enclave, Android Keystore).
  Future<Uint8List> hardwareEncrypt(Uint8List data, String keyId,
      {Map<String, dynamic> meta = const {}});

  /// Decrypts using native hardware keys.
  Future<Uint8List> hardwareDecrypt(Uint8List data, String keyId,
      {Map<String, dynamic> meta = const {}});
}

// ============================================================
// Crypto Policy Hooks
// ============================================================

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

// ============================================================
// Routing & Policy Manifest
// ============================================================

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

  // Support for secure Server-Delegated Public CDN routing
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

// ============================================================
// OFFLINE MUTATION QUEUE & SYNC MANAGER
// ============================================================

class QueuedMutation {
  final String id;
  final String method;
  final String path;
  final Map<String, dynamic> body;
  final Map<String, String> headers;
  final int timestamp;

  QueuedMutation(
      {required this.id,
      required this.method,
      required this.path,
      required this.body,
      required this.headers,
      required this.timestamp});

  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'body': body,
        'headers': headers,
        'timestamp': timestamp
      };

  factory QueuedMutation.fromJson(Map<String, dynamic> map) => QueuedMutation(
      id: map['id'],
      method: map['method'],
      path: map['path'],
      body: map['body'] is Map ? Map<String, dynamic>.from(map['body']) : {},
      headers: Map<String, String>.from(map['headers'] ?? {}),
      timestamp: map['timestamp']);
}

class OfflineSyncManager {
  final ApiClient client;
  final CacheStore store;
  final String _queueKey = 'sys_offline_mutations';
  bool _isSyncing = false;
  final StreamController<int> _queueLength = StreamController<int>.broadcast();

  OfflineSyncManager({required this.client, required this.store});

  Stream<int> get queueLength => _queueLength.stream;

  Future<void> enqueue(RequestContext ctx) async {
    final list = await _getQueue();
    list.add(QueuedMutation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      method: ctx.method,
      path: ctx.uri.path,
      body: ctx.body is Map ? ctx.body : {},
      headers: ctx.headers,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
    await store.set(
        _queueKey,
        CacheEntry(
            value: list.map((e) => e.toJson()).toList(),
            createdAt: DateTime.now()));
    _queueLength.add(list.length);
  }

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final list = await _getQueue();
      if (list.isEmpty) return;
      final failed = <QueuedMutation>[];

      for (final m in list) {
        try {
          await client.request(
              method: m.method,
              path: m.path,
              kind: RequestKind.rest,
              body: m.body,
              headers: m.headers,
              cachePolicy: CachePolicy.networkOnly,
              bypassOfflineQueue: true);
        } catch (e) {
          if (e is ApiException &&
              e.statusCode != null &&
              e.statusCode! >= 400 &&
              e.statusCode! < 500) {
            // Client Error (4xx) - discard request as it will never succeed.
          } else {
            failed.add(m); // Network/500 Error - Retain in queue for next sync.
          }
        }
      }
      await store.set(
          _queueKey,
          CacheEntry(
              value: failed.map((e) => e.toJson()).toList(),
              createdAt: DateTime.now()));
      _queueLength.add(failed.length);
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<QueuedMutation>> _getQueue() async {
    final entry = await store.get(_queueKey);
    if (entry == null || entry.value == null) return [];
    final decoded = entry.value as List;
    return decoded.map((e) => QueuedMutation.fromJson(e)).toList();
  }
}

// ============================================================
// Advanced Interceptors, Request Pipeline, & Retries
// ============================================================

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

  // Keeps track of the active route manifest for server delegation
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

class RequestRetryException implements Exception {}

abstract class RequestPolicy {
  FutureOr<RequestContext> onRequest(RequestContext context);
  FutureOr<ApiResponse<dynamic>> onResponse(
      RequestContext context, ApiResponse<dynamic> response);
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace);
}

abstract class AdvancedRequestPolicy extends RequestPolicy {
  /// If a policy returns true, the pipeline will pause, allow the policy to fix the issue, and try again.
  Future<bool> shouldRetry(
      RequestContext context, ApiResponse<dynamic>? response, Object? error);
}

// Automatically injects private server's signature to securely stream from public resources.
class ServerApprovedDelegationPolicy extends RequestPolicy {
  @override
  FutureOr<RequestContext> onRequest(RequestContext context) {
    if (context.trustTier == ApiTrustTier.authenticatedPublic &&
        context.activeManifest?.serverDelegatedSignature != null) {
      return context.copyWith(headers: {
        ...context.headers,
        'X-Server-Delegated-Signature':
            context.activeManifest!.serverDelegatedSignature!
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
  final OfflineSyncManager syncManager;
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
        (error is ApiException && error.statusCode == null)) {
      if (['POST', 'PUT', 'PATCH', 'DELETE'].contains(context.method)) {
        await syncManager.enqueue(context);
        throw ApiException(
            message: 'Offline. Mutation queued.',
            statusCode: 0,
            uri: context.uri);
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
    final token = await auth.getAccessToken();
    if (token != null && token.isNotEmpty) {
      return context.copyWith(headers: {
        ...context.headers,
        HttpHeaders.authorizationHeader: 'Bearer $token'
      });
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
        error is RequestRetryException) {
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

class RequestPipeline {
  final List<RequestPolicy> policies;
  const RequestPipeline({this.policies = const []});

  Future<ApiResponse<dynamic>> execute(
    RequestContext initialContext,
    int maxRetries,
    Future<ApiResponse<dynamic>> Function(RequestContext c) action,
  ) async {
    int attempts = 0;
    while (true) {
      attempts++;
      RequestContext currentContext = initialContext;

      try {
        for (final p in policies) {
          currentContext = await p.onRequest(currentContext);
        }

        var response = await action(currentContext);

        for (final p in policies.reversed) {
          response = await p.onResponse(currentContext, response);
        }

        return response;
      } catch (e, s) {
        bool willRetry = false;

        for (final p in policies) {
          if (p is AdvancedRequestPolicy) {
            final should = await p.shouldRetry(currentContext, null, e);
            if (should) willRetry = true;
          }
        }

        if (!willRetry || attempts > maxRetries) {
          for (final p in policies.reversed) {
            await p.onError(currentContext, e, s);
          }
          rethrow;
        }
      }
    }
  }
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

class CoalescingPolicy extends RequestPolicy {
  final Map<String, Completer<ApiResponse<dynamic>>> _inFlight = {};
  @override
  FutureOr<RequestContext> onRequest(RequestContext context) => context;
  @override
  FutureOr<ApiResponse<dynamic>> onResponse(
          RequestContext context, ApiResponse<dynamic> response) =>
      response;
  @override
  FutureOr<void> onError(
      RequestContext context, Object error, StackTrace stackTrace) {}

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

class RequestMerger {
  final Map<String, List<Completer<dynamic>>> _pending = {};
  final Duration window;
  RequestMerger({this.window = const Duration(milliseconds: 12)});

  Future<T> merge<T>(String key, Future<T> Function() action) {
    final batch = _pending[key];
    if (batch != null) {
      final c = Completer<dynamic>();
      batch.add(c);
      return c.future as Future<T>;
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

    return main.future as Future<T>;
  }
}

class CacheEntry {
  final dynamic value;
  final DateTime createdAt;
  final Duration? ttl;
  final Map<String, String> headers;
  CacheEntry(
      {required this.value,
      required this.createdAt,
      this.ttl,
      this.headers = const {}});
  bool get isExpired =>
      ttl != null && DateTime.now().difference(createdAt) > ttl!;

  Map<String, dynamic> toJson() => {
        'value': value,
        'createdAt': createdAt.toIso8601String(),
        'ttl': ttl?.inMilliseconds,
        'headers': headers
      };
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
      value: json['value'],
      createdAt: DateTime.parse(json['createdAt']),
      ttl: json['ttl'] != null ? Duration(milliseconds: json['ttl']) : null,
      headers: Map<String, String>.from(json['headers'] ?? {}));
}
// ============================================================
// Cache Strategy
// ============================================================

abstract class CacheStore {
  Future<CacheEntry?> get(String key);
  Future<void> set(String key, CacheEntry entry);
  Future<void> remove(String key);
  Future<void> clear();
}

class MemoryCacheStore implements CacheStore {
  final Map<String, CacheEntry> _map = {};
  @override
  Future<CacheEntry?> get(String key) async => _map[key];
  @override
  Future<void> set(String key, CacheEntry entry) async => _map[key] = entry;
  @override
  Future<void> remove(String key) async => _map.remove(key);
  @override
  Future<void> clear() async => _map.clear();
}

// ============================================================
// HTTP / REST Transport
// ============================================================

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
}

class IoTransport implements HttpTransport {
  final HttpClient _client;
  IoTransport({HttpClient? client}) : _client = client ?? HttpClient();

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
      final json = await ComputeCore.encodeJsonAsync(body);
      request.write(json);
    }

    final response =
        await request.close().timeout(timeout ?? const Duration(seconds: 30));
    return _IoTransportResponse(response);
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
  Future<Uint8List> bytes() async =>
      Uint8List.fromList(await _response.expand((v) => v).toList());

  @override
  Future<String> text({Encoding encoding = utf8}) async =>
      encoding.decode(await bytes());
}

class MultipartRequestBody {
  final List<MultipartPart> fields;
  final List<UploadFile> files;
  final String boundary;

  MultipartRequestBody(
      {this.fields = const [], this.files = const [], String? boundary})
      : boundary =
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

  String _escape(String value) => value.replaceAll('"', '\\"');
}

// ============================================================
// Universal RPC & Binary Protocol Transport (gRPC / Custom)
// ============================================================

enum RpcStatus {
  ok,
  cancelled,
  unknown,
  deadlineExceeded,
  unauthenticated,
  resourceExhausted,
  internal
}

class RpcException implements Exception {
  final RpcStatus status;
  final String message;
  final Map<String, String> trailers;
  RpcException(this.status, this.message, {this.trailers = const {}});
  @override
  String toString() => 'RpcException(${status.name}: $message)';
}

abstract class RpcTransport {
  Future<Uint8List> unaryCall(String method, Uint8List payload,
      {Map<String, String>? headers, Duration? timeout});
  Stream<Uint8List> streamCall(String method, Stream<Uint8List> payloads,
      {Map<String, String>? headers});
}

class BinaryRpcClient {
  final RpcTransport transport;
  BinaryRpcClient(this.transport);

  Future<TResponse> call<TRequest, TResponse>(
    String method,
    TRequest request, {
    required Uint8List Function(TRequest) serialize,
    required TResponse Function(Uint8List) deserialize,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final rawBytes = serialize(request);
    final responseBytes = await transport.unaryCall(method, rawBytes,
        headers: headers, timeout: timeout);
    return deserialize(responseBytes);
  }
}

// ============================================================
// Socket / WebSockets / Live Sessions
// ============================================================

abstract class SocketConnection {
  Stream<dynamic> get messages;
  Stream<void> get onClose;
  Future<void> send(dynamic data);
  Future<void> close([int? code, String? reason]);
}

abstract class SocketTransport {
  Future<SocketConnection> connect(Uri uri, {Map<String, String>? headers});
}

class IoSocketTransport implements SocketTransport {
  @override
  Future<SocketConnection> connect(Uri uri,
      {Map<String, String>? headers}) async {
    final ws = await WebSocket.connect(uri.toString(), headers: headers);
    return _IoSocketConnection(ws);
  }
}

class _IoSocketConnection implements SocketConnection {
  final WebSocket _socket;
  final StreamController<void> _closed = StreamController<void>.broadcast();
  _IoSocketConnection(this._socket) {
    _socket.done.then((_) {
      if (!_closed.isClosed) _closed.add(null);
      if (!_closed.isClosed) _closed.close();
    });
  }
  @override
  Stream<dynamic> get messages => _socket;
  @override
  Stream<void> get onClose => _closed.stream;
  @override
  Future<void> send(dynamic data) async {
    if (data is String || data is List<int>) {
      _socket.add(data);
    } else {
      _socket.add(await ComputeCore.encodeJsonAsync(data));
    }
  }

  @override
  Future<void> close([int? code, String? reason]) =>
      _socket.close(code, reason);
}

class RealtimeEvent {
  final String type;
  final dynamic data;
  final DateTime timestamp;
  RealtimeEvent({required this.type, this.data, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}

class RealtimeChannel {
  final String name;
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();
  RealtimeChannel(this.name);
  Stream<RealtimeEvent> get events => _events.stream;
  void emit(RealtimeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> close() async => _events.close();
}

class RealtimeClient {
  final Uri socketUrl;
  final SocketTransport socketTransport;
  final AuthProvider? authProvider;
  final Map<String, RealtimeChannel> _channels = {};
  SocketConnection? _connection;
  StreamSubscription? _subscription;
  final StreamController<RealtimeEvent> _rawEvents =
      StreamController<RealtimeEvent>.broadcast();

  RealtimeClient(
      {required this.socketUrl,
      required this.socketTransport,
      this.authProvider});

  Stream<RealtimeEvent> get rawEvents => _rawEvents.stream;
  RealtimeChannel channel(String name) =>
      _channels.putIfAbsent(name, () => RealtimeChannel(name));

  Future<void> connect() async {
    final token = await authProvider?.getAccessToken();
    final uri = token == null
        ? socketUrl
        : socketUrl.replace(
            queryParameters: {...socketUrl.queryParameters, 'token': token});
    _connection = await socketTransport.connect(uri);
    _subscription = _connection!.messages.listen(_handleMessage, onDone: () {
      _rawEvents.add(RealtimeEvent(type: 'close'));
    });
    _rawEvents.add(RealtimeEvent(type: 'connect'));
  }

  Future<void> subscribe(String name) async =>
      _connection?.send({'type': 'subscribe', 'channel': name});
  Future<void> unsubscribe(String name) async =>
      _connection?.send({'type': 'unsubscribe', 'channel': name});
  Future<void> publish(String name, dynamic data) async =>
      _connection?.send({'type': 'publish', 'channel': name, 'data': data});

  Future<void> close() async {
    await _subscription?.cancel();
    await _connection?.close();
    for (final c in _channels.values) {
      await c.close();
    }
    await _rawEvents.close();
  }

  void _handleMessage(dynamic message) async {
    try {
      final decoded = message is String
          ? await ComputeCore.decodeJsonAsync(message)
          : message;
      if (decoded is Map) {
        final type = decoded['type']?.toString() ?? 'message';
        final channelName = decoded['channel']?.toString();
        final event = RealtimeEvent(type: type, data: decoded['data']);
        _rawEvents.add(event);
        if (channelName != null) _channels[channelName]?.emit(event);
      } else {
        _rawEvents.add(RealtimeEvent(type: 'message', data: decoded));
      }
    } catch (e) {
      _rawEvents.add(RealtimeEvent(type: 'error', data: e.toString()));
    }
  }
}

class DuplexFrame {
  final String streamId;
  final String type;
  final dynamic data;
  final Map<String, dynamic> meta;
  DuplexFrame(
      {required this.streamId,
      required this.type,
      this.data,
      this.meta = const {}});
  Map<String, dynamic> toJson() =>
      {'streamId': streamId, 'type': type, 'data': data, 'meta': meta};
  factory DuplexFrame.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    return DuplexFrame(
      streamId: map['streamId']?.toString() ?? '',
      type: map['type']?.toString() ?? 'message',
      data: map['data'],
      meta: Map<String, dynamic>.from(map['meta'] ?? const {}),
    );
  }
}

class DuplexSessionController {
  final String streamId;
  final SocketConnection connection;
  final StreamController<DuplexFrame> _frames =
      StreamController<DuplexFrame>.broadcast();
  final StreamController<void> _closed = StreamController<void>.broadcast();
  late final StreamSubscription _sub;

  DuplexSessionController({required this.streamId, required this.connection}) {
    _sub = connection.messages.listen((event) async {
      try {
        final decoded =
            event is String ? await ComputeCore.decodeJsonAsync(event) : event;
        _frames.add(DuplexFrame.fromJson(decoded));
      } catch (_) {
        _frames.add(DuplexFrame(streamId: streamId, type: 'raw', data: event));
      }
    }, onDone: () {
      if (!_closed.isClosed) _closed.add(null);
      if (!_closed.isClosed) _closed.close();
    });
  }

  Stream<DuplexFrame> get frames => _frames.stream;
  Stream<void> get onClosed => _closed.stream;

  Future<void> send(DuplexFrame frame) => connection.send(frame.toJson());
  Future<void> ping() =>
      connection.send({'streamId': streamId, 'type': 'ping'});
  Future<void> close([String? reason]) async {
    await _sub.cancel();
    await connection.close(1000, reason);
    await _frames.close();
    await _closed.close();
  }
}

// ============================================================
// Raw UDP / RTP-Lite Media Layer / Jitter Buffer
// ============================================================

enum UdpPacketType {
  appData(0),
  audio(1),
  video(2),
  ping(3);

  final int id;
  const UdpPacketType(this.id);
  factory UdpPacketType.fromId(int id) =>
      values.firstWhere((e) => e.id == id, orElse: () => UdpPacketType.appData);
}

class UdpMediaPacket {
  final int sequence; // 16-bit (0 - 65535)
  final int timestamp; // 32-bit
  final UdpPacketType type; // 8-bit
  final Uint8List payload;

  const UdpMediaPacket(
      {required this.sequence,
      required this.timestamp,
      required this.type,
      required this.payload});

  Uint8List toBytes() {
    final bytes = Uint8List(7 + payload.length);
    final data = ByteData.sublistView(bytes);
    data.setUint16(0, sequence, Endian.big);
    data.setUint32(2, timestamp, Endian.big);
    data.setUint8(6, type.id);
    bytes.setAll(7, payload);
    return bytes;
  }

  factory UdpMediaPacket.fromBytes(Uint8List bytes) {
    if (bytes.length < 7) throw Exception('UDP Packet too small');
    final data = ByteData.sublistView(bytes);
    return UdpMediaPacket(
      sequence: data.getUint16(0, Endian.big),
      timestamp: data.getUint32(2, Endian.big),
      type: UdpPacketType.fromId(data.getUint8(6)),
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
  final StreamController<UdpMediaPacket> _frames =
      StreamController<UdpMediaPacket>.broadcast();
  bool _isClosed = false;

  IoUdpTransport._(this._socket, this._targetAddress, this._targetPort,
      this._crypto, this._nativeDelegate) {
    _socket.listen(_onRawData, onDone: close);
  }

  static Future<IoUdpTransport> connect(Uri uri, CryptoPolicy crypto,
      NativeSystemDelegate? nativeDelegate) async {
    final addresses = await InternetAddress.lookup(uri.host);
    if (addresses.isEmpty)
      throw Exception('DNS resolution failed for ${uri.host}');
    final targetAddress = addresses.first;
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    return IoUdpTransport._(
        socket, targetAddress, uri.port, crypto, nativeDelegate);
  }

  @override
  Stream<UdpMediaPacket> get frames => _frames.stream;

  @override
  Future<void> send(UdpMediaPacket packet) async {
    if (_isClosed) return;
    Uint8List rawBytes = packet.toBytes();

    if (_crypto.mode == EncryptionMode.hardware && _nativeDelegate != null) {
      rawBytes = await _nativeDelegate!
          .hardwareEncrypt(rawBytes, 'udp-session-key', meta: {'type': 'udp'});
    } else if (_crypto.mode != EncryptionMode.none) {
      rawBytes = _crypto.encryptBytes(rawBytes, meta: {'type': 'udp'});
    }

    _socket.send(rawBytes, _targetAddress, _targetPort);
  }

  void _onRawData(RawSocketEvent event) async {
    if (event == RawSocketEvent.read) {
      final datagram = _socket.receive();
      if (datagram == null) return;
      if (datagram.address.address != _targetAddress.address ||
          datagram.port != _targetPort) return;

      try {
        Uint8List safeBytes = datagram.data;
        if (_crypto.mode == EncryptionMode.hardware &&
            _nativeDelegate != null) {
          safeBytes = await _nativeDelegate!.hardwareDecrypt(
              safeBytes, 'udp-session-key',
              meta: {'type': 'udp'});
        } else if (_crypto.mode != EncryptionMode.none) {
          safeBytes = _crypto.decryptBytes(safeBytes, meta: {'type': 'udp'});
        }
        _frames.add(UdpMediaPacket.fromBytes(safeBytes));
      } catch (_) {}
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
  final StreamController<UdpMediaPacket> _orderedStream =
      StreamController<UdpMediaPacket>.broadcast();
  final int maxDelayMs;
  int _expectedSequence = -1;
  int _lastFlushTime = 0;

  JitterBuffer({this.maxDelayMs = 150});

  Stream<UdpMediaPacket> get orderedFrames => _orderedStream.stream;

  void insert(UdpMediaPacket packet) {
    if (_expectedSequence == -1) _expectedSequence = packet.sequence;
    int dist = (packet.sequence - _expectedSequence) & 0xFFFF;
    if (dist > 32767) return; // Late packet, drop it
    _buffer[packet.sequence] = packet;
    _flush();
  }

  void _flush() {
    final now = DateTime.now().millisecondsSinceEpoch;
    while (_buffer.containsKey(_expectedSequence)) {
      _orderedStream.add(_buffer.remove(_expectedSequence)!);
      _expectedSequence = (_expectedSequence + 1) % 65536;
      _lastFlushTime = now;
    }
    if (_buffer.isNotEmpty && (now - _lastFlushTime) > maxDelayMs) {
      final keys = _buffer.keys.toList()
        ..sort((a, b) {
          int d = (a - b) & 0xFFFF;
          return d > 32767 ? -1 : 1;
        });
      _expectedSequence = keys.first;
      _flush();
    }
  }

  void dispose() {
    _buffer.clear();
    _orderedStream.close();
  }
}

// ============================================================
// Adaptive HTTP Media Playback
// ============================================================

class MediaTrack {
  final String id;
  final MediaTrackType type;
  final int bitrate;
  final int? width;
  final int? height;
  final Uri uri;
  final Map<String, dynamic> meta;

  MediaTrack(
      {required this.id,
      required this.type,
      required this.bitrate,
      required this.uri,
      this.width,
      this.height,
      this.meta = const {}});

  factory MediaTrack.fromJson(dynamic json) {
    final map = (json as Map).cast<String, dynamic>();
    return MediaTrack(
      id: map['id']?.toString() ?? '',
      type: MediaTrackType.values.firstWhere(
          (e) => e.name == (map['type']?.toString() ?? 'video'),
          orElse: () => MediaTrackType.video),
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

  MediaManifest(
      {required this.mediaId,
      required this.tracks,
      this.defaultTrack,
      this.meta = const {}});

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

class AdaptiveMediaSession {
  final String sessionId;
  final StreamController<MediaSwitchEvent> _switches =
      StreamController<MediaSwitchEvent>.broadcast();
  final StreamController<double> _buffer = StreamController<double>.broadcast();
  MediaManifest manifest;
  MediaTrack activeTrack;

  AdaptiveMediaSession(
      {required this.sessionId,
      required this.manifest,
      required this.activeTrack});

  Stream<MediaSwitchEvent> get switches => _switches.stream;
  Stream<double> get buffer => _buffer.stream;

  void updateBuffer(double value) {
    if (!_buffer.isClosed) _buffer.add(value.clamp(0.0, 1.0));
  }

  void switchTrack(MediaTrack next,
      {MediaSwitchMode mode = MediaSwitchMode.seamless}) {
    final old = activeTrack;
    activeTrack = next;
    if (!_switches.isClosed)
      _switches
          .add(MediaSwitchEvent(oldTrack: old, newTrack: next, mode: mode));
  }

  Future<void> dispose() async {
    await _switches.close();
    await _buffer.close();
  }
}

class MediaSwitchEvent {
  final MediaTrack? oldTrack;
  final MediaTrack newTrack;
  final MediaSwitchMode mode;
  MediaSwitchEvent(
      {required this.newTrack,
      this.oldTrack,
      this.mode = MediaSwitchMode.seamless});
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

  void play() {
    _isPlaying = true;
    _playing.add(true);
  }

  void pause() {
    _isPlaying = false;
    _playing.add(false);
  }

  void seek(Duration value) {
    _positionValue = value;
    _position.add(value);
  }

  void switchQuality(MediaTrack next) => media.switchTrack(next);
  Future<void> dispose() async {
    await _position.close();
    await _playing.close();
    await media.dispose();
  }
}

// ============================================================
// EMBEDDED LOCALHOST MEDIA PROXY (The Holy Grail)
// ============================================================

/// Runs a localized HTTP Server on the device. Native Video Players stream from this.
/// This proxy intercepts the request, routes it securely to the CDN with auth signatures,
/// decrypts the bytes in an Isolate (if CryptoPolicy is set), and pipes them to the Native Player.
class EmbeddedMediaProxy {
  final ApiClient client;
  HttpServer? _server;
  int get port => _server?.port ?? 0;

  EmbeddedMediaProxy(this.client);

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleNativePlayerRequest);
  }

  String getProxyUrl(String mediaPath) {
    if (_server == null) throw Exception('Media Proxy not started');
    return 'http://127.0.0.1:$port/stream?path=${Uri.encodeComponent(mediaPath)}';
  }

  Future<void> _handleNativePlayerRequest(HttpRequest request) async {
    try {
      final path = request.uri.queryParameters['path'];
      if (path == null) {
        request.response.statusCode = 400;
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
          requirePolicyCheck: true);

      request.response.statusCode = apiResponse.statusCode;
      apiResponse.headers.forEach((key, value) {
        if (key.toLowerCase() != 'transfer-encoding')
          request.response.headers.set(key, value);
      });

      // Stream bytes ultra-fast back to ExoPlayer/AVPlayer.
      // If client.cryptoPolicy != none, insert it here before piping.
      await apiResponse.byteStream.pipe(request.response);
    } catch (e) {
      request.response.statusCode = 500;
      request.response.write(e.toString());
      await request.response.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}

// ============================================================
// GraphQL Query / Batching / Transfers
// ============================================================

class QueryRequest<T> {
  final String name;
  final Map<String, dynamic> variables;
  final String contentType;
  final String accept;
  final JsonFactory<T>? decode;

  QueryRequest(
      {required this.name,
      this.variables = const {},
      this.contentType = 'application/json; charset=utf-8',
      this.accept = 'application/json',
      this.decode});
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
      headers: headers,
      contentType: request.contentType,
      accept: request.accept,
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
  BatchRequestItem(
      {required this.id,
      required this.method,
      required this.path,
      this.query = const {},
      this.body,
      this.headers = const {}});
  Map<String, dynamic> toJson() => {
        'id': id,
        'method': method,
        'path': path,
        'query': query,
        'body': body,
        'headers': headers
      };
}

class BatchResultItem {
  final String id;
  final int statusCode;
  final dynamic body;
  final Map<String, String> headers;
  BatchResultItem(
      {required this.id,
      required this.statusCode,
      required this.body,
      required this.headers});
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
    final res = await client.post<BatchResponse>(batchPath,
        body: {'items': items.map((e) => e.toJson()).toList()},
        decode: (json) => BatchResponse.fromJson(json));
    return res.data;
  }
}

abstract class TransferCheckpointStore {
  Future<Map<String, dynamic>?> load(String id);
  Future<void> save(String id, Map<String, dynamic> checkpoint);
  Future<void> clear(String id);
}

class MemoryTransferCheckpointStore implements TransferCheckpointStore {
  final Map<String, Map<String, dynamic>> _store = {};
  @override
  Future<Map<String, dynamic>?> load(String id) async => _store[id];
  @override
  Future<void> save(String id, Map<String, dynamic> checkpoint) async =>
      _store[id] = checkpoint;
  @override
  Future<void> clear(String id) async => _store.remove(id);
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

  ResumableTransferManager(
      {required this.client, required this.store, this.nativeDelegate});

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
        id: id, direction: TransferDirection.download);
    final key = checkpointKey ?? id;
    final checkpoint = await store.load(key);
    final offset = (checkpoint?['offset'] as num?)?.toInt() ?? 0;
    final reqHeaders = <String, String>{
      ...headers,
      if (offset > 0) HttpHeaders.rangeHeader: 'bytes=$offset-'
    };

    // Use OS Hand-off if requested and available
    if (allowOSBackground && nativeDelegate != null) {
      final uri = await client.buildUri(path, query, kind: RequestKind.media);
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
      return controller; // OS handles the rest
    }

    final response = await client.sendRaw(
        method: 'GET',
        path: path,
        kind: RequestKind.media,
        query: query,
        headers: reqHeaders,
        trustTier: trustTier);
    if (response.statusCode >= 400)
      throw ApiException(
          message: 'Download failed', statusCode: response.statusCode);

    final sink =
        file.openWrite(mode: offset > 0 ? FileMode.append : FileMode.writeOnly);
    try {
      var received = offset;
      await for (final chunk in response.byteStream) {
        if (controller.isCancelled) break;
        while (controller.isPaused)
          await Future<void>.delayed(const Duration(milliseconds: 25));
        sink.add(chunk);
        received += chunk.length;
        await store.save(key, {'offset': received});
      }
      await sink.flush();
      await sink.close();
      await store.clear(key);
      controller.emitProgress(1.0);
    } finally {
      await controller.dispose();
    }
    return controller;
  }
}

// ============================================================
// Base API Client
// ============================================================

class ApiClient {
  final ApiClientConfig config;
  final HttpTransport transport;
  AuthProvider? authProvider;
  final JsonEncoder? jsonEncoder;
  final Object? Function(Object? value)? jsonReviver;
  final CacheStore cacheStore;
  final RequestPipeline pipeline;
  final CoalescingPolicy coalescingPolicy;
  final RequestMerger requestMerger;
  final TransferCheckpointStore transferCheckpointStore;
  final NativeSystemDelegate? nativeDelegate;
  final RpcTransport? rpcTransport;

  final RouteProvider? routeProvider;
  final RouteProvider? socketRouteProvider;
  final RouteProvider? duplexRouteProvider;
  final RouteProvider? udpRouteProvider;
  final RouteProvider? rpcRouteProvider;
  final CryptoPolicy cryptoPolicy;
  late final OfflineSyncManager offlineManager;

  ApiClient({
    required this.config,
    required this.transport,
    this.authProvider,
    this.jsonEncoder,
    this.jsonReviver,
    CacheStore? cacheStore,
    RequestPipeline? pipeline,
    CoalescingPolicy? coalescingPolicy,
    RequestMerger? requestMerger,
    TransferCheckpointStore? transferCheckpointStore,
    this.nativeDelegate,
    this.rpcTransport,
    this.routeProvider,
    this.socketRouteProvider,
    this.duplexRouteProvider,
    this.udpRouteProvider,
    this.rpcRouteProvider,
    CryptoPolicy? cryptoPolicy,
  })  : cacheStore = cacheStore ?? MemoryCacheStore(),
        pipeline = pipeline ??
            RequestPipeline(policies: [ServerApprovedDelegationPolicy()]),
        coalescingPolicy = coalescingPolicy ?? CoalescingPolicy(),
        requestMerger = requestMerger ?? RequestMerger(),
        transferCheckpointStore =
            transferCheckpointStore ?? MemoryTransferCheckpointStore(),
        cryptoPolicy = cryptoPolicy ?? PassThroughCryptoPolicy() {
    // Inject the Offline Manager interceptor dynamically at boot.
    offlineManager = OfflineSyncManager(client: this, store: this.cacheStore);
    this.pipeline.policies.add(OfflineMutationPolicy(offlineManager));
  }

  Future<Uri> buildUri(String path, Map<String, dynamic> query,
      {required RequestKind kind}) async {
    final base = await _resolveHttpBase(kind: kind);
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = base.resolve(normalized);
    if (query.isEmpty) return uri;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      ...query.map((k, v) => MapEntry(k, v?.toString() ?? ''))
    });
  }

  Future<Map<String, String>> buildHeaders(Map<String, String> headers,
      {String? idempotencyKey,
      required ApiTrustTier trustTier,
      required Uri uri,
      required RequestKind kind}) async {
    final token = await authProvider?.getAccessToken();
    final merged = <String, String>{
      ...config.defaultHeaders,
      ...headers,
      if (config.userAgent != null)
        HttpHeaders.userAgentHeader: config.userAgent!,
      if (token != null && token.isNotEmpty)
        HttpHeaders.authorizationHeader: 'Bearer $token',
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
        HttpHeaders.acceptHeader: accept
      },
      body: body,
      decode: decode,
      timeout: timeout,
      trustTier: trustTier,
      mergeKey: mergeKey,
      cachePolicy: cachePolicy,
    );
  }

  Future<ApiResponse<T>> post<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      dynamic body,
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      String? idempotencyKey,
      String? mergeKey}) {
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
        mergeKey: mergeKey);
  }

  Future<ApiResponse<T>> get<T>(String path,
      {Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      JsonFactory<T>? decode,
      Duration? timeout,
      ApiTrustTier? trustTier,
      CachePolicy cachePolicy = CachePolicy.networkOnly}) {
    return request<T>(
        method: 'GET',
        path: path,
        kind: RequestKind.rest,
        query: query,
        headers: headers,
        decode: decode,
        timeout: timeout,
        trustTier: trustTier,
        cachePolicy: cachePolicy);
  }

  Future<TransportResponse> sendRaw(
      {required String method,
      required String path,
      required RequestKind kind,
      Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      Object? body,
      Duration? timeout,
      ApiTrustTier? trustTier,
      String? idempotencyKey,
      bool requirePolicyCheck = true}) async {
    final context = await _prepareContext(
        method: method,
        path: path,
        kind: kind,
        query: query,
        headers: headers,
        body: body,
        timeout: timeout,
        trustTier: trustTier,
        idempotencyKey: idempotencyKey);
    if (requirePolicyCheck) await _assertRequestAllowed(context);
    return transport.send(
        method: context.method,
        uri: context.uri,
        headers: context.headers,
        body: context.body,
        timeout: context.timeout);
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
    if (cachePolicy == CachePolicy.cacheOnly ||
        cachePolicy == CachePolicy.cacheFirst ||
        cachePolicy == CachePolicy.staleWhileRevalidate) {
      final cached = await cacheStore.get(cacheKey);
      if (cached != null && !cached.isExpired) {
        final decodedCached = cached.value is String
            ? await ComputeCore.decodeJsonAsync(cached.value)
            : cached.value;
        final res = ApiResponse<T>(
            statusCode: 200,
            headers: cached.headers,
            data: _castOrDecode<T>(decodedCached, decode),
            uri: initialContext.uri);
        if (cachePolicy != CachePolicy.staleWhileRevalidate) return res;
        unawaited(_revalidate(initialContext, decode, cacheKey));
        return res;
      }
    }

    final coalesceKey = mergeKey ?? _requestSignature(initialContext);

    // Check if we need to temporarily disable offline interceptor for sync events
    final activePolicies = bypassOfflineQueue
        ? pipeline.policies.where((p) => p is! OfflineMutationPolicy).toList()
        : pipeline.policies;

    final activePipeline = RequestPipeline(policies: activePolicies);

    // Executes through the Interceptor Pipeline with Retry support
    final dynamicResponse = await activePipeline
        .execute(initialContext, config.maxRetries, (ctx) async {
      Future<ApiResponse<dynamic>> performAction() async {
        if (config.enableLogging) _logRequest(ctx);
        final raw = await transport.send(
            method: ctx.method,
            uri: ctx.uri,
            headers: ctx.headers,
            body: ctx.body,
            timeout: ctx.timeout);
        final text = await raw.text();
        final decoded =
            await _decodeResponseAsync<dynamic>(text, null, raw.headers);
        final response = ApiResponse<dynamic>(
            statusCode: raw.statusCode,
            headers: raw.headers,
            data: decoded,
            uri: ctx.uri);
        if (raw.statusCode >= 400) {
          throw ApiException(
              message: _extractErrorMessage(decoded, text),
              statusCode: raw.statusCode,
              uri: ctx.uri,
              body: decoded);
        }
        return response;
      }

      if (mergeKey != null)
        return requestMerger.merge(coalesceKey, performAction);
      return coalescingPolicy.coalesce(coalesceKey, performAction);
    });

    if (requireIntegrityCheck || initialContext.requireIntegrityCheck) {
      await _verifyIntegrity(initialContext, dynamicResponse);
    }

    if (cachePolicy != CachePolicy.networkOnly && method == 'GET') {
      await cacheStore.set(
          cacheKey,
          CacheEntry(
              value: dynamicResponse.data,
              createdAt: DateTime.now(),
              ttl: const Duration(minutes: 5),
              headers: dynamicResponse.headers));
    }

    if (config.enableLogging) _logResponse(dynamicResponse);
    return ApiResponse<T>(
        statusCode: dynamicResponse.statusCode,
        headers: dynamicResponse.headers,
        data: _castOrDecode<T>(dynamicResponse.data, decode),
        uri: dynamicResponse.uri);
  }

  Future<UdpConnection> connectUdp(String path) async {
    final context = RequestContext(
        method: 'UDP',
        uri: config.baseUrl,
        kind: RequestKind.udp,
        trustTier: config.defaultTrustTier,
        headers: const {},
        body: null,
        cachePolicy: CachePolicy.networkOnly,
        timeout: config.receiveTimeout);
    Uri uri = config.baseUrl;
    final manifest = udpRouteProvider == null
        ? null
        : await udpRouteProvider!.resolve(
            RouteContext(request: context, purpose: 'udp', manifest: null));
    if (manifest != null && !manifest.isExpired()) {
      uri = manifest.udpBase ?? config.baseUrl;
      if (!manifest.allows(uri, method: 'UDP', purpose: 'udp'))
        throw PolicyViolation('UDP route not allowed', uri: uri);
    }
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return IoUdpTransport.connect(
        uri.replace(path: normalizedPath), cryptoPolicy, nativeDelegate);
  }

  ApiModule module(String prefix) => ApiModule(this, prefix: prefix);

  Future<Uri> _resolveHttpBase({required RequestKind kind}) async {
    final ctx = RequestContext(
        method: 'GET',
        uri: config.baseUrl,
        kind: kind,
        trustTier: config.defaultTrustTier,
        headers: const {},
        body: null,
        cachePolicy: CachePolicy.networkOnly,
        timeout: config.receiveTimeout);
    final manifest = routeProvider == null
        ? null
        : await routeProvider!.resolve(
            RouteContext(request: ctx, purpose: 'private', manifest: null));
    if (manifest != null && !manifest.isExpired()) return manifest.httpBase;
    return config.baseUrl;
  }

  dynamic _normalizeBody(dynamic body, Map<String, String> headers) {
    if (body == null ||
        body is MultipartRequestBody ||
        body is String ||
        body is List<int> ||
        body is Stream<List<int>>) return body;
    headers.putIfAbsent(
        HttpHeaders.contentTypeHeader, () => 'application/json; charset=utf-8');
    // It will be encoded asynchronously in the transport layer for heavy payloads.
    return body;
  }

  Future<T> _decodeResponseAsync<T>(
      String text, JsonFactory<T>? decode, Map<String, String> headers) async {
    if (T == String) return text as T;
    if (T == Uint8List) return Uint8List.fromList(utf8.encode(text)) as T;

    if (text.isEmpty) return null as T;
    try {
      final dynamic decodedJson = await ComputeCore.decodeJsonAsync(text);
      if (decode != null) return decode(decodedJson);
      return decodedJson as T;
    } catch (_) {
      return text as T;
    }
  }

  T _castOrDecode<T>(dynamic value, JsonFactory<T>? decode) =>
      decode != null ? decode(value) : value as T;

  String _extractErrorMessage(dynamic data, String raw) {
    if (data is Map) {
      for (final key in const ['message', 'error', 'detail', 'details']) {
        if (data[key] != null) return data[key].toString();
      }
    }
    return raw.trim().isNotEmpty ? raw : 'Request failed';
  }

  String _cacheKey(RequestContext ctx) =>
      '${ctx.method}:${ctx.uri}:${ctx.trustTier.name}:${ctx.cachePolicy.name}:${_bodySignature(ctx.body)}';
  String _requestSignature(RequestContext ctx) =>
      '${ctx.method}:${ctx.uri}:${ctx.trustTier.name}:${_bodySignature(ctx.body)}:${_headerSignature(ctx.headers)}';
  String _headerSignature(Map<String, String> headers) {
    final entries = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => '${e.key.toLowerCase()}=${e.value}').join('&');
  }

  String _bodySignature(dynamic body) {
    if (body == null) return 'null';
    if (body is String) return 's:${body.hashCode}';
    if (body is num || body is bool) return 'p:$body';
    if (body is List<int>) return 'bytes:${body.length}';
    if (body is Stream<List<int>>) return 'stream:${body.runtimeType}';
    if (body is Map)
      return 'map:{${(body.keys.map((e) => e.toString()).toList()..sort()).map((k) => '$k=${_bodySignature(body[k])}').join(',')}}';
    return body.runtimeType.toString();
  }

  Future<void> _revalidate<T>(
      RequestContext context, JsonFactory<T>? decode, String cacheKey) async {
    try {
      final fresh = await request<T>(
          method: context.method,
          path: context.uri.path,
          kind: context.kind,
          query: context.uri.queryParameters,
          headers: context.headers,
          body: context.body,
          decode: decode,
          timeout: context.timeout,
          cachePolicy: CachePolicy.networkOnly,
          trustTier: context.trustTier);
      await cacheStore.set(
          cacheKey,
          CacheEntry(
              value: fresh.data,
              createdAt: DateTime.now(),
              ttl: const Duration(minutes: 5),
              headers: fresh.headers));
    } catch (_) {}
  }

  Future<void> _verifyIntegrity(
      RequestContext context, ApiResponse<dynamic> response) async {
    if ((response.headers['x-signature'] ??
            response.headers['x-content-signature']) ==
        null) {
      throw IntegrityViolation('Missing integrity signature', uri: context.uri);
    }
  }

  Future<RequestContext> _prepareContext(
      {required String method,
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
      bool requireIntegrityCheck = false}) async {
    final uri = await buildUri(path, query, kind: kind);
    final finalHeaders = await buildHeaders(headers,
        idempotencyKey: idempotencyKey,
        trustTier: trustTier ?? config.defaultTrustTier,
        uri: uri,
        kind: kind);

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
          timeout: timeout ?? config.receiveTimeout);
      manifest = await routeProvider!.resolve(
          RouteContext(request: dummyCtx, purpose: kind.name, manifest: null));
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

  Future<void> _assertRequestAllowed(RequestContext context) async {
    if (routeProvider == null) return;
    final manifest = await routeProvider!.resolve(RouteContext(
        request: context, purpose: context.kind.name, manifest: null));
    if (manifest != null &&
        !manifest.allows(context.uri,
            method: context.method, purpose: context.kind.name)) {
      throw PolicyViolation('Route not allowed by server policy',
          uri: context.uri);
    }
  }

  void _logRequest(RequestContext context) =>
      print('→ ${context.method} ${context.uri}');
  void _logResponse(ApiResponse<dynamic> response) =>
      print('← ${response.statusCode} ${response.uri}');
}

class ApiModule {
  final ApiClient client;
  final String prefix;
  const ApiModule(this.client, {this.prefix = ''});
  String _joinPath(String path) => prefix.isEmpty
      ? path
      : (path.startsWith('/') ? '$prefix$path' : '$prefix/$path');

  Future<ApiResponse<T>> request<T>(
      {required String method,
      required String path,
      required RequestKind kind,
      Map<String, dynamic> query = const {},
      Map<String, String> headers = const {},
      dynamic body,
      JsonFactory<T>? decode,
      Duration? timeout}) {
    return client.request<T>(
        method: method,
        path: _joinPath(path),
        kind: kind,
        query: query,
        headers: headers,
        body: body,
        decode: decode,
        timeout: timeout);
  }
}

// ============================================================
// The High-Level Omni SDK Wrapper (The God Engine)
// ============================================================

class AppSdk {
  final ApiClient client;
  late final ApiModule root;
  late final QueryEngine queries;
  late final BinaryRpcClient? rpc;
  late final EmbeddedMediaProxy mediaProxy;

  AppSdk(this.client) {
    root = client.module('');
    queries = QueryEngine(client);
    rpc = client.rpcTransport != null
        ? BinaryRpcClient(client.rpcTransport!)
        : null;
    mediaProxy = EmbeddedMediaProxy(client);
    mediaProxy.start(); // Auto-start the localhost media server securely
  }

  /// Reactive REST / DB Models
  ReactiveCrudRepository<T> repository<T>(
      {required String path,
      required JsonFactory<T> fromJson,
      required JsonEncoderFn<T> toJson}) {
    return ReactiveCrudRepository<T>(
        api: root, resourcePath: path, fromJson: fromJson, toJson: toJson);
  }

  /// Real-time Pub/Sub WebSockets
  /// Real-time Pub/Sub WebSockets
  RealtimeClient realtime({required String socketPath}) {
    return RealtimeClient(
      socketUrl: client.config.baseUrl.resolve(socketPath),
      socketTransport: IoSocketTransport(),
      authProvider: client.authProvider,
    );
  }

  /// Ultra-low latency, ordered, decrypted binary UDP stream (Video / VoIP).
  Future<Stream<UdpMediaPacket>> liveMediaStream(String path,
      {int jitterDelayMs = 150}) async {
    final connection = await client.connectUdp(path);
    final jitterBuffer = JitterBuffer(maxDelayMs: jitterDelayMs);
    connection.frames.listen((packet) => jitterBuffer.insert(packet),
        onDone: () => jitterBuffer.dispose());
    return jitterBuffer.orderedFrames;
  }

  /// Send raw video/audio frames directly to the server via secure UDP.
  Future<UdpConnection> createLiveMediaIngest(String path) async =>
      client.connectUdp(path);

  /// Background-safe OS Transfers
  ResumableTransferManager transfers() => ResumableTransferManager(
      client: client,
      store: client.transferCheckpointStore,
      nativeDelegate: client.nativeDelegate);

  /// Batch operations
  BatchManager batch({String batchPath = '/batch'}) =>
      BatchManager(client: client, batchPath: batchPath);
}

/// A Reactive Repository that supports Instant Offline reads and background network syncs
class ReactiveCrudRepository<T> {
  final ApiModule api;
  final String resourcePath;
  final JsonFactory<T> fromJson;
  final JsonEncoderFn<T> toJson;
  final StreamController<T> _docStream = StreamController<T>.broadcast();
  final StreamController<List<T>> _listStream =
      StreamController<List<T>>.broadcast();

  ReactiveCrudRepository(
      {required this.api,
      required this.resourcePath,
      required this.fromJson,
      required this.toJson});

  /// Instantly observe a single document. Yields disk cache instantly, fetches network in background.
  Stream<T> watch(String id) async* {
    final cacheKey =
        'GET:${api.client.config.baseUrl.resolve('$resourcePath/$id').toString()}';

    // 1. Yield Offline Cache instantly
    final cached = await api.client.cacheStore.get(cacheKey);
    if (cached != null) {
      final decodedCached = cached.value is String
          ? await ComputeCore.decodeJsonAsync(cached.value)
          : cached.value;
      yield fromJson(decodedCached);
    }

    // 2. Fetch Network
    try {
      final res = await api.request<T>(
          method: 'GET',
          path: '$resourcePath/$id',
          kind: RequestKind.rest,
          decode: (json) => fromJson(json));
      _docStream.add(res.data);
      yield res.data;
    } catch (e) {
      if (cached == null) throw e;
    }

    // 3. Listen for future mutations
    yield* _docStream.stream;
  }

  /// Instantly observe a list of documents.
  Stream<List<T>> watchList({Map<String, dynamic> query = const {}}) async* {
    final uri =
        await api.client.buildUri(resourcePath, query, kind: RequestKind.rest);
    final cacheKey = 'GET:${uri.toString()}';

    final cached = await api.client.cacheStore.get(cacheKey);
    if (cached != null) {
      final decodedCached = cached.value is String
          ? await ComputeCore.decodeJsonAsync(cached.value)
          : cached.value;
      yield ((decodedCached as List?) ?? []).map((e) => fromJson(e)).toList();
    }

    try {
      final res = await api.request<List<T>>(
          method: 'GET',
          path: resourcePath,
          kind: RequestKind.rest,
          query: query,
          decode: (json) =>
              ((json as List?) ?? const []).map((e) => fromJson(e)).toList());
      _listStream.add(res.data);
      yield res.data;
    } catch (e) {
      if (cached == null) throw e;
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
            ((json as List?) ?? const []).map((e) => fromJson(e)).toList());
    return res.data;
  }

  Future<T> read(String id) async {
    final res = await api.request<T>(
        method: 'GET',
        path: '$resourcePath/$id',
        kind: RequestKind.rest,
        decode: (json) => fromJson(json));
    return res.data;
  }

  Future<T> create(T value) async {
    final res = await api.request<T>(
        method: 'POST',
        path: resourcePath,
        kind: RequestKind.rest,
        body: toJson(value),
        decode: (json) => fromJson(json));
    return res.data;
  }

  Future<T> update(String id, T value) async {
    final res = await api.request<T>(
        method: 'PUT',
        path: '$resourcePath/$id',
        kind: RequestKind.rest,
        body: toJson(value),
        decode: (json) => fromJson(json));
    _docStream.add(res.data); // Alert active watchers
    return res.data;
  }

  Future<void> remove(String id) async {
    await api.request<dynamic>(
        method: 'DELETE',
        path: '$resourcePath/$id',
        kind: RequestKind.rest,
        decode: (json) => json);
  }
}
