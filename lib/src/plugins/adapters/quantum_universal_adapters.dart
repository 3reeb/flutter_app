// =============================================================================
// quantum_universal_adapters.dart
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
// Assuming these are imported from your previous files:
import '../quantum_api_engine.dart';
import '../quantum_auth_engine.dart';
import '../quantum_socket_engine.dart';
import '../internal/quantum_socket_stream_hub.dart';
import '../quantum_media_api.dart';
// =============================================================================
// SECTION 1: UNIVERSAL ADAPTER CONFIGURATION SCHEMAS
// =============================================================================

enum QuerySerializationFormat {
  /// Payload CMS style: where[field][equals]=value&limit=10
  bracketNotation,

  /// MongoDB/Loopback style: filter={"field": "value"}&limit=10
  jsonString,

  /// Standard key-value query parameters: field=value&limit=10
  flatKeyValue
}

enum MediaUploadStrategy {
  /// Standard multipart/form-data upload
  multipart,

  /// Upload binary directly in the HTTP body (AWS S3 Presigned / Google Cloud)
  binaryRawBody
}

/// Dynamic Configuration Schema to map the Engine to ANY Rest API (e.g. Payload CMS)
class UniversalApiConfig {
  final String baseUrl;
  final QuerySerializationFormat queryFormat;
  final Map<String, String> defaultHeaders;

  /// JSON path where the array of items lives (e.g., 'docs' for Payload CMS, 'data' for Strapi)
  final String listResponsePath;

  /// JSON path where the total count lives (e.g., 'totalDocs' for Payload CMS, 'meta.pagination.total' for Strapi)
  final String totalCountResponsePath;

  const UniversalApiConfig({
    required this.baseUrl,
    this.queryFormat = QuerySerializationFormat.bracketNotation,
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.listResponsePath = 'docs',
    this.totalCountResponsePath = 'totalDocs',
  });
}

/// Dynamic Configuration Schema to map the Auth Engine to ANY Authentication Flow
class UniversalAuthConfig {
  final String loginEndpoint; // e.g. "/api/users/login"
  final String registerEndpoint; // e.g. "/api/users"
  final String refreshEndpoint; // e.g. "/api/users/refresh"
  final String logoutEndpoint; // e.g. "/api/users/logout"
  final String meEndpoint; // e.g. "/api/users/me"

  /// JSON path to extract the token from the login response (e.g., 'token' for Payload CMS, 'jwt' for Strapi)
  final String tokenJsonPath;

  /// JSON path to extract the user profile object
  final String userJsonPath;

  const UniversalAuthConfig({
    required this.loginEndpoint,
    required this.registerEndpoint,
    required this.refreshEndpoint,
    required this.logoutEndpoint,
    required this.meEndpoint,
    this.tokenJsonPath = 'token',
    this.userJsonPath = 'user',
  });
}

/// Dynamic Configuration Schema to map standard sockets to custom WebSocket frames
class UniversalSocketConfig {
  final String wsUrl;
  final Map<String, dynamic> headers;

  /// Socket frame wrapped formatting function. Matches any standard CMS or custom pub-sub protocol.
  final String Function(SocketMessage message)? frameEncoder;

  /// Socket frame decoder.
  final SocketMessage Function(dynamic rawFrame)? frameDecoder;

  const UniversalSocketConfig({
    required this.wsUrl,
    this.headers = const {},
    this.frameEncoder,
    this.frameDecoder,
  });
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

// =============================================================================
// SECTION 2: UNIVERSAL REST API VAULT DRIVER
// =============================================================================

class UniversalApiDriver implements VaultDriver {
  @override
  final String driverId = 'universal_rest';

  final UniversalApiConfig config;
  final HttpClient _client;

  UniversalApiDriver(this.config) : _client = HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 15);
  }

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  void _injectHeaders(HttpClientRequest request, DriverContext context) {
    config.defaultHeaders.forEach((k, v) => request.headers.set(k, v));
    context.securityHeaders.forEach((k, v) => request.headers.set(k, v));

    if (context.session.accessToken != null) {
      request.headers.set(HttpHeaders.authorizationHeader,
          'JWT ${context.session.accessToken}');
    }
  }

  /// Converts standard Query models into custom serialization patterns (Payload bracket-notation, JSON, Flat key-val)
  String _serializeQuery(Map<String, dynamic> query) {
    if (query.isEmpty) return '';
    final params = <String>[];

    switch (config.queryFormat) {
      case QuerySerializationFormat.bracketNotation:
        // Converts {'where': {'title': {'equals': 'hello'}}} to where[title][equals]=hello
        void recurse(Map map, String prefix) {
          map.forEach((key, val) {
            final nextPrefix =
                prefix.isEmpty ? key.toString() : '$prefix[$key]';
            if (val is Map) {
              recurse(val, nextPrefix);
            } else if (val is List) {
              for (var i = 0; i < val.length; i++) {
                params.add(
                    '${Uri.encodeComponent('$nextPrefix[$i]')}=${Uri.encodeComponent(val[i].toString())}');
              }
            } else {
              params.add(
                  '${Uri.encodeComponent(nextPrefix)}=${Uri.encodeComponent(val.toString())}');
            }
          });
        }
        recurse(query, '');
        break;

      case QuerySerializationFormat.jsonString:
        // Strapi/Loopback JSON filter notation
        query.forEach((key, val) {
          if (val is Map || val is List) {
            params.add('$key=${Uri.encodeComponent(jsonEncode(val))}');
          } else {
            params.add('$key=${Uri.encodeComponent(val.toString())}');
          }
        });
        break;

      case QuerySerializationFormat.flatKeyValue:
        query.forEach((key, val) {
          params.add(
              '${Uri.encodeComponent(key)}=${Uri.encodeComponent(val.toString())}');
        });
        break;
    }

    return params.join('&');
  }

  dynamic _extractNestedProperty(dynamic json, String path) {
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  @override
  Future<ApiResult<dynamic>> read(String slug, Map<String, dynamic> query,
      {String? id, required DriverContext context}) async {
    try {
      final queryStr = _serializeQuery(query);
      final url = id != null
          ? '${config.baseUrl}/$slug/$id${queryStr.isNotEmpty ? '?$queryStr' : ''}'
          : '${config.baseUrl}/$slug${queryStr.isNotEmpty ? '?$queryStr' : ''}';

      final request = await _client.getUrl(Uri.parse(url));
      _injectHeaders(request, context);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (id != null) {
          return ApiResult.success(decoded, driverUsed: driverId);
        } else {
          // Normalize responses based on payload path settings
          final list =
              _extractNestedProperty(decoded, config.listResponsePath) ??
                  decoded;
          final total =
              _extractNestedProperty(decoded, config.totalCountResponsePath) ??
                  (list is List ? list.length : 0);
          return ApiResult.success({
            'items': list,
            'total': total,
          }, driverUsed: driverId);
        }
      }

      return ApiResult.failure(
          VaultStreamException(
              'http_err', decoded['message'] ?? 'Read request failed'),
          driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(
          VaultStreamException('connection_exception', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<ApiResult<dynamic>> write(
      String slug, String op, Map<String, dynamic> body,
      {String? id, required DriverContext context}) async {
    try {
      final endpoint = id != null
          ? '${config.baseUrl}/$slug/$id'
          : '${config.baseUrl}/$slug';
      final uri = Uri.parse(endpoint);

      HttpClientRequest request;
      if (op == 'deleteById') {
        request = await _client.deleteUrl(uri);
      } else if (op == 'updateById' || op == 'patchById') {
        request = await _client.patchUrl(uri);
      } else {
        request = await _client.postUrl(uri);
      }

      _injectHeaders(request, context);
      request.headers.contentType = ContentType.json;

      if (op != 'deleteById') {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final respBody = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(respBody);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResult.success(decoded, driverUsed: driverId);
      }
      return ApiResult.failure(
          VaultStreamException(
              'http_err', decoded['message'] ?? 'Write failed'),
          driverUsed: driverId);
    } catch (e) {
      return ApiResult.failure(
          VaultStreamException('connection_exception', e.toString()),
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
  Future<void> dispose() async {
    _client.close(force: true);
  }
}

// =============================================================================
// SECTION 3: UNIVERSAL AUTHENTICATION DRIVER
// =============================================================================

class UniversalAuthDriver implements AuthDriver {
  @override
  final String driverId = 'universal_auth';

  @override
  final AuthCapabilities capabilities = const AuthCapabilities(
    register: true,
    login: true,
    refresh: true,
    revoke: true,
    profileUpdates: true,
    passwordOperations: true,
    emailVerification: true,
  );

  final UniversalApiConfig apiConfig;
  final UniversalAuthConfig authConfig;
  final HttpClient _client;

  UniversalAuthDriver({required this.apiConfig, required this.authConfig})
      : _client = HttpClient();

  @override
  Future<void> initialize(Map<String, dynamic> config) async {}

  AuthException _handleError(dynamic code, dynamic message) => AuthException(
      code?.toString() ?? 'auth_error',
      message?.toString() ?? 'Operation failed');

  dynamic _extractNested(dynamic json, String path) {
    if (path.isEmpty) return json;
    final parts = path.split('.');
    dynamic current = json;
    for (final part in parts) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  SessionContext _buildSession(dynamic decodedJson) {
    final token =
        _extractNested(decodedJson, authConfig.tokenJsonPath) as String?;
    final userData = _extractNested(decodedJson, authConfig.userJsonPath)
            as Map<String, dynamic>? ??
        {};

    return SessionContext(
      userId: userData['id']?.toString() ?? userData['_id']?.toString(),
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      accessToken: token,
      refreshToken: decodedJson['exp']?.toString() ?? '',
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      claims: userData,
      authProviderUsed: 'jwt_cms',
    );
  }

  Future<AuthResult<SessionContext>> _postAuth(
      String endpoint, Map<String, dynamic> payload,
      {String? token}) async {
    try {
      final request =
          await _client.postUrl(Uri.parse('${apiConfig.baseUrl}$endpoint'));
      apiConfig.defaultHeaders.forEach((k, v) => request.headers.set(k, v));
      if (token != null)
        request.headers.set(HttpHeaders.authorizationHeader, 'JWT $token');

      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResult.success(_buildSession(decoded), driverUsed: driverId);
      }
      return AuthResult.failure(
          _handleError(response.statusCode,
              decoded['message'] ?? 'Authentication failed'),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(AuthException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> login(AuthRequest request) =>
      _postAuth(authConfig.loginEndpoint, request.credentials);

  @override
  Future<AuthResult<SessionContext>> register(AuthRequest request) =>
      _postAuth(authConfig.registerEndpoint, request.credentials);

  @override
  Future<AuthResult<SessionContext>> refreshSession(
      SessionContext currentSession) async {
    return _postAuth(authConfig.refreshEndpoint, {},
        token: currentSession.accessToken);
  }

  @override
  Future<AuthResult<void>> logout(SessionContext session) async {
    try {
      final request = await _client.postUrl(
          Uri.parse('${apiConfig.baseUrl}${authConfig.logoutEndpoint}'));
      if (session.accessToken != null)
        request.headers
            .set(HttpHeaders.authorizationHeader, 'JWT ${session.accessToken}');
      await request.close();
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(AuthException('logout_failed', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> revokeSession(SessionContext session) =>
      logout(session);

  @override
  Future<AuthResult<SessionContext>> updateProfile(Map<String, dynamic> profile,
      {required SessionContext currentSession}) async {
    try {
      final request = await _client
          .patchUrl(Uri.parse('${apiConfig.baseUrl}${authConfig.meEndpoint}'));
      if (currentSession.accessToken != null)
        request.headers.set(HttpHeaders.authorizationHeader,
            'JWT ${currentSession.accessToken}');
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(profile));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResult.success(_buildSession(decoded), driverUsed: driverId);
      }
      return AuthResult.failure(
          _handleError(response.statusCode, decoded['message']),
          driverUsed: driverId);
    } catch (e) {
      return AuthResult.failure(AuthException('network_error', e.toString()),
          driverUsed: driverId);
    }
  }

  // --- Password Operations ---

  @override
  Future<AuthResult<void>> forgotPassword(String email) async {
    try {
      final request = await _client
          .postUrl(Uri.parse('${apiConfig.baseUrl}/forgot-password'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'email': email}));
      await request.close();
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(AuthException('forgot_failed', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<void>> resetPassword(
      {required String token, required String password}) async {
    try {
      final request = await _client
          .postUrl(Uri.parse('${apiConfig.baseUrl}/reset-password'));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'token': token, 'password': password}));
      await request.close();
      return const AuthResult.success(null);
    } catch (e) {
      return AuthResult.failure(AuthException('reset_failed', e.toString()),
          driverUsed: driverId);
    }
  }

  @override
  Future<AuthResult<SessionContext>> changePassword(
      {required SessionContext currentSession,
      required String oldPassword,
      required String newPassword}) async {
    return _postAuth('/change-password',
        {'oldPassword': oldPassword, 'newPassword': newPassword},
        token: currentSession.accessToken);
  }

  // --- Falling Back gracefully on Unsupported API components ---
  @override
  Future<AuthResult<AuthChallenge>> requestOtp(AuthChallenge request) async =>
      AuthResult.failure(
          const AuthException('unsupported', 'CMS doesn\'t support SMS OTP'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> verifyOtp(
          AuthChallenge challenge, String code) async =>
      AuthResult.failure(const AuthException('unsupported', 'No OTP'),
          driverUsed: driverId);
  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyRegistration(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Passkeys'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> completePasskeyRegistration(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Passkeys'),
          driverUsed: driverId);
  @override
  Future<AuthResult<AuthChallenge>> beginPasskeyAuthentication(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Passkeys'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> completePasskeyAuthentication(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Passkeys'),
          driverUsed: driverId);
  @override
  Future<AuthResult<AuthChallenge>> beginBiometricAuth(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Biometrics'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> completeBiometricAuth(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Biometrics'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> linkProvider(
          AuthProvider provider, AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Link provider'),
          driverUsed: driverId);
  @override
  Future<AuthResult<SessionContext>> unlinkProvider(
          AuthProvider provider, AuthRequest request) async =>
      AuthResult.failure(
          const AuthException('unsupported', 'No Unlink provider'),
          driverUsed: driverId);
  @override
  Future<AuthResult<AuthChallenge>> confirmOperation(
          AuthRequest request) async =>
      AuthResult.failure(const AuthException('unsupported', 'No Stepup auth'),
          driverUsed: driverId);
  @override
  Future<AuthResult<List<String>>> discoverAuthMethods(
          AuthRequest request) async =>
      const AuthResult.success(['emailPassword'], driverUsed: 'universal_auth');
  @override
  Future<AuthResult<Map<String, dynamic>>> getAuthPolicy() async =>
      const AuthResult.success({'policy': 'rest_standard'},
          driverUsed: 'universal_auth');
  @override
  Future<AuthResult<void>> verifyEmail(String token) async =>
      const AuthResult.success(null);
  @override
  Future<AuthResult<void>> resendVerification() async =>
      const AuthResult.success(null);
  @override
  Future<AuthResult<void>> unlockAccount(String token) async =>
      const AuthResult.success(null);
  @override
  Future<AuthResult<void>> revokeAllSessions(
          SessionContext currentSession) async =>
      const AuthResult.success(null);

  @override
  Future<void> dispose() async {
    _client.close(force: true);
  }
}

// =============================================================================
// SECTION 4: UNIVERSAL WEBSOCKET DRIVER
// =============================================================================

class UniversalSocketDriver extends QLSocketDriverBase<SocketState, SocketMessage>
    implements SocketDriver {
  @override
  final String driverId = 'universal_ws';

  final UniversalSocketConfig socketConfig;
  WebSocket? _socket;

  UniversalSocketDriver(this.socketConfig);

  @override
  Future<void> connect(String url, Map<String, dynamic> options) async {
    try {
      emitState(SocketState.connecting);

      final headers = Map<String, dynamic>.from(socketConfig.headers);
      if (options.containsKey('headers')) {
        headers.addAll(options['headers'] as Map<String, dynamic>);
      }

      _socket = await WebSocket.connect(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      emitState(SocketState.connected);

      _socket!.listen(
        (data) {
          if (data is String) {
            if (socketConfig.frameDecoder != null) {
              emitMessage(socketConfig.frameDecoder!(data));
            } else {
              try {
                final map = jsonDecode(data);
                emitMessage(SocketMessage.fromMap(map));
              } catch (_) {
                // Ignore raw text frames that aren't envelopes
              }
            }
          } else if (data is List<int>) {
            emitBinary(data is Uint8List ? data : Uint8List.fromList(data));
          }
        },
        onError: (err) {
          emitState(SocketState.error);
          disconnect();
        },
        onDone: () {
          emitState(SocketState.disconnected);
          disconnect();
        },
        cancelOnError: true,
      );
    } catch (_) {
      emitState(SocketState.error);
      rethrow;
    }
  }

  @override
  Future<void> send(SocketMessage message) async {
    if (_socket == null || _socket!.readyState != WebSocket.open) {
      throw Exception('Socket is closed.');
    }

    if (socketConfig.frameEncoder != null) {
      final customFrame = socketConfig.frameEncoder!(message);
      _socket!.add(customFrame);
    } else {
      _socket!.add(jsonEncode(message.toMap()));
    }
  }

  @override
  Future<void> sendRawBinary(Uint8List data) async {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(data);
    }
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    emitState(SocketState.disconnected);
  }
}

// =============================================================================
// SECTION 5: UNIVERSAL HIGH-PERFORMANCE MULTIPART MEDIA UPLOADER
// =============================================================================

/// Dynamic streaming uploader supporting CMS Multipart protocols (Payload, Strapi) or raw S3 uploads.
class UniversalMediaUploader {
  final File file;
  final String uploadUrl;
  final Map<String, String> headers;
  final MediaUploadStrategy strategy;
  final String formFieldName; // e.g. "file" for Payload CMS

  UniversalMediaUploader({
    required this.file,
    required this.uploadUrl,
    this.headers = const {},
    this.strategy = MediaUploadStrategy.multipart,
    this.formFieldName = 'file',
  });

  /// Uploads binary files directly while writing to socket streams. This avoids
  /// loading the entire file into RAM, which prevents memory spikes on large file uploads.
  Stream<TransferProgress> start() {
    final controller = StreamController<TransferProgress>.broadcast();
    final client = HttpClient();

    () async {
      try {
        final totalBytes = await file.length();
        final boundary =
            'QuantumBoundary${DateTime.now().microsecondsSinceEpoch}';

        final uri = Uri.parse(uploadUrl);
        final request = await client.postUrl(uri);

        // Apply configuration headers
        headers.forEach((k, v) => request.headers.set(k, v));

        if (strategy == MediaUploadStrategy.multipart) {
          request.headers.set(HttpHeaders.contentTypeHeader,
              'multipart/form-data; boundary=$boundary');

          final headerMultipart = '--$boundary\r\n'
              'Content-Disposition: form-data; name="$formFieldName"; filename="${p_basename(file.path)}"\r\n'
              'Content-Type: ${p_lookupMime(file.path)}\r\n\r\n';

          final footerMultipart = '\r\n--$boundary--\r\n';
          final multipartPayloadLength = utf8.encode(headerMultipart).length +
              totalBytes +
              utf8.encode(footerMultipart).length;
          request.contentLength = multipartPayloadLength;

          // Write header block
          request.add(utf8.encode(headerMultipart));

          // Pipe binary bytes in 64kb chunks
          int sentBytes = 0;
          final fileStream = file.openRead();
          await for (var chunk in fileStream) {
            request.add(chunk);
            sentBytes += chunk.length;
            controller.add(TransferProgress(
              sentBytes: sentBytes,
              totalBytes: totalBytes,
              progress: sentBytes / totalBytes,
              stage: 'uploading_multipart',
              currentSpeedBps: 0,
              estimatedTimeRemaining: const Duration(seconds: 0),
            ));
          }

          // Write footer block
          request.add(utf8.encode(footerMultipart));
        } else {
          // Direct Binary Put strategy (AWS S3)
          request.headers
              .set(HttpHeaders.contentTypeHeader, p_lookupMime(file.path));
          request.contentLength = totalBytes;

          int sentBytes = 0;
          final fileStream = file.openRead();
          await for (var chunk in fileStream) {
            request.add(chunk);
            sentBytes += chunk.length;
            controller.add(TransferProgress(
              sentBytes: sentBytes,
              totalBytes: totalBytes,
              progress: sentBytes / totalBytes,
              stage: 'uploading_raw',
              currentSpeedBps: 0,
              estimatedTimeRemaining: const Duration(seconds: 0),
            ));
          }
        }

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          controller.close();
        } else {
          controller.addError(VaultStreamException('http_upload_failed', body));
          controller.close();
        }
      } catch (e) {
        controller
            .addError(VaultStreamException('upload_exception', e.toString()));
        controller.close();
      } finally {
        client.close();
      }
    }();

    return controller.stream;
  }

  // Pure self-contained helpers to eliminate external package dependencies (like 'mime' or 'path')
  String p_basename(String path) =>
      path.split(Platform.isWindows ? '\\' : '/').last;
  String p_lookupMime(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
