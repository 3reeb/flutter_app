// =============================================================================
// quantum.dart
// =============================================================================

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
// Import your existing engine files
import 'quantum_api_engine.dart';
import 'quantum_auth_engine.dart';
import 'quantum_media_api.dart';
import 'quantum_socket_engine.dart';
import 'adapters/quantum_mock_adapters.dart';
import 'adapters/quantum_firebase_adapters.dart';
import '../runtime/quantum_permissions.dart';
enum QuantumDriverMode { mock, http, firebase }

/// Unified Configuration
/// Unified Configuration
class QuantumConfig {
  final String apiUrl;
  final String socketUrl;
  final String cacheDirectoryPath;
  final String environment;
  final String? clientSecret;
  final bool enableTelemetry;
  final bool enableOfflineQueueing;
  @Deprecated('Use driverMode instead')
  final bool useMockDrivers;
  final QuantumDriverMode driverMode;

  // Advanced Network Simulation Parameters
  final Duration mockMinLatency;
  final Duration mockMaxLatency;
  final double mockFailureProbability;

  const QuantumConfig({
    required this.apiUrl,
    required this.socketUrl,
    required this.cacheDirectoryPath,
    this.environment = 'production',
    this.clientSecret,
    this.enableTelemetry = true,
    this.enableOfflineQueueing = true,
    this.useMockDrivers = false,
    this.driverMode = QuantumDriverMode.http,
    this.mockMinLatency = const Duration(milliseconds: 1),
    this.mockMaxLatency = const Duration(milliseconds: 5),
    this.mockFailureProbability = 0.0,
  });
}

/// The Ultimate Single Entrypoint Facade
class Quantum {
  static VaultStreamClient? _client;
  static bool get isInitialized => _client != null && _client!.isInitialized;

  // High-performance memory-maps for continuous streams & background pipelines
  static final Map<String, dynamic> _activeTasks = {};
  static final Map<String, StreamSubscription> _activeSubscriptions = {};

  Quantum._();

  static const SessionContext _guestSession = SessionContext(
    claims: <String, dynamic>{'roles': <String>['guest']},
  );

  static SessionContext _sessionFromArgs(Map<String, dynamic> args) {
    final dynamic raw = args['session'] ?? args['auth'] ?? args['context'];
    if (raw is SessionContext) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return SessionContext(
        userId: map['userId']?.toString(),
        sessionId: map['sessionId']?.toString(),
        accessToken: map['accessToken']?.toString(),
        refreshToken: map['refreshToken']?.toString(),
        expiresAt: map['expiresAt'] is DateTime
            ? map['expiresAt'] as DateTime
            : DateTime.tryParse(map['expiresAt']?.toString() ?? ''),
        claims: map['claims'] is Map
            ? Map<String, dynamic>.from(map['claims'] as Map)
            : <String, dynamic>{},
        authProviderUsed: map['authProviderUsed']?.toString() ?? 'none',
        deviceId: map['deviceId']?.toString(),
      );
    }
    return _guestSession;
  }

  static dynamic _permissionRuleFromPayload(
    Map<String, dynamic> json,
    Map<String, dynamic> args,
  ) {
    return json['permission'] ??
        json['permissions'] ??
        json['guard'] ??
        json['policy'] ??
        args['permission'] ??
        args['permissions'] ??
        args['guard'] ??
        args['policy'];
  }

  static void _enforcePermissionIfNeeded(
    Map<String, dynamic> json,
    Map<String, dynamic> args, {
    required String domain,
    required String action,
    String? resource,
  }) {
    final dynamic rule = _permissionRuleFromPayload(json, args);
    if (rule == null) return;
    final SessionContext session = _sessionFromArgs(args);
    QuantumPermissionEngine.instance.require(
      rule,
      QuantumPermissionContext.fromSession(
        session,
        env: <String, dynamic>{
          'domain': domain,
          'action': action,
          'resource': resource,
          'args': args,
        },
        data: args,
        scope: domain,
        resource: resource,
        operation: action,
      ),
      code: 'permission_denied',
    );
  }

  static Future<void> initialize(QuantumConfig config) async {
    if (isInitialized) return;

    final clientConfig = VaultStreamClientConfig(
      baseUrl: config.apiUrl,
      cacheDirectoryPath: config.cacheDirectoryPath,
      environment: config.environment,
      telemetryEnabled: config.enableTelemetry,
      securityPolicy: SecurityPolicy(clientSecret: config.clientSecret),
      authPolicy: AuthPolicy(clientSecret: config.clientSecret),
      offlinePolicy: OfflinePolicy(
        mode: config.enableOfflineQueueing
            ? OfflineMode.writeQueue
            : OfflineMode.readThrough,
        queueWritesWhenOffline: config.enableOfflineQueueing,
      ),
      socketConfig: QuantumSocketConfig(
        url: config.socketUrl,
        autoReconnect: true,
        clientSecret: config.clientSecret,
      ),
    );

    _client = VaultStreamClient(config: clientConfig);

    // Determine the effective driver mode (backward compatible with useMockDrivers)
    QuantumDriverMode effectiveMode = config.driverMode;
    if (config.useMockDrivers && effectiveMode == QuantumDriverMode.http) {
      effectiveMode = QuantumDriverMode
          .mock; // Fallback for deprecated boolean if default mode was used
    }
    if (config.useMockDrivers) {
      effectiveMode = QuantumDriverMode.mock;
    }
    if (effectiveMode == QuantumDriverMode.http &&
        config.apiUrl.trim().isEmpty) {
      throw ArgumentError(
          'QuantumConfig.apiUrl is required when driverMode is http.');
    }

    // --- Wire up Drivers based on selected mode ---
    switch (effectiveMode) {
      case QuantumDriverMode.mock:
        final mockNetwork = MockNetworkConfig(
          minLatency: config.mockMinLatency,
          maxLatency: config.mockMaxLatency,
          failureProbability: config.mockFailureProbability,
        );
        _client!.registerAuthDriver(MockAuthDriver(networkConfig: mockNetwork));
        _client!.registerDriver(MockApiDriver(networkConfig: mockNetwork));
        break;

      case QuantumDriverMode.firebase:
        // Firebase Production Mode
        _client!.registerAuthDriver(FirebaseAuthDriver());
        _client!.registerDriver(FirebaseApiDriver());
        // Note: Socket and Media drivers should also be registered if their core engine supports it natively via the same registry,
        // but typically socket is configured separately or injected.
        break;

      case QuantumDriverMode.http:
      default:
        // HTTP Production mode: use real HTTP internet driver
        _client!.registerDriver(VaultHttpDriver(
            baseUrl: config.apiUrl,
            timeout: config.environment == 'test'
                ? const Duration(milliseconds: 500)
                : const Duration(seconds: 15)));
        break;
    }

    await _client!.init();
  }

  static VaultStreamClient get _engine {
    if (!isInitialized) throw Exception('Quantum Engine offline.');
    return _client!;
  }

  // ===========================================================================
  // ERGONOMIC NAMESPACES (Direct zero-overhead pointers)
  // ===========================================================================
  static _QuantumDbFacade get db => _QuantumDbFacade(_engine);
  static VaultAuth get auth => _engine.auth();
  static QuantumMediaEngine get media => _engine.media;
  static QuantumSocketEngine get realtime => _engine.socket!;
  static VaultCache get cache => _engine.cache();
  static VaultOffline get offline => _engine.offline();
  static VaultCrypto get crypto => _engine.crypto();

  // ===========================================================================
  // SDUI JSON PARSER: THE 'QUERY' BODY BUILDER
  // ===========================================================================

  /// Translates complex JSON payloads into the powerful VaultQuery object.
  /// Supports modern body-based querying architectures.
  static VaultQuery _buildQuery(Map<String, dynamic> args) {
    final q = VaultQuery();
    if (args['filter'] != null) q.rawFilter(args['filter']);
    if (args['where'] != null) {
      (args['where'] as Map<String, dynamic>).forEach((k, v) => q.where(k, v));
    }
    if (args['and'] != null)
      q.and((args['and'] as List).cast<Map<String, dynamic>>());
    if (args['or'] != null)
      q.or((args['or'] as List).cast<Map<String, dynamic>>());
    if (args['not'] != null) q.not(args['not']);
    if (args['sortBy'] != null)
      q.sortBy(args['sortBy']['field'],
          descending: args['sortBy']['descending'] ?? false);
    if (args['limit'] != null) q.limit(args['limit']);
    if (args['offset'] != null) q.offset(args['offset']);
    if (args['page'] != null) q.page(args['page']);
    if (args['select'] != null)
      q.select((args['select'] as List).cast<String>());
    if (args['populate'] != null)
      q.populate((args['populate'] as List).cast<String>());
    if (args['depth'] != null) q.depth(args['depth']);
    if (args['search'] != null) q.search(args['search']);
    if (args['distinct'] != null) q.distinct(args['distinct']);
    if (args['groupBy'] != null) q.groupBy(args['groupBy']);
    if (args['aggregate'] != null) q.aggregate(args['aggregate']);
    return q;
  }

  static QueryPolicy? _buildPolicy(Map<String, dynamic>? args) {
    if (args == null || args['policy'] == null) return null;
    final p = args['policy'];
    return QueryPolicy(
      forceRefresh: p['forceRefresh'] ?? false,
      instant: p['instant'] ?? false,
      targetDriver: p['targetDriver'],
    );
  }

  // ===========================================================================
  // SDUI: ONE-TIME EXECUTIONS (Full Engine Capabilities Exposed)
  // ===========================================================================

  // ===========================================================================
  // SDUI: ONE-TIME EXECUTIONS (Exposing Full Unsimplified Engine Capabilities)
  // ===========================================================================

  static Future<Map<String, dynamic>> runAction(
      Map<String, dynamic> json) async {
    try {
      final domain = json['domain'] as String;
      final action = json['action'] as String;
      final args = (json['args'] as Map<String, dynamic>?) ?? {};

      // FIX: Robustly resolve the resource name from either top-level or args
      final resource = (json['resource'] ?? args['resource']) as String?;
      final policy = _buildPolicy(args);
      _enforcePermissionIfNeeded(json, args, domain: domain, action: action, resource: resource);

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
                  (await col.create(args['data'], policy: policy)).data;
              break;
            case 'createMany':
              resultData = (await col.createMany(
                      (args['items'] as List).cast<Map<String, dynamic>>(),
                      policy: policy))
                  .data;
              break;
            case 'readById':
              resultData = (await col.readById(args['id'],
                      select: args['select']?.cast<String>(), policy: policy))
                  .data;
              break;
            case 'readOne':
              resultData = (await col.readOne(args['filter'] ?? {},
                      select: args['select']?.cast<String>(), policy: policy))
                  .data;
              break;
            case 'query':
            case 'readMany':
              resultData =
                  (await col.readMany(_buildQuery(args), policy: policy)).data;
              break;
            case 'updateById':
              resultData = (await col.updateById(args['id'], args['data'],
                      policy: policy))
                  .data;
              break;
            case 'updateMany':
              resultData = (await col.updateMany(args['filter'], args['data'],
                      policy: policy))
                  .data;
              break;
            case 'upsertById':
              resultData = (await col.upsertById(args['id'], args['data'],
                      policy: policy))
                  .data;
              break;
            case 'patchById':
              resultData = (await col.patchById(args['id'], args['data'],
                      policy: policy))
                  .data;
              break;
            case 'deleteById':
              resultData =
                  (await col.deleteById(args['id'], policy: policy)).data;
              break;
            case 'deleteMany':
              resultData =
                  (await col.deleteMany(args['filter'], policy: policy)).data;
              break;
            case 'count':
              resultData =
                  (await col.count(args['filter'], policy: policy)).data;
              break;
            case 'exists':
              resultData =
                  (await col.exists(args['filter'], policy: policy)).data;
              break;
            case 'schema':
              resultData = (await col.schema(
                      forceRefresh: args['forceRefresh'] ?? false))
                  ?.definition;
              break;
            case 'permissions':
              resultData = (await col.permissions(
                      forceRefresh: args['forceRefresh'] ?? false))
                  .permissions;
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
              resultData = (await glob.get(policy: policy)).data;
              break;
            case 'set':
              resultData = (await glob.set(args['data'], policy: policy)).data;
              break;
            case 'update':
              resultData =
                  (await glob.update(args['data'], policy: policy)).data;
              break;
            case 'upsert':
              resultData =
                  (await glob.upsert(args['data'], policy: policy)).data;
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
              resultData = await _engine.health().summary();
              break;
            case 'telemetry':
              resultData = _engine.telemetry().snapshot();
              break;
            default:
              throw Exception('Unknown System action: $action');
          }
          break;

        // --- 4. EXTREME AUTHENTICATION ---
        case 'auth':
          switch (action) {
            case 'login':
              resultData = (await auth.login(args, policy: policy)).data;
              break;
            case 'register':
              resultData = (await auth.register(args, policy: policy)).data;
              break;
            case 'loginWithProvider':
              final provider = AuthProvider.values
                  .firstWhere((e) => e.name == args['provider']);
              resultData = (await auth.loginWithProvider(
                      provider, args['payload'] ?? {}))
                  .data;
              break;
            case 'requestOtp':
              final channel = OtpChannel.values
                  .firstWhere((e) => e.name == (args['channel'] ?? 'email'));
              resultData = (await auth.requestOtp(
                      destination: args['destination'],
                      purpose: args['purpose'] ?? 'login',
                      channel: channel))
                  .data;
              break;
            case 'verifyOtp':
              resultData = (await auth.verifyOtp(
                      destination: args['destination'],
                      code: args['code'],
                      purpose: args['purpose'] ?? 'login'))
                  .data;
              break;
            case 'startPasskeyRegistration':
              resultData =
                  (await auth.startPasskeyRegistration(userId: args['userId']))
                      .data;
              break;
            case 'completePasskeyRegistration':
              resultData = (await auth.completePasskeyRegistration(
                      userId: args['userId'], credential: args['credential']))
                  .data;
              break;
            case 'startPasskeyAuthentication':
              resultData = (await auth.startPasskeyAuthentication(
                      userId: args['userId']))
                  .data;
              break;
            case 'completePasskeyAuthentication':
              resultData = (await auth.completePasskeyAuthentication(
                      userId: args['userId'], credential: args['credential']))
                  .data;
              break;
            case 'linkProvider':
              final p = AuthProvider.values
                  .firstWhere((e) => e.name == args['provider']);
              resultData =
                  (await auth.linkProvider(p, args['payload'] ?? {})).data;
              break;
            case 'confirmOperation':
              resultData = (await auth.confirmOperation(
                      operation: args['operation'], payload: args['payload']))
                  .data;
              break;
            case 'refreshSession':
              resultData = (await auth.refreshSession()).data;
              break;
            case 'updateProfile':
              resultData = (await auth.updateProfile(args['profile'])).data;
              break;
            case 'logout':
              await auth.logout();
              resultData = true;
              break;
            case 'me':
              resultData = (await auth.me()).data;
              break;
            default:
              throw Exception('Unknown Auth action: $action');
          }
          break;

        // --- 5. UNCOMPROMISED MEDIA CONTROL ---
        case 'media':
          switch (action) {
            case 'getProxyUrl':
              resultData = media.getProxyPlayUrl(args['url']);
              break;
            case 'prefetch':
              media.prefetchMedia((args['urls'] as List).cast<String>());
              resultData = true;
              break;
            case 'getMediaBytes':
              resultData = await media.getMediaBytes(args['url']);
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
            case 'upload_start':
              final method = HttpMethod.values
                  .firstWhere((e) => e.name == (args['method'] ?? 'patch'));
              final uploader = media.createUploader(
                  file: File(args['filePath']),
                  uploadUrl: args['uploadUrl'],
                  method: method,
                  headers: (args['headers'] as Map?)?.cast<String, String>() ??
                      const {});
              _activeTasks[taskId] = uploader;
              uploader.start(startOffset: args['startOffset'] ?? 0);
              resultData = {'taskId': taskId};
              break;
            case 'upload_pause':
              (_activeTasks[taskId] as ResumableUploader?)?.pause();
              resultData = true;
              break;
            case 'upload_resume':
              (_activeTasks[taskId] as ResumableUploader?)?.start();
              resultData = true;
              break;
            case 'upload_abort':
              (_activeTasks[taskId] as ResumableUploader?)?.abort();
              _activeTasks.remove(taskId);
              resultData = true;
              break;
            case 'live_pipeline_start':
              final pipeline = media.createLivePipeline();
              pipeline.initialize(
                transmitter: (packetBytes) async =>
                    realtime.sendBinary(packetBytes),
                sourceReceiver: realtime.onRawBinary,
              );
              _activeTasks[taskId] = pipeline;
              resultData = {'taskId': taskId};
              break;
            case 'live_pipeline_feed_mic':
              (_activeTasks[taskId] as LiveMediaPipeline?)
                  ?.ingressInput
                  .add(args['bytes'] as Uint8List);
              resultData = true;
              break;
            case 'live_pipeline_stop':
              (_activeTasks[taskId] as LiveMediaPipeline?)?.terminate();
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
              resultData = (await realtime.request(
                      args['channel'], args['event'], args['payload']))
                  .payload;
              break;
            case 'binary_out':
              await realtime.sendBinary(args['bytes'] as Uint8List);
              resultData = true;
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
                  pinned: args['pinned'] ?? false);
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
              await cache.clear(tag: args['tag']);
              resultData = true;
              break;
            case 'stats':
              final s = await cache.stats();
              resultData = {
                'hits': s.hits,
                'misses': s.misses,
                'bytes': s.bytesEstimate,
                'size': s.size
              };
              break;
            default:
              throw Exception('Unknown Cache action: $action');
          }
          break;

        // --- 9. CRYPTO CONTROLS ---
        case 'crypto':
          switch (action) {
            case 'encrypt':
              resultData = await crypto.encrypt(args['data']);
              break;
            case 'decrypt':
              resultData = await crypto.decrypt(args['envelope']);
              break;
            case 'hash':
              resultData = await crypto.hash(args['data']);
              break;
            case 'sign':
              resultData = await crypto.sign(args['data']);
              break;
            case 'verify':
              resultData = await crypto.verify(args['data'], args['signature']);
              break;
            default:
              throw Exception('Unknown Crypto action: $action');
          }
          break;

        default:
          throw Exception('Unknown Domain: $domain');
      }

      return {'success': true, 'data': resultData};
    } catch (e) {
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

      // FIX: Robustly resolve the resource name from either top-level or args
      final resource = (json['resource'] ?? args['resource']) as String?;
      final policy = _buildPolicy(args);
      _enforcePermissionIfNeeded(json, args, domain: domain, action: action, resource: resource);

      switch (domain) {
        // --- 1. LIVE DATABASE SUBSCRIPTIONS ---
        case 'api_collection':
          if (action == 'subscribe') {
            if (resource == null)
              throw Exception('Collection stream missing "resource" name.');
            final queryParams = args['query'] != null
                ? (args['query'] as Map<String, dynamic>)
                : _buildQuery(args).toMap();
            yield* db
                .collection(resource)
                .subscribe(queryParams, policy: policy)
                .map((res) {
              return res.isSuccess
                  ? {'success': true, 'data': res.data}
                  : {'success': false, 'error': res.error.toString()};
            });
          }
          break;

        // --- 2. LIVE SOCKETS & FIREHOSE ---
        case 'realtime':
          if (action == 'subscribe') {
            yield* realtime.subscribe(args['channel']).map((msg) {
              return {'success': true, 'event': msg.event, 'data': msg.payload};
            });
          } else if (action == 'binary_in') {
            yield* realtime.onRawBinary.map((bytes) {
              return {'success': true, 'bytes': bytes};
            });
          } else if (action == 'firehose') {
            yield* realtime.onAnyMessage.map((msg) {
              return {
                'success': true,
                'channel': msg.channel,
                'event': msg.event,
                'data': msg.payload
              };
            });
          }
          break;

        // --- 3. ADAPTIVE MEDIA STREAMING ---
        case 'media':
          if (action == 'adaptive_stream') {
            final streamer = media
                .createAdaptiveStreamer(args['manifest'] as AdaptiveManifest);
            streamer.start();
            yield* streamer.stream.map((chunkBytes) {
              return {
                'success': true,
                'bytes': chunkBytes,
                'quality': streamer.currentQuality.name
              };
            });
          }
          break;

        // --- 4. CONTINUOUS TASK PROGRESS ---
        case 'task':
          if (action == 'upload_progress') {
            final taskId = args['taskId'];
            final uploader = _activeTasks[taskId] as ResumableUploader?;
            if (uploader != null) {
              yield* uploader.progress.map((p) => {
                    'success': true,
                    'progress': p.progress,
                    'speedBps': p.currentSpeedBps,
                    'remainingSeconds': p.estimatedTimeRemaining.inSeconds
                  });
            } else {
              throw Exception(
                  'Task ID $taskId is not an active ResumableUploader');
            }
          } else if (action == 'live_pipeline_speaker_out') {
            final taskId = args['taskId'];
            final pipeline = _activeTasks[taskId] as LiveMediaPipeline?;
            if (pipeline != null) {
              yield* pipeline.egressOutput
                  .map((frameBytes) => {'success': true, 'bytes': frameBytes});
            }
          }
          break;

        default:
          yield {
            'success': false,
            'error': 'Domain $domain does not support streams'
          };
      }
    } catch (e) {
      yield {'success': false, 'error': e.toString()};
    }
  }
}

// =============================================================================
// HELPER FACADES & EXTENSIONS
// =============================================================================
class _QuantumDbFacade {
  final VaultStreamClient _client;
  _QuantumDbFacade(this._client);
  VaultCollection collection(String slug) => _client.collection(slug);
  VaultGlobal global(String slug) => _client.global(slug);
  VaultBatch get batch => _client.batch();
}

extension VaultCollectionSubscriptionExt on VaultCollection {
  Stream<ApiResult<dynamic>> subscribe(Map<String, dynamic> query,
      {QueryPolicy? policy}) {
    return Quantum._engine
        .executeSubscribe(slug: slug, query: query, policy: policy);
  }
}
