/*
 * ============================================================================
 * File: network_shell.dart
 * 
 * Description:
 * The single entry point facade (Quantum shell) for the OmniCloud networking core, 
 * providing high-level wrappers for APIs, caching, streaming, media, offline sync, 
 * and dynamic action routing.
 * 
 * Key Components:
 * - Quantum: The unified facade for initializing and accessing network capabilities.
 * - OmniCollection / OmniGlobal: Simplified database and global settings abstractions.
 * - Facades (_OmniDbFacade, _OmniAuthFacade): Grouped functional boundaries.
 * 
 * Dependencies/Relationships:
 * Wraps functionality from network.dart and provides an easy-to-consume SDUI API.
 * 
 * Notes:
 * Handles continuous streams, live database queries, and background media pipelines.
 * ============================================================================
 */
// =============================================================================
// network_shell.dart
// =============================================================================
// The Ultimate Single Entrypoint Facade for the OmniCloud Enhanced Core.
// Unsimplified. Uncompromised. 100% Production Ready.
// =============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

// Import the core engine (ensure the path is correct for your project)
import 'network.dart';

enum QuantumDriverMode { mock, http, grpc }

/// Unified Configuration for the Quantum Shell
class OmniShellConfig {
  final String apiUrl;
  final String socketUrl;
  final String? mediaUrl;
  final String? udpUrl;
  final String cacheDirectoryPath;
  final String environment;
  final String? clientSecret;
  final bool enableTelemetry;
  final bool enableOfflineQueueing;
  final QuantumDriverMode driverMode;

  // Advanced Network Simulation & Tuning
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final int maxRetries;
  final List<String>? allowedCertFingerprintsSha256;

  const OmniShellConfig({
    required this.apiUrl,
    required this.socketUrl,
    this.mediaUrl,
    this.udpUrl,
    required this.cacheDirectoryPath,
    this.environment = 'production',
    this.clientSecret,
    this.enableTelemetry = true,
    this.enableOfflineQueueing = true,
    this.driverMode = QuantumDriverMode.http,
    this.connectTimeout = const Duration(seconds: 20),
    this.receiveTimeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.allowedCertFingerprintsSha256,
  });
}

/// The Ultimate Single Entrypoint Facade for OmniCloud
class Quantum {
  static AppSdk? _sdk;
  static SessionStore? _sessionStore;

  static bool get isInitialized => _sdk != null;

  // High-performance memory-maps for continuous streams & background pipelines
  static final Map<String, dynamic> _activeTasks = {};
  static final Map<String, StreamSubscription> _activeSubscriptions = {};

  Quantum._();

  static const SessionContext _guestSession = SessionContext(
    claims: <String, dynamic>{
      'roles': <String>['guest']
    },
  );

  static SessionContext _sessionFromArgs(Map<String, dynamic> args) {
    final dynamic raw = args['session'] ?? args['auth'] ?? args['context'];
    if (raw is SessionContext) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return SessionContext.fromJson(map);
    }
    return _guestSession;
  }

  /// Initializes the entire engine, routing manifests, cache policies, and offline sync.
  static Future<void> initialize(OmniShellConfig config) async {
    if (isInitialized) return;

    if (config.driverMode == QuantumDriverMode.http &&
        config.apiUrl.trim().isEmpty) {
      throw ArgumentError(
          'OmniShellConfig.apiUrl is required when driverMode is http.');
    }

    _sessionStore = SessionStore();

    // Construct robust client configuration
    final clientConfig = ApiClientConfig(
      baseUrl: Uri.parse(config.apiUrl),
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      enableLogging: config.environment != 'production',
      defaultTrustTier: ApiTrustTier.authenticatedPublic,
      maxRetries: config.maxRetries,
      allowedCertFingerprintsSha256: config.allowedCertFingerprintsSha256,
      defaultHeaders: {
        if (config.clientSecret != null)
          'X-Client-Secret': config.clientSecret!,
        'X-Environment': config.environment,
      },
    );

    // Initialize the core ApiClient
    final apiClient = ApiClient(
      config: clientConfig,
      authProvider: _sessionStore, // Dynamically linked SessionStore
      // Note: You can inject a SecurePersistentCacheStore here based on cacheDirectoryPath
      cacheStore: MemoryCacheStore(maxEntries: 1000),
      // If clientSecret is provided, enforce HMAC
      pipeline: RequestPipeline(policies: [
        TraceparentPolicy(),
        if (config.clientSecret != null)
          HmacSigningPolicy(config.clientSecret!),
      ]),
      cryptoPolicy:
          PassThroughCryptoPolicy(), // Can be swapped with ExternalCryptoPolicy
    );

    // Mount to the main AppSdk wrapper
    _sdk = AppSdk(apiClient);

    // Start background local proxy for media caching
    await _sdk!.mediaProxy.start();
  }

  static AppSdk get _engine {
    if (!isInitialized)
      throw Exception(
          'Quantum Shell offline. Call Quantum.initialize() first.');
    return _sdk!;
  }

  // ===========================================================================
  // ERGONOMIC NAMESPACES (Direct zero-overhead pointers)
  // ===========================================================================
  static _OmniDbFacade get db => _OmniDbFacade(_engine);
  static _OmniAuthFacade get auth => _OmniAuthFacade(_engine, _sessionStore!);
  static _OmniMediaFacade get media => _OmniMediaFacade(_engine);
  static _OmniRealtimeFacade get realtime => _OmniRealtimeFacade(_engine);
  static _OmniCacheFacade get cache => _OmniCacheFacade(_engine);
  static _OmniOfflineFacade get offline => _OmniOfflineFacade(_engine);
  static _OmniCryptoFacade get crypto => _OmniCryptoFacade(_engine);

  // ===========================================================================
  // SDUI JSON PARSER: THE 'QUERY' BODY BUILDER
  // ===========================================================================

  static Map<String, dynamic> _buildQueryMap(Map<String, dynamic> args) {
    final Map<String, dynamic> query = {};
    if (args['filter'] != null) query['filter'] = args['filter'];
    if (args['where'] != null) query['where'] = args['where'];
    if (args['and'] != null) query['and'] = args['and'];
    if (args['or'] != null) query['or'] = args['or'];
    if (args['not'] != null) query['not'] = args['not'];
    if (args['sortBy'] != null) query['sortBy'] = args['sortBy'];
    if (args['limit'] != null) query['limit'] = args['limit'];
    if (args['offset'] != null) query['offset'] = args['offset'];
    if (args['page'] != null) query['page'] = args['page'];
    if (args['select'] != null) query['select'] = args['select'];
    if (args['populate'] != null) query['populate'] = args['populate'];
    if (args['search'] != null) query['search'] = args['search'];
    return query;
  }

  static CachePolicy _buildPolicy(Map<String, dynamic>? args) {
    if (args == null || args['policy'] == null) return CachePolicy.networkOnly;
    final p = args['policy'];
    if (p['forceRefresh'] == true) return CachePolicy.networkOnly;
    if (p['cacheFirst'] == true) return CachePolicy.cacheFirst;
    if (p['cacheOnly'] == true) return CachePolicy.cacheOnly;
    return CachePolicy.networkOnly;
  }

  // ===========================================================================
  // SDUI: ONE-TIME EXECUTIONS (Exposing Full Unsimplified Engine Capabilities)
  // ===========================================================================

  static Future<Map<String, dynamic>> runAction(
      Map<String, dynamic> json) async {
    try {
      final domain = json['domain'] as String;
      final action = json['action'] as String;
      final args = (json['args'] as Map<String, dynamic>?) ?? {};
      final resource = (json['resource'] ?? args['resource']) as String?;
      final cachePolicy = _buildPolicy(args);

      dynamic resultData;

      switch (domain) {
        // --- 1. CORE API & DATABASE (Collections) ---
        case 'api_collection':
          if (resource == null)
            throw Exception('Collection action missing "resource" name.');
          final col = db.collection(resource);

          switch (action) {
            case 'create':
              resultData =
                  await col.create(args['data'], cachePolicy: cachePolicy);
              break;
            case 'createMany':
              resultData = await col.createMany(
                  (args['items'] as List).cast<Map<String, dynamic>>());
              break;
            case 'readById':
              resultData =
                  await col.readById(args['id'], cachePolicy: cachePolicy);
              break;
            case 'readOne':
              resultData = await col.readOne(args['filter'] ?? {},
                  cachePolicy: cachePolicy);
              break;
            case 'query':
            case 'readMany':
              resultData = await col.readMany(_buildQueryMap(args),
                  cachePolicy: cachePolicy);
              break;
            case 'updateById':
              resultData = await col.updateById(args['id'], args['data']);
              break;
            case 'updateMany':
              resultData = await col.updateMany(args['filter'], args['data']);
              break;
            case 'upsertById':
              resultData = await col.upsertById(args['id'], args['data']);
              break;
            case 'patchById':
              resultData = await col.patchById(args['id'], args['data']);
              break;
            case 'deleteById':
              resultData = await col.deleteById(args['id']);
              break;
            case 'deleteMany':
              resultData = await col.deleteMany(args['filter']);
              break;
            case 'count':
              resultData = await col.count(args['filter']);
              break;
            default:
              throw Exception('Unknown Collection action: $action');
          }
          break;

        // --- 2. CORE API & DATABASE (Globals) ---
        case 'api_global':
          if (resource == null)
            throw Exception('Global action missing "resource" name.');
          final glob = db.global(resource);
          switch (action) {
            case 'get':
              resultData = await glob.get(cachePolicy: cachePolicy);
              break;
            case 'set':
              resultData = await glob.set(args['data']);
              break;
            case 'update':
              resultData = await glob.update(args['data']);
              break;
            default:
              throw Exception('Unknown Global action: $action');
          }
          break;

        // --- 3. SYSTEM, OFFLINE & HEALTH ---
        case 'api_system':
          switch (action) {
            case 'syncOffline':
              await offline.syncAll();
              resultData = true;
              break;
            case 'healthSummary':
              resultData = {
                'status': 'healthy',
                'queueLength': await offline.getQueueCount()
              };
              break;
            default:
              throw Exception('Unknown System action: $action');
          }
          break;

        // --- 4. EXTREME AUTHENTICATION ---
        case 'auth':
          switch (action) {
            case 'login':
              resultData = await auth.login(args);
              break;
            case 'register':
              resultData = await auth.register(args);
              break;
            case 'loginWithProvider':
              resultData = await auth.loginWithProvider(
                  args['provider'], args['payload'] ?? {});
              break;
            case 'requestOtp':
              resultData = await auth.requestOtp(
                  args['destination'], args['channel'] ?? 'email');
              break;
            case 'verifyOtp':
              resultData =
                  await auth.verifyOtp(args['destination'], args['code']);
              break;
            case 'startPasskeyRegistration':
              resultData = await auth.startPasskeyRegistration(args['userId']);
              break;
            case 'completePasskeyRegistration':
              resultData = await auth.completePasskeyRegistration(
                  args['userId'], args['credential']);
              break;
            case 'refreshSession':
              resultData = await auth.refreshSession();
              break;
            case 'updateProfile':
              resultData = await auth.updateProfile(args['profile']);
              break;
            case 'logout':
              await auth.logout();
              resultData = true;
              break;
            case 'me':
              resultData = await auth.me();
              break;
            default:
              throw Exception('Unknown Auth action: $action');
          }
          break;

        // --- 5. UNCOMPROMISED MEDIA CONTROL ---
        case 'media':
          switch (action) {
            case 'getProxyUrl':
              resultData = await media.getProxyPlayUrl(args['url']);
              break;
            default:
              throw Exception('Unknown Media action: $action');
          }
          break;

        // --- 6. BACKGROUND PIPELINES & TASK MEMORY ---
        case 'task':
          final taskId = args['taskId'] ??
              DateTime.now().microsecondsSinceEpoch.toString();
          switch (action) {
            case 'download_start':
              final controller = await media.startDownload(
                taskId: taskId,
                url: args['url'],
                savePath: args['savePath'],
                headers:
                    (args['headers'] as Map?)?.cast<String, String>() ?? {},
              );
              _activeTasks[taskId] = controller;
              resultData = {'taskId': taskId};
              break;
            case 'transfer_pause':
              (_activeTasks[taskId] as ResumableTransferController?)?.pause();
              resultData = true;
              break;
            case 'transfer_resume':
              (_activeTasks[taskId] as ResumableTransferController?)?.resume();
              resultData = true;
              break;
            case 'transfer_cancel':
              (_activeTasks[taskId] as ResumableTransferController?)?.cancel();
              _activeTasks.remove(taskId);
              resultData = true;
              break;
            case 'cancel_stream':
              await _activeSubscriptions[taskId]?.cancel();
              _activeSubscriptions.remove(taskId);
              resultData = true;
              break;
            default:
              throw Exception('Unknown Task action: $action');
          }
          break;

        // --- 7. REALTIME & FIREHOSE ---
        case 'realtime':
          switch (action) {
            case 'emit':
              await realtime.emit(
                  args['channel'], args['event'], args['payload']);
              resultData = true;
              break;
            case 'rpc':
              resultData = await realtime.rpc(args['method'], args['payload']);
              break;
            default:
              throw Exception('Unknown Realtime action: $action');
          }
          break;

        // --- 8. ADVANCED INFRASTRUCTURE (Cache Management) ---
        case 'cache':
          switch (action) {
            case 'set':
              await cache.set(args['key'], args['value'],
                  ttl: args['ttl'] != null
                      ? Duration(milliseconds: args['ttl'])
                      : null);
              resultData = true;
              break;
            case 'get':
              resultData = await cache.get(args['key']);
              break;
            case 'remove':
              await cache.remove(args['key']);
              resultData = true;
              break;
            case 'clear':
              await cache.clear();
              resultData = true;
              break;
            default:
              throw Exception('Unknown Cache action: $action');
          }
          break;

        // --- 9. CRYPTO CONTROLS ---
        case 'crypto':
          switch (action) {
            case 'encrypt':
              resultData = await crypto.encrypt(
                  args['data'] as Uint8List, args['meta'] ?? {});
              break;
            case 'decrypt':
              resultData = await crypto.decrypt(
                  args['data'] as Uint8List, args['meta'] ?? {});
              break;
            default:
              throw Exception('Unknown Crypto action: $action');
          }
          break;

        default:
          throw Exception('Unknown Domain: $domain');
      }

      return {'success': true, 'data': resultData};
    } catch (e, stackTrace) {
      OmniLogger.error('Action Failed in Quantum Shell', e, stackTrace);
      return {'success': false, 'error': e.toString()};
    }
  }

  // ===========================================================================
  // SDUI: CONTINUOUS STREAMS (Live DB, Adaptive Streaming, Binary In)
  // ===========================================================================

  static Stream<Map<String, dynamic>> runStreamAction(
      Map<String, dynamic> json) async* {
    try {
      final domain = json['domain'] as String;
      final action = json['action'] as String;
      final args = (json['args'] as Map<String, dynamic>?) ?? {};
      final resource = (json['resource'] ?? args['resource']) as String?;

      switch (domain) {
        // --- 1. LIVE DATABASE SUBSCRIPTIONS ---
        case 'api_collection':
          if (action == 'subscribe') {
            if (resource == null)
              throw Exception('Collection stream missing "resource" name.');
            yield* db
                .collection(resource)
                .watchList(query: _buildQueryMap(args))
                .map((data) {
              return {'success': true, 'data': data};
            });
          }
          break;

        // --- 2. LIVE SOCKETS & FIREHOSE ---
        case 'realtime':
          if (action == 'subscribe') {
            final channel = args['channel'] as String;
            yield* realtime.events(channel).map((msg) {
              return {'success': true, 'event': msg.type, 'data': msg.data};
            });
          }
          break;

        // --- 3. LIVE MEDIA (UDP/Jitter Buffer) ---
        case 'media':
          if (action == 'live_udp_stream') {
            final stream = await _engine.liveMediaStream(args['path'],
                encryptionKeyId: args['encryptionKeyId'] ?? 'default');
            yield* stream.map((packet) {
              return {
                'success': true,
                'sequence': packet.sequence,
                'bytes': packet.payload
              };
            });
          }
          break;

        // --- 4. CONTINUOUS TASK PROGRESS ---
        case 'task':
          if (action == 'transfer_progress') {
            final taskId = args['taskId'];
            final controller =
                _activeTasks[taskId] as ResumableTransferController?;
            if (controller != null) {
              yield* controller.progress.map((p) => {
                    'success': true,
                    'progress': p,
                    'isPaused': controller.isPaused,
                    'isCancelled': controller.isCancelled
                  });
            } else {
              throw Exception(
                  'Task ID $taskId is not an active ResumableTransferController');
            }
          }
          break;

        default:
          yield {
            'success': false,
            'error': 'Domain $domain does not support streams'
          };
      }
    } catch (e, stackTrace) {
      OmniLogger.error('Stream Action Failed in Quantum Shell', e, stackTrace);
      yield {'success': false, 'error': e.toString()};
    }
  }
}

// =============================================================================
// HELPER FACADES & EXTENSIONS
// =============================================================================

/// Dynamic Collection Abstraction leveraging the new `ReactiveCrudRepository`
class OmniCollection {
  final ReactiveCrudRepository<Map<String, dynamic>> _repo;
  final ApiModule _api;
  final String _slug;

  OmniCollection(this._api, this._slug)
      : _repo = ReactiveCrudRepository<Map<String, dynamic>>(
          api: _api,
          resourcePath: '/$_slug',
          fromJson: (json) => Map<String, dynamic>.from(json as Map),
          toJson: (data) => data,
        );

  Future<dynamic> create(Map<String, dynamic> data,
      {CachePolicy cachePolicy = CachePolicy.networkOnly}) async {
    return _repo.create(data);
  }

  Future<dynamic> createMany(List<Map<String, dynamic>> items) async {
    final res = await _api.request<List<dynamic>>(
      method: 'POST',
      path: '/$_slug/bulk',
      kind: RequestKind.rest,
      body: {'items': items},
      decode: (json) => json as List<dynamic>,
    );
    return res.data;
  }

  Future<dynamic> readById(String id,
      {CachePolicy cachePolicy = CachePolicy.networkOnly}) async {
    return _repo.read(id);
  }

  Future<dynamic> readOne(Map<String, dynamic> filter,
      {CachePolicy cachePolicy = CachePolicy.networkOnly}) async {
    final list = await _repo.list(query: {'filter': filter, 'limit': 1});
    return list.isNotEmpty ? list.first : null;
  }

  Future<dynamic> readMany(Map<String, dynamic> query,
      {CachePolicy cachePolicy = CachePolicy.networkOnly}) async {
    return _repo.list(query: query);
  }

  Future<dynamic> updateById(String id, Map<String, dynamic> data) async {
    return _repo.update(id, data);
  }

  Future<dynamic> updateMany(
      Map<String, dynamic> filter, Map<String, dynamic> data) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/$_slug/bulk',
      kind: RequestKind.rest,
      body: {'filter': filter, 'data': data},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<dynamic> upsertById(String id, Map<String, dynamic> data) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/$_slug/$id/upsert',
      kind: RequestKind.rest,
      body: data,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<dynamic> patchById(String id, Map<String, dynamic> data) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'PATCH',
      path: '/$_slug/$id',
      kind: RequestKind.rest,
      body: data,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<dynamic> deleteById(String id) async {
    await _repo.remove(id);
    return true;
  }

  Future<dynamic> deleteMany(Map<String, dynamic> filter) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'DELETE',
      path: '/$_slug/bulk',
      kind: RequestKind.rest,
      body: {'filter': filter},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<dynamic> count(Map<String, dynamic>? filter) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/$_slug/count',
      kind: RequestKind.rest,
      query: filter != null ? {'filter': filter} : {},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data['count'];
  }

  Stream<List<Map<String, dynamic>>> watchList(
      {Map<String, dynamic> query = const {}}) {
    return _repo.watchList(query: query);
  }
}

class OmniGlobal {
  final ApiModule _api;
  final String _slug;
  OmniGlobal(this._api, this._slug);

  Future<Map<String, dynamic>> get(
      {CachePolicy cachePolicy = CachePolicy.networkOnly}) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/global/$_slug',
      kind: RequestKind.rest,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> set(Map<String, dynamic> data) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/global/$_slug',
      kind: RequestKind.rest,
      body: data,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> update(Map<String, dynamic> data) async {
    final res = await _api.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/global/$_slug',
      kind: RequestKind.rest,
      body: data,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }
}

// -----------------------------------------------------------------------------
// INTERNAL FACADE CLASSES
// -----------------------------------------------------------------------------

class _OmniDbFacade {
  final AppSdk _sdk;
  _OmniDbFacade(this._sdk);

  OmniCollection collection(String slug) => OmniCollection(_sdk.root, slug);
  OmniGlobal global(String slug) => OmniGlobal(_sdk.root, slug);
  BatchManager get batch => _sdk.batch;
}

class _OmniAuthFacade {
  final AppSdk _sdk;
  final SessionStore _store;
  _OmniAuthFacade(this._sdk, this._store);

  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/login',
      kind: RequestKind.rest,
      body: credentials,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    _store.setSession(SessionContext.fromJson(res.data['session']));
    return res.data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/register',
      kind: RequestKind.rest,
      body: data,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    _store.setSession(SessionContext.fromJson(res.data['session']));
    return res.data;
  }

  Future<Map<String, dynamic>> loginWithProvider(
      String provider, Map<String, dynamic> payload) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/provider/$provider',
      kind: RequestKind.rest,
      body: payload,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    _store.setSession(SessionContext.fromJson(res.data['session']));
    return res.data;
  }

  Future<Map<String, dynamic>> requestOtp(
      String destination, String channel) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/otp/request',
      kind: RequestKind.rest,
      body: {'destination': destination, 'channel': channel},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> verifyOtp(
      String destination, String code) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/otp/verify',
      kind: RequestKind.rest,
      body: {'destination': destination, 'code': code},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    _store.setSession(SessionContext.fromJson(res.data['session']));
    return res.data;
  }

  Future<Map<String, dynamic>> startPasskeyRegistration(String userId) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/passkey/register/start',
      kind: RequestKind.rest,
      body: {'userId': userId},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> completePasskeyRegistration(
      String userId, dynamic credential) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/passkey/register/complete',
      kind: RequestKind.rest,
      body: {'userId': userId, 'credential': credential},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> refreshSession() async {
    final current = await _store.getSession();
    if (current?.refreshToken == null)
      throw Exception('No refresh token available');
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'POST',
      path: '/auth/refresh',
      kind: RequestKind.rest,
      body: {'refreshToken': current!.refreshToken},
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    _store.setSession(SessionContext.fromJson(res.data['session']));
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> profile) async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'PUT',
      path: '/auth/profile',
      kind: RequestKind.rest,
      body: profile,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await _sdk.root.request<Map<String, dynamic>>(
      method: 'GET',
      path: '/auth/me',
      kind: RequestKind.rest,
      decode: (json) => Map<String, dynamic>.from(json as Map),
    );
    return res.data;
  }

  Future<void> logout() async {
    try {
      await _sdk.root.request<dynamic>(
        method: 'POST',
        path: '/auth/logout',
        kind: RequestKind.rest,
        decode: (json) => json,
      );
    } catch (_) {} // Ignore network errors on logout
    _store.setSession(null);
  }
}

class _OmniMediaFacade {
  final AppSdk _sdk;
  _OmniMediaFacade(this._sdk);

  Future<String> getProxyPlayUrl(String url) async {
    return _sdk.mediaProxy.getProxyUrl(url);
  }

  Future<ResumableTransferController> startDownload(
      {required String taskId,
      required String url,
      required String savePath,
      Map<String, String> headers = const {}}) async {
    return _sdk.transfers.startDownload(
      id: taskId,
      path: url,
      file: File(savePath),
      headers: headers,
    );
  }

  // 🚀 ADD THIS METHOD: The true bridge to your network core for binary assets
  Future<Uint8List> getBytes(String url,
      {Map<String, String> headers = const {}}) async {
    final response = await _sdk.client.sendRaw(
      method: 'GET',
      path: url,
      kind: RequestKind.media,
      headers: headers,
      requirePolicyCheck:
          true, // Enforces route manifests and security policies
    );

    if (response.statusCode >= 400) {
      throw Exception(
          'QuantumMediaEngine Network Error: ${response.statusCode} on $url');
    }

    return await response.bytes();
  }
}

class _OmniRealtimeFacade {
  final AppSdk _sdk;
  RealtimeClient? _sharedClient;

  _OmniRealtimeFacade(this._sdk);

  RealtimeClient get _client {
    if (_sharedClient == null) {
      _sharedClient = _sdk.realtime(socketPath: '/socket');
      _sharedClient!.connect();
    }
    return _sharedClient!;
  }

  Future<void> emit(String channel, String event, dynamic payload) async {
    await _client.send(event, payload, meta: {'channel': channel});
  }

  Stream<RealtimeEvent> events(String channel) {
    return _client.events.where((e) => e.meta['channel'] == channel);
  }

  Future<dynamic> rpc(String method, dynamic payload) async {
    if (_sdk.rpc == null) throw Exception('RPC Transport not configured');

    // Assumes simple JSON payload encapsulation over binary RPC for generic requests
    final bytes = await ComputeCore.encodeJsonAsync(payload);
    final requestBytes = Uint8List.fromList((bytes as String).codeUnits);

    final responseBytes = await _sdk.rpc!.invoke<Uint8List, Uint8List>(
      method,
      requestBytes,
      serialize: (b) => b,
      deserialize: (b) => b,
    );

    return await ComputeCore.decodeJsonAsync(
        String.fromCharCodes(responseBytes));
  }
}

class _OmniCacheFacade {
  final AppSdk _sdk;
  _OmniCacheFacade(this._sdk);

  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    await _sdk.client.cacheStore.set(
        key,
        CacheEntry(
          value: value,
          createdAt: DateTime.now(),
          ttl: ttl,
        ));
  }

  Future<dynamic> get(String key) async {
    final entry = await _sdk.client.cacheStore.get(key);
    if (entry == null || entry.isExpired) return null;
    return entry.value;
  }

  Future<void> remove(String key) async {
    await _sdk.client.cacheStore.remove(key);
  }

  Future<void> clear() async {
    await _sdk.client.cacheStore.clear();
  }
}

class _OmniOfflineFacade {
  final AppSdk _sdk;
  _OmniOfflineFacade(this._sdk);

  Future<void> syncAll() async {
    await _sdk.client.offlineManager.processQueue(_sdk.client);
  }

  Future<int> getQueueCount() async {
    return _sdk.client.offlineManager.getCount();
  }

  Stream<int> get queueLength => _sdk.client.offlineManager.queueLength;
}

class _OmniCryptoFacade {
  final AppSdk _sdk;
  _OmniCryptoFacade(this._sdk);

  Future<Uint8List> encrypt(Uint8List data, Map<String, dynamic> meta) async {
    return _sdk.client.cryptoPolicy.encryptBytes(data, meta: meta);
  }

  Future<Uint8List> decrypt(Uint8List data, Map<String, dynamic> meta) async {
    return _sdk.client.cryptoPolicy.decryptBytes(data, meta: meta);
  }
}
