// =============================================================================
// quantum_api_engine.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import '../foundation/quantum_isolate_bridge.dart';
import '../foundation/quantum_schema.dart';
import '../foundation/quantum_core.dart';
import '../runtime/quantum_permissions.dart';
// Assuming these are in your project
import 'quantum_auth_engine.dart';
import 'quantum_media_api.dart';
import 'quantum_socket_engine.dart';
// -----------------------------------------------------------------------------
// SECTION 1 — CORE PRIMITIVES & POLICIES (100% UNTOUCHED)
// -----------------------------------------------------------------------------
typedef JsonEncoderFn = dynamic Function(dynamic value);
typedef JsonDecoderFn = dynamic Function(dynamic value);

typedef ProgressListener = void Function(TransferProgress progress);

enum CachePolicyMode {
  cacheFirst,
  networkFirst,
  staleWhileRevalidate,
  cacheOnly,
  networkOnly
}

enum OfflineMode { disabled, readThrough, writeQueue, fullOffline }

enum StreamDirection { bidirectional, inboundOnly, outboundOnly }

enum RequestPriority { low, normal, high, instant }

class VaultStreamException implements Exception {
  final String code;
  final String message;
  final Object? details;

  const VaultStreamException(this.code, this.message, {this.details});

  @override
  String toString() => 'VaultStreamException($code): $message';
}

class ApiResult<T> {
  final T? data;
  final VaultStreamException? error;
  final bool fromCache;
  final bool fromOffline;
  final String driverUsed;
  final Map<String, dynamic> meta;

  const ApiResult.success(
    this.data, {
    this.fromCache = false,
    this.fromOffline = false,
    this.driverUsed = 'default',
    this.meta = const {},
  }) : error = null;

  const ApiResult.failure(
    this.error, {
    this.fromCache = false,
    this.fromOffline = false,
    this.driverUsed = 'default',
    this.meta = const {},
  }) : data = null;

  bool get isSuccess => error == null;
}

class RuntimeTrace {
  final String name;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final int requestBytes;
  final int responseBytes;
  final bool cacheHit;
  final bool offlineHit;
  final Map<String, dynamic> meta;

  const RuntimeTrace({
    required this.name,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.requestBytes,
    required this.responseBytes,
    required this.cacheHit,
    required this.offlineHit,
    required this.meta,
  });
}

class QueryPolicy {
  final CachePolicyMode cachePolicy;
  final Duration? ttl;
  final bool forceRefresh;
  final bool revalidateOnRead;
  final bool isolateByUser;
  final bool isolateBySession;
  final bool instant;
  final RequestPriority priority;
  final String? targetDriver;

  const QueryPolicy({
    this.cachePolicy = CachePolicyMode.staleWhileRevalidate,
    this.ttl,
    this.forceRefresh = false,
    this.revalidateOnRead = false,
    this.isolateByUser = true,
    this.isolateBySession = true,
    this.instant = false,
    this.priority = RequestPriority.normal,
    this.targetDriver,
  });

  QueryPolicy copyWith({
    CachePolicyMode? cachePolicy,
    Duration? ttl,
    bool? forceRefresh,
    bool? revalidateOnRead,
    bool? isolateByUser,
    bool? isolateBySession,
    bool? instant,
    RequestPriority? priority,
    String? targetDriver,
  }) {
    return QueryPolicy(
      cachePolicy: cachePolicy ?? this.cachePolicy,
      ttl: ttl ?? this.ttl,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      revalidateOnRead: revalidateOnRead ?? this.revalidateOnRead,
      isolateByUser: isolateByUser ?? this.isolateByUser,
      isolateBySession: isolateBySession ?? this.isolateBySession,
      instant: instant ?? this.instant,
      priority: priority ?? this.priority,
      targetDriver: targetDriver ?? this.targetDriver,
    );
  }
}

class CacheEntry {
  final String key;
  final dynamic value;
  final DateTime createdAt;
  final DateTime lastAccessAt;
  final Duration? ttl;
  final Set<String> tags;
  final String? slug;
  final String? docId;
  final String? ownerUserId;
  final String? sessionId;
  final String? projectionKey;
  final bool pinned;
  final Map<String, dynamic> meta;

  const CacheEntry({
    required this.key,
    required this.value,
    required this.createdAt,
    required this.lastAccessAt,
    required this.ttl,
    required this.tags,
    this.slug,
    this.docId,
    required this.ownerUserId,
    required this.sessionId,
    required this.projectionKey,
    required this.pinned,
    required this.meta,
  });

  bool isExpired(DateTime now) {
    if (ttl == null) return false;
    return now.difference(createdAt) > ttl!;
  }

  CacheEntry touch(DateTime now) {
    return CacheEntry(
      key: key,
      value: value,
      createdAt: createdAt,
      lastAccessAt: now,
      ttl: ttl,
      tags: tags,
      slug: slug,
      docId: docId,
      ownerUserId: ownerUserId,
      sessionId: sessionId,
      projectionKey: projectionKey,
      pinned: pinned,
      meta: meta,
    );
  }
}

class CacheStats {
  final int size;
  final int hits;
  final int misses;
  final int evictions;
  final int bytesEstimate;
  const CacheStats(
      {required this.size,
      required this.hits,
      required this.misses,
      required this.evictions,
      required this.bytesEstimate});
}

class AccessPolicy {
  final bool canBypass;
  final bool cachePermissions;
  final Duration? permissionsTtl;
  final bool sessionScoped;
  final bool purgeOnLogout;
  const AccessPolicy(
      {this.canBypass = false,
      this.cachePermissions = true,
      this.permissionsTtl,
      this.sessionScoped = true,
      this.purgeOnLogout = true});
}

class SecurityPolicy {
  final SecurityScope scope;
  final bool encryptLocalData;
  final bool encryptTokens;
  final bool redactLogs;
  final bool verifyServerPayloads;
  final bool signRequests;
  final bool tamperChecks;
  final bool bindCacheToSession;
  final String? clientSecret;
  final List<String> pinnedCertificateHashes;

  const SecurityPolicy({
    this.scope = SecurityScope.sessionBound,
    this.encryptLocalData = true,
    this.encryptTokens = true,
    this.redactLogs = true,
    this.verifyServerPayloads = true,
    this.signRequests = true,
    this.tamperChecks = true,
    this.bindCacheToSession = true,
    this.clientSecret,
    this.pinnedCertificateHashes = const [],
  });
}

class OfflinePolicy {
  final OfflineMode mode;
  final bool readCacheWhenOffline;
  final bool queueWritesWhenOffline;
  final bool syncOnReconnect;
  final bool reconcileConflicts;
  final int maxQueueSize;
  final Duration retryDelay;

  const OfflinePolicy({
    this.mode = OfflineMode.readThrough,
    this.readCacheWhenOffline = true,
    this.queueWritesWhenOffline = true,
    this.syncOnReconnect = true,
    this.reconcileConflicts = true,
    this.maxQueueSize = 1000,
    this.retryDelay = const Duration(seconds: 2),
  });
}

class BatchPolicy {
  final bool enabled;
  final Duration window;
  final int maxBatchSize;
  final bool dedupeByKey;
  final bool coalesceSameQuery;
  const BatchPolicy(
      {this.enabled = true,
      this.window = const Duration(milliseconds: 20),
      this.maxBatchSize = 32,
      this.dedupeByKey = true,
      this.coalesceSameQuery = true});
}

class StreamPolicy {
  final StreamDirection direction;
  final int chunkSize;
  final bool backpressure;
  final bool retryOnDrop;
  final Duration? heartbeat;
  const StreamPolicy(
      {this.direction = StreamDirection.bidirectional,
      this.chunkSize = 64 * 1024,
      this.backpressure = true,
      this.retryOnDrop = true,
      this.heartbeat});
}

class VaultStreamClientConfig {
  final String baseUrl;
  final String cacheDirectoryPath; // NEW: Added for Media Engine
  final QuantumSocketConfig? socketConfig; // NEW: Added for Socket Engine
  final String appName;
  final String environment;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final JsonEncoderFn? encoder;
  final JsonDecoderFn? decoder;
  final NowFn? now;
  final LoggerFn? logger;
  final QueryPolicy defaultQueryPolicy;
  final SecurityPolicy securityPolicy;
  final OfflinePolicy offlinePolicy;
  final CachePolicyMode defaultCachePolicy;
  final BatchPolicy batchPolicy;
  final StreamPolicy streamPolicy;
  final AccessPolicy accessPolicy;
  final bool telemetryEnabled;
  final int maxCacheSize;
  final AuthPolicy authPolicy;

  const VaultStreamClientConfig({
    required this.baseUrl,
    required this.cacheDirectoryPath, // NEW
    this.socketConfig, // NEW
    this.appName = 'VaultStream',
    this.environment = 'prod',
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.encoder,
    this.decoder,
    this.now,
    this.logger,
    this.defaultQueryPolicy = const QueryPolicy(),
    this.securityPolicy = const SecurityPolicy(),
    this.offlinePolicy = const OfflinePolicy(),
    this.defaultCachePolicy = CachePolicyMode.staleWhileRevalidate,
    this.batchPolicy = const BatchPolicy(),
    this.streamPolicy = const StreamPolicy(),
    this.accessPolicy = const AccessPolicy(),
    this.telemetryEnabled = true,
    this.maxCacheSize = 2000,
    this.authPolicy = const AuthPolicy(),
  });
}

class SchemaInfo {
  final String slug;
  final String kind;
  final Map<String, dynamic> definition;
  final DateTime fetchedAt;
  final String version;
  final String hash;
  const SchemaInfo(
      {required this.slug,
      required this.kind,
      required this.definition,
      required this.fetchedAt,
      required this.version,
      required this.hash});
}

class PermissionSnapshot {
  final String scope;
  final String? userId;
  final DateTime fetchedAt;
  final Duration? ttl;
  final Map<String, dynamic> permissions;
  const PermissionSnapshot(
      {required this.scope,
      required this.userId,
      required this.fetchedAt,
      required this.ttl,
      required this.permissions});
  bool isExpired(DateTime now) =>
      ttl != null && now.difference(fetchedAt) > ttl!;
}

// -----------------------------------------------------------------------------
// SECTION 2 — DRIVER PROTOCOLS & HTTP/SOCKET TRANSPORT (INTEGRATED)
// -----------------------------------------------------------------------------

class DriverContext {
  final SessionContext session;
  final QueryPolicy policy;
  final Map<String, String> securityHeaders;
  final bool isOffline;

  const DriverContext(
      {required this.session,
      required this.policy,
      required this.securityHeaders,
      required this.isOffline});
}

abstract class VaultDriver {
  String get driverId;
  Future<void> initialize(Map<String, dynamic> config);
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context});
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context});
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context});
  Future<void> dispose();
}

class VaultHttpDriver implements VaultDriver {
  @override
  final String driverId = 'http';
  final String baseUrl;
  final HttpClient _client;
  final Duration timeout;

  VaultHttpDriver(
      {required this.baseUrl,
      List<String> pinnedCertHashes = const [],
      Duration? timeout})
      : _client = HttpClient(),
        timeout = timeout ?? const Duration(seconds: 15) {
    _client.connectionTimeout = this.timeout;
    if (pinnedCertHashes.isNotEmpty) {
      _client.badCertificateCallback = (cert, host, port) {
        final fingerprint = sha256.convert(cert.der).toString();
        return pinnedCertHashes.contains(fingerprint);
      };
    }
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  void _injectHeaders(HttpClientRequest request, DriverContext context) {
    context.securityHeaders.forEach((k, v) => request.headers.set(k, v));
    if (context.session.accessToken != null) {
      request.headers.set(HttpHeaders.authorizationHeader,
          'Bearer ${context.session.accessToken}');
    }
    request.headers.set(
        'X-Vault-Environment', context.policy.targetDriver ?? 'production');
  }

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    try {
      final endpoint = id != null ? '$baseUrl/$slug/$id' : '$baseUrl/$slug';
      final uri = Uri.parse(endpoint).replace(
          queryParameters: query.map((k, v) => MapEntry(k, v.toString())));
      final request = await _client.getUrl(uri).timeout(timeout);
      _injectHeaders(request, context);

      final response = await request.close().timeout(timeout);
      final body =
          await response.transform(utf8.decoder).join().timeout(timeout);
      final decoded = jsonDecode(body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded, driverUsed: driverId);
      }
      return ApiResult.failure(
          VaultStreamException(
              'http_error', decoded['message'] ?? 'Failed read'),
          driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(
          VaultStreamException('http_exception', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    try {
      final endpoint = id != null ? '$baseUrl/$slug/$id' : '$baseUrl/$slug';
      final request =
          await _client.postUrl(Uri.parse(endpoint)).timeout(timeout);
      _injectHeaders(request, context);
      request.headers.contentType = ContentType.json;

      final serializedBody = jsonEncode({'op': op, 'data': body});
      final bytes = utf8.encode(serializedBody);
      request.headers.contentLength = bytes.length;
      request.add(bytes);

      final response = await request.close().timeout(timeout);
      final respBody =
          await response.transform(utf8.decoder).join().timeout(timeout);
      final decoded = jsonDecode(respBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded, driverUsed: driverId);
      }
      return ApiResult.failure(
          VaultStreamException(
              'http_error', decoded['message'] ?? 'Failed write'),
          driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(
          VaultStreamException('http_exception', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context}) {
    if (context.isOffline) {
      return Stream<ApiResult<dynamic>>.value(ApiResult.failure(
        VaultStreamException('offline_stream_unavailable',
            'Streaming subscriptions are unavailable while offline.'),
        fromOffline: true,
        driverUsed: driverId,
      ));
    }

    final sanitizedQuery = Map<String, dynamic>.from(query)
      ..remove('pollIntervalMs')
      ..remove('pollMs')
      ..remove('maxEvents')
      ..remove('once')
      ..remove('emitOnlyOnChange')
      ..remove('stream');

    final intervalMs = int.tryParse(
          '${query['pollIntervalMs'] ?? query['pollMs'] ?? ''}',
        ) ??
        2000;
    final maxEvents = int.tryParse('${query['maxEvents'] ?? ''}');
    final emitOnlyOnChange = query['emitOnlyOnChange'] != false;
    final once = query['once'] == true || query['stream'] == false;

    Future<ApiResult<dynamic>> fetch() => read(
          slug,
          sanitizedQuery,
          context: context,
        );

    if (once) {
      return Stream<ApiResult<dynamic>>.fromFuture(fetch());
    }

    return _pollingSubscription(
      fetch: fetch,
      interval: Duration(milliseconds: intervalMs.clamp(250, 60000).toInt()),
      maxEvents: maxEvents,
      emitOnlyOnChange: emitOnlyOnChange,
    );
  }

  @override
  Future<void> dispose() async => _client.close(force: true);
}

// NEW: Added the Socket Driver seamlessly integrating with QuantumSocketEngine
class VaultSocketDriver implements VaultDriver {
  @override
  final String driverId = 'socket';
  final QuantumSocketEngine _engine;

  VaultSocketDriver(this._engine);

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    try {
      final res = await _engine.request(slug, 'read',
          {'query': query, 'id': id, 'headers': context.securityHeaders});
      return ApiResult.success(res.payload, driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(VaultStreamException('socket_err', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    try {
      final res = await _engine.request(slug, op,
          {'body': body, 'id': id, 'headers': context.securityHeaders});
      return ApiResult.success(res.payload, driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(VaultStreamException('socket_err', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context}) {
    final channel = 'live:$slug';
    _engine.emit(channel, 'scope', query); // Let server know subscription rules
    return _engine.subscribe(channel).map((msg) {
      if (msg.event == 'error')
        return ApiResult.failure(VaultStreamException('sub_err', msg.payload),
            driverUsed: driverId);
      return ApiResult.success(msg.payload, driverUsed: driverId);
    });
  }

  @override
  Future<void> dispose() async {} // Engine disposed globally
}

// abstract class LocalStore {
//   Future<void> init();
//   Future<String?> read(String key);
//   Future<void> write(String key, String value);
//   Future<void> delete(String key);
//   Future<void> clear({String? prefix});
// }

// -----------------------------------------------------------------------------
// SECTION 3 — SECURE LOCAL STORAGE ENGINE & TELEMETRY (100% UNTOUCHED)
// -----------------------------------------------------------------------------

abstract class LocalStore implements AuthSecretStore {
  Future<void> init();
  @override
  Future<String?> read(String key);
  @override
  Future<void> write(String key, String value);
  @override
  Future<void> delete(String key);
  Future<List<String>> keys({String? prefix});
  @override
  Future<void> clear({String? prefix});
  Future<int> size();
}

abstract class SecureVault implements AuthSecretStore {
  @override
  Future<void> init();
  Future<String?> readSecret(String key);
  Future<void> writeSecret(String key, String value);
  Future<void> deleteSecret(String key);
  Future<void> clearSecrets();
}

class MemoryLocalStore implements LocalStore {
  final Map<String, String> _store = {};
  @override
  Future<void> init() async {}
  @override
  Future<String?> read(String key) async => _store[key];
  @override
  Future<void> write(String key, String value) async => _store[key] = value;
  @override
  Future<void> delete(String key) async => _store.remove(key);
  @override
  Future<List<String>> keys({String? prefix}) async => prefix == null
      ? _store.keys.toList()
      : _store.keys.where((k) => k.startsWith(prefix)).toList();
  @override
  Future<void> clear({String? prefix}) async {
    if (prefix == null)
      _store.clear();
    else
      _store.removeWhere((k, _) => k.startsWith(prefix));
  }

  @override
  Future<int> size() async => _store.length;
}

class MemorySecureVault implements SecureVault {
  final Map<String, String> _secrets = {};
  @override
  Future<void> init() async {}
  @override
  Future<String?> readSecret(String key) async => _secrets[key];
  @override
  Future<void> writeSecret(String key, String value) async =>
      _secrets[key] = value;
  @override
  Future<void> deleteSecret(String key) async => _secrets.remove(key);
  @override
  Future<void> clearSecrets() async => _secrets.clear();
  @override
  Future<String?> read(String key) async => readSecret(key);
  @override
  Future<void> write(String key, String value) async => writeSecret(key, value);
  @override
  Future<void> delete(String key) async => deleteSecret(key);
  @override
  Future<void> clear({String? prefix}) async {
    if (prefix == null)
      _secrets.clear();
    else
      _secrets.removeWhere((k, _) => k.startsWith(prefix));
  }
}

class VaultSecurityEngine {
  final SecurityPolicy policy;
  VaultSecurityEngine(this.policy);

  static Map<String, String> generateSecurityHeadersInIsolate(
      Map<String, dynamic> args) {
    final payloadString = args['payload'] as String;
    final secret = args['secret'] as String;
    final method = args['method'] as String;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final nonce = DateTime.now().microsecondsSinceEpoch.toString() +
        (Object().hashCode).toString();
    final key = utf8.encode(secret);
    final bytes = utf8.encode('$method:$timestamp:$nonce:$payloadString');
    final digest = Hmac(sha256, key).convert(bytes);
    return {
      'X-Vault-Signature': digest.toString(),
      'X-Vault-Timestamp': timestamp,
      'X-Vault-Nonce': nonce
    };
  }

  Future<Map<String, String>> generateSecurityHeaders(
      Map<String, dynamic> payload, String method) async {
    if (!policy.signRequests || policy.clientSecret == null) return {};
    final payloadString =
        await QLIsolateBridge.safeRun(() => jsonEncode(payload));
    return await QLIsolateBridge.safeRun(() =>
        generateSecurityHeadersInIsolate({
          'payload': payloadString,
          'secret': policy.clientSecret!,
          'method': method
        }));
  }

  static Map<String, dynamic> encryptForStorageInIsolate(
      Map<String, dynamic> args) {
    final data = args['data'] as String;
    final secret = args['secret'] as String;
    return {'_encrypted': true, 'data': QuantumCipher.encrypt(data, secret)};
  }

  static dynamic decryptFromStorageInIsolate(Map<String, dynamic> args) {
    final raw = args['raw'] as String;
    final secret = args['secret'] as String;
    return jsonDecode(QuantumCipher.decrypt(raw, secret));
  }

  Future<dynamic> encryptForStorage(dynamic data) async {
    if (!policy.encryptLocalData || data == null || policy.clientSecret == null)
      return data;
    final serialized = await QLIsolateBridge.safeRun(() => jsonEncode(data));
    return await QLIsolateBridge.safeRun(() => encryptForStorageInIsolate(
        {'data': serialized, 'secret': policy.clientSecret!}));
  }

  Future<dynamic> decryptFromStorage(dynamic encryptedData) async {
    if (!policy.encryptLocalData ||
        encryptedData is! Map ||
        encryptedData['_encrypted'] != true ||
        policy.clientSecret == null) return encryptedData;
    final rawString = encryptedData['data'] as String;
    return await QLIsolateBridge.safeRun(() => decryptFromStorageInIsolate(
        {'raw': rawString, 'secret': policy.clientSecret!}));
  }

  static Map<String, dynamic> redactSensitiveDataInIsolate(
      Map<String, dynamic> data) {
    final redacted = Map<String, dynamic>.from(data);
    const sensitiveKeys = [
      'password',
      'token',
      'secret',
      'credit_card',
      'ssn',
      'email'
    ];
    for (final key in redacted.keys.toList()) {
      if (sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
        redacted[key] = '***REDACTED***';
      } else if (redacted[key] is Map<String, dynamic>) {
        redacted[key] = redactSensitiveDataInIsolate(redacted[key]);
      }
    }
    return redacted;
  }

  Future<Map<String, dynamic>> redactSensitiveData(
      Map<String, dynamic> data) async {
    if (!policy.redactLogs) return data;
    return await QLIsolateBridge.safeRun(
        () => redactSensitiveDataInIsolate(data));
  }
}

class TelemetryHub {
  final bool enabled;
  final VaultSecurityEngine security;
  final List<RuntimeTrace> _traces = [];
  final Map<String, int> _counters = {};
  final Map<String, int> _bytes = {};

  TelemetryHub({required this.enabled, required this.security});

  void record(RuntimeTrace trace) {
    if (!enabled) return;
    if (_traces.length > 500) _traces.removeAt(0);
    _traces.add(trace);
  }

  void increment(String name, [int by = 1]) {
    if (enabled) _counters[name] = (_counters[name] ?? 0) + by;
  }

  void addBytes(String name, int value) {
    if (enabled) _bytes[name] = (_bytes[name] ?? 0) + value;
  }

  Map<String, dynamic> snapshot() => {
        'traces': _traces.length,
        'counters': Map<String, int>.from(_counters),
        'bytes': Map<String, int>.from(_bytes)
      };
}

String _jsonFingerprint(dynamic value) {
  dynamic normalize(dynamic input) {
    if (input is Map) {
      final keys = input.keys.map((e) => e.toString()).toList(growable: false)
        ..sort();
      return {
        for (final key in keys)
          key: normalize(input[key] ?? input[key.toString()]),
      };
    }
    if (input is Iterable) {
      return input.map(normalize).toList(growable: false);
    }
    if (input is Uint8List) {
      return base64Encode(input);
    }
    return input;
  }

  try {
    return jsonEncode(normalize(value));
  } catch (_) {
    return value?.toString() ?? 'null';
  }
}

QLSchemaBlueprint? _resolveSchemaBlueprint(String slug,
    {required bool isGlobal}) {
  final candidates = <String>[
    slug,
    isGlobal ? 'global.$slug' : 'collection.$slug',
    isGlobal ? 'global:$slug' : 'collection:$slug',
  ];

  for (final candidate in candidates) {
    if (candidate.trim().isEmpty) continue;
    final schema = QLSchemaRegistry.instance.getSchema(candidate);
    if (schema != null) return schema;
  }
  return null;
}

List<String> _pathsFromProjectionInput(dynamic select) {
  if (select is List) {
    return select
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (select is String && select.isNotEmpty) return <String>[select];
  return const <String>[];
}

List<String> _normalizeStringList(dynamic value) {
  if (value is Iterable && value is! String) {
    return value
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

String _queryFamilyKey(String slug, Map<String, dynamic> query, {String? id}) {
  if (id != null) return 'doc:$slug:$id';
  final normalized = Map<String, dynamic>.from(query);
  normalized.remove('select');
  return 'query:$slug:${_fastHashQuery(normalized)}';
}

Set<String> _coverageFromMeta(
    Map<String, dynamic> meta, QLSchemaBlueprint? schema) {
  final rawPaths = _normalizeStringList(meta['selectPaths']);
  if (rawPaths.isEmpty) {
    if (meta['full'] == true && schema != null) {
      return schema.expandSelection(schema.fieldPaths()).toSet();
    }
    return <String>{};
  }
  return schema != null
      ? schema.expandSelection(rawPaths).toSet()
      : rawPaths.toSet();
}

List<String> _schemaReadablePaths(QLSchemaBlueprint schema) {
  return schema.fields
      .where((f) => !f.isVirtual && !f.isComputed)
      .where((f) => !(f.type == QLFieldType.object && f.children.isNotEmpty))
      .map((f) => f.path)
      .toList(growable: false);
}

bool _coverageContainsAll(Set<String> coverage, Iterable<String> required) {
  for (final path in required) {
    if (!coverage.contains(path)) return false;
  }
  return true;
}

Set<String> _coverageUnion(Set<String> a, Set<String> b) {
  final out = <String>{}
    ..addAll(a)
    ..addAll(b);
  return out;
}

List<String> _missingPaths(Set<String> requested, Set<String> cached) {
  return requested
      .where((path) => !cached.contains(path))
      .toList(growable: false);
}

Map<String, dynamic> _deepMergeMaps(
    Map<String, dynamic> base, Map<String, dynamic> incoming) {
  final out = Map<String, dynamic>.from(base);
  for (final entry in incoming.entries) {
    final current = out[entry.key];
    final next = entry.value;
    if (current is Map && next is Map) {
      out[entry.key] = _deepMergeMaps(
          Map<String, dynamic>.from(current), Map<String, dynamic>.from(next));
    } else if (current is List && next is List) {
      out[entry.key] = _mergeLists(current, next);
    } else {
      out[entry.key] = next;
    }
  }
  return out;
}

List<dynamic> _mergeLists(List<dynamic> base, List<dynamic> incoming) {
  final mapById = <String, Map<String, dynamic>>{};
  final other = <dynamic>[];
  void addItem(dynamic item) {
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      final id = map['id']?.toString();
      if (id != null && id.isNotEmpty) {
        final existing = mapById[id];
        mapById[id] = existing == null ? map : _deepMergeMaps(existing, map);
      } else {
        other.add(map);
      }
    } else {
      other.add(item);
    }
  }

  for (final item in base) addItem(item);
  for (final item in incoming) addItem(item);
  return <dynamic>[...mapById.values, ...other];
}

Map<String, dynamic> _mergeReadPayload(dynamic cached, dynamic incoming) {
  if (cached is Map && incoming is Map) {
    return _deepMergeMaps(
        Map<String, dynamic>.from(cached), Map<String, dynamic>.from(incoming));
  }
  if (cached is List && incoming is List) {
    return <String, dynamic>{'items': _mergeLists(cached, incoming)};
  }
  if (incoming is Map<String, dynamic>)
    return Map<String, dynamic>.from(incoming);
  return <String, dynamic>{'value': incoming};
}

Set<String> _entryCoverage(CacheEntry entry, QLSchemaBlueprint? schema) {
  return _coverageFromMeta(entry.meta, schema);
}

CacheEntry? _bestCacheEntryForKey(
  LinkedHashMap<String, CacheEntry> cache,
  String exactKey,
  String familyKey,
  QLSchemaBlueprint? schema,
  Set<String> requestedCoverage,
  Map<String, Set<String>> familyIndex,
) {
  final exact = cache[exactKey];
  CacheEntry? best = exact;
  Set<String> bestCoverage =
      exact == null ? <String>{} : _entryCoverage(exact, schema);

  if (familyKey.isNotEmpty && familyIndex.containsKey(familyKey)) {
    for (final candidateKey in familyIndex[familyKey]!) {
      final candidate = cache[candidateKey];
      if (candidate == null) continue;
      final coverage = _entryCoverage(candidate, schema);
      if (best == null) {
        best = candidate;
        bestCoverage = coverage;
      } else if (coverage.length > bestCoverage.length) {
        best = candidate;
        bestCoverage = coverage;
      }
      if (_coverageContainsAll(coverage, requestedCoverage)) {
        return candidate;
      }
    }
  }

  if (best != null && _coverageContainsAll(bestCoverage, requestedCoverage)) {
    return best;
  }
  return best;
}

Set<String> _requestedCoveragePaths(
  QLSchemaBlueprint? schema,
  Map<String, dynamic> query,
) {
  final selectPaths = _pathsFromProjectionInput(query['select']);
  if (schema == null) return selectPaths.toSet();
  if (selectPaths.isNotEmpty)
    return schema.expandSelection(selectPaths).toSet();
  return _schemaReadablePaths(schema).toSet();
}

Map<String, dynamic> _projectCachedValue(
  dynamic cachedValue,
  QLSchemaBlueprint schema,
  Iterable<String> requestedPaths,
) {
  final projection =
      schema.createProjection(requestedPaths.toList(growable: false));
  final transformed = _applySchemaReadTransform(
    cachedValue,
    schema,
    projection: projection,
  );
  if (transformed is Map<String, dynamic>) return transformed;
  return <String, dynamic>{'value': transformed};
}

QLProjection? _projectionForPayload(
    QLSchemaBlueprint schema, Map<String, dynamic> payload) {
  final selected = <String>[];
  for (final spec in schema.fields) {
    if (spec.isVirtual || spec.isComputed) continue;
    if (spec.path.contains('[]')) continue;
    final segments = spec.path
        .replaceAll('[]', '')
        .split('.')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    if (_payloadContainsPath(payload, segments)) {
      selected.add(spec.path);
    }
  }
  return selected.isEmpty ? null : schema.createProjection(selected);
}

bool _payloadContainsPath(dynamic payload, List<String> segments) {
  if (segments.isEmpty) return payload != null;
  if (payload is Map) {
    final next = payload[segments.first];
    if (next == null) return false;
    return _payloadContainsPath(next, segments.sublist(1));
  }
  if (payload is List) {
    if (payload.isEmpty) return false;
    if (segments.length == 1) return true;
    return _payloadContainsPath(payload.first, segments.sublist(1));
  }
  return segments.length == 1 && payload != null;
}

QLProjection? _projectionForQuery(
    QLSchemaBlueprint schema, Map<String, dynamic> query) {
  final paths = _pathsFromProjectionInput(query['select']);
  if (paths.isEmpty) return null;
  return schema.createProjection(paths);
}

void _preserveIdentity(
    Map<String, dynamic> source, Map<String, dynamic> target) {
  for (final key in const ['id', '_id']) {
    if (source.containsKey(key) && !target.containsKey(key)) {
      target[key] = source[key];
    }
  }
}

dynamic _applySchemaReadTransform(
  dynamic payload,
  QLSchemaBlueprint schema, {
  QLProjection? projection,
}) {
  if (payload is List) {
    return payload
        .map((item) => item is Map
            ? _applySchemaReadTransform(
                Map<String, dynamic>.from(item as Map),
                schema,
                projection: projection,
              )
            : item)
        .toList(growable: false);
  }

  if (payload is Map<String, dynamic>) {
    final out = Map<String, dynamic>.from(payload);

    if (out['items'] is List) {
      out['items'] = (out['items'] as List)
          .map((item) => item is Map
              ? _applySchemaReadTransform(
                  Map<String, dynamic>.from(item as Map),
                  schema,
                  projection: projection,
                )
              : item)
          .toList(growable: false);
      return out;
    }

    if (out['data'] is Map) {
      out['data'] = _applySchemaReadTransform(
        Map<String, dynamic>.from(out['data'] as Map),
        schema,
        projection: projection,
      );
      return out;
    }

    final parsed = schema.parse(out, projection: projection);
    _preserveIdentity(out, parsed);
    return parsed;
  }

  return payload;
}

Map<String, dynamic> _sanitizeSchemaWritePayload(
  String slug,
  Map<String, dynamic> payload, {
  required bool isGlobal,
  required String op,
  String? id,
}) {
  final schema = _resolveSchemaBlueprint(slug, isGlobal: isGlobal);
  if (schema == null) return Map<String, dynamic>.from(payload);

  final allowPartial = <String>{
    'patchById',
    'updateById',
    'upsertById',
    'updateMany',
    'upsertGlobal',
    'updateGlobal',
  }.contains(op);

  final projection = allowPartial
      ? (_projectionForPayload(schema, payload) ??
          (payload.isEmpty ? schema.createProjection(const <String>[]) : null))
      : schema.createProjection(schema.fieldPaths());

  if (allowPartial && projection == null && payload.isNotEmpty) {
    throw VaultStreamException(
      'schema_validation_failed',
      'No writable schema fields matched the payload.',
      details: <String, dynamic>{
        'slug': slug,
        'op': op,
        if (id != null) 'id': id
      },
    );
  }

  final sanitized = schema.serialize(payload, projection: projection);
  final validation = schema.validate(sanitized, projection: projection);
  if (validation.isNotEmpty) {
    throw VaultStreamException(
      'schema_validation_failed',
      validation.join('; '),
      details: <String, dynamic>{
        'slug': slug,
        'op': op,
        if (id != null) 'id': id,
        'errors': validation,
      },
    );
  }

  return sanitized;
}

Stream<ApiResult<dynamic>> _pollingSubscription({
  required Future<ApiResult<dynamic>> Function() fetch,
  required Duration interval,
  int? maxEvents,
  bool emitOnlyOnChange = true,
}) async* {
  String? lastFingerprint;
  int emitted = 0;

  while (true) {
    final result = await fetch();
    final fingerprint = _jsonFingerprint(result.data);
    final changed = fingerprint != lastFingerprint;

    if (!emitOnlyOnChange || emitted == 0 || changed || !result.isSuccess) {
      if (result.isSuccess) {
        lastFingerprint = fingerprint;
      }
      emitted++;
      yield result;
      if (maxEvents != null && emitted >= maxEvents) return;
    }

    await Future<void>.delayed(interval);
  }
}

// -----------------------------------------------------------------------------
// SECTION 4 — ROUTER & FALLBACK
// -----------------------------------------------------------------------------

class VaultRouter {
  final Map<String, VaultDriver> _drivers = {};
  void registerDriver(VaultDriver driver) => _drivers[driver.driverId] = driver;
  VaultDriver getDriver(String? targetDriverId) {
    if (targetDriverId == null) {
      if (_drivers.containsKey('default')) return _drivers['default']!;
      if (_drivers.isNotEmpty) return _drivers.values.first;
    }

    final driver = _drivers[targetDriverId ?? 'default'];
    if (driver != null) return driver;

    throw StateError(
      'No VaultDriver registered for "${targetDriverId ?? 'default'}". Register a real driver before calling Quantum.',
    );
  }

  Future<void> disposeAll() async {
    for (final driver in _drivers.values) {
      await driver.dispose();
    }
  }
}

// -----------------------------------------------------------------------------
// SECTION 5 — SYSTEM ORCHESTRATOR (MASSIVE CACHE & MEDIA/SOCKET INJECTION)
// -----------------------------------------------------------------------------

class _QueuedRequest {
  final String key, slug, op;
  final Map<String, dynamic> body;
  final String? id;
  final bool isGlobal;
  final QueryPolicy policy;

  const _QueuedRequest({
    required this.key,
    required this.slug,
    required this.op,
    required this.body,
    this.id,
    required this.isGlobal,
    required this.policy,
  });

  // NEW: Added serialization for crash-proof persistent offline queue
  Map<String, dynamic> toMap() => {
        'key': key,
        'slug': slug,
        'op': op,
        'body': body,
        'id': id,
        'isGlobal': isGlobal
      };
  factory _QueuedRequest.fromMap(Map<String, dynamic> map) => _QueuedRequest(
      key: map['key'],
      slug: map['slug'],
      op: map['op'],
      body: map['body'],
      id: map['id'],
      isGlobal: map['isGlobal'],
      policy: const QueryPolicy());
}

class VaultStreamClient {
  VaultStreamClientConfig _config;
  final LocalStore _store;
  final SecureVault _secureVault;
  late final VaultSecurityEngine _securityEngine;
  late final TelemetryHub _telemetry;

  late final QuantumAuthEngine authEngine;
  QuantumMediaEngine? _mediaEngine;
  QuantumSocketEngine? _socketEngine;
  SecureSduiVault? _sduiVault;
  SecureDisplayEngine? _secureDisplayEngine;

  final VaultRouter _router = VaultRouter();

  final LinkedHashMap<String, CacheEntry> _cache =
      LinkedHashMap<String, CacheEntry>();
  final Map<String, Set<String>> _tagIndex = {};
  final Map<String, Set<String>> _slugIndex = {};
  final Map<String, Set<String>> _docIndex = {};
  final Map<String, Set<String>> _familyIndex = {};
  final Map<String, Future<ApiResult<dynamic>>> _inFlightReads = {};

  final Map<String, SchemaInfo> _schemaCache = {};
  final Map<String, PermissionSnapshot> _permissionCache = {};
  final Queue<_QueuedRequest> _queue = Queue<_QueuedRequest>();

  bool _initialized = false;
  bool _offline = false;
  bool _wasAuthenticated = false;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _evictions = 0;

  final StreamController<SessionContext> _sessionChanges =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _events =
      StreamController.broadcast();

  VaultStreamClient({
    required VaultStreamClientConfig config,
    LocalStore? store,
    SecureVault? secureVault,
    QuantumAuthEngine? authEngine,
    AuthDriver? authDriver,
  })  : _config = config,
        _store = store ?? MemoryLocalStore(),
        _secureVault = secureVault ?? MemorySecureVault() {
    _securityEngine = VaultSecurityEngine(config.securityPolicy);
    _telemetry = TelemetryHub(
        enabled: config.telemetryEnabled, security: _securityEngine);
    this.authEngine = authEngine ??
        QuantumAuthEngine(
          driver: authDriver ?? MemoryAuthDriver(driverId: 'default_auth'),
          store: _secureVault,
          security: AuthSecurityEngine(config.authPolicy),
          policy: config.authPolicy,
        );
    _updateSessionPrefix();
    _wasAuthenticated = this.authEngine.isAuthenticated;

    this.authEngine.onSessionChanged.listen((session) {
      final prevAuth = _wasAuthenticated;
      _wasAuthenticated = session.isAuthenticated;
      _updateSessionPrefix();
      _sessionChanges.add(session);

      if (!prevAuth && session.isAuthenticated && session.userId != null) {
        _migrateGuestData(session.userId!);
      } else if (prevAuth && !session.isAuthenticated) {
        // Automatically purge decrypted cache and scoped data
        clearSession(purgeCache: true);
      }
    });
  }

  VaultStreamClientConfig get config => _config;
  SessionContext get session => authEngine.session;
  bool get isInitialized => _initialized;
  bool get isOffline => _offline;
  Stream<SessionContext> get sessionChanges => _sessionChanges.stream;
  Stream<Map<String, dynamic>> get events => _events.stream;

  DateTime _now() => _config.now?.call() ?? DateTime.now();
  void _updateSessionPrefix() {
    _baseSessionPrefix =
        's:${session.sessionId ?? 'anon'}|u:${session.userId ?? 'guest'}|';
  }

  void registerDriver(VaultDriver driver) => _router.registerDriver(driver);
  void registerAuthDriver(AuthDriver driver) => authEngine.driver = driver;

  // NEW EXPOSURES FOR THE NEW ENGINES
  QuantumMediaEngine get media => _mediaEngine!;
  QuantumSocketEngine? get socket => _socketEngine;

  Future<void> _migrateGuestData(String newUserId) async {
    bool migrated = false;

    // Migrate in-memory cache ownership from guest to authenticated user
    final guestKeys = _cache.keys
        .where((k) => _cache[k]?.ownerUserId == null)
        .toList(growable: false);

    for (final k in guestKeys) {
      final oldEntry = _cache[k]!;
      _cache[k] = CacheEntry(
        key: oldEntry.key,
        value: oldEntry.value,
        createdAt: oldEntry.createdAt,
        lastAccessAt: oldEntry.lastAccessAt,
        ttl: oldEntry.ttl,
        tags: oldEntry.tags,
        slug: oldEntry.slug,
        docId: oldEntry.docId,
        ownerUserId: newUserId,
        sessionId: session.sessionId,
        projectionKey: oldEntry.projectionKey,
        pinned: oldEntry.pinned,
        meta: oldEntry.meta,
      );
      migrated = true;
    }

    if (migrated) {
      _telemetry.increment('guest_data_migrated');
      // Push any pending guest operations to the server under the new identity
      retryPending();
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    await _store.init();
    await authEngine.init();

    // NEW: Initialize Socket Engine & Driver if configured
    if (_config.socketConfig != null) {
      _socketEngine = QuantumSocketEngine(config: _config.socketConfig!);
      await _socketEngine!.connect();
      registerDriver(VaultSocketDriver(_socketEngine!)); // Link the driver!
    }
    await QuantumMediaEngine.instance.init(
      localStore: _store,
      cacheDirectory: Directory(_config.cacheDirectoryPath),
      clientSecret: _config.securityPolicy.clientSecret,
    );
    // Restore offline queue from persistent disk to prevent crash-loss
    await _restorePersistentQueue();

    _initialized = true;
    _telemetry.increment('init');
    if (_config.securityPolicy.clientSecret != null) {
      _sduiVault = SecureSduiVault(
          store: _store,
          secret: _config.securityPolicy.clientSecret!,
          authEngine: this.authEngine);
      _secureDisplayEngine =
          SecureDisplayEngine(secret: _config.securityPolicy.clientSecret!);
    }
  }

  Future<void> reconfigure(VaultStreamClientConfig next) async {
    _config = next;
    _telemetry.increment('reconfigure');
  }

  void setOffline(bool value) {
    _offline = value;
    _telemetry.increment(value ? 'offline_on' : 'offline_off');
    if (!value && _config.offlinePolicy.syncOnReconnect) unawaited(syncAll());
  }

  Future<void> clearSession({bool purgeCache = true}) async {
    final prevId = session.userId;
    await authEngine.logout();
    _telemetry.increment('session_cleared');
    if (purgeCache && prevId != null) await purgeUserScopedData(prevId);
  }

  Future<void> purgeUserScopedData(String userId) async {
    final keysToRemove = _cache.keys
        .where((k) => _cache[k]?.ownerUserId == userId)
        .toList(growable: false);
    for (var k in keysToRemove) {
      _removeCacheKey(k);
    }
    _permissionCache.removeWhere((_, p) => p.userId == userId);
    _schemaCache.clear();
    await _store.clear(prefix: 'u:$userId:');
    _telemetry.increment('purge_user_scoped_data');
  }

  String _permissionKey(String scope) => _sessionKey('perm:$scope');
  String _schemaKey(String kind, String slug) => 'schema:$kind:$slug';
  String _docKey(String slug, String id) => _sessionKey('doc:$slug:$id');

  dynamic _permissionRuleFromPayload(Map<String, dynamic> payload) {
    final rules = <dynamic>[];
    for (final key in const [
      'permissions',
      'permission',
      'guard',
      'guards',
      'requires',
      'access',
      'policy',
      'permissionRule',
    ]) {
      final value = payload[key];
      if (value != null) rules.add(value);
    }
    if (rules.isEmpty) return null;
    return rules.length == 1 ? rules.first : {'all': rules};
  }

  void _enforcePermissionRule(
    dynamic rule, {
    required String slug,
    required String operation,
    required Map<String, dynamic> data,
    bool isGlobal = false,
    String? schema,
  }) {
    final sessionCtx = session.permissionContext(
      data: data,
      scope: slug,
      resource: slug,
      operation: operation,
      schema: schema,
      meta: <String, dynamic>{
        'slug': slug,
        'operation': operation,
        'isGlobal': isGlobal,
        'driver': _config.defaultQueryPolicy.targetDriver ?? 'api',
      },
    );
    final decision =
        QuantumPermissionEngine.instance.evaluate(rule, sessionCtx);
    if (!decision.allowed) {
      throw VaultStreamException(
        'permission_denied',
        decision.reason,
        details: decision.toJson(),
      );
    }
  }

  static int _calculateBytesSyncInIsolate(dynamic payload, [int depth = 0]) {
    if (depth > 10 || payload == null) return 0;
    if (payload is String) return payload.length;
    if (payload is num) return 8;
    if (payload is bool) return 1;
    if (payload is List) {
      int size = 0;
      for (int i = 0; i < payload.length; i++)
        size += _calculateBytesSyncInIsolate(payload[i], depth + 1);
      return size;
    }
    if (payload is Map) {
      int size = 0;
      for (final entry in payload.entries)
        size += _calculateBytesSyncInIsolate(entry.key, depth + 1) +
            _calculateBytesSyncInIsolate(entry.value, depth + 1);
      return size;
    }
    return 8;
  }

  Future<int> _calculateBytes(dynamic payload) async {
    if (!_config.telemetryEnabled) return 0;
    return await QLIsolateBridge.safeRun(
        () => _calculateBytesSyncInIsolate(payload));
  }

  // ─── PROXIES ───────────────────────────────────────────────────────────────

  VaultCollection collection(String slug) => VaultCollection._(this, slug);
  VaultGlobal global(String slug) => VaultGlobal._(this, slug);
  VaultAuth auth() => VaultAuth._(this);
  VaultSchema schema() => VaultSchema._(this);
  VaultAccess access() => VaultAccess._(this);
  VaultCache cache() => VaultCache._(this);
  VaultOffline offline() => VaultOffline._(this);
  VaultBatch batch() => VaultBatch._(this);
  VaultStream stream() => VaultStream._(this);
  VaultTelemetry telemetry() => VaultTelemetry._(this);
  VaultHealth health() => VaultHealth._(this);
  SecureSduiVault get sduiVault => _sduiVault!;
  VaultSecureDisplay secureDisplay() =>
      VaultSecureDisplay._(_secureDisplayEngine!);
  VaultCrypto crypto() => VaultCrypto._(
      _config.securityPolicy.clientSecret ?? 'quantum_default_key');

  // ─── DATA ENGINE READ/WRITE OPERATIONS ─────────────────────────────────────

  Future<ApiResult<dynamic>> executeRead({
    required String slug,
    required Map<String, dynamic> query,
    String? projectionKey,
    QueryPolicy? policy,
    String? id,
    bool isGlobal = false,
  }) async {
    try {
      // 🚀 FIX: Moved 'try' to the very top to safely catch Permission Denials
      final p = policy ?? _config.defaultQueryPolicy;
      final schema = _resolveSchemaBlueprint(slug, isGlobal: isGlobal);
      final familyKey = _queryFamilyKey(slug, query, id: id);
      final requestedCoverage = _requestedCoveragePaths(schema, query);
      final key = id != null
          ? _docKey(slug, id)
          : _queryKey(slug, query, projectionKey);
      final now = _now();

      final readRule = _permissionRuleFromPayload(query);
      if (readRule != null) {
        _enforcePermissionRule(
          readRule,
          slug: slug,
          operation: 'read',
          data: query,
          isGlobal: isGlobal,
        );
      }

      CacheEntry? cached = _cache.remove(key);
      if (cached != null) _cache[key] = cached;
      cached ??= _bestCacheEntryForKey(
        _cache,
        key,
        familyKey,
        schema,
        requestedCoverage,
        _familyIndex,
      );

      final cachedCoverage =
          cached == null ? <String>{} : _entryCoverage(cached, schema);

      if (p.cachePolicy != CachePolicyMode.networkOnly &&
          cached != null &&
          !cached.isExpired(now) &&
          !p.forceRefresh &&
          _coverageContainsAll(cachedCoverage, requestedCoverage)) {
        _cacheHits++;
        _telemetry.increment('cache_hit');
        _cache[key] = cached.touch(now);
        final data = schema == null || requestedCoverage.isEmpty
            ? cached.value
            : _projectCachedValue(cached.value, schema, requestedCoverage);
        return ApiResult.success(data,
            fromCache: true, meta: {'cacheKey': key});
      }

      if (_offline && _config.offlinePolicy.readCacheWhenOffline) {
        if (cached != null) {
          _cacheHits++;
          _telemetry.increment('offline_cache_hit');
          final data = schema == null || requestedCoverage.isEmpty
              ? cached.value
              : _projectCachedValue(cached.value, schema, requestedCoverage);
          return ApiResult.success(data,
              fromCache: true, fromOffline: true, meta: {'cacheKey': key});
        }
        return const ApiResult.failure(
            VaultStreamException('offline_no_cache', 'System Offline'));
      }

      final start = _now();
      final driver = _router.getDriver(p.targetDriver);
      final fetchQuery = Map<String, dynamic>.from(query);
      final missingPaths = schema == null
          ? const <String>[]
          : _missingPaths(requestedCoverage, cachedCoverage);
      if (schema != null && missingPaths.isNotEmpty) {
        fetchQuery['select'] = missingPaths;
      }
      final context = DriverContext(
        session: session,
        policy: p,
        isOffline: _offline,
        securityHeaders: await _securityEngine.generateSecurityHeaders(
            {'slug': slug, 'query': fetchQuery}, 'READ'),
      );

      final result =
          await driver.read(slug, fetchQuery, id: id, context: context);
      final end = _now();
      final resBytes = await _calculateBytes(result.data);
      _telemetry.record(RuntimeTrace(
          name: 'read:$slug',
          startedAt: start,
          endedAt: end,
          duration: end.difference(start),
          requestBytes: 0,
          responseBytes: resBytes,
          cacheHit: false,
          offlineHit: false,
          meta: {'slug': slug, 'driver': driver.driverId}));

      if (result.isSuccess) {
        final projection =
            schema == null ? null : _projectionForQuery(schema, fetchQuery);
        final transformed = schema == null
            ? result.data
            : _applySchemaReadTransform(result.data, schema,
                projection: projection);

        final merged =
            (cached != null && schema != null && missingPaths.isNotEmpty)
                ? _mergeReadPayload(cached.value, transformed)
                : transformed;

        final Iterable<String> finalCoverage = schema == null
            ? const <String>[]
            : (requestedCoverage.isNotEmpty
                ? requestedCoverage
                : _schemaReadablePaths(schema));

        await _cacheWrite(
          key,
          merged,
          ttl: p.ttl,
          tags: {slug, if (isGlobal) 'global'},
          slug: slug,
          docId: id,
          ownerUserId: session.userId,
          sessionId: session.sessionId,
          projectionKey: projectionKey,
          familyKey: familyKey,
          meta: <String, dynamic>{
            'selectPaths': finalCoverage,
            'full': schema != null &&
                missingPaths.isEmpty &&
                _pathsFromProjectionInput(query['select']).isEmpty,
          },
        );

        if (projectionKey != null && merged is Map<String, dynamic>) {
          await _cacheProjectionMerge(slug, id, projectionKey, merged,
              ttl: p.ttl);
        }
      } else {
        _cacheMisses++;
        _telemetry.increment('cache_miss');
      }
      return result;
    } catch (e) {
      _cacheMisses++;
      _telemetry.increment('read_error');
      if (e is VaultStreamException) {
        return ApiResult.failure(e, driverUsed: 'engine');
      }
      return ApiResult.failure(
          VaultStreamException('read_error', e.toString(), details: e),
          driverUsed: 'engine');
    }
  }

  Future<ApiResult<dynamic>> executeWrite({
    required String slug,
    required String op,
    required Map<String, dynamic> body,
    String? id,
    bool isGlobal = false,
    QueryPolicy? policy,
  }) async {
    try {
      // 🚀 FIX: Moved 'try' to the very top to safely catch Permission Denials
      final p = policy ?? _config.defaultQueryPolicy;
      final requestKey =
          _queryKey(slug, {'op': op, ...body, if (id != null) 'id': id});

      final writeRule = _permissionRuleFromPayload(body) ??
          _permissionRuleFromPayload({
            'permissions': body['permissions'],
            'permission': body['permission'],
            'guard': body['guard'],
            'requires': body['requires'],
            'access': body['access'],
            'policy': body['policy'],
          });
      if (writeRule != null) {
        _enforcePermissionRule(
          writeRule,
          slug: slug,
          operation: op,
          data: body,
          isGlobal: isGlobal,
        );
      }

      if (_offline && _config.offlinePolicy.queueWritesWhenOffline) {
        if (_queue.length >= _config.offlinePolicy.maxQueueSize) {
          return const ApiResult.failure(VaultStreamException(
              'offline_queue_full', 'Offline transaction buffer full'));
        }
        _queue.add(_QueuedRequest(
            key: requestKey,
            slug: slug,
            op: op,
            body: body,
            id: id,
            isGlobal: isGlobal,
            policy: p));
        await _persistQueueToDisk();
        _telemetry.increment('queued_write');
        return const ApiResult.success({'queued': true},
            fromOffline: true, meta: {'queued': true});
      }

      final start = _now();
      final driver = _router.getDriver(p.targetDriver);
      final sanitizedBody = _sanitizeSchemaWritePayload(slug, body,
          isGlobal: isGlobal, op: op, id: id);
      final context = DriverContext(
        session: session,
        policy: p,
        isOffline: _offline,
        securityHeaders: await _securityEngine.generateSecurityHeaders(
            {'slug': slug, 'op': op, 'body': sanitizedBody}, 'WRITE'),
      );

      ApiResult<dynamic> result;
      int attempt = 0;
      while (true) {
        result = await driver.write(slug, op, sanitizedBody,
            id: id, context: context);
        if (result.isSuccess || attempt >= 3) break;
        if (result.error?.code == 'http_error' ||
            result.error?.code == 'http_err') {
          break;
        }
        attempt++;
        final delayMs =
            _config.environment == 'test' ? 1 : math.min(250 * attempt, 1200);
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }

      final end = _now();
      final reqBytes = await _calculateBytes(sanitizedBody);
      final resBytes = await _calculateBytes(result.data);
      _telemetry.record(RuntimeTrace(
          name: 'write:$slug/$op',
          startedAt: start,
          endedAt: end,
          duration: end.difference(start),
          requestBytes: reqBytes,
          responseBytes: resBytes,
          cacheHit: false,
          offlineHit: false,
          meta: {'slug': slug, 'op': op, 'driver': driver.driverId}));

      if (result.isSuccess) {
        _invalidateInstant(slug: slug, docId: id, isGlobal: isGlobal);
      } else {
        if (!_offline && _config.offlinePolicy.queueWritesWhenOffline) {
          _queue.add(_QueuedRequest(
              key: requestKey,
              slug: slug,
              op: op,
              body: sanitizedBody,
              id: id,
              isGlobal: isGlobal,
              policy: p));
          await _persistQueueToDisk();
        }
      }
      return result;
    } catch (e) {
      _telemetry.increment('write_error');
      if (e is VaultStreamException) {
        return ApiResult.failure(e, driverUsed: 'engine');
      }
      return ApiResult.failure(
          VaultStreamException('write_error', e.toString(), details: e),
          driverUsed: 'engine');
    }
  }

  Stream<ApiResult<dynamic>> executeSubscribe(
      {required String slug,
      required Map<String, dynamic> query,
      QueryPolicy? policy}) {
    final p = policy ?? config.defaultQueryPolicy;
    // Uses socket driver natively now if injected
    final driver = _router.getDriver('socket');
    final context = DriverContext(
        session: authEngine.session,
        policy: p,
        securityHeaders: const {},
        isOffline: _offline);
    return driver.subscribe(slug, query, context: context);
  }

  Future<void> _cacheWrite(
    String key,
    dynamic value, {
    Duration? ttl,
    Set<String> tags = const {},
    String? slug,
    String? docId,
    String? ownerUserId,
    String? sessionId,
    String? projectionKey,
    String? familyKey,
    bool pinned = false,
    Map<String, dynamic> meta = const {},
  }) async {
    if (!pinned && _cache.length >= _config.maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _removeCacheKey(oldestKey);
      _evictions++;
    }

    final mergedMeta = <String, dynamic>{
      ...meta,
      if (familyKey != null) 'familyKey': familyKey,
    };

    final entry = CacheEntry(
        key: key,
        value: value,
        createdAt: _now(),
        lastAccessAt: _now(),
        ttl: ttl,
        tags: tags,
        slug: slug,
        docId: docId,
        ownerUserId: ownerUserId,
        sessionId: sessionId,
        projectionKey: projectionKey,
        pinned: pinned,
        meta: mergedMeta);
    _cache.remove(key);
    _cache[key] = entry;

    for (final tag in tags) _tagIndex.putIfAbsent(tag, () => {}).add(key);
    if (slug != null) _slugIndex.putIfAbsent(slug, () => {}).add(key);
    if (docId != null) _docIndex.putIfAbsent('$slug:$docId', () => {}).add(key);
    final family = mergedMeta['familyKey']?.toString();
    if (family != null && family.isNotEmpty) {
      _familyIndex.putIfAbsent(family, () => {}).add(key);
    }

    final payload = await _securityEngine.encryptForStorage(value);
    final serialized = await QLIsolateBridge.safeRun(() => jsonEncode(payload));
    unawaited(_store.write(key, serialized));
  }

  void _removeCacheKey(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      for (final tag in entry.tags) {
        final set = _tagIndex[tag];
        if (set != null) {
          set.remove(key);
          if (set.isEmpty) _tagIndex.remove(tag);
        }
      }
      if (entry.slug != null) {
        final set = _slugIndex[entry.slug];
        if (set != null) {
          set.remove(key);
          if (set.isEmpty) _slugIndex.remove(entry.slug);
        }
      }
      if (entry.docId != null) {
        final docKey = '${entry.slug}:${entry.docId}';
        final set = _docIndex[docKey];
        if (set != null) {
          set.remove(key);
          if (set.isEmpty) _docIndex.remove(docKey);
        }
      }
      final family = entry.meta['familyKey']?.toString();
      if (family != null && family.isNotEmpty) {
        final set = _familyIndex[family];
        if (set != null) {
          set.remove(key);
          if (set.isEmpty) _familyIndex.remove(family);
        }
      }
      unawaited(_store.delete(key));
    }
  }

  void _invalidateInstant(
      {required String slug, String? docId, bool isGlobal = false}) {
    Set<String> keysToRemove = {};
    if (isGlobal)
      keysToRemove.addAll(_tagIndex['global'] ?? {});
    else if (docId != null)
      keysToRemove.addAll(_docIndex['$slug:$docId'] ?? {});
    else
      keysToRemove.addAll(_slugIndex[slug] ?? {});

    final toRemove = keysToRemove
        .where((k) => !(_cache[k]?.pinned ?? false))
        .toList(growable: false);
    for (final k in toRemove) _removeCacheKey(k);
  }

  Future<void> _cacheProjectionMerge(String slug, String? id,
      String projectionKey, Map<String, dynamic> partial,
      {Duration? ttl}) async {
    final key = id != null
        ? _docKey(slug, id)
        : _sessionKey('projection:$slug:$projectionKey');
    final existing = _cache[key];
    final merged = <String, dynamic>{
      if (existing?.value is Map<String, dynamic>)
        ...(existing!.value as Map<String, dynamic>),
      ...partial
    };
    await _cacheWrite(key, merged,
        ttl: ttl,
        tags: {slug, 'projection'},
        slug: slug,
        docId: id,
        ownerUserId: session.userId,
        sessionId: session.sessionId,
        projectionKey: projectionKey);
  }

  Future<dynamic> cacheGet(String key) async {
    final entry = _cache.remove(key);
    if (entry == null) {
      _cacheMisses++;
      return null;
    }
    final now = _now();
    if (entry.isExpired(now)) {
      if (!entry.pinned) {
        _removeCacheKey(key);
        _evictions++;
      }
      _cacheMisses++;
      return null;
    }
    _cacheHits++;
    _cache[key] = entry.touch(now);
    return entry.value;
  }

  Future<void> cacheSet(String key, dynamic value,
          {Duration? ttl,
          Set<String> tags = const {},
          bool pinned = false,
          Map<String, dynamic> meta = const {}}) async =>
      _cacheWrite(key, value,
          ttl: ttl,
          tags: tags,
          ownerUserId: session.userId,
          sessionId: session.sessionId,
          pinned: pinned,
          meta: meta);

  Future<void> cacheRemove(String key) async => _removeCacheKey(key);

  Future<void> cacheClear({String? tag}) async {
    if (tag == null) {
      _cache.clear();
      _tagIndex.clear();
      _docIndex.clear();
      _slugIndex.clear();
      await _store.clear();
    } else {
      final keys = _tagIndex[tag]?.toList(growable: false) ?? [];
      for (var k in keys) _removeCacheKey(k);
    }
  }

  Future<void> cacheInvalidateBySlug(String slug) async {
    final keys = _slugIndex[slug]?.toList(growable: false) ?? [];
    for (var k in keys) _removeCacheKey(k);
  }

  Future<CacheStats> cacheStats() async {
    final count = _cache.length;
    final cacheEntries = _cache.map((k, v) => MapEntry(k, v.meta));
    final func = VaultStreamClient._calculateBytesSyncInIsolate;
    final estimate = await QLIsolateBridge.safeRun(() => func(cacheEntries));
    return CacheStats(
        size: count,
        hits: _cacheHits,
        misses: _cacheMisses,
        evictions: _evictions,
        bytesEstimate: estimate);
  }

  Future<SchemaInfo?> getSchema(String kind, String slug,
      {bool forceRefresh = false}) async {
    final key = _schemaKey(kind, slug);
    if (!forceRefresh && _schemaCache.containsKey(key))
      return _schemaCache[key];
    final result = await executeRead(
        slug: slug,
        query: {'op': 'schema', 'kind': kind},
        isGlobal: kind == 'global');
    if (!result.isSuccess) return _schemaCache[key];
    final schema = SchemaInfo(
        slug: slug,
        kind: kind,
        definition: (result.data as Map<String, dynamic>)['schema'] ??
            {'slug': slug, 'kind': kind, 'fields': []},
        fetchedAt: _now(),
        version: '1',
        hash: 'local-${slug.hashCode}');
    _schemaCache[key] = schema;
    return schema;
  }

  Future<void> refreshSchema(String kind, String slug) async {
    _schemaCache.remove(_schemaKey(kind, slug));
    await getSchema(kind, slug, forceRefresh: true);
  }

  Future<PermissionSnapshot> getPermissions(String scope,
      {bool forceRefresh = false}) async {
    final key = _permissionKey(scope);
    final now = _now();
    if (!forceRefresh &&
        _permissionCache.containsKey(key) &&
        !_permissionCache[key]!.isExpired(now)) return _permissionCache[key]!;
    final result = await executeRead(
        slug: scope, query: {'op': 'permissions'}, isGlobal: false);
    final snapshot = PermissionSnapshot(
        scope: scope,
        userId: session.userId,
        fetchedAt: now,
        ttl: _config.accessPolicy.permissionsTtl,
        permissions: result.isSuccess
            ? (result.data as Map<String, dynamic>)
            : {'read': true});
    _permissionCache[key] = snapshot;
    return snapshot;
  }

  Future<void> refreshPermissions(String scope) async {
    _permissionCache.remove(_permissionKey(scope));
    await getPermissions(scope, forceRefresh: true);
  }

  Future<void> syncAll() async {
    if (_queue.isEmpty) return;
    _telemetry.increment('sync_all');
    final pending = List<_QueuedRequest>.from(_queue);
    _queue.clear();
    for (final req in pending) {
      final result = await executeWrite(
          slug: req.slug,
          op: req.op,
          body: req.body,
          id: req.id,
          policy: req.policy,
          isGlobal: req.isGlobal);
      if (!result.isSuccess) {
        _queue.add(req);
      }
    }
    await _persistQueueToDisk();
  }

  Future<void> _persistQueueToDisk() async {
    await _store.write('offline_queue_backup',
        jsonEncode(_queue.map((e) => e.toMap()).toList()));
  }

  Future<void> _restorePersistentQueue() async {
    final data = await _store.read('offline_queue_backup');
    if (data != null) {
      final list = jsonDecode(data) as List;
      _queue.addAll(list.map((e) => _QueuedRequest.fromMap(e)));
    }
  }

  Future<void> retryPending() => syncAll();

  void emitEvent(String name, Map<String, dynamic> payload) {
    if (_events.hasListener)
      _events.add(
          {'name': name, 'payload': payload, 'at': _now().toIso8601String()});
  }

  Future<void> close() async {
    await _router.disposeAll();
    await authEngine.dispose();
    await _socketEngine?.dispose();
    await _mediaEngine?.dispose();
    await _sessionChanges.close();
    await _events.close();
  }
}

// -----------------------------------------------------------------------------
// SECTION 6 — DOMAIN SPECIFIC PROXIES (100% UNTOUCHED ORIGINAL CLASSES)
// -----------------------------------------------------------------------------

class VaultCollection {
  final VaultStreamClient _client;
  final String slug;
  const VaultCollection._(this._client, this.slug);

  Future<ApiResult<dynamic>> create(Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug, op: 'create', body: data, policy: policy);
  Future<ApiResult<dynamic>> createMany(List<Map<String, dynamic>> items,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug, op: 'createMany', body: {'items': items}, policy: policy);
  Future<ApiResult<dynamic>> readById(String id,
          {QueryPolicy? policy, List<String>? select}) =>
      _client.executeRead(
          slug: slug,
          query: {'select': select, 'op': 'readById'},
          id: id,
          policy: policy);
  Future<ApiResult<dynamic>> readOne(Map<String, dynamic> filter,
          {QueryPolicy? policy, List<String>? select}) =>
      _client.executeRead(
          slug: slug,
          query: {'filter': filter, 'select': select, 'op': 'readOne'},
          policy: policy);
  Future<ApiResult<dynamic>> readMany(VaultQuery query,
          {QueryPolicy? policy}) =>
      _client.executeRead(
          slug: slug,
          query: query.toMap(),
          policy: policy,
          projectionKey: query.projectionKey);
  Future<ApiResult<dynamic>> updateById(String id, Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug, op: 'updateById', body: data, id: id, policy: policy);
  Future<ApiResult<dynamic>> updateMany(
          Map<String, dynamic> filter, Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug,
          op: 'updateMany',
          body: {'filter': filter, 'data': data},
          policy: policy);
  Future<ApiResult<dynamic>> upsertById(String id, Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug, op: 'upsertById', body: data, id: id, policy: policy);
  Future<ApiResult<dynamic>> patchById(String id, Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug, op: 'patchById', body: data, id: id, policy: policy);
  Future<ApiResult<dynamic>> deleteById(String id, {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug, op: 'deleteById', body: const {}, id: id, policy: policy);
  Future<ApiResult<dynamic>> deleteMany(Map<String, dynamic> filter,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug,
          op: 'deleteMany',
          body: {'filter': filter},
          policy: policy);
  Future<ApiResult<dynamic>> count(Map<String, dynamic> filter,
          {QueryPolicy? policy}) =>
      _client.executeRead(
          slug: slug, query: {'filter': filter, 'op': 'count'}, policy: policy);
  Future<ApiResult<dynamic>> exists(Map<String, dynamic> filter,
          {QueryPolicy? policy}) =>
      _client.executeRead(
          slug: slug,
          query: {'filter': filter, 'op': 'exists'},
          policy: policy);
  Future<SchemaInfo?> schema({bool forceRefresh = false}) =>
      _client.getSchema('collection', slug, forceRefresh: forceRefresh);
  Future<PermissionSnapshot> permissions({bool forceRefresh = false}) =>
      _client.getPermissions(slug, forceRefresh: forceRefresh);
}

class VaultGlobal {
  final VaultStreamClient _client;
  final String slug;
  const VaultGlobal._(this._client, this.slug);

  Future<ApiResult<dynamic>> get({QueryPolicy? policy}) => _client.executeRead(
      slug: slug,
      query: const {'op': 'getGlobal'},
      policy: policy,
      isGlobal: true);
  Future<ApiResult<dynamic>> set(Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug,
          op: 'setGlobal',
          body: data,
          isGlobal: true,
          policy: policy);
  Future<ApiResult<dynamic>> update(Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug,
          op: 'updateGlobal',
          body: data,
          isGlobal: true,
          policy: policy);
  Future<ApiResult<dynamic>> upsert(Map<String, dynamic> data,
          {QueryPolicy? policy}) =>
      _client.executeWrite(
          slug: slug,
          op: 'upsertGlobal',
          body: data,
          isGlobal: true,
          policy: policy);
  Future<SchemaInfo?> schema({bool forceRefresh = false}) =>
      _client.getSchema('global', slug, forceRefresh: forceRefresh);
}

VaultStreamException _authErrorToVault(AuthException? error) =>
    VaultStreamException(error?.code ?? 'auth_error',
        error?.message ?? 'Security authorization rejected',
        details: error?.details);

class VaultAuth {
  final VaultStreamClient _client;
  const VaultAuth._(this._client);

  Future<ApiResult<dynamic>> register(Map<String, dynamic> payload,
      {QueryPolicy? policy,
      AuthProvider provider = AuthProvider.emailPassword}) async {
    final result =
        await _client.authEngine.register(payload, provider: provider);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> login(Map<String, dynamic> payload,
      {QueryPolicy? policy,
      AuthProvider provider = AuthProvider.emailPassword}) async {
    final result = await _client.authEngine.login(payload, provider: provider);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> loginWithProvider(
      AuthProvider provider, Map<String, dynamic> payload,
      {QueryPolicy? policy}) async {
    final result =
        await _client.authEngine.loginWithProvider(provider, payload);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> requestOtp(
      {required String destination,
      String purpose = 'login',
      OtpChannel channel = OtpChannel.email,
      QueryPolicy? policy}) async {
    final result = await _client.authEngine.requestOtp(
        destination: destination, purpose: purpose, channel: channel);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> verifyOtp(
      {required String destination,
      required String code,
      String purpose = 'login',
      QueryPolicy? policy}) async {
    final result = await _client.authEngine
        .verifyOtp(destination: destination, code: code, purpose: purpose);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> startPasskeyRegistration(
      {required String userId, QueryPolicy? policy}) async {
    final result =
        await _client.authEngine.startPasskeyRegistration(userId: userId);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> completePasskeyRegistration(
      {required String userId,
      required Map<String, dynamic> credential,
      QueryPolicy? policy}) async {
    final result = await _client.authEngine
        .completePasskeyRegistration(userId: userId, credential: credential);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> startPasskeyAuthentication(
      {required String userId, QueryPolicy? policy}) async {
    final result =
        await _client.authEngine.startPasskeyAuthentication(userId: userId);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> completePasskeyAuthentication(
      {required String userId,
      required Map<String, dynamic> credential,
      QueryPolicy? policy}) async {
    final result = await _client.authEngine
        .completePasskeyAuthentication(userId: userId, credential: credential);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> linkProvider(
      AuthProvider provider, Map<String, dynamic> payload,
      {QueryPolicy? policy}) async {
    final result = await _client.authEngine.linkProvider(provider, payload);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> unlinkProvider(AuthProvider provider,
      {Map<String, dynamic> payload = const {}, QueryPolicy? policy}) async {
    final result = await _client.authEngine.unlinkProvider(provider);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> confirmOperation(
      {required String operation,
      required Map<String, dynamic> payload,
      QueryPolicy? policy}) async {
    final result = await _client.authEngine
        .confirmOperation(operation: operation, payload: payload);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> logout({QueryPolicy? policy}) async {
    await _client.clearSession(purgeCache: true);
    return const ApiResult.success({'ok': true}, driverUsed: 'auth_engine');
  }

  Future<ApiResult<dynamic>> me({QueryPolicy? policy}) async {
    return ApiResult.success(_client.session.toJson(),
        driverUsed: 'auth_engine');
  }

  Future<ApiResult<dynamic>> refreshSession({QueryPolicy? policy}) async {
    final result = await _client.authEngine.refresh();
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> verifyEmail(String token,
      {QueryPolicy? policy}) async {
    final result = await _client.authEngine.verifyEmail(token);
    return result.isSuccess
        ? const ApiResult.success({'ok': true}, driverUsed: 'auth_engine')
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> resendVerification({QueryPolicy? policy}) async {
    final result = await _client.authEngine.resendVerification();
    return result.isSuccess
        ? const ApiResult.success({'ok': true}, driverUsed: 'auth_engine')
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> forgotPassword(String email,
      {QueryPolicy? policy}) async {
    final result = await _client.authEngine.forgotPassword(email);
    return result.isSuccess
        ? const ApiResult.success({'ok': true}, driverUsed: 'auth_engine')
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> resetPassword(
      {required String token,
      required String password,
      QueryPolicy? policy}) async {
    final result = await _client.authEngine
        .resetPassword(token: token, password: password);
    return result.isSuccess
        ? const ApiResult.success({'ok': true}, driverUsed: 'auth_engine')
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> changePassword(
      {required String oldPassword,
      required String newPassword,
      QueryPolicy? policy}) async {
    final result = await _client.authEngine
        .changePassword(oldPassword: oldPassword, newPassword: newPassword);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> unlockAccount(String token,
      {QueryPolicy? policy}) async {
    final result = await _client.authEngine.unlockAccount(token);
    return result.isSuccess
        ? const ApiResult.success({'ok': true}, driverUsed: 'auth_engine')
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> revokeAllSessions({QueryPolicy? policy}) async {
    final result = await _client.authEngine.revokeAllSessions();
    return result.isSuccess
        ? const ApiResult.success({'ok': true}, driverUsed: 'auth_engine')
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> updateProfile(Map<String, dynamic> profile,
      {QueryPolicy? policy}) async {
    final result = await _client.authEngine.updateProfile(profile);
    return result.isSuccess
        ? ApiResult.success(result.data?.toJson(),
            driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> discoverAuthMethods({QueryPolicy? policy}) async {
    final result = await _client.authEngine.discoverAuthMethods();
    return result.isSuccess
        ? ApiResult.success(result.data, driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }

  Future<ApiResult<dynamic>> getAuthPolicy({QueryPolicy? policy}) async {
    final result = await _client.authEngine.getAuthPolicy();
    return result.isSuccess
        ? ApiResult.success(result.data, driverUsed: result.driverUsed)
        : ApiResult.failure(_authErrorToVault(result.error),
            driverUsed: result.driverUsed);
  }
}

class VaultSchema {
  final VaultStreamClient _client;
  const VaultSchema._(this._client);
  Future<SchemaInfo?> collection(String slug, {bool forceRefresh = false}) =>
      _client.getSchema('collection', slug, forceRefresh: forceRefresh);
  Future<SchemaInfo?> global(String slug, {bool forceRefresh = false}) =>
      _client.getSchema('global', slug, forceRefresh: forceRefresh);
  Future<void> refreshCollection(String slug) =>
      _client.refreshSchema('collection', slug);
  Future<void> refreshGlobal(String slug) =>
      _client.refreshSchema('global', slug);
}

class VaultAccess {
  final VaultStreamClient _client;
  const VaultAccess._(this._client);
  Future<PermissionSnapshot> permissions(String scope,
          {bool forceRefresh = false}) =>
      _client.getPermissions(scope, forceRefresh: forceRefresh);
  Future<void> refresh(String scope) => _client.refreshPermissions(scope);
  Future<bool> canRead(String scope) async =>
      (await permissions(scope)).permissions['read'] != false;
  Future<bool> canCreate(String scope) async =>
      (await permissions(scope)).permissions['create'] == true;
  Future<bool> canUpdate(String scope) async =>
      (await permissions(scope)).permissions['update'] == true;
  Future<bool> canDelete(String scope) async =>
      (await permissions(scope)).permissions['delete'] == true;
}

class VaultCache {
  final VaultStreamClient _client;
  const VaultCache._(this._client);
  Future<dynamic> get(String key) => _client.cacheGet(key);
  Future<void> set(String key, dynamic value,
          {Duration? ttl,
          Set<String> tags = const {},
          bool pinned = false,
          Map<String, dynamic> meta = const {}}) =>
      _client.cacheSet(key, value,
          ttl: ttl, tags: tags, pinned: pinned, meta: meta);
  Future<void> remove(String key) => _client.cacheRemove(key);
  Future<void> clear({String? tag}) => _client.cacheClear(tag: tag);
  Future<void> invalidateBySlug(String slug) =>
      _client.cacheInvalidateBySlug(slug);
  Future<CacheStats> stats() => _client.cacheStats();

  // ─── ENHANCED CACHE MANAGEMENT ─────────────────────────────────────────────

  Future<CacheEntry?> inspect(String key) async => _client._cache[key];

  Future<List<CacheEntry>> inspectAll({String? tag, String? slug}) async {
    if (tag != null) {
      final keys = _client._tagIndex[tag] ?? <String>{};
      return keys
          .map((k) => _client._cache[k])
          .whereType<CacheEntry>()
          .toList();
    }
    if (slug != null) {
      final keys = _client._slugIndex[slug] ?? <String>{};
      return keys
          .map((k) => _client._cache[k])
          .whereType<CacheEntry>()
          .toList();
    }
    return _client._cache.values.toList();
  }

  Future<void> pin(String key) async {
    final entry = _client._cache[key];
    if (entry != null) {
      _client._cache[key] = CacheEntry(
        key: entry.key,
        value: entry.value,
        createdAt: entry.createdAt,
        lastAccessAt: entry.lastAccessAt,
        ttl: entry.ttl,
        tags: entry.tags,
        slug: entry.slug,
        docId: entry.docId,
        ownerUserId: entry.ownerUserId,
        sessionId: entry.sessionId,
        projectionKey: entry.projectionKey,
        pinned: true,
        meta: entry.meta,
      );
    }
  }

  Future<void> unpin(String key) async {
    final entry = _client._cache[key];
    if (entry != null) {
      _client._cache[key] = CacheEntry(
        key: entry.key,
        value: entry.value,
        createdAt: entry.createdAt,
        lastAccessAt: entry.lastAccessAt,
        ttl: entry.ttl,
        tags: entry.tags,
        slug: entry.slug,
        docId: entry.docId,
        ownerUserId: entry.ownerUserId,
        sessionId: entry.sessionId,
        projectionKey: entry.projectionKey,
        pinned: false,
        meta: entry.meta,
      );
    }
  }

  Future<int> purgeExpired() async {
    final now = DateTime.now();
    final expired = _client._cache.entries
        .where((e) => e.value.isExpired(now) && !e.value.pinned)
        .map((e) => e.key)
        .toList(growable: false);
    for (final k in expired) _client._removeCacheKey(k);
    return expired.length;
  }

  Future<List<String>> entries({String? tag, String? slug}) async {
    if (tag != null) return (_client._tagIndex[tag] ?? <String>{}).toList();
    if (slug != null) return (_client._slugIndex[slug] ?? <String>{}).toList();
    return _client._cache.keys.toList();
  }

  Future<void> revalidate(String key) async {
    final entry = _client._cache[key];
    if (entry == null || entry.slug == null) return;
    await _client.executeRead(
      slug: entry.slug!,
      query: const {},
      id: entry.docId,
      policy: const QueryPolicy(forceRefresh: true),
    );
  }

  Future<void> revalidateBySlug(String slug) async {
    final keys =
        (_client._slugIndex[slug] ?? <String>{}).toList(growable: false);
    for (final k in keys) await revalidate(k);
  }
}

class VaultOffline {
  final VaultStreamClient _client;
  const VaultOffline._(this._client);
  void enable() => _client.setOffline(true);
  void disable() => _client.setOffline(false);
  bool get isEnabled => _client.isOffline;
  Future<void> syncAll() => _client.syncAll();
  Future<void> retryPending() => _client.retryPending();
}

class VaultBatch {
  final VaultStreamClient _client;
  const VaultBatch._(this._client);
  Future<List<ApiResult<dynamic>>> run(
    List<Future<ApiResult<dynamic>> Function()> requests, {
    bool stopOnFailure = true,
  }) async {
    final out = <ApiResult<dynamic>>[];
    for (final req in requests) {
      try {
        final result = await req();
        out.add(result);
        if (stopOnFailure && !result.isSuccess) break;
      } catch (e, st) {
        out.add(ApiResult.failure(
          VaultStreamException('batch_error', e.toString(),
              details: {'stackTrace': st.toString()}),
          driverUsed: 'batch',
        ));
        if (stopOnFailure) break;
      }
    }
    return out;
  }
}

class VaultStream {
  final VaultStreamClient _client;
  const VaultStream._(this._client);
  StreamController<T> open<T>({StreamDirection? direction}) =>
      StreamController<T>.broadcast(sync: true);
  Stream<T> transform<TIn, T>(
          Stream<TIn> input, T Function(TIn value) mapper) =>
      input.map(mapper);
}

class VaultTelemetry {
  final VaultStreamClient _client;
  const VaultTelemetry._(this._client);
  Map<String, dynamic> snapshot() => _client._telemetry.snapshot();
}

class VaultHealth {
  final VaultStreamClient _client;
  const VaultHealth._(this._client);
  Future<Map<String, dynamic>> summary() async {
    final stats = await _client.cacheStats();
    return {
      'initialized': _client.isInitialized,
      'offline': _client.isOffline,
      'session': {
        'authenticated': _client.session.isAuthenticated,
        'userId': _client.session.userId,
        'sessionId': _client.session.sessionId
      },
      'cache': {
        'size': stats.size,
        'hits': stats.hits,
        'misses': stats.misses,
        'evictions': stats.evictions,
        'bytesEstimate': stats.bytesEstimate
      },
      'telemetry': _client._telemetry.snapshot(),
    };
  }
}

// -----------------------------------------------------------------------------
// SECTION 6B — SECURE SDUI VAULT (Long-Term Encrypted Local JSON Storage)
// -----------------------------------------------------------------------------

class _SduiMeta {
  final String key;
  final String versionHash;
  final DateTime storedAt;
  final int sizeBytes;
  final bool requireAuth;
  const _SduiMeta(
      {required this.key,
      required this.versionHash,
      required this.storedAt,
      required this.sizeBytes,
      this.requireAuth = false});
  Map<String, dynamic> toJson() => {
        'key': key,
        'versionHash': versionHash,
        'storedAt': storedAt.toIso8601String(),
        'sizeBytes': sizeBytes,
        'requireAuth': requireAuth
      };
  factory _SduiMeta.fromJson(Map<String, dynamic> j) => _SduiMeta(
        key: j['key'] as String,
        versionHash: j['versionHash'] as String,
        storedAt: DateTime.parse(j['storedAt'] as String),
        sizeBytes: j['sizeBytes'] as int,
        requireAuth: j['requireAuth'] as bool? ?? false,
      );
}

class SecureSduiVault {
  final LocalStore _store;
  final String _secret;
  final QuantumAuthEngine _authEngine;
  static const _prefix = 'sdui_vault:';
  static const _metaKey = 'sdui_vault_meta';

  SecureSduiVault(
      {required LocalStore store,
      required String secret,
      required QuantumAuthEngine authEngine})
      : _store = store,
        _secret = secret,
        _authEngine = authEngine;

  String _vaultKey(String key) => '$_prefix$key';

  /// Encrypt and persist SDUI JSON for long-term storage.
  Future<void> store(String key, Map<String, dynamic> json,
      {String? version, bool requireAuth = false}) async {
    final serialized = jsonEncode(json);
    final versionHash = version ?? QuantumCipher.hash(serialized);
    final envelope = await QLIsolateBridge.safeRun(
        () => QuantumCipher.encrypt(serialized, _secret));
    final integrityTag =
        QuantumCipher.sign('$key:$versionHash:$envelope', _secret);
    final record = jsonEncode({
      'envelope': envelope,
      'version': versionHash,
      'integrity': integrityTag,
      'storedAt': DateTime.now().toIso8601String()
    });
    await _store.write(_vaultKey(key), record);
    await _updateMeta(key, versionHash, serialized.length, requireAuth);
  }

  /// Load and decrypt SDUI JSON. Returns null if not found or tampered (auto-purges on tamper).
  /// Strictly blocks decryption if authentication is required but missing.
  /// Returned Map is unmodifiable to prevent memory tampering.
  Future<Map<String, dynamic>?> load(String key) async {
    _SduiMeta? meta;
    for (final m in await _loadMetaEntries()) {
      if (m.key == key) {
        meta = m;
        break;
      }
    }
    if (meta != null && meta.requireAuth && !_authEngine.isAuthenticated) {
      // Rejects without ever running the AES cipher. JSON remains securely encrypted on disk.
      return null;
    }

    final raw = await _store.read(_vaultKey(key));
    if (raw == null) return null;
    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      final envelope = record['envelope'] as String;
      final version = record['version'] as String;
      final integrity = record['integrity'] as String;
      if (!QuantumCipher.verify(
          '$key:$version:$envelope', integrity, _secret)) {
        await invalidate(key);
        return null;
      }
      final decrypted = await QLIsolateBridge.safeRun(
          () => QuantumCipher.decrypt(envelope, _secret));
      return Map.unmodifiable(jsonDecode(decrypted) as Map<String, dynamic>);
    } catch (_) {
      await invalidate(key);
      return null;
    }
  }

  /// Check if stored version differs from [serverVersion].
  Future<bool> needsUpdate(String key, String serverVersion) async {
    final raw = await _store.read(_vaultKey(key));
    if (raw == null) return true;
    try {
      final record = jsonDecode(raw) as Map<String, dynamic>;
      return record['version'] != serverVersion;
    } catch (_) {
      return true;
    }
  }

  /// Atomic update: re-encrypt with new JSON and version.
  Future<void> applyUpdate(
          String key, Map<String, dynamic> newJson, String newVersion) =>
      store(key, newJson, version: newVersion);

  /// Remove a stored SDUI entry.
  Future<void> invalidate(String key) async {
    await _store.delete(_vaultKey(key));
    await _removeMeta(key);
  }

  /// Remove all stored SDUI entries.
  Future<void> invalidateAll() async {
    final keys = await _store.keys(prefix: _prefix);
    for (final k in keys) await _store.delete(k);
    await _store.delete(_metaKey);
  }

  /// List metadata of all stored entries.
  Future<List<Map<String, dynamic>>> listStored() async {
    final raw = await _store.read(_metaKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> _updateMeta(
      String key, String versionHash, int sizeBytes, bool requireAuth) async {
    final entries = await _loadMetaEntries();
    entries.removeWhere((m) => m.key == key);
    entries.add(_SduiMeta(
        key: key,
        versionHash: versionHash,
        storedAt: DateTime.now(),
        sizeBytes: sizeBytes,
        requireAuth: requireAuth));
    await _store.write(
        _metaKey, jsonEncode(entries.map((m) => m.toJson()).toList()));
  }

  Future<void> _removeMeta(String key) async {
    final entries = await _loadMetaEntries();
    entries.removeWhere((m) => m.key == key);
    await _store.write(
        _metaKey, jsonEncode(entries.map((m) => m.toJson()).toList()));
  }

  Future<List<_SduiMeta>> _loadMetaEntries() async {
    final raw = await _store.read(_metaKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => _SduiMeta.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// -----------------------------------------------------------------------------
// SECTION 6C — SECURE DISPLAY PAYLOAD (Tamper-Proof Server→Client Display)
// -----------------------------------------------------------------------------

class SecureDisplayResult {
  final Map<String, dynamic>? data;
  final String? rejectionReason;
  bool get isVerified => data != null && rejectionReason == null;
  const SecureDisplayResult.verified(this.data) : rejectionReason = null;
  const SecureDisplayResult.rejected(this.rejectionReason) : data = null;
}

class SecureDisplayEngine {
  final String _secret;
  final Duration _maxAge;
  final Set<String> _consumedNonces = {};
  static const int _maxNonceBufferSize = 10000;

  SecureDisplayEngine({required String secret, Duration? maxAge})
      : _secret = secret,
        _maxAge = maxAge ?? const Duration(minutes: 5);

  /// Verify a server-signed secure display payload.
  SecureDisplayResult verify(Map<String, dynamic> payload) {
    final data = payload['data'];
    final signature = payload['signature'] as String?;
    final timestamp = payload['timestamp'] as int?;
    final nonce = payload['nonce'] as String?;
    if (signature == null ||
        timestamp == null ||
        nonce == null ||
        data == null) {
      return const SecureDisplayResult.rejected('Missing required fields');
    }
    // Anti-replay: check nonce
    if (_consumedNonces.contains(nonce)) {
      return const SecureDisplayResult.rejected(
          'Replay detected: nonce already consumed');
    }
    // Timestamp validation
    final payloadTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(payloadTime).abs() > _maxAge) {
      return const SecureDisplayResult.rejected(
          'Payload expired or clock skew too large');
    }
    // Signature verification
    final signatureInput = '$nonce:$timestamp:${jsonEncode(data)}';
    if (!QuantumCipher.verify(signatureInput, signature, _secret)) {
      return const SecureDisplayResult.rejected(
          'Invalid signature — data tampered');
    }
    // Consume nonce
    if (_consumedNonces.length >= _maxNonceBufferSize) {
      _consumedNonces.clear();
    }
    _consumedNonces.add(nonce);
    return SecureDisplayResult.verified(
        data is Map<String, dynamic> ? data : {'value': data});
  }

  /// Verify and consume a one-time display token.
  SecureDisplayResult verifyAndConsume(Map<String, dynamic> payload) {
    final result = verify(payload);
    if (result.isVerified) {
      final token = payload['displayToken'] as String?;
      if (token != null) _consumedNonces.add('token:$token');
    }
    return result;
  }
}

class VaultSecureDisplay {
  final SecureDisplayEngine _engine;
  const VaultSecureDisplay._(this._engine);
  SecureDisplayResult verify(Map<String, dynamic> payload) =>
      _engine.verify(payload);
  SecureDisplayResult verifyAndConsume(Map<String, dynamic> payload) =>
      _engine.verifyAndConsume(payload);
}

// -----------------------------------------------------------------------------
// SECTION 6D — VAULT CRYPTO API (Public Encryption for Developers)
// -----------------------------------------------------------------------------

class VaultCrypto {
  final String _secret;
  const VaultCrypto._(this._secret);
  Future<String> encrypt(dynamic data, {String? key}) async {
    final secret = key ?? _secret;
    final serialized = jsonEncode(data);
    return await QLIsolateBridge.safeRun(
        () => QuantumCipher.encrypt(serialized, secret));
  }

  Future<dynamic> decrypt(String envelope, {String? key}) async {
    final secret = key ?? _secret;
    final decrypted = await QLIsolateBridge.safeRun(
        () => QuantumCipher.decrypt(envelope, secret));
    return jsonDecode(decrypted);
  }

  String sign(dynamic data) => QuantumCipher.sign(jsonEncode(data), _secret);
  bool verify(dynamic data, String signature) =>
      QuantumCipher.verify(jsonEncode(data), signature, _secret);
  String hash(dynamic data) => QuantumCipher.hash(jsonEncode(data));
}

class VaultQuery {
  final Map<String, dynamic> _data = {};
  String? get projectionKey =>
      _data['select'] is List ? _data['select'].join(',') : null;

  VaultQuery where(String field, dynamic value) {
    _data.putIfAbsent('where', () => <String, dynamic>{});
    (_data['where'] as Map<String, dynamic>)[field] = value;
    return this;
  }

  VaultQuery and(List<Map<String, dynamic>> clauses) {
    _data['and'] = clauses;
    return this;
  }

  VaultQuery or(List<Map<String, dynamic>> clauses) {
    _data['or'] = clauses;
    return this;
  }

  VaultQuery not(Map<String, dynamic> clause) {
    _data['not'] = clause;
    return this;
  }

  VaultQuery sortBy(String field, {bool descending = false}) {
    _data['sort'] = {'field': field, 'descending': descending};
    return this;
  }

  VaultQuery limit(int value) {
    _data['limit'] = value;
    return this;
  }

  VaultQuery limitToLast(int value) {
    _data['limitToLast'] = value;
    return this;
  }

  VaultQuery startAfter(List<dynamic> values) {
    _data['startAfter'] = values;
    return this;
  }

  VaultQuery startAt(List<dynamic> values) {
    _data['startAt'] = values;
    return this;
  }

  VaultQuery endBefore(List<dynamic> values) {
    _data['endBefore'] = values;
    return this;
  }

  VaultQuery endAt(List<dynamic> values) {
    _data['endAt'] = values;
    return this;
  }

  VaultQuery offset(int value) {
    _data['offset'] = value;
    return this;
  }

  VaultQuery page(int value) {
    _data['page'] = value;
    return this;
  }

  VaultQuery select(List<String> fields) {
    _data['select'] = fields;
    return this;
  }

  VaultQuery populate(List<String> relations) {
    _data['populate'] = relations;
    return this;
  }

  VaultQuery depth(int value) {
    _data['depth'] = value;
    return this;
  }

  VaultQuery search(String value) {
    _data['search'] = value;
    return this;
  }

  VaultQuery distinct(String field) {
    _data['distinct'] = field;
    return this;
  }

  VaultQuery groupBy(String field) {
    _data['groupBy'] = field;
    return this;
  }

  VaultQuery aggregate(Map<String, dynamic> ops) {
    _data['aggregate'] = ops;
    return this;
  }

  VaultQuery rawFilter(Map<String, dynamic> filter) {
    _data['filter'] = filter;
    return this;
  }

  Map<String, dynamic> toMap() => Map<String, dynamic>.from(_data);
}

extension VaultQueryFactory on VaultCollection {
  Future<ApiResult<dynamic>> read(VaultQuery query, {QueryPolicy? policy}) =>
      readMany(query, policy: policy);
}

// -----------------------------------------------------------------------------
// SECTION 7 — MOCK FALLBACK DRIVER (100% UNTOUCHED)
// -----------------------------------------------------------------------------

class _MockFallbackDriver implements VaultDriver {
  @override
  String get driverId => 'mock_fallback';
  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    await Future.delayed(const Duration(milliseconds: 1));
    if (id != null)
      return ApiResult.success(
          <String, dynamic>{'id': id, 'slug': slug, 'query': query},
          driverUsed: driverId);
    return ApiResult.success(<String, dynamic>{
      'items': [
        {'id': '1', 'slug': slug}
      ],
      'page': query['page'] ?? 1,
      'limit': query['limit'] ?? 10
    }, driverUsed: driverId);
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    await Future.delayed(const Duration(milliseconds: 1));
    return ApiResult.success(<String, dynamic>{
      'ok': true,
      'op': op,
      'slug': slug,
      'id':
          id ?? body['id'] ?? DateTime.now().microsecondsSinceEpoch.toString(),
      'body': body
    }, driverUsed: driverId);
  }

  @override
  Stream<ApiResult<dynamic>> subscribe(String slug, Map<String, dynamic> query,
      {required DriverContext context}) async* {
    yield ApiResult.success(const {'event': 'mock_subscribe'},
        driverUsed: driverId);
  }

  @override
  Future<void> dispose() async {}
}

String _queryKey(String slug, Map<String, dynamic> query,
    [String? projectionKey]) {
  final hash = _fastHashQuery(query);
  return _sessionKey('query:$slug:$hash:${projectionKey ?? ''}');
}

int _fastHashQuery(Map<String, dynamic> query, [int depth = 0]) {
  if (depth > 10) return 0;
  final keys = query.keys.toList(growable: false)..sort();
  int hash = 0;
  for (int i = 0; i < keys.length; i++) {
    hash = Object.hash(hash, keys[i], _hashValue(query[keys[i]], depth + 1));
  }
  return hash;
}

int _hashValue(dynamic value, int depth) {
  if (depth > 10) return 0;
  if (value is Map<String, dynamic>) return _fastHashQuery(value, depth + 1);
  if (value is List) {
    int listHash = 0;
    for (int i = 0; i < value.length; i++)
      listHash = Object.hash(listHash, _hashValue(value[i], depth + 1));
    return listHash;
  }
  return value.hashCode;
}

String _sessionKey(String key) => _baseSessionPrefix + key;
String _baseSessionPrefix = 's:anon|u:guest|';
